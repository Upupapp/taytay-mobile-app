import 'package:flutter/foundation.dart';

import 'verification_repository.dart';

/// What a resident sees about their own verification.
///
/// ---
///
/// ## Why a resident-facing stage exists separately from the server's state
///
/// The backend owns "a canonical `VerificationState` enumeration (not a
/// boolean)" and exposes it as `verification_tier`
/// (`Taytay_Rizal_LGUIDS_Backend@68fa195`, gap **G-08**). Its values are not
/// published, and it is free to add more without a version bump.
///
/// So the app keeps two things apart:
///
/// * [VerificationAttemptState] — the server's own vocabulary, preserved raw.
/// * [ResidentVerificationStage] — the six situations a resident can actually
///   be in, each with copy and a next action.
///
/// The mapping runs one way, and **an unrecognised server value degrades to the
/// least-capable stage** ([ResidentVerificationStage.manualReview]), which is
/// the one that always has a safe path: go to the municipal hall. Mapping an
/// unknown state to "verified" would grant capabilities the server never
/// granted; mapping it to "unsuccessful" would tell a resident they failed when
/// nobody said so.
enum ResidentVerificationStage {
  /// Nothing has been submitted.
  notStarted(
    'Not started',
    'You have not started verifying your identity yet.',
  ),

  /// Started but not sent.
  inProgress(
    'In progress',
    'You started verifying your identity but have not sent it yet.',
  ),

  /// Sent, waiting for the LGU.
  pendingReview(
    'Waiting for review',
    'Taytay LGU has your details and is checking them.',
  ),

  /// The office needs something corrected or added.
  needsMoreInformation(
    'More information needed',
    'Taytay LGU needs something corrected before it can finish checking.',
  ),

  /// Done.
  verified('Verified', 'Taytay LGU has confirmed your identity.'),

  /// The office could not confirm the identity from what was sent.
  unsuccessful(
    'Could not be verified',
    'Taytay LGU could not confirm your identity from what was sent.',
  ),

  /// Automatic checking is not possible; a person needs to look at it.
  ///
  /// Also the destination for any server state this build does not recognise —
  /// see the class doc. It is the safe default because it always has a real
  /// next step that does not depend on the app working.
  manualReview(
    'Needs a person to check',
    'This needs Taytay LGU staff to check it in person.',
  );

  const ResidentVerificationStage(this.label, this.summary);

  /// Short status word shown as the headline.
  final String label;

  /// One plain sentence. No turnaround estimate — see [nextActionLabel].
  final String summary;

  /// Whether the resident has something to do.
  bool get needsResidentAction =>
      this == ResidentVerificationStage.notStarted ||
      this == ResidentVerificationStage.inProgress ||
      this == ResidentVerificationStage.needsMoreInformation ||
      this == ResidentVerificationStage.unsuccessful;

  /// Whether visiting the municipal hall is the recommended route.
  bool get suggestsInPerson =>
      this == ResidentVerificationStage.manualReview ||
      this == ResidentVerificationStage.unsuccessful;

  /// The button a resident sees, or `null` when there is nothing to press.
  String? get nextActionLabel => switch (this) {
    ResidentVerificationStage.notStarted => 'Start verification',
    ResidentVerificationStage.inProgress => 'Continue verification',
    ResidentVerificationStage.needsMoreInformation => 'Fix and resend',
    ResidentVerificationStage.unsuccessful => 'Try again',
    ResidentVerificationStage.pendingReview => null,
    ResidentVerificationStage.verified => null,
    ResidentVerificationStage.manualReview => null,
  };

  /// Maps a server state onto a resident stage.
  ///
  /// `null` — meaning this build did not recognise what the server sent — maps
  /// to [manualReview] deliberately. Fail closed: never to `verified`.
  static ResidentVerificationStage fromAttemptState(
    VerificationAttemptState? state,
  ) => switch (state) {
    VerificationAttemptState.notStarted => ResidentVerificationStage.notStarted,
    VerificationAttemptState.draft => ResidentVerificationStage.inProgress,
    VerificationAttemptState.submitted ||
    VerificationAttemptState.underReview =>
      ResidentVerificationStage.pendingReview,
    // The office is waiting on the resident. Until TAB 04 this state had no
    // server value behind it and could never be reached; `needs-more-information`
    // has been published since backend TAB 06.
    VerificationAttemptState.needsMoreInformation =>
      ResidentVerificationStage.needsMoreInformation,
    VerificationAttemptState.approved => ResidentVerificationStage.verified,
    VerificationAttemptState.rejected => ResidentVerificationStage.unsuccessful,
    // Withdrawn and expired both end with nothing on file and a resident free to
    // start again — which is `notStarted` from where they are standing, and is
    // deliberately not `unsuccessful`: being told you were refused when a clock
    // ran out is a different conversation at a counter.
    VerificationAttemptState.withdrawn ||
    VerificationAttemptState.expired => ResidentVerificationStage.notStarted,
    null => ResidentVerificationStage.manualReview,
  };
}

/// A kind of thing a resident submitted.
///
/// ---
///
/// **Categories, never contents.** The status screen tells a resident *which
/// kinds* of information the LGU holds for their attempt — "your details", "your
/// address", "photo of your ID" — and never echoes the values back. Re-rendering
/// a birth date or an ID image on a status screen puts personal data on a screen
/// that may be read over a shoulder in a queue, for no purpose the resident does
/// not already know.
enum VerificationItemCategory {
  personalDetails('Your details', 'Name and date of birth'),
  address('Your address', 'Barangay and street', field: 'street_address'),
  contact('Contact details', 'Mobile number', field: 'mobile_number'),
  identityDocument('Proof of identity', 'Government-issued ID'),
  photo('Photo of you', 'Used to check the ID belongs to you');

  const VerificationItemCategory(this.label, this.description, {this.field});

  final String label;
  final String description;

  /// The correctable field on `POST me/profile/corrections`, when this category
  /// maps to exactly one.
  ///
  /// **Null is the common case and is deliberate.** The two contracts are keyed
  /// differently: this app groups what a resident recognises — "your details",
  /// "proof of identity" — and the server takes named fields. "Your details" is
  /// three of them (`first_name`, `last_name`, `birth_date`) and a document is
  /// none of them; picking one on the resident's behalf would file a correction
  /// against a field the office never questioned, and re-typing a name into a
  /// birth-date correction is the kind of error nobody notices until a
  /// caseworker reads it.
  ///
  /// So a category with no single field is not sent. Raised as F23: closing it
  /// properly needs either per-field correction in the app's own model or a
  /// server route that accepts a KYC correction keyed the way the office asks
  /// for it — a contract conversation, not a client workaround.
  final String? field;

  /// Maps a server category code, falling back to `null` for anything this
  /// build does not recognise. An unknown category is dropped from the list
  /// rather than shown as a raw code a resident cannot act on.
  static VerificationItemCategory? fromCode(String? code) {
    if (code == null) return null;
    for (final value in VerificationItemCategory.values) {
      if (value.name == code) return value;
    }
    return null;
  }
}

/// Something the office needs corrected.
///
/// Carries a category and a resident-facing instruction — **never** a reviewer's
/// name, an internal note, a score, or a reason code that would let a resident
/// (or anyone reading over their shoulder) infer how the matching works.
@immutable
class VerificationItemIssue {
  const VerificationItemIssue({
    required this.category,
    required this.instruction,
  });

  final VerificationItemCategory category;

  /// What to do, phrased for the resident. Supplied by the server, because only
  /// the reviewing office knows what was wrong with a specific submission.
  final String instruction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerificationItemIssue &&
          other.category == category &&
          other.instruction == instruction);

  @override
  int get hashCode => Object.hash(category, instruction);

  /// Redacted: an instruction can quote what a resident submitted.
  @override
  String toString() => 'VerificationItemIssue(${category.name})';
}

/// The full resident-facing picture of one verification attempt.
///
/// ---
///
/// **What this type cannot hold.** There is deliberately no field for a reviewer
/// identity, a risk or fraud score, caseworker notes, an audit trail, candidate
/// matches, or a rejection heuristic. The committed client-visibility matrix
/// lists reviewer identity and internal review notes among the fields that
/// "never appear in any citizen or verifier response, in any endpoint, ever",
/// and a citizen projection is built "by naming the fields to include, never by
/// taking the staff projection and removing some".
///
/// This class is that named list. A server that sent more would find nowhere to
/// put it — asserted in `verification_test.dart`.
@immutable
class VerificationStatusDetail {
  const VerificationStatusDetail({
    required this.stage,
    required this.rawState,
    this.submittedCategories = const <VerificationItemCategory>[],
    this.issues = const <VerificationItemIssue>[],
    this.residentGuidance,
    this.manualReviewAvailable = false,
    this.submittedAt,
  });

  /// Nothing known yet — the initial state before a load completes.
  static const VerificationStatusDetail unknown = VerificationStatusDetail(
    stage: ResidentVerificationStage.notStarted,
    rawState: '',
  );

  final ResidentVerificationStage stage;

  /// The server's own value, preserved for support without being rendered as
  /// the status a resident reads.
  final String rawState;

  /// Kinds of information the LGU holds for this attempt.
  final List<VerificationItemCategory> submittedCategories;

  /// What needs fixing, when the office said so.
  final List<VerificationItemIssue> issues;

  /// Server-composed, resident-addressed guidance.
  ///
  /// The one place server text is shown, and for the same reason a validation
  /// message is: only the reviewing office knows what was wrong with a
  /// particular submission, so the app cannot compose this for itself.
  final String? residentGuidance;

  /// Whether an in-person route at the municipal hall is offered.
  final bool manualReviewAvailable;

  final DateTime? submittedAt;

  bool get isVerified => stage == ResidentVerificationStage.verified;

  bool get hasIssues => issues.isNotEmpty;

  /// True when this build did not recognise the server's state.
  bool get isUnrecognised =>
      stage == ResidentVerificationStage.manualReview && rawState.isNotEmpty;

  /// Redacted: guidance and issues can quote submitted values.
  @override
  String toString() =>
      'VerificationStatusDetail(${stage.name}, '
      'categories: ${submittedCategories.length}, issues: ${issues.length})';
}
