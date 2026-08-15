import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/services/data/planned_service_request_repository.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake_validation.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart';
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';
import 'package:taytay_resident/features/services/presentation/assistance_intake_controller.dart';

/// Records everything a submission carried, so a test can assert what was sent
/// as well as what was shown.
class RecordingIntakeRepository implements ServiceRequestRepository {
  RecordingIntakeRepository({this.form});

  AssistanceIntakeForm? form;

  int loadFormCalls = 0;
  int submitCalls = 0;

  final List<String> idempotencyKeys = <String>[];
  final List<String> narratives = <String>[];
  final List<Map<String, Object?>> answers = <Map<String, Object?>>[];
  final List<List<String>> consentKeys = <List<String>>[];

  /// Replaced per test. Defaults to a successful filing with a reference.
  Result<ServiceRequest> submitOutcome = Ok<ServiceRequest>(
    ServiceRequest(
      id: 'req-1',
      serviceCode: 'CEDULA',
      state: ServiceRequestState.submitted,
      rawState: 'submitted',
      submittedAt: DateTime.utc(2026, 8, 16),
      referenceNumber: 'TAY-2026-000123',
    ),
  );

  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async {
    loadFormCalls++;
    final value = form;
    return value == null
        ? const Err<AssistanceIntakeForm>(ServerFailure(isTemporary: true))
        : Ok<AssistanceIntakeForm>(value);
  }

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async {
    submitCalls++;
    idempotencyKeys.add(idempotencyKey);
    narratives.add(narrative);
    this.answers.add(answers);
    this.consentKeys.add(consentKeys);
    return submitOutcome;
  }

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<ServiceRequest>>(ServerFailure());

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      const Err<ServiceRequest>(ServerFailure());

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic, per Article 5.6. No real Taytay resident, no real
// reference number, no real document number appears anywhere in this file.

ServerValue<IntakeAnswerKind> kind(IntakeAnswerKind value) =>
    ServerValue<IntakeAnswerKind>(raw: value.wireValue, known: value);

/// A kind no build knows — the forward-compatibility case.
ServerValue<IntakeAnswerKind> unknownKind() =>
    const ServerValue<IntakeAnswerKind>(
      raw: 'holographic_capture',
      known: null,
    );

AssistanceIntakeForm intakeForm({
  List<IntakeQuestion> questions = const <IntakeQuestion>[],
  List<IntakeRequirement> requirements = const <IntakeRequirement>[],
  List<IntakeConsent> consents = const <IntakeConsent>[],
  ActiveRequestNotice? activeRequest,
  int? narrativeMaxLength,
}) => AssistanceIntakeForm(
  serviceCode: 'CEDULA',
  serviceName: 'Community Tax Certificate',
  narrativePrompt: 'Tell us what you need help with',
  narrativeMaxLength: narrativeMaxLength,
  questions: questions,
  requirements: requirements,
  consents: consents,
  activeRequest: activeRequest,
);

const IntakeConsent dataConsent = IntakeConsent(
  key: 'data_processing',
  label: 'Processing of my personal data',
  statement:
      'I allow Taytay LGU to process the details in this application to '
      'assess it.',
);

AssistanceIntakeDraft completeDraft(AssistanceIntakeForm form) {
  var draft = const AssistanceIntakeDraft(
    contextConfirmed: true,
    narrative: 'I need help with the certificate fee.',
  );
  for (final question in form.questions) {
    if (!question.isRenderable) continue;
    draft = draft.withAnswer(question.key, switch (question.kind.known) {
      IntakeAnswerKind.number => 4,
      IntakeAnswerKind.yesNo => true,
      IntakeAnswerKind.date => DateTime.utc(2026, 1, 1),
      IntakeAnswerKind.multipleChoice => <String>['a'],
      _ => 'answer',
    });
  }
  for (final consent in form.consents) {
    draft = draft.withConsent(consent.key, given: true);
  }
  return draft;
}

AssistanceIntakeController controllerFor(
  RecordingIntakeRepository repository,
) => AssistanceIntakeController(repository: repository, serviceCode: 'CEDULA');

// ─── Widget harness ─────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedIntake = ({
  AppDependencies dependencies,
  RecordingIntakeRepository requests,
});

Future<BootedIntake> bootIntake(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  AssistanceIntakeForm? form,
  ServiceRequestRepository? repositoryOverride,
  String location = '/apply/CEDULA',
  Size size = const Size(400, 3000),
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

  final requests = RecordingIntakeRepository(form: form);
  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
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
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: repositoryOverride ?? requests,
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

  return (dependencies: dependencies, requests: requests);
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('the form belongs to the server', () {
    test(
      'the shipped repository declines rather than inventing questions',
      () async {
        const repository = PlannedServiceRequestRepository();

        final result = await repository.loadIntakeForm('CEDULA');

        // The whole point: with `ServiceDelivery` unpublished there is no form,
        // and the app says so instead of asking a resident for personal data no
        // municipal office requested.
        expect(result.isErr, isTrue);
        expect(result.failureOrNull, isA<ServerFailure>());
      },
    );

    testWidgets('an absent backend produces an honest screen, not a form', (
      tester,
    ) async {
      await bootIntake(
        tester,
        repositoryOverride: const PlannedServiceRequestRepository(),
      );

      expect(find.textContaining('not switched on yet'), findsOneWidget);
      expect(find.textContaining('municipal hall'), findsWidgets);
      // Nothing to fill in, so nothing that could be sent.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Send my application'), findsNothing);
    });

    testWidgets('the steps are derived from the form, not fixed', (
      tester,
    ) async {
      // A form with no questions and no consents must not show those steps.
      await bootIntake(tester, form: intakeForm());

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Questions from the office'), findsNothing);
    });
  });

  group('validation is a courtesy, never a rule of its own', () {
    test('the context step must be confirmed before continuing', () {
      final form = intakeForm();

      expect(
        AssistanceIntakeValidation.validateContext(
          const AssistanceIntakeDraft(),
        ),
        isNotEmpty,
      );
      expect(
        AssistanceIntakeValidation.validateContext(
          const AssistanceIntakeDraft(contextConfirmed: true),
        ),
        isEmpty,
      );
      expect(form.questions, isEmpty);
    });

    test('a length is enforced only when the server declared one', () {
      const draft = AssistanceIntakeDraft(narrative: 'aaaaaaaaaa');

      expect(
        AssistanceIntakeValidation.validateNarrative(draft, intakeForm()),
        isEmpty,
      );
      expect(
        AssistanceIntakeValidation.validateNarrative(
          draft,
          intakeForm(narrativeMaxLength: 5),
        ),
        isNotEmpty,
      );
    });

    test('an optional question may be left blank, a required one may not', () {
      final form = intakeForm(
        questions: <IntakeQuestion>[
          IntakeQuestion(
            key: 'dependants',
            prompt: 'How many dependants?',
            kind: kind(IntakeAnswerKind.number),
          ),
          IntakeQuestion(
            key: 'notes',
            prompt: 'Anything else?',
            kind: kind(IntakeAnswerKind.shortText),
            isRequired: false,
          ),
        ],
      );

      final errors = AssistanceIntakeValidation.validateQuestions(
        const AssistanceIntakeDraft(),
        form,
      );

      expect(errors.map((error) => error.field), <String>['dependants']);
    });

    test('"no" on a yes/no question is an answer, not a blank', () {
      final form = intakeForm(
        questions: <IntakeQuestion>[
          IntakeQuestion(
            key: 'employed',
            prompt: 'Are you employed?',
            kind: kind(IntakeAnswerKind.yesNo),
          ),
        ],
      );

      final draft = const AssistanceIntakeDraft().withAnswer('employed', false);

      expect(
        AssistanceIntakeValidation.validateQuestions(draft, form),
        isEmpty,
      );
    });

    test('a number question rejects text the server would reject', () {
      final form = intakeForm(
        questions: <IntakeQuestion>[
          IntakeQuestion(
            key: 'dependants',
            prompt: 'How many dependants?',
            kind: kind(IntakeAnswerKind.number),
          ),
        ],
      );

      final typed = const AssistanceIntakeDraft().withAnswer(
        'dependants',
        'four',
      );
      final parsed = const AssistanceIntakeDraft().withAnswer('dependants', 4);

      expect(
        AssistanceIntakeValidation.validateQuestions(typed, form),
        isNotEmpty,
      );
      expect(
        AssistanceIntakeValidation.validateQuestions(parsed, form),
        isEmpty,
      );
    });

    test('a required consent is enforced, an optional one is not', () {
      final form = intakeForm(
        consents: <IntakeConsent>[
          dataConsent,
          const IntakeConsent(
            key: 'contact_me',
            label: 'Updates by SMS',
            statement: 'Taytay LGU may text me about this application.',
            isRequired: false,
          ),
        ],
      );

      final errors = AssistanceIntakeValidation.validateConsent(
        const AssistanceIntakeDraft(),
        form,
      );

      expect(errors.map((error) => error.field), <String>[
        'consent_data_processing',
      ]);
    });

    test('a question this build cannot render is not a field error', () {
      final form = intakeForm(
        questions: <IntakeQuestion>[
          IntakeQuestion(
            key: 'scan',
            prompt: 'Provide a holographic capture',
            kind: unknownKind(),
          ),
        ],
      );

      // Reporting it would tell a resident to fix something never shown. The
      // wizard blocks submission instead — see the acceptance group below.
      expect(
        AssistanceIntakeValidation.validateQuestions(
          const AssistanceIntakeDraft(),
          form,
        ),
        isEmpty,
      );
      expect(form.hasUnrenderableQuestions, isTrue);
    });
  });

  group('the wizard never loses what was entered', () {
    test('stepping back keeps the draft intact', () async {
      final repository = RecordingIntakeRepository(form: intakeForm());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..next();
      controller.updateNarrative('I need help with the fee.');
      controller.back();

      expect(controller.step, IntakeStep.context);
      expect(controller.draft.narrative, 'I need help with the fee.');
      expect(controller.draft.contextConfirmed, isTrue);
    });

    test('a failed submission keeps every answer', () async {
      final form = intakeForm(consents: <IntakeConsent>[dataConsent]);
      final repository = RecordingIntakeRepository(form: form)
        ..submitOutcome = const Err<ServiceRequest>(NetworkFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      final draft = completeDraft(form);
      controller
        ..confirmContext(confirmed: draft.contextConfirmed)
        ..updateNarrative(draft.narrative)
        ..toggleConsent(dataConsent.key, given: true);

      await controller.submit();

      expect(controller.submission?.outcome, IntakeOutcome.couldNotSend);
      expect(controller.draft.narrative, draft.narrative);
      expect(controller.draft.hasConsent(dataConsent.key), isTrue);
      // And it says so, so a resident does not apply again out of doubt.
      expect(
        controller.submission?.residentMessage,
        contains('nothing was submitted'),
      );
    });

    test('edit from review only goes backwards', () async {
      final repository = RecordingIntakeRepository(form: intakeForm());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('help')
        ..next();
      controller.next();
      expect(controller.step, IntakeStep.review);

      // Forward is refused; backward is honoured.
      controller.editStep(IntakeStep.outcome);
      expect(controller.step, IntakeStep.review);

      controller.editStep(IntakeStep.describe);
      expect(controller.step, IntakeStep.describe);
    });
  });

  group('submission is idempotency-aware — acceptance 2', () {
    test('a retry replays the same key rather than filing twice', () async {
      final form = intakeForm();
      final repository = RecordingIntakeRepository(form: form)
        ..submitOutcome = const Err<ServiceRequest>(TimeoutFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('I need help.');

      await controller.submit();
      await controller.retrySubmission();

      expect(repository.submitCalls, 2);
      expect(repository.idempotencyKeys.first, isNotEmpty);
      expect(
        repository.idempotencyKeys.first,
        repository.idempotencyKeys.last,
        reason:
            'A retry after a dropped connection must replay the same attempt, '
            'not create a second application.',
      );
    });

    test('a success issues a reference and retires the key', () async {
      final form = intakeForm();
      final repository = RecordingIntakeRepository(form: form);
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('I need help.');
      await controller.submit();

      expect(controller.submission?.isSuccess, isTrue);
      expect(controller.submission?.referenceNumber, 'TAY-2026-000123');

      // A later attempt is a genuinely new application, so it must not reuse
      // the key the server already answered.
      await controller.submit();
      expect(
        repository.idempotencyKeys.first,
        isNot(repository.idempotencyKeys.last),
      );
    });

    test('a conflict is reported as already open and is not retried', () async {
      final form = intakeForm();
      final repository = RecordingIntakeRepository(form: form)
        ..submitOutcome = const Err<ServiceRequest>(ConflictFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('I need help.');
      await controller.submit();

      expect(controller.submission?.outcome, IntakeOutcome.alreadyOpen);

      await controller.retrySubmission();
      expect(
        repository.submitCalls,
        1,
        reason:
            'The server has stated an application exists; asking again '
            'only makes it say so twice.',
      );
    });

    test('an incomplete form cannot be sent from review', () async {
      final form = intakeForm(consents: <IntakeConsent>[dataConsent]);
      final repository = RecordingIntakeRepository(form: form);
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      // Reached review, then stepped back and cleared a required consent.
      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('I need help.')
        ..toggleConsent(dataConsent.key, given: true);
      expect(controller.canSubmit, isTrue);

      controller.toggleConsent(dataConsent.key, given: false);
      expect(controller.canSubmit, isFalse);

      await controller.submit();
      expect(repository.submitCalls, 0);
      expect(controller.step, IntakeStep.review);
    });

    test('an unrenderable question blocks submission entirely', () async {
      final form = intakeForm(
        questions: <IntakeQuestion>[
          IntakeQuestion(
            key: 'scan',
            prompt: 'Provide a holographic capture',
            kind: unknownKind(),
          ),
        ],
      );
      final repository = RecordingIntakeRepository(form: form);
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.initialise();

      controller
        ..confirmContext(confirmed: true)
        ..updateNarrative('I need help.');

      expect(controller.isBlockedByUnknownQuestions, isTrue);
      expect(controller.canSubmit, isFalse);

      await controller.submit();
      expect(
        repository.submitCalls,
        0,
        reason:
            'Submitting would file an application the office considers '
            'incomplete, and the resident would never learn why.',
      );
    });

    test(
      'consents travel as their own field, not folded into answers',
      () async {
        final form = intakeForm(consents: <IntakeConsent>[dataConsent]);
        final repository = RecordingIntakeRepository(form: form);
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);
        await controller.initialise();

        controller
          ..confirmContext(confirmed: true)
          ..updateNarrative('I need help.')
          ..toggleConsent(dataConsent.key, given: true);
        await controller.submit();

        expect(repository.consentKeys.single, <String>['data_processing']);
        expect(
          repository.answers.single.containsKey('data_processing'),
          isFalse,
        );
        expect(repository.narratives.single, 'I need help.');
      },
    );
  });

  group('only a verified resident can apply — acceptance 1', () {
    testWidgets('a guest is sent to sign in', (tester) async {
      await bootIntake(tester, level: AccessLevel.guest, form: intakeForm());

      expect(currentLocation(tester), AppRoute.signIn.path);
      expect(find.text('Send my application'), findsNothing);
    });

    testWidgets('an unverified resident is sent to verification', (
      tester,
    ) async {
      await bootIntake(
        tester,
        level: AccessLevel.unverified,
        form: intakeForm(),
      );

      expect(currentLocation(tester), AppRoute.verification.path);
    });

    testWidgets('a verified resident reaches the first step', (tester) async {
      final booted = await bootIntake(tester, form: intakeForm());

      expect(currentLocation(tester), '/apply/CEDULA');
      expect(find.text('Who this is for'), findsOneWidget);
      expect(booted.requests.loadFormCalls, 1);
    });

    test('the capability and its route agree on verified', () {
      expect(
        ResidentCapability.applyForAssistance.requirement,
        AccessRequirement.verified,
      );
      expect(AppRoute.applyForService.requirement, AccessRequirement.verified);
      expect(
        ResidentCapability.applyForAssistance.route,
        AppRoute.applyForService,
      );
    });
  });

  group('the resident-facing surface', () {
    testWidgets('a full application reaches a reference number', (
      tester,
    ) async {
      final form = intakeForm(consents: <IntakeConsent>[dataConsent]);
      final booted = await bootIntake(tester, form: form);

      // Step 1 — confirm context.
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 — describe.
      await tester.enterText(
        find.byType(TextField).first,
        'I need help with the fee.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 — consent.
      expect(find.text('Before you send this'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4 — review, then send.
      expect(find.text('Check your answers'), findsOneWidget);
      await tester.tap(find.text('Send my application'));
      await tester.pumpAndSettle();

      expect(find.text('Application sent'), findsOneWidget);
      expect(find.textContaining('TAY-2026-000123'), findsOneWidget);
      expect(booted.requests.submitCalls, 1);
    });

    testWidgets('an already-open application is warned about up front', (
      tester,
    ) async {
      await bootIntake(
        tester,
        form: intakeForm(
          activeRequest: const ActiveRequestNotice(
            rawState: 'under_review',
            referenceNumber: 'TAY-2026-000001',
          ),
        ),
      );

      expect(
        find.text('You already have an application for this service'),
        findsOneWidget,
      );
      expect(find.textContaining('TAY-2026-000001'), findsOneWidget);
      // A warning, never a block: only the server refuses a second one.
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('an unrenderable question names itself and disables Continue', (
      tester,
    ) async {
      await bootIntake(
        tester,
        form: intakeForm(
          questions: <IntakeQuestion>[
            IntakeQuestion(
              key: 'scan',
              prompt: 'Provide a holographic capture',
              kind: unknownKind(),
            ),
          ],
        ),
      );

      expect(
        find.text('This application needs the municipal hall'),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('no staff control is exposed — acceptance 3', (tester) async {
      await bootIntake(
        tester,
        form: intakeForm(consents: <IntakeConsent>[dataConsent]),
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'approve',
        'reject',
        'assign',
        'caseworker',
        'assessment',
        'priority',
        'internal note',
        'audit',
      ]) {
        expect(
          text,
          isNot(contains(forbidden)),
          reason:
              '"$forbidden" is a staff control and has no place in the '
              'resident intake.',
        );
      }
    });

    testWidgets('the wizard survives a 200% text scale', (tester) async {
      await bootIntake(
        tester,
        form: intakeForm(
          requirements: <IntakeRequirement>[
            const IntakeRequirement(
              code: 'BARANGAY_CLEARANCE',
              label: 'Barangay clearance',
              description: 'Issued by your barangay hall within the last year.',
            ),
          ],
        ),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 4000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Who this is for'), findsOneWidget);
    });
  });
}
