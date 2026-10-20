import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';

/// "Step n of m" with a gold stitched progress mark.
///
/// Done steps are filled gold, the current step is a gold ring, future steps
/// are a hairline. The label carries the same information in words.
class StepThread extends StatelessWidget {
  const StepThread({required this.step, required this.total, super.key})
    : assert(step >= 1 && step <= total && total > 0);

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'STEP $step OF $total',
          style: AppTypography.eyebrow.copyWith(color: BrandColors.inkGold),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: <Widget>[
            for (var i = 1; i <= total; i++) ...<Widget>[
              _Knot(
                state: i < step
                    ? _KnotState.done
                    : i == step
                    ? _KnotState.current
                    : _KnotState.future,
              ),
              if (i != total)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    color: i < step
                        ? BrandColors.sealGold
                        : BrandColors.sealGold.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

enum _KnotState { done, current, future }

class _Knot extends StatelessWidget {
  const _Knot({required this.state});

  final _KnotState state;

  @override
  Widget build(BuildContext context) {
    final fill = switch (state) {
      _KnotState.done => BrandColors.sealGold,
      _KnotState.current => BrandColors.surfaceCard,
      _KnotState.future => BrandColors.surfaceMuted,
    };
    return Semantics(
      label: switch (state) {
        _KnotState.done => 'Completed step',
        _KnotState.current => 'Current step',
        _KnotState.future => 'Upcoming step',
      },
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.sealGold, width: 2),
        ),
      ),
    );
  }
}
