import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/security_screen.dart';
import '../../features/auth/presentation/sign_in_help_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/credential/presentation/digital_id_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/registration/presentation/registration_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../design/design_tokens.dart';
import '../session/session_controller.dart';
import '../startup/launch_controller.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Builds the app's router.
///
/// **Why `go_router` and a declarative redirect.** Navigation here is derived
/// state: the session decides what is reachable, so the guard must run on
/// *every* navigation, including deep links, notification taps and Android
/// back-stack restoration. An imperative `Navigator.push` guarded at each call
/// site only protects the paths someone remembered to guard, and cannot protect
/// a cold start into a deep link at all.
///
/// The router listens to [SessionController]: when the session ends — because
/// the resident signed out, or because the server answered 401 — every protected
/// route re-evaluates and the resident is moved off it without a single screen
/// knowing about session handling.
GoRouter buildAppRouter({
  required SessionController session,
  required LaunchController launch,
  String? initialLocation,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation ?? AppRoute.splash.path,
    // Both are navigation inputs: the session decides what is reachable, and
    // first-launch decides where a cold start begins. Merged so a change to
    // either re-evaluates the guard.
    refreshListenable: Listenable.merge(<Listenable>[session, launch]),
    debugLogDiagnostics: false,
    redirect: (context, state) => resolveRedirect(
      session: session.state,
      location: state.uri.toString(),
      launch: launch.state,
    ),
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn.path,
        name: AppRoute.signIn.routeName,
        builder: (context, state) => SignInScreen(
          returnTo: state.uri.queryParameters[AppRoute.redirectQueryParam],
        ),
      ),
      GoRoute(
        path: AppRoute.signInHelp.path,
        name: AppRoute.signInHelp.routeName,
        builder: (context, state) => const SignInHelpScreen(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.routeName,
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.account.path,
        name: AppRoute.account.routeName,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoute.security.path,
        name: AppRoute.security.routeName,
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoute.verification.path,
        name: AppRoute.verification.routeName,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoute.digitalId.path,
        name: AppRoute.digitalId.routeName,
        builder: (context, state) => const DigitalIdScreen(),
      ),
    ],
  );
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.explore_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'That link does not lead anywhere in this app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: () => context.goNamed(AppRoute.home.routeName),
                child: const Text('Go to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
