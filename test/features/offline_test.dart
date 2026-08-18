import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/network/network_monitor.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart';
import 'package:taytay_resident/features/services/domain/service_catalog_repository.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/network_status_views.dart';
import 'package:taytay_resident/shared/widgets/remote_image.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────

/// A catalogue that fails the way a dead connection does.
class OfflineCatalogRepository implements ServiceCatalogRepository {
  OfflineCatalogRepository({this.failure = const NetworkFailure()});

  AppFailure? failure;
  int calls = 0;

  /// What the process last actually fetched, if anything. Null in these tests
  /// unless a case sets it.
  CachedRead<Paginated<LguService>>? lastKnown;

  @override
  Future<Result<Paginated<LguService>>> listServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 25,
  }) async {
    calls++;
    final value = failure;
    return value == null
        ? const Ok<Paginated<LguService>>(
            Paginated<LguService>.single(<LguService>[]),
          )
        : Err<Paginated<LguService>>(value);
  }

  @override
  CachedRead<Paginated<LguService>>? lastKnownServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 25,
  }) => lastKnown;
}

/// One catalogue entry, obviously synthetic.
LguService service({
  String code = 'AICS',
  String name = 'Medical assistance',
  ServiceCategory category = ServiceCategory.kalusugan,
}) => LguService(
  id: 'uuid-$code',
  code: code,
  name: name,
  description: 'Help with hospital bills.',
  category: ServerValue<ServiceCategory>(
    raw: category.wireValue,
    known: category,
  ),
  status: const ServerValue<ServicePublicationStatus>(
    raw: 'published',
    known: ServicePublicationStatus.published,
  ),
  availableChannels: const <ServerValue<ServiceChannel>>[
    ServerValue<ServiceChannel>(
      raw: 'citizen-mobile',
      known: ServiceChannel.citizenMobile,
    ),
  ],
);

/// The catalogue this process last actually fetched, ten o'clock in Taytay.
CachedRead<Paginated<LguService>> remembered() =>
    CachedRead<Paginated<LguService>>(
      value: Paginated<LguService>.single(<LguService>[service()]),
      // 02:00 UTC is 10:00 AM in Taytay.
      storedAt: DateTime.utc(2026, 8, 16, 2),
      isFresh: false,
    );

/// Wraps a bare widget in the localisations it now legitimately needs.
///
/// The offline vocabulary is translated, so `AppStrings.of` has to resolve —
/// a widget test that skipped the delegates would be testing a configuration
/// the app never runs in.
Widget localised(Widget child) => MaterialApp(
  localizationsDelegates: AppStrings.localizationsDelegates,
  supportedLocales: AppLocales.supported,
  home: Scaffold(body: child),
);

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedOffline = ({
  AppDependencies dependencies,
  NetworkMonitor monitor,
  OfflineCatalogRepository catalog,
});

Future<BootedOffline> bootOffline(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  AppFailure? catalogFailure = const NetworkFailure(),
  void Function(OfflineCatalogRepository catalog)? beforeLoad,
  String location = '/services',
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
  }

  final monitor = NetworkMonitor();
  final catalog = OfflineCatalogRepository(failure: catalogFailure);
  beforeLoad?.call(catalog);

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    networkMonitor: monitor,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
  );
  final dependencies = AppDependencies(
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
    serviceCatalogRepository: catalog,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    platform: base.platform,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (dependencies: dependencies, monitor: monitor, catalog: catalog);
}

void main() {
  // ── The banner earns its place before it takes it ───────────────────────

  group('Offline banner', () {
    testWidgets('is absent before anything has been attempted', (tester) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor.reset();
      await tester.pumpAndSettle();

      expect(booted.monitor.status, NetworkStatus.unknown);
      expect(find.text('Not reaching Taytay LGU'), findsNothing);
    });

    testWidgets('is absent after a single failed request', (tester) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor
        ..reset()
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();

      // One dropped request on a Philippine mobile connection is ordinary. A
      // banner that flashes on every one is a banner residents scroll past.
      expect(find.text('Not reaching Taytay LGU'), findsNothing);
    });

    testWidgets('appears once two requests in a row fail to arrive', (
      tester,
    ) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor
        ..reset()
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();

      expect(find.text('Not reaching Taytay LGU'), findsOneWidget);
      expect(find.textContaining('nothing has been sent'), findsOneWidget);
    });

    testWidgets('goes away as soon as something gets through', (tester) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor
        ..reset()
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();
      expect(find.text('Not reaching Taytay LGU'), findsOneWidget);

      booted.monitor.recordOutcome(null);
      await tester.pumpAndSettle();
      expect(find.text('Not reaching Taytay LGU'), findsNothing);
    });

    testWidgets('never appears over a server refusal', (tester) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor
        ..reset()
        ..recordOutcome(const ForbiddenFailure())
        ..recordOutcome(const NotFoundFailure())
        ..recordOutcome(const ServerFailure());
      await tester.pumpAndSettle();

      // The server answered every time. Sending a resident to check their data
      // balance over a permission decision is how the banner stops being read.
      expect(find.text('Not reaching Taytay LGU'), findsNothing);
    });

    testWidgets('rides above the content on both shell layouts', (
      tester,
    ) async {
      final booted = await bootOffline(
        tester,
        catalogFailure: null,
        // Wide enough for the navigation rail.
        size: const Size(1000, 900),
      );

      booted.monitor
        ..reset()
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('Not reaching Taytay LGU'), findsOneWidget);
    });
  });

  // ── No false success ────────────────────────────────────────────────────
  //
  // Acceptance 1 of TAB 25.

  group('Nothing claims to have arrived', () {
    testWidgets('a failed load says so instead of showing an empty list', (
      tester,
    ) async {
      await bootOffline(tester);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();

      // "No services" would be a lie: the app does not know what is there.
      expect(rendered, isNot(contains('no services')));
      expect(rendered, isNot(contains('sent')));
      expect(rendered, isNot(contains('saved')));
    });

    testWidgets('the unsent notice never says "saved"', (tester) async {
      await tester.pumpWidget(
        localised(const UnsentNotice(what: 'your application')),
      );

      expect(find.text('Not sent yet'), findsOneWidget);
      expect(
        find.textContaining('Taytay LGU does not have your application'),
        findsOneWidget,
      );

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();
      // A resident who reads "saved" believes the office has it, stops chasing
      // it, and finds out weeks later that nothing was filed.
      expect(rendered, isNot(contains('saved')));
      expect(rendered, isNot(contains('submitted')));
      expect(rendered, contains('does not have'));
    });

    testWidgets('the unsent notice says a retry cannot duplicate', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        localised(
          UnsentNotice(what: 'your registration', onRetry: () => retried++),
        ),
      );

      expect(
        find.textContaining('does not create a duplicate'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try sending again'));
      expect(retried, 1);
    });
  });

  // ── Stale content ───────────────────────────────────────────────────────

  group('Stale content notice', () {
    testWidgets('says nothing when the content is fresh', (tester) async {
      await tester.pumpWidget(
        localised(
          StaleContentNotice(
            storedAt: DateTime.utc(2026, 8, 16, 2),
            isFresh: true,
          ),
        ),
      );

      // A timestamp on every screen is noise, and noise is how the one that
      // matters gets missed.
      expect(find.textContaining('Showing what was saved'), findsNothing);
    });

    testWidgets('states the age in Manila time when it is not', (tester) async {
      await tester.pumpWidget(
        // 02:00 UTC is 10:00 AM in Taytay.
        localised(StaleContentNotice(storedAt: DateTime.utc(2026, 8, 16, 2))),
      );

      expect(find.textContaining('16 Aug 2026'), findsOneWidget);
      expect(find.textContaining('10:00 AM'), findsOneWidget);
      expect(find.textContaining('It may have changed'), findsOneWidget);
    });

    testWidgets('offers a refresh only when there is one to offer', (
      tester,
    ) async {
      await tester.pumpWidget(
        localised(StaleContentNotice(storedAt: DateTime.utc(2026, 8, 16, 2))),
      );
      expect(find.text('Refresh'), findsNothing);

      var refreshed = 0;
      await tester.pumpWidget(
        localised(
          StaleContentNotice(
            storedAt: DateTime.utc(2026, 8, 16, 2),
            onRefresh: () => refreshed++,
          ),
        ),
      );
      await tester.tap(find.text('Refresh'));
      expect(refreshed, 1);
    });
  });

  // ── Images ──────────────────────────────────────────────────────────────

  group('RemoteImage', () {
    testWidgets('decodes to the size of the box, not of the source', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 200,
                child: RemoteImage(url: 'https://example.test/cover.jpg'),
              ),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      // 360 dp × 3 = 1080 physical pixels. A 4000-wide source decoded at source
      // resolution is ~48 MB per card; this is ~2.6 MB.
      expect(provider.width, 1080);
    });

    testWidgets('never decodes past its ceiling', (tester) async {
      tester.view.devicePixelRatio = 4;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 600,
              child: RemoteImage(url: 'https://example.test/cover.jpg'),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).width, RemoteImage.feedDecodeCeiling);
    });

    testWidgets('a full-size view is allowed more pixels than a feed card', (
      tester,
    ) async {
      expect(
        RemoteImage.fullScreenDecodeCeiling,
        greaterThan(RemoteImage.feedDecodeCeiling),
      );
    });

    testWidgets('is decorative unless the LGU wrote a description', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: RemoteImage(url: 'https://example.test/a.jpg'),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.excludeFromSemantics, isTrue);
      expect(image.semanticLabel, isNull);
    });

    testWidgets('carries the office\'s own description when there is one', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: RemoteImage(
                url: 'https://example.test/a.jpg',
                semanticLabel: 'Residents queueing at the covered court',
              ),
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.excludeFromSemantics, isFalse);
      expect(image.semanticLabel, 'Residents queueing at the covered court');
    });

    testWidgets('reserves its space before the bytes arrive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  height: 200,
                  child: RemoteImage(url: 'https://example.test/a.jpg'),
                ),
                Text('Below the picture'),
              ],
            ),
          ),
        ),
      );

      // A tap that lands on the wrong card because the layout moved is a
      // resident opening the wrong announcement.
      final before = tester.getTopLeft(find.text('Below the picture'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getTopLeft(find.text('Below the picture')), before);
    });

    testWidgets('the image cache budget is raised once and stays raised', (
      tester,
    ) async {
      RemoteImage.configureImageCache();
      expect(PaintingBinding.instance.imageCache.maximumSize, 300);
      expect(PaintingBinding.instance.imageCache.maximumSizeBytes, 64 << 20);
    });
  });

  // ── Session timeout is not a network problem ────────────────────────────

  group('A dead session and a dead connection are different things', () {
    testWidgets('an expired session does not raise the offline banner', (
      tester,
    ) async {
      final booted = await bootOffline(tester, catalogFailure: null);

      booted.monitor
        ..reset()
        ..recordOutcome(const UnauthenticatedFailure())
        ..recordOutcome(const UnauthenticatedFailure());
      await tester.pumpAndSettle();

      // The server answered — it said "sign in again". Telling somebody their
      // connection is down sends them to fix the wrong thing.
      expect(find.text('Not reaching Taytay LGU'), findsNothing);
      expect(booted.monitor.status, NetworkStatus.reachable);
    });
  });

  // ── No infinite spinners ────────────────────────────────────────────────

  group('Every wait ends', () {
    test('the request timeout is finite and short enough to act on', () {
      final timeout = config().requestTimeout;
      expect(timeout, greaterThan(Duration.zero));
      // A resident staring at a spinner for more than half a minute has already
      // decided the app is broken.
      expect(timeout, lessThanOrEqualTo(const Duration(seconds: 30)));
    });

    testWidgets('a failed load lands on a terminal state, not a spinner', (
      tester,
    ) async {
      await bootOffline(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ── Public content survives a weak connection ───────────────────────────
  //
  // Acceptance 2 of TAB 25.

  group('The catalogue falls back to what was actually fetched', () {
    testWidgets('a failed first load adopts the last known catalogue', (
      tester,
    ) async {
      await bootOffline(
        tester,
        beforeLoad: (catalog) => catalog.lastKnown = remembered(),
      );

      // A guest opening the app on a weak connection is exactly the person the
      // public content is for.
      expect(find.text('Medical assistance'), findsOneWidget);
      expect(
        find.textContaining('Showing what was saved on your phone'),
        findsOneWidget,
      );
    });

    testWidgets('and states when the office actually answered', (tester) async {
      await bootOffline(
        tester,
        beforeLoad: (catalog) => catalog.lastKnown = remembered(),
      );

      // The cache's own timestamp, not the moment the app gave up.
      expect(
        find.textContaining('Last updated Sun 16 Aug 2026'),
        findsOneWidget,
      );
      expect(find.textContaining('10:00 AM'), findsOneWidget);
    });

    testWidgets('with nothing remembered it says so rather than "none"', (
      tester,
    ) async {
      await bootOffline(tester);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ')
          .toLowerCase();

      expect(rendered, isNot(contains('no services listed yet')));
    });
  });
}
