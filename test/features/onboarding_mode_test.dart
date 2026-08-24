import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/onboarding_mode.dart';

const SessionState _guest = GuestSession();
const SessionState _verified = AuthenticatedSession(
  ResidentSession(
    accountId: 'acct-1',
    displayName: 'Maria',
    accessLevel: AccessLevel.verified,
  ),
);

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the app to the sign-in screen with the flag set as asked.
Future<void> _bootToSignIn(
  WidgetTester tester, {
  required bool selfRegistration,
  Locale locale = AppLocales.english,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // The same mechanism `device_adaptation_test.dart` uses: the app resolves the
  // locale itself, so the platform is told which one rather than a Localizations
  // ancestor being faked around it.
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final dependencies = AppDependencies.build(
    config: _config(),
    transport: _BootstrapTransport(selfRegistration: selfRegistration),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  final signIn = find.text('Sign in').first;
  await tester.ensureVisible(signIn);
  await tester.tap(signIn);
  await tester.pumpAndSettle();
}

void main() {
  group('the mode describes the platform, not an intention', () {
    test('an absent flag is staff-mediated, and is not an error', () {
      // The normal case, and the one that must be right: the backend does not
      // publish this flag today because it has no route behind it.
      expect(
        OnboardingMode.fromFlag(FeatureFlags.none.selfRegistration),
        OnboardingMode.staffMediated,
      );
    });

    test('the flag switches it, without a new build', () {
      expect(
        OnboardingMode.fromFlag(
          const FeatureFlags(<String, bool>{
            'self_registration': true,
          }).selfRegistration,
        ),
        OnboardingMode.selfEnrolled,
      );
    });

    test('a flag explicitly off is staff-mediated', () {
      expect(
        OnboardingMode.fromFlag(
          const FeatureFlags(<String, bool>{
            'self_registration': false,
          }).selfRegistration,
        ),
        OnboardingMode.staffMediated,
      );
    });
  });

  group('the wizard is unreachable while there is nothing behind it', () {
    test('by route, for a guest and for a signed-in resident', () {
      for (final SessionState session in <SessionState>[_guest, _verified]) {
        expect(
          resolveRedirect(session: session, location: AppRoute.register.path),
          AppRoute.signIn.path,
          reason: 'sign-in is the honest next step, not a dead end',
        );
      }
    });

    test('by deep link, including one carrying a query string', () {
      // The links this app receives arrive from SMS, email and printed QR
      // codes. A guard that only covered in-app navigation would leave the
      // wizard reachable by exactly the routes it cannot control.
      expect(
        resolveRedirect(
          session: _guest,
          location: '${AppRoute.register.path}?from=/home',
        ),
        AppRoute.signIn.path,
      );
    });

    test('and the default is staff-mediated without anybody saying so', () {
      // The parameter's default, asserted directly. A caller that forgets to
      // pass the mode gets the safe answer rather than the permissive one.
      expect(
        resolveRedirect(session: _guest, location: AppRoute.register.path),
        isNot(isNull),
      );
    });
  });

  group('what a resident actually sees', () {
    testWidgets('staff-mediated shows the office panel, not a dead control', (
      tester,
    ) async {
      await _bootToSignIn(tester, selfRegistration: false);

      // The acceptance criterion is "not a disabled button". A control a
      // resident cannot use reads as a broken app; a sentence tells them where
      // to go.
      expect(
        find.text('Accounts are made at the MSWDO office'),
        findsOneWidget,
      );
      expect(find.text('Create an account'), findsNothing);
    });

    testWidgets('and the office contact comes from the server', (tester) async {
      await _bootToSignIn(tester, selfRegistration: false);

      expect(
        find.textContaining('mswdo@taytayrizal.gov.ph'),
        findsOneWidget,
        reason:
            'a phone number compiled into a released app is one the '
            'municipality cannot correct without a store submission',
      );
    });

    testWidgets('self-enrolled shows the wizard entry instead', (tester) async {
      await _bootToSignIn(tester, selfRegistration: true);

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Accounts are made at the MSWDO office'), findsNothing);
    });

    testWidgets('the office panel is in Filipino too', (tester) async {
      await _bootToSignIn(
        tester,
        selfRegistration: false,
        locale: AppLocales.filipino,
      );

      expect(
        find.text('Ginagawa ang account sa tanggapan ng MSWDO'),
        findsOneWidget,
      );
    });
  });

  group('and reachable the moment the server says so', () {
    test('self-enrolled opens the route, unchanged', () {
      expect(
        resolveRedirect(
          session: _guest,
          location: AppRoute.register.path,
          onboarding: OnboardingMode.selfEnrolled,
        ),
        isNull,
      );
    });

    test('nothing else about routing changes with the mode', () {
      // The seam is one route. If switching it moved anything else, it would be
      // a product change disguised as a flag.
      for (final AppRoute route in AppRoute.values) {
        if (route == AppRoute.register) continue;
        expect(
          resolveRedirect(
            session: _verified,
            location: route.path,
            onboarding: OnboardingMode.selfEnrolled,
          ),
          resolveRedirect(session: _verified, location: route.path),
          reason: route.name,
        );
      }
    });
  });
}

/// Answers `app/bootstrap` with the flag set as asked, and a support contact.
class _BootstrapTransport implements ApiTransport {
  _BootstrapTransport({required this.selfRegistration});

  final bool selfRegistration;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    if (request.path == 'app/bootstrap') {
      return Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'service': 'taytay',
              'api_version': 'v1',
              'client': <String, Object?>{
                'channel': 'citizen-mobile',
                'default_page_size': 15,
                'minimum_version': '0.0.0',
              },
              'features': <String, Object?>{
                'self_registration': selfRegistration,
              },
              'support': <String, Object?>{
                'email': 'mswdo@taytayrizal.gov.ph',
                'phone': '(02) 8286-0000',
              },
            },
          }),
          headers: const <String, String>{'content-type': 'application/json'},
        ),
      );
    }
    return const Err<ApiHttpResponse>(NetworkFailure());
  }
}
