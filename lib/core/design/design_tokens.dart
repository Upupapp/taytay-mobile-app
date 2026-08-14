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
/// **A note on what these values are, and are not.**
///
/// These are *application interface* colours chosen for this app. They are **not**
/// a claimed reproduction of an official Municipality of Taytay colour
/// specification, and no Pantone, CMYK or ink reference is asserted anywhere in
/// this repository — no such specification has been supplied to this project, and
/// inventing one would put a fabricated standard into a government product where
/// later readers would treat it as authoritative.
///
/// If the LGU issues a brand manual, these values are reconciled against it in a
/// deliberate change, and the source is cited at that point.
abstract final class BrandColors {
  /// Deep blue — the app's primary colour and the Material 3 seed.
  ///
  /// Chosen as a conventional Philippine civic blue that meets 4.5:1 against
  /// white (see `brand_test.dart`). Continuous with the earlier Taytay prototype
  /// so residents who saw it recognise this app.
  static const Color taytayBlue = Color(0xFF0B3D91);
  static const Color taytayBlueDark = Color(0xFF062358);
  static const Color taytayBlueLight = Color(0xFF1E5BC6);

  /// Gold accent, in the family of the gold in the municipal seal. Accent only —
  /// never a text colour on light surfaces, where it cannot reach 4.5:1.
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

/// Elevation steps, in Material 3 terms.
///
/// Material 3 expresses depth primarily through *surface tone*, not shadow, which
/// is why these are levels rather than shadow definitions: `surfaceContainerLow`
/// through `surfaceContainerHighest` already encode depth and stay legible in
/// dark mode and high-contrast, where a hand-rolled shadow disappears.
///
/// A shadow is used only where a surface genuinely floats above scrolling
/// content — a menu, a sheet, a dialog scrim edge.
abstract final class Elevation {
  /// Flat against the background. Cards, list rows.
  static const double none = 0;

  /// Raised just enough to separate from content that scrolls under it.
  static const double raised = 1;

  /// App bar once content has scrolled beneath it.
  static const double scrolledUnder = 3;

  /// Menus, bottom sheets.
  static const double floating = 6;

  /// Dialogs — the only thing above everything else.
  static const double dialog = 8;
}

/// Opacity steps.
///
/// Deliberately few, and none of them are used to express *disabled text*:
/// Material 3 uses `onSurface` at 38% for disabled, which is below 4.5:1 by
/// design because disabled controls are exempt from WCAG 1.4.3. Anything a
/// resident must actually read uses a full-opacity colour role instead — dimming
/// live text is the most common way an app quietly fails contrast.
abstract final class Opacities {
  /// Scrim behind a modal surface.
  static const double scrim = 0.32;

  /// Pressed / hovered state layer over a coloured surface.
  static const double stateLayer = 0.12;

  /// Decorative dividers and hairlines drawn over a brand colour.
  static const double hairline = 0.24;

  /// Disabled control — Material 3's own value. Never applied to text a
  /// resident is expected to read.
  static const double disabled = 0.38;
}

/// Icon sizes.
///
/// The size is the *glyph*; the tap target is separate and always at least
/// [A11y.minTapTarget]. Conflating the two produces 24 dp buttons.
abstract final class IconSizes {
  /// Inline with body text — status dots, chevrons in dense rows.
  static const double sm = 18;

  /// Default: list leading icons, button icons, app bar actions.
  static const double md = 24;

  /// Section headers and card leading marks.
  static const double lg = 32;

  /// Empty/error/success illustrations.
  static const double xl = 48;

  /// Full-screen state illustrations.
  static const double xxl = 56;
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

double _pow(double base, double exponent) =>
    math.pow(base, exponent).toDouble();
