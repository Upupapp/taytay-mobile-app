import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../core/motion/motion_tokens.dart';

/// A consent or agreement tick on a card (CSS `.cb` on RegTerms): soft fill,
/// radius 18, a 24 px box; ticked, the card turns soft blue with a blue
/// border, so the state is a border and a tick as well as a colour.
///
/// The whole card is the target and announces as a checkbox with [label].
/// A screen keeps its own "Continue" disabled until every required card is
/// ticked; this widget only reports [onChanged].
class ConsentCheckCard extends StatefulWidget {
  const ConsentCheckCard({
    required this.value,
    required this.onChanged,
    required this.label,
    this.description,
    super.key,
  });

  final bool value;

  /// Null shows the card disabled.
  final ValueChanged<bool>? onChanged;
  final String label;

  /// A smaller second line, e.g. what the consent covers.
  final String? description;

  @override
  State<ConsentCheckCard> createState() => _ConsentCheckCardState();
}

class _ConsentCheckCardState extends State<ConsentCheckCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool on = widget.value;
    final ValueChanged<bool>? onChanged = widget.onChanged;
    final String? description = widget.description;
    final BorderRadius corners = BorderRadius.circular(18);

    return Semantics(
      container: true,
      checked: on,
      enabled: onChanged != null,
      label: widget.label,
      hint: description,
      onTap: onChanged == null ? null : () => onChanged(!on),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: corners,
          onTap: onChanged == null ? null : () => onChanged(!on),
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: AnimatedContainer(
            duration: Motion.reduced(context)
                ? MotionTokens.instant
                : MotionTokens.fast,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: on ? BrandColors.blue50 : BrandColors.background,
              borderRadius: corners,
              border: Border.all(
                color: on ? BrandColors.blue : BrandColors.transparent,
                width: FocusRing.borderWidth,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Box(on: on, focused: _focused),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.label,
                        style: AppTypography.bodyStyle.copyWith(
                          height: 1.45,
                          color: BrandColors.ink,
                        ),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Text(
                            description,
                            style: AppTypography.listDetail.copyWith(
                              color: BrandColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 24 px box. Unticked, its border is the 3:1 chevron grey rather than
/// the mock-up's `#B9C2D3`, which a low-vision resident cannot find
/// (WCAG 1.4.11).
class _Box extends StatelessWidget {
  const _Box({required this.on, required this.focused});

  final bool on;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      foregroundDecoration: focused
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: FocusRing.ring.withValues(alpha: 0.25),
                width: FocusRing.ringWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            )
          : null,
      decoration: BoxDecoration(
        color: on ? BrandColors.blue : BrandColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: on ? BrandColors.blue : BrandColors.chevron,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(Icons.check_rounded, size: 16, color: BrandColors.white)
          : null,
    );
  }
}
