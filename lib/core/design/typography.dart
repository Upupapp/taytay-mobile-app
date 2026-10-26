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

  /// Welcome screen title. CSS `h1` in gen1.py, after polish: 28 / 800,
  /// line-height 1.13, letter-spacing -0.6.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: black,
    height: 1.13,
    letterSpacing: -0.6,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in sheet title. CSS `h1` is 25px; polish maps 25 → 24.
  /// Line-height 1.15, letter-spacing -0.5, weight 800.
  static const TextStyle h1SignIn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: black,
    height: 1.15,
    letterSpacing: -0.5,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// In-app header title. CSS `.hd .t b` is 16 / 800.
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// In-app header subtitle. CSS `.hd .t small` is 11 / 600.
  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in wordmark. CSS `.brand b` is 14 / 800.
  static const TextStyle brandTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome wordmark. CSS `.brand b` in gen1.py is 15 / 800,
  /// letter-spacing -0.1.
  static const TextStyle brandTitleWelcome = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: black,
    height: 1.2,
    letterSpacing: -0.1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Wordmark subtitle. CSS `.brand small` is 11 / 700, gold.
  static const TextStyle brandSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome wordmark subtitle. Same size and weight, letter-spacing 0.3.
  static const TextStyle brandSubtitleWelcome = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0.3,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Page titles that are not the welcome H1. 20 / 800.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 18 / 800. Polish maps 17px to 18. Not the list-row title.
  static const TextStyle titleCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: black,
    height: 1.25,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Card and list titles. CSS `.ct` is 14 / 800. `.lt` polishes 13.5 → 14 / 800.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Empty-state title. gen2 `empty()` keeps the `.ct` weight and sets 16 px.
  static const TextStyle emptyTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome body. CSS `.body` is 14 / 500, line-height 1.55.
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: body,
    height: 1.55,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sheet and card supporting copy. `.sub` is 13 / 500 / 1.5.
  /// `.cs` polishes 12.5 → 13 / 500 / 1.5.
  static const TextStyle bodyCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: body,
    height: 1.5,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// List meta. `.ls` polishes 11.5 → 12 / 500.
  static const TextStyle listMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: body,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Field value. CSS `.in` polishes 13.5 → 14 / 600.
  static const TextStyle fieldValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Field labels. CSS label polishes 11.5 → 12 / 700.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Chips and badges. CSS `.bdg` / `.pill` is 11 / 800.
  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// In-app button label. gen.py's second `.btn` is 15 / 800.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: black,
    height: 1,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in sheet button. `.btn` polishes 15.5 → 16 / 800.
  static const TextStyle buttonSignIn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: black,
    height: 1,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome sheet button. gen1 `.fin button` is 16 / 800.
  static const TextStyle buttonWelcome = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: black,
    height: 1,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Compact pill. CSS `.sbtn` is 12 / 800.
  static const TextStyle sbtn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Text button. CSS `.link` is 13 / 800.
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in guest link. The sheet overrides `.link` to 12 px; weight stays 800.
  static const TextStyle linkGuest = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome Skip. CSS `.skip` is 14 / 800.
  static const TextStyle linkSkip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome eyebrow. CSS `.en` in gen1.py is 11 / 800, letter-spacing 1.6.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 1.6,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in eyebrow. CSS `.en` in gen.py is letter-spacing 1.5, size polished
  /// from 10.5 to 11, weight 800.
  static const TextStyle eyebrowSignIn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 1.5,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Applies the app's weight and size adjustments to a base Material scale.
  static TextTheme apply(TextTheme base) {
    TextStyle? role(
      TextStyle? style,
      FontWeight weight, {
      double? size,
      double? height,
      double? letterSpacing,
    }) {
      return style?.copyWith(
        fontFamily: fontFamily,
        fontWeight: weight,
        fontSize: size,
        height: height,
        // Null would keep Material's tracking. CSS `normal` is 0 unless a
        // style sets its own letter-spacing.
        letterSpacing: letterSpacing ?? 0,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return base.copyWith(
      headlineLarge: role(
        base.headlineLarge,
        black,
        size: 28,
        height: 1.13,
        letterSpacing: -0.6,
      ),
      headlineMedium: role(
        base.headlineMedium,
        black,
        size: 24,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      headlineSmall: role(base.headlineSmall, black, size: 20, height: 1.2),
      titleLarge: role(base.titleLarge, black, size: 20, height: 1.2),
      titleMedium: role(base.titleMedium, black, size: 18, height: 1.25),
      titleSmall: role(base.titleSmall, black, size: 14, height: 1.25),
      bodyLarge: role(base.bodyLarge, body, size: 14, height: 1.55),
      bodyMedium: role(base.bodyMedium, body, size: 13, height: 1.5),
      bodySmall: role(base.bodySmall, body, size: 12, height: 1.4),
      labelLarge: role(base.labelLarge, black, size: 15, height: 1),
      labelMedium: role(base.labelMedium, strong, size: 12, height: 1.2),
      labelSmall: role(base.labelSmall, black, size: 11, height: 1.2),
    );
  }
}

/// Plus Jakarta's Chrome `line-height: normal`, after the 3× capture rounding.
///
/// The hhea and typo metrics are ascender 1038 and descender −222 on a
/// 1000-unit em. Blink rounds each to a device pixel, so 11 → 13.67,
/// 14 → 17.67 and 15 → 19. Account spacing uses this same box.
abstract final class TypeMetrics {
  static double ascender(double fontSize) =>
      ((fontSize * 3 * 1038 / 1000).round()) / 3;

  static double descender(double fontSize) =>
      ((fontSize * 3 * 222 / 1000).round()) / 3;

  static double line(double fontSize) =>
      ascender(fontSize) + descender(fontSize);
}
