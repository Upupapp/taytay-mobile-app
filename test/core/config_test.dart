import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/config/app_environment.dart';

AppConfig build({
  String environment = 'dev',
  String baseUrl = '',
  bool release = false,
}) => AppConfig.from(
  rawEnvironment: environment,
  rawApiBaseUrl: baseUrl,
  isReleaseBuild: release,
);

void main() {
  group('AppEnvironment', () {
    test('parses the supported values and rejects everything else', () {
      expect(AppEnvironment.tryParse('dev'), AppEnvironment.dev);
      expect(AppEnvironment.tryParse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.tryParse('prod'), AppEnvironment.prod);
      expect(AppEnvironment.tryParse('production'), isNull);
      expect(AppEnvironment.tryParse(''), isNull);
      expect(AppEnvironment.tryParse(null), isNull);
    });

    test('diagnostics are shown outside production only', () {
      expect(AppEnvironment.prod.allowsDiagnosticsUi, isFalse);
      expect(AppEnvironment.staging.allowsDiagnosticsUi, isTrue);
      expect(AppEnvironment.dev.allowsDiagnosticsUi, isTrue);
      expect(AppEnvironment.prod.badgeLabel, isEmpty);
    });
  });

  group('AppConfig', () {
    test('a dev build with no overrides is usable', () {
      final config = build();
      expect(config.environment, AppEnvironment.dev);
      expect(config.isUsable, isTrue);
    });

    test('each environment has a distinct default API base URL', () {
      final urls = <String>{
        for (final environment in AppEnvironment.values)
          build(environment: environment.wireValue).apiBaseUri.toString(),
      };
      expect(urls, hasLength(AppEnvironment.values.length));
    });

    test('staging and production defaults are https and versioned', () {
      for (final environment in <AppEnvironment>[
        AppEnvironment.staging,
        AppEnvironment.prod,
      ]) {
        final uri = build(environment: environment.wireValue).apiBaseUri;
        expect(uri.scheme, 'https', reason: environment.wireValue);
        // conventions §1: the version lives in the path, never a header.
        expect(uri.path, contains('/v1'), reason: environment.wireValue);
      }
    });

    test('a release build with no environment refuses to start', () {
      final config = build(environment: '', release: true);
      expect(config.isUsable, isFalse);
      expect(
        config.issues.map((i) => i.message).join(),
        contains(AppConfig.envDefineKey),
      );
    });

    test('an unrecognised environment is an issue, not a silent fallback', () {
      final config = build(environment: 'produciton');
      expect(config.isUsable, isFalse);
    });

    test('cleartext http is rejected outside development', () {
      expect(
        build(
          environment: 'prod',
          baseUrl: 'http://api.taytay.gov.ph/api/v1',
        ).isUsable,
        isFalse,
      );
      expect(
        build(
          environment: 'staging',
          baseUrl: 'http://staging.taytay.gov.ph/api/v1',
        ).isUsable,
        isFalse,
      );
      // Local development against an emulator host is allowed.
      expect(
        build(
          environment: 'dev',
          baseUrl: 'http://10.0.2.2:8000/api/v1',
        ).isUsable,
        isTrue,
      );
    });

    test('credentials embedded in the base URL are rejected', () {
      final config = build(
        environment: 'prod',
        baseUrl: 'https://user:secret@api.taytay.gov.ph/api/v1',
      );
      expect(config.isUsable, isFalse);
      expect(
        config.issues.map((i) => i.message).join(),
        contains('credentials'),
      );
    });

    test('a query string on the base URL is rejected', () {
      // Tokens have been smuggled into "configuration" this way.
      expect(
        build(
          environment: 'prod',
          baseUrl: 'https://api.taytay.gov.ph/api/v1?key=abc123',
        ).isUsable,
        isFalse,
      );
    });

    test('a malformed base URL is reported rather than thrown', () {
      final config = build(environment: 'dev', baseUrl: 'not a url');
      expect(config.isUsable, isFalse);
    });

    test('toString carries no credential-shaped content', () {
      expect(build().toString(), isNot(contains('token')));
    });

    test('timeouts are bounded so a request cannot hang forever', () {
      final config = build();
      expect(config.connectTimeout, lessThanOrEqualTo(config.requestTimeout));
      expect(config.requestTimeout, lessThan(config.uploadTimeout));
      expect(config.requestTimeout.inSeconds, greaterThan(0));
    });
  });
}
