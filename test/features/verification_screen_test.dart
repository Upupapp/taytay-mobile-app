import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

/// Serves a fixed status so a test can assert what a resident sees.
class StubVerificationRepository implements VerificationRepository {
  StubVerificationRepository(this.detail);

  VerificationStatusDetail detail;

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      Ok<VerificationStatusDetail>(detail);

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure(isTemporary: true));

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the app onto the verification screen with a given status.
Future<AppDependencies> bootVerification(
  WidgetTester tester, {
  required VerificationStatusDetail detail,
  AccessLevel level = AccessLevel.unverified,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  await sessionStore.write(
    StoredSession(
      resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
      accessToken: 'token',
    ),
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
  );
  // Swap in the stub while keeping every other wire intact.
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
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: StubVerificationRepository(detail),
    serviceRequestRepository: base.serviceRequestRepository,
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

  // Scrolled first: at a large text scale the tile sits below the fold, and a
  // `ListView` only builds what fits — so the widget is genuinely absent from
  // the tree and `ensureVisible` cannot find it. `scrollUntilVisible` scrolls
  // until it is built.
  // TAB 11: Home's next-action card is how a signed-in resident reaches
  // verification. Its button label comes from the stage when one has loaded,
  // and falls back to "Check my status" when it has not.
  final action = find.text('Check my status').evaluate().isNotEmpty
      ? find.text('Check my status')
      : find.byType(FilledButton).first;
  await scrollToTile(tester, action);
  await tester.tap(action);
  await tester.pumpAndSettle();

  return dependencies;
}

/// Scrolls the home list until [finder] has been built and is on screen.
Future<void> scrollToTile(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Returns to the home screen.
///
/// The verification route is entered with `go`, which replaces the location, so
/// there is no back button to press — navigation is explicit, as it is in the app.
Future<void> goHome(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).goNamed('home');
  await tester.pumpAndSettle();
}

void main() {
  group('status is understandable without staff detail', () {
    testWidgets(
      'pending review states what is happening and offers no action',
      (tester) async {
        await bootVerification(
          tester,
          detail: const VerificationStatusDetail(
            stage: ResidentVerificationStage.pendingReview,
            rawState: 'under_review',
            submittedCategories: <VerificationItemCategory>[
              VerificationItemCategory.personalDetails,
              VerificationItemCategory.address,
            ],
          ),
        );

        expect(find.text('Waiting for review'), findsOneWidget);
        expect(find.text('What Taytay LGU has from you'), findsOneWidget);
        expect(find.text('Your details'), findsOneWidget);
        expect(find.text('Your address'), findsOneWidget);
        // Categories, never values.
        expect(find.textContaining('Name and date of birth'), findsOneWidget);
      },
    );

    testWidgets('no turnaround promise appears on screen', (tester) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.pendingReview,
          rawState: 'under_review',
        ),
      );

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();

      expect(
        rendered,
        isNot(matches(RegExp(r'\b\d+\s*(day|days|week|weeks)\b'))),
      );
      expect(rendered, isNot(contains('guarantee')));
    });

    testWidgets('the raw server state is never shown as the status', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.manualReview,
          rawState: 'awaiting_barangay_endorsement',
        ),
      );

      expect(
        find.textContaining('awaiting_barangay_endorsement'),
        findsNothing,
      );
      expect(find.text('Needs a person to check'), findsOneWidget);
    });
  });

  group('every unsuccessful state offers a safe next step', () {
    testWidgets('unsuccessful offers retry and the municipal hall', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.unsuccessful,
          rawState: 'rejected',
        ),
      );

      expect(find.text('Could not be verified'), findsOneWidget);
      expect(find.text('Try again'), findsWidgets);
      expect(find.text('Finish at the municipal hall'), findsOneWidget);
    });

    testWidgets('manual review offers the municipal hall', (tester) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.manualReview,
          rawState: 'manual',
          manualReviewAvailable: true,
        ),
      );

      expect(find.text('Finish at the municipal hall'), findsOneWidget);
      expect(
        find.textContaining('do not need anything from this app'),
        findsOneWidget,
      );
    });

    testWidgets('not started explains why verification is worth doing', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: 'not_started',
        ),
      );

      expect(find.text('Not started'), findsOneWidget);
      expect(find.text('Start verification'), findsWidgets);
    });
  });

  group('needs more information', () {
    testWidgets('shows only the flagged items with the office instruction', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'under_review',
          submittedCategories: <VerificationItemCategory>[
            VerificationItemCategory.personalDetails,
            VerificationItemCategory.address,
          ],
          issues: <VerificationItemIssue>[
            VerificationItemIssue(
              category: VerificationItemCategory.address,
              instruction: 'Add your house number.',
            ),
          ],
          residentGuidance: 'We could not find that address.',
        ),
      );

      expect(find.text('One thing to fix'), findsOneWidget);
      expect(find.textContaining('Add your house number.'), findsWidgets);
      expect(find.text('From Taytay LGU'), findsOneWidget);
      // The unflagged category is not presented as needing correction.
      expect(find.text('Two things to fix'), findsNothing);
    });

    testWidgets('sending is disabled until the item is answered', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'under_review',
          issues: <VerificationItemIssue>[
            VerificationItemIssue(
              category: VerificationItemCategory.address,
              instruction: 'Add your house number.',
            ),
          ],
        ),
      );

      expect(find.text('Fill in every item above to send.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '12 Rizal St');
      await tester.pumpAndSettle();

      expect(find.text('Fill in every item above to send.'), findsNothing);
    });
  });

  group('verified unlocks access without a restart', () {
    testWidgets(
      'the session level rises and the digital ID becomes reachable',
      (tester) async {
        final dependencies = await bootVerification(
          tester,
          detail: const VerificationStatusDetail(
            stage: ResidentVerificationStage.verified,
            rawState: 'approved',
          ),
        );

        expect(find.text('Verified'), findsWidgets);
        // Acceptance 2: centralized state, same session, no restart.
        expect(dependencies.session.accessLevel, AccessLevel.verified);

        // The gate is gone: TAB 11's Home offers the credential as the next
        // action, and it opens directly — same session, no restart.
        await goHome(tester);
        await scrollToTile(tester, find.text('Open my digital ID'));
        await tester.tap(find.text('Open my digital ID'));
        await tester.pumpAndSettle();

        expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);
        expect(find.text('Sign in to continue'), findsNothing);
        expect(find.text('Verify your identity'), findsNothing);
      },
    );
  });

  group('accessibility', () {
    testWidgets('the status headline is announced as a live region', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.pendingReview,
          rawState: 'under_review',
        ),
      );

      final semantics = tester.getSemantics(
        find
            .ancestor(
              of: find.text('Waiting for review'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics, isNotNull);
    });

    testWidgets('the screen survives a 200% text scale', (tester) async {
      await bootVerification(
        tester,
        textScaler: const TextScaler.linear(2),
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'under_review',
          submittedCategories: <VerificationItemCategory>[
            VerificationItemCategory.personalDetails,
          ],
          issues: <VerificationItemIssue>[
            VerificationItemIssue(
              category: VerificationItemCategory.address,
              instruction: 'Add your house number.',
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
