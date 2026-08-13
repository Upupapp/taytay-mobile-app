import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/platform_repository.dart';

/// Talks to `GET /api/v1/health`.
///
/// This is the only endpoint the Taytay backend currently publishes, and it is
/// the reference implementation for every repository that follows: the data
/// layer owns the wire format, the domain layer never sees a `Map`, and unknown
/// fields are ignored rather than rejected (conventions §1 — "clients must
/// ignore unknown fields").
class PlatformApiRepository implements PlatformRepository {
  const PlatformApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<ServiceHealth>> checkHealth() async {
    final response = await _apiClient.send<ServiceHealth>(
      method: HttpMethod.get,
      path: 'health',
      // PUBLIC BY DESIGN: the liveness probe is unauthenticated on the server.
      authenticated: false,
      decode: _decodeHealth,
    );
    return response.map((envelope) => envelope.data);
  }

  static ServiceHealth _decodeHealth(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return ServiceHealth(
      service: _string(map['service']) ?? 'unknown',
      status: _string(map['status']) ?? 'unknown',
      apiVersion: _string(map['api_version']) ?? 'unknown',
    );
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
