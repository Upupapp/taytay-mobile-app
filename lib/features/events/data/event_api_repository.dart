import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/event_repository.dart';

/// Talks to `events` and the registration routes beneath it.
///
/// ---
///
/// **There is no seats-left number anywhere in this file, and there must never
/// be one.** The backend stores no seat counter, deliberately: a second source
/// of one fact drifts, and the cached copy always wins the check that reads it
/// (ADR 0030 §2, ADR 0031 §1). Availability is *derived on every read* and
/// arrives as a state with the office's own wording attached, so a client cannot
/// invent a friendlier sentence for a window that closed an hour ago.
///
/// `EventCapacity.remaining` therefore stays `null` on every path through this
/// decoder. The total capacity is a fact about the event and is published; what
/// is left of it is not, and computing it here — capacity minus a count from
/// somewhere — is precisely the badge that has residents queueing at 4am for
/// something that was never first-come-first-served.
///
/// **The capacity race is an ordinary outcome, not an exception.** Two residents
/// tapping register on the last place is expected: one succeeds, one is
/// waitlisted or refused, and the refusal needs calm, specific words rather than
/// an error dialog.
class EventApiRepository implements EventRepository {
  const EventApiRepository({required ApiClient apiClient, Telemetry? telemetry})
    : _apiClient = apiClient,
      _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents. See `Telemetry` for the three
  /// conditions that gate every signal, and `TelemetrySignal` for why the
  /// payload is a sealed set with no free-text field.
  final Telemetry? _telemetry;

  static const String path = 'events';

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int? perPage,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<Paginated<LguEvent>>(
      BackendGap.absentOnNodeContract,
      'listEvents',
    );
  }

  @override
  Future<Result<LguEvent>> loadEvent(String id) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<LguEvent>(
      BackendGap.absentOnNodeContract,
      'loadEvent',
    );
  }

  /// Built from the event itself, because there is no separate form endpoint.
  ///
  /// Re-read at the moment the resident opens the form rather than reused from
  /// the list they tapped: availability is the server's answer *now*, and a page
  /// that has been open while somebody read the description is a page whose
  /// answer may have changed.
  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async {
    final Result<LguEvent> event = await loadEvent(eventId);
    return event.map(
      (LguEvent value) => EventRegistrationForm(
        eventId: value.id,
        eventTitle: value.title,
        notice: value.registrationRules,
      ),
    );
  }

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    unawaited(
      _telemetry?.record(
            const FlowStep(
              flow: TelemetryFlow.eventRegistration,
              stage: TelemetryStage.blocked,
            ),
          ) ??
          Future<bool>.value(false),
    );
    return backendGapFailure<RegistrationAttempt>(
      BackendGap.absentOnNodeContract,
      'register',
    );
  }

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<EventRegistration>(
      BackendGap.absentOnNodeContract,
      'cancelRegistration',
    );
  }
}
