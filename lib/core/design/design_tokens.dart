import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The Taytay brand palette — the single source of colour truth.
///
/// Only one brand exists in this app: the Municipality of Taytay, Rizal. No
/// partner, vendor or reference-app branding appears anywhere in the product
/// surface.
///
/// These are *brand* colours. Screens read semantic roles from
/// `Theme.of(context).colorScheme`, which is derived from these; a widget that
/// hard-codes a value from here bypasses dark mode and high-contrast handling.
///
/// **The 2026-11 redesign.** The first block below is the redesign palette,
/// named as `design/README.md` names it (blue, navy, gold, ink, text, muted…).
/// The second block keeps the names feature code already uses and re-points
/// each one at the redesign value nearest its old meaning, so every screen
/// compiles and moves toward the new look before Phase 3 restyles it. New code
/// uses the first block.
///
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
  // ---------------------------------------------------------------------------
  // Redesign palette (design/README.md, design-system.css).
  // ---------------------------------------------------------------------------

  /// Primary blue. The Material 3 seed and `ColorScheme.primary`.
  static const Color blue = Color(0xFF0A2071);

  /// Deepest blue: the start of the header gradient, gold-button ink.
  static const Color navy = Color(0xFF08124A);

  /// Bright blue: the end of the header gradient and the sky tile.
  static const Color sky = Color(0xFF2D54E0);

  /// The lighter end of the sky icon tile.
  static const Color skyLight = Color(0xFF5C7DF2);

  /// Gold. Accent and fill only — about 1.4:1 on white, never text on a light
  /// surface.
  static const Color gold = Color(0xFFF5DA18);

  /// Gold dark enough to be text on a light surface (eyebrows, pill ink).
  static const Color goldInk = Color(0xFF6B5A00);

  /// Gold tint behind gold pills and notes.
  static const Color gold50 = Color(0xFFFEF7CF);

  /// Red. Error borders and the emergency context.
  static const Color red = Color(0xFFE0090A);

  /// Red dark enough for error text on light surfaces and on [red50].
  static const Color redInk = Color(0xFFA30708);

  /// Red tint behind red pills and notes.
  static const Color red50 = Color(0xFFFDECEC);

  /// Green. Success and "open".
  static const Color green = Color(0xFF17663A);

  /// Green tint behind green pills and notes.
  static const Color green50 = Color(0xFFE4F4EA);

  /// Soft blue: the soft secondary button and quiet chips.
  static const Color blue50 = Color(0xFFECF1FC);

  /// Pressed soft button; the selected bottom-navigation indicator.
  static const Color blue100 = Color(0xFFDCE5FA);

  /// Headings.
  static const Color ink = Color(0xFF0E1733);

  /// Body copy.
  static const Color text = Color(0xFF2B3550);

  /// Supporting copy, list details, timestamps.
  static const Color muted = Color(0xFF5B6680);

  /// Screen background behind soft cards.
  static const Color background = Color(0xFFF4F6FA);

  /// Glass screens' page colour, under the colour blobs.
  static const Color glassBackground = Color(0xFFEEF2FA);

  /// Filled text fields at rest.
  static const Color softFill = Color(0xFFF2F4F8);

  /// Filled text field under a pointer. CSS `.inp:hover`.
  static const Color softFillHover = Color(0xFFECEFF5);

  /// Quiet (unselected) chip fill. CSS `.soft .chip`.
  static const Color chipFill = Color(0xFFEEF1F7);

  /// Hairline between list rows.
  static const Color divider = Color(0xFFEEF1F6);

  /// Light structural line (foot bars, steppers).
  static const Color line = Color(0xFFECEFF5);

  /// Stronger line (unselected check cards on white).
  static const Color line2 = Color(0xFFDCE2EC);

  /// Header subtitle on the blue gradient. CSS `.tt .s`.
  static const Color onHeaderMuted = Color(0xFFC3CDE6);

  /// Lede copy on the blue gradient. CSS `.lede`, `.wtitle p`.
  static const Color onHeaderLede = Color(0xFFD5DDF2);

  /// "Verified" on the blue gradient. CSS `.vt`.
  static const Color onHeaderSuccess = Color(0xFF9BE3B4);

  /// The verified tick on the header avatar. CSS `.vb`.
  static const Color successBright = Color(0xFF2EA05A);

  /// Error field fill. CSS `.inp.err`.
  static const Color errorFill = Color(0xFFFFF5F5);

  /// Fully transparent. The resting border of a filled field.
  static const Color transparent = Color(0x00000000);

  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Names feature code already uses, re-pointed at the redesign palette.
  // ---------------------------------------------------------------------------

  /// Re-pointed to [blue].
  static const Color taytayBlue = blue;

  /// Re-pointed to [navy].
  static const Color taytayBlueDark = navy;

  /// Re-pointed to [sky].
  static const Color taytayBlueLight = sky;

  /// Re-pointed to [gold]. Accent only — never a text colour on light
  /// surfaces, where it cannot reach 4.5:1.
  static const Color sealGold = gold;

  /// Re-pointed to [red]. Reserved for the national/emergency context.
  static const Color flagRed = red;

  /// Status colours, contrast-checked against white in `brand_test.dart`.
  static const Color success = green;
  static const Color warning = goldInk;

  /// The error role. [redInk] rather than [red] so error *text* clears 4.5:1
  /// on white and on [red50]; error borders use [red].
  static const Color danger = redInk;
  static const Color info = blue;

  /// The page is [surface]; cards sit on [surfaceCard].
  static const Color surface = background;
  static const Color surfaceMuted = blue50;
  static const Color surfaceCard = white;

  /// Headings and primary copy.
  static const Color textPrimary = ink;

  /// Supporting copy. Re-pointed to [muted].
  static const Color textSecondary = muted;
  static const Color textMuted = muted;

  /// Re-pointed to [goldInk] (6.3:1 on [surface]).
  static const Color inkGold = goldInk;

  /// Welcome body copy. Re-pointed to [text].
  static const Color welcomeCopy = text;

  /// The stitched thread on the old welcome screen. Kept until Phase 3
  /// rebuilds onboarding.
  static const Color threadGold = Color(0xFFC9A227);

  /// Photo-credit chip ink on the old welcome screen.
  static const Color creditInk = Color(0xFF5E5843);

  /// Core of the travelling light on the old welcome screen.
  static const Color speckCore = Color(0xFFFFF6C2);

  /// Sheet body copy. Re-pointed to [text].
  static const Color sheetBody = text;

  /// Field label. Re-pointed to [text] (CSS `.fld`).
  static const Color fieldLabel = text;

  /// Field fill and resting border. A filled field has a transparent border.
  static const Color fieldFill = softFill;
  static const Color fieldBorder = transparent;

  /// Error field fill. Re-pointed to [errorFill].
  static const Color fieldErrorFill = errorFill;

  /// Placeholder ink. The mock-up's `#8A93A6` is 2.8:1 on [softFill]; [muted]
  /// keeps a placeholder readable (5.2:1).
  static const Color fieldHint = muted;

  /// Card hairline. Re-pointed to [divider].
  static const Color cardLine = divider;

  /// List meta. Re-pointed to [muted].
  static const Color listMeta = muted;

  /// Field value. Re-pointed to [ink].
  static const Color fieldInk = ink;

  /// Trailing chevron. Kept at 3.6:1 on white: the mock-up's `#B4BCCB` is
  /// below the 3:1 a meaningful graphic needs.
  static const Color chevron = Color(0xFF7D869C);

  /// SAMPLE dashed stroke, dev gallery only.
  static const Color sampleBorder = Color(0xFFE0A400);

  /// Dimmed issued card, 160° `#6E7C99 → #4A5674 → #333D55`.
  static const Color cardDimStart = Color(0xFF6E7C99);
  static const Color cardDimMid = Color(0xFF4A5674);
  static const Color cardDimEnd = Color(0xFF333D55);

  /// Dashed frame around the scannable code.
  static const Color qrFrame = Color(0xFF9AA6BF);

  /// Status chip fills, re-pointed to the redesign tints.
  static const Color chipAmberBg = gold50;
  static const Color chipGreenBg = green50;
  static const Color chipRedBg = red50;
  static const Color chipBlueBg = blue50;
  static const Color chipGreyBg = chipFill;
  static const Color chipGoldBg = gold50;
}

/// Shadows. **The redesign has none** ("no shadows or glows anywhere"): every
/// list is empty, so old callers compile and paint flat. Do not add a value
/// here; depth comes from surface colour, glass and the header shapes.
abstract final class TaytayShadows {
  static const List<BoxShadow> card = <BoxShadow>[];

  static const List<BoxShadow> raised = <BoxShadow>[];

  static const List<BoxShadow> digitalId = <BoxShadow>[];
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

  /// Horizontal padding of form and onboarding screens (CSS `.obbody`).
  static const double formGutter = 20;

  /// Gap between form fields (CSS `.form`).
  static const double formGap = 18;

  /// Gap between stacked cards on a screen body (CSS `.body`).
  static const double section = 14;
}

/// Corner radii.
///
/// The first block is the original scale, kept for callers. The second block
/// is the redesign, named by what it rounds; new code uses those.
abstract final class Radii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Bottom sheets: top corners.
  static const double sheet = 24;
  static const double sheetLarge = 28;

  /// The welcome arch. A large continuous corner, not a card radius.
  static const double arch = 120;

  static const double pill = 999;

  /// Small square tags on a photo or card (CSS `.hero .ey`, radius 6).
  static const double tag = 6;

  // Redesign (design/README.md "Radii and sizes").

  /// Buttons.
  static const double button = 16;

  /// Filled text fields and search boxes.
  static const double field = 14;

  /// Soft cards and lists.
  static const double card = 20;

  /// Glass cards and boxed empty states.
  static const double cardLarge = 22;

  /// Icon tiles: 44 dp tile.
  static const double tile = 14;

  /// Icon tiles: 36 dp tile.
  static const double tileSmall = 11;

  /// Icon tiles: 56 dp tile.
  static const double tileLarge = 17;

  /// Bottom corners of the blue header.
  static const double header = 28;

  /// Centred dialogs.
  static const double dialog = 22;

  /// Notes (inset callouts, soft variant).
  static const double note = 14;

  /// Check cards (consent rows).
  static const double check = 16;
}

/// Component sizes from the redesign. A visual size, not a tap target: a 36 dp
/// chip still reserves [A11y.minTapTarget] through the theme's padded tap
/// target size.
abstract final class ComponentSizes {
  /// Primary and soft buttons.
  static const double buttonHeight = 52;

  /// The widest a centred dialog grows (`AppDialog.show`). A phone never
  /// reaches it; a tablet keeps a readable line instead of a wall of text.
  static const double dialogMaxWidth = 480;

  /// The block a photo stands behind while it loads in a dialog
  /// (`SkeletonLayout.photo`).
  static const double skeletonPhoto = 200;

  /// Compact button (CSS `.btn.sm`).
  static const double buttonHeightSmall = 44;

  /// Filled text fields.
  static const double fieldHeight = 54;

  /// Chips and filter pills (CSS `.soft .chip`).
  static const double chipHeight = 36;

  /// Icon tiles.
  static const double tile = 44;
  static const double tileSmall = 36;
  static const double tileLarge = 56;

  /// Home launcher squares (CSS `.launch .sq`, 62 at radius 20).
  static const double launchTile = 62;

  /// Round icon buttons on the header (bell, back, search).
  static const double headerIconButton = 44;

  /// Initials avatar on the header.
  static const double avatar = 44;

  /// Seal on the header.
  static const double seal = 38;

  /// Minimum list row height (CSS `.li`).
  static const double listRow = 64;

  /// The soft icon square that leads a settings row (CSS `.ic`, radius 12).
  static const double listIcon = 40;

  /// The red count on a row (CSS `.cnt`).
  static const double countBadge = 22;

  /// The numbered disc beside a step (claim steps, event agenda).
  static const double stepDisc = 26;

  /// The thin completion bar under a row (CSS `.prog`).
  static const double progressBar = 6;

  /// The resident's avatar on the My Account header (CSS `.prof .av`).
  static const double profileAvatar = 60;

  /// The verified tick on that avatar (CSS `.vb`).
  static const double profileBadge = 22;

  /// The gold "My Taytay ID" button on the My Account header (CSS `.idbtn`).
  static const double headerButton = 50;

  /// Chat bubbles stop at this share of the row (CSS `.them` max-width 82%).
  static const double bubbleWidthFactor = 0.82;

  /// Bottom navigation bar, without the safe-area inset.
  static const double navigationBar = 80;

  /// Selected-destination indicator (CSS `.tab .ind`).
  static const Size navigationIndicator = Size(56, 30);
}

/// Focus treatment for filled fields and search boxes: white fill, a 1.5 px
/// blue border and a 3 px ring of blue at 14% outside it (CSS `.inp:focus`).
/// A ring is not a shadow: it is the visible focus indicator and must stay.
abstract final class FocusRing {
  static const double borderWidth = 1.5;
  static const double ringWidth = 3;

  /// [BrandColors.blue] at 14%.
  static const Color ring = Color(0x240A2071);

  /// [BrandColors.red] at 16%, for a focused field in error.
  static const Color errorRing = Color(0x29E0090A);
}

/// Elevation steps. **The redesign is flat**: every step is 0, so no Material
/// surface casts a shadow or picks up an elevation tint. The names stay so
/// callers compile.
abstract final class Elevation {
  static const double none = 0;
  static const double raised = 0;
  static const double scrolledUnder = 0;
  static const double floating = 0;
  static const double dialog = 0;
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

  /// Visible diameter of the back button. The hit target stays
  /// [minTapTarget]; the circle is the smaller mark from the mockups, centred
  /// inside that target (decision D3).
  static const double backButtonVisual = 44;

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
