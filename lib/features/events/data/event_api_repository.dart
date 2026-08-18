import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
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
    int perPage = 20,
  }) async {
    final response = await _apiClient.send<List<LguEvent>>(
      method: HttpMethod.get,
      path: path,
      // Guest-visible, and sent anonymously so the answer stays cacheable.
      authenticated: false,
      query: <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'per_page': '${perPage.clamp(1, 100)}',
      },
      decode: (Object? data) => data is List<dynamic>
          ? data.map(_decodeEvent).whereType<LguEvent>().toList(growable: false)
          : const <LguEvent>[],
    );
    return response.map(_toPage);
  }

  @override
  Future<Result<LguEvent>> loadEvent(String id) async {
    final response = await _apiClient.send<LguEvent?>(
      method: HttpMethod.get,
      path: '$path/$id',
      authenticated: false,
      decode: _decodeEvent,
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<LguEvent>(
              NotFoundFailure(debugMessage: 'No readable event in the body.'),
            )
          : Ok<LguEvent>(envelope.data!),
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
    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.eventRegistration,
          stage: TelemetryStage.started,
        ),
      ),
    );

    final response = await _apiClient.send<RegistrationAttempt>(
      method: HttpMethod.post,
      path: '$path/$eventId/registration',
      authenticated: true,
      // A dropped connection after the server committed would otherwise take a
      // second place from a resident who already holds one.
      idempotencyKey: idempotencyKey,
      decode: (Object? data) => _decodeAttempt(eventId, data),
    );

    return switch (response) {
      Ok<ApiEnvelope<RegistrationAttempt>>(:final value) =>
        Ok<RegistrationAttempt>(value.data),
      // A refusal here is the race resolving, not a fault. The server answers
      // CONFLICT or INVALID_STATE_TRANSITION when the last place went while the
      // resident was deciding, and that deserves a sentence rather than a red
      // banner about something going wrong.
      Err<ApiEnvelope<RegistrationAttempt>>(:final failure)
          when failure is ConflictFailure =>
        const Ok<RegistrationAttempt>(
          RegistrationAttempt(
            outcome: RegistrationOutcome.full,
            residentMessage:
                'That event filled up while you were deciding. If there is a '
                'waitlist you can still join it.',
          ),
        ),
      Err<ApiEnvelope<RegistrationAttempt>>(:final failure) =>
        Err<RegistrationAttempt>(failure),
    };
  }

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<EventRegistration>(
      method: HttpMethod.delete,
      path: '$path/$eventId/registration',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: (Object? data) =>
          _decodeRegistration(eventId, data) ??
          EventRegistration(
            eventId: eventId,
            state: const ServerValue<EventRegistrationState>(
              raw: 'cancelled',
              known: EventRegistrationState.cancelled,
            ),
          ),
    );
    return response.map((envelope) => envelope.data);
  }

  static LguEvent? _decodeEvent(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    final Object? title = entry['title'];
    if (id is! String || id.isEmpty || title is! String) return null;

    final Map<String, dynamic> registration =
        entry['registration'] is Map<String, dynamic>
        ? entry['registration'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final Object? capacity = registration['capacity'];
    final Object? covers = entry['cover_urls'];

    return LguEvent(
      id: id,
      title: title,
      description: entry['description'] is String
          ? entry['description'] as String
          : (entry['summary'] is String ? entry['summary'] as String : ''),
      // Instants. Rendered in Manila by the presentation layer, because a phone
      // can be set to any timezone and the event happens in Taytay regardless.
      startsAt: DateTime.tryParse(
        entry['starts_at'] is String ? entry['starts_at'] as String : '',
      )?.toUtc(),
      endsAt: DateTime.tryParse(
        entry['ends_at'] is String ? entry['ends_at'] as String : '',
      )?.toUtc(),
      category: entry['category'] is String
          ? entry['category'] as String
          : null,
      coverImageUrl: covers is List<dynamic> && covers.isNotEmpty
          ? (covers.first is String ? covers.first as String : null)
          : null,
      organiser: entry['contact_office'] is String
          ? entry['contact_office'] as String
          : null,
      contact: entry['contact_number'] is String
          ? entry['contact_number'] as String
          : null,
      registrationRules: entry['participant_instructions'] is String
          ? entry['participant_instructions'] as String
          : (entry['participation_note'] is String
                ? entry['participation_note'] as String
                : null),
      capacity: EventCapacity(
        capacity: capacity is int ? capacity : null,
        // NEVER SET. See the class doc: the server stores no seat counter, and
        // deriving one here is the badge that starts a queue at 4am.
      ),
      registrationState: ServerValue.parse<EventRegistrationState>(
        registration['availability'] is String
            ? registration['availability'] as String
            : null,
        EventRegistrationState.values,
        (EventRegistrationState s) => s.wireValue,
      ),
    );
  }

  static EventRegistration? _decodeRegistration(String eventId, Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final Object? state = data['state'] ?? data['status'];

    return EventRegistration(
      eventId: eventId,
      id: data['id'] is String ? data['id'] as String : null,
      state: ServerValue.parse<EventRegistrationState>(
        state is String ? state : null,
        EventRegistrationState.values,
        (EventRegistrationState s) => s.wireValue,
      ),
      reference: data['reference'] is String
          ? data['reference'] as String
          : null,
      instructions: data['instructions'] is String
          ? data['instructions'] as String
          : null,
      // Only when the office publishes it. A queue position is a statement
      // about other people as much as about this resident, so the app never
      // computes one.
      waitlistPosition: data['waitlist_position'] is int
          ? data['waitlist_position'] as int
          : null,
    );
  }

  static RegistrationAttempt _decodeAttempt(String eventId, Object? data) {
    final EventRegistration? registration = _decodeRegistration(eventId, data);
    final EventRegistrationState? state = registration?.state.known;

    final RegistrationOutcome outcome = switch (state) {
      EventRegistrationState.registered => RegistrationOutcome.registered,
      EventRegistrationState.waitlisted => RegistrationOutcome.waitlisted,
      // An unrecognised state is not read as success. The resident is told to
      // check, which is true, rather than told they have a place they may not
      // have — that is the version that ends with somebody turning up.
      _ => RegistrationOutcome.refused,
    };

    final Object? message = data is Map<String, dynamic>
        ? data['message']
        : null;

    return RegistrationAttempt(
      outcome: outcome,
      residentMessage: message is String && message.trim().isNotEmpty
          ? message.trim()
          : switch (outcome) {
              RegistrationOutcome.registered =>
                'You have a place at this event.',
              RegistrationOutcome.waitlisted =>
                'You are on the waitlist. The office will tell you if a place opens.',
              _ =>
                'Your registration could not be confirmed. Please check with the office.',
            },
      registration: registration,
    );
  }

  static Paginated<LguEvent> _toPage(ApiEnvelope<List<LguEvent>> envelope) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<LguEvent>.single(envelope.data);
    }
    return Paginated<LguEvent>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
