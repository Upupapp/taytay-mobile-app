import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart';
import '../domain/notification_repository.dart';

/// The [NotificationRepository] this build ships with: it declines, honestly.
///
/// **`Notification` has been implemented since backend TAB 20** and serves the
/// inbox, per-notification and bulk read, and preferences. This file said it was
/// planned, which was true at backend `7844859` and has not been true for
/// forty-five commits.
///
/// Only this repository is a stub. The presentation layer above it — optimistic
/// read with reconciliation, Manila-day grouping, critical categories that
/// cannot be switched off, a push prompt deferred to a meaningful moment — is
/// the strongest feature in the codebase and is fully tested. TAB 13 wires the
/// repository beneath it without changing any of those semantics.

class PlannedNotificationRepository implements NotificationRepository {
  const PlannedNotificationRepository();

  static const UnwiredRepository _repository = UnwiredRepository.notifications;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
  }) async => unwiredRepositoryFailure<Paginated<ResidentNotification>>(
    _repository,
    'listOwn',
  );

  @override
  Future<Result<void>> markRead(String id) async =>
      unwiredRepositoryFailure<void>(_repository, 'markRead');

  @override
  Future<Result<void>> markAllRead() async =>
      unwiredRepositoryFailure<void>(_repository, 'markAllRead');

  /// Declines rather than pretending the device is reachable.
  ///
  /// Registering a token against nothing would leave the app believing the LGU
  /// can contact this resident when it cannot — and a resident who trusts that
  /// stops checking the app for the answer they are waiting for.
  @override
  Future<Result<void>> registerPushToken(String token) async =>
      unwiredRepositoryFailure<void>(_repository, 'registerPushToken');

  @override
  Future<Result<void>> unregisterPushToken() async =>
      unwiredRepositoryFailure<void>(_repository, 'unregisterPushToken');

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async =>
      unwiredRepositoryFailure<NotificationPreferences>(
        _repository,
        'loadPreferences',
      );

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async => unwiredRepositoryFailure<void>(_repository, 'updatePreferences');
}
