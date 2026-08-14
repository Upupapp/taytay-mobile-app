import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/event_repository.dart';

/// One LGU event, opened from the list or from a notification.
///
/// The identifier is re-validated here for the same reason it is on an
/// announcement: a path can be typed or restored from the back stack without
/// passing through [DeepLink].
///
/// **Nothing on this screen registers attendance.** The endpoint matrix has no
/// event-registration row, and a link must never act on a resident's behalf in
/// any case. Opening an event shows it; that is all.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  AppFailure? _failure;
  LguEvent? _event;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.eventId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null && _failure == null && _idIsValid) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).eventRepository;
    setState(() => _loading = true);

    final result = await repository.loadEvent(widget.eventId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (event) => _event = event,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: SafeArea(
        child: switch ((_idIsValid, _loading, event)) {
          (false, _, _) => _NotAvailable(
            message: DeepLinkRejection.invalidIdentifier.residentMessage,
          ),
          (_, true, null) => const AppLoadingView(message: 'Opening event…'),
          (_, _, null) => _NotAvailable(
            message: DeepLinkRejection.unknownTarget.residentMessage,
          ),
          (_, _, final LguEvent loaded) => ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Text(
                loaded.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (loaded.venue != null) ...<Widget>[
                const SizedBox(height: Spacing.xs),
                Text(loaded.venue!),
              ],
              const SizedBox(height: Spacing.md),
              Text(
                loaded.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'This event is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      message: message,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.events.routeName),
        child: const Text('See all events'),
      ),
    );
  }
}
