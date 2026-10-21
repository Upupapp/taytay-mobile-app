import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A gradient plus the foreground colour it is guaranteed to support.
///
/// **Why a gradient needs its own type.** Contrast is checked between a
/// foreground and *a* background colour, but a gradient has no single background
/// colour — it has a range. Text placed on one reaches its worst contrast at
/// whichever stop is closest in luminance to the text, and that stop is often not
/// the one a designer looked at.
///
/// So a gradient here carries its intended [onColor], and
/// [worstCaseContrastRatio] reports the ratio at the *least favourable* stop.
/// `brand_test.dart` asserts that every gradient in [BrandGradients] clears
/// WCAG AA at that worst stop, which means a caller cannot place the declared
/// foreground on a gradient and be surprised.
///
/// Gradients are also **decorative**, never load-bearing: nothing is
/// distinguishable only by where it sits in a gradient.
@immutable
class BrandGradient {
  const BrandGradient({
    required this.name,
    required this.colors,
    required this.onColor,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.stops,
  });

  final String name;

  /// Stop colours, in order. At least two — asserted in `brand_test.dart`
  /// rather than in the constructor, because a `const` constructor cannot
  /// evaluate `List.length`.
  final List<Color> colors;

  /// The foreground colour this gradient is designed to carry.
  final Color onColor;

  final Alignment begin;
  final Alignment end;
  final List<double>? stops;

  /// The gradient as Flutter draws it.
  LinearGradient toLinearGradient() =>
      LinearGradient(colors: colors, begin: begin, end: end, stops: stops);

  /// Contrast of [onColor] against the least favourable stop.
  ///
  /// Interpolated midpoints are also sampled: a gradient between two dark blues
  /// stays dark throughout, but one running dark-blue → gold passes through
  /// mid-tones that neither endpoint reveals.
  double worstCaseContrastRatio() {
    var worst = double.infinity;
    for (var i = 0; i < colors.length - 1; i++) {
      const samples = 16;
      for (var step = 0; step <= samples; step++) {
        final sampled = Color.lerp(colors[i], colors[i + 1], step / samples)!;
        final ratio = contrastRatio(onColor, sampled);
        if (ratio < worst) worst = ratio;
      }
    }
    return worst;
  }

  @override
  String toString() => 'BrandGradient($name)';
}

/// The app's gradients.
///
/// Kept few. A gradient is atmosphere, and an app with many of them has replaced
/// its colour system with decoration — every additional one is another surface
/// whose contrast has to be re-proved.
abstract final class BrandGradients {
  /// In-app header. 135° from [BrandColors.taytayBlueDark] to
  /// [BrandColors.taytayBlue] — CSS 135deg is top-left toward bottom-right.
  ///
  /// White text clears AA across the whole range. [BrandColors.sealGold] does
  /// too, which is why eyebrows on this header may be gold. Gold on a *light*
  /// surface is a different question and is still forbidden.
  static const BrandGradient inAppHeader = BrandGradient(
    name: 'inAppHeader',
    colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
    onColor: Colors.white,
  );

  /// The primary brand surface: the splash mark backdrop and the home hero.
  ///
  /// Same ramp as [inAppHeader]. Kept under the original name so existing
  /// callers do not move.
  static const BrandGradient brand = inAppHeader;

  /// A deeper variant for large areas, where the mid blue would be heavy.
  static const BrandGradient brandDeep = BrandGradient(
    name: 'brandDeep',
    colors: <Color>[Color(0xFF03132F), BrandColors.taytayBlueDark],
    onColor: Colors.white,
  );

  /// Verified-credential surface. Distinctly *not* the brand gradient, so a
  /// credential does not look like every other card.
  static const BrandGradient verified = BrandGradient(
    name: 'verified',
    colors: <Color>[BrandColors.taytayBlue, Color(0xFF0A5C7A)],
    onColor: Colors.white,
  );

  /// Welcome and sign-in field. Same navy ramp as the header, deep enough that
  /// both white and [BrandColors.sealGold] clear 4.5:1 at every stop.
  ///
  /// The gold glow is **not** a stop on this gradient. A gold stop would pull
  /// the worst-case sample through a mid-tone and fail white text. The glow is
  /// painted separately by [WovenGoldGlow], at an opacity that leaves the
  /// underlying navy in charge of contrast.
  static const BrandGradient woven = BrandGradient(
    name: 'woven',
    colors: <Color>[
      Color(0xFF031433),
      BrandColors.taytayBlueDark,
      BrandColors.taytayBlue,
    ],
    // gen.py welcome/sign-in field: the mid navy sits at 55%, not halfway.
    stops: <double>[0, 0.55, 1],
    onColor: Colors.white,
  );

  /// Every gradient, for the contrast test.
  static const List<BrandGradient> all = <BrandGradient>[
    brand,
    inAppHeader,
    brandDeep,
    verified,
    woven,
  ];
}

/// The sign-in and welcome page field, as `wbg()` paints it.
///
/// The header is a short strip. This painter draws the full 844 px field and
/// shows the slice that sits behind the brand row (the row is at 44 px in the
/// mockup, under the status bar). A gold stop is not added to
/// [BrandGradients.woven]: the glows are the same radial layers as the CSS.
class WovenFieldPainter extends CustomPainter {
  const WovenFieldPainter.signIn() : welcome = false;

  const WovenFieldPainter.welcome() : welcome = true;

  final bool welcome;

  @override
  void paint(Canvas canvas, Size size) {
    const pageHeight = 844.0;
    // The brand row starts at CSS top 44. y = 0 of this strip is that line.
    const originY = 44.0;
    canvas.save();
    canvas.translate(0, -originY);
    final page = Rect.fromLTWH(0, 0, size.width, pageHeight);
    final angle = (welcome ? 115 : 100) * math.pi / 180;
    // CSS 90deg is left-to-right, which is Flutter's unrotated linear gradient.
    final linear = LinearGradient(
      colors: const <Color>[
        Color(0xFF041A44),
        BrandColors.taytayBlueDark,
        BrandColors.taytayBlue,
      ],
      stops: const <double>[0, 0.4, 1],
      transform: GradientRotation(angle - math.pi / 2),
    );
    canvas.drawRect(page, Paint()..shader = linear.createShader(page));
    if (welcome) {
      _glow(
        canvas: canvas,
        page: page,
        cx: 0.82,
        cy: 0.24,
        rx: 240,
        ry: 240,
        color: BrandColors.sealGold.withValues(alpha: 0.5),
      );
      _glow(
        canvas: canvas,
        page: page,
        cx: 0.10,
        cy: 0.52,
        rx: 300,
        ry: 260,
        color: const Color(0xFF1E5BC6).withValues(alpha: 0.85),
      );
    } else {
      _glow(
        canvas: canvas,
        page: page,
        cx: 0.80,
        cy: 0.20,
        rx: 220,
        ry: 200,
        color: BrandColors.sealGold.withValues(alpha: 0.42),
      );
      _glow(
        canvas: canvas,
        page: page,
        cx: 0.20,
        cy: 0.36,
        rx: 260,
        ry: 240,
        color: const Color(0xFF2E70E0).withValues(alpha: 0.75),
      );
    }
    canvas.restore();
  }

  void _glow({
    required Canvas canvas,
    required Rect page,
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
  bool shouldRepaint(covariant WovenFieldPainter oldDelegate) =>
      oldDelegate.welcome != welcome;
}

/// Decorative gold glow over a [BrandGradients.woven] field.
///
/// Opacity stays low on purpose: the glow is atmosphere, and the text behind
/// it is still contrasted against the navy ramp, not against a gold disc.
class WovenGoldGlow extends StatelessWidget {
  const WovenGoldGlow({
    required this.child,
    this.alignment = const Alignment(0.8, -0.6),
    this.radius = 0.9,
    super.key,
  });

  final Widget child;
  final Alignment alignment;
  final double radius;

  /// Gold mixed over a stop at the opacity this glow uses. Tests sample this
  /// so a future opacity change cannot quietly drop white text below AA.
  static Color blendOver(Color stop) =>
      Color.alphaBlend(BrandColors.sealGold.withValues(alpha: 0.22), stop);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: radius,
          colors: <Color>[
            BrandColors.sealGold.withValues(alpha: 0.22),
            BrandColors.sealGold.withValues(alpha: 0),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Paints a [BrandGradient] and supplies its [BrandGradient.onColor] to
/// descendants as the default text colour.
///
/// Using this instead of a bare `Container(decoration: …)` is what keeps the
/// pairing honest: the foreground that was contrast-checked against the gradient
/// is the foreground that actually gets used, rather than whatever the ambient
/// theme happened to supply.
class BrandGradientSurface extends StatelessWidget {
  const BrandGradientSurface({
    required this.gradient,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    super.key,
  });

  final BrandGradient gradient;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Deliberately does not vary with theme brightness: the gradient supplies
    // its own background in both themes, so its contrast-checked foreground is
    // correct in both.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient.toLinearGradient(),
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: gradient.onColor),
          child: IconTheme.merge(
            data: IconThemeData(color: gradient.onColor),
            child: child,
          ),
        ),
      ),
    );
  }
}
