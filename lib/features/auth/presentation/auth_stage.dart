import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/asset_manifest.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_thread.dart';

/// The 02 frame: navy field fading near y = 330, thread and speck behind
/// the white sheet, seal row, and the step dots on the dark header.
class AuthStage extends StatelessWidget {
  const AuthStage({
    required this.sheetTop,
    required this.child,
    this.sheetBottom = 20,
    this.wrapSheet = true,
    this.arch = AuthArch.none,
    this.step,
    this.stepLabel,
    this.threadCycle = 0,
    this.atmosphere = SignInAtmosphere.signIn,
    this.curve = ThreadCurve.signIn,
    this.onBack,
    this.footer,
    this.bleed = false,
    super.key,
  });

  /// CSS `.sheet { top }`. Short windows pull the sheet up so it can scroll.
  final double sheetTop;
  final double sheetBottom;

  /// False when the sheet should hug its content (forgot password).
  final bool wrapSheet;
  final AuthArch arch;

  /// 1-based step of 6. Null hides the knot row.
  final int? step;

  /// The gold caption after "Step n of 6 · ".
  final String? stepLabel;
  final double threadCycle;
  final SignInAtmosphere atmosphere;
  final ThreadCurve curve;
  final VoidCallback? onBack;
  final Widget? footer;
  final Widget child;

  /// `02-04` draws the sheet edge to edge, radius on the top corners only.
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final height = MediaQuery.sizeOf(context).height;
    final headerTop = padding.top > 44 ? padding.top : 44.0;
    final bottom = math.max(sheetBottom, padding.bottom);
    final side = math.max(14.0, math.max(padding.left, padding.right));
    final belowHeader = headerTop + 56;
    var top = sheetTop;
    if (height - bottom - top < 160) {
      top = math.max(belowHeader, height - bottom - 160);
    }
    final maxTop = math.max(0.0, height - bottom - 48);
    if (top > maxTop) top = maxTop;

    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Stack(
        key: const Key('sign-in-stack'),
        children: <Widget>[
          Positioned.fill(child: SignInBackdrop(atmosphere: atmosphere)),
          if (arch != AuthArch.none) _Arch(kind: arch),
          Positioned.fill(
            child: IgnorePointer(
              child: SignInThreadOverlay(cycle: threadCycle, curve: curve),
            ),
          ),
          if (bleed)
            const Positioned.fill(child: ColoredBox(color: Color(0x73062358))),
          Positioned(
            top: headerTop,
            left: padding.left,
            right: padding.right,
            child: WovenHeader(
              showBack: true,
              onBack: onBack,
              paintField: false,
              includeSafeArea: false,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            ),
          ),
          if (step != null)
            Positioned(
              top: headerTop + 60,
              left: 20 + padding.left,
              right: 20 + padding.right,
              child: _StepDots(step: step!, label: stepLabel ?? ''),
            ),
          if (wrapSheet)
            Positioned(
              top: top,
              left: bleed ? 0 : side,
              right: bleed ? 0 : side,
              bottom: bleed
                  ? 0
                  : footer == null
                  ? bottom
                  : bottom + 66,
              child: _Sheet(bleed: bleed, expand: true, child: child),
            )
          else
            Positioned(
              top: top,
              left: side,
              right: side,
              child: _Sheet(expand: false, child: child),
            ),
          if (footer != null)
            Positioned(
              left: 20 + padding.left,
              right: 20 + padding.right,
              bottom: math.max(34, padding.bottom),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

/// Which mark sits on the field above the sheet.
enum AuthArch { none, hall, hallShort, key, submitted }

class _Arch extends StatelessWidget {
  const _Arch({required this.kind});

  final AuthArch kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      AuthArch.hall => const _HallArch(top: 112, height: 196),
      AuthArch.hallShort => const _HallArch(top: 112, height: 140),
      AuthArch.key => const _KeyArch(),
      AuthArch.submitted => const _SubmittedMark(),
      AuthArch.none => const SizedBox.shrink(),
    };
  }
}

class _HallArch extends StatelessWidget {
  const _HallArch({required this.top, required this.height});

  final double top;
  final double height;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(200),
      topRight: Radius.circular(200),
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    );
    return Stack(
      children: <Widget>[
        Positioned(
          left: 64,
          top: top + 8,
          width: 246,
          height: height,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF1E5BC6),
                    Color(0xFF0B3D91),
                    Color(0xFF062358),
                  ],
                  stops: <double>[0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 72,
          top: top,
          width: 246,
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: radius,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 4),
                BoxShadow(
                  color: Color(0x40062358),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Image.asset(
                AppAssets.byKey('municipal_hall')!.path,
                fit: BoxFit.cover,
                semanticLabel: AppAssets.byKey('municipal_hall')!.semanticLabel,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyArch extends StatelessWidget {
  const _KeyArch();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(75),
      topRight: Radius.circular(75),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(18),
    );
    return Stack(
      children: <Widget>[
        Positioned(
          left: 126,
          top: 124,
          width: 150,
          height: 150,
          child: Transform.rotate(
            angle: 4 * math.pi / 180,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF1E5BC6),
                    Color(0xFF0B3D91),
                    Color(0xFF062358),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 120,
          top: 118,
          width: 150,
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 4),
                BoxShadow(
                  color: Color(0x33062358),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Icon(
              Icons.key_outlined,
              size: 60,
              color: BrandColors.taytayBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmittedMark extends StatelessWidget {
  const _SubmittedMark();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(90),
      topRight: Radius.circular(90),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );
    return Stack(
      children: <Widget>[
        Positioned(
          left: 98,
          top: 133,
          width: 180,
          height: 190,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF1E5BC6), Color(0xFF062358)],
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 105,
          top: 126,
          width: 180,
          height: 190,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Color(0xFFFFFFFF), spreadRadius: 4),
                BoxShadow(
                  color: Color(0x38062358),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFFFF4CC),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Center(
                    child: CustomPaint(
                      size: Size(44, 44),
                      painter: _HourglassPainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          right: 24,
          top: 346,
          child: AuthCopy(
            eyebrow: 'Naipasa na',
            title: "You're all set, Juana!",
            titleSize: 28,
            centered: true,
            subtitle:
                'Your account is created and your details were sent to '
                'Taytay LGU for verification.',
          ),
        ),
      ],
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF8A5A00);
    final sx = size.width / 24;
    final sy = size.height / 24;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawLine(const Offset(5, 22), const Offset(19, 22), paint);
    canvas.drawLine(const Offset(5, 2), const Offset(19, 2), paint);
    final glass = Path()
      ..moveTo(17, 22)
      ..lineTo(17, 17.828)
      ..quadraticBezierTo(17, 17, 16.414, 16.414)
      ..lineTo(12, 12)
      ..lineTo(7.586, 16.414)
      ..quadraticBezierTo(7, 17, 7, 17.828)
      ..lineTo(7, 22)
      ..moveTo(7, 2)
      ..lineTo(7, 6.172)
      ..quadraticBezierTo(7, 7, 7.586, 7.586)
      ..lineTo(12, 12)
      ..lineTo(16.414, 7.586)
      ..quadraticBezierTo(17, 7, 17, 6.172)
      ..lineTo(17, 2);
    canvas.drawPath(glass, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) => false;
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child, this.bleed = false, this.expand = true});

  final Widget child;
  final bool bleed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = bleed
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : BorderRadius.circular(26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F062358),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        key: signInFormSheetKey,
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: expand ? StackFit.expand : StackFit.loose,
          children: <Widget>[
            const Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.all(7),
                  child: CustomPaint(painter: SheetSeamPainter()),
                ),
              ),
            ),
            if (expand) Positioned.fill(child: child) else child,
          ],
        ),
      ),
    );
  }
}

/// The white form sheet. Tests look for this to prove the copy sits on it.
const Key signInFormSheetKey = Key('sign-in-form-sheet');

/// `.sheet:before` — a 1.4 px gold dash, inset 7, radius 20.
class SheetSeamPainter extends CustomPainter {
  const SheetSeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x8CC9A227);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SheetSeamPainter oldDelegate) => false;
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Flexible(
              child: Text(
                'Create account',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: AppTypography.black,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Step $step of 6 · $label',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: AppTypography.black,
                  color: Color(0xFFFCD116),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Step $step of 6, $label',
          child: SizedBox(
            height: 24,
            width: 350,
            child: CustomPaint(painter: _StepDotPainter(step: step)),
          ),
        ),
      ],
    );
  }
}

class _StepDotPainter extends CustomPainter {
  const _StepDotPainter({required this.step});

  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 390;
    canvas.save();
    canvas.scale(scale);
    for (var i = 0; i < 6; i++) {
      final cx = 20.0 + i * 70;
      const cy = 12.0;
      final index = i + 1;
      if (index < step) {
        canvas.drawCircle(
          Offset(cx, cy),
          8,
          Paint()..color = const Color(0xFFFCD116),
        );
        final check = Path()
          ..moveTo(cx - 3.5, cy)
          ..lineTo(cx - 1, cy + 2.5)
          ..lineTo(cx + 4.5, cy - 5);
        canvas.drawPath(
          check,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF062358),
        );
      } else if (index == step) {
        canvas.drawCircle(
          Offset(cx, cy),
          10,
          Paint()..color = const Color(0xFF062358),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          3.5,
          Paint()..color = const Color(0xFFFCD116),
        );
      } else {
        canvas.drawCircle(
          Offset(cx, cy),
          6,
          Paint()..color = const Color(0xFF0B3D91),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StepDotPainter oldDelegate) =>
      oldDelegate.step != step;
}

/// Shared eyebrow, title and supporting line inside a sheet.
class AuthCopy extends StatelessWidget {
  const AuthCopy({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.titleSize = 24,
    this.subtitleSize = 13,
    this.centered = false,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final double titleSize;
  final double subtitleSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: centered
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            const CustomPaint(size: Size(16, 2), painter: _DashPainter()),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                eyebrow.toUpperCase(),
                style: AppTypography.eyebrowSignIn.copyWith(
                  color: BrandColors.inkGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: AppTypography.h1SignIn.copyWith(
              fontSize: titleSize,
              color: BrandColors.taytayBlueDark,
            ),
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: subtitleSize,
              fontWeight: AppTypography.body,
              height: 1.5,
              color: const Color(0xFF4A5470),
            ),
          ),
        ],
      ],
    );
  }
}

/// A design `.link`. The slot stays the line height; the hit target is 48 dp.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink(
    this.label, {
    required this.onPressed,
    this.align = Alignment.center,
    this.fontSize = 13,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Alignment align;
  final double fontSize;

  /// False when the link sits in a row and should hug its label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.taytayBlue,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: AppTypography.black,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
    if (!expand) {
      return SizedBox(
        width: 48,
        height: fontSize * 1.35,
        child: OverflowBox(
          maxWidth: 80,
          maxHeight: 48,
          alignment: align,
          child: button,
        ),
      );
    }
    return SizedBox(
      height: fontSize * 1.35,
      width: double.infinity,
      child: OverflowBox(
        maxHeight: 48,
        alignment: align,
        child: Align(alignment: align, child: button),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9A227)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    var x = 0.0;
    while (x < size.width) {
      final next = math.min(x + 4, size.width);
      canvas.drawLine(Offset(x, 1), Offset(next, 1), paint);
      x = next + 3;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}
