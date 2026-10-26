import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';

/// Spacing for My Account, taken from the 08 CSS and the DOM boxes.
///
/// One CSS pixel is one logical pixel here, and three device pixels on the
/// 08 PNGs. A value stays fractional when the CSS computed it that way.
///
/// Plus Jakarta Sans sets USE_TYPO_METRICS. The hhea and typo metrics are
/// ascender 1038, descender −222, line gap 0, on a 1000-unit em, so Chrome's
/// `line-height: normal` is 1.26em (11 → 13.67, 12 → 15, 13 → 16.33,
/// 14 → 17.67, 15 → 19 at the 3× capture). Flutter's unset [TextStyle.height]
/// is a different box: a 12 px label measured 15 dp, and a chip with 6 dp of
/// padding was 21 dp (63 px) against Chrome's 19.67 dp (59 px). [normal] is
/// that Chrome line box, applied with [lineBox] so the first and last lines
/// keep the half-leading.
abstract final class S8Space {
  /// Page inset. 08-01 card border sits at x = 48.
  static const double gutter = 16;

  /// Card padding, and the inset of a row hairline.
  ///
  /// 08-01 tiles and hairlines run x = 99–1070, which is [gutter] plus the
  /// 1 dp card stroke plus 16.
  static const double cardPad = 16;

  /// Vertical padding of the profile card. CSS padding matches [cardPad].
  static const double profilePadY = 16;

  /// Gap between stacked cards. 08-01 profile border ends at y = 668 and the
  /// next border starts at y = 704.
  static const double cardGap = 12;

  /// First content under the header when it is not the inbox filter.
  ///
  /// 08-01 header ends at y = 311 and the profile card border starts at y = 360.
  static const double pagePad = 16;

  /// Inbox inset under the header, down to the filter.
  ///
  /// 08-02 header ends at y = 311 and the All pill starts at y = 396.
  static const double listInset = 28;

  /// Thread inset under the header, down to the day chip. CSS 22.67 px.
  static const double threadInset = 22.67;

  /// Day chip to the first bubble. 08-07 chip fill ends at y = 489, bubble at 526.
  static const double dayGap = 12;

  /// Bottom padding of a scrolling account page. 08-02 list clears the tab bar.
  static const double pageBottom = 24;

  /// Office, menu, and settings tile. 08-01 / 08-02 / 08-04 tiles are 132 px.
  static const double tile = 44;

  /// Vertical padding of a tile row.
  ///
  /// 08-01 the divider ends at y = 920 and the next tile starts at y = 956.
  static const double rowPadY = 12;

  /// Extra inset at the top and bottom of a card of rows.
  ///
  /// CSS 2 px. Menu, settings, credit, inbox, and banner cards all use it.
  static const double cardInsetY = 2;

  /// Tile to the row title. CSS 12 px.
  static const double iconGap = 12;

  /// Title line to the meta line under it.
  ///
  /// 08-01 title ink starts at y = 774 and the subtitle at y = 832, the 14/1.2
  /// line plus 2 dp. 08-10 title ink to byline ink is the same step.
  static const double titleGap = 2;

  /// 1 dp hairline. 08-01 divider is y = 917–919, #EEF1F6.
  static const double divider = 1;

  /// Filter pill box. CSS height 36, with `padding: 0 14px`.
  static const double filterHeight = 36;

  /// Horizontal padding of a filter pill. CSS `padding: 0 14px` on 12 / 700.
  ///
  /// All computes to 44.59 px and Unread to 72.56 px, 7 px apart
  /// ([filterGapX]).
  static const double filterPadX = 14;

  /// All pill to the inbox card. 08-02 pill ends at y = 504, card border at 540.
  static const double filterGap = 12;

  /// All pill to the Unread pill. 08-02 blue ends at x = 182, Unread border
  /// starts at x = 203.
  static const double filterGapX = 7;

  /// Padding of the empty state. CSS `.empty` is `28px 18px`.
  static const double emptyPadY = 28;
  static const double emptyPadX = 18;

  /// Empty-state circle. CSS `.eic` is 72 px, with a 32 px icon inside.
  static const double emptyCircle = 72;
  static const double emptyIcon = 32;

  /// Circle to the empty-state title. CSS margin-top 14 on a 16 / 800 label.
  static const double emptyTitleGap = 14;

  /// Primary button. CSS height 48.
  static const double buttonHeight = 48;

  /// Horizontal padding of a Replace chip. 08-10 row chips are 186 px wide.
  static const double replacePadX = 9;

  /// Vertical padding of a row Replace chip. 08-10 those chips are 59 px tall.
  static const double replacePadY = 3;

  /// The intro Replace chip inherits the 13 / 1.5 line, so its text box is
  /// 16.5 and the chip is 22.5 with [replacePadY]. It is not a taller pad.
  static const double introLineHeight = 1.5;

  /// Day chip. CSS `padding: 3px 9px` around an 11 / 800 label at [normal].
  static const double dayPadY = 3;

  /// Horizontal padding of the day chip.
  static const double dayPadX = 9;

  /// Edit-field box. 08-03 borders run y = 810–941.
  static const double fieldHeight = 44;

  /// Label to the field box.
  ///
  /// 08-03 a label without a descender ends 24 px above the border. The
  /// 8 dp gap left the border 9 px low on every field.
  static const double labelGap = 5;

  /// Field to the next label. 08-03 mobile border ends, email label follows.
  static const double fieldStack = 12;

  /// Inside a field box, before the value.
  static const double fieldPadX = 12;

  /// Section label to the card under it.
  ///
  /// CSS `margin: 16px 0 8px` on a 15 / 800 label at normal line height.
  /// Adjacent vertical margins collapse, so this is the 8 and [sectionBreak]
  /// is the 16. They are not added.
  static const double sectionGap = 8;

  /// Card to the next section label. The collapsed margin-top of that label.
  static const double sectionBreak = 16;

  /// About seal. CSS 72 px.
  static const double seal = 72;

  /// Seal artwork to the app title.
  ///
  /// The image is inline, so its line box continues 3.67 px past the 72 px
  /// artwork, and the title's margin-top is 8. The gap under the artwork is
  /// 11.67.
  static const double sealGap = 11.67;

  /// Field box to the legal-name note. 08-03 the mobile field, which follows
  /// that note, starts 21 px low when this uses [fieldStack].
  static const double legalGap = 5;

  /// Notice heading to its paragraph. CSS 4 px. The body under it is 13 / 1.5.
  static const double noticeGap = 4;

  /// Header to the draft chip. CSS 18.67 px.
  static const double noticeInset = 18.67;

  /// Draft chip to the notice title. The title's margin-top is 10.
  static const double draftGap = 10;

  /// Empty-state title to the paragraph. CSS `.cs` margin-top is 4.
  static const double emptyBodyGap = 4;

  /// Empty-state body to the button. CSS margin-top 16.
  static const double emptyButtonGap = 16;

  /// Empty-state button to the footnote. CSS margin-top 10.
  static const double emptyNoteGap = 10;

  /// Padding under the version lines. CSS 16 px.
  static const double aboutPadBottom = 16;

  /// Gap between privacy-notice blocks, not after the last one.
  ///
  /// CSS 12 px. With [noticeGap] and a 13 / 1.5 body, each block is 72.67 px.
  static const double blockGap = 12;

  /// Vertical padding of an 08-10 banner row, top and bottom. CSS 6 px.
  /// Titles on those rows are 13 px.
  static const double bannerPadY = 6;

  /// Chrome `line-height: normal` for Plus Jakarta Sans. See the class note.
  static const double normal = 1.26;

  /// The line box Chrome used at the 3× capture.
  ///
  /// Blink rounds the typo ascender and descender to device pixels. A flat
  /// 1.26em is the same number before that rounding; this is the box the DOM
  /// measured (12 → 15, 14 → 17.67, 11 → 13.67).
  static double line(double fontSize) {
    const double ascender = 1038 / 1000;
    const double descender = 222 / 1000;
    final double device = fontSize * 3;
    return ((device * ascender).round() + (device * descender).round()) / 3;
  }

  /// Half-leading stays on the first ascent and the last descent, split
  /// evenly, which is how Chrome builds a `normal` line box.
  static const TextHeightBehavior lineBox = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 12 px inbox preview. CSS `normal`, so each line is 15.
  static const double previewLineHeight = normal;

  /// 13 px notice and version body. CSS `line-height: 1.5` (19.5).
  static const double bodyLineHeight = 1.5;

  /// 13 px thread body. CSS `line-height: 1.45` (18.85).
  static const double threadLineHeight = 1.45;

  /// Kept for the version caption, which is the same 13 / 1.5 body.
  static const double versionLineHeight = bodyLineHeight;

  /// 08-01 name line. 16 px normal is 20.33. The SAMPLE chip is
  /// `vertical-align: middle`, and that inline box measures 22.13.
  static const double profileNameLine = 22.13;

  static StrutStyle strut(
    double size, {
    double? height,
    FontWeight? weight,
  }) {
    return StrutStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height ?? normal,
      leadingDistribution: TextLeadingDistribution.even,
      forceStrutHeight: true,
    );
  }

  /// Chat bubble. CSS padding 10 px by 12 px, max-width 270 px.
  static const double bubblePadY = 10;
  static const double bubblePadX = 12;
  static const double bubbleMaxWidth = 270;

  static const TextStyle preview = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: previewLineHeight,
    color: BrandColors.textSecondary,
    decoration: TextDecoration.none,
  );
}
