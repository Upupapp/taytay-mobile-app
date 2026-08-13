import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import 'illustration.dart';

/// A wide informational strip — "verify your account", "your ID is ready".
///
/// Distinct from `AppBanner`, which is an inline *message* about the content
/// beside it. This is a promotional surface: a gradient, a painted motif, a
/// headline and an optional action.
///
/// The motif is painted, not a shipped image, so the banner can span any width
/// without a set of density variants, and its colours come from the gradient it
/// sits on rather than from baked-in pixels.
///
/// **Contrast is inherited, not guessed.** [BrandGradientSurface] supplies the
/// gradient's contrast-proved `onColor` to the subtree, so the headline is
/// legible at every point along the ramp — proved in `brand_test.dart` by
/// sampling interpolated midpoints, not just the endpoints.
class FeatureBanner extends StatelessWidget {
  const FeatureBanner({
    required this.title,
    this.message,
    this.action,
    this.gradient = BrandGradients.brand,
    this.motif = BannerMotif.horizon,
    this.onTap,
    super.key,
  });

  final String title;
  final String? message;

  /// Trailing action, typically an `AppButton`.
  final Widget? action;

  final BrandGradient gradient;
  final BannerMotif motif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(Radii.lg);

    final content = Stack(
      children: <Widget>[
        // The motif sits behind the copy and is hidden from assistive
        // technology: it carries no information the text does not.
        Positioned.fill(
          child: ExcludeSemantics(
            child: Illustration(
              size: Size.infinite,
              decorative: true,
              semanticLabel: '',
              painterBuilder: (palette) =>
                  _BannerMotifPainter(motif, gradient.onColor),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: gradient.onColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: Spacing.xs),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: gradient.onColor.withValues(alpha: 0.92),
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            ],
          ),
        ),
      ],
    );

    return ClipRRect(
      borderRadius: radius,
      child: BrandGradientSurface(
        gradient: gradient,
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
  }
}

/// Which decorative motif a banner carries.
enum BannerMotif {
  /// Layered horizon bands — the lakeshore abstraction used across the app.
  horizon,

  /// Concentric arcs radiating from the trailing edge.
  arcs,

  /// A quiet grid of dots.
  dots,
}

class _BannerMotifPainter extends CustomPainter {
  const _BannerMotifPainter(this.motif, this.onColor);

  final BannerMotif motif;

  /// The gradient's foreground; the motif is drawn as a low-opacity tint of it,
  /// so it can never compete with the headline for contrast.
  final Color onColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = onColor.withValues(alpha: 0.10);

    switch (motif) {
      case BannerMotif.horizon:
        final band = Path()
          ..moveTo(w * 0.45, h)
          ..quadraticBezierTo(w * 0.68, h * 0.42, w, h * 0.58)
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(band, paint);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.62, h)
            ..quadraticBezierTo(w * 0.82, h * 0.60, w, h * 0.76)
            ..lineTo(w, h)
            ..close(),
          Paint()..color = onColor.withValues(alpha: 0.08),
        );
      case BannerMotif.arcs:
        for (var i = 1; i <= 3; i++) {
          canvas.drawCircle(
            Offset(w * 1.02, h * 0.5),
            h * (0.34 * i),
            Paint()
              ..color = onColor.withValues(alpha: 0.09)
              ..style = PaintingStyle.stroke
              ..strokeWidth = h * 0.045,
          );
        }
      case BannerMotif.dots:
        const spacing = 22.0;
        for (var y = spacing; y < h; y += spacing) {
          for (var x = w * 0.55; x < w; x += spacing) {
            canvas.drawCircle(Offset(x, y), 1.8, paint);
          }
        }
    }
  }

  @override
  bool shouldRepaint(_BannerMotifPainter oldDelegate) =>
      oldDelegate.motif != motif || oldDelegate.onColor != onColor;
}
