import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/citizen_api/domain/citizen_contract.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/platform/domain/verification_review_time.dart';
import 'package:taytay_resident/features/profile/domain/name_lock.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
import 'package:taytay_resident/features/verification/domain/field_correction_note.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_face.dart';
import 'package:taytay_resident/features/verification/domain/verification_id_type.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/domain/verification_submit_outcome.dart';
import 'package:taytay_resident/features/verification/presentation/manila_stamp.dart';
import 'package:taytay_resident/features/verification/presentation/s3_chrome.dart';
import 'package:taytay_resident/features/verification/presentation/verification_screen.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/shared/widgets/biometric_consent_dialog.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';
import 'package:taytay_resident/shared/widgets/taytay_buttons.dart';

import '../support/biometric_fakes.dart';
import '../support/layout_matrix.dart';

/// Serves a fixed status so a test can assert what a resident sees.
class StubVerificationRepository implements VerificationRepository {
  StubVerificationRepository(this.detail);

  VerificationStatusDetail detail;
  int startCalls = 0;
  int replaceCalls = 0;
  int correctionCalls = 0;
  String? lastIdType;
  String? lastMessage;

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      Ok<VerificationStatusDetail>(detail);

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure(isTemporary: true));

  @override
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
    String message = '',
    bool allowBlank = false,
  }) async {
    correctionCalls++;
    lastMessage = message;
    return const Ok<void>(null);
  }

  @override
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required VerificationImagePart front,
    VerificationImagePart? back,
    required VerificationImagePart selfie,
    String? idempotencyKey,
  }) async {
    startCalls++;
    lastIdType = idType;
    return const Ok<VerificationStatus>(
      VerificationStatus(
        state: VerificationAttemptState.underReview,
        rawState: 'pending',
      ),
    );
  }

  @override
  Future<Result<VerificationStatusDetail>> replaceDocuments({
    VerificationImagePart? front,
    VerificationImagePart? back,
    VerificationImagePart? selfie,
    String? idempotencyKey,
  }) async {
    replaceCalls++;
    return Ok<VerificationStatusDetail>(detail);
  }

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) async => const Err<KycDocument>(ServerFailure());

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async =>
      const Ok<List<KycDocument>>(<KycDocument>[]);

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async => const Err<VerificationStatus>(ServerFailure());

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

class _ReadyPicker implements DocumentPicker {
  CapturedDocument get _file => CapturedDocument(
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    fileName: 'sample.jpg',
    mimeType: 'image/jpeg',
    source: DocumentSource.gallery,
  );

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => _file;

  @override
  bool supports(DocumentSource source) => true;
}

Future<AppDependencies> bootVerification(
  WidgetTester tester, {
  required VerificationStatusDetail detail,
  AccessLevel level = AccessLevel.unverified,
  DocumentPicker? picker,
  PlatformRepository? platformRepository,
  AccountControlsRepository? consents,
  VerificationRepository? repository,
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
    // The selfie consent published and given unless a test says otherwise:
    // a selfie is offered only then (D-209).
    platformRepository: platformRepository ?? BiometricPlatform(),
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: repository ?? StubVerificationRepository(detail),
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: picker ?? base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: consents ?? BiometricConsents(),
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  await tester.tap(find.text('My Account').last);
  await tester.pumpAndSettle();
  final shortcut = find.text('Verify my identity');
  final scrollable = find
      .descendant(
        of: find
            .ancestor(
              of: find.byKey(const Key('profile-screen')),
              matching: find.byType(Scaffold),
            )
            .first,
        matching: find.byType(Scrollable),
      )
      .first;
  for (
    var attempt = 0;
    attempt < 15 && shortcut.evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(shortcut.first);
  await tester.tap(shortcut.first);
  await tester.pumpAndSettle();
  return dependencies;
}

void main() {
  group('the tier picks the screen and fails closed', () {
    test('only the exact word verified is the verified face', () {
      expect(verificationFaceFor('verified'), VerificationFace.verified);
      expect(verificationFaceFor('VERIFIED'), VerificationFace.unverified);
      expect(verificationFaceFor('approved'), VerificationFace.unverified);
      expect(verificationFaceFor('pending'), VerificationFace.pending);
      expect(verificationFaceFor('rejected'), VerificationFace.needsCorrection);
      expect(
        verificationFaceFor('unverified', fieldNotes: true),
        VerificationFace.needsCorrection,
      );
      expect(verificationFaceFor('gold'), VerificationFace.unverified);
      expect(verificationFaceFor(null), VerificationFace.unverified);
      expect(
        verificationFaceFor('gold', fieldNotes: true),
        VerificationFace.unverified,
      );
      expect(AccessLevel.fromVerificationTier('gold'), AccessLevel.unverified);
    });

    test('a Manila stamp keeps the design clock', () {
      expect(
        formatManilaStamp(DateTime.utc(2026, 10, 20, 12, 12)),
        'Oct 20, 2026 · 8:12 PM',
      );
      expect(
        formatManilaStamp(DateTime.utc(2026, 10, 20, 12, 40)),
        'Oct 20, 2026 · 8:40 PM',
      );
      expect(formatManilaDate(DateTime.utc(2026, 10, 22)), 'Oct 22, 2026');
      expect(idTypeLabel('philid'), 'PhilSys National ID');
    });

    test('a 403 does not stamp verified without the server tier', () {
      final source = File(
        'lib/features/auth/presentation/account_wizard_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains("applyVerificationTier('verified')")));
      expect(source, contains('loadOwnDetail'));
      expect(source, contains('AccessLevel.fromVerificationTier'));
    });

    test('409 opens pending review and 403 continues as verified', () {
      expect(
        verificationSubmitOutcome(const ConflictFailure()),
        VerificationSubmitOutcome.pendingReview,
      );
      expect(
        verificationSubmitOutcome(const ForbiddenFailure()),
        VerificationSubmitOutcome.continueVerified,
      );
      expect(verificationSubmitOutcome(null), VerificationSubmitOutcome.opened);
      expect(
        verificationSubmitOutcome(const NetworkFailure()),
        VerificationSubmitOutcome.failed,
      );
    });
  });

  group('status pages', () {
    testWidgets('pending, verified and needs-correction say what they are', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: PendingStatusPage()));
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Your account is verified'), findsNothing);

      await tester.pumpWidget(const MaterialApp(home: VerifiedStatusPage()));
      expect(find.text('Your account is verified'), findsOneWidget);
      expect(find.text('Not verified'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: NeedsCorrectionPage(
            notes: <FieldCorrectionNote>[
              FieldCorrectionNote(
                label: 'ID photo',
                note: 'The photo is blurry. Retake the front of your ID.',
              ),
              FieldCorrectionNote(
                label: 'Address',
                note: 'Barangay does not match the ID.',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Needs correction'), findsNWidgets(2));
      expect(find.text('ID photo'), findsOneWidget);
      expect(find.textContaining('The photo is blurry'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Your account is verified'), findsNothing);
    });

    testWidgets('an unknown tier renders as unverified', (tester) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.manualReview,
          rawState: 'gold',
        ),
      );

      expect(find.text('Not verified'), findsOneWidget);
      expect(find.text('Your account is verified'), findsNothing);
      expect(find.text('Verification status'), findsOneWidget);
    });

    testWidgets('can_edit false disables resubmit and re-upload', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.unsuccessful,
          rawState: 'rejected',
          canEdit: false,
          issues: <VerificationItemIssue>[
            VerificationItemIssue(
              category: VerificationItemCategory.other,
              instruction: 'Send a clearer photo.',
            ),
          ],
        ),
        picker: _ReadyPicker(),
      );
      final repository =
          dependencies.verificationRepository as StubVerificationRepository;

      expect(find.text('Previous selfie kept'), findsNothing);
      expect(find.text('Details'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      final PrimaryButton resubmit = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Resubmit for verification'),
      );
      expect(resubmit.onPressed, isNull);
      await tester.ensureVisible(find.text('Upload new photo'));
      await tester.tap(find.text('Upload new photo'));
      await tester.pump();
      expect(repository.replaceCalls, 0);
      expect(repository.correctionCalls, 0);
    });

    testWidgets('can_edit true enables resubmit and keeps a sent selfie', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.unsuccessful,
          rawState: 'rejected',
          canEdit: true,
          selfieMediaId: '11111111-1111-4111-8111-111111111111',
        ),
      );
      final repository =
          dependencies.verificationRepository as StubVerificationRepository;

      expect(find.text('Previous selfie kept'), findsOneWidget);
      final PrimaryButton resubmit = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Resubmit for verification'),
      );
      expect(resubmit.onPressed, isNotNull);

      await tester.tap(find.text('Resubmit for verification'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('verification-message-field')),
        'The front is clearer now.',
      );
      await tester.tap(find.byKey(const Key('verification-resubmit-confirm')));
      await tester.pumpAndSettle();
      expect(repository.lastMessage, 'The front is clearer now.');
      expect(repository.correctionCalls, 1);
    });

    testWidgets('a blank resubmit message is sent as the resident left it', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.unsuccessful,
          rawState: 'rejected',
          canEdit: true,
        ),
      );
      final repository =
          dependencies.verificationRepository as StubVerificationRepository;
      await tester.tap(find.text('Resubmit for verification'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('verification-resubmit-confirm')));
      await tester.pumpAndSettle();
      expect(repository.lastMessage, '');
      expect(repository.correctionCalls, 1);
    });

    testWidgets('start stays disabled until the front and the selfie exist', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: '',
        ),
        picker: _ReadyPicker(),
      );
      final repository =
          dependencies.verificationRepository as StubVerificationRepository;

      expect(find.text('Previous selfie kept'), findsNothing);
      expect(find.text('Take a selfie'), findsOneWidget);
      PrimaryButton start() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Start verification'),
      );
      expect(start().onPressed, isNull);

      await tester.ensureVisible(find.byKey(const Key('verification-id-type')));
      await tester.tap(find.byKey(const Key('verification-id-front')));
      await tester.pump();
      expect(start().onPressed, isNull);
      await tester.tap(find.byKey(const Key('verification-selfie')));
      await tester.pump();
      expect(start().onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('verification-id-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passport'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start verification'));
      await tester.pumpAndSettle();
      expect(repository.startCalls, 1);
      expect(repository.lastIdType, 'passport');
    });

    testWidgets('the start page says the name is checked before Start', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: '',
        ),
      );

      expect(_lines(NameCheckCopy.beforeSending), findsOneWidget);
      expect(find.byKey(const Key('verification-check-name')), findsOneWidget);
      // Ahead of the photos, so the name is fixed before they are picked.
      expect(
        tester.getTopLeft(_lines(NameCheckCopy.beforeSending)).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('verification-id-front'))).dy,
        ),
      );
    });

    testWidgets('a pending request sends nothing, so it says nothing', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.manualReview,
          rawState: 'pending',
        ),
      );

      expect(find.text('Pending review'), findsOneWidget);
      expect(_lines(NameCheckCopy.beforeSending), findsNothing);
    });

    testWidgets('the pending page follows the review time app config sends', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.manualReview,
          rawState: 'pending',
        ),
      );
      AppBootstrap sending(VerificationReviewTime reviewTime) => AppBootstrap(
        service: '',
        apiVersion: '',
        timezone: 'Asia/Manila',
        channel: 'citizen-mobile',
        defaultPageSize: 25,
        minimumVersion: '',
        features: FeatureFlags.none,
        support: SupportContact.none,
        verificationReviewTime: reviewTime,
      );
      const String lead =
          'Taytay LGU staff are checking your valid ID and selfie.';

      // Nothing sent yet: the copy this build shipped with (D-200).
      expect(
        find.text(
          '$lead This usually takes 1–3 working days. No action needed.',
        ),
        findsOneWidget,
      );

      dependencies.platform.replaceBootstrapForTesting(
        sending(const ReviewTimeStated(2, 4)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          '$lead This usually takes 2–4 working days. No action needed.',
        ),
        findsOneWidget,
      );

      dependencies.platform.replaceBootstrapForTesting(
        sending(VerificationReviewTime.notStated),
      );
      await tester.pumpAndSettle();
      expect(find.text('$lead No action needed.'), findsOneWidget);
      expect(find.textContaining('working day'), findsNothing);
      expect(find.text('Pending review'), findsOneWidget);
    });

    testWidgets('a verified stage raises the session without a restart', (
      tester,
    ) async {
      final dependencies = await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.verified,
          rawState: 'approved',
        ),
      );

      expect(find.text('Your account is verified'), findsOneWidget);
      expect(dependencies.session.accessLevel, AccessLevel.verified);
      expect(dependencies.session.toString(), isNot(contains('Juana')));
    });
  });

  test('a field note does not print its text', () {
    const note = FieldCorrectionNote(
      label: 'Address',
      note: '12 Sample Street',
    );
    expect(note.toString(), 'FieldCorrectionNote');
    expect(note.toString(), isNot(contains('Sample')));
  });

  group('the selfie consent on the verification screen (D-209, D-210)', () {
    const VerificationStatusDetail notStarted = VerificationStatusDetail(
      stage: ResidentVerificationStage.notStarted,
      rawState: '',
    );

    /// Presses the selfie slot as the resident does. The slot can sit under
    /// the page's fixed footer, so its own handler is called; a slot the
    /// screen switched off has none.
    Future<void> tapSelfie(WidgetTester tester) async {
      final Finder slot = find.byKey(const Key('verification-selfie'));
      await tester.ensureVisible(slot);
      await tester.pumpAndSettle();
      tester.widget<S3Field>(slot).onTap?.call();
      await tester.pumpAndSettle();
    }

    PrimaryButton start(WidgetTester tester) => tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Start verification'),
    );

    testWidgets('owed: the consent opens before the camera, then the photo', (
      tester,
    ) async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      );
      await bootVerification(
        tester,
        detail: notStarted,
        picker: _ReadyPicker(),
        consents: consents,
      );
      await tester.ensureVisible(
        find.byKey(const Key('verification-id-front')),
      );
      await tester.tap(find.byKey(const Key('verification-id-front')));
      await tester.pumpAndSettle();

      await tapSelfie(tester);
      expect(find.text(BiometricConsentCopy.dialogTitle), findsOneWidget);
      expect(start(tester).onPressed, isNull);
      await tester.ensureVisible(find.byKey(biometricConsentTickKey));
      await tester.tap(find.byKey(biometricConsentTickKey));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(biometricConsentAgreeKey));
      await tester.tap(find.byKey(biometricConsentAgreeKey));
      await tester.pumpAndSettle();

      expect(consents.accepted.single.kind, ConsentKind.biometric);
      expect(find.text(BiometricConsentCopy.dialogTitle), findsNothing);
      expect(start(tester).onPressed, isNotNull);
    });

    testWidgets('declined: no photo, and the in-person way is said', (
      tester,
    ) async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      );
      await bootVerification(
        tester,
        detail: notStarted,
        picker: _ReadyPicker(),
        consents: consents,
      );
      await tapSelfie(tester);
      await tester.ensureVisible(find.byKey(biometricConsentDeclineKey));
      await tester.tap(find.byKey(biometricConsentDeclineKey));
      await tester.pumpAndSettle();

      expect(consents.accepted, isEmpty);
      expect(find.text('Take a selfie'), findsOneWidget);
      expect(find.text(BiometricConsentCopy.declinedHeading), findsOneWidget);
      expect(find.byKey(inPersonVerificationNoteKey), findsOneWidget);
      expect(
        find.textContaining('Bring a valid ID to the MSWDO'),
        findsOneWidget,
      );
      // The resident may change their mind: the slot still asks.
      await tapSelfie(tester);
      expect(find.text(BiometricConsentCopy.dialogTitle), findsOneWidget);
    });

    testWidgets('unpublished: no selfie is offered, and in person is', (
      tester,
    ) async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.unpublished,
      );
      await bootVerification(
        tester,
        detail: notStarted,
        picker: _ReadyPicker(),
        platformRepository: BiometricPlatform(published: false),
        consents: consents,
      );
      expect(find.byKey(verificationSelfieUnavailableKey), findsOneWidget);
      expect(
        find.text(BiometricConsentCopy.unavailableHeading),
        findsOneWidget,
      );
      expect(find.byKey(inPersonVerificationNoteKey), findsOneWidget);

      await tapSelfie(tester);
      expect(find.text(BiometricConsentCopy.dialogTitle), findsNothing);
      expect(find.text('Take a selfie'), findsOneWidget);
      expect(start(tester).onPressed, isNull);
      expect(consents.accepted, isEmpty);
    });

    testWidgets('a failed read offers Try again, and no selfie meanwhile', (
      tester,
    ) async {
      final BiometricConsents consents = BiometricConsents()
        ..stateFailure = const NetworkFailure();
      await bootVerification(
        tester,
        detail: notStarted,
        picker: _ReadyPicker(),
        consents: consents,
      );
      expect(find.byKey(verificationConsentFailedKey), findsOneWidget);
      await tapSelfie(tester);
      expect(find.text('Take a selfie'), findsOneWidget);

      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(verificationConsentFailedKey), findsNothing);
      await tapSelfie(tester);
      expect(find.text('Photo added'), findsWidgets);
    });

    testWidgets('a selfie refused for consent reads the consent again', (
      tester,
    ) async {
      final BiometricConsents consents = BiometricConsents();
      final _RefusingStub repository = _RefusingStub(notStarted);
      await bootVerification(
        tester,
        detail: notStarted,
        picker: _ReadyPicker(),
        consents: consents,
        repository: repository,
      );
      await tester.ensureVisible(
        find.byKey(const Key('verification-id-front')),
      );
      await tester.tap(find.byKey(const Key('verification-id-front')));
      await tester.pumpAndSettle();
      await tapSelfie(tester);
      final int reads = consents.stateReads;
      await tester.ensureVisible(find.text('Start verification'));
      await tester.tap(find.text('Start verification'));
      await tester.pumpAndSettle();
      expect(repository.startCalls, 1);
      expect(consents.stateReads, greaterThan(reads));
      expect(find.textContaining('Nothing was sent'), findsOneWidget);
    });

    testWidgets('pending with an erased selfie says so and takes a new one', (
      tester,
    ) async {
      final DateTime erased = DateTime.utc(2026, 11, 10, 2);
      final dependencies = await bootVerification(
        tester,
        detail: VerificationStatusDetail(
          stage: ResidentVerificationStage.pendingReview,
          rawState: 'pending',
          canEdit: true,
          selfieMediaId: 'media-sample',
          selfieErasedAt: erased,
        ),
        picker: _ReadyPicker(),
      );
      final repository =
          dependencies.verificationRepository as StubVerificationRepository;

      expect(find.byKey(verificationSelfieErasedKey), findsOneWidget);
      expect(
        find.textContaining('Staff cannot approve this request'),
        findsOneWidget,
      );
      expect(find.textContaining(formatManilaDate(erased)), findsOneWidget);
      expect(find.textContaining('No action needed'), findsNothing);

      await tester.ensureVisible(find.byKey(verificationRetakeSelfieKey));
      await tester.tap(find.byKey(verificationRetakeSelfieKey));
      await tester.pumpAndSettle();
      expect(repository.replaceCalls, 1);
    });

    testWidgets('a pending request with its selfie still says no action', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.pendingReview,
          rawState: 'pending',
          canEdit: true,
          selfieMediaId: 'media-sample',
        ),
      );
      expect(find.byKey(verificationSelfieErasedKey), findsNothing);
      expect(find.textContaining('No action needed'), findsOneWidget);
    });

    testWidgets('a rejected request with an erased selfie asks for a new one', (
      tester,
    ) async {
      await bootVerification(
        tester,
        detail: VerificationStatusDetail(
          stage: ResidentVerificationStage.unsuccessful,
          rawState: 'rejected',
          canEdit: true,
          selfieMediaId: 'media-sample',
          selfieErasedAt: DateTime.utc(2026, 11, 10),
        ),
      );
      expect(find.byKey(verificationSelfieErasedKey), findsOneWidget);
      expect(find.text(VerificationSelfieCopy.erasedSlot), findsOneWidget);
      expect(find.text('Previous selfie kept'), findsNothing);
    });

    testWidgets('each page with its selfie note fits every phone at 200%', (
      tester,
    ) async {
      final Widget notes = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SoftNote(
            tone: NoteTone.warning,
            heading: BiometricConsentCopy.unavailableHeading,
            message: BiometricConsentCopy.unavailable,
          ),
          const InPersonVerificationNote(
            office: MunicipalOffice(
              id: 'o',
              name: 'Synthetic Social Welfare Office',
              slug: 'mswdo',
              description: '',
              head: '',
              hours: 'Mon–Fri, sample hours',
              phone: '0900-000-0002',
              email: '',
              address: 'Sample Street, Sample Barangay, Taytay',
              category: 'social',
            ),
          ),
          SoftNote(
            tone: NoteTone.warning,
            heading: VerificationSelfieCopy.erasedHeading,
            message: VerificationSelfieCopy.erasedPending(' on 10 Nov 2026'),
          ),
        ],
      );
      for (final Widget Function() build in <Widget Function()>[
        () => UnverifiedStatusPage(onStart: () {}, below: notes),
        () => PendingStatusPage(selfieNotice: notes),
        () => NeedsCorrectionPage(
          selfieNotice: notes,
          selfieKept: false,
          selfieValue: VerificationSelfieCopy.erasedSlot,
        ),
      ]) {
        await expectCleanLayouts(tester, build, scrollable: false, height: 900);
      }
    });
  });

  test('locale files still carry the older stage copy', () {
    expect(AppLocales.english.languageCode, 'en');
  });
}

/// The name-check statement. The redesign draws it as one plain [Text]
/// (it was split line by line by the retired S3Lines).
Finder _lines(String text) => find.text(text);

/// Refuses the start for want of the selfie consent, as the server does.
class _RefusingStub extends StubVerificationRepository {
  _RefusingStub(super.detail);

  @override
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required VerificationImagePart front,
    VerificationImagePart? back,
    required VerificationImagePart selfie,
    String? idempotencyKey,
  }) async {
    startCalls++;
    return const Err<VerificationStatus>(
      ForbiddenFailure(requiresBiometricConsent: true),
    );
  }
}
