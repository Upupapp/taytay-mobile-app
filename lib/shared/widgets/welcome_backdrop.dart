import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/welcome_field.dart';

/// The welcome page field: a navy ramp, shifting glows, then a fade to the
/// light surface under the copy.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({required this.page, super.key});

  /// Zero-based welcome page.
  final int page;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackdropPainter(WelcomePageField.pages[page]),
      child: const SizedBox.expand(),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.field);

  final WelcomePageField field;

  static const double pageHeight = 844;

  @override
  void paint(Canvas canvas, Size size) {
    final page = Rect.fromLTWH(0, 0, size.width, pageHeight);
    canvas.drawRect(page, Paint()..shader = _cssLinear(page, field));
    for (final glow in field.glows) {
      _glow(canvas, page, glow);
    }
    final fade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const <Color>[
        Color(0x00F3F5FA),
        Color(0x00F3F5FA),
        BrandColors.surface,
        BrandColors.surface,
      ],
      stops: <double>[
        0,
        field.fadeHold / pageHeight,
        field.fadeSolid / pageHeight,
        1,
      ],
    );
    canvas.drawRect(page, Paint()..shader = fade.createShader(page));
    if (size.height > pageHeight) {
      canvas.drawRect(
        Rect.fromLTWH(0, pageHeight, size.width, size.height - pageHeight),
        Paint()..color = BrandColors.surface,
      );
    }
  }

  /// CSS linear-gradient endpoints. Flutter's rotated edge-to-edge line is
  /// shorter than the CSS corner-to-corner line, so an angled ramp reaches its
  /// last stop too soon.
  ui.Shader _cssLinear(Rect page, WelcomePageField field) {
    final angle = field.angleDegrees * math.pi / 180;
    final dx = math.sin(angle);
    final dy = -math.cos(angle);
    final half = (page.width * dx.abs() + page.height * dy.abs()) / 2;
    final center = page.center;
    return ui.Gradient.linear(
      Offset(center.dx - dx * half, center.dy - dy * half),
      Offset(center.dx + dx * half, center.dy + dy * half),
      field.colors,
      field.stops,
    );
  }

  void _glow(Canvas canvas, Rect page, WelcomeGlow glow) {
    final center = Offset(page.width * glow.cx, page.height * glow.cy);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(glow.rx, glow.ry);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: 1);
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 0.5,
        colors: <Color>[glow.paintColor, glow.paintColor.withValues(alpha: 0)],
        stops: const <double>[0, 0.7],
      ).createShader(bounds);
    canvas.drawRect(bounds.inflate(0.2), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.field != field;
}
