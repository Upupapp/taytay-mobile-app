import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
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
    test('an empty number is refused before any network call', () async {
      final Result<void> result = await repository.requestOneTimeCode(
        mobileNumber: '   ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('the Node API has no OTP route, so the call declines', () async {
      final Result<void> result = await repository.requestOneTimeCode(
        mobileNumber: '0917-000-0000',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });
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
    test('an empty code is refused before any network call', () async {
      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '0917-000-0000',
        code: '  ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('the Node API has no OTP exchange, so no session is minted', () async {
      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '0917-000-0000',
        code: '000000',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });
  });

  group('signing out', () {
    test('clears locally and does not call a token route', () async {
      final Result<void> result = await repository.signOut();

      // The Node API publishes no revocation route. A resident on a borrowed
      // phone must still be able to sign out.
      expect(result.isOk, isTrue);
      expect(transport.requests, isEmpty);
    });
  });

  group('no staff surface is reachable from here', () {
    test('the repository names no staff-only endpoint', () {
      final String source = File(
        'lib/features/auth/data/auth_api_repository.dart',
      ).readAsStringSync();

      for (final String path in <String>[
        "'auth/otp'",
        "'auth/tokens'",
        "'auth/tokens/mfa'",
        "'auth/tokens/current'",
        "'auth/password/forgot'",
        "'me/profile'",
      ]) {
        expect(source, isNot(contains(path)), reason: path);
      }
    });
  });
}
