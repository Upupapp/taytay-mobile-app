import 'dart:convert';
import 'dart:typed_data';

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
    test(
      'declines: the Node contract has one multipart submit, not a case',
      () async {
        final Result<VerificationStatus> result = await repository.openCase(
          claim: claimOf(),
          idempotencyKey: 'key-1',
        );

        // A birth date, a barangay code and a street address stay on the device.
        // `POST me/verification-requests` is the route that exists, and it takes
        // files, not this claim.
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
        expect(transport.requests, isEmpty);
      },
    );

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
    test('declines and does not post me/kyc/submit', () async {
      final Result<void> result = await repository.submitForReview(
        documentUploadIds: const <String>['upload-1'],
        idempotencyKey: 'key-2',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });
  });

  group('attaching a document — F28', () {
    test('declines and does not post a document slot', () async {
      final Result<KycDocument> result = await repository.attachDocument(
        type: KycDocumentType.identityDocument,
        fileName: 'sample-id.jpg',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'image/jpeg',
        idempotencyKey: 'key-3',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(transport.requests, isEmpty);
    });

    test('loading documents declines rather than guessing a type', () async {
      final Result<List<KycDocument>> result = await repository.loadDocuments();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });

    test('there is no selfie or biometric type to send', () {
      // A facial image is not revocable the way a password is, and a released
      // build cannot be trusted to grade its own verification. Adding a value
      // here is not a small change, so the absence is asserted rather than
      // assumed.
      expect(KycDocumentType.values, hasLength(2));
      for (final KycDocumentType type in KycDocumentType.values) {
        for (final String forbidden in <String>[
          'selfie',
          'face',
          'live',
          'biometric',
        ]) {
          expect(type.wireValue, isNot(contains(forbidden)), reason: forbidden);
          expect(
            type.label.toLowerCase(),
            isNot(contains(forbidden)),
            reason: forbidden,
          );
        }
      }
    });
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
