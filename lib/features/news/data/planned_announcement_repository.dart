import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// The [AnnouncementRepository] this build ships with: it declines, honestly.
///
/// `GET /api/v1/announcements` is in the committed matrix and marked `planned`;
/// the module behind it is not built. The News destination therefore renders a
/// real "not published yet" state through the same failure path as every other
/// absent module, rather than sample announcements — which, on a municipal app,
/// would be a fabricated statement by a local government.
class PlannedAnnouncementRepository implements AnnouncementRepository {
  const PlannedAnnouncementRepository();

  static const String _reason =
      'GET /api/v1/announcements is planned; no announcements module is built.';

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<Announcement>>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      const Err<Announcement>(
        ServerFailure(isTemporary: true, debugMessage: _reason),
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
  }) async => const Err<Paginated<PostComment>>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) async => const Err<PostComment>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async =>
      const Err<void>(ServerFailure(isTemporary: true, debugMessage: _reason));

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String idempotencyKey,
  }) async =>
      const Err<void>(ServerFailure(isTemporary: true, debugMessage: _reason));
}
