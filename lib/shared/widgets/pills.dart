import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// A filter or scope chip on a soft page (Directory.dc `.chipsrow .chip`):
/// solid blue when in force, the soft grey pill otherwise. 36 px tall in a
/// 48 dp target, announced as a selectable button.
///
/// [chooser] draws a chevron after the label, for a chip that opens a picker
/// of choices rather than being one (the inbox's Category and When, D-238);
/// [semanticLabel] then names what is being chosen ("When: Any time"), since
/// the label alone says only the current choice.
class SoftChoiceChip extends StatelessWidget {
  const SoftChoiceChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.chooser = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool chooser;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color fill = selected ? BrandColors.blue : BrandColors.chipFill;
    final Color ink = selected ? BrandColors.white : BrandColors.text;
    final Widget text = Text(
      label,
      style: AppTypography.chip.copyWith(color: ink),
    );
    // The label and the tap are declared here: excluding the InkWell's own
    // semantics would otherwise drop its tap action with it.
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: fill,
                shape: const StadiumBorder(),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ComponentSizes.chipHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.section,
                    vertical: Spacing.sm,
                  ),
                  child: chooser
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(child: text),
                            const SizedBox(width: Spacing.xs),
                            TaytayIcon(
                              icon: TaytayIcons.chevronDown,
                              semanticLabel: '',
                              excludeSemantics: true,
                              size: IconSizes.sm,
                              color: ink,
                            ),
                          ],
                        )
                      : text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The colour family of a [StatusPill].
enum PillTone {
  /// In progress, or information.
  blue,

  /// Done, held, approved.
  green,

  /// Waiting on somebody.
  gold,

  /// Stopped or called off.
  red,

  /// No particular state.
  neutral,
}

/// A status in words on a soft pill (CSS `.pill`): the label is the status,
/// the colour only repeats it.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, this.tone = PillTone.blue, super.key});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color ink) = switch (tone) {
      PillTone.blue => (BrandColors.blue50, BrandColors.blue),
      PillTone.green => (BrandColors.green50, BrandColors.green),
      PillTone.gold => (BrandColors.gold50, BrandColors.goldInk),
      PillTone.red => (BrandColors.red50, BrandColors.redInk),
      PillTone.neutral => (BrandColors.chipFill, BrandColors.text),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xxs,
          vertical: Spacing.xs,
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            fontWeight: AppTypography.medium,
            color: ink,
          ),
        ),
      ),
    );
  }
}

/// A filter chip on the blue header (Balita.dc `.chip.bar` / `.chip.onbar`):
/// white with blue text when in force, a white outline otherwise. 36 px tall
/// in a 48 dp target, announced as a selectable button.
class HeaderChoiceChip extends StatelessWidget {
  const HeaderChoiceChip({
    required this.label,
    required this.selected,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ComponentSizes.chipHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.section,
                vertical: Spacing.xs,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? BrandColors.white : BrandColors.transparent,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: selected
                      ? BrandColors.white
                      : BrandColors.white.withValues(alpha: 0.4),
                  width: FocusRing.borderWidth,
                ),
              ),
              child: Text(
                label,
                style: AppTypography.chip.copyWith(
                  color: selected ? BrandColors.blue : BrandColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
