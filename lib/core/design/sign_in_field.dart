import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Navy ramp, two glows, and the fade to [BrandColors.surface] for one `02` screen.
///
/// Defaults are `02-01`: transparent through y = 322, solid surface at y = 382.
class SignInAtmosphere {
  const SignInAtmosphere({
    this.fadeHold = 322,
    this.fadeSolid = 382,
    this.angle = 100,
    this.goldX = 0.80,
    this.goldY = 0.20,
    this.blueX = 0.20,
    this.blueY = 0.36,
  });

  final double fadeHold;
  final double fadeSolid;
  final double angle;
  final double goldX;
  final double goldY;
  final double blueX;
  final double blueY;

  static const SignInAtmosphere signIn = SignInAtmosphere();

  static const SignInAtmosphere reset = SignInAtmosphere(
    fadeHold: 290,
    fadeSolid: 350,
    angle: 108,
    goldX: 0.62,
    goldY: 0.26,
    blueX: 0.38,
    blueY: 0.42,
  );

  static const SignInAtmosphere personal = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 116,
    goldX: 0.45,
    goldY: 0.22,
    blueX: 0.55,
    blueY: 0.38,
  );

  static const SignInAtmosphere code = SignInAtmosphere(
    fadeHold: 290,
    fadeSolid: 350,
    angle: 124,
    goldX: 0.30,
    goldY: 0.28,
    blueX: 0.70,
    blueY: 0.44,
  );

  static const SignInAtmosphere terms = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 132,
    goldX: 0.20,
    goldY: 0.22,
    blueX: 0.80,
    blueY: 0.38,
  );

  static const SignInAtmosphere idCard = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 140,
    goldX: 0.36,
    goldY: 0.18,
    blueX: 0.64,
    blueY: 0.34,
  );

  static const SignInAtmosphere selfie = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 148,
    goldX: 0.55,
    goldY: 0.24,
    blueX: 0.45,
    blueY: 0.40,
  );

  static const SignInAtmosphere review = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 156,
    goldX: 0.72,
    goldY: 0.20,
    blueX: 0.28,
    blueY: 0.36,
  );

  static const SignInAtmosphere submitted = SignInAtmosphere(
    fadeHold: 250,
    fadeSolid: 320,
    angle: 164,
    goldX: 0.86,
    goldY: 0.26,
    blueX: 0.14,
    blueY: 0.42,
  );

  static const SignInAtmosphere errors = SignInAtmosphere(
    fadeHold: 170,
    fadeSolid: 240,
    angle: 172,
    goldX: 0.50,
    goldY: 0.30,
    blueX: 0.50,
    blueY: 0.46,
  );
}

/// The page field behind every `02` sheet.
class SignInBackdrop extends StatelessWidget {
  const SignInBackdrop({this.atmosphere = SignInAtmosphere.signIn, super.key});

  final SignInAtmosphere atmosphere;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SignInPagePainter(atmosphere),
      child: const SizedBox.expand(),
    );
  }
}

class SignInPagePainter extends CustomPainter {
  const SignInPagePainter(this.atmosphere);

  final SignInAtmosphere atmosphere;

  static const double pageHeight = 844;

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
          atmosphere.angle,
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
      cx: atmosphere.goldX,
      cy: atmosphere.goldY,
      rx: 220,
      ry: 200,
      color: BrandColors.sealGold.withValues(alpha: 0.42),
    );
    _glow(
      canvas,
      page,
      cx: atmosphere.blueX,
      cy: atmosphere.blueY,
      rx: 260,
      ry: 240,
      color: const Color(0xFF2E70E0).withValues(alpha: 0.75),
    );
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
        atmosphere.fadeHold / pageHeight,
        atmosphere.fadeSolid / pageHeight,
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
  bool shouldRepaint(covariant SignInPagePainter oldDelegate) {
    final previous = oldDelegate.atmosphere;
    return previous.fadeHold != atmosphere.fadeHold ||
        previous.fadeSolid != atmosphere.fadeSolid ||
        previous.angle != atmosphere.angle ||
        previous.goldX != atmosphere.goldX ||
        previous.goldY != atmosphere.goldY ||
        previous.blueX != atmosphere.blueX ||
        previous.blueY != atmosphere.blueY;
  }
}
