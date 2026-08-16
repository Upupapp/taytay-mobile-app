import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/sharing/share_service.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/news/data/planned_announcement_repository.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/post_detail_controller.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────

ServerValue<ReactionKind> reaction(ReactionKind value) =>
    ServerValue<ReactionKind>(raw: value.wireValue, known: value);

ServerValue<CommentAuthorKind> authorKind(CommentAuthorKind value) =>
    ServerValue<CommentAuthorKind>(raw: value.wireValue, known: value);

const PostCapabilities everything = PostCapabilities(
  canReact: true,
  canComment: true,
  canShare: true,
  canDeleteOwnComment: true,
  canReportComment: true,
);

Announcement post({
  String id = 'post-1',
  PostCapabilities capabilities = everything,
  int? reactions = 5,
  int? comments = 2,
  ServerValue<ReactionKind>? myReaction,
  String? shareUrl,
  List<ServerValue<ReactionKind>>? availableReactions,
}) => Announcement(
  id: id,
  title: 'Classes suspended tomorrow',
  body: 'All public schools in Taytay are closed on Tuesday.',
  author: 'Taytay Public Information Office',
  publishedAt: DateTime.utc(2026, 8, 10),
  engagement: AnnouncementEngagement(reactions: reactions, comments: comments),
  capabilities: capabilities,
  availableReactions:
      availableReactions ??
      <ServerValue<ReactionKind>>[
        reaction(ReactionKind.like),
        reaction(ReactionKind.care),
      ],
  myReaction: myReaction,
  shareUrl: shareUrl,
);

PostComment comment({
  String id = 'c-1',
  String body = 'Thank you for the update.',
  String authorName = 'Ana',
  CommentAuthorKind kind = CommentAuthorKind.resident,
  bool isMine = false,
  String? parentId,
  bool isHidden = false,
}) => PostComment(
  id: id,
  body: body,
  authorName: authorName,
  authorKind: authorKind(kind),
  createdAt: DateTime.utc(2026, 8, 11),
  isMine: isMine,
  parentId: parentId,
  isHiddenByModerator: isHidden,
);

/// Scriptable across every interaction the contract offers.
class ScriptedPostRepository implements AnnouncementRepository {
  ScriptedPostRepository({this.detail, this.comments = const <PostComment>[]});

  Announcement? detail;
  List<PostComment> comments;
  bool commentsHaveMore = false;

  Result<ReactionOutcome>? reactionOutcome;
  Result<PostComment>? addCommentOutcome;
  Result<void> deleteOutcome = const Ok<void>(null);
  Result<void> reportOutcome = const Ok<void>(null);

  final List<String> reactionKeys = <String>[];
  final List<String> commentKeys = <String>[];
  final List<String> reportedReasons = <String>[];
  int setReactionCalls = 0;
  int clearReactionCalls = 0;
  int addCommentCalls = 0;
  int listCommentsCalls = 0;

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async {
    final value = detail;
    return value == null
        ? const Err<Announcement>(NotFoundFailure())
        : Ok<Announcement>(value);
  }

  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 20,
  }) async {
    listCommentsCalls++;
    return Ok<Paginated<PostComment>>(
      Paginated<PostComment>(
        items: comments,
        page: page,
        perPage: perPage,
        total: comments.length,
        totalPages: 1,
        hasMore: commentsHaveMore,
      ),
    );
  }

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async {
    setReactionCalls++;
    reactionKeys.add(idempotencyKey);
    return reactionOutcome ??
        Ok<ReactionOutcome>(
          ReactionOutcome(
            reactions: 6,
            myReaction: ServerValue<ReactionKind>(
              raw: reaction.wireValue,
              known: reaction,
            ),
          ),
        );
  }

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async {
    clearReactionCalls++;
    reactionKeys.add(idempotencyKey);
    return reactionOutcome ??
        const Ok<ReactionOutcome>(ReactionOutcome(reactions: 4));
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) async {
    addCommentCalls++;
    commentKeys.add(idempotencyKey);
    return addCommentOutcome ??
        Ok<PostComment>(comment(id: 'new', body: body, isMine: true));
  }

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async => deleteOutcome;

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String idempotencyKey,
  }) async {
    reportedReasons.add(reason);
    return reportOutcome;
  }

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async => Ok<Paginated<Announcement>>(
    Paginated<Announcement>.single(<Announcement>[?detail]),
  );
}

/// Records what was handed to the OS.
class RecordingShareService implements ShareService {
  RecordingShareService({this.outcome = ShareOutcome.shared});

  ShareOutcome outcome;
  final List<ShareableContent> shared = <ShareableContent>[];

  @override
  Future<ShareOutcome> share(ShareableContent content) async {
    shared.add(content);
    return outcome;
  }
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedPost = ({
  AppDependencies dependencies,
  ScriptedPostRepository posts,
  RecordingShareService sharing,
});

Future<BootedPost> bootPost(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  Announcement? detail,
  List<PostComment> comments = const <PostComment>[],
  AnnouncementRepository? repositoryOverride,
  ShareOutcome shareOutcome = ShareOutcome.shared,
  String location = '/news/post-1',
  Size size = const Size(400, 4000),
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

  final posts = ScriptedPostRepository(detail: detail, comments: comments);
  final sharing = RecordingShareService(outcome: shareOutcome);

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
    shareService: sharing,
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
    announcementRepository: repositoryOverride ?? posts,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: sharing,
    externalLinks: base.externalLinks,
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

  return (dependencies: dependencies, posts: posts, sharing: sharing);
}

PostDetailController controllerFor(ScriptedPostRepository repository) =>
    PostDetailController(repository: repository, postId: 'post-1');

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

void main() {
  group('capabilities gate what is offered', () {
    test('nothing is offered by default', () {
      expect(PostCapabilities.none.canReact, isFalse);
      expect(PostCapabilities.none.canComment, isFalse);
      expect(PostCapabilities.none.canShare, isFalse);
      expect(PostCapabilities.none.canDeleteOwnComment, isFalse);
      expect(PostCapabilities.none.canReportComment, isFalse);
    });

    test('a post with no capabilities refuses every mutation', () async {
      final repository = ScriptedPostRepository(
        detail: post(capabilities: PostCapabilities.none),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);
      final posted = await controller.submitComment('hello');
      final reported = await controller.reportComment('c-1', 'spam');

      expect(repository.setReactionCalls, 0);
      expect(repository.addCommentCalls, 0);
      expect(posted, isFalse);
      expect(reported, isFalse);
      // Comments are not even fetched for a post that does not allow them.
      expect(repository.listCommentsCalls, 0);
    });

    testWidgets('a post with no capabilities shows no controls', (
      tester,
    ) async {
      await bootPost(tester, detail: post(capabilities: PostCapabilities.none));

      expect(find.text('Share'), findsNothing);
      expect(find.text('Post comment'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      // The post itself still reads.
      expect(find.text('Classes suspended tomorrow'), findsOneWidget);
    });

    test('the shipped repository declines every interaction', () async {
      const repository = PlannedAnnouncementRepository();

      expect((await repository.listComments('p')).isErr, isTrue);
      expect(
        (await repository.setReaction(
          postId: 'p',
          reaction: ReactionKind.like,
          idempotencyKey: 'k',
        )).isErr,
        isTrue,
      );
      expect(
        (await repository.addComment(
          postId: 'p',
          body: 'x',
          idempotencyKey: 'k',
        )).isErr,
        isTrue,
      );
    });
  });

  group('reactions reconcile with the server — acceptance 2', () {
    test('the server\'s count replaces the optimistic guess', () async {
      final repository = ScriptedPostRepository(detail: post(reactions: 5));
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);

      // The stub answers 6; the optimistic guess was also 6, but the point is
      // that the value now comes from the server.
      expect(controller.post!.engagement!.reactions, 6);
      expect(controller.myReaction?.known, ReactionKind.like);
    });

    test('a server count that disagrees with the guess still wins', () async {
      final repository = ScriptedPostRepository(detail: post(reactions: 5))
        ..reactionOutcome = Ok<ReactionOutcome>(
          ReactionOutcome(
            reactions: 42,
            myReaction: reaction(ReactionKind.like),
          ),
        );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);

      // Two people reacted at once. The app's arithmetic was wrong; the
      // server's is not.
      expect(controller.post!.engagement!.reactions, 42);
    });

    test('a failure puts back exactly what was there', () async {
      final repository = ScriptedPostRepository(detail: post(reactions: 5))
        ..reactionOutcome = const Err<ReactionOutcome>(NetworkFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);

      expect(controller.post!.engagement!.reactions, 5);
      expect(
        controller.myReaction,
        isNull,
        reason:
            'A reaction that stuck when the server refused it is a lie the '
            'resident cannot see.',
      );
    });

    test('tapping the set reaction again clears it', () async {
      final repository = ScriptedPostRepository(
        detail: post(reactions: 5, myReaction: reaction(ReactionKind.like)),
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);

      expect(repository.clearReactionCalls, 1);
      expect(repository.setReactionCalls, 0);
      expect(controller.myReaction, isNull);
      expect(controller.post!.engagement!.reactions, 4);
    });

    test(
      'switching reactions does not change the total optimistically',
      () async {
        final repository =
            ScriptedPostRepository(
                detail: post(
                  reactions: 5,
                  myReaction: reaction(ReactionKind.like),
                ),
              )
              ..reactionOutcome = Ok<ReactionOutcome>(
                ReactionOutcome(
                  reactions: 5,
                  myReaction: reaction(ReactionKind.care),
                ),
              );
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);
        await controller.load();

        await controller.toggleReaction(ReactionKind.care);

        expect(controller.post!.engagement!.reactions, 5);
        expect(controller.myReaction?.known, ReactionKind.care);
      },
    );

    test('an absent count is not invented by reacting', () async {
      final repository = ScriptedPostRepository(detail: post(reactions: null))
        ..reactionOutcome = Ok<ReactionOutcome>(
          ReactionOutcome(
            reactions: 1,
            myReaction: reaction(ReactionKind.like),
          ),
        );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // Mid-flight there is still no number to show; only the server's answer
      // introduces one.
      await controller.toggleReaction(ReactionKind.like);
      expect(controller.post!.engagement!.reactions, 1);
    });

    test('each reaction attempt carries an idempotency key', () async {
      final repository = ScriptedPostRepository(detail: post());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.toggleReaction(ReactionKind.like);

      expect(repository.reactionKeys.single, isNotEmpty);
    });
  });

  group('comments', () {
    test('a failed comment keeps its key so a retry replays', () async {
      final repository = ScriptedPostRepository(detail: post())
        ..addCommentOutcome = const Err<PostComment>(TimeoutFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      await controller.submitComment('Salamat po');
      await controller.submitComment('Salamat po');

      expect(repository.addCommentCalls, 2);
      expect(
        repository.commentKeys.first,
        repository.commentKeys.last,
        reason: 'A retry must not post the same paragraph twice.',
      );
      expect(controller.postingState, CommentPostingState.failed);
    });

    test('a successful comment retires the key and appends', () async {
      final repository = ScriptedPostRepository(detail: post(comments: 2));
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      final posted = await controller.submitComment('Salamat po');

      expect(posted, isTrue);
      expect(controller.comments.last.body, 'Salamat po');
      expect(controller.postingState, CommentPostingState.idle);
      // The visible count moved with it.
      expect(controller.post!.engagement!.comments, 3);

      await controller.submitComment('Another');
      expect(repository.commentKeys.first, isNot(repository.commentKeys.last));
    });

    test('an empty comment is not sent', () async {
      final repository = ScriptedPostRepository(detail: post());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      expect(await controller.submitComment('   '), isFalse);
      expect(repository.addCommentCalls, 0);
    });

    test('deleting own comment restores it when the server refuses', () async {
      final repository = ScriptedPostRepository(
        detail: post(comments: 1),
        comments: <PostComment>[comment(isMine: true)],
      )..deleteOutcome = const Err<void>(NetworkFailure());
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      final deleted = await controller.deleteOwnComment('c-1');

      expect(deleted, isFalse);
      expect(controller.comments.length, 1);
      expect(controller.post!.engagement!.comments, 1);
    });

    test('a comment that is not mine cannot be deleted', () async {
      final repository = ScriptedPostRepository(
        detail: post(),
        comments: <PostComment>[comment()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // Guarded in the controller as well as the screen: deleting somebody
      // else's words is not a resident act.
      expect(await controller.deleteOwnComment('c-1'), isFalse);
      expect(controller.comments.length, 1);
    });

    test('a hidden comment is kept and marked, never dropped', () async {
      final repository = ScriptedPostRepository(
        detail: post(),
        comments: <PostComment>[comment(isHidden: true)],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // Dropping it would leave a reply pointing at nothing, and would hide
      // from a resident that their own comment was moderated.
      expect(controller.comments.single.isHiddenByModerator, isTrue);
    });

    test('reporting asks; it does not act', () async {
      final repository = ScriptedPostRepository(
        detail: post(),
        comments: <PostComment>[comment()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      final reported = await controller.reportComment('c-1', 'spam');

      expect(reported, isTrue);
      expect(repository.reportedReasons.single, 'spam');
      // The comment is untouched: acting on the report is the office's job.
      expect(controller.comments.length, 1);
    });
  });

  group('guest gating preserves the action — acceptance 3', () {
    testWidgets('a guest tapping a reaction meets the gate', (tester) async {
      final booted = await bootPost(
        tester,
        level: AccessLevel.guest,
        detail: post(),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Like'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        booted.dependencies.intents.pending?.kind,
        ResidentIntentKind.likePost,
      );
      // And the gate did not act on their behalf.
      expect(booted.posts.setReactionCalls, 0);
    });

    testWidgets('a guest tapping post-comment meets the gate', (tester) async {
      final booted = await bootPost(
        tester,
        level: AccessLevel.guest,
        detail: post(),
      );

      await tester.enterText(find.byType(TextField), 'Salamat');
      await tester.tap(find.text('Post comment'));
      await tester.pumpAndSettle();

      expect(
        booted.dependencies.intents.pending?.kind,
        ResidentIntentKind.commentOnPost,
      );
      expect(booted.posts.addCommentCalls, 0);
    });

    testWidgets('a guest still reads the post and its comments', (
      tester,
    ) async {
      await bootPost(
        tester,
        level: AccessLevel.guest,
        detail: post(),
        comments: <PostComment>[comment(body: 'Thanks for posting.')],
      );

      expect(find.text('Classes suspended tomorrow'), findsOneWidget);
      expect(find.text('Thanks for posting.'), findsOneWidget);
    });
  });

  group('sharing', () {
    testWidgets('shares the server\'s link when there is one', (tester) async {
      final booted = await bootPost(
        tester,
        detail: post(shareUrl: 'https://example.test/news/post-1'),
      );

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      final shared = booted.sharing.shared.single;
      expect(shared.url, 'https://example.test/news/post-1');
      expect(shared.text, contains('https://example.test/news/post-1'));
    });

    testWidgets('never invents a link when the server sent none', (
      tester,
    ) async {
      final booted = await bootPost(tester, detail: post());

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      final shared = booted.sharing.shared.single;
      expect(shared.url, isNull);
      // A fabricated link in a shared advisory sends people to a 404, or to a
      // domain somebody else owns.
      expect(shared.text, isNot(contains('http')));
      expect(shared.text, contains('Taytay LGU'));
    });

    testWidgets('a clipboard fallback tells the resident what happened', (
      tester,
    ) async {
      await bootPost(
        tester,
        detail: post(),
        shareOutcome: ShareOutcome.copiedToClipboard,
      );

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Copied'), findsOneWidget);
    });

    testWidgets('dismissing the share sheet says nothing', (tester) async {
      await bootPost(
        tester,
        detail: post(),
        shareOutcome: ShareOutcome.dismissed,
      );

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      // Backing out is a choice, not a failure.
      expect(find.byType(SnackBar), findsNothing);
    });

    test('shareable content carries no personal data by construction', () {
      const content = ShareableContent(title: 'T', body: 'B');
      expect(content.toString(), isNot(contains('B')));
    });
  });

  group('the detail screen', () {
    testWidgets(
      'an official reply is distinguished by word, not colour alone',
      (tester) async {
        await bootPost(
          tester,
          detail: post(),
          comments: <PostComment>[
            comment(
              id: 'c-2',
              authorName: 'Taytay Public Information Office',
              kind: CommentAuthorKind.official,
              body: 'Classes resume on Wednesday.',
            ),
          ],
        );

        expect(find.text('Taytay LGU'), findsOneWidget);
        expect(find.text('Classes resume on Wednesday.'), findsOneWidget);
      },
    );

    testWidgets('a hidden comment renders as withheld', (tester) async {
      await bootPost(
        tester,
        detail: post(),
        comments: <PostComment>[comment(isHidden: true, body: 'secret')],
      );

      expect(
        find.text('This comment was removed by Taytay LGU.'),
        findsOneWidget,
      );
      expect(find.text('secret'), findsNothing);
    });

    testWidgets('an unrecognised reaction is shown but cannot be pressed', (
      tester,
    ) async {
      await bootPost(
        tester,
        detail: post(
          availableReactions: <ServerValue<ReactionKind>>[
            const ServerValue<ReactionKind>(raw: 'applaud', known: null),
          ],
        ),
      );

      expect(find.text('applaud'), findsOneWidget);
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(
        chip.onSelected,
        isNull,
        reason:
            'Sending a value the app does not understand is worse than '
            'showing that it exists.',
      );
    });

    testWidgets('delete is offered only on the resident\'s own comment', (
      tester,
    ) async {
      await bootPost(
        tester,
        detail: post(),
        comments: <PostComment>[
          comment(id: 'mine', isMine: true),
          comment(id: 'theirs', authorName: 'Ben'),
        ],
      );

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('a failed comment keeps the text in the box', (tester) async {
      final booted = await bootPost(tester, detail: post());
      booted.posts.addCommentOutcome = const Err<PostComment>(NetworkFailure());

      await tester.enterText(find.byType(TextField), 'Salamat po');
      await tester.tap(find.text('Post comment'));
      await tester.pumpAndSettle();

      expect(find.text('Your comment was not posted'), findsOneWidget);
      // The words are still there.
      expect(find.text('Salamat po'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('no moderation control exists anywhere', (tester) async {
      await bootPost(
        tester,
        detail: post(),
        comments: <PostComment>[comment(id: 'theirs', authorName: 'Ben')],
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'hide comment',
        'remove comment',
        'ban',
        'moderate',
        'pin post',
        'archive post',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('a missing post says so plainly', (tester) async {
      await bootPost(tester);

      expect(find.text('This announcement is not available'), findsOneWidget);
    });

    testWidgets('the detail survives a 200% text scale', (tester) async {
      await bootPost(
        tester,
        detail: post(),
        comments: <PostComment>[comment()],
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 6000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Classes suspended tomorrow'), findsOneWidget);
    });
  });
}
