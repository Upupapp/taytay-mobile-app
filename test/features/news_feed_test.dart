import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/news/data/planned_announcement_repository.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/news_feed_controller.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real Taytay advisory is reproduced here.

ServerValue<PublicationState> publication(PublicationState value) =>
    ServerValue<PublicationState>(raw: value.wireValue, known: value);

ServerValue<AdvisoryLevel> advisory(AdvisoryLevel value) =>
    ServerValue<AdvisoryLevel>(raw: value.wireValue, known: value);

Announcement post({
  String id = 'post-1',
  String title = 'Barangay clean-up drive',
  String body = 'Volunteers are welcome at the covered court on Saturday.',
  String? summary,
  String? author = 'Taytay Public Information Office',
  String? category = 'Community',
  DateTime? publishedAt,
  bool isPinned = false,
  ServerValue<AdvisoryLevel>? advisoryLevel,
  ServerValue<PublicationState>? publicationState,
  AnnouncementMedia? media,
  AnnouncementEngagement? engagement,
}) => Announcement(
  id: id,
  title: title,
  body: body,
  summary: summary,
  author: author,
  category: category,
  publishedAt: publishedAt ?? DateTime.utc(2026, 8, 10),
  isPinned: isPinned,
  advisoryLevel: advisoryLevel,
  publicationState: publicationState ?? publication(PublicationState.published),
  media: media,
  engagement: engagement,
);

Paginated<Announcement> pageOf(
  List<Announcement> items, {
  int page = 1,
  bool hasMore = false,
}) => Paginated<Announcement>(
  items: items,
  page: page,
  perPage: 20,
  total: items.length,
  totalPages: hasMore ? page + 1 : page,
  hasMore: hasMore,
);

/// Serves scripted pages, and can be told to fail on a chosen page.
class ScriptedAnnouncementRepository implements AnnouncementRepository {
  ScriptedAnnouncementRepository({this.pages = const <int, dynamic>{}});

  /// page number → `Paginated<Announcement>` or `AppFailure`.
  Map<int, dynamic> pages;

  final List<int> requestedPages = <int>[];

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async {
    requestedPages.add(page);
    final scripted = pages[page];
    if (scripted is Paginated<Announcement>) {
      return Ok<Paginated<Announcement>>(scripted);
    }
    if (scripted is AppFailure) {
      return Err<Paginated<Announcement>>(scripted);
    }
    return const Err<Paginated<Announcement>>(ServerFailure(isTemporary: true));
  }

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      const Err<Announcement>(NotFoundFailure());

  // The feed never interacts with a post — TAB 20's detail screen does. These
  // decline so a stray call in a feed test would fail loudly.
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
    required String reason,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

Future<void> bootNews(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  required AnnouncementRepository repository,
  Size size = const Size(400, 3000),
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

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
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

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/news');
  await tester.pumpAndSettle();
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('what a resident may see — acceptance 1', () {
    test('a published post is visible', () {
      expect(post().isResidentVisible, isTrue);
    });

    test('a draft, scheduled or archived post is not', () {
      for (final state in <PublicationState>[
        PublicationState.draft,
        PublicationState.scheduled,
        PublicationState.archived,
      ]) {
        expect(
          post(publicationState: publication(state)).isResidentVisible,
          isFalse,
          reason: 'A withdrawn advisory shown as current is worse than a gap.',
        );
      }
    });

    test('an unrecognised state is shown, not hidden', () {
      // The opposite default to an action guard, and deliberately so: hiding
      // unknown states turns one backend change into a blank feed on every
      // unpatched phone.
      final unknown = post(
        publicationState: const ServerValue<PublicationState>(
          raw: 'republished',
          known: null,
        ),
      );

      expect(unknown.isResidentVisible, isTrue);
    });

    test('a post with no publication state at all is shown', () {
      expect(post(publicationState: null).isResidentVisible, isTrue);
    });
  });

  group('the announcement model', () {
    test('the preview falls back to the body rather than truncating it', () {
      expect(post(summary: null).preview, contains('covered court'));
      expect(post(summary: 'Short summary').preview, 'Short summary');
    });

    test('advisory and emergency both count as advisory emphasis', () {
      expect(
        post(advisoryLevel: advisory(AdvisoryLevel.advisory)).isAdvisory,
        isTrue,
      );
      expect(
        post(advisoryLevel: advisory(AdvisoryLevel.emergency)).isAdvisory,
        isTrue,
      );
      expect(
        post(advisoryLevel: advisory(AdvisoryLevel.normal)).isAdvisory,
        isFalse,
      );
      expect(post().isAdvisory, isFalse);
    });

    test('media reports an aspect ratio only when both dimensions arrived', () {
      expect(
        const AnnouncementMedia(url: 'x', width: 1600, height: 900).aspectRatio,
        closeTo(16 / 9, 0.001),
      );
      expect(
        const AnnouncementMedia(url: 'x', width: 1600).aspectRatio,
        isNull,
      );
      expect(
        const AnnouncementMedia(url: 'x', width: 0, height: 0).aspectRatio,
        isNull,
      );
    });

    test('engagement knows when the office sent nothing', () {
      expect(const AnnouncementEngagement().hasAny, isFalse);
      expect(const AnnouncementEngagement(comments: 0).hasAny, isTrue);
    });

    test(
      'the shipped repository declines rather than inventing news',
      () async {
        const repository = PlannedAnnouncementRepository();

        final result = await repository.listAnnouncements();

        expect(result.isErr, isTrue);
      },
    );
  });

  group('the feed controller', () {
    test('non-visible posts never reach the screen', () async {
      final repository = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{
          1: pageOf(<Announcement>[
            post(id: 'a'),
            post(
              id: 'b',
              publicationState: publication(PublicationState.archived),
            ),
          ]),
        },
      );
      final controller = NewsFeedController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.items.map((p) => p.id), <String>['a']);
    });

    test('pinned posts lift to the top, stably', () async {
      final repository = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{
          1: pageOf(<Announcement>[
            post(id: 'a'),
            post(id: 'b', isPinned: true),
            post(id: 'c'),
            post(id: 'd', isPinned: true),
          ]),
        },
      );
      final controller = NewsFeedController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();

      // Pinned first, and within each group the office's own order is kept.
      expect(controller.items.map((p) => p.id), <String>['b', 'd', 'a', 'c']);
    });

    test('load more appends the next page', () async {
      final repository = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{
          1: pageOf(<Announcement>[post(id: 'a')], hasMore: true),
          2: pageOf(<Announcement>[post(id: 'b')], page: 2),
        },
      );
      final controller = NewsFeedController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.items.map((p) => p.id), <String>['a', 'b']);
      expect(controller.hasMore, isFalse);
      expect(repository.requestedPages, <int>[1, 2]);
    });

    test(
      'the end of the feed is the server\'s answer, not a short page',
      () async {
        // One post survives filtering, but the server said there is more.
        final repository = ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(id: 'a'),
              post(
                id: 'b',
                publicationState: publication(PublicationState.draft),
              ),
            ], hasMore: true),
          },
        );
        final controller = NewsFeedController(repository: repository);
        addTearDown(controller.dispose);

        await controller.refresh();

        expect(controller.items.length, 1);
        expect(controller.hasMore, isTrue);
      },
    );

    test('a page failure keeps what the resident was reading', () async {
      final repository = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{
          1: pageOf(<Announcement>[post(id: 'a')], hasMore: true),
          2: const NetworkFailure(),
        },
      );
      final controller = NewsFeedController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.items.map((p) => p.id), <String>['a']);
      expect(controller.pageFailure, isA<NetworkFailure>());
      // Not the whole-screen failure — the feed still has content.
      expect(controller.failure, isNull);
    });

    test('a first-page failure is distinct from an empty feed', () async {
      final failing = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{1: const NetworkFailure()},
      );
      final empty = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{1: pageOf(const <Announcement>[])},
      );

      final a = NewsFeedController(repository: failing);
      final b = NewsFeedController(repository: empty);
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      await a.refresh();
      await b.refresh();

      expect(a.failure, isNotNull);
      expect(a.isEmptyAndHealthy, isFalse);
      expect(b.failure, isNull);
      expect(b.isEmptyAndHealthy, isTrue);
    });

    test('refresh discards the old pages rather than appending', () async {
      final repository = ScriptedAnnouncementRepository(
        pages: <int, dynamic>{
          1: pageOf(<Announcement>[post(id: 'a')]),
        },
      );
      final controller = NewsFeedController(repository: repository);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.refresh();

      expect(controller.items.length, 1);
    });

    test(
      'load more does nothing once the server says there is no more',
      () async {
        final repository = ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post(id: 'a')]),
          },
        );
        final controller = NewsFeedController(repository: repository);
        addTearDown(controller.dispose);

        await controller.refresh();
        await controller.loadMore();

        expect(repository.requestedPages, <int>[1]);
      },
    );
  });

  group('the feed screen', () {
    testWidgets('a guest reads the whole feed without signing in', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post()]),
          },
        ),
      );

      expect(currentLocation(tester), '/news');
      expect(find.text('Barangay clean-up drive'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Create account'), findsNothing);
    });

    testWidgets('a failure and an empty feed say different things', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{1: const NetworkFailure()},
        ),
      );

      expect(
        find.text('Announcements are not available right now'),
        findsOneWidget,
      );
      // Never "Taytay LGU has published nothing" — during an emergency the
      // difference is the whole point.
      expect(find.text('Nothing new right now'), findsNothing);
    });

    testWidgets('an empty feed says so plainly', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{1: pageOf(const <Announcement>[])},
        ),
      );

      expect(find.text('Nothing new right now'), findsOneWidget);
      expect(
        find.text('Announcements are not available right now'),
        findsNothing,
      );
    });

    testWidgets('an emergency advisory is named, not just coloured', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(
                title: 'Classes suspended',
                isPinned: true,
                advisoryLevel: advisory(AdvisoryLevel.emergency),
              ),
            ]),
          },
        ),
      );

      expect(find.text('Emergency advisory'), findsOneWidget);
    });

    testWidgets('a pinned ordinary post is labelled as pinned', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post(isPinned: true)]),
          },
        ),
      );

      expect(find.text('Pinned by Taytay LGU'), findsOneWidget);
    });

    testWidgets('counts appear only when the office published them', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(id: 'a', title: 'With counts'),
              post(id: 'b', title: 'Without counts'),
            ]),
          },
        ),
      );

      // Neither post carries engagement, so the count row is absent entirely.
      // Asserted by icon rather than by scanning for "0", because a legitimate
      // date — "10 Aug 2026" — contains one.
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byIcon(Icons.mode_comment_outlined), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });

    testWidgets('a published count is rendered', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(
                engagement: const AnnouncementEngagement(
                  reactions: 12,
                  comments: 3,
                ),
              ),
            ]),
          },
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('the byline names the office, the category and the date', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post()]),
          },
        ),
      );

      expect(
        find.text('Taytay Public Information Office · Community · 10 Aug 2026'),
        findsOneWidget,
      );
    });

    testWidgets('the end of the feed is stated', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post()]),
          },
        ),
      );

      expect(
        find.text('That is everything Taytay LGU has published here.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping a post opens it', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post()]),
          },
        ),
      );

      await tester.tap(find.text('Barangay clean-up drive'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/news/post-1');
    });

    testWidgets('a broken cover image does not take the post down', (
      tester,
    ) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(
                media: const AnnouncementMedia(
                  url: 'https://example.test/missing.jpg',
                  width: 1600,
                  height: 900,
                ),
              ),
            ]),
          },
        ),
      );

      // The words are the part that matters in an advisory.
      expect(tester.takeException(), isNull);
      expect(find.text('Barangay clean-up drive'), findsOneWidget);
    });

    testWidgets('no publishing control exists anywhere on the feed', (
      tester,
    ) async {
      await bootNews(
        tester,
        level: AccessLevel.verified,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[post(isPinned: true)]),
          },
        ),
      );

      // Scanned for *controls*, not for words: resident copy legitimately says
      // "Taytay LGU has published", and a word-match on "publish" would flag it
      // while catching no actual affordance.
      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'new post',
        'compose',
        'moderate',
        'pin this',
        'archive this',
        'schedule this',
      ]) {
        expect(
          text,
          isNot(contains(forbidden)),
          reason: '"$forbidden" is an admin-console action.',
        );
      }
      expect(find.byType(FloatingActionButton), findsNothing);
      // The only tappable thing on a card is the card itself.
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('the feed survives a 200% text scale', (tester) async {
      await bootNews(
        tester,
        repository: ScriptedAnnouncementRepository(
          pages: <int, dynamic>{
            1: pageOf(<Announcement>[
              post(
                isPinned: true,
                advisoryLevel: advisory(AdvisoryLevel.advisory),
                engagement: const AnnouncementEngagement(reactions: 4),
              ),
            ]),
          },
        ),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 5000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Advisory'), findsOneWidget);
    });
  });
}
