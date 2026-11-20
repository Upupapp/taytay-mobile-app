import 'dart:math' as math;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/own_assistance_repository.dart';
import '../domain/own_assistance_request.dart';
import 'own_assistance_codec.dart';

/// The resident's own assistance requests on the Node API (backend
/// `d1e997c`, ADR 0003 C, D-223): `GET /me/assistance-requests`, registered
/// or verified, a cursor page at a time. Applying from a Tulong page and
/// adding documents to a returned request (backend `6794f8d`, ADR 0004
/// decision 2, D-226) are the two multipart writes.
class OwnAssistanceApiRepository implements OwnAssistanceRepository {
  const OwnAssistanceApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The route's ceiling on `limit`. The office's default page size may be
  /// larger, and a larger `limit` is a 422.
  static const int maxLimit = 50;

  /// How many full pages [findOwn] reads before it stops. Five hundred
  /// requests is far beyond one person's; past it the request is said as
  /// not shown rather than read for ever.
  static const int findPageCeiling = 10;

  @override
  Future<Result<Paginated<OwnAssistanceRequest>>> listOwn({String? cursor}) =>
      _read(
        limit: math.min(_apiClient.pages.defaultPerPage, maxLimit),
        cursor: cursor,
      );

  @override
  Future<Result<OwnAssistanceRequest>> findOwn(String id) async {
    String? cursor;
    for (int read = 0; read < findPageCeiling; read++) {
      final Result<Paginated<OwnAssistanceRequest>> page = await _read(
        limit: maxLimit,
        cursor: cursor,
      );
      switch (page) {
        case Err(:final failure):
          return Err<OwnAssistanceRequest>(failure);
        case Ok(:final value):
          for (final OwnAssistanceRequest item in value.items) {
            if (item.id == id) return Ok<OwnAssistanceRequest>(item);
          }
          final String? next = value.nextCursor;
          if (!value.hasMore || next == null || next.isEmpty) {
            return const Err<OwnAssistanceRequest>(
              NotFoundFailure(debugMessage: 'Not in the resident\'s list.'),
            );
          }
          cursor = next;
      }
    }
    return const Err<OwnAssistanceRequest>(
      NotFoundFailure(debugMessage: 'Not within the pages read.'),
    );
  }

  @override
  Future<Result<OwnAssistanceRequest>> apply({
    required String serviceSlug,
    required String purpose,
    int? requestedAmountCentavos,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final int? amount = requestedAmountCentavos;
    final Result<ApiEnvelope<OwnAssistanceRequest?>> response = await _apiClient
        .send<OwnAssistanceRequest?>(
          method: HttpMethod.post,
          path: 'me/assistance-applications',
          authenticated: true,
          // Filed means 201. Any other success would show a control number
          // for a request the server did not say it filed.
          requiredStatus: 201,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{
            'service_slug': serviceSlug,
            'purpose': purpose.trim(),
            // Whole centavos as digits, as the route reads a multipart field.
            if (amount != null) 'requested_amount_centavos': '$amount',
            'idempotency_key': idempotencyKey,
          },
          files: _parts(files),
          decode: OwnAssistanceCodec.row,
        );
    return response.flatMap(_present);
  }

  @override
  Future<Result<OwnAssistanceRequest>> addDocuments(
    String requestId, {
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final Result<ApiEnvelope<OwnAssistanceRequest?>> response = await _apiClient
        .send<OwnAssistanceRequest?>(
          method: HttpMethod.post,
          path: 'me/assistance-requests/$requestId/documents',
          authenticated: true,
          requiredStatus: 201,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{'idempotency_key': idempotencyKey},
          files: _parts(files),
          decode: OwnAssistanceCodec.row,
        );
    return response.flatMap(_present);
  }

  /// One part per document, named by its code.
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

  static Result<OwnAssistanceRequest> _present(
    ApiEnvelope<OwnAssistanceRequest?> envelope,
  ) {
    final OwnAssistanceRequest? value = envelope.data;
    if (value == null) {
      return Err<OwnAssistanceRequest>(
        ContractFailure(
          requestId: envelope.requestId,
          debugMessage: 'Assistance response had no readable row.',
        ),
      );
    }
    return Ok<OwnAssistanceRequest>(value);
  }

  Future<Result<Paginated<OwnAssistanceRequest>>> _read({
    required int limit,
    String? cursor,
  }) async {
    final Result<ApiEnvelope<List<OwnAssistanceRequest>>> response =
        await _apiClient.send<List<OwnAssistanceRequest>>(
          method: HttpMethod.get,
          path: 'me/assistance-requests',
          authenticated: true,
          query: <String, String>{'limit': '$limit', 'cursor': ?cursor},
          decode: OwnAssistanceCodec.list,
        );
    return response.map(_page);
  }

  static Paginated<OwnAssistanceRequest> _page(
    ApiEnvelope<List<OwnAssistanceRequest>> envelope,
  ) {
    final PageMeta? pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<OwnAssistanceRequest>.single(envelope.data);
    }
    return Paginated<OwnAssistanceRequest>(
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
