import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import 'taytay_glyph.dart';
import 'taytay_icon.dart';

/// The three designed tile sizes (CSS `.gt.sm`, `.gt`, `.gt.lg`).
enum IconTileSize {
  small(ComponentSizes.tileSmall, Radii.tileSmall, 18),
  medium(ComponentSizes.tile, Radii.tile, 22),
  large(ComponentSizes.tileLarge, Radii.tileLarge, 28);

  const IconTileSize(this.dimension, this.radius, this.glyphSize);

  final double dimension;
  final double radius;
  final double glyphSize;
}

/// Coloured disc or rounded tile behind an icon.
///
/// **New code uses [IconTile.glyph]**: the redesign's gradient tile (one of
/// six [TileTone]s at 135°) with a solid [TaytayGlyph], white on every tone
/// but gold, which carries navy.
///
/// The default constructor is the earlier flat tile with a Lucide icon. It
/// stays so screens not yet redesigned keep drawing what they drew.
class IconTile extends StatelessWidget {
  const IconTile({
    required IconData this.icon,
    required Color this.fill,
    required Color this.ink,
    this.size = 40,
    this.iconSize,
    this.radius,
    super.key,
  }) : glyph = null,
       tone = TileTone.blue,
       tileSize = null,
       semanticLabel = null;

  /// The gradient tile with a solid glyph (CSS `.gt`).
  ///
  /// Decorative unless [semanticLabel] is given: a tile nearly always sits
  /// beside a title that names the same thing.
  const IconTile.glyph({
    required TaytayGlyph this.glyph,
    this.tone = TileTone.blue,
    IconTileSize this.tileSize = IconTileSize.medium,
    this.semanticLabel,
    super.key,
  }) : icon = null,
       fill = null,
       ink = null,
       size = 0,
       iconSize = null,
       radius = null;

  /// The gradient tile with a Lucide [icon], for something no solid glyph
  /// names (a lock, an inbox, a bell). Same sizes, tones and semantics as
  /// [IconTile.glyph].
  const IconTile.lucide({
    required IconData this.icon,
    this.tone = TileTone.blue,
    IconTileSize this.tileSize = IconTileSize.medium,
    this.semanticLabel,
    super.key,
  }) : glyph = null,
       fill = null,
       ink = null,
       size = 0,
       iconSize = null,
       radius = null;

  final IconData? icon;
  final Color? fill;
  final Color? ink;
  final double size;
  final double? iconSize;

  /// Null paints a circle. A value paints a rounded square.
  final double? radius;

  final TaytayGlyph? glyph;
  final TileTone tone;
  final IconTileSize? tileSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final IconTileSize? tileSize = this.tileSize;
    if (tileSize != null) return _gradientTile(tileSize);
    return _flatTile();
  }

  Widget _gradientTile(IconTileSize tileSize) {
    final BrandGradient gradient = BrandGradients.tile(tone);
    final TaytayGlyph? glyph = this.glyph;
    final Widget tile = Container(
      width: tileSize.dimension,
      height: tileSize.dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient.toLinearGradient(),
        borderRadius: BorderRadius.circular(tileSize.radius),
      ),
      child: glyph != null
          ? GlyphIcon(glyph, size: tileSize.glyphSize, color: gradient.onColor)
          : TaytayIcon(
              icon: icon ?? Icons.circle,
              semanticLabel: '',
              excludeSemantics: true,
              size: tileSize.glyphSize * 0.86,
              color: gradient.onColor,
            ),
    );
    final String? label = semanticLabel;
    if (label == null || label.isEmpty) return ExcludeSemantics(child: tile);
    return Semantics(label: label, image: true, child: tile);
  }

  Widget _flatTile() {
    final double? corner = radius;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: corner == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: corner == null ? null : BorderRadius.circular(corner),
      ),
      child: TaytayIcon(
        icon: icon ?? Icons.circle,
        semanticLabel: '',
        excludeSemantics: true,
        size: iconSize ?? size * 0.46,
        color: ink,
      ),
    );
  }
}
