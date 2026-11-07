import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 's3_stroke.dart';

// The card, timeline and type scale moved to `shared/widgets/s3_surface.dart`
// so document requests can draw progress the same way. Re-exported here so the
// verification screens keep one import.
export '../../../shared/widgets/s3_surface.dart';

/// In-app header for the verification and profile screens.
///
/// The band is 104 logical px. The back control is the design's translucent
/// disc: a 44 dp circle at 14% white, with a white Lucide arrow-left, inside
/// a 48 dp target. These screens have no bell.
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

/// `.bdg` (with an icon) or `.chip` (text only) from the verification CSS.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon = true,
    super.key,
  });

  final String label;
  final StatusTone tone;

  /// `.bdg` carries a 12px icon. `.chip` on the profile sections does not.
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color fill) = switch (tone) {
      StatusTone.pending => (BrandColors.warning, BrandColors.chipAmberBg),
      StatusTone.verified => (BrandColors.success, BrandColors.chipGreenBg),
      StatusTone.correction => (BrandColors.danger, BrandColors.chipRedBg),
      StatusTone.neutral => (BrandColors.textSecondary, BrandColors.chipGreyBg),
    };
    final IconData mark = switch (tone) {
      StatusTone.verified => TaytayIcons.badgeCheck,
      StatusTone.correction => TaytayIcons.circleAlert,
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
            if (icon) ...<Widget>[
              TaytayIcon(
                icon: mark,
                semanticLabel: '',
                excludeSemantics: true,
                size: 12,
                color: ink,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: s3Type(
                11,
                AppTypography.black,
                ink,
                height: icon ? 1.2 : s3Line,
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

/// `.f` label. The red asterisk is the design's required mark.
class S3Label extends StatelessWidget {
  const S3Label(this.text, {this.asterisk = false, super.key});

  final String text;
  final bool asterisk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text.rich(
        TextSpan(
          text: text,
          style: s3Type(12, AppTypography.strong, BrandColors.fieldLabel),
          children: <InlineSpan>[
            if (asterisk)
              TextSpan(
                text: ' *',
                style: s3Type(12, AppTypography.strong, BrandColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

const Color _inputLine = Color(0xFFD6DCE8);
const Color _inputRead = Color(0xFFF6F8FB);

/// `.in`: 44px field, optional chevron, chip, or dashed upload.
class S3Input extends StatelessWidget {
  const S3Input({
    required this.value,
    this.readOnly = false,
    this.dashed = false,
    this.chevron = false,
    this.leading,
    this.trailing,
    super.key,
  });

  final String value;
  final bool readOnly;
  final bool dashed;
  final bool chevron;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color ink = dashed
        ? BrandColors.taytayBlue
        : readOnly
        ? BrandColors.textSecondary
        : BrandColors.fieldInk;
    final FontWeight weight = dashed
        ? AppTypography.black
        : AppTypography.medium;
    final Widget label = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: s3Type(14, weight, ink),
    );
    final Widget row = Row(
      mainAxisAlignment: dashed
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, const SizedBox(width: 8)],
        if (dashed) label else Expanded(child: label),
        if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
        if (chevron) S3StrokeIcon.chevronDown,
      ],
    );
    return CustomPaint(
      foregroundPainter: dashed ? const _DashBorder() : null,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: readOnly ? _inputRead : BrandColors.surfaceCard,
          borderRadius: BorderRadius.circular(Radii.md),
          border: dashed ? null : Border.all(color: _inputLine, width: 1.3),
        ),
        // 2/3 below the row lifts the glyphs 1 device px at 3×. The cap of
        // a 14px field otherwise starts one pixel under the design.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2 / 3),
          child: row,
        ),
      ),
    );
  }
}

class _DashBorder extends CustomPainter {
  const _DashBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _inputLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Radii.md),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Label, 5px gap, then a 44px input. `.f` margin-top defaults to 12.
class S3Field extends StatelessWidget {
  const S3Field({
    required this.label,
    required this.value,
    this.top = 12,
    this.asterisk = false,
    this.readOnly = false,
    this.dashed = false,
    this.chevron = false,
    this.leading,
    this.trailing,
    this.below,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final double top;
  final bool asterisk;
  final bool readOnly;
  final bool dashed;
  final bool chevron;
  final Widget? leading;
  final Widget? trailing;
  final Widget? below;

  /// Makes the whole field a button. Null leaves the field as it is drawn.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        S3Label(label, asterisk: asterisk),
        S3Input(
          value: value,
          readOnly: readOnly,
          dashed: dashed,
          chevron: chevron,
          leading: leading,
          trailing: trailing,
        ),
        ?below,
      ],
    );
    final VoidCallback? tap = onTap;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: tap == null
          ? column
          : Semantics(
              button: true,
              label: label,
              child: InkWell(onTap: tap, child: column),
            ),
    );
  }
}
