import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart';
import '../domain/notification_repository.dart';

/// Notification repository for a backend module that does not exist yet.
///
/// The `Notification` module is listed as **planned** in the committed
/// `docs/architecture/domain-boundary-map.md`, and publishes no endpoint. Rather
/// than invent one, every operation declines with a temporary failure — which
/// exercises the real error path and tells the truth. See `planned_backend.dart`
/// for why this is preferred to a mock.

class PlannedNotificationRepository implements NotificationRepository {
  const PlannedNotificationRepository();

  static const PlannedModule _module = PlannedModule.notification;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
  }) async => plannedBackendFailure<Paginated<ResidentNotification>>(
    _module,
    'listOwn',
  );

  @override
  Future<Result<void>> markRead(String id) async =>
      plannedBackendFailure<void>(_module, 'markRead');

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async =>
      plannedBackendFailure<NotificationPreferences>(
        _module,
        'loadPreferences',
      );

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async => plannedBackendFailure<void>(_module, 'updatePreferences');
}
