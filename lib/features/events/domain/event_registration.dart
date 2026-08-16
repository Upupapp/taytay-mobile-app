import 'package:flutter/foundation.dart';

import '../../../core/forms/server_form.dart';
import 'event_repository.dart' show EventRegistrationState;

export '../../../core/forms/server_form.dart';

/// Whether the office recorded the resident as having turned up.
///
/// **Only after the event, and only when the backend exposes it.** Attendance is
/// a fact about a person, and an app that displayed "absent" for an event whose
/// register the office had not finished would accuse somebody of missing
/// something they attended.
enum AttendanceResult {
  attended('attended'),
  absent('absent'),

  /// The office keeps a register but has not marked this resident either way.
  notRecorded('not_recorded');

  const AttendanceResult(this.wireValue);

  final String wireValue;
}

/// What the office asks before it will accept a registration.
///
/// ---
///
/// **Fetched, never authored.** Same rule as the assistance intake: the app does
/// not know what a medical mission asks for and a vaccination drive does not, so
/// it renders what the office defined and invents nothing.
///
/// **[allowsUnverifiedResidents] is the server's answer to the Master Command's
/// middle case.** "Authenticated/Unverified → allow only if event/backend
/// permits; otherwise verification gate." That is a policy decision per event —
/// a barangay clean-up may take anyone with an account, a cash-aid orientation
/// may not — and the client asks rather than assumes.
@immutable
class EventRegistrationForm {
  const EventRegistrationForm({
    required this.eventId,
    required this.eventTitle,
    this.fields = const <ServerField>[],
    this.consents = const <ServerConsent>[],
    this.allowsUnverifiedResidents = false,
    this.canCancel = false,
    this.notice,
  });

  final String eventId;
  final String eventTitle;

  /// Event-specific questions. Often none — most events ask nothing beyond who
  /// you are, and the flow is shorter for it.
  final List<ServerField> fields;

  final List<ServerConsent> consents;

  /// Whether a signed-in but unverified resident may register for this event.
  ///
  /// Defaults to **false**: an absent flag means the office did not say, and
  /// sending someone into a verification flow they did not need is recoverable,
  /// where registering someone the office would have refused is not.
  final bool allowsUnverifiedResidents;

  /// Whether a registration for this event can be cancelled from the app.
  final bool canCancel;

  /// Anything the office wants read before registering.
  final String? notice;

  /// Fields this build cannot render an input for.
  ///
  /// As with the intake wizard, an unrenderable field **blocks** registration
  /// rather than being skipped — registering somebody without an answer the
  /// office requires produces a place they may lose at the door.
  List<ServerField> get unrenderableFields =>
      fields.where((field) => !field.isRenderable).toList(growable: false);

  bool get hasUnrenderableFields => unrenderableFields.isNotEmpty;

  List<ServerConsent> get requiredConsents =>
      consents.where((consent) => consent.isRequired).toList(growable: false);

  @override
  String toString() =>
      'EventRegistrationForm($eventId, ${fields.length} fields)';
}

/// The resident's own registration for one event.
///
/// ---
///
/// **Everything here is the server's answer.** The state, the reference, the
/// waitlist position and the attendance result are all recorded by the office;
/// none is computed by the app. That is the concurrency rule the Master Command
/// states plainly — the server is authoritative for slot ownership — expressed
/// as a type with nowhere to put a local guess.
@immutable
class EventRegistration {
  const EventRegistration({
    required this.eventId,
    required this.state,
    this.id,
    this.reference,
    this.instructions,
    this.waitlistPosition,
    this.attendance,
    this.registeredAt,
    this.canCancel = false,
  });

  final String eventId;

  final ServerValue<EventRegistrationState> state;

  /// Server-issued id, when there is one to cancel against.
  final String? id;

  /// What a resident quotes at the door.
  final String? reference;

  /// What to bring, where to go, when to arrive — as the office wrote it.
  final String? instructions;

  /// Position in the queue, **only when the backend intentionally provides
  /// it**.
  ///
  /// The Master Command says so, and the reason is that a position is a
  /// statement about other people as much as about this resident. When the
  /// office does not publish it, the app says the resident is on the waitlist
  /// and stops there rather than estimating.
  final int? waitlistPosition;

  /// Recorded after the event, when it is resident-visible.
  final ServerValue<AttendanceResult>? attendance;

  final DateTime? registeredAt;

  /// Whether **this** registration can still be given up from the app.
  ///
  /// ---
  ///
  /// **Separate from [EventRegistrationForm.canCancel], and answering a later
  /// question.** The form's flag is what the office promises *before* somebody
  /// registers — "you will be able to change your mind". This one is the answer
  /// *now*, for this place, and it can be false while the form's is true: a
  /// cancellation window closes, the register is printed, the event starts.
  ///
  /// Defaults to **false**, like every other permission-shaped field in this
  /// app. An absent flag means the office did not say, and offering a button
  /// the server will refuse teaches residents that the app lies to them.
  final bool canCancel;

  bool get isActive => state.known?.isResidentRegistered ?? false;

  /// Whether the app may offer a cancel control.
  ///
  /// Three conditions, all from the server: the office allows it, the place is
  /// live, and there is an id to cancel against. A registration with no id is
  /// one the backend has not made addressable, and cancelling "the one I have"
  /// is not something this app will guess at.
  bool get isCancellable => canCancel && isActive && id != null;

  bool get isWaitlisted => state.known == EventRegistrationState.waitlisted;

  bool get isCancelled => state.known == EventRegistrationState.cancelled;

  /// Redacted of the reference: it identifies a place a person holds.
  @override
  String toString() => 'EventRegistration($eventId, ${state.raw})';
}

/// How a registration attempt ended, in terms a screen can branch on.
///
/// **`full` and `closed` are outcomes, not errors.** A resident who reaches the
/// last place a second after somebody else did nothing wrong, and telling them
/// "something went wrong" would send them to a support desk over a queue.
enum RegistrationOutcome {
  /// A place is held.
  registered,

  /// A waitlist place is held.
  waitlisted,

  /// The server refused because the event filled while they were filling the
  /// form in.
  full,

  /// Registration closed before they submitted.
  closed,

  /// The server refused for a reason it stated.
  refused,

  /// It could not be sent. **Nothing was registered**, so retrying is safe.
  couldNotSend,
}

/// The end of a registration attempt.
@immutable
class RegistrationAttempt {
  const RegistrationAttempt({
    required this.outcome,
    required this.residentMessage,
    this.registration,
    this.requestId,
  });

  final RegistrationOutcome outcome;

  /// Fixed app copy chosen by [outcome] — never the server's operator-facing
  /// `message`.
  final String residentMessage;

  /// Present when the server issued one.
  final EventRegistration? registration;

  /// Correlation id, so a resident can quote an opaque reference.
  final String? requestId;

  bool get isHeld =>
      outcome == RegistrationOutcome.registered ||
      outcome == RegistrationOutcome.waitlisted;

  @override
  String toString() => 'RegistrationAttempt(${outcome.name})';
}
