import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../result/result.dart';
import 'api_transport.dart';
import 'retry_policy.dart';

/// The real network transport, over `package:http`.
///
/// Responsibilities are deliberately narrow: build the URL, send bytes, apply
/// the timeout, apply [RetryPolicy], and translate socket-level failures into
/// the [AppFailure] taxonomy. It does **not** know about envelopes, sessions or
/// authorisation — those sit above it in `ApiClient`, where they are testable
/// without a socket.
///
/// It never throws: every failure path returns an `Err`.
class HttpApiTransport implements ApiTransport {
  HttpApiTransport({
    required AppConfig config,
    http.Client? client,
    RetryPolicy retryPolicy = const RetryPolicy(),
    Future<void> Function(Duration)? sleep,
  }) : _config = config,
       _client = client ?? http.Client(),
       _retryPolicy = retryPolicy,
       _sleep = sleep ?? Future<void>.delayed;

  final AppConfig _config;
  final http.Client _client;
  final RetryPolicy _retryPolicy;

  /// Injected so retry tests do not spend real time asleep.
  final Future<void> Function(Duration) _sleep;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    final uri = _resolve(request);
    final timeout = request.timeout ?? _config.requestTimeout;

    Result<ApiHttpResponse>? last;

    // The first attempt of a write that may have reached the server. A later
    // attempt that fails before sending, or is turned away as unavailable,
    // does not undo it: the resident still cannot be told nothing happened.
    AppFailure? unconfirmed;

    for (var attempt = 1; attempt <= _retryPolicy.maxAttempts; attempt++) {
      final result = await _attempt(uri, request, timeout);
      last = result;

      final failure = result.failureOrNull;
      if (failure == null) {
        final response = result.valueOrNull!;
        // A retryable status still counts as a delivered response; decide
        // whether to try again, but return this one if we stop.
        if (!_retryPolicy.isRetryable(
          request: request,
          failure: const NetworkFailure(),
          statusCode: response.statusCode,
        )) {
          return result;
        }
        if (attempt == _retryPolicy.maxAttempts) {
          return _withEarlier(request, result, unconfirmed);
        }
        await _sleep(
          _retryPolicy.delayFor(attempt, retryAfter: response.retryAfter),
        );
        continue;
      }

      if (failure.outcomeUnknown) unconfirmed ??= failure;
      if (!_retryPolicy.isRetryable(request: request, failure: failure)) {
        return _withEarlier(request, result, unconfirmed);
      }
      if (attempt == _retryPolicy.maxAttempts) {
        return _withEarlier(request, result, unconfirmed);
      }
      await _sleep(_retryPolicy.delayFor(attempt));
    }

    return _withEarlier(request, last!, unconfirmed);
  }

  /// The last attempt's result, unless it would hide an earlier attempt of a
  /// write that may have arrived.
  ///
  /// A timed-out write retried into a dead connection ends on "could not
  /// connect"; reporting only that would let a screen say nothing was sent
  /// about a request the office may already hold. Reads are exempt: whether a
  /// `GET` arrived changes nothing.
  static Result<ApiHttpResponse> _withEarlier(
    ApiRequest request,
    Result<ApiHttpResponse> last,
    AppFailure? unconfirmed,
  ) {
    if (unconfirmed == null || request.method.isSafe) return last;
    if (last.failureOrNull?.outcomeUnknown ?? false) return last;
    return Err<ApiHttpResponse>(unconfirmed);
  }

  Future<Result<ApiHttpResponse>> _attempt(
    Uri uri,
    ApiRequest request,
    Duration timeout,
  ) async {
    try {
      final http.BaseRequest outgoing;
      final List<MultipartFile> parts = <MultipartFile>[
        if (request.file != null) request.file!,
        ...request.files,
      ];
      if (parts.isNotEmpty) {
        // Content-Type is left to `package:http` so it can generate the
        // boundary. Setting it by hand produces a body the server cannot parse
        // and a 400 that looks like a validation failure.
        final multipart = http.MultipartRequest(request.method.wireValue, uri)
          ..headers.addAll(
            <String, String>{...request.headers}..remove('Content-Type'),
          )
          ..files.addAll(
            parts.map(
              (MultipartFile part) => http.MultipartFile.fromBytes(
                part.field,
                part.bytes,
                filename: part.filename,
                contentType: MediaType.parse(part.mimeType),
              ),
            ),
          );
        if (request.body is Map<String, dynamic>) {
          // `value.toString()`, and it used to be `'\$value'` — a backslash-
          // escaped dollar, so every text field alongside a file was sent as the
          // literal five characters `$value`.
          //
          // Latent until now: no repository sent a body with a file, so nothing
          // exercised this line. The first caller to do so was the KYC document
          // upload, which would have sent `type=$value` and met a 422 the
          // resident could do nothing about, on the screen that decides whether
          // they ever become Verified.
          (request.body! as Map<String, dynamic>).forEach((key, value) {
            if (value != null) multipart.fields[key] = value.toString();
          });
        }
        outgoing = multipart;
      } else {
        outgoing = http.Request(request.method.wireValue, uri)
          ..headers.addAll(request.headers);
        if (request.body != null) {
          (outgoing as http.Request).body = jsonEncode(request.body);
        }
      }

      final streamed = await _client.send(outgoing).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      final String type = (response.headers['content-type'] ?? '')
          .toLowerCase();
      final bool image = type.startsWith('image/');
      // An image has no charset that round-trips through a String. Keep the
      // bytes and leave the text body empty so a JPEG is not decoded as text.
      String text = '';
      if (!image) {
        try {
          text = response.body;
        } on FormatException {
          text = '';
        }
      }

      return Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: response.statusCode,
          body: text,
          bodyBytes: image ? response.bodyBytes : null,
          // Header names are lower-cased by `package:http`; ApiHttpResponse
          // reads them that way.
          headers: response.headers,
        ),
      );
    } on TimeoutException {
      return const Err<ApiHttpResponse>(
        TimeoutFailure(debugMessage: 'Request exceeded its timeout budget.'),
      );
    } on SocketException catch (error) {
      // No route, DNS failure and a refused connection happen before the
      // request is written. A reset or a broken pipe may happen after.
      return Err<ApiHttpResponse>(
        NetworkFailure(
          mayHaveArrived: !failedBeforeSending(error),
          debugMessage: 'Socket error: ${error.osError?.message}',
        ),
      );
    } on HandshakeException catch (error) {
      // TLS failure. Reported as a network failure to the resident, but kept
      // distinct in the debug message: a handshake failure on a government
      // endpoint deserves a different investigation from a dropped connection.
      // The handshake comes before the request, so nothing was sent.
      return Err<ApiHttpResponse>(
        NetworkFailure(debugMessage: 'TLS handshake failed: ${error.message}'),
      );
    } on http.ClientException catch (error) {
      // `package:http` raises this for a connection closed mid-exchange
      // ("Connection closed before full header was received"), after the
      // request was written.
      return Err<ApiHttpResponse>(
        NetworkFailure(
          mayHaveArrived: true,
          debugMessage: 'HTTP client error: ${error.message}',
        ),
      );
    } on Object catch (error) {
      return Err<ApiHttpResponse>(
        UnexpectedFailure(
          debugContext: 'HttpApiTransport.send',
          error: error,
          debugMessage: 'Unhandled transport error.',
        ),
      );
    }
  }

  /// Builds the absolute URL, preserving the configured base path.
  Uri _resolve(ApiRequest request) {
    final basePath = _config.apiBaseUri.path.endsWith('/')
        ? _config.apiBaseUri.path
        : '${_config.apiBaseUri.path}/';
    final relative = request.path.startsWith('/')
        ? request.path.substring(1)
        : request.path;
    return _config.apiBaseUri.replace(
      path: '$basePath$relative',
      queryParameters: request.query.isEmpty ? null : request.query,
    );
  }

  void close() => _client.close();
}

/// Whether [error] happened while connecting, before any of the request was
/// written.
///
/// ---
///
/// **Only a failure this function is sure of counts as "not sent".** The Dart
/// runtime names its connect failures — `Failed host lookup` and
/// `Connection failed` — and a refused or unreachable destination carries an
/// errno that a connected socket does not produce. Everything else, a reset or
/// a broken pipe above all, may come after the request left the phone, and is
/// reported as possibly arrived. A guess in that direction costs a sentence
/// saying "we could not confirm"; a guess the other way tells a resident
/// nothing was sent about a request the office holds.
@visibleForTesting
bool failedBeforeSending(SocketException error) {
  final String message = error.message;
  if (message.startsWith('Failed host lookup') ||
      message.startsWith('Connection failed') ||
      message.startsWith('Connection attempt cancelled')) {
    return true;
  }
  final int? code = error.osError?.errorCode;
  return code != null && _connectErrnos.contains(code);
}

/// Refused, network unreachable, host unreachable and network down: answers
/// to a connection attempt, never to a request on an open socket.
final Set<int> _connectErrnos = Platform.isIOS || Platform.isMacOS
    ? const <int>{61, 51, 65, 50}
    : Platform.isWindows
    ? const <int>{10061, 10051, 10065, 10050}
    : const <int>{111, 101, 113, 100};
