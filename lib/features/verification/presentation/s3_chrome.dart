import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_icon.dart';

/// In-app header shared by the verification and profile screens.
///
/// Height is 104 logical px, which is the design's header band at 390×844 @3×.
/// The line bar starts below it.
class S3Header extends StatelessWidget {
  const S3Header({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBell = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool showBell;

  static const double height = 104;

  @override
  Widget build(BuildContext context) {
    const gradient = BrandGradients.inAppHeader;
    // 104 at the default scale, which is the design band. A larger text
    // scale grows the band so the two lines still fit; the body scrolls.
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    final double band = math.max(height, 52 + 36 * scale);
    return SizedBox(
      height: band,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: gradient.begin,
            end: gradient.end,
            colors: gradient.colors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 44, 8, 8),
          child: Row(
            children: <Widget>[
              TaytayBackButton(onPressed: onBack, light: true),
              const SizedBox(width: 8),
              const FramedSeal(diameter: 36, shadowBlur: 8, shadowOffsetY: 2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headerTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headerSubtitle.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (showBell)
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: TaytayIcon(
                      icon: TaytayIcons.bell,
                      semanticLabel: 'Notifications',
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amber, green, or red status chip from the designs.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    super.key,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color fill) = switch (tone) {
      StatusTone.pending => (BrandColors.warning, const Color(0xFFFFF4D6)),
      StatusTone.verified => (BrandColors.success, const Color(0xFFE5F6EE)),
      StatusTone.correction => (BrandColors.danger, const Color(0xFFFDECEC)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TaytayIcon(
              icon: tone == StatusTone.verified
                  ? TaytayIcons.badgeCheck
                  : TaytayIcons.clock,
              semanticLabel: '',
              excludeSemantics: true,
              size: 14,
              color: ink,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.headerSubtitle.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusTone {
  pending,
  verified,
  correction,
}

/// One row in a progress list.
///
/// A dark icon shares the title's run. The detail sits below that icon so it
/// is its own run. A light icon stays above the line-bar threshold, which is
/// how the later steps on `03-01` and `03-09` keep a run that starts on the
/// title rather than on the glyph.
class ProgressRow extends StatelessWidget {
  const ProgressRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.iconDark = true,
    this.showDetail = true,
    this.bottom = 8,
    this.titleNudge = 4,
    this.rowShift = 0,
    this.titleShift = 0,
    this.detailShift = 0,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// When false the glyph is tinted so it does not open a dark run.
  final bool iconDark;
  final bool showDetail;
  final double bottom;

  /// Extra logical px before a light title, so its run starts on the design line.
  final double titleNudge;

  /// Visual shift of the icon and title. Does not move the detail or the next row.
  final double rowShift;

  /// Visual shift of the title ink only.
  final double titleShift;

  /// Visual shift of the detail ink only.
  final double detailShift;

  @override
  Widget build(BuildContext context) {
    final Color ink = iconDark
        ? BrandColors.success
        : BrandColors.textMuted.withValues(alpha: 0.55);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Transform.translate(
            offset: Offset(0, rowShift),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TaytayIcon(
                  icon: icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 22,
                  color: ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    // A light glyph does not open a run, so the title ink has to
                    // sit where the design's title run starts.
                    padding: EdgeInsets.only(top: iconDark ? 0 : titleNudge),
                    child: Transform.translate(
                      offset: Offset(0, titleShift),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: BrandColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDetail)
            Transform.translate(
              offset: Offset(0, detailShift),
              child: Padding(
                padding: const EdgeInsets.only(left: 34, top: 3),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    color: BrandColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
