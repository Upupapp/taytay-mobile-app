import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import 'correctable_field.dart';
import 'kyc_claim.dart';
import 'verification_status_detail.dart';

/// Where a resident's verification attempt has reached, as the server reports it.
///
/// **These are `ResidentProfile`'s KYC states, not the `Verification` module's.**
/// This file used to name `Verification` and say wire values were not
/// published. Both were wrong: `Verification` is the verifier-device side (F17),
/// and `GET me/kyc` has published nine states since backend TAB 06. They are
/// mapped in [parse].
enum VerificationAttemptState {
  notStarted,
  draft,
  submitted,

  /// Automatic matching, or a reviewer holding it. Two server states —
  /// `screening` and `manual-review` — with one resident meaning: somebody or
  /// something is looking at it and there is nothing to do but wait. Kept as one
  /// state here because splitting them would put the office's internal handover
  /// on a resident's screen without giving them anything to act on.
  underReview,

  /// **The office asked for something.** The one non-terminal state with a
  /// resident action in it, and the one this enum was missing: the server has
  /// published `needs-more-information` since backend TAB 06 and the app had no
  /// value for it, so a resident whose application was waiting on *them* would
  /// have been shown a state that did not exist.
  needsMoreInformation,

  approved,
  rejected,

  /// The applicant withdrew it. Terminal.
  withdrawn,

  /// Left unattended past its window. Terminal, and the applicant may start
  /// again — which is why it is not folded into [rejected]: one is a decision
  /// about them and the other is a clock, and telling a resident they were
  /// refused when they were not is a different conversation at a counter.
  expired;

  /// Whether the resident has something to do next.
  bool get needsResidentAction =>
      this == VerificationAttemptState.notStarted ||
      this == VerificationAttemptState.draft ||
      this == VerificationAttemptState.needsMoreInformation ||
      this == VerificationAttemptState.expired;

  /// Nothing further will happen to this attempt.
  bool get isTerminal =>
      this == VerificationAttemptState.approved ||
      this == VerificationAttemptState.rejected ||
      this == VerificationAttemptState.withdrawn ||
      this == VerificationAttemptState.expired;

  /// The wire values `GET me/kyc` publishes, mapped.
  ///
  /// Unrecognised values resolve to [underReview] rather than to a state with a
  /// resident action in it. A new server state this build has never heard of
  /// must not tell somebody to do something — "we are looking at it" is the
  /// answer that is still true whatever the new state turns out to mean.
  static VerificationAttemptState parse(String? wireValue) =>
      switch (wireValue) {
        'draft' => VerificationAttemptState.draft,
        'submitted' => VerificationAttemptState.submitted,
        'screening' || 'manual-review' => VerificationAttemptState.underReview,
        'needs-more-information' =>
          VerificationAttemptState.needsMoreInformation,
        'approved' => VerificationAttemptState.approved,
        'rejected' => VerificationAttemptState.rejected,
        'withdrawn' => VerificationAttemptState.withdrawn,
        'expired' => VerificationAttemptState.expired,
        null => VerificationAttemptState.notStarted,
        _ => VerificationAttemptState.underReview,
      };
}

/// The state of the resident's own verification, with the next step.
@immutable
class VerificationStatus {
  const VerificationStatus({
    required this.state,
    required this.rawState,
    this.residentGuidance,
  });

  final VerificationAttemptState? state;

  /// The server's own value, preserved.
  final String rawState;

  /// Server-supplied, resident-safe guidance on what to do next, when the
  /// server chooses to send it.
  ///
  /// **The exception to "never render the server's message".** That rule
  /// (CLAUDE.md Article 5.5) is about the operator-facing `error.message`. This
  /// is a deliberate `data` field addressed to the resident — the same category
  /// as a validation message shown next to its field — and rejection reasons are
  /// the one thing the app cannot compose for itself, because only the reviewing
  /// office knows why. It is rendered only where a status is being explained.
  final String? residentGuidance;
}

/// Identity verification for the signed-in resident.
///
/// **The app captures; the server decides.** There is no method here that
/// submits a pass/fail, a liveness score or a biometric template. A released
/// mobile build cannot be trusted to grade its own verification (backend
/// ADR 0002 context), and a biometric template is not revocable the way a
/// password is.
abstract interface class VerificationRepository {
  /// The signed-in resident's own verification status.
  Future<Result<VerificationStatus>> loadOwnStatus();

  /// The full resident-facing picture: stage, submitted categories, anything
  /// needing correction, and whether an in-person route is offered.
  ///
  /// Added in TAB 08 alongside [loadOwnStatus] rather than replacing it —
  /// additive evolution, so nothing that already reads the simple status
  /// breaks. Both map the same server state; this one carries what the status
  /// screen needs.
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail();

  /// Opens the resident's KYC case with what they claim about themselves.
  ///
  /// **This is the door to the Verified state, and it was shut for the whole
  /// integration sequence.** `POST me/kyc` requires a barangay, the only
  /// identifier it accepted was an auto-increment primary key no route
  /// published, and so no client could open a case — which put the Verified
  /// tier, the digital ID and every service resting on them out of reach. That
  /// was F14. The backend now publishes `GET barangays` and accepts the code it
  /// publishes, so [KycClaim.barangayCode] is what a claim is filed against.
  ///
  /// **Idempotent by account, server-side**: the case is resolved from the
  /// authenticated actor, so opening twice returns the same case rather than
  /// creating a second one. [idempotencyKey] is still sent, because the app does
  /// not get to rely on a server-side guarantee it cannot see, and a retried
  /// request that creates a duplicate municipal case is not recoverable from
  /// this side.
  ///
  /// Returns the case's state, so a caller that has just opened one shows the
  /// server's answer rather than assuming `draft`.
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  });

  /// Resends only the items the office asked to have corrected.
  ///
  /// Deliberately narrower than [submitForReview]: a resident answering a
  /// "needs more information" request should not have to redo the whole
  /// submission, and re-sending everything would mean re-uploading an identity
  /// document the office already holds and has not questioned.
  ///
  /// [corrections] is keyed by the category the office flagged, so a caller
  /// cannot send a correction for something that was never in question.
  ///
  /// [idempotencyKey] is required: a resend that arrives twice is a second item
  /// in a municipal review queue.
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
  });

  /// Attaches a document to the resident's open case (F28).
  ///
  /// **The bytes, not a reference.** There is no upload-then-reference dance
  /// here because the server has no staging area: one request carries the file
  /// and the slot it belongs in, and either the office has it or it does not.
  ///
  /// Accepted only while the case is the resident's to change — `draft`, or
  /// `needs-more-information` when the office has asked for something. A
  /// document sent after submission would change what a reviewer already looked
  /// at without their knowing.
  ///
  /// [idempotencyKey] is required: an upload is the request most likely to be
  /// retried, because it is long and runs on the worst connections.
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  });

  /// What the office holds for this case, one row per type.
  ///
  /// Every type is reported whether or not something was sent, so a resident can
  /// see that they have attached nothing — the state most easily mistaken for
  /// having attached something.
  Future<Result<List<KycDocument>>> loadDocuments();

  /// Submits captured evidence for review.
  ///
  /// [documentUploadIds] are references to material already uploaded, not the
  /// bytes: an identity document should not be re-sent on every retry, and a
  /// reference lets the server tie the upload to the attempt.
  ///
  /// [idempotencyKey] is required — resubmitting a verification because a
  /// connection dropped must not create a second review in the office's queue.
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  });
}
