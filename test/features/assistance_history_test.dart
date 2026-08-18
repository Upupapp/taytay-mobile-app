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
import 'package:taytay_resident/features/services/domain/assistance_case.dart';
import 'package:taytay_resident/features/services/domain/assistance_history.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart'
    show Paginated, ServerValue;
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';
import 'package:taytay_resident/features/services/presentation/release_and_referral.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real resident, reference number or amount.

ServerValue<ServiceRequestState> historyStatus(ServiceRequestState value) =>
    ServerValue<ServiceRequestState>(raw: value.wireValue, known: value);

AssistanceHistoryEntry entry({
  String requestId = 'req-1',
  String serviceCode = 'AICS',
  String? serviceName = 'Assistance to Individuals in Crisis',
  ServiceRequestState state = ServiceRequestState.completed,
  String? referenceNumber = 'TAY-2026-000123',
  DateTime? submittedAt,
  DateTime? completedAt,
  String? outcomeSummary,
  String? receiptReference,
}) => AssistanceHistoryEntry(
  requestId: requestId,
  serviceCode: serviceCode,
  serviceName: serviceName,
  status: historyStatus(state),
  referenceNumber: referenceNumber,
  submittedAt: submittedAt ?? DateTime.utc(2026, 7, 1),
  completedAt: completedAt,
  outcomeSummary: outcomeSummary,
  receiptReference: receiptReference,
);

class StubHistoryRepository implements ServiceRequestRepository {
  StubHistoryRepository({this.open, this.past});

  List<AssistanceHistoryEntry>? open;
  List<AssistanceHistoryEntry>? past;

  final List<HistoryScope> requestedScopes = <HistoryScope>[];

  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int perPage = 25,
  }) async {
    requestedScopes.add(scope);
    final items = scope.isPast ? past : open;
    return items == null
        ? const Err<Paginated<AssistanceHistoryEntry>>(
            ServerFailure(isTemporary: true),
          )
        : Ok<Paginated<AssistanceHistoryEntry>>(
            Paginated<AssistanceHistoryEntry>.single(items),
          );
  }

  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) async =>
      const Err<AssistanceCaseDetail>(ServerFailure(isTemporary: true));

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<ServiceRequest>>(ServerFailure());

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      const Err<ServiceRequest>(ServerFailure());

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

Future<StubHistoryRepository> bootHistory(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  List<AssistanceHistoryEntry>? open,
  List<AssistanceHistoryEntry>? past,
  ServiceRequestRepository? repositoryOverride,
  String location = '/requests',
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

  final requests = StubHistoryRepository(open: open, past: past);
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
    serviceRequestRepository: repositoryOverride ?? requests,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
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

  return requests;
}

/// Renders one card on its own, for the presentation-only assertions.
Future<void> pumpCard(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
  await tester.pumpAndSettle();
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('the history model', () {
    test('a finished entry is one whose status is terminal', () {
      expect(entry(state: ServiceRequestState.completed).isFinished, isTrue);
      expect(entry(state: ServiceRequestState.rejected).isFinished, isTrue);
      expect(entry(state: ServiceRequestState.cancelled).isFinished, isTrue);
      expect(entry(state: ServiceRequestState.processing).isFinished, isFalse);
    });

    test('an unrecognised status is not assumed finished', () {
      const unknown = AssistanceHistoryEntry(
        requestId: 'req-9',
        serviceCode: 'X',
        status: ServerValue<ServiceRequestState>(
          raw: 'awaiting_board_approval',
          known: null,
        ),
      );

      expect(unknown.isFinished, isFalse);
    });

    test('an entry redacts its outcome in toString', () {
      final subject = entry(outcomeSummary: 'PHP 5,000 cash assistance');

      // What a person received is a fact about their circumstances.
      expect(subject.toString(), isNot(contains('5,000')));
    });

    test('an empty release is recognised as empty', () {
      expect(const ReleaseDetail().isEmpty, isTrue);
      expect(
        const ReleaseDetail(amountDescription: 'One sack of rice').isEmpty,
        isFalse,
      );
    });

    test('every referral status has resident wording, including unknown', () {
      for (final status in ReferralStatus.values) {
        expect(referralStatusLabel(status), isNotEmpty);
      }
      expect(referralStatusLabel(null), 'Being processed');
    });

    test('a declined referral still points somewhere', () {
      // A referral that stops with no next step is how someone gives up on a
      // service they are entitled to.
      expect(
        referralStatusLabel(ReferralStatus.declined),
        contains('what happens next'),
      );
    });

    testWidgets('renders an in-kind description just as happily', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ReleaseCard(
          release: ReleaseDetail(amountDescription: 'One sack of rice, 25 kg'),
        ),
      );

      expect(find.text('One sack of rice, 25 kg'), findsOneWidget);
    });

    testWidgets('omits absent fields instead of showing empty rows', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ReleaseCard(
          release: ReleaseDetail(amountDescription: 'PHP 1,000'),
        ),
      );

      // A date row reading "—" looks like a system that lost the information.
      expect(find.text('When'), findsNothing);
      expect(find.text('Where'), findsNothing);
    });

    testWidgets('states the acknowledgement rather than offering it', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ReleaseCard(
          release: ReleaseDetail(
            amountDescription: 'PHP 1,000',
            acknowledgement: ServerValue<ReleaseAcknowledgement>(
              raw: 'awaiting_resident',
              known: ReleaseAcknowledgement.awaitingResident,
            ),
          ),
        ),
      );

      expect(
        find.textContaining('will ask you to confirm receipt'),
        findsOneWidget,
      );
      // Acknowledging receipt is a signature at a counter, not a tap in advance.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('no funding or accounting vocabulary appears', (tester) async {
      await pumpCard(
        tester,
        const ReleaseCard(
          release: ReleaseDetail(
            amountDescription: 'PHP 5,000.00',
            location: 'Taytay municipal hall, window 4',
            instructions: 'Bring a valid ID.',
          ),
        ),
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'budget',
        'fund source',
        'disbursement',
        'batch',
        'manifest',
        'beneficiar',
        'voucher no',
      ]) {
        expect(
          text,
          isNot(contains(forbidden)),
          reason: '"$forbidden" is an accounting internal.',
        );
      }
    });
  });

  group('the referral card', () {
    testWidgets('shows a contact only when the office published one', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ReferralCard(
          referral: ReferralDetail(
            destination: 'Provincial Social Welfare Office',
            serviceRequested: 'Medical assistance',
          ),
        ),
      );

      expect(find.text('Provincial Social Welfare Office'), findsOneWidget);
      expect(find.text('Contact'), findsNothing);
    });

    testWidgets('shows the contact when it was published', (tester) async {
      await pumpCard(
        tester,
        const ReferralCard(
          referral: ReferralDetail(
            destination: 'Provincial Social Welfare Office',
            contact: '(02) 8000 0000',
          ),
        ),
      );

      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('(02) 8000 0000'), findsOneWidget);
    });
  });

  group('the history list', () {
    testWidgets('opens on the open scope and asks for it', (tester) async {
      final repository = await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(state: ServiceRequestState.processing),
        ],
      );

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(repository.requestedScopes, <HistoryScope>[HistoryScope.open]);
    });

    testWidgets('switching to Past refetches with the past scope', (
      tester,
    ) async {
      final repository = await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(state: ServiceRequestState.processing),
        ],
        past: <AssistanceHistoryEntry>[
          entry(
            requestId: 'req-2',
            state: ServiceRequestState.completed,
            completedAt: DateTime.utc(2026, 7, 20),
            outcomeSummary: 'PHP 5,000 cash assistance released.',
          ),
        ],
      );

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(repository.requestedScopes, <HistoryScope>[
        HistoryScope.open,
        HistoryScope.past,
      ]);
      expect(find.text('PHP 5,000 cash assistance released.'), findsOneWidget);
      expect(find.text('Finished: 20 Jul 2026'), findsOneWidget);
    });

    testWidgets('an empty scope reads differently from a failure', (
      tester,
    ) async {
      // Empty: the office genuinely has nothing for this scope.
      await bootHistory(tester, open: const <AssistanceHistoryEntry>[]);
      expect(find.text('You have no open requests'), findsOneWidget);
      expect(find.text('Not available yet'), findsNothing);
    });

    testWidgets('a failure never reads as "you have no record"', (
      tester,
    ) async {
      // `open: null` makes the stub fail. Telling a resident their record is
      // empty when the app simply could not reach the LGU is the failure this
      // separation exists to prevent.
      await bootHistory(tester);

      expect(find.text('Not available yet'), findsOneWidget);
      expect(find.text('You have no open requests'), findsNothing);
    });

    testWidgets('the past scope has its own empty wording', (tester) async {
      await bootHistory(
        tester,
        open: const <AssistanceHistoryEntry>[],
        past: const <AssistanceHistoryEntry>[],
      );

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing finished yet'), findsOneWidget);
    });

    testWidgets('a card falls back to the code when there is no name', (
      tester,
    ) async {
      await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(serviceName: null, state: ServiceRequestState.processing),
        ],
      );

      // A code a resident can quote beats a blank.
      expect(find.text('AICS'), findsOneWidget);
    });

    testWidgets('a receipt is a reference, not a download', (tester) async {
      await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[entry(receiptReference: 'RCPT-0099')],
      );

      expect(
        find.textContaining('Receipt reference RCPT-0099'),
        findsOneWidget,
      );
      // No button that would fetch a document no endpoint serves.
      expect(find.text('Download'), findsNothing);
      expect(find.text('Download receipt'), findsNothing);
    });

    testWidgets('tapping a record opens its case', (tester) async {
      await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(state: ServiceRequestState.processing),
        ],
      );

      await tester.tap(find.text('Assistance to Individuals in Crisis'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/requests/req-1');
    });

    testWidgets('no staff vocabulary reaches the list — acceptance 3', (
      tester,
    ) async {
      await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(
            state: ServiceRequestState.assigned,
            outcomeSummary: 'Being handled by the social welfare office.',
          ),
        ],
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'caseworker',
        'assessment',
        'internal',
        'audit',
        'budget',
        'disbursement',
        'other beneficiaries',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('a guest is sent to sign in — acceptance 1', (tester) async {
      await bootHistory(
        tester,
        level: AccessLevel.guest,
        open: <AssistanceHistoryEntry>[entry()],
      );

      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('an unverified resident is sent to verification', (
      tester,
    ) async {
      await bootHistory(
        tester,
        level: AccessLevel.unverified,
        open: <AssistanceHistoryEntry>[entry()],
      );

      expect(currentLocation(tester), AppRoute.verification.path);
    });

    testWidgets('the list survives a 200% text scale', (tester) async {
      await bootHistory(
        tester,
        open: <AssistanceHistoryEntry>[
          entry(
            outcomeSummary: 'PHP 5,000 cash assistance released.',
            completedAt: DateTime.utc(2026, 7, 20),
            receiptReference: 'RCPT-0099',
          ),
        ],
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 5000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
