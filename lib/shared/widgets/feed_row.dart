import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import '../../core/design/typography.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import 'taytay_glyph.dart';

/// The colour of a feed row's category line (Balita: ABISO green, ADVISORY
/// blue, NEGOSYO gold, SAFETY red, anything else neutral). Each clears 4.5:1
/// on white.
enum CategoryTone {
  blue(BrandColors.blue),
  green(BrandColors.green),
  gold(BrandColors.goldInk),
  red(BrandColors.redInk),
  neutral(BrandColors.text);

  const CategoryTone(this.color);

  final Color color;
}

/// One story in a list (CSS `.row` on Balita): the category line, a bold
/// title, a date, and a 76 px thumbnail on the right.
///
/// Everything is data from the caller: [category] is upper-cased by the
/// caller (it is shown as given), [dateLabel] is already formatted (e.g.
/// `ManilaTime.formatDate`), and [thumbnail] is the caller's image widget,
/// usually a `RemoteImage`. With no thumbnail, [placeholderGlyph] draws a sky
/// tile; with neither, the text runs the full width.
///
/// [divider] draws the hairline above every row but the first.
class FeedRow extends StatelessWidget {
  const FeedRow({
    required this.title,
    this.category,
    this.categoryTone = CategoryTone.blue,
    this.dateLabel,
    this.thumbnail,
    this.placeholderGlyph,
    this.onTap,
    this.divider = false,
    this.titleMaxLines,
    super.key,
  });

  final String title;
  final String? category;
  final CategoryTone categoryTone;
  final String? dateLabel;
  final Widget? thumbnail;
  final TaytayGlyph? placeholderGlyph;
  final VoidCallback? onTap;
  final bool divider;

  /// Null shows the whole title; the list grows rather than cutting words.
  final int? titleMaxLines;

  static const double thumbnailSize = 76;

  @override
  Widget build(BuildContext context) {
    final String? category = this.category;
    final String? dateLabel = this.dateLabel;
    final int? maxLines = titleMaxLines;
    final Widget? thumb = _thumbnail();
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.xs),
                    child: Text(
                      category,
                      style: AppTypography.category.copyWith(
                        color: categoryTone.color,
                      ),
                    ),
                  ),
                Text(
                  title,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: AppTypography.listTitle.copyWith(
                    fontWeight: AppTypography.strong,
                    color: BrandColors.ink,
                  ),
                ),
                if (dateLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: Text(
                      dateLabel,
                      style: AppTypography.small.copyWith(
                        fontWeight: AppTypography.medium,
                        color: BrandColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (thumb != null) ...<Widget>[const SizedBox(width: 14), thumb],
        ],
      ),
    );

    final VoidCallback? onTap = this.onTap;
    Widget content = row;
    if (onTap != null) {
      final bool reduced = Motion.reduced(context);
      content = InkWell(
        onTap: () {
          unawaited(
            AppHaptics.fire(HapticIntent.selection, suppressed: reduced),
          );
          onTap();
        },
        child: row,
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: divider
                ? Border(
                    top: BorderSide(
                      color: BrandColors.ink.withValues(alpha: 0.07),
                    ),
                  )
                : null,
          ),
          child: content,
        ),
      ),
    );
  }

  Widget? _thumbnail() {
    final Widget? thumbnail = this.thumbnail;
    final TaytayGlyph? glyph = placeholderGlyph;
    if (thumbnail != null) {
      return ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(dimension: thumbnailSize, child: thumbnail),
        ),
      );
    }
    if (glyph == null) return null;
    final BrandGradient sky = BrandGradients.tile(TileTone.sky);
    return ExcludeSemantics(
      child: Container(
        width: thumbnailSize,
        height: thumbnailSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: sky.toLinearGradient(),
          borderRadius: BorderRadius.circular(16),
        ),
        child: GlyphIcon(glyph, size: 28, color: sky.onColor),
      ),
    );
  }
}
