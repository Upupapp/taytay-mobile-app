/// Document requests and their terms, in the resident's language.
///
/// The domain keeps the English sentences (`issuanceStatusLabel`,
/// `issuanceFeeLine`, …) as the no-context fallback, because the domain may
/// not import Flutter or the generated strings. Every screen renders through
/// these instead, so a phone set to Filipino never reads a status in English.
library;

import '../../features/issuance/domain/issuance_form.dart';
import '../../features/issuance/domain/issuance_status.dart';
import '../../features/issuance/domain/issuance_terms.dart';
import '../../l10n/app_localizations.dart';
import '../documents/upload_policy.dart';

/// The status in plain words. `null` is a status this build does not know.
String issuanceStatusText(AppStrings strings, IssuanceStatus? status) =>
    switch (status) {
      IssuanceStatus.submitted => strings.issuanceStatusSubmitted,
      IssuanceStatus.underReview => strings.issuanceStatusUnderReview,
      IssuanceStatus.needsInfo => strings.issuanceStatusNeedsInfo,
      IssuanceStatus.approved => strings.issuanceStatusApproved,
      IssuanceStatus.readyForPickup => strings.issuanceStatusReadyForPickup,
      IssuanceStatus.released => strings.issuanceStatusReleased,
      IssuanceStatus.rejected => strings.issuanceStatusRejected,
      IssuanceStatus.cancelled => strings.assistanceStageCancelled,
      null => strings.issuanceStatusUpdated,
    };

/// What the status means for the resident, and what happens next.
String issuanceStatusExplanationText(
  AppStrings strings,
  IssuanceStatus? status,
) => switch (status) {
  IssuanceStatus.submitted => strings.issuanceExplainSubmitted,
  IssuanceStatus.underReview => strings.issuanceExplainUnderReview,
  IssuanceStatus.needsInfo => strings.issuanceExplainNeedsInfo,
  IssuanceStatus.approved => strings.issuanceExplainApproved,
  IssuanceStatus.readyForPickup => strings.issuanceExplainReadyForPickup,
  IssuanceStatus.released => strings.issuanceExplainReleased,
  IssuanceStatus.rejected => strings.issuanceExplainRejected,
  IssuanceStatus.cancelled => strings.issuanceExplainCancelled,
  null => strings.issuanceExplainUpdated,
};

/// One line of a request's history. The move is decided in the domain
/// (`issuanceHistoryMove`), so this and the English fallback cannot disagree.
String issuanceHistoryText(
  AppStrings strings, {
  required IssuanceStatus? from,
  required IssuanceStatus? to,
}) => switch (issuanceHistoryMove(from: from, to: to)) {
  IssuanceHistoryMove.sent => strings.issuanceHistorySent,
  IssuanceHistoryMove.cancelled => strings.issuanceHistoryCancelled,
  IssuanceHistoryMove.answered => strings.issuanceHistoryAnswered,
  IssuanceHistoryMove.reviewStarted => strings.issuanceHistoryReviewStarted,
  IssuanceHistoryMove.askedForMore => strings.issuanceHistoryAskedForMore,
  IssuanceHistoryMove.approved => strings.issuanceHistoryApproved,
  IssuanceHistoryMove.refused => strings.issuanceHistoryRefused,
  IssuanceHistoryMove.ready => strings.issuanceStatusReadyForPickup,
  IssuanceHistoryMove.released => strings.issuanceHistoryReleased,
  IssuanceHistoryMove.submitted => strings.issuanceStatusSubmitted,
  IssuanceHistoryMove.updated => strings.issuanceHistoryUpdated,
};

/// The fee line. `null` is "not stated", which is not "free"; zero is a
/// stated fee of nothing. The amount stays integer centavos to the end.
String issuanceFeeText(AppStrings strings, int? feeCentavos) {
  if (feeCentavos == null) return strings.issuanceFeeNotStated;
  if (feeCentavos == 0) return strings.issuanceFeeNone;
  return strings.issuanceFee(formatPesos(feeCentavos));
}

/// Working days from the office's Citizen's Charter.
String issuanceProcessingText(AppStrings strings, int? processingDays) {
  if (processingDays == null) return strings.issuanceProcessingNotStated;
  if (processingDays <= 0) return strings.issuanceProcessingSameDay;
  return strings.issuanceProcessingDays(processingDays);
}

/// "JPEG, PDF or PNG, up to 10 MB each", from the server's `accepts` block.
/// The type names are the same in every language.
String acceptedFilesText(AppStrings strings, UploadPolicy policy) {
  final List<String> kinds = acceptedFileKinds(policy);
  final String list = switch (kinds.length) {
    0 => strings.issuanceAcceptedAnyFile,
    1 => kinds.first,
    _ => strings.issuanceAcceptedOr(
      kinds.sublist(0, kinds.length - 1).join(', '),
      kinds.last,
    ),
  };
  return strings.issuanceAcceptedLine(list, policy.maxMegabytes);
}

/// Why a purpose cannot be sent.
String purposeProblemMessage(AppStrings strings, PurposeProblem problem) =>
    switch (problem) {
      PurposeProblem.empty => strings.issuancePurposeEmpty,
      PurposeProblem.tooShort => strings.applyPurposeTooShort(
        issuancePurposeMin,
      ),
      PurposeProblem.tooLong => strings.applyPurposeTooLong(issuancePurposeMax),
    };
