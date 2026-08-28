/// What a client-side validation error *is*, apart from the words for it.
///
/// ## Why a `FieldError` needs this at all
///
/// `FieldError.message` is a mixed carrier and always has been. Some of what it
/// holds is composed by this app; the rest is the server's own validation text,
/// which Article 5.5 lets through deliberately — a validation message shown
/// beside the field it belongs to is the one piece of server prose a resident is
/// allowed to read, because only the server knows what was wrong with a
/// particular value.
///
/// That mix is why the client half stayed English. A localiser cannot translate
/// a `String` without knowing which half it came from, so both halves were
/// rendered as-is and the app's own sentences — *"Describe what you need help
/// with, in your own words."* — reached Filipino readers in English on a screen
/// they use to apply for assistance.
///
/// So the client half now carries a **kind** as well as a sentence. A
/// `FieldError` with a kind is this app's, and the screen renders it in the
/// reader's language; one without is the server's, and its text is shown
/// untouched. The English stays on the error as the no-context fallback, the
/// same arrangement `AppFailure.residentMessage` uses.
enum ValidationMessage {
  /// The applicant has not confirmed the details are theirs.
  confirmDetails,

  /// The free-text description of what is needed is empty.
  narrativeMissing,

  /// The free-text description is longer than the server's own limit.
  narrativeTooLong,

  /// A required consent has not been given.
  consentRequired,

  /// A required question has no answer, phrased for the kind of question.
  answerMissingChoice,
  answerMissingYesNo,
  answerMissingDate,
  answerMissingNumber,
  answerMissingGeneric,

  /// A number question was given something that is not a number.
  answerNotANumber,

  /// A free-text answer is longer than the server's declared maximum.
  answerTooLong,
}
