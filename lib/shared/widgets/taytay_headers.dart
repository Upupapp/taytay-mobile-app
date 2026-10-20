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
                    style: AppTypography.headerTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.headerSubtitle.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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

/// Welcome and sign-in header: the official seal and the municipal wordmark
/// on the deep gradient, with the gold glow.
///
/// The seal is the registered municipal PNG, drawn by [BrandMark]. That widget
/// downscales the file with [BoxFit.contain]. It does not recolour, mask, or
/// redraw it.
class WovenHeader extends StatelessWidget {
  const WovenHeader({
    this.showBack = false,
    this.onBack,
    this.backEnabled = true,
    this.welcome = false,
    this.trailing,
    super.key,
  });

  final bool showBack;
  final VoidCallback? onBack;

  /// Passed through to [TaytayBackButton]. False while a step is busy.
  final bool backEnabled;

  /// Welcome uses the larger seal and the 15 / 800 wordmark from gen1.py.
  /// Sign-in uses 14 / 800 from gen.py.
  final bool welcome;

  final Widget? trailing;

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
                if (showBack)
                  TaytayBackButton(
                    onPressed: onBack,
                    enabled: backEnabled,
                    light: true,
                  ),
                if (!showBack) const SizedBox(width: Spacing.md),
                BrandMark(size: welcome ? 52 : 46),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Bayan ng Taytay',
                        style:
                            (welcome
                                    ? AppTypography.brandTitleWelcome
                                    : AppTypography.brandTitle)
                                .copyWith(color: Colors.white),
                      ),
                      Text(
                        'Lalawigan ng Rizal',
                        style:
                            (welcome
                                    ? AppTypography.brandSubtitleWelcome
                                    : AppTypography.brandSubtitle)
                                .copyWith(color: BrandColors.sealGold),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
