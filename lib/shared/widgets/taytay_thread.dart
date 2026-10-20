import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/motion/motion_tokens.dart';

/// One cubic of the welcome thread.
///
/// The exit height of page *n* is the entry height of page *n+1*, so a swipe
/// reads as one continuous stitch. Pages use `Y=[200,300,170,260]`. Sign-in
/// continues from near the page-3 exit.
@immutable
class ThreadCurve {
  const ThreadCurve(this.entryY, this.exitY);

  final double entryY;
  final double exitY;

  Path toPath() => Path()
    ..moveTo(-2, entryY)
    ..cubicTo(130, entryY, 260, exitY, 392, exitY);

  static const List<ThreadCurve> pages = <ThreadCurve>[
    ThreadCurve(200, 300),
    ThreadCurve(300, 170),
    ThreadCurve(170, 260),
  ];

  /// Entry 250, close to the page-3 exit at 260.
  static const ThreadCurve signIn = ThreadCurve(250, 180);
}

/// Passed as `go_router` extra when Get started opens Sign-in.
///
/// The sign-in screen draws this once, then drops it. Reduced motion does not
/// send it.
@immutable
class WelcomeThreadArrival {
  const WelcomeThreadArrival();
}

/// Stitched gold thread: shadow, gold, and a thin highlight.
class ThreadPainter extends CustomPainter {
  const ThreadPainter(this.curve);

  final ThreadCurve curve;

  @override
  void paint(Canvas canvas, Size size) {
    paintThread(canvas, curve.toPath());
  }

  @override
  bool shouldRepaint(covariant ThreadPainter oldDelegate) =>
      oldDelegate.curve != curve;
}

/// Draws the three thread strokes. Shared by the pages and the sign-in carry.
void paintThread(Canvas canvas, Path path) {
  final shadow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x47503700)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
  canvas.save();
  canvas.translate(0.8, 1.6);
  _dash(canvas, path, shadow);
  canvas.restore();

  final gold = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = BrandColors.threadGold;
  _dash(canvas, path, gold);

  final highlight = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xBFFFF0BE);
  canvas.save();
  canvas.translate(-0.3, -0.5);
  _dash(canvas, path, highlight);
  canvas.restore();
}

void _dash(Canvas canvas, Path path, Paint paint) {
  const dash = 8.0;
  const gap = 6.0;
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dash, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }
}

/// Point at [t] along [curve], from 0 at the entry to 1 at the exit.
Offset pointOnThread(ThreadCurve curve, double t) {
  final metric = curve.toPath().computeMetrics().first;
  final tangent = metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));
  return tangent?.position ?? Offset(-2, curve.entryY);
}

/// The glowing speck at the thread tip.
class TravellingLight extends StatelessWidget {
  const TravellingLight({required this.curve, required this.t, super.key});

  static const Key mark = Key('welcome-travelling-light');

  final ThreadCurve curve;

  /// 0 at the entry, 1 at the exit.
  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: mark,
        painter: _LightPainter(curve, t),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LightPainter extends CustomPainter {
  const _LightPainter(this.curve, this.t);

  final ThreadCurve curve;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = pointOnThread(curve, t);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = BrandColors.sealGold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      4.5,
      Paint()
        ..color = BrandColors.sealGold.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 4.5, Paint()..color = BrandColors.speckCore);
  }

  @override
  bool shouldRepaint(covariant _LightPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.curve != curve;
}

/// Page dots drawn as knots on the thread.
///
/// Pages 1 and 2 put the knots on the canvas at y 792. Page 3 puts them in
/// the copy block, which is what `w3.html` does.
class KnotIndicator extends StatelessWidget {
  const KnotIndicator({
    required this.active,
    required this.label,
    this.inline = false,
    super.key,
  });

  /// Zero-based active page.
  final int active;

  final String label;

  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _KnotPainter(active: active, inline: inline),
          child: SizedBox(width: inline ? 338 : 390, height: inline ? 22 : 844),
        ),
      ),
    );
  }
}

class _KnotPainter extends CustomPainter {
  const _KnotPainter({required this.active, required this.inline});

  final int active;
  final bool inline;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Path();
    final centers = <Offset>[];
    if (inline) {
      line
        ..moveTo(107, 11)
        ..lineTo(231, 11);
      centers.addAll(const <Offset>[
        Offset(124, 11),
        Offset(169, 11),
        Offset(214, 11),
      ]);
    } else {
      line
        ..moveTo(38, 792)
        ..lineTo(162, 792);
      centers.addAll(const <Offset>[
        Offset(55, 792),
        Offset(100, 792),
        Offset(145, 792),
      ]);
    }
    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = BrandColors.threadGold;
    _dash(canvas, line, stitch);
    for (var i = 0; i < centers.length; i++) {
      final center = centers[i];
      if (i == active) {
        canvas.drawCircle(center, 8, Paint()..color = BrandColors.taytayBlue);
        canvas.drawCircle(center, 3, Paint()..color = BrandColors.sealGold);
      } else {
        canvas.drawCircle(center, 5, Paint()..color = BrandColors.surface);
        canvas.drawCircle(
          center,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = BrandColors.taytayBlue,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KnotPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.inline != inline;
}

/// Draws the sign-in continuation, then removes itself.
class SignInThreadOverlay extends StatefulWidget {
  const SignInThreadOverlay({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<SignInThreadOverlay> createState() => _SignInThreadOverlayState();
}

class _SignInThreadOverlayState extends State<SignInThreadOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: MotionTokens.welcomeCarry)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onFinished();
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 390;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            height: 844 * scale,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 390,
                height: 844,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = MotionTokens.welcomeLightCurve.transform(
                      _controller.value,
                    );
                    return Stack(
                      children: <Widget>[
                        const CustomPaint(
                          painter: ThreadPainter(ThreadCurve.signIn),
                          child: SizedBox.expand(),
                        ),
                        TravellingLight(curve: ThreadCurve.signIn, t: t),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
