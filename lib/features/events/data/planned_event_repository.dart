import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/event_repository.dart';

/// The [EventRepository] this build ships with: it declines, honestly.
///
/// `GET /api/v1/events` is in the committed matrix and marked `planned`. An
/// invented event would send residents to a municipal hall on a date the LGU
/// never announced, which is a worse failure than an empty screen.
class PlannedEventRepository implements EventRepository {
  const PlannedEventRepository();

  static const String _reason =
      'GET /api/v1/events is planned; no events module is built.';

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<LguEvent>>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  @override
  Future<Result<LguEvent>> loadEvent(String id) async => const Err<LguEvent>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );
}
