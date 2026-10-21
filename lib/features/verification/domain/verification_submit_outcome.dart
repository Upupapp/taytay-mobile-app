import '../../../core/result/app_failure.dart';

/// What the account wizard does after `POST /me/verification-requests`.
///
/// `201` opens the submitted step. `409` is a request already pending, so the
/// resident is taken to the pending-review status screen. `403` is
/// [VerificationSubmitOutcome.continueVerified]: the wizard then reads
/// `GET /me` and goes home only when that tier is verified. Staff and admin
/// accounts also receive 403, so the status alone is not a verified session.
/// Every other failure stays on the wizard and is explained with this app's
/// own copy.
enum VerificationSubmitOutcome {
  opened,
  pendingReview,
  continueVerified,
  failed,
}

/// Maps the failure from that one call. `null` is the `201`.
VerificationSubmitOutcome verificationSubmitOutcome(AppFailure? failure) {
  return switch (failure) {
    null => VerificationSubmitOutcome.opened,
    ConflictFailure() => VerificationSubmitOutcome.pendingReview,
    ForbiddenFailure() => VerificationSubmitOutcome.continueVerified,
    _ => VerificationSubmitOutcome.failed,
  };
}
