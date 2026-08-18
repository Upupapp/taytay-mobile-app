import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/assistance_program.dart';

/// Assistance programmes the LGU is currently running.
///
/// ---
///
/// **Signed in, unlike the service catalogue.** The committed matrix draws the
/// line: `GET /api/v1/services` is `public`, and the citizen programme row is
/// `GET /api/v1/programs?status=active` with **bearer** auth. So a guest browses
/// services freely and is asked to sign in for programmes — the server's rule,
/// stated here before the request rather than delivered as a `401`.
///
/// **Active only, and the app cannot ask for anything else.** The citizen row
/// carries the filter; `ProgramRepository` has no method that could request a
/// draft, a suspended or a retired programme.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  bool _started = false;
  bool _loading = false;
  AppFailure? _failure;
  List<AssistanceProgram> _programs = const <AssistanceProgram>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);

    // Bearer endpoint: a guest must not issue the request at all.
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.browsePrograms,
    )) {
      return;
    }

    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await dependencies.programRepository.listActivePrograms();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (page) => _programs = page.items,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistance programmes')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.browsePrograms,
          child: RefreshIndicator(
            onRefresh: _load,
            child: switch ((_loading, _failure, _programs.isEmpty)) {
              (true, _, _) => const AppLoadingView(
                message: 'Loading programmes…',
              ),
              (_, final AppFailure _, _) => ListView(
                children: <Widget>[
                  StatusView(
                    title: 'Not available yet',
                    kind: StatusKind.empty,
                    icon: Icons.volunteer_activism_outlined,
                    message:
                        'Taytay LGU has not published assistance programmes in '
                        'this app yet. The municipal hall can tell you what is '
                        'running and what it needs from you.',
                    primaryAction: TextButton(
                      onPressed: _load,
                      child: const Text('Check again'),
                    ),
                  ),
                ],
              ),
              (_, _, true) => ListView(
                children: const <Widget>[
                  StatusView(
                    title: 'No programmes running right now',
                    kind: StatusKind.empty,
                    icon: Icons.volunteer_activism_outlined,
                    message:
                        'Taytay LGU assistance programmes will appear here when '
                        'they open.',
                  ),
                ],
              ),
              _ => ListView.builder(
                padding: const EdgeInsets.all(Spacing.lg),
                itemCount: _programs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return const _GuidanceNotice();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: _ProgramCard(program: _programs[index - 1]),
                  );
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// Said once at the top of the list, and again on every detail screen.
///
/// The single most important sentence in this feature: what a resident reads
/// here is what the office published, not a decision about them.
class _GuidanceNotice extends StatelessWidget {
  const _GuidanceNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: Spacing.lg),
      child: AppBanner(
        tone: BannerTone.info,
        title: 'These are guidelines, not a decision',
        message:
            'Taytay LGU publishes who a programme is meant to help so you can '
            'judge whether to apply. Whether you qualify is decided by staff '
            'when they look at your documents.',
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});

  final AssistanceProgram program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availability = program.availabilityNote;

    return AppCard(
      // Addressed by id, not by code. `programs/{program}` resolves the path
      // segment with `findByUuid` server-side; the code is the human-facing
      // string an office quotes at a counter and is not a route key. It stays
      // visible on the detail screen, where a resident can read it out.
      onTap: DeepLink.isValidIdentifier(program.id)
          ? () => context.goNamed(
              AppRoute.programDetail.routeName,
              pathParameters: <String, String>{'programId': program.id},
            )
          : null,
      semanticLabel: program.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(program.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            program.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (program.ownerOffice != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              program.ownerOffice!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.xs),
          Text(availability, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Re-exported so the detail screen shows the same sentence.
class ProgramGuidanceNotice extends StatelessWidget {
  const ProgramGuidanceNotice({super.key});

  @override
  Widget build(BuildContext context) => const _GuidanceNotice();
}

/// Used by tests to build a page without touching the network.
Paginated<AssistanceProgram> programPage(List<AssistanceProgram> items) =>
    Paginated<AssistanceProgram>.single(items);
