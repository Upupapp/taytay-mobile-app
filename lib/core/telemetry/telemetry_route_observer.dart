import 'package:flutter/widgets.dart';

import '../router/app_routes.dart';
import 'telemetry.dart';

/// Records which screens residents open, by route rather than by path.
///
/// ---
///
/// ## The one thing this class exists to get right
///
/// The obvious implementation sends `route.settings.name`, which for this app is
/// a location like `/events/e-1` or `/requests/req-8823`. **That is an
/// identifier.** It names a specific event, a specific application, a specific
/// announcement — and joined to a handful of other events it describes one
/// resident's week at the municipal hall.
///
/// So the path is resolved to an `AppRoute` **enum value** and the enum's name
/// is what travels. `AppRoute.eventDetail` says a resident opened an event,
/// which is the operational fact anyone wanted, and says nothing about which.
///
/// A path that resolves to no known route sends **nothing at all** rather than
/// falling back to the raw string. An unresolvable path is exactly the case
/// where the raw string is most likely to be something unexpected.
///
/// ## It is inert unless telemetry is on
///
/// [Telemetry.record] returns without sending unless the resident consented, the
/// build permits it and a sink exists. In the shipped build all three are false,
/// so this observer walks the same code and sends nothing — which is the state
/// every test runs in.
class TelemetryRouteObserver extends NavigatorObserver {
  TelemetryRouteObserver(this.telemetry);

  final Telemetry telemetry;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    _record(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    // The screen underneath is the one a resident is now looking at.
    _record(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) {
    _record(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _record(Route<Object?>? route) {
    final resolved = resolve(route?.settings.name);
    if (resolved == null) return;
    telemetry.record(ScreenViewed(resolved));
  }

  /// The route a location belongs to, or `null`.
  ///
  /// Separated out and visible so the rule above is testable without a
  /// navigator: a path in, an enum or nothing out, never a string.
  @visibleForTesting
  static AppRoute? resolve(String? location) {
    if (location == null || location.isEmpty) return null;
    final path = Uri.tryParse(location)?.path ?? location;
    return AppRoute.forPath(path);
  }
}
