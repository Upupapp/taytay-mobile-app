import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// Talks to `newsfeed` and its engagement routes.
///
/// ---
///
/// **The path was wrong before this, not just the module status.** This app
/// asked for `GET announcements` — a route no module has ever served on this
/// backend — while `Content` has published `GET newsfeed` since backend TAB 23.
/// A wrong path and a wrong belief about a module are separate errors and the
/// stub carried both.
///
/// **The app consumes; it never publishes.** No creating, scheduling, pinning,
/// archiving, or moderating another resident's comment. Those are admin-console
/// surfaces and building one here would breach Article 0 — which matters more
/// than usual on this feature, because it is the only one in the app where a
/// staff-shaped action would look natural next to a resident-shaped one.
class NewsfeedApiRepository implements AnnouncementRepository {
  const NewsfeedApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'newsfeed';

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.send<List<Announcement>>(
      method: HttpMethod.get,
      path: path,
      // Guest-visible by design, and sent anonymously so the response stays
      // publicly cacheable — the same reasoning as the service catalogue.
      authenticated: false,
      query: <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'per_page': '${perPage.clamp(1, 100)}',
      },
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodePost)
                .whereType<Announcement>()
                .toList(growable: false)
          : const <Announcement>[],
    );
    return response.map(_toPage);
  }

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async {
    final response = await _apiClient.send<Announcement?>(
      method: HttpMethod.get,
      path: '$path/$id',
      authenticated: false,
      decode: _decodePost,
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          // A post pulled between a link being sent and a resident tapping it.
          // Resolved as not-found rather than as a fault: an advisory being
          // taken down is ordinary, and the screen says "no longer available".
          ? const Err<Announcement>(
              NotFoundFailure(debugMessage: 'No readable post in the body.'),
            )
          : Ok<Announcement>(envelope.data!),
    );
  }

  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.send<List<PostComment>>(
      method: HttpMethod.get,
      path: '$path/$postId/comments',
      // Reading comments needs an account: the server puts this route behind
      // auth:sanctum while the post itself is public.
      authenticated: true,
      query: <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'per_page': '${perPage.clamp(1, 100)}',
      },
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeComment)
                .whereType<PostComment>()
                .toList(growable: false)
          : const <PostComment>[],
    );
    return response.map(_toCommentPage);
  }

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<ReactionOutcome>(
      method: HttpMethod.post,
      path: '$path/$postId/reaction',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'kind': reaction.wireValue},
      decode: _decodeReaction,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<ReactionOutcome>(
      method: HttpMethod.delete,
      path: '$path/$postId/reaction',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: _decodeReaction,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    String? parentId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<PostComment?>(
      method: HttpMethod.post,
      path: '$path/$postId/comments',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'body': body, 'parent_id': ?parentId},
      decode: _decodeComment,
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<PostComment>(
              ContractFailure(debugMessage: 'No readable comment in the body.'),
            )
          : Ok<PostComment>(envelope.data!),
    );
  }

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async {
    // `newsfeed-comments/{comment}`, not nested under the post: the server
    // addresses a comment by its own id and decides ownership itself. The app
    // never compares author names to work out whether something is deletable.
    final response = await _apiClient.send<void>(
      method: HttpMethod.delete,
      path: 'newsfeed-comments/$commentId',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String idempotencyKey,
  }) async {
    // F26, and it is a store-submission blocker rather than a missing nicety.
    //
    // Both Google Play and the App Store require a way to report objectionable
    // user-generated content, and this is the only feature in the app that
    // produces any. The backend's moderation surface is
    // `admin/newsfeed-comments/{comment}/moderation` — staff-only, and calling
    // it from here would breach Article 0 twice over: a staff route, and a
    // resident acting on somebody else's comment.
    //
    // Declining rather than pretending: a report button that silently does
    // nothing is worse than an absent one, because a resident who has just seen
    // something abusive believes they have told the municipality.
    return backendGapFailure<void>(
      BackendGap.contentReporting,
      'reportComment',
    );
  }

  static Announcement? _decodePost(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    if (id is! String || id.isEmpty) return null;

    final Object? headline = entry['headline'];
    final Object? body = entry['body'];

    return Announcement(
      id: id,
      title: headline is String && headline.trim().isNotEmpty
          ? headline.trim()
          : '',
      body: body is String ? body : '',
      category: entry['category'] is String
          ? entry['category'] as String
          : null,
      // `published_at`, never `created_at`: the latter is when somebody started
      // drafting, and a reader asking "when was this posted" means the former.
      publishedAt: DateTime.tryParse(
        entry['published_at'] is String ? entry['published_at'] as String : '',
      )?.toUtc(),
      isPinned: entry['is_pinned'] == true,
      media: _decodeMedia(entry['media']),
      capabilities: PostCapabilities(
        canReact: true,
        // The office can close comments on a post, and that is the server's
        // decision to make per post — never a global app setting.
        canComment: entry['comments_enabled'] == true,
        canShare: true,
      ),
    );
  }

  /// The first non-decorative image, with its alt text.
  ///
  /// Alt text is always present in the payload, so a client never has to decide
  /// what to do with a missing one — and it is a government content-standards
  /// requirement as much as an accessibility one. A decorative image carries
  /// none by definition and is skipped rather than announced.
  static AnnouncementMedia? _decodeMedia(Object? raw) {
    if (raw is! List<dynamic>) return null;
    for (final Object? item in raw) {
      if (item is! Map<String, dynamic>) continue;
      if (item['is_decorative'] == true) continue;

      final Object? urls = item['urls'];
      if (urls is! List<dynamic> || urls.isEmpty) continue;
      final Object? url = urls.first;
      if (url is! String || url.isEmpty) continue;

      final Object? alt = item['alt_text'];
      return AnnouncementMedia(
        url: url,
        alternativeText: alt is String && alt.trim().isNotEmpty
            ? alt.trim()
            : null,
      );
    }
    return null;
  }

  static PostComment? _decodeComment(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    final Object? body = entry['body'];
    if (id is! String || id.isEmpty || body is! String) return null;

    return PostComment(
      id: id,
      body: body,
      authorName: entry['author_name'] is String
          ? entry['author_name'] as String
          : '',
      authorKind: ServerValue.parse<CommentAuthorKind>(
        entry['author_kind'] is String ? entry['author_kind'] as String : null,
        CommentAuthorKind.values,
        (CommentAuthorKind k) => k.wireValue,
      ),
      createdAt: DateTime.tryParse(
        entry['created_at'] is String ? entry['created_at'] as String : '',
      )?.toUtc(),
      // The server's answer, never a comparison against a display name — two
      // residents can share one.
      isMine: entry['is_mine'] == true,
      parentId: entry['parent_id'] is String
          ? entry['parent_id'] as String
          : null,
      isHiddenByModerator: entry['is_hidden'] == true,
    );
  }

  static ReactionOutcome _decodeReaction(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? count = map['reactions'] ?? map['count'];
    final Object? mine = map['my_reaction'];
    return ReactionOutcome(
      reactions: count is int ? count : 0,
      myReaction: mine is String
          ? ServerValue.parse<ReactionKind>(
              mine,
              ReactionKind.values,
              (ReactionKind k) => k.wireValue,
            )
          : null,
    );
  }

  static Paginated<Announcement> _toPage(
    ApiEnvelope<List<Announcement>> envelope,
  ) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<Announcement>.single(envelope.data);
    }
    return Paginated<Announcement>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }

  static Paginated<PostComment> _toCommentPage(
    ApiEnvelope<List<PostComment>> envelope,
  ) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<PostComment>.single(envelope.data);
    }
    return Paginated<PostComment>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
