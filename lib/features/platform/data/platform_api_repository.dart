import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/app_bootstrap.dart';
import '../domain/platform_repository.dart';
import '../domain/privacy_notice.dart';

/// Talks to `GET /api/v1/health` and `GET /api/v1/app/config`.
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
      path: 'app/config',
      authenticated: false,
      decode: _decodeConfig,
    );
    return response.map((envelope) => envelope.data);
  }

  /// `GET /app/config`. Feature flags are strings. Absent flags stay off.
  /// Older bootstrap fields (service, api version, timezone, channel, page
  /// size) are not on this schema and keep the client defaults.
  static AppBootstrap _decodeConfig(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? flags = map['feature_flags'] ?? map['features'];
    final Map<String, bool> parsed = <String, bool>{};
    if (flags is Map) {
      flags.forEach((Object? key, Object? value) {
        if (key is! String) return;
        parsed[key] = _truthy(value);
      });
    }
    final Object? client = map['client'];
    final Map<String, dynamic> clientMap = client is Map<String, dynamic>
        ? client
        : const <String, dynamic>{};
    final Object? support = map['support'];
    final Map<String, dynamic> supportMap = support is Map<String, dynamic>
        ? support
        : const <String, dynamic>{};
    final Object? page = clientMap['default_page_size'];
    return AppBootstrap(
      service: _string(map['service']) ?? '',
      apiVersion: _string(map['api_version']) ?? '',
      timezone: _string(map['timezone']) ?? 'Asia/Manila',
      channel: _string(clientMap['channel']) ?? 'citizen-mobile',
      defaultPageSize: page is int && page > 0 ? page : 25,
      minimumVersion:
          _string(map['minimum_app_version']) ??
          _string(clientMap['minimum_version']) ??
          '',
      features: FeatureFlags(parsed),
      support: SupportContact(
        email:
            _string(map['support_email']) ?? _string(supportMap['email']) ?? '',
        phone:
            _string(map['contact_line']) ?? _string(supportMap['phone']) ?? '',
      ),
      privacyVersion: _string(map['privacy_version']) ?? '',
      termsVersion: _string(map['terms_version']) ?? '',
      updatedAt: DateTime.tryParse(
        map['updated_at'] is String ? map['updated_at'] as String : '',
      )?.toUtc(),
      privacyNotice: _notice(map['privacy_notice']),
      serverTime: DateTime.tryParse(
        map['server_time'] is String ? map['server_time'] as String : '',
      )?.toUtc(),
    );
  }

  static bool _truthy(Object? value) {
    if (value is bool) return value;
    if (value is! String) return false;
    return switch (value.trim().toLowerCase()) {
      'true' || '1' || 'yes' || 'on' => true,
      _ => false,
    };
  }

  static ServiceHealth _decodeHealth(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return ServiceHealth(
      service: _string(map['service']) ?? 'unknown',
      status: _string(map['status']) ?? 'unknown',
      apiVersion: _string(map['api_version']) ?? 'unknown',
    );
  }

  static PrivacyNotice _notice(Object? raw) {
    if (raw is! Map) return PrivacyNotice.missing;
    final Map<String, dynamic> map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final Object? body = map['body_markdown'];
    return PrivacyNotice(
      version: _string(map['version']) ?? '',
      updatedAt: DateTime.tryParse(
        map['updated_at'] is String ? map['updated_at'] as String : '',
      )?.toUtc(),
      bodyMarkdown: body is String ? body : '',
    );
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
