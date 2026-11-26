import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/issuance_copy.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/issuance_type.dart';
import 'issuance_widgets.dart';

/// One document type: what it is, what it needs, what it costs, how long it
/// takes and how to claim it.
///
/// Drawn as the Office detail pattern without a photo: the blue header with
/// the back control over the white sheet, the facts as `.fact` rows.
class IssuanceTypeScreen extends StatefulWidget {
  const IssuanceTypeScreen({required this.typeId, super.key});

  final String typeId;

  @override
  State<IssuanceTypeScreen> createState() => _IssuanceTypeScreenState();
}

class _IssuanceTypeScreenState extends State<IssuanceTypeScreen>
    with LiveRefresh<IssuanceTypeScreen> {
  bool _started = false;
  AppFailure? _failure;
  IssuanceType? _type;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    // The catalogue's topic, as on the catalogue screen (D-221).
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.issuanceRequests,
    }, () => unawaited(_reloadQuietly()));
  }

  /// A re-read for a change (D-218): only a type read back for the id still
  /// on screen replaces it; a failure keeps the page and says nothing.
  Future<void> _reloadQuietly() async {
    if (_type == null) return;
    final String id = widget.typeId;
    final Result<IssuanceType> result = await AppDependencies.of(
      context,
    ).issuanceRepository.loadType(id);
    if (!mounted || id != widget.typeId || _type == null) return;
    if (result case Ok(:final value)) setState(() => _type = value);
  }

  // The router may keep this State when only the id changes (a link from one
  // type to another). The new type is read rather than the old one kept.
  @override
  void didUpdateWidget(IssuanceTypeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.typeId == widget.typeId) return;
    _type = null;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    final Result<IssuanceType> result = await AppDependencies.of(
      context,
    ).issuanceRepository.loadType(widget.typeId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _type = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    final IssuanceType? type = _type;
    final AppFailure? failure = _failure;
    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (BuildContext context, Widget? _) {
        final AccessDecision decision = AccessPolicy.evaluate(
          session: dependencies.session.state,
          requirement: AccessRequirement.verified,
        );
        final AppStrings strings = AppStrings.of(context);
        return IssuanceScaffold(
          title: strings.issuanceTypeTitle,
          white: failure == null,
          footer: type != null && decision is AccessAllowed
              ? PrimaryButton(
                  key: const Key('issuance-start-request'),
                  label: strings.issuanceRequestThis,
                  onPressed: () => context.pushNamed(
                    AppRoute.issuanceForm.routeName,
                    pathParameters: <String, String>{'typeId': type.id},
                  ),
                )
              : null,
          body: failure != null
              ? IssuanceLoadFailure(
                  failure: failure,
                  onRetry: _load,
                  failedTitle: strings.issuanceLoadFailedDocument,
                )
              : type == null
              ? ListView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  children: <Widget>[
                    LoadingSkeleton(
                      layout: SkeletonLayout.detail,
                      count: 1,
                      semanticLabel: strings.issuanceTypeLoading,
                    ),
                  ],
                )
              : IssuanceTypeDetails(type: type, decision: decision),
        );
      },
    );
  }
}

/// The body of the type screen. Separate so the design frames can draw it
/// from sample data without a repository.
class IssuanceTypeDetails extends StatelessWidget {
  const IssuanceTypeDetails({
    required this.type,
    required this.decision,
    super.key,
  });

  final IssuanceType type;
  final AccessDecision decision;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final String? description = type.description;
    final String? claim = type.claimInstructions;
    return ListView(
      padding: EdgeInsets.only(
        bottom: Spacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        DetailSheet(
          children: <Widget>[
            IssuanceAccessNotice(decision: decision),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const IconTile.glyph(
                  glyph: TaytayGlyph.document,
                  tileSize: IconTileSize.large,
                ),
                const SizedBox(width: Spacing.section),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          type.name,
                          style: AppTypography.pageTitle.copyWith(
                            color: BrandColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxs),
                      IssuanceText(type.officeName, color: BrandColors.muted),
                    ],
                  ),
                ),
              ],
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: Spacing.section),
              IssuanceText(description),
            ],
            const SizedBox(height: Spacing.sm),
            DetailFactRow(
              icon: TaytayIcons.handCoins,
              label: strings.issuanceFeeLabel,
              value: issuanceFeeText(strings, type.feeCentavos),
            ),
            DetailFactRow(
              icon: TaytayIcons.clock,
              label: strings.issuanceProcessingLabel,
              value: issuanceProcessingText(strings, type.processingDays),
              divider: false,
            ),
            const SizedBox(height: Spacing.formGap),
            IssuanceCard(
              title: strings.issuanceWhatToSend,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (type.requirements.isEmpty)
                    IssuanceText(strings.issuanceNoFilesNeeded),
                  for (final IssuanceRequirement requirement
                      in type.requirements)
                    _RequirementLine(requirement: requirement),
                  const SizedBox(height: Spacing.md),
                  IssuanceText(
                    strings.issuanceSendEachAs(
                      acceptedFilesText(strings, type.uploadPolicy),
                    ),
                    color: BrandColors.muted,
                    small: true,
                  ),
                ],
              ),
            ),
            IssuanceCard(
              title: strings.issuanceHowToClaim,
              child: IssuanceText(claim ?? strings.issuanceClaimFallback),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.requirement});

  final IssuanceRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final String? hint = requirement.hint;
    final String need = requirement.required
        ? strings.applyObligationRequired
        : strings.applyObligationOptional;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: Spacing.xxs),
            child: TaytayIcon(
              icon: TaytayIcons.paperclip,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xxs,
              color: BrandColors.blue,
            ),
          ),
          const SizedBox(width: Spacing.sm + Spacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${requirement.label} · $need',
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                    height: 1.5,
                  ),
                ),
                if (hint != null)
                  IssuanceText(hint, color: BrandColors.muted, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
