import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// One gold or blue glow on a welcome page.
///
/// CSS `radial-gradient(<rx> <ry> at <cx>% <cy>%, color, transparent 70%)`.
@immutable
class WelcomeGlow {
  const WelcomeGlow({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.color,
    required this.alpha,
  });

  /// Center, as a fraction of the 390×844 page.
  final double cx;
  final double cy;

  /// Ellipse radii in CSS pixels.
  final double rx;
  final double ry;

  final Color color;
  final double alpha;

  Color get paintColor => color.withValues(alpha: alpha);
}

/// The welcome page field from `w1.html`, `w2.html` and `w3.html`.
///
/// The linear ramp is the contrast surface. Glows are painted on top at an
/// opacity that leaves the navy in charge.
@immutable
class WelcomePageField {
  const WelcomePageField({
    required this.angleDegrees,
    required this.colors,
    required this.stops,
    required this.glows,
    required this.fadeHold,
    required this.fadeSolid,
  });

  /// CSS linear-gradient angle. 0 is up, 90 is to the right.
  final double angleDegrees;

  final List<Color> colors;
  final List<double> stops;
  final List<WelcomeGlow> glows;

  /// The fade to [BrandColors.surface] stays transparent until this y, then
  /// is solid at [fadeSolid]. Both are CSS pixels on the 844-tall page.
  final double fadeHold;
  final double fadeSolid;

  static const List<WelcomePageField> pages = <WelcomePageField>[
    WelcomePageField(
      angleDegrees: 115,
      colors: <Color>[
        Color(0xFF041A44),
        BrandColors.taytayBlueDark,
        BrandColors.taytayBlue,
      ],
      stops: <double>[0, 0.4, 1],
      glows: <WelcomeGlow>[
        WelcomeGlow(
          cx: 0.82,
          cy: 0.24,
          rx: 240,
          ry: 240,
          color: BrandColors.sealGold,
          alpha: 0.5,
        ),
        WelcomeGlow(
          cx: 0.10,
          cy: 0.52,
          rx: 300,
          ry: 260,
          color: BrandColors.taytayBlueLight,
          alpha: 0.85,
        ),
      ],
      fadeHold: 430,
      fadeSolid: 500,
    ),
    WelcomePageField(
      angleDegrees: 90,
      colors: <Color>[
        BrandColors.taytayBlue,
        Color(0xFF0A3580),
        Color(0xFF123F9E),
      ],
      stops: <double>[0, 0.5, 1],
      glows: <WelcomeGlow>[
        WelcomeGlow(
          cx: 0.52,
          cy: 0.22,
          rx: 260,
          ry: 230,
          color: BrandColors.sealGold,
          alpha: 0.48,
        ),
        WelcomeGlow(
          cx: 0.96,
          cy: 0.50,
          rx: 260,
          ry: 260,
          color: Color(0xFF2E70E0),
          alpha: 0.8,
        ),
      ],
      fadeHold: 430,
      fadeSolid: 500,
    ),
    WelcomePageField(
      angleDegrees: 65,
      colors: <Color>[
        Color(0xFF123F9E),
        BrandColors.taytayBlue,
        BrandColors.taytayBlueDark,
      ],
      stops: <double>[0, 0.45, 1],
      glows: <WelcomeGlow>[
        WelcomeGlow(
          cx: 0.22,
          cy: 0.30,
          rx: 260,
          ry: 240,
          color: BrandColors.sealGold,
          alpha: 0.46,
        ),
        WelcomeGlow(
          cx: 0.92,
          cy: 0.18,
          rx: 240,
          ry: 220,
          color: BrandColors.sealGold,
          alpha: 0.28,
        ),
      ],
      fadeHold: 370,
      fadeSolid: 440,
    ),
  ];
}
