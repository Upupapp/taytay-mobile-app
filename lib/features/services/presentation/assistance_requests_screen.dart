import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/assistance_history.dart';
import '../domain/request_status_copy.dart';
import 'release_and_referral.dart';

/// Everything the resident has asked Taytay LGU for — open and finished.
///
/// ---
///
/// **`/me/` only.** The endpoint takes no resident identifier, so there is no
/// code path here that could name another person's record, and none that could
/// be made to.
///
/// **One list with two scopes, not two screens.** "Where is my application?"
/// and "what did I receive last year?" are the same person asking about the same
/// records. Splitting them into separate destinations means a resident has to
/// know which one a request has moved to in order to find it — and the move
/// happens without warning, on a day the office decided something.
///
/// **What a citizen projection excludes.** The committed matrix says the detail
/// response carries *no assessment, no internal notes, no staff identities*.
/// Nothing on this screen has a field for any of them.
///
/// Drawn as the `List + search + filters` pattern (Directory.dc): the blue
/// header with the back control, the scope chips, the records as soft cards.
class AssistanceRequestsScreen extends StatefulWidget {
  const AssistanceRequestsScreen({super.key});

  @override
  State<AssistanceRequestsScreen> createState() =>
      _AssistanceRequestsScreenState();
}

class _AssistanceRequestsScreenState extends State<AssistanceRequestsScreen> {
  HistoryScope _scope = HistoryScope.open;

  bool _loading = true;
  AppFailure? _failure;
  Paginated<AssistanceHistoryEntry>? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == null && _failure == null) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceRequestRepository;
    setState(() => _loading = true);

    final result = await repository.listOwnHistory(scope: _scope);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (page) {
          _page = page;
          _failure = null;
        },
        onErr: (failure) {
          _page = null;
          _failure = failure;
        },
      );
    });
  }

  void _changeScope(HistoryScope scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _page = null;
      _failure = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const BlueHeader(title: 'My requests', showBack: true),
          Expanded(
            // Belt and braces with the route guard: the route is
            // verified-only, so this can only render for a verified resident
            // — but a screen that also states its own requirement keeps
            // working if it is ever reused inside a route with a weaker one.
            child: CapabilityGate(
              capability: ResidentCapability.trackAssistanceRequests,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ScopeSelector(scope: _scope, onChanged: _changeScope),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final page = _page;
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.section,
      Spacing.lg,
      Spacing.xl + MediaQuery.paddingOf(context).bottom,
    );

    if (_loading && page == null) {
      return ListView(
        padding: padding,
        children: const <Widget>[
          LoadingSkeleton(
            layout: SkeletonLayout.cards,
            semanticLabel: 'Loading your requests…',
          ),
        ],
      );
    }
    if (_failure != null) {
      // Not the same sentence as an empty list, deliberately. "You have never
      // received assistance from Taytay LGU" and "we could not reach Taytay
      // LGU" are different statements, and showing the first one wrongly tells
      // a resident their record does not exist.
      return ListView(
        padding: padding,
        children: <Widget>[
          ErrorState(
            title: 'Not available yet',
            message:
                'Taytay LGU has not switched on request tracking in this app '
                'yet. The municipal hall can tell you where your requests '
                'stand.',
            onRetry: _load,
            retryLabel: 'Check again',
            boxed: true,
          ),
        ],
      );
    }
    if (page == null || page.isEmpty) {
      return ListView(
        padding: padding,
        children: <Widget>[
          EmptyState(
            title: _scope.isPast
                ? 'Nothing finished yet'
                : 'You have no open requests',
            message: _scope.isPast
                ? 'Matters the municipal hall has closed will appear here. '
                      'This app does not take applications.'
                : 'This app does not take applications. Programme pages under '
                      'Tulong are information only. The municipal hall can '
                      'tell you about a programme.',
            boxed: true,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: page.items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: Spacing.md),
        itemBuilder: (context, index) => _HistoryCard(entry: page.items[index]),
      ),
    );
  }
}

/// Open or past: two chips (Directory.dc `.chipsrow`), always both present.
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.scope, required this.onChanged});

  final HistoryScope scope;
  final void Function(HistoryScope) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.section,
        Spacing.lg,
        0,
      ),
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.xs,
        children: <Widget>[
          SoftChoiceChip(
            label: 'Open',
            selected: scope == HistoryScope.open,
            onTap: () => onChanged(HistoryScope.open),
          ),
          SoftChoiceChip(
            label: 'Past',
            selected: scope == HistoryScope.past,
            onTap: () => onChanged(HistoryScope.past),
          ),
        ],
      ),
    );
  }
}

/// One record: what it was for, where it ended, and what came of it.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final AssistanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final String? outcome = entry.outcomeSummary;
    final String? reference = entry.referenceNumber;
    final DateTime? sent = entry.submittedAt;
    final DateTime? finished = entry.completedAt;
    final String? receipt = entry.receiptReference;

    return SoftCard(
      onTap: () => context.goNamed(
        AppRoute.requestDetail.routeName,
        pathParameters: <String, String>{'requestId': entry.requestId},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  // The catalogue name when the server sent one; the code
                  // otherwise, because a code a resident can quote beats a
                  // blank.
                  entry.serviceName ?? entry.serviceCode,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
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
          const SizedBox(height: Spacing.sm),
          StatusPill(label: requestStatusLabel(entry.status.known)),

          if (outcome != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            // The office's own summary of what was provided, verbatim. Never
            // composed by the app from a status.
            Text(
              outcome,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
          ],

          if (reference != null || sent != null || finished != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.xs,
                children: <Widget>[
                  if (reference != null)
                    _Meta(label: 'Reference', value: reference),
                  if (sent != null)
                    _Meta(label: 'Sent', value: formatCaseDate(sent)),
                  if (finished != null)
                    _Meta(label: 'Finished', value: formatCaseDate(finished)),
                ],
              ),
            ),

          if (receipt != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            // A reference, not a download. There is no document endpoint, and
            // a button that fetches nothing teaches a resident the receipt is
            // theirs to hold when the office's copy is the authoritative one.
            Text(
              'Receipt reference $receipt. The municipal hall can print a '
              'copy.',
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: AppTypography.small.copyWith(
        fontWeight: AppTypography.medium,
        color: BrandColors.muted,
      ),
    );
  }
}
