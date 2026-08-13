import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/motion_tokens.dart';
import 'illustration.dart';

/// Artwork for empty, success and error states, and for dialogs.
///
/// Drawn rather than shipped as files, for the same reasons as
/// `TaytayScenes` — and one more that matters here: these appear in both themes
/// on the same screen a resident may be re-reading after a failure, and a
/// baked-in raster would be the one element that stops matching the surface
/// around it.
abstract final class StateIllustrations {
  static Widget empty({double size = 120, Key? key}) => Illustration(
    key: key,
    size: Size.square(size),
    semanticLabel: 'Illustration: an empty tray, meaning there is nothing here '
        'yet.',
    painterBuilder: _EmptyPainter.new,
  );

  static Widget error({double size = 120, Key? key}) => Illustration(
    key: key,
    size: Size.square(size),
    semanticLabel:
        'Illustration: a disconnected link, meaning something could not be '
        'loaded.',
    painterBuilder: _ErrorPainter.new,
  );

  /// Success.
  ///
  /// This is the **only animated illustration in the app**, and the
  /// justification is narrow: the tick draws itself once, over 420 ms, at the
  /// moment a resident's submission is confirmed. Motion here carries meaning —
  /// it marks the transition from "sending" to "done" — which is the test a
  /// decorative loop cannot pass.
  ///
  /// Under reduced motion the completed tick is drawn immediately, with no
  /// travel. It is never looped, and it never replays on rebuild.
  static Widget success({double size = 120, Key? key}) =>
      _AnimatedSuccess(size: size, key: key);
}

class _AnimatedSuccess extends StatefulWidget {
  const _AnimatedSuccess({required this.size, super.key});

  final double size;

  @override
  State<_AnimatedSuccess> createState() => _AnimatedSuccessState();
}

class _AnimatedSuccessState extends State<_AnimatedSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.emphasised,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: jump to the finished state rather than animating to it.
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = IllustrationPalette.of(context);
    return Semantics(
      label: 'Illustration: a check mark, meaning the request was completed.',
      image: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _SuccessPainter(palette, _controller.value),
          ),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  const _SuccessPainter(this.palette, this.progress);

  final IllustrationPalette palette;

  /// 0 → 1, driving how much of the tick has been drawn.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centre = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      centre,
      s * 0.42,
      Paint()..color = palette.primary.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      centre,
      s * 0.32,
      Paint()..color = palette.primary.withValues(alpha: 0.22),
    );

    final tick = Path()
      ..moveTo(centre.dx - s * 0.17, centre.dy + s * 0.01)
      ..lineTo(centre.dx - s * 0.04, centre.dy + s * 0.14)
      ..lineTo(centre.dx + s * 0.19, centre.dy - s * 0.14);

    // Draw only the leading fraction of the stroke, so the tick appears to be
    // written rather than to fade in.
    final metrics = tick.computeMetrics().toList();
    final drawn = Path();
    for (final metric in metrics) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
        Offset.zero,
      );
    }
    IllustrationPainting.stroke(canvas, drawn, palette.primary, s * 0.09);
  }

  @override
  bool shouldRepaint(_SuccessPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.palette != palette;
}

class _EmptyPainter extends CustomPainter {
  const _EmptyPainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h) / 10;

    // Tray.
    final tray = Rect.fromLTWH(w * 0.16, h * 0.46, w * 0.68, h * 0.30);
    IllustrationPainting.softStack(
      canvas,
      tray,
      unit * 0.6,
      palette.ink,
      offset: unit * 0.35,
    );
    IllustrationPainting.fillRRect(
      canvas,
      tray,
      unit * 0.6,
      palette.surfaceSoft,
    );
    IllustrationPainting.stroke(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(tray, Radius.circular(unit * 0.6)),
        ),
      palette.ink,
      unit * 0.14,
      opacity: 0.35,
    );

    // Two sheets resting above it, offset — suggesting "nothing filed yet".
    for (var i = 0; i < 2; i++) {
      IllustrationPainting.fillRRect(
        canvas,
        Rect.fromLTWH(
          w * (0.28 + i * 0.10),
          h * (0.22 + i * 0.08),
          w * 0.34,
          h * 0.16,
        ),
        unit * 0.3,
        palette.surface,
        opacity: 0.9 - i * 0.25,
      );
    }
  }

  @override
  bool shouldRepaint(_EmptyPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _ErrorPainter extends CustomPainter {
  const _ErrorPainter(this.palette);

  final IllustrationPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h) / 10;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      math.min(w, h) * 0.40,
      Paint()..color = palette.ink.withValues(alpha: 0.07),
    );

    // A broken link: two rounded segments with a gap between them.
    final left = Rect.fromLTWH(w * 0.20, h * 0.42, w * 0.26, h * 0.16);
    final right = Rect.fromLTWH(w * 0.54, h * 0.42, w * 0.26, h * 0.16);
    IllustrationPainting.fillRRect(
      canvas,
      left,
      unit * 0.8,
      palette.ink,
      opacity: 0.55,
    );
    IllustrationPainting.fillRRect(
      canvas,
      right,
      unit * 0.8,
      palette.ink,
      opacity: 0.55,
    );

    // The break, drawn as two short diverging strokes.
    for (final direction in <int>[-1, 1]) {
      IllustrationPainting.stroke(
        canvas,
        Path()
          ..moveTo(w * 0.50, h * (0.50 + 0.06 * direction))
          ..lineTo(w * 0.50, h * (0.50 + 0.16 * direction)),
        palette.ink,
        unit * 0.16,
        opacity: 0.40,
      );
    }
  }

  @override
  bool shouldRepaint(_ErrorPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
