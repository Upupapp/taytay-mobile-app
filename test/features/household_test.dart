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
import 'package:taytay_resident/features/household/data/household_api_repository.dart';
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
    // C-12. These ran against a DTO no production file imports, and one whose
    // contract was partly invented: it read `label`, `barangay` and `role`, where the server sends
    // `name`, `barangay_id` and `is_head`/`relationship_to_me`. Production reads the server's names correctly.
    //
    // The privacy property is what mattered and it is kept — asserted twice, on
    // the decoder that actually runs: once by putting a hostile payload on the
    // wire and reading what survives, and once against the decoder's source, so
    // a future edit that starts reading a staff field fails here rather than in
    // front of a resident.

    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'code': 'HH-1',
      'street_address': '12 Rizal St',
      'member_count': 4,
      // None of the following may reach a resident's screen. The client
      // visibility matrix calls Household.members cross-resident data and its
      // exposure a critical defect.
      'head_name': 'Juan Dela Cruz',
      'members': <Object>[
        <String, dynamic>{'name': 'Maria Dela Cruz', 'resident_id': 'r-99'},
      ],
      'residents': <Object>[
        <String, dynamic>{'name': 'Juan Dela Cruz'},
      ],
      'relatives': <String>['Maria'],
      'dependents': <String>['Juan'],
      'families': <Object>[
        <String, dynamic>{'head_name': 'Juan Dela Cruz'},
      ],
    };

    test('cross-resident data does not survive the real decoder', () async {
      final repository = HouseholdApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(hostilePayload()),
          accessTokenProvider: () async => 'tok',
        ),
      );

      final summary = (await repository.loadOwnHousehold()).valueOrNull;
      final rendered = summary.toString().toLowerCase();

      for (final forbidden in <String>[
        'juan',
        'maria',
        'dela cruz',
        'r-99',
        'head_name',
        'relatives',
        'dependents',
      ]) {
        expect(rendered, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('the production decoder names no cross-resident key', () {
      const source =
          'lib/features/household/data/household_api_repository.dart';
      final decoder = File(source).readAsStringSync();

      for (final forbidden in <String>[
        'members',
        'residents',
        'relatives',
        'dependents',
        'head_name',
        'families',
      ]) {
        expect(
          decoder.contains("'$forbidden'"),
          isFalse,
          reason: '$source reads $forbidden',
        );
      }
    });
  });


  group('a correction never rewrites the record — acceptance 3', () {
    test('production declines rather than inventing a payload', () async {
      // C-12. This asserted that `HouseholdDto.encodeCorrection` produced
      // `{kind: ...}` — a body nothing sends, for a request production refuses
      // to make at all.
      //
      // The real behaviour is better than the encoded one and is what is
      // asserted now: `me/profile/corrections` needs a named field with a
      // proposed value, a household correction carries a category and nothing
      // else, and rather than inventing a field the repository declines and the
      // screen sends the resident to the office. Reporting that the office's
      // count is wrong is not the same as proposing what it should be.
      final repository = HouseholdApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(const <String, dynamic>{}),
          accessTokenProvider: () async => 'tok',
        ),
      );

      final outcome = await repository.submitCorrectionRequest(
        request: const HouseholdCorrectionRequest(
          kind: HouseholdCorrectionKind.addressWrong,
        ),
        idempotencyKey: 'key-1',
      );

      expect(outcome, isA<Err<void>>());
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
