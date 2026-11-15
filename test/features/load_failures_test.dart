// D-221: the items D-220 left. A failure of the office's side is not called
// "offline"; Try again shows that it is working and sends one read however
// often it is tapped; the screens whose data the server publishes topics for
// re-read quietly when those topics change.
//
// The inbox and the privacy notice are held in account_s8_test, the digital
// ID in digital_id_test, the events list in events_test.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/change_stream.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/live/live_message.dart';
import 'package:taytay_resident/core/live/live_updates.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/directory/presentation/directory_screen.dart';
import 'package:taytay_resident/features/household/presentation/household_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_catalogue_screen.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/features/settings/presentation/privacy_controls_screen.dart';
import 'package:taytay_resident/features/tulong/presentation/service_info_screen.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_screen.dart';
import 'package:taytay_resident/features/verification/domain/resident_record.dart';
import 'package:taytay_resident/features/verification/domain/resident_record_repository.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';

import '../support/layout_matrix.dart';

const ServerFailure _server = ServerFailure(requestId: 'req-synthetic');
final String _serverWords = _server.residentMessage;

AppConfig _dev() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawMockLatencyMs: '0',
);

ApiHttpResponse _page(List<Object?> data) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{
      'pagination': <String, Object?>{'has_more': false, 'next_cursor': null},
    },
  }),
);

ApiHttpResponse _item(Map<String, Object?> data) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{},
  }),
);

final ApiHttpResponse _serverError = ApiHttpResponse(
  statusCode: 500,
  body: jsonEncode(<String, Object?>{
    'error': <String, Object?>{
      'code': 'internal_error',
      'message': 'operator text',
      'details': null,
      'request_id': 'req-synthetic',
    },
  }),
);

Map<String, Object?> _service(String name, String slug) => <String, Object?>{
  'id': '11111111-1111-4111-8111-${slug.hashCode.abs() % 999999999999}',
  'name': name,
  'slug': slug,
  'summary': 'A synthetic summary',
  'details': 'Synthetic details for a test service.',
  'category': null,
  'requirements': const <String>['Bring an ID'],
  'contacts': const <Object?>[],
  'locations': const <Object?>[],
  'featured': false,
  'hidden_from_list': false,
  'created_at': '2026-07-01T00:00:00Z',
  'updated_at': '2026-07-01T00:00:00Z',
};

/// Answers each request from [answer], held behind [gate] while it is set,
/// and keeps every request it was sent.
class _Gated implements ApiTransport {
  _Gated(this.answer);

  Result<ApiHttpResponse> Function(ApiRequest request) answer;
  final List<ApiRequest> requests = <ApiRequest>[];
  Completer<void>? gate;

  int asked(String path) =>
      requests.where((ApiRequest request) => request.path == path).length;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    final Completer<void>? waiting = gate;
    if (waiting != null) await waiting.future;
    return answer(request);
  }
}

/// [base] with [live] (and a record repository) in place of its own.
AppDependencies _rebuild(
  AppDependencies base, {
  LiveUpdates? live,
  ResidentRecordRepository? records,
}) => AppDependencies(
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
  residentRecordRepository: records ?? base.residentRecordRepository,
  serviceRequestRepository: base.serviceRequestRepository,
  requirementRepository: base.requirementRepository,
  documentPicker: base.documentPicker,
  shareService: base.shareService,
  externalLinks: base.externalLinks,
  accountControlsRepository: base.accountControlsRepository,
  notificationRepository: base.notificationRepository,
  registrationRepository: base.registrationRepository,
  barangayDirectory: base.barangayDirectory,
  platform: base.platform,
  mockBehavior: base.mockBehavior,
  officeMessaging: base.officeMessagingRepository,
  socialServices: base.socialServiceRepository,
  issuance: base.issuanceRepository,
  sectors: base.sectorRepository,
  passwordClient: base.accountPasswordClient,
  live: live,
  onDispose: base.onDispose,
);

Widget _host(AppDependencies dependencies, Widget screen) =>
    AppDependenciesScope(
      dependencies: dependencies,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        home: screen,
      ),
    );

void _tallView(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(400, 1800);
  addTearDown(tester.view.reset);
}

/// A guest app over [transport], with no change stream.
AppDependencies _guest(_Gated transport) {
  final AppDependencies dependencies = AppDependencies.build(
    config: _dev(),
    transport: transport,
    secrets: InMemorySecretStore(),
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  addTearDown(dependencies.dispose);
  return dependencies;
}

/// A signed-in, verified app over a transport whose change stream the test
/// writes to.
class _LiveApp {
  _LiveApp._(this.dependencies, this.live, this.streams);

  final AppDependencies dependencies;
  final LiveUpdates live;
  final List<StreamController<String>> streams;

  static Future<_LiveApp> open(_Gated transport) async {
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
      config: _dev(),
      transport: transport,
      secrets: InMemorySecretStore(),
      sessionStore: store,
      localAuthenticator: const UnavailableLocalAuthenticator(),
    );
    await base.session.restore();
    final List<StreamController<String>> streams = <StreamController<String>>[];
    final LiveUpdates live = LiveUpdates(
      open: () async {
        streams.add(StreamController<String>());
        return ChangeStreamOpen(streams.last.stream);
      },
      session: base.session,
    );
    final AppDependencies dependencies = _rebuild(base, live: live);
    addTearDown(() {
      dependencies.dispose();
      for (final StreamController<String> stream in streams) {
        unawaited(stream.close());
      }
    });
    return _LiveApp._(dependencies, live, streams);
  }

  /// Opens the stream and reads its first `ready`, which is not a change.
  Future<void> connect(WidgetTester tester) async {
    live.handleLifecycle(AppLifecycleState.resumed);
    await tester.pump();
    expect(live.status, LiveStatus.open);
    streams.last.add('event: ready\ndata: {"topics":[]}\n\n');
    await tester.pump();
  }

  Future<void> change(WidgetTester tester, String topic) async {
    streams.last.add('event: change\ndata: {"topics":["$topic"]}\n\n');
    await tester.pump();
  }

  /// Closes the stream so no timer outlives the test.
  Future<void> close(WidgetTester tester) async {
    live.handleLifecycle(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
  }
}

class _Records implements ResidentRecordRepository {
  final List<Result<ResidentRecord>> answers = <Result<ResidentRecord>>[];
  Completer<void>? gate;
  int loads = 0;

  static const ResidentRecord record = ResidentRecord(
    givenName: 'Juana',
    familyName: 'Dela Cruz',
    barangayName: 'San Juan',
    verificationTier: 'pending',
    completeness: 60,
  );

  @override
  Future<Result<ResidentRecord>> load() async {
    loads++;
    final Completer<void>? waiting = gate;
    if (waiting != null) await waiting.future;
    return answers.isEmpty
        ? const Ok<ResidentRecord>(record)
        : answers.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('a failure of the office\'s side is not called offline', () {
    Future<void> pumpCanvas(WidgetTester tester, Widget canvas) async {
      await tester.pumpWidget(layoutHost(canvas, scrollable: false));
      await tester.pump();
    }

    testWidgets('Balita says the failure, and keeps offline for no '
        'connection', (tester) async {
      var retries = 0;
      await pumpCanvas(
        tester,
        BalitaCanvas(
          frame: BalitaFrame.failed,
          failure: _server,
          onRetry: () => retries++,
        ),
      );
      expect(find.text(_serverWords), findsOneWidget);
      expect(find.textContaining('Check your connection'), findsNothing);
      expect(find.text('Reference: req-synthetic'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);

      await pumpCanvas(
        tester,
        const BalitaCanvas(
          frame: BalitaFrame.failed,
          failure: NetworkFailure(),
        ),
      );
      expect(
        find.text('Announcements are not available right now'),
        findsOneWidget,
      );
      expect(find.text(_serverWords), findsNothing);
    });

    testWidgets('Tulong says the failure above the saved pages', (
      tester,
    ) async {
      await pumpCanvas(
        tester,
        TulongCanvas(
          frame: TulongFrame.offline,
          failure: _server,
          onRetry: () {},
        ),
      );
      expect(find.text(_serverWords), findsOneWidget);
      expect(find.text('Programme pages need a connection'), findsNothing);

      await pumpCanvas(
        tester,
        const TulongCanvas(
          frame: TulongFrame.offline,
          failure: TimeoutFailure(),
        ),
      );
      expect(find.text('Programme pages need a connection'), findsOneWidget);
    });

    testWidgets('Directory drops the "You\'re offline" strip for a server '
        'failure', (tester) async {
      var retries = 0;
      await pumpCanvas(
        tester,
        DirectoryCanvas(
          frame: DirectoryFrame.offline,
          offices: const <Office>[],
          failure: _server,
          onRetry: () => retries++,
        ),
      );
      expect(find.text(_serverWords), findsOneWidget);
      expect(find.text("You're offline"), findsNothing);
      expect(find.text("Can't load the directory"), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);

      await pumpCanvas(
        tester,
        const DirectoryCanvas(
          frame: DirectoryFrame.offline,
          offices: <Office>[],
          failure: NetworkFailure(),
        ),
      );
      expect(find.text("You're offline"), findsOneWidget);
    });

    testWidgets('the messages inbox says the failure', (tester) async {
      var retries = 0;
      await pumpCanvas(
        tester,
        AccountCanvas(
          frame: AccountFrame.inboxError,
          title: 'Messages',
          showBack: true,
          failure: _server,
          onInboxRetry: () => retries++,
        ),
      );
      expect(find.text(_serverWords), findsOneWidget);
      expect(find.textContaining('could not be reached'), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('each failure fits every phone', (tester) async {
      final List<Widget Function()> canvases = <Widget Function()>[
        () => BalitaCanvas(
          frame: BalitaFrame.failed,
          failure: _server,
          onRetry: () {},
        ),
        () => TulongCanvas(
          frame: TulongFrame.offline,
          failure: _server,
          onRetry: () {},
        ),
        () => DirectoryCanvas(
          frame: DirectoryFrame.offline,
          offices: const <Office>[],
          failure: _server,
          onRetry: () {},
        ),
        () => AccountCanvas(
          frame: AccountFrame.inboxError,
          title: 'Messages',
          showBack: true,
          failure: _server,
          onInboxRetry: () {},
        ),
      ];
      for (final Widget Function() canvas in canvases) {
        await expectCleanLayouts(tester, canvas, scrollable: false);
      }
    });

    testWidgets('a programme page that the server failed says so', (
      tester,
    ) async {
      _tallView(tester);
      final _Gated transport = _Gated(
        (ApiRequest request) => Ok<ApiHttpResponse>(_serverError),
      );
      await tester.pumpWidget(
        _host(_guest(transport), const ServiceInfoScreen(slug: 'burial')),
      );
      await tester.pumpAndSettle();
      expect(find.text(_serverWords), findsOneWidget);
      expect(find.text('Programme pages need a connection'), findsNothing);
      expect(find.text('operator text'), findsNothing);

      transport.answer = (ApiRequest request) =>
          const Err<ApiHttpResponse>(NetworkFailure());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Programme pages need a connection'), findsOneWidget);
    });
  });

  group('Try again shows that it is working and reads once', () {
    testWidgets('Tulong', (tester) async {
      _tallView(tester);
      final _Gated transport = _Gated(
        (ApiRequest request) => Ok<ApiHttpResponse>(_serverError),
      );
      await tester.pumpWidget(_host(_guest(transport), const TulongScreen()));
      await tester.pumpAndSettle();
      expect(find.text(_serverWords), findsOneWidget);
      final int before = transport.asked('services');

      transport
        ..gate = Completer<void>()
        ..answer = (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_service('Burial Assistance', 'burial')]),
        );
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Try again'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(transport.asked('services'), before + 1);

      transport.gate?.complete();
      transport.gate = null;
      await tester.pumpAndSettle();
      expect(find.byType(LoadingSkeleton), findsNothing);
      expect(find.byKey(const Key('tulong-open-burial')), findsOneWidget);
    });

    testWidgets('Directory', (tester) async {
      _tallView(tester);
      final _Gated transport = _Gated(
        (ApiRequest request) => const Err<ApiHttpResponse>(NetworkFailure()),
      );
      await tester.pumpWidget(
        _host(_guest(transport), const DirectoryScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsOneWidget);
      final int before = transport.asked('offices');

      transport
        ..gate = Completer<void>()
        ..answer = (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(const <Object?>[]));
      await tester.tap(find.byKey(const Key('directory-retry')));
      await tester.tap(
        find.byKey(const Key('directory-retry')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byType(LoadingSkeleton), findsWidgets);
      expect(find.byKey(const Key('directory-retry')), findsNothing);
      expect(transport.asked('offices'), before + 1);

      transport.gate?.complete();
      transport.gate = null;
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsNothing);
      expect(find.byType(LoadingSkeleton), findsNothing);
    });

    testWidgets('the profile wizard', (tester) async {
      _tallView(tester);
      final _Records records = _Records()
        ..answers.add(const Err<ResidentRecord>(_server));
      final AppDependencies dependencies = _rebuild(
        _guest(_Gated((ApiRequest request) => Ok<ApiHttpResponse>(_item({})))),
        records: records,
      );
      await tester.pumpWidget(
        _host(
          dependencies,
          const ProfileWizardScreen(step: ProfileWizardStep.overview),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_serverWords), findsOneWidget);
      expect(records.loads, 1);

      records.gate = Completer<void>();
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Try again'), warnIfMissed: false);
      await tester.pump();
      expect(find.bySemanticsLabel('Loading your profile'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(records.loads, 2);

      records.gate?.complete();
      records.gate = null;
      await tester.pumpAndSettle();
      expect(find.text(_serverWords), findsNothing);
      expect(find.bySemanticsLabel('Loading your profile'), findsNothing);
    });
  });

  group('the topics the server publishes are heard', () {
    test('by the names the server gives them', () {
      expect(LiveTopics.offices, 'offices');
      expect(LiveTopics.services, 'services');
      expect(LiveTopics.households, 'households');
      expect(LiveTopics.consents, 'consents');
      // The server files the document catalogue under this topic too.
      expect(LiveTopics.issuanceRequests, 'issuance-requests');
    });

    /// Pumps [screen] signed in, connects the stream, and checks that a
    /// change to [topic] re-reads [path] once and quietly, and that a change
    /// to another topic reads nothing.
    Future<void> expectQuietReread(
      WidgetTester tester, {
      required Widget screen,
      required String topic,
      required String path,
      required Result<ApiHttpResponse> Function(ApiRequest request) answer,
    }) async {
      _tallView(tester);
      final _Gated transport = _Gated(answer);
      final _LiveApp app = await _LiveApp.open(transport);
      await tester.pumpWidget(_host(app.dependencies, screen));
      await tester.pumpAndSettle();
      await app.connect(tester);
      final int before = transport.asked(path);
      expect(before, greaterThan(0), reason: '$path is read on opening');

      transport.gate = Completer<void>();
      await app.change(tester, topic);
      expect(transport.asked(path), before + 1, reason: '$topic re-reads');
      expect(
        find.byType(LoadingSkeleton),
        findsNothing,
        reason: 'a re-read shows no loading state',
      );
      transport.gate?.complete();
      transport.gate = null;
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));
      await app.change(tester, LiveTopics.news);
      expect(transport.asked(path), before + 1, reason: 'news is not $topic');
      await app.close(tester);
    }

    testWidgets('Directory hears offices', (tester) async {
      await expectQuietReread(
        tester,
        screen: const DirectoryScreen(),
        topic: LiveTopics.offices,
        path: 'offices',
        answer: (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(const <Object?>[])),
      );
    });

    testWidgets('Tulong hears services', (tester) async {
      await expectQuietReread(
        tester,
        screen: const TulongScreen(),
        topic: LiveTopics.services,
        path: 'services',
        answer: (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_service('Burial Assistance', 'burial')]),
        ),
      );
    });

    testWidgets('a programme page hears services', (tester) async {
      await expectQuietReread(
        tester,
        screen: const ServiceInfoScreen(slug: 'burial'),
        topic: LiveTopics.services,
        path: 'services/burial',
        answer: (ApiRequest request) =>
            Ok<ApiHttpResponse>(_item(_service('Burial Assistance', 'burial'))),
      );
    });

    testWidgets('Household hears households', (tester) async {
      await expectQuietReread(
        tester,
        screen: const HouseholdScreen(),
        topic: LiveTopics.households,
        path: 'households/current',
        answer: (ApiRequest request) => Ok<ApiHttpResponse>(
          _item(<String, Object?>{'id': 'hh-1', 'members': const <Object?>[]}),
        ),
      );
    });

    testWidgets('Privacy controls hear consents', (tester) async {
      await expectQuietReread(
        tester,
        screen: const PrivacyControlsScreen(),
        topic: LiveTopics.consents,
        path: 'me/consents',
        answer: (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(const <Object?>[])),
      );
    });

    testWidgets('the document catalogue hears its server topic', (
      tester,
    ) async {
      await expectQuietReread(
        tester,
        screen: const IssuanceCatalogueScreen(),
        topic: LiveTopics.issuanceRequests,
        path: 'issuance-types',
        answer: (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(const <Object?>[])),
      );
    });
  });
}
