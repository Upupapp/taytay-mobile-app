import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_router.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/splash/presentation/splash_screen.dart';

/// What startup of [TaytayResidentApp] actually did.
///
/// Availability is asked only by the app lock's load. `app/config` is the
/// bootstrap refresh. [debugBuildAppRouterCount] moves only inside
/// [buildAppRouter], including a router that was built and then disposed.
class _StartupProbe {
  _StartupProbe()
    : authenticator = _CountingAuthenticator(),
      transport = _RecordingTransport(),
      routersBefore = debugBuildAppRouterCount;

  final _CountingAuthenticator authenticator;
  final _RecordingTransport transport;
  final int routersBefore;

  int get routerBuilds => debugBuildAppRouterCount - routersBefore;

  int get bootstrapCalls =>
      transport.paths.where((path) => path == 'app/config').length;
}

void main() {
  testWidgets(
    'unusable config skips lock load, platform refresh, and the router',
    (tester) async {
      final probe = _StartupProbe();
      final config = AppConfig.from(
        rawEnvironment: 'prod',
        rawApiBaseUrl: 'https://api.example.com/api/v1',
        isReleaseBuild: true,
        rawDataMode: 'mock',
      );
      expect(config.isUsable, isFalse);

      await _pump(tester, config: config, probe: probe);
      await tester.pump();

      expect(_misconfiguredApp, findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(probe.authenticator.availabilityCalls, 0);
      expect(probe.bootstrapCalls, 0);
      expect(probe.routerBuilds, 0);

      // Dispose used to be the read that forced the lazy router into existence.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(probe.authenticator.availabilityCalls, 0);
      expect(probe.bootstrapCalls, 0);
      expect(probe.routerBuilds, 0);
    },
  );

  testWidgets(
    'usable config still loads the lock, refreshes the platform, and builds the router',
    (tester) async {
      final probe = _StartupProbe();
      final config = AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: '',
        isReleaseBuild: false,
      );
      expect(config.isUsable, isTrue);

      await _pump(tester, config: config, probe: probe, welcomeSeen: true);

      expect(_misconfiguredApp, findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(probe.authenticator.availabilityCalls, 1);
      expect(probe.bootstrapCalls, 1);
      expect(probe.routerBuilds, 1);

      // The splash holds on a timer. Advance past it so the test does not end
      // with that timer still pending, then confirm startup did not run again.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(probe.authenticator.availabilityCalls, 1);
      expect(probe.bootstrapCalls, 1);
      expect(probe.routerBuilds, 1);
    },
  );
}

final Finder _misconfiguredApp = find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_MisconfiguredApp',
);

Future<void> _pump(
  WidgetTester tester, {
  required AppConfig config,
  required _StartupProbe probe,
  bool welcomeSeen = false,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  if (welcomeSeen) {
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  }

  final dependencies = AppDependencies.build(
    config: config,
    sessionStore: InMemorySessionStore(),
    secrets: secrets,
    transport: probe.transport,
    localAuthenticator: probe.authenticator,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
}

class _CountingAuthenticator implements LocalAuthenticator {
  int availabilityCalls = 0;

  @override
  Future<LocalUnlockAvailability> availability() async {
    availabilityCalls += 1;
    return LocalUnlockAvailability.unsupported;
  }

  @override
  Future<LocalUnlockOutcome> authenticate({required String reason}) async =>
      LocalUnlockOutcome.unavailable;
}

class _RecordingTransport implements ApiTransport {
  final List<String> paths = <String>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    paths.add(request.path);
    return Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{'data': <String, Object?>{}}),
      ),
    );
  }
}
