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

  /// Entry 250, close to the page-3 exit at 260. `02-01` and `02-10`.
  static const ThreadCurve signIn = ThreadCurve(250, 180);

  /// `02-02` rises from the sign-in exit.
  static const ThreadCurve reset = ThreadCurve(180, 250);

  /// Flat stitch across the create-account header (`02-03` through `02-08`, `02-11`).
  static const ThreadCurve wizard = ThreadCurve(136, 136);

  /// `02-09`.
  static const ThreadCurve submitted = ThreadCurve(230, 170);

  /// The welcome stitch at a fractional [PageController.page].
  ///
  /// Control heights blend, so a swipe reads as one curve instead of two
  /// stitches sliding apart.
  static ThreadCurve welcomeAt(double page) {
    final double clamped = page.clamp(0, pages.length - 1).toDouble();
    final int index = clamped.floor();
    final double frac = clamped - index;
    if (index >= pages.length - 1) return pages.last;
    return pages[index].lerp(pages[index + 1], frac);
  }

  ThreadCurve lerp(ThreadCurve other, double t) {
    return ThreadCurve(
      entryY + (other.entryY - entryY) * t,
      exitY + (other.exitY - exitY) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThreadCurve && other.entryY == entryY && other.exitY == exitY;

  @override
  int get hashCode => Object.hash(entryY, exitY);
}

/// Passed as `go_router` extra when Get started opens Sign-in.
///
/// [cycle] is the live 0–1 position of the 7s loop, before easing, so the
/// speck on Sign-in continues from the same moment instead of restarting.
/// Reduced motion does not send it. The thread itself stays on the sign-in
/// screen either way; only the speck is hidden when motion is reduced.
@immutable
class WelcomeThreadArrival {
  const WelcomeThreadArrival(this.cycle);

  final double cycle;
}

/// Where the speck sits on the joined welcome stitch.
@immutable
class SpeckPlacement {
  const SpeckPlacement({required this.page, required this.t});

  /// Zero-based welcome page that should paint the speck.
  final int page;

  /// 0 at that page's entry, 1 at its exit.
  final double t;
}

/// Places the speck on the three welcome curves treated as one path.
///
/// [page] is [PageController.page]. [phase] is the eased 7s loop, 0 at the
/// entry of the settled page and 1 at its exit. [anchor] is the page the
/// resident was on when the swipe began.
///
/// While the page is still, the speck walks that page's curve. While it is
/// moving, the parameter eases from the live phase to the shared boundary, so
/// the exit of page *n* and the entry of page *n+1* are the same point in the
/// scrollable (the curves meet: x 392 on one page, x −2 on the next, same y).
SpeckPlacement placeSpeck({
  required double page,
  required double phase,
  required int anchor,
}) {
  final count = ThreadCurve.pages.length;
  final frac = (page - anchor).clamp(-1.0, 1.0);
  final held = phase.clamp(0.0, 1.0);
  final double along = frac >= 0
      ? anchor + held + frac * (1 - held)
      : anchor + held * (1 + frac);
  if (along >= count) {
    return SpeckPlacement(page: count - 1, t: 1);
  }
  final index = along.floor().clamp(0, count - 1);
  return SpeckPlacement(page: index, t: (along - index).clamp(0.0, 1.0));
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

/// The sign-in stitch and its speck.
///
/// The thread stays for as long as the screen is up. The speck loops on the
/// same 7s cycle as the welcome pages, starting at [cycle] so a hand-off from
/// Get started does not jump. Reduced motion keeps the thread and hides the
/// speck.
class SignInThreadOverlay extends StatefulWidget {
  const SignInThreadOverlay({
    this.cycle = 0,
    this.curve = ThreadCurve.signIn,
    this.clock,
    super.key,
  });

  /// Raw 0–1 position on the 7s loop, before easing.
  ///
  /// Used only when [clock] is null and this overlay owns its loop.
  final double cycle;

  /// Which cubic the thread and the speck follow.
  final ThreadCurve curve;

  /// A loop owned above this overlay, so a route change does not restart it.
  final Animation<double>? clock;

  @override
  State<SignInThreadOverlay> createState() => _SignInThreadOverlayState();
}

class _SignInThreadOverlayState extends State<SignInThreadOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _owned;

  @override
  void initState() {
    super.initState();
    if (widget.clock == null) {
      _owned = AnimationController(
        vsync: this,
        duration: MotionTokens.welcomeLight,
        value: widget.cycle.clamp(0.0, 1.0),
      );
    }
  }

  Animation<double> get _drive => widget.clock ?? _owned!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AnimationController? owned = _owned;
    if (owned == null) return;
    if (Motion.decorativeLoop(context)) {
      if (!owned.isAnimating) owned.repeat();
    } else {
      owned.stop();
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
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
                  animation: _drive,
                  builder: (context, _) {
                    final showSpeck = Motion.decorativeLoop(context);
                    final t = MotionTokens.welcomeLightCurve.transform(
                      _drive.value,
                    );
                    return Stack(
                      children: <Widget>[
                        CustomPaint(
                          painter: ThreadPainter(widget.curve),
                          child: const SizedBox.expand(),
                        ),
                        if (showSpeck)
                          TravellingLight(curve: widget.curve, t: t),
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
