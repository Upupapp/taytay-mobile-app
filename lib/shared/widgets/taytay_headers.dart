import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'brand_mark.dart';
import 'taytay_back_button.dart';
import 'taytay_icon.dart';

/// Gradient header for pages inside the app: back, title, optional subtitle,
/// optional bell.
class InAppHeader extends StatelessWidget {
  const InAppHeader({
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.showBell = false,
    this.bellCount = 0,
    this.onBell,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showBell;
  final int bellCount;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return BrandGradientSurface(
      gradient: BrandGradients.inAppHeader,
      padding: EdgeInsets.fromLTRB(
        showBack ? Spacing.xs : Spacing.lg,
        Spacing.sm,
        Spacing.sm,
        Spacing.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (showBack) TaytayBackButton(onPressed: onBack, light: true),
            if (showBack) const SizedBox(width: Spacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.title.copyWith(color: Colors.white),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.bodyCompact.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showBell) _Bell(count: bellCount, onPressed: onBell),
          ],
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = count > 0 ? 'Notifications, $count unread' : 'Notifications';
    return SizedBox(
      width: A11y.minTapTarget,
      height: A11y.minTapTarget,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const TaytayIcon(
            icon: TaytayIcons.bell,
            semanticLabel: '',
            excludeSemantics: true,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Welcome and sign-in header: wordmark on the deep gradient, with the gold
/// glow. The municipal seal is not drawn here — no verified seal file has been
/// supplied, and [BrandMark] is the stand-in the brand rules allow.
class WovenHeader extends StatelessWidget {
  const WovenHeader({this.showBack = false, this.onBack, super.key});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BrandGradientSurface(
      gradient: BrandGradients.woven,
      child: WovenGoldGlow(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xs,
              Spacing.sm,
              Spacing.lg,
              Spacing.lg,
            ),
            child: Row(
              children: <Widget>[
                if (showBack) TaytayBackButton(onPressed: onBack, light: true),
                if (!showBack) const SizedBox(width: Spacing.md),
                const BrandMark(size: 40),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Bayan ng Taytay',
                        style: AppTypography.titleCompact.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Lalawigan ng Rizal',
                        style: AppTypography.label.copyWith(
                          color: BrandColors.sealGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
