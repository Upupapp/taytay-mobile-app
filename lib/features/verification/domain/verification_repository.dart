import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import 'verification_status_detail.dart';

/// Where a resident's verification attempt has reached, as the server reports it.
///
/// The `Verification` module owns "verification attempts, scan events, verifier
/// registry" per the committed boundary map. Wire values are not published, so
/// none are assigned here.
enum VerificationAttemptState {
  notStarted,
  draft,
  submitted,
  underReview,
  approved,
  rejected;

  /// Whether the resident has something to do next.
  bool get needsResidentAction =>
      this == VerificationAttemptState.notStarted ||
      this == VerificationAttemptState.draft ||
      this == VerificationAttemptState.rejected;
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
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  });

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
