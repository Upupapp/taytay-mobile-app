import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'typography.dart';

/// Which old CSS button the control followed.
///
/// The redesign has one button: 52 high, radius 16, 14 / 600, no shadow. The
/// three kinds stay so callers compile; all three now resolve to the same
/// metrics, and Phase 3 drops the argument screen by screen.
enum TaytayButtonKind {
  /// Formerly the sign-in pill. Now the redesign button.
  signIn,

  /// Formerly the welcome pill. Now the redesign button.
  welcome,

  /// The in-app button. The redesign button.
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

  /// Always null: the redesign has no shadows. Kept so callers compile.
  final List<BoxShadow>? primaryShadow;

  /// The redesign button (design/README.md "Radii and sizes").
  static const TaytayButtonMetrics redesign = TaytayButtonMetrics(
    height: ComponentSizes.buttonHeight,
    radius: Radii.button,
    label: AppTypography.button,
    borderWidth: 1.5,
  );

  static const TaytayButtonMetrics signIn = redesign;

  static const TaytayButtonMetrics welcome = redesign;

  static const TaytayButtonMetrics inApp = redesign;

  static TaytayButtonMetrics of(TaytayButtonKind kind) => switch (kind) {
    TaytayButtonKind.signIn => signIn,
    TaytayButtonKind.welcome => welcome,
    TaytayButtonKind.inApp => inApp,
  };
}

/// Button styles for Material buttons that are not the theme's default.
///
/// The theme already makes [FilledButton] the primary, and
/// [FilledButton.tonal] and [OutlinedButton] the soft secondary. These are
/// for a [FilledButton] that must look like one of the others (gold), or a
/// compact one.
abstract final class TaytayButtonStyles {
  static final OutlinedBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.button),
  );

  /// Soft secondary: blue-50 fill, blue label, blue-100 when pressed.
  static ButtonStyle soft() => FilledButton.styleFrom(
    backgroundColor: BrandColors.blue50,
    foregroundColor: BrandColors.blue,
    disabledBackgroundColor: BrandColors.chipFill,
    disabledForegroundColor: BrandColors.muted,
    minimumSize: const Size(64, ComponentSizes.buttonHeight),
    shape: _shape,
    elevation: 0,
    shadowColor: BrandColors.transparent,
    textStyle: AppTypography.button,
  ).copyWith(overlayColor: _pressed(BrandColors.blue100));

  /// Gold: gold fill, navy label (CSS `.btn.gold`).
  static ButtonStyle gold() => FilledButton.styleFrom(
    backgroundColor: BrandColors.gold,
    foregroundColor: BrandColors.navy,
    minimumSize: const Size(64, ComponentSizes.buttonHeight),
    shape: _shape,
    elevation: 0,
    shadowColor: BrandColors.transparent,
    textStyle: AppTypography.button,
  );

  /// Compact: 44 high, 13.5 / 600 (CSS `.btn.sm`). Merge over another style.
  static ButtonStyle compact() => FilledButton.styleFrom(
    minimumSize: const Size(64, ComponentSizes.buttonHeightSmall),
    textStyle: AppTypography.sbtn,
  );

  /// A pressed/hovered/focused layer that *replaces* the fill rather than
  /// tinting it: CSS moves blue-50 to blue-100 on hover.
  static WidgetStateProperty<Color?> _pressed(Color color) =>
      WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return color;
        }
        return null;
      });
}
