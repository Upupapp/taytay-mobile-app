import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../shared/widgets/intent_resumer.dart';
import 'shell_destinations.dart';

/// Material 3 window size classes, as this app uses them.
///
/// The breakpoints are the published Material 3 values (compact `< 600`, medium
/// `600–839`, expanded `≥ 840`), named here so the shell reads in terms of the
/// guidance rather than in magic numbers, and so a widget test can drive them
/// by name.
enum ShellLayout {
  /// Phones in portrait. Bottom navigation bar.
  compact,

  /// Small tablets, phones in landscape, split-screen. Collapsed rail.
  medium,

  /// Tablets and desktops. Extended rail with labels.
  expanded;

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  static ShellLayout forWidth(double width) {
    if (width >= expandedMinWidth) return ShellLayout.expanded;
    if (width >= mediumMinWidth) return ShellLayout.medium;
    return ShellLayout.compact;
  }

  bool get usesRail => this != ShellLayout.compact;
}

/// The app's root shell: five destinations, one information architecture, three
/// layouts.
///
/// ---
///
/// **The same routes at every width.** The rail and the bar are two renderings
/// of one navigation model — `/services` is `/services` on a phone and on a
/// tablet, a deep link lands in the same place, and a resident who is told
/// "open the Services tab" over the phone by an LGU clerk finds it either way.
/// A layout that changed the routes would be a second app.
///
/// **State per branch.** `StatefulShellRoute.indexedStack` gives each
/// destination its own navigator, so scrolling halfway down the announcements,
/// switching to Services and coming back returns to where the resident was. On a
/// weak connection that is the difference between a working app and one that
/// re-fetches everything on every tap.
///
/// **No admin surface — acceptance 1.** There are five destinations and this is
/// the only place a destination can be declared. There is no overflow menu, no
/// hidden tab, no long-press, and no branch that appears for a particular
/// account. A test asserts the count and the vocabulary.
class RootShell extends StatelessWidget {
  const RootShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(BuildContext context, int index) {
    final reduced = Motion.reduced(context);
    // `initialLocation: true` when re-tapping the current tab pops that branch
    // back to its root — the standard "tap the tab you are on to go home"
    // gesture, and the escape hatch from a screen a resident deep-linked into.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    AppHaptics.fire(HapticIntent.selection, suppressed: reduced);
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder rather than MediaQuery: the shell must respond to the space
    // it is actually given, which on a foldable or in split-screen is not the
    // size of the window.
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ShellLayout.forWidth(constraints.maxWidth);
        // One resumer for the whole shell, not one per branch: a held intent is
        // a single app-wide fact, and duplicating the resumer would replay it
        // once per branch that happened to be alive.
        return IntentResumer(
          child: layout.usesRail
              ? _RailScaffold(
                  layout: layout,
                  selectedIndex: navigationShell.currentIndex,
                  onSelected: (index) => _goToBranch(context, index),
                  child: navigationShell,
                )
              : _BarScaffold(
                  selectedIndex: navigationShell.currentIndex,
                  onSelected: (index) => _goToBranch(context, index),
                  child: navigationShell,
                ),
        );
      },
    );
  }
}

/// Compact: bottom navigation.
class _BarScaffold extends StatelessWidget {
  const _BarScaffold({
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        // Always show labels. Icon-only navigation is a memory test, and the
        // icons for "News" and "Events" are not distinguishable to someone who
        // uses the app twice a year.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: <NavigationDestination>[
          for (final destination in ShellDestination.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
              tooltip: destination.label,
            ),
        ],
      ),
    );
  }
}

/// Medium and expanded: a navigation rail beside the content.
class _RailScaffold extends StatelessWidget {
  const _RailScaffold({
    required this.layout,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
  });

  final ShellLayout layout;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = layout == ShellLayout.expanded;

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            extended: expanded,
            // Labels stay visible even when the rail is collapsed, for the same
            // reason the bottom bar always shows them.
            labelType: expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacing.lg,
                      horizontal: Spacing.md,
                    ),
                    child: Text(
                      'Taytay LGU IDS',
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : null,
            destinations: <NavigationRailDestination>[
              for (final destination in ShellDestination.values)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
