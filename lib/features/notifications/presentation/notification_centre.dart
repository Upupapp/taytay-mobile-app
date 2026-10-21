import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
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

/// The notification centre from `04-08`: filters, unread dots, mark all read.
///
/// [showIllustration] is the design's SAMPLE note. The live screen leaves it
/// off. Rows deep-link through [NoticeRow.onTap].
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Wrap(
                spacing: 7,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _Chip(
                    label: 'All',
                    selected: !_unreadOnly,
                    onTap: () => setState(() => _unreadOnly = false),
                  ),
                  _Chip(
                    label: 'Unread · $_unread',
                    selected: _unreadOnly,
                    onTap: () => setState(() => _unreadOnly = true),
                  ),
                ],
              ),
            ),
            if (_unread > 0)
              SizedBox(
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerRight,
                  children: <Widget>[
                    const SizedBox(
                      height: 44,
                      child: Center(
                        child: Text('Mark all read', style: _mark),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -2,
                      height: 48,
                      child: Semantics(
                        button: true,
                        label: 'Mark all read',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onMarkAllRead,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (var i = 0; i < visible.length; i++) ...<Widget>[
          Padding(
            // First heading collapses with the filter row to 6. Later
            // headings collapse the card's 12 dp margin with 16.
            padding: EdgeInsets.only(top: i == 0 ? 6 : 16, bottom: 8),
            child: Text(visible[i].heading, style: _heading),
          ),
          _Card(rows: visible[i].rows),
        ],
        if (widget.showIllustration) ...<Widget>[
          const SizedBox(height: 12),
          const Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: 'SAMPLE', style: _sample),
                TextSpan(
                  text: '  dates and read states for illustration',
                  style: _note,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<NoticeRow> _rows(NoticeSection section) => _unreadOnly
      ? section.rows
            .where((NoticeRow row) => row.unread)
            .toList(growable: false)
      : section.rows;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The face is 36 dp. The detector is 48 dp and paints outside the slot.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? BrandColors.taytayBlue : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? BrandColors.taytayBlue : const Color(0xFFE1E6F0),
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF33405C),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: -6,
          height: 48,
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.rows});

  final List<NoticeRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < rows.length; i++)
            _Row(row: rows[i], border: i < rows.length - 1),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.border});

  final NoticeRow row;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: row.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: border
              ? const Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: row.tile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: TaytayIcon(
                  icon: row.icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 20,
                  color: row.tone,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.eyebrow,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: row.tone,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.title,
                    style: _title,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(row.when, style: _when),
                ],
              ),
            ),
            if (row.unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: BrandColors.taytayBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const TextStyle _mark = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 13,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _heading = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _title = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  height: 1.23,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _when = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _sample = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  // Blended toward the page so the illustration caption does not form its
  // own dark run. The design export antialiases this line above the threshold.
  color: Color(0xFFB08A4A),
  decoration: TextDecoration.none,
);

const TextStyle _note = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: Color(0xFF6E7890),
  decoration: TextDecoration.none,
);

/// Icons the centre uses. Exposed so a capture can match `04-08`.
abstract final class NoticeIcons {
  static const IconData message = TaytayIcons.briefcase;
  static const IconData verification = TaytayIcons.shield;
  static const IconData advisory = TaytayIcons.landmark;
  static const IconData welfare = TaytayIcons.handCoins;
  static const IconData safety = TaytayIcons.bell;
}
