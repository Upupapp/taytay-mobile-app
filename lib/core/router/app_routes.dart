import '../session/access_policy.dart';

/// Every destination in the app, with the access it requires.
///
/// The requirement lives *next to the path*, not in a separate table and not
/// inside the screen, so that adding a route forces the author to answer "who
/// may see this?" in the same edit. `AppRouter` reads only from here; a route
/// that is not in this enum cannot be registered.
enum AppRoute {
  /// Cold-start screen. Holds until the session is restored.
  splash('splash', '/', AccessRequirement.public),

  /// First-run introduction. Public: it explains what the app is *before*
  /// asking anyone to hand over identity information.
  onboarding('onboarding', '/onboarding', AccessRequirement.public),

  /// Sign-in. Public by definition.
  signIn('sign-in', '/sign-in', AccessRequirement.public),

  /// Resident dashboard.
  ///
  /// Public on purpose. A guest can browse LGU services, announcements and
  /// office information without an account: requiring registration to read
  /// public-service information would exclude residents who cannot or will not
  /// register, and would collect personal data with no purpose behind it.
  home('home', '/home', AccessRequirement.public),

  /// Account and preferences — needs an account, verified or not.
  account('account', '/account', AccessRequirement.authenticated),

  /// Identity verification: status, next step, and the submission flow.
  /// Authenticated but explicitly *not* verified — this is how a resident
  /// becomes verified.
  verification('verification', '/verification', AccessRequirement.authenticated),

  /// The resident's LGU digital ID. Verified residents only: a credential is a
  /// statement by the LGU about a person whose identity it has confirmed.
  digitalId('digital-id', '/digital-id', AccessRequirement.verified);

  const AppRoute(this.routeName, this.path, this.requirement);

  /// Name used for `goNamed` navigation. Stable; screens never hard-code paths.
  final String routeName;

  /// URL path, also the deep-link target.
  final String path;

  /// Who may see it. See `AccessPolicy` — this gates navigation, not authority.
  final AccessRequirement requirement;

  /// Query parameter carrying the destination a resident was pushed off, so
  /// sign-in can return them to it.
  static const String redirectQueryParam = 'from';

  static AppRoute? forPath(String path) {
    for (final route in AppRoute.values) {
      if (route.path == path) return route;
    }
    return null;
  }
}
