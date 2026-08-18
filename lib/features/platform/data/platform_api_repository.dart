import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
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
    final response = await _apiClient.send<AppBootstrap>(
      method: HttpMethod.get,
      path: 'app/bootstrap',
      // PUBLIC BY DESIGN, and it has to be: a client that cannot start cannot
      // sign in to be told it should update.
      authenticated: false,
      decode: _decodeBootstrap,
    );
    return response.map((envelope) => envelope.data);
  }

  static AppBootstrap _decodeBootstrap(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final client = _map(map['client']);
    final support = _map(map['support']);

    return AppBootstrap(
      service: _string(map['service']) ?? '',
      apiVersion: _string(map['api_version']) ?? '',
      serverTime: DateTime.tryParse(_string(map['server_time']) ?? '')?.toUtc(),
      timezone: _string(map['timezone']) ?? 'Asia/Manila',
      channel: _string(client['channel']) ?? 'unknown',
      defaultPageSize: _int(client['default_page_size']) ?? 25,
      // Empty means no minimum. The server is explicit that a missing
      // configuration must never become an accidental hard block, and the
      // decoder must not invent one by defaulting to anything else.
      minimumVersion: _string(client['minimum_version']) ?? '',
      features: _decodeFeatures(map['features']),
      support: SupportContact(
        email: _string(support['email']) ?? '',
        phone: _string(support['phone']) ?? '',
      ),
    );
  }

  /// Every boolean the server sent, including names this build has never heard
  /// of — a flag added server-side is readable without an app release, and
  /// anything non-boolean is dropped rather than coerced.
  static FeatureFlags _decodeFeatures(Object? raw) {
    final map = _map(raw);
    final flags = <String, bool>{};
    map.forEach((key, value) {
      if (value is bool) flags[key] = value;
    });
    return FeatureFlags(flags);
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int? _int(Object? value) =>
      value is int ? value : (value is String ? int.tryParse(value) : null);

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
