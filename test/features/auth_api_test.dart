import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/retry_policy.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/features/auth/data/auth_api_repository.dart';
import 'package:taytay_resident/features/auth/data/firebase_identity.dart';
import 'package:taytay_resident/features/auth/domain/account_application.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';
import 'package:taytay_resident/features/auth/domain/code_exchange.dart';
import 'package:taytay_resident/features/auth/domain/sign_in_challenge.dart';
import 'package:taytay_resident/features/verification/domain/verification_id_type.dart';

class _FakeIdentity implements FirebaseIdentity {
  Result<FirebaseCredentialSession> signInResult = const Err(
    UnauthenticatedFailure(debugMessage: 'not signed in'),
  );
  Result<FirebaseCredentialSession> createResult = const Err(
    UnauthenticatedFailure(debugMessage: 'not created'),
  );
  Result<void> phoneResult = const Ok<void>(null);
  Result<FirebaseCredentialSession> confirmResult = const Err(
    UnauthenticatedFailure(debugMessage: 'no code'),
  );

  int phoneSends = 0;
  int confirms = 0;
  int emailSignIns = 0;
  int creates = 0;
  int signOuts = 0;

  @override
  Future<Result<FirebaseCredentialSession>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emailSignIns++;
    return signInResult;
  }

  @override
  Future<Result<FirebaseCredentialSession>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    creates++;
    return createResult;
  }

  @override
  Future<Result<void>> sendPhoneCode({required String phoneNumber}) async {
    phoneSends++;
    return phoneResult;
  }

  @override
  Future<Result<FirebaseCredentialSession>> confirmPhoneCode({
    required String code,
  }) async {
    confirms++;
    return confirmResult;
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => null;

  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

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
  late _FakeIdentity identity;
  late AuthApiRepository repository;

  AuthApiRepository build(_Recording t, FirebaseIdentity identity) =>
      AuthApiRepository(
        apiClient: ApiClient(
          config: AppConfig.from(
            rawEnvironment: 'dev',
            rawApiBaseUrl: 'https://example.test/api/v1',
            isReleaseBuild: false,
          ),
          transport: t,
          accessTokenProvider: () async => 'session-token',
        ),
        identity: identity,
      );

  setUp(() {
    transport = _Recording(<Result<ApiHttpResponse>>[]);
    identity = _FakeIdentity();
    repository = build(transport, identity);
  });

  ApiHttpResponse okEnvelope(Object data) => ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{'data': data}),
  );

  group('requesting a code', () {
    test('an empty number is refused before any network call', () async {
      final Result<void> result = await repository.requestOneTimeCode(
        mobileNumber: '   ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('a mobile number asks Firebase and does not call the API', () async {
      final Result<void> result = await repository.requestOneTimeCode(
        mobileNumber: '0917-000-0000',
      );

      expect(result.isOk, isTrue);
      expect(identity.phoneSends, 1);
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

    test('a phone code opens the session with GET /me', () async {
      identity.confirmResult = const Ok<FirebaseCredentialSession>(
        FirebaseCredentialSession(idToken: 'id-token-1'),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(
          okEnvelope(<String, Object?>{
            'id': 'user-1',
            'name': 'Juana Sample',
            'verification_status': 'pending',
            'role': 'admin',
          }),
        ),
      );

      final Result<AuthOutcome> result = await repository.verifyOneTimeCode(
        mobileNumber: '0917-000-0000',
        code: '000000',
      );

      final AuthOutcome outcome = (result as Ok<AuthOutcome>).value;
      expect(outcome.resident.accountId, 'user-1');
      expect(outcome.resident.displayName, 'Juana');
      expect(outcome.resident.accessLevel, AccessLevel.unverified);
      expect(outcome.accessToken, 'id-token-1');
      expect(outcome.expiresAt, isNull);
      expect(transport.requests.single.path, 'me');
      expect(transport.requests.single.method, HttpMethod.get);
      expect(
        transport.requests.single.headers['Authorization'],
        'Bearer id-token-1',
      );
      expect(transport.requests.single.body, isNull);
    });
  });

  group('signing out', () {
    test('clears locally and does not call a token route', () async {
      final Result<void> result = await repository.signOut();

      // The Node API publishes no revocation route. A resident on a borrowed
      // phone must still be able to sign out.
      expect(result.isOk, isTrue);
      expect(identity.signOuts, 1);
      expect(transport.requests, isEmpty);
    });
  });

  group('Firebase sign-in and registration', () {
    test(
      'email and password sign in, then GET /me carries the ID token',
      () async {
        identity.signInResult = const Ok<FirebaseCredentialSession>(
          FirebaseCredentialSession(idToken: 'id-token-2'),
        );
        transport.responses.add(
          Ok<ApiHttpResponse>(
            okEnvelope(<String, Object?>{
              'id': 'user-2',
              'name': 'Pedro Sample Resident',
              'verification_status': 'verified',
            }),
          ),
        );

        final Result<AuthOutcome> result = await repository.signInWithPassword(
          identifier: 'pedro@example.com',
          password: 'Password1',
        );

        final AuthOutcome outcome = (result as Ok<AuthOutcome>).value;
        expect(identity.emailSignIns, 1);
        expect(outcome.resident.accessLevel, AccessLevel.verified);
        expect(outcome.resident.displayName, 'Pedro');
        expect(outcome.expiresAt, isNull);
        expect(transport.requests.single.path, 'me');
        expect(
          transport.requests.single.headers['Authorization'],
          'Bearer id-token-2',
        );
        expect(result.toString(), isNot(contains('id-token-2')));
        expect(result.toString(), isNot(contains('Password1')));
      },
    );

    test('a mobile number and password never leave the device', () async {
      final Result<AuthOutcome> result = await repository.signInWithPassword(
        identifier: '09170000000',
        password: 'Password1',
      );

      final ValidationFailure failure =
          result.failureOrNull! as ValidationFailure;
      expect(
        failure.fieldErrors['identifier'],
        contains(passwordSignInNeedsEmail),
      );
      expect(identity.emailSignIns, 0);
      expect(transport.requests, isEmpty);
    });

    test(
      'registration without a password does not call Firebase or the API',
      () async {
        final Result<AuthOutcome> result = await repository.registerAccount(
          email: 'juana@example.com',
        );

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(identity.creates, 0);
        expect(transport.requests, isEmpty);
      },
    );

    test('createAccount uses Firebase, then GET /me', () async {
      identity.createResult = const Ok<FirebaseCredentialSession>(
        FirebaseCredentialSession(idToken: 'id-token-3'),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(
          okEnvelope(<String, Object?>{
            'id': 'user-3',
            'name': 'Juana Sample',
            'verification_status': 'unverified',
          }),
        ),
      );

      final Result<AuthOutcome> result = await repository.createAccount(
        email: 'juana@example.com',
        password: 'Password1',
      );

      expect(result.isOk, isTrue);
      expect(identity.creates, 1);
      expect(transport.requests.single.path, 'me');
      expect(
        transport.requests.single.headers['Authorization'],
        'Bearer id-token-3',
      );
    });
  });

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

    AccountApplication ready({String idType = 'PhilSys National ID'}) =>
        AccountApplication(
          email: bare.email,
          password: bare.password,
          mobile: bare.mobile,
          givenName: bare.givenName,
          familyName: bare.familyName,
          barangay: bare.barangay,
          idTypeLabel: idType,
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
      final Result<void> result = await repository.recordConsents();
      expect(result.failureOrNull, isA<ContractFailure>());
      expect(transport.requests.single.path, 'app/config');
    });

    test('consent posts both published versions, each with its kind '
        '(D-208)', () async {
      transport.responses.add(Ok<ApiHttpResponse>(config()));
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
      );
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'y'})),
      );
      final Result<void> result = await repository.recordConsents();
      expect(result.isOk, isTrue);
      expect(transport.requests.map((ApiRequest r) => r.path), <String>[
        'app/config',
        'me/consents',
        'me/consents',
      ]);
      expect(transport.requests[1].body, <String, Object?>{
        'version': '2026-03-privacy',
        'kind': 'privacy',
      });
      expect(transport.requests[2].body, <String, Object?>{
        'version': '2026-03-terms',
        'kind': 'terms',
      });
    });

    test(
      'two consent calls even when the two versions match (D-208)',
      () async {
        transport.responses.add(
          Ok<ApiHttpResponse>(config(terms: '2026-03-privacy')),
        );
        transport.responses.add(
          Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
        );
        transport.responses.add(
          Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'version': 'x'})),
        );
        final Result<void> result = await repository.recordConsents();
        expect(result.isOk, isTrue);
        final List<ApiRequest> posts = transport.requests
            .where((ApiRequest r) => r.path == 'me/consents')
            .toList();
        expect(posts.map((ApiRequest r) => r.body), <Object?>[
          <String, Object?>{'version': '2026-03-privacy', 'kind': 'privacy'},
          <String, Object?>{'version': '2026-03-privacy', 'kind': 'terms'},
        ]);
      },
    );

    test('submit posts only the verification request, opened on 201', () async {
      transport.responses.add(Ok<ApiHttpResponse>(created()));
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.isOk, isTrue);
      expect(transport.requests.single.path, 'me/verification-requests');
      expect(transport.requests.single.body, <String, Object?>{
        'id_type': 'philid',
      });
      expect(
        transport.requests.single.files.map((MultipartFile f) => f.field),
        <String>['id_front', 'selfie'],
      );
      expect(result.toString(), isNot(contains('Password1')));
    });

    test('each ID type the wizard offers posts its own id_type', () async {
      for (final String wire in verificationIdTypes) {
        transport.responses.add(Ok<ApiHttpResponse>(created()));
        final Result<void> result = await repository.submitProfile(
          ready(idType: idTypeLabel(wire)),
        );
        expect(result.isOk, isTrue, reason: wire);
        expect(transport.requests.last.body, <String, Object?>{
          'id_type': wire,
        }, reason: wire);
      }
    });

    test('a 200 from verification does not count as opened', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(okEnvelope(<String, Object?>{'status': 'pending'})),
      );
      final Result<void> result = await repository.submitProfile(ready());
      expect(result.failureOrNull, isA<ContractFailure>());
    });

    test('409 is already pending and 403 is already verified', () async {
      transport.responses.add(Ok<ApiHttpResponse>(problem(409, 'CONFLICT')));
      final Result<void> pending = await repository.submitProfile(ready());
      expect(pending.failureOrNull, isA<ConflictFailure>());
      expect(
        pending.failureOrNull!.residentMessage,
        isNot(contains('operator')),
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

  group('saving the registration profile', () {
    const RegistrationProfile profile = RegistrationProfile(
      givenName: 'Juana',
      familyName: 'Dela Cruz',
      mobile: '0917 123 4567',
      email: 'juana.delacruz@example.com',
      barangayId: '00000000-0000-4000-8000-0000000000a1',
      street: 'Purok 3',
    );

    test(
      'PATCH /me sends only ProfilePatch fields, with barangay_id',
      () async {
        transport.responses.add(
          Ok<ApiHttpResponse>(
            okEnvelope(<String, Object?>{
              'id': 'acct-1',
              'email_verified': false,
              'role': 'registered',
            }),
          ),
        );
        final Result<SavedProfile> result = await repository
            .saveRegistrationProfile(profile);

        final ApiRequest request = transport.requests.single;
        expect(request.method, HttpMethod.patch);
        expect(request.path, 'me');
        expect(request.body, <String, Object?>{
          'name': 'Juana Dela Cruz',
          'mobile': '09171234567',
          'email': 'juana.delacruz@example.com',
          'barangay_id': '00000000-0000-4000-8000-0000000000a1',
          'street': 'Purok 3',
        });
        // ProfilePatch is strict. Nothing outside it is sent, least of all a
        // role or an office.
        const Set<String> declared = <String>{
          'name',
          'birthdate',
          'sex',
          'mobile',
          'email',
          'barangay_id',
          'address',
          'street',
          'purok',
        };
        final Object? body = request.body;
        expect(body, isA<Map<String, Object?>>());
        expect(
          (body! as Map<String, Object?>).keys.toSet().difference(declared),
          isEmpty,
        );
        expect(result.valueOrNull?.emailVerified, isFalse);
        expect(profile.toString(), isNot(contains('Juana')));
      },
    );

    test('an emptied street is cleared; no barangay is refused', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(
          okEnvelope(<String, Object?>{'id': 'acct-1', 'email_verified': true}),
        ),
      );
      final Result<SavedProfile> cleared = await repository
          .saveRegistrationProfile(
            const RegistrationProfile(
              givenName: 'Juana',
              familyName: 'Dela Cruz',
              mobile: '09171234567',
              email: 'juana.delacruz@example.com',
              barangayId: '00000000-0000-4000-8000-0000000000a1',
            ),
          );
      final Object? body = transport.requests.single.body;
      expect(body, isA<Map<String, Object?>>());
      final Map<String, Object?> map = body! as Map<String, Object?>;
      expect(map.containsKey('street'), isTrue);
      expect(map['street'], isNull);
      expect(cleared.valueOrNull?.emailVerified, isTrue);

      final Result<SavedProfile> missing = await repository
          .saveRegistrationProfile(
            const RegistrationProfile(
              givenName: 'Juana',
              familyName: 'Dela Cruz',
              mobile: '09171234567',
              email: 'juana.delacruz@example.com',
              barangayId: '',
            ),
          );
      expect(missing.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, hasLength(1));
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
