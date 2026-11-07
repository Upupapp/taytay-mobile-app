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

/// The status in plain words. `null` is a status this build does not know: a
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

/// One line of a request's history, in the resident's words.
///
/// Composed here rather than taken from the server's `description`, so the
/// copy a resident reads is this app's own and can be translated with the rest
/// of it. The office's own message travels beside the line, unchanged.
String issuanceHistoryLine({
  required IssuanceStatus? from,
  required IssuanceStatus? to,
}) {
  if (from == null && to == IssuanceStatus.submitted) {
    return 'You sent the request';
  }
  if (to == IssuanceStatus.cancelled) return 'You cancelled the request';
  if (from == IssuanceStatus.needsInfo && to == IssuanceStatus.underReview) {
    return 'You sent what the office asked for';
  }
  return switch (to) {
    IssuanceStatus.underReview => 'The office started reviewing it',
    IssuanceStatus.needsInfo => 'The office asked for more',
    IssuanceStatus.approved => 'The office approved it',
    IssuanceStatus.rejected => 'The office could not issue it',
    IssuanceStatus.readyForPickup => 'Ready to claim',
    IssuanceStatus.released => 'The office released the document',
    IssuanceStatus.submitted => 'Sent to the office',
    IssuanceStatus.cancelled => 'You cancelled the request',
    null => 'The request was updated',
  };
}
