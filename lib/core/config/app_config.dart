import 'package:flutter/foundation.dart';

import 'app_environment.dart';

/// Immutable, compile-time-resolved application configuration.
///
/// **No secrets live here, ever.** `--dart-define` values are embedded in the
/// shipped binary in clear text and are recoverable from any downloaded APK/IPA;
/// they are configuration, not a vault. API keys, signing material and anything
/// else confidential stay server-side. This class therefore only carries values
/// that are safe to publish: which environment the build targets, the public API
/// base URL, and timeout budgets.
///
/// See CLAUDE.md Article 7.
/// Where repository data comes from.
///
/// `live` talks to the API. `mock` is synthetic fixtures, and only a dev build
/// may select it (decision D2).
enum AppDataMode {
  live('live'),
  mock('mock');

  const AppDataMode(this.wireValue);

  final String wireValue;

  static AppDataMode? tryParse(String? value) {
    if (value == null || value.isEmpty) return AppDataMode.live;
    for (final mode in AppDataMode.values) {
      if (mode.wireValue == value) return mode;
    }
    return null;
  }
}

/// How a dev mock responds, so loading and offline states can be shown.
enum MockFailureMode {
  none('none'),
  offline('offline'),
  server('server');

  const MockFailureMode(this.wireValue);

  final String wireValue;

  static MockFailureMode? tryParse(String? value) {
    if (value == null || value.isEmpty) return MockFailureMode.none;
    for (final mode in MockFailureMode.values) {
      if (mode.wireValue == value) return mode;
    }
    return null;
  }
}

@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUri,
    required this.connectTimeout,
    required this.requestTimeout,
    required this.uploadTimeout,
    this.dataMode = AppDataMode.live,
    this.mockFailure = MockFailureMode.none,
    this.mockLatency = const Duration(milliseconds: 400),
    this.issues = const <ConfigIssue>[],
  });

  /// Reads the ambient `--dart-define` values and validates them.
  ///
  /// Never throws: a misconfigured build produces [issues], which
  /// [AppConfig.isUsable] reports and the bootstrap turns into a blocking,
  /// explicit failure screen. A silent fallback to some other environment is the
  /// outcome this method exists to prevent.
  factory AppConfig.resolve() {
    const rawEnv = String.fromEnvironment(envDefineKey);
    const rawBaseUrl = String.fromEnvironment(apiBaseUrlDefineKey);
    const rawDataMode = String.fromEnvironment(dataModeDefineKey);
    const rawMockFailure = String.fromEnvironment(mockFailureDefineKey);
    const rawMockLatency = String.fromEnvironment(mockLatencyDefineKey);
    return AppConfig.from(
      rawEnvironment: rawEnv,
      rawApiBaseUrl: rawBaseUrl,
      isReleaseBuild: kReleaseMode,
      rawDataMode: rawDataMode,
      rawMockFailure: rawMockFailure,
      rawMockLatencyMs: rawMockLatency,
    );
  }

  /// Testable core of [AppConfig.resolve].
  factory AppConfig.from({
    required String rawEnvironment,
    required String rawApiBaseUrl,
    required bool isReleaseBuild,
    String rawDataMode = '',
    String rawMockFailure = '',
    String rawMockLatencyMs = '',
  }) {
    final issues = <ConfigIssue>[];

    final parsedEnvironment = AppEnvironment.tryParse(rawEnvironment);
    if (rawEnvironment.isNotEmpty && parsedEnvironment == null) {
      issues.add(
        ConfigIssue(
          'TAYTAY_ENV is "$rawEnvironment", which is not one of '
          '${AppEnvironment.values.map((e) => e.wireValue).join(', ')}.',
        ),
      );
    }
    if (rawEnvironment.isEmpty && isReleaseBuild) {
      // A release build that falls back to a development API would ship real
      // residents onto test data. Refuse instead of guessing.
      issues.add(
        const ConfigIssue(
          'Release build was compiled without --dart-define=$envDefineKey. '
          'The API target of a release build must be explicit.',
        ),
      );
    }
    final environment = parsedEnvironment ?? AppEnvironment.dev;

    // Dev debug builds may omit the URL and use the emulator host. Every
    // release build, and every staging or production build, must be given one:
    // there is no baked-in staging or production host to fall back to.
    final allowDevDefault =
        rawApiBaseUrl.isEmpty &&
        !isReleaseBuild &&
        (rawEnvironment.isEmpty || parsedEnvironment == AppEnvironment.dev);

    final String baseUrl;
    if (rawApiBaseUrl.isNotEmpty) {
      baseUrl = rawApiBaseUrl;
    } else if (allowDevDefault) {
      baseUrl = _devApiBaseUrl;
    } else {
      issues.add(
        const ConfigIssue(
          'This build was compiled without --dart-define=$apiBaseUrlDefineKey. '
          'There is no default staging or production host. A release build '
          'must pass the public API base URL (https, including /api/v1). '
          'A dev debug build may omit it.',
        ),
      );
      baseUrl = _unconfiguredApiBaseUrl;
    }

    final baseUri = Uri.tryParse(baseUrl);
    final Uri? acceptedUri;
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      acceptedUri = null;
      issues.add(
        const ConfigIssue('$apiBaseUrlDefineKey is not a valid absolute URL.'),
      );
    } else {
      acceptedUri = baseUri;
      if (baseUri.userInfo.isNotEmpty) {
        issues.add(
          const ConfigIssue(
            'The API base URL contains embedded credentials. Credentials are '
            'never carried in configuration.',
          ),
        );
      }
      if (baseUri.query.isNotEmpty) {
        issues.add(
          const ConfigIssue(
            'The API base URL must not carry query parameters — tokens and keys '
            'have been smuggled this way before.',
          ),
        );
      }
      if (baseUri.scheme != 'https' && environment != AppEnvironment.dev) {
        issues.add(
          ConfigIssue(
            'The ${environment.wireValue} API base URL must use https. '
            'Personal data may never travel in clear text.',
          ),
        );
      }
    }

    final dataMode = AppDataMode.tryParse(rawDataMode);
    if (dataMode == null) {
      issues.add(
        ConfigIssue(
          '$dataModeDefineKey is "$rawDataMode", which is not live or mock.',
        ),
      );
    }
    final resolvedDataMode = dataMode ?? AppDataMode.live;
    if (resolvedDataMode == AppDataMode.mock &&
        environment != AppEnvironment.dev) {
      issues.add(
        ConfigIssue(
          'Mock data is refused: $dataModeDefineKey=mock is only valid when '
          '$envDefineKey=dev. A ${environment.wireValue} build must not start '
          'on synthetic fixtures.',
        ),
      );
    }

    final mockFailure = MockFailureMode.tryParse(rawMockFailure);
    if (mockFailure == null) {
      issues.add(
        ConfigIssue(
          '$mockFailureDefineKey is "$rawMockFailure", which is not '
          'none, offline, or server.',
        ),
      );
    }
    var mockLatency = const Duration(milliseconds: 400);
    if (rawMockLatencyMs.isNotEmpty) {
      final parsed = int.tryParse(rawMockLatencyMs);
      if (parsed == null || parsed < 0 || parsed > 10000) {
        issues.add(
          const ConfigIssue(
            '$mockLatencyDefineKey must be a whole number of milliseconds '
            'from 0 to 10000.',
          ),
        );
      } else {
        mockLatency = Duration(milliseconds: parsed);
      }
    }

    return AppConfig(
      environment: environment,
      apiBaseUri: acceptedUri ?? Uri.parse(_unconfiguredApiBaseUrl),
      connectTimeout: const Duration(seconds: 15),
      requestTimeout: const Duration(seconds: 30),
      uploadTimeout: const Duration(minutes: 2),
      dataMode: resolvedDataMode,
      mockFailure: mockFailure ?? MockFailureMode.none,
      mockLatency: mockLatency,
      issues: List<ConfigIssue>.unmodifiable(issues),
    );
  }

  /// `--dart-define` key selecting the environment.
  static const String envDefineKey = 'TAYTAY_ENV';

  /// `--dart-define` key supplying the API base URL.
  ///
  /// Required for every release build, and for staging and production in any
  /// mode. A dev debug build may omit it. There is no baked-in staging or
  /// production host — a guessed hostname must not ship inside the binary.
  static const String apiBaseUrlDefineKey = 'TAYTAY_API_BASE_URL';

  /// `--dart-define` key selecting live or mock repositories.
  ///
  /// Mock is refused unless [envDefineKey] is `dev`.
  static const String dataModeDefineKey = 'TAYTAY_DATA';

  /// `--dart-define` key: `none`, `offline`, or `server`. Dev mocks only.
  static const String mockFailureDefineKey = 'TAYTAY_MOCK_FAILURE';

  /// `--dart-define` key: simulated mock latency in milliseconds.
  static const String mockLatencyDefineKey = 'TAYTAY_MOCK_LATENCY_MS';

  final AppEnvironment environment;

  final AppDataMode dataMode;

  final MockFailureMode mockFailure;

  final Duration mockLatency;

  /// True only for a usable dev build that asked for mocks.
  bool get usesMockData =>
      isUsable &&
      environment == AppEnvironment.dev &&
      dataMode == AppDataMode.mock;

  /// Absolute base URI of the versioned API, including the `/api/v1` prefix.
  /// The version lives in the path per `docs/api/conventions.md` §1.
  final Uri apiBaseUri;

  final Duration connectTimeout;
  final Duration requestTimeout;
  final Duration uploadTimeout;

  /// Configuration problems found at startup. Empty means the build is sound.
  final List<ConfigIssue> issues;

  bool get isUsable => issues.isEmpty;

  /// Android emulator route to the host machine. Used only when a dev debug
  /// build omits [apiBaseUrlDefineKey].
  static const String _devApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

  /// Placeholder for a build that was not given a base URL. `.invalid` is
  /// reserved and does not resolve. The startup screen refuses to run before
  /// anything reads this.
  static const String _unconfiguredApiBaseUrl =
      'https://unconfigured.invalid/api/v1';

  @override
  String toString() =>
      'AppConfig(environment: ${environment.wireValue}, '
      'dataMode: ${dataMode.wireValue}, '
      'apiBaseUri: $apiBaseUri, issues: ${issues.length})';
}

/// A single configuration defect, phrased for a developer or release engineer.
@immutable
class ConfigIssue {
  const ConfigIssue(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigIssue && other.message == message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => message;
}
