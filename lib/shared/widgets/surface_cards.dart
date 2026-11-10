import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';

/// The everyday card (CSS `.soft .card`): white, no border, radius 20, no
/// shadow. On a white page (sign-in, registration) pass [filled] for the
/// `#F4F6FA` fill instead.
///
/// With [onTap] the whole card is one target with ink and a focus highlight.
/// Give it a [semanticLabel] then, or it announces as everything inside it.
class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.filled = false,
    this.radius = Radii.card,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool filled;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      decoration: BoxDecoration(
        color: filled ? BrandColors.background : BrandColors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      radius: radius,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

/// The frosted card of the main tabs (CSS `.glass .card`): white 74% → 50%,
/// a 1 px white border at 85%, and the page behind it blurred 18 and
/// saturated 160%. Put it on a [GlassBackground]; on a flat page it is only a
/// paler card. [pinned] draws the gold-tinted variant.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.pinned = false,
    this.radius = Radii.cardLarge,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool pinned;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius corners = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: corners,
      child: BackdropFilter(
        filter: GlassTokens.backdropFilter(),
        child: _CardSurface(
          decoration: BoxDecoration(
            gradient: pinned ? GlassTokens.pinnedFill : GlassTokens.fill,
            borderRadius: corners,
            border: Border.all(
              color: GlassTokens.border,
              width: GlassTokens.borderWidth,
            ),
          ),
          radius: radius,
          padding: padding,
          onTap: onTap,
          semanticLabel: semanticLabel,
          child: child,
        ),
      ),
    );
  }
}

/// The page behind glass cards (CSS `.app.glass`): `#EEF2FA` with three soft
/// colour blobs. Decorative; it carries no semantics.
class GlassBackground extends StatelessWidget {
  const GlassBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GlassBlobPainter(), child: child);
  }
}

class _GlassBlobPainter extends CustomPainter {
  const _GlassBlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GlassTokens.pageColor);
    for (final GlassBlob blob in GlassTokens.pageBlobs) {
      final Offset centre = Offset(
        blob.center.dx * size.width,
        blob.center.dy * size.height,
      );
      final Rect oval = Rect.fromCenter(
        center: centre,
        width: blob.radii.width * 2,
        height: blob.radii.height * 2,
      );
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[blob.color, blob.color.withValues(alpha: 0)],
          stops: const <double>[0, 0.7],
        ).createShader(oval);
      canvas.drawOval(oval, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlassBlobPainter oldDelegate) => false;
}

/// The shared body of both cards: decoration, padding and the optional tap.
///
/// The decoration paints behind a transparent [Material], so ink from a tap
/// shows on the card rather than under it.
class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.decoration,
    required this.radius,
    required this.padding,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final BoxDecoration decoration;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = this.onTap;
    final BorderRadius corners = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      final bool reduced = Motion.reduced(context);
      content = InkWell(
        borderRadius: corners,
        onTap: () {
          unawaited(
            AppHaptics.fire(HapticIntent.selection, suppressed: reduced),
          );
          onTap();
        },
        child: content,
      );
    }
    final Widget card = DecoratedBox(
      decoration: decoration,
      child: Material(type: MaterialType.transparency, child: content),
    );
    final String? label = semanticLabel;
    if (label == null) return card;
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      child: card,
    );
  }
}
