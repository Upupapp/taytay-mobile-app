import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart' show ServerValue;
import 'post_interaction.dart';

// Re-exported so a screen or controller working with announcements gets the
// interaction types and `ServerValue` from one import rather than three.
export '../../services/domain/lgu_service.dart' show ServerValue;
export 'post_interaction.dart';

/// Whether an announcement is ordinary news or something a resident needs now.
///
/// Carried as a [ServerValue] like every other server enum: adding a value is
/// not a breaking change, and a released app must meet an unknown one without
/// dropping the post.
enum AdvisoryLevel {
  /// Ordinary municipal news.
  normal('normal'),

  /// Something residents should act on — a schedule change, a road closure.
  advisory('advisory'),

  /// Public safety. A typhoon, a suspension of classes, an evacuation.
  emergency('emergency');

  const AdvisoryLevel(this.wireValue);

  final String wireValue;
}

/// The publication state the office recorded.
///
/// ---
///
/// **The app does not decide what is published — but it will not display
/// something the server has told it is not.** The contract says
/// `GET /api/v1/announcements` returns published posts, so in practice every
/// value here is `published`. The field exists as a belt on that brace: if a
/// draft or an archived typhoon advisory ever reaches this client through a
/// contract slip, showing it is worse than dropping it. See
/// [Announcement.isResidentVisible].
enum PublicationState {
  draft('draft'),
  scheduled('scheduled'),
  published('published'),
  archived('archived');

  const PublicationState(this.wireValue);

  final String wireValue;
}

/// A picture attached to a post.
///
/// **Dimensions travel with the URL** so a card can reserve the right space
/// before the bytes arrive. Without them an image-heavy feed reflows as each
/// picture lands, which moves whatever is under the resident's thumb — the
/// layout-jump rule from the asset pipeline, applied to remote media.
@immutable
class AnnouncementMedia {
  const AnnouncementMedia({
    required this.url,
    this.width,
    this.height,
    this.alternativeText,
  });

  final String url;
  final int? width;
  final int? height;

  /// Authored by the LGU. Absent is handled by describing the post rather than
  /// inventing a description of a picture the app cannot see.
  final String? alternativeText;

  /// Width ÷ height when the server sent both, for reserving space.
  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  @override
  String toString() => 'AnnouncementMedia(${width}x$height)';
}

/// Counts the office publishes about a post.
///
/// ---
///
/// **Every count is nullable, and absent renders as nothing rather than zero.**
/// "0 comments" is a claim: it says the office counted and found none. When the
/// backend has not sent a number, the app has not been told anything, and
/// printing a zero invents a fact — on a municipal advisory, where a resident
/// may read an empty comment count as "nobody else is affected".
@immutable
class AnnouncementEngagement {
  const AnnouncementEngagement({this.reactions, this.comments, this.shares});

  final int? reactions;
  final int? comments;
  final int? shares;

  bool get hasAny => reactions != null || comments != null || shares != null;

  @override
  String toString() => 'AnnouncementEngagement()';
}

/// One municipal announcement — `balita`.
///
/// Public content by contract: `GET /api/v1/announcements` carries no `auth`
/// column entry and is marked `public`. Nothing here is personal data, which is
/// why the whole feature is readable by a guest and why an announcement id is
/// safe to put in a push notification.
///
/// ---
///
/// **This app consumes; it never publishes.** Creating, scheduling, pinning,
/// archiving and moderating are admin-portal actions. There is no field here
/// that would let a resident set one, and no repository method that would send
/// one.
@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.publishedAt,
    this.category,
    this.author,
    this.summary,
    this.media,
    this.isPinned = false,
    this.advisoryLevel,
    this.publicationState,
    this.engagement,
    this.shareUrl,
    this.capabilities = PostCapabilities.none,
    this.availableReactions = const <ServerValue<ReactionKind>>[],
    this.myReaction,
  });

  /// Opaque server identifier. The deep-link target for `news_post`.
  final String id;

  final String title;
  final String body;
  final DateTime? publishedAt;

  /// The server's own label, preserved and shown as sent. Not mapped to an enum
  /// because the app takes no decision from it — an unrecognised category should
  /// display, not disappear.
  final String? category;

  /// The office or official identity that published it, as the LGU wrote it.
  /// Never a staff member's personal name unless the office chose to publish one.
  final String? author;

  /// A short preview the office authored.
  ///
  /// Falls back to the body in [preview] rather than being generated: a
  /// machine-truncated first paragraph of an emergency advisory can cut off the
  /// half that says what to do.
  final String? summary;

  final AnnouncementMedia? media;

  /// Pinned by the admin portal. Presentation emphasis only — the app never
  /// re-orders on its own.
  final bool isPinned;

  final ServerValue<AdvisoryLevel>? advisoryLevel;
  final ServerValue<PublicationState>? publicationState;

  final AnnouncementEngagement? engagement;

  /// The canonical public link, **exactly as the server supplied it**.
  ///
  /// Never composed by the app from a host and an id: this client does not know
  /// the LGU's public web address, and a fabricated link inside a shared typhoon
  /// advisory sends people to a 404 or to a domain somebody else owns.
  final String? shareUrl;

  /// What the backend says this resident may do here. Defaults to nothing.
  final PostCapabilities capabilities;

  /// The reaction set this post accepts, in the server's order.
  final List<ServerValue<ReactionKind>> availableReactions;

  /// The resident's own reaction, when they have one.
  final ServerValue<ReactionKind>? myReaction;

  /// A copy with the reaction fields replaced.
  ///
  /// Exists so a controller can apply an optimistic change and then adopt the
  /// server's answer without rebuilding the whole post by hand — the sort of
  /// by-hand copy where one field quietly gets dropped.
  Announcement withReaction({
    required ServerValue<ReactionKind>? myReaction,
    int? reactions,
  }) => Announcement(
    id: id,
    title: title,
    body: body,
    publishedAt: publishedAt,
    category: category,
    author: author,
    summary: summary,
    media: media,
    isPinned: isPinned,
    advisoryLevel: advisoryLevel,
    publicationState: publicationState,
    engagement: AnnouncementEngagement(
      reactions: reactions ?? engagement?.reactions,
      comments: engagement?.comments,
      shares: engagement?.shares,
    ),
    shareUrl: shareUrl,
    capabilities: capabilities,
    availableReactions: availableReactions,
    myReaction: myReaction,
  );

  /// Whether this post may be shown to a resident.
  ///
  /// ---
  ///
  /// **Fails open on an unknown state, closed on a known non-public one**, and
  /// the asymmetry is deliberate.
  ///
  /// A state this build does not recognise means the office added a value after
  /// the app shipped. Hiding those would turn one backend change into a blank
  /// feed for every unpatched phone — during precisely the kind of event that
  /// makes a municipality add a new publication state. The server chose to send
  /// the post; that is the authority the constitution defers to.
  ///
  /// A state this build *does* recognise as non-public — a draft, a scheduled
  /// post, an archived advisory — is a different matter. There the app knows
  /// what it was told, and displaying a withdrawn typhoon advisory is worse than
  /// displaying nothing.
  ///
  /// This is the opposite default to `ResidentRequirement.acceptsUpload`, which
  /// fails closed. The difference is that one governs *reading public content
  /// the server deliberately sent*, and the other governs *acting on a record*.
  bool get isResidentVisible => switch (publicationState?.known) {
    PublicationState.draft ||
    PublicationState.scheduled ||
    PublicationState.archived => false,
    PublicationState.published => true,
    // Unrecognised, or not sent at all.
    null => true,
  };

  /// What the card shows under the title.
  String get preview => summary ?? body;

  /// True when the post should carry advisory emphasis.
  bool get isAdvisory =>
      advisoryLevel?.known == AdvisoryLevel.advisory ||
      advisoryLevel?.known == AdvisoryLevel.emergency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Announcement && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Announcement($id)';
}

/// Municipal announcements, as the committed contract describes them.
///
/// Two calls, both public, both paginated per `docs/api/conventions.md` §5.
/// Nothing is invented: the list row exists in the endpoint matrix (§12), and
/// the detail read is the same collection addressed by id — which is what the
/// notification deep link needs and what the conventions' resource shape
/// implies. Should the backend ship the list without a detail route, this is
/// the one method that changes.
///
/// **There is no create, update, publish, pin or archive method, and there
/// cannot be one.** Those belong to the admin console, and a resident client
/// that could express them would be carrying an authority it must never hold.
abstract interface class AnnouncementRepository {
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page,
    int perPage,
  });

  /// One announcement by opaque id.
  ///
  /// A `404` is an ordinary outcome here, not an error to hide: an announcement
  /// can be withdrawn between the notification being sent and the resident
  /// tapping it, and the screen says so plainly.
  Future<Result<Announcement>> loadAnnouncement(String id);

  // ── Resident interactions ────────────────────────────────────────────────
  //
  // Every one of these is offered only when `Announcement.capabilities` says
  // the backend supports it, and every mutation carries an idempotency key for
  // the same reason a submission does: a dropped connection after the server
  // committed is indistinguishable from one before.

  /// Comments the resident is allowed to see, oldest first.
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page,
    int perPage,
  });

  /// Sets or replaces the resident's reaction.
  ///
  /// Returns the post's new total so the screen can adopt the server's count
  /// rather than keep its own optimistic arithmetic — which is wrong the moment
  /// two people react at once.
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  });

  /// Removes the resident's reaction.
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  });

  /// Posts a comment, optionally as a reply.
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  });

  /// Deletes a comment the resident wrote.
  ///
  /// **Own comments only.** There is no method here that names somebody else's,
  /// and there must not be: moderation is an admin-console act.
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  });

  /// Reports a comment to the office.
  ///
  /// Reporting is *asking a moderator to look*, which is a resident action.
  /// Acting on the report is not, and nothing here does.
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required String reason,
    required String idempotencyKey,
  });
}
