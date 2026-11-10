import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';

/// Marks a fact the LGU has not confirmed. The word SAMPLE is the signal;
/// the gold is only a repeat of it.
class SampleTag extends StatelessWidget {
  const SampleTag({
    super.key,
    this.label = 'SAMPLE',
    this.lineHeight,
    this.lineSlot,
  });

  final String label;

  /// CSS `.sample` sets no line-height, so the chip's text is the font's
  /// normal 1.26. Callers that sit in a measured line pass that. The default
  /// keeps [AppTypography.labelStrong]'s 1.2, which the directory rows were
  /// spaced with.
  final double? lineHeight;

  /// Label box, when it is not `11 * [lineHeight]`. Chrome's `normal` line
  /// for 11 px is 13.67, which is not `11 * 1.26`.
  final double? lineSlot;

  @override
  Widget build(BuildContext context) {
    // CSS border-box: padding is 2 × 7 inside a 1 px dashed border. The stroke
    // is painted after the fill and inset by half its width, so it sits in
    // that 1 px ring instead of under the fill.
    return CustomPaint(
      foregroundPainter: const _DashedRRectPainter(
        color: BrandColors.sampleBorder,
        radius: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.chipAmberBg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            child: _SampleLabel(
              label: label,
              lineHeight: lineHeight,
              lineSlot: lineSlot,
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleLabel extends StatelessWidget {
  const _SampleLabel({required this.label, this.lineHeight, this.lineSlot});

  final String label;
  final double? lineHeight;
  final double? lineSlot;

  @override
  Widget build(BuildContext context) {
    final double? height = lineHeight;
    final double? explicit = lineSlot;
    final double? slot = explicit ?? (height == null ? null : 11 * height);
    if (slot == null) {
      return Text(
        label,
        style: AppTypography.labelStrong.copyWith(
          color: BrandColors.warning,
          letterSpacing: 0.6,
          height: height,
        ),
      );
    }
    // 11 px is [AppTypography.labelStrong]. The slot keeps the caller's line
    // box; a forced strut would round 16.5 to 17 and the chip would be 23.
    return SizedBox(
      height: slot,
      child: Text(
        label,
        style: AppTypography.labelStrong.copyWith(
          color: BrandColors.warning,
          letterSpacing: 0.6,
          height: slot / 11,
          leadingDistribution: TextLeadingDistribution.even,
        ),
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
    // Inset by half the stroke so the 1 px dash is not clipped, and so it
    // sits on top of the fill rather than underneath it.
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.max(0, radius - 0.5)),
        ),
      );
    const dash = 3.0;
    const gap = 3.0;
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
