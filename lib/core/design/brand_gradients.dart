import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// A CSS `linear-gradient(<angle>deg, …)` for Flutter.
///
/// CSS measures the angle clockwise from "to top" and stretches the gradient
/// line so the corners land on 0% and 100%: its length is
/// `|w·sin a| + |h·cos a|`. A plain [LinearGradient] between two alignments
/// gets neither right on a box that is not square, so the redesign's 150°
/// header would come out at a different angle on every screen width.
///
/// Use with `begin: Alignment.centerLeft, end: Alignment.centerRight`: the
/// transform stretches that horizontal line to the CSS length and turns it.
@immutable
class CssGradientAngle extends GradientTransform {
  const CssGradientAngle(this.degrees);

  final double degrees;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double radians = degrees * math.pi / 180;
    final double length =
        (bounds.width * math.sin(radians)).abs() +
        (bounds.height * math.cos(radians)).abs();
    final double stretch = bounds.width == 0 ? 1 : length / bounds.width;
    final Offset center = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(radians - math.pi / 2)
      ..scaleByDouble(stretch, 1, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }

  @override
  bool operator ==(Object other) =>
      other is CssGradientAngle && other.degrees == degrees;

  @override
  int get hashCode => degrees.hashCode;
}

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
/// `brand_test.dart` asserts that every gradient in [BrandGradients.all] clears
/// WCAG AA for text at that worst stop, and every icon tile in
/// [BrandGradients.tiles] clears 3:1 for its icon, which means a caller cannot
/// place the declared foreground on a gradient and be surprised.
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
    this.cssAngle,
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

  /// A CSS angle in degrees. When set, [begin] and [end] are ignored and the
  /// gradient is drawn as CSS draws `linear-gradient(<cssAngle>deg, …)`.
  final double? cssAngle;

  /// The gradient as Flutter draws it.
  LinearGradient toLinearGradient() {
    final double? angle = cssAngle;
    if (angle == null) {
      return LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
        stops: stops,
      );
    }
    return LinearGradient(
      colors: colors,
      stops: stops,
      transform: CssGradientAngle(angle),
    );
  }

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

/// The six icon-tile colours (CSS `.gt`, `.gt.green` …).
enum TileTone { blue, green, gold, red, navy, sky }

/// The app's gradients.
///
/// Kept few. A gradient is atmosphere, and an app with many of them has replaced
/// its colour system with decoration — every additional one is another surface
/// whose contrast has to be re-proved.
abstract final class BrandGradients {
  /// The blue header (CSS `header.bar`, `.whead`): 150°, navy 0% → blue 50%
  /// → sky 100%. White text clears AA at every stop (6.1:1 at sky).
  static const BrandGradient header = BrandGradient(
    name: 'header',
    colors: <Color>[BrandColors.navy, BrandColors.blue, BrandColors.sky],
    stops: <double>[0, 0.5, 1],
    cssAngle: 150,
    onColor: Colors.white,
  );

  /// The registration wave header (CSS `.whead`): the header ramp with blue
  /// at 45%.
  static const BrandGradient waveHeader = BrandGradient(
    name: 'waveHeader',
    colors: <Color>[BrandColors.navy, BrandColors.blue, BrandColors.sky],
    stops: <double>[0, 0.45, 1],
    cssAngle: 150,
    onColor: Colors.white,
  );

  /// Re-pointed to [header]: the old in-app header was a 135° navy ramp.
  static const BrandGradient inAppHeader = header;

  /// The primary brand surface: the splash mark backdrop and the home hero.
  /// Re-pointed with [inAppHeader].
  static const BrandGradient brand = header;

  /// A deeper variant for large areas, where the sky end would be heavy.
  static const BrandGradient brandDeep = BrandGradient(
    name: 'brandDeep',
    colors: <Color>[Color(0xFF03132F), BrandColors.navy],
    onColor: Colors.white,
  );

  /// Verified-credential surface. Distinctly *not* the brand gradient, so a
  /// credential does not look like every other card.
  static const BrandGradient verified = BrandGradient(
    name: 'verified',
    colors: <Color>[BrandColors.blue, Color(0xFF0A5C7A)],
    onColor: Colors.white,
  );

  /// Old welcome and sign-in field. Deep enough that both white and
  /// [BrandColors.gold] clear 4.5:1 at every stop. Phase 3 replaces those
  /// screens with the wave header.
  ///
  /// The gold glow is **not** a stop on this gradient. A gold stop would pull
  /// the worst-case sample through a mid-tone and fail white text. The glow is
  /// painted separately by [WovenGoldGlow], at an opacity that leaves the
  /// underlying navy in charge of contrast.
  static const BrandGradient woven = BrandGradient(
    name: 'woven',
    colors: <Color>[Color(0xFF031433), BrandColors.navy, BrandColors.blue],
    // gen.py welcome/sign-in field: the mid navy sits at 55%, not halfway.
    stops: <double>[0, 0.55, 1],
    onColor: Colors.white,
  );

  /// Every gradient that carries text, for the 4.5:1 contrast test.
  static const List<BrandGradient> all = <BrandGradient>[
    header,
    waveHeader,
    brand,
    inAppHeader,
    brandDeep,
    verified,
    woven,
  ];

  // Icon tiles, 135°. White icon, except navy on gold.

  static const BrandGradient tileBlue = BrandGradient(
    name: 'tileBlue',
    colors: <Color>[BrandColors.blue, BrandColors.sky],
    cssAngle: 135,
    onColor: Colors.white,
  );

  static const BrandGradient tileGreen = BrandGradient(
    name: 'tileGreen',
    colors: <Color>[BrandColors.green, Color(0xFF2EA05A)],
    cssAngle: 135,
    onColor: Colors.white,
  );

  static const BrandGradient tileGold = BrandGradient(
    name: 'tileGold',
    colors: <Color>[Color(0xFFE8C500), BrandColors.gold],
    cssAngle: 135,
    onColor: BrandColors.navy,
  );

  static const BrandGradient tileRed = BrandGradient(
    name: 'tileRed',
    colors: <Color>[Color(0xFFB00708), BrandColors.red],
    cssAngle: 135,
    onColor: Colors.white,
  );

  static const BrandGradient tileNavy = BrandGradient(
    name: 'tileNavy',
    colors: <Color>[BrandColors.navy, Color(0xFF22307E)],
    cssAngle: 135,
    onColor: Colors.white,
  );

  static const BrandGradient tileSky = BrandGradient(
    name: 'tileSky',
    colors: <Color>[BrandColors.sky, BrandColors.skyLight],
    cssAngle: 135,
    onColor: Colors.white,
  );

  /// The tile for [tone].
  static BrandGradient tile(TileTone tone) => switch (tone) {
    TileTone.blue => tileBlue,
    TileTone.green => tileGreen,
    TileTone.gold => tileGold,
    TileTone.red => tileRed,
    TileTone.navy => tileNavy,
    TileTone.sky => tileSky,
  };

  /// Every icon tile. Their foreground is an icon, a meaningful graphic, so
  /// the contrast test holds them to 3:1 (WCAG 1.4.11), not 4.5:1: the green
  /// and sky ends sit between the two.
  static const List<BrandGradient> tiles = <BrandGradient>[
    tileBlue,
    tileGreen,
    tileGold,
    tileRed,
    tileNavy,
    tileSky,
  ];
}

/// One decorative circle on the blue header (CSS `header.bar::before/::after`).
///
/// Offsets are from the header's edges, as CSS writes them: a negative
/// [right] pushes the circle past the right edge. Exactly one of [top] and
/// [bottom], and one of [left] and [right], is set.
@immutable
class HeaderCircle {
  const HeaderCircle({
    required this.diameter,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double diameter;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
}

/// The blue header's shapes and corners (design/README.md "Gradients").
abstract final class HeaderShapes {
  /// White circle, 220 px at 7%, top-right.
  static const HeaderCircle white = HeaderCircle(
    diameter: 220,
    color: Color(0x12FFFFFF),
    top: -80,
    right: -70,
  );

  /// Gold circle, 150 px at 16%, bottom-left.
  static const HeaderCircle gold = HeaderCircle(
    diameter: 150,
    color: Color(0x29F5DA18),
    bottom: -60,
    left: -40,
  );

  static const List<HeaderCircle> circles = <HeaderCircle>[white, gold];

  /// Bottom corners. There is no gold bottom line.
  static const BorderRadius radius = BorderRadius.vertical(
    bottom: Radius.circular(Radii.header),
  );

  /// How far a glass screen's body rides up over the header (CSS
  /// `.glass .body { margin-top: -32px }`).
  static const double glassOverlap = 32;
}

/// One layer of the registration wave (CSS `.whead .wave`, a 390 × 50 SVG
/// stretched to the header's width).
@immutable
class WaveLayer {
  const WaveLayer({
    required this.color,
    required this.points,
    this.viewBox = WaveHeaderShapes.viewBox,
  });

  final Color color;

  /// Start y, then two cubic segments as (c1x, c1y, c2x, c2y, x, y), in
  /// [viewBox]. The second segment's first control point is the SVG `S`
  /// reflection, written out.
  final List<double> points;

  /// The SVG view box the points are written in: 390 × 50 for the wave
  /// header, 390 × 64 for the welcome photo ([WelcomeShapes]).
  final Size viewBox;

  /// The layer's filled path, scaled to [size] (`preserveAspectRatio=none`).
  Path toPath(Size size) {
    final double sx = size.width / viewBox.width;
    final double sy = size.height / viewBox.height;
    final Path path = Path()..moveTo(0, points[0] * sy);
    for (var i = 1; i + 5 < points.length; i += 6) {
      path.cubicTo(
        points[i] * sx,
        points[i + 1] * sy,
        points[i + 2] * sx,
        points[i + 3] * sy,
        points[i + 4] * sx,
        points[i + 5] * sy,
      );
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }
}

/// The wave header's three layers: gold 85%, white 40%, white.
abstract final class WaveHeaderShapes {
  static const Size viewBox = Size(390, 50);

  /// The wave's drawn height at the bottom of the header (CSS `.wave`).
  static const double waveHeight = 50;

  /// `.whead` side padding.
  static const double sidePadding = 20;

  /// `.whead` padding: 12 + safe area, 20 at the sides, 58 at the bottom.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(
    sidePadding,
    12,
    sidePadding,
    58,
  );

  /// `.s1`: white 7%, 200 px, top-right.
  static const HeaderCircle bubble = HeaderCircle(
    diameter: 200,
    color: Color(0x12FFFFFF),
    top: -70,
    right: -60,
  );

  /// `.s3`: sky 55%, 110 px, bottom-left.
  static const HeaderCircle skyBubble = HeaderCircle(
    diameter: 110,
    color: Color(0x8C2D54E0),
    bottom: 30,
    left: -30,
  );

  /// `.s2`: a gold ring at 55%, 48 px with a 6 px stroke.
  static const Color ringColor = Color(0x8CF5DA18);
  static const double ringDiameter = 48;
  static const double ringStroke = 6;
  static const double ringTop = 104;
  static const double ringRight = -20;

  /// `.s4`: a 46 × 30 field of white dots at 45%, 1.6 px, every 10 px.
  static const Color dotColor = Color(0x73FFFFFF);
  static const double dotFieldWidth = 46;
  static const Size dotField = Size(dotFieldWidth, 30);
  static const double dotRadius = 1.6;
  static const double dotPitch = 10;
  static const double dotFieldRight = 4;
  static const double dotFieldBottom = 62;

  /// Space kept between centred header text and the dot field.
  static const double dotFieldGap = 4;

  /// How far a centred title block (success screens, notices) stays in from
  /// each side of the header's padding: far enough that its lines end before
  /// the dot field at the bottom right, and the same on the left so the block
  /// stays centred. A long subtitle ran over the dots without it (F1, D-199).
  static const double centeredTextInset =
      dotFieldRight + dotFieldWidth + dotFieldGap - sidePadding;

  /// `.s5`: a red dot, 10 px. Hidden below 380 px wide.
  static const double sparkDiameter = 10;
  static const double sparkTop = 156;
  static const double sparkRight = 44;
  static const double sparkMinWidth = 380;

  /// `.s6`: a gold plus, 14 px with 3 px bars, turned 15°.
  static const double plusSize = 14;
  static const double plusBar = 3;
  static const double plusTop = 18;
  static const double plusRight = 120;
  static const double plusTurnDegrees = 15;

  static const List<WaveLayer> layers = <WaveLayer>[
    WaveLayer(
      color: Color(0xD9F5DA18),
      points: <double>[16, 70, -2, 140, 34, 215, 18, 290, 2, 340, 2, 390, 14],
    ),
    WaveLayer(
      color: Color(0x66FFFFFF),
      points: <double>[25, 80, 8, 150, 40, 232, 25, 314, 10, 352, 12, 390, 22],
    ),
    WaveLayer(
      color: Colors.white,
      points: <double>[34, 92, 20, 162, 48, 252, 34, 342, 20, 362, 26, 390, 32],
    ),
  ];
}

/// Paints [WaveHeaderShapes.layers] across its whole size. Phase 2's
/// WaveHeader puts it, 50 px tall, along the bottom of the gradient.
class WavePainter extends CustomPainter {
  const WavePainter({this.layers = WaveHeaderShapes.layers});

  /// The wave to paint: the header's by default, [WelcomeShapes.layers] on
  /// the welcome photo.
  final List<WaveLayer> layers;

  @override
  void paint(Canvas canvas, Size size) {
    for (final WaveLayer layer in layers) {
      canvas.drawPath(layer.toPath(size), Paint()..color = layer.color);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.layers != layers;
}

/// The welcome scene (design `Main.dc.html`, CSS `.wel`): a photo zone over
/// the top of the page, darkened by [tint], with a 64 px three-layer wave
/// melting into the white panel below.
abstract final class WelcomeShapes {
  /// `.zone { height: 62%; min-height: 340px }`.
  static const double zoneFraction = 0.62;
  static const double zoneMinHeight = 340;

  /// `.zone .bg { object-position: center 35% }`.
  static const Alignment photoAlignment = Alignment(0, -0.3);

  /// `.zone .tint`: 180°, navy 82% → navy 25% at 28% → blue 10% at 55% →
  /// blue 55%. White text sits on the dark top band.
  static const LinearGradient tint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xD108124A),
      Color(0x4008124A),
      Color(0x1A0A2071),
      Color(0x8C0A2071),
    ],
    stops: <double>[0, 0.28, 0.55, 1],
  );

  /// `.zone .wave`: a 390 × 64 SVG stretched to the zone's width.
  static const Size viewBox = Size(390, 64);
  static const double waveHeight = 64;

  /// `.wtop` padding: 16 + safe area at the top, 20 at the sides.
  static const EdgeInsets topRowPadding = EdgeInsets.fromLTRB(20, 16, 20, 0);

  /// `.skip`: a 40 px pill of white at 14%, inside a 48 px target.
  static const double skipHeight = 40;
  static const Color skipFill = Color(0x24FFFFFF);

  /// `.fab`: the 64 px gold Next disc.
  static const double fab = 64;

  /// `.pager i`: 8 px dots, the current one 24 px wide.
  static const double pagerDot = 8;
  static const double pagerDotActive = 24;

  /// `.panel`: padding 4 / 28 / 24 + safe area, 14 between items, body
  /// text at most 320 wide.
  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(28, 4, 28, 24);
  static const double panelGap = 14;
  static const double bodyMaxWidth = 320;

  /// Gold 90%, white 45%, white.
  static const List<WaveLayer> layers = <WaveLayer>[
    WaveLayer(
      color: Color(0xE6F5DA18),
      viewBox: viewBox,
      points: <double>[22, 70, 0, 150, 46, 225, 24, 300, 2, 345, 4, 390, 18],
    ),
    WaveLayer(
      color: Color(0x73FFFFFF),
      viewBox: viewBox,
      points: <double>[32, 82, 12, 158, 54, 240, 32, 322, 10, 356, 16, 390, 28],
    ),
    WaveLayer(
      color: Colors.white,
      viewBox: viewBox,
      points: <double>[42, 95, 26, 170, 62, 262, 42, 354, 22, 366, 32, 390, 40],
    ),
  ];
}

/// One soft colour blob behind a glass screen (CSS `.app.glass` radial
/// gradients): an ellipse of [radii] centred at [center], fractions of the
/// page, fading from [color] to transparent at 70%.
@immutable
class GlassBlob {
  const GlassBlob({
    required this.center,
    required this.radii,
    required this.color,
  });

  final Offset center;
  final Size radii;
  final Color color;
}

/// Glass surfaces (Home, ID, Balita, Account): white 74% → 50% at 135°, a
/// 1 px border of white at 85%, and a backdrop blur of 18 with saturation
/// 160%. Phase 2's GlassCard composes [backdropFilter] in a `BackdropFilter`
/// clipped to the card's radius.
abstract final class GlassTokens {
  static const LinearGradient fill = LinearGradient(
    colors: <Color>[Color(0xBDFFFFFF), Color(0x80FFFFFF)],
    transform: CssGradientAngle(135),
  );

  /// The pinned (gold) glass card.
  static const LinearGradient pinnedFill = LinearGradient(
    colors: <Color>[Color(0xD9FEF7CF), Color(0x8CFEF7CF)],
    transform: CssGradientAngle(135),
  );

  static const Color border = Color(0xD9FFFFFF);
  static const double borderWidth = 1;

  /// The bottom navigation (BottomNav.dc `.bn .row`): white 78% → 92%
  /// top to bottom, under a 1 px top border of white at 90%.
  static const LinearGradient navFill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xC7FFFFFF), Color(0xEBFFFFFF)],
  );
  static const Color navBorder = Color(0xE6FFFFFF);

  /// CSS `blur(18px)`: CSS blur takes a standard deviation, as Flutter does.
  static const double blurSigma = 18;
  static const double saturation = 1.6;

  /// Blur then saturate, as CSS `backdrop-filter: blur() saturate()` applies.
  static ImageFilter backdropFilter() => ImageFilter.compose(
    outer: ColorFilter.matrix(saturationMatrix(saturation)),
    inner: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
  );

  /// The page behind glass cards.
  static const Color pageColor = BrandColors.glassBackground;

  static const List<GlassBlob> pageBlobs = <GlassBlob>[
    GlassBlob(
      center: Offset(1, 0.34),
      radii: Size(240, 220),
      color: Color(0x61F5DA18),
    ),
    GlassBlob(
      center: Offset(0, 0.58),
      radii: Size(260, 240),
      color: Color(0x4D2D54E0),
    ),
    GlassBlob(
      center: Offset(1, 0.92),
      radii: Size(260, 240),
      color: Color(0x1FE0090A),
    ),
  ];

  /// The CSS `saturate()` matrix (Filter Effects Level 1, feColorMatrix).
  static List<double> saturationMatrix(double s) => <double>[
    0.213 + 0.787 * s, 0.715 - 0.715 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 + 0.285 * s, 0.072 - 0.072 * s, 0, 0, //
    0.213 - 0.213 * s, 0.715 - 0.715 * s, 0.072 + 0.928 * s, 0, 0, //
    0, 0, 0, 1, 0,
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
