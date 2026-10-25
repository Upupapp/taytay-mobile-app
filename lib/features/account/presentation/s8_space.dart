import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';

/// Spacing for My Account, taken from the 08 CSS.
///
/// One CSS pixel is one logical pixel here, and three device pixels on the
/// 08 PNGs. A value stays fractional when the CSS computed it that way.
/// `line-height: normal` is an unset [TextStyle.height], not 1.2 or 1.0.
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

  /// Filter to the empty-state mark.
  ///
  /// 08-06 the glyph starts at y = 696. The 24 dp slot draws the glyph 2 dp
  /// below the slot, so the lead is 62.
  static const double emptyLead = 62;

  /// Empty-state mark to its title. 08-06 the title ink starts at y = 896.
  static const double emptyGap = 40;

  /// Empty-state mark. 08-06 glyph is 72 px.
  static const double emptyMark = 24;

  /// Primary button. 08-06 Message an office is y = 1120–1263.
  static const double buttonHeight = 48;

  /// Extra inset of that button inside the page gutter. 08-06 button x = 102.
  static const double buttonInset = 18;

  /// Horizontal padding of a Replace chip. 08-10 row chips are 186 px wide.
  static const double replacePadX = 9;

  /// Vertical padding of a row Replace chip. 08-10 those chips are 59 px tall.
  static const double replacePadY = 3;

  /// Vertical padding of the intro Replace chip. 08-10 that chip is 68 px tall.
  static const double introPadY = 4;

  /// Day chip. CSS `padding: 3px 9px` around a 12 / 700 label at normal height.
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

  /// Seal artwork to the app title. 08-05 the seal ends at y = 622 and the
  /// title ink starts at y = 673.
  static const double sealGap = 15;

  /// Field box to the legal-name note. 08-03 the mobile field, which follows
  /// that note, starts 21 px low when this uses [fieldStack].
  static const double legalGap = 5;

  /// Notice heading to its paragraph. CSS 4 px. The body under it is 13 / 1.5.
  static const double noticeGap = 4;

  /// Header to the draft chip. CSS 18.67 px.
  static const double noticeInset = 18.67;

  /// Draft chip to the notice title. 08-09 the title ink starts at y = 477.
  static const double draftGap = 9;

  /// Empty-state title to the paragraph. 08-06 the paragraph starts at y = 970.
  static const double emptyBodyGap = 3;

  /// Empty-state button to the footnote. 08-06 the footnote starts at y = 1304.
  static const double emptyNoteGap = 11;

  /// Padding under the version lines. CSS 16 px.
  static const double aboutPadBottom = 16;

  /// Gap between privacy-notice blocks, not after the last one.
  ///
  /// CSS 12 px. With [noticeGap] and a 13 / 1.5 body, each block is 72.67 px.
  static const double blockGap = 12;

  /// Vertical padding of an 08-10 banner row, top and bottom. CSS 6 px.
  /// Titles on those rows are 13 px.
  static const double bannerPadY = 6;

  /// 12 px inbox preview. The two preview lines use a 1.5 line height.
  static const double previewLineHeight = 1.5;

  /// 13 px notice body. 08-09 paragraph lines start 59 px apart.
  static const double bodyLineHeight = 1.5;

  /// 13 px thread body. 08-07 office-bubble lines start 56 px apart.
  ///
  /// 08-08 uses the same step. It is not the notice pitch.
  static const double threadLineHeight = 56 / 39;

  /// 12 px version caption. 08-05 the two lines start 59 px apart.
  static const double versionLineHeight = 59 / 36;

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
