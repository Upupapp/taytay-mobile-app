import 'package:flutter/widgets.dart';

import '../../features/events/domain/event_repository.dart';
import '../../features/events/domain/event_send_failure.dart';
import '../../l10n/app_localizations.dart';
import '../result/app_failure.dart';
import 'app_locales.dart';

/// Events in the resident's language (D-237).
///
/// The English stays where it was — `registrationStateLabel`, `openToWords`,
/// and the sentences in `event_send_failure.dart` — as the no-context fallback
/// and for the tests that read it. These say the same things through
/// [AppStrings].

/// What a registration state is called, on the list row and the event page.
String eventRegistrationStateLabel(
  BuildContext context,
  EventRegistrationState? state,
) {
  final strings = AppStrings.of(context);
  return switch (state) {
    EventRegistrationState.notRequired => strings.eventsStateNotRequired,
    EventRegistrationState.notOpen => strings.eventsStateNotOpen,
    EventRegistrationState.open => strings.eventsStateOpen,
    EventRegistrationState.registered => strings.eventsStateRegistered,
    EventRegistrationState.waitlisted => strings.eventsStateWaitlisted,
    EventRegistrationState.cancelled => strings.eventsStateCancelled,
    EventRegistrationState.full => strings.eventsStateFull,
    EventRegistrationState.closed => strings.eventsStateClosed,
    null => strings.eventsStateUnknown,
  };
}

/// Who the office opened registration to (D-194). Null for a walk-in event
/// and for a value this build does not know, as `openToWords`.
String? eventOpenToWords(BuildContext context, LguEvent event) {
  if (event.registrationState?.known == EventRegistrationState.notRequired) {
    return null;
  }
  final strings = AppStrings.of(context);
  return switch (event.openTo?.known) {
    EventEligibility.verifiedResidents => strings.eventsOpenToVerified,
    EventEligibility.appAccounts => strings.eventsOpenToAccounts,
    null => null,
  };
}

/// What the office recorded about attendance.
String eventAttendanceWords(BuildContext context, AttendanceResult result) {
  final strings = AppStrings.of(context);
  return switch (result) {
    AttendanceResult.attended => strings.eventsAttended,
    AttendanceResult.absent => strings.eventsAbsent,
    AttendanceResult.notRecorded => strings.eventsAttendanceNotRecorded,
  };
}

/// The sentence on the registration outcome screen.
///
/// Keyed on the outcome (and the refusal), not on the English. A message that
/// is not this app's own sentence for its outcome — a dev mock's SAMPLE line —
/// is shown as it came. [failure] and [unconfirmed] are the controller's, for
/// [RegistrationOutcome.couldNotSend].
String registrationAttemptMessage(
  BuildContext context,
  RegistrationAttempt attempt, {
  AppFailure? failure,
  bool unconfirmed = false,
}) {
  final strings = AppStrings.of(context);
  final String message = attempt.residentMessage;
  String own(String english, String localised) =>
      message == english ? localised : message;

  return switch (attempt.outcome) {
    RegistrationOutcome.registered => own(
      registrationHeldCopy,
      strings.eventsOutcomeRegisteredBody,
    ),
    RegistrationOutcome.waitlisted => own(
      registrationWaitlistedCopy,
      strings.eventsOutcomeWaitlistedBody,
    ),
    RegistrationOutcome.full => own(
      registrationFullCopy,
      strings.eventsOutcomeFullBody,
    ),
    RegistrationOutcome.closed => own(
      registrationClosedCopy,
      strings.eventsOutcomeClosedBody,
    ),
    RegistrationOutcome.refused => switch (attempt.refusal) {
      final RegistrationRefusal refusal => own(
        registrationRefusalCopy(refusal),
        _refusal(strings, refusal),
      ),
      null => message,
    },
    RegistrationOutcome.couldNotSend => switch (failure) {
      final AppFailure lost => registrationSendFailureIn(
        context,
        lost,
        unconfirmed: unconfirmed,
      ),
      null => message,
    },
  };
}

String _refusal(AppStrings strings, RegistrationRefusal refusal) =>
    switch (refusal) {
      RegistrationRefusal.needsVerification =>
        strings.eventsRefusedNeedsVerification,
      RegistrationRefusal.notAllowed => strings.eventsRefusedNotAllowed,
      RegistrationRefusal.notListed => strings.eventsRefusedNotListed,
      RegistrationRefusal.notTaking => strings.eventsRefusedNotTaking,
      RegistrationRefusal.notAccepted => strings.eventsRefusedNotAccepted,
    };

/// `registrationSendFailure` in the resident's language: "could not confirm"
/// for a send that may have arrived, "nothing was registered" only for a
/// connection that failed before sending (D-188).
String registrationSendFailureIn(
  BuildContext context,
  AppFailure failure, {
  bool unconfirmed = false,
}) {
  final strings = AppStrings.of(context);
  return switch (failure) {
    _ when failure.outcomeUnknown || unconfirmed =>
      strings.eventsRegistrationUnconfirmed,
    NetworkFailure() => strings.eventsRegistrationNotSent(
      localisedResidentMessage(context, failure),
    ),
    _ => localisedResidentMessage(context, failure),
  };
}
