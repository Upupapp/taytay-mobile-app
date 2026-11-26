/// Where a document request stands, as the server's lifecycle names it.
///
/// The backend owns the transitions (`src/modules/issuance/lifecycle.ts`). This
/// app never moves a request by itself: cancelling and resubmitting are asked
/// of the server, which answers with the request as it now is, and whether a
/// resident may cancel or resubmit is read from `can_cancel` and
/// `can_resubmit` rather than worked out from the status here.
enum IssuanceStatus {
  submitted,
  underReview,
  needsInfo,
  approved,
  readyForPickup,
  released,
  rejected,
  cancelled;

  /// Nothing further happens to the request.
  bool get isFinished => switch (this) {
    released || rejected || cancelled => true,
    submitted ||
    underReview ||
    needsInfo ||
    approved ||
    readyForPickup => false,
  };

  /// The resident has something to do: send more, or go to the counter.
  bool get asksSomethingOfResident =>
      this == IssuanceStatus.needsInfo || this == IssuanceStatus.readyForPickup;
}

/// Who made a move in a request's history.
enum IssuanceActor { resident, office, unknown }

/// The status in plain words, in English: the no-context fallback; screens use
/// `issuanceStatusText`. `null` is a status this build does not know: a
/// newer server, which must never crash a released app (Article 8).
String issuanceStatusLabel(IssuanceStatus? status) => switch (status) {
  IssuanceStatus.submitted => 'Sent to the office',
  IssuanceStatus.underReview => 'Being reviewed',
  IssuanceStatus.needsInfo => 'Needs more from you',
  IssuanceStatus.approved => 'Approved, being prepared',
  IssuanceStatus.readyForPickup => 'Ready to claim',
  IssuanceStatus.released => 'Claimed',
  IssuanceStatus.rejected => 'Not issued',
  IssuanceStatus.cancelled => 'Cancelled',
  null => 'Updated',
};

/// One sentence saying what the status means for the resident, and what
/// happens next.
String issuanceStatusExplanation(IssuanceStatus? status) => switch (status) {
  IssuanceStatus.submitted =>
    'The office has your request. Nobody has started on it yet.',
  IssuanceStatus.underReview =>
    'The office is checking your request and your files. Nothing is needed '
        'from you now.',
  IssuanceStatus.needsInfo =>
    'The office needs something more before it can go on. Read what they '
        'asked for, then send it here.',
  IssuanceStatus.approved =>
    'The office approved your request and is preparing the document. You will '
        'be told here when it is ready.',
  IssuanceStatus.readyForPickup =>
    'Your document is ready. Read below when and where to claim it.',
  IssuanceStatus.released => 'The office released the document to you.',
  IssuanceStatus.rejected =>
    'The office could not issue this document. Their reason is below.',
  IssuanceStatus.cancelled => 'This request was cancelled.',
  null =>
    'The office updated this request. Ask the office if anything is '
        'unclear.',
};

/// One move in a request's history, as the resident reads it.
///
/// Decided here, once, so the English line below and the translated line in
/// `core/l10n/issuance_copy.dart` cannot disagree about which move it was.
enum IssuanceHistoryMove {
  sent,
  cancelled,
  answered,
  reviewStarted,
  askedForMore,
  approved,
  refused,
  ready,
  released,
  submitted,
  updated,
}

IssuanceHistoryMove issuanceHistoryMove({
  required IssuanceStatus? from,
  required IssuanceStatus? to,
}) {
  if (from == null && to == IssuanceStatus.submitted) {
    return IssuanceHistoryMove.sent;
  }
  if (to == IssuanceStatus.cancelled) return IssuanceHistoryMove.cancelled;
  if (from == IssuanceStatus.needsInfo && to == IssuanceStatus.underReview) {
    return IssuanceHistoryMove.answered;
  }
  return switch (to) {
    IssuanceStatus.underReview => IssuanceHistoryMove.reviewStarted,
    IssuanceStatus.needsInfo => IssuanceHistoryMove.askedForMore,
    IssuanceStatus.approved => IssuanceHistoryMove.approved,
    IssuanceStatus.rejected => IssuanceHistoryMove.refused,
    IssuanceStatus.readyForPickup => IssuanceHistoryMove.ready,
    IssuanceStatus.released => IssuanceHistoryMove.released,
    IssuanceStatus.submitted => IssuanceHistoryMove.submitted,
    IssuanceStatus.cancelled => IssuanceHistoryMove.cancelled,
    null => IssuanceHistoryMove.updated,
  };
}

/// One line of a request's history, in the resident's words.
///
/// Composed here rather than taken from the server's `description`, so the
/// copy a resident reads is this app's own and can be translated with the rest
/// of it. The office's own message travels beside the line, unchanged. This is
/// the English, no-context fallback; screens use `issuanceHistoryText`.
String issuanceHistoryLine({
  required IssuanceStatus? from,
  required IssuanceStatus? to,
}) => switch (issuanceHistoryMove(from: from, to: to)) {
  IssuanceHistoryMove.sent => 'You sent the request',
  IssuanceHistoryMove.cancelled => 'You cancelled the request',
  IssuanceHistoryMove.answered => 'You sent what the office asked for',
  IssuanceHistoryMove.reviewStarted => 'The office started reviewing it',
  IssuanceHistoryMove.askedForMore => 'The office asked for more',
  IssuanceHistoryMove.approved => 'The office approved it',
  IssuanceHistoryMove.refused => 'The office could not issue it',
  IssuanceHistoryMove.ready => 'Ready to claim',
  IssuanceHistoryMove.released => 'The office released the document',
  IssuanceHistoryMove.submitted => 'Sent to the office',
  IssuanceHistoryMove.updated => 'The request was updated',
};
