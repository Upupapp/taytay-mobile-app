import 'package:flutter/painting.dart';

import 'design_tokens.dart';
import 'typography.dart';

/// Which CSS button the control follows.
///
/// Sign-in, welcome and in-app buttons do not share a size or a radius.
/// One style for all three was a compromise the mockups do not make.
enum TaytayButtonKind {
  /// gen.py `.btn`: 16 / 800, pill, height 50. Primary shadow
  /// `0 8px 20px rgba(11,61,145,.28)`. Secondary inset 1.6 px.
  signIn,

  /// gen1.py `.fin`: 16 / 800, pill, height 52. Primary shadow
  /// `0 10px 22px rgba(11,61,145,.3)`. Secondary inset 1.6 px.
  welcome,

  /// The later `.btn`: 15 / 800, radius 12, height 48. Primary has no
  /// shadow. Secondary inset 1.5 px.
  inApp,
}

/// The numbers for one [TaytayButtonKind].
class TaytayButtonMetrics {
  const TaytayButtonMetrics({
    required this.height,
    required this.radius,
    required this.label,
    required this.borderWidth,
    this.primaryShadow,
  });

  final double height;
  final double radius;
  final TextStyle label;
  final double borderWidth;
  final List<BoxShadow>? primaryShadow;

  static const TaytayButtonMetrics signIn = TaytayButtonMetrics(
    height: 50,
    radius: Radii.pill,
    label: AppTypography.buttonSignIn,
    borderWidth: 1.6,
    primaryShadow: <BoxShadow>[
      BoxShadow(color: Color(0x470B3D91), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  static const TaytayButtonMetrics welcome = TaytayButtonMetrics(
    height: 52,
    radius: Radii.pill,
    label: AppTypography.buttonWelcome,
    borderWidth: 1.6,
    primaryShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x4C0B3D91),
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const TaytayButtonMetrics inApp = TaytayButtonMetrics(
    height: 48,
    radius: Radii.md,
    label: AppTypography.button,
    borderWidth: 1.5,
  );

  static TaytayButtonMetrics of(TaytayButtonKind kind) => switch (kind) {
    TaytayButtonKind.signIn => signIn,
    TaytayButtonKind.welcome => welcome,
    TaytayButtonKind.inApp => inApp,
  };
}
