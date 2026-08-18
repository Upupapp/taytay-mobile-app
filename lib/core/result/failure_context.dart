import 'app_failure.dart';

/// Where a failure happened, for the codes that mean different things depending.
///
/// ---
///
/// **One code, several meanings, and the generic copy wastes the only moment a
/// resident is paying attention.** `CONFLICT` is the clearest case: registering
/// for an event it means somebody took the last place; submitting an assistance
/// draft it means the application has already been filed; withdrawing a
/// correction it means a caseworker has already decided it. "There was a
/// conflict" is true for all three and useful for none.
///
/// Deliberately a small closed set rather than a free-form string. A context
/// that can be anything ends up carrying a screen name, then a path, then
/// something with an id in it — and error copy is exactly the surface where a
/// stray identifier gets read aloud in a queue.
enum FailureContext {
  signIn,
  assistanceSubmission,
  documentUpload,
  eventRegistration,
  correction,

  /// No more specific reading applies. Falls back to the taxonomy's own copy.
  general,
}

/// The resident-facing sentence for [failure] as it occurred in [context].
///
/// Falls through to [AppFailure.residentMessage] wherever the context adds
/// nothing — most failures mean the same thing everywhere, and inventing a
/// variant per screen would give thirteen features thirteen dialects of the same
/// sentence, which is the condition this sweep exists to end.
String contextualResidentMessage(
  AppFailure failure,
  FailureContext context,
) => switch ((failure, context)) {
  // A conflict is somebody else's success, or your own earlier one.
  (ConflictFailure(), FailureContext.eventRegistration) =>
    'That event filled up while you were deciding. If there is a waitlist you '
        'can still join it.',
  (ConflictFailure(), FailureContext.assistanceSubmission) =>
    'This application has already been sent to Taytay LGU. You do not need to '
        'send it again.',
  (ConflictFailure(), FailureContext.correction) =>
    'Taytay LGU has already decided on this request, so it can no longer be '
        'changed.',

  // A not-found on a write is almost never "we could not find the page".
  (NotFoundFailure(), FailureContext.eventRegistration) =>
    'That event is no longer listed. It may have been cancelled or already '
        'taken place.',
  (NotFoundFailure(), FailureContext.correction) =>
    'That request is no longer listed. It may have already been decided.',

  // A forbidden on an upload usually means the case moved on, not that the
  // resident did something wrong — and blaming them is the worse guess.
  (ForbiddenFailure(), FailureContext.documentUpload) =>
    'Taytay LGU is not accepting documents for this request at the moment. '
        'Check the request for what is needed next.',

  // Rate limiting on sign-in is the one refusal that says nothing about the
  // account, which is why it can be specific without disclosing anything.
  (RateLimitedFailure(), FailureContext.signIn) =>
    'Too many attempts. Please wait a little while before asking for another '
        'code.',

  _ => failure.residentMessage,
};
