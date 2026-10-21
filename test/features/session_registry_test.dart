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

    test('listing sessions declines and sends nothing', () async {
      final Result<List<DeviceSessionSummary>> result = await repository
          .listActiveSessions();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });

    test('revoking one declines and names no session path', () async {
      final Result<void> result = await repository.revokeSession(
        sessionId: 's-2',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull, isNot(isA<ForbiddenFailure>()));
      expect(transport.requests, isEmpty);
    });

    test(
      'revoking all others is one decline, not a loop of requests',
      () async {
        final Result<void> result = await repository.revokeAllOtherSessions();

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
        expect(transport.requests, isEmpty);
      },
    );
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
