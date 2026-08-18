import 'package:flutter/foundation.dart';

import '../../services/domain/lgu_service.dart' show ServerValue;

/// A reaction the backend supports.
///
/// ---
///
/// **The app renders the reactions the server offers, and no others.** A post
/// carries its own `availableReactions`; a kind this build does not recognise is
/// shown by its raw label rather than dropped, and a kind this build knows but
/// the server did not offer is not shown at all. Neither direction is guessed.
enum ReactionKind {
  like('like'),
  care('care'),
  celebrate('celebrate'),
  sad('sad');

  const ReactionKind(this.wireValue);

  final String wireValue;
}

/// Who wrote a comment.
///
/// **`official` exists so an LGU reply is visibly distinguished**, which the
/// Master Command requires. It is a fact the server states about the author, not
/// something the app infers from a name — inferring it would let any resident
/// who set the right display name appear to speak for the municipality.
enum CommentAuthorKind {
  resident('resident'),
  official('official');

  const CommentAuthorKind(this.wireValue);

  final String wireValue;
}

/// What the backend says this resident may do with this post.
///
/// ---
///
/// **Every flag defaults to false.** A capability the server did not mention is
/// one the app does not offer: showing a comment box that fails on submit wastes
/// somebody's typing, and showing a report control the backend cannot record
/// tells a resident their complaint went somewhere when it went nowhere.
///
/// **There is no moderation capability here, and there cannot be one.** Hiding
/// or deleting another resident's comment, pinning, archiving and viewing
/// moderation metrics are admin-console actions. This app identifies itself as
/// `citizen-mobile`; a flag for any of them would be dead weight at best.
@immutable
class PostCapabilities {
  const PostCapabilities({
    this.canReact = false,
    this.canComment = false,
    this.canShare = false,
    this.canDeleteOwnComment = false,
    this.canReportComment = false,
  });

  /// Nothing offered. The safe default, and what an absent block decodes to.
  static const PostCapabilities none = PostCapabilities();

  final bool canReact;
  final bool canComment;
  final bool canShare;

  /// **Own** comment only. There is deliberately no `canDeleteAnyComment`.
  final bool canDeleteOwnComment;

  final bool canReportComment;

  @override
  String toString() =>
      'PostCapabilities(react: $canReact, comment: $canComment)';
}

/// Why a resident says a comment should not be there (F26).
///
/// ---
///
/// **A closed set, mirroring the server's, and there is deliberately no
/// `other`.** `other` is the door free text comes back through: a category that
/// means nothing forces a box to explain it, and that box is where somebody
/// types a neighbour's name and address into a municipal record that staff read
/// and retention rules keep. The moderator has the comment in front of them; the
/// category tells them what to look for, which is the whole job it has.
///
/// Typed rather than a `String` so a screen cannot send a value the server will
/// refuse — a 422 on a report is a resident believing they told the LGU about
/// something abusive when they did not.
enum ReportReason {
  abusive(
    'abusive',
    'Abusive or threatening',
    'Insults, threats, or hateful language.',
  ),
  harassment(
    'harassment',
    'Targeting someone',
    'Aimed at a particular person.',
  ),

  /// The one that matters most on a municipal feed specifically. A comment under
  /// an advisory saying relief distribution moved sends people to the wrong
  /// place.
  falseInformation(
    'false-information',
    'False information about services',
    'Wrong claims about Taytay LGU services or schedules.',
  ),
  spam(
    'spam',
    'Spam or advertising',
    'Selling something, or posted repeatedly.',
  ),
  personalInformation(
    'personal-information',
    "Someone's personal information",
    'A phone number, address, or other private detail posted without consent.',
  );

  const ReportReason(this.wireValue, this.label, this.description);

  /// Sent as-is, and matched against the server's own vocabulary.
  final String wireValue;

  /// What the resident chooses from.
  final String label;
  final String description;
}

/// One comment on an announcement.
@immutable
class PostComment {
  const PostComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.authorKind,
    this.createdAt,
    this.isMine = false,
    this.parentId,
    this.isHiddenByModerator = false,
  });

  final String id;
  final String body;

  /// As the server published it.
  final String authorName;

  final ServerValue<CommentAuthorKind> authorKind;

  final DateTime? createdAt;

  /// Whether the signed-in resident wrote it. **The server's answer**, not a
  /// comparison the app makes against a display name.
  final bool isMine;

  /// Set for a reply. Replies are rendered indented under their parent.
  final String? parentId;

  /// The office has hidden it.
  ///
  /// **The app renders whatever the backend chose to send and does not
  /// second-guess it.** If a hidden comment arrives, it is shown as withheld
  /// rather than silently dropped — dropping it would leave a reply pointing at
  /// nothing, and would hide from a resident that their own comment was
  /// moderated.
  final bool isHiddenByModerator;

  bool get isOfficial => authorKind.known == CommentAuthorKind.official;

  bool get isReply => parentId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PostComment && other.id == id);

  @override
  int get hashCode => id.hashCode;

  /// Redacted of the body and the author: a comment is a person's words, and
  /// this type is reachable from a log line.
  @override
  String toString() => 'PostComment($id)';
}

/// What the server returned after a reaction changed.
///
/// ---
///
/// **Counts come back from the server, and the app adopts them.** An optimistic
/// increment is a guess that holds until the truth arrives; if two people react
/// at once, the app's arithmetic is wrong and the server's is not. Returning the
/// count with the mutation is what makes reconciliation possible without a
/// second round trip.
@immutable
class ReactionOutcome {
  const ReactionOutcome({required this.reactions, this.myReaction});

  /// The post's reaction total after the change.
  final int reactions;

  /// What the resident's reaction now is — `null` when they cleared it.
  final ServerValue<ReactionKind>? myReaction;

  @override
  String toString() => 'ReactionOutcome($reactions)';
}
