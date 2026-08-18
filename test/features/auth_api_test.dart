import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/features/auth/data/auth_api_repository.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';

class _Recording implements ApiTransport {
  _Recording(this.responses);

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

Result<ApiHttpResponse> ok(int status, Object body) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(body),
    headers: const <String, String>{'x-request-id': 'req-1'},
  ),
);

Result<ApiHttpResponse> apiError(
  int status,
  String code, {
  Map<String, String> headers = const <String, String>{'x-request-id': 'req-1'},
}) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(<String, Object?>{
      'error': <String, Object?>{'code': code, 'message': 'operator text'},
    }),
    headers: headers,
  ),
);

Object token({String value = 'tok-abc'}) => <String, Object?>{
  'data': <String, Object?>{
    'status': 'authenticated',
    'token': value,
    'token_type': 'Bearer',
    'expires_at': '2026-09-01T00:00:00Z',
  },
  'meta': <String, Object?>{'request_id': 'req-1'},
};

Object account({String? residentId = 'res-1', bool mobileVerified = true}) =>
    <String, Object?>{
      'data': <String, Object?>{
        'id': 'acct-1',
        'account_type': 'citizen',
        'status': 'active',
        'display_name': 'Ana',
        'email': 'ana@example.test',
        'mobile_number': '+639171234567',
        'mobile_verified': mobileVerified,
        'mfa_enabled': false,
        'permissions': <String>['resident.self'],
        'roles': <String>['resident'],
        'resident_id': residentId,
      },
      'meta': <String, Object?>{'request_id': 'req-1'},
    };

Object profile(String tier) => <String, Object?>{
  'data': <String, Object?>{'id': 'res-1', 'verification_tier': tier},
  'meta': <String, Object?>{'request_id': 'req-1'},
};

void main() {
  late _Recording transport;
  late AuthApiRepository repository;

  AuthApiRepository build(_Recording t) => AuthApiRepository(
    apiClient: ApiClient(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      transport: t,
      accessTokenProvider: () async => 'session-token',
    ),
  );

  setUp(() {
    transport = _Recording(<Result<ApiHttpResponse>>[]);
    repository = build(transport);
  });

  group('requesting a code', () {
    test('posts the number and carries an idempotency key', () async {
      transport.responses.add(
        ok(202, <String, Object?>{
          'data': <String, Object?>{'status': 'accepted'},
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<void> result = await repository.requestOneTimeCode(
        mobileNumber: '+639171234567',
      );

      expect(result.isOk, isTrue);
      final ApiRequest request = transport.requests.single;
      expect(request.path, 'auth/otp');
      expect(request.method, HttpMethod.post);
      expect(
        (request.body! as Map<String, Object?>)['mobile_number'],
        '+639171234567',
      );

      final String key = request.headers['Idempotency-Key']!;
      expect(key, isNotEmpty);
      // The number never travels in the header. An Idempotency-Key is logged by
      // proxies and load balancers, and a mobile number in a header is a mobile
      // number in somebody's access log.
      expect(key, isNot(contains('639171234567')));
    });

    test('the same number produces the same key, so a repeat is a repeat', () {
      // A random key on a retry is a new request, which is the failure the key
      // exists to prevent.
      final _Recording a = _Recording(<Result<ApiHttpResponse>>[
        ok(202, <String, Object?>{
          'data': <String, Object?>{},
          'meta': <String, Object?>{},
        }),
        ok(202, <String, Object?>{
          'data': <String, Object?>{},
          'meta': <String, Object?>{},
        }),
      ]);
      final AuthApiRepository r = build(a);

      return Future<void>(() async {
        await r.requestOneTimeCode(mobileNumber: '+639171234567');
        await r.requestOneTimeCode(mobileNumber: '+639171234567');
        expect(
          a.requests.first.headers['Idempotency-Key'],
          a.requests.last.headers['Idempotency-Key'],
        );
      });
    });

    test(
      'a throttle is surfaced with its Retry-After, not swallowed',
      () async {
        transport.responses.add(
          apiError(
            429,
            'RATE_LIMITED',
            headers: const <String, String>{
              'x-request-id': 'req-1',
              'retry-after': '60',
            },
          ),
        );

        final Result<void> result = await repository.requestOneTimeCode(
          mobileNumber: '+639171234567',
        );

        final RateLimitedFailure failure =
            result.failureOrNull! as RateLimitedFailure;
        expect(failure.retryAfter, const Duration(seconds: 60));
        // One attempt. Retrying inside the transport would spend the resident's
        // allowance without their seeing it, and defeat the control.
        expect(transport.requests, hasLength(1));
      },
    );
  });

  group('RetryPolicy — a throttled write is never repeated', () {
    const RetryPolicy policy = RetryPolicy();

    test('a 429 on a keyed POST is not retryable', () {
      expect(
        policy.isRetryable(
          request: const ApiRequest(
            method: HttpMethod.post,
            path: 'auth/otp',
            headers: <String, String>{'Idempotency-Key': 'otp-1'},
          ),
          failure: const RateLimitedFailure(),
          statusCode: 429,
        ),
        isFalse,
      );
    });

    test('but a 429 on a read still honours Retry-After', () {
      expect(
        policy.isRetryable(
          request: const ApiRequest(method: HttpMethod.get, path: 'services'),
          failure: const RateLimitedFailure(),
          statusCode: 429,
        ),
        isTrue,
      );
    });

    test('and a dropped connection on a keyed POST still is', () {
      // What the idempotency key is for.
      expect(
        policy.isRetryable(
          request: const ApiRequest(
            method: HttpMethod.post,
            path: 'auth/otp',
            headers: <String, String>{'Idempotency-Key': 'otp-1'},
          ),
          failure: const NetworkFailure(),
        ),
        isTrue,
      );
    });
  });

  group('verifying a code', () {
    test(
      'asks the server who this is before saying a session exists',
      () async {
        transport.responses
          ..add(ok(201, token()))
          ..add(ok(200, account()))
          ..add(ok(200, profile('verified')));

        final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
          mobileNumber: '+639171234567',
          code: '123456',
        );

        expect(transport.requests.map((ApiRequest r) => r.path), <String>[
          'auth/otp/verify',
          'me',
          'me/profile',
        ]);

        // The two reads carry the token just issued, not the stored session's.
        // Storing it first would mean a session existed for a moment at a level
        // nobody had checked.
        expect(
          transport.requests[1].headers['Authorization'],
          'Bearer tok-abc',
        );

        final AuthOutcome outcome = (result as Ok<AuthOutcome>).value;
        expect(outcome.resident.accountId, 'acct-1');
        expect(outcome.resident.displayName, 'Ana');
        expect(outcome.resident.accessLevel, AccessLevel.verified);
        expect(outcome.accessToken, 'tok-abc');
        expect(outcome.expiresAt, isNotNull);
      },
    );

    test('an unverified tier is unverified', () async {
      transport.responses
        ..add(ok(201, token()))
        ..add(ok(200, account()))
        ..add(ok(200, profile('provisional')));

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '+639171234567',
        code: '123456',
      );

      expect(
        (result as Ok<AuthOutcome>).value.resident.accessLevel,
        AccessLevel.unverified,
      );
    });

    test('an account with no resident link never asks for a tier', () async {
      transport.responses
        ..add(ok(201, token()))
        ..add(ok(200, account(residentId: null)));

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '+639171234567',
        code: '123456',
      );

      expect(
        transport.requests.map((ApiRequest r) => r.path),
        isNot(contains('me/profile')),
      );
      expect(
        (result as Ok<AuthOutcome>).value.resident.accessLevel,
        AccessLevel.unverified,
      );
    });

    test(
      'a failed profile read leaves the resident unverified, not verified',
      () async {
        // Fails towards one extra screen rather than towards handing somebody a
        // digital ID the LGU has not issued.
        transport.responses
          ..add(ok(201, token()))
          ..add(ok(200, account()))
          ..add(const Err<ApiHttpResponse>(NetworkFailure()));

        final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
          mobileNumber: '+639171234567',
          code: '123456',
        );

        expect(
          (result as Ok<AuthOutcome>).value.resident.accessLevel,
          AccessLevel.unverified,
        );
      },
    );

    test('a failed GET me refuses the session outright', () async {
      // The opposite of the profile read. Without `GET me` there is no account
      // id and no name — nothing to build a session out of — so guessing one is
      // the fail-open mistake.
      transport.responses
        ..add(ok(201, token()))
        ..add(apiError(500, 'SERVER_ERROR'));

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '+639171234567',
        code: '123456',
      );

      expect(result.isErr, isTrue);
    });

    test(
      'an unverified mobile is a branch of success, not a failure',
      () async {
        transport.responses
          ..add(ok(201, token()))
          ..add(ok(200, account(mobileVerified: false)))
          ..add(ok(200, profile('verified')));

        final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
          mobileNumber: '+639171234567',
          code: '123456',
        );

        expect(result.isOk, isTrue);
        expect(
          (result as Ok<AuthOutcome>).value.requiresContactVerification,
          isTrue,
        );
      },
    );

    test('a wrong code never reaches the account reads', () async {
      transport.responses.add(apiError(422, 'VALIDATION_FAILED'));

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '+639171234567',
        code: '000000',
      );

      expect(result.isErr, isTrue);
      expect(transport.requests, hasLength(1));
    });

    test('a 200 with no token is a contract failure, not a session', () async {
      transport.responses.add(
        ok(201, <String, Object?>{
          'data': <String, Object?>{'status': 'authenticated'},
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '+639171234567',
        code: '123456',
      );

      expect(result.failureOrNull, isA<ContractFailure>());
    });
  });

  group('signing out', () {
    test('calls the server and succeeds anyway when it refuses', () async {
      transport.responses.add(apiError(500, 'SERVER_ERROR'));

      final Result<void> result = await repository.signOut();

      expect(transport.requests.single.path, 'auth/tokens/current');
      expect(transport.requests.single.method, HttpMethod.delete);
      // A resident on a borrowed phone must always be able to sign out.
      expect(result.isOk, isTrue);
    });

    test('succeeds with no connection at all', () async {
      transport.responses.add(const Err<ApiHttpResponse>(NetworkFailure()));
      expect((await repository.signOut()).isOk, isTrue);
    });
  });

  group('no staff surface is reachable from here', () {
    test('the repository names no staff-only endpoint', () {
      // F20. `auth/tokens`, `auth/tokens/mfa` and `auth/password/forgot` all
      // filter `account_type = Staff` server-side. Wiring them would put admin
      // console surfaces in the resident repository — forbidden by Article 0 —
      // and the code could never do anything but fail for a resident.
      final String source = File(
        'lib/features/auth/data/auth_api_repository.dart',
      ).readAsStringSync();

      for (final String path in <String>[
        "'auth/tokens'",
        "'auth/tokens/mfa'",
        "'auth/password/forgot'",
      ]) {
        expect(source, isNot(contains(path)), reason: path);
      }
      // The one `auth/tokens/...` path that is not staff-only is still here.
      expect(source, contains("'auth/tokens/current'"));
    });
  });
}
