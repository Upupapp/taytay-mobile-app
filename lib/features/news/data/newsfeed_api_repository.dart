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
  NewsfeedApiRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The cursor from the last list page. Page 1 starts again.
  String? _cursor;

  static const String path = 'news';

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int? perPage,
    String? category,
  }) async {
    assert(page >= 1);
    if (page <= 1) _cursor = null;
    final String? chip = category?.trim();
    final response = await _apiClient.send<List<Announcement>>(
      method: HttpMethod.get,
      path: path,
      // NOT guest-visible unconditionally, which reading the route file would
      // have you believe and which calling it disproves. The route carries no
      // `auth:sanctum`, and the controller still refuses an anonymous reader
      // unless `newsfeed.public_access` is on — a flag that defaults off (F30).
      //
      // So the token goes if there is one and the request stays anonymous if
      // there is not. Sending nothing by construction would fail for a signed-in
      // resident too, which is the worse half of the bug: the token exists and
      // is withheld on principle.
      authenticated: false,
      attachTokenIfAvailable: true,
      query: <String, String>{
        'limit':
            '${_apiClient.pages.clampRequest(perPage ?? _apiClient.pages.defaultPerPage)}',
        'cursor': ?_cursor,
        'category': ?((chip == null || chip.isEmpty || chip == 'Lahat')
            ? null
            : chip),
      },
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodePost)
                .whereType<Announcement>()
                .toList(growable: false)
          : const <Announcement>[],
    );
    if (response case Ok<ApiEnvelope<List<Announcement>>>(:final value)) {
      _cursor = value.pagination?.nextCursor;
    }
    return response.map(_toPage);
  }

  @override
  Future<Result<void>> saveArticle(String id) {
    final Object _ = id;
    return Future<Result<void>>.value(
      backendGapFailure<void>(BackendGap.absentOnNodeContract, 'saveArticle'),
    );
  }

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async {
    final response = await _apiClient.send<Announcement?>(
      method: HttpMethod.get,
      path: '$path/$id',
      authenticated: false,
      attachTokenIfAvailable: true,
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
    int? perPage,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<Paginated<PostComment>>(
      BackendGap.absentOnNodeContract,
      'listComments',
    );
  }

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<ReactionOutcome>(
      BackendGap.absentOnNodeContract,
      'setReaction',
    );
  }

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<ReactionOutcome>(
      BackendGap.absentOnNodeContract,
      'clearReaction',
    );
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    String? parentId,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<PostComment>(
      BackendGap.absentOnNodeContract,
      'addComment',
    );
  }

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'deleteOwnComment',
    );
  }

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required ReportReason reason,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'reportComment',
    );
  }

  static Announcement? _decodePost(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    if (id is! String || id.isEmpty) return null;

    final Object? headline = entry['title'] ?? entry['headline'];
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
      officeSlug: entry['office_slug'] is String
          ? entry['office_slug'] as String
          : null,
      coverMediaId: entry['cover_media_id'] is String
          ? entry['cover_media_id'] as String
          : null,
      // `published_at`, never `created_at`: the latter is when somebody started
      // drafting, and a reader asking "when was this posted" means the former.
      publishedAt: DateTime.tryParse(
        entry['published_at'] is String ? entry['published_at'] as String : '',
      )?.toUtc(),
      isPinned: entry['is_pinned'] == true,
      publicationState: _status(entry['status']),
      media: _decodeMedia(entry['media']),
      capabilities: PostCapabilities(
        canReact: true,
        // The office can close comments on a post, and that is the server's
        // decision to make per post — never a global app setting.
        canComment: entry['comments_enabled'] == true,
        canShare: true,
        // Both were false while their endpoints worked, so no screen offered
        // either. Deleting your own words and reporting somebody else's are
        // things every store expects of an app carrying user content, and the
        // routes have served both since this baseline.
        //
        // Not tied to `comments_enabled`: closing comments on a post stops new
        // ones, and the ones already there are exactly the ones that might need
        // reporting.
        canDeleteOwnComment: true,
        canReportComment: true,
      ),
    );
  }

  static ServerValue<PublicationState>? _status(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final PublicationState? known = switch (raw) {
      'draft' => PublicationState.draft,
      'published' => PublicationState.published,
      'scheduled' => PublicationState.scheduled,
      'archived' => PublicationState.archived,
      _ => null,
    };
    return ServerValue<PublicationState>(raw: raw, known: known);
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

}
