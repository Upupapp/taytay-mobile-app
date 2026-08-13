import '../session/access_policy.dart';
import '../session/session_state.dart';
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
String? resolveRedirect({
  required SessionState session,
  required String location,
}) {
  final target = AppRoute.forPath(_pathOf(location));
  if (target == null) {
    // Unknown location: let the router's not-found page handle it rather than
    // silently rewriting an address a resident may have typed or been sent.
    return null;
  }

  // Until the stored session has been read, the only honest answer is "wait".
  // Deciding early is what sends a signed-in resident to sign-in on every cold
  // start.
  if (!session.isResolved) {
    return target == AppRoute.splash ? null : AppRoute.splash.path;
  }

  // Session known and we are still on the splash: move on.
  if (target == AppRoute.splash) return AppRoute.home.path;

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
