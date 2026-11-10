import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/issuance_terms.dart';
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

class _IssuanceTypeScreenState extends State<IssuanceTypeScreen> {
  bool _started = false;
  AppFailure? _failure;
  IssuanceType? _type;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
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
        return IssuanceScaffold(
          title: 'Document details',
          white: failure == null,
          footer: type != null && decision is AccessAllowed
              ? PrimaryButton(
                  key: const Key('issuance-start-request'),
                  label: 'Request this document',
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
                  what: 'this document',
                )
              : type == null
              ? ListView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  children: const <Widget>[
                    LoadingSkeleton(
                      layout: SkeletonLayout.detail,
                      count: 1,
                      semanticLabel: 'Opening this document',
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
              label: 'Fee',
              value: issuanceFeeLine(type.feeCentavos),
            ),
            DetailFactRow(
              icon: TaytayIcons.clock,
              label: 'Processing time',
              value: issuanceProcessingLine(type.processingDays),
              divider: false,
            ),
            const SizedBox(height: Spacing.formGap),
            IssuanceCard(
              title: 'What you need to send',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (type.requirements.isEmpty)
                    const IssuanceText(
                      'No files. The purpose of your request is enough.',
                    ),
                  for (final IssuanceRequirement requirement
                      in type.requirements)
                    _RequirementLine(requirement: requirement),
                  const SizedBox(height: Spacing.md),
                  IssuanceText(
                    'Send each one as a photo or a file: '
                    '${acceptedFilesLine(type.uploadPolicy)}.',
                    color: BrandColors.muted,
                    small: true,
                  ),
                ],
              ),
            ),
            IssuanceCard(
              title: 'How to claim it',
              child: IssuanceText(
                claim ??
                    'The office will tell you here when and where to claim '
                        'it, once it is ready.',
              ),
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
    final String? hint = requirement.hint;
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
                  '${requirement.label} · '
                  '${requirement.required ? 'Required' : 'Optional'}',
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
