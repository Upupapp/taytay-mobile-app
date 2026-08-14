import '../../../core/result/result.dart';
import '../domain/device_session_repository.dart';

/// The [DeviceSessionRepository] this build ships with: it declines, honestly.
///
/// See the contract's own doc for why there is nothing to call. Both methods
/// return a temporary [ServerFailure] so the security screen renders its real
/// "not available yet" state through the same failure path as every other
/// absent module — rather than a mock list, which would reassure a resident
/// checking whether someone else is signed in to their account.
class PlannedDeviceSessionRepository implements DeviceSessionRepository {
  const PlannedDeviceSessionRepository();

  static const String _reason =
      'No endpoint lists or revokes other sessions in the committed contract; '
      'only DELETE /auth/tokens/current exists.';

  @override
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions() async =>
      const Err<List<DeviceSessionSummary>>(
        ServerFailure(isTemporary: true, debugMessage: _reason),
      );

  @override
  Future<Result<void>> revokeSession({required String sessionId}) async =>
      const Err<void>(ServerFailure(isTemporary: true, debugMessage: _reason));
}
