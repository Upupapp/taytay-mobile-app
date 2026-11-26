import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';

/// The three things a resident sends about a document request.
enum IssuanceAct {
  submit(
    'Nothing was sent.',
    'We could not confirm that your request was received. Sending the same '
        'request again is safe: it will not be filed twice. You can also '
        'check My document requests.',
  ),
  resubmit(
    'Nothing was sent.',
    'We could not confirm that your changes were received. Sending them again '
        'is safe: they will not be filed twice. You can also go back and open '
        'the request to check.',
  ),
  cancel(
    'Nothing was cancelled.',
    'We could not confirm that your cancellation was received. Trying again '
        'is safe: the request is cancelled only once. You can also go back and '
        'open the request to check.',
  );

  const IssuanceAct(this.nothing, this.unconfirmed);

  /// The sentence for an act that certainly did not reach the office.
  final String nothing;

  /// The sentence for an act that may have reached the office.
  ///
  /// True because every act carries an idempotency key that is kept for the
  /// retry (`IssuanceSendKey`): the server answers a repeat with what the
  /// first one did, and never acts twice.
  final String unconfirmed;

  /// [nothing] in the resident's language. The constant above is the English
  /// fallback, kept so a test can read it without a locale.
  String nothingIn(AppStrings strings) => switch (this) {
    IssuanceAct.submit || IssuanceAct.resubmit => strings.issuanceNothingSent,
    IssuanceAct.cancel => strings.issuanceNothingCancelled,
  };

  /// [unconfirmed] in the resident's language.
  String unconfirmedIn(AppStrings strings) => switch (this) {
    IssuanceAct.submit => strings.issuanceUnconfirmedSubmit,
    IssuanceAct.resubmit => strings.issuanceUnconfirmedResubmit,
    IssuanceAct.cancel => strings.issuanceUnconfirmedCancel,
  };
}

/// What a resident reads when sending to the office did not go through.
///
/// Every line is this app's own. The server's `message` is written for an
/// operator and never reaches the screen (Article 5.5); the failure's kind is
/// what decides the words. Each one says whether anything reached the office,
/// because "did it go?" is the question a resident has at that moment.
///
/// [strings] is the resident's language (`AppStrings.of(context)`); without
/// it the English strings are used, as a test reads them.
({String title, String body, bool offerVerification}) issuanceSendFailure(
  AppFailure failure, {
  required IssuanceAct act,
  AppStrings? strings,
}) {
  final AppStrings s = strings ?? lookupAppStrings(AppLocales.english);
  final String nothing = act.nothingIn(s);
  return switch (failure) {
    // The request may have arrived: no answer came, the connection dropped
    // after it was written, the answer could not be read, or the server
    // failed part-way. "Nothing was sent" here would be a guess.
    _ when failure.outcomeUnknown => (
      title: s.unsentTitle,
      body: act.unconfirmedIn(s),
      offerVerification: false,
    ),
    // `VERIFICATION_REQUIRED`: the server said why, so the way on is offered.
    ForbiddenFailure(requiresVerification: true) => (
      title: s.issuanceFailVerifyTitle,
      body: '$nothing ${s.issuanceFailVerifyBody}',
      offerVerification: true,
    ),
    // A plain `FORBIDDEN` is a different refusal — a staff account, for one.
    // The app does not guess which, and verification would not help.
    ForbiddenFailure() => (
      title: s.applyNotAllowedTitle,
      body: '$nothing ${s.issuanceFailForbiddenBody}',
      offerVerification: false,
    ),
    // Past the guard above, the connection failed before the request left
    // the phone. A timeout is always unknown and never reaches this line; it
    // is named only because the switch must cover every kind.
    NetworkFailure() || TimeoutFailure() => (
      title: s.applyOfflineTitle,
      body: '$nothing ${s.issuanceFailOfflineBody}',
      offerVerification: false,
    ),
    ValidationFailure() => (
      title: s.applyCheckTitle,
      body: '$nothing ${s.issuanceFailCheckBody}',
      offerVerification: false,
    ),
    UnacceptableUploadFailure() => (
      title: s.applyFileTitle,
      body: '$nothing ${s.issuanceFailFileBody}',
      offerVerification: false,
    ),
    RateLimitedFailure() => (
      title: s.applyRateTitle,
      body: '$nothing ${s.issuanceFailRateBody}',
      offerVerification: false,
    ),
    // A new request has no state to conflict with. A 409 on a submit means
    // its key was already used for something else: a fault in this app, not
    // anything the resident did. Said plainly, and nothing about it is logged.
    ConflictFailure() when act == IssuanceAct.submit => (
      title: s.applyServerTitle,
      body: '$nothing ${s.issuanceFailKeyConflictBody}',
      offerVerification: false,
    ),
    ConflictFailure() => (
      title: s.addDocsMovedTitle,
      body: '$nothing ${s.issuanceFailMovedBody}',
      offerVerification: false,
    ),
    NotFoundFailure() => (
      title: s.issuanceFailGoneTitle,
      body: '$nothing ${s.issuanceFailGoneBody}',
      offerVerification: false,
    ),
    UnauthenticatedFailure() => (
      title: s.applySessionTitle,
      body: '$nothing ${s.issuanceFailSessionBody}',
      offerVerification: false,
    ),
    // Past the guard above: a `503` that turned it away before acting.
    ServerFailure() ||
    ContractFailure() ||
    UnexpectedFailure() ||
    CodeExchangeFailure() => (
      title: s.applyServerTitle,
      body: '$nothing ${s.issuanceFailServerBody}',
      offerVerification: false,
    ),
  };
}
