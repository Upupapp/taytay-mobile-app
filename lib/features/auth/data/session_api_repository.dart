import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
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
    final response = await _apiClient.send<List<DeviceSessionSummary>>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: _decodeAll,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<void>> revokeSession({required String sessionId}) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.delete,
      path: '$path/$sessionId',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> revokeAllOtherSessions() async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: '$path/revoke-all',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  static List<DeviceSessionSummary> _decodeAll(Object? data) {
    if (data is! List<dynamic>) return const <DeviceSessionSummary>[];

    final List<DeviceSessionSummary> sessions = <DeviceSessionSummary>[];
    for (final Object? entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final Object? id = entry['id'];
      if (id is! String || id.isEmpty) continue;

      final Object? name = entry['name'];
      sessions.add(
        DeviceSessionSummary(
          id: id,
          // A session the resident cannot recognise is one they dare not
          // revoke, so an unnamed token gets a plain, honest placeholder rather
          // than an empty row or an invented device model.
          label: name is String && name.trim().isNotEmpty
              ? name.trim()
              : 'Unnamed sign-in',
          isCurrentDevice: entry['current'] == true,
          lastSeenAt: DateTime.tryParse(
            entry['last_used_at'] is String
                ? entry['last_used_at'] as String
                : '',
          )?.toUtc(),
        ),
      );
    }
    return List<DeviceSessionSummary>.unmodifiable(sessions);
  }
}
