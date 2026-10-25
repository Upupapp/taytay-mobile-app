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
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/sharing/share_service.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/directory/data/office_api_repository.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/mock_data/data/mock/taytay_mocks.dart';
import 'package:taytay_resident/features/news/data/newsfeed_api_repository.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> _offices() => _ok(<Object?>[
  <String, String>{
    'id': '22222222-2222-4222-8222-222222222222',
    'name': 'MSWDO',
    'slug': 'mswdo',
  },
]);

Result<ApiHttpResponse> _ok(Object? data) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{
      'data': data,
      'meta': <String, Object?>{
        'request_id': 'req-news',
        'pagination': <String, Object?>{'has_more': false},
      },
    }),
    headers: const <String, String>{'x-request-id': 'req-news'},
  ),
);

ApiClient _client(_Scripted transport, {String? token = 'tok'}) => ApiClient(
  config: AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  ),
  transport: transport,
  accessTokenProvider: () async => token,
);

Map<String, Object?> _item({String status = 'published'}) => <String, Object?>{
  'id': '11111111-1111-4111-8111-111111111111',
  'title': 'Hall notice',
  'body': 'Bring a valid ID.',
  'office_id': '22222222-2222-4222-8222-222222222222',
  'office_slug': 'mswdo',
  'status': status,
  'author_id': '33333333-3333-4333-8333-333333333333',
  'created_at': '2026-07-01T00:00:00Z',
  'updated_at': '2026-07-02T00:00:00Z',
  'cover_media_id': '44444444-4444-4444-8444-444444444444',
  'category': 'Abiso',
  'published_at': '2026-07-15T02:00:00Z',
};

Announcement _story({String? shareUrl, String? author}) => Announcement(
  id: 'post-1',
  title: 'Barangay clean-up drive',
  body: 'Volunteers are welcome at the covered court on Saturday.',
  summary: 'Saturday at the covered court.',
  author: author ?? 'Taytay Public Information Office',
  category: 'Community',
  publishedAt: DateTime.utc(2026, 8, 10),
  shareUrl: shareUrl,
  publicationState: const ServerValue<PublicationState>(
    raw: 'published',
    known: PublicationState.published,
  ),
);

class _Pages implements AnnouncementRepository {
  _Pages(this.posts);

  final List<Announcement> posts;
  final List<String?> categories = <String?>[];

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
    String? category,
  }) async {
    categories.add(category);
    return Ok<Paginated<Announcement>>(Paginated<Announcement>.single(posts));
  }

  @override
  Future<Result<List<NewsCategory>>> listCategories() async =>
      const Ok<List<NewsCategory>>(NewsCategory.catalogue);

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      const Err<Announcement>(NotFoundFailure());

  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<PostComment>>(ServerFailure());

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(ServerFailure());

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(ServerFailure());

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) async => const Err<PostComment>(ServerFailure());

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required ReportReason reason,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

class _RecordingShare implements ShareService {
  ShareOutcome outcome = ShareOutcome.shared;
  final List<ShareableContent> shared = <ShareableContent>[];

  @override
  Future<ShareOutcome> share(ShareableContent content) async {
    shared.add(content);
    return outcome;
  }
}

Future<void> _boot(
  WidgetTester tester, {
  required AnnouncementRepository repository,
  ShareService? shareService,
}) async {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
    shareService: shareService,
  );
  final AppDependencies dependencies = AppDependencies(
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
    announcementRepository: repository,
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
  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/news');
  await tester.pumpAndSettle();
}

void _expectAtLeast48(WidgetTester tester, Key key) {
  final Finder marked = find.byKey(key);
  expect(marked, findsOneWidget, reason: '$key is missing');
  final Size size = tester.getSize(marked);
  expect(size.width, greaterThanOrEqualTo(A11y.minTapTarget), reason: '$key');
  expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget), reason: '$key');
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('news presentation does not use Transform.translate', () {
    final Directory root = Directory('lib/features/news');
    for (final FileSystemEntity entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      expect(
        entity.readAsStringSync(),
        isNot(contains('Transform.translate')),
        reason: entity.path,
      );
    }
  });

  test('GET /news reads the published item and hides a draft', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[_item()]),
      _offices(),
    ]);
    final Result<Paginated<Announcement>> listed = await NewsfeedApiRepository(
      apiClient: _client(transport),
    ).listAnnouncements();
    final Announcement post =
        (listed as Ok<Paginated<Announcement>>).value.items.single;

    expect(transport.requests.first.path, 'news');
    expect(transport.requests.first.query.containsKey('category'), isFalse);
    expect(transport.requests.first.query.containsKey('cursor'), isFalse);
    expect(post.officeSlug, 'mswdo');
    expect(post.coverMediaId, '44444444-4444-4444-8444-444444444444');
    expect(post.category, 'Abiso');
    expect(post.publishedAt, DateTime.utc(2026, 7, 15, 2));
    expect(post.shareUrl, isNull);
    expect(post.presentation, isNull);
    expect(post.isResidentVisible, isTrue);

    final _Scripted detail = _Scripted(<Result<ApiHttpResponse>>[
      _ok(_item(status: 'draft')),
      _offices(),
    ]);
    final Result<Announcement> loaded = await NewsfeedApiRepository(
      apiClient: _client(detail),
    ).loadAnnouncement(post.id);
    final Announcement draft = (loaded as Ok<Announcement>).value;

    expect(detail.requests.first.path, 'news/${post.id}');
    expect(draft.publicationState?.known, PublicationState.draft);
    expect(draft.isResidentVisible, isFalse);
  });

  test('a chip is the category query and Lahat sends none', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[]),
      _ok(<Object?>[]),
    ]);
    final NewsfeedApiRepository repository = NewsfeedApiRepository(
      apiClient: _client(transport),
    );

    await repository.listAnnouncements(category: 'advisory');
    await repository.listAnnouncements(category: 'Lahat');

    expect(transport.requests.first.query['category'], 'advisory');
    expect(transport.requests.last.query.containsKey('category'), isFalse);
    expect(
      transport.requests.every(
        (ApiRequest request) => request.headers.values.every(
          (String value) => !value.contains('http'),
        ),
      ),
      isTrue,
    );
  });

  test('a guest read stays anonymous and a session sends its token', () async {
    final _Scripted guest = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[]),
    ]);
    await NewsfeedApiRepository(
      apiClient: _client(guest, token: null),
    ).listAnnouncements();
    expect(guest.requests.single.headers['Authorization'], isNull);

    final _Scripted signedIn = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[]),
    ]);
    await NewsfeedApiRepository(
      apiClient: _client(signedIn),
    ).listAnnouncements();
    expect(signedIn.requests.single.headers['Authorization'], contains('tok'));
  });

  test('loadAnnouncement calls news/{id}', () async {
    const String id = '11111111-1111-4111-8111-111111111111';
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(_item()),
      _offices(),
    ]);
    final Result<Announcement> loaded = await NewsfeedApiRepository(
      apiClient: _client(transport),
    ).loadAnnouncement(id);

    expect(loaded.isOk, isTrue);
    expect(transport.requests.first.path, 'news/$id');
    expect(transport.requests.first.method, HttpMethod.get);
  });

  test('cover_url, share_url and pinned come from the item', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[
        <String, Object?>{
          ..._item(),
          'cover_url': 'https://example.test/covers/pwd.jpg',
          'share_url': 'https://example.test/news/pwd',
          'pinned': true,
          'pinned_at': '2026-07-20T01:00:00Z',
        },
        <String, Object?>{
          ..._item(),
          'id': '22222222-2222-4222-8222-222222222222',
          'pinned': false,
          'share_url': 'https://example.test/news/other',
          'cover_url': null,
        },
      ]),
      _offices(),
    ]);
    final Result<Paginated<Announcement>> listed = await NewsfeedApiRepository(
      apiClient: _client(transport),
    ).listAnnouncements();
    final List<Announcement> items =
        (listed as Ok<Paginated<Announcement>>).value.items;

    expect(items.first.coverUrl, 'https://example.test/covers/pwd.jpg');
    expect(items.first.shareUrl, 'https://example.test/news/pwd');
    expect(items.first.isPinned, isTrue);
    expect(items.first.pinnedAt, DateTime.utc(2026, 7, 20, 1));
    expect(items.last.coverUrl, isNull);
    expect(items.last.isPinned, isFalse);
    // The repository keeps the server's order. The feed lifts pinned items.
    expect(items.map((Announcement item) => item.isPinned), <bool>[
      true,
      false,
    ]);
  });

  test('GET /news/categories returns slug and label', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[
        <String, String>{'slug': 'advisory', 'label': 'Advisory'},
        <String, String>{'slug': 'events', 'label': 'Events'},
      ]),
    ]);
    final Result<List<NewsCategory>> result = await NewsfeedApiRepository(
      apiClient: _client(transport),
    ).listCategories();

    expect(transport.requests.single.path, 'news/categories');
    final List<NewsCategory> categories =
        (result as Ok<List<NewsCategory>>).value;
    expect(categories.map((NewsCategory item) => item.slug), <String>[
      'advisory',
      'events',
    ]);
    expect(categories.first.label, 'Advisory');
  });

  test(
    'office_slug resolves to the office name and then stays cached',
    () async {
      final Map<String, Object?> article = _item();
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(<Object?>[article]),
        _offices(),
        _ok(<Object?>[article]),
      ]);
      final NewsfeedApiRepository repository = NewsfeedApiRepository(
        apiClient: _client(transport),
      );

      final Announcement first =
          ((await repository.listAnnouncements())
                  as Ok<Paginated<Announcement>>)
              .value
              .items
              .single;
      final Announcement second =
          ((await repository.listAnnouncements())
                  as Ok<Paginated<Announcement>>)
              .value
              .items
              .single;

      expect(first.author, 'MSWDO');
      expect(first.officeSlug, 'mswdo');
      expect(second.author, 'MSWDO');
      expect(
        transport.requests.map((ApiRequest request) => request.path),
        <String>['news', 'offices', 'news'],
      );
    },
  );

  test('office_slug prefers short_name, then name', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[_item()]),
      _ok(<Object?>[
        <String, String>{
          'id': '22222222-2222-4222-8222-222222222222',
          'slug': 'mswdo',
          'short_name': 'MSWDO',
          'name': 'Municipal Social Welfare and Development Office of Taytay',
        },
      ]),
    ]);
    final Announcement article =
        ((await NewsfeedApiRepository(
                  apiClient: _client(transport),
                ).listAnnouncements())
                as Ok<Paginated<Announcement>>)
            .value
            .items
            .single;

    expect(article.author, 'MSWDO');
  });

  test('a null short_name falls back to the office name', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[_item()]),
      _ok(<Object?>[
        <String, Object?>{
          'id': '22222222-2222-4222-8222-222222222222',
          'slug': 'mswdo',
          'short_name': null,
          'name': 'Municipal Social Welfare and Development Office of Taytay',
        },
      ]),
    ]);
    final Announcement article =
        ((await NewsfeedApiRepository(
                  apiClient: _client(transport),
                ).listAnnouncements())
                as Ok<Paginated<Announcement>>)
            .value
            .items
            .single;

    expect(
      article.author,
      'Municipal Social Welfare and Development Office of Taytay',
    );
  });

  test('GET /offices/{slug} reads short_name', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<String, Object?>{
        'id': '22222222-2222-4222-8222-222222222222',
        'slug': 'health',
        'name': 'Municipal Health Office',
        'short_name': 'MHO',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      }),
      _ok(<String, Object?>{
        'id': '55555555-5555-4555-8555-555555555555',
        'slug': 'assessor',
        'name': "Municipal Assessor's Office",
        'short_name': null,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      }),
    ]);
    final OfficeApiRepository repository = OfficeApiRepository(
      apiClient: _client(transport),
    );

    final Office health =
        ((await repository.bySlug('health')) as Ok<Office?>).value!;
    final Office assessor =
        ((await repository.bySlug('assessor')) as Ok<Office?>).value!;

    expect(
      transport.requests.map((ApiRequest request) => request.path),
      <String>['offices/health', 'offices/assessor'],
    );
    expect(health.shortName, 'MHO');
    expect(health.name, 'Municipal Health Office');
    expect(assessor.shortName, "Municipal Assessor's Office");
    expect(assessor.id, 'assessor');
  });

  test('the dev mock byline uses the office short name', () async {
    final MockAnnouncementRepository repository = MockAnnouncementRepository(
      MockBehaviorController(
        latency: Duration.zero,
        failure: MockFailureMode.none,
      ),
    );
    final List<Announcement> items =
        ((await repository.listAnnouncements()) as Ok<Paginated<Announcement>>)
            .value
            .items;

    expect(
      items.map((Announcement item) => item.author),
      containsAll(<String>['MSWDO', 'Treasury Office', 'BPLO', 'PIO']),
    );
  });

  test('a failed offices read is retried on the next list', () async {
    final Map<String, Object?> article = _item();
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[article]),
      const Err<ApiHttpResponse>(NetworkFailure()),
      _ok(<Object?>[article]),
      _ok(<Object?>[
        <String, String>{
          'id': '22222222-2222-4222-8222-222222222222',
          'slug': 'mswdo',
          'name': 'Municipal Social Welfare and Development Office of Taytay',
        },
      ]),
    ]);
    final NewsfeedApiRepository repository = NewsfeedApiRepository(
      apiClient: _client(transport),
    );

    final Announcement first =
        ((await repository.listAnnouncements()) as Ok<Paginated<Announcement>>)
            .value
            .items
            .single;
    final Announcement second =
        ((await repository.listAnnouncements()) as Ok<Paginated<Announcement>>)
            .value
            .items
            .single;

    expect(first.author, isNull);
    expect(first.officeSlug, 'mswdo');
    expect(
      second.author,
      'Municipal Social Welfare and Development Office of Taytay',
    );
    expect(
      transport.requests.map((ApiRequest request) => request.path),
      <String>['news', 'offices', 'news', 'offices'],
    );
  });

  test('an unknown office keeps the slug for the card', () async {
    final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[_item()]),
      _ok(<Object?>[]),
    ]);
    final Announcement article =
        ((await NewsfeedApiRepository(
                  apiClient: _client(transport),
                ).listAnnouncements())
                as Ok<Paginated<Announcement>>)
            .value
            .items
            .single;

    expect(article.author, isNull);
    expect(article.officeSlug, 'mswdo');
  });

  testWidgets('a long office name stays on one line', (tester) async {
    const String office =
        'Municipal Social Welfare and Development Office of Taytay';
    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.feed,
        articles: <Announcement>[_story(author: office)],
      ),
    );

    final RichText byline = tester.widget<RichText>(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText && widget.text.toPlainText().contains(office),
      ),
    );
    expect(byline.maxLines, 1);
    expect(byline.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byWidget(byline)).height, lessThanOrEqualTo(20));
  });

  testWidgets('bell, save, share, card, back and see-all are 48 dp', (
    tester,
  ) async {
    final Announcement story = _story();
    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.feed,
        articles: <Announcement>[story],
        onSave: (_) {},
        onShare: (_) {},
        onArticle: (_) {},
        onBell: () {},
      ),
    );
    _expectAtLeast48(tester, const Key('balita-bell'));
    _expectAtLeast48(tester, Key('balita-save-${story.id}'));
    _expectAtLeast48(tester, Key('balita-share-${story.id}'));
    _expectAtLeast48(tester, Key('balita-article-${story.id}'));
    final Iterable<Icon> icons = tester.widgetList<Icon>(find.byType(Icon));
    expect(icons, isNotEmpty);
    expect(
      icons.every((Icon icon) => icon.icon?.fontFamily == 'Lucide'),
      isTrue,
    );
    expect(
      tester
          .widgetList<TaytayIcon>(find.byType(TaytayIcon))
          .map((TaytayIcon icon) => icon.icon),
      containsAll(<IconData>[TaytayIcons.bookmark, TaytayIcons.share]),
    );

    await _pump(
      tester,
      BalitaCanvas(frame: BalitaFrame.article, article: story),
    );
    expect(tester.getSize(find.byType(TaytayBackButton)), const Size(48, 48));

    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.emptyCategory,
        selectedChip: 'Events',
        onSeeAll: () {},
      ),
    );
    _expectAtLeast48(tester, const Key('balita-see-all'));
  });

  testWidgets('save tells the resident, and share does not invent a url', (
    tester,
  ) async {
    final _RecordingShare sharing = _RecordingShare();
    await _boot(
      tester,
      repository: _Pages(<Announcement>[_story()]),
      shareService: sharing,
    );

    await tester.tap(find.byKey(const Key('balita-save-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('Saving a story is not available yet.'), findsOneWidget);
    expect(find.textContaining('F32'), findsNothing);

    await tester.tap(find.byKey(const Key('balita-share-post-1')));
    await tester.pumpAndSettle();
    final ShareableContent shared = sharing.shared.single;
    expect(shared.url, isNull);
    expect(shared.text, isNot(contains('http')));
    expect(shared.text, contains('Taytay LGU'));

    await tester.tap(find.byKey(const Key('balita-article-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('Saving a story is not available yet.'), findsNothing);
  });

  testWidgets('saving a story clears when the resident leaves Balita', (
    tester,
  ) async {
    await _boot(tester, repository: _Pages(<Announcement>[_story()]));
    await tester.tap(find.byKey(const Key('balita-save-post-1')));
    await tester.pumpAndSettle();
    expect(find.text('Saving a story is not available yet.'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle();
    expect(find.text('Saving a story is not available yet.'), findsNothing);
  });

  testWidgets('an Advisory chip is sent as the lowercase slug', (tester) async {
    final _Pages pages = _Pages(<Announcement>[_story()]);
    await _boot(tester, repository: pages);

    await tester.tap(find.byKey(const Key('balita-chip-Advisory')));
    await tester.pumpAndSettle();

    expect(pages.categories, contains('advisory'));
    expect(pages.categories, isNot(contains('Advisory')));
  });

  testWidgets('share passes the server url through when one was sent', (
    tester,
  ) async {
    final _RecordingShare sharing = _RecordingShare();
    await _boot(
      tester,
      repository: _Pages(<Announcement>[
        _story(shareUrl: 'https://example.test/news/post-1'),
      ]),
      shareService: sharing,
    );

    await tester.tap(find.byKey(const Key('balita-share-post-1')));
    await tester.pumpAndSettle();
    expect(sharing.shared.single.url, 'https://example.test/news/post-1');
    expect(
      sharing.shared.single.text,
      contains('https://example.test/news/post-1'),
    );
  });
}
