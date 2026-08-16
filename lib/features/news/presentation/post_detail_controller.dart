import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// Where the comment composer is.
enum CommentPostingState { idle, sending, failed }

/// Drives one announcement: the post, its reactions, and its comments.
///
/// ---
///
/// ## What this class guarantees
///
/// * **An optimistic reaction always reconciles.** The tap updates the screen
///   immediately, the server's answer replaces that guess, and a failure puts
///   back exactly what was there before. The app's arithmetic is wrong the
///   moment two people react at once; the server's is not.
/// * **A reaction is never counted twice.** One idempotency key per attempt,
///   reused across retries of that attempt.
/// * **A failed comment keeps its text.** Losing a paragraph somebody typed on a
///   phone because a bus went through a tunnel is the failure this prevents.
/// * **Nothing is offered that the backend did not declare.** Every action
///   checks `PostCapabilities` first, so a control cannot appear for something
///   that would fail on submit.
class PostDetailController extends ChangeNotifier {
  PostDetailController({
    required AnnouncementRepository repository,
    required this.postId,
  }) : _repository = repository;

  final AnnouncementRepository _repository;
  final String postId;

  Announcement? _post;
  AppFailure? _loadFailure;
  bool _loading = true;

  final List<PostComment> _comments = <PostComment>[];
  bool _loadingComments = false;
  bool _hasMoreComments = true;
  int _commentPage = 0;
  AppFailure? _commentsFailure;

  CommentPostingState _posting = CommentPostingState.idle;
  AppFailure? _postingFailure;
  String? _commentKey;

  /// Set while a reaction is in flight, so the control can be inert without
  /// changing size.
  bool _reacting = false;

  Announcement? get post => _post;
  AppFailure? get loadFailure => _loadFailure;
  bool get isLoading => _loading;

  List<PostComment> get comments => List<PostComment>.unmodifiable(_comments);
  bool get isLoadingComments => _loadingComments;
  bool get hasMoreComments => _hasMoreComments;
  AppFailure? get commentsFailure => _commentsFailure;

  CommentPostingState get postingState => _posting;
  AppFailure? get postingFailure => _postingFailure;
  bool get isReacting => _reacting;

  PostCapabilities get capabilities =>
      _post?.capabilities ?? PostCapabilities.none;

  /// The resident's current reaction, if any.
  ServerValue<ReactionKind>? get myReaction => _post?.myReaction;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final result = await _repository.loadAnnouncement(postId);
    _loading = false;
    result.fold(
      onOk: (post) {
        _post = post;
        _loadFailure = null;
      },
      onErr: (failure) {
        _post = null;
        _loadFailure = failure;
      },
    );
    notifyListeners();

    // Comments are only worth asking for when the post allows them.
    if (_post != null && capabilities.canComment) await loadMoreComments();
  }

  Future<void> loadMoreComments() async {
    if (_loadingComments || !_hasMoreComments) return;
    _loadingComments = true;
    _commentsFailure = null;
    notifyListeners();

    final next = _commentPage + 1;
    final result = await _repository.listComments(postId, page: next);
    _loadingComments = false;

    result.fold(
      onOk: (page) {
        _commentPage = next;
        // Rendered exactly as sent, including anything the office hid. The app
        // does not second-guess moderation state — dropping a hidden comment
        // would leave a reply pointing at nothing, and would hide from a
        // resident that their own comment was moderated.
        _comments.addAll(page.items);
        _hasMoreComments = page.hasMore;
      },
      onErr: (failure) => _commentsFailure = failure,
    );
    notifyListeners();
  }

  // ── Reactions ────────────────────────────────────────────────────────────

  /// Applies [reaction], or clears it when it is the one already set.
  ///
  /// Tapping your own reaction again is how every feed works, and modelling it
  /// as a toggle here means the screen does not need two controls.
  Future<void> toggleReaction(ReactionKind reaction) async {
    final current = _post;
    if (current == null || _reacting || !capabilities.canReact) return;

    final wasSet = current.myReaction?.known == reaction;
    final before = current;

    // Optimistic: the tap lands immediately.
    final optimisticCount = _optimisticCount(current, wasSet: wasSet);
    _post = current.withReaction(
      myReaction: wasSet
          ? null
          : ServerValue<ReactionKind>(raw: reaction.wireValue, known: reaction),
      reactions: optimisticCount,
    );
    _reacting = true;
    notifyListeners();

    final key = generateRequestId();
    final result = wasSet
        ? await _repository.clearReaction(postId: postId, idempotencyKey: key)
        : await _repository.setReaction(
            postId: postId,
            reaction: reaction,
            idempotencyKey: key,
          );

    _reacting = false;
    result.fold(
      onOk: (outcome) {
        // The server's count wins over the guess, always.
        _post = _post!.withReaction(
          myReaction: outcome.myReaction,
          reactions: outcome.reactions,
        );
      },
      // Put back exactly what was there. A reaction that silently stuck when the
      // server refused it is a lie the resident cannot see.
      onErr: (_) => _post = before,
    );
    notifyListeners();
  }

  /// The count to show while the server is answering.
  ///
  /// Returns `null` — meaning "no count shown" — when the office never published
  /// one, rather than starting a count from zero. Inventing a total is the same
  /// mistake as printing "0 comments".
  int? _optimisticCount(Announcement post, {required bool wasSet}) {
    final current = post.engagement?.reactions;
    if (current == null) return null;

    // Switching from one reaction to another does not change the total.
    final isSwitching = !wasSet && post.myReaction != null;
    if (isSwitching) return current;

    final next = wasSet ? current - 1 : current + 1;
    return next < 0 ? 0 : next;
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  /// Posts a comment. [body] is kept by the caller so a failure loses nothing.
  Future<bool> submitComment(String body, {String? parentId}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || _posting == CommentPostingState.sending) {
      return false;
    }
    if (!capabilities.canComment) return false;

    // One key per attempt, reused across retries of that attempt.
    _commentKey ??= generateRequestId();
    _posting = CommentPostingState.sending;
    _postingFailure = null;
    notifyListeners();

    final result = await _repository.addComment(
      postId: postId,
      body: trimmed,
      idempotencyKey: _commentKey!,
      parentId: parentId,
    );

    return result.fold(
      onOk: (comment) {
        _comments.add(comment);
        _bumpCommentCount(1);
        _posting = CommentPostingState.idle;
        _postingFailure = null;
        // Answered: the next comment is a new one, not a replay.
        _commentKey = null;
        notifyListeners();
        return true;
      },
      onErr: (failure) {
        _posting = CommentPostingState.failed;
        _postingFailure = failure;
        // The key survives, so "Try again" replays this attempt rather than
        // posting the same paragraph twice.
        notifyListeners();
        return false;
      },
    );
  }

  /// Deletes a comment the resident wrote.
  Future<bool> deleteOwnComment(String commentId) async {
    if (!capabilities.canDeleteOwnComment) return false;

    final index = _comments.indexWhere((comment) => comment.id == commentId);
    if (index < 0) return false;
    // Guarded twice: the screen only offers this on an own comment, and so does
    // this method. Deleting somebody else's words is not a resident act.
    if (!_comments[index].isMine) return false;

    final removed = _comments.removeAt(index);
    _bumpCommentCount(-1);
    notifyListeners();

    final result = await _repository.deleteOwnComment(
      postId: postId,
      commentId: commentId,
      idempotencyKey: generateRequestId(),
    );

    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        // Put it back where it was, in order.
        _comments.insert(index, removed);
        _bumpCommentCount(1);
        _postingFailure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Reports a comment to the office. Asking a moderator to look is a resident
  /// action; acting on the report is not, and nothing here does.
  Future<bool> reportComment(String commentId, String reason) async {
    if (!capabilities.canReportComment) return false;

    final result = await _repository.reportComment(
      postId: postId,
      commentId: commentId,
      reason: reason,
      idempotencyKey: generateRequestId(),
    );
    return result.isOk;
  }

  /// Keeps the visible comment count in step with a local add or remove.
  ///
  /// Only when the office published a count in the first place — a `null` stays
  /// `null`.
  void _bumpCommentCount(int delta) {
    final current = _post;
    final existing = current?.engagement?.comments;
    if (current == null || existing == null) return;

    final next = existing + delta;
    _post = Announcement(
      id: current.id,
      title: current.title,
      body: current.body,
      publishedAt: current.publishedAt,
      category: current.category,
      author: current.author,
      summary: current.summary,
      media: current.media,
      isPinned: current.isPinned,
      advisoryLevel: current.advisoryLevel,
      publicationState: current.publicationState,
      engagement: AnnouncementEngagement(
        reactions: current.engagement?.reactions,
        comments: next < 0 ? 0 : next,
        shares: current.engagement?.shares,
      ),
      shareUrl: current.shareUrl,
      capabilities: current.capabilities,
      availableReactions: current.availableReactions,
      myReaction: current.myReaction,
    );
  }
}
