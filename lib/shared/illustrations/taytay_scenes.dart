import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'illustration.dart';

/// Onboarding and background scenes.
///
/// **Original geometric compositions, drawn in Flutter.** They evoke Taytay
/// through place and civic function — the Laguna de Bay lakeshore and the hills
/// behind the town, a municipal building, a service counter, an ID card — and
/// they contain **no municipal seal, no coat of arms and no element derived from
/// one**. TAB 03 established that the seal is absent until verified artwork is
/// supplied; that ruling covers redrawing and stylising it too, so none of these
/// scenes gestures at it.
///
/// Nothing here is traced from or based on ServanaClientAPP artwork. What
/// carried over is composition technique — layered depth, restrained palette,
/// soft stacked shapes instead of blur.
abstract final class TaytayScenes {
  /// Scene 1 — services. A municipal building with a service counter.
  static Widget services({double height = 200, Key? key}) => Illustration(
    key: key,
    size: Size.infinite,
    semanticLabel:
        'Illustration: a municipal building with a service counter, '
        'representing Taytay LGU services.',
    painterBuilder: _ServicesScenePainter.new,
  ).sized(height);

  /// Scene 2 — the digital ID.
  static Widget digitalId({double height = 200, Key? key}) => Illustration(
    key: key,
    size: Size.infinite,
    semanticLabel:
        'Illustration: a resident identification card shown on a phone.',
    painterBuilder: _DigitalIdScenePainter.new,
  ).sized(height);

  /// Scene 3 — privacy. A shield over a document.
  static Widget privacy({double height = 200, Key? key}) => Illustration(
    key: key,
    size: Size.infinite,
    semanticLabel:
        'Illustration: a shield protecting a document, representing the '
        'privacy of resident information.',
    painterBuilder: _PrivacyScenePainter.new,
  ).sized(height);

  /// Decorative backdrop — the lakeshore horizon and hills.
  ///
  /// Hidden from assistive technology: it is scenery, and naming it would make a
  /// screen reader announce landscape before the content on top of it.
  static Widget horizonBackdrop({double height = 160, Key? key}) =>
      Illustration(
        key: key,
        size: Size.infinite,
        decorative: true,
        semanticLabel: '',
        painterBuilder: _HorizonPainter.new,
      ).sized(height);
}

extension on Illustration {
  /// Constrains an infinitely-sized illustration to a height and full width.
  Widget sized(double height) =>
      SizedBox(height: height, width: double.infinity, child: this);
}

/// A low municipal building behind a service counter.
class _ServicesScenePainter extends CustomPainter {
  const _ServicesScenePainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h) / 10;

    // Depth wash behind everything.
    IllustrationPainting.fillRRect(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.62),
      unit * 1.2,
      palette.primarySoft,
    );

    // Building mass, with its soft stack for depth.
    final building = Rect.fromLTWH(w * 0.22, h * 0.26, w * 0.56, h * 0.44);
    IllustrationPainting.softStack(
      canvas,
      building,
      unit * 0.6,
      palette.primary,
      offset: unit * 0.5,
    );
    IllustrationPainting.fillRRect(
      canvas,
      building,
      unit * 0.6,
      palette.primary,
    );

    // Pediment: a simple triangle, the civic-architecture cue. Deliberately
    // plain — no crest, no seal, no emblem in the tympanum.
    final roof = Path()
      ..moveTo(w * 0.18, h * 0.28)
      ..lineTo(w * 0.5, h * 0.13)
      ..lineTo(w * 0.82, h * 0.28)
      ..close();
    canvas.drawPath(roof, Paint()..color = palette.primary);

    // Columns.
    for (var i = 0; i < 4; i++) {
      final x = w * (0.29 + i * 0.14);
      IllustrationPainting.fillRRect(
        canvas,
        Rect.fromLTWH(x, h * 0.32, unit * 0.42, h * 0.28),
        unit * 0.2,
        palette.surface,
        opacity: 0.85,
      );
    }

    // Counter in front, and two document sheets on it.
    final counter = Rect.fromLTWH(w * 0.14, h * 0.68, w * 0.72, h * 0.12);
    IllustrationPainting.fillRRect(
      canvas,
      counter,
      unit * 0.35,
      palette.accent,
    );
    for (var i = 0; i < 2; i++) {
      IllustrationPainting.fillRRect(
        canvas,
        Rect.fromLTWH(w * (0.24 + i * 0.30), h * 0.62, w * 0.16, h * 0.09),
        unit * 0.2,
        palette.surface,
      );
    }

    // Ground line.
    IllustrationPainting.stroke(
      canvas,
      Path()
        ..moveTo(w * 0.06, h * 0.84)
        ..lineTo(w * 0.94, h * 0.84),
      palette.ink,
      unit * 0.14,
      opacity: 0.20,
    );
  }

  @override
  bool shouldRepaint(_ServicesScenePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// A phone showing an ID card.
class _DigitalIdScenePainter extends CustomPainter {
  const _DigitalIdScenePainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h) / 10;

    IllustrationPainting.fillRRect(
      canvas,
      Rect.fromLTWH(w * 0.10, h * 0.14, w * 0.80, h * 0.70),
      unit * 1.2,
      palette.primarySoft,
    );

    // Phone body.
    final phone = Rect.fromLTWH(w * 0.34, h * 0.16, w * 0.32, h * 0.68);
    IllustrationPainting.softStack(
      canvas,
      phone,
      unit * 0.7,
      palette.ink,
      offset: unit * 0.4,
    );
    IllustrationPainting.fillRRect(canvas, phone, unit * 0.7, palette.ink);
    IllustrationPainting.fillRRect(
      canvas,
      phone.deflate(unit * 0.22),
      unit * 0.55,
      palette.surface,
    );

    // ID card on the screen: a portrait block and three text lines. No seal,
    // no emblem — the card is shown as a layout, not as a credential design.
    final card = Rect.fromLTWH(w * 0.375, h * 0.30, w * 0.25, h * 0.26);
    IllustrationPainting.fillRRect(canvas, card, unit * 0.3, palette.primary);
    IllustrationPainting.fillRRect(
      canvas,
      Rect.fromLTWH(w * 0.395, h * 0.335, w * 0.07, h * 0.09),
      unit * 0.18,
      palette.surface,
      opacity: 0.9,
    );
    for (var i = 0; i < 3; i++) {
      IllustrationPainting.fillRRect(
        canvas,
        Rect.fromLTWH(
          w * 0.475,
          h * (0.345 + i * 0.045),
          w * (0.11 - i * 0.02),
          h * 0.018,
        ),
        unit * 0.1,
        palette.surface,
        opacity: 0.8,
      );
    }

    // A verification tick beside the card.
    final tick = Path()
      ..moveTo(w * 0.40, h * 0.63)
      ..lineTo(w * 0.455, h * 0.685)
      ..lineTo(w * 0.60, h * 0.545);
    IllustrationPainting.stroke(canvas, tick, palette.accent, unit * 0.30);
  }

  @override
  bool shouldRepaint(_DigitalIdScenePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// A shield over a document.
class _PrivacyScenePainter extends CustomPainter {
  const _PrivacyScenePainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h) / 10;

    IllustrationPainting.fillRRect(
      canvas,
      Rect.fromLTWH(w * 0.12, h * 0.16, w * 0.76, h * 0.66),
      unit * 1.2,
      palette.primarySoft,
    );

    // Document behind.
    final doc = Rect.fromLTWH(w * 0.30, h * 0.20, w * 0.34, h * 0.50);
    IllustrationPainting.fillRRect(canvas, doc, unit * 0.35, palette.surface);
    for (var i = 0; i < 4; i++) {
      IllustrationPainting.fillRRect(
        canvas,
        Rect.fromLTWH(
          w * 0.34,
          h * (0.28 + i * 0.09),
          w * (0.26 - (i.isOdd ? 0.08 : 0)),
          h * 0.025,
        ),
        unit * 0.12,
        palette.ink,
        opacity: 0.28,
      );
    }

    // Shield in front. A plain heraldic outline — a common privacy pictogram,
    // and deliberately not a coat of arms: no charges, no quartering, no motto.
    final cx = w * 0.60;
    final cy = h * 0.52;
    final sw = w * 0.26;
    final sh = h * 0.44;
    final shield = Path()
      ..moveTo(cx, cy - sh / 2)
      ..lineTo(cx + sw / 2, cy - sh / 2 + sh * 0.16)
      ..lineTo(cx + sw / 2, cy + sh * 0.10)
      ..quadraticBezierTo(cx + sw / 2, cy + sh / 2, cx, cy + sh / 2)
      ..quadraticBezierTo(cx - sw / 2, cy + sh / 2, cx - sw / 2, cy + sh * 0.10)
      ..lineTo(cx - sw / 2, cy - sh / 2 + sh * 0.16)
      ..close();

    canvas.drawPath(
      shield.shift(Offset(0, unit * 0.35)),
      Paint()..color = palette.primary.withValues(alpha: 0.22),
    );
    canvas.drawPath(shield, Paint()..color = palette.primary);

    // Keyhole.
    canvas.drawCircle(
      Offset(cx, cy - sh * 0.06),
      unit * 0.34,
      Paint()..color = palette.surface,
    );
    IllustrationPainting.fillRRect(
      canvas,
      Rect.fromLTWH(cx - unit * 0.14, cy - sh * 0.02, unit * 0.28, unit * 0.7),
      unit * 0.14,
      palette.surface,
    );
  }

  @override
  bool shouldRepaint(_PrivacyScenePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Lakeshore horizon: layered hills over water.
///
/// Taytay sits on the western shore of Laguna de Bay with the Sierra Madre
/// foothills behind it. The scene is an abstraction of that geography — layered
/// bands, no landmark, no identifiable structure.
class _HorizonPainter extends CustomPainter {
  const _HorizonPainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far ridge.
    final far = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.44, h * 0.56)
      ..quadraticBezierTo(w * 0.66, h * 0.76, w * 0.82, h * 0.50)
      ..quadraticBezierTo(w * 0.92, h * 0.36, w, h * 0.48)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()..color = palette.primary.withValues(alpha: 0.18),
    );

    // Near ridge.
    final near = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.30, h * 0.58, w * 0.58, h * 0.78)
      ..quadraticBezierTo(w * 0.80, h * 0.92, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      near,
      Paint()..color = palette.primary.withValues(alpha: 0.32),
    );

    // Water lines.
    for (var i = 0; i < 3; i++) {
      IllustrationPainting.stroke(
        canvas,
        Path()
          ..moveTo(w * (0.10 + i * 0.06), h * (0.88 + i * 0.035))
          ..lineTo(w * (0.34 + i * 0.10), h * (0.88 + i * 0.035)),
        palette.primary,
        h * 0.018,
        opacity: 0.30,
      );
    }
  }

  @override
  bool shouldRepaint(_HorizonPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
