import '../../../core/api/paginated.dart';
import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/event_repository.dart';

/// The [EventRepository] this build ships with: it declines, honestly.
///
/// **`Events` has been implemented since backend TAB 25.** This file said
/// `GET /api/v1/events` was `planned`; the module serves events, registration,
/// waitlist and attendance today. Wiring it is TAB 12, and the interesting part
/// there is that availability is derived server-side and must never be cached or
/// recomputed here.
///
/// It still declines rather than inventing an event, which would send residents
/// to a municipal hall on a date the LGU never announced — a worse failure than
/// an empty screen.
class PlannedEventRepository implements EventRepository {
  const PlannedEventRepository();

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async => unwiredRepositoryFailure<Paginated<LguEvent>>(
    UnwiredRepository.events,
    'listEvents',
  );

  @override
  Future<Result<LguEvent>> loadEvent(String id) async =>
      unwiredRepositoryFailure<LguEvent>(UnwiredRepository.events, 'loadEvent');

  // ── Registration ─────────────────────────────────────────────────────────
  //
  // All decline. A fabricated registration is the worst outcome available
  // here: a resident would arrive at a covered court holding a reference the
  // office has never seen, and be turned away in front of the queue.

  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async => unwiredRepositoryFailure<EventRegistrationForm>(
    UnwiredRepository.events,
    'loadRegistrationForm',
  );

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<RegistrationAttempt>(
    UnwiredRepository.events,
    'register',
  );

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<EventRegistration>(
    UnwiredRepository.events,
    'cancelRegistration',
  );
}
