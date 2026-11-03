import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 's3_stroke.dart';

/// `.bd` padding: 14px 16px.
const EdgeInsets s3PagePadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

/// `.card` margin-bottom.
const double s3CardGap = 12;

/// CSS `normal` for Plus Jakarta Sans. Typo ascender 1038 and descender 222.
const double s3Line = 1.26;

/// A unitless CSS line-height, split evenly above and below the glyphs.
TextStyle s3Type(
  double size,
  FontWeight weight,
  Color color, {
  double height = s3Line,
}) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    color: color,
    decoration: TextDecoration.none,
  );
}

/// Multi-line copy at a CSS line-height.
///
/// Flutter rounds a line box to a whole logical pixel, so `13 × 1.5` becomes
/// 20 instead of 19.5 and each extra line sits 1.5 device px low at 3×. The
/// lines keep that strut, and their tops are placed `fontSize × height` apart.
class S3Lines extends StatelessWidget {
  const S3Lines(
    this.text, {
    required this.size,
    required this.weight,
    required this.color,
    this.height = s3Line,
    this.align = TextAlign.start,
    super.key,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = s3Type(size, weight, color, height: height);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            final double maxWidth = constraints.maxWidth;
            final TextPainter painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textAlign: align,
              textScaler: scaler,
            )..layout(maxWidth: maxWidth.isFinite ? maxWidth : 100000);
            final List<String> lines = <String>[];
            var start = 0;
            while (start < text.length) {
              final TextRange range = painter.getLineBoundary(
                TextPosition(offset: start),
              );
              if (range.end <= start) break;
              lines.add(text.substring(range.start, range.end).trimRight());
              start = range.end;
            }
            painter.dispose();
            if (lines.length <= 1) {
              return Text(text, textAlign: align, style: style);
            }
            final double step = size * scaler.scale(1) * height;
            return SizedBox(
              width: maxWidth.isFinite ? maxWidth : null,
              height: step * lines.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: i * step,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        textAlign: align,
                        maxLines: 1,
                        softWrap: false,
                        style: style,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The timeline title sits in the body's 16px strut, not a 13px line box.
const StrutStyle s3BodyStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  height: s3Line,
  forceStrutHeight: true,
  leadingDistribution: TextLeadingDistribution.even,
);

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
    // The border insets the child, matching CSS border-box. A Material
    // shape border paints on the edge and does not.
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.cardLine),
        boxShadow: TaytayShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
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

enum TimelineTone {
  // Disc colour only. The step title is a separate string.
  done,
  current,
  upcoming,
  navy,
}

/// One step in a filled timeline.
class TimelineStep {
  const TimelineStep({
    required this.icon,
    required this.title,
    required this.tone,
    this.detail = '',
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final TimelineTone tone;
  final VoidCallback? onTap;
}

/// `.tl`: a 22px disc, a 13px title in the body strut, and a 12px detail.
class Timeline extends StatelessWidget {
  const Timeline({required this.steps, super.key});

  final List<TimelineStep> steps;

  static const Color _amber = Color(0xFFE0A400);
  static const Color _future = Color(0xFFAEB6C8);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final TimelineStep step in steps) _TimelineRow(step: step),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});

  final TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Widget mark) = switch (step.tone) {
      TimelineTone.done => (
        BrandColors.success,
        const TaytayIcon(
          icon: TaytayIcons.check,
          semanticLabel: '',
          excludeSemantics: true,
          size: 13,
          color: Colors.white,
        ),
      ),
      TimelineTone.navy => (
        BrandColors.taytayBlue,
        const TaytayIcon(
          icon: TaytayIcons.check,
          semanticLabel: '',
          excludeSemantics: true,
          size: 13,
          color: Colors.white,
        ),
      ),
      TimelineTone.current => (
        Timeline._amber,
        Text('•', style: s3Type(12, AppTypography.black, Colors.white)),
      ),
      TimelineTone.upcoming => (Timeline._future, const SizedBox.shrink()),
    };
    final Widget row = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: mark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 16×1.26. The strut rounds to 20; the slot keeps the CSS box.
                SizedBox(
                  height: 16 * s3Line,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: s3BodyStrut,
                      style: s3Type(
                        13,
                        AppTypography.strong,
                        BrandColors.fieldInk,
                      ),
                    ),
                  ),
                ),
                if (step.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SizedBox(
                      height: 12 * s3Line,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          step.detail,
                          style: s3Type(
                            12,
                            FontWeight.w400,
                            BrandColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    final VoidCallback? onTap = step.onTap;
    if (onTap == null) return row;
    // The disc row is shorter than 48. The target hangs off it.
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        row,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: A11y.minTapTarget,
          child: InkWell(onTap: onTap),
        ),
      ],
    );
  }
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
