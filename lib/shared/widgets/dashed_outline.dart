import 'package:flutter/widgets.dart';

import '../../core/design/design_tokens.dart';

/// A 2 px dashed rounded outline (CSS `border: 2px dashed`), painted inside
/// the box. Flutter has no dashed [Border].
///
/// Two shapes use it: RegID's empty file slot (`UploadSlot`) and the ID tab's
/// card that is not issued yet. Pass it as a [CustomPaint.painter] behind the
/// content; it draws nothing a screen reader reads.
class DashedOutline extends CustomPainter {
  const DashedOutline({required this.colour, this.radius = Radii.lg});

  final Color colour;
  final double radius;

  static const double _stroke = 2;
  static const double _dash = 6;
  static const double _period = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke;
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(_stroke / 2),
          Radius.circular(radius),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _period;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedOutline oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.radius != radius;
}
