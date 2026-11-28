import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';

/// One notification row, already turned into resident-facing copy.
class NoticeRow {
  const NoticeRow({
    required this.eyebrow,
    required this.title,
    required this.when,
    required this.unread,
    required this.tone,
    required this.tile,
    required this.icon,
    this.body = '',
    this.onTap,
    this.onMarkRead,
  });

  final String eyebrow;
  final String title;

  /// The words the LGU wrote, under the title, in full (D-231). The title of
  /// several notices is the same for every one ("Verification update"), so
  /// the body is where a notice says what happened.
  final String body;
  final String when;
  final bool unread;
  final Color tone;
  final Color tile;
  final IconData icon;
  final VoidCallback? onTap;

  /// Marks this notice read without opening it: the blue dot's tap (D-238).
  /// Null draws the dot as a mark only.
  final VoidCallback? onMarkRead;
}

class NoticeSection {
  const NoticeSection({required this.heading, required this.rows});

  final String heading;
  final List<NoticeRow> rows;
}

/// The notification centre, drawn as the Directory list pattern: the All /
/// Unread chips (`.chipsrow`) with Mark all as read, the [choosers] under
/// them (Category and When) with Clear filters while one narrows the list,
/// then each section as a heading over one soft list. Rows deep-link through
/// [NoticeRow.onTap].
///
/// ---
///
/// **It draws; it does not decide.** What is filtered, and every count, comes
/// from the caller (the inbox controller, D-238), so the counts are the
/// inbox's and not whatever rows happen to be passed in.
///
/// **An unread notice is a tinted row, a bold title and a blue dot** (the
/// console's DL-294): never colour alone, because a screen reader hears
/// "Unread:" before the title, and the dot is the button that marks it read.
///
/// [showIllustration] used to draw the design's SAMPLE caption; the redesign
/// draws no sample text, so it is kept only for callers that still pass it.
class NotificationCentre extends StatelessWidget {
  const NotificationCentre({
    required this.sections,
    required this.allCount,
    required this.unreadCount,
    required this.unreadOnly,
    required this.onShowUnread,
    required this.onMarkAllRead,
    this.choosers = const <Widget>[],
    this.onClearFilters,
    this.empty,
    this.showIllustration = false,
    super.key,
  });

  /// The rows to show, already filtered. A section with no rows is skipped.
  final List<NoticeSection> sections;

  /// Every notice, and every unread one, whatever is filtered.
  final int allCount;
  final int unreadCount;

  final bool unreadOnly;
  final ValueChanged<bool> onShowUnread;
  final VoidCallback onMarkAllRead;

  /// The chips that open the Category and When pickers.
  final List<Widget> choosers;

  /// Clears Category, When and the search; null while none of them narrows
  /// the list, which hides Clear filters.
  final VoidCallback? onClearFilters;

  /// What the centre says when no row is left to show.
  final Widget? empty;
  final bool showIllustration;

  @override
  Widget build(BuildContext context) {
    final List<NoticeSection> visible = <NoticeSection>[
      for (final NoticeSection section in sections)
        if (section.rows.isNotEmpty) section,
    ];
    final AppStrings strings = AppStrings.of(context);
    final VoidCallback? onClearFilters = this.onClearFilters;
    final Widget? empty = this.empty;
    // Its own ink layer: the centre may be drawn on a page with no Material.
    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.section,
          Spacing.lg,
          Spacing.xl,
        ),
        children: <Widget>[
          // The chips have the whole width: beside a link they were squeezed
          // to half of it, and a long Filipino label broke over three lines.
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SoftChoiceChip(
                key: const Key('inbox-show-all'),
                label: strings.inboxFilterAllCount(allCount),
                selected: !unreadOnly,
                onTap: () => onShowUnread(false),
              ),
              SoftChoiceChip(
                key: const Key('inbox-show-unread'),
                label: strings.inboxFilterUnread(unreadCount),
                selected: unreadOnly,
                onTap: () => onShowUnread(true),
              ),
            ],
          ),
          if (choosers.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: choosers,
            ),
          ],
          // Clear filters at the start, Mark all as read at the end, on one
          // line under the chips.
          if (onClearFilters != null || unreadCount > 0)
            Row(
              children: <Widget>[
                if (onClearFilters != null)
                  Flexible(
                    child: AuthLink(
                      strings.inboxClearFilters,
                      key: const Key('inbox-clear-filters'),
                      alignment: Alignment.centerLeft,
                      onPressed: onClearFilters,
                    ),
                  ),
                if (unreadCount > 0)
                  Flexible(
                    child: AuthLink(
                      strings.inboxMarkAllRead,
                      alignment: Alignment.centerRight,
                      onPressed: onMarkAllRead,
                    ),
                  ),
              ],
            ),
          if (visible.isEmpty && empty != null) ...<Widget>[
            const SizedBox(height: Spacing.section),
            empty,
          ],
          for (var i = 0; i < visible.length; i++) ...<Widget>[
            SizedBox(height: i == 0 ? Spacing.section : Spacing.formGap),
            SettingsSectionTitle(visible[i].heading),
            SoftCard(
              padding: EdgeInsets.zero,
              // Clipped, so a tinted first or last row keeps the card's
              // rounded corners.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (
                      var r = 0;
                      r < visible[i].rows.length;
                      r++
                    ) ...<Widget>[
                      if (r > 0) const SettingsDivider(),
                      _Row(row: visible[i].rows[r]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A notification (Directory `.li`): the category's tile, the category label
/// (10.5 / 800, upper case), the title, the LGU's words and when it was sent.
///
/// While unread the row is tinted blue, its title is bold and a blue dot sits
/// at its end (D-238, the console's DL-294). Unread is said in words too: a
/// screen reader hears "Unread:" before the title, and the dot is a button
/// named "Mark as read:" and the title.
class _Row extends StatelessWidget {
  const _Row({required this.row});

  final NoticeRow row;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final VoidCallback? onTap = row.onTap;
    // The dot's 48 dp target reaches into the row's end padding.
    final bool dotButton = row.unread && row.onMarkRead != null;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.listRow),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.section,
          dotButton ? Spacing.xs : Spacing.lg,
          Spacing.section,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: ComponentSizes.avatar - Spacing.xs,
              height: ComponentSizes.avatar - Spacing.xs,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: row.tile,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: TaytayIcon(
                icon: row.icon,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: row.tone,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.eyebrow,
                    style: AppTypography.category.copyWith(color: row.tone),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    row.title,
                    semanticsLabel: row.unread
                        ? strings.inboxUnreadTitle(row.title)
                        : null,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                      fontWeight: row.unread
                          ? AppTypography.strong
                          : AppTypography.medium,
                    ),
                  ),
                  if (row.body.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      row.body.trim(),
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.text,
                      ),
                    ),
                  ],
                  if (row.when.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      row.when,
                      style: AppTypography.small.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (row.unread)
              _UnreadDot(title: row.title, onMarkRead: row.onMarkRead),
          ],
        ),
      ),
    );
    // Painted on a Material of its own, so the tap's ink shows over the tint.
    final Widget tinted = Material(
      color: unreadRowTint(unread: row.unread),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (onTap == null) return tinted;
    // A tappable row reads as one button (DESIGN_SYSTEM.md §8 rule 8).
    return Semantics(button: true, container: true, child: tinted);
  }
}

/// The fill of a notice row: tinted blue while unread, the card's white once
/// read. Every ink on the row keeps its contrast on both (D-238).
Color unreadRowTint({required bool unread}) =>
    unread ? BrandColors.blue100 : BrandColors.white;

/// The unread dot. With [onMarkRead] it is the button that marks the notice
/// read, a 48 dp target around the dot, named "Mark as read:" and the title;
/// without it, a mark that says "Unread".
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.title, this.onMarkRead});

  final String title;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    const Widget dot = DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.blue,
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: Spacing.md, height: Spacing.md),
    );
    final VoidCallback? onMarkRead = this.onMarkRead;
    if (onMarkRead == null) {
      return Padding(
        padding: const EdgeInsets.only(left: Spacing.sm, top: Spacing.xs),
        child: Semantics(label: strings.inboxUnread, child: dot),
      );
    }
    // Its own node, apart from the row's: the row opens the notice, the dot
    // only marks it read.
    return Semantics(
      container: true,
      button: true,
      label: strings.inboxMarkReadOne(title),
      onTap: onMarkRead,
      excludeSemantics: true,
      child: InkWell(
        onTap: onMarkRead,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: A11y.minTapTarget,
          height: A11y.minTapTarget,
          child: Center(child: dot),
        ),
      ),
    );
  }
}

/// Icons the centre uses. Exposed so a capture can match `04-08`.
abstract final class NoticeIcons {
  static const IconData message = TaytayIcons.briefcase;
  static const IconData verification = TaytayIcons.shield;
  static const IconData advisory = TaytayIcons.landmark;
  static const IconData welfare = TaytayIcons.handCoins;
  static const IconData safety = TaytayIcons.bell;
}
