import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_envelope.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/request_context.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';

/// Records what it was asked to send and replies with a canned response.
class _RecordingTransport implements ApiTransport {
  _RecordingTransport(this.response);

  final Result<ApiHttpResponse> response;
  final List<ApiRequest> sent = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    sent.add(request);
    return response;
  }
}

ApiHttpResponse _json(
  int status,
  Object body, {
  Map<String, String> headers = const <String, String>{},
}) => ApiHttpResponse(
  statusCode: status,
  body: jsonEncode(body),
  headers: headers,
);

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

void main() {
  group('RequestContext headers', () {
    test('always declares the citizen-mobile channel and a request id', () {
      const context = RequestContext(requestId: 'abc-123');
      final headers = context.headers();

      expect(headers['X-Client-Channel'], 'citizen-mobile');
      expect(headers['X-Request-Id'], 'abc-123');
      expect(headers['Accept'], 'application/json');
    });

    test('omits Authorization for a guest and sets it for a resident', () {
      expect(
        const RequestContext(
          requestId: 'r',
        ).headers().containsKey('Authorization'),
        isFalse,
      );
      expect(
        const RequestContext(
          requestId: 'r',
          bearerToken: 'token-value',
        ).headers()['Authorization'],
        'Bearer token-value',
      );
    });

    test('never sends an authority-shaped header', () {
      // ADR 0002 §4: any role/permission claim from a client is ignored
      // server-side. Sending one anyway would invite a reader to trust it.
      final headers = const RequestContext(
        requestId: 'r',
        bearerToken: 't',
      ).headers(hasJsonBody: true, idempotencyKey: 'idem-1');

      for (final key in headers.keys.map((k) => k.toLowerCase())) {
        expect(
          key,
          isNot(
            anyOf(contains('role'), contains('admin'), contains('permission')),
          ),
        );
      }
      expect(headers['Idempotency-Key'], 'idem-1');
      expect(headers['Content-Type'], 'application/json');
    });

    test('never renders the token in toString', () {
      expect(
        const RequestContext(requestId: 'r', bearerToken: 'secret').toString(),
        isNot(contains('secret')),
      );
    });

    test('generated ids fit the server-accepted shape', () {
      final pattern = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
      for (var i = 0; i < 50; i++) {
        expect(pattern.hasMatch(generateRequestId()), isTrue);
      }
      expect(generateRequestId(), isNot(generateRequestId()));
    });
  });

  group('ApiEnvelopeDecoder success', () {
    test('reads data and meta.request_id', () {
      final result = ApiEnvelopeDecoder.decode<Map<String, dynamic>>(
        _json(200, <String, dynamic>{
          'data': <String, dynamic>{'id': '9b1f', 'code': 'BRGY_CLEARANCE'},
          'meta': <String, dynamic>{'request_id': '01JB'},
        }),
        (data) => data! as Map<String, dynamic>,
      );

      final envelope = result.valueOrNull!;
      expect(envelope.data['code'], 'BRGY_CLEARANCE');
      expect(envelope.requestId, '01JB');
    });

    test('reads pagination when present', () {
      final result = ApiEnvelopeDecoder.decode<List<Object?>>(
        _json(200, <String, dynamic>{
          'data': <Object?>[],
          'meta': <String, dynamic>{
            'request_id': 'x',
            'pagination': <String, dynamic>{
              'page': 2,
              'per_page': 25,
              'total': 138,
              'total_pages': 6,
              'has_more': true,
            },
          },
        }),
        (data) => data! as List<Object?>,
      );

      final pagination = result.valueOrNull!.pagination!;
      expect(pagination.page, 2);
      expect(pagination.total, 138);
      expect(pagination.hasMore, isTrue);
    });

    test('ignores unknown fields rather than failing', () {
      // conventions §1: "Clients must ignore unknown fields."
      final result = ApiEnvelopeDecoder.decode<Map<String, dynamic>>(
        _json(200, <String, dynamic>{
          'data': <String, dynamic>{'status': 'ok', 'brand_new_field': 42},
          'meta': <String, dynamic>{'request_id': 'x', 'something_new': true},
        }),
        (data) => data! as Map<String, dynamic>,
      );
      expect(result.isOk, isTrue);
    });

    test('a 204 with no body decodes to a void result', () {
      final result = ApiEnvelopeDecoder.decode<void>(
        const ApiHttpResponse(statusCode: 204, body: ''),
        (_) {},
      );
      expect(result.isOk, isTrue);
    });

    test('a non-JSON body is a contract failure, not a server error', () {
      final result = ApiEnvelopeDecoder.decode<Object?>(
        const ApiHttpResponse(
          statusCode: 200,
          body: '<html><body>Gateway</body></html>',
        ),
        (data) => data,
      );
      expect(result.failureOrNull, isA<ContractFailure>());
    });
  });

  group('ApiEnvelopeDecoder errors', () {
    test('decodes the canonical error envelope', () {
      final result = ApiEnvelopeDecoder.decode<Object?>(
        _json(403, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'FORBIDDEN',
            'message': 'internal detail that must not be shown',
            'request_id': '01JB',
          },
        }),
        (data) => data,
      );

      final failure = result.failureOrNull!;
      expect(failure, isA<ForbiddenFailure>());
      expect(failure.requestId, '01JB');
      expect(failure.debugMessage, contains('internal detail'));
      expect(failure.residentMessage, isNot(contains('internal detail')));
    });

    test('decodes validation details into field errors', () {
      final result = ApiEnvelopeDecoder.decode<Object?>(
        _json(422, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'VALIDATION_FAILED',
            'message': 'The given data was invalid.',
            'details': <String, dynamic>{
              'mobile_number': <String>['The mobile number field is required.'],
            },
            'request_id': 'r',
          },
        }),
        (data) => data,
      );

      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.fieldErrors['mobile_number'], hasLength(1));
    });

    test('reads Retry-After from the response headers on a 429', () {
      final result = ApiEnvelopeDecoder.decode<Object?>(
        _json(
          429,
          <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'RATE_LIMITED',
              'request_id': 'r',
            },
          },
          headers: <String, String>{'retry-after': '45'},
        ),
        (data) => data,
      );

      final failure = result.failureOrNull! as RateLimitedFailure;
      expect(failure.retryAfter, const Duration(seconds: 45));
    });

    test('falls back to the status when the body is not an envelope', () {
      final result = ApiEnvelopeDecoder.decode<Object?>(
        const ApiHttpResponse(statusCode: 502, body: 'upstream down'),
        (data) => data,
      );
      // This test's name always said "falls back to the status" and its
      // assertion said the opposite — ContractFailure, which is what the decoder
      // returned for *any* unparseable body regardless of status. TAB 23 found
      // what that cost on the upload path: a reverse proxy answering 413 with an
      // HTML page became "something went wrong" instead of "that file is too
      // large".
      //
      // A gateway 502 with no envelope is a server problem and reads as one.
      // The contract-breach reading is reserved for an unparseable body on a
      // *success*, which is the captive-portal case.
      // A ServerFailure, and deliberately no claim about `isTemporary`: only a
      // 503 carries that today, and widening it here would be changing the retry
      // taxonomy from inside a decoder test.
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('an unparseable body on a 200 is still a contract breach', () {
      // The captive-portal case: a login page arriving where the envelope should
      // be. Reporting it as a server fault sends somebody to a barangay hall
      // over their own wifi.
      final result = ApiEnvelopeDecoder.decode<Object?>(
        const ApiHttpResponse(
          statusCode: 200,
          body: '<html>Sign in to this network</html>',
        ),
        (data) => data,
      );
      expect(result.failureOrNull, isA<ContractFailure>());
    });
  });

  group('ApiClient', () {
    test('resolves paths against the configured base URI', () {
      final client = ApiClient(
        config: _config(),
        transport: _RecordingTransport(
          Ok<ApiHttpResponse>(_json(200, <String, dynamic>{'data': null})),
        ),
      );

      expect(
        client.resolve('health').toString(),
        'https://example.test/api/v1/health',
      );
      expect(
        client.resolve('/health', <String, String>{'page': '2'}).toString(),
        'https://example.test/api/v1/health?page=2',
      );
    });

    test('refuses to send an authenticated request with no token', () async {
      final transport = _RecordingTransport(
        Ok<ApiHttpResponse>(_json(200, <String, dynamic>{'data': null})),
      );
      final client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => null,
      );

      final result = await client.send<Object?>(
        method: HttpMethod.get,
        path: 'residents/me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(transport.sent, isEmpty, reason: 'nothing should reach the wire');
    });

    test('notifies the session exactly once on a 401', () async {
      var unauthenticatedCalls = 0;
      final client = ApiClient(
        config: _config(),
        transport: _RecordingTransport(
          Ok<ApiHttpResponse>(
            _json(401, <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'UNAUTHENTICATED',
                'request_id': 'r',
              },
            }),
          ),
        ),
        accessTokenProvider: () async => 'token',
        onUnauthenticated: () async => unauthenticatedCalls++,
      );

      final result = await client.send<Object?>(
        method: HttpMethod.get,
        path: 'residents/me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(unauthenticatedCalls, 1);
    });

    test('does not end the session on a 403', () async {
      var unauthenticatedCalls = 0;
      final client = ApiClient(
        config: _config(),
        transport: _RecordingTransport(
          Ok<ApiHttpResponse>(
            _json(403, <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'FORBIDDEN',
                'request_id': 'r',
              },
            }),
          ),
        ),
        accessTokenProvider: () async => 'token',
        onUnauthenticated: () async => unauthenticatedCalls++,
      );

      await client.send<Object?>(
        method: HttpMethod.get,
        path: 'residents/me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(unauthenticatedCalls, 0);
    });

    test('an unauthenticated call carries no Authorization header', () async {
      final transport = _RecordingTransport(
        Ok<ApiHttpResponse>(
          _json(200, <String, dynamic>{
            'data': <String, dynamic>{'status': 'ok'},
          }),
        ),
      );
      final client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token-that-must-not-be-sent',
      );

      await client.send<Object?>(
        method: HttpMethod.get,
        path: 'health',
        authenticated: false,
        decode: (data) => data,
      );

      expect(
        transport.sent.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('propagates a transport failure untouched', () async {
      final client = ApiClient(
        config: _config(),
        transport: _RecordingTransport(
          const Err<ApiHttpResponse>(NetworkFailure()),
        ),
      );

      final result = await client.send<Object?>(
        method: HttpMethod.get,
        path: 'health',
        authenticated: false,
        decode: (data) => data,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('UnconfiguredApiTransport', () {
    test('reports a network failure rather than pretending to work', () async {
      final result = await const UnconfiguredApiTransport().send(
        const ApiRequest(method: HttpMethod.get, path: 'health'),
      );
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
