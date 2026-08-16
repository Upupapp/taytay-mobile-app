import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';

/// The five primary destinations, fixed for every resident.
///
/// ---
///
/// **The same five, in the same order, at every access level — acceptance 3.**
/// Not four for a guest and six for a verified resident. Three reasons, in the
/// order they matter:
///
/// 1. **Learnability.** Municipal software is used rarely and under pressure —
///    a deadline, a queue, a form somebody needs today. Navigation that moves
///    between visits is navigation that has to be relearned every visit, and the
///    people worst served by that are the ones with the least practice.
/// 2. **It discloses nothing to keep it stable.** The catalogue is public and
///    the server authorises every request, so a visible tab is not a leak. What
///    a growing tab bar *does* leak is that this person's status changed —
///    visible to anyone glancing at their phone.
/// 3. **Verifiability.** Five destinations that never vary is a property a test
///    can assert once and hold forever. "The right subset for each of three
///    states" is nine assertions that drift.
///
/// What varies is the *content* of a destination, and only where the content
/// itself is gated — which is where the explanation belongs anyway.
enum ShellDestination {
  home(AppRoute.home, 'Home', Icons.home_outlined, Icons.home),
  services(
    AppRoute.services,
    'Services',
    Icons.grid_view_outlined,
    Icons.grid_view,
  ),
  news(AppRoute.news, 'News', Icons.article_outlined, Icons.article),
  events(AppRoute.events, 'Events', Icons.event_outlined, Icons.event),
  profile(AppRoute.profile, 'Profile', Icons.person_outline, Icons.person);

  const ShellDestination(this.route, this.label, this.icon, this.selectedIcon);

  final AppRoute route;

  /// The English label, and the fallback.
  ///
  /// Short enough to survive a 200% text scale in a five-item bar without
  /// wrapping into an unreadable stack. Prefer [labelIn] on any surface a
  /// resident reads — this is what remains for the places with no
  /// `BuildContext`: a test name, a route table, a log line.
  final String label;

  /// The label in the reader's language.
  ///
  /// Filipino runs longer than English here — "Mga Kaganapan" against "Events"
  /// — which is exactly why the bar is checked at both languages and at 200%
  /// text. A five-item bar that fits one and clips the other is a bar that was
  /// only ever looked at in one.
  String labelIn(AppStrings strings) => switch (this) {
    ShellDestination.home => strings.navHome,
    ShellDestination.services => strings.navServices,
    ShellDestination.news => strings.navNews,
    ShellDestination.events => strings.navEvents,
    ShellDestination.profile => strings.navProfile,
  };

  final IconData icon;

  /// Filled variant for the selected state. Material 3 uses the fill, not colour
  /// alone, to indicate selection — which is what makes it legible to someone
  /// who cannot distinguish the two colours (WCAG 2.2 §1.4.1).
  final IconData selectedIcon;

  /// The branch index this destination occupies in the shell.
  int get branchIndex => index;

  /// The destination a location belongs to, or `null` when it is outside the
  /// shell entirely (sign-in, splash, the digital ID).
  static ShellDestination? forLocation(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    ShellDestination? best;
    for (final destination in values) {
      final root = destination.route.path;
      if (path == root || path.startsWith('$root/')) {
        // Longest prefix wins, so `/news/abc` resolves to News rather than to
        // whichever destination happened to be checked first.
        if (best == null || root.length > best.route.path.length) {
          best = destination;
        }
      }
    }
    return best;
  }
}
