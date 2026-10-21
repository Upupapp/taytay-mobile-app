import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/button_styles.dart';
import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import 'taytay_icon.dart';

export '../../core/design/button_styles.dart';

/// Shared paint for the resident buttons. Metrics come from
/// [TaytayButtonKind], so a sign-in pill and an in-app button stay distinct.
class _TaytayButton extends StatelessWidget {
  const _TaytayButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.kind,
    this.borderColor,
    this.icon,
    this.expand = true,
    this.shadows,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final TaytayButtonKind kind;
  final Color? borderColor;
  final TaytayIcon? icon;
  final bool expand;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final metrics = TaytayButtonMetrics.of(kind);
    final radius = BorderRadius.circular(metrics.radius);
    final child = Material(
      color: onPressed == null
          ? background.withValues(alpha: Opacities.disabled)
          : background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: metrics.borderWidth),
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
          constraints: BoxConstraints(
            minWidth: expand ? double.infinity : A11y.minTapTarget,
            minHeight: metrics.height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  icon!,
                  const SizedBox(width: Spacing.sm),
                ],
                if (expand)
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: metrics.label.copyWith(color: foreground),
                    ),
                  )
                else
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: metrics.label.copyWith(color: foreground),
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

/// The one filled action. Navy, white label.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.kind = TaytayButtonKind.inApp,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayButtonKind kind;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      kind: kind,
      background: BrandColors.taytayBlue,
      foreground: Colors.white,
      icon: icon,
      expand: expand,
      shadows: TaytayButtonMetrics.of(kind).primaryShadow,
    );
  }
}

/// An alternative action. Navy outline, navy label, light fill.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.kind = TaytayButtonKind.inApp,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayButtonKind kind;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      kind: kind,
      background: BrandColors.surfaceCard,
      foreground: BrandColors.taytayBlue,
      borderColor: BrandColors.taytayBlue,
      icon: icon,
      expand: expand,
    );
  }
}

/// Accent action. Gold fill, navy label. CSS `.gold` sits on the sign-in
/// pill, so the default kind is [TaytayButtonKind.signIn].
class GoldButton extends StatelessWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    this.kind = TaytayButtonKind.signIn,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TaytayButtonKind kind;
  final TaytayIcon? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _TaytayButton(
      label: label,
      onPressed: onPressed,
      kind: kind,
      background: BrandColors.sealGold,
      foreground: BrandColors.taytayBlueDark,
      icon: icon,
      expand: expand,
    );
  }
}
