import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/startup/platform_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';

/// Scripted platform repository. Never a real socket.
class _ScriptedPlatform implements PlatformRepository {
  _ScriptedPlatform({this.bootstrap});

  final AppBootstrap? bootstrap;
  int calls = 0;

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async {
    calls++;
    final AppBootstrap? value = bootstrap;
    if (value == null) {
      return const Err<AppBootstrap>(
        NetworkFailure(debugMessage: 'no connection'),
      );
    }
    return Ok<AppBootstrap>(value);
  }

  @override
  Future<Result<ServiceHealth>> checkHealth() async =>
      const Err<ServiceHealth>(NetworkFailure(debugMessage: 'not used here'));
}

AppBootstrap bootstrapWith({
  String minimumVersion = '',
  Map<String, bool> features = const <String, bool>{},
}) => AppBootstrap(
  service: 'taytay-lguids',
  apiVersion: 'v1',
  timezone: 'Asia/Manila',
  channel: 'citizen-mobile',
  defaultPageSize: 25,
  minimumVersion: minimumVersion,
  features: FeatureFlags(features),
  support: const SupportContact(email: 'help@taytay.example', phone: '8000'),
);

void main() {
  group('SupportedVersion — every uncertain case lets the resident in', () {
    test('no published minimum means no minimum', () {
      expect(
        SupportedVersion.compare(appVersion: '1.0.0', minimum: ''),
        SupportedVersion.supported,
      );
    });

    test('an older build than the minimum is refused', () {
      expect(
        SupportedVersion.compare(appVersion: '1.0.0', minimum: '1.2.0'),
        SupportedVersion.tooOld,
      );
      expect(
        SupportedVersion.compare(appVersion: '1.9.9', minimum: '2.0.0'),
        SupportedVersion.tooOld,
      );
    });

    test('equal or newer is served', () {
      for (final String version in <String>[
        '1.2.0',
        '1.2.1',
        '1.3.0',
        '2.0.0',
      ]) {
        expect(
          SupportedVersion.compare(appVersion: version, minimum: '1.2.0'),
          SupportedVersion.supported,
          reason: '$version should be served against a 1.2.0 minimum',
        );
      }
    });

    test('a build suffix is ignored, not treated as a component', () {
      expect(
        SupportedVersion.compare(appVersion: '1.2.0+37', minimum: '1.2.0'),
        SupportedVersion.supported,
      );
    });

    test('a malformed minimum never locks anybody out', () {
      // A build with a broken update check cannot fix its own update check, so
      // every unparseable case resolves to "let them in". The cost of a wrong
      // `tooOld` is a resident with a working app sent to a store for a version
      // that may not exist.
      for (final String junk in <String>[
        'latest',
        '1.2.3.4',
        'v1.2.0',
        '1.-2.0',
        '  ',
        'null',
      ]) {
        expect(
          SupportedVersion.compare(appVersion: '1.0.0', minimum: junk),
          SupportedVersion.supported,
          reason: 'a minimum of "$junk" must not block',
        );
      }
    });
  });

  group('feature flags are rendering hints and fail closed', () {
    test('an absent flag is off', () {
      expect(bootstrapWith().features.digitalId, isFalse);
      expect(bootstrapWith().features.isOn('anything_at_all'), isFalse);
    });

    test('a flag the server sends is readable, known or not', () {
      final FeatureFlags flags = bootstrapWith(
        features: <String, bool>{
          'digital_id': true,
          'a_flag_from_a_later_release': true,
        },
      ).features;

      expect(flags.digitalId, isTrue);
      expect(flags.isOn('a_flag_from_a_later_release'), isTrue);
      expect(flags.names, contains('a_flag_from_a_later_release'));
    });
  });

  group('PlatformController', () {
    test('starts permissive on versions and closed on features', () {
      final PlatformController controller = PlatformController(
        repository: _ScriptedPlatform(),
      );

      expect(controller.hasAnswered, isFalse);
      expect(controller.mustUpgrade, isFalse);
      expect(controller.features.digitalId, isFalse);
      expect(controller.isInMaintenance, isFalse);
    });

    test('a failed bootstrap does not unlock or lock anything', () async {
      final PlatformController controller = PlatformController(
        repository: _ScriptedPlatform(),
        version: '1.0.0',
      );

      await controller.refresh();

      expect(controller.hasAnswered, isFalse);
      expect(controller.mustUpgrade, isFalse);
      expect(controller.features.digitalId, isFalse);
    });

    test('a published minimum above this build demands an upgrade', () async {
      final PlatformController controller = PlatformController(
        repository: _ScriptedPlatform(
          bootstrap: bootstrapWith(minimumVersion: '2.0.0'),
        ),
        version: '1.0.0',
      );

      await controller.refresh();

      expect(controller.hasAnswered, isTrue);
      expect(controller.mustUpgrade, isTrue);
      expect(controller.support.phone, '8000');
    });

    test('a 503 raises maintenance; a success clears it', () {
      final PlatformController controller = PlatformController(
        repository: _ScriptedPlatform(),
      );

      controller.observe(
        const ServerFailure(isTemporary: true, isMaintenance: true),
      );
      expect(controller.isInMaintenance, isTrue);

      controller.observe(null);
      expect(controller.isInMaintenance, isFalse);
    });

    test('an unwired repository declining is not maintenance', () {
      // The distinction the whole flag exists for. Fourteen repositories decline
      // with a temporary ServerFailure right now; if that read as maintenance,
      // the screen would be showing against a perfectly healthy server.
      final PlatformController controller = PlatformController(
        repository: _ScriptedPlatform(),
      );

      controller.observe(
        const ServerFailure(isTemporary: true, debugMessage: 'not wired yet'),
      );

      expect(controller.isInMaintenance, isFalse);
    });
  });

  group('the guard honours what the server said', () {
    const SessionState verified = AuthenticatedSession(
      ResidentSession(accountId: 'acct-1', accessLevel: AccessLevel.verified),
    );
    const SessionState guest = GuestSession();

    test(
      'an unsupported build is sent to the upgrade screen from anywhere',
      () {
        for (final AppRoute route in <AppRoute>[
          AppRoute.home,
          AppRoute.services,
          AppRoute.signIn,
          AppRoute.splash,
        ]) {
          expect(
            resolveRedirect(
              session: verified,
              location: route.path,
              mustUpgrade: true,
            ),
            AppRoute.updateRequired.path,
            reason: '${route.path} should be blocked',
          );
        }
      },
    );

    test('and cannot navigate away from it', () {
      expect(
        resolveRedirect(
          session: verified,
          location: AppRoute.updateRequired.path,
          mustUpgrade: true,
        ),
        isNull,
      );
    });

    test('the upgrade gate outranks the session gate', () {
      // Restoring a session for a client the server will not serve is work
      // nobody benefits from, and the screen must reach a resident who cannot
      // sign in at all.
      expect(
        resolveRedirect(
          session: const SessionRestoring(),
          location: AppRoute.home.path,
          mustUpgrade: true,
        ),
        AppRoute.updateRequired.path,
      );
    });

    test('maintenance stops what needs the server for one resident', () {
      expect(
        resolveRedirect(
          session: verified,
          location: AppRoute.account.path,
          isInMaintenance: true,
        ),
        AppRoute.maintenance.path,
      );
    });

    test('maintenance leaves guest browsing alone', () {
      // Cached services and programmes still read. A resident who opened the app
      // to check what a clearance needs should get that answer, not a wall.
      for (final AppRoute route in <AppRoute>[
        AppRoute.home,
        AppRoute.services,
        AppRoute.settings,
      ]) {
        expect(
          resolveRedirect(
            session: guest,
            location: route.path,
            isInMaintenance: true,
          ),
          isNull,
          reason: '${route.path} is public and should stay reachable',
        );
      }
    });

    test('neither gate fires when the server has said nothing', () {
      expect(
        resolveRedirect(session: verified, location: AppRoute.account.path),
        isNull,
      );
    });
  });

  group('both blocking paths render for a resident', () {
    Future<void> boot(
      WidgetTester tester, {
      required PlatformController platform,
      Locale? locale,
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1;
      // The device's language decides — this app has no in-app switcher, because
      // a resident who told their phone they read Filipino has already answered.
      final Locale chosen = locale ?? AppLocales.english;
      tester.platformDispatcher.localeTestValue = chosen;
      tester.platformDispatcher.localesTestValue = <Locale>[chosen];
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final InMemorySecretStore secrets = InMemorySecretStore();
      await secrets.write(LaunchController.welcomeCompletedKey, 'true');

      final AppDependencies base = AppDependencies.build(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        secrets: secrets,
        sessionStore: InMemorySessionStore(),
        localAuthenticator: const UnavailableLocalAuthenticator(),
        documentPicker: const UnavailableDocumentPicker(),
      );

      final AppDependencies dependencies = AppDependencies(
        config: base.config,
        session: base.session,
        launch: base.launch,
        intents: base.intents,
        appLock: base.appLock,
        apiClient: base.apiClient,
        cache: base.cache,
        network: base.network,
        telemetry: base.telemetry,
        authRepository: base.authRepository,
        deviceSessionRepository: base.deviceSessionRepository,
        platformRepository: base.platformRepository,
        serviceCatalogRepository: base.serviceCatalogRepository,
        programRepository: base.programRepository,
        announcementRepository: base.announcementRepository,
        eventRepository: base.eventRepository,
        residentProfileRepository: base.residentProfileRepository,
        householdRepository: base.householdRepository,
        credentialRepository: base.credentialRepository,
        verificationRepository: base.verificationRepository,
        serviceRequestRepository: base.serviceRequestRepository,
        requirementRepository: base.requirementRepository,
        documentPicker: base.documentPicker,
        shareService: base.shareService,
        externalLinks: base.externalLinks,
        accountControlsRepository: base.accountControlsRepository,
        notificationRepository: base.notificationRepository,
        registrationRepository: base.registrationRepository,
        platform: platform,
        onDispose: base.onDispose,
      );
      addTearDown(dependencies.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: textScaler),
          child: TaytayResidentApp(dependencies: dependencies),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('an unsupported build meets the upgrade screen', (
      tester,
    ) async {
      final PlatformController platform = PlatformController(
        repository: _ScriptedPlatform(
          bootstrap: bootstrapWith(minimumVersion: '99.0.0'),
        ),
        version: '1.0.0',
      );
      await platform.refresh();

      await boot(tester, platform: platform);

      expect(find.text('Update the app to continue'), findsOneWidget);
      // The support contact is the whole point of a screen with no way forward.
      expect(find.text('8000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and survives Filipino at 200%', (tester) async {
      final PlatformController platform = PlatformController(
        repository: _ScriptedPlatform(
          bootstrap: bootstrapWith(minimumVersion: '99.0.0'),
        ),
        version: '1.0.0',
      );
      await platform.refresh();

      await boot(
        tester,
        platform: platform,
        locale: AppLocales.filipino,
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('I-update ang app para makapagpatuloy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 503 puts an account screen behind the maintenance notice', (
      tester,
    ) async {
      final PlatformController platform = PlatformController(
        repository: _ScriptedPlatform(),
      );
      platform.observe(
        const ServerFailure(isTemporary: true, isMaintenance: true),
      );

      await boot(tester, platform: platform);
      expect(platform.isInMaintenance, isTrue);
    });
  });
}
