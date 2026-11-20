import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/own_assistance_request.dart';
import 'assistance_copy.dart';

/// My requests: the resident's own assistance requests (D-223), the
/// settings-list pattern.
///
/// Stateless: `MyRequestsScreen` reads the pages and passes them in; the
/// layout tests pass synthetic ones. The in-person sentence is drawn in every
/// frame, loading and failure included, so that what the page says never
/// depends on what the list holds (ADR 0003 C).
class MyRequestsCanvas extends StatelessWidget {
  const MyRequestsCanvas({
    required this.environment,
    this.items,
    this.failure,
    this.loading = false,
    this.hasMore = false,
    this.loadingMore = false,
    this.moreFailed = false,
    this.onRetry,
    this.onMore,
    this.onOpen,
    this.onBack,
    this.accountLinked,
    super.key,
  });

  final AppEnvironment environment;

  /// Null until the first read answers.
  final List<OwnAssistanceRequest>? items;
  final AppFailure? failure;

  /// The first read has not answered.
  final bool loading;

  /// The API said more exist (`has_more`).
  final bool hasMore;
  final bool loadingMore;
  final bool moreFailed;
  final VoidCallback? onRetry;
  final VoidCallback? onMore;
  final ValueChanged<OwnAssistanceRequest>? onOpen;
  final VoidCallback? onBack;

  /// `linked_to_office_record` from `GET /me`. Only `false` adds a line, under
  /// an empty list: an account the office has not linked reads an empty list,
  /// and saying so names the account's state, never a request's. True and
  /// unknown leave the empty state as D-223 drew it.
  final bool? accountLinked;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final List<OwnAssistanceRequest>? items = this.items;
    final ValueChanged<OwnAssistanceRequest>? onOpen = this.onOpen;
    return SoftPage(
      title: s.myRequestsTitle,
      subtitle: s.myRequestsSubtitle,
      offlineBanner: true,
      onBack: onBack,
      scrollKey: const Key('my-requests-scroll'),
      children: <Widget>[
        const InPersonNote(),
        const SizedBox(height: Spacing.xl),
        if (loading && items == null)
          LoadingSkeleton(count: 3, semanticLabel: s.myRequestsLoading)
        else if (items == null)
          FailureView(
            failure: failure ?? const UnexpectedFailure(),
            environment: environment,
            onRetry: onRetry,
          )
        else if (items.isEmpty) ...<Widget>[
          EmptyState(
            key: const Key('my-requests-empty'),
            title: s.myRequestsEmptyTitle,
            message: s.myRequestsEmptyMessage,
            boxed: true,
          ),
          if (accountLinked == false) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            SoftNote(
              key: const Key('my-requests-not-linked'),
              live: false,
              message: s.accountNotLinkedNote,
            ),
          ],
        ] else ...<Widget>[
          SettingsList(
            children: <Widget>[
              for (final OwnAssistanceRequest item in items)
                AssistanceRequestRow(
                  key: Key('my-request-${item.id}'),
                  request: item,
                  onTap: onOpen == null ? null : () => onOpen(item),
                ),
            ],
          ),
          if (hasMore) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            SecondaryButton(
              key: const Key('my-requests-more'),
              label: loadingMore
                  ? s.myRequestsLoadingMore
                  : moreFailed
                  ? s.myRequestsMoreFailed
                  : s.myRequestsShowOlder,
              onPressed: loadingMore ? null : onMore,
            ),
          ],
        ],
      ],
    );
  }
}

/// "Some requests are discussed only in person at the MSWDO." Shown to every
/// resident on every frame of My requests and of one request, so an empty
/// list, or a request that is not shown, gives nothing away (D-223).
class InPersonNote extends StatelessWidget {
  const InPersonNote({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftNote(
      key: const Key('my-requests-in-person'),
      // Not a live region: it is the same on every visit and announces
      // nothing that happened.
      live: false,
      message: AppStrings.of(context).myRequestsInPerson,
    );
  }
}

/// One request (a settings-list row): the programme, the reference, the
/// filing date and the status in words. Read as one label. The detail —
/// amounts, payout date and venue — is one tap further, on a phone a
/// household may share.
class AssistanceRequestRow extends StatelessWidget {
  const AssistanceRequestRow({required this.request, this.onTap, super.key});

  final OwnAssistanceRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final VoidCallback? onTap = this.onTap;
    final String programme = AssistanceCopy.programme(s, request);
    final String? filed = AssistanceCopy.date(request.filedAt);
    final String filedLine = filed == null ? '' : s.myRequestsFiled(filed);
    final String? channel = AssistanceCopy.channel(s, request.channel);
    final String status = AssistanceCopy.stage(s, request.stage);
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
            const SettingsIcon(icon: TaytayIcons.handHelping),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    programme,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  if (request.referenceNumber.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      request.referenceNumber,
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                  if (filedLine.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      filedLine,
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                  if (channel != null) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      channel,
                      key: const Key('my-request-channel-line'),
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  StageLine(stage: request.stage),
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
      label: AssistanceCopy.join(<String?>[
        programme,
        request.referenceNumber,
        filedLine,
        channel,
        status,
      ]),
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

/// A request's stage: an icon and the words, in the stage's ink. The words
/// carry the meaning; they wrap rather than truncate, because two of them are
/// sentences.
class StageLine extends StatelessWidget {
  const StageLine({required this.stage, this.large = false, super.key});

  final AssistanceStage stage;

  /// Body size, for the head of one request.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final Color ink = AssistanceCopy.ink(stage);
    final TextStyle base = large
        ? AppTypography.bodyStyle
        : AppTypography.small;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TaytayIcon(
          icon: AssistanceCopy.icon(stage),
          semanticLabel: '',
          excludeSemantics: true,
          size: IconSizes.sm,
          color: ink,
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Text(
            AssistanceCopy.stage(AppStrings.of(context), stage),
            key: const Key('my-request-stage'),
            style: base.copyWith(fontWeight: AppTypography.medium, color: ink),
          ),
        ),
      ],
    );
  }
}

/// One request (D-223): what was decided and when to come, never how it was
/// decided. Each fact is drawn only when the API sends it, and the API sends
/// it only in the status that gives it meaning.
class MyRequestDetailCanvas extends StatelessWidget {
  const MyRequestDetailCanvas({
    required this.environment,
    this.request,
    this.failure,
    this.loading = false,
    this.onRetry,
    this.onSeeAll,
    this.onBack,
    this.onAddDocuments,
    super.key,
  });

  final AppEnvironment environment;
  final OwnAssistanceRequest? request;
  final AppFailure? failure;
  final bool loading;
  final VoidCallback? onRetry;
  final VoidCallback? onSeeAll;
  final VoidCallback? onBack;

  /// Opens Add documents, for a returned request that names what is missing
  /// (D-226). Null draws no button.
  final VoidCallback? onAddDocuments;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final OwnAssistanceRequest? request = this.request;
    final AppFailure? failure = this.failure;
    return SoftPage(
      title: s.myRequestDetailTitle,
      offlineBanner: true,
      onBack: onBack,
      scrollKey: const Key('my-request-scroll'),
      children: <Widget>[
        if (loading && request == null)
          LoadingSkeleton(count: 2, semanticLabel: s.myRequestLoading)
        else if (request == null && failure is NotFoundFailure)
          // Said the same way whatever the reason, and never as an error:
          // the list simply does not carry it.
          EmptyState(
            key: const Key('my-request-not-shown'),
            title: s.myRequestNotShownTitle,
            message: s.myRequestNotShownMessage,
            actionLabel: s.myRequestsSeeAll,
            onAction: onSeeAll,
            boxed: true,
          )
        else if (request == null)
          FailureView(
            failure: failure ?? const UnexpectedFailure(),
            environment: environment,
            onRetry: onRetry,
          )
        else ...<Widget>[
          _Head(request: request),
          if (request.takesDocuments) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            _Missing(request: request, onAddDocuments: onAddDocuments),
          ],
          const SizedBox(height: Spacing.lg),
          _Facts(request: request),
        ],
        const SizedBox(height: Spacing.xl),
        const InPersonNote(),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.request});

  final OwnAssistanceRequest request;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return SoftCard(
      key: const Key('my-request-head'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AssistanceCopy.programme(s, request),
            style: AppTypography.cardTitle.copyWith(color: BrandColors.ink),
          ),
          const SizedBox(height: Spacing.md),
          StageLine(stage: request.stage, large: true),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.request});

  final OwnAssistanceRequest request;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final List<(Key, IconData, String, String?)> facts =
        <(Key, IconData, String, String?)>[
          (
            const Key('my-request-reference'),
            TaytayIcons.fileText,
            s.myRequestReference,
            request.referenceNumber.isEmpty ? null : request.referenceNumber,
          ),
          (
            const Key('my-request-filed'),
            TaytayIcons.calendar,
            s.myRequestFiledOn,
            AssistanceCopy.date(request.filedAt),
          ),
          (
            const Key('my-request-amount'),
            TaytayIcons.handCoins,
            s.myRequestApprovedAmount,
            AssistanceCopy.amount(request.approvedAmountCentavos),
          ),
          (
            const Key('my-request-payout-date'),
            TaytayIcons.calendar,
            s.myRequestPayoutDate,
            AssistanceCopy.date(request.payoutScheduledFor),
          ),
          (
            const Key('my-request-payout-venue'),
            TaytayIcons.mapPin,
            s.myRequestPayoutVenue,
            request.payoutVenue,
          ),
          (
            const Key('my-request-released'),
            TaytayIcons.circleCheck,
            s.myRequestReleasedOn,
            AssistanceCopy.date(request.releasedAt),
          ),
          (
            const Key('my-request-changed'),
            TaytayIcons.clock,
            s.myRequestStatusChangedOn,
            AssistanceCopy.date(request.statusChangedAt),
          ),
          (
            const Key('my-request-channel'),
            TaytayIcons.send,
            s.myRequestChannel,
            AssistanceCopy.channel(s, request.channel),
          ),
        ];
    final List<(Key, IconData, String, String)> shown =
        <(Key, IconData, String, String)>[
          for (final (Key, IconData, String, String?) fact in facts)
            if (fact.$4 case final String value when value.isNotEmpty)
              (fact.$1, fact.$2, fact.$3, value),
        ];
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < shown.length; i++)
            DetailFactRow(
              key: shown[i].$1,
              icon: shown[i].$2,
              label: shown[i].$3,
              value: shown[i].$4,
              divider: i < shown.length - 1,
            ),
        ],
      ),
    );
  }
}

/// A returned request's documents still needed, in the office's words for
/// residents, and Add documents (D-226). Never the office's remarks or why it
/// returned the request: the API sends neither.
class _Missing extends StatelessWidget {
  const _Missing({required this.request, this.onAddDocuments});

  final OwnAssistanceRequest request;
  final VoidCallback? onAddDocuments;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final VoidCallback? onAdd = onAddDocuments;
    return SoftCard(
      key: const Key('my-request-missing'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              s.myRequestMissingHeading,
              style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
            ),
          ),
          for (final MissingDocument document in request.missingDocuments)
            Padding(
              key: Key('my-request-missing-${document.code}'),
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${document.name} · ${AssistanceCopy.missingState(s, document.state)}',
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  if (document.instruction case final String instruction)
                    Text(
                      instruction,
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          if (onAdd != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            PrimaryButton(
              key: const Key('my-request-add-documents'),
              label: s.myRequestAddDocuments,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}
