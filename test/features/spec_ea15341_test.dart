import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/credential/data/credential_api_repository.dart';
import 'package:taytay_resident/features/credential/domain/digital_id.dart';
import 'package:taytay_resident/features/household/data/household_api_repository.dart';
import 'package:taytay_resident/features/household/domain/household_record.dart';
import 'package:taytay_resident/features/mock_data/data/mock/taytay_mocks.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_api_repository.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';

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

Result<ApiHttpResponse> ok(Object data, {int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

Result<ApiHttpResponse> apiError(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': code,
            'message': 'operator text',
            'details': <String, Object?>{},
            'request_id': 'req-1',
          },
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

ApiClient _clientFor(_Scripted transport) => ApiClient(
  config: AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  ),
  transport: transport,
  accessTokenProvider: () async => 'tok',
);

Map<String, Object?> cardBody({
  required String token,
  required String qrExpires,
}) => <String, Object?>{
  'id': '00000000-0000-4000-8000-0000000000e1',
  'id_number': 'SAMPLE-ID-0001',
  'photo_media_id': '00000000-0000-4000-8000-0000000000e2',
  'status': 'active',
  'issued_at': '2026-01-01T00:00:00.000Z',
  'expires_at': '2027-01-01T00:00:00.000Z',
  'qr': <String, Object?>{'token': token, 'expires_at': qrExpires},
};

Map<String, Object?> householdBody() => <String, Object?>{
  'id': '00000000-0000-4000-8000-0000000000a1',
  'address': 'Sample Street',
  'barangay_id': '00000000-0000-4000-8000-0000000000b1',
  'barangay_name': 'San Juan',
  'head_user_id': '00000000-0000-4000-8000-0000000000c1',
  'viewer_role': 'head',
  'created_at': '2026-01-01T00:00:00.000Z',
  'members': <Object>[
    <String, Object?>{
      'id': '00000000-0000-4000-8000-0000000000d1',
      'name': 'Sample Head',
      'relationship': 'head',
      'birthdate': '1990-01-02',
      'sex': 'unspecified',
      'user_id': '00000000-0000-4000-8000-0000000000c1',
      'invite_status': 'accepted',
    },
  ],
};

void main() {
  final DateTime issued = DateTime.utc(2026, 6, 1, 12);

  group('digital ID', () {
    test('a verified read keeps the QR until the refresh window', () async {
      final _Scripted transport = _Scripted();
      transport.responses.add(
        ok(
          cardBody(
            token: 'sample-qr-a',
            qrExpires: issued.add(digitalIdQrLifetime).toIso8601String(),
          ),
        ),
      );
      transport.responses.add(
        ok(
          cardBody(
            token: 'sample-qr-b',
            qrExpires: issued
                .add(digitalIdQrLifetime)
                .add(digitalIdQrLifetime)
                .toIso8601String(),
          ),
        ),
      );
      final CredentialApiRepository repository = CredentialApiRepository(
        apiClient: _clientFor(transport),
      );

      final DigitalIdCard first = (await repository.loadDigitalId(
        now: issued,
      )).valueOrNull!;
      final DigitalIdCard again = (await repository.loadDigitalId(
        now: issued.add(const Duration(seconds: 30)),
      )).valueOrNull!;
      final DigitalIdCard refreshed = (await repository.loadDigitalId(
        now: issued.add(digitalIdQrLifetime - const Duration(seconds: 10)),
      )).valueOrNull!;

      expect(first.qr?.token, 'sample-qr-a');
      expect(again.qr?.token, 'sample-qr-a');
      expect(refreshed.qr?.token, 'sample-qr-b');
      expect(first.expiresAt, DateTime.utc(2027, 1, 1));
      expect(first.qr!.expiresAt.difference(issued), digitalIdQrLifetime);
      expect(transport.requests, hasLength(2));
      expect(
        transport.requests.every(
          (ApiRequest request) =>
              request.method == HttpMethod.get &&
              request.path == 'me/digital-id',
        ),
        isTrue,
      );
      expect(first.toString(), isNot(contains('sample-qr-a')));
      expect(first.qr.toString(), isNot(contains('sample-qr-a')));
      expect(first.toString(), isNot(contains('SAMPLE-ID-0001')));
    });

    test('an unverified resident is refused and no card is invented', () async {
      final _Scripted transport = _Scripted();
      transport.responses.add(apiError(403, 'FORBIDDEN'));
      final CredentialApiRepository repository = CredentialApiRepository(
        apiClient: _clientFor(transport),
      );

      final Result<DigitalIdCard> result = await repository.loadDigitalId(
        now: issued,
      );

      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(
        result.failureOrNull!.residentMessage,
        isNot(contains('operator')),
      );
      expect(transport.requests.single.path, 'me/digital-id');
    });

    test('the staff scan is on the interface and is not sent', () async {
      final _Scripted transport = _Scripted();
      final CredentialApiRepository repository = CredentialApiRepository(
        apiClient: _clientFor(transport),
      );

      final Result<DigitalIdHolder> result = await repository
          .verifyScannedToken(token: 'sample-qr-a');

      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(transport.requests, isEmpty);
      final String source = File(
        'lib/features/credential/data/credential_api_repository.dart',
      ).readAsStringSync();
      expect(RegExp(r"path:\s*'digital-id/verify'").hasMatch(source), isFalse);
      final String screen = File(
        'lib/features/credential/presentation/digital_id_screen.dart',
      ).readAsStringSync();
      expect(screen, isNot(contains('DigitalIdCard')));
    });

    test('the mock refreshes before the two-minute QR expires', () async {
      final MockCredentialRepository repository = MockCredentialRepository(
        MockBehaviorController(
          latency: Duration.zero,
          failure: MockFailureMode.none,
        ),
      );

      final DigitalIdCard first = (await repository.loadDigitalId(
        now: issued,
      )).valueOrNull!;
      final DigitalIdCard held = (await repository.loadDigitalId(
        now: issued.add(const Duration(seconds: 20)),
      )).valueOrNull!;
      final DigitalIdCard refreshed = (await repository.loadDigitalId(
        now: issued.add(digitalIdQrLifetime - digitalIdQrRefreshLead),
      )).valueOrNull!;
      final Result<DigitalIdCard> refused = await MockCredentialRepository(
        MockBehaviorController(
          latency: Duration.zero,
          failure: MockFailureMode.none,
        ),
        verified: false,
      ).loadDigitalId(now: issued);

      expect(held.qr?.token, first.qr?.token);
      expect(refreshed.qr?.token, isNot(first.qr?.token));
      expect(
        refreshed.qr!.expiresAt.difference(
          issued.add(digitalIdQrLifetime - digitalIdQrRefreshLead),
        ),
        digitalIdQrLifetime,
      );
      expect(first.toString(), isNot(contains('sample-qr')));
      expect(refused.failureOrNull, isA<ForbiddenFailure>());
      expect(refused.failureOrNull.toString(), isNot(contains('sample-qr')));
    });
  });

  group('household', () {
    test('member, leave, transfer, and invitation routes match the spec', () async {
      final _Scripted transport = _Scripted();
      final HouseholdApiRepository repository = HouseholdApiRepository(
        apiClient: _clientFor(transport),
      );
      transport.responses.add(ok(householdBody(), status: 201));
      transport.responses.add(
        ok(<String, Object?>{
          'id': '00000000-0000-4000-8000-0000000000d2',
          'name': 'Sample Relative',
          'relationship': 'child',
          'birthdate': '2015-04-02',
          'sex': 'unspecified',
          'user_id': null,
          'invite_status': 'none',
        }, status: 201),
      );
      transport.responses.add(
        ok(<String, Object?>{'id': 'm', 'deleted': true}),
      );
      transport.responses.add(ok(<String, Object?>{'left': true}));
      transport.responses.add(ok(householdBody()));
      transport.responses.add(
        ok(<String, Object?>{
          'id': '00000000-0000-4000-8000-0000000000f1',
          'household_id': '00000000-0000-4000-8000-0000000000a1',
          'address': 'Sample Street',
          'barangay_id': '00000000-0000-4000-8000-0000000000b1',
          'barangay_name': 'San Juan',
        }),
      );
      transport.responses.add(ok(householdBody()));
      transport.responses.add(ok(<String, Object?>{'declined': true}));

      expect(
        (await repository.createHousehold(
          address: 'Sample Street',
          barangayId: '00000000-0000-4000-8000-0000000000b1',
        )).valueOrNull?.viewerRole,
        HouseholdViewerRole.head,
      );
      final HouseholdMember? member = (await repository.addMember(
        const HouseholdMemberDraft(
          name: 'Sample Relative',
          relationship: HouseholdMemberRelationship.child,
          birthdate: '2015-04-02',
          sex: HouseholdSex.unspecified,
        ),
      )).valueOrNull;
      expect(member?.relationship, HouseholdRelationship.child);
      expect(member.toString(), isNot(contains('Sample')));
      expect((await repository.removeMember(member!.id)).isOk, isTrue);
      expect((await repository.leaveHousehold()).isOk, isTrue);
      expect(
        (await repository.transferHeadship(memberId: member.id)).isOk,
        isTrue,
      );
      expect(
        (await repository.loadCurrentInvitation()).valueOrNull?.id,
        '00000000-0000-4000-8000-0000000000f1',
      );
      expect(
        (await repository.acceptInvitation(
          '00000000-0000-4000-8000-0000000000f1',
        )).isOk,
        isTrue,
      );
      expect(
        (await repository.declineInvitation(
          '00000000-0000-4000-8000-0000000000f1',
        )).isOk,
        isTrue,
      );

      expect(
        transport.requests.map(
          (ApiRequest request) => '${request.method.wireValue} ${request.path}',
        ),
        <String>[
          'POST households',
          'POST households/current/members',
          'DELETE households/current/members/00000000-0000-4000-8000-0000000000d2',
          'POST households/current/leave',
          'POST households/current/transfer',
          'GET households/invitations/current',
          'POST households/invitations/00000000-0000-4000-8000-0000000000f1/accept',
          'POST households/invitations/00000000-0000-4000-8000-0000000000f1/decline',
        ],
      );
      final Object? createBody = transport.requests.first.body;
      expect(createBody, <String, Object?>{
        'address': 'Sample Street',
        'barangay_id': '00000000-0000-4000-8000-0000000000b1',
      });
      expect(
        transport.requests.any(
          (ApiRequest request) =>
              request.method == HttpMethod.get && request.path == 'households',
        ),
        isFalse,
      );
      expect(
        transport.requests.map((ApiRequest request) => request.path),
        isNot(contains('digital-id/verify')),
      );
    });

    test(
      'the mock creates, edits, transfers, and answers an invitation',
      () async {
        final MockBehaviorController gate = MockBehaviorController(
          latency: Duration.zero,
          failure: MockFailureMode.none,
        );
        final MockHouseholdRepository repository = MockHouseholdRepository(
          gate,
          startEmpty: true,
          invitation: const HouseholdInvitation(
            id: '00000000-0000-4000-8000-0000000000f1',
            householdId: '00000000-0000-4000-8000-0000000000a2',
            address: 'Invitation Street',
            barangayId: '00000000-0000-4000-8000-0000000000b1',
            barangayName: 'San Juan',
          ),
        );

        final HouseholdRecord created = (await repository.createHousehold(
          address: 'Sample Street',
          barangayId: '00000000-0000-4000-8000-0000000000b1',
        )).valueOrNull!;
        final HouseholdRecord patched = (await repository.updateCurrent(
          address: 'Revised Street',
        )).valueOrNull!;
        expect(patched.address, 'Revised Street');
        expect(patched.toString(), isNot(contains('Revised')));
        expect(
          (await repository.acceptInvitation(
            '00000000-0000-4000-8000-0000000000f1',
          )).failureOrNull,
          isA<ConflictFailure>(),
        );
        expect((await repository.deleteCurrent()).isOk, isTrue);
        final HouseholdRecord joined = (await repository.acceptInvitation(
          '00000000-0000-4000-8000-0000000000f1',
        )).valueOrNull!;
        expect(joined.viewerRole, HouseholdViewerRole.member);
        expect(joined.toString(), isNot(contains('Invitation')));
        expect((await repository.loadCurrentInvitation()).valueOrNull, isNull);

        final MockHouseholdRepository head = MockHouseholdRepository(
          gate,
          asHead: true,
        );
        final HouseholdRecord current = (await head.loadCurrent()).valueOrNull!;
        final HouseholdMember relative = current.members.firstWhere(
          (HouseholdMember member) =>
              member.relationship != HouseholdRelationship.head,
        );
        final HouseholdRecord transferred = (await head.transferHeadship(
          memberId: relative.id,
        )).valueOrNull!;
        expect(transferred.viewerRole, HouseholdViewerRole.member);
        expect(transferred.headUserId, relative.userId);
        expect(created.members.single.toString(), isNot(contains('Juana')));
      },
    );
  });

  group('profile street and purok', () {
    test('they are stored on the DTO and stay out of toString', () async {
      final _Scripted transport = _Scripted();
      transport.responses.add(
        ok(<String, Object?>{
          'id': '00000000-0000-4000-8000-0000000000c1',
          'firebase_uid': 'sample-resident',
          'email_verified': false,
          'verification_status': 'unverified',
          'rejection_reason': null,
          'role': 'registered',
          'closed': false,
          'street': 'Sample Street',
          'purok': 'Purok 4',
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
        }),
      );
      transport.responses.add(ok(<String, Object?>{}));
      final ResidentProfileApiRepository repository =
          ResidentProfileApiRepository(apiClient: _clientFor(transport));

      final detail = (await repository.loadOwnDetail()).valueOrNull;

      expect(detail?.street, 'Sample Street');
      expect(detail?.purok, 'Purok 4');
      expect(detail.toString(), isNot(contains('Sample Street')));
      expect(detail.toString(), isNot(contains('Purok 4')));

      expect(
        (await repository.updateContactDetails(
          update: const ContactDetailsUpdate(
            street: 'Sample Street',
            purok: 'Purok 4',
          ),
          idempotencyKey: 'once',
        )).isOk,
        isTrue,
      );
      expect(transport.requests[1].body, <String, Object?>{
        'street': 'Sample Street',
        'purok': 'Purok 4',
      });

      expect(
        (await repository.updateContactDetails(
          update: const ContactDetailsUpdate(purokOrSitio: 'Old Purok'),
          idempotencyKey: 'twice',
        )).isErr,
        isTrue,
      );
      expect(transport.requests, hasLength(2));
    });
  });
}
