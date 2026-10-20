import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/router/app_routes.dart';
import 'taytay_icon.dart';

/// Back control used on every non-root page.
///
/// The visible circle is [A11y.backButtonVisual] (44 dp). The hit target is
/// [A11y.minTapTarget] (48 dp), which is the floor in Article 6. The circle is
/// centred in that target so the mockup's 44 dp mark and the tap-size rule are
/// both true (decision D3).
///
/// Welcome and sign-in mockups draw this same solid white circle. In-app
/// mockups draw a 44 px disc at 14% white with a white chevron, which reads as
/// a bare chevron on the navy header. Those screens still use this circle.
class TaytayBackButton extends StatelessWidget {
  const TaytayBackButton({
    this.onPressed,
    this.light = false,
    this.enabled = true,
    super.key,
  });

  /// Overrides the default, which pops or returns home.
  final VoidCallback? onPressed;

  /// White circle and navy glyph, for use on a navy header.
  final bool light;

  /// False while a step is busy, so the control cannot be tapped twice.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = light
        ? BrandColors.surfaceCard
        : scheme.surfaceContainerLowest;
    final glyph = light ? BrandColors.taytayBlueDark : scheme.onSurface;

    // The ink well is the 48 dp target. A circle centred inside it is only
    // paint; putting the well on the circle made screen readers measure 44.
    return SizedBox(
      width: A11y.minTapTarget,
      height: A11y.minTapTarget,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  unawaited(AppHaptics.fire(HapticIntent.selection));
                  if (onPressed != null) {
                    onPressed!();
                    return;
                  }
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.goNamed(AppRoute.home.routeName);
                }
              : null,
          child: Center(
            child: SizedBox(
              width: A11y.backButtonVisual,
              height: A11y.backButtonVisual,
              child: Material(
                color: fill,
                shape: const CircleBorder(),
                elevation: 0,
                child: Center(
                  child: TaytayIcon(
                    icon: TaytayIcons.arrowLeft,
                    semanticLabel: 'Back',
                    size: IconSizes.sm,
                    color: glyph,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
