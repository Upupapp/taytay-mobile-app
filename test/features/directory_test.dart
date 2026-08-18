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
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
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

  /// What the process last actually fetched. Set by the cases that exercise
  /// the offline fallback.
  CachedRead<Paginated<LguService>>? lastKnown;

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

  @override
  CachedRead<Paginated<LguService>>? lastKnownServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 20,
  }) => lastKnown;
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
  Future<Result<AssistanceProgram>> loadProgram(String id) async {
    detailCalls++;
    for (final program in programs) {
      // By id, matching the server: `programs/{program}` resolves the path
      // segment with `findByUuid`, and the code is not a route key.
      if (program.id == id) return Ok<AssistanceProgram>(program);
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

AssistanceProgram aics() => AssistanceProgram(
  id: 'prog-aics-0001',
  code: 'AICS',
  name: 'Assistance to Individuals in Crisis Situation',
  description: 'Help for residents facing an unexpected crisis.',
  ownerOffice: 'Municipal Social Welfare and Development Office',
  targetPopulation: 'Residents facing an unexpected crisis',
  benefitType: 'financial',
  acceptsApplications: true,
  // 31 December 2026, 18:00 in Taytay — the note must read the Manila day,
  // not the UTC one.
  applicationsCloseAt: DateTime.utc(2026, 12, 31, 10),
  decidedBy: 'lgu',
  turnaroundTargetDays: 7,
  requirements: const <ProgramRequirement>[
    ProgramRequirement(
      code: 'valid-id',
      label: 'Valid government-issued ID',
      obligation: RequirementObligation.required,
    ),
    ProgramRequirement(
      code: 'barangay-cert',
      label: 'Barangay certificate',
      obligation: RequirementObligation.conditional,
      conditionNote: 'If your address is not on your ID',
    ),
  ],
  conditions: const <EligibilityCondition>[
    EligibilityCondition('A resident of Taytay, Rizal'),
    EligibilityCondition('18 years old and above'),
  ],
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
    network: base.network,
    telemetry: base.telemetry,
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
      const condition = EligibilityCondition('60 years old and above');
      expect(condition.explanation, isNotEmpty);

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

    test('availability is the server\'s answer, never a clock comparison', () {
      // This acceptance changed at TAB 07, and the reason it changed matters.
      //
      // It used to forbid the words "open" and "closed" entirely, because the
      // app was deriving them from published dates against the device clock —
      // and a window that has passed on a phone may still be open at the
      // counter, so saying "closed" sent somebody away from help they could
      // have had.
      //
      // The server now answers the question itself: `accepts_applications` is
      // computed from committed rows at the moment it replies. Relaying that is
      // not the client deciding, it is the client reporting, and refusing to say
      // "closed" when the office has said so would be the unhelpful half of the
      // old rule surviving its reason.
      //
      // What stays forbidden is deriving it. The date is quoted; it is never
      // compared.
      expect(aics().availabilityNote, contains('31 December 2026'));
      expect(aics().availabilityNote, contains('Accepting applications'));

      final closed = AssistanceProgram(
        id: 'p',
        code: 'X',
        name: 'X',
        description: 'X',
        acceptsApplications: false,
        applicationsCloseAt: DateTime.utc(2020),
      );
      expect(closed.availabilityNote, 'Closed to new applications');

      // A closing date in the future does not override the server saying no.
      final pausedButDated = AssistanceProgram(
        id: 'p',
        code: 'X',
        name: 'X',
        description: 'X',
        acceptsApplications: false,
        applicationsCloseAt: DateTime.utc(2099),
      );
      expect(pausedButDated.availabilityNote, isNot(contains('2099')));

      // And the entity holds no comparison to make one with.
      final source = File(
        'lib/features/programs/domain/assistance_program.dart',
      ).readAsStringSync();
      for (final banned in <String>['isBefore', 'isAfter', 'DateTime.now']) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });

    test('there is no grant figure to do arithmetic with at all', () {
      // Stronger than the rule this replaces. The entity used to hold the
      // maximum grant as text so no arithmetic could be done with it; the
      // citizen projection publishes no figure of any kind, so there is now
      // nowhere for one to land. A number on this screen is a promise a
      // caseworker then has to keep.
      final source = File(
        'lib/features/programs/domain/assistance_program.dart',
      ).readAsStringSync();
      for (final banned in <String>[
        'maximumGrant',
        'grantAmount',
        'incomeCeiling',
        'budgetRemaining',
        'double ',
      ]) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('the programme decoder is an allow-list', () {
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'id': 'prog-aics-0001',
      'code': 'AICS',
      'name': 'Assistance to Individuals in Crisis Situation',
      'description': 'Help for residents facing a crisis.',
      'owner_office': 'Municipal Social Welfare and Development Office',
      // Keys the staff projection adds and the citizen one holds back. They are
      // in the payload here precisely because a widened projection is the way
      // they would arrive for real.
      'status': 'active',
      'is_citizen_visible': true,
      'authority': 'DSWD',
      'funding_source_label': 'Trust Fund 2026',
      'eligibility_guidance_version': 4,
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
        decoded.ownerOffice,
        decoded.targetPopulation,
        decoded.benefitType,
        decoded.decidedBy,
        ...decoded.conditions.map((c) => c.explanation),
        ...decoded.requirements.map((r) => r.label),
        ...decoded.requirements.map((r) => r.instructions),
        ...decoded.requirements.map((r) => r.conditionNote),
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
      expect(decoded.ownerOffice, isNotNull);
    });

    test('a machine-readable rule set is ignored, not adopted', () {
      // `eligibility_rules` is exactly what would let this app compute a
      // verdict. There is nowhere to put it.
      final decoded = ProgramDto.decode(<String, dynamic>{
        'id': 'prog-test',
        'code': 'X',
        'name': 'X',
        'eligibility_rules': <String, dynamic>{'age': '>=60'},
      })!;
      expect(decoded.conditions, isEmpty);
    });

    test('a programme with no id, code or name is dropped', () {
      // There is no `status` to refuse any more — the citizen projection never
      // carries one, because `publicQuery()` filters drafts server-side. What
      // remains worth refusing is a row a resident could not act on: an entry
      // with no name is not degraded data, it is a line in a list of public
      // benefits that does nothing when tapped.
      expect(
        ProgramDto.decode(<String, dynamic>{'code': 'X', 'name': 'X'}),
        isNull,
        reason: 'no id',
      );
      expect(
        ProgramDto.decode(<String, dynamic>{'id': 'p', 'name': 'X'}),
        isNull,
        reason: 'no code',
      );
      expect(
        ProgramDto.decode(<String, dynamic>{'id': 'p', 'code': 'X'}),
        isNull,
        reason: 'no name',
      );
    });

    test('an entry without a code or a name is not a programme', () {
      expect(ProgramDto.decode(<String, dynamic>{'name': 'X'}), isNull);
      expect(
        ProgramDto.decode(<String, dynamic>{'id': 'prog-test', 'code': 'X'}),
        isNull,
      );
      expect(ProgramDto.decode('nope'), isNull);
      expect(ProgramDto.decode(null), isNull);
    });

    test('a bad entry is dropped without taking the page down', () {
      final decoded = ProgramDto.decodeAll(<Object>[
        <String, dynamic>{'id': 'p-a', 'code': 'A', 'name': 'A'},
        // No name: unrenderable, dropped.
        <String, dynamic>{'id': 'p-b', 'code': 'B'},
        'garbage',
        <String, dynamic>{'id': 'p-c', 'code': 'C', 'name': 'C'},
      ]);
      expect(decoded.map((p) => p.code), <String>['A', 'C']);
    });

    test('conditions are sentences, and anything structured is dropped', () {
      final decoded = ProgramDto.decode(<String, dynamic>{
        'id': 'p',
        'code': 'X',
        'name': 'X',
        'conditions': <Object>[
          '60 years old and above',
          '   ',
          // A comparator arriving in the conditions list is exactly what would
          // let this app compute a verdict. It has nowhere to go.
          <String, dynamic>{'field': 'age', 'operator': '>=', 'value': 60},
        ],
      })!;

      expect(decoded.conditions, hasLength(1));
      expect(decoded.conditions.single.explanation, '60 years old and above');
    });

    test('requirements decode with their obligation and instructions', () {
      final decoded = ProgramDto.decode(<String, dynamic>{
        'id': 'p',
        'code': 'X',
        'name': 'X',
        'requirements': <Object>[
          <String, dynamic>{
            'id': 'prog-test',
            'code': 'valid-id',
            'label': 'Valid government-issued ID',
            'obligation': 'required',
            'accepted_documents': <Object>['philsys', 'passport', 42],
          },
          <String, dynamic>{
            'id': 'prog-test',
            'code': 'brgy',
            'label': 'Barangay certificate',
            'obligation': 'conditional',
            'condition_note': 'If your address is not on your ID',
            'instructions': 'Ask at your barangay hall.',
          },
          // No label: cannot be brought to an office, so it is not shown.
          <String, dynamic>{'id': 'prog-test', 'code': 'nameless'},
          'a bare string',
        ],
      })!;

      expect(decoded.requirements, hasLength(2));
      expect(
        decoded.requirements.first.obligation,
        RequirementObligation.required,
      );
      expect(decoded.requirements.first.acceptedDocuments, <String>[
        'philsys',
        'passport',
      ]);
      expect(
        decoded.requirements.last.obligation,
        RequirementObligation.conditional,
      );
      expect(decoded.requirements.last.conditionNote, isNotNull);
    });

    test('an unrecognised obligation reads as required', () {
      // Fails towards the resident bringing the document. A photocopy costs
      // less than the trip.
      expect(
        RequirementObligation.parse('something-new'),
        RequirementObligation.required,
      );
      expect(RequirementObligation.parse(null), RequirementObligation.required);
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

    test('the deny-list mirrors what the staff projection holds back', () {
      // Re-checked against `ProgramController::staffProjection()` at the
      // baseline. These are the exact keys the server adds for staff and
      // withholds from a resident; if one ever arrives, the projection widened
      // and somebody must decide whether a resident should see it.
      for (final key in <String>[
        'status',
        'is_citizen_visible',
        'authority',
        'funding_source_label',
        'eligibility_guidance_version',
      ]) {
        expect(ProgramDto.forbiddenKeys, contains(key), reason: key);
      }
    });
  });

  group('routes and deep links', () {
    test('services and programmes are both public', () {
      // The server draws this line, not the app — and until TAB 07 the app drew
      // it in the wrong place. `GET programs` carries no `auth:sanctum` and
      // never has, so requiring an account here withheld information the
      // municipality had published for everyone, from the residents least
      // likely to already have an account.
      expect(AppRoute.services.requirement, AccessRequirement.public);
      expect(AppRoute.serviceDetail.requirement, AccessRequirement.public);
      expect(AppRoute.programs.requirement, AccessRequirement.public);
      expect(AppRoute.programDetail.requirement, AccessRequirement.public);
      expect(
        ResidentCapability.browsePrograms.requirement,
        AccessRequirement.public,
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

  group('programmes are public, and a guest reads them', () {
    // Inverted at TAB 07, and the inversion is the finding. These tests used to
    // assert that a guest was sent to sign in and issued no request — the app's
    // own rule, not the server's. `GET programs` carries no `auth:sanctum`, so
    // the effect was to withhold published municipal information from the
    // residents least likely to already have an account.
    testWidgets('a guest sees the list and the request is made', (
      tester,
    ) async {
      final booted = await bootDirectory(
        tester,
        programs: <AssistanceProgram>[aics()],
        location: '/programs',
      );

      expect(booted.programs.listCalls, 1);
      expect(find.text('Welcome to Taytay LGU IDS'), findsNothing);
      expect(
        find.text('Assistance to Individuals in Crisis Situation'),
        findsOneWidget,
      );
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

    testWidgets('a guest deep-linking to a programme reaches it', (
      tester,
    ) async {
      final booted = await bootDirectory(
        tester,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/prog-aics-0001',
      );

      expect(booted.programs.detailCalls, 1);
      expect(find.text('Welcome to Taytay LGU IDS'), findsNothing);
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
        location: '/programs/prog-aics-0001',
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
        location: '/programs/prog-aics-0001',
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
        location: '/programs/prog-aics-0001',
      );

      await reveal(tester, find.text('What to bring'));
      expect(find.text('Valid government-issued ID'), findsOneWidget);
      // A conditional requirement says when it applies, right next to itself.
      expect(find.text('If it applies'), findsOneWidget);
      expect(find.text('If your address is not on your ID'), findsOneWidget);

      await reveal(tester, find.text('Details'));
      expect(find.text('AICS'), findsOneWidget);
      // Told plainly, because an applicant deciding whether to travel deserves
      // to know when the LGU does not control the answer.
      expect(find.text('Taytay LGU'), findsOneWidget);
      expect(find.text('about 7 days'), findsOneWidget);

      // The citizen projection publishes no figure and no legal basis, so
      // neither has anywhere to appear.
      expect(find.textContaining('PHP'), findsNothing);
      expect(find.textContaining('Ordinance'), findsNothing);
    });

    testWidgets('the CTA explains and submits nothing', (tester) async {
      await bootDirectory(
        tester,
        level: AccessLevel.verified,
        programs: <AssistanceProgram>[aics()],
        location: '/programs/prog-aics-0001',
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
        location: '/programs/prog-aics-0001',
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
        location: '/programs/prog-aics-0001',
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
