import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// One tone of [StatusChip]. The fill is a light tint; the label uses the
/// status colour, which clears 4.5:1 on that tint and on white.
///
/// The tone picks colours. The words on the chip are the `label` argument.
enum StatusTone {
  /// Warning amber.
  amber,

  /// Success green.
  green,

  /// Danger red.
  red,

  /// Information blue.
  blue,

  /// Neutral grey.
  grey,

  /// Seal gold, darkened for text.
  gold,
}

/// A short status label. Colour repeats the words; it is not the only signal.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      StatusTone.amber => (BrandColors.warning, const Color(0xFFFFF3D6)),
      StatusTone.green => (BrandColors.success, const Color(0xFFE5F6EE)),
      StatusTone.red => (BrandColors.danger, const Color(0xFFFDECEA)),
      StatusTone.blue => (BrandColors.taytayBlue, const Color(0xFFE7EEF8)),
      StatusTone.grey => (BrandColors.textSecondary, const Color(0xFFEEF1F6)),
      StatusTone.gold => (BrandColors.inkGold, const Color(0xFFFFF6D8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(label, style: AppTypography.labelStrong.copyWith(color: fg)),
    );
  }
}

/// Marks a fact the LGU has not confirmed. The word SAMPLE is the signal;
/// the gold is only a repeat of it.
class SampleTag extends StatelessWidget {
  const SampleTag({super.key, this.label = 'SAMPLE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D8),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.inkGold),
      ),
      child: Text(
        label,
        style: AppTypography.labelStrong.copyWith(
          color: BrandColors.inkGold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Icon tile, title, subtitle, and a trailing control. Default trailing is a
/// chevron.
class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    required this.icon,
    required this.iconLabel,
    this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String iconLabel;
  final Color? iconBackground;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = iconBackground ?? const Color(0xFFE7EEF8);
    final fg = iconColor ?? BrandColors.taytayBlue;
    return Material(
      color: BrandColors.surfaceCard,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: TaytayIcon(
                    icon: icon,
                    semanticLabel: iconLabel,
                    color: fg,
                    size: IconSizes.sm,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.titleCompact.copyWith(
                          fontSize: 15,
                          color: BrandColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.bodyCompact.copyWith(
                            color: BrandColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    const TaytayIcon(
                      icon: TaytayIcons.chevronRight,
                      semanticLabel: '',
                      excludeSemantics: true,
                      color: BrandColors.textMuted,
                      size: IconSizes.sm,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Call, directions, and message. Message is a control the screen wires; this
/// widget does not decide who may use it.
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.onCall,
    required this.onDirections,
    this.onMessage,
    super.key,
  });

  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Action(
            label: 'Call',
            icon: TaytayIcons.phone,
            onPressed: onCall,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _Action(
            label: 'Directions',
            icon: TaytayIcons.mapPin,
            onPressed: onDirections,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _Action(
            label: 'Message',
            icon: TaytayIcons.messageCircle,
            onPressed: onMessage,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
        foregroundColor: BrandColors.taytayBlue,
        side: const BorderSide(color: BrandColors.taytayBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.taytayBlue,
          ),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: BrandColors.taytayBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
