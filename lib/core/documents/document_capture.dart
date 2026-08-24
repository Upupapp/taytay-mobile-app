import 'package:flutter/foundation.dart';

import 'upload_policy.dart';

/// Where a document came from.
enum DocumentSource {
  camera('Take a photo'),
  gallery('Choose a photo'),
  file('Choose a file');

  const DocumentSource(this.label);

  /// Resident-facing action label. Fixed copy.
  final String label;
}

/// A file the resident chose, held in memory on its way to the server.
///
/// ---
///
/// **Bytes, not a path.** Two reasons, and both are constitution Article 5
/// obligations rather than preferences:
///
/// 1. A path points at a file the app does not own and cannot promise to
///    delete. On Android a gallery pick may hand back a URI backed by a copy in
///    a cache directory that survives the flow; on iOS a camera capture may
///    write to the temporary directory. Holding bytes means the sensitive
///    material has exactly one lifetime — this object's — and it ends when the
///    upload does.
/// 2. A path is not a document. Sending one to the server transmits a reference
///    that means nothing outside this device.
///
/// Nothing here is ever logged. [toString] names the source and the size and
/// deliberately omits the filename, which routinely contains a person's name or
/// a document number.
@immutable
class CapturedDocument {
  const CapturedDocument({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.source,
  });

  final Uint8List bytes;

  /// As the platform reported it. Shown to the resident so they can tell two
  /// picks apart; never logged, never used to decide the type.
  final String fileName;

  /// As the platform reported it. **Checked against the actual bytes** before
  /// the document is accepted — see [DocumentCapturePolicy.inspect].
  final String mimeType;

  final DocumentSource source;

  int get sizeBytes => bytes.lengthInBytes;

  /// Human-readable size for the preview, e.g. `1.4 MB`.
  String get readableSize {
    const int kib = 1024;
    if (sizeBytes < kib) return '$sizeBytes bytes';
    if (sizeBytes < kib * kib) {
      return '${(sizeBytes / kib).toStringAsFixed(0)} KB';
    }
    return '${(sizeBytes / (kib * kib)).toStringAsFixed(1)} MB';
  }

  bool get isImage => mimeType.startsWith('image/');

  @override
  String toString() =>
      'CapturedDocument(${source.name}, $mimeType, $sizeBytes bytes)';
}

/// Why a chosen file cannot be sent.
///
/// A closed set, each with copy that says what to do next rather than what the
/// validator objected to.
enum DocumentRejection {
  empty(
    'That file is empty. Choose it again, or take a photo of the document '
    'instead.',
  ),
  tooLarge(
    'That file is too large to send. A photo taken in this app is usually small '
    'enough — try taking one instead.',
  ),
  unsupportedType(
    'Taytay LGU can only accept a photo (JPEG or PNG) or a PDF. Take a photo of '
    'the document if you have it on paper.',
  ),
  contentsDoNotMatchType(
    'That file could not be read as a photo or a PDF. Take a photo of the '
    'document instead.',
  );

  const DocumentRejection(this.residentMessage);

  /// Fixed, resident-facing. Never a platform error string.
  final String residentMessage;
}

/// What may be uploaded, and how far a photo may be compressed.
///
/// ---
///
/// ## The readability floor
///
/// TAB 16's acceptance criterion is that documents stay readable after
/// optimisation, and that is a resolution question with a real answer. Optical
/// character recognition and human reading of small print on an A4 form both
/// need roughly 150–200 DPI. A4 is 8.27 inches on its long edge, so:
///
/// * 150 DPI → ~1240 px
/// * 200 DPI → ~1654 px
///
/// [minLongEdge] is therefore **1600 px**, near the top of that band, and
/// [imageQuality] is 88 — high enough that JPEG ringing does not close up the
/// counters of small type. These are floors handed to the platform picker, which
/// re-encodes natively; the app never downscales below them, and never
/// re-encodes a PDF at all.
///
/// A document rejected at the counter days later, for a reason nobody told the
/// resident, costs them a second trip. That is the failure this class exists to
/// prevent, and it is why the limits err toward larger files.
abstract final class DocumentCapturePolicy {
  /// Long-edge floor in pixels for a captured or chosen photo.
  static const int minLongEdge = 1600;

  /// JPEG quality handed to the platform re-encoder, 0–100.
  static const int imageQuality = 88;

  /// Checks a chosen file, returning the reason it cannot be sent or `null`.
  ///
  /// ---
  ///
  /// **The declared type is not trusted.** A file's reported MIME type comes
  /// from an extension or from the OS, and both are attacker-influenced on a
  /// shared device. So the leading bytes are matched against the format's own
  /// signature, and a mismatch is rejected.
  ///
  /// This is not a security boundary — the server validates the upload and its
  /// answer is the one that counts. It is here because catching it on the device
  /// tells the resident something actionable *now*, instead of after a round
  /// trip that ends in a message written for an operator.
  /// [policy] is the server's, carried on the requirements response. It is a
  /// **parameter rather than a constant** because a ceiling maintained in this
  /// repository is a second description of a boundary the server owns, and it
  /// drifts the first time the server's changes — which is exactly what TAB 01
  /// found had already happened, twice, in two different files.
  static DocumentRejection? inspect(
    CapturedDocument document,
    UploadPolicy policy,
  ) {
    if (document.sizeBytes == 0) return DocumentRejection.empty;
    if (document.sizeBytes > policy.maxBytes) return DocumentRejection.tooLarge;
    if (!policy.mimeTypes.contains(document.mimeType)) {
      return DocumentRejection.unsupportedType;
    }
    if (!_signatureMatches(document)) {
      return DocumentRejection.contentsDoNotMatchType;
    }
    return null;
  }

  /// Whether a document of this type may be re-encoded at all.
  ///
  /// A PDF is never touched: re-encoding one is not compression, it is
  /// rasterising a document that may already be a signed original.
  static bool mayCompress(String mimeType) => mimeType.startsWith('image/');

  static bool _signatureMatches(CapturedDocument document) {
    final bytes = document.bytes;
    return switch (document.mimeType) {
      'image/jpeg' => _startsWith(bytes, _jpeg),
      'image/png' => _startsWith(bytes, _png),
      'application/pdf' => _startsWith(bytes, _pdf),
      _ => false,
    };
  }

  static const List<int> _jpeg = <int>[0xFF, 0xD8, 0xFF];
  static const List<int> _png = <int>[0x89, 0x50, 0x4E, 0x47];

  /// `%PDF`.
  static const List<int> _pdf = <int>[0x25, 0x50, 0x44, 0x46];

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}

/// The device-side seam for choosing a document.
///
/// An interface so the whole upload flow is testable without a platform
/// channel, and so the picker can be swapped without touching a screen. The
/// same shape as `LocalAuthenticator`: one real implementation at the edge, one
/// that reports the capability as absent.
abstract interface class DocumentPicker {
  /// Returns the chosen document, or `null` when the resident cancelled.
  ///
  /// Cancelling is not an error and must never be reported as one — a person
  /// backing out of a camera is exercising a choice.
  /// [policy] decides which file extensions the system picker offers, so the
  /// list a resident sees comes from the server rather than from a constant
  /// this repository maintains beside it.
  Future<CapturedDocument?> pick(DocumentSource source, UploadPolicy policy);

  /// Whether this device offers [source] at all. A tablet with no camera should
  /// not show a camera button that cannot work.
  bool supports(DocumentSource source);
}

/// Reports every source as unavailable.
///
/// The default in tests and on any platform without a picker. It declines
/// rather than throwing, so a screen renders an honest explanation instead of
/// crashing on a device the app was not expecting.
class UnavailableDocumentPicker implements DocumentPicker {
  const UnavailableDocumentPicker();

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => null;

  @override
  bool supports(DocumentSource source) => false;
}
