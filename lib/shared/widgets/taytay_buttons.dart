import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../core/haptics/app_haptics.dart';
import 'taytay_icon.dart';

/// Shared shape for the three resident buttons. Height is at least 48 dp.
class _TaytayButton extends StatelessWidget {
  const _TaytayButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.icon,
    this.expand = true,
    this.shadows,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final TaytayIcon? icon;
  final bool expand;

  /// Sign-in `.pri` shadow. Welcome uses a slightly larger one; this is the
  /// shared primary.
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Radii.pill);
    final child = Material(
      color: onPressed == null
          ? background.withValues(alpha: Opacities.disabled)
          : background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.6),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed == null
            ? null
            : () {
                unawaited(AppHaptics.fire(HapticIntent.confirm));
                onPressed!();
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: A11y.minTapTarget,
            minHeight: 50,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  icon!,
                  const SizedBox(width: Spacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.button.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final painted = shadows == null
        ? child
        : DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
            child: child,
          );
    return Semantics(button: true, label: label, child: painted);
  }
}

/// The one filled action on a light surface. Navy, white label.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      background: BrandColors.taytayBlue,
      foreground: Colors.white,
      icon: icon,
      expand: expand,
      shadows: const <BoxShadow>[
        BoxShadow(
          color: Color(0x470B3D91),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

/// An alternative action. Navy outline, navy label, light fill.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      background: BrandColors.surfaceCard,
      foreground: BrandColors.taytayBlue,
      borderColor: BrandColors.taytayBlue,
      icon: icon,
      expand: expand,
    );
  }
}

/// Accent action. Gold fill, navy label — the pair that clears AA.
class GoldButton extends StatelessWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      background: BrandColors.sealGold,
      foreground: BrandColors.taytayBlueDark,
      icon: icon,
      expand: expand,
    );
  }
}
