import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

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

  test(
    'a release build refuses mock data even when the environment is dev',
    () {
      final config = AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'http://10.0.2.2:8000/api/v1',
        isReleaseBuild: true,
        rawDataMode: 'mock',
        rawMockLatencyMs: '0',
      );
      expect(config.isUsable, isFalse);
      expect(config.usesMockData, isFalse);
      expect(config.environment.name, 'dev');
      expect(
        config.issues.map((issue) => issue.message).join('\n'),
        contains('Mock data is refused'),
      );
      expect(
        config.issues.map((issue) => issue.message).join('\n'),
        contains('release'),
      );
    },
  );

  test('staging refuses to start in mock mode', () {
    final config = _config(env: 'staging', data: 'mock');
    expect(config.isUsable, isFalse);
    expect(config.usesMockData, isFalse);
    expect(
      config.issues.map((issue) => issue.message).join('\n'),
      contains('Mock data is refused'),
    );
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

  testWidgets(
    'a prod build with mock data shows _MisconfiguredApp and builds no mock repositories',
    (tester) async {
      final config = _config(env: 'prod', data: 'mock', release: true);
      final dependencies = AppDependencies.build(
        config: config,
        sessionStore: InMemorySessionStore(),
        secrets: InMemorySecretStore(),
        transport: const UnconfiguredApiTransport(),
      );
      addTearDown(dependencies.dispose);

      expect(_mockRepositoryNames(dependencies), isEmpty);

      await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_MisconfiguredApp',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Mock data is refused'), findsOneWidget);
      expect(_mockRepositoryNames(dependencies), isEmpty);
    },
  );

  test('omitting the data flag stays on the live API', () {
    final config = _config(env: 'dev');
    expect(config.dataMode, AppDataMode.live);
    expect(config.usesMockData, isFalse);
  });
}

/// Runtime types of every repository the composition root built.
///
/// A name that starts with `Mock` is a synthetic stand-in. Production must
/// not construct one, including when the config that asked for mocks was refused.
List<String> _mockRepositoryNames(AppDependencies dependencies) {
  final created = <Object?>[
    dependencies.authRepository,
    dependencies.deviceSessionRepository,
    dependencies.platformRepository,
    dependencies.serviceCatalogRepository,
    dependencies.programRepository,
    dependencies.announcementRepository,
    dependencies.eventRepository,
    dependencies.residentProfileRepository,
    dependencies.householdRepository,
    dependencies.registrationRepository,
    dependencies.barangayDirectory,
    dependencies.credentialRepository,
    dependencies.verificationRepository,
    dependencies.serviceRequestRepository,
    dependencies.requirementRepository,
    dependencies.notificationRepository,
    dependencies.accountControlsRepository,
    dependencies.officeMessagingRepository,
    dependencies.mockBehavior,
  ];
  return <String>[
    for (final object in created)
      if (object != null && object.runtimeType.toString().startsWith('Mock'))
        object.runtimeType.toString(),
  ];
}
