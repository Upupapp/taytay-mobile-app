import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/deep_link.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/mock_data/data/mock/taytay_mocks.dart';
import 'package:taytay_resident/features/notifications/data/notification_api_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/sectors/presentation/sectors_copy.dart';

/// D-216: the sector notice opens Sectors and benefits, with no id on the way.
///
/// Synthetic: the ids are made up and nobody here is a real resident.
const String _applicationId = '00000000-0000-4000-8000-000000000215';

Map<String, Object?> _notice(String type, String title) => <String, Object?>{
  'id': 'n-$type',
  'type': type,
  'title': title,
  'body': 'Open the app to see it.',
  'subject_id': _applicationId,
  'read_at': null,
  'created_at': '2026-11-12T05:20:00Z',
};

/// Answers every request with the same page of notices.
class _Always implements ApiTransport {
  _Always(this.rows);

  final List<Object?> rows;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'data': rows,
            'meta': <String, Object?>{'request_id': 'req-ok'},
          }),
          headers: const <String, String>{'x-request-id': 'req-ok'},
        ),
      );
}

NotificationApiRepository _api(List<Object?> rows) => NotificationApiRepository(
  apiClient: ApiClient(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    transport: _Always(rows),
    accessTokenProvider: () async => 'tok',
  ),
);

Future<ResidentNotification> _decoded(Map<String, Object?> row) async =>
    (await _api(<Object?>[row]).listOwn()).valueOrNull!.items.single;

/// The dev mock's inbox, except that the list is decoded from the wire by the
/// live repository, so the tap goes through the real kind-to-target mapping.
class _Inbox extends MockNotificationRepository {
  _Inbox(super.gate, this._rows);

  final List<Object?> _rows;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 15,
    String? cursor,
  }) => _api(_rows).listOwn(cursor: cursor);
}

Future<void> _openInbox(WidgetTester tester, List<Object?> rows) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  await store.write(
    const StoredSession(
      resident: ResidentSession(
        accountId: 'acct-sample',
        accessLevel: AccessLevel.verified,
        displayName: 'Ana',
      ),
      accessToken: 'token-sample',
    ),
  );
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: '',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  final AppDependencies dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    network: base.network,
    telemetry: base.telemetry,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    residentRecordRepository: base.residentRecordRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: _Inbox(
      MockBehaviorController(
        latency: Duration.zero,
        failure: MockFailureMode.none,
      ),
      rows,
    ),
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    mockBehavior: base.mockBehavior,
    officeMessaging: base.officeMessagingRepository,
    socialServices: base.socialServiceRepository,
    issuance: base.issuanceRepository,
    sectors: base.sectorRepository,
    passwordClient: base.accountPasswordClient,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(
    tester.element(find.byType(Scaffold).first),
  ).go(AppRoute.notifications.path);
  await tester.pumpAndSettle();
}

String _location(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

void main() {
  group('the notice maps to a place, not a record', () {
    test('sector_application_decided targets /sectors with no id', () async {
      final ResidentNotification notice = await _decoded(
        _notice('sector_application_decided', 'Sector application decided'),
      );

      expect(notice.target[DeepLink.targetKey], 'sector_applications');
      expect(notice.target.containsKey(DeepLink.idKey), isFalse);
      final DeepLinkResult link = DeepLink.resolve(notice.target);
      expect(link, isA<DeepLinkResolved>());
      final DeepLinkTarget target = (link as DeepLinkResolved).target;
      expect(target.route, AppRoute.sectors);
      expect(target.location, '/sectors');
    });

    test('a kind this build does not know still opens nothing', () async {
      final ResidentNotification notice = await _decoded(
        _notice('sector_application_audited', 'Something new'),
      );

      expect(notice.target.containsKey(DeepLink.targetKey), isFalse);
      expect(
        DeepLink.resolve(notice.target),
        isA<DeepLinkRejected>().having(
          (DeepLinkRejected r) => r.reason,
          'reason',
          DeepLinkRejection.unknownTarget,
        ),
      );
    });

    test('an id on the sectors target is still refused', () {
      expect(
        DeepLink.resolve(<String, String>{
          DeepLink.targetKey: 'sector_applications',
          DeepLink.idKey: _applicationId,
        }),
        isA<DeepLinkRejected>().having(
          (DeepLinkRejected r) => r.reason,
          'reason',
          DeepLinkRejection.wrongArity,
        ),
      );
    });

    test('a record notice keeps its id', () async {
      final ResidentNotification notice = await _decoded(
        _notice('issuance_request_updated', 'Your request changed'),
      );
      expect(notice.target[DeepLink.idKey], _applicationId);
      expect(notice.target[DeepLink.targetKey], 'issuance_request');
    });
  });

  group('tapping the notice in the inbox', () {
    testWidgets('opens Sectors and benefits', (tester) async {
      await _openInbox(tester, <Object?>[
        _notice('sector_application_decided', 'Sector application decided'),
      ]);
      expect(_location(tester), AppRoute.notifications.path);

      await tester.tap(find.text('Sector application decided'));
      await tester.pumpAndSettle();

      expect(_location(tester), AppRoute.sectors.path);
      expect(find.text(SectorsCopy.title), findsWidgets);
    });

    testWidgets('an unknown kind stays in the inbox', (tester) async {
      await _openInbox(tester, <Object?>[
        _notice('sector_application_audited', 'Something new'),
      ]);

      await tester.tap(find.text('Something new'));
      await tester.pumpAndSettle();

      expect(_location(tester), AppRoute.notifications.path);
      expect(find.text(SectorsCopy.title), findsNothing);
    });
  });
}
