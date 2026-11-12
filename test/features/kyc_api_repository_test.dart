import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

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
    test('a profile claim is not the verification start', () async {
      final Result<VerificationStatus> result = await repository.openCase(
        claim: claimOf(),
        idempotencyKey: 'key-1',
      );

      // A birth date, a barangay code and a street address stay on the device.
      // Start is `POST me/verification-requests` with the ID photos.
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
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
    test('an identity photo replaces id_front', () async {
      transport.responses.add(
        _envelope(200, <String, Object?>{
          'status': 'rejected',
          'can_edit': true,
          'id_front_media_id': '11111111-1111-4111-8111-111111111111',
        }),
      );

      final Result<KycDocument> result = await repository.attachDocument(
        type: KycDocumentType.identityDocument,
        fileName: 'sample-id.jpg',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'image/jpeg',
        idempotencyKey: 'key-3',
      );

      expect(result.isOk, isTrue);
      expect(transport.requests, hasLength(1));
      expect(
        transport.requests.single.path,
        'me/verification-requests/current/documents',
      );
      expect(transport.requests.single.files.single.field, 'id_front');
      expect(transport.requests.single.headers['Idempotency-Key'], 'key-3');
    });

    test('proof of address is not a documents slot', () async {
      final Result<KycDocument> result = await repository.attachDocument(
        type: KycDocumentType.proofOfAddress,
        fileName: 'sample-bill.jpg',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: 'image/jpeg',
        idempotencyKey: 'key-4',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('documents are read from the current request', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(
          ApiHttpResponse(
            statusCode: 200,
            body: jsonEncode(<String, Object?>{
              'data': <String, Object?>{
                'id': '00000000-0000-4000-8000-000000000001',
                'status': 'pending',
                'id_type': 'philid',
                'id_front_media_id': '00000000-0000-4000-8000-000000000002',
                'id_back_media_id': null,
                'selfie_media_id': '00000000-0000-4000-8000-000000000003',
                'submitted_at': '2026-11-05T01:00:00Z',
                'can_edit': true,
                'submitted_categories': <String>[
                  'philid',
                  'id_front',
                  'selfie',
                ],
                'issues': <Object?>[],
              },
            }),
          ),
        ),
      );

      final Result<List<KycDocument>> result = await repository.loadDocuments();

      expect(transport.requests.single.method, HttpMethod.get);
      expect(
        transport.requests.single.path,
        'me/verification-requests/current',
      );
      final List<KycDocument> rows = result.valueOrNull!;
      expect(rows.map((KycDocument d) => d.type), KycDocumentType.values);
      expect(rows.first.isAttached, isTrue);
      expect(rows.first.receivedAt, DateTime.utc(2026, 11, 5, 1));
      expect(rows.last.isAttached, isFalse);
    });

    test('no request yet is every row unattached, not an error', () async {
      transport.responses.add(
        Ok<ApiHttpResponse>(
          ApiHttpResponse(
            statusCode: 404,
            body: jsonEncode(<String, Object?>{
              'error': <String, Object?>{
                'code': 'NOT_FOUND',
                'message': 'operator text',
              },
            }),
          ),
        ),
      );

      final Result<List<KycDocument>> result = await repository.loadDocuments();

      expect(result.valueOrNull, hasLength(KycDocumentType.values.length));
      expect(
        result.valueOrNull!.every((KycDocument d) => !d.isAttached),
        isTrue,
      );
    });

    test('there is no separate submit on the Node API', () async {
      final Result<void> result = await repository.submitForReview(
        documentUploadIds: const <String>[],
        idempotencyKey: 'key-5',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
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

  group('citizen verification writes', () {
    final VerificationImagePart photo = VerificationImagePart(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'sample.jpg',
      mimeType: 'image/jpeg',
    );

    test('start posts the ID photos and not a claim', () async {
      transport.responses.add(
        _envelope(201, <String, Object?>{'status': 'pending'}),
      );

      final Result<VerificationStatus> result = await repository
          .submitVerification(
            idType: 'philid',
            front: photo,
            selfie: photo,
            idempotencyKey: 'start-1',
          );

      expect((result as Ok<VerificationStatus>).value.rawState, 'pending');
      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, 'me/verification-requests');
      // The key rides in the multipart body, where this route reads it; the
      // API reads no `Idempotency-Key` header (backend `0ff7682`, D-213).
      expect(request.body, <String, Object?>{
        'id_type': 'philid',
        'idempotency_key': 'start-1',
      });
      expect(request.headers.containsKey('Idempotency-Key'), isFalse);
      expect(request.files.map((MultipartFile file) => file.field), <String>[
        'id_front',
        'selfie',
      ]);
      expect(request.headers.containsKey('X-Role'), isFalse);
    });

    test('a start with no key sends none (older callers)', () async {
      transport.responses.add(
        _envelope(201, <String, Object?>{'status': 'pending'}),
      );
      await repository.submitVerification(
        idType: 'philid',
        front: photo,
        selfie: photo,
      );
      expect(transport.requests.single.body, <String, Object?>{
        'id_type': 'philid',
      });
    });

    test('re-upload posts only the images that changed', () async {
      transport.responses.add(
        _envelope(200, <String, Object?>{
          'status': 'rejected',
          'can_edit': true,
          'message': null,
          'notes': 'staff-only',
        }),
      );

      final Result<VerificationStatusDetail> result = await repository
          .replaceDocuments(selfie: photo);

      expect(result.isOk, isTrue);
      final ApiRequest request = transport.requests.single;
      expect(request.path, 'me/verification-requests/current/documents');
      expect(request.files.single.field, 'selfie');
      expect(request.body, isNull);
    });

    test('corrections post the citizen message and return pending', () async {
      transport.responses.add(
        _envelope(200, <String, Object?>{
          'status': 'pending',
          'message': 'Please review my verification again.',
          'can_edit': true,
          'notes': 'do-not-echo',
        }),
      );

      final Result<void> result = await repository.submitCorrections(
        corrections: const <CorrectableField, String>{},
        idempotencyKey: 'corr-1',
        message: 'Please review my verification again.',
      );

      expect(result.isOk, isTrue);
      final ApiRequest request = transport.requests.single;
      expect(request.path, 'me/verification-requests/current/corrections');
      expect(request.body, <String, Object?>{
        'message': 'Please review my verification again.',
      });
      expect(request.body, isNot(contains('notes')));
    });

    test('an empty correction does not leave the device', () async {
      final Result<void> result = await repository.submitCorrections(
        corrections: const <CorrectableField, String>{},
        idempotencyKey: 'corr-2',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(transport.requests, isEmpty);
    });

    test('the citizen fields are read and notes are not', () async {
      transport.responses.add(
        _envelope(200, <String, Object?>{
          'status': 'rejected',
          'message': 'Please look again.',
          'submitted_at': '2026-10-20T12:40:00Z',
          'created_at': '2026-01-01T00:00:00Z',
          'can_edit': true,
          'submitted_categories': <String>['id_front', 'selfie', 'unknown'],
          'issues': <Object>[
            <String, String>{
              'category': 'id_front',
              'message': 'The photo is blurry.',
            },
            <String, String>{'category': 'secret', 'message': 'hidden'},
          ],
          'notes': 'staff note that must not be copied',
        }),
      );

      final Result<VerificationStatusDetail> result = await repository
          .loadOwnStatusDetail();
      final VerificationStatusDetail detail =
          (result as Ok<VerificationStatusDetail>).value;

      expect(detail.rawState, 'rejected');
      expect(detail.residentGuidance, 'Please look again.');
      expect(detail.canEdit, isTrue);
      expect(detail.submittedAt, DateTime.utc(2026, 10, 20, 12, 40));
      expect(detail.submittedCategories, <VerificationItemCategory>[
        VerificationItemCategory.identityDocument,
        VerificationItemCategory.photo,
      ]);
      expect(detail.issues, hasLength(2));
      expect(detail.issues.first.instruction, 'The photo is blurry.');
      expect(detail.issues.last.category, VerificationItemCategory.other);
      expect(detail.issues.last.instruction, 'hidden');
      expect(detail.toString(), isNot(contains('staff note')));
      expect(detail.toString(), isNot(contains('secret')));
      expect(detail.toString(), isNot(contains('Please look')));
    });
  });
}

Ok<ApiHttpResponse> _envelope(int status, Map<String, Object?> data) {
  return Ok<ApiHttpResponse>(
    ApiHttpResponse(
      statusCode: status,
      body: jsonEncode(<String, Object?>{
        'data': data,
        'meta': <String, Object?>{},
      }),
      headers: const <String, String>{'content-type': 'application/json'},
    ),
  );
}
