import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
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
      appBar: AppBar(title: const Text('Request status')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.trackAssistanceRequests,
          child: switch ((_idIsValid, _loading, detail)) {
            (false, _, _) => _Unavailable(
              message: DeepLinkRejection.invalidIdentifier.residentMessage,
            ),
            (_, true, null) => const AppLoadingView(
              message: 'Opening your request…',
            ),
            (_, _, null) => _Unavailable(
              message:
                  'Taytay LGU has not switched on request tracking in this app '
                  'yet. The municipal hall can tell you where your request '
                  'stands.',
              onRetry: _load,
            ),
            (_, _, final AssistanceCaseDetail loaded) => RefreshIndicator(
              onRefresh: _load,
              child: _Case(detail: loaded, requestId: widget.requestId),
            ),
          },
        ),
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

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        _StatusCard(request: request),
        const SizedBox(height: Spacing.lg),

        // The outcome reason, only when the office chose to publish one.
        if (detail.outcomeReason != null) ...<Widget>[
          AppBanner(
            tone: BannerTone.warning,
            title: 'What Taytay LGU said',
            message: detail.outcomeReason!,
          ),
          const SizedBox(height: Spacing.lg),
        ],

        if (detail.release != null && !detail.release!.isEmpty) ...<Widget>[
          ReleaseCard(release: detail.release!),
          const SizedBox(height: Spacing.lg),
        ],

        if (detail.referral != null) ...<Widget>[
          ReferralCard(referral: detail.referral!),
          const SizedBox(height: Spacing.lg),
        ],

        if (detail.nextActions.isNotEmpty) ...<Widget>[
          _NextActions(actions: detail.nextActions, requestId: requestId),
          const SizedBox(height: Spacing.lg),
        ],

        _Timeline(entries: detail.timeline),
      ],
    );
  }
}

/// Where the request stands, and whose turn it is.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = request.state;
    final waitingOnResident = state?.needsResident ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              requestStatusLabel(state),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: waitingOnResident
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(requestStatusMeaning(state), style: theme.textTheme.bodyMedium),
          const SizedBox(height: Spacing.md),
          const Divider(),
          const SizedBox(height: Spacing.sm),

          _Line(label: 'Service', value: request.serviceCode),
          if (request.referenceNumber != null)
            _Line(label: 'Reference', value: request.referenceNumber!),
          if (request.submittedAt != null)
            _Line(label: 'Sent', value: formatCaseDate(request.submittedAt!)),
          // The office's own vocabulary, kept visible so a resident and a clerk
          // are talking about the same thing. Labelled as such rather than
          // presented as the status, which is the friendly line above.
          _Line(
            label: 'Status code used by the office',
            value: request.rawState,
          ),
        ],
      ),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('What to do next', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
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
    final theme = Theme.of(context);
    final destination = _destination;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(action.label, style: theme.textTheme.titleSmall),
          if (action.detail != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(action.detail!, style: theme.textTheme.bodySmall),
          ],
          if (destination != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            AppButton(
              label: 'Open',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.goNamed(
                destination.routeName,
                pathParameters: <String, String>{'requestId': requestId},
              ),
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
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Text(
        'Taytay LGU has not recorded any updates on this yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Newest first for reading; the server's order is preserved in the model so
    // the app and a support conversation agree on what happened when.
    final ordered = entries.reversed.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('History', style: theme.textTheme.titleMedium),
        ),
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
    final theme = Theme.of(context);
    final accent = isLatest
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The rail is decoration; every row states its own date and summary in
          // text, so nothing here depends on seeing the line.
          ExcludeSemantics(
            child: Column(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(entry.summary, style: theme.textTheme.bodyLarge),
                  if (entry.detail != null) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(entry.detail!, style: theme.textTheme.bodySmall),
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

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
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
    return StatusView(
      title: 'This request is not available',
      kind: StatusKind.empty,
      icon: Icons.assignment_outlined,
      message: message,
      primaryAction: onRetry == null
          ? null
          : TextButton(
              onPressed: () => onRetry!(),
              child: const Text('Check again'),
            ),
      secondaryAction: TextButton(
        onPressed: () => context.goNamed(AppRoute.requests.routeName),
        child: const Text('See my requests'),
      ),
    );
  }
}

// Date formatting moved to `release_and_referral.dart` when the release card
// and the history list needed the same rendering. One record should not print
// three different ways.
