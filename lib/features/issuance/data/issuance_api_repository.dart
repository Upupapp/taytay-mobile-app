import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/issuance_repository.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_type.dart';
import 'issuance_codec.dart';

/// Document requests on the Node API (backend `2fd0566`, `0d1cb14`).
///
/// The catalogue is public and read anonymously. Everything under `me/` is the
/// signed-in resident's own, and the server answers for nobody else's.
///
/// **A retried send files once.** Submit, resubmit and cancel carry the
/// caller's key as `idempotency_key` in the body — a multipart field for the
/// two that send files — because that is where the Node API reads it: the
/// same key with the same fields and files is answered with the request as it
/// stands, and never acts twice. The key also goes to [ApiClient] as the
/// `Idempotency-Key` header, which the server ignores and this app's transport
/// reads: it is what lets a send lost to a dropped connection be repeated
/// automatically (`RetryPolicy`).
class IssuanceApiRepository implements IssuanceRepository {
  const IssuanceApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<IssuanceType>>> listTypes() async {
    // The whole list: an office lists at most 50 active types and `meta` is
    // `{}`. There is no cursor to follow.
    final Result<ApiEnvelope<List<IssuanceType>>> response = await _apiClient
        .send<List<IssuanceType>>(
          method: HttpMethod.get,
          path: 'issuance-types',
          authenticated: false,
          decode: IssuanceCodec.typeList,
        );
    return response.map(
      (ApiEnvelope<List<IssuanceType>> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<IssuanceType>> loadType(String typeId) async {
    final Result<ApiEnvelope<IssuanceType?>> response = await _apiClient
        .send<IssuanceType?>(
          method: HttpMethod.get,
          path: 'issuance-types/$typeId',
          authenticated: false,
          decode: IssuanceCodec.type,
        );
    return response.flatMap(_present<IssuanceType>);
  }

  @override
  Future<Result<IssuanceRequestDetail>> submit({
    required String typeId,
    required String purpose,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final Result<ApiEnvelope<IssuanceRequestDetail?>> response =
        await _apiClient.send<IssuanceRequestDetail?>(
          method: HttpMethod.post,
          path: 'me/issuance-requests',
          authenticated: true,
          // Filed means 201. Any other success would show a reference number
          // for a request the server did not say it opened.
          requiredStatus: 201,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{
            'type_id': typeId,
            'purpose': purpose.trim(),
            'idempotency_key': idempotencyKey,
          },
          files: _parts(files),
          decode: IssuanceCodec.detail,
        );
    return response.flatMap(_present<IssuanceRequestDetail>);
  }

  @override
  Future<Result<Paginated<IssuanceRequestSummary>>> listOwn({
    String? cursor,
  }) async {
    final Result<ApiEnvelope<List<IssuanceRequestSummary>>> response =
        await _apiClient.send<List<IssuanceRequestSummary>>(
          method: HttpMethod.get,
          path: 'me/issuance-requests',
          authenticated: true,
          query: <String, String>{
            'limit': '${_apiClient.pages.defaultPerPage}',
            'cursor': ?cursor,
          },
          decode: IssuanceCodec.summaryList,
        );
    return response.map(_page);
  }

  @override
  Future<Result<IssuanceRequestDetail>> loadOwn(String requestId) async {
    final Result<ApiEnvelope<IssuanceRequestDetail?>> response =
        await _apiClient.send<IssuanceRequestDetail?>(
          method: HttpMethod.get,
          path: 'me/issuance-requests/$requestId',
          authenticated: true,
          decode: IssuanceCodec.detail,
        );
    return response.flatMap(_present<IssuanceRequestDetail>);
  }

  @override
  Future<Result<IssuanceRequestDetail>> cancel(
    String requestId, {
    String? reason,
    required String idempotencyKey,
  }) async {
    final String? said = reason?.trim();
    final Result<ApiEnvelope<IssuanceRequestDetail?>> response =
        await _apiClient.send<IssuanceRequestDetail?>(
          method: HttpMethod.post,
          path: 'me/issuance-requests/$requestId/cancel',
          authenticated: true,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{
            if (said != null && said.isNotEmpty) 'reason': said,
            'idempotency_key': idempotencyKey,
          },
          decode: IssuanceCodec.detail,
        );
    return response.flatMap(_present<IssuanceRequestDetail>);
  }

  @override
  Future<Result<IssuanceRequestDetail>> resubmit(
    String requestId, {
    String? note,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final String? said = note?.trim();
    final Result<ApiEnvelope<IssuanceRequestDetail?>> response =
        await _apiClient.send<IssuanceRequestDetail?>(
          method: HttpMethod.post,
          path: 'me/issuance-requests/$requestId/resubmit',
          authenticated: true,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{
            if (said != null && said.isNotEmpty) 'note': said,
            'idempotency_key': idempotencyKey,
          },
          files: _parts(files),
          decode: IssuanceCodec.detail,
        );
    return response.flatMap(_present<IssuanceRequestDetail>);
  }

  @override
  Future<Result<Uint8List>> loadAttachmentImage(
    String requestId,
    String attachmentId,
  ) async {
    final Result<ApiEnvelope<Uint8List?>>
    response = await _apiClient.send<Uint8List?>(
      method: HttpMethod.get,
      path: 'me/issuance-requests/$requestId/attachments/$attachmentId/content',
      authenticated: true,
      binary: true,
      decode: (Object? _) => null,
    );
    return response.flatMap(
      (ApiEnvelope<Uint8List?> envelope) => switch (envelope.data) {
        final Uint8List bytes when bytes.isNotEmpty => Ok<Uint8List>(bytes),
        // The binary path reads a 404 as an empty picture. For the resident's
        // own file that is "not found", and is said so.
        _ => const Err<Uint8List>(
          NotFoundFailure(debugMessage: 'Attachment content was not found.'),
        ),
      },
    );
  }

  /// One part per chosen file, under its requirement code.
  ///
  /// The file name sent is the code and an extension, not the name the phone
  /// gave the file: a gallery name routinely carries a person's name or a
  /// document number, and the office stores its own name anyway.
  static List<MultipartFile> _parts(Map<String, CapturedDocument> files) =>
      <MultipartFile>[
        for (final MapEntry<String, CapturedDocument> entry in files.entries)
          MultipartFile(
            field: entry.key,
            filename: '${entry.key}.${_extension(entry.value.mimeType)}',
            bytes: entry.value.bytes,
            mimeType: entry.value.mimeType,
          ),
      ];

  static String _extension(String mimeType) => switch (mimeType) {
    'application/pdf' => 'pdf',
    'image/png' => 'png',
    _ => 'jpg',
  };

  /// A success with nothing readable in it is a contract failure, not a blank
  /// screen.
  static Result<T> _present<T>(ApiEnvelope<T?> envelope) {
    final T? value = envelope.data;
    if (value == null) {
      return Err<T>(
        ContractFailure(
          requestId: envelope.requestId,
          debugMessage: 'Issuance response had no readable data.',
        ),
      );
    }
    return Ok<T>(value);
  }

  static Paginated<IssuanceRequestSummary> _page(
    ApiEnvelope<List<IssuanceRequestSummary>> envelope,
  ) {
    final PageMeta? pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<IssuanceRequestSummary>.single(envelope.data);
    }
    return Paginated<IssuanceRequestSummary>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
      nextCursor: pagination.nextCursor,
    );
  }
}
