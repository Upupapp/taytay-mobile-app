import 'package:flutter/material.dart';

/// The app's type scale.
///
/// Built by adjusting Material 3's own scale rather than replacing it. The
/// M3 scale already carries tested line heights and letter spacing at every
/// size, and — more importantly — every Material component reads from these
/// named roles, so a component the app has not customised still lands on the
/// scale.
///
/// **Font.** Plus Jakarta Sans, bundled under `assets/fonts/plus_jakarta_sans/`
/// (SIL OFL 1.1). It is an asset, not a download: nothing is fetched at runtime.
/// See CLAUDE.md Article 6 and decision D4.
///
/// **Sizes are never scaled down to fit.** Every size below is a floor that the
/// OS text setting multiplies up from. A layout that does not fit at 200% scrolls;
/// it does not shrink its text.
abstract final class AppTypography {
  static const String fontFamily = 'Plus Jakarta Sans';

  /// Weight for headings and anything that labels an action.
  static const FontWeight strong = FontWeight.w700;

  /// Display and screen titles in the mockups (H1, card titles).
  static const FontWeight black = FontWeight.w800;

  /// Weight for supporting labels — section headers, field labels.
  static const FontWeight medium = FontWeight.w600;

  /// Body copy in the mockups.
  static const FontWeight body = FontWeight.w500;

  /// Smallest size the app will render, at 1.0x scale.
  ///
  /// Material's `labelSmall` is 11sp. Government copy that a resident may need
  /// to act on should not be smaller than this, and nothing below it is used for
  /// anything but timestamps and legal footnotes.
  static const double minFontSize = 11;

  /// Screen title. Mockup H1 is 28 / extra-bold.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: black,
    height: 1.15,
  );

  /// Card and page titles, 20 / extra-bold. [titleCompact] is the 18 step.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: black,
    height: 1.2,
  );

  static const TextStyle titleCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: black,
    height: 1.25,
  );

  /// Body, 14 / medium. [bodyCompact] is the 13.5 step used in dense rows.
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: body,
    height: 1.45,
  );

  static const TextStyle bodyCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: body,
    height: 1.4,
  );

  /// Buttons and chips, 12 / bold.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: strong,
    height: 1.2,
  );

  /// The smallest action label, 11 / extra-bold.
  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: black,
    height: 1.2,
  );

  /// Eyebrow above a title: 11 / extra-bold, tracked out.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 1.6,
  );

  /// Applies the app's weight and size adjustments to a base Material scale.
  static TextTheme apply(TextTheme base) {
    TextStyle? role(TextStyle? style, FontWeight weight, {double? size}) {
      return style?.copyWith(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: size,
      );
    }

    return base.copyWith(
      // Display/headline: a screen title. 28 matches the mockup H1.
      headlineLarge: role(base.headlineLarge, black, size: 28),
      headlineMedium: role(base.headlineMedium, black, size: 24),
      headlineSmall: role(base.headlineSmall, black, size: 20),

      // Titles: card and section headings, 20 and 18.
      titleLarge: role(base.titleLarge, black, size: 20),
      titleMedium: role(base.titleMedium, black, size: 18),
      titleSmall: role(base.titleSmall, strong, size: 14),

      // Body: the default for everything a resident reads.
      bodyLarge: role(base.bodyLarge, body, size: 14)?.copyWith(height: 1.45),
      bodyMedium: role(
        base.bodyMedium,
        body,
        size: 13.5,
      )?.copyWith(height: 1.45),
      bodySmall: role(base.bodySmall, body, size: 12)?.copyWith(height: 1.40),

      labelLarge: role(base.labelLarge, strong, size: 14),
      labelMedium: role(base.labelMedium, strong, size: 12),
      labelSmall: role(base.labelSmall, black, size: 11),
    );
  }
}
