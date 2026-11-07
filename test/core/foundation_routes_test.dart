import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_headers.dart';

const SessionState _guest = GuestSession();
const SessionState _unverified = AuthenticatedSession(
  ResidentSession(
    accountId: 'acct-sample',
    accessLevel: AccessLevel.unverified,
  ),
);
const SessionState _verified = AuthenticatedSession(
  ResidentSession(accountId: 'acct-sample', accessLevel: AccessLevel.verified),
);

/// Routes that do not show a back button.
///
/// Written out, not derived from [AppRoute.showsBackButton]. That getter is
/// `!navigationRoots.contains`, so a test that only compares the two checks
/// the definition against itself.
///
/// Shell tabs, plus the splash, onboarding and the three gates.
/// Events left the bar in S4 and shows a back button. Programs is the Tulong
/// root and does not.
const Set<AppRoute> _routesWithoutBackButton = <AppRoute>{
  AppRoute.splash,
  AppRoute.onboarding,
  AppRoute.updateRequired,
  AppRoute.maintenance,
  AppRoute.consentUpdate,
  AppRoute.home,
  AppRoute.services,
  AppRoute.news,
  AppRoute.programs,
  AppRoute.profile,
};

/// Screens whose header is [WovenHeader], including the navigation-root welcome.
const Set<AppRoute> _wovenHeaderRoutes = <AppRoute>{
  AppRoute.onboarding,
  AppRoute.signIn,
  AppRoute.signInHelp,
  AppRoute.forgotPassword,
};

const Map<AppRoute, Map<String, String>>
_sampleArguments = <AppRoute, Map<String, String>>{
  AppRoute.serviceDetail: <String, String>{'serviceCode': 'business-permit'},
  AppRoute.applyForService: <String, String>{'serviceCode': 'business-permit'},
  AppRoute.newsPost: <String, String>{'postId': 'post-sample-1'},
  AppRoute.eventDetail: <String, String>{'eventId': 'evt-sample-1'},
  AppRoute.eventRegistration: <String, String>{'eventId': 'evt-sample-1'},
  AppRoute.requestDetail: <String, String>{'requestId': 'req-sample-1'},
  AppRoute.requestRequirements: <String, String>{'requestId': 'req-sample-1'},
  AppRoute.programDetail: <String, String>{'programId': 'aics'},
  AppRoute.tulongOffice: <String, String>{'officeId': 'mswdo'},
  AppRoute.officeDetail: <String, String>{'officeId': 'mswdo'},
  AppRoute.officeCompose: <String, String>{'officeId': 'mswdo'},
  AppRoute.officeMessageSent: <String, String>{'officeId': 'mswdo'},
  AppRoute.messageThread: <String, String>{'threadId': 'thread-sample-1'},
  AppRoute.issuanceType: <String, String>{'typeId': 'dt-sample-birth'},
  AppRoute.issuanceForm: <String, String>{'typeId': 'dt-sample-birth'},
  AppRoute.issuanceRequestDetail: <String, String>{
    'requestId': 'dr-sample-ready',
  },
};

String _openLocation(AppRoute route) =>
    route.location(_sampleArguments[route] ?? const <String, String>{});

void main() {
  test('routes with no back button are this list', () {
    expect(AppRoute.navigationRoots, _routesWithoutBackButton);
    expect(_routesWithoutBackButton, isNot(contains(AppRoute.events)));
    for (final route in AppRoute.values) {
      expect(
        route.showsBackButton,
        !_routesWithoutBackButton.contains(route),
        reason: route.routeName,
      );
    }
  });

  test('the live shell is the approved five tabs', () {
    expect(AppRoute.designRootTabs, <AppRoute>[
      AppRoute.home,
      AppRoute.services,
      AppRoute.news,
      AppRoute.programs,
      AppRoute.profile,
    ]);
    expect(AppRoute.designRootTabs, isNot(contains(AppRoute.events)));
    expect(AppRoute.shellDestinations, AppRoute.designRootTabs);
    expect(AppRoute.shellDestinations, isNot(contains(AppRoute.events)));
  });

  test('new public routes stay reachable for a guest', () {
    for (final route in <AppRoute>[
      AppRoute.forgotPassword,
      AppRoute.hotlines,
      AppRoute.photoCredits,
    ]) {
      expect(
        resolveRedirect(session: _guest, location: route.path),
        isNull,
        reason: route.routeName,
      );
    }
    expect(
      resolveRedirect(session: _guest, location: '/offices/mswdo'),
      isNull,
    );
  });

  test('office messaging is verified-only', () {
    const locations = <String>[
      '/profile/messages',
      '/messages/thread-sample-1',
      '/offices/mswdo/message',
      '/offices/mswdo/message/sent',
    ];
    for (final location in locations) {
      expect(
        resolveRedirect(session: _guest, location: location),
        contains(AppRoute.signIn.path),
        reason: location,
      );
      expect(
        resolveRedirect(session: _unverified, location: location),
        AppRoute.verification.path,
        reason: location,
      );
      expect(
        resolveRedirect(session: _verified, location: location),
        isNull,
        reason: location,
      );
    }
  });

  test('the component gallery is refused outside a dev build', () {
    for (final session in <SessionState>[_guest, _unverified, _verified]) {
      expect(
        resolveRedirect(
          session: session,
          location: AppRoute.componentGallery.path,
        ),
        AppRoute.home.path,
        reason: session.runtimeType.toString(),
      );
      expect(
        resolveRedirect(
          session: session,
          location: AppRoute.componentGallery.path,
          allowDevRoutes: true,
        ),
        isNull,
      );
    }
  });

  test('a restoring session still waits, including on the gallery', () {
    expect(
      resolveRedirect(
        session: const SessionRestoring(),
        location: AppRoute.componentGallery.path,
        allowDevRoutes: true,
      ),
      AppRoute.splash.path,
    );
  });

  testWidgets('every route shows one TaytayBackButton, or none on a root', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = InMemorySessionStore();
    await store.write(
      const StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: AccessLevel.verified,
          displayName: 'Ana',
        ),
        accessToken: 'token-sample',
      ),
    );
    final secrets = InMemorySecretStore();
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');

    final dependencies = AppDependencies.build(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: '',
        isReleaseBuild: false,
        rawDataMode: 'mock',
        rawMockLatencyMs: '0',
      ),
      sessionStore: store,
      secrets: secrets,
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
    await tester.pump();

    // Splash holds while the session is still restoring. It is a root.
    expect(_currentPath(tester), AppRoute.splash.path);
    _expectBackButtons(AppRoute.splash);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The dev mock answers bootstrap with self-registration off, which would
    // send /register to sign-in. Publish the flag so the wizard itself opens.
    dependencies.platform.replaceBootstrapForTesting(
      const AppBootstrap(
        service: 'taytay-sample',
        apiVersion: 'sample',
        timezone: 'Asia/Manila',
        channel: 'citizen-mobile',
        defaultPageSize: 15,
        minimumVersion: '',
        features: FeatureFlags(<String, bool>{'self_registration': true}),
        support: SupportContact.none,
      ),
    );
    await tester.pumpAndSettle();

    for (final route in AppRoute.values) {
      if (route == AppRoute.splash || route == AppRoute.signIn) continue;
      _go(tester, _openLocation(route));
      await tester.pumpAndSettle();
      final String landed =
          route == AppRoute.serviceDetail || route == AppRoute.applyForService
          ? AppRoute.programDetail.location(<String, String>{
              'programId': _sampleArguments[route]!['serviceCode']!,
            })
          // The dev mock names no consent version, so nothing is owed and
          // the consent gate sends the resident home.
          : route == AppRoute.consentUpdate
          ? AppRoute.home.path
          : _openLocation(route);
      expect(_currentPath(tester), landed, reason: route.name);
      _expectBackButtons(route);
      if (_wovenHeaderRoutes.contains(route)) {
        expect(
          find.byType(WovenHeader),
          findsOneWidget,
          reason: route.routeName,
        );
      }
    }

    // My Account, verified: its "Request documents" row opens the catalogue,
    // pushed, so back returns to My Account. Eight rows at 400×900 once
    // overflowed this frame; it scrolls now, and the walk above would have
    // failed on an overflow.
    _go(tester, AppRoute.profile.path);
    await tester.pumpAndSettle();
    final Finder documents = find.text('Request documents');
    await tester.ensureVisible(documents);
    await tester.pumpAndSettle();
    await tester.tap(documents);
    await tester.pumpAndSettle();
    // Pushed: the router's location stays /profile and the catalogue is on top.
    final Finder catalogue = find.byKey(const Key('issuance-my-requests'));
    expect(catalogue, findsOneWidget);
    _expectBackButtons(AppRoute.issuanceCatalogue);
    await tester.tap(find.byType(TaytayBackButton));
    await tester.pumpAndSettle();
    expect(catalogue, findsNothing);
    expect(_currentPath(tester), AppRoute.profile.path);
    expect(find.text('Request documents'), findsOneWidget);

    // A signed-in resident is sent away from sign-in. Open it as a guest.
    await dependencies.session.signOut();
    await tester.pumpAndSettle();
    _go(tester, AppRoute.signIn.path);
    await tester.pumpAndSettle();
    expect(_currentPath(tester), AppRoute.signIn.path);
    _expectBackButtons(AppRoute.signIn);
    expect(find.byType(WovenHeader), findsOneWidget);
  });
}

void _go(WidgetTester tester, String location) {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
}

String _currentPath(WidgetTester tester) {
  return GoRouter.of(
    tester.element(find.byType(Scaffold).first),
  ).routerDelegate.currentConfiguration.uri.path;
}

void _expectBackButtons(AppRoute route) {
  expect(
    find.byType(TaytayBackButton),
    _routesWithoutBackButton.contains(route) ? findsNothing : findsOneWidget,
    reason: route.routeName,
  );
}
