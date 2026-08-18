import '../session/access_policy.dart';
import '../session/session_state.dart';
import '../startup/launch_controller.dart';
import 'app_routes.dart';

/// Decides where a navigation attempt should actually land.
///
/// Kept as a pure function, separate from the `GoRouter` wiring, so the rules
/// can be tested exhaustively without pumping widgets. Returns `null` when the
/// requested location is fine as-is.
///
/// This is *navigation*, not authorization — see `AccessPolicy`. Its job is to
/// make a deep link into a protected screen land somewhere useful instead of on
/// a screen that will immediately fail an API call.
/// [launch] decides only whether a first-time resident sees the welcome scenes
/// before the app. It is presentation state and confers nothing: every access
/// decision below still comes from [AccessPolicy].
String? resolveRedirect({
  required SessionState session,
  required String location,
  LaunchState launch = LaunchState.returning,
  bool mustUpgrade = false,
  bool isInMaintenance = false,
}) {
  final target = AppRoute.forPath(_pathOf(location));
  if (target == null) {
    // Unknown location: let the router's not-found page handle it rather than
    // silently rewriting an address a resident may have typed or been sent.
    return null;
  }

  // THE SERVER REFUSES THIS BUILD. Ahead of everything, including the session
  // and launch gates: there is no point restoring a session for a client the
  // server will not serve, and the screen has to be reachable by a resident who
  // cannot sign in at all. Defaults to false, so a bootstrap that has not
  // answered — or never answers — never locks anybody out.
  if (mustUpgrade) {
    return target == AppRoute.updateRequired
        ? null
        : AppRoute.updateRequired.path;
  }

  // Until the stored session has been read, the only honest answer is "wait".
  // Deciding early is what sends a signed-in resident to sign-in on every cold
  // start.
  if (!session.isResolved || launch == LaunchState.restoring) {
    return target == AppRoute.splash ? null : AppRoute.splash.path;
  }

  // Session known and we are still on the splash: move on. A first-time
  // resident meets the welcome scenes; everyone else goes straight to the app.
  //
  // Note what does *not* happen here: a returning resident is never sent back
  // through onboarding, and a first-time resident is never held there — the
  // welcome route stays public and escapable, so this is a starting point, not
  // a gate.
  if (target == AppRoute.splash) {
    return launch == LaunchState.firstLaunch
        ? AppRoute.onboarding.path
        : AppRoute.home.path;
  }

  // A signed-in resident has no business on the sign-in screen. Resume the
  // destination they were originally heading for, if it is now reachable.
  //
  // Only *known internal routes* are honoured. Sending a resident wherever a
  // `?from=` parameter points is an open redirect, and this app's links arrive
  // from SMS, email and QR codes — all attacker-writable.
  if (target == AppRoute.signIn && session.accessLevel.isAuthenticated) {
    final requested = Uri.tryParse(
      location,
    )?.queryParameters[AppRoute.redirectQueryParam];
    final resumed = requested == null
        ? null
        : AppRoute.forPath(_pathOf(requested));
    if (resumed != null &&
        resumed != AppRoute.signIn &&
        AccessPolicy.evaluate(
              session: session,
              requirement: resumed.requirement,
            )
            is AccessAllowed) {
      return resumed.path;
    }
    return AppRoute.home.path;
  }

  // THE OFFICE'S SYSTEM IS DOWN, and this deliberately blocks less than the
  // upgrade gate does.
  //
  // Maintenance stops anything that needs the server to answer for a particular
  // resident — a case, an ID, an inbox — because those cannot work and a screen
  // of "temporarily unavailable" tiles explains nothing. It does *not* stop
  // guest browsing, because cached services and programmes still read, and a
  // resident who opened the app to check what documents a clearance needs should
  // get that answer rather than a wall.
  //
  // Raised only by a live `503 SERVICE_UNAVAILABLE` and cleared by the next
  // request that succeeds, so it follows the server rather than a timer.
  if (isInMaintenance &&
      target.requirement != AccessRequirement.public &&
      target != AppRoute.maintenance) {
    return AppRoute.maintenance.path;
  }

  final decision = AccessPolicy.evaluate(
    session: session,
    requirement: target.requirement,
  );

  return switch (decision) {
    AccessAllowed() => null,
    AccessPending() => AppRoute.splash.path,
    AccessNeedsAuthentication() =>
      '${AppRoute.signIn.path}?${AppRoute.redirectQueryParam}=${Uri.encodeQueryComponent(location)}',
    // An unverified resident asking for a verified-only screen is not an error;
    // it is the moment to show them how to get verified.
    AccessNeedsVerification() => AppRoute.verification.path,
  };
}

/// Strips query and fragment from a location.
String _pathOf(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return location;
  return uri.path.isEmpty ? location : uri.path;
}
