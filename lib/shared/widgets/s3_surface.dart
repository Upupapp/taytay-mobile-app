import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

export 'icon_tile.dart';

// The timeline the verification status pages drew first.
// Shared so a second feature can show progress the same way without reaching
// into another feature's presentation layer (Article 2.2).

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
