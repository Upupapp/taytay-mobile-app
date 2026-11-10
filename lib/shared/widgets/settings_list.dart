import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import 'surface_cards.dart';
import 'taytay_icon.dart';

/// The colour of a [SettingsIcon] (CSS `.ic`, `.ic.g`, `.ic.y`, `.ic.r`).
enum SettingsTone { blue, green, gold, red }

/// The settings / profile list of the redesign (`Account.dc.html` `.list`):
/// one card holding rows, with a hairline between rows that starts after the
/// icon. [glass] draws the frosted card of a main tab; otherwise the white
/// soft card.
///
/// Rows are [SettingsRow]s and [SettingsSwitchRow]s, or any widget of the
/// same shape. The list clips them to its corners so a pressed row's ink
/// stays inside the card.
class SettingsList extends StatelessWidget {
  const SettingsList({required this.children, this.glass = false, super.key});

  final List<Widget> children;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final double radius = glass ? Radii.cardLarge : Radii.card;
    final Widget rows = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SettingsDivider(),
            children[i],
          ],
        ],
      ),
    );
    if (glass) {
      return GlassCard(padding: EdgeInsets.zero, child: rows);
    }
    return SoftCard(padding: EdgeInsets.zero, child: rows);
  }
}

/// The hairline between two rows (CSS `.soft .li::before`): `#EEF1F6`, from
/// the text column to 16 px short of the right edge.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  /// Row padding, the 40 px icon and the gap after it.
  static const double inset = Spacing.lg + ComponentSizes.listIcon + Spacing.lg;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: inset, right: Spacing.lg),
      child: Divider(height: 1, thickness: 1, color: BrandColors.divider),
    );
  }
}

/// A section heading above a [SettingsList] (CSS `.soft .h2`): 15 / 600 ink,
/// announced as a heading.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {this.onHeader = false, super.key});

  final String title;

  /// White on the blue header instead of ink on the page.
  final bool onHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xxs,
        bottom: Spacing.sm + Spacing.xxs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppTypography.sectionTitle.copyWith(
            color: onHeader ? BrandColors.white : BrandColors.ink,
          ),
        ),
      ),
    );
  }
}

/// The 40 px rounded square that leads a row (CSS `.ic`): a soft tint with
/// the icon in the matching ink. Decorative; the row carries the words.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon({
    required this.icon,
    this.tone = SettingsTone.blue,
    this.fill,
    this.ink,
    super.key,
  });

  final IconData icon;
  final SettingsTone tone;

  /// Overrides the tone's tint, for a row whose data names its colours.
  final Color? fill;
  final Color? ink;

  static (Color, Color) colours(SettingsTone tone) => switch (tone) {
    SettingsTone.blue => (BrandColors.blue50, BrandColors.blue),
    SettingsTone.green => (BrandColors.green50, BrandColors.green),
    SettingsTone.gold => (BrandColors.gold50, BrandColors.goldInk),
    SettingsTone.red => (BrandColors.red50, BrandColors.redInk),
  };

  @override
  Widget build(BuildContext context) {
    final (Color toneFill, Color toneInk) = colours(tone);
    return Container(
      width: ComponentSizes.listIcon,
      height: ComponentSizes.listIcon,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill ?? toneFill,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: '',
        excludeSemantics: true,
        color: ink ?? toneInk,
        size: IconSizes.sm + Spacing.xxs,
      ),
    );
  }
}

/// One row of a [SettingsList] (CSS `.li`): icon, title, detail, and a
/// trailing chevron, count or control. At least 64 tall, 14 / 16 padding.
///
/// [progress] (0–1) draws the thin bar under the detail (CSS `.prog`), such
/// as how much of a profile is filled in. [badgeCount] draws the red count
/// (CSS `.cnt`) and is read out with the row. [destructive] is the red
/// sign-out row (CSS `.out`).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.detail,
    this.icon,
    this.tone = SettingsTone.blue,
    this.iconFill,
    this.iconInk,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.badgeCount,
    this.progress,
    this.destructive = false,
    this.onTap,
    this.semanticLabel,
    this.titleMaxLines,
    this.detailMaxLines,
    this.detailStyle,
    super.key,
  });

  final String title;
  final String? detail;
  final IconData? icon;
  final SettingsTone tone;
  final Color? iconFill;
  final Color? iconInk;

  /// Replaces the icon square, e.g. an avatar.
  final Widget? leading;

  /// Replaces the chevron, e.g. a button or a time.
  final Widget? trailing;
  final bool showChevron;
  final int? badgeCount;
  final double? progress;
  final bool destructive;
  final VoidCallback? onTap;

  /// What the row announces. Defaults to the title, the detail and the count.
  final String? semanticLabel;
  final int? titleMaxLines;
  final int? detailMaxLines;

  /// Overrides the muted detail, e.g. a record value in body ink
  /// (CSS `.li .d .k`).
  final TextStyle? detailStyle;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    final String? detail = this.detail;
    final double? progress = this.progress;
    final int? badgeCount = this.badgeCount;
    final VoidCallback? onTap = this.onTap;
    final bool hasBadge = badgeCount != null && badgeCount > 0;
    final Widget? leading =
        this.leading ??
        (icon == null
            ? null
            : SettingsIcon(
                icon: icon,
                tone: destructive ? SettingsTone.red : tone,
                fill: iconFill,
                ink: iconInk,
              ));
    final Widget? trailing =
        this.trailing ??
        (onTap != null && showChevron && !destructive
            ? const TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: '',
                excludeSemantics: true,
                color: BrandColors.chevron,
                size: IconSizes.sm,
              )
            : null);

    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.listRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.section,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading,
              const SizedBox(width: Spacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                    style: AppTypography.listTitle.copyWith(
                      color: destructive ? BrandColors.redInk : BrandColors.ink,
                    ),
                  ),
                  if (detail != null && detail.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      detail,
                      maxLines: detailMaxLines,
                      overflow: detailMaxLines == null
                          ? null
                          : TextOverflow.ellipsis,
                      style:
                          detailStyle ??
                          AppTypography.listDetail.copyWith(
                            color: BrandColors.muted,
                          ),
                    ),
                  ],
                  if (progress != null) ...<Widget>[
                    const SizedBox(height: Spacing.xs),
                    _ProgressBar(value: progress),
                  ],
                ],
              ),
            ),
            if (hasBadge) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              CountBadge(count: badgeCount),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              trailing,
            ],
          ],
        ),
      ),
    );

    if (onTap == null) {
      // A row that is not itself a button may hold one (a trailing Sign out),
      // so its children keep their own semantics.
      final String? label = semanticLabel;
      if (label == null) return Semantics(container: true, child: row);
      return Semantics(
        container: true,
        label: label,
        child: ExcludeSemantics(child: row),
      );
    }
    final String label =
        semanticLabel ??
        <String>[
          title,
          if (detail != null && detail.isNotEmpty) detail,
          if (hasBadge) '$badgeCount new',
        ].join(', ');
    final bool reduced = Motion.reduced(context);
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              unawaited(
                AppHaptics.fire(HapticIntent.selection, suppressed: reduced),
              );
              onTap();
            },
            child: row,
          ),
        ),
      ),
    );
  }
}

/// A switch row in a [SettingsList]: the same icon, title and detail as a
/// [SettingsRow], with the theme's switch at the end. Built on
/// [SwitchListTile], so the whole row toggles and announces its state.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.detail,
    this.icon,
    this.tone = SettingsTone.blue,
    this.iconFill,
    this.iconInk,
    super.key,
  });

  final String title;
  final String? detail;
  final bool value;

  /// Null shows the switch disabled.
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final SettingsTone tone;
  final Color? iconFill;
  final Color? iconInk;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    final String? detail = this.detail;
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        secondary: icon == null
            ? null
            : SettingsIcon(
                icon: icon,
                tone: tone,
                fill: iconFill,
                ink: iconInk,
              ),
        title: Text(
          title,
          style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
        ),
        subtitle: detail == null || detail.isEmpty
            ? null
            : Text(
                detail,
                style: AppTypography.listDetail.copyWith(
                  color: BrandColors.muted,
                ),
              ),
      ),
    );
  }
}

/// The red count on a row or a header button (CSS `.cnt`): 22 tall, white
/// 11 / 800. It is decorative; the row reads the count in its label.
class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: ComponentSizes.countBadge,
          minHeight: ComponentSizes.countBadge,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs + Spacing.xxs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.red,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTypography.tiny.copyWith(
            fontWeight: AppTypography.black,
            color: BrandColors.white,
          ),
        ),
      ),
    );
  }
}

/// CSS `.prog`: 6 px, the line colour, filled blue to [value].
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.pill),
        child: SizedBox(
          height: ComponentSizes.progressBar,
          child: LinearProgressIndicator(
            value: value.clamp(0, 1).toDouble(),
            backgroundColor: BrandColors.line,
            color: BrandColors.blue,
            minHeight: ComponentSizes.progressBar,
          ),
        ),
      ),
    );
  }
}
