import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
        if (attempt == _retryPolicy.maxAttempts) return result;
        await _sleep(
          _retryPolicy.delayFor(attempt, retryAfter: response.retryAfter),
        );
        continue;
      }

      if (!_retryPolicy.isRetryable(request: request, failure: failure)) {
        return result;
      }
      if (attempt == _retryPolicy.maxAttempts) return result;
      await _sleep(_retryPolicy.delayFor(attempt));
    }

    return last!;
  }

  Future<Result<ApiHttpResponse>> _attempt(
    Uri uri,
    ApiRequest request,
    Duration timeout,
  ) async {
    try {
      final http.BaseRequest outgoing;
      final MultipartFile? file = request.file;
      if (file != null) {
        // Content-Type is left to `package:http` so it can generate the
        // boundary. Setting it by hand produces a body the server cannot parse
        // and a 400 that looks like a validation failure.
        final multipart = http.MultipartRequest(request.method.wireValue, uri)
          ..headers.addAll(
            <String, String>{...request.headers}..remove('Content-Type'),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              file.field,
              file.bytes,
              filename: file.filename,
              contentType: MediaType.parse(file.mimeType),
            ),
          );
        if (request.body is Map<String, dynamic>) {
          (request.body! as Map<String, dynamic>).forEach((key, value) {
            if (value != null) multipart.fields[key] = '\$value';
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

      return Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: response.statusCode,
          body: response.body,
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
      // No route, DNS failure, connection refused.
      return Err<ApiHttpResponse>(
        NetworkFailure(debugMessage: 'Socket error: ${error.osError?.message}'),
      );
    } on HandshakeException catch (error) {
      // TLS failure. Reported as a network failure to the resident, but kept
      // distinct in the debug message: a handshake failure on a government
      // endpoint deserves a different investigation from a dropped connection.
      return Err<ApiHttpResponse>(
        NetworkFailure(debugMessage: 'TLS handshake failed: ${error.message}'),
      );
    } on http.ClientException catch (error) {
      return Err<ApiHttpResponse>(
        NetworkFailure(debugMessage: 'HTTP client error: ${error.message}'),
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
