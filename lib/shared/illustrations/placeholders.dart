import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import 'illustration.dart';

/// Stand-in artwork for remote images that have not loaded, failed, or were
/// never supplied.
///
/// **Why a drawn placeholder rather than a shipped "no image" PNG.** It costs no
/// install bytes, it takes the surface colour of whichever theme is active, and
/// it scales to any aspect ratio without a second file. It is also never
/// mistaken for content: a flat geometric motif reads as "nothing here", where a
/// grey photograph-shaped rectangle reads as a photograph that failed.
///
/// Every placeholder reserves its final size, so content does not reflow when
/// the real image arrives — the layout shift that moves a resident's thumb
/// mid-tap.
abstract final class ImagePlaceholders {
  /// Aspect ratio for an event poster. Portrait, matching printed LGU notices.
  static const double eventPosterAspect = 3 / 4;

  /// Aspect ratio for a newsfeed image.
  static const double newsfeedAspect = 16 / 9;

  /// Event poster placeholder.
  static Widget eventPoster({Key? key, double? width}) => _Placeholder(
    key: key,
    aspectRatio: eventPosterAspect,
    width: width,
    semanticLabel:
        'Illustration: a placeholder for an event notice that has not loaded.',
    motif: _PlaceholderMotif.poster,
  );

  /// Newsfeed image placeholder.
  static Widget newsfeed({Key? key, double? width}) => _Placeholder(
    key: key,
    aspectRatio: newsfeedAspect,
    width: width,
    semanticLabel:
        'Illustration: a placeholder for a news image that has not loaded.',
    motif: _PlaceholderMotif.newsfeed,
  );

  /// Square avatar placeholder, e.g. an office or a service.
  static Widget square({Key? key, double size = 56}) => _Placeholder(
    key: key,
    aspectRatio: 1,
    width: size,
    semanticLabel: 'Illustration: a placeholder image.',
    motif: _PlaceholderMotif.square,
  );
}

enum _PlaceholderMotif { poster, newsfeed, square }

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.aspectRatio,
    required this.semanticLabel,
    required this.motif,
    this.width,
    super.key,
  });

  final double aspectRatio;
  final String semanticLabel;
  final _PlaceholderMotif motif;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final illustration = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Illustration(
          size: Size.infinite,
          semanticLabel: semanticLabel,
          painterBuilder: (palette) => _PlaceholderPainter(palette, motif),
        ),
      ),
    );

    return width == null
        ? illustration
        : SizedBox(width: width, child: illustration);
  }
}

class _PlaceholderPainter extends CustomPainter {
  const _PlaceholderPainter(this.palette, this.motif);

  final IllustrationPalette palette;
  final _PlaceholderMotif motif;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = size.shortestSide / 10;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = palette.surfaceSoft,
    );

    switch (motif) {
      case _PlaceholderMotif.poster:
        // A sheet with a heading bar and text lines — a notice, not a photo.
        IllustrationPainting.fillRRect(
          canvas,
          Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.60, h * 0.10),
          unit * 0.25,
          palette.primary,
          opacity: 0.40,
        );
        for (var i = 0; i < 4; i++) {
          IllustrationPainting.fillRRect(
            canvas,
            Rect.fromLTWH(
              w * 0.20,
              h * (0.36 + i * 0.11),
              w * (0.60 - (i.isOdd ? 0.18 : 0)),
              h * 0.05,
            ),
            unit * 0.2,
            palette.ink,
            opacity: 0.18,
          );
        }
      case _PlaceholderMotif.newsfeed:
        // Horizon bands — abstract scenery, clearly not a photograph.
        final band = Path()
          ..moveTo(0, h * 0.72)
          ..quadraticBezierTo(w * 0.28, h * 0.48, w * 0.54, h * 0.70)
          ..quadraticBezierTo(w * 0.78, h * 0.88, w, h * 0.62)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(
          band,
          Paint()..color = palette.primary.withValues(alpha: 0.26),
        );
        canvas.drawCircle(
          Offset(w * 0.76, h * 0.28),
          unit * 0.9,
          Paint()..color = palette.primary.withValues(alpha: 0.30),
        );
      case _PlaceholderMotif.square:
        canvas.drawCircle(
          Offset(w / 2, h * 0.42),
          size.shortestSide * 0.16,
          Paint()..color = palette.primary.withValues(alpha: 0.32),
        );
        IllustrationPainting.fillRRect(
          canvas,
          Rect.fromLTWH(w * 0.22, h * 0.62, w * 0.56, h * 0.16),
          unit * 0.4,
          palette.primary,
          opacity: 0.24,
        );
    }
  }

  @override
  bool shouldRepaint(_PlaceholderPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.motif != motif;
}
