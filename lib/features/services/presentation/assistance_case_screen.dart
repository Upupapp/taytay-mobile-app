import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/assistance_case.dart';
import '../domain/request_status_copy.dart';
import '../domain/service_request_repository.dart';
import 'release_and_referral.dart';

/// One request: where it stands, what happens next, and what has happened so far.
///
/// ---
///
/// **The canonical status is never lost.** The screen renders resident-friendly
/// wording, and keeps the server's own lifecycle value visible as a reference a
/// resident can quote at the counter. Acceptance 1 of TAB 17 is exactly that
/// traceability — copy is a rendering of the status, not a replacement for it.
///
/// **Nothing internal has a place to appear.** There is no widget here for an
/// assessment score, a caseworker note, a risk flag, a handoff or an audit
/// entry, because `AssistanceCaseDetail` has no field to carry one. A screen
/// cannot leak what its model cannot hold.
///
/// **This screen never acts on the case.** It is a push-notification target, and
/// a link must not submit, cancel or confirm anything on somebody's behalf. Its
/// actions navigate.
///
/// Drawn as the detail pattern (Office.dc) without a photo: the blue header
/// with the back control, then the white sheet. It has no pill actions,
/// because nothing here acts.
class AssistanceCaseScreen extends StatefulWidget {
  const AssistanceCaseScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<AssistanceCaseScreen> createState() => _AssistanceCaseScreenState();
}

class _AssistanceCaseScreenState extends State<AssistanceCaseScreen> {
  bool _loading = true;
  AppFailure? _failure;
  AssistanceCaseDetail? _detail;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.requestId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_detail == null && _failure == null && _idIsValid) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceRequestRepository;
    setState(() => _loading = true);

    final result = await repository.loadOwnCase(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (detail) {
          _detail = detail;
          _failure = null;
        },
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: BrandColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const BlueHeader(title: 'Request status', showBack: true),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.trackAssistanceRequests,
              child: switch ((_idIsValid, _loading, detail)) {
                (false, _, _) => _Unavailable(
                  message: DeepLinkRejection.invalidIdentifier.residentMessage,
                ),
                (_, true, null) => ListView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  children: const <Widget>[
                    LoadingSkeleton(
                      layout: SkeletonLayout.detail,
                      count: 1,
                      semanticLabel: 'Opening your request…',
                    ),
                  ],
                ),
                (_, _, null) => _Unavailable(
                  message:
                      'Taytay LGU has not switched on request tracking in '
                      'this app yet. The municipal hall can tell you where '
                      'your request stands.',
                  onRetry: _load,
                ),
                (_, _, final AssistanceCaseDetail loaded) => RefreshIndicator(
                  onRefresh: _load,
                  child: _Case(detail: loaded, requestId: widget.requestId),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({required this.detail, required this.requestId});

  final AssistanceCaseDetail detail;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final request = detail.request;
    final String? reason = detail.outcomeReason;
    final release = detail.release;
    final referral = detail.referral;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: Spacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        DetailSheet(
          children: <Widget>[
            _Status(request: request),

            // The outcome reason, only when the office chose to publish one.
            if (reason != null) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              CasePanel(
                icon: TaytayIcons.info,
                title: 'What Taytay LGU said',
                children: <Widget>[
                  Text(
                    reason,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ],
              ),
            ],

            if (release != null && !release.isEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              ReleaseCard(release: release),
            ],

            if (referral != null) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              ReferralCard(referral: referral),
            ],

            if (detail.nextActions.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              _NextActions(actions: detail.nextActions, requestId: requestId),
            ],

            const SizedBox(height: Spacing.formGap),
            _Timeline(entries: detail.timeline),
          ],
        ),
      ],
    );
  }
}

/// Where the request stands, and whose turn it is.
class _Status extends StatelessWidget {
  const _Status({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final state = request.state;
    final waitingOnResident = state?.needsResident ?? false;
    final String? reference = request.referenceNumber;
    final DateTime? sent = request.submittedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTile.glyph(
              glyph: TaytayGlyph.document,
              tone: waitingOnResident ? TileTone.gold : TileTone.blue,
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
                      requestStatusLabel(state),
                      style: AppTypography.pageTitle.copyWith(
                        color: waitingOnResident
                            ? BrandColors.blue
                            : BrandColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    requestStatusMeaning(state),
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.formGap),
        const Divider(height: 1, thickness: 1, color: BrandColors.divider),
        if (request.serviceCode.isNotEmpty)
          DetailFactRow(
            icon: TaytayIcons.handHeart,
            label: 'Service',
            value: request.serviceCode,
          ),
        if (reference != null && reference.isNotEmpty)
          DetailFactRow(
            icon: TaytayIcons.fileText,
            label: 'Reference',
            value: reference,
          ),
        if (sent != null)
          DetailFactRow(
            icon: TaytayIcons.calendar,
            label: 'Sent',
            value: formatCaseDate(sent),
          ),
        // The office's own vocabulary, kept visible so a resident and a clerk
        // are talking about the same thing. Labelled as such rather than
        // presented as the status, which is the friendly line above.
        if (request.rawState.isNotEmpty)
          DetailFactRow(
            icon: TaytayIcons.info,
            label: 'Status code used by the office',
            value: request.rawState,
          ),
      ],
    );
  }
}

/// What the resident can do next — **only what the backend offered**.
class _NextActions extends StatelessWidget {
  const _NextActions({required this.actions, required this.requestId});

  final List<CaseNextAction> actions;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionTitle('What to do next'),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: _NextActionTile(action: action, requestId: requestId),
          ),
      ],
    );
  }
}

class _NextActionTile extends StatelessWidget {
  const _NextActionTile({required this.action, required this.requestId});

  final CaseNextAction action;
  final String requestId;

  /// Where this action goes, or `null` when the app has nowhere to send them.
  ///
  /// Only two kinds have a destination in this build. The rest are **described,
  /// not linked** — inventing a destination for "contact office" would mean the
  /// app choosing which office, and it does not know.
  AppRoute? get _destination => switch (action.kind.known) {
    NextActionKind.uploadRequirement => AppRoute.requestRequirements,
    NextActionKind.provideInformation => AppRoute.requestRequirements,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    final String? detail = action.detail;

    return SoftCard(
      filled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            action.label,
            style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(
              detail,
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ],
          if (destination != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            FilledButton(
              style: TaytayButtonStyles.soft(),
              onPressed: () => context.goNamed(
                destination.routeName,
                pathParameters: <String, String>{'requestId': requestId},
              ),
              child: const Text('Open'),
            ),
          ],
        ],
      ),
    );
  }
}

/// What has happened, newest first.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<CaseTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Taytay LGU has not recorded any updates on this yet.',
        style: AppTypography.bodyStyle.copyWith(color: BrandColors.muted),
      );
    }

    // Newest first for reading; the server's order is preserved in the model so
    // the app and a support conversation agree on what happened when.
    final ordered = entries.reversed.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionTitle('History'),
        const SizedBox(height: Spacing.md),
        for (var index = 0; index < ordered.length; index++)
          _TimelineRow(
            entry: ordered[index],
            isLatest: index == 0,
            isLast: index == ordered.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLatest,
    required this.isLast,
  });

  final CaseTimelineEntry entry;
  final bool isLatest;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final String? detail = entry.detail;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The rail is decoration; every row states its own date and summary in
          // text, so nothing here depends on seeing the line.
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Column(
                children: <Widget>[
                  Container(
                    width: Spacing.md,
                    height: Spacing.md,
                    decoration: BoxDecoration(
                      color: isLatest ? BrandColors.blue : BrandColors.line2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: Spacing.xxs,
                        color: BrandColors.divider,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    formatCaseDate(entry.occurredAt),
                    style: AppTypography.small.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.muted,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    entry.summary,
                    style: AppTypography.bodyStyle.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.ink,
                    ),
                  ),
                  if (detail != null) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      detail,
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final Future<void> Function()? retry = onRetry;
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        EmptyState(
          title: 'This request is not available',
          message: message,
          actionLabel: retry == null ? null : 'Check again',
          onAction: retry,
          boxed: true,
        ),
        const SizedBox(height: Spacing.sm),
        Center(
          child: TextButton(
            onPressed: () => context.goNamed(AppRoute.requests.routeName),
            child: const Text('See my requests'),
          ),
        ),
      ],
    );
  }
}

// Date formatting moved to `release_and_referral.dart` when the release card
// and the history list needed the same rendering. One record should not print
// three different ways.
