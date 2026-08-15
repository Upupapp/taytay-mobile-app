import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/profile/data/planned_resident_profile_repository.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_dto.dart';
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
  group('ownership is declared, and eligibility follows it', () {
    test('every eligibility-bearing field belongs to the LGU', () {
      // The rule behind acceptance 2. A resident who could edit their own birth
      // date could grant themselves a senior citizen benefit; one who could edit
      // their barangay could move into another office's caseload.
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

    test('the editable set is exactly what the contract authorises', () {
      // `PATCH /api/v1/me/profile` is "contact fields only". Widening this set
      // must be a deliberate act with a contract behind it.
      expect(
        ResidentProfileField.ownedBy(FieldOwnership.accountOwned),
        unorderedEquals(<ResidentProfileField>[
          ResidentProfileField.mobileNumber,
          ResidentProfileField.emailAddress,
        ]),
      );
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
    /// A payload carrying everything a resident must never receive.
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'full_name': 'Ana Dela Cruz',
      'barangay': 'San Juan',
      'verification_tier': 'verified',
      // None of the following may survive.
      'resident_id': 'r-99',
      'record_number': 'REC-0001',
      'household_id': 'hh-7',
      'psgc_code': '045822000',
      'philsys_number': '1234-5678-9012',
      'assessment': 'Eligible for AICS',
      'internal_notes': 'Applicant seems suspicious',
      'remarks': 'Escalate',
      'reviewed_by': 'staff-1',
      'reviewer_name': 'Maria Santos',
      'risk_score': 0.9,
      'fraud_score': 12,
      'sector_flags': <String>['solo_parent'],
      'household_members': <Object>[
        <String, dynamic>{'name': 'Juan Dela Cruz', 'age': 12},
      ],
      'relatives': <String>['Juan Dela Cruz'],
      'dependents': 3,
      'audit_trail': <Object>[
        <String, dynamic>{'actor_name': 'Maria Santos'},
      ],
      'created_by': 'staff-1',
      'deactivation_reason': 'duplicate',
    };

    test('nothing staff, registry, audit or third-party survives', () {
      final decoded = ResidentProfileDto.decode(hostilePayload());
      final rendered = decoded.values.values.join(' ').toLowerCase();

      for (final leak in <String>[
        'r-99',
        'rec-0001',
        'hh-7',
        '045822000',
        '1234-5678-9012',
        'aics',
        'suspicious',
        'escalate',
        'staff-1',
        'maria santos',
        'solo_parent',
        'juan dela cruz',
        'duplicate',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
      // What a resident is entitled to see did survive.
      expect(decoded.valueOf(ResidentProfileField.fullName), 'Ana Dela Cruz');
      expect(decoded.valueOf(ResidentProfileField.barangay), 'San Juan');
      expect(decoded.verificationTier, 'verified');
    });

    test('another resident cannot arrive through an allowed key', () {
      // A nested object under an allowed key is a shape this app never agreed
      // to; flattening it is how a household list becomes an address.
      final decoded = ResidentProfileDto.decode(<String, dynamic>{
        'street_address': <String, dynamic>{'occupant': 'Juan Dela Cruz'},
        'full_name': <String>['Ana', 'Juan'],
      });
      expect(decoded.values, isEmpty);
    });

    test('allowed and forbidden key sets are disjoint', () {
      for (final key in ResidentProfileDto.allowedKeys.keys) {
        expect(
          ResidentProfileDto.forbiddenKeys,
          isNot(contains(key)),
          reason: key,
        );
      }
    });

    test('every allowed key maps to a field this app names', () {
      for (final field in ResidentProfileDto.allowedKeys.values) {
        expect(ResidentProfileField.values, contains(field));
      }
    });

    test('a non-object payload decodes to nothing, never throws', () {
      for (final payload in <Object?>[
        null,
        'x',
        42,
        <int>[1, 2],
      ]) {
        expect(ResidentProfileDto.decode(payload).values, isEmpty);
      }
    });

    test('an encoded update carries only contact keys', () {
      final body = ResidentProfileDto.encodeContactUpdate(
        const ContactDetailsUpdate(
          mobileNumber: '09171234567',
          emailAddress: 'ana@example.test',
        ),
      );
      expect(body.keys, unorderedEquals(<String>['mobile_number', 'email']));

      // Nothing canonical can appear, because nothing can express it.
      for (final key in <String>[
        'full_name',
        'birth_date',
        'barangay',
        'street_address',
        'civil_status',
      ]) {
        expect(body.containsKey(key), isFalse, reason: key);
      }
    });

    test('an empty update sends nothing at all', () {
      expect(
        ResidentProfileDto.encodeContactUpdate(const ContactDetailsUpdate()),
        isEmpty,
      );
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

    test('the shipped repository declines every operation', () {
      const repository = PlannedResidentProfileRepository();
      expect(repository.loadOwnDetail(), completion(isA<Err<dynamic>>()));
      expect(
        repository.updateContactDetails(
          update: const ContactDetailsUpdate(mobileNumber: '09171234567'),
          idempotencyKey: 'k',
        ),
        completion(isA<Err<dynamic>>()),
      );
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

    testWidgets('the editor offers only the two fields the contract allows', (
      tester,
    ) async {
      await bootProfile(
        tester,
        level: AccessLevel.verified,
        detail: fullDetail(),
        location: '/profile/contact',
      );

      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.textContaining('Email address'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Nothing canonical has a control here.
      for (final label in <String>[
        'Full name',
        'Date of birth',
        'Barangay',
        'Street address',
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
      expect(find.byType(TextFormField), findsNWidgets(2));
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
