import 'package:flutter/material.dart';

import '../../../core/design/taytay_icons.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';

/// The five primary destinations, fixed for every resident.
///
/// Home, Directory, Balita, Tulong, My Account. Events is not a tab. The same
/// five show for a guest, an unverified resident and a verified resident.
enum ShellDestination {
  home(AppRoute.home, 'Home', TaytayIcons.house),
  directory(AppRoute.services, 'Directory', TaytayIcons.building2),
  balita(AppRoute.news, 'Balita', TaytayIcons.newspaper),
  tulong(AppRoute.programs, 'Tulong', TaytayIcons.handHeart),
  account(AppRoute.profile, 'My Account', TaytayIcons.user);

  const ShellDestination(this.route, this.label, this.icon);

  final AppRoute route;

  /// English label, and the fallback where there is no [BuildContext].
  final String label;

  final IconData icon;

  String labelIn(AppStrings strings) => switch (this) {
    ShellDestination.home => strings.navHome,
    ShellDestination.directory => strings.navServices,
    ShellDestination.balita => strings.navNews,
    ShellDestination.tulong => strings.navTulong,
    ShellDestination.account => strings.navProfile,
  };

  int get branchIndex => index;

  /// The destination a location belongs to, or null when it is outside the
  /// shell. Events is outside the shell, so `/events` resolves to null.
  static ShellDestination? forLocation(String location) {
    final String path = Uri.tryParse(location)?.path ?? location;
    ShellDestination? best;
    for (final ShellDestination destination in values) {
      final String root = destination.route.path;
      if (path == root || path.startsWith('$root/')) {
        if (best == null || root.length > best.route.path.length) {
          best = destination;
        }
      }
    }
    if (best != null) return best;
    // Hotlines and notifications stay on the Home branch.
    if (path.startsWith('/offices/') && path.endsWith('/message/sent')) {
      return ShellDestination.directory;
    }
    if (path.startsWith('/offices/') && !path.contains('/message')) {
      return ShellDestination.directory;
    }
    if (path == AppRoute.hotlines.path ||
        path.startsWith('${AppRoute.hotlines.path}/') ||
        path == AppRoute.notifications.path ||
        path.startsWith('${AppRoute.notifications.path}/')) {
      return ShellDestination.home;
    }
    return null;
  }
}
