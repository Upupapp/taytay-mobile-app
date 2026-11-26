import '../../../core/result/result.dart';
import 'event_registration.dart';

// ── Answers the server gave ─────────────────────────────────────────────────
//
// This app's own sentences, chosen by the outcome or the refusal — never the
// server's `words` or `error.message` (Article 5.5). English, kept here as the
// no-context fallback; `core/l10n/events_copy.dart` says them in the
// resident's language.
//
// "Nothing was registered" is said for `full` and `closed` because the server
// answers them only when this resident holds no place: a key it has seen
// answers with what that send did, and a place already held is reported
// before either.

/// `registered`.
const String registrationHeldCopy =
    'Taytay LGU has your place. Quote your reference at the door.';

/// `waitlisted`.
const String registrationWaitlistedCopy =
    'Taytay LGU has you on the waitlist. The office moves people up when a '
    'place opens, and you will see a notice in the app if it does.';

/// `full`.
const String registrationFullCopy =
    'Every place was taken before your registration arrived, and this event '
    'keeps no waitlist. Nothing was registered.';

/// `closed`.
const String registrationClosedCopy =
    'Registration for this event closed before your registration arrived. '
    'Nothing was registered.';

/// A refusal (`403`, `404`, `409`, `422`).
///
/// None of these says "nothing was registered": a refusal says this send was
/// turned away, not what an earlier send under the same key did.
String registrationRefusalCopy(RegistrationRefusal refusal) =>
    switch (refusal) {
      RegistrationRefusal.needsVerification =>
        'This event takes registrations from verified accounts. Verify your '
            'account first, then register.',
      RegistrationRefusal.notAllowed =>
        'Event registration is not available for this account in the app.',
      RegistrationRefusal.notListed =>
        'This event is no longer listed, so Taytay LGU could not take a '
            'registration for it.',
      RegistrationRefusal.notTaking =>
        'Taytay LGU is not taking registrations for this event right now. The '
            'event page says whether registration opens later.',
      RegistrationRefusal.notAccepted =>
        'Taytay LGU could not accept this registration as it was sent. If it '
            'happens again, quote the reference below to the office.',
    };

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
