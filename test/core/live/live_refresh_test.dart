import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/change_stream.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/live/live_updates.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/events/presentation/events_controller.dart';
import 'package:taytay_resident/features/sectors/domain/resident_sector.dart';
import 'package:taytay_resident/features/sectors/domain/sector_repository.dart';
import 'package:taytay_resident/features/sectors/presentation/sectors_copy.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';

/// D-218: a re-read for a change keeps what is on screen, shows no loading
/// state, and on failure says nothing.

LguEvent _event(String id) =>
    LguEvent(id: id, title: 'Event $id', description: 'About $id');

Paginated<LguEvent> _page(List<String> ids, {bool hasMore = false}) =>
    Paginated<LguEvent>(
      items: <LguEvent>[for (final String id in ids) _event(id)],
      page: 1,
      perPage: 20,
      total: ids.length,
      totalPages: 1,
      hasMore: hasMore,
    );

/// Answers each page from a script, in order.
class _Events implements EventRepository {
  final List<Result<Paginated<LguEvent>>> answers =
      <Result<Paginated<LguEvent>>>[];
  final List<int> pagesAsked = <int>[];

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async {
    pagesAsked.add(page);
    return answers.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sectors implements SectorRepository {
  int reads = 0;
  List<OwnSector> own = const <OwnSector>[];
  Completer<void>? gate;

  @override
  Future<Result<List<OwnSector>>> listOwn() async {
    reads++;
    final Completer<void>? waiting = gate;
    if (waiting != null) await waiting.future;
    return Ok<List<OwnSector>>(own);
  }

  @override
  Future<Result<List<SectorApplication>>> listApplications() async =>
      const Ok<List<SectorApplication>>(<SectorApplication>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('a controller\'s quiet refresh', () {
    test('never passes through a loading state, and replaces the list only '
        'when it arrives', () async {
      final _Events events = _Events()
        ..answers.add(Ok<Paginated<LguEvent>>(_page(<String>['a'])));
      final EventsController controller = EventsController(repository: events);
      await controller.refresh();

      final List<bool> loadingSeen = <bool>[];
      final List<List<String>> itemsSeen = <List<String>>[];
      controller.addListener(() {
        loadingSeen.add(controller.isLoadingFirstPage);
        itemsSeen.add(<String>[
          for (final LguEvent event in controller.items) event.id,
        ]);
      });

      events.answers.add(Ok<Paginated<LguEvent>>(_page(<String>['b', 'a'])));
      final Future<void> quiet = controller.refreshQuietly();
      expect(controller.items.map((LguEvent e) => e.id), <String>['a']);
      await quiet;

      expect(loadingSeen, <bool>[false]);
      expect(itemsSeen, <List<String>>[
        <String>['b', 'a'],
      ]);
      controller.dispose();
    });

    test('a failure keeps the list and says nothing', () async {
      final _Events events = _Events()
        ..answers.add(Ok<Paginated<LguEvent>>(_page(<String>['a'])));
      final EventsController controller = EventsController(repository: events);
      await controller.refresh();
      var notified = 0;
      controller.addListener(() => notified++);

      events.answers.add(const Err<Paginated<LguEvent>>(NetworkFailure()));
      await controller.refreshQuietly();

      expect(notified, 0);
      expect(controller.items.map((LguEvent e) => e.id), <String>['a']);
      expect(controller.failure, isNull);
      controller.dispose();
    });

    test('every page the resident scrolled through is read again', () async {
      final _Events events = _Events()
        ..answers.addAll(<Result<Paginated<LguEvent>>>[
          Ok<Paginated<LguEvent>>(_page(<String>['a'], hasMore: true)),
          Ok<Paginated<LguEvent>>(_page(<String>['b'])),
        ]);
      final EventsController controller = EventsController(repository: events);
      await controller.refresh();
      await controller.loadMore();
      events.pagesAsked.clear();

      events.answers.addAll(<Result<Paginated<LguEvent>>>[
        Ok<Paginated<LguEvent>>(_page(<String>['new', 'a'], hasMore: true)),
        Ok<Paginated<LguEvent>>(_page(<String>['b'])),
      ]);
      await controller.refreshQuietly();

      expect(events.pagesAsked, <int>[1, 2]);
      expect(controller.items.map((LguEvent e) => e.id), <String>[
        'new',
        'a',
        'b',
      ]);
      controller.dispose();
    });
  });

  group('a screen re-reads on a hint', () {
    testWidgets('Sectors re-reads quietly when sector-applications changes', (
      WidgetTester tester,
    ) async {
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
        documentPicker: const UnavailableDocumentPicker(),
      );

      final List<StreamController<String>> streams =
          <StreamController<String>>[];
      final LiveUpdates live = LiveUpdates(
        open: () async {
          streams.add(StreamController<String>());
          return ChangeStreamOpen(streams.last.stream);
        },
        session: base.session,
      );
      final _Sectors sectors = _Sectors();
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
        sectors: sectors,
        passwordClient: base.accountPasswordClient,
        live: live,
        onDispose: base.onDispose,
      );
      addTearDown(() {
        dependencies.dispose();
        for (final StreamController<String> stream in streams) {
          unawaited(stream.close());
        }
      });

      await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/sectors');
      await tester.pumpAndSettle();

      expect(live.status, LiveStatus.open);
      expect(find.text(SectorsCopy.none), findsOneWidget);
      final int before = sectors.reads;

      streams.last.add(
        'event: ready\ndata: {"topics":["sector-applications"]}\n\n',
      );
      await tester.pump();
      expect(sectors.reads, before, reason: 'the first ready is not a change');

      // The office approves an application. The read is held open to see
      // what the screen shows meanwhile.
      sectors
        ..gate = Completer<void>()
        ..own = <OwnSector>[
          OwnSector(
            sector: ResidentSector.pwd,
            since: DateTime.utc(2025, 3, 2),
            idLastFour: '0000',
            validUntil: DateTime.utc(2028, 3, 2),
          ),
        ];
      streams.last.add(
        'event: change\ndata: {"topics":["sector-applications"]}\n\n',
      );
      await tester.pump();
      expect(sectors.reads, before + 1);
      expect(find.byType(LoadingSkeleton), findsNothing);
      expect(find.text(SectorsCopy.none), findsOneWidget);

      sectors.gate?.complete();
      await tester.pumpAndSettle();
      expect(find.text(SectorsCopy.none), findsNothing);
      expect(find.text(SectorsCopy.recorded), findsOneWidget);

      // A change nobody on screen listens for reads nothing.
      await tester.pump(const Duration(seconds: 3));
      streams.last.add('event: change\ndata: {"topics":["news"]}\n\n');
      await tester.pump();
      expect(sectors.reads, before + 1);

      live.handleLifecycle(AppLifecycleState.paused);
      await tester.pump();
      expect(live.status, LiveStatus.idle);
    });
  });
}
