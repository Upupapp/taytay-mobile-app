import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';

AppConfig _config({
  required String env,
  String data = '',
  String failure = '',
  String latency = '',
  bool release = false,
}) {
  return AppConfig.from(
    rawEnvironment: env,
    rawApiBaseUrl: env == 'dev' ? '' : 'https://api.example.com/api/v1',
    isReleaseBuild: release,
    rawDataMode: data,
    rawMockFailure: failure,
    rawMockLatencyMs: latency,
  );
}

void main() {
  test('a dev build may select the synthetic mock', () {
    final config = _config(env: 'dev', data: 'mock', latency: '0');
    expect(config.isUsable, isTrue);
    expect(config.usesMockData, isTrue);
    expect(config.mockLatency, Duration.zero);
    expect(config.toString(), contains('dataMode: mock'));
    expect(config.toString(), isNot(contains('token')));
  });

  test('production refuses to start in mock mode', () {
    final config = _config(env: 'prod', data: 'mock', release: true);
    expect(config.isUsable, isFalse);
    expect(config.usesMockData, isFalse);
    expect(
      config.issues.map((issue) => issue.message).join('\n'),
      contains('Mock data is refused'),
    );
  });

  test('staging refuses to start in mock mode', () {
    final config = _config(env: 'staging', data: 'mock');
    expect(config.isUsable, isFalse);
    expect(config.usesMockData, isFalse);
  });

  test('an unknown data mode is a config error', () {
    final config = _config(env: 'dev', data: 'fixtures');
    expect(config.isUsable, isFalse);
  });

  test('an unknown failure mode is a config error', () {
    final config = _config(env: 'dev', data: 'mock', failure: 'explode');
    expect(config.isUsable, isFalse);
  });

  test('latency outside 0 to 10000 is a config error', () {
    expect(_config(env: 'dev', latency: '-1').isUsable, isFalse);
    expect(_config(env: 'dev', latency: '10001').isUsable, isFalse);
    expect(_config(env: 'dev', latency: '400').mockLatency.inMilliseconds, 400);
  });

  test('omitting the data flag stays on the live API', () {
    final config = _config(env: 'dev');
    expect(config.dataMode, AppDataMode.live);
    expect(config.usesMockData, isFalse);
  });
}
