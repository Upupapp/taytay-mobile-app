import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/deep_link.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/programs/data/planned_program_repository.dart';
import 'package:taytay_resident/features/programs/data/program_dto.dart';
import 'package:taytay_resident/features/programs/domain/assistance_program.dart';
import 'package:taytay_resident/features/programs/domain/program_repository.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart';
import 'package:taytay_resident/features/services/domain/service_catalog_repository.dart';
import 'package:taytay_resident/features/services/presentation/service_directory_controller.dart';

/// Serves a fixed catalogue, and records that it was asked.
class StubCatalogRepository implements ServiceCatalogRepository {
  StubCatalogRepository({
    this.services = const <LguService>[],
    this.fails = false,
  });

  List<LguService> services;
  bool fails;
  int listCalls = 0;

  @override
  Future<Result<Paginated<LguService>>> listServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 20,
  }) async {
    listCalls++;
    if (fails) {
      return const Err<Paginated<LguService>>(ServerFailure(isTemporary: true));
    }
    return Ok<Paginated<LguService>>(Paginated<LguService>.single(services));
  }
}

/// Serves programmes, and records that a guest never asked.
class StubProgramRepository implements ProgramRepository {
  StubProgramRepository({this.programs = const <AssistanceProgram>[]});

  List<AssistanceProgram> programs;
  int listCalls = 0;
  int detailCalls = 0;

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = 20,
  }) async {
    listCalls++;
    return Ok<Paginated<AssistanceProgram>>(
      Paginated<AssistanceProgram>.single(programs),
    );
  }

  @override
  Future<Result<AssistanceProgram>> loadProgram(String code) async {
    detailCalls++;
    for (final program in programs) {
      if (program.code == code) return Ok<AssistanceProgram>(program);
    }
    return const Err<AssistanceProgram>(NotFoundFailure());
  }
}

LguService service({
  required String code,
  required String name,
  String description = 'A municipal service.',
  ServiceCategory category = ServiceCategory.dokumento,
}) => LguService(
  id: 'uuid-$code',
  code: code,
  name: name,
  description: description,
  category: ServerValue<ServiceCategory>(
    raw: category.wireValue,
    known: category,
  ),
  status: const ServerValue<ServicePublicationStatus>(
    raw: 'published',
    known: ServicePublicationStatus.published,
  ),
  availableChannels: const <ServerValue<ServiceChannel>>[
    ServerValue<ServiceChannel>(
      raw: 'citizen-mobile',
      known: ServiceChannel.citizenMobile,
    ),
  ],
);

List<LguService> catalogue() => <LguService>[
  service(
    code: 'CEDULA',
    name: 'Community tax certificate',
    description: 'Also called a cedula. Needed for many transactions.',
  ),
  service(
    code: 'BURIAL',
    name: 'Burial assistance',
    description: 'Help with funeral costs for a family member.',
    category: ServiceCategory.kalusugan,
  ),
  service(
    code: 'JOBFAIR',
    name: 'Job fair registration',
    description: 'Register for the next Taytay job fair.',
    category: ServiceCategory.trabaho,
  ),
];

AssistanceProgram aics() => const AssistanceProgram(
  code: 'AICS',
  name: 'Assistance to Individuals in Crisis Situation',
  description: 'Help for residents facing an unexpected crisis.',
  category: 'social-welfare',
  legalBasis: 'Municipal Ordinance 2019-12',
  maximumGrant: 'Up to PHP 10,000',
  eligibility: <EligibilityCriterion>[
    EligibilityCriterion(
      text: 'A resident of Taytay, Rizal',
      category: 'Residency',
    ),
    EligibilityCriterion(text: '18 years old and above', category: 'Age'),
  ],
  requirements: <ProgramRequirement>[
    ProgramRequirement(text: 'Valid government-issued ID'),
    ProgramRequirement(text: 'Barangay certificate', isOptional: true),
  ],
  effectiveFrom: '1 January 2026',
  effectiveTo: '31 December 2026',
  owningOffice: 'Municipal Social Welfare and Development Office',
  contact: '(02) 8000-0000',
  applicationChannel: 'At the municipal hall',
);

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedDirectory = ({
  AppDependencies dependencies,
  StubCatalogRepository catalog,
  StubProgramRepository programs,
});

Future<BootedDirectory> bootDirectory(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  List<LguService>? services,
  List<AssistanceProgram> programs = const <AssistanceProgram>[],
  bool catalogFails = false,
  String location = '/services',
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
        resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
        accessToken: 'token',
      ),
    );
  }

  final catalog = StubCatalogRepository(
    services: services ?? catalogue(),
    fails: catalogFails,
  );
  final programRepository = StubProgramRepository(programs: programs);

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
    serviceCatalogRepository: catalog,
    programRepository: programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
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

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (
    dependencies: dependencies,
    catalog: catalog,
    programs: programRepository,
  );
}

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ')
    .toLowerCase();

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).last;
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  group('search and filter run on the device', () {
    late StubCatalogRepository repository;
    late ServiceDirectoryController controller;

    setUp(() async {
      repository = StubCatalogRepository(services: catalogue());
      controller = ServiceDirectoryController(repository: repository);
      await controller.load();
    });

    tearDown(() => controller.dispose());

    test('a query filters what was already returned, issuing no request', () {
      controller.search('burial');

      expect(controller.visible.map((s) => s.code), <String>['BURIAL']);
      // A search term is a sentence about somebody's circumstances. Filtering
      // locally means the LGU never learns what a resident was looking for.
      expect(repository.listCalls, 1);
    });

    test('search matches name, description and category, never the code', () {
      controller.search('cedula');
      expect(controller.visible, hasLength(1));

      controller.search('funeral');
      expect(controller.visible.map((s) => s.code), <String>['BURIAL']);

      controller.search('trabaho');
      expect(controller.visible.map((s) => s.code), <String>['JOBFAIR']);

      // `JOBFAIR` is not a word a resident searches for, and matching it would
      // produce a result they cannot explain.
      controller.search('JOBFAIR');
      expect(controller.visible, isEmpty);
    });

    test('a category filter toggles', () {
      controller.filterByCategory(ServiceCategory.kalusugan);
      expect(controller.visible.map((s) => s.code), <String>['BURIAL']);

      controller.filterByCategory(ServiceCategory.kalusugan);
      expect(controller.visible, hasLength(3));
    });

    test('query and category combine', () {
      controller
        ..filterByCategory(ServiceCategory.kalusugan)
        ..search('cedula');
      expect(controller.visible, isEmpty);
      expect(controller.isFiltered, isTrue);

      controller.clearFilters();
      expect(controller.visible, hasLength(3));
      expect(controller.isFiltered, isFalse);
    });

    test('categories offered are only those actually returned', () {
      // Never advertises a category the LGU does not currently publish, and
      // never offers one that would produce an empty list.
      expect(
        controller.availableCategories,
        unorderedEquals(<ServiceCategory>[
          ServiceCategory.dokumento,
          ServiceCategory.kalusugan,
          ServiceCategory.trabaho,
        ]),
      );
    });

    test('an entry is found by its stable code, not its uuid', () {
      expect(controller.byCode('CEDULA')?.name, 'Community tax certificate');
      expect(controller.byCode('uuid-CEDULA'), isNull);
      expect(controller.byCode('NOPE'), isNull);
    });
  });

  group('staleness is explicit — acceptance 3', () {
    test(
      'a failed refresh keeps the entries and flags them as saved',
      () async {
        final repository = StubCatalogRepository(services: catalogue());
        final controller = ServiceDirectoryController(repository: repository);
        addTearDown(controller.dispose);

        await controller.load();
        expect(controller.isShowingStale, isFalse);
        expect(controller.loadedAt, isNotNull);

        repository.fails = true;
        await controller.load();

        // The catalogue a resident had is kept — but labelled, because a
        // silently-stale programme window looks identical to a working app.
        expect(controller.totalCount, 3);
        expect(controller.isShowingStale, isTrue);
        expect(controller.hasNothingToShow, isFalse);
      },
    );

    test('a first-load failure has nothing to show, and says so', () async {
      final controller = ServiceDirectoryController(
        repository: StubCatalogRepository(fails: true),
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.hasNothingToShow, isTrue);
      expect(controller.isShowingStale, isFalse);
    });

    test('the controller holds no personal state and is safe to log', () {
      final controller = ServiceDirectoryController(
        repository: StubCatalogRepository(),
      );
      addTearDown(controller.dispose);
      expect(controller.toString(), contains('loaded: 0'));
    });
  });

  group('the app never computes eligibility — acceptance 2', () {
    test('a criterion is text, with nowhere to put a rule', () {
      const criterion = EligibilityCriterion(text: '60 years old and above');
      expect(criterion.text, isNotEmpty);

      final source = File(
        'lib/features/programs/domain/assistance_program.dart',
      ).readAsStringSync();
      // No operator, no threshold, no field name to compare against.
      for (final field in <String>[
        'minimumAge',
        'maximumAge',
        'incomeCeiling',
        'operator',
        'threshold',
        'ruleExpression',
      ]) {
        expect(source, isNot(contains('this.$field')), reason: field);
      }
    });

    test('no source file evaluates eligibility or promises approval', () {
      final offenders = <String>[];
      for (final directory in <String>[
        'lib/features/programs',
        'lib/features/services',
      ]) {
        for (final file
            in Directory(directory)
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
            RegExp(r'\bisEligible\b'),
            RegExp(r'\bcanApply\b'),
            RegExp(r'\bqualifies\b'),
            RegExp(r'\bwillBeApproved\b'),
            RegExp(r'\bcomputeEligibility\b'),
          ]) {
            if (pattern.hasMatch(source)) {
              offenders.add('${file.path}: ${pattern.pattern}');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('availability is quoted, never computed into open or closed', () {
      // A window that has passed on a phone clock may still be open at the
      // counter. Saying "closed" sends somebody away from help they could have
      // had.
      expect(aics().availabilityNote, contains('1 January 2026'));
      expect(aics().availabilityNote, contains('31 December 2026'));

      const noDates = AssistanceProgram(code: 'X', name: 'X', description: 'X');
      expect(noDates.availabilityNote, isNull);

      const fromOnly = AssistanceProgram(
        code: 'X',
        name: 'X',
        description: 'X',
        effectiveFrom: '1 May',
      );
      expect(fromOnly.availabilityNote, contains('from 1 May'));

      for (final program in <AssistanceProgram>[aics(), noDates, fromOnly]) {
        final note = program.availabilityNote?.toLowerCase() ?? '';
        for (final verdict in <String>['closed', 'open now', 'expired']) {
          expect(note, isNot(contains(verdict)), reason: verdict);
        }
      }
    });

    test('the maximum grant is text, so no arithmetic can be done with it', () {
      expect(aics().maximumGrant, 'Up to PHP 10,000');
      final source = File(
        'lib/features/programs/domain/assistance_program.dart',
      ).readAsStringSync();
      expect(source, contains('final String? maximumGrant;'));
    });
  });

  group('the programme decoder is an allow-list', () {
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'code': 'AICS',
      'name': 'Assistance to Individuals in Crisis Situation',
      'description': 'Help for residents facing a crisis.',
      'status': 'active',
      'legal_basis': 'Municipal Ordinance 2019-12',
      'maximum_grant': 'Up to PHP 10,000',
      // None of the following may survive.
      'funding_source': 'Trust Fund 2026 line 14',
      'audit': <String, dynamic>{'created_by': 'staff-1'},
      'created_by': 'staff-1',
      'updated_by': 'staff-2',
      // Deliberately distinctive: "12" would collide with the legal basis
      // "Municipal Ordinance 2019-12" and pass the check for the wrong reason.
      'slots_remaining': 137,
      'quota': 4242,
      'capacity': 4242,
      'budget_remaining': 987654,
      'beneficiary_count': 991,
      'priority_score': 0.7373,
      'ranking': 3,
      'weight': 1.5,
      'eligibility_rules': <String, dynamic>{'age': '>=60'},
      'internal_notes': 'Watch for duplicates',
      'remarks': 'Escalate',
      'draft': true,
      'applicants': <String>['Bayani Magsaysay'],
      'beneficiaries': <String>['Corazon Bonifacio'],
    };

    test('no capacity, ranking, budget, draft or applicant data survives', () {
      final decoded = ProgramDto.decode(hostilePayload())!;
      final rendered = <String?>[
        decoded.code,
        decoded.name,
        decoded.description,
        decoded.category,
        decoded.legalBasis,
        decoded.maximumGrant,
        decoded.owningOffice,
        decoded.contact,
        decoded.applicationChannel,
        decoded.effectiveFrom,
        decoded.effectiveTo,
        ...decoded.eligibility.map((e) => e.text),
        ...decoded.requirements.map((r) => r.text),
      ].whereType<String>().join(' ').toLowerCase();

      for (final leak in <String>[
        'trust fund',
        'staff-1',
        'staff-2',
        '137',
        '4242',
        '987654',
        '991',
        '0.7373',
        '>=60',
        'duplicates',
        'escalate',
        'bayani',
        'corazon',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }

      // What a citizen is entitled to did survive.
      expect(decoded.code, 'AICS');
      expect(decoded.legalBasis, 'Municipal Ordinance 2019-12');
      expect(decoded.maximumGrant, 'Up to PHP 10,000');
    });

    test('a machine-readable rule set is ignored, not adopted', () {
      // `eligibility_rules` is exactly what would let this app compute a
      // verdict. There is nowhere to put it.
      final decoded = ProgramDto.decode(<String, dynamic>{
        'code': 'X',
        'name': 'X',
        'eligibility_rules': <String, dynamic>{'age': '>=60'},
      })!;
      expect(decoded.eligibility, isEmpty);
    });

    test('a non-active programme is refused, and so is an unstated status', () {
      for (final status in <String>[
        'draft',
        'suspended',
        'retired',
        'closed',
      ]) {
        expect(
          ProgramDto.decode(<String, dynamic>{
            'code': 'X',
            'name': 'X',
            'status': status,
          }),
          isNull,
          reason: status,
        );
      }
      // Active is the only value that passes.
      expect(
        ProgramDto.decode(<String, dynamic>{
          'code': 'X',
          'name': 'X',
          'status': 'active',
        }),
        isNotNull,
      );
    });

    test('an entry without a code or a name is not a programme', () {
      expect(ProgramDto.decode(<String, dynamic>{'name': 'X'}), isNull);
      expect(ProgramDto.decode(<String, dynamic>{'code': 'X'}), isNull);
      expect(ProgramDto.decode('nope'), isNull);
      expect(ProgramDto.decode(null), isNull);
    });

    test('a bad entry is dropped without taking the page down', () {
      final decoded = ProgramDto.decodeAll(<Object>[
        <String, dynamic>{'code': 'A', 'name': 'A', 'status': 'active'},
        <String, dynamic>{'code': 'B', 'status': 'draft', 'name': 'B'},
        'garbage',
        <String, dynamic>{'code': 'C', 'name': 'C'},
      ]);
      expect(decoded.map((p) => p.code), <String>['A', 'C']);
    });

    test('eligibility and requirements read as text, in both shapes', () {
      final decoded = ProgramDto.decode(<String, dynamic>{
        'code': 'X',
        'name': 'X',
        'eligibility': <Object>[
          '60 years old and above',
          <String, dynamic>{
            'text': 'Resident of Taytay',
            'category': 'Residency',
          },
          <String, dynamic>{'nothing': 'useful'},
        ],
        'requirements': <Object>[
          'Valid ID',
          <String, dynamic>{'text': 'Barangay certificate', 'optional': true},
        ],
      })!;

      expect(decoded.eligibility, hasLength(2));
      expect(decoded.eligibility.last.category, 'Residency');
      expect(decoded.requirements, hasLength(2));
      expect(decoded.requirements.first.isOptional, isFalse);
      expect(decoded.requirements.last.isOptional, isTrue);
    });

    test('allowed and forbidden key sets are disjoint', () {
      for (final key in ProgramDto.allowedKeys) {
        expect(ProgramDto.forbiddenKeys, isNot(contains(key)), reason: key);
      }
      for (final key in <String>[
        'funding_source',
        'audit',
        'slots_remaining',
        'eligibility_rules',
        'applicants',
      ]) {
        expect(ProgramDto.forbiddenKeys, contains(key), reason: key);
      }
    });

    test('the shipped programme repository declines', () {
      const repository = PlannedProgramRepository();
      expect(repository.listActivePrograms(), completion(isA<Err<dynamic>>()));
      expect(repository.loadProgram('AICS'), completion(isA<Err<dynamic>>()));
    });
  });

  group('routes and deep links', () {
    test('services are public, programmes are authenticated', () {
      // The server draws this line, not the app: /services is public and
      // /programs?status=active is bearer.
      expect(AppRoute.services.requirement, AccessRequirement.public);
      expect(AppRoute.serviceDetail.requirement, AccessRequirement.public);
      expect(AppRoute.programs.requirement, AccessRequirement.authenticated);
      expect(
        AppRoute.programDetail.requirement,
        AccessRequirement.authenticated,
      );
      expect(
        ResidentCapability.browsePrograms.requirement,
        AccessRequirement.authenticated,
      );
    });

    test('a service path resolves to the detail route, not the list', () {
      expect(AppRoute.forPath('/services'), AppRoute.services);
      expect(AppRoute.forPath('/services/CEDULA'), AppRoute.serviceDetail);
      expect(AppRoute.forPath('/programs'), AppRoute.programs);
      expect(AppRoute.forPath('/programs/AICS'), AppRoute.programDetail);
    });

    test('both directory deep links resolve and carry a bounded code', () {
      final service =
          DeepLink.resolve(<String, String>{
                'target': 'service',
                'id': 'CEDULA',
              })
              as DeepLinkResolved;
      expect(service.target.location, '/services/CEDULA');

      final program =
          DeepLink.resolve(<String, String>{'target': 'program', 'id': 'AICS'})
              as DeepLinkResolved;
      expect(program.target.location, '/programs/AICS');

      // The same bounded identifier rule as everywhere else.
      expect(
        DeepLink.resolve(<String, String>{
          'target': 'service',
          'id': '../digital-id',
        }),
        isA<DeepLinkRejected>(),
      );
    });
  });

  group('guests can use the directory — acceptance 1', () {
    testWidgets('a guest sees the catalogue without signing in', (
      tester,
    ) async {
      final booted = await bootDirectory(tester);

      expect(booted.catalog.listCalls, greaterThan(0));
      expect(find.text('Community tax certificate'), findsOneWidget);
      expect(find.text('Burial assistance'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('a guest can search and reach a detail screen', (tester) async {
      await bootDirectory(tester);

      await tester.enterText(find.byType(TextField), 'burial');
      await tester.pumpAndSettle();
      expect(find.text('Community tax certificate'), findsNothing);

      await tester.tap(find.text('Burial assistance'));
      await tester.pumpAndSettle();

      expect(find.text('BURIAL'), findsOneWidget);
      expect(find.textContaining('funeral costs'), findsWidgets);
    });

    testWidgets('a guest opening a service deep link is not gated', (
      tester,
    ) async {
      await bootDirectory(tester, location: '/services/CEDULA');

      expect(find.text('Community tax certificate'), findsOneWidget);
      expect(find.text('Welcome to Taytay LGU IDS'), findsNothing);
    });

    testWidgets('an unknown code says so and offers the list', (tester) async {
      await bootDirectory(tester, location: '/services/NOPE');

      expect(find.text('This service is not available'), findsOneWidget);
      expect(find.text('See all services'), findsOneWidget);
    });

    testWidgets('an empty catalogue says the catalogue is empty', (
      tester,
    ) async {
      await bootDirectory(tester, services: const <LguService>[]);
      expect(find.text('No services listed yet'), findsOneWidget);
    });

    testWidgets('a query with no matches says something different', (
      tester,
    ) async {
      // A separate test, not a second boot: re-pumping a `TaytayResidentApp`
      // updates the existing State, and the router is a `late final` built from
      // the first dependencies.
      await bootDirectory(tester);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Nothing matches that'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });

    testWidgets('an unreachable catalogue explains and offers a retry', (
      tester,
    ) async {
      await bootDirectory(tester, catalogFails: true);

      expect(find.text('Could not load services'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('programmes are gated, and guests fetch nothing', () {
    testWidgets('a guest is sent to sign in and issues no request', (
      tester,
    ) async {
      final booted = await bootDirectory(tester, location: '/programs');

      expect(booted.programs.listCalls, 0);
      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
    });

    testWidgets('a signed-in resident sees the list and the guidance notice', (
      tester,
    ) async {
      final booted = await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs',
      );

      expect(booted.programs.listCalls, 1);
      expect(find.text('These are guidelines, not a decision'), findsOneWidget);
      expect(
        find.text('Assistance to Individuals in Crisis Situation'),
        findsOneWidget,
      );
    });

    testWidgets('a guest deep-linking to a programme fetches nothing', (
      tester,
    ) async {
      final booted = await bootDirectory(tester, location: '/programs/AICS');

      expect(booted.programs.detailCalls, 0);
      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
    });
  });

  group('programme detail is guidance, never a verdict — acceptance 2', () {
    testWidgets('eligibility is labelled as guidelines in the heading', (
      tester,
    ) async {
      await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
      );

      expect(find.text('Who this is meant to help'), findsOneWidget);
      expect(
        find.textContaining('Staff decide each application individually'),
        findsOneWidget,
      );
      expect(find.text('A resident of Taytay, Rizal'), findsOneWidget);
    });

    testWidgets('nothing on the screen promises approval', (tester) async {
      await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
      );
      final rendered = renderedText(tester);

      // Phrases, not words: the correct copy says "whether you qualify is
      // decided by staff", which contains "you qualify" and must not trip.
      for (final promise in <String>[
        'you qualify for',
        'you are eligible',
        'you will receive',
        'has been approved',
        'guaranteed',
        'you will get',
      ]) {
        expect(rendered, isNot(contains(promise)), reason: promise);
      }
      expect(rendered, contains('cannot tell you the outcome in advance'));
    });

    testWidgets('requirements and details render only published fields', (
      tester,
    ) async {
      await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
      );

      await reveal(tester, find.text('What to bring'));
      expect(find.text('Valid government-issued ID'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);

      await reveal(tester, find.text('Details'));
      expect(find.text('Municipal Ordinance 2019-12'), findsOneWidget);
      expect(find.text('Up to PHP 10,000'), findsOneWidget);
    });

    testWidgets('the CTA explains and submits nothing', (tester) async {
      await bootDirectory(
        tester,
        level: AccessLevel.verified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
      );

      await reveal(tester, find.text('Nothing is submitted by tapping this.'));
      expect(
        find.text('Nothing is submitted by tapping this.'),
        findsOneWidget,
      );

      // Scoped to the button: "Where to apply" sits above it as a detail row.
      await tester.tap(find.widgetWithText(FilledButton, 'How to apply'));
      await tester.pumpAndSettle();

      // Guidance, not a submission — there is no endpoint to submit to.
      expect(find.textContaining('not switched on yet'), findsOneWidget);
    });

    testWidgets('an unverified resident meets the verification gate', (
      tester,
    ) async {
      final booted = await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
      );

      await reveal(tester, find.text('Nothing is submitted by tapping this.'));
      await tester.tap(find.widgetWithText(FilledButton, 'How to apply'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Verify your identity'),
        ),
        findsOneWidget,
      );
      // The gate holds the intent; it does not act on it.
      expect(
        booted.dependencies.intents.pending?.kind,
        ResidentIntentKind.applyForService,
      );
    });
  });

  group('accessibility and responsiveness', () {
    testWidgets('the directory survives a 200% text scale', (tester) async {
      await bootDirectory(
        tester,
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 3000),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('programme detail survives a 200% text scale', (tester) async {
      await bootDirectory(
        tester,
        level: AccessLevel.unverified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/AICS',
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 4000),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the directory renders on a wide surface', (tester) async {
      await bootDirectory(tester, size: const Size(1000, 1800));

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Community tax certificate'), findsOneWidget);
    });
  });
}
