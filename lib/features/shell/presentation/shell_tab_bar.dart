import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 'shell_destinations.dart';

/// The phone tab bar (BottomNav.dc `.bn`): Home, Directory, Balita, Tulong,
/// My Account.
///
/// The widget is 104 dp tall: an 80 dp glass row and 24 dp of lift for the
/// Balita disc. The shell overlaps that lift on the page. Each side tab is an
/// icon in a 56 × 30 pill (blue-100 when selected) over its 11 px label; the
/// centre is a 62 dp white ring holding the blue disc with its gold rim, its
/// label underneath. No shadows: the ring separates the disc from the page.
class ShellTabBar extends StatelessWidget {
  const ShellTabBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Painted bar, excluding the disc that sits above it.
  static const double barHeight = ComponentSizes.navigationBar;

  /// How far the disc rises above the bar.
  static const double lift = Spacing.xl;

  /// The white ring around the disc: the disc's hit area.
  static const double discSize = 62;

  static const Key discKey = Key('shell-centre-disc');

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return SizedBox(
      height: barHeight + lift,
      child: Stack(
        clipBehavior: Clip.none,
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
            bottom: 0,
            height: barHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xs + Spacing.xxs,
                Spacing.sm,
                Spacing.xs + Spacing.xxs,
                0,
              ),
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

/// The glass row: white 78% → 92%, a white hairline on top, and the page
/// behind blurred 18 and saturated 160%.
class _BarSurface extends StatelessWidget {
  const _BarSurface();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: GlassTokens.backdropFilter(),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: GlassTokens.navFill,
            border: Border(top: BorderSide(color: GlassTokens.navBorder)),
          ),
        ),
      ),
    );
  }
}

/// `.ctr .fab`: a 62 dp white ring, inside it the 54 dp blue disc with a
/// 3 px gold rim and the white Balita glyph.
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
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: BrandColors.white,
          ),
          child: Container(
            width: ShellTabBar.discSize - Spacing.sm,
            height: ShellTabBar.discSize - Spacing.sm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.blue,
              border: Border.all(color: BrandColors.gold, width: 3),
            ),
            child: const TaytayIcon(
              icon: TaytayIcons.newspaper,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.md,
              color: BrandColors.white,
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
    final bool centre = destination == ShellDestination.balita;
    final TextStyle style =
        (selected ? AppTypography.navLabelSelected : AppTypography.navLabel)
            .copyWith(color: selected ? BrandColors.blue : BrandColors.muted);
    final Widget text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: style,
    );
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
          // Tall enough for a 200% label under the pill; items sit at the
          // top of the row (CSS align-items: start).
          height: A11y.minTapTarget + Spacing.lg,
          child: centre
              ? Column(
                  children: <Widget>[
                    SizedBox(
                      height:
                          ComponentSizes.navigationIndicator.height +
                          Spacing.xxs,
                    ),
                    text,
                  ],
                )
              : Column(
                  children: <Widget>[
                    Container(
                      width: ComponentSizes.navigationIndicator.width,
                      height: ComponentSizes.navigationIndicator.height,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? BrandColors.blue100
                            : BrandColors.transparent,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: TaytayIcon(
                        icon: destination.icon,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.md - Spacing.xxs,
                        color: selected ? BrandColors.blue : BrandColors.muted,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    text,
                  ],
                ),
        ),
      ),
    );
  }
}
