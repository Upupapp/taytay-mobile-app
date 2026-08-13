import 'package:flutter/material.dart';

import '../../core/assets/asset_manifest.dart';

/// The palette an illustration paints with.
///
/// Derived from the active [ColorScheme] rather than from fixed hex values, so
/// every scene is correct in light mode, dark mode and high-contrast without a
/// second set of artwork. This is the main reason these are painted rather than
/// shipped as files: a PNG cannot re-colour itself for dark mode, so a file-based
/// pipeline needs two of everything and someone to keep them in step.
@immutable
class IllustrationPalette {
  const IllustrationPalette({
    required this.ink,
    required this.primary,
    required this.primarySoft,
    required this.accent,
    required this.surface,
    required this.surfaceSoft,
  });

  factory IllustrationPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IllustrationPalette(
      ink: scheme.onSurface,
      primary: scheme.primary,
      primarySoft: Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.16),
        scheme.surface,
      ),
      accent: scheme.tertiary,
      surface: scheme.surface,
      surfaceSoft: scheme.surfaceContainerHighest,
    );
  }

  /// Foreground linework.
  final Color ink;
  final Color primary;

  /// A wash of [primary] over the surface — the depth layer.
  final Color primarySoft;
  final Color accent;
  final Color surface;
  final Color surfaceSoft;
}

/// Base for every drawn scene in the app.
///
/// **Announced as an illustration, always.** The accessible name is required to
/// begin with [AssetPolicy.illustrationLabelPrefix], asserted in the
/// constructor. A drawn scene described to a screen-reader user as though it
/// were a photograph of a real office, event or person is a factual claim this
/// app cannot support — and the residents relying on that description are
/// exactly the ones who cannot check it.
///
/// Decorative scenes pass `decorative: true` instead, which hides them from the
/// accessibility tree entirely. That is the right answer for a backdrop: naming
/// it would make a screen reader read out scenery before the content.
class Illustration extends StatelessWidget {
  const Illustration({
    required this.painterBuilder,
    required this.semanticLabel,
    required this.size,
    this.decorative = false,
    super.key,
  });

  /// Builds the painter for the current palette.
  final CustomPainter Function(IllustrationPalette palette) painterBuilder;

  /// Accessible name. Must start with `Illustration:` unless [decorative].
  final String semanticLabel;

  final Size size;

  /// Scenery with no informational content, hidden from assistive technology.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    assert(
      decorative ||
          semanticLabel.startsWith(AssetPolicy.illustrationLabelPrefix),
      'A non-decorative illustration must be announced as one: '
      '"$semanticLabel" should start with '
      '"${AssetPolicy.illustrationLabelPrefix}".',
    );
    assert(
      AssetPolicy.forbiddenLabelClaims.every(
        (claim) => !semanticLabel.toLowerCase().contains(claim),
      ),
      'This app ships no documentary photography; "$semanticLabel" implies it '
      'does.',
    );

    final palette = IllustrationPalette.of(context);
    // RepaintBoundary: a scene is static and often sits beside content that
    // animates or scrolls. Without it, every unrelated repaint repaints the
    // whole illustration.
    final canvas = RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: painterBuilder(palette),
        isComplex: true,
        willChange: false,
      ),
    );

    if (decorative) return ExcludeSemantics(child: canvas);
    return Semantics(label: semanticLabel, image: true, child: canvas);
  }
}

/// Shared painting helpers.
abstract final class IllustrationPainting {
  /// A rounded rectangle in one flat fill.
  static void fillRRect(
    Canvas canvas,
    Rect rect,
    double radius,
    Color color, {
    double opacity = 1,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color.withValues(alpha: color.a * opacity),
    );
  }

  /// A stroked line with rounded caps — the app's linework style.
  static void stroke(
    Canvas canvas,
    Path path,
    Color color,
    double width, {
    double opacity = 1,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: color.a * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Soft depth without a blur filter.
  ///
  /// A real `MaskFilter` blur is expensive on the low-end hardware much of this
  /// audience carries; stacking two translucent offset shapes reads as depth at a
  /// fraction of the cost. This is the Servana softness *principle* rebuilt, not
  /// its artwork.
  static void softStack(
    Canvas canvas,
    Rect rect,
    double radius,
    Color color, {
    double offset = 6,
  }) {
    fillRRect(
      canvas,
      rect.translate(0, offset),
      radius,
      color,
      opacity: 0.18,
    );
    fillRRect(
      canvas,
      rect.translate(0, offset / 2),
      radius,
      color,
      opacity: 0.32,
    );
  }
}
