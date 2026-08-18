import '../../../core/api/paginated.dart';
import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// The [AnnouncementRepository] this build ships with: it declines, honestly.
///
/// **Two errors, not one.** This file said `GET /api/v1/announcements` was
/// `planned`. No module has ever served that path on this backend — the route
/// does not exist and never did — while `Content` has published `GET newsfeed`
/// and its whole engagement surface since backend TAB 23. So the app was asking
/// the wrong question of the wrong module and reading a plausible answer into
/// its own silence. Wiring it against the real paths is TAB 11.
///
/// It still declines rather than showing sample announcements — which, on a
/// municipal app, would be a fabricated statement by a local government.
class PlannedAnnouncementRepository implements AnnouncementRepository {
  const PlannedAnnouncementRepository();

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async => unwiredRepositoryFailure<Paginated<Announcement>>(
    UnwiredRepository.newsfeed,
    'listAnnouncements',
  );

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      unwiredRepositoryFailure<Announcement>(
        UnwiredRepository.newsfeed,
        'loadAnnouncement',
      );

  // ── Interactions ─────────────────────────────────────────────────────────
  //
  // All decline. Note that a post from this repository also carries
  // `PostCapabilities.none`, so in practice no screen offers any of these —
  // the methods still refuse rather than relying on the UI to be careful.

  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 20,
  }) async => unwiredRepositoryFailure<Paginated<PostComment>>(
    UnwiredRepository.newsfeed,
    'listComments',
  );

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<ReactionOutcome>(
    UnwiredRepository.newsfeed,
    'setReaction',
  );

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<ReactionOutcome>(
    UnwiredRepository.newsfeed,
    'clearReaction',
  );

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) async => unwiredRepositoryFailure<PostComment>(
    UnwiredRepository.newsfeed,
    'addComment',
  );

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(
    UnwiredRepository.newsfeed,
    'deleteOwnComment',
  );

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(
    UnwiredRepository.newsfeed,
    'reportComment',
  );
}
