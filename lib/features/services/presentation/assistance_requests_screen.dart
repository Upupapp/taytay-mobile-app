import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
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
      appBar: AppBar(title: const Text('My requests')),
      body: SafeArea(
        // Belt and braces with the route guard: the route is verified-only, so
        // this can only render for a verified resident — but a screen that also
        // states its own requirement keeps working if it is ever reused inside a
        // route with a weaker one.
        child: CapabilityGate(
          capability: ResidentCapability.trackAssistanceRequests,
          child: Column(
            children: <Widget>[
              _ScopeSelector(scope: _scope, onChanged: _changeScope),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final page = _page;

    if (_loading && page == null) {
      return const AppLoadingView(message: 'Loading your requests…');
    }
    if (_failure != null) {
      // Not the same sentence as an empty list, deliberately. "You have never
      // received assistance from Taytay LGU" and "we could not reach Taytay
      // LGU" are different statements, and showing the first one wrongly tells
      // a resident their record does not exist.
      return ListView(
        children: <Widget>[
          StatusView(
            title: 'Not available yet',
            kind: StatusKind.empty,
            icon: Icons.assignment_outlined,
            message:
                'Taytay LGU has not switched on request tracking in this app '
                'yet. The municipal hall can tell you where your requests '
                'stand.',
            primaryAction: TextButton(
              onPressed: _load,
              child: const Text('Check again'),
            ),
          ),
        ],
      );
    }
    if (page == null || page.isEmpty) {
      return ListView(
        children: <Widget>[
          StatusView(
            title: _scope.isPast
                ? 'Nothing finished yet'
                : 'You have no open requests',
            kind: StatusKind.empty,
            icon: Icons.assignment_outlined,
            message: _scope.isPast
                ? 'Requests that are completed, released or closed will appear '
                      'here.'
                : 'Anything you apply for with Taytay LGU will appear here '
                      'while it is being handled.',
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacing.lg),
        itemCount: page.items.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: _HistoryCard(entry: page.items[index]),
        ),
      ),
    );
  }
}

/// Open or past. Two segments, always both present.
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.scope, required this.onChanged});

  final HistoryScope scope;
  final void Function(HistoryScope) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: SegmentedButton<HistoryScope>(
        segments: const <ButtonSegment<HistoryScope>>[
          ButtonSegment<HistoryScope>(
            value: HistoryScope.open,
            label: Text('Open'),
            icon: Icon(Icons.pending_actions_outlined),
          ),
          ButtonSegment<HistoryScope>(
            value: HistoryScope.past,
            label: Text('Past'),
            icon: Icon(Icons.history_outlined),
          ),
        ],
        selected: <HistoryScope>{scope},
        onSelectionChanged: (selection) => onChanged(selection.first),
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
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.goNamed(
        AppRoute.requestDetail.routeName,
        pathParameters: <String, String>{'requestId': entry.requestId},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            // The catalogue name when the server sent one; the code otherwise,
            // because a code a resident can quote beats a blank.
            entry.serviceName ?? entry.serviceCode,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            requestStatusLabel(entry.status.known),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          if (entry.outcomeSummary != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            // The office's own summary of what was provided, verbatim. Never
            // composed by the app from a status.
            Text(entry.outcomeSummary!, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.xs,
            children: <Widget>[
              if (entry.referenceNumber != null)
                _Meta(label: 'Reference', value: entry.referenceNumber!),
              if (entry.submittedAt != null)
                _Meta(label: 'Sent', value: formatCaseDate(entry.submittedAt!)),
              if (entry.completedAt != null)
                _Meta(
                  label: 'Finished',
                  value: formatCaseDate(entry.completedAt!),
                ),
            ],
          ),

          if (entry.receiptReference != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            // A reference, not a download. There is no document endpoint, and a
            // button that fetches nothing teaches a resident the receipt is
            // theirs to hold when the office's copy is the authoritative one.
            Text(
              'Receipt reference ${entry.receiptReference}. The municipal hall '
              'can print a copy.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Text(
      '$label: $value',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
