import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/app_bootstrap.dart';
import '../domain/platform_repository.dart';

/// Talks to `GET /api/v1/health` and `GET /api/v1/app/bootstrap`.
///
/// The reference implementation every repository that follows is modelled on:
/// the data layer owns the wire format, the domain layer never sees a `Map`, and
/// unknown fields are ignored rather than rejected (conventions §1 — "clients
/// must ignore unknown fields", and `meta` is declared additive).
///
/// The doc comment here used to say health was "the only endpoint the Taytay
/// backend currently publishes". It publishes 262.
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

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<AppBootstrap>(
      BackendGap.absentOnNodeContract,
      'loadBootstrap',
    );
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
