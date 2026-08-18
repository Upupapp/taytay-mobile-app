import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';

/// Opening a KYC case — the other half of F14.
///
/// Reading `GET barangays` was the easy half. This is the one that mattered:
/// `POST me/kyc` is the door to the Verified state, the digital ID and every
/// service resting on them, and until the backend accepted a published
/// identifier no client could open it at all.
class _Scripted implements ApiTransport {
  final List<Result<ApiHttpResponse>> responses = <Result<ApiHttpResponse>>[];
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> caseResponse({
  String status = 'draft',
  int statusCode = 201,
}) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: statusCode,
    body: jsonEncode(<String, Object?>{
      'data': <String, Object?>{
        'id': '01a0140e-0eaf-71fa-bcb7-c354b5edee94',
        'status': status,
        'can_edit': true,
        'submitted_at': null,
        'message': null,
        'claimed': <String, Object?>{'first_name': 'Maria'},
        'resident_id': null,
      },
      'meta': <String, Object?>{'request_id': 'req-1'},
    }),
    headers: const <String, String>{'x-request-id': 'req-1'},
  ),
);

KycClaim claimOf({
  String barangayCode = 'brgy-dolores',
  String street = '12 Mabini St',
}) => KycClaim(
  givenName: 'Maria',
  middleName: '',
  familyName: 'Santos',
  birthDate: DateTime(1990, 3, 7),
  sex: ClaimedSex.female,
  barangayCode: barangayCode,
  streetAddress: street,
);

void main() {
  late _Scripted transport;
  late KycApiRepository repository;

  setUp(() {
    transport = _Scripted();
    repository = KycApiRepository(
      apiClient: ApiClient(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        transport: transport,
        accessTokenProvider: () async => 'tok',
      ),
    );
  });

  group('opening a case', () {
    test('files the claim against the published code, never an integer', () async {
      transport.responses.add(caseResponse());

      await repository.openCase(claim: claimOf(), idempotencyKey: 'key-1');

      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, 'me/kyc');

      final Map<String, Object?> body = request.body! as Map<String, Object?>;
      // The whole of F14 in one assertion. `barangay_id` is the auto-increment
      // primary key the backend's own Article 4 forbids publishing; this app has
      // no way to know one and must never learn.
      expect(body['barangay_code'], 'brgy-dolores');
      expect(body.containsKey('barangay_id'), isFalse);
    });

    test('a birth date is a date, with no timezone attached', () async {
      transport.responses.add(caseResponse());

      await repository.openCase(claim: claimOf(), idempotencyKey: 'key-1');

      // An ISO instant would put a timezone on a birthday. Manila is UTC+8, so
      // a date serialised as UTC lands on the previous day, and a birthday off
      // by one fails the registry match this claim exists to be checked against.
      expect(
        (transport.requests.single.body! as Map<String, Object?>)['birth_date'],
        '1990-03-07',
      );
    });

    test('an absent middle name is absent, not blank', () async {
      transport.responses.add(caseResponse());

      await repository.openCase(claim: claimOf(), idempotencyKey: 'key-1');

      final Map<String, Object?> body =
          transport.requests.single.body! as Map<String, Object?>;
      // The server's rule is `nullable`. An empty string is a value a reviewer
      // has to interpret; many Filipino records genuinely carry no middle name.
      expect(body.containsKey('middle_name'), isFalse);
      expect(body.containsKey('suffix'), isFalse);
      expect(body['first_name'], 'Maria');
      expect(body['last_name'], 'Santos');
      expect(body['sex'], 'female');
      expect(body['street_address'], '12 Mabini St');
    });

    test('it carries an idempotency key, and the case comes back', () async {
      transport.responses.add(caseResponse());

      final Result<VerificationStatus> result = await repository.openCase(
        claim: claimOf(),
        idempotencyKey: 'key-1',
      );

      // The server resolves the case from the account, so a repeat returns the
      // same one — but the app does not get to rely on a guarantee it cannot
      // see, and a duplicate municipal case is not recoverable from this side.
      expect(
        transport.requests.single.headers.entries
            .firstWhere(
              (MapEntry<String, String> e) =>
                  e.key.toLowerCase() == 'idempotency-key',
            )
            .value,
        'key-1',
      );
      expect(
        (result as Ok<VerificationStatus>).value.state,
        VerificationAttemptState.draft,
      );
    });

    test('an incomplete claim never leaves the device', () async {
      final Result<VerificationStatus> result = await repository.openCase(
        claim: claimOf(barangayCode: ''),
        idempotencyKey: 'key-1',
      );

      // A 422 here is a dead end: the server's field errors are keyed by wire
      // names a resident has never seen, on the screen that decides whether they
      // ever become Verified.
      expect(result.isErr, isTrue);
      expect(transport.requests, isEmpty);
    });
  });

  group('submitting for review', () {
    test('it posts the submission with no body', () async {
      transport.responses.add(
        caseResponse(status: 'submitted', statusCode: 200),
      );

      final Result<void> result = await repository.submitForReview(
        documentUploadIds: const <String>[],
        idempotencyKey: 'key-2',
      );

      expect(result.isOk, isTrue);
      final ApiRequest request = transport.requests.single;
      expect(request.path, 'me/kyc/submit');
      // The case is resolved from the authenticated account: there is no
      // identifier in this request for anybody to tamper with.
      expect(request.body, isNull);
    });

    test(
      'a submission carrying documents declines rather than dropping them',
      () async {
        final Result<void> result = await repository.submitForReview(
          documentUploadIds: const <String>['upload-1'],
          idempotencyKey: 'key-2',
        );

        // F28: nothing attaches a file to a KYC case. Posting anyway would tell a
        // resident who has just photographed their PhilID that the office has it.
        expect(result.isErr, isTrue);
        expect(transport.requests, isEmpty);
      },
    );
  });

  group('reading the case', () {
    test('no case is an ordinary state, not an error', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(
          ApiHttpResponse(
            statusCode: 404,
            body: jsonEncode(<String, Object?>{
              'error': <String, Object?>{
                'code': 'NOT_FOUND',
                'message': 'No KYC case.',
              },
            }),
            headers: const <String, String>{},
          ),
        ),
      );

      final Result<VerificationStatus> result = await repository
          .loadOwnStatus();

      // The honest answer to "where has my application got to" is "you have not
      // made one" — a next step, not an error banner.
      expect(
        (result as Ok<VerificationStatus>).value.state,
        VerificationAttemptState.notStarted,
      );
    });
  });
}
