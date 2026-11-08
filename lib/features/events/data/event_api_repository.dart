import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/page_policy.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/event_repository.dart';

/// Talks to `events` and the registration routes beneath it (backend
/// `580acbb`, DL-192; D-191).
///
/// `GET events?scope=&limit=&cursor=`, `GET events/{id}`,
/// `POST events/{id}/registrations` and
/// `POST events/{id}/registrations/{registration_id}/cancel`. Reading is public,
/// and a signed-in resident's bearer goes with it so the server can fill
/// `my_registration`. `scope=registered`, registering and cancelling need the
/// resident's account.
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
/// tapping register on the last place is expected: the server gives the place
/// inside a lock on the event's row, one is registered, and the other is
/// waitlisted or told the event is full, in a `200`. Each reads calm, specific
/// words rather than an error dialog.
///
/// **The idempotency key travels in the body, never as a header.** The Node API
/// reads `idempotency_key` from the body, and its CORS policy allows four
/// request headers. A retry with the same key is answered with what the first
/// attempt did, so a registration whose answer was lost is never made twice.
/// Without the header the transport does not repeat the send by itself: the
/// resident does, with the same key, after reading that it is safe.
///
/// **An answer this app cannot read is a [ContractFailure], never a blank.** An
/// empty list from an unreadable page would tell a resident there are no
/// events; an empty outcome would hide whether they have a place.
class EventApiRepository implements EventRepository {
  EventApiRepository({required ApiClient apiClient, Telemetry? telemetry})
    : _apiClient = apiClient,
      _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents. See `Telemetry` for the three
  /// conditions that gate every signal, and `TelemetrySignal` for why the
  /// payload is a sealed set with no free-text field.
  final Telemetry? _telemetry;

  /// The cursor the last page of each scope returned. Page 1 starts again.
  ///
  /// Kept per scope, because the list screen and another reader of the same
  /// repository may be paging different scopes at once, and a cursor for
  /// "upcoming" sent with `scope=past` would page the wrong list.
  final Map<EventScope, String> _cursors = <EventScope, String>{};

  static const String path = 'events';

  /// The route's own ceiling (`limit` 1–50).
  static const int maxLimit = 50;

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int? perPage,
  }) async {
    assert(page >= 1);
    if (page <= 1) _cursors.remove(scope);
    final String? cursor = _cursors[scope];
    if (page > 1 && cursor == null) {
      // Nothing past the last page. Asking without a cursor would return the
      // first page again, and the list would show every event twice.
      return Ok<Paginated<LguEvent>>(
        Paginated<LguEvent>(
          items: const <LguEvent>[],
          page: page,
          perPage: 0,
          total: 0,
          totalPages: 0,
          hasMore: false,
        ),
      );
    }

    final PagePolicy pages = _apiClient.pages;
    final int requested = pages.clampRequest(perPage ?? pages.defaultPerPage);
    final int limit = requested.clamp(1, maxLimit);
    final Result<ApiEnvelope<List<LguEvent>>> response = await _apiClient
        .send<List<LguEvent>>(
          method: HttpMethod.get,
          path: path,
          // "My events" is the resident's own list and needs the account. The
          // other two are public; a signed-in resident's token still goes, so
          // each row says whether they hold a place.
          authenticated: scope.needsAccount,
          attachTokenIfAvailable: true,
          query: <String, String>{
            'scope': _scopeWire(scope),
            'limit': '$limit',
            'cursor': ?cursor,
          },
          decode: _decodeEvents,
        );

    switch (response) {
      case Err<ApiEnvelope<List<LguEvent>>>(:final failure):
        return Err<Paginated<LguEvent>>(failure);
      case Ok<ApiEnvelope<List<LguEvent>>>(:final value):
        final PageMeta? pagination = value.pagination;
        if (pagination == null ||
            (pagination.hasMore && pagination.nextCursor == null)) {
          return Err<Paginated<LguEvent>>(
            ContractFailure(
              requestId: value.requestId,
              debugMessage: 'An events page came without a usable cursor.',
            ),
          );
        }
        final String? next = pagination.nextCursor;
        if (pagination.hasMore && next != null) {
          _cursors[scope] = next;
        } else {
          _cursors.remove(scope);
        }
        return Ok<Paginated<LguEvent>>(
          Paginated<LguEvent>(
            items: value.data,
            page: page,
            perPage: limit,
            total: pagination.total,
            totalPages: pagination.totalPages,
            hasMore: pagination.hasMore,
            nextCursor: pagination.nextCursor,
          ),
        );
    }
  }

  @override
  Future<Result<LguEvent>> loadEvent(String id) async {
    final Result<ApiEnvelope<_EventDetail>> response = await _readDetail(id);
    return response.map((ApiEnvelope<_EventDetail> value) => value.data.event);
  }

  /// Built from the event itself, because there is no separate form endpoint.
  ///
  /// Re-read at the moment the resident opens the form rather than reused from
  /// the list they tapped: availability is the server's answer *now*, and a page
  /// that has been open while somebody read the description is a page whose
  /// answer may have changed.
  ///
  /// The office asks nothing beyond who the resident is, so `fields` and
  /// `consents` arrive empty, and `allows_unverified_residents` is false for
  /// every event (DL-192): an unverified resident is sent to verification.
  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async {
    final Result<ApiEnvelope<_EventDetail>> response = await _readDetail(
      eventId,
    );
    return response.map((ApiEnvelope<_EventDetail> value) => value.data.form);
  }

  Future<Result<ApiEnvelope<_EventDetail>>> _readDetail(String id) =>
      _apiClient.send<_EventDetail>(
        method: HttpMethod.get,
        path: '$path/$id',
        authenticated: false,
        attachTokenIfAvailable: true,
        decode: _decodeDetail,
      );

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async {
    final Result<ApiEnvelope<_RegisterAnswer>> response = await _apiClient
        .send<_RegisterAnswer>(
          method: HttpMethod.post,
          path: '$path/$eventId/registrations',
          authenticated: true,
          body: <String, Object?>{
            'idempotency_key': idempotencyKey,
            // The office asks nothing (DL-192), so these are normally empty and
            // left out. Anything a future form collected is sent as it is, and
            // the server's refusal is reported rather than the answer dropped.
            if (answers.isNotEmpty) 'answers': answers,
            if (consentKeys.isNotEmpty) 'consent_keys': consentKeys,
          },
          decode: _decodeRegisterAnswer,
        );

    switch (response) {
      case Ok<ApiEnvelope<_RegisterAnswer>>(:final value):
        final RegistrationAttempt attempt = RegistrationAttempt(
          outcome: value.data.outcome,
          residentMessage: value.data.residentMessage,
          registration: value.data.registration,
          requestId: value.requestId,
        );
        _record(
          attempt.isHeld ? TelemetryStage.completed : TelemetryStage.blocked,
        );
        return Ok<RegistrationAttempt>(attempt);
      case Err<ApiEnvelope<_RegisterAnswer>>(:final failure):
        final String? refusal = _refusalCopy(failure);
        // A timeout, a lost connection, a server fault or an unreadable answer
        // stays a failure. The caller keeps the key and says what it knows.
        if (refusal == null) return Err<RegistrationAttempt>(failure);
        _record(TelemetryStage.blocked);
        return Ok<RegistrationAttempt>(
          RegistrationAttempt(
            outcome: RegistrationOutcome.refused,
            residentMessage: refusal,
            requestId: failure.requestId,
          ),
        );
    }
  }

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async {
    final Result<ApiEnvelope<EventRegistration>> response = await _apiClient
        .send<EventRegistration>(
          method: HttpMethod.post,
          path: '$path/$eventId/registrations/$registrationId/cancel',
          authenticated: true,
          body: <String, Object?>{'idempotency_key': idempotencyKey},
          decode: _decodeRegistration,
        );
    return response.map((ApiEnvelope<EventRegistration> value) => value.data);
  }

  void _record(TelemetryStage stage) {
    unawaited(
      _telemetry?.record(
            FlowStep(flow: TelemetryFlow.eventRegistration, stage: stage),
          ) ??
          Future<bool>.value(false),
    );
  }

  // ── Resident copy ──────────────────────────────────────────────────────────
  //
  // This app's own sentences, chosen by the outcome or the refusal. Never the
  // server's `words` or `error.message` (Article 5.5).

  /// "Nothing was registered" is said for `full` and `closed` because the
  /// server answers them only when this resident holds no place: a key it has
  /// seen answers with what that send did, and a place already held is
  /// reported before either.
  static const String _registeredCopy =
      'Taytay LGU has your place. Quote your reference at the door.';
  static const String _waitlistedCopy =
      'Taytay LGU has you on the waitlist. The office moves people up when a '
      'place opens, and you will see a notice in the app if it does.';
  static const String _fullCopy =
      'Every place was taken before your registration arrived, and this event '
      'keeps no waitlist. Nothing was registered.';
  static const String _closedCopy =
      'Registration for this event closed before your registration arrived. '
      'Nothing was registered.';

  /// The refusals the brief names (`403`, `404`, `409`, `422`), or null for a
  /// failure that is not a refusal.
  ///
  /// None of these says "nothing was registered": a refusal says this send was
  /// turned away, not what an earlier send under the same key did.
  static String? _refusalCopy(AppFailure failure) => switch (failure) {
    ForbiddenFailure(requiresVerification: true) =>
      'This event takes registrations from verified accounts. Verify your '
          'account first, then register.',
    ForbiddenFailure() =>
      'Event registration is not available for this account in the app.',
    NotFoundFailure() =>
      'This event is no longer listed, so Taytay LGU could not take a '
          'registration for it.',
    ConflictFailure() =>
      'Taytay LGU is not taking registrations for this event right now. The '
          'event page says whether registration opens later.',
    ValidationFailure() =>
      'Taytay LGU could not accept this registration as it was sent. If it '
          'happens again, quote the reference below to the office.',
    _ => null,
  };

  // ── Decoding ──────────────────────────────────────────────────────────────
  //
  // Each decoder throws `FormatException` on a body it cannot read, which the
  // envelope decoder reports as a `ContractFailure`. Unknown fields are
  // ignored; a missing required one is a contract breach.

  static String _scopeWire(EventScope scope) => switch (scope) {
    EventScope.upcoming => 'upcoming',
    EventScope.registered => 'registered',
    EventScope.past => 'past',
  };

  static List<LguEvent> _decodeEvents(Object? data) {
    if (data is! List<dynamic>) {
      throw const FormatException('The events page is not a list.');
    }
    return <LguEvent>[for (final Object? row in data) _decodeEvent(row)];
  }

  static _EventDetail _decodeDetail(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('The event is not an object.');
    }
    final LguEvent event = _decodeEvent(data);
    final Object? form = data['registration_form'];
    final Map<String, dynamic>? asks = form is Map<String, dynamic>
        ? form
        : null;
    return _EventDetail(
      event: event,
      form: EventRegistrationForm(
        eventId: event.id,
        eventTitle: event.title,
        // The office asks nothing beyond who the resident is (DL-192), so the
        // lists stay empty: no field or consent shape is published to render.
        // Both flags default to false when the form is missing.
        allowsUnverifiedResidents: asks?['allows_unverified_residents'] == true,
        canCancel: asks?['can_cancel'] == true,
        notice: _text(asks?['notice']),
      ),
    );
  }

  static LguEvent _decodeEvent(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('An event is not an object.');
    }
    final String? id = _text(raw['id']);
    final String? title = _text(raw['title']);
    if (id == null || title == null) {
      throw const FormatException('An event has no id or no title.');
    }
    final Object? registration = raw['registration'];
    final Map<String, dynamic>? window = registration is Map<String, dynamic>
        ? registration
        : null;
    final Object? rawCover = raw['cover_image'];
    final Map<String, dynamic>? cover = rawCover is Map<String, dynamic>
        ? rawCover
        : null;
    final Object? capacity = raw['capacity'];

    return LguEvent(
      id: id,
      title: title,
      description: _text(raw['description']) ?? _text(raw['summary']) ?? '',
      startsAt: _instant(raw['starts_at']),
      endsAt: _instant(raw['ends_at']),
      venue: _venue(raw['venue']),
      // The server's own label, shown as sent. The code beside it decides
      // nothing in this app.
      category: _text(raw['category_label']),
      // The API's own cover route, kept only as a sign that a cover exists.
      // Its host is never requested: `EventCover` reads `events/{id}/cover`
      // from the configured base (D-193), as a Balita cover is read.
      coverImageUrl: _text(cover?['url']),
      coverAltText: _text(cover?['alt_text']),
      organiser: _text(raw['organiser']),
      contact: _contact(raw['contact']),
      registrationRules: _text(window?['rules']),
      whatToBring: _text(raw['what_to_bring']),
      // The total the office published. What is left of it is never sent and
      // never computed.
      capacity: EventCapacity(capacity: capacity is int ? capacity : null),
      registrationState: _registrationState(window?['state']),
      publicationState: _publication(raw['status']),
      myRegistration: _optionalRegistration(raw['my_registration']),
    );
  }

  static EventVenue? _venue(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final String? name = _text(raw['name']);
    if (name == null) return null;
    return EventVenue(
      name: name,
      address: _text(raw['address']),
      // Opened only when `hasSafeDirections` says so.
      directionsUrl: _text(raw['map_url']),
    );
  }

  /// One line from what the office published: name, office, phone.
  static String? _contact(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final List<String> parts = <String>[
      for (final String key in const <String>['name', 'office', 'phone'])
        if (_text(raw[key]) case final String value) value,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  static EventRegistration? _optionalRegistration(Object? raw) =>
      raw == null ? null : _decodeRegistration(raw);

  static EventRegistration _decodeRegistration(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('A registration is not an object.');
    }
    final String? eventId = _text(raw['event_id']);
    final String? state = _text(raw['state']);
    if (eventId == null || state == null) {
      throw const FormatException('A registration has no event or no state.');
    }
    final String? attendance = _text(raw['attendance']);
    return EventRegistration(
      eventId: eventId,
      id: _text(raw['id']),
      reference: _text(raw['reference']),
      state: ServerValue.parse<EventRegistrationState>(
        state,
        EventRegistrationState.values,
        (EventRegistrationState value) => value.wireValue,
      ),
      registeredAt: _instant(raw['registered_at']),
      // Null until the office completes the event. Never read as "absent".
      attendance: attendance == null
          ? null
          : ServerValue.parse<AttendanceResult>(
              attendance,
              AttendanceResult.values,
              (AttendanceResult value) => value.wireValue,
            ),
      canCancel: raw['can_cancel'] == true,
      instructions: _text(raw['instructions']),
      // No waitlist position is sent, so none is held.
    );
  }

  static _RegisterAnswer _decodeRegisterAnswer(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('The registration answer is not an object.');
    }
    final (
      RegistrationOutcome outcome,
      String copy,
    ) = switch (data['outcome']) {
      'registered' => (RegistrationOutcome.registered, _registeredCopy),
      'waitlisted' => (RegistrationOutcome.waitlisted, _waitlistedCopy),
      'full' => (RegistrationOutcome.full, _fullCopy),
      'closed' => (RegistrationOutcome.closed, _closedCopy),
      // An outcome this build does not know may be a place it holds. Saying
      // "could not confirm" is true; any guess is not.
      _ => throw const FormatException('Unknown registration outcome.'),
    };
    return _RegisterAnswer(
      outcome: outcome,
      residentMessage: copy,
      registration: _optionalRegistration(data['registration']),
    );
  }

  static ServerValue<EventRegistrationState>? _registrationState(Object? raw) {
    // `not_required` is a walk-in event and reads "No registration needed".
    // Only `open` offers the register control, so it offers none (D-192).
    final String? value = _text(raw);
    return value == null
        ? null
        : ServerValue.parse<EventRegistrationState>(
            value,
            EventRegistrationState.values,
            (EventRegistrationState state) => state.wireValue,
          );
  }

  static ServerValue<PublicationState>? _publication(Object? raw) {
    // `cancelled` and `completed` are not publication states: they read as
    // unknown, so the event is shown, which a called-off event must be.
    final String? value = _text(raw);
    return value == null
        ? null
        : ServerValue.parse<PublicationState>(
            value,
            PublicationState.values,
            (PublicationState state) => state.wireValue,
          );
  }

  static DateTime? _instant(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// `GET events/{id}`: the event and, on that read only, its form.
final class _EventDetail {
  const _EventDetail({required this.event, required this.form});

  final LguEvent event;
  final EventRegistrationForm form;
}

/// What `POST events/{id}/registrations` answered.
final class _RegisterAnswer {
  const _RegisterAnswer({
    required this.outcome,
    required this.residentMessage,
    this.registration,
  });

  final RegistrationOutcome outcome;
  final String residentMessage;
  final EventRegistration? registration;
}
