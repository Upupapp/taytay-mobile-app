import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/server_value.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/resident_requirement.dart';

/// Talks to `me/cases/{case}/requirements` and the document routes beneath it.
///
/// ---
///
/// **This is where uploads fail in practice, and most of the failures are size.**
/// A current phone camera produces a 4–12 MB photograph; a resident
/// photographing a barangay clearance has no idea that is a problem, and the
/// error they meet if nothing is done about it arrives after the whole file has
/// been pushed over mobile data they paid for. So the image is downscaled before
/// it is sent, and the size error becomes something most residents never see.
///
/// The downscale uses Flutter's own image codec rather than a package. Article 1
/// asks for a stated reason per dependency, and "to resize a JPEG" is not one
/// when the engine already does it — `instantiateImageCodec` takes a target
/// width and decodes straight to it, which is also less memory than decoding
/// full-size and scaling after.
class RequirementApiRepository implements RequirementRepository {
  const RequirementApiRepository({
    required ApiClient apiClient,
    Telemetry? telemetry,
  }) : _apiClient = apiClient,
       _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents. See `Telemetry` for the three
  /// conditions that gate every signal, and `TelemetrySignal` for why the
  /// payload is a sealed set with no free-text field.
  final Telemetry? _telemetry;

  /// The longest edge an identity document is sent at.
  ///
  /// Chosen against what the document is *for*: a reviewer reading a name, a
  /// date and a signature off a clearance. 2000px on the long edge keeps small
  /// print legible while taking a typical camera photo from megabytes to
  /// hundreds of kilobytes. Larger is not more readable, it is only more
  /// expensive — and on a prepaid connection the resident pays for it twice,
  /// once in data and once in the time they stand there waiting.
  static const int maxLongEdge = 2000;

  /// The client-side ceiling, deliberately below any proxy limit.
  ///
  /// A body that exceeds nginx's `client_max_body_size` is refused *by nginx*,
  /// before the application sees it — so the answer is not the JSON envelope and
  /// carries no error code. Refusing here first means the resident is told the
  /// file is too large, in words, instead of meeting a failure the app cannot
  /// read. The number needs confirming against the deployed proxy: it is a guess
  /// at a value only the backend team knows, and it is recorded as one.
  static const int maxUploadBytes = 8 * 1024 * 1024;

  @override
  Future<Result<RequirementChecklist>> listRequirements(
    String requestId,
  ) async {
    final response = await _apiClient.send<RequirementChecklist>(
      method: HttpMethod.get,
      path: 'me/cases/$requestId/requirements',
      authenticated: true,
      decode: (Object? data) => _decodeChecklist(requestId, data),
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<UploadedDocumentReference>> uploadRequirementDocument({
    required String requestId,
    required String requirementCode,
    required CapturedDocument document,
    required String idempotencyKey,
    void Function(double)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    // Progress is reported at the two moments this transport can honestly report
    // it: the file is ready to send, and the server has answered. `package:http`
    // buffers the body rather than streaming it, so a percentage between those
    // two points would be an animation rather than a measurement — and a
    // progress bar that moves while nothing is happening is how a resident
    // decides the app has frozen and kills it mid-upload.
    onProgress?.call(0);

    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.documentUpload,
          stage: TelemetryStage.started,
        ),
      ),
    );

    final Uint8List bytes = await _rightSized(document);

    // Checked before sending, and again after: an upload that has already
    // reached the server cannot be un-sent, so what must never happen is
    // reporting success for something the resident stopped.
    if (cancellation?.isCancelled ?? false) {
      return const Err<UploadedDocumentReference>(
        UnexpectedFailure(debugContext: 'upload:cancelled'),
      );
    }

    if (bytes.lengthInBytes > maxUploadBytes) {
      // Refused before it leaves the device. The alternative is pushing several
      // megabytes over mobile data to be told no by a proxy that cannot say why.
      return const Err<UploadedDocumentReference>(
        UnacceptableUploadFailure(
          isTooLarge: true,
          debugMessage: 'Body exceeds the client ceiling after downscaling.',
        ),
      );
    }

    final response = await _apiClient.send<UploadedDocumentReference>(
      method: HttpMethod.post,
      path: 'me/cases/$requestId/requirements/$requirementCode/documents',
      authenticated: true,
      // An upload is the request most likely to be retried — it is long, and it
      // runs on the worst connections. Without the key a retry is a second
      // version in the office's file.
      idempotencyKey: idempotencyKey,
      file: MultipartFile(
        // The field name the server validates under. Not configurable: a
        // mismatch here is a 422 that reads like the resident's fault.
        field: 'file',
        filename: document.fileName,
        bytes: bytes,
        mimeType: document.mimeType,
      ),
      decode: (Object? data) => _decodeUploaded(requirementCode, data),
    );

    onProgress?.call(1);

    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.documentUpload,
          stage: TelemetryStage.completed,
        ),
      ),
    );

    if (cancellation?.isCancelled ?? false) {
      return const Err<UploadedDocumentReference>(
        UnexpectedFailure(debugContext: 'upload:cancelled'),
      );
    }

    return response.map((envelope) => envelope.data);
  }

  /// Decodes to the target size, or returns the bytes untouched.
  ///
  /// Anything that is not an image the engine can read — a PDF, most obviously —
  /// passes through whole. A PDF of a birth certificate is already small and
  /// re-encoding it would be lossy in a way a reviewer would notice.
  Future<Uint8List> _rightSized(CapturedDocument document) async {
    if (!document.mimeType.startsWith('image/')) return document.bytes;

    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        document.bytes,
      );
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      );

      final int longEdge = descriptor.width > descriptor.height
          ? descriptor.width
          : descriptor.height;
      if (longEdge <= maxLongEdge) {
        descriptor.dispose();
        return document.bytes;
      }

      final double scale = maxLongEdge / longEdge;
      final ui.Codec codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? encoded = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      frame.image.dispose();
      codec.dispose();
      descriptor.dispose();

      if (encoded == null) return document.bytes;
      final Uint8List resized = encoded.buffer.asUint8List();
      // Only if it actually helped. Re-encoding a small JPEG as PNG can be
      // larger, and sending the bigger one to prove a point costs the resident
      // data for nothing.
      return resized.lengthInBytes < document.bytes.lengthInBytes
          ? resized
          : document.bytes;
    } on Object {
      // A file the engine cannot decode is still a file the office may accept.
      // Failing the upload because the *optimisation* failed would be the app
      // refusing on its own initiative.
      return document.bytes;
    }
  }

  static RequirementChecklist _decodeChecklist(String requestId, Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? rows = map['requirements'];

    final List<ResidentRequirement> items = <ResidentRequirement>[];
    if (rows is List<dynamic>) {
      for (final Object? row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final Object? id = row['id'];
        final Object? label = row['label'];
        if (id is! String || label is! String) continue;

        items.add(
          ResidentRequirement(
            code: id,
            label: label,
            obligation: ServerValue<RequirementObligation>(
              raw: row['is_required'] == true ? 'required' : 'optional',
              known: row['is_required'] == true
                  ? RequirementObligation.required
                  : RequirementObligation.optional,
            ),
            // Three server booleans, one resident question: what do I still have
            // to do? Accepted beats provided beats missing, in that order,
            // because a document that was provided and then refused is not
            // "provided" from where the resident is standing.
            status: _statusFrom(row),
          ),
        );
      }
    }

    return RequirementChecklist(
      requestId: requestId,
      items: List<ResidentRequirement>.unmodifiable(items),
    );
  }

  static ServerValue<RequirementStatus> _statusFrom(Map<String, dynamic> row) {
    if (row['is_accepted'] == true) {
      return const ServerValue<RequirementStatus>(
        raw: 'verified',
        known: RequirementStatus.verified,
      );
    }
    if (row['is_provided'] == true) {
      return const ServerValue<RequirementStatus>(
        raw: 'submitted',
        known: RequirementStatus.submitted,
      );
    }
    return const ServerValue<RequirementStatus>(
      raw: 'missing',
      known: RequirementStatus.missing,
    );
  }

  static UploadedDocumentReference _decodeUploaded(
    String requirementCode,
    Object? data,
  ) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? id = map['id'] ?? map['version_id'];
    return UploadedDocumentReference(
      id: id is String ? id : '',
      requirementCode: requirementCode,
      status: const ServerValue<RequirementStatus>(
        raw: 'submitted',
        known: RequirementStatus.submitted,
      ),
    );
  }
}
