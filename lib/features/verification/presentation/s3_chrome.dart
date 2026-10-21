import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_icon.dart';

/// Horizontal inset that puts a card on the design's x = 51 device px.
const EdgeInsets s3PagePadding = EdgeInsets.fromLTRB(17, 15, 17, 16);

/// Gap between stacked cards. 14 logical px is 42 device px.
const double s3CardGap = 14;

/// In-app header for the verification and profile screens.
///
/// The band is 104 logical px. The back control is the design's translucent
/// disc: a 44 dp circle at 14% white, with a white chevron, inside a 48 dp
/// target. These screens have no bell.
class S3Header extends StatelessWidget {
  const S3Header({
    required this.title,
    required this.subtitle,
    this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  static const double height = 104;

  @override
  Widget build(BuildContext context) {
    const gradient = BrandGradients.inAppHeader;
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
          padding: const EdgeInsets.fromLTRB(6, 44, 16, 8),
          child: Row(
            children: <Widget>[
              TaytayBackButton(onPressed: onBack, translucent: true),
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
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headerSubtitle.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White card. Radius 16, the design's card shadow.
class S3Card extends StatelessWidget {
  const S3Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: TaytayShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Coloured disc or rounded tile behind an icon.
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.fill,
    required this.ink,
    this.size = 40,
    this.iconSize,
    this.radius,
    super.key,
  });

  final IconData icon;
  final Color fill;
  final Color ink;
  final double size;
  final double? iconSize;

  /// Null paints a circle. A value paints a rounded square.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final double? corner = radius;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: corner == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: corner == null ? null : BorderRadius.circular(corner),
      ),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: '',
        excludeSemantics: true,
        size: iconSize ?? size * 0.46,
        color: ink,
      ),
    );
  }
}

/// Amber, green, or red status chip from the designs.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color fill) = switch (tone) {
      StatusTone.pending => (BrandColors.warning, BrandColors.chipAmberBg),
      StatusTone.verified => (BrandColors.success, BrandColors.chipGreenBg),
      StatusTone.correction => (BrandColors.danger, BrandColors.chipRedBg),
      StatusTone.neutral => (BrandColors.textSecondary, BrandColors.chipGreyBg),
    };
    final IconData icon = switch (tone) {
      StatusTone.verified => TaytayIcons.badgeCheck,
      StatusTone.correction => TaytayIcons.triangleAlert,
      StatusTone.neutral => TaytayIcons.circleCheck,
      StatusTone.pending => TaytayIcons.clock,
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
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: 14,
              color: ink,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.headerSubtitle.copyWith(
                color: ink,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusTone {
  // Chip colour only. The words on the chip are the label string.
  pending,
  verified,
  correction,
  neutral,
}

enum TimelineTone {
  // Disc colour only. The step title is a separate string.
  done,
  current,
  upcoming,
}

/// One step in a filled timeline.
class TimelineStep {
  const TimelineStep({
    required this.icon,
    required this.title,
    required this.tone,
    this.detail = '',
  });

  final IconData icon;
  final String title;
  final String detail;
  final TimelineTone tone;
}

/// Filled discs, a connecting stroke, and the step's title and detail.
class Timeline extends StatelessWidget {
  const Timeline({required this.steps, super.key});

  final List<TimelineStep> steps;

  static const Color _amber = Color(0xFFE0A400);
  static const Color _future = Color(0xFFAEB6C8);

  static (Color fill, Color ink) _paint(TimelineTone tone) => switch (tone) {
    TimelineTone.done => (BrandColors.success, Colors.white),
    TimelineTone.current => (_amber, Colors.white),
    TimelineTone.upcoming => (_future, Colors.white),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], last: i == steps.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.last});

  final TimelineStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color ink) = Timeline._paint(step.tone);
    // Light rail. A dark stroke would join the discs into one run.
    const Color line = Color(0xFFE7EBF3);
    // Disc is 24 logical (the design's ~74 device px). The detail starts at
    // the disc's bottom, so the rail and the detail stay separate runs.
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTile(
                icon: step.icon,
                fill: fill,
                ink: ink,
                size: 24,
                iconSize: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          if (step.detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 2),
              child: Text(
                step.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  color: BrandColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          if (!last)
            const Padding(
              padding: EdgeInsets.only(left: 11),
              child: SizedBox(
                width: 2,
                height: 4,
                child: ColoredBox(color: line),
              ),
            ),
        ],
      ),
    );
  }
}

/// A green check-circle with a title and an optional detail.
class CheckLine extends StatelessWidget {
  const CheckLine({
    required this.title,
    this.detail = '',
    this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 24 dp disc beside the title. The detail sits under the disc so the
    // green fill does not join the two lines into one dark run. A tappable
    // row still offers a 48 dp target.
    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: onTap == null ? 44 : A11y.minTapTarget,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const IconTile(
                icon: TaytayIcons.check,
                fill: BrandColors.success,
                ink: Colors.white,
                size: 24,
                iconSize: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 2),
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
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
