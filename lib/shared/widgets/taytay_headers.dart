import 'package:flutter/material.dart';

import '../../core/design/brand_assets.dart';
import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
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
/// on the page field from the mockup.
///
/// The seal file is drawn unaltered inside the mockup's circle: a white pad,
/// then a gold ring on the container. The PNG is only downscaled.
class WovenHeader extends StatelessWidget {
  const WovenHeader({
    this.showBack = false,
    this.onBack,
    this.backEnabled = true,
    this.welcome = false,
    this.trailing,
    this.paintField = true,
    this.includeSafeArea = true,
    this.padding,
    super.key,
  });

  final bool showBack;
  final VoidCallback? onBack;

  /// Passed through to [TaytayBackButton]. False while a step is busy.
  final bool backEnabled;

  /// Welcome uses the 58 px seal and the 15 / 800 wordmark from gen1.py.
  /// Sign-in uses the 46 px seal and 14 / 800 from gen.py.
  final bool welcome;

  final Widget? trailing;

  /// Welcome pages paint their own field behind this row. Sign-in keeps the
  /// default, which paints the field inside the header.
  final bool paintField;

  /// Welcome pages position the row themselves. Sign-in keeps the safe area.
  final bool includeSafeArea;

  /// Replaces the default padding when the row is placed on a full-page canvas.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // The back control is 48 dp with a 44 dp circle. A 10 dp spacer after it
    // leaves the CSS gap of 12 between the circle's edge and the seal.
    final seal = welcome ? 58.0 : 46.0;
    final afterBack = showBack ? 10.0 : 0.0;
    final brandGap = welcome ? 11.0 : 10.0;
    // Chrome's boxes for `.brand`, at 1×. The row centres the text div on
    // the seal (`align-items: center`). Welcome: div y=55 h=40, `b` h=19,
    // `small` y=80. Sign-in: div y=47.5 h=39, `b` h=18, `small` y=71.5.
    // The 6 between `b`'s bottom and `small`'s top is that measured gap.
    final typeScale = MediaQuery.textScalerOf(context).scale(1);
    final titleSize = welcome ? 15.0 : 14.0;
    final titleBox = (welcome ? 19.0 : 18.0) * typeScale;
    // The text div is 21 dp taller than `b`. Six of that is the gap down to
    // `small`; the subtitle line fills the rest, and what remains sits under
    // it so the div stays the measured 40 (welcome) or 39 (sign-in).
    final belowTitle = 21.0 * typeScale;
    final row = Padding(
      padding: padding ?? EdgeInsets.fromLTRB(showBack ? 18 : 20, 4, 20, 16),
      child: Row(
        children: <Widget>[
          if (showBack)
            TaytayBackButton(
              onPressed: onBack,
              enabled: backEnabled,
              light: true,
            ),
          if (showBack) SizedBox(width: afterBack),
          FramedSeal(
            diameter: seal,
            shadowBlur: welcome ? 14 : 12,
            shadowOffsetY: welcome ? 4 : 3,
          ),
          SizedBox(width: brandGap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bayan ng Taytay',
                  style:
                      (welcome
                              ? AppTypography.brandTitleWelcome
                              : AppTypography.brandTitle)
                          .copyWith(
                            color: Colors.white,
                            height: titleBox / (titleSize * typeScale),
                          ),
                ),
                SizedBox(height: 6 * typeScale),
                Text(
                  'Lalawigan ng Rizal',
                  style:
                      (welcome
                              ? AppTypography.brandSubtitleWelcome
                              : AppTypography.brandSubtitle)
                          .copyWith(
                            color: BrandColors.sealGold,
                            height: TypeMetrics.line(11) / 11,
                          ),
                ),
                SizedBox(
                  height:
                      belowTitle -
                      6 * typeScale -
                      TypeMetrics.line(11) * typeScale,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    return Stack(
      children: <Widget>[
        if (paintField)
          Positioned.fill(
            child: CustomPaint(
              painter: welcome
                  ? const WovenFieldPainter.welcome()
                  : const WovenFieldPainter.signIn(),
            ),
          ),
        if (includeSafeArea) SafeArea(bottom: false, child: row) else row,
      ],
    );
  }
}

/// The mockup's circular frame around the official seal.
///
/// The artwork is [BrandAssets.municipalSeal], drawn with [BoxFit.contain] and
/// no colour filter. The circle, the 2 px white pad and the gold ring belong
/// to this container. They are not painted into the file.
class FramedSeal extends StatelessWidget {
  const FramedSeal({
    required this.diameter,
    this.shadowBlur = 12,
    this.shadowOffsetY = 3,
    super.key,
  });

  /// Outer diameter of the white circle, before the ring. Sign-in is 46.
  /// Welcome is 58.
  final double diameter;

  final double shadowBlur;
  final double shadowOffsetY;

  @override
  Widget build(BuildContext context) {
    const seal = BrandAssets.municipalSeal;
    return Semantics(
      label: seal.semanticLabel,
      image: true,
      child: Container(
        width: diameter,
        height: diameter,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          // CSS paints the first shadow on top. Flutter paints the last one
          // on top, so the gold ring is last: `0 0 0 2px rgba(252,209,22,.85)`.
          // On the welcome navy that ring reads about (214, 181, 29).
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0x4D000000),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffsetY),
            ),
            const BoxShadow(color: Color(0xD9FCD116), spreadRadius: 2),
          ],
        ),
        child: Image.asset(
          seal.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
