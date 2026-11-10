import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

export 'icon_tile.dart';

// The card, timeline and type scale the verification status pages drew first.
// Shared so a second feature can show progress the same way without reaching
// into another feature's presentation layer (Article 2.2).

/// `.bd` padding: 14px 16px.
const EdgeInsets s3PagePadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

/// `.card` margin-bottom.
const double s3CardGap = 12;

/// CSS `normal` for Plus Jakarta Sans. Typo ascender 1038 and descender 222.
const double s3Line = 1.26;

/// A unitless CSS line-height, split evenly above and below the glyphs.
TextStyle s3Type(
  double size,
  FontWeight weight,
  Color color, {
  double height = s3Line,
}) {
  return TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    color: color,
    decoration: TextDecoration.none,
  );
}

/// Multi-line copy at a CSS line-height.
///
/// Flutter rounds a line box to a whole logical pixel, so `13 × 1.5` becomes
/// 20 instead of 19.5 and each extra line sits 1.5 device px low at 3×. The
/// lines keep that strut, and their tops are placed `fontSize × height` apart.
class S3Lines extends StatelessWidget {
  const S3Lines(
    this.text, {
    required this.size,
    required this.weight,
    required this.color,
    this.height = s3Line,
    this.align = TextAlign.start,
    super.key,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = s3Type(size, weight, color, height: height);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            final double maxWidth = constraints.maxWidth;
            final TextPainter painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textAlign: align,
              textScaler: scaler,
            )..layout(maxWidth: maxWidth.isFinite ? maxWidth : 100000);
            final List<String> lines = <String>[];
            var start = 0;
            while (start < text.length) {
              final TextRange range = painter.getLineBoundary(
                TextPosition(offset: start),
              );
              if (range.end <= start) break;
              lines.add(text.substring(range.start, range.end).trimRight());
              start = range.end;
            }
            painter.dispose();
            if (lines.length <= 1) {
              return Text(text, textAlign: align, style: style);
            }
            final double step = size * scaler.scale(1) * height;
            return SizedBox(
              width: maxWidth.isFinite ? maxWidth : null,
              height: step * lines.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: i * step,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        textAlign: align,
                        maxLines: 1,
                        softWrap: false,
                        style: style,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The timeline title sits in the body's 16px strut, not a 13px line box.
const StrutStyle s3BodyStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  height: s3Line,
  forceStrutHeight: true,
  leadingDistribution: TextLeadingDistribution.even,
);

/// White card. Drawn as the redesign's `SoftCard` look: radius 20, no border,
/// no shadow. New code uses `SoftCard` (surface_cards.dart).
class S3Card extends StatelessWidget {
  const S3Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // The old 1 px stroke is gone, but its 1 px inset stays: screens laid
    // out against this card keep their positions until they are redesigned.
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum TimelineTone {
  // Disc colour only. The step title is a separate string.
  done,
  current,
  upcoming,
  navy,
}

/// One step in a filled timeline.
class TimelineStep {
  const TimelineStep({
    required this.icon,
    required this.title,
    required this.tone,
    this.detail = '',
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final TimelineTone tone;
  final VoidCallback? onTap;
}

/// A list of steps: a numbered-step disc (green done, blue for what the
/// resident can now do, gold for the step in hand, hollow for what is next),
/// the step in words and a supporting line. A step with [TimelineStep.onTap]
/// is one 48 dp button with a chevron.
class Timeline extends StatelessWidget {
  const Timeline({required this.steps, super.key});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final TimelineStep step in steps) _TimelineRow(step: step),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});

  final TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color ink, Color? ring) = switch (step.tone) {
      TimelineTone.done => (BrandColors.green, BrandColors.white, null),
      TimelineTone.navy => (BrandColors.blue, BrandColors.white, null),
      TimelineTone.current => (BrandColors.gold, BrandColors.navy, null),
      TimelineTone.upcoming => (
        BrandColors.white,
        BrandColors.muted,
        BrandColors.line2,
      ),
    };
    final VoidCallback? onTap = step.onTap;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: ComponentSizes.stepDisc,
            height: ComponentSizes.stepDisc,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: ring == null ? null : Border.all(color: ring, width: 2),
            ),
            child: TaytayIcon(
              icon: step.icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xs,
              color: ink,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  step.title,
                  style: AppTypography.listTitle.copyWith(
                    color: step.tone == TimelineTone.upcoming
                        ? BrandColors.muted
                        : BrandColors.ink,
                  ),
                ),
                if (step.detail.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    step.detail,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: Spacing.sm),
            const Padding(
              padding: EdgeInsets.only(top: Spacing.xs),
              child: TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.chevron,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
        child: row,
      ),
    );
  }
}
