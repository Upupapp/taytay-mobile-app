import 'package:flutter/material.dart';

/// The app's type scale.
///
/// Built by adjusting Material 3's own scale rather than replacing it. The
/// M3 scale already carries tested line heights and letter spacing at every
/// size, and — more importantly — every Material component reads from these
/// named roles, so a component the app has not customised still lands on the
/// scale.
///
/// **Font.** The platform font (Roboto on Android, San Francisco on iOS). No
/// font is downloaded at runtime: that is a third-party CDN call on first launch
/// and unstyled text on the weak connections many residents have. See CLAUDE.md
/// Article 6.
///
/// **Sizes are never scaled down to fit.** Every size below is a floor that the
/// OS text setting multiplies up from. A layout that does not fit at 200% scrolls;
/// it does not shrink its text.
abstract final class AppTypography {
  /// Weight for headings and anything that labels an action.
  static const FontWeight strong = FontWeight.w700;

  /// Weight for supporting labels — section headers, field labels.
  static const FontWeight medium = FontWeight.w600;

  /// Smallest size the app will render, at 1.0x scale.
  ///
  /// Material's `labelSmall` is 11sp. Government copy that a resident may need
  /// to act on should not be smaller than this, and nothing below it is used for
  /// anything but timestamps and legal footnotes.
  static const double minFontSize = 11;

  /// Applies the app's weight and size adjustments to a base Material scale.
  static TextTheme apply(TextTheme base) {
    return base.copyWith(
      // Display/headline: used sparingly — a screen title, a value being
      // presented (an ID number, an amount).
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: strong),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: strong),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: strong),

      // Titles: card and section headings.
      titleLarge: base.titleLarge?.copyWith(fontWeight: strong),
      titleMedium: base.titleMedium?.copyWith(fontWeight: medium),
      titleSmall: base.titleSmall?.copyWith(fontWeight: medium),

      // Body: the default for everything a resident reads. Line height is
      // raised slightly from Material's default — Filipino and English service
      // copy runs long, and tighter leading measurably slows reading of
      // multi-line paragraphs.
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.bodySmall?.copyWith(height: 1.40),

      // Labels: buttons, chips, field labels. Strong weight on the large label
      // because it is the one that names an action.
      labelLarge: base.labelLarge?.copyWith(fontWeight: strong),
      labelMedium: base.labelMedium?.copyWith(fontWeight: medium),
      labelSmall: base.labelSmall?.copyWith(fontWeight: medium),
    );
  }
}
