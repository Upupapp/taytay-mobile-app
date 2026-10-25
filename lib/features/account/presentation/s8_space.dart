import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';

/// Spacing for My Account, measured from the 08 frames at 3×.
///
/// One logical pixel in the app is 3 device pixels on those PNGs. Each value
/// is a whole dp taken from a repeating role, and every row of that role uses
/// it. The frame cited on each token is where the distance was read.
abstract final class S8Space {
  /// Page inset. 08-01 card border sits at x = 48.
  static const double gutter = 16;

  /// Card padding, and the inset of a row hairline.
  ///
  /// 08-01 tiles and hairlines run x = 99–1070, which is [gutter] plus the
  /// 1 dp card stroke plus 16.
  static const double cardPad = 16;

  /// Vertical padding of the profile card. 08-01 the name ink starts 65 px
  /// under the border, one dp more than [cardPad] once the line box is counted.
  static const double profilePadY = 17;

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

  /// Thread inset under the header, down to the day chip.
  ///
  /// 08-07 header ends at y = 362 and the day chip fill starts at y = 431.
  static const double threadInset = 23;

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

  /// Extra inset at the top and bottom of a card of tile rows.
  ///
  /// 08-01 the first tile starts 45 px under the card border. [rowPadY] is
  /// 36 px, and the same 9 px remains under the last tile. 08-04 matches.
  static const double cardInsetY = 3;

  /// Tile to the row title. 08-04 the tile ends at x = 231 and the title ink
  /// starts at x = 270.
  static const double iconGap = 13;

  /// Title line to the meta line under it.
  ///
  /// 08-01 title ink starts at y = 774 and the subtitle at y = 832, the 14/1.2
  /// line plus 2 dp. 08-10 title ink to byline ink is the same step.
  static const double titleGap = 2;

  /// 1 dp hairline. 08-01 divider is y = 917–919, #EEF1F6.
  static const double divider = 1;

  /// Filter pill. 08-02 All is y = 396–503.
  static const double filterHeight = 36;

  /// Horizontal padding of a filter pill.
  ///
  /// 08-02 Unread is 205 px wide and the word is 123 px, 41 px on each side.
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

  /// Vertical padding of the thread day chip. 08-07 the chip is 59 px tall
  /// around a 12 px label.
  static const double dayPadY = 2;

  /// Horizontal padding of the day chip. 08-07 the chip is 126 px wide.
  static const double dayPadX = 8;

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

  /// Section label to the card under it. 08-04 Notifications ink to the card.
  static const double sectionGap = 8;

  /// Card to the next section label.
  ///
  /// 08-04 the first card border ends at y = 1074 and App starts at y = 1139.
  /// 24 dp left the next card 21 px low once the card itself was the right height.
  static const double sectionBreak = 17;

  /// About seal. 08-05 seal artwork is y = 416–622.
  static const double seal = 69;

  /// Seal artwork to the app title. 08-05 the seal ends at y = 622 and the
  /// title ink starts at y = 673.
  static const double sealGap = 15;

  /// Field box to the legal-name note. 08-03 the mobile field, which follows
  /// that note, starts 21 px low when this uses [fieldStack].
  static const double legalGap = 5;

  /// Notice heading to its paragraph. 08-09 section titles start 218 px apart.
  static const double noticeGap = 8;

  /// Header to the draft chip. 08-09 the chip starts at y = 368, 57 px under
  /// the header, while other pages use [pagePad].
  static const double noticeInset = 19;

  /// Draft chip. 08-09 the amber chip is y = 368–426.
  static const double draftChip = 20;

  /// Draft chip to the notice title. 08-09 the title ink starts at y = 477.
  static const double draftGap = 9;

  /// Empty-state title to the paragraph. 08-06 the paragraph starts at y = 970.
  static const double emptyBodyGap = 3;

  /// Empty-state button to the footnote. 08-06 the footnote starts at y = 1304.
  static const double emptyNoteGap = 11;

  /// Padding under the version lines. 08-05 the version ink ends at y = 830
  /// and the card border at y = 886.
  static const double aboutPadBottom = 19;

  /// Gap between privacy-notice blocks, not after the last one.
  ///
  /// 08-09 the section titles start 218 px apart. 12 dp made each step 4 px long.
  static const double blockGap = 11;

  /// 14 px titles. 08-01 and 08-10 line step.
  static const double titleLineHeight = 1.2;

  /// 12 px single-line meta and bylines. 08-10 byline step is 45 px.
  static const double metaLineHeight = 1.2;

  /// 12 px inbox preview. 08-02 the two preview lines start 53 px apart.
  static const double previewLineHeight = 1.5;

  /// 13 px notice body. 08-09 paragraph lines start 59 px apart.
  static const double bodyLineHeight = 1.5;

  /// 13 px thread body. 08-07 office-bubble lines start 56 px apart.
  ///
  /// 08-08 uses the same step. It is not the notice pitch.
  static const double threadLineHeight = 56 / 39;

  /// 12 px version caption. 08-05 the two lines start 59 px apart.
  static const double versionLineHeight = 59 / 36;

  /// 11 px Replace label.
  static const double chipLineHeight = 1.2;

  static const TextStyle preview = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: previewLineHeight,
    color: BrandColors.textSecondary,
    decoration: TextDecoration.none,
  );
}
