import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/event_repository.dart';

/// Events — what the LGU is running, and when.
///
/// Public, matching `GET /api/v1/events`. A resident should be able to find out
/// that a medical mission is happening on Saturday without first proving who
/// they are.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _loading = true;
  AppFailure? _failure;
  Paginated<LguEvent>? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == null && _failure == null) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).eventRepository;
    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await repository.listEvents();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (page) => _page = page,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: switch ((_loading, _failure, page)) {
            (true, _, null) => const AppLoadingView(message: 'Loading events…'),
            (_, final AppFailure _, _) => ListView(
              children: <Widget>[
                StatusView(
                  title: 'No events listed yet',
                  kind: StatusKind.empty,
                  icon: Icons.event_busy_outlined,
                  message:
                      'Taytay LGU has not published events in this app yet. '
                      'Schedules are still posted at the municipal hall and '
                      'barangay halls.',
                  primaryAction: TextButton(
                    onPressed: _load,
                    child: const Text('Check again'),
                  ),
                ),
              ],
            ),
            (_, _, final Paginated<LguEvent> loaded) when loaded.isEmpty =>
              ListView(
                children: const <Widget>[
                  StatusView(
                    title: 'Nothing scheduled right now',
                    kind: StatusKind.empty,
                    icon: Icons.event_busy_outlined,
                    message: 'Upcoming Taytay LGU events will appear here.',
                  ),
                ],
              ),
            (_, _, final Paginated<LguEvent> loaded) => ListView.builder(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: loaded.items.length,
              itemBuilder: (context, index) =>
                  _EventCard(event: loaded.items[index]),
            ),
            // Not loading, no failure, no page: the first frame before
            // `didChangeDependencies` has run. Never a resident-visible state
            // for more than a frame, and a spinner is the honest rendering.
            _ => const AppLoadingView(),
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final LguEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: AppCard(
        onTap: () => context.goNamed(
          AppRoute.eventDetail.routeName,
          pathParameters: <String, String>{'eventId': event.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(event.title, style: theme.textTheme.titleMedium),
            if (event.venue != null) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              Text(
                event.venue!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
