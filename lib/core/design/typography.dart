import 'package:flutter/material.dart';

/// The app's type scale.
///
/// Built by adjusting Material 3's own scale rather than replacing it. The
/// M3 scale already carries tested line heights and letter spacing at every
/// size, and — more importantly — every Material component reads from these
/// named roles, so a component the app has not customised still lands on the
/// scale.
///
/// **The 2026-11 redesign** (`design/README.md`, "Type"). The roles named
/// after the README — [hero], [headerTitleLarge], [pageTitle], [sectionTitle],
/// [listTitle], [listDetail], [chip], [category]… — are what new code uses.
/// The older names further down are re-pointed at the nearest redesign role
/// so feature code compiles until Phase 3 restyles it.
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

  /// Display titles, the redesign's ExtraBold (category labels, selected tab).
  static const FontWeight black = FontWeight.w800;

  /// Headings: hero, header, page and empty-state titles.
  static const FontWeight strong = FontWeight.w700;

  /// SemiBold: list titles, buttons, chips, fields, section titles.
  static const FontWeight medium = FontWeight.w600;

  /// Body copy.
  static const FontWeight body = FontWeight.w500;

  /// Smallest size the app will render, at 1.0x scale.
  ///
  /// The redesign's category label (ABISO · MSWDO) is 10.5 / 800, uppercase
  /// and tracked; nothing else goes below 11, and nothing a resident must act
  /// on goes below 11.5.
  static const double minFontSize = 10.5;

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ---------------------------------------------------------------------------
  // Redesign roles.
  // ---------------------------------------------------------------------------

  /// Hero titles: welcome, wave header. 22 / 700, tracking −0.015em.
  static final TextStyle hero = _base.copyWith(
    fontSize: 22,
    fontWeight: strong,
    height: 1.18,
    letterSpacing: -0.33,
  );

  /// The big header bar title (tab roots). 20 / 700.
  static final TextStyle headerTitleLarge = _base.copyWith(
    fontSize: 20,
    fontWeight: strong,
    height: 1.12,
    letterSpacing: -0.3,
  );

  /// Header bar title beside a back button. 15 / 600.
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Header subtitle. 11.5 / 500, on `BrandColors.onHeaderMuted`.
  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: body,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Page title. 18 / 700.
  static final TextStyle pageTitle = _base.copyWith(
    fontSize: 18,
    fontWeight: strong,
    height: 1.15,
    letterSpacing: -0.27,
  );

  /// Section title. 15 / 600.
  static final TextStyle sectionTitle = _base.copyWith(
    fontSize: 15,
    fontWeight: medium,
    height: 1.25,
  );

  /// Body. 13.5 / 500, line height 1.5.
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: body,
    height: 1.5,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// List row title. 13.5 / 600.
  static final TextStyle listTitle = _base.copyWith(
    fontSize: 13.5,
    fontWeight: medium,
    height: 1.3,
  );

  /// List detail and supporting copy. 12.5 / 500.
  static final TextStyle listDetail = _base.copyWith(
    fontSize: 12.5,
    fontWeight: body,
    height: 1.4,
  );

  /// Small text and timestamps. 11.5 / 500.
  static final TextStyle small = _base.copyWith(
    fontSize: 11.5,
    fontWeight: body,
    height: 1.3,
  );

  /// Tiny text. 11 / 500.
  static final TextStyle tiny = _base.copyWith(
    fontSize: 11,
    fontWeight: body,
    height: 1.3,
  );

  /// Field hint and error line under a field. 11.5 / 500.
  static final TextStyle fieldHelp = _base.copyWith(
    fontSize: 11.5,
    fontWeight: body,
    height: 1.3,
  );

  /// Chips and filter pills. 13.5 / 600.
  static final TextStyle chip = _base.copyWith(
    fontSize: 13.5,
    fontWeight: medium,
    height: 1.2,
  );

  /// Status pill (Open, Verified). 11.5 / 700.
  static final TextStyle pill = _base.copyWith(
    fontSize: 11.5,
    fontWeight: strong,
    height: 1.2,
  );

  /// Bottom navigation label. 11 / 600; [navLabelSelected] is 11 / 800.
  static final TextStyle navLabel = _base.copyWith(
    fontSize: 11,
    fontWeight: medium,
    height: 1.2,
  );

  static final TextStyle navLabelSelected = navLabel.copyWith(
    fontWeight: black,
  );

  /// Category label (ABISO · MSWDO). 10.5 / 800, tracking 0.06em. Callers
  /// upper-case the string; a [TextStyle] cannot.
  static final TextStyle category = _base.copyWith(
    fontSize: 10.5,
    fontWeight: black,
    height: 1.2,
    letterSpacing: 0.63,
  );

  // ---------------------------------------------------------------------------
  // Older names, re-pointed at the redesign roles.
  // ---------------------------------------------------------------------------

  /// Welcome title. Re-pointed to [hero] (22 / 700).
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: strong,
    height: 1.18,
    letterSpacing: -0.33,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in title. Re-pointed to [hero] (22 / 700).
  static const TextStyle h1SignIn = h1;

  /// Sign-in wordmark. 15 / 700.
  static const TextStyle brandTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome wordmark. Re-pointed to [brandTitle].
  static const TextStyle brandTitleWelcome = brandTitle;

  /// Wordmark subtitle. Re-pointed to [headerSubtitle] at 600.
  static const TextStyle brandSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome wordmark subtitle. Re-pointed to [brandSubtitle].
  static const TextStyle brandSubtitleWelcome = brandSubtitle;

  /// Page titles. Re-pointed to [headerTitleLarge] (20 / 700).
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: strong,
    height: 1.12,
    letterSpacing: -0.3,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Re-pointed to [pageTitle] (18 / 700).
  static const TextStyle titleCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: strong,
    height: 1.15,
    letterSpacing: -0.27,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Card and list titles. Re-pointed to [listTitle] (13.5 / 600).
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: medium,
    height: 1.3,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Empty-state title. 15 / 700 (CSS `.es .ttl`).
  static const TextStyle emptyTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: strong,
    height: 1.3,
    letterSpacing: -0.15,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Supporting copy. Re-pointed to [listDetail] (12.5 / 500), line 1.5.
  static const TextStyle bodyCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: body,
    height: 1.5,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// List meta. Re-pointed to [listDetail] (12.5 / 500).
  static const TextStyle listMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: body,
    height: 1.4,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Field value. 14 / 600.
  static const TextStyle fieldValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Field label above a filled field. 12.5 / 600.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Chips and badges. Re-pointed to [pill] (11.5 / 700).
  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Button label. 14 / 600.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in button. Re-pointed to [button].
  static const TextStyle buttonSignIn = button;

  /// Welcome button. Re-pointed to [button].
  static const TextStyle buttonWelcome = button;

  /// Compact pill button (CSS `.btn.sm`). 13.5 / 600.
  static const TextStyle sbtn = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Text button. 13.5 / 600 (CSS `.soft .link`).
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in guest link. Re-pointed to [link].
  static const TextStyle linkGuest = link;

  /// Welcome Skip. 14 / 600.
  static const TextStyle linkSkip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Eyebrow. 11.5 / 700, tracking 0.06em, on `BrandColors.goldInk`.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: strong,
    height: 1.2,
    letterSpacing: 0.69,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sign-in eyebrow. Re-pointed to [eyebrow].
  static const TextStyle eyebrowSignIn = eyebrow;

  /// Applies the redesign's sizes and weights to a base Material scale.
  ///
  /// [bodyColor] and [supportingColor] colour the body roles; null keeps the
  /// base colours (the dark theme, until its pass lands).
  static TextTheme apply(
    TextTheme base, {
    Color? bodyColor,
    Color? supportingColor,
  }) {
    TextStyle? role(
      TextStyle? style,
      FontWeight weight, {
      double? size,
      double? height,
      double? letterSpacing,
      Color? color,
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
        color: color,
      );
    }

    return base.copyWith(
      headlineLarge: role(
        base.headlineLarge,
        strong,
        size: 22,
        height: 1.18,
        letterSpacing: -0.33,
      ),
      headlineMedium: role(
        base.headlineMedium,
        strong,
        size: 20,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      headlineSmall: role(
        base.headlineSmall,
        strong,
        size: 18,
        height: 1.15,
        letterSpacing: -0.27,
      ),
      titleLarge: role(
        base.titleLarge,
        strong,
        size: 20,
        height: 1.12,
        letterSpacing: -0.3,
      ),
      titleMedium: role(base.titleMedium, medium, size: 15, height: 1.25),
      titleSmall: role(base.titleSmall, medium, size: 13.5, height: 1.3),
      bodyLarge: role(
        base.bodyLarge,
        body,
        size: 14,
        height: 1.5,
        color: bodyColor,
      ),
      bodyMedium: role(
        base.bodyMedium,
        body,
        size: 13.5,
        height: 1.5,
        color: bodyColor,
      ),
      bodySmall: role(
        base.bodySmall,
        body,
        size: 12.5,
        height: 1.45,
        color: supportingColor,
      ),
      labelLarge: role(base.labelLarge, medium, size: 14, height: 1.2),
      labelMedium: role(base.labelMedium, medium, size: 12.5, height: 1.2),
      labelSmall: role(base.labelSmall, medium, size: 11, height: 1.2),
    );
  }
}

/// Plus Jakarta's Chrome `line-height: normal`, after the 3× capture rounding.
///
/// The hhea and typo metrics are ascender 1038 and descender −222 on a
/// 1000-unit em. Blink rounds each to a device pixel, so 11 → 13.67,
/// 14 → 17.67 and 15 → 19. Account spacing uses this same box.
///
/// [baseline] is not [ascender]. Chrome ceils the descender to a device
/// pixel and gives the rest of the line box to the baseline, so a 14 px
/// line is still 17.67 tall but its baseline sits at 14.33, not 14.67.
/// `vertical-align: middle` and the glyphs inside that line use [baseline].
abstract final class TypeMetrics {
  static double ascender(double fontSize) =>
      ((fontSize * 3 * 1038 / 1000).round()) / 3;

  static double descender(double fontSize) =>
      ((fontSize * 3 * 222 / 1000).round()) / 3;

  static double line(double fontSize) =>
      ascender(fontSize) + descender(fontSize);

  /// Alphabetic baseline, in CSS px, measured from the top of [line].
  static double baseline(double fontSize) {
    final int descender = (fontSize * 3 * 222 / 1000).ceil();
    final int line =
        (fontSize * 3 * 1038 / 1000).round() +
        (fontSize * 3 * 222 / 1000).round();
    return (line - descender) / 3;
  }
}
