import 'dart:io';

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
import 'package:taytay_resident/features/household/data/household_dto.dart';
import 'package:taytay_resident/features/household/data/planned_household_repository.dart';
import 'package:taytay_resident/features/household/domain/household_repository.dart';
import 'package:taytay_resident/features/household/domain/household_summary.dart';

/// Records every read and every correction so a test can assert what a guest
/// did not do, and exactly what a report carried.
class RecordingHouseholdRepository implements HouseholdRepository {
  RecordingHouseholdRepository({this.summary});

  HouseholdSummary? summary;

  int loadCalls = 0;
  final List<HouseholdCorrectionRequest> requests =
      <HouseholdCorrectionRequest>[];
  final List<String> idempotencyKeys = <String>[];
  Result<void> submitOutcome = const Ok<void>(null);

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    loadCalls++;
    final value = summary;
    return value == null
        ? const Err<HouseholdSummary>(ServerFailure(isTemporary: true))
        : Ok<HouseholdSummary>(value);
  }

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) async {
    requests.add(request);
    idempotencyKeys.add(idempotencyKey);
    return submitOutcome;
  }
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedHousehold = ({
  AppDependencies dependencies,
  RecordingHouseholdRepository household,
});

Future<BootedHousehold> bootHousehold(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  HouseholdSummary? summary,
  String location = '/household',
  Size size = const Size(400, 1800),
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

  final household = RecordingHouseholdRepository(summary: summary);
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
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: household,
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

  return (dependencies: dependencies, household: household);
}

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ')
    .toLowerCase();

/// Bounded drag loop — the shell keeps every branch alive, a label can match
/// several rows, and `.first` on an unbuilt finder throws.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

HouseholdSummary fullSummary() => const HouseholdSummary(
  role: HouseholdRole.head,
  label: 'Dela Cruz household',
  barangay: 'San Juan',
  streetAddress: '12 Rizal Street',
  memberCount: 4,
);

void main() {
  group('the shape refuses cross-resident data — acceptance 1', () {
    test('there is no member type anywhere in the feature', () {
      // The strongest form of the guarantee: not "we do not render members" but
      // "there is nothing that could hold one". The visibility matrix names
      // `Household.members` among the things a citizen never receives.
      final offenders = <String>[];
      for (final file
          in Directory('lib/features/household')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .where((line) => !line.trimLeft().startsWith('///'))
            .join('\n');
        for (final pattern in <RegExp>[
          RegExp(r'class\s+HouseholdMember'),
          RegExp(r'List<\s*HouseholdMember'),
          RegExp(r'\bmemberNames\b'),
          RegExp(r'\bmembers\s*='),
        ]) {
          if (pattern.hasMatch(source)) offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the summary exposes no identifier and no member list', () {
      final summary = fullSummary();
      // Only an aggregate is shown about the others.
      expect(summary.memberCount, 4);
      // And nothing that could name one, or the household in the registry.
      final source = File(
        'lib/features/household/domain/household_summary.dart',
      ).readAsStringSync();
      for (final field in <String>[
        'householdId',
        'residentId',
        'members',
        'sectors',
        'monthlyIncome',
      ]) {
        expect(source, isNot(contains('this.$field')), reason: field);
      }
    });

    test('a role that is not recognised fails closed to member', () {
      // "Head of household" carries weight at a counter — it is who the office
      // speaks to. Guessing it upward would grant a standing the LGU never gave.
      expect(HouseholdRole.fromRaw('head'), HouseholdRole.head);
      expect(HouseholdRole.fromRaw('household_head'), HouseholdRole.head);
      for (final raw in <String?>[
        null,
        '',
        'HEAD',
        'spouse',
        'guardian',
        'unknown',
      ]) {
        expect(
          HouseholdRole.fromRaw(raw),
          HouseholdRole.member,
          reason: '$raw',
        );
      }
    });

    test('the summary redacts its toString', () {
      final rendered = fullSummary().toString();
      for (final leak in <String>[
        'Dela Cruz',
        'San Juan',
        'Rizal Street',
        '4',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });
  });

  group('the decoder is an allow-list — acceptance 2', () {
    /// Everything a resident must never receive about their household.
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'role': 'head',
      'label': 'Dela Cruz household',
      'barangay': 'San Juan',
      'street_address': '12 Rizal Street',
      'member_count': 4,
      // None of the following may survive.
      // Deliberately chosen not to collide with any legitimate value above:
      // "San Juan" is a real barangay and would make a naive substring check
      // pass for the wrong reason.
      'members': <Object>[
        <String, dynamic>{'name': 'Bayani Magsaysay', 'age': 12},
        <String, dynamic>{
          'name': 'Corazon Bonifacio',
          'sectors': <String>['pwd'],
        },
      ],
      'residents': <String>['Bayani Magsaysay'],
      'relatives': <String>['Emilio Aguinaldo'],
      'dependents': 3,
      'head_name': 'Corazon Bonifacio',
      'sectors': <String>['vawc-survivor', 'cicl', 'indigent'],
      'vulnerability_score': 0.82,
      'risk_score': 12,
      'is_indigent': true,
      'monthly_income': 8000,
      'caseworker_notes': 'Family visited twice',
      'assessment': 'Eligible for AICS',
      'internal_notes': 'Escalate to supervisor',
      'remarks': 'Suspicious',
      'assigned_to': 'staff-1',
      'reviewed_by': 'Maria Santos',
      'assistance_requests': <Object>[
        <String, dynamic>{'id': 'req-9', 'programme': 'AICS'},
      ],
      'disbursements': <Object>[
        <String, dynamic>{'amount': 5000},
      ],
      'referrals': <String>['DSWD'],
      'household_id': 'hh-7',
      'id': 'hh-7',
      'record_number': 'HH-0001',
      'psgc_code': '045822000',
      'audit_trail': <Object>[
        <String, dynamic>{'actor_name': 'Maria Santos'},
      ],
      'created_by': 'staff-1',
      'updated_by': 'staff-2',
      'match_candidates': <String>['hh-8'],
    };

    test('no vulnerability, casework, case or registry data survives', () {
      final decoded = HouseholdDto.decode(hostilePayload());
      final rendered = <String?>[
        decoded.label,
        decoded.barangay,
        decoded.streetAddress,
        decoded.memberCount?.toString(),
        decoded.role.name,
      ].whereType<String>().join(' ').toLowerCase();

      for (final leak in <String>[
        'bayani',
        'magsaysay',
        'corazon',
        'bonifacio',
        'emilio',
        'aguinaldo',
        'pwd',
        'vawc',
        'cicl',
        'indigent',
        '0.82',
        '8000',
        'visited',
        'aics',
        'escalate',
        'suspicious',
        'staff-1',
        'req-9',
        '5000',
        'dswd',
        'hh-7',
        'hh-0001',
        '045822000',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }

      // What a resident is entitled to see did survive.
      expect(decoded.role, HouseholdRole.head);
      expect(decoded.label, 'Dela Cruz household');
      expect(decoded.barangay, 'San Juan');
      expect(decoded.memberCount, 4);
    });

    test('allowed and forbidden key sets are disjoint', () {
      for (final key in HouseholdDto.allowedKeys) {
        expect(HouseholdDto.forbiddenKeys, isNot(contains(key)), reason: key);
      }
    });

    test('the forbidden set names every category the matrix protects', () {
      // Documentation with teeth: the next person to add a field reads this.
      for (final key in <String>[
        'members',
        'sectors',
        'monthly_income',
        'caseworker_notes',
        'assigned_to',
        'assistance_requests',
        'household_id',
        'audit_trail',
      ]) {
        expect(HouseholdDto.forbiddenKeys, contains(key), reason: key);
      }
    });

    test('a nested object under an allowed key is dropped, not flattened', () {
      // How a member list would otherwise arrive rendered as an address.
      final decoded = HouseholdDto.decode(<String, dynamic>{
        'street_address': <String, dynamic>{'occupant': 'Juan Dela Cruz'},
        'barangay': <String>['San Juan', 'Santa Ana'],
        'label': 42,
      });
      expect(decoded.streetAddress, isNull);
      expect(decoded.barangay, isNull);
      expect(decoded.label, isNull);
    });

    test('an implausible member count is refused', () {
      // Rendering a zero or a thousand would tell a resident something false
      // about their own record.
      for (final raw in <Object>[0, -1, 61, 10000, '4', 4.5]) {
        expect(
          HouseholdDto.decode(<String, dynamic>{
            'member_count': raw,
          }).memberCount,
          isNull,
          reason: '$raw',
        );
      }
      expect(
        HouseholdDto.decode(<String, dynamic>{'member_count': 1}).memberCount,
        1,
      );
    });

    test('a non-object payload decodes to a safe default, never throws', () {
      for (final payload in <Object?>[
        null,
        'x',
        7,
        <int>[1],
      ]) {
        final decoded = HouseholdDto.decode(payload);
        expect(decoded.role, HouseholdRole.member);
        expect(decoded.memberCount, isNull);
      }
    });
  });

  group('a correction never rewrites the record — acceptance 3', () {
    test('a request carries a category and nothing else', () {
      final body = HouseholdDto.encodeCorrection(
        const HouseholdCorrectionRequest(
          kind: HouseholdCorrectionKind.addressWrong,
        ),
      );
      expect(body.keys, <String>['kind']);
      expect(body['kind'], 'addressWrong');
    });

    test('no correction category can move a person between households', () {
      // Household composition is a registry decision with consequences for two
      // households at once. No value can express it, so no request can carry it.
      for (final kind in HouseholdCorrectionKind.values) {
        final text = '${kind.name} ${kind.label}'.toLowerCase();
        for (final phrase in <String>[
          'move',
          'transfer',
          'reassign',
          'merge',
          'split',
        ]) {
          expect(text, isNot(contains(phrase)), reason: '${kind.name}/$phrase');
        }
      }
    });

    test('the request type has no target value of any kind', () {
      final source = File(
        'lib/features/household/domain/household_summary.dart',
      ).readAsStringSync();
      final start = source.indexOf('class HouseholdCorrectionRequest');
      final body = source.substring(start);

      // A single field. Anything else would be a value the server could read as
      // "change it to this".
      expect(body, contains('final HouseholdCorrectionKind kind;'));
      for (final field in <String>[
        'newAddress',
        'targetHousehold',
        'residentId',
        'note',
        'evidence',
        'attachment',
      ]) {
        expect(body, isNot(contains(field)), reason: field);
      }
    });

    test('every category has a label and a description', () {
      for (final kind in HouseholdCorrectionKind.values) {
        expect(kind.label, isNotEmpty, reason: kind.name);
        expect(kind.description.length, greaterThan(20), reason: kind.name);
      }
    });

    test('a request is safe to log — it names no person', () {
      const request = HouseholdCorrectionRequest(
        kind: HouseholdCorrectionKind.notMyHousehold,
      );
      expect(request.toString(), contains('notMyHousehold'));
      expect(request.toString(), isNot(contains('acct')));
    });
  });

  group('own-record scope is structural', () {
    test('no repository method takes an identifier', () {
      // Not "takes one and validates it" — takes none. An interface that cannot
      // express "fetch household 42" cannot be talked into registry browsing.
      final source = File(
        'lib/features/household/domain/household_repository.dart',
      ).readAsStringSync();

      for (final signature in <String>[
        'householdId',
        'residentId',
        'loadHousehold(String',
        'byId(',
      ]) {
        expect(source, isNot(contains(signature)), reason: signature);
      }
      expect(source, contains('loadOwnHousehold()'));
    });

    test('no household source builds a registry path', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib/features/household')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .where((line) => !line.trimLeft().startsWith('///'))
            .join('\n');
        if (RegExp(r'/households/|/residents/').hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('neither route carries an identifier', () {
      expect(AppRoute.household.path, '/household');
      expect(AppRoute.householdCorrection.path, '/household/correction');
      expect(AppRoute.household.parameters, isEmpty);
      expect(AppRoute.householdCorrection.parameters, isEmpty);
    });

    test('both routes are verified-only', () {
      expect(AppRoute.household.requirement, AccessRequirement.verified);
      expect(
        AppRoute.householdCorrection.requirement,
        AccessRequirement.verified,
      );
    });

    test('the shipped repository declines both operations', () {
      const repository = PlannedHouseholdRepository();
      expect(repository.loadOwnHousehold(), completion(isA<Err<dynamic>>()));
      expect(
        repository.submitCorrectionRequest(
          request: const HouseholdCorrectionRequest(
            kind: HouseholdCorrectionKind.addressWrong,
          ),
          idempotencyKey: 'k',
        ),
        completion(isA<Err<dynamic>>()),
      );
    });

    test('the capability still reports the backend as absent', () {
      // It has a screen now, but no citizen endpoint exists — so the honest
      // availability answer is unchanged.
      expect(
        ResidentCapability.viewHouseholdSummary.availability,
        BackendAvailability.planned,
      );
      expect(ResidentCapability.viewHouseholdSummary.route, AppRoute.household);
    });
  });

  group('the screen shows only what is authorised', () {
    testWidgets('both summaries render, and no member is named', (
      tester,
    ) async {
      await bootHousehold(tester, summary: fullSummary());

      expect(find.text('Your household'), findsOneWidget);
      expect(find.text('Your family record'), findsOneWidget);
      expect(find.text('San Juan'), findsOneWidget);
      expect(find.text('12 Rizal Street'), findsOneWidget);
      expect(find.text('Household head'), findsOneWidget);
      // The aggregate, and only the aggregate.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('People recorded here'), findsOneWidget);
    });

    testWidgets('it explains why the others are not shown', (tester) async {
      await bootHousehold(tester, summary: fullSummary());

      await reveal(
        tester,
        find.text('Why you cannot see the other people here'),
      );
      expect(find.textContaining('belong to them'), findsOneWidget);
    });

    testWidgets('a member records their own role, not the head\'s', (
      tester,
    ) async {
      await bootHousehold(
        tester,
        summary: const HouseholdSummary(
          role: HouseholdRole.member,
          barangay: 'San Juan',
        ),
      );

      expect(find.text('Household member'), findsOneWidget);
      expect(find.text('Household head'), findsNothing);
    });

    testWidgets('an absent field says which kind of absent it is', (
      tester,
    ) async {
      await bootHousehold(
        tester,
        summary: const HouseholdSummary(role: HouseholdRole.member),
      );

      // Never a blank or a dash on a government record.
      expect(find.text('Not on file'), findsWidgets);
    });

    testWidgets('an unreadable record explains and offers the counter', (
      tester,
    ) async {
      await bootHousehold(tester);

      expect(find.text('Not available in this app yet'), findsOneWidget);
      expect(find.textContaining('municipal hall'), findsWidgets);
      // No fabricated household appears in its place.
      expect(find.text('Your family record'), findsNothing);
    });

    testWidgets('no staff or vulnerability wording appears anywhere', (
      tester,
    ) async {
      await bootHousehold(tester, summary: fullSummary());
      final rendered = renderedText(tester);

      for (final leak in <String>[
        'caseworker',
        'assessment',
        'vulnerab',
        'risk',
        'indigent',
        'income',
        'sector',
        'audit',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });
  });

  group('access is gated centrally', () {
    testWidgets('a guest reads nothing and is sent to sign in', (tester) async {
      final booted = await bootHousehold(tester, level: AccessLevel.guest);

      expect(booted.household.loadCalls, 0);
      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
    });

    testWidgets('an unverified resident reads nothing and is sent to verify', (
      tester,
    ) async {
      final booted = await bootHousehold(tester, level: AccessLevel.unverified);

      expect(booted.household.loadCalls, 0);
      expect(find.text('Identity verification'), findsWidgets);
      expect(find.text('Your household'), findsNothing);
    });

    testWidgets('the correction screen is gated the same way', (tester) async {
      final booted = await bootHousehold(
        tester,
        level: AccessLevel.unverified,
        location: '/household/correction',
      );

      expect(booted.household.requests, isEmpty);
      expect(find.text('What looks wrong?'), findsNothing);
    });
  });

  group('the correction screen', () {
    testWidgets('offers categories and no free-text field', (tester) async {
      await bootHousehold(tester, location: '/household/correction');

      expect(find.text('What looks wrong?'), findsOneWidget);
      // No box a resident could type a relative's medical condition into.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.byType(RadioListTile<HouseholdCorrectionKind>),
        findsNWidgets(HouseholdCorrectionKind.values.length),
      );
    });

    testWidgets('it says plainly that nothing is changed by sending', (
      tester,
    ) async {
      await bootHousehold(tester, location: '/household/correction');

      await reveal(
        tester,
        find.text('Sending this does not change your household record.'),
      );
      expect(
        find.text('Sending this does not change your household record.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Please do not type personal details'),
        findsOneWidget,
      );
    });

    testWidgets('sending is blocked until a category is chosen', (
      tester,
    ) async {
      final booted = await bootHousehold(
        tester,
        location: '/household/correction',
      );

      await reveal(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(booted.household.requests, isEmpty);
    });

    testWidgets('a sent report carries only a category and a key', (
      tester,
    ) async {
      final booted = await bootHousehold(
        tester,
        location: '/household/correction',
      );

      await tester.tap(find.text(HouseholdCorrectionKind.addressWrong.label));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(booted.household.requests, hasLength(1));
      expect(
        booted.household.requests.single.kind,
        HouseholdCorrectionKind.addressWrong,
      );
      expect(booted.household.idempotencyKeys.single, isNotEmpty);
      expect(find.text('Taytay LGU has your report'), findsOneWidget);
      expect(find.textContaining('Nothing has been changed'), findsOneWidget);
    });

    testWidgets('a failed report says nothing was sent or changed', (
      tester,
    ) async {
      final booted = await bootHousehold(
        tester,
        location: '/household/correction',
      );
      booted.household.submitOutcome = const Err<void>(
        ServerFailure(isTemporary: true, debugMessage: 'module not built'),
      );

      await tester.tap(find.text(HouseholdCorrectionKind.roleWrong.label));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing was sent'), findsOneWidget);
      // The operator-facing debug text never reaches the resident.
      expect(find.textContaining('module not built'), findsNothing);
    });

    testWidgets('a sent report cannot be sent twice', (tester) async {
      final booted = await bootHousehold(
        tester,
        location: '/household/correction',
      );

      await tester.tap(find.text(HouseholdCorrectionKind.sizeWrong.label));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      // Two identical corrections is a real cost to the office that has to
      // close one of them.
      expect(booted.household.requests, hasLength(1));
    });
  });

  group('accessibility and responsiveness', () {
    testWidgets('the summary survives a 200% text scale', (tester) async {
      await bootHousehold(
        tester,
        summary: fullSummary(),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 3200),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Your household'), findsOneWidget);
    });

    testWidgets('the correction screen survives a 200% text scale', (
      tester,
    ) async {
      await bootHousehold(
        tester,
        location: '/household/correction',
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 3200),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('What looks wrong?'), findsOneWidget);
    });

    testWidgets('the summary renders on a wide surface', (tester) async {
      await bootHousehold(
        tester,
        summary: fullSummary(),
        size: const Size(1000, 1800),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Your family record'), findsOneWidget);
    });
  });
}
