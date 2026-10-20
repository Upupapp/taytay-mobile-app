import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// A Lucide glyph with a required screen-reader label.
///
/// The label is not optional. An icon that only means something by its picture
/// fails the moment a resident cannot see it, and a default of "icon" would
/// hide that. Decorative uses pass an empty label and [excludeSemantics].
class TaytayIcon extends StatelessWidget {
  const TaytayIcon({
    required this.icon,
    required this.semanticLabel,
    this.size = IconSizes.md,
    this.color,
    this.excludeSemantics = false,
    super.key,
  });

  final IconData icon;

  /// What the glyph means. Empty only when [excludeSemantics] is true.
  final String semanticLabel;

  final double size;
  final Color? color;
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    assert(
      semanticLabel.isNotEmpty || excludeSemantics,
      'TaytayIcon needs a semanticLabel, or excludeSemantics for decoration.',
    );
    final glyph = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: excludeSemantics ? null : semanticLabel,
    );
    if (!excludeSemantics) return glyph;
    return ExcludeSemantics(child: glyph);
  }
}
