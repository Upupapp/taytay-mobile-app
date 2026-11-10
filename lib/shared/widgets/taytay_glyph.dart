import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';

/// One solid icon from the redesign set, in one colour.
///
/// Decorative by default, because the icon nearly always sits beside words that
/// already say the same thing. Pass [semanticLabel] when it stands alone.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(
    this.glyph, {
    this.size = 22,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final TaytayGlyph glyph;
  final double size;

  /// Defaults to the ambient [IconTheme] colour.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color paint = color ?? IconTheme.of(context).color ?? BrandColors.ink;
    final Widget picture = SvgPicture.asset(
      glyph.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(paint, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
    final String? label = semanticLabel;
    if (label == null || label.isEmpty) {
      return ExcludeSemantics(child: picture);
    }
    return Semantics(label: label, image: true, child: picture);
  }
}

/// One of the two empty-state illustrations, at its designed 168 × 132.
///
/// Always decorative: the state's title says what the picture shows.
class IllustrationArt extends StatelessWidget {
  const IllustrationArt(this.illustration, {this.width, super.key});

  final TaytayIllustration illustration;

  /// Scales the art down on a narrow layout. Defaults to the designed width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final double w = width ?? TaytayIllustration.width;
    return ExcludeSemantics(
      child: SvgPicture.asset(
        illustration.assetPath,
        width: w,
        height: w * TaytayIllustration.height / TaytayIllustration.width,
        excludeFromSemantics: true,
      ),
    );
  }
}
