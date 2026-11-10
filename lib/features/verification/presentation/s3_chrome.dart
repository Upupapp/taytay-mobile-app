import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/taytay_icon.dart';

// The card, timeline and type scale moved to `shared/widgets/s3_surface.dart`
// so document requests can draw progress the same way. Re-exported here so the
// verification screens keep one import.
export '../../../shared/widgets/s3_surface.dart';

/// In-app header for the verification and profile screens: the redesign's
/// [BlueHeader] with the translucent back control, the title and the
/// "Bayan ng Taytay · Rizal" line. These screens have no bell.
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

  @override
  Widget build(BuildContext context) {
    return BlueHeader(
      title: title,
      subtitle: subtitle,
      showBack: true,
      onBack: onBack,
    );
  }
}

/// A status on a soft pill (CSS `.pill`), with its icon when [icon] is set.
/// The words are the status; the colour and the icon only repeat it.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon = true,
    super.key,
  });

  final String label;
  final StatusTone tone;

  /// The status icon before the words. The profile sections draw none.
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final (Color ink, Color fill) = switch (tone) {
      StatusTone.pending => (BrandColors.goldInk, BrandColors.gold50),
      StatusTone.verified => (BrandColors.green, BrandColors.green50),
      StatusTone.correction => (BrandColors.redInk, BrandColors.red50),
      StatusTone.neutral => (BrandColors.text, BrandColors.chipFill),
    };
    final IconData mark = switch (tone) {
      StatusTone.verified => TaytayIcons.badgeCheck,
      StatusTone.correction => TaytayIcons.circleAlert,
      StatusTone.neutral => TaytayIcons.circleCheck,
      StatusTone.pending => TaytayIcons.clock,
    };
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xxs,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon) ...<Widget>[
              TaytayIcon(
                icon: mark,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm - Spacing.xs,
                color: ink,
              ),
              const SizedBox(width: Spacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTypography.small.copyWith(
                  fontWeight: AppTypography.strong,
                  color: ink,
                ),
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

/// The field label (CSS `.soft .lbl`): 12.5 / 600 above the field, with the
/// red required mark.
class S3Label extends StatelessWidget {
  const S3Label(this.text, {this.asterisk = false, super.key});

  final String text;
  final bool asterisk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text.rich(
        TextSpan(
          text: text,
          style: AppTypography.label.copyWith(color: BrandColors.text),
          children: <InlineSpan>[
            if (asterisk)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: BrandColors.redInk),
              ),
          ],
        ),
      ),
    );
  }
}

/// A read-out field (CSS `.soft .field`): 54 tall, filled `#F2F4F8`, 14
/// radius, no border. [dashed] is the RegID `.add` slot (white, 2 px dashed
/// outline, blue words); [readOnly] is a value the resident cannot change
/// here; [chevron] marks a picker.
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
    final Widget? leading = this.leading;
    final Widget? trailing = this.trailing;
    final Color ink = dashed
        ? BrandColors.blue
        : readOnly
        ? BrandColors.muted
        : BrandColors.ink;
    final Widget label = Text(
      value,
      style: AppTypography.fieldValue.copyWith(
        color: ink,
        fontWeight: dashed ? AppTypography.strong : null,
      ),
    );
    final Widget row = Row(
      mainAxisAlignment: dashed
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading,
          const SizedBox(width: Spacing.sm),
        ],
        if (dashed) Flexible(child: label) else Expanded(child: label),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: Spacing.sm),
          trailing,
        ],
        if (chevron)
          const TaytayIcon(
            icon: TaytayIcons.chevronDown,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.muted,
          ),
      ],
    );
    return CustomPaint(
      foregroundPainter: dashed ? const _DashBorder() : null,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: ComponentSizes.fieldHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: dashed
              ? BrandColors.white
              : readOnly
              ? BrandColors.background
              : BrandColors.softFill,
          borderRadius: BorderRadius.circular(Radii.field),
        ),
        child: row,
      ),
    );
  }
}

/// `.add { border: 2px dashed var(--line2) }`.
class _DashBorder extends CustomPainter {
  const _DashBorder();

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2;
    final Paint paint = Paint()
      ..color = BrandColors.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(stroke / 2),
          const Radius.circular(Radii.field),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Label above a 54 px field (RegDetails `.soft .f`). [top] is the gap above
/// the label.
class S3Field extends StatelessWidget {
  const S3Field({
    required this.label,
    required this.value,
    this.top = Spacing.section,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              child: InkWell(
                onTap: tap,
                borderRadius: BorderRadius.circular(Radii.field),
                child: column,
              ),
            ),
    );
  }
}
