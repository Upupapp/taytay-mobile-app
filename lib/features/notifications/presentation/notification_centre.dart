import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
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
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String when;
  final bool unread;
  final Color tone;
  final Color tile;
  final IconData icon;
  final VoidCallback? onTap;
}

class NoticeSection {
  const NoticeSection({required this.heading, required this.rows});

  final String heading;
  final List<NoticeRow> rows;
}

/// The notification centre, drawn as the Directory list pattern: the All /
/// Unread chips (`.chipsrow`) with Mark all read, then each section as a
/// heading over one soft list. Rows deep-link through [NoticeRow.onTap].
///
/// [showIllustration] used to draw the design's SAMPLE caption; the redesign
/// draws no sample text, so it is kept only for callers that still pass it.
class NotificationCentre extends StatefulWidget {
  const NotificationCentre({
    required this.sections,
    required this.onMarkAllRead,
    this.showIllustration = false,
    super.key,
  });

  final List<NoticeSection> sections;
  final VoidCallback onMarkAllRead;
  final bool showIllustration;

  @override
  State<NotificationCentre> createState() => _NotificationCentreState();
}

class _NotificationCentreState extends State<NotificationCentre> {
  bool _unreadOnly = false;

  int get _unread => widget.sections
      .expand((NoticeSection section) => section.rows)
      .where((NoticeRow row) => row.unread)
      .length;

  @override
  Widget build(BuildContext context) {
    final List<NoticeSection> visible = <NoticeSection>[
      for (final NoticeSection section in widget.sections)
        if (_rows(section).isNotEmpty)
          NoticeSection(heading: section.heading, rows: _rows(section)),
    ];
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
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    SoftChoiceChip(
                      label: 'All',
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false),
                    ),
                    SoftChoiceChip(
                      label: 'Unread · $_unread',
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
              ),
              if (_unread > 0)
                Flexible(
                  child: AuthLink(
                    'Mark all read',
                    alignment: Alignment.centerRight,
                    onPressed: widget.onMarkAllRead,
                  ),
                ),
            ],
          ),
          for (var i = 0; i < visible.length; i++) ...<Widget>[
            SizedBox(height: i == 0 ? Spacing.section : Spacing.formGap),
            SettingsSectionTitle(visible[i].heading),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (var r = 0; r < visible[i].rows.length; r++) ...<Widget>[
                    if (r > 0) const SettingsDivider(),
                    _Row(row: visible[i].rows[r]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<NoticeRow> _rows(NoticeSection section) => _unreadOnly
      ? section.rows
            .where((NoticeRow row) => row.unread)
            .toList(growable: false)
      : section.rows;
}

/// A notification (Directory `.li`): the category's tile, the category label
/// (10.5 / 800, upper case), the title, when it was sent, and a blue dot
/// while unread. The dot is also said in words.
class _Row extends StatelessWidget {
  const _Row({required this.row});

  final NoticeRow row;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = row.onTap;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.listRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.section,
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
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                      fontWeight: row.unread
                          ? AppTypography.strong
                          : AppTypography.medium,
                    ),
                  ),
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
              Padding(
                padding: const EdgeInsets.only(
                  left: Spacing.sm,
                  top: Spacing.xs,
                ),
                child: Semantics(
                  label: 'Unread',
                  child: Container(
                    width: Spacing.sm,
                    height: Spacing.sm,
                    decoration: const BoxDecoration(
                      color: BrandColors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
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
