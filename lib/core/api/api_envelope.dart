import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../result/result.dart';
import 'api_transport.dart';

/// Pagination block from `meta.pagination` (conventions §5).
@immutable
class PageMeta {
  const PageMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  static const int defaultPerPage = 25;
  static const int maxPerPage = 100;

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasMore;

  static PageMeta? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final page = _asInt(raw['page']);
    final perPage = _asInt(raw['per_page']);
    if (page == null || perPage == null) return null;
    return PageMeta(
      page: page,
      perPage: perPage,
      total: _asInt(raw['total']) ?? 0,
      totalPages: _asInt(raw['total_pages']) ?? 0,
      hasMore: raw['has_more'] == true,
    );
  }
}

/// A decoded success envelope: `{ "data": ..., "meta": { ... } }`.
@immutable
class ApiEnvelope<T> {
  const ApiEnvelope({required this.data, this.requestId, this.pagination});

  final T data;

  /// `meta.request_id` — quote-able by a resident to the support desk.
  final String? requestId;

  final PageMeta? pagination;
}

/// Decodes the Taytay API response envelopes into [Result].
///
/// The contract this implements (`docs/api/conventions.md`):
///
/// * success is `{ "data": ..., "meta": {...} }` — there is no `success: true`
///   flag, the HTTP status carries success or failure;
/// * failure is `{ "error": { code, message, details, request_id } }`;
/// * `meta` is additive and **clients must ignore unknown fields**, so this
///   decoder never rejects a response for carrying keys it does not know.
abstract final class ApiEnvelopeDecoder {
  /// Interprets [response], converting the payload with [decodeData].
  ///
  /// [decodeData] receives the raw `data` value and must not throw; anything it
  /// does throw is contained and reported as [ContractFailure].
  static Result<ApiEnvelope<T>> decode<T>(
    ApiHttpResponse response,
    T Function(Object? data) decodeData,
  ) {
    final Object? decodedBody;
    if (response.body.trim().isEmpty) {
      decodedBody = null;
    } else {
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException catch (error) {
        // An HTML error page reaching a JSON client is the exact failure the
        // server's ForceJsonResponse middleware exists to prevent; if it happens
        // it is a contract breach, not a resident's problem.
        return Err<ApiEnvelope<T>>(
          ContractFailure(
            requestId: response.requestId,
            debugMessage: 'Response body was not JSON: ${error.message}',
          ),
        );
      }
    }

    if (!response.isSuccess) {
      return Err<ApiEnvelope<T>>(_decodeError(response, decodedBody));
    }

    // 204 No Content has no body; a caller expecting a value gets a contract
    // failure, a caller decoding to void gets its unit value.
    final Object? dataField = decodedBody is Map<String, dynamic>
        ? decodedBody['data']
        : null;

    final Object? meta = decodedBody is Map<String, dynamic>
        ? decodedBody['meta']
        : null;
    final metaMap = meta is Map<String, dynamic> ? meta : null;

    try {
      return Ok<ApiEnvelope<T>>(
        ApiEnvelope<T>(
          data: decodeData(dataField),
          requestId: _asString(metaMap?['request_id']) ?? response.requestId,
          pagination: PageMeta.tryParse(metaMap?['pagination']),
        ),
      );
    } on Object catch (error) {
      return Err<ApiEnvelope<T>>(
        ContractFailure(
          requestId: response.requestId,
          debugMessage: 'Could not read `data` as $T: $error',
        ),
      );
    }
  }

  /// Turns a non-2xx response into the matching [AppFailure].
  static AppFailure _decodeError(
    ApiHttpResponse response,
    Object? decodedBody,
  ) {
    final Object? errorField = decodedBody is Map<String, dynamic>
        ? decodedBody['error']
        : null;
    final errorMap = errorField is Map<String, dynamic> ? errorField : null;

    final code = ApiErrorCode.parse(_asString(errorMap?['code']));
    final requestId = _asString(errorMap?['request_id']) ?? response.requestId;

    return failureFromApiError(
      statusCode: response.statusCode,
      code: code,
      message: _asString(errorMap?['message']),
      requestId: requestId,
      fieldErrors: _decodeFieldErrors(errorMap?['details']),
      retryAfter: response.retryAfter,
    );
  }

  /// `details` for `VALIDATION_FAILED` is `field -> [messages]`. Anything else
  /// (a free-form object for another code) is ignored rather than coerced.
  static Map<String, List<String>> _decodeFieldErrors(Object? details) {
    if (details is! Map<String, dynamic>) return const <String, List<String>>{};
    final result = <String, List<String>>{};
    for (final entry in details.entries) {
      final value = entry.value;
      if (value is List) {
        final messages = value.whereType<String>().toList(growable: false);
        if (messages.isNotEmpty) result[entry.key] = messages;
      } else if (value is String) {
        result[entry.key] = <String>[value];
      }
    }
    return Map<String, List<String>>.unmodifiable(result);
  }
}

int? _asInt(Object? value) => switch (value) {
  final int value => value,
  final String value => int.tryParse(value),
  _ => null,
};

String? _asString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
