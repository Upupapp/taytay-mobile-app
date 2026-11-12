import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/resident_sector.dart';
import 'sectors_copy.dart';

/// Sectors and benefits (`Sectors.dc.html`), the settings-list pattern.
///
/// Stateless: `SectorsScreen` reads the two lists and passes them in, the
/// goldens and layout tests pass synthetic ones. Everything drawn comes from
/// the API; a mock-up line the API does not send is left out (D-215).
class SectorsCanvas extends StatelessWidget {
  const SectorsCanvas({
    required this.today,
    required this.environment,
    this.overview,
    this.failure,
    this.loading = false,
    this.onRetry,
    this.onApply,
    this.onBack,
    super.key,
  });

  /// "Now", for whether a recorded ID has lapsed.
  final DateTime today;
  final AppEnvironment environment;
  final SectorOverview? overview;
  final AppFailure? failure;

  /// The first read has not answered.
  final bool loading;
  final VoidCallback? onRetry;
  final ValueChanged<ResidentSector>? onApply;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final SectorOverview? overview = this.overview;
    final AppFailure? failure = this.failure;
    return SoftPage(
      title: SectorsCopy.title,
      subtitle: SectorsCopy.subtitle,
      offlineBanner: true,
      onBack: onBack,
      scrollKey: const Key('sectors-scroll'),
      children: <Widget>[
        const _Intro(),
        const SizedBox(height: Spacing.xl),
        if (loading && overview == null)
          const LoadingSkeleton(count: 3, semanticLabel: SectorsCopy.loading)
        else if (overview == null)
          FailureView(
            failure: failure ?? const UnexpectedFailure(),
            environment: environment,
            onRetry: onRetry,
          )
        else ...<Widget>[
          const SettingsSectionTitle(SectorsCopy.yoursHeading),
          _Yours(overview: overview, today: today, onApply: onApply),
          const SizedBox(height: Spacing.xl),
          const SettingsSectionTitle(SectorsCopy.applyHeading),
          _Offers(sectors: overview.offered, onApply: onApply),
          const SizedBox(height: Spacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
            child: Text(
              SectorsCopy.inPerson,
              style: AppTypography.small.copyWith(color: BrandColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}

/// CSS `.card.intro`: the gold heart and one sentence.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile.lucide(
            icon: TaytayIcons.heart,
            tone: TileTone.gold,
            tileSize: IconTileSize.small,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              SectorsCopy.intro,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `.list.mine`: recorded sectors, then applications still open.
class _Yours extends StatelessWidget {
  const _Yours({required this.overview, required this.today, this.onApply});

  final SectorOverview overview;
  final DateTime today;
  final ValueChanged<ResidentSector>? onApply;

  static String? _date(DateTime? instant) =>
      instant == null ? null : ManilaTime.formatDate(instant);

  @override
  Widget build(BuildContext context) {
    // Nothing recorded is said even beside an application being checked: the
    // list stays empty until the office links the account on its first
    // approval, and a resident should not read that as a lost record.
    final Widget? none = overview.recorded.isEmpty
        ? SoftCard(
            key: const Key('sectors-none'),
            child: Text(
              SectorsCopy.none,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
          )
        : null;
    if (overview.isEmpty) return none ?? const SizedBox.shrink();
    final ValueChanged<ResidentSector>? onApply = this.onApply;
    final Widget list = SettingsList(
      children: <Widget>[
        for (final OwnSector own in overview.recorded)
          _row(
            key: Key('sectors-own-${own.sector.name}'),
            sector: own.sector,
            detail: SectorsCopy.ownDetail(
              since: _date(own.since),
              lastFour: own.idLastFour,
              validUntil: _date(own.validUntil),
            ),
            status: own.lapsedOn(today)
                ? SectorsCopy.lapsed
                : SectorsCopy.recorded,
            tone: own.lapsedOn(today) ? PillTone.gold : PillTone.green,
            tile: BrandColors.green50,
            ink: BrandColors.green,
          ),
        for (final SectorApplication application in overview.open)
          if (application.status == SectorApplicationStatus.returned)
            _row(
              key: Key('sectors-returned-${application.sector.name}'),
              sector: application.sector,
              detail: SectorsCopy.returnedDetail(application.reason),
              status: SectorsCopy.returned,
              tone: PillTone.red,
              tile: BrandColors.red50,
              ink: BrandColors.redInk,
              onTap: onApply == null ? null : () => onApply(application.sector),
            )
          else
            _row(
              key: Key('sectors-pending-${application.sector.name}'),
              sector: application.sector,
              detail: SectorsCopy.appliedOn(_date(application.submittedAt)),
              status: SectorsCopy.beingChecked,
              tone: PillTone.gold,
              tile: BrandColors.gold50,
              ink: BrandColors.goldInk,
            ),
      ],
    );
    if (none == null) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        none,
        const SizedBox(height: Spacing.md),
        list,
      ],
    );
  }

  Widget _row({
    required Key key,
    required ResidentSector sector,
    required String detail,
    required String status,
    required PillTone tone,
    required Color tile,
    required Color ink,
    VoidCallback? onTap,
  }) {
    return _SectorRow(
      key: key,
      title: SectorsCopy.label(sector),
      detail: detail,
      status: status,
      tone: tone,
      tile: tile,
      ink: ink,
      onTap: onTap,
    );
  }
}

/// CSS `.list .li`: a `SettingsRow` whose status pill sits under the detail
/// rather than at the end, so "Being checked" at 200% text on a 360 dp phone
/// wraps instead of pushing the row off the screen. Read as one label:
/// sector, detail, status.
class _SectorRow extends StatelessWidget {
  const _SectorRow({
    required this.title,
    required this.detail,
    required this.status,
    required this.tone,
    required this.tile,
    required this.ink,
    this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final String status;
  final PillTone tone;
  final Color tile;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = this.onTap;
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.listRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.section,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SettingsIcon(icon: TaytayIcons.users, fill: tile, ink: ink),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  if (detail.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      detail,
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  StatusPill(label: status, tone: tone),
                ],
              ),
            ),
            if (onTap != null) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              const TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: '',
                excludeSemantics: true,
                color: BrandColors.chevron,
                size: IconSizes.sm,
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: SectorsCopy.join(<String>[title, detail, status]),
      onTap: onTap,
      child: ExcludeSemantics(
        child: onTap == null
            ? row
            : Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, child: row),
              ),
      ),
    );
  }
}

/// CSS `.applyg`: one card per sector the page offers.
class _Offers extends StatelessWidget {
  const _Offers({required this.sectors, this.onApply});

  final List<ResidentSector> sectors;
  final ValueChanged<ResidentSector>? onApply;

  @override
  Widget build(BuildContext context) {
    if (sectors.isEmpty) {
      return SoftCard(
        key: const Key('sectors-nothing-to-apply'),
        child: Text(
          SectorsCopy.nothingToApply,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
        ),
      );
    }
    final ValueChanged<ResidentSector>? onApply = this.onApply;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ResidentSector sector in sectors) ...<Widget>[
          if (sector != sectors.first) const SizedBox(height: Spacing.md),
          SoftCard(
            key: Key('sectors-apply-${sector.name}'),
            onTap: onApply == null ? null : () => onApply(sector),
            semanticLabel: SectorsCopy.join(<String>[
              SectorsCopy.label(sector),
              SectorsCopy.offer(sector),
            ]),
            child: Row(
              children: <Widget>[
                IconTile.lucide(icon: _icon(sector), tone: _tone(sector)),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        SectorsCopy.label(sector),
                        style: AppTypography.listTitle.copyWith(
                          color: BrandColors.ink,
                        ),
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        SectorsCopy.offer(sector),
                        style: AppTypography.listDetail.copyWith(
                          color: BrandColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                const TaytayIcon(
                  icon: TaytayIcons.chevronRight,
                  semanticLabel: '',
                  excludeSemantics: true,
                  color: BrandColors.chevron,
                  size: IconSizes.sm,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

IconData _icon(ResidentSector sector) => switch (sector) {
  ResidentSector.seniorCitizen => TaytayIcons.userRound,
  ResidentSector.pwd => TaytayIcons.accessibility,
  ResidentSector.soloParent => TaytayIcons.usersRound,
};

TileTone _tone(ResidentSector sector) => switch (sector) {
  ResidentSector.seniorCitizen => TileTone.navy,
  ResidentSector.pwd => TileTone.sky,
  ResidentSector.soloParent => TileTone.gold,
};
