import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The sign-in page field from `02-01`.
///
/// The navy ramp and the two glows fill the 844-tall frame. A vertical fade
/// then covers them: transparent through y = 322, solid [BrandColors.surface]
/// at y = 382. The white form sheet starts at 332, on that light ground.
class SignInBackdrop extends StatelessWidget {
  const SignInBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: SignInPagePainter(),
      child: SizedBox.expand(),
    );
  }
}

class SignInPagePainter extends CustomPainter {
  const SignInPagePainter();

  static const double pageHeight = 844;

  /// CSS `linear-gradient(180deg, transparent 322px, #F3F5FA 382px)`.
  static const double fadeHold = 322;
  static const double fadeSolid = 382;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final page = Rect.fromLTWH(0, 0, size.width, pageHeight);
    canvas.drawRect(
      page,
      Paint()
        ..shader = _cssLinear(
          page,
          100,
          const <Color>[
            Color(0xFF041A44),
            BrandColors.taytayBlueDark,
            BrandColors.taytayBlue,
          ],
          const <double>[0, 0.4, 1],
        ),
    );
    _glow(
      canvas,
      page,
      cx: 0.80,
      cy: 0.20,
      rx: 220,
      ry: 200,
      color: BrandColors.sealGold.withValues(alpha: 0.42),
    );
    _glow(
      canvas,
      page,
      cx: 0.20,
      cy: 0.36,
      rx: 260,
      ry: 240,
      color: const Color(0xFF2E70E0).withValues(alpha: 0.75),
    );
    const fade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0x00F3F5FA),
        Color(0x00F3F5FA),
        BrandColors.surface,
        BrandColors.surface,
      ],
      stops: <double>[0, fadeHold / pageHeight, fadeSolid / pageHeight, 1],
    );
    canvas.drawRect(page, Paint()..shader = fade.createShader(page));
    if (size.height > pageHeight) {
      canvas.drawRect(
        Rect.fromLTWH(0, pageHeight, size.width, size.height - pageHeight),
        Paint()..color = BrandColors.surface,
      );
    }
    canvas.restore();
  }

  /// CSS linear-gradient endpoints. A rotated edge-to-edge line is shorter
  /// than the CSS corner-to-corner line, so an angled ramp reaches its last
  /// stop too soon.
  ui.Shader _cssLinear(
    Rect page,
    double angleDegrees,
    List<Color> colors,
    List<double> stops,
  ) {
    final angle = angleDegrees * math.pi / 180;
    final dx = math.sin(angle);
    final dy = -math.cos(angle);
    final half = (page.width * dx.abs() + page.height * dy.abs()) / 2;
    final center = page.center;
    return ui.Gradient.linear(
      Offset(center.dx - dx * half, center.dy - dy * half),
      Offset(center.dx + dx * half, center.dy + dy * half),
      colors,
      stops,
    );
  }

  void _glow(
    Canvas canvas,
    Rect page, {
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required Color color,
  }) {
    final center = Offset(page.width * cx, page.height * cy);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(rx, ry);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: 1);
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 0.5,
        colors: <Color>[color, color.withValues(alpha: 0)],
        stops: const <double>[0, 0.7],
      ).createShader(bounds);
    canvas.drawRect(bounds.inflate(0.2), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SignInPagePainter oldDelegate) => false;
}
