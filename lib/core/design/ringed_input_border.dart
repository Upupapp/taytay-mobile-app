import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// An [OutlineInputBorder] that can also paint a focus ring outside itself.
///
/// The redesign's focused field is a white fill, a 1.5 px blue border and a
/// 3 px ring of blue at 14% *outside* the border (CSS `outline: 3px solid …;
/// outline-offset: 0`). [InputDecorationTheme] has one border per state and no
/// ring, so the ring is painted here, around the border's outer edge.
///
/// The ring overhangs the field by [ring]'s width. A parent that clips right
/// at the field's edge (a zero-padding scroll view) clips the ring with it.
class RingedInputBorder extends OutlineInputBorder {
  const RingedInputBorder({
    super.borderSide,
    super.borderRadius = const BorderRadius.all(Radius.circular(Radii.field)),
    super.gapPadding,
    this.ring = BorderSide.none,
  });

  /// Painted outside the border at its own width. [BorderSide.none] paints
  /// nothing.
  final BorderSide ring;

  @override
  RingedInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    BorderSide? ring,
  }) {
    return RingedInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
      ring: ring ?? this.ring,
    );
  }

  @override
  RingedInputBorder scale(double t) {
    return RingedInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
      ring: ring.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RingedInputBorder) {
      return _lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RingedInputBorder) {
      return _lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  static RingedInputBorder _lerp(
    RingedInputBorder a,
    RingedInputBorder b,
    double t,
  ) {
    return RingedInputBorder(
      borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
      borderRadius:
          BorderRadius.lerp(a.borderRadius, b.borderRadius, t) ??
          b.borderRadius,
      gapPadding: a.gapPadding + (b.gapPadding - a.gapPadding) * t,
      ring: BorderSide.lerp(a.ring, b.ring, t),
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (ring.style != BorderStyle.none && ring.width > 0) {
      final RRect outer = borderRadius.toRRect(rect);
      canvas.drawRRect(outer.inflate(ring.width / 2), ring.toPaint());
    }
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RingedInputBorder &&
        other.borderSide == borderSide &&
        other.borderRadius == borderRadius &&
        other.gapPadding == gapPadding &&
        other.ring == ring;
  }

  @override
  int get hashCode => Object.hash(borderSide, borderRadius, gapPadding, ring);
}
