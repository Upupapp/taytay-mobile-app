import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// One tone of [StatusChip]. The fill is a light tint; the label uses the
/// status colour, which clears 4.5:1 on that tint and on white.
///
/// The tone picks colours. The words on the chip are the `label` argument.
enum StatusTone {
  /// Warning amber.
  amber,

  /// Success green.
  green,

  /// Danger red.
  red,

  /// Information blue.
  blue,

  /// Neutral grey.
  grey,

  /// Seal gold, darkened for text.
  gold,
}

/// A short status label. Colour repeats the words; it is not the only signal.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      StatusTone.amber => (BrandColors.warning, BrandColors.chipAmberBg),
      StatusTone.green => (BrandColors.success, BrandColors.chipGreenBg),
      StatusTone.red => (BrandColors.danger, BrandColors.chipRedBg),
      StatusTone.blue => (BrandColors.taytayBlue, BrandColors.chipBlueBg),
      StatusTone.grey => (BrandColors.textSecondary, BrandColors.chipGreyBg),
      StatusTone.gold => (BrandColors.inkGold, BrandColors.chipGoldBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(label, style: AppTypography.labelStrong.copyWith(color: fg)),
    );
  }
}

/// Marks a fact the LGU has not confirmed. The word SAMPLE is the signal;
/// the gold is only a repeat of it.
class SampleTag extends StatelessWidget {
  const SampleTag({super.key, this.label = 'SAMPLE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    // CSS border-box: the 1 px dashed border takes space outside the 2 px pad.
    return CustomPaint(
      painter: const _DashedRRectPainter(
        color: BrandColors.sampleBorder,
        radius: 6,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
        decoration: BoxDecoration(
          color: BrandColors.chipAmberBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.labelStrong.copyWith(
            color: BrandColors.warning,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// Icon tile, title, subtitle, and a trailing control. Default trailing is a
/// chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    required this.icon,
    required this.iconLabel,
    this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String iconLabel;
  final Color? iconBackground;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = iconBackground ?? BrandColors.chipBlueBg;
    final fg = iconColor ?? BrandColors.taytayBlue;
    return Material(
      color: BrandColors.surfaceCard,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Padding(
            // gen2 `.li` is padding 12px 0 and gap 12. Horizontal inset belongs
            // to the card that holds the row.
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: TaytayIcon(
                    icon: icon,
                    semanticLabel: iconLabel,
                    color: fg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.cardTitle.copyWith(
                          color: BrandColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: AppTypography.listMeta.copyWith(
                              color: BrandColors.listMeta,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    const TaytayIcon(
                      icon: TaytayIcons.chevronRight,
                      semanticLabel: '',
                      excludeSemantics: true,
                      color: BrandColors.chevron,
                      size: 18,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Call, directions, and message. Message is a control the screen wires; this
/// widget does not decide who may use it.
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.onCall,
    required this.onDirections,
    this.onMessage,
    super.key,
  });

  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Action(
            label: 'Call',
            icon: TaytayIcons.phone,
            onPressed: onCall,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _Action(
            label: 'Directions',
            icon: TaytayIcons.mapPin,
            onPressed: onDirections,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _Action(
            label: 'Message',
            icon: TaytayIcons.messageCircle,
            onPressed: onMessage,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
        foregroundColor: BrandColors.taytayBlue,
        side: const BorderSide(color: BrandColors.taytayBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.taytayBlue,
          ),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.sbtn.copyWith(color: BrandColors.taytayBlue),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `.sample` uses a 1px dashed stroke. Flutter has no dashed [Border].
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 3.0;
    const gap = 2.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
