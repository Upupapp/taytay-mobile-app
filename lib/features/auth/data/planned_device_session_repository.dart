import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/device_session_repository.dart';

/// The [DeviceSessionRepository] this build ships with: it declines, honestly.
///
/// **The reason this gave is no longer true.** It said only
/// `DELETE /auth/tokens/current` existed. `Identity` publishes the full session
/// and device registry today — `GET me/sessions`, `DELETE me/sessions/{session}`,
/// `POST me/sessions/revoke-all`, and the three `me/devices` routes — and has
/// since backend TAB 05. Wiring it is TAB 03.
///
/// It matters more than most: a resident who loses a phone signs it out from
/// another one here. Both methods still decline rather than returning a mock
/// list, which would reassure a resident checking whether someone else is signed
/// in to their account.
class PlannedDeviceSessionRepository implements DeviceSessionRepository {
  const PlannedDeviceSessionRepository();

  @override
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions() async =>
      unwiredRepositoryFailure<List<DeviceSessionSummary>>(
        UnwiredRepository.deviceSessions,
        'listActiveSessions',
      );

  @override
  Future<Result<void>> revokeSession({required String sessionId}) async =>
      unwiredRepositoryFailure<void>(
        UnwiredRepository.deviceSessions,
        'revokeSession',
      );
}
