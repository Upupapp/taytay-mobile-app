import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/issuance_terms.dart';
import '../domain/issuance_type.dart';
import 'issuance_widgets.dart';

/// One document type: what it is, what it needs, what it costs, how long it
/// takes and how to claim it.
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
              ? const Center(child: CircularProgressIndicator())
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
      padding: s3PagePadding,
      children: <Widget>[
        IssuanceAccessNotice(decision: decision),
        IssuanceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const IconTile(
                    icon: TaytayIcons.fileText,
                    fill: BrandColors.chipBlueBg,
                    ink: BrandColors.taytayBlue,
                    size: 44,
                    iconSize: 22,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          header: true,
                          child: Text(
                            type.name,
                            style: s3Type(
                              16,
                              AppTypography.black,
                              BrandColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        IssuanceText(type.officeName),
                      ],
                    ),
                  ),
                ],
              ),
              if (description != null) ...<Widget>[
                const SizedBox(height: 10),
                IssuanceText(description, color: BrandColors.textPrimary),
              ],
              const SizedBox(height: 6),
              IssuanceFact(
                icon: TaytayIcons.handCoins,
                text: issuanceFeeLine(type.feeCentavos),
              ),
              IssuanceFact(
                icon: TaytayIcons.clock,
                text: issuanceProcessingLine(type.processingDays),
              ),
            ],
          ),
        ),
        IssuanceCard(
          title: 'What you need to send',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (type.requirements.isEmpty)
                const IssuanceText(
                  'No files. The purpose of your request is enough.',
                ),
              for (final IssuanceRequirement requirement in type.requirements)
                _RequirementLine(requirement: requirement),
              const SizedBox(height: 8),
              IssuanceText(
                'Send each one as a photo or a file: '
                '${acceptedFilesLine(type.uploadPolicy)}.',
              ),
            ],
          ),
        ),
        IssuanceCard(
          title: 'How to claim it',
          child: IssuanceText(
            claim ??
                'The office will tell you here when and where to claim it, '
                    'once it is ready.',
            color: BrandColors.textPrimary,
          ),
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
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              TaytayIcons.paperclip,
              size: 16,
              color: BrandColors.taytayBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${requirement.label} · '
                  '${requirement.required ? 'Required' : 'Optional'}',
                  style: s3Type(
                    13,
                    AppTypography.strong,
                    BrandColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                if (hint != null) IssuanceText(hint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
