import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import 'taytay_back_button.dart';

/// The playful header of sign-in, registration and every form flow (CSS
/// `.whead`): the header gradient, floating shapes, and a three-layer wave
/// (gold, white 40%, white) melting into the white page below.
///
/// Top row: a back control and [stepLabel] ("Step 2 of 6"). Then an optional
/// gold progress bar ([progress], 0–1), an optional [badge] (the success
/// mark), and the [title] / [subtitle] block. [centered] centres the badge and
/// title, as the success screens do.
class WaveHeader extends StatelessWidget {
  const WaveHeader({
    this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.backEnabled = true,
    this.stepLabel,
    this.progress,
    this.progressSemanticLabel,
    this.trailing,
    this.badge,
    this.eyebrow,
    this.centered = false,
    this.includeSafeArea = true,
    super.key,
  }) : assert(
         progress == null || (progress >= 0 && progress <= 1),
         'progress is a fraction from 0 to 1',
       );

  final String? title;
  final String? subtitle;
  final bool showBack;

  /// Overrides the back control's default, which pops or returns home.
  final VoidCallback? onBack;
  final bool backEnabled;

  /// "Step 2 of 6". Shown at the top right.
  final String? stepLabel;

  /// Fraction of the flow done, 0–1. Null hides the bar.
  final double? progress;

  /// The bar's accessible name, e.g. "Create account progress".
  final String? progressSemanticLabel;

  /// Replaces [stepLabel] at the top right, e.g. a "Skip" link.
  final Widget? trailing;

  /// Drawn above the title, e.g. `SuccessMark`.
  final Widget? badge;

  /// Drawn in the title block, just above [title]: sign-in's seal and brand
  /// line (CSS `.wtitle .brandrow`).
  final Widget? eyebrow;
  final bool centered;
  final bool includeSafeArea;

  /// The decorative dot field at the bottom right (CSS `.s4`), for layout
  /// tests that check text stays clear of it.
  static const Key dotFieldKey = Key('wave-header-dot-field');

  @override
  Widget build(BuildContext context) {
    final double safeTop = includeSafeArea
        ? MediaQuery.paddingOf(context).top
        : 0;
    const EdgeInsets padding = WaveHeaderShapes.padding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide =
            constraints.maxWidth >= WaveHeaderShapes.sparkMinWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: BrandGradients.waveHeader.toLinearGradient(),
          ),
          child: ClipRect(
            child: Stack(
              children: <Widget>[
                ..._shapes(wide),
                Padding(
                  padding: padding.copyWith(top: padding.top + safeTop),
                  child: _content(constraints.maxWidth - padding.horizontal),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  height: WaveHeaderShapes.waveHeight,
                  child: ExcludeSemantics(
                    child: CustomPaint(painter: WavePainter()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(double contentWidth) {
    final String? title = this.title;
    final String? subtitle = this.subtitle;
    final String? stepLabel = this.stepLabel;
    final double? progress = this.progress;
    final Widget? badge = this.badge;
    final Widget? eyebrow = this.eyebrow;
    final Widget? trailing = this.trailing;
    final CrossAxisAlignment cross = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final TextAlign align = centered ? TextAlign.center : TextAlign.start;

    final bool hasTopRow = showBack || stepLabel != null || trailing != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (hasTopRow)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
            child: Row(
              children: <Widget>[
                if (showBack)
                  TaytayBackButton(
                    onPressed: onBack,
                    translucent: true,
                    enabled: backEnabled,
                  ),
                const Spacer(),
                if (trailing != null)
                  trailing
                else if (stepLabel != null)
                  Flexible(
                    child: Text(
                      stepLabel,
                      textAlign: TextAlign.end,
                      style: AppTypography.listDetail.copyWith(
                        fontWeight: AppTypography.strong,
                        color: BrandColors.white.withValues(alpha: 0.8),
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: _ProgressBar(
              value: progress,
              semanticLabel: progressSemanticLabel,
            ),
          ),
        if (badge != null)
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Center(child: badge),
          ),
        if (title != null || subtitle != null || eyebrow != null)
          Padding(
            padding: EdgeInsets.only(
              top: badge != null ? Spacing.md : (hasTopRow ? 20 : 0),
            ),
            child: Align(
              alignment: centered
                  ? Alignment.topCenter
                  : AlignmentDirectional.topStart,
              // CSS `.wtitle { max-width: min(300px, 82%) }`. A centred title
              // keeps clear of the dot field at the bottom right, by the same
              // inset on both sides so it stays centred (D-199).
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: centered ? WaveHeaderShapes.centeredTextInset : 0,
                ),
                child: SizedBox(
                  width: centered ? null : math.min(300, contentWidth * 0.82),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: cross,
                    children: <Widget>[
                      if (eyebrow != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: eyebrow,
                        ),
                      if (title != null)
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: align,
                            style: AppTypography.hero.copyWith(
                              color: BrandColors.white,
                            ),
                          ),
                        ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            subtitle,
                            textAlign: align,
                            style: AppTypography.bodyStyle.copyWith(
                              color: BrandColors.onHeaderLede,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _shapes(bool wide) {
    Widget circle(HeaderCircle c) => Positioned(
      top: c.top,
      right: c.right,
      bottom: c.bottom,
      left: c.left,
      width: c.diameter,
      height: c.diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
      ),
    );

    return <Widget>[
      Positioned.fill(
        child: ExcludeSemantics(
          child: Stack(
            children: <Widget>[
              circle(WaveHeaderShapes.bubble),
              const Positioned(
                top: WaveHeaderShapes.ringTop,
                right: WaveHeaderShapes.ringRight,
                width: WaveHeaderShapes.ringDiameter,
                height: WaveHeaderShapes.ringDiameter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: WaveHeaderShapes.ringColor,
                        width: WaveHeaderShapes.ringStroke,
                      ),
                    ),
                  ),
                ),
              ),
              circle(WaveHeaderShapes.skyBubble),
              Positioned(
                right: WaveHeaderShapes.dotFieldRight,
                bottom: WaveHeaderShapes.dotFieldBottom,
                width: WaveHeaderShapes.dotField.width,
                height: WaveHeaderShapes.dotField.height,
                child: const CustomPaint(
                  key: dotFieldKey,
                  painter: _DotFieldPainter(),
                ),
              ),
              if (wide)
                const Positioned(
                  top: WaveHeaderShapes.sparkTop,
                  right: WaveHeaderShapes.sparkRight,
                  width: WaveHeaderShapes.sparkDiameter,
                  height: WaveHeaderShapes.sparkDiameter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrandColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Positioned(
                top: WaveHeaderShapes.plusTop,
                right: WaveHeaderShapes.plusRight,
                width: WaveHeaderShapes.plusSize,
                height: WaveHeaderShapes.plusSize,
                child: Transform.rotate(
                  angle: WaveHeaderShapes.plusTurnDegrees * math.pi / 180,
                  child: const CustomPaint(painter: _PlusPainter()),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// The gold progress bar on the wave header (CSS `.wprog`).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.semanticLabel});

  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: SizedBox(
          height: 6,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: ColoredBox(
                  color: BrandColors.white.withValues(alpha: 0.18),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.gold,
                    borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotFieldPainter extends CustomPainter {
  const _DotFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = WaveHeaderShapes.dotColor;
    const double pitch = WaveHeaderShapes.dotPitch;
    for (double y = pitch / 2; y < size.height; y += pitch) {
      for (double x = pitch / 2; x < size.width; x += pitch) {
        canvas.drawCircle(Offset(x, y), WaveHeaderShapes.dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotFieldPainter oldDelegate) => false;
}

class _PlusPainter extends CustomPainter {
  const _PlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = BrandColors.gold;
    const double bar = WaveHeaderShapes.plusBar;
    canvas
      ..drawRect(
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width,
          height: bar,
        ),
        paint,
      )
      ..drawRect(
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: bar,
          height: size.height,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _PlusPainter oldDelegate) => false;
}
