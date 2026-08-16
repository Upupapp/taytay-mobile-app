import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/event_repository.dart';
import 'events_controller.dart';

/// Events — what Taytay LGU has scheduled.
///
/// ---
///
/// **Public, because `GET /api/v1/events` is public.** A guest browses upcoming
/// and past events and reads every detail. Only the "Registered" scope needs an
/// account, and it is not shown to a guest at all: an empty "My events" would
/// imply they had lost registrations they never had.
///
/// **This app consumes; it never publishes.** No create, edit, publish, cancel
/// or capacity control, and no repository method that could express one.
///
/// **Registering arrives in TAB 22.** This screen shows the registration state
/// the server reports and offers no register button — a control that cannot
/// complete is worse than an absent one.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventsController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    _controller =
        EventsController(
            repository: AppDependencies.of(context).eventRepository,
          )
          ..addListener(_onChanged)
          ..refresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Through `AccessPolicy`, not an `accessLevel` comparison. One place decides
    // "may this person see it", and a scattered level check is how two screens
    // end up disagreeing — `EventScope.registered` declares what it needs and
    // this reads the same rule the router does.
    final canSeeRegistered =
        AccessPolicy.evaluate(
              session: AppDependencies.of(context).session.state,
              requirement: AccessRequirement.authenticated,
            )
            is AccessAllowed;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: SafeArea(
        child: controller == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  _ScopeSelector(
                    scope: controller.scope,
                    showRegistered: canSeeRegistered,
                    onChanged: controller.changeScope,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: _EventList(controller: controller),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Upcoming, Registered (signed in only) and Past.
class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.scope,
    required this.showRegistered,
    required this.onChanged,
  });

  final EventScope scope;
  final bool showRegistered;
  final Future<void> Function(EventScope) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: SegmentedButton<EventScope>(
        segments: <ButtonSegment<EventScope>>[
          const ButtonSegment<EventScope>(
            value: EventScope.upcoming,
            label: Text('Upcoming'),
            icon: Icon(Icons.event_outlined),
          ),
          if (showRegistered)
            const ButtonSegment<EventScope>(
              value: EventScope.registered,
              label: Text('Registered'),
              icon: Icon(Icons.how_to_reg_outlined),
            ),
          const ButtonSegment<EventScope>(
            value: EventScope.past,
            label: Text('Past'),
            icon: Icon(Icons.history_outlined),
          ),
        ],
        selected: <EventScope>{scope},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingFirstPage) {
      return const _EventsSkeleton();
    }

    if (controller.failure != null) {
      // Distinct from an empty list. "Taytay LGU has scheduled nothing" and "we
      // could not reach Taytay LGU" are different statements.
      return ListView(
        children: <Widget>[
          StatusView(
            title: 'Events are not available right now',
            kind: StatusKind.error,
            icon: Icons.wifi_off_outlined,
            message:
                'We could not reach Taytay LGU. Check your connection and try '
                'again. Event notices are also posted at the municipal hall and '
                'barangay halls.',
            primaryAction: TextButton(
              onPressed: controller.refresh,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (controller.isEmptyAndHealthy) {
      return ListView(
        children: <Widget>[
          StatusView(
            title: switch (controller.scope) {
              EventScope.upcoming => 'Nothing scheduled right now',
              EventScope.registered => 'You have not registered for anything',
              EventScope.past => 'No past events to show',
            },
            kind: StatusKind.empty,
            icon: Icons.event_busy_outlined,
            message: switch (controller.scope) {
              EventScope.upcoming =>
                'New Taytay LGU events will appear here when they are '
                    'announced.',
              EventScope.registered =>
                'Events you register for will appear here.',
              EventScope.past => 'Events that have finished will appear here.',
            },
          ),
        ],
      );
    }

    final events = controller.items;

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == events.length) return _Footer(controller: controller);
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: EventCard(event: events[index]),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.pageFailure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: AppBanner(
          tone: BannerTone.warning,
          title: 'Could not load more',
          message: 'What you have already seen is still here.',
          action: TextButton(
            onPressed: controller.retryPage,
            child: const Text('Try again'),
          ),
        ),
      );
    }

    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: TextButton(
          onPressed: controller.loadMore,
          child: const Text('Load more'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Text(
        'That is everything Taytay LGU has listed here.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One event in the list.
///
/// Public so Home can render the same card rather than a second, subtly
/// different one.
class EventCard extends StatelessWidget {
  const EventCard({required this.event, super.key});

  final LguEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.goNamed(
        AppRoute.eventDetail.routeName,
        pathParameters: <String, String>{'eventId': event.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (event.coverImageUrl != null) ...<Widget>[
            EventCover(url: event.coverImageUrl!),
            const SizedBox(height: Spacing.md),
          ],

          if (event.isRegistered) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.how_to_reg_outlined,
                  size: IconSizes.sm,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Spacing.xs),
                // Never colour alone — and `Expanded`, because these labels are
                // sentences ("You are on the waitlist") that overflow a narrow
                // card at a large text scale otherwise.
                Expanded(
                  child: Text(
                    registrationStateLabel(event.registrationState?.known),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
          ],

          Text(event.title, style: theme.textTheme.titleMedium),

          if (event.startsAt != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            // The whole point of the Manila formatter: the time is stated with
            // the clock it belongs to, so a phone set to another timezone
            // cannot mislead somebody into arriving on the wrong day.
            _IconLine(
              icon: Icons.schedule_outlined,
              text: ManilaTime.formatRange(event.startsAt!, event.endsAt),
            ),
          ],

          if (event.venue != null) ...<Widget>[
            const SizedBox(height: Spacing.xxs),
            _IconLine(icon: Icons.place_outlined, text: event.venue!.name),
          ],

          if (!event.isRegistered) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _RegistrationSummary(event: event),
          ],
        ],
      ),
    );
  }
}

/// Registration state and remaining places, when the office stated them.
class _RegistrationSummary extends StatelessWidget {
  const _RegistrationSummary({required this.event});

  final LguEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = event.registrationState?.known;
    final remaining = event.capacity.remaining;

    final parts = <String>[
      if (state != null) registrationStateLabel(state),
      // Only when the server said so. The app never subtracts a registered
      // count from a capacity to produce this — a number computed from a stale
      // page tells a resident there is room when there is not.
      if (remaining != null)
        remaining == 1 ? '1 place left' : '$remaining places left',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: IconSizes.sm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// An event cover, with its space reserved and a failure that does not take the
/// event down with it.
class EventCover extends StatelessWidget {
  const EventCover({required this.url, this.height, super.key});

  final String url;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final image = Image.network(
      url,
      fit: BoxFit.cover,
      // Decorative: the title, date and venue below carry every fact. Giving it
      // a description this app invented for a picture it cannot see would be
      // worse than silence.
      excludeFromSemantics: true,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.event_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: height == null
          ? AspectRatio(aspectRatio: 16 / 9, child: image)
          : SizedBox(height: height, width: double.infinity, child: image),
    );
  }
}

/// Placeholder cards while the first page loads.
class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    final block = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Semantics(
      liveRegion: true,
      label: 'Loading events',
      child: ExcludeSemantics(
        child: ListView.builder(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: block,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Container(width: 200, height: 12, color: block),
                  const SizedBox(height: Spacing.sm),
                  Container(width: 140, height: 12, color: block),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resident-facing wording for a registration state.
///
/// One switch for the card and the detail screen, for the same reason the
/// request-status copy has one: two switches over an enum drift, and a resident
/// then reads two different words for one state.
String registrationStateLabel(EventRegistrationState? state) => switch (state) {
  EventRegistrationState.notOpen => 'Registration not open yet',
  EventRegistrationState.open => 'Registration open',
  EventRegistrationState.registered => 'You are registered',
  EventRegistrationState.waitlisted => 'You are on the waitlist',
  EventRegistrationState.cancelled => 'You cancelled your place',
  EventRegistrationState.full => 'Fully booked',
  EventRegistrationState.closed => 'Registration closed',
  // An unrecognised state reads neutrally rather than as a refusal — a released
  // app meets values added after it shipped, and "check with the office" is
  // true of all of them.
  null => 'Ask the office about registering',
};
