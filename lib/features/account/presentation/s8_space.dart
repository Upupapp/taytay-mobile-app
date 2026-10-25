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

  /// Horizontal padding of a filter pill. 08-02 All is 134 px wide.
  static const double filterPadX = 16;

  /// All pill to the inbox card. 08-02 pill ends at y = 504, card border at 540.
  static const double filterGap = 12;

  /// All pill to the Unread pill. 08-02 blue ends at x = 182, Unread border
  /// starts at x = 203.
  static const double filterGapX = 7;

  /// Filter to the empty-state mark. 08-06 pill ends at y = 504, mark at 696.
  static const double emptyLead = 64;

  /// Empty-state mark to its title. 08-06 mark ends at y = 768, title ink at 896.
  static const double emptyGap = 43;

  /// Empty-state mark. 08-06 glyph is 72 px.
  static const double emptyMark = 24;

  /// Primary button. 08-06 Message an office is y = 1120–1263.
  static const double buttonHeight = 48;

  /// Extra inset of that button inside the page gutter. 08-06 button x = 102.
  static const double buttonInset = 18;

  /// Replace chip padding. 08-10 row chips are 186×59, with 30 px of amber
  /// beside the word.
  static const double replacePadX = 10;

  /// Vertical padding that keeps the 11/1.2 chip on the 59 px row chip.
  static const double replacePadY = 3;

  /// Edit-field box. 08-03 borders run y = 810–941.
  static const double fieldHeight = 44;

  /// Label to the field box. 08-03 label ink to the border.
  static const double labelGap = 8;

  /// Field to the next label. 08-03 mobile border ends, email label follows.
  static const double fieldStack = 12;

  /// Inside a field box, before the value.
  static const double fieldPadX = 12;

  /// Section label to the card under it. 08-04 Notifications ink to the card.
  static const double sectionGap = 8;

  /// Card to the next section label. 08-04 first card border to App.
  static const double sectionBreak = 24;

  /// About seal. 08-05 seal artwork is y = 416–622.
  static const double seal = 69;

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

  /// 12 px version caption. 08-05 the two lines start 68 px apart.
  static const double versionLineHeight = 1.89;

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
