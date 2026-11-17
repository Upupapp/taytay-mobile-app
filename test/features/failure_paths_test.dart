import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/events/data/event_api_repository.dart';
import 'package:taytay_resident/features/events/domain/event_registration.dart';

/// The failure paths TAB 23 names, tested deliberately rather than hoped for.
///
/// ---
///
/// **These are the seven the Master Command lists**, and they are listed because
/// they are the ones thirteen newly wired repositories are most likely to get
/// wrong: an expired token mid-journey, a revoked session, network loss
/// mid-upload, a duplicate submit, a capacity race, an oversized upload
/// *including* the proxy rejection that does not look like one, and rate
/// limiting on OTP.
///
/// The two upload paths were tested on the requirements page's repository,
/// which declined without sending; it went with the `/requests` pages (D-225).
///
/// What they have in common is that none of them is reachable by using the app
/// normally. Each needs a server behaving badly on purpose, which is exactly why
/// they go untested until something happens to a resident.
class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> ok(Object data, {int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

Result<ApiHttpResponse> apiError(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{'code': code, 'message': 'operator text'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

void main() {
  group('an expired token mid-journey ends the session exactly once', () {
    test(
      'a 401 partway through a journey invalidates, and only once',
      () async {
        var invalidations = 0;
        final AuthCoordinator coordinator = AuthCoordinator(
          onSessionInvalidated: () async => invalidations++,
        );
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          ok(<Object?>[]),
          apiError(401, 'UNAUTHENTICATED'),
          apiError(401, 'UNAUTHENTICATED'),
        ]);
        final ApiClient client = ApiClient(
          config: config(),
          transport: transport,
          accessTokenProvider: () async => 'tok',
          authCoordinator: coordinator,
          onUnauthenticated: () async => invalidations++,
        );

        // The journey: a list loads, then the token dies partway through.
        await client.send<void>(
          method: HttpMethod.get,
          path: 'me/cases',
          authenticated: true,
          decode: (_) {},
        );
        await Future.wait<void>(<Future<void>>[
          client
              .send<void>(
                method: HttpMethod.get,
                path: 'me/notifications',
                authenticated: true,
                decode: (_) {},
              )
              .then((_) {}),
          client
              .send<void>(
                method: HttpMethod.get,
                path: 'me/profile',
                authenticated: true,
                decode: (_) {},
              )
              .then((_) {}),
        ]);

        // Two screens noticed; the resident is signed out once. Thirteen
        // repositories each pulling the session down independently is the
        // stampede this coordinator exists to prevent.
        expect(invalidations, 1);
      },
    );
  });

  group('a revoked session is refused, not retried into', () {
    test('an authenticated request with no token never reaches the wire', () async {
      // After revocation the store is cleared, so the provider has nothing. The
      // request must not go out anonymously: that produces a misleading 401 and,
      // worse, a request that looks deliberately anonymous in an audit log.
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final ApiClient client = ApiClient(
        config: config(),
        transport: transport,
        accessTokenProvider: () async => null,
      );

      final Result<void> result = await client.send<void>(
        method: HttpMethod.get,
        path: 'me/cases',
        authenticated: true,
        decode: (_) {},
      );

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(transport.requests, isEmpty);
    });
  });

  group('the capacity race resolves as an outcome, not a fault', () {
    test(
      'two registrations for one place: one confirmed, one told why',
      () async {
        final EventApiRepository first = EventApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: _Scripted(<Result<ApiHttpResponse>>[
              ok(<String, Object?>{
                'outcome': 'registered',
                'words': 'You are registered.',
                'registration': <String, Object?>{
                  'id': 'reg-1',
                  'event_id': 'e-1',
                  'reference': 'ER-2026-000001',
                  'state': 'registered',
                  'registered_at': '2026-09-01T00:00:00Z',
                  'attendance': null,
                  'can_cancel': true,
                  'instructions': null,
                },
              }, status: 201),
            ]),
            accessTokenProvider: () async => 'tok',
          ),
        );
        final EventApiRepository second = EventApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: _Scripted(<Result<ApiHttpResponse>>[
              // The last place went inside the server's lock on the event's
              // row. Losing the race is a 200 with an outcome, not an error.
              ok(<String, Object?>{
                'outcome': 'full',
                'words': 'Every place was taken.',
                'registration': null,
              }),
            ]),
            accessTokenProvider: () async => 'tok',
          ),
        );

        final List<Result<RegistrationAttempt>> results =
            await Future.wait<Result<RegistrationAttempt>>(
              <Future<Result<RegistrationAttempt>>>[
                first.register(
                  eventId: 'e-1',
                  answers: const <String, Object?>{},
                  consentKeys: const <String>[],
                  idempotencyKey: 'a',
                ),
                second.register(
                  eventId: 'e-1',
                  answers: const <String, Object?>{},
                  consentKeys: const <String>[],
                  idempotencyKey: 'b',
                ),
              ],
            );

        // Backend `580acbb` serves registration (D-191). One tap holds the
        // place; the other reads a calm outcome rather than a fault.
        expect(
          results.every((Result<RegistrationAttempt> r) => r.isOk),
          isTrue,
        );
        expect(
          results.first.valueOrNull?.outcome,
          RegistrationOutcome.registered,
        );
        expect(results.first.valueOrNull?.isHeld, isTrue);
        expect(results.last.valueOrNull?.outcome, RegistrationOutcome.full);
        expect(results.last.valueOrNull?.isHeld, isFalse);
        expect(
          results.last.valueOrNull?.residentMessage.toLowerCase(),
          isNot(contains('went wrong')),
        );
      },
    );
  });
}
