import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/links/external_link_service.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/core/time/manila_time.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/events/presentation/events_controller.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real Taytay event, venue or schedule.

ServerValue<PublicationState> publication(PublicationState value) =>
    ServerValue<PublicationState>(raw: value.wireValue, known: value);

ServerValue<EventRegistrationState> registration(
  EventRegistrationState value,
) => ServerValue<EventRegistrationState>(raw: value.wireValue, known: value);

LguEvent event({
  String id = 'e-1',
  String title = 'Medical mission',
  String description = 'Free check-ups at the covered court.',
  DateTime? startsAt,
  DateTime? endsAt,
  EventVenue? venue = const EventVenue(name: 'Barangay San Juan covered court'),
  String? category,
  String? organiser,
  String? contact,
  String? registrationRules,
  String? whatToBring,
  String? shareUrl,
  String? coverImageUrl,
  EventCapacity capacity = const EventCapacity(),
  ServerValue<EventRegistrationState>? registrationState,
  ServerValue<PublicationState>? publicationState,
  EventRegistration? myRegistration,
}) => LguEvent(
  id: id,
  title: title,
  description: description,
  // 05 Aug 2026, 10:00 PHT is 02:00 UTC.
  startsAt: startsAt ?? DateTime.utc(2026, 8, 5, 2),
  endsAt: endsAt,
  venue: venue,
  category: category,
  organiser: organiser,
  contact: contact,
  registrationRules: registrationRules,
  whatToBring: whatToBring,
  shareUrl: shareUrl,
  coverImageUrl: coverImageUrl,
  capacity: capacity,
  registrationState: registrationState,
  publicationState: publicationState ?? publication(PublicationState.published),
  myRegistration: myRegistration,
);

/// The resident's own place at an event, as the server would describe it.
EventRegistration myPlace({
  String eventId = 'e-1',
  String? id = 'reg-1',
  EventRegistrationState state = EventRegistrationState.registered,
  String? reference = 'TR-2026-0001',
  bool canCancel = true,
}) => EventRegistration(
  eventId: eventId,
  id: id,
  state: registration(state),
  reference: reference,
  canCancel: canCancel,
);

Paginated<LguEvent> pageOf(
  List<LguEvent> items, {
  int page = 1,
  bool hasMore = false,
}) => Paginated<LguEvent>(
  items: items,
  page: page,
  perPage: 20,
  total: items.length,
  totalPages: hasMore ? page + 1 : page,
  hasMore: hasMore,
);

class ScriptedEventRepository implements EventRepository {
  ScriptedEventRepository({
    this.pages = const <EventScope, dynamic>{},
    this.detail,
  });

  /// scope → `Paginated<LguEvent>` or `AppFailure`.
  Map<EventScope, dynamic> pages;
  LguEvent? detail;

  final List<EventScope> requestedScopes = <EventScope>[];

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async {
    requestedScopes.add(scope);
    final scripted = pages[scope];
    if (scripted is Paginated<LguEvent>) {
      return Ok<Paginated<LguEvent>>(scripted);
    }
    if (scripted is AppFailure) return Err<Paginated<LguEvent>>(scripted);
    return const Err<Paginated<LguEvent>>(ServerFailure(isTemporary: true));
  }

  @override
  Future<Result<LguEvent>> loadEvent(String id) async {
    final value = detail;
    return value == null
        ? const Err<LguEvent>(NotFoundFailure())
        : Ok<LguEvent>(value);
  }

  // Discovery does not register. TAB 22 has its own scripted repository; these
  // decline so a stray call from a discovery test would fail loudly.
  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async => const Err<EventRegistrationForm>(ServerFailure());

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async => const Err<RegistrationAttempt>(ServerFailure());

  /// Cancellation is scripted, because the detail screen offers it.
  bool cancelFails = false;
  final List<String> cancelledRegistrationIds = <String>[];
  final List<String> cancelKeys = <String>[];

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async {
    cancelledRegistrationIds.add(registrationId);
    cancelKeys.add(idempotencyKey);
    return cancelFails
        ? const Err<EventRegistration>(NetworkFailure())
        : Ok<EventRegistration>(
            myPlace(
              eventId: eventId,
              state: EventRegistrationState.cancelled,
              canCancel: false,
            ),
          );
  }
}

/// Records what the app asked the OS to open.
class RecordingLinkService implements ExternalLinkService {
  RecordingLinkService({this.outcome = LinkOutcome.opened});

  LinkOutcome outcome;
  final List<String> opened = <String>[];

  @override
  Future<LinkOutcome> open(String url) async {
    opened.add(url);
    // Still honours the safety rule, so a test cannot accidentally prove that
    // an unsafe URL "opened".
    if (!ExternalLink.isSafe(url)) return LinkOutcome.refused;
    return outcome;
  }
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedEvents = ({
  AppDependencies dependencies,
  ScriptedEventRepository events,
  RecordingLinkService links,
});

Future<BootedEvents> bootEvents(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  Map<EventScope, dynamic> pages = const <EventScope, dynamic>{},
  LguEvent? detail,
  EventRepository? repositoryOverride,
  LinkOutcome linkOutcome = LinkOutcome.opened,
  String location = '/events',
  Size size = const Size(400, 4000),
  TextScaler textScaler = TextScaler.noScaling,
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

  final events = ScriptedEventRepository(pages: pages, detail: detail);
  final links = RecordingLinkService(outcome: linkOutcome);

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
    externalLinks: links,
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
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: repositoryOverride ?? events,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: links,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (dependencies: dependencies, events: events, links: links);
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('Manila time — acceptance 3', () {
    test('renders an instant in Philippine wall time', () {
      // 02:00 UTC is 10:00 in Manila.
      final instant = DateTime.utc(2026, 8, 5, 2);

      expect(ManilaTime.formatTime(instant), '10:00 AM');
      expect(ManilaTime.formatDate(instant), '05 Aug 2026');
      expect(ManilaTime.formatDateWithWeekday(instant), 'Wed 05 Aug 2026');
      expect(
        ManilaTime.formatDateTime(instant),
        'Wed 05 Aug 2026, 10:00 AM PHT',
      );
    });

    test('a device in another timezone reads the same Manila time', () {
      // The same instant expressed as a local time somewhere else. A resident
      // reading a Taytay schedule from abroad must not be shown their own
      // clock, or they arrive on the wrong day.
      final utc = DateTime.utc(2026, 8, 5, 2);
      final elsewhere = utc.toLocal();

      expect(ManilaTime.formatTime(elsewhere), ManilaTime.formatTime(utc));
    });

    test('midnight and noon read correctly in 12-hour time', () {
      // 16:00 UTC = 00:00 Manila next day; 04:00 UTC = 12:00 noon Manila.
      expect(ManilaTime.formatTime(DateTime.utc(2026, 8, 4, 16)), '12:00 AM');
      expect(ManilaTime.formatTime(DateTime.utc(2026, 8, 5, 4)), '12:00 PM');
    });

    test('a same-day range collapses the date', () {
      final start = DateTime.utc(2026, 8, 5, 2);
      final end = DateTime.utc(2026, 8, 5, 6);

      expect(
        ManilaTime.formatRange(start, end),
        'Wed 05 Aug 2026, 10:00 AM – 2:00 PM PHT',
      );
    });

    test('a range crossing midnight repeats the day', () {
      // 14:00 UTC (10 PM Manila) to 18:00 UTC (2 AM Manila, next day). An event
      // running past midnight is exactly what a collapsed range misreports.
      final start = DateTime.utc(2026, 8, 5, 14);
      final end = DateTime.utc(2026, 8, 5, 18);

      final rendered = ManilaTime.formatRange(start, end);
      expect(rendered, contains('Wed 05 Aug 2026, 10:00 PM'));
      expect(rendered, contains('Thu 06 Aug 2026, 2:00 AM'));
    });

    test('the offset is Philippine Standard Time with no DST', () {
      expect(ManilaTime.offset, const Duration(hours: 8));
      expect(ManilaTime.label, 'PHT');
    });
  });

  group('external links are https-only', () {
    test('accepts a well-formed https URL', () {
      expect(ExternalLink.isSafe('https://maps.example.test/?q=hall'), isTrue);
    });

    test('refuses every other scheme and shape', () {
      for (final unsafe in <String?>[
        null,
        '',
        'http://maps.example.test',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'intent://scan#Intent;scheme=zxing;end',
        'geo:14.5,121.1',
        '//maps.example.test',
        'maps.example.test',
        'https://',
      ]) {
        expect(
          ExternalLink.isSafe(unsafe),
          isFalse,
          reason: '"$unsafe" must not be handed to the operating system.',
        );
      }
    });

    test('a venue offers directions only for a safe link', () {
      expect(const EventVenue(name: 'Hall').hasSafeDirections, isFalse);
      expect(
        const EventVenue(
          name: 'Hall',
          directionsUrl: 'http://maps.example.test',
        ).hasSafeDirections,
        isFalse,
      );
      expect(
        const EventVenue(
          name: 'Hall',
          directionsUrl: 'https://maps.example.test/?q=hall',
        ).hasSafeDirections,
        isTrue,
      );
    });

    test(
      'the unavailable service still distinguishes refused from absent',
      () async {
        const service = UnavailableExternalLinkService();

        expect(await service.open('javascript:x'), LinkOutcome.refused);
        expect(
          await service.open('https://maps.example.test'),
          LinkOutcome.unavailable,
        );
      },
    );
  });

  group('what a resident may see', () {
    test('a published event is visible, a withdrawn one is not', () {
      expect(event().isResidentVisible, isTrue);
      for (final state in <PublicationState>[
        PublicationState.draft,
        PublicationState.scheduled,
        PublicationState.archived,
      ]) {
        expect(
          event(publicationState: publication(state)).isResidentVisible,
          isFalse,
          reason:
              'A cancelled fun run advertised as current sends people out '
              'on a Saturday morning for nothing.',
        );
      }
    });

    test('an unrecognised publication state is shown', () {
      expect(
        event(
          publicationState: const ServerValue<PublicationState>(
            raw: 'rescheduled',
            known: null,
          ),
        ).isResidentVisible,
        isTrue,
      );
    });

    test('past is decided by the end, not the start', () {
      final now = DateTime.utc(2026, 8, 5, 4);
      final running = event(
        startsAt: DateTime.utc(2026, 8, 5, 2),
        endsAt: DateTime.utc(2026, 8, 5, 6),
      );

      // Halfway through is not "past".
      expect(running.isPast(now: now), isFalse);
      expect(running.isPast(now: DateTime.utc(2026, 8, 5, 8)), isTrue);
    });

    test('capacity is stated, never computed', () {
      expect(const EventCapacity().isStated, isFalse);
      expect(const EventCapacity(capacity: 50).isStated, isTrue);
      // `isFull` is only true when the server sent a remaining count.
      expect(const EventCapacity(capacity: 50).isFull, isFalse);
      expect(const EventCapacity(remaining: 0).isFull, isTrue);
    });

    test('changing scope refetches with the new scope', () async {
      final repository = ScriptedEventRepository(
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event(id: 'a')]),
          EventScope.past: pageOf(<LguEvent>[event(id: 'old')]),
        },
      );
      final controller = EventsController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.changeScope(EventScope.past);

      expect(repository.requestedScopes, <EventScope>[
        EventScope.upcoming,
        EventScope.past,
      ]);
      expect(controller.items.map((e) => e.id), <String>['old']);
    });

    test('re-selecting the current scope does not refetch', () async {
      final repository = ScriptedEventRepository(
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
      );
      final controller = EventsController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.changeScope(EventScope.upcoming);

      expect(repository.requestedScopes.length, 1);
    });

    test('a page failure keeps what was already listed', () async {
      final repository = ScriptedEventRepository(
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[
            event(id: 'a'),
          ], hasMore: true),
        },
      );
      final controller = EventsController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      // Page 2 is unscripted, so the stub fails.
      repository.pages = <EventScope, dynamic>{
        EventScope.upcoming: const NetworkFailure(),
      };
      await controller.loadMore();

      expect(controller.items.length, 1);
      expect(controller.pageFailure, isA<NetworkFailure>());
      expect(controller.failure, isNull);
    });

    test('a first-page failure is distinct from an empty list', () async {
      final failing = EventsController(
        repository: ScriptedEventRepository(
          pages: <EventScope, dynamic>{
            EventScope.upcoming: const NetworkFailure(),
          },
        ),
      );
      final empty = EventsController(
        repository: ScriptedEventRepository(
          pages: <EventScope, dynamic>{
            EventScope.upcoming: pageOf(const <LguEvent>[]),
          },
        ),
      );
      addTearDown(failing.dispose);
      addTearDown(empty.dispose);

      await failing.refresh();
      await empty.refresh();

      expect(failing.isEmptyAndHealthy, isFalse);
      expect(empty.isEmptyAndHealthy, isTrue);
    });
  });

  group('the events list', () {
    testWidgets('a guest browses without signing in and sees no My Events', (
      tester,
    ) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
      );

      expect(find.text('Medical mission'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      // An empty "My events" would imply a guest had lost registrations they
      // never had.
      expect(find.text('Registered'), findsNothing);
    });

    testWidgets('a signed-in resident gets the Registered scope', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.unverified,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
      );

      expect(find.text('Registered'), findsOneWidget);
    });

    testWidgets('the card states the time with its clock', (tester) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
      );

      expect(find.textContaining('Wed 05 Aug 2026'), findsOneWidget);
      expect(find.textContaining('PHT'), findsOneWidget);
    });

    testWidgets('remaining places show only when the office stated them', (
      tester,
    ) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[
            event(
              id: 'a',
              title: 'Stated',
              capacity: const EventCapacity(capacity: 50, remaining: 4),
              registrationState: registration(EventRegistrationState.open),
            ),
            event(
              id: 'b',
              title: 'Unstated',
              capacity: const EventCapacity(capacity: 50),
              registrationState: registration(EventRegistrationState.open),
            ),
          ]),
        },
      );

      expect(find.textContaining('4 places left'), findsOneWidget);
      // Never computed from capacity minus a registered count.
      expect(find.textContaining('50 places left'), findsNothing);
    });

    testWidgets('a registration this resident holds is called out', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.verified,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[
            event(
              registrationState: registration(
                EventRegistrationState.waitlisted,
              ),
            ),
          ]),
        },
      );

      expect(find.text('You are on the waitlist'), findsOneWidget);
    });

    testWidgets('failure and empty say different things', (tester) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: const NetworkFailure(),
        },
      );

      expect(find.text('Events are not available right now'), findsOneWidget);
      expect(find.text('Nothing scheduled right now'), findsNothing);
    });

    testWidgets('an empty scope says so plainly', (tester) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(const <LguEvent>[]),
        },
      );

      expect(find.text('Nothing scheduled right now'), findsOneWidget);
    });

    testWidgets('no event-management control exists — acceptance 1', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.verified,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'create event',
        'new event',
        'edit event',
        'cancel event',
        'manage capacity',
        'attendance list',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('tapping an event opens it', (tester) async {
      await bootEvents(
        tester,
        pages: <EventScope, dynamic>{
          EventScope.upcoming: pageOf(<LguEvent>[event()]),
        },
        detail: event(),
      );

      await tester.tap(find.text('Medical mission'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/events/e-1');
    });
  });

  group('the event detail', () {
    testWidgets('a guest reads the whole thing', (tester) async {
      await bootEvents(
        tester,
        detail: event(
          category: 'Health',
          organiser: 'Taytay Health Office',
          contact: '(02) 8000 0000',
          registrationRules: 'Open to all Taytay residents.',
          whatToBring: 'Bring a valid ID and your barangay clearance.',
        ),
        location: '/events/e-1',
      );

      expect(find.text('Medical mission'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Taytay Health Office'), findsOneWidget);
      expect(find.text('Who can join'), findsOneWidget);
      expect(find.text('What to bring'), findsOneWidget);
    });

    testWidgets('directions appear only for a server-supplied https link', (
      tester,
    ) async {
      await bootEvents(
        tester,
        detail: event(
          venue: const EventVenue(name: 'Covered court', address: 'Main St'),
        ),
        location: '/events/e-1',
      );

      expect(find.text('Open directions'), findsNothing);
    });

    testWidgets('a safe directions link opens', (tester) async {
      final booted = await bootEvents(
        tester,
        detail: event(
          venue: const EventVenue(
            name: 'Covered court',
            directionsUrl: 'https://maps.example.test/?q=court',
          ),
        ),
        location: '/events/e-1',
      );

      await tester.tap(find.text('Open directions'));
      await tester.pumpAndSettle();

      expect(booted.links.opened.single, 'https://maps.example.test/?q=court');
    });

    testWidgets('an unopenable link blames the device, not the resident', (
      tester,
    ) async {
      await bootEvents(
        tester,
        detail: event(
          venue: const EventVenue(
            name: 'Covered court',
            directionsUrl: 'https://maps.example.test/?q=court',
          ),
        ),
        linkOutcome: LinkOutcome.unavailable,
        location: '/events/e-1',
      );

      await tester.tap(find.text('Open directions'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No app on this device'), findsOneWidget);
    });

    testWidgets('a withdrawn event does not open from a stale link', (
      tester,
    ) async {
      await bootEvents(
        tester,
        detail: event(publicationState: publication(PublicationState.archived)),
        location: '/events/e-1',
      );

      // The second door: the list filters, and so does the detail.
      expect(find.text('This event is not available'), findsOneWidget);
      expect(find.text('Medical mission'), findsNothing);
    });

    testWidgets('no register control when the office has not opened one', (
      tester,
    ) async {
      // No registration state at all: the office has said nothing, so the app
      // says nothing either and points at the office. TAB 22 added the control;
      // it appears only on the server's own `open` state.
      await bootEvents(tester, detail: event(), location: '/events/e-1');

      expect(find.text('Register for this event'), findsNothing);
      expect(find.text('Ask the office about registering'), findsOneWidget);
    });

    testWidgets('a full event offers no register control', (tester) async {
      await bootEvents(
        tester,
        detail: event(
          registrationState: registration(EventRegistrationState.full),
          capacity: const EventCapacity(capacity: 50, remaining: 0),
        ),
        location: '/events/e-1',
      );

      // Offering it would send a resident through a form to be refused at the
      // end of it.
      expect(find.text('Register for this event'), findsNothing);
      expect(find.text('Fully booked'), findsOneWidget);
    });

    testWidgets('a full event says so without inventing a number', (
      tester,
    ) async {
      await bootEvents(
        tester,
        detail: event(
          capacity: const EventCapacity(capacity: 50, remaining: 0),
        ),
        location: '/events/e-1',
      );

      expect(find.textContaining('No places left'), findsOneWidget);
    });

    testWidgets('the detail survives a 200% text scale', (tester) async {
      await bootEvents(
        tester,
        detail: event(
          category: 'Health',
          organiser: 'Taytay Health Office',
          contact: '(02) 8000 0000',
          registrationRules: 'Open to all Taytay residents.',
          whatToBring: 'Bring a valid ID.',
          capacity: const EventCapacity(capacity: 50, remaining: 4),
        ),
        location: '/events/e-1',
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 8000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Medical mission'), findsOneWidget);
    });
  });

  // ── Giving up a place ───────────────────────────────────────────────────
  //
  // Deferred from the registration TAB so it could be built on the shared
  // confirmation sheet rather than a one-off dialog.

  group('Cancelling a registration', () {
    testWidgets('is offered only when the server says it may be', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(myRegistration: myPlace(canCancel: false)),
        location: '/events/e-1',
      );

      expect(find.text('TR-2026-0001'), findsOneWidget);
      expect(find.text('Give up my place'), findsNothing);
    });

    testWidgets('is not offered without an id to cancel against', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(myRegistration: myPlace(id: null)),
        location: '/events/e-1',
      );

      expect(find.text('Give up my place'), findsNothing);
    });

    testWidgets('is not offered once the place is already given up', (
      tester,
    ) async {
      await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(
          myRegistration: myPlace(state: EventRegistrationState.cancelled),
        ),
        location: '/events/e-1',
      );

      expect(find.text('Give up my place'), findsNothing);
    });

    testWidgets('asks first, and dismissing cancels nothing', (tester) async {
      final booted = await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(myRegistration: myPlace()),
        location: '/events/e-1',
      );

      await tester.tap(find.text('Give up my place').first);
      await tester.pumpAndSettle();

      // The sheet names what is lost rather than asking "are you sure".
      expect(find.text('Give up your place?'), findsOneWidget);
      expect(
        find.textContaining('offer your place to the next person'),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep my place'));
      await tester.pumpAndSettle();

      expect(booted.events.cancelledRegistrationIds, isEmpty);
    });

    testWidgets('sends one keyed request and adopts the server answer', (
      tester,
    ) async {
      final booted = await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(myRegistration: myPlace()),
        location: '/events/e-1',
      );

      await tester.tap(find.text('Give up my place').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Give up my place').last);
      await tester.pumpAndSettle();

      expect(booted.events.cancelledRegistrationIds, <String>['reg-1']);
      expect(booted.events.cancelKeys.single, isNotEmpty);
      // The card now shows the server's version, so the control is gone.
      expect(find.text('Give up my place'), findsNothing);
      expect(find.textContaining('has been given up'), findsOneWidget);
    });

    testWidgets('a failure keeps the place and says so', (tester) async {
      final booted = await bootEvents(
        tester,
        level: AccessLevel.verified,
        detail: event(myRegistration: myPlace()),
        location: '/events/e-1',
      );
      booted.events.cancelFails = true;

      await tester.tap(find.text('Give up my place').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Give up my place').last);
      await tester.pumpAndSettle();

      // A place the app quietly removed from view is a place the resident
      // stops turning up for while still holding it.
      expect(find.text('Give up my place'), findsOneWidget);
      expect(find.textContaining('You still have your place'), findsOneWidget);
    });
  });

  group('EventRegistration', () {
    test('is not cancellable unless the server allows it', () {
      expect(myPlace().isCancellable, isTrue);
      expect(myPlace(canCancel: false).isCancellable, isFalse);
      expect(myPlace(id: null).isCancellable, isFalse);
      expect(
        myPlace(state: EventRegistrationState.cancelled).isCancellable,
        isFalse,
      );
    });

    test('withRegistration keeps everything else about the event', () {
      final original = event(
        organiser: 'Taytay Health Office',
        myRegistration: myPlace(),
      );
      final updated = original.withRegistration(
        myPlace(state: EventRegistrationState.cancelled),
      );

      expect(updated.organiser, 'Taytay Health Office');
      expect(updated.title, original.title);
      expect(updated.startsAt, original.startsAt);
      expect(updated.myRegistration!.isCancelled, isTrue);
    });

    test('toString carries no reference', () {
      expect(myPlace().toString(), isNot(contains('TR-2026-0001')));
    });
  });
}
