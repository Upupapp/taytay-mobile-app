import 'package:flutter/foundation.dart';

import '../result/result.dart';

/// HTTP verbs the API contract uses.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const HttpMethod(this.wireValue);

  final String wireValue;

  /// `GET`/`HEAD` never mutate (conventions §7); used to decide what may be
  /// retried automatically.
  bool get isSafe => this == HttpMethod.get;
}

/// One outbound API call, fully described and transport-agnostic.
@immutable
class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const <String, String>{},
    this.body,
    this.headers = const <String, String>{},
    this.timeout,
    this.file,
  });

  final HttpMethod method;

  /// Path relative to `AppConfig.apiBaseUri`, e.g. `health` or
  /// `residents/me/credentials`. Never an absolute URL — the base URI is the one
  /// place the environment is decided.
  final String path;

  final Map<String, String> query;

  /// Decoded JSON body, or `null`.
  final Object? body;

  final Map<String, String> headers;

  /// Overrides the config default; used for uploads.
  final Duration? timeout;

  /// A file to send as `multipart/form-data` instead of a JSON body.
  ///
  /// The only request shape in this app that is not JSON. It is expressed here
  /// rather than left to a bespoke upload path so that everything above the
  /// transport — retry, idempotency, correlation, failure mapping — keeps
  /// working identically for an upload, which is the request most likely to be
  /// retried and therefore the one that needs those rules most.
  final MultipartFile? file;

  @override
  String toString() => 'ApiRequest(${method.wireValue} $path)';
}

/// A raw HTTP response, before envelope interpretation.
@immutable
class ApiHttpResponse {
  const ApiHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const <String, String>{},
  });

  final int statusCode;

  /// Raw response body text. May be empty (`204 No Content`).
  final String body;

  /// Lower-cased response headers.
  final Map<String, String> headers;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// `X-Request-Id`, which the server always sets (conventions §2).
  String? get requestId => headers['x-request-id'];

  /// `Retry-After` in seconds, when present on a 429/503.
  Duration? get retryAfter {
    final raw = headers['retry-after'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }
}

/// A file being sent, with the field name the server expects it under.
@immutable
class MultipartFile {
  const MultipartFile({
    required this.field,
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });

  final String field;
  final String filename;
  final Uint8List bytes;
  final String mimeType;

  /// Redacted: the bytes are a resident's identity document.
  @override
  String toString() =>
      'MultipartFile($field, $mimeType, ${bytes.length} bytes)';
}

/// The seam between the app and the network.
///
/// Everything above this interface — envelope decoding, failure mapping, session
/// handling — is pure Dart and unit-testable without a socket. The concrete
/// HTTP implementation is deliberately *not* part of TAB 01: choosing a client
/// package (and its certificate-pinning story) is a decision that belongs with
/// the first real authenticated endpoint, and an unused HTTP dependency shipped
/// early is an unreviewed attack surface.
///
/// A transport reports connectivity problems as [NetworkFailure] or
/// [TimeoutFailure] and never throws.
abstract interface class ApiTransport {
  Future<Result<ApiHttpResponse>> send(ApiRequest request);
}
