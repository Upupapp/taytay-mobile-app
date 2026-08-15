import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/services/data/planned_service_request_repository.dart';
import 'package:taytay_resident/features/services/domain/assistance_case.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart'
    show Paginated, ServerValue;
import 'package:taytay_resident/features/services/domain/request_status_copy.dart';
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────

ServerValue<ServiceRequestState> caseState(ServiceRequestState value) =>
    ServerValue<ServiceRequestState>(raw: value.wireValue, known: value);

ServerValue<NextActionKind> actionKind(NextActionKind value) =>
    ServerValue<NextActionKind>(raw: value.wireValue, known: value);

ServiceRequest request({
  ServiceRequestState? state = ServiceRequestState.underVerification,
  String rawState = 'under_verification',
  String? referenceNumber = 'TAY-2026-000123',
}) => ServiceRequest(
  id: 'req-1',
  serviceCode: 'AICS',
  state: state,
  rawState: rawState,
  submittedAt: DateTime.utc(2026, 8, 1),
  referenceNumber: referenceNumber,
);

AssistanceCaseDetail caseDetail({
  ServiceRequest? subject,
  List<CaseTimelineEntry>? timeline,
  List<CaseNextAction> nextActions = const <CaseNextAction>[],
  String? outcomeReason,
  String? releaseInstructions,
  String? referral,
}) => AssistanceCaseDetail(
  request: subject ?? request(),
  timeline:
      timeline ??
      <CaseTimelineEntry>[
        CaseTimelineEntry(
          occurredAt: DateTime.utc(2026, 8, 1),
          state: caseState(ServiceRequestState.submitted),
          summary: 'You sent this application.',
        ),
        CaseTimelineEntry(
          occurredAt: DateTime.utc(2026, 8, 4),
          state: caseState(ServiceRequestState.underVerification),
          summary: 'Taytay LGU started checking your documents.',
        ),
      ],
  nextActions: nextActions,
  outcomeReason: outcomeReason,
  releaseInstructions: releaseInstructions,
  referral: referral,
);

class StubCaseRepository implements ServiceRequestRepository {
  StubCaseRepository({this.detail});

  AssistanceCaseDetail? detail;
  int caseCalls = 0;

  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) async {
    caseCalls++;
    final value = detail;
    return value == null
        ? const Err<AssistanceCaseDetail>(ServerFailure(isTemporary: true))
        : Ok<AssistanceCaseDetail>(value);
  }

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 20,
  }) async => Ok<Paginated<ServiceRequest>>(
    Paginated<ServiceRequest>.single(<ServiceRequest>[request()]),
  );

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      Ok<ServiceRequest>(request());

  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async => const Err<AssistanceIntakeForm>(ServerFailure());

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async => const Err<ServiceRequest>(ServerFailure());

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

Future<StubCaseRepository> bootCase(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  AssistanceCaseDetail? detail,
  ServiceRequestRepository? repositoryOverride,
  String location = '/requests/req-1',
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

  final requests = StubCaseRepository(detail: detail);
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
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: repositoryOverride ?? requests,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
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

  return requests;
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('status copy — acceptance 1', () {
    test('every canonical state has resident wording', () {
      for (final state in ServiceRequestState.values) {
        expect(requestStatusLabel(state), isNotEmpty);
        expect(requestStatusMeaning(state), isNotEmpty);
      }
    });

    test('an unrecognised state reads neutrally rather than alarmingly', () {
      // A released app meets values added after it shipped.
      expect(requestStatusLabel(null), 'Being processed');
      expect(
        requestStatusMeaning(null),
        contains('Nothing is needed from you'),
      );
    });

    test('an assigned case never names a staff member', () {
      final label = requestStatusLabel(ServiceRequestState.assigned);
      expect(label, 'With a Taytay LGU officer');
      expect(label.toLowerCase(), isNot(contains('assigned to')));
    });

    test('waiting-on-resident states are marked as such', () {
      expect(ServiceRequestState.waitingRequirements.needsResident, isTrue);
      expect(ServiceRequestState.readyForRelease.needsResident, isTrue);
      expect(ServiceRequestState.underVerification.needsResident, isFalse);
      expect(ServiceRequestState.pendingReview.needsResident, isFalse);
    });

    test('terminal states are exactly the three that end a case', () {
      final terminal = ServiceRequestState.values
          .where((state) => state.isTerminal)
          .toSet();
      expect(terminal, <ServiceRequestState>{
        ServiceRequestState.completed,
        ServiceRequestState.rejected,
        ServiceRequestState.cancelled,
      });
    });
  });

  group('the case model cannot carry staff data', () {
    test(
      'a next action this build does not know is described, not actioned',
      () {
        const unknown = CaseNextAction(
          kind: ServerValue<NextActionKind>(
            raw: 'schedule_home_visit',
            known: null,
          ),
          label: 'Wait for a home visit',
        );

        expect(unknown.isActionable, isFalse);
        // The label still tells the resident what the office wants.
        expect(unknown.label, isNotEmpty);
      },
    );

    test('the detail exposes only resident-safe fields', () {
      final detail = caseDetail();

      // A screen cannot leak what its model cannot hold: there is no field for
      // an assessment, a note, a score or a staff identity anywhere here.
      expect(detail.timeline.first.summary, isNotEmpty);
      expect(detail.outcomeReason, isNull);
      expect(detail.latest?.state.known, ServiceRequestState.underVerification);
    });

    test(
      'the shipped repository declines rather than composing a history',
      () async {
        const repository = PlannedServiceRequestRepository();

        final result = await repository.loadOwnCase('req-1');

        expect(result.isErr, isTrue);
      },
    );
  });

  group('the case screen', () {
    testWidgets('shows friendly copy and keeps the canonical value', (
      tester,
    ) async {
      await bootCase(tester, detail: caseDetail());

      expect(find.text('Being checked'), findsOneWidget);
      // Acceptance 1: the office's own value stays traceable, labelled as such.
      expect(find.text('Status code used by the office'), findsOneWidget);
      expect(find.text('under_verification'), findsOneWidget);
      expect(find.text('TAY-2026-000123'), findsOneWidget);
    });

    testWidgets('says whose turn it is', (tester) async {
      await bootCase(
        tester,
        detail: caseDetail(
          subject: request(
            state: ServiceRequestState.waitingRequirements,
            rawState: 'waiting_requirements',
          ),
        ),
      );

      expect(find.text('Waiting for your documents'), findsOneWidget);
      expect(find.textContaining('waiting for you'), findsOneWidget);
    });

    testWidgets('renders the timeline newest first', (tester) async {
      await bootCase(tester, detail: caseDetail());

      expect(find.text('History'), findsOneWidget);
      expect(find.text('You sent this application.'), findsOneWidget);
      expect(
        find.text('Taytay LGU started checking your documents.'),
        findsOneWidget,
      );

      final text = renderedText(tester);
      expect(
        text.indexOf('started checking'),
        lessThan(text.indexOf('You sent this application.')),
        reason: 'The most recent update is what a resident opened the app for.',
      );
    });

    testWidgets('offers only the next actions the backend sent', (
      tester,
    ) async {
      await bootCase(
        tester,
        detail: caseDetail(
          nextActions: <CaseNextAction>[
            CaseNextAction(
              kind: actionKind(NextActionKind.uploadRequirement),
              label: 'Send your barangay clearance',
              detail: 'The office cannot continue without it.',
            ),
          ],
        ),
      );

      expect(find.text('What to do next'), findsOneWidget);
      expect(find.text('Send your barangay clearance'), findsOneWidget);
      // Not offered, because the server did not offer it.
      expect(find.text('View release instructions'), findsNothing);
    });

    testWidgets('an actionable next step navigates and submits nothing', (
      tester,
    ) async {
      await bootCase(
        tester,
        detail: caseDetail(
          nextActions: <CaseNextAction>[
            CaseNextAction(
              kind: actionKind(NextActionKind.uploadRequirement),
              label: 'Send your barangay clearance',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/requests/req-1/requirements');
    });

    testWidgets('an unknown next action offers no button', (tester) async {
      await bootCase(
        tester,
        detail: caseDetail(
          nextActions: const <CaseNextAction>[
            CaseNextAction(
              kind: ServerValue<NextActionKind>(
                raw: 'schedule_home_visit',
                known: null,
              ),
              label: 'Wait for a home visit',
            ),
          ],
        ),
      );

      expect(find.text('Wait for a home visit'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('a rejection reason appears only when the office sent one', (
      tester,
    ) async {
      await bootCase(
        tester,
        detail: caseDetail(
          subject: request(
            state: ServiceRequestState.rejected,
            rawState: 'rejected',
          ),
        ),
      );

      expect(find.text('Not approved'), findsOneWidget);
      // Nothing invented in the LGU's name.
      expect(find.text('What Taytay LGU said'), findsNothing);
    });

    testWidgets('a published rejection reason is shown', (tester) async {
      await bootCase(
        tester,
        detail: caseDetail(
          subject: request(
            state: ServiceRequestState.rejected,
            rawState: 'rejected',
          ),
          outcomeReason:
              'Your household already received this assistance this quarter.',
        ),
      );

      expect(find.text('What Taytay LGU said'), findsOneWidget);
      expect(
        find.text(
          'Your household already received this assistance this quarter.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('release instructions and referral show when provided', (
      tester,
    ) async {
      await bootCase(
        tester,
        detail: caseDetail(
          subject: request(
            state: ServiceRequestState.readyForRelease,
            rawState: 'ready_for_release',
          ),
          releaseInstructions:
              'Collect at the Taytay municipal hall, window 4.',
          referral: 'Referred to the Provincial Social Welfare Office.',
        ),
      );

      expect(find.text('Collecting this'), findsOneWidget);
      expect(find.text('Referred onward'), findsOneWidget);
    });

    testWidgets('an absent backend explains rather than showing a blank case', (
      tester,
    ) async {
      await bootCase(
        tester,
        repositoryOverride: const PlannedServiceRequestRepository(),
      );

      expect(find.textContaining('not switched on'), findsOneWidget);
      expect(find.text('History'), findsNothing);
    });

    testWidgets('a malformed identifier is refused', (tester) async {
      await bootCase(
        tester,
        detail: caseDetail(),
        location: '/requests/..%2F..%2Fadmin',
      );

      expect(find.text('This request is not available'), findsOneWidget);
    });

    testWidgets('a guest is sent to sign in', (tester) async {
      await bootCase(tester, level: AccessLevel.guest, detail: caseDetail());
      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('an unverified resident is sent to verification', (
      tester,
    ) async {
      await bootCase(
        tester,
        level: AccessLevel.unverified,
        detail: caseDetail(),
      );
      expect(currentLocation(tester), AppRoute.verification.path);
    });

    testWidgets('no internal vocabulary reaches the screen — acceptance 2', (
      tester,
    ) async {
      await bootCase(
        tester,
        detail: caseDetail(
          nextActions: <CaseNextAction>[
            CaseNextAction(
              kind: actionKind(NextActionKind.awaitReview),
              label: 'Wait for Taytay LGU to finish checking',
            ),
          ],
          outcomeReason: 'The office needs one more document.',
        ),
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'caseworker',
        'assessment',
        'risk',
        'score',
        'internal',
        'audit',
        'handoff',
        'assigned to',
      ]) {
        expect(
          text,
          isNot(contains(forbidden)),
          reason:
              '"$forbidden" is staff vocabulary and must never reach a '
              'resident.',
        );
      }
    });

    testWidgets('the case survives a 200% text scale', (tester) async {
      await bootCase(
        tester,
        detail: caseDetail(
          nextActions: <CaseNextAction>[
            CaseNextAction(
              kind: actionKind(NextActionKind.uploadRequirement),
              label: 'Send your barangay clearance',
              detail: 'The office cannot continue without it.',
            ),
          ],
        ),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 5000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Being checked'), findsOneWidget);
    });
  });
}
