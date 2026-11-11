import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/programs/data/program_api_repository.dart';
import 'package:taytay_resident/features/tulong/data/mock_social_service_repository.dart';
import 'package:taytay_resident/features/tulong/data/social_service_api_repository.dart';
import 'package:taytay_resident/features/tulong/data/social_service_codec.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';
import 'package:taytay_resident/shared/widgets/icon_tile.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

class _Recording implements ApiTransport {
  _Recording(this.responses);

  final List<ApiHttpResponse> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(responses.removeAt(0));
  }
}

ApiHttpResponse _envelope(Object? data, {String? cursor}) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{
      'pagination': <String, Object?>{'next_cursor': cursor},
    },
  }),
);

Map<String, Object?> _service({
  required String name,
  required String slug,
  Object? requirements = const <String>['Bring an ID'],
  bool featured = false,
  Object? presentation,
}) => <String, Object?>{
  'id': '11111111-1111-4111-8111-111111111199',
  'name': name,
  'slug': slug,
  'summary': 'A synthetic summary',
  'details': 'Synthetic details for a test service.',
  'requirements': requirements,
  'contacts': <Map<String, Object?>>[
    <String, Object?>{
      'type': 'mobile',
      'label': 'Contact',
      'value': '555-0100',
    },
  ],
  'locations': <Map<String, String>>[
    <String, String>{'name': 'Where', 'address': '1 Sample Street'},
  ],
  'featured': featured,
  'presentation': presentation,
  'created_at': '2026-07-01T00:00:00Z',
  'updated_at': '2026-07-01T00:00:00Z',
};

AppConfig _dev({String dataMode = ''}) => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawDataMode: dataMode,
  rawMockLatencyMs: '0',
);

Future<AppDependencies> _boot(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  String location = '/programs',
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
        accessToken: 'token',
      ),
    );
  }
  final AppDependencies dependencies = AppDependencies.build(
    config: _dev(dataMode: 'mock'),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  addTearDown(dependencies.dispose);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
  return dependencies;
}

void main() {
  test('staging refuses mock data', () {
    final AppConfig staging = AppConfig.from(
      rawEnvironment: 'staging',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
      rawDataMode: 'mock',
    );
    expect(staging.usesMockData, isFalse);
  });

  test('a dev build without the mock flag uses the live repository', () async {
    final AppDependencies dependencies = AppDependencies.build(
      config: _dev(),
      secrets: InMemorySecretStore(),
      sessionStore: InMemorySessionStore(),
      localAuthenticator: const UnavailableLocalAuthenticator(),
    );
    addTearDown(dependencies.dispose);
    expect(
      dependencies.socialServiceRepository,
      isA<SocialServiceApiRepository>(),
    );
    expect(dependencies.programRepository, isA<ProgramApiRepository>());
  });

  test(
    'the dev fixture lists eight programmes and keeps the cash gift off the list',
    () async {
      final MockSocialServiceRepository repository =
          MockSocialServiceRepository(
            MockBehaviorController(
              latency: Duration.zero,
              failure: MockFailureMode.none,
            ),
          );
      final Result<Paginated<SocialService>> listed = await repository
          .listServices();
      final List<SocialService> items = listed.valueOrNull!.items;
      expect(items, hasLength(8));
      expect(
        items.map((SocialService service) => service.slug),
        isNot(contains('pwd-cash-gift')),
      );
      final SocialService gift = (await repository.loadService(
        'pwd-cash-gift',
      )).valueOrNull!;
      expect(gift.showsFeaturedLayout, isTrue);
      expect(gift.hiddenFromList, isTrue);
      expect(gift.featuredHeadline, contains('\n'));
      expect(gift.claimSteps, hasLength(3));
      expect(gift.heroUrl, isNull);
      expect(gift.toString(), 'SocialService(pwd-cash-gift)');
      final List<SocialService> featured = (await repository.listServices(
        featured: true,
      )).valueOrNull!.items;
      expect(featured.map((SocialService service) => service.slug), <String>[
        'pwd-cash-gift',
      ]);
    },
  );

  test('a failed list still returns pages saved in the fixture', () async {
    final MockSocialServiceRepository repository = MockSocialServiceRepository(
      MockBehaviorController(
        latency: Duration.zero,
        failure: MockFailureMode.offline,
      ),
    );
    expect((await repository.listServices()).isErr, isTrue);
    final List<SocialService> saved = await repository.savedOnThisPhone();
    expect(saved, isNotEmpty);
    expect(
      saved.every((SocialService service) => service.savedLine.isNotEmpty),
      isTrue,
    );
  });

  test('live reads call services only, send no search term, and ignore '
      'presentation', () async {
    final _Recording transport = _Recording(<ApiHttpResponse>[
      _envelope(<Object?>[
        _service(name: 'Sample Assistance', slug: 'sample-assistance'),
        <String, Object?>{'summary': 'no name and no slug'},
        _service(
          name: 'Gift',
          slug: 'gift',
          featured: true,
          requirements: <Map<String, Object?>>[
            <String, Object?>{'text': 'Bring an ID', 'sample': true},
          ],
          presentation: <String, Object?>{
            'badge': 'SHOULD NOT APPEAR',
            'layout': 'featured',
            'hero_sample': true,
          },
        ),
      ], cursor: 'next-1'),
    ]);
    final SocialServiceApiRepository repository = SocialServiceApiRepository(
      apiClient: ApiClient(
        config: _dev(),
        transport: transport,
        cache: PublicCache(),
      ),
    );

    final Paginated<SocialService> page = (await repository.listServices(
      limit: 80,
      cursor: 'cursor-1',
    )).valueOrNull!;
    expect(page.items, hasLength(2));
    expect(page.items.last.presentation, isNull);
    expect(page.items.last.showsFeaturedLayout, isFalse);
    expect(page.items.last.requirements.single.sample, isFalse);
    expect(page.items.last.featured, isTrue);

    final ApiRequest request = transport.requests.single;
    expect(request.method, HttpMethod.get);
    expect(request.path, 'services');
    // D-59, D-205: the contract accepts `q`, and the app never sends it.
    expect(request.query.containsKey('q'), isFalse);
    expect(request.query['limit'], '50');
    expect(request.query['cursor'], 'cursor-1');
    expect(request.query.containsKey('featured'), isFalse);
    expect(request.query.keys, isNot(contains('role')));
    expect(request.query.keys, isNot(contains('is_admin')));
    expect(request.headers.keys, isNot(contains('role')));
    expect(request.body, isNull);

    transport.responses.add(
      _envelope(_service(name: 'Sample Assistance', slug: 'sample-assistance')),
    );
    final SocialService loaded = (await repository.loadService(
      'sample-assistance',
    )).valueOrNull!;
    expect(loaded.slug, 'sample-assistance');
    expect(transport.requests.last.path, 'services/sample-assistance');
    expect(transport.requests.last.path.contains('programs'), isFalse);
  });

  test(
    'service icon keys map onto Lucide names, and unknown keys fall back',
    () {
      const Map<String, String> keys = <String, String>{
        'accessibility': 'accessibility',
        'users': 'users',
        'users-round': 'usersRound',
        'users_round': 'usersRound',
        'Users-Round': 'usersRound',
        'baby': 'baby',
        'hand-coins': 'handCoins',
        'handcoins': 'handCoins',
        'graduation-cap': 'graduationCap',
        'graduationcap': 'graduationCap',
        'heart': 'heart',
        'heart-pulse': 'heartPulse',
        'heartpulse': 'heartPulse',
        'briefcase': 'briefcase',
        'briefcase-business': 'briefcaseBusiness',
        'briefcasebusiness': 'briefcaseBusiness',
        'hand-heart': 'handHeart',
        'handheart': 'handHeart',
        'HAND_HEART': 'handHeart',
        '': 'handHeart',
      };
      for (final MapEntry<String, String> entry in keys.entries) {
        expect(
          canonicalServiceIconKey(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(canonicalServiceIconKey(null), 'handHeart');
      expect(canonicalServiceIconKey('no-such-icon'), 'handHeart');
      expect(canonicalServiceIconKey('wifi-off'), 'handHeart');
    },
  );

  test('live fields decode, and presentation cannot invent them', () {
    final SocialService decoded = decodeSocialService(<String, Object?>{
      'name': 'Sample',
      'slug': 'sample',
      'icon_key': 'users-round',
      'tile_color': '#abc',
      'badge': 'MSWDO',
      'legal_basis': 'RA 7277',
      'claim_steps': <Object?>[' one ', '', 4, 'two'],
      'featured_headline': 'Line one\nLine two',
      'schedule': 'Mon',
      'hero_url': ' https://example.test/services/sample/hero ',
      'hidden_from_list': true,
      'featured': true,
      'contacts': <Object?>[
        <String, Object?>{
          'type': 'email',
          'label': null,
          'value': 'desk@example.test',
        },
        <String, Object?>{'type': 'MOBILE', 'value': '555-0100'},
        <String, Object?>{
          'type': 'facebook',
          'label': 'Page',
          'value': 'facebook.com/example',
        },
        <String, Object?>{'type': 'pigeon', 'label': 'Desk', 'value': '1'},
        <String, Object?>{'type': 'hotline', 'label': 'Empty', 'value': '  '},
      ],
      'presentation': <String, Object?>{
        'badge': 'SHOULD NOT APPEAR',
        'layout': 'featured',
        'glyph': 'heart',
      },
    }, allowPresentation: false)!;

    expect(decoded.iconKey, 'usersRound');
    expect(decoded.tileColor, 0xFFAABBCC);
    expect(decoded.badge, 'MSWDO');
    expect(decoded.legalBasis, 'RA 7277');
    expect(decoded.claimSteps, <String>['one', 'two']);
    expect(decoded.featuredHeadline, 'Line one\nLine two');
    expect(decoded.schedule, 'Mon');
    expect(decoded.heroUrl, 'https://example.test/services/sample/hero');
    expect(decoded.hiddenFromList, isTrue);
    expect(decoded.showsFeaturedLayout, isTrue);
    expect(decoded.presentation, isNull);
    expect(decoded.contacts, hasLength(4));
    expect(decoded.contacts[0].type, ServiceContactType.email);
    expect(decoded.contacts[0].label, isNull);
    expect(decoded.contacts[0].displayLabel, 'Email');
    expect(decoded.contacts[0].toString(), 'ServiceContact(email)');
    expect(decoded.contacts[1].type, ServiceContactType.mobile);
    expect(decoded.contacts[1].displayLabel, 'Mobile');
    expect(decoded.contacts[2].type, ServiceContactType.facebook);
    expect(decoded.contacts[3].type, ServiceContactType.unknown);
    expect(decoded.dialable, '555-0100');

    final SocialService full = decodeSocialService(<String, Object?>{
      'name': 'Painted',
      'slug': 'painted',
      'tile_color': '#0B3D91',
    }, allowPresentation: false)!;
    expect(full.tileColor, 0xFF0B3D91);
    expect(full.iconKey, 'handHeart');
    expect(full.claimSteps, isEmpty);
    expect(full.showsFeaturedLayout, isFalse);

    for (final String bad in <String>[
      'blue',
      '#abcd',
      '#GG0000',
      'rgb(0,0,0)',
    ]) {
      expect(
        decodeSocialService(<String, Object?>{
          'name': 'Bad',
          'slug': 'bad',
          'tile_color': bad,
          'featured': true,
          'featured_headline': 'Only a headline',
        }, allowPresentation: false)!.tileColor,
        isNull,
      );
    }

    final SocialService headlineOnly = decodeSocialService(<String, Object?>{
      'name': 'Headline',
      'slug': 'headline',
      'featured': true,
      'featured_headline': 'Only a headline',
      'claim_steps': <String>[],
    }, allowPresentation: false)!;
    expect(headlineOnly.featured, isTrue);
    expect(headlineOnly.showsFeaturedLayout, isFalse);
  });

  test(
    'hidden services stay off the catalogue unless featured is asked',
    () async {
      Map<String, Object?> hiddenGift() => <String, Object?>{
        ..._service(name: 'Gift', slug: 'gift', featured: true),
        'hidden_from_list': true,
        'featured_headline': 'Gift\nline',
        'claim_steps': <String>['Bring an ID'],
        'icon_key': 'not-a-lucide-name',
      };
      final _Recording transport = _Recording(<ApiHttpResponse>[
        _envelope(<Object?>[
          _service(name: 'Shown', slug: 'shown'),
          hiddenGift(),
          <String, Object?>{
            ..._service(name: 'Quiet', slug: 'quiet'),
            'hidden_from_list': true,
            'featured': false,
          },
        ]),
        _envelope(<Object?>[
          _service(name: 'Shown', slug: 'shown'),
          hiddenGift(),
          <String, Object?>{
            ..._service(name: 'Quiet', slug: 'quiet'),
            'hidden_from_list': true,
          },
        ]),
        _envelope(hiddenGift()),
      ]);
      final SocialServiceApiRepository repository = SocialServiceApiRepository(
        apiClient: ApiClient(
          config: _dev(),
          transport: transport,
          cache: PublicCache(),
        ),
      );

      final List<SocialService> catalogue =
          (await repository.listServices()).valueOrNull!.items;
      expect(catalogue.map((SocialService service) => service.slug), <String>[
        'shown',
      ]);
      expect(transport.requests.single.query.containsKey('featured'), isFalse);

      final List<SocialService> featured = (await repository.listServices(
        featured: true,
      )).valueOrNull!.items;
      expect(featured.map((SocialService service) => service.slug), <String>[
        'gift',
      ]);
      expect(featured.single.showsFeaturedLayout, isTrue);
      expect(featured.single.hiddenFromList, isTrue);
      expect(featured.single.iconKey, 'handHeart');
      expect(transport.requests.last.query['featured'], 'true');

      final SocialService loaded = (await repository.loadService(
        'gift',
      )).valueOrNull!;
      expect(loaded.slug, 'gift');
      expect(loaded.hiddenFromList, isTrue);
      expect(transport.requests.last.path, 'services/gift');
    },
  );

  testWidgets(
    'an unknown icon falls back, and a hotline label can stay a siren',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const SocialService service = SocialService(
        id: '11111111-1111-4111-8111-111111111199',
        name: 'Sample',
        slug: 'sample',
        summary: 'A synthetic summary',
        details: 'Synthetic details.',
        iconKey: 'mystery',
        officeName: 'Municipal Social Welfare and Development Office',
        contacts: <ServiceContact>[
          ServiceContact(
            type: ServiceContactType.hotline,
            label: 'Anti-trafficking',
            value: '1343',
          ),
          ServiceContact(
            type: ServiceContactType.email,
            value: 'desk@example.test',
          ),
          ServiceContact(
            type: ServiceContactType.facebook,
            label: 'Facebook',
            value: 'facebook.com/example',
          ),
          ServiceContact(
            type: ServiceContactType.mobile,
            label: 'Contact',
            value: '555-0100',
          ),
        ],
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: TulongCanvas(frame: TulongFrame.detail, service: service),
        ),
      );
      await tester.pumpAndSettle();

      final TaytayIcon hero = tester
          .widgetList<TaytayIcon>(find.byType(TaytayIcon))
          .singleWhere(
            (TaytayIcon icon) => icon.size == IconTileSize.large.glyphSize,
          );
      expect(hero.icon, TaytayIcons.handHeart);
      final Iterable<IconData> icons = tester
          .widgetList<TaytayIcon>(find.byType(TaytayIcon))
          .map((TaytayIcon icon) => icon.icon);
      expect(icons, contains(TaytayIcons.siren));
      expect(icons, contains(TaytayIcons.mail));
      expect(icons, contains(TaytayIcons.messageSquare));
      expect(icons, contains(TaytayIcons.phone));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Anti-trafficking'), findsOneWidget);
    },
  );

  testWidgets('users-round is the vendored users-2 glyph on every tile', (
    WidgetTester tester,
  ) async {
    Future<void> pumpRow(String iconKey, int tile) {
      return tester.pumpWidget(
        MaterialApp(
          home: TulongCanvas(
            frame: TulongFrame.list,
            services: <SocialService>[
              SocialService(
                id: '11111111-1111-4111-8111-111111111108',
                name: 'Youth Programmes',
                slug: 'youth',
                summary: 'Youth groups',
                details: 'Synthetic details.',
                iconKey: iconKey,
                tileColor: tile,
              ),
            ],
          ),
        ),
      );
    }

    bool youthMark(CustomPaint paint) => paint.size == const Size.square(20);

    await pumpRow('users', 0xFF7A5E0C);
    expect(
      tester.widgetList<CustomPaint>(find.byType(CustomPaint)).where(youthMark),
      isEmpty,
    );
    expect(_tileIcon(tester, 'youth').icon, TaytayIcons.users);

    await pumpRow('usersRound', 0xFF0B3D91);
    expect(
      tester.widgetList<CustomPaint>(find.byType(CustomPaint)).where(youthMark),
      isEmpty,
    );
    expect(TaytayIcons.usersRound.codePoint, 58478);
    expect(_tileIcon(tester, 'youth').icon, TaytayIcons.usersRound);

    await tester.pumpWidget(
      const MaterialApp(
        home: TulongCanvas(
          frame: TulongFrame.detail,
          service: SocialService(
            id: '11111111-1111-4111-8111-111111111108',
            name: 'Youth Programmes',
            slug: 'youth',
            summary: 'Youth groups',
            details: 'Synthetic details.',
            iconKey: 'usersRound',
            tileColor: 0xFF0B3D91,
          ),
        ),
      ),
    );
    final Iterable<double> youthSizes = tester
        .widgetList<TaytayIcon>(find.byType(TaytayIcon))
        .where((TaytayIcon icon) => icon.icon == TaytayIcons.usersRound)
        .map((TaytayIcon icon) => icon.size);
    expect(youthSizes, contains(IconTileSize.large.glyphSize));
  });

  testWidgets(
    'the old service route lands on the Tulong page and has no apply control',
    (WidgetTester tester) async {
      await _boot(tester, location: '/services/pwd-assistance');
      expect(
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).routerDelegate.currentConfiguration.uri.path,
        '/programs/pwd-assistance',
      );
      expect(find.text('PWD Assistance'), findsWidgets);
      expect(find.text('Who can avail'), findsOneWidget);
      expect(find.text('Apply for this service'), findsNothing);
      expect(find.textContaining('Apply'), findsNothing);
      expect(find.textContaining('Submit'), findsNothing);
    },
  );

  testWidgets(
    'the old apply route lands on the PWD page and has no apply control',
    (WidgetTester tester) async {
      await _boot(tester, location: '/apply/pwd-assistance');
      expect(
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).routerDelegate.currentConfiguration.uri.path,
        '/programs/pwd-assistance',
      );
      expect(find.text('PWD Assistance'), findsWidgets);
      expect(find.text('Who can avail'), findsOneWidget);
      expect(find.text('Apply for this service'), findsNothing);
      expect(find.text('How to apply'), findsNothing);
      expect(find.textContaining('Apply'), findsNothing);
      expect(find.textContaining('Submit'), findsNothing);
    },
  );

  test('Tulong does not nudge lines with a translation', () {
    final Directory root = Directory('lib/features/tulong');
    final Iterable<File> sources = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'));
    for (final File file in sources) {
      expect(file.readAsStringSync().contains('Transform.translate'), isFalse);
    }
  });

  testWidgets('a guest reads every listed programme and cannot apply', (
    WidgetTester tester,
  ) async {
    await _boot(tester);
    expect(find.text('PWD Assistance'), findsOneWidget);
    expect(find.text('Senior Citizens (OSCA)'), findsOneWidget);
    expect(find.text('Solo Parents'), findsOneWidget);
    expect(find.text('Crisis Assistance (AICS)'), findsOneWidget);
    expect(find.text('Educational Assistance'), findsOneWidget);
    expect(find.text('Women & Children'), findsOneWidget);
    expect(find.text('Jobs & Employment (PESO)'), findsOneWidget);
    expect(find.text('Youth Programmes (TYDO)'), findsOneWidget);
    expect(find.text('2026 PWD Cash Gift'), findsNothing);
    expect(find.textContaining('Apply'), findsNothing);
    expect(find.textContaining('Submit'), findsNothing);
    expect(find.text('How to apply'), findsNothing);

    expect(
      tester.getSize(find.byKey(const Key('tulong-search'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('tulong-open-pwd-assistance')))
          .height,
      greaterThanOrEqualTo(48),
    );
    final Iterable<Icon> icons = tester.widgetList<Icon>(find.byType(Icon));
    expect(icons, isNotEmpty);
    for (final Icon icon in icons) {
      expect(icon.icon?.fontFamily, 'Lucide');
    }
  });

  testWidgets('a service page has a 48 dp back button and no application', (
    WidgetTester tester,
  ) async {
    await _boot(tester, location: '/programs/aics');
    expect(find.text('Who can avail'), findsOneWidget);
    expect(find.text('How to apply'), findsNothing);
    expect(find.textContaining('Apply'), findsNothing);
    // Phrases, not words: published eligibility copy may contain "qualify"
    // without promising a decision.
    for (final String phrase in <String>[
      'you qualify for',
      'you are eligible',
      'you will receive',
      'has been approved',
      'guaranteed',
    ]) {
      expect(find.textContaining(phrase), findsNothing);
    }
    final Size back = tester.getSize(find.byType(TaytayBackButton));
    expect(back.width, greaterThanOrEqualTo(48));
    expect(back.height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byKey(const Key('tulong-call'))).height, 48);
    expect(
      tester.getSize(find.byKey(const Key('tulong-directions'))).height,
      48,
    );
    expect(tester.getSize(find.byKey(const Key('tulong-message'))).height, 48);
  });

  testWidgets('the featured programme is information, reached by its slug', (
    WidgetTester tester,
  ) async {
    await _boot(tester, location: '/programs/pwd-cash-gift');
    expect(find.text('How to claim'), findsOneWidget);
    expect(find.textContaining('Apply'), findsNothing);
    expect(find.byType(TaytayBackButton), findsOneWidget);
  });

  testWidgets('a guest Message goes to sign-in', (WidgetTester tester) async {
    await _boot(tester, location: '/programs/pwd-assistance');
    await tester.tap(find.byKey(const Key('tulong-message')));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('New message'), findsNothing);
  });

  testWidgets('an unverified Message opens the verification gate', (
    WidgetTester tester,
  ) async {
    await _boot(
      tester,
      level: AccessLevel.unverified,
      location: '/programs/pwd-assistance',
    );
    await tester.tap(find.byKey(const Key('tulong-message')));
    await tester.pumpAndSettle();
    expect(find.text('Verify your account to message offices'), findsOneWidget);
    expect(find.text('New message'), findsNothing);
  });

  testWidgets('a verified resident opens the office composer', (
    WidgetTester tester,
  ) async {
    await _boot(
      tester,
      level: AccessLevel.verified,
      location: '/programs/pwd-assistance',
    );
    await tester.tap(find.byKey(const Key('tulong-message')));
    await tester.pumpAndSettle();
    expect(find.text('New message'), findsOneWidget);
    expect(find.byKey(const Key('directory-message-field')), findsOneWidget);
    expect(find.text('Sign in to continue'), findsNothing);
    expect(find.text('Verify your account to message offices'), findsNothing);
  });
}

/// The Lucide glyph inside a service's gradient tile.
TaytayIcon _tileIcon(WidgetTester tester, String slug) {
  return tester.widget<TaytayIcon>(
    find.descendant(
      of: find.byKey(Key('tulong-tile-$slug')),
      matching: find.byType(TaytayIcon),
    ),
  );
}
