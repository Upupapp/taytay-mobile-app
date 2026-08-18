import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/features/auth/data/session_api_repository.dart';
import 'package:taytay_resident/features/auth/domain/device_session_repository.dart';

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

Result<ApiHttpResponse> ok(Object body, {int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(body),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

Result<ApiHttpResponse> unauthorised() => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: 401,
    body: jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': 'UNAUTHENTICATED',
        'message': 'operator text',
      },
    }),
    headers: const <String, String>{'x-request-id': 'req-1'},
  ),
);

void main() {
  AppConfig config() => AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  );

  group('the session list answers "is somebody else signed in as me?"', () {
    late _Scripted transport;
    late SessionApiRepository repository;

    setUp(() {
      transport = _Scripted(<Result<ApiHttpResponse>>[]);
      repository = SessionApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: transport,
          accessTokenProvider: () async => 'tok',
        ),
      );
    });

    test('reads me/sessions and marks the current one', () async {
      transport.responses.add(
        ok(<String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'id': 's-1',
              'name': 'Ana\'s phone',
              'last_used_at': '2026-08-18T02:00:00Z',
              'expires_at': '2026-09-01T00:00:00Z',
              'current': true,
            },
            <String, Object?>{
              'id': 's-2',
              'name': 'Old handset',
              'last_used_at': '2026-07-01T02:00:00Z',
              'current': false,
            },
          ],
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<List<DeviceSessionSummary>> result = await repository
          .listActiveSessions();

      expect(transport.requests.single.path, 'me/sessions');
      final List<DeviceSessionSummary> sessions =
          (result as Ok<List<DeviceSessionSummary>>).value;
      expect(sessions, hasLength(2));
      expect(sessions.first.isCurrentDevice, isTrue);
      expect(sessions.last.label, 'Old handset');
      expect(sessions.last.lastSeenAt, isNotNull);
    });

    test('an unnamed session is labelled, never blank', () async {
      // A session a resident cannot recognise is one they dare not revoke.
      transport.responses.add(
        ok(<String, Object?>{
          'data': <Object?>[
            <String, Object?>{'id': 's-1', 'current': false},
          ],
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<List<DeviceSessionSummary>> result = await repository
          .listActiveSessions();
      expect(
        (result as Ok<List<DeviceSessionSummary>>).value.single.label,
        isNotEmpty,
      );
    });

    test(
      'the summary carries no movement data, whatever the server sends',
      () async {
        transport.responses.add(
          ok(<String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'id': 's-1',
                'name': 'Phone',
                'current': false,
                // None of this may survive into the app.
                'ip_address': '203.0.113.7',
                'user_agent': 'Dalvik/2.1.0',
                'city': 'Taytay',
                'latitude': 14.5691,
              },
            ],
            'meta': <String, Object?>{'request_id': 'req-1'},
          }),
        );

        final Result<List<DeviceSessionSummary>> result = await repository
            .listActiveSessions();
        final String rendered = (result as Ok<List<DeviceSessionSummary>>)
            .value
            .single
            .toString();

        for (final String leak in <String>[
          '203.0.113.7',
          'Dalvik',
          'Taytay',
          '14.5',
        ]) {
          expect(rendered, isNot(contains(leak)), reason: leak);
        }
      },
    );

    test('revoking one names it in the path', () async {
      transport.responses.add(
        ok(<String, Object?>{'data': null, 'meta': <String, Object?>{}}),
      );
      await repository.revokeSession(sessionId: 's-2');
      expect(transport.requests.single.path, 'me/sessions/s-2');
      expect(transport.requests.single.method, HttpMethod.delete);
    });

    test('revoking all others is a different request, not a loop', () async {
      // A loop would be a partial success on a dropped connection: some phones
      // signed out, some not, and no way for the resident to tell which.
      transport.responses.add(
        ok(<String, Object?>{'data': null, 'meta': <String, Object?>{}}),
      );
      await repository.revokeAllOtherSessions();
      expect(transport.requests.single.path, 'me/sessions/revoke-all');
      expect(transport.requests.single.method, HttpMethod.post);
    });

    test("someone else's session is not found, never forbidden", () async {
      // Confirming that a session id exists but belongs to somebody else is
      // itself a disclosure. The server answers 404 and the app must not
      // translate that into "you may not".
      transport.responses.add(
        ok(<String, Object?>{
          'error': <String, Object?>{
            'code': 'NOT_FOUND',
            'message': 'That session was not found.',
          },
        }, status: 404),
      );

      final Result<void> result = await repository.revokeSession(
        sessionId: 'someone-elses',
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(result.failureOrNull, isNot(isA<ForbiddenFailure>()));
    });
  });

  group('a revoked session ends this one, exactly once', () {
    test('ten concurrent 401s produce one invalidation', () async {
      // The classic failure is a stampede: thirteen repositories each noticing a
      // 401 and each pulling the session down. The coordinator serialises it.
      //
      // The Master Command asks for "exactly one refresh". There is no refresh
      // endpoint in this contract and inventing one would be a path the server
      // never agreed to — so the guarantee is the same shape with the honest
      // verb: exactly one sign-out.
      var invalidations = 0;
      final AuthCoordinator coordinator = AuthCoordinator(
        onSessionInvalidated: () async => invalidations++,
      );

      final _Scripted transport = _Scripted(
        List<Result<ApiHttpResponse>>.generate(10, (_) => unauthorised()),
      );
      final ApiClient client = ApiClient(
        config: config(),
        transport: transport,
        accessTokenProvider: () async => 'tok',
        authCoordinator: coordinator,
        onUnauthenticated: () async => invalidations++,
      );

      await Future.wait<void>(
        List<Future<void>>.generate(
          10,
          (_) => client
              .send<void>(
                method: HttpMethod.get,
                path: 'me/sessions',
                authenticated: true,
                decode: (_) {},
              )
              .then((_) {}),
        ),
      );

      expect(invalidations, 1);
      expect(coordinator.isRefreshing, isFalse);
    });

    test('the session is cleared from disk, not just from memory', () async {
      // A residual session on a shared phone is a personal data leak to whoever
      // holds it next, and shared phones are ordinary in this user base.
      final InMemorySessionStore store = InMemorySessionStore();
      await store.write(
        const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
            displayName: 'Ana',
          ),
          accessToken: 'tok',
        ),
      );

      final SessionController controller = SessionController(store: store);
      await controller.restore();
      expect(controller.state, isA<AuthenticatedSession>());

      await controller.handleUnauthenticated();

      expect(controller.state, isA<GuestSession>());
      expect(await store.read(), isNull);
      // And nothing about the resident survives on the controller.
      expect(controller.state.residentOrNull, isNull);
      expect(controller.toString(), isNot(contains('Ana')));
    });

    test('signing out clears the store even when the server refuses', () async {
      final InMemorySessionStore store = InMemorySessionStore();
      await store.write(
        const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'tok',
        ),
      );

      final SessionController controller = SessionController(store: store);
      await controller.restore();
      await controller.signOut();

      expect(await store.read(), isNull);
      expect(controller.state, isA<GuestSession>());
    });
  });
}
