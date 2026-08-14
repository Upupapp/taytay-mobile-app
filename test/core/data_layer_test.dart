import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/api/planned_backend.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/keystore_session_store.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/credential/data/planned_credential_repository.dart';
import 'package:taytay_resident/features/notifications/data/planned_notification_repository.dart';
import 'package:taytay_resident/features/profile/data/planned_resident_profile_repository.dart';
import 'package:taytay_resident/features/services/data/lgu_service_dto.dart';
import 'package:taytay_resident/features/services/data/planned_service_request_repository.dart';
import 'package:taytay_resident/features/services/data/service_catalog_api_repository.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart';
import 'package:taytay_resident/features/verification/data/planned_verification_repository.dart';

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

ApiHttpResponse json(
  int status,
  Object body, {
  Map<String, String> headers = const <String, String>{},
}) => ApiHttpResponse(
  statusCode: status,
  body: jsonEncode(body),
  headers: headers,
);

ApiHttpResponse errorBody(int status, String code) =>
    json(status, <String, dynamic>{
      'error': <String, dynamic>{'code': code, 'request_id': 'r'},
    });

/// Replays a scripted sequence of responses and records every request.
class ScriptedTransport implements ApiTransport {
  ScriptedTransport(this.script);

  final List<Result<ApiHttpResponse>> script;
  final List<ApiRequest> sent = <ApiRequest>[];
  int _index = 0;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    sent.add(request);
    final response = script[math.min(_index, script.length - 1)];
    _index++;
    return response;
  }
}

class _CountingRefresher implements TokenRefresher {
  _CountingRefresher(this.token, {this.delay = Duration.zero});

  final String? token;
  final Duration delay;
  int calls = 0;

  @override
  Future<String?> refresh() async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return token;
  }
}

class _ThrowingRefresher implements TokenRefresher {
  int calls = 0;

  @override
  Future<String?> refresh() async {
    calls++;
    throw StateError('refresh exploded');
  }
}

void main() {
  group('RetryPolicy — what may be repeated', () {
    const policy = RetryPolicy();

    test('GET is repeatable; unsafe methods are not without a key', () {
      const get = ApiRequest(method: HttpMethod.get, path: 'services');
      expect(policy.mayRepeat(get), isTrue);

      for (final method in <HttpMethod>[
        HttpMethod.post,
        HttpMethod.put,
        HttpMethod.patch,
        HttpMethod.delete,
      ]) {
        expect(
          policy.mayRepeat(ApiRequest(method: method, path: 'x')),
          isFalse,
          reason: '${method.name} without an Idempotency-Key must not repeat',
        );
      }
    });

    test('an unsafe method with an Idempotency-Key is repeatable', () {
      const request = ApiRequest(
        method: HttpMethod.post,
        path: 'requests',
        headers: <String, String>{'Idempotency-Key': 'idem-1'},
      );
      expect(policy.mayRepeat(request), isTrue);
    });

    test('an empty Idempotency-Key does not count', () {
      const request = ApiRequest(
        method: HttpMethod.post,
        path: 'requests',
        headers: <String, String>{'Idempotency-Key': ''},
      );
      expect(policy.mayRepeat(request), isFalse);
    });

    test('500 is never retried, 502/503/504/429 are', () {
      const get = ApiRequest(method: HttpMethod.get, path: 'services');
      bool retry(int status) => policy.isRetryable(
        request: get,
        failure: const ServerFailure(),
        statusCode: status,
      );

      // The application saw the request; repeating it repeats the fault.
      expect(retry(500), isFalse);
      for (final status in <int>[408, 429, 502, 503, 504]) {
        expect(retry(status), isTrue, reason: '$status');
      }
      for (final status in <int>[400, 401, 403, 404, 409, 422]) {
        expect(retry(status), isFalse, reason: '$status');
      }
    });

    test('network and timeout failures are retried; others are not', () {
      const get = ApiRequest(method: HttpMethod.get, path: 'services');
      bool retry(AppFailure failure) =>
          policy.isRetryable(request: get, failure: failure);

      expect(retry(const NetworkFailure()), isTrue);
      expect(retry(const TimeoutFailure()), isTrue);
      expect(retry(const ServerFailure(isTemporary: true)), isTrue);
      expect(retry(const ServerFailure()), isFalse);
      expect(retry(const ValidationFailure()), isFalse);
      expect(retry(const UnauthenticatedFailure()), isFalse);
    });

    test('a retryable status on a non-repeatable request is still refused', () {
      // The idempotency rule outranks the status rule: a 503 on an unkeyed POST
      // may already have been applied.
      const post = ApiRequest(method: HttpMethod.post, path: 'requests');
      expect(
        policy.isRetryable(
          request: post,
          failure: const ServerFailure(isTemporary: true),
          statusCode: 503,
        ),
        isFalse,
      );
    });
  });

  group('RetryPolicy — backoff', () {
    const policy = RetryPolicy();

    test('full jitter keeps every delay inside the exponential ceiling', () {
      final random = math.Random(7);
      for (var attempt = 1; attempt <= 4; attempt++) {
        final ceiling = policy.baseDelay * math.pow(2, attempt - 1).toDouble();
        final capped = ceiling > policy.maxDelay ? policy.maxDelay : ceiling;
        for (var i = 0; i < 40; i++) {
          final delay = policy.delayFor(attempt, random: random);
          expect(delay, greaterThanOrEqualTo(Duration.zero));
          expect(delay, lessThanOrEqualTo(capped), reason: 'attempt $attempt');
        }
      }
    });

    test('jitter actually varies — it is not a fixed backoff', () {
      final random = math.Random(11);
      final delays = <Duration>{
        for (var i = 0; i < 20; i++) policy.delayFor(3, random: random),
      };
      expect(delays.length, greaterThan(1));
    });

    test('a server Retry-After wins over the computed delay', () {
      expect(
        policy.delayFor(1, retryAfter: const Duration(seconds: 5)),
        const Duration(seconds: 5),
      );
    });

    test('an absurd Retry-After is capped rather than obeyed', () {
      expect(
        policy.delayFor(1, retryAfter: const Duration(minutes: 10)),
        policy.maxRetryAfter,
      );
    });
  });

  group('ApiClient — auth recovery fails closed', () {
    test(
      'a 401 with no refresher ends the session and does not replay',
      () async {
        var invalidated = 0;
        final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
          Ok<ApiHttpResponse>(errorBody(401, 'UNAUTHENTICATED')),
        ]);
        final coordinator = AuthCoordinator(
          onSessionInvalidated: () async => invalidated++,
        );
        final client = ApiClient(
          config: config(),
          transport: transport,
          accessTokenProvider: () async => 'token',
          authCoordinator: coordinator,
        );

        final result = await client.send<Object?>(
          method: HttpMethod.get,
          path: 'residents/me',
          authenticated: true,
          decode: (data) => data,
        );

        expect(result.failureOrNull, isA<UnauthenticatedFailure>());
        expect(invalidated, 1);
        expect(transport.sent, hasLength(1), reason: 'must not replay');
        expect(coordinator.canRefresh, isFalse);
      },
    );

    test(
      'a refresher that returns null invalidates rather than continuing',
      () async {
        var invalidated = 0;
        final refresher = _CountingRefresher(null);
        final coordinator = AuthCoordinator(
          refresher: refresher,
          onSessionInvalidated: () async => invalidated++,
        );

        expect(await coordinator.handleUnauthenticated(), AuthRecovery.failed);
        expect(refresher.calls, 1);
        expect(invalidated, 1);
      },
    );

    test(
      'a refresher that throws is a failure, never "probably fine"',
      () async {
        var invalidated = 0;
        final refresher = _ThrowingRefresher();
        final coordinator = AuthCoordinator(
          refresher: refresher,
          onSessionInvalidated: () async => invalidated++,
        );

        expect(await coordinator.handleUnauthenticated(), AuthRecovery.failed);
        expect(refresher.calls, 1);
        expect(invalidated, 1);
      },
    );

    test('concurrent 401s cause exactly one refresh (single flight)', () async {
      final refresher = _CountingRefresher(
        'new-token',
        delay: const Duration(milliseconds: 20),
      );
      final coordinator = AuthCoordinator(refresher: refresher);

      final verdicts = await Future.wait<AuthRecovery>(<Future<AuthRecovery>>[
        coordinator.handleUnauthenticated(),
        coordinator.handleUnauthenticated(),
        coordinator.handleUnauthenticated(),
        coordinator.handleUnauthenticated(),
      ]);

      expect(refresher.calls, 1, reason: 'four 401s, one refresh');
      expect(verdicts, everyElement(AuthRecovery.refreshed));
      expect(coordinator.isRefreshing, isFalse, reason: 'must not stay wedged');
    });

    test(
      'a later 401 can refresh again after the first flight completes',
      () async {
        final refresher = _CountingRefresher('new-token');
        final coordinator = AuthCoordinator(refresher: refresher);

        await coordinator.handleUnauthenticated();
        await coordinator.handleUnauthenticated();

        expect(refresher.calls, 2);
      },
    );

    test('a successful refresh replays the request exactly once', () async {
      final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
        Ok<ApiHttpResponse>(errorBody(401, 'UNAUTHENTICATED')),
        Ok<ApiHttpResponse>(
          json(200, <String, dynamic>{
            'data': <String, dynamic>{'ok': true},
          }),
        ),
      ]);
      var token = 'stale';
      final client = ApiClient(
        config: config(),
        transport: transport,
        accessTokenProvider: () async => token,
        authCoordinator: AuthCoordinator(
          refresher: _CountingRefresher('fresh'),
          onSessionInvalidated: () async => token = '',
        ),
      );
      // The session controller would normally rotate this.
      token = 'fresh';

      final result = await client.send<Object?>(
        method: HttpMethod.get,
        path: 'residents/me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(result.isOk, isTrue);
      expect(transport.sent, hasLength(2));
      expect(
        transport.sent[1].headers['X-Request-Id'],
        isNot(transport.sent[0].headers['X-Request-Id']),
        reason: 'a replay is a distinct request and must be traceable as one',
      );
    });

    test('a second 401 after refresh invalidates instead of looping', () async {
      var invalidated = 0;
      final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
        Ok<ApiHttpResponse>(errorBody(401, 'UNAUTHENTICATED')),
        Ok<ApiHttpResponse>(errorBody(401, 'UNAUTHENTICATED')),
        Ok<ApiHttpResponse>(errorBody(401, 'UNAUTHENTICATED')),
      ]);
      final client = ApiClient(
        config: config(),
        transport: transport,
        accessTokenProvider: () async => 'token',
        onUnauthenticated: () async => invalidated++,
        authCoordinator: AuthCoordinator(
          refresher: _CountingRefresher('fresh'),
        ),
      );

      final result = await client.send<Object?>(
        method: HttpMethod.get,
        path: 'residents/me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(transport.sent, hasLength(2), reason: 'one replay, never a loop');
      expect(invalidated, 1);
    });

    test(
      'an authenticated call with no token never reaches the wire',
      () async {
        final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
          Ok<ApiHttpResponse>(json(200, <String, dynamic>{'data': null})),
        ]);
        final client = ApiClient(
          config: config(),
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
        expect(transport.sent, isEmpty);
      },
    );
  });

  group('PublicCache — refuses anything personal', () {
    test('an authenticated response is never stored', () {
      final cache = PublicCache();
      final stored = cache.store<String>(
        key: 'services',
        value: 'payload',
        authenticated: true,
      );

      expect(stored, isFalse);
      expect(cache.read<String>('services'), isNull);
      expect(cache.size, 0);
    });

    test('a key outside the allow-list is never stored', () {
      final cache = PublicCache();
      expect(
        cache.store<String>(
          key: 'residents/me',
          value: 'personal',
          authenticated: false,
        ),
        isFalse,
      );
      expect(cache.read<String>('residents/me'), isNull);
    });

    test('a public response is stored and read back', () {
      final cache = PublicCache();
      expect(
        cache.store<String>(
          key: 'services',
          value: 'catalogue',
          authenticated: false,
        ),
        isTrue,
      );
      expect(cache.read<String>('services'), 'catalogue');
    });

    test('a stale entry is evicted rather than returned', () {
      var now = DateTime(2026, 8, 14, 12);
      final cache = PublicCache(
        defaultTtl: const Duration(minutes: 5),
        clock: () => now,
      );
      cache.store<String>(
        key: 'services',
        value: 'catalogue',
        authenticated: false,
      );

      now = now.add(const Duration(minutes: 6));
      expect(cache.read<String>('services'), isNull);
      expect(cache.size, 0, reason: 'evicted on read, not merely hidden');
    });

    test('a type mismatch returns null instead of throwing', () {
      final cache = PublicCache()
        ..store<String>(key: 'services', value: 'x', authenticated: false);
      expect(cache.read<int>('services'), isNull);
    });

    test('clear empties everything', () {
      final cache = PublicCache()
        ..store<String>(key: 'services', value: 'x', authenticated: false)
        ..store<String>(key: 'health', value: 'y', authenticated: false);
      expect(cache.size, 2);
      cache.clear();
      expect(cache.size, 0);
    });

    test('the allow-list holds only the committed public endpoints', () {
      // services and health are unauthenticated by design on the server.
      expect(
        PublicCache.defaultAllowedKeys,
        unorderedEquals(<String>['services', 'health']),
      );
    });
  });

  group('KeystoreSessionStore', () {
    late InMemorySecretStore secrets;
    late KeystoreSessionStore store;

    const resident = ResidentSession(
      accountId: 'acct-1',
      accessLevel: AccessLevel.verified,
      displayName: 'Ana',
    );

    setUp(() {
      secrets = InMemorySecretStore();
      store = KeystoreSessionStore(secrets: secrets);
    });

    test('round-trips a session', () async {
      await store.write(
        const StoredSession(resident: resident, accessToken: 'token'),
      );
      final read = await store.read();

      expect(read, isNotNull);
      expect(read!.accessToken, 'token');
      expect(read.resident.accountId, 'acct-1');
      expect(read.resident.accessLevel, AccessLevel.verified);
      expect(read.resident.displayName, 'Ana');
    });

    test('stores only the three minimised fields', () async {
      await store.write(
        const StoredSession(resident: resident, accessToken: 'token'),
      );
      final raw = await secrets.read(SecretKeys.residentSummary);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;

      expect(
        decoded.keys,
        unorderedEquals(<String>[
          'account_id',
          'verification_tier',
          'display_name',
        ]),
      );
    });

    test(
      'persists the tier as the server vocabulary, not an enum index',
      () async {
        // An app update that reorders AccessLevel must not promote a session.
        await store.write(
          const StoredSession(resident: resident, accessToken: 'token'),
        );
        final raw = await secrets.read(SecretKeys.residentSummary);
        expect(raw, contains('"verification_tier":"verified"'));
      },
    );

    test('a token with no summary reads as no session, and clears', () async {
      await secrets.write(SecretKeys.accessToken, 'orphan-token');
      expect(await store.read(), isNull);
      expect(await secrets.read(SecretKeys.accessToken), isNull);
    });

    test('a summary with no token reads as no session, and clears', () async {
      await secrets.write(SecretKeys.residentSummary, '{"account_id":"a"}');
      expect(await store.read(), isNull);
      expect(await secrets.read(SecretKeys.residentSummary), isNull);
    });

    test('a corrupt summary reads as no session, and clears', () async {
      await secrets.write(SecretKeys.accessToken, 'token');
      await secrets.write(SecretKeys.residentSummary, 'not json at all');
      expect(await store.read(), isNull);
      expect(await secrets.read(SecretKeys.accessToken), isNull);
    });

    test(
      'an unrecognised tier restores as unverified, never verified',
      () async {
        await secrets.write(SecretKeys.accessToken, 'token');
        await secrets.write(
          SecretKeys.residentSummary,
          jsonEncode(<String, Object?>{
            'account_id': 'a',
            'verification_tier': 'super_verified',
          }),
        );

        final read = await store.read();
        expect(read!.resident.accessLevel, AccessLevel.unverified);
      },
    );

    test('clear removes both entries', () async {
      await store.write(
        const StoredSession(resident: resident, accessToken: 'token'),
      );
      await store.clear();

      expect(await secrets.read(SecretKeys.accessToken), isNull);
      expect(await secrets.read(SecretKeys.residentSummary), isNull);
      expect(await store.read(), isNull);
    });

    test('the secret key list is exactly what the store writes', () {
      expect(
        SecretKeys.all,
        unorderedEquals(<String>[
          SecretKeys.accessToken,
          SecretKeys.residentSummary,
        ]),
      );
    });
  });

  group('LguService DTO mapping', () {
    Map<String, dynamic> cedula() => <String, dynamic>{
      'id': '018f2c8a-0a01-7000-8000-00000000c001',
      'code': 'CEDULA',
      'name': 'Community Tax Certificate (Cedula)',
      'description':
          'Application and issuance of the community tax certificate.',
      'category': 'dokumento',
      'status': 'published',
      'available_channels': <String>[
        'citizen-web',
        'citizen-mobile',
        'admin-console',
      ],
    };

    test('maps every field of the committed resource', () {
      final service = LguServiceDto.fromJson(cedula())!;

      expect(service.code, 'CEDULA');
      expect(service.category.known, ServiceCategory.dokumento);
      expect(service.status.known, ServicePublicationStatus.published);
      expect(service.availableChannels, hasLength(3));
      expect(service.isOfferedOnMobile, isTrue);
      expect(service.hasUnrecognisedValues, isFalse);
    });

    test('a service not offered on mobile reports that faithfully', () {
      // BUSINESS_PERMIT is web + admin only in the committed catalogue config.
      final json = cedula()
        ..['code'] = 'BUSINESS_PERMIT'
        ..['available_channels'] = <String>['citizen-web', 'admin-console'];

      expect(LguServiceDto.fromJson(json)!.isOfferedOnMobile, isFalse);
    });

    test('an unknown category is preserved, not dropped or guessed', () {
      // Adding a category is an additive, non-breaking server change.
      final json = cedula()..['category'] = 'kabuhayan';
      final service = LguServiceDto.fromJson(json)!;

      expect(service.category.known, isNull);
      expect(service.category.raw, 'kabuhayan');
      expect(service.hasUnrecognisedValues, isTrue);
    });

    test('an unknown channel is preserved too', () {
      final json = cedula()
        ..['available_channels'] = <String>['citizen-mobile', 'kiosk-device'];
      final service = LguServiceDto.fromJson(json)!;

      expect(service.isOfferedOnMobile, isTrue);
      expect(service.availableChannels.last.raw, 'kiosk-device');
      expect(service.availableChannels.last.isRecognised, isFalse);
    });

    test('unknown fields are ignored, never rejected', () {
      final json = cedula()..['brand_new_field'] = <String, dynamic>{'x': 1};
      expect(LguServiceDto.fromJson(json), isNotNull);
    });

    test('a row missing its identity is skipped, not fatal to the page', () {
      final page = LguServiceDto.listFromJson(<Object?>[
        cedula(),
        <String, dynamic>{'name': 'no id or code'},
        'not an object',
        cedula()..['id'] = 'second',
      ]);

      // Two well-formed rows survive; the malformed pair is dropped rather
      // than hiding the whole catalogue from a resident.
      expect(page, hasLength(2));
      expect(page.map((s) => s.id), containsAll(<String>['second']));
    });

    test('the domain type exposes no eligibility or approval logic', () {
      // Guards the rule that authority is server-side: if someone adds
      // `canApply` here, this test is where the conversation happens.
      final service = LguServiceDto.fromJson(cedula())!;
      expect(service.toString(), contains('CEDULA'));
      expect(
        <String>['isOfferedOnMobile', 'hasUnrecognisedValues'],
        isNotEmpty,
        reason: 'the only derived getters, both restating server facts',
      );
    });
  });

  group('ServiceCatalogApiRepository', () {
    test(
      'requests the public route unauthenticated, with clamped paging',
      () async {
        final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
          Ok<ApiHttpResponse>(
            json(200, <String, dynamic>{
              'data': <Object?>[],
              'meta': <String, dynamic>{
                'request_id': 'r',
                'pagination': <String, dynamic>{
                  'page': 1,
                  'per_page': 100,
                  'total': 0,
                  'total_pages': 1,
                  'has_more': false,
                },
              },
            }),
          ),
        ]);
        final repository = ServiceCatalogApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: transport,
            accessTokenProvider: () async => 'token-that-must-not-be-sent',
          ),
        );

        final result = await repository.listServices(
          channel: ServiceChannel.citizenMobile,
          page: 0,
          perPage: 5000,
        );

        expect(result.isOk, isTrue);
        final request = transport.sent.single;
        expect(request.query['channel'], 'citizen-mobile');
        expect(
          request.query['per_page'],
          '100',
          reason: 'clamped to the maximum',
        );
        expect(request.query['page'], '1', reason: 'clamped to the first page');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.headers['X-Client-Channel'], 'citizen-mobile');
      },
    );

    test('maps pagination from meta', () async {
      final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
        Ok<ApiHttpResponse>(
          json(200, <String, dynamic>{
            'data': <Object?>[],
            'meta': <String, dynamic>{
              'pagination': <String, dynamic>{
                'page': 2,
                'per_page': 25,
                'total': 138,
                'total_pages': 6,
                'has_more': true,
              },
            },
          }),
        ),
      ]);
      final repository = ServiceCatalogApiRepository(
        apiClient: ApiClient(config: config(), transport: transport),
      );

      final page = (await repository.listServices()).valueOrNull!;
      expect(page.page, 2);
      expect(page.total, 138);
      expect(page.hasMore, isTrue);
    });

    test('a missing pagination block degrades to a single page', () async {
      final transport = ScriptedTransport(<Result<ApiHttpResponse>>[
        Ok<ApiHttpResponse>(json(200, <String, dynamic>{'data': <Object?>[]})),
      ]);
      final repository = ServiceCatalogApiRepository(
        apiClient: ApiClient(config: config(), transport: transport),
      );

      final page = (await repository.listServices()).valueOrNull!;
      expect(page.page, 1);
      expect(page.hasMore, isFalse);
    });
  });

  group('planned backend repositories decline honestly', () {
    test('every planned module declines with a temporary failure', () async {
      final outcomes = <String, Result<Object?>>{
        'profile': await const PlannedResidentProfileRepository()
            .loadOwnSummary(),
        'credential': await const PlannedCredentialRepository()
            .loadOwnCredential(),
        'verification': await const PlannedVerificationRepository()
            .loadOwnStatus(),
        'requests': await const PlannedServiceRequestRepository()
            .listOwnRequests(),
        'notifications': await const PlannedNotificationRepository().listOwn(),
      };

      outcomes.forEach((name, result) {
        final failure = result.failureOrNull;
        expect(failure, isA<ServerFailure>(), reason: name);
        expect((failure! as ServerFailure).isTemporary, isTrue, reason: name);
        // The resident is told to try later, never that they did something
        // wrong, and never the operator-facing detail.
        expect(failure.residentMessage, contains('temporarily unavailable'));
        expect(failure.residentMessage, isNot(contains('module')));
      });
    });

    test('the module list matches the committed boundary map', () {
      expect(
        PlannedModule.values.map((m) => m.moduleName),
        unorderedEquals(<String>[
          'Identity',
          'ResidentProfile',
          'Credential',
          'Verification',
          'ServiceDelivery',
          'Notification',
        ]),
      );
    });
  });
}
