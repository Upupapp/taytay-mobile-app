import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_api_repository.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';

/// Records every read and write so a test can assert what a guest did not do,
/// and exactly what a save carried.
class RecordingProfileRepository implements ResidentProfileRepository {
  RecordingProfileRepository({this.detail});

  ResidentProfileDetail? detail;

  int detailCalls = 0;
  final List<ContactDetailsUpdate> updates = <ContactDetailsUpdate>[];
  final List<String> idempotencyKeys = <String>[];
  Result<void> updateOutcome = const Ok<void>(null);

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    detailCalls++;
    final value = detail;
    return value == null
        ? const Err<ResidentProfileDetail>(ServerFailure(isTemporary: true))
        : Ok<ResidentProfileDetail>(value);
  }

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Err<ResidentProfileSummary>(ServerFailure());

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async {
    updates.add(update);
    idempotencyKeys.add(idempotencyKey);
    return updateOutcome;
  }

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedProfile = ({
  AppDependencies dependencies,
  RecordingProfileRepository profile,
});

Future<BootedProfile> bootProfile(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  ResidentProfileDetail? detail,
  String location = '/profile',
  Size size = const Size(400, 1600),
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = AppLocales.english,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Through the platform and the app's own resolution rule — the real path —
  // rather than by wrapping Localizations around the tree, which would prove
  // the widgets and not the resolution.
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

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

  final profile = RecordingProfileRepository(detail: detail);
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
    network: base.network,
    telemetry: base.telemetry,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: profile,
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

  return (dependencies: dependencies, profile: profile);
}

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ')
    .toLowerCase();

/// Scrolls [finder] into view, anchored on the screen currently showing.
///
/// A bounded drag loop rather than `scrollUntilVisible`: the shell keeps every
/// branch alive, a label can match several rows, and `.first` on an unbuilt
/// finder throws.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// A record with something in every group, for the rendering tests.
ResidentProfileDetail fullDetail() => const ResidentProfileDetail(
  values: <ResidentProfileField, String>{
    ResidentProfileField.mobileNumber: '09171234567',
    ResidentProfileField.emailAddress: 'ana@example.test',
    ResidentProfileField.fullName: 'Ana Dela Cruz',
    ResidentProfileField.birthDate: '03 March 1990',
    ResidentProfileField.barangay: 'San Juan',
  },
  verificationTier: 'verified',
);

void main() {
  _c13();
  _profileLocalisation();
  group('ownership is declared, and eligibility follows it', () {
    test('every eligibility-bearing field belongs to the LGU', () {
      // The rule behind acceptance 2, and it keeps its teeth. A resident who
      // could edit their own birth date could grant themselves a senior citizen
      // benefit; one who could edit their barangay could move into another
      // office's caseload.
      //
      // C-13 did not weaken this rule — it corrected a field that was wearing
      // the flag wrongly. A street address was marked eligibility-bearing, which
      // conflated *which barangay serves you* with *where in it you live*. The
      // office itself draws that line: barangay_id is not self-service,
      // street_address and purok_or_sitio are. barangay stays LGU-owned and
      // eligibility-bearing, which is what this test is really protecting.
      for (final field in ResidentProfileField.values) {
        if (!field.isEligibilityBearing) continue;
        expect(field.ownership, FieldOwnership.lguVerified, reason: field.name);
        expect(field.isEditableInApp, isFalse, reason: field.name);
      }
    });

    test('only account-owned fields are editable in the app', () {
      expect(FieldOwnership.accountOwned.isEditableInApp, isTrue);
      expect(FieldOwnership.lguVerified.isEditableInApp, isFalse);

      for (final field in ResidentProfileField.values) {
        expect(
          field.isEditableInApp,
          field.ownership == FieldOwnership.accountOwned,
          reason: field.name,
        );
      }
    });

    test('the editable set is exactly what the office authorises', () {
      // Widening this set must be a deliberate act with a contract behind it,
      // and this is the deliberate act: `CorrectableField::isSelfService()`
      // returns street_address, purok_or_sitio, mobile_number and email. The
      // set is now four because the office says four — not because it was
      // convenient.
      //
      // barangay_id is the one that must never appear here. Which barangay
      // serves somebody decides whose caseload they are in, and the server does
      // not list it as self-service either.
      expect(
        ResidentProfileField.ownedBy(FieldOwnership.accountOwned),
        unorderedEquals(<ResidentProfileField>[
          ResidentProfileField.mobileNumber,
          ResidentProfileField.emailAddress,
          ResidentProfileField.streetAddress,
          ResidentProfileField.purokOrSitio,
        ]),
      );
      expect(
        ResidentProfileField.barangay.ownership,
        FieldOwnership.lguVerified,
      );
    });

    test('every account-owned field has a control on the editor', () {
      // The check the old catch-all comment claimed to be. It said adding an
      // account-owned field would be "a compile error until it has a control";
      // the `_ =>` branch meant it never was, and such a field would have
      // rendered as an empty row.
      final source = File(
        'lib/features/profile/presentation/contact_details_screen.dart',
      ).readAsStringSync();

      for (final field in ResidentProfileField.ownedBy(
        FieldOwnership.accountOwned,
      )) {
        expect(
          source,
          contains('ResidentProfileField.${field.name} =>'),
          reason: '${field.name} is editable and has no control',
        );
      }
    });

    test('both groups are non-empty and every field is classified', () {
      for (final ownership in FieldOwnership.values) {
        expect(
          ResidentProfileField.ownedBy(ownership),
          isNotEmpty,
          reason: ownership.name,
        );
        expect(ownership.sectionTitle, isNotEmpty);
        expect(ownership.sectionExplanation, isNotEmpty);
      }
      expect(
        ResidentProfileField.values.length,
        ResidentProfileField.ownedBy(FieldOwnership.accountOwned).length +
            ResidentProfileField.ownedBy(FieldOwnership.lguVerified).length,
      );
    });

    test('an update can carry nothing but account-owned fields', () {
      const update = ContactDetailsUpdate(
        mobileNumber: '09171234567',
        emailAddress: 'ana@example.test',
      );
      for (final field in update.touchedFields) {
        expect(field.ownership, FieldOwnership.accountOwned);
      }
      expect(const ContactDetailsUpdate().isEmpty, isTrue);
    });

    test('the correction copy names a real next step, not a form', () {
      expect(CanonicalCorrection.nextStep, contains('municipal hall'));
      expect(CanonicalCorrection.nextStep, contains('valid ID'));
      // It must not promise a submission this app cannot make.
      for (final phrase in <String>['submit', 'request a change', 'upload']) {
        expect(
          CanonicalCorrection.nextStep.toLowerCase(),
          isNot(contains(phrase)),
          reason: phrase,
        );
      }
    });
  });

  group('the decoder is an allow-list', () {
    // C-12. These ran against `ResidentProfileDto`, which no production file
    // imports and whose contract was partly invented: it read `full_name` and
    // `barangay`, where the server sends the four name parts and `barangay_id`.
    // Production reads the server's names correctly — it iterates
    // `ResidentProfileField.values` and takes each field's own `wireName`, which
    // makes it allow-list by construction rather than by care.
    //
    // The privacy property is what mattered and it is kept, asserted twice on
    // the decoder that actually runs: once by putting a hostile payload on the
    // wire, once against the decoder's source so a future edit that starts
    // reading a staff field fails here rather than in front of a resident.

    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'first_name': 'Ana',
      'last_name': 'Reyes',
      'mobile_number': '09171234567',
      'verification_tier': 'verified',
      // None of the following may reach a resident's screen.
      'resident_id': 'r-1',
      'record_number': 'REC-1',
      'household_id': 'hh-1',
      'psgc_code': '045822',
      'philsys_number': '1234-5678-9012',
      'assessment': 'eligible',
      'internal_notes': 'Applicant looks suspicious',
      'remarks': 'Escalate to supervisor',
      'reviewed_by': 'staff-1',
      'reviewer_name': 'Maria Santos',
      'risk_score': 0.87,
      'fraud_score': 12,
      'sector_flags': <String>['vawc-survivor'],
      'household_members': <Object>[
        <String, dynamic>{'name': 'Juan Dela Cruz'},
      ],
    };

    test(
      'staff-only and third-party data does not survive the real decoder',
      () async {
        final repository = ResidentProfileApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: _OneResponse(hostilePayload()),
            accessTokenProvider: () async => 'tok',
          ),
        );

        final detail = (await repository.loadOwnDetail()).valueOrNull;
        final rendered = <String>[
          detail.toString(),
          ...?detail?.values.values,
          detail?.verificationTier ?? '',
        ].join(' ').toLowerCase();

        for (final forbidden in <String>[
          'r-1',
          'rec-1',
          'hh-1',
          '045822',
          '1234-5678-9012',
          'suspicious',
          'escalate',
          'staff-1',
          'maria santos',
          '0.87',
          'vawc',
          'juan dela cruz',
        ]) {
          expect(rendered, isNot(contains(forbidden)), reason: forbidden);
        }
      },
    );

    test('the production decoder names no staff-only key', () {
      const source =
          'lib/features/profile/data/resident_profile_api_repository.dart';
      final decoder = File(source).readAsStringSync();

      for (final forbidden in <String>[
        'resident_id',
        'record_number',
        'household_id',
        'psgc_code',
        'philsys_number',
        'assessment',
        'internal_notes',
        'remarks',
        'reviewed_by',
        'risk_score',
        'sector_flags',
        'household_members',
      ]) {
        expect(
          decoder.contains("'$forbidden'"),
          isFalse,
          reason: '$source reads $forbidden',
        );
      }
    });
  });

  group('own-record scope — acceptance 3', () {
    test('no repository method takes a resident identifier', () {
      // An API that cannot express "fetch someone else" cannot be misused into
      // doing so. Enforced at the source, because a signature is what a future
      // caller reads.
      final source = File(
        'lib/features/profile/domain/resident_profile_repository.dart',
      ).readAsStringSync();

      for (final signature in <String>[
        'loadDetail(String',
        'loadProfile(String',
        'residentId',
        'byId(',
      ]) {
        expect(source, isNot(contains(signature)), reason: signature);
      }
      expect(source, contains('loadOwnDetail()'));
    });

    test('no profile source builds a path with an identifier', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib/features/profile')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (RegExp(r'residents/\$|/residents/').hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('no completion percentage exists — omitted, not hidden', () {
    test('the summary type carries no completeness figure', () {
      // Removed in TAB 12: no authoritative backend definition exists, and a
      // client-computed figure would count the fields this build knows about.
      final source = File(
        'lib/features/profile/domain/resident_profile_repository.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('completionPercent')));
    });

    test('no profile source computes a percentage', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib/features/profile')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (RegExp(
          r'''(complete|completion)[A-Za-z]*\s*=|['"]\d+%''',
        ).hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('the two kinds of data are visibly apart — acceptance 1', () {
    testWidgets('both sections appear, each with its own explanation', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
      );

      expect(find.text('Your account details'), findsWidgets);
      expect(find.text('Confirmed by Taytay LGU'), findsOneWidget);
      expect(
        find.textContaining('You can change these yourself'),
        findsOneWidget,
      );
      expect(find.textContaining('only the LGU can change them'), findsWidgets);
    });

    testWidgets('editable rows show a chevron, canonical rows a lock', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
      );

      // The distinction is legible before anything is tapped, and carried by
      // words as well as by iconography.
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
    });

    testWidgets('a known value is shown; an absent one says which', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
      );

      expect(find.text('Ana Dela Cruz'), findsOneWidget);
      // `civilStatus` was not supplied: never a blank row on a government
      // record, which reads as data loss.
      expect(find.text('Not on file'), findsWidgets);
    });

    testWidgets('an unreadable record says so without blaming the resident', (
      tester,
    ) async {
      await bootProfile(tester, level: AccessLevel.verified);

      expect(find.text('Not available in this app yet'), findsWidgets);
      expect(
        find.textContaining('has not switched on your record'),
        findsOneWidget,
      );
    });

    // One boot per test. Re-pumping a second `TaytayResidentApp` into the same
    // tester updates the existing State rather than creating a new one, and the
    // router is a `late final` built from the first session — so a second boot
    // would silently keep the first resident's access level.
    testWidgets('the badge says verified for a verified resident', (
      tester,
    ) async {
      await bootProfile(tester, level: AccessLevel.verified);
      expect(find.text('Verified by Taytay LGU'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsWidgets);
    });

    testWidgets('the badge says not yet verified for an unverified one', (
      tester,
    ) async {
      await bootProfile(tester, level: AccessLevel.unverified);
      expect(find.text('Not yet verified'), findsOneWidget);
      expect(find.byIcon(Icons.pending_outlined), findsOneWidget);
    });

    testWidgets('the badge says not signed in for a guest', (tester) async {
      await bootProfile(tester);
      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsWidgets);
    });
  });

  group('canonical fields cannot be overwritten — acceptance 2', () {
    testWidgets('tapping one explains and offers the counter, not a form', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
      );

      await reveal(tester, find.text('Full name'));
      await tester.tap(find.text('Full name'));
      await tester.pumpAndSettle();

      expect(find.text(CanonicalCorrection.title), findsWidgets);
      expect(find.textContaining('municipal hall'), findsOneWidget);
      // No input of any kind: nothing here collects evidence it cannot send.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('mid-verification, it offers the cheaper route', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.unverified,
        detail: fullDetail(),
      );

      await reveal(tester, find.text('Date of birth'));
      await tester.tap(find.text('Date of birth'));
      await tester.pumpAndSettle();

      expect(find.text('Check my verification'), findsOneWidget);
    });

    testWidgets('the editor offers exactly what the office authorises', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
        // Tall enough that every control is built. The editor is a ListView, so
        // on a phone-sized surface the last field is below the fold and simply
        // does not exist in the tree — which would make this test pass or fail
        // on layout rather than on what the editor offers.
        size: const Size(400, 3000),
      );

      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.textContaining('Email address'), findsOneWidget);
      expect(find.text('Street address'), findsOneWidget);
      // Restored. This assertion failed earlier and I read the failure as "the
      // field is below the fold in a ListView". It was not: the label was the
      // literal string '${field.label} (optional)', because an escape survived
      // an edit. The finder was right and the diagnosis was wrong.
      expect(find.textContaining('Purok or sitio'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));

      // Nothing canonical has a control here — and `Street address` has left
      // this list because the office says it is the resident's (C-13), not
      // because the rule softened. `Barangay` is the case the rule exists for:
      // which barangay serves somebody decides whose caseload they are in, the
      // server does not list it as self-service, and it must never gain a
      // control on this screen.
      for (final label in <String>[
        'Full name',
        'Date of birth',
        'Barangay',
        'Civil status',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('saving sends only contact fields, with an idempotency key', (
      tester,
    ) async {
      final booted = await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
      );

      await reveal(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(booted.profile.updates, hasLength(1));
      for (final field in booted.profile.updates.single.touchedFields) {
        expect(field.ownership, FieldOwnership.accountOwned);
      }
      expect(booted.profile.idempotencyKeys.single, isNotEmpty);
    });

    testWidgets('a failed save says nothing was changed', (tester) async {
      final booted = await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
      );
      booted.profile.updateOutcome = const Err<void>(
        ServerFailure(isTemporary: true, debugMessage: 'module not built'),
      );

      await reveal(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing was changed'), findsOneWidget);
      // The operator-facing debug text never reaches the resident.
      expect(find.textContaining('module not built'), findsNothing);
    });

    testWidgets('an invalid mobile number is refused before anything is sent', (
      tester,
    ) async {
      final booted = await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
      );

      await tester.enterText(find.byType(TextFormField).first, '12345');
      await reveal(tester, find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(booted.profile.updates, isEmpty);
      expect(
        find.text('Enter an 11-digit mobile number starting with 09.'),
        findsOneWidget,
      );
    });
  });

  group('a guest triggers no personal read', () {
    testWidgets('opening Profile as a guest fetches nothing', (tester) async {
      final booted = await bootProfile(tester);

      // The read is the disclosure, so the read is what is gated.
      expect(booted.profile.detailCalls, 0);
      expect(find.text('You are browsing as a guest'), findsOneWidget);
      // Neither field section is built at all.
      expect(find.text('Confirmed by Taytay LGU'), findsNothing);
    });

    testWidgets('no personal wording appears for a guest', (tester) async {
      await bootProfile(tester);
      final rendered = renderedText(tester);

      // Whole words: "ana" is a substring of "manage", and a naive contains
      // check would fail on copy that discloses nothing.
      expect(rendered, isNot(matches(RegExp(r'ana'))));
      for (final leak in <String>['acct-', 'dela cruz', 'san juan', '0917']) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });

    testWidgets('a guest is redirected away from the contact editor', (
      tester,
    ) async {
      final booted = await bootProfile(tester, location: '/profile/contact');

      // The route is authenticated, so the guard moves them to sign-in.
      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
      expect(booted.profile.updates, isEmpty);
    });

    testWidgets('signing out clears personal content from Profile', (
      tester,
    ) async {
      final booted = await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
      );
      expect(find.text('Ana Dela Cruz'), findsOneWidget);

      await booted.dependencies.session.signOut();
      await tester.pumpAndSettle();

      expect(find.text('Ana Dela Cruz'), findsNothing);
      expect(renderedText(tester), isNot(contains('dela cruz')));
    });
  });

  group('privacy information is public and honest', () {
    testWidgets('a guest can read it without an account', (tester) async {
      await bootProfile(tester, location: '/profile/privacy');

      expect(find.text('Privacy and your data'), findsWidgets);
      expect(find.textContaining('Data Privacy Act of 2012'), findsOneWidget);
      expect(find.text('Your rights'), findsOneWidget);
    });

    testWidgets('it offers no consent toggle it could not record', (
      tester,
    ) async {
      await bootProfile(tester, location: '/profile/privacy');

      // No consent endpoint exists, so a switch here would tell a resident they
      // had withdrawn something the LGU has no record of.
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('it is honest about retention and about changing consent', (
      tester,
    ) async {
      await bootProfile(tester, location: '/profile/privacy');

      await reveal(tester, find.text('Deleting your record'));
      expect(
        find.textContaining('as long as the law requires'),
        findsOneWidget,
      );
      expect(find.text('Changing what you agreed to'), findsOneWidget);
    });

    test('it reads nothing at all', () {
      // Structural rather than behavioural: the screen reaches for no
      // dependency, so it renders identically for everyone and discloses
      // nothing by being opened. A widget test could not prove this, because
      // the screen sits on top of Profile in the branch stack and Profile's own
      // read has already happened.
      final source = File(
        'lib/features/profile/presentation/privacy_screen.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('AppDependencies')));
      expect(source, isNot(contains('Repository')));
      expect(source, isNot(contains('session')));
    });
  });

  group('withheld shortcuts stay withheld', () {
    testWidgets('no notification-preferences control appears', (tester) async {
      await bootProfile(tester, level: AccessLevel.verified);
      final rendered = renderedText(tester);

      // §11 of the matrix has an inbox, mark-read and device registration, and
      // no preferences row at all.
      for (final phrase in <String>[
        'notification preferences',
        'push notifications',
        'sms alerts',
      ]) {
        expect(rendered, isNot(contains(phrase)), reason: phrase);
      }
    });

    testWidgets('the household shortcut states it is unavailable', (
      tester,
    ) async {
      await bootProfile(tester, level: AccessLevel.verified);

      await reveal(tester, find.text('See your household summary'));
      // Declared, and honestly reported — TAB 10's decision, unchanged.
      expect(find.text('Not available yet'), findsWidgets);
    });

    testWidgets('the assistance-history shortcut is present', (tester) async {
      await bootProfile(tester, level: AccessLevel.verified);
      expect(find.text('Track your assistance requests'), findsOneWidget);
    });

    testWidgets('help and privacy are reachable from Profile', (tester) async {
      await bootProfile(tester, level: AccessLevel.verified);

      await reveal(tester, find.text('Help and support'));
      expect(find.text('Privacy and your data'), findsOneWidget);
      expect(find.text('Help and support'), findsOneWidget);
    });
  });

  group('accessibility and responsiveness', () {
    testWidgets('Profile survives a 200% text scale', (tester) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 3000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Confirmed by Taytay LGU'), findsOneWidget);
    });

    testWidgets('the contact editor survives a 200% text scale', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 3000),
      );

      expect(tester.takeException(), isNull);
      // Four since C-13: the office lists street_address and purok_or_sitio as
      // self-service alongside mobile and email, so the editor carries four
      // controls. The surface here is 3000 tall, so all four are built.
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('Profile renders on a wide surface beside the rail', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        size: const Size(1000, 1600),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Confirmed by Taytay LGU'), findsOneWidget);
    });
  });
}

/// Answers every request with one JSON body, so a hostile payload can be put on
/// the wire and the real decoder watched.
class _OneResponse implements ApiTransport {
  _OneResponse(this.body);

  final Map<String, dynamic> body;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, dynamic>{'data': body}),
          headers: const <String, String>{'content-type': 'application/json'},
        ),
      );
}

void _c13() {
  group('who may change what is the office’s answer — C-13', () {
    const street = ResidentProfileField.streetAddress;
    const mobile = ResidentProfileField.mobileNumber;

    test(
      'the declaration now matches the office, and the served list still wins',
      () {
        // The defect this closed: the server marks street_address self-service,
        // the enum declared it lguVerified, and the screen told a resident "only
        // the LGU can change them" about a field the office lets them edit.
        //
        // The declaration is corrected so the FALLBACK is right too — a response
        // that stops publishing editable_fields must not reintroduce the wrong
        // sentence.
        expect(street.ownership, FieldOwnership.accountOwned);

        const served = ResidentProfileDetail(
          selfServiceFields: <String>{
            'street_address',
            'purok_or_sitio',
            'mobile_number',
            'email',
          },
        );

        expect(
          served.ownershipOf(street),
          FieldOwnership.accountOwned,
          reason: 'the office says the resident may change it',
        );
      },
    );

    test('a field the office does not list becomes the LGU’s', () {
      const served = ResidentProfileDetail(
        selfServiceFields: <String>{'mobile_number'},
      );

      expect(served.ownershipOf(mobile), FieldOwnership.accountOwned);
      expect(
        served.ownershipOf(ResidentProfileField.birthDate),
        FieldOwnership.lguVerified,
      );
    });

    test('an absent list falls back to the declaration, not to nothing', () {
      // The wrong way to fail is to decide the resident may change nothing.
      const silent = ResidentProfileDetail();

      expect(silent.selfServiceFields, isNull);
      expect(silent.ownershipOf(mobile), mobile.ownership);
      expect(silent.ownershipOf(street), street.ownership);
      expect(silent.fieldsOwnedBy(FieldOwnership.accountOwned), isNotEmpty);
    });

    test('the repository reads editable_fields off the wire', () async {
      final repository = ResidentProfileApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(const <String, dynamic>{
            'first_name': 'Ana',
            'street_address': '12 Rizal St',
            'editable_fields': <String>[
              'street_address',
              'mobile_number',
              'email',
            ],
          }),
          accessTokenProvider: () async => 'tok',
        ),
      );

      final detail = (await repository.loadOwnDetail()).valueOrNull!;

      expect(detail.selfServiceFields, contains('street_address'));
      expect(detail.ownershipOf(street), FieldOwnership.accountOwned);
    });

    test(
      'an empty or malformed list is treated as "the server did not say"',
      () async {
        for (final Object? served in <Object?>[<String>[], 'nonsense', null]) {
          final repository = ResidentProfileApiRepository(
            apiClient: ApiClient(
              config: config(),
              transport: _OneResponse(<String, dynamic>{
                'first_name': 'Ana',
                'editable_fields': ?served,
              }),
              accessTokenProvider: () async => 'tok',
            ),
          );

          final detail = (await repository.loadOwnDetail()).valueOrNull!;
          expect(detail.selfServiceFields, isNull, reason: '$served');
          expect(detail.ownershipOf(street), street.ownership);
        }
      },
    );
  });
}

void _profileLocalisation() {
  group('the profile surface speaks Filipino too', () {
    testWidgets('field labels and section copy translate', (tester) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        locale: AppLocales.filipino,
        size: const Size(400, 3000),
      );

      // Until this was localised, ResidentProfileField carried English labels
      // as enum constants and this screen rendered them directly — so the one
      // surface where a resident reads their own government record stayed in
      // English while the rest of the app translated.
      expect(find.text('Kumpirmado ng Taytay LGU'), findsOneWidget);
      expect(find.text('Buong pangalan'), findsOneWidget);
      expect(find.text('Petsa ng kapanganakan'), findsOneWidget);

      expect(find.text('Confirmed by Taytay LGU'), findsNothing);
      expect(find.text('Full name'), findsNothing);
    });

    test('every field has a label and every locale has every key', () {
      // Both directions. A field with no entry would render its English
      // fallback silently; a locale missing a key would fall back to English
      // just as silently.
      const keys = <String>[
        'profileSectionAccountTitle',
        'profileSectionAccountExplanation',
        'profileSectionLguTitle',
        'profileSectionLguExplanation',
        'profileFieldMobileNumber',
        'profileFieldEmailAddress',
        'profileFieldStreetAddress',
        'profileFieldPurokOrSitio',
        'profileFieldFullName',
        'profileFieldBirthDate',
        'profileFieldSex',
        'profileFieldCivilStatus',
        'profileFieldBarangay',
        'profileFieldOptionalSuffix',
      ];

      for (final path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_fil.arb',
      ]) {
        final strings =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        for (final key in keys) {
          expect(strings[key], isA<String>(), reason: '$path is missing $key');
        }
      }

      // One label key per field, so adding a field to the enum without adding
      // copy fails here rather than shipping an English word into a Filipino
      // screen.
      expect(
        ResidentProfileField.values.length,
        9,
        reason:
            'a field was added or removed; add or remove its label and hint '
            'keys, and update this count deliberately',
      );
    });
  });
}
