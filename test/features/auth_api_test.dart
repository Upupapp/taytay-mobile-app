import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/auth/data/auth_api_repository.dart';
import 'package:taytay_resident/features/auth/domain/account_application.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';
import 'package:taytay_resident/features/auth/domain/code_exchange.dart';

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

  ApiHttpResponse okEnvelope(Object data) => ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{'data': data}),
  );

  group('email and reset codes', () {
    test('a 202 without retry_after is a contract failure', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'accepted': true})),
      );
      final Result<CodeAcceptance> result = await repository
          .requestPasswordReset(email: 'juana@example.com');
      expect(result.failureOrNull, isA<ContractFailure>());
    });

    test('retry_after from the body drives the acceptance', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(
          okEnvelope(<String, Object?>{'accepted': true, 'retry_after': 60}),
        ),
      );
      final Result<CodeAcceptance> result = await repository
          .requestPasswordReset(email: 'juana@example.com');
      expect((result as Ok<CodeAcceptance>).value.retryAfterSeconds, 60);
    });
  });

  group('submitting a profile', () {
    const AccountApplication bare = AccountApplication(
      email: 'juana@example.com',
      password: 'Password1!',
      mobile: '09170000000',
      givenName: 'Juana',
      familyName: 'Dela Cruz',
      barangay: 'San Juan',
    );

    AccountApplication ready() => AccountApplication(
      email: bare.email,
      password: bare.password,
      mobile: bare.mobile,
      givenName: bare.givenName,
      familyName: bare.familyName,
      barangay: bare.barangay,
      idTypeLabel: 'PhilSys National ID',
      idFrontBytes: Uint8List.fromList(<int>[1, 2]),
      idFrontName: 'id_front.jpg',
      idFrontMime: 'image/jpeg',
      selfieBytes: Uint8List.fromList(<int>[3]),
      selfieName: 'selfie.jpg',
      selfieMime: 'image/jpeg',
    );

    ApiHttpResponse config({
      String? privacy = '2026-03-privacy',
      String? terms = '2026-03-terms',
    }) => okEnvelope(<String, Object?>{
      'privacy_version': privacy,
      'terms_version': terms,
    });

    ApiHttpResponse created() => ApiHttpResponse(
      statusCode: 201,
      body: jsonEncode(<String, Object?>{
        'data': <String, Object?>{'status': 'pending'},
      }),
    );

    ApiHttpResponse problem(int status, String code) => ApiHttpResponse(
      statusCode: status,
      body: jsonEncode(<String, Object?>{
        'error': <String, Object?>{
          'code': code,
          'message': 'operator text that must not be shown',
        },
      }),
    );

    test('a missing ID front or selfie fails before any request', () async {
      final Result<void> missingFront = await repository.submitProfile(bare);
      expect(missingFront.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);

      final Result<void> missingSelfie = await repository.submitProfile(
        AccountApplication(
          email: bare.email,
          password: bare.password,
          mobile: bare.mobile,
          givenName: bare.givenName,
          familyName: bare.familyName,
          barangay: bare.barangay,
          idFrontBytes: Uint8List.fromList(<int>[1]),
          idFrontName: 'id_front.jpg',
          idFrontMime: 'image/jpeg',
        ),
      );
      expect(missingSelfie.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('a config without versions is a contract failure', () async {
      transport.responses.add(Ok<ApiHttpResponse>(config(privacy: null)));
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.failureOrNull, isA<ContractFailure>());
      expect(transport.requests.single.path, 'app/config');
    });

    test('posts both consent versions, then opens on 201', () async {
      transport.responses.add(Ok<ApiHttpResponse>(config()));
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'y'})),
      );
      transport.responses.add(Ok<ApiHttpResponse>(created()));
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.isOk, isTrue);
      expect(transport.requests.map((ApiRequest r) => r.path), <String>[
        'app/config',
        'me/consents',
        'me/consents',
        'me/verification-requests',
      ]);
      expect(transport.requests[1].body, <String, Object?>{
        'version': '2026-03-privacy',
      });
      expect(transport.requests[2].body, <String, Object?>{
        'version': '2026-03-terms',
      });
      expect(transport.requests[3].body, <String, Object?>{
        'id_type': 'philid',
      });
      expect(
        transport.requests[3].files.map((MultipartFile f) => f.field),
        <String>['id_front', 'selfie'],
      );
      expect(result.toString(), isNot(contains('Password1')));
      expect(result.toString(), isNot(contains('draft')));
    });

    test('one consent call when the two versions match', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(config(terms: '2026-03-privacy')),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(Ok<ApiHttpResponse>(created()));
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.isOk, isTrue);
      expect(
        transport.requests.where((ApiRequest r) => r.path == 'me/consents'),
        hasLength(1),
      );
    });

    test('a 200 from verification does not count as opened', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(config(terms: '2026-03-privacy')),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'status': 'pending'})),
      );
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.failureOrNull, isA<ContractFailure>());
    });

    test('409 is already pending and 403 is already verified', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(config(terms: '2026-03-privacy')),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(Ok<ApiHttpResponse>(problem(409, 'CONFLICT')));
      final Result<void> pending = await repository.submitProfile(ready());
      expect(pending.failureOrNull, isA<ConflictFailure>());
      expect(
        pending.failureOrNull!.residentMessage,
        isNot(contains('operator')),
      );

      transport.responses.add(
        Ok<ApiHttpResponse>(config(terms: '2026-03-privacy')),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(Ok<ApiHttpResponse>(problem(403, 'FORBIDDEN')));
      final Result<void> verified = await repository.submitProfile(ready());
      expect(verified.failureOrNull, isA<ForbiddenFailure>());
      expect(
        verified.failureOrNull!.residentMessage,
        isNot(contains('operator')),
      );
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
