import '../../../core/result/result.dart';

/// The sentence for a registration that may have reached Taytay LGU.
///
/// True because the registration carries an idempotency key that is kept for
/// every retry of the same attempt (`SendKey`, D-191): the server answers a
/// repeat with what the first send did, and a resident holds at most one place
/// at an event, so trying again never registers anybody twice.
const String registrationUnconfirmed =
    'We could not confirm that your registration was received. Trying again '
    'is safe: you will not be registered twice.';

/// The sentence for a cancellation that may have reached Taytay LGU.
///
/// It does not say the resident still has the place, because they may not.
/// The same key answers a late retry with the registration as it stands, so
/// trying again gives up nothing twice.
const String cancellationUnconfirmed =
    'We could not confirm that your place was given up. Trying again is safe: '
    'it will not be done twice.';

/// A `409` on a cancellation: the event has started or is no longer published,
/// so the app can no longer give the place up.
const String cancellationTooLate =
    'Your place can no longer be given up in the app. Contact Taytay LGU if '
    'you cannot go.';

/// What a resident reads when a registration did not get an answer the app
/// could use.
///
/// Every line is this app's own; the server's `message` never reaches the
/// screen (Article 5.5). It says nothing was registered only where the app
/// knows (D-188): a connection that failed before the request left the phone,
/// with no earlier attempt in this flow that may have arrived. A timeout, a
/// connection dropped after sending, an unreadable answer or a server that
/// failed part-way says "could not confirm" — and keeps saying it on a later
/// retry that fails before sending, because the earlier one may still have
/// registered the resident ([unconfirmed]: `SendKey.unconfirmed`, read after
/// settling this failure).
String registrationSendFailure(AppFailure failure, {bool unconfirmed = false}) {
  return switch (failure) {
    _ when failure.outcomeUnknown || unconfirmed => registrationUnconfirmed,
    // Past the guard above, the connection failed before anything was sent.
    NetworkFailure() =>
      'We could not send your registration, so nothing was registered. '
          '${failure.residentMessage}',
    _ => failure.residentMessage,
  };
}
