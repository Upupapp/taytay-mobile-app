import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 'shell_destinations.dart';

/// The approved phone tab bar: Home, Directory, Balita, Tulong, My Account.
///
/// The widget is 107 dp tall: a 90 dp bar and 17 dp of lift for the Balita
/// disc. The shell overlaps that lift on the page. The disc is a 60 dp box,
/// so the hit area is the disc itself. The lift is a [Positioned] child.
/// The home indicator is centred with [Center].
class ShellTabBar extends StatelessWidget {
  const ShellTabBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Painted bar, excluding the disc that sits above it.
  static const double barHeight = 90;

  /// How far the navy disc rises above the bar. The centre column packs to
  /// the bottom of its 52 dp box, so the 60 dp disc clears the bar by 17 dp.
  static const double lift = 17;

  static const double discSize = 60;

  static const Key discKey = Key('shell-centre-disc');

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return SizedBox(
      height: barHeight + lift,
      child: Stack(
        children: <Widget>[
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: _BarSurface(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Center(
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: BrandColors.textPrimary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final destination in ShellDestination.values)
                    Expanded(
                      child: _Tab(
                        destination: destination,
                        label: destination.labelIn(strings),
                        selected: destination.branchIndex == selectedIndex,
                        onTap: () => onSelected(destination.branchIndex),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _Disc(
                onTap: () => onSelected(ShellDestination.balita.index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarSurface extends StatelessWidget {
  const _BarSurface();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: const Border(top: BorderSide(color: BrandColors.cardLine)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BrandColors.taytayBlueDark.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Balita',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          key: ShellTabBar.discKey,
          width: ShellTabBar.discSize,
          height: ShellTabBar.discSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                BrandColors.taytayBlueLight,
                BrandColors.taytayBlue,
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x590B3D91),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
              BoxShadow(color: Color(0xE6FCD116), spreadRadius: 6),
              BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 4),
            ],
          ),
          child: const Center(
            child: TaytayIcon(
              icon: TaytayIcons.newspaper,
              semanticLabel: '',
              excludeSemantics: true,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? BrandColors.taytayBlue : _idle;
    final bool centre = destination == ShellDestination.balita;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: Key('shell-tab-${destination.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: centre
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(label, style: _labelStyle(color)),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TaytayIcon(
                      icon: destination.icon,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: 22,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _labelStyle(color),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

TextStyle _labelStyle(Color color) => TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: color,
  height: 1.1,
  decoration: TextDecoration.none,
);

/// Idle tab ink. CSS `.nv` is `#5F6880`.
const Color _idle = Color(0xFF5F6880);
