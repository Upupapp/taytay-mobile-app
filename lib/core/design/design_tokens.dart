import 'dart:math' as math;
import 'dart:ui';

/// The Taytay brand palette — the single source of colour truth.
///
/// Only one brand exists in this app: the Municipality of Taytay, Rizal. No
/// partner, vendor or reference-app branding appears anywhere in the product
/// surface.
///
/// These are *brand* colours. Screens read semantic roles from
/// `Theme.of(context).colorScheme`, which is derived from these; a widget that
/// hard-codes a value from here bypasses dark mode and high-contrast handling.
abstract final class BrandColors {
  /// Official deep blue — the primary brand colour and the Material 3 seed.
  static const Color taytayBlue = Color(0xFF0B3D91);
  static const Color taytayBlueDark = Color(0xFF062358);
  static const Color taytayBlueLight = Color(0xFF1E5BC6);

  /// Municipal seal gold. Accent only — never a text colour on light surfaces,
  /// where it cannot reach 4.5:1 contrast.
  static const Color sealGold = Color(0xFFFCD116);

  /// Philippine flag red. Reserved for the national/emergency context; not a
  /// generic error colour.
  static const Color flagRed = Color(0xFFCE1126);

  /// Status colours, contrast-checked against their `on` pairs in the theme.
  static const Color success = Color(0xFF0F7A4D);
  static const Color warning = Color(0xFF8A5A00);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1B5EA8);
}

/// Spacing scale, in logical pixels.
///
/// A 4-point grid: every gap in the app is one of these. Ad-hoc values are how a
/// layout stops being predictable under large text settings.
abstract final class Spacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Default horizontal page padding.
  static const double screenGutter = lg;
}

/// Corner radii.
abstract final class Radii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Accessibility constants applied across the app.
///
/// Material 3 is the accessibility foundation: it ships correct focus
/// indicators, semantics, contrast-aware colour roles and dynamic type support
/// out of the box. These constants cover the things a theme cannot enforce on
/// its own.
abstract final class A11y {
  /// Minimum interactive size. Material's own guidance is 48x48 dp; WCAG 2.2
  /// (2.5.8 Target Size, AA) requires at least 24x24 CSS px. 48 satisfies both
  /// and is the floor for every tappable element in this app, including icon
  /// buttons in dense rows.
  static const double minTapTarget = 48;

  /// The app honours the OS text size all the way to this multiplier without
  /// clipping or truncating. Layouts must scroll rather than shrink text; a
  /// government service a person cannot read is a service they cannot use.
  static const double maxSupportedTextScale = 2.0;

  /// Below this the OS setting is respected but layouts are not guaranteed;
  /// clamped so a tiny system scale cannot render text illegibly small.
  static const double minSupportedTextScale = 0.85;

  /// WCAG 2.2 AA contrast minimum for body text.
  static const double minBodyContrastRatio = 4.5;

  /// WCAG 2.2 AA contrast minimum for large text and meaningful graphics.
  static const double minLargeTextContrastRatio = 3.0;
}

/// Relative luminance per WCAG 2.x, used by the contrast checks that guard the
/// palette in tests.
double relativeLuminance(Color color) {
  double channel(double component) => component <= 0.03928
      ? component / 12.92
      : _pow((component + 0.055) / 1.055, 2.4);

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two opaque colours, from 1.0 to 21.0.
double contrastRatio(Color a, Color b) {
  final luminanceA = relativeLuminance(a);
  final luminanceB = relativeLuminance(b);
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

double _pow(double base, double exponent) => math.pow(base, exponent).toDouble();
