import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/http_api_transport.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Records the delays the transport asked for, without spending them.
class _Clock {
  final List<Duration> slept = <Duration>[];

  Future<void> sleep(Duration duration) async => slept.add(duration);
}

void main() {
  group('multipart', () {
    test(
      'a text field beside a file carries its value, not the word value',
      () async {
        // THE DEFECT THIS EXISTS FOR. The line read `multipart.fields[key] =
        // '\$value'` — a backslash-escaped dollar, so every text field sent
        // alongside a file was the literal five characters `$value`.
        //
        // It survived because nothing exercised it: no repository sent a body
        // with a file until the KYC document upload (F28), which would have sent
        // `type=$value` and met a 422 the resident could do nothing about, on the
        // screen that decides whether they ever become Verified.
        late String seenBody;
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((http.Request request) async {
            seenBody = request.body;
            return http.Response('{"data":{}}', 200);
          }),
        );

        await transport.send(
          ApiRequest(
            method: HttpMethod.post,
            path: 'me/kyc/documents',
            body: const <String, dynamic>{'type': 'identity-document'},
            file: MultipartFile(
              field: 'file',
              filename: 'philid.jpg',
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              mimeType: 'image/jpeg',
            ),
          ),
        );

        expect(seenBody, contains('identity-document'));
        expect(seenBody, isNot(contains(r'$value')));
        // And the file is still there — a fix that dropped it would pass the
        // assertions above.
        expect(seenBody, contains('philid.jpg'));
      },
    );
  });

  group('URL resolution', () {
    test('preserves the configured base path and appends the query', () async {
      late Uri seen;
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(
            jsonEncode(<String, Object?>{'data': null}),
            200,
          );
        }),
      );

      await transport.send(
        const ApiRequest(
          method: HttpMethod.get,
          path: 'services',
          query: <String, String>{'page': '2'},
        ),
      );

      expect(seen.toString(), 'https://example.test/api/v1/services?page=2');
    });

    test('a leading slash on the path does not escape the base', () async {
      late Uri seen;
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient((request) async {
          seen = request.url;
          return http.Response('{}', 200);
        }),
      );

      await transport.send(
        const ApiRequest(method: HttpMethod.get, path: '/health'),
      );

      expect(seen.path, '/api/v1/health');
    });
  });

  group('headers and body', () {
    test('sends the supplied headers and JSON-encodes the body', () async {
      late http.BaseRequest seen;
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient((request) async {
          seen = request;
          return http.Response('{}', 200);
        }),
      );

      await transport.send(
        const ApiRequest(
          method: HttpMethod.post,
          path: 'requests',
          headers: <String, String>{
            'X-Client-Channel': 'citizen-mobile',
            'Idempotency-Key': 'idem-1',
          },
          body: <String, Object?>{'service_code': 'CEDULA'},
        ),
      );

      expect(seen.method, 'POST');
      expect(seen.headers['X-Client-Channel'], 'citizen-mobile');
      expect(seen.headers['Idempotency-Key'], 'idem-1');
      expect((seen as http.Request).body, contains('CEDULA'));
    });
  });

  group('failure translation', () {
    test(
      'a socket error becomes a NetworkFailure, never an exception',
      () async {
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient(
            (_) async => throw const SocketException('no route'),
          ),
          retryPolicy: const RetryPolicy(maxAttempts: 1),
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'health'),
        );
        expect(result.failureOrNull, isA<NetworkFailure>());
      },
    );

    test(
      'a TLS handshake failure is reported distinctly in debug detail',
      () async {
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient(
            (_) async => throw const HandshakeException('bad certificate'),
          ),
          retryPolicy: const RetryPolicy(maxAttempts: 1),
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'health'),
        );
        final failure = result.failureOrNull!;
        expect(failure, isA<NetworkFailure>());
        expect(failure.debugMessage, contains('TLS handshake'));
        // The resident still sees plain connectivity copy, never TLS internals.
        expect(failure.residentMessage, isNot(contains('TLS')));
      },
    );

    test('a timeout becomes a TimeoutFailure', () async {
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return http.Response('{}', 200);
        }),
        retryPolicy: const RetryPolicy(maxAttempts: 1),
      );

      final result = await transport.send(
        const ApiRequest(
          method: HttpMethod.get,
          path: 'health',
          timeout: Duration(milliseconds: 10),
        ),
      );
      expect(result.failureOrNull, isA<TimeoutFailure>());
    });

    test(
      'an unexpected error is contained, not thrown at the caller',
      () async {
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async => throw StateError('boom')),
          retryPolicy: const RetryPolicy(maxAttempts: 1),
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'health'),
        );
        expect(result.failureOrNull, isA<UnexpectedFailure>());
      },
    );
  });

  group('retry behaviour', () {
    test(
      'a GET is retried up to the attempt limit and then gives up',
      () async {
        var calls = 0;
        final clock = _Clock();
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async {
            calls++;
            throw const SocketException('flaky');
          }),
          sleep: clock.sleep,
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'services'),
        );

        expect(calls, 3, reason: 'default maxAttempts');
        expect(clock.slept, hasLength(2), reason: 'one sleep between attempts');
        expect(result.failureOrNull, isA<NetworkFailure>());
      },
    );

    test(
      'a transient failure followed by success returns the success',
      () async {
        var calls = 0;
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async {
            calls++;
            if (calls == 1) throw const SocketException('flaky');
            return http.Response(
              jsonEncode(<String, Object?>{
                'data': <String, Object?>{'ok': true},
              }),
              200,
            );
          }),
          sleep: (_) async {},
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'services'),
        );

        expect(calls, 2);
        expect(result.valueOrNull?.statusCode, 200);
      },
    );

    test(
      'an unkeyed POST is never retried, however transient the failure',
      () async {
        // The whole point of the idempotency rule: a dropped connection after the
        // server committed is indistinguishable from one before.
        var calls = 0;
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async {
            calls++;
            throw const SocketException('dropped mid-flight');
          }),
          sleep: (_) async {},
        );

        final result = await transport.send(
          const ApiRequest(method: HttpMethod.post, path: 'requests'),
        );

        expect(calls, 1, reason: 'a second application must never be created');
        expect(result.failureOrNull, isA<NetworkFailure>());
      },
    );

    test('a POST carrying an Idempotency-Key is retried', () async {
      var calls = 0;
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient((_) async {
          calls++;
          if (calls < 3) throw const SocketException('flaky');
          return http.Response('{"data":null}', 201);
        }),
        sleep: (_) async {},
      );

      final result = await transport.send(
        const ApiRequest(
          method: HttpMethod.post,
          path: 'requests',
          headers: <String, String>{'Idempotency-Key': 'idem-1'},
        ),
      );

      expect(calls, 3);
      expect(result.valueOrNull?.statusCode, 201);
    });

    test('a 503 is retried; a 500 is not', () async {
      Future<int> attemptsFor(int status) async {
        var calls = 0;
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async {
            calls++;
            return http.Response('{"error":{"code":"X"}}', status);
          }),
          sleep: (_) async {},
        );
        await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'services'),
        );
        return calls;
      }

      expect(await attemptsFor(503), 3);
      expect(
        await attemptsFor(500),
        1,
        reason: 'the application saw the request; repeating repeats the fault',
      );
      expect(await attemptsFor(422), 1);
      expect(await attemptsFor(401), 1, reason: '401 is the auth layer\'s job');
    });

    test(
      'a 429 honours Retry-After rather than the computed backoff',
      () async {
        final clock = _Clock();
        var calls = 0;
        final transport = HttpApiTransport(
          config: config(),
          client: MockClient((_) async {
            calls++;
            return http.Response(
              '{"error":{"code":"RATE_LIMITED"}}',
              429,
              headers: <String, String>{'retry-after': '4'},
            );
          }),
          sleep: clock.sleep,
        );

        await transport.send(
          const ApiRequest(method: HttpMethod.get, path: 'services'),
        );

        expect(calls, 3);
        expect(clock.slept, everyElement(const Duration(seconds: 4)));
      },
    );

    test('the final retryable response is returned, not swallowed', () async {
      final transport = HttpApiTransport(
        config: config(),
        client: MockClient(
          (_) async => http.Response('{"error":{"code":"X"}}', 503),
        ),
        sleep: (_) async {},
      );

      final result = await transport.send(
        const ApiRequest(method: HttpMethod.get, path: 'services'),
      );

      expect(
        result.isOk,
        isTrue,
        reason: 'a delivered 503 is still a response',
      );
      expect(result.valueOrNull?.statusCode, 503);
    });
  });
}
