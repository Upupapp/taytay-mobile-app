import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// Reads published Balita: `GET /news`, `GET /news/{id}`, and
/// `GET /news/categories`.
///
/// The app consumes. It does not create, edit, pin, or unpin. Pin and unpin
/// are staff routes. Bookmarks are not on the contract, so this repository
/// has no save method.
class NewsfeedApiRepository implements AnnouncementRepository {
  NewsfeedApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The cursor from the last list page. Page 1 starts again.
  String? _cursor;

  /// Office slug to the name from `GET /offices`. Null until the first read.
  Map<String, String>? _offices;

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
      authenticated: false,
      // Public read. A signed-in resident still sends the session token.
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
    switch (response) {
      case Err<ApiEnvelope<List<Announcement>>>(:final failure):
        return Err<Paginated<Announcement>>(failure);
      case Ok<ApiEnvelope<List<Announcement>>>(:final value):
        _cursor = value.pagination?.nextCursor;
        final List<Announcement> named = await _withOffices(value.data);
        return Ok<Paginated<Announcement>>(
          _toPage(
            ApiEnvelope<List<Announcement>>(
              data: named,
              requestId: value.requestId,
              pagination: value.pagination,
            ),
          ),
        );
    }
  }

  @override
  Future<Result<List<NewsCategory>>> listCategories() async {
    final Result<ApiEnvelope<List<NewsCategory>>> response = await _apiClient
        .send<List<NewsCategory>>(
          method: HttpMethod.get,
          path: 'news/categories',
          authenticated: false,
          attachTokenIfAvailable: true,
          decode: _decodeCategories,
        );
    return response.map(
      (ApiEnvelope<List<NewsCategory>> envelope) => envelope.data,
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
    switch (response) {
      case Err<ApiEnvelope<Announcement?>>(:final failure):
        return Err<Announcement>(failure);
      case Ok<ApiEnvelope<Announcement?>>(:final value):
        final Announcement? article = value.data;
        if (article == null) {
          // A post pulled between a link being sent and a resident tapping it.
          // Resolved as not-found rather than as a fault: an advisory being
          // taken down is ordinary, and the screen says "no longer available".
          return const Err<Announcement>(
            NotFoundFailure(debugMessage: 'No readable post in the body.'),
          );
        }
        final List<Announcement> named = await _withOffices(<Announcement>[
          article,
        ]);
        return Ok<Announcement>(named.single);
    }
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
      coverUrl: _text(entry['cover_url']),
      // `published_at`, never `created_at`: the latter is when somebody started
      // drafting, and a reader asking "when was this posted" means the former.
      publishedAt: DateTime.tryParse(
        entry['published_at'] is String ? entry['published_at'] as String : '',
      )?.toUtc(),
      isPinned: entry['pinned'] == true,
      pinnedAt: DateTime.tryParse(
        entry['pinned_at'] is String ? entry['pinned_at'] as String : '',
      )?.toUtc(),
      shareUrl: _text(entry['share_url']),
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

  Future<List<Announcement>> _withOffices(List<Announcement> items) async {
    final bool needsName = items.any(
      (Announcement item) =>
          (item.author == null || item.author!.trim().isEmpty) &&
          (item.officeSlug != null && item.officeSlug!.isNotEmpty),
    );
    if (!needsName) return items;
    final Map<String, String> names = await _officeNames();
    return <Announcement>[
      for (final Announcement item in items)
        if ((item.author == null || item.author!.trim().isEmpty) &&
            names[item.officeSlug] != null)
          item.withAuthor(names[item.officeSlug]!)
        else
          item,
    ];
  }

  /// `name` is the office's published label. The news item has only the slug.
  Future<Map<String, String>> _officeNames() async {
    final Map<String, String>? cached = _offices;
    if (cached != null) return cached;
    final Map<String, String> names = <String, String>{};
    String? cursor;
    for (var page = 0; page < 5; page++) {
      final Result<ApiEnvelope<Map<String, String>>> response = await _apiClient
          .send<Map<String, String>>(
            method: HttpMethod.get,
            path: 'offices',
            authenticated: false,
            query: <String, String>{'limit': '50', 'cursor': ?cursor},
            decode: _decodeOfficeNames,
          );
      switch (response) {
        case Err<ApiEnvelope<Map<String, String>>>():
          if (page == 0) return _offices = const <String, String>{};
          return _offices = names;
        case Ok<ApiEnvelope<Map<String, String>>>(:final value):
          names.addAll(value.data);
          final String? next = value.pagination?.nextCursor;
          if (value.pagination?.hasMore != true ||
              next == null ||
              next.isEmpty) {
            return _offices = names;
          }
          cursor = next;
      }
    }
    return _offices = names;
  }

  static Map<String, String> _decodeOfficeNames(Object? data) {
    if (data is! List) return const <String, String>{};
    final Map<String, String> names = <String, String>{};
    for (final Object? item in data) {
      if (item is! Map) continue;
      final Object? slug = item['slug'];
      final Object? name = item['name'];
      if (slug is! String || slug.isEmpty || name is! String) continue;
      final String label = name.trim();
      if (label.isEmpty) continue;
      names[slug] = label;
    }
    return names;
  }

  static List<NewsCategory> _decodeCategories(Object? data) {
    if (data is! List) return const <NewsCategory>[];
    return data
        .map((Object? item) {
          if (item is! Map) return null;
          final Object? slug = item['slug'];
          final Object? label = item['label'];
          if (slug is! String ||
              slug.isEmpty ||
              label is! String ||
              label.trim().isEmpty) {
            return null;
          }
          return NewsCategory(slug: slug, label: label.trim());
        })
        .whereType<NewsCategory>()
        .toList(growable: false);
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
