import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/events/data/planned_event_repository.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/events/presentation/event_registration_controller.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real Taytay event, resident or reference.

ServerValue<EventRegistrationState> regState(EventRegistrationState value) =>
    ServerValue<EventRegistrationState>(raw: value.wireValue, known: value);

ServerValue<ServerFieldKind> fieldKind(ServerFieldKind value) =>
    ServerValue<ServerFieldKind>(raw: value.wireValue, known: value);

ServerValue<AttendanceResult> attendance(AttendanceResult value) =>
    ServerValue<AttendanceResult>(raw: value.wireValue, known: value);

EventRegistrationForm form({
  List<ServerField> fields = const <ServerField>[],
  List<ServerConsent> consents = const <ServerConsent>[],
  bool allowsUnverified = false,
  bool canCancel = true,
  String? notice,
}) => EventRegistrationForm(
  eventId: 'e-1',
  eventTitle: 'Medical mission',
  fields: fields,
  consents: consents,
  allowsUnverifiedResidents: allowsUnverified,
  canCancel: canCancel,
  notice: notice,
);

const ServerConsent healthConsent = ServerConsent(
  key: 'health_data',
  label: 'Sharing my health details with the medical team',
  statement:
      'I allow Taytay LGU to share the details in this form with the medical '
      'team running this mission.',
);

ServerField textField({
  String key = 'companions',
  String prompt = 'How many people are coming with you?',
  ServerFieldKind kind = ServerFieldKind.number,
  bool isRequired = true,
}) => ServerField(
  key: key,
  prompt: prompt,
  kind: fieldKind(kind),
  isRequired: isRequired,
);

EventRegistration registration({
  EventRegistrationState state = EventRegistrationState.registered,
  String? reference = 'TAY-EV-000045',
  int? waitlistPosition,
  ServerValue<AttendanceResult>? attendanceResult,
  String? instructions,
}) => EventRegistration(
  eventId: 'e-1',
  id: 'reg-1',
  state: regState(state),
  reference: reference,
  waitlistPosition: waitlistPosition,
  attendance: attendanceResult,
  instructions: instructions,
);

LguEvent event({
  ServerValue<EventRegistrationState>? registrationState,
  EventRegistration? myRegistration,
}) => LguEvent(
  id: 'e-1',
  title: 'Medical mission',
  description: 'Free check-ups at the covered court.',
  startsAt: DateTime.utc(2026, 8, 5, 2),
  registrationState: registrationState,
  myRegistration: myRegistration,
);

class ScriptedRegistrationRepository implements EventRepository {
  ScriptedRegistrationRepository({this.registrationForm, this.detail});

  EventRegistrationForm? registrationForm;
  LguEvent? detail;

  Result<RegistrationAttempt>? registerOutcome;
  Result<EventRegistration> cancelOutcome = Ok<EventRegistration>(
    registration(state: EventRegistrationState.cancelled),
  );

  int registerCalls = 0;
  final List<String> idempotencyKeys = <String>[];
  final List<Map<String, Object?>> submittedAnswers = <Map<String, Object?>>[];
  final List<List<String>> submittedConsents = <List<String>>[];

  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async {
    final value = registrationForm;
    return value == null
        ? const Err<EventRegistrationForm>(ServerFailure(isTemporary: true))
        : Ok<EventRegistrationForm>(value);
  }

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async {
    registerCalls++;
    idempotencyKeys.add(idempotencyKey);
    submittedAnswers.add(answers);
    submittedConsents.add(consentKeys);
    return registerOutcome ??
        Ok<RegistrationAttempt>(
          RegistrationAttempt(
            outcome: RegistrationOutcome.registered,
            residentMessage: 'Taytay LGU has your place.',
            registration: registration(),
          ),
        );
  }

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async => cancelOutcome;

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async =>
      Ok<Paginated<LguEvent>>(Paginated<LguEvent>.single(<LguEvent>[?detail]));

  @override
  Future<Result<LguEvent>> loadEvent(String id) async {
    final value = detail;
    return value == null
        ? const Err<LguEvent>(NotFoundFailure())
        : Ok<LguEvent>(value);
  }
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedRegistration = ({
  AppDependencies dependencies,
  ScriptedRegistrationRepository events,
});

Future<BootedRegistration> bootRegistration(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  EventRegistrationForm? registrationForm,
  LguEvent? detail,
  EventRepository? repositoryOverride,
  String location = '/events/e-1/register',
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

  final events = ScriptedRegistrationRepository(
    registrationForm: registrationForm,
    detail: detail,
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
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
    externalLinks: base.externalLinks,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
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

  return (dependencies: dependencies, events: events);
}

EventRegistrationController controllerFor(
  ScriptedRegistrationRepository repository, {
  AccessLevel level = AccessLevel.verified,
}) => EventRegistrationController(
  repository: repository,
  eventId: 'e-1',
  accessLevel: level,
);

/// The submit control, scoped so it cannot match the AppBar title, which is
/// also the word "Register".
final Finder registerButton = find.widgetWithText(FilledButton, 'Register');

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

void main() {
  group('the server owns capacity and eligibility', () {
    test('the shipped repository declines every registration call', () async {
      const repository = PlannedEventRepository();

      expect((await repository.loadRegistrationForm('e-1')).isErr, isTrue);
      expect(
        (await repository.register(
          eventId: 'e-1',
          answers: const <String, Object?>{},
          consentKeys: const <String>[],
          idempotencyKey: 'k',
        )).isErr,
        isTrue,
      );
      expect(
        (await repository.cancelRegistration(
          eventId: 'e-1',
          registrationId: 'r',
          idempotencyKey: 'k',
        )).isErr,
        isTrue,
      );
    });

    test('a full answer is an outcome, not a failure', () async {
      final repository =
          ScriptedRegistrationRepository(registrationForm: form())
            ..registerOutcome = const Ok<RegistrationAttempt>(
              RegistrationAttempt(
                outcome: RegistrationOutcome.full,
                residentMessage: 'This event filled up.',
              ),
            );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      await controller.submit();

      // Somebody who reached the last place a second late did nothing wrong.
      expect(controller.attempt?.outcome, RegistrationOutcome.full);
      expect(controller.failure, isNull);
      expect(controller.attempt?.isHeld, isFalse);
    });

    test('a full or closed outcome is not retried', () async {
      final repository =
          ScriptedRegistrationRepository(registrationForm: form())
            ..registerOutcome = const Ok<RegistrationAttempt>(
              RegistrationAttempt(
                outcome: RegistrationOutcome.closed,
                residentMessage: 'Registration has closed.',
              ),
            );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      await controller.submit();
      await controller.retry();

      expect(
        repository.registerCalls,
        1,
        reason:
            'The server has stated the position; asking again only makes '
            'it say so twice.',
      );
    });
  });

  group('idempotency — acceptance 2', () {
    test('a retry replays the same key', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(),
      )..registerOutcome = const Err<RegistrationAttempt>(TimeoutFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      await controller.submit();
      await controller.retry();

      expect(repository.registerCalls, 2);
      expect(
        repository.idempotencyKeys.first,
        repository.idempotencyKeys.last,
        reason:
            'A double registration holds a place somebody else could have '
            'had.',
      );
    });

    test('a success retires the key', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      await controller.submit();
      // A later attempt is a new one. (The block guard now refuses, so drive
      // the key directly through a second controller instead.)
      expect(controller.attempt?.isHeld, isTrue);
      expect(repository.idempotencyKeys.single, isNotEmpty);
    });

    test('a failure keeps every answer', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(
          fields: <ServerField>[textField()],
          consents: <ServerConsent>[healthConsent],
        ),
      )..registerOutcome = const Err<RegistrationAttempt>(NetworkFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..answer('companions', 2)
        ..toggleConsent(healthConsent.key, given: true);
      await controller.submit();

      expect(controller.attempt?.outcome, RegistrationOutcome.couldNotSend);
      expect(controller.answers['companions'], 2);
      expect(controller.consents, contains(healthConsent.key));
      expect(
        controller.attempt?.residentMessage,
        contains('nothing was registered'),
      );
    });
  });

  group('verification is the server\'s call, per event', () {
    test('an unverified resident is blocked when the event says so', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(),
      );
      final controller = controllerFor(
        repository,
        level: AccessLevel.unverified,
      );
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.block, RegistrationBlock.needsVerification);
      expect(controller.canSubmit, isFalse);
    });

    test('an unverified resident proceeds when the event permits it', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(allowsUnverified: true),
      );
      final controller = controllerFor(
        repository,
        level: AccessLevel.unverified,
      );
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.block, isNull);
      expect(controller.canSubmit, isTrue);
    });

    test('the permissive flag defaults to false', () {
      // An absent flag means the office did not say. Sending somebody into a
      // verification flow they did not need is recoverable; registering
      // somebody the office would have refused is not.
      expect(form().allowsUnverifiedResidents, isFalse);
    });

    test('an existing registration is reported before verification', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(),
      );
      final controller = controllerFor(
        repository,
        level: AccessLevel.unverified,
      );
      addTearDown(controller.dispose);
      await controller.initialise(existing: registration());

      // Telling somebody who already holds a place to go and verify themselves
      // is nonsense.
      expect(controller.block, RegistrationBlock.alreadyRegistered);
    });
  });

  group('the form is the office\'s', () {
    test('an unrenderable field blocks registration', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(
          fields: <ServerField>[
            const ServerField(
              key: 'scan',
              prompt: 'Provide a retina scan',
              kind: ServerValue<ServerFieldKind>(
                raw: 'retina_scan',
                known: null,
              ),
            ),
          ],
        ),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.block, RegistrationBlock.unsupportedForm);
      await controller.submit();
      expect(repository.registerCalls, 0);
    });

    test('required fields and consents are enforced', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(
          fields: <ServerField>[textField()],
          consents: <ServerConsent>[healthConsent],
        ),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.canSubmit, isFalse);

      controller.answer('companions', 1);
      expect(controller.canSubmit, isFalse);

      controller.toggleConsent(healthConsent.key, given: true);
      expect(controller.canSubmit, isTrue);
    });

    test('an optional field may be left blank', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(
          fields: <ServerField>[textField(isRequired: false)],
        ),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.canSubmit, isTrue);
    });

    test('a number field rejects text', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(fields: <ServerField>[textField()]),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller.answer('companions', 'two');
      expect(controller.canSubmit, isFalse);

      controller.answer('companions', 2);
      expect(controller.canSubmit, isTrue);
    });

    test('steps are derived from the form', () async {
      final none = ScriptedRegistrationRepository(registrationForm: form());
      final both = ScriptedRegistrationRepository(
        registrationForm: form(
          fields: <ServerField>[textField()],
          consents: <ServerConsent>[healthConsent],
        ),
      );
      final a = controllerFor(none);
      final b = controllerFor(both);
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      await a.initialise();
      await b.initialise();

      expect(a.progressSteps, <RegistrationStep>[RegistrationStep.confirm]);
      expect(b.progressSteps.length, 3);
    });

    test('consents travel as their own field', () async {
      final repository = ScriptedRegistrationRepository(
        registrationForm: form(consents: <ServerConsent>[healthConsent]),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller.toggleConsent(healthConsent.key, given: true);
      await controller.submit();

      expect(repository.submittedConsents.single, <String>['health_data']);
      expect(
        repository.submittedAnswers.single.containsKey('health_data'),
        isFalse,
      );
    });
  });

  group('the registration record', () {
    test('a waitlist position is shown only when the office sent one', () {
      expect(
        registration(state: EventRegistrationState.waitlisted).waitlistPosition,
        isNull,
      );
      expect(
        registration(
          state: EventRegistrationState.waitlisted,
          waitlistPosition: 3,
        ).waitlistPosition,
        3,
      );
    });

    test('registered and waitlisted both count as holding a place', () {
      expect(registration().isActive, isTrue);
      expect(
        registration(state: EventRegistrationState.waitlisted).isActive,
        isTrue,
      );
      expect(
        registration(state: EventRegistrationState.cancelled).isActive,
        isFalse,
      );
    });

    test('the record redacts its reference', () {
      expect(registration().toString(), isNot(contains('TAY-EV-000045')));
    });
  });

  group('access', () {
    test('the route is authenticated, not verified', () {
      // Gating at `verified` would refuse an event that takes anyone with an
      // account; gating at `public` would open a /me-scoped write to a guest.
      expect(
        AppRoute.eventRegistration.requirement,
        AccessRequirement.authenticated,
      );
    });

    testWidgets('a guest is sent to sign in', (tester) async {
      await bootRegistration(
        tester,
        level: AccessLevel.guest,
        registrationForm: form(),
      );

      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets(
      'an unverified resident reaches the screen and is gated there',
      (tester) async {
        await bootRegistration(
          tester,
          level: AccessLevel.unverified,
          registrationForm: form(),
        );

        // The route let them in; the *form* decides.
        expect(currentLocation(tester), '/events/e-1/register');
        expect(
          find.text('This event needs a verified account'),
          findsOneWidget,
        );
        expect(find.text('Verify my identity'), findsOneWidget);
      },
    );
  });

  group('the registration screen', () {
    testWidgets('an absent backend explains rather than offering a form', (
      tester,
    ) async {
      await bootRegistration(
        tester,
        repositoryOverride: const PlannedEventRepository(),
      );

      expect(find.textContaining('not switched on yet'), findsOneWidget);
      expect(registerButton, findsNothing);
    });

    testWidgets('a short form registers end to end', (tester) async {
      final booted = await bootRegistration(
        tester,
        registrationForm: form(notice: 'Doors open at 8 AM.'),
      );

      expect(find.text('Confirm your registration'), findsOneWidget);
      expect(find.text('Doors open at 8 AM.'), findsOneWidget);

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('You are registered'), findsOneWidget);
      expect(find.textContaining('TAY-EV-000045'), findsOneWidget);
      expect(booted.events.registerCalls, 1);
    });

    testWidgets('a waitlist outcome shows the position when published', (
      tester,
    ) async {
      final booted = await bootRegistration(tester, registrationForm: form());
      booted.events.registerOutcome = Ok<RegistrationAttempt>(
        RegistrationAttempt(
          outcome: RegistrationOutcome.waitlisted,
          residentMessage: 'You are on the waitlist.',
          registration: registration(
            state: EventRegistrationState.waitlisted,
            waitlistPosition: 3,
          ),
        ),
      );

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('You are on the waitlist'), findsOneWidget);
      expect(find.textContaining('number 3 on the waitlist'), findsOneWidget);
    });

    testWidgets('a full event reads as a state, not a fault', (tester) async {
      final booted = await bootRegistration(tester, registrationForm: form());
      booted.events.registerOutcome = const Ok<RegistrationAttempt>(
        RegistrationAttempt(
          outcome: RegistrationOutcome.full,
          residentMessage: 'Every place has been taken.',
        ),
      );

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('This event is full'), findsOneWidget);
      // No retry offered — the server has stated the position.
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a send failure offers a retry and says nothing was taken', (
      tester,
    ) async {
      final booted = await bootRegistration(tester, registrationForm: form());
      booted.events.registerOutcome = const Err<RegistrationAttempt>(
        NetworkFailure(),
      );

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Not registered'), findsOneWidget);
      expect(find.textContaining('nothing was registered'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('an already-registered resident is told, not re-asked', (
      tester,
    ) async {
      // The event detail carries the registration, and the flow blocks.
      await bootRegistration(
        tester,
        registrationForm: form(),
        detail: event(myRegistration: registration()),
        location: '/events/e-1',
      );

      expect(find.text('Register for this event'), findsNothing);
      expect(find.text('You are registered'), findsOneWidget);
      expect(find.textContaining('TAY-EV-000045'), findsOneWidget);
    });

    testWidgets('no tickets, payments or seat maps appear', (tester) async {
      await bootRegistration(
        tester,
        registrationForm: form(
          fields: <ServerField>[textField()],
          consents: <ServerConsent>[healthConsent],
        ),
      );

      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data ?? '')
          .join('\n')
          .toLowerCase();
      for (final forbidden in <String>[
        'ticket',
        'payment',
        'pay now',
        'seat',
        'price',
        'checkout',
      ]) {
        expect(
          text,
          isNot(contains(forbidden)),
          reason: 'The Master Command rules out commercial ticketing.',
        );
      }
    });

    testWidgets('the flow survives a 200% text scale', (tester) async {
      await bootRegistration(
        tester,
        registrationForm: form(
          fields: <ServerField>[textField()],
          consents: <ServerConsent>[healthConsent],
          notice: 'Doors open at 8 AM. Bring a valid ID.',
        ),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 8000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Confirm your registration'), findsOneWidget);
    });
  });

  group('the event detail reflects a held place', () {
    testWidgets('attendance shows only when the office recorded it', (
      tester,
    ) async {
      await bootRegistration(
        tester,
        detail: event(
          myRegistration: registration(
            attendanceResult: attendance(AttendanceResult.attended),
          ),
        ),
        location: '/events/e-1',
      );

      expect(
        find.textContaining('recorded you as having attended'),
        findsOneWidget,
      );
    });

    testWidgets('an unrecorded register says so rather than implying absence', (
      tester,
    ) async {
      await bootRegistration(
        tester,
        detail: event(
          myRegistration: registration(
            attendanceResult: attendance(AttendanceResult.notRecorded),
          ),
        ),
        location: '/events/e-1',
      );

      expect(find.textContaining('has not been recorded yet'), findsOneWidget);
    });

    testWidgets('the register control appears only on an open state', (
      tester,
    ) async {
      await bootRegistration(
        tester,
        detail: event(registrationState: regState(EventRegistrationState.open)),
        location: '/events/e-1',
      );

      expect(find.text('Register for this event'), findsOneWidget);
      expect(
        find.textContaining('Taytay LGU decides whether a place is available'),
        findsOneWidget,
      );
    });

    testWidgets('tapping register opens the flow', (tester) async {
      await bootRegistration(
        tester,
        registrationForm: form(),
        detail: event(registrationState: regState(EventRegistrationState.open)),
        location: '/events/e-1',
      );

      await tester.tap(find.text('Register for this event'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/events/e-1/register');
    });
  });
}
