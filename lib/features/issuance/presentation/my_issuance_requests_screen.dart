import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';
import 'issuance_widgets.dart';

/// The resident's own document requests, newest first.
///
/// A row carries the reference, the document, the office and the status. It
/// never carries the purpose: what a resident wrote is read on the request
/// itself, behind one more tap, on a phone a household may share.
class MyIssuanceRequestsScreen extends StatefulWidget {
  const MyIssuanceRequestsScreen({super.key});

  @override
  State<MyIssuanceRequestsScreen> createState() =>
      _MyIssuanceRequestsScreenState();
}

class _MyIssuanceRequestsScreenState extends State<MyIssuanceRequestsScreen> {
  bool _started = false;
  bool _loading = true;
  bool _loadingMore = false;
  AppFailure? _failure;
  AppFailure? _moreFailure;
  final List<IssuanceRequestSummary> _items = <IssuanceRequestSummary>[];
  String? _next;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
      _moreFailure = null;
    });
    final Result<Paginated<IssuanceRequestSummary>> result =
        await AppDependencies.of(context).issuanceRepository.listOwn();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _items
            ..clear()
            ..addAll(value.items);
          _next = value.hasMore ? value.nextCursor : null;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _more() async {
    final String? cursor = _next;
    if (cursor == null || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailure = null;
    });
    final Result<Paginated<IssuanceRequestSummary>> result =
        await AppDependencies.of(
          context,
        ).issuanceRepository.listOwn(cursor: cursor);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      switch (result) {
        case Ok(:final value):
          _items.addAll(value.items);
          _next = value.hasMore ? value.nextCursor : null;
        case Err(:final failure):
          _moreFailure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppFailure? failure = _failure;
    return IssuanceScaffold(
      title: 'My document requests',
      footer: PrimaryButton(
        key: const Key('issuance-new-request'),
        label: 'Request a document',
        onPressed: () =>
            context.pushNamed(AppRoute.issuanceCatalogue.routeName),
      ),
      body: failure != null
          ? IssuanceLoadFailure(
              failure: failure,
              onRetry: _load,
              what: 'your requests',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: issuanceListPadding(context),
                children: <Widget>[
                  if (_loading && _items.isEmpty)
                    const LoadingSkeleton(
                      layout: SkeletonLayout.cards,
                      semanticLabel: 'Loading your requests',
                    )
                  else if (_items.isEmpty)
                    const EmptyState(
                      title: 'No document requests yet',
                      message:
                          'When you request a certificate or a copy from a '
                          'municipal office, you can follow it here.',
                      boxed: true,
                    )
                  else ...<Widget>[
                    for (final IssuanceRequestSummary item in _items)
                      IssuanceRequestRow(
                        item: item,
                        onTap: () => context.pushNamed(
                          AppRoute.issuanceRequestDetail.routeName,
                          pathParameters: <String, String>{
                            'requestId': item.id,
                          },
                        ),
                      ),
                    if (_next != null)
                      SecondaryButton(
                        key: const Key('issuance-load-more'),
                        label: _loadingMore
                            ? 'Loading…'
                            : _moreFailure != null
                            ? 'Could not load more. Try again'
                            : 'Show older requests',
                        onPressed: _loadingMore ? null : _more,
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// One request in the list (a soft card, Directory row type): the document,
/// the reference and office, the status in words and the date sent. Public so
/// the design frames can draw it.
class IssuanceRequestRow extends StatelessWidget {
  const IssuanceRequestRow({
    required this.item,
    required this.onTap,
    super.key,
  });

  final IssuanceRequestSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IssuanceStatus? status = item.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoftCard(
        key: Key('issuance-request-${item.id}'),
        padding: const EdgeInsets.fromLTRB(
          Spacing.section,
          Spacing.section,
          Spacing.md,
          Spacing.section,
        ),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            const IconTile.glyph(glyph: TaytayGlyph.document),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.typeName,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  IssuanceText(
                    '${item.referenceNumber} · ${item.officeName}',
                    color: BrandColors.muted,
                    small: true,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      IssuanceStatusChip(status: status),
                      Text(
                        'Sent ${issuanceDate(item.createdAt)}',
                        style: AppTypography.small.copyWith(
                          color: BrandColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const TaytayIcon(
              icon: TaytayIcons.chevronRight,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.chevron,
            ),
          ],
        ),
      ),
    );
  }
}
