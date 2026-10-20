import '../../../core/api/api_client.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/device_session_repository.dart';

/// Talks to `GET me/sessions`, `DELETE me/sessions/{session}` and
/// `POST me/sessions/revoke-all`.
///
/// ---
///
/// **Sessions, not devices.** `Identity` publishes both and they answer
/// different questions. `me/sessions` lists the *tokens* an account holds —
/// every place it is signed in, with a `current` flag naming the one asking.
/// `me/devices` lists registrations whose reason for existing is a push token.
/// A resident opening the security screen is asking whether somebody else is
/// signed in as them, and only the first list answers that.
///
/// **This is a safety feature, not a power-user setting.** A resident who loses
/// a phone must be able to sign that phone out from another one, and on a
/// government identity app that is a baseline expectation. It is also why the
/// summaries stay thin: a session list is a movement log, and this one carries a
/// label and a last-seen time and no IP address, no user agent and no city.
class SessionApiRepository implements DeviceSessionRepository {
  const SessionApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/sessions';

  @override
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions() async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<List<DeviceSessionSummary>>(
      BackendGap.absentOnNodeContract,
      'listActiveSessions',
    );
  }

  @override
  Future<Result<void>> revokeSession({required String sessionId}) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'revokeSession',
    );
  }

  @override
  Future<Result<void>> revokeAllOtherSessions() async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'revokeAllOtherSessions',
    );
  }

}
