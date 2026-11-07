import '../../../core/result/result.dart';

/// The three things a resident sends about a document request.
enum IssuanceAct {
  submit('Nothing was sent.'),
  resubmit('Nothing was sent.'),
  cancel('Nothing was cancelled.');

  const IssuanceAct(this.nothing);

  /// The sentence for the act that failed.
  final String nothing;
}

/// What a resident reads when sending to the office did not go through.
///
/// Every line is this app's own. The server's `message` is written for an
/// operator and never reaches the screen (Article 5.5); the failure's kind is
/// what decides the words. Each one says whether anything reached the office,
/// because "did it go?" is the question a resident has at that moment.
({String title, String body, bool offerVerification}) issuanceSendFailure(
  AppFailure failure, {
  required IssuanceAct act,
}) {
  final String nothing = act.nothing;
  return switch (failure) {
    // `VERIFICATION_REQUIRED`: the server said why, so the way on is offered.
    ForbiddenFailure(requiresVerification: true) => (
      title: 'Only verified residents can do this',
      body:
          '$nothing Taytay LGU does not have your account as verified. Finish '
          'verification first, then come back to this page.',
      offerVerification: true,
    ),
    // A plain `FORBIDDEN` is a different refusal — a staff account, for one.
    // The app does not guess which, and verification would not help.
    ForbiddenFailure() => (
      title: 'Not available for this account',
      body:
          '$nothing Document requests are not open to this account. The '
          'municipal hall can tell you more.',
      offerVerification: false,
    ),
    NetworkFailure() => (
      title: 'You are offline',
      body:
          '$nothing Your answers are still here on the phone. Connect to the '
          'internet and try again.',
      offerVerification: false,
    ),
    TimeoutFailure() => (
      title: 'No answer from Taytay LGU',
      body:
          'We cannot tell whether it arrived. Try again: it will not be sent '
          'twice. Or open My document requests to check first.',
      offerVerification: false,
    ),
    ValidationFailure() => (
      title: 'Something needs another look',
      body:
          '$nothing The office could not accept part of it. The items marked '
          'below need checking.',
      offerVerification: false,
    ),
    UnacceptableUploadFailure() => (
      title: 'A file could not be accepted',
      body:
          '$nothing A file was too large or could not be read. Choose a smaller '
          'photo or another file, and try again.',
      offerVerification: false,
    ),
    RateLimitedFailure() => (
      title: 'Too many tries',
      body: '$nothing Wait a few minutes, then try again.',
      offerVerification: false,
    ),
    // A new request has no state to conflict with. A 409 on a submit means
    // its key was already used for something else: a fault in this app, not
    // anything the resident did. Said plainly, and nothing about it is logged.
    ConflictFailure() when act == IssuanceAct.submit => (
      title: 'It did not go through',
      body:
          '$nothing Something went wrong on our side. Open My document '
          'requests to check what the office has before trying again.',
      offerVerification: false,
    ),
    ConflictFailure() => (
      title: 'The request has moved on',
      body:
          '$nothing The office has already acted on it. Go back and open it '
          'again to see where it stands.',
      offerVerification: false,
    ),
    NotFoundFailure() => (
      title: 'No longer available',
      body:
          '$nothing The office no longer lists this. Go back to the list to see '
          'what is available.',
      offerVerification: false,
    ),
    UnauthenticatedFailure() => (
      title: 'Please sign in again',
      body: '$nothing Your session ended. Sign in, then try again.',
      offerVerification: false,
    ),
    ServerFailure() ||
    ContractFailure() ||
    UnexpectedFailure() ||
    CodeExchangeFailure() => (
      title: 'It did not go through',
      body: '$nothing Something went wrong on our side. Try again in a moment.',
      offerVerification: false,
    ),
  };
}
