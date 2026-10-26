import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_envelope.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/auth/data/firebase_identity.dart';
import 'package:taytay_resident/features/credential/data/credential_api_repository.dart';
import 'package:taytay_resident/features/credential/domain/credential_repository.dart';
import 'package:taytay_resident/features/directory/data/office_api_repository.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/household/data/household_api_repository.dart';
import 'package:taytay_resident/features/household/domain/household_summary.dart';
import 'package:taytay_resident/features/notifications/data/notification_api_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_inbox_controller.dart';
import 'package:taytay_resident/features/registration/data/barangay_api_repository.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

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

class _SwapToken implements TokenRefresher {
  _SwapToken(this.onRefresh);

  final Future<String?> Function() onRefresh;
  int calls = 0;

  @override
  Future<String?> refresh() async {
    calls++;
    return onRefresh();
  }
}

class _CursorRepo implements NotificationRepository {
  final List<String?> cursors = <String?>[];

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 20,
    String? cursor,
  }) async {
    cursors.add(cursor);
    if (cursor == null) {
      return Ok<Paginated<ResidentNotification>>(
        Paginated<ResidentNotification>(
          items: <ResidentNotification>[_notice('n-1')],
          page: 1,
          perPage: perPage,
          total: 2,
          totalPages: 2,
          hasMore: true,
          nextCursor: 'page-2',
        ),
      );
    }
    return Ok<Paginated<ResidentNotification>>(
      Paginated<ResidentNotification>(
        items: <ResidentNotification>[_notice('n-2')],
        page: 2,
        perPage: perPage,
        total: 2,
        totalPages: 2,
        hasMore: false,
      ),
    );
  }

  @override
  Future<Result<void>> markRead(String id) async => const Ok<void>(null);

  @override
  Future<Result<void>> markAllRead() async => const Ok<void>(null);

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async =>
      const Err<NotificationPreferences>(ServerFailure());

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async => const Ok<void>(null);

  @override
  Future<Result<String>> registerPushToken(String token) async =>
      const Err<String>(ServerFailure());
}

ResidentNotification _notice(String id) => ResidentNotification(
  id: id,
  title: 'Notice',
  body: 'Open the app.',
  sentAt: DateTime.utc(2026, 8, 1),
  readAt: null,
);

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

Result<ApiHttpResponse> _ok(Object? data, {Map<String, Object?>? pagination}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{
            'request_id': 'req-1',
            'pagination': ?pagination,
          },
        }),
      ),
    );

Result<ApiHttpResponse> _problem(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': code,
            'message': 'operator text that must not be shown',
          },
        }),
      ),
    );

String? _authorization(ApiRequest request) {
  for (final MapEntry<String, String> header in request.headers.entries) {
    if (header.key.toLowerCase() == 'authorization') return header.value;
  }
  return null;
}

void main() {
  test('phone numbers become E.164 and tokens refresh a minute early', () {
    expect(philippineE164('0917 000 0000'), '+639170000000');
    expect(philippineE164('+63 917 000 0000'), '+639170000000');
    expect(philippineE164('123'), isNull);

    final DateTime now = DateTime.utc(2026, 8, 1, 12);
    expect(
      firebaseTokenNeedsRefresh(
        expiresAt: now.add(const Duration(seconds: 30)),
        now: now,
        force: false,
      ),
      isTrue,
    );
    expect(
      firebaseTokenNeedsRefresh(
        expiresAt: now.add(const Duration(minutes: 10)),
        now: now,
        force: false,
      ),
      isFalse,
    );
    expect(
      firebaseTokenNeedsRefresh(expiresAt: null, now: now, force: true),
      isTrue,
    );
  });

  test('password change stays on the Firebase SDK', () {
    final String source = File(
      'lib/features/account/data/firebase_account_password_client.dart',
    ).readAsStringSync();
    expect(source, contains('reauthenticateWithCredential'));
    expect(source, contains('updatePassword'));
    expect(source, isNot(contains('HttpMethod')));
  });

  test(
    'an authenticated call sends the Firebase ID token and retries once',
    () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _problem(401, 'UNAUTHENTICATED'),
        _ok(<String, Object?>{'id': 'user-1', 'name': 'Juana Sample'}),
      ]);
      String bearer = 'stale-id-token';
      var ended = false;
      final _SwapToken refresher = _SwapToken(() async {
        bearer = 'fresh-id-token';
        return bearer;
      });
      final ApiClient client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => bearer,
        onUnauthenticated: () async {
          ended = true;
        },
        authCoordinator: AuthCoordinator(refresher: refresher),
      );

      final Result<ApiEnvelope<String>> result = await client.send<String>(
        method: HttpMethod.get,
        path: 'me',
        authenticated: true,
        decode: (Object? data) =>
            data is Map<String, dynamic> ? data['id'] as String : '',
      );

      expect(result.isOk, isTrue);
      expect(refresher.calls, 1);
      expect(ended, isFalse);
      expect(transport.requests, hasLength(2));
      expect(_authorization(transport.requests[0]), 'Bearer stale-id-token');
      expect(_authorization(transport.requests[1]), 'Bearer fresh-id-token');
      expect(
        transport.requests.map((ApiRequest request) => request.path),
        everyElement('me'),
      );
    },
  );

  test('a public barangay read stays anonymous when a token exists', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[
        <String, Object?>{'id': 'b-1', 'name': 'San Juan'},
      ]),
    ]);
    final ApiClient client = ApiClient(
      config: _config(),
      transport: transport,
      accessTokenProvider: () async => 'firebase-id-token',
    );

    final result = await BarangayApiRepository(
      apiClient: client,
    ).listBarangays();

    expect(result.isOk, isTrue);
    expect(transport.requests.single.path, 'barangays');
    expect(_authorization(transport.requests.single), isNull);
  });

  test('household decode reads the 3e3b110 member fields', () {
    final HouseholdSummary summary = HouseholdApiRepository.decodeHousehold(
      <String, Object?>{
        'id': 'hh-9',
        'address': '1 Sample Road',
        'barangay_name': 'Dolores',
        'viewer_role': 'member',
        'members': <Object?>[
          <String, Object?>{
            'id': 'm-9',
            'name': 'Ana Sample',
            'relationship': 'child',
            'birthdate': '2015-04-04',
            'sex': 'unspecified',
            'invite_status': 'pending',
          },
          <String, Object?>{'name': 'Dropped Sample'},
        ],
      },
    );

    expect(summary.role, HouseholdRole.member);
    expect(summary.memberCount, 1);
    expect(summary.members.single.relationship, HouseholdRelationship.child);
    expect(summary.members.single.sex, HouseholdSex.unspecified);
    expect(summary.members.single.inviteStatus, HouseholdInviteStatus.pending);
    final DateTime? birthdate = summary.members.single.birthdate;
    expect(birthdate?.year, 2015);
    expect(birthdate?.month, 4);
    expect(birthdate?.day, 4);
    expect(summary.toString(), isNot(contains('Ana')));
    expect(summary.toString(), isNot(contains('hh-9')));
  });

  test(
    'digital ID 404 and a null card stay not issued, and the QR is redacted',
    () async {
      final _Scripted missing = _Scripted(<Result<ApiHttpResponse>>[
        _problem(404, 'NOT_FOUND'),
      ]);
      final Result<ResidentCredential?> notFound =
          await CredentialApiRepository(
            apiClient: ApiClient(
              config: _config(),
              transport: missing,
              accessTokenProvider: () async => 'firebase-id-token',
            ),
          ).loadOwnCredential();
      expect(notFound.valueOrNull, isNull);
      expect(missing.requests.single.path, 'me/digital-id');

      expect(CredentialApiRepository.decodeDigitalId(null), isNull);

      final ResidentCredential? card = CredentialApiRepository.decodeDigitalId(
        <String, Object?>{
          'id': 'card-1',
          'id_number': 'TY-0001',
          'photo_media_id': 'media-1',
          'status': 'active',
          'issued_at': '2026-01-01T00:00:00Z',
          'expires_at': '2027-01-01T00:00:00Z',
          'qr': <String, Object?>{
            'token': 'qr-secret-token',
            'expires_at': '2026-01-01T00:05:00Z',
          },
        },
      );
      expect(card!.idNumber, 'TY-0001');
      expect(card.photoMediaId, 'media-1');
      expect(card.state, CredentialLifecycleState.active);
      final PresentationArtifact? qr = card.qr;
      expect(qr, isNotNull);
      expect(card.toString(), isNot(contains('qr-secret-token')));
      expect(card.toString(), isNot(contains('TY-0001')));
      expect(qr!.toString(), isNot(contains('qr-secret-token')));

      final ResidentCredential? suspended =
          CredentialApiRepository.decodeDigitalId(<String, Object?>{
            'id': 'card-2',
            'status': 'suspended',
            'qr': null,
          });
      expect(suspended!.state, CredentialLifecycleState.suspended);
      expect(suspended.qr, isNull);
    },
  );

  test('verification reads the request fields and drops staff notes', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<String, Object?>{
        'id': 'vr-1',
        'user_id': 'user-1',
        'id_type': 'philid',
        'id_front_media_id': 'front-1',
        'id_back_media_id': 'back-1',
        'selfie_media_id': 'selfie-1',
        'status': 'pending',
        'notes': 'Bring the card to the hall.',
        'created_at': '2026-08-01T00:00:00Z',
        'reviewed_at': null,
        'internal_notes': 'staff only',
        'reviewer_id': 'staff-1',
      }),
    ]);
    final Result<VerificationStatusDetail> result = await KycApiRepository(
      apiClient: ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'firebase-id-token',
      ),
    ).loadOwnStatusDetail();

    final VerificationStatusDetail detail =
        (result as Ok<VerificationStatusDetail>).value;
    expect(detail.id, 'vr-1');
    expect(detail.userId, 'user-1');
    expect(detail.idType, 'philid');
    expect(detail.idFrontMediaId, 'front-1');
    expect(detail.idBackMediaId, 'back-1');
    expect(detail.selfieMediaId, 'selfie-1');
    expect(detail.rawState, 'pending');
    expect(detail.residentGuidance, 'Bring the card to the hall.');
    expect(detail.submittedCategories, isEmpty);
    expect(detail.issues, isEmpty);
    expect(detail.toString(), isNot(contains('staff only')));
    expect(detail.toString(), isNot(contains('staff-1')));
  });

  test(
    'an office keeps the hall photo and reads banner and coordinates',
    () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(<Object?>[
          <String, Object?>{
            'id': 'office-1',
            'name': 'Mayor\'s Office',
            'slug': 'mayors-office',
            'address': 'Municipal Hall, Taytay',
            'banner_media_id': 'banner-1',
            'latitude': 14.56,
            'longitude': 121.13,
          },
        ]),
      ]);
      final result = await OfficeApiRepository(
        apiClient: ApiClient(config: _config(), transport: transport),
      ).list();

      final Office office = result.valueOrNull!.offices.single;
      expect(office.bannerMediaId, 'banner-1');
      expect(office.latitude, 14.56);
      expect(office.longitude, 121.13);
      expect(office.heroAsset, 'assets/photos/municipal_hall.jpg');
      expect(office.insetAsset, 'assets/photos/municipal_hall.jpg');
      expect(office.directionsQuery, 'Municipal Hall, Taytay');
    },
  );

  test(
    'notifications page with next_cursor and do not relabel message_received',
    () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(
          <Object?>[
            <String, Object?>{
              'id': 'n-1',
              'title': 'Verified',
              'body': 'Open the app.',
              'type': 'verification_decided',
              'created_at': '2026-08-01T00:00:00Z',
            },
          ],
          pagination: <String, Object?>{
            'has_more': true,
            'next_cursor': 'cursor-2',
          },
        ),
        _ok(<Object?>[
          <String, Object?>{
            'id': 'n-2',
            'title': 'Message',
            'body': 'Open the app.',
            'type': 'message_received',
            'created_at': '2026-08-02T00:00:00Z',
          },
        ]),
      ]);
      final NotificationApiRepository repository = NotificationApiRepository(
        apiClient: ApiClient(
          config: _config(),
          transport: transport,
          accessTokenProvider: () async => 'firebase-id-token',
        ),
      );

      final Result<Paginated<ResidentNotification>> first = await repository
          .listOwn(page: 1);
      final Paginated<ResidentNotification> page =
          (first as Ok<Paginated<ResidentNotification>>).value;
      expect(page.nextCursor, 'cursor-2');
      expect(
        page.items.single.category?.known,
        NotificationCategory.verificationUpdate,
      );
      expect(page.items.single.target['type'], 'verification_decided');
      expect(transport.requests.single.query.containsKey('cursor'), isFalse);

      final Result<Paginated<ResidentNotification>> second = await repository
          .listOwn(page: 2, cursor: page.nextCursor);
      final ResidentNotification message =
          (second as Ok<Paginated<ResidentNotification>>).value.items.single;
      expect(transport.requests[1].query['cursor'], 'cursor-2');
      expect(
        message.category?.known,
        isNot(NotificationCategory.accountSecurity),
      );
      expect(message.category?.raw, 'message_received');
      expect(message.target['type'], 'message_received');
    },
  );

  test(
    'the inbox loads the next cursor and does not repeat page one',
    () async {
      final _CursorRepo repository = _CursorRepo();
      final NotificationInboxController controller =
          NotificationInboxController(
            repository: repository,
            clock: () => DateTime.utc(2026, 8, 20),
          );

      await controller.refresh();
      expect(controller.hasMore, isTrue);
      await controller.loadMore();

      expect(repository.cursors, <String?>[null, 'page-2']);
      expect(
        controller.items.map((ResidentNotification item) => item.id),
        <String>['n-1', 'n-2'],
      );
      expect(controller.hasMore, isFalse);
    },
  );
}
