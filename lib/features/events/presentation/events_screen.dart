import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/feed_row.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
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
///
/// Drawn as the Balita list (`Balita.dc.html`): the glass page, the blue
/// header with the back control and the scope chips, the events as rows in a
/// glass card.
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

    final Widget header = BlueHeader(
      overlap: true,
      showBack: true,
      title: 'Events',
      subtitle: 'Bayan ng Taytay · Rizal',
      bottom: controller == null
          ? null
          : _ScopeSelector(
              scope: controller.scope,
              showRegistered: canSeeRegistered,
              onChanged: controller.changeScope,
            ),
    );

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: GlassBackground(
        child: RefreshIndicator(
          onRefresh: controller?.refresh ?? () async {},
          child: ListView(
            // No per-item repaint / semantics wrappers: they hit-test only
            // their own box, so the strip GlassOverlap raises over the
            // header would not take a tap.
            addRepaintBoundaries: false,
            addSemanticIndexes: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: Spacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            children: <Widget>[
              header,
              GlassOverlap(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: controller == null
                      ? const _EventsSkeleton()
                      : _EventList(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upcoming, Registered (signed in only) and Past, as the header chips
/// (Balita `.chip.bar` / `.chip.onbar`).
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
    Widget chip(String label, EventScope value) => HeaderChoiceChip(
      label: label,
      selected: scope == value,
      onTap: () => onChanged(value),
    );
    return Semantics(
      container: true,
      label: 'Show events',
      child: Wrap(
        spacing: Spacing.sm,
        children: <Widget>[
          chip('Upcoming', EventScope.upcoming),
          if (showRegistered) chip('Registered', EventScope.registered),
          chip('Past', EventScope.past),
        ],
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
      return ErrorState(
        title: 'Events are not available right now',
        message:
            'We could not reach Taytay LGU. Check your connection and try '
            'again. Event notices are also posted at the municipal hall and '
            'barangay halls.',
        onRetry: controller.refresh,
        offline: true,
        boxed: true,
      );
    }

    if (controller.isEmptyAndHealthy) {
      return EmptyState(
        title: switch (controller.scope) {
          EventScope.upcoming => 'Nothing scheduled right now',
          EventScope.registered => 'You have not registered for anything',
          EventScope.past => 'No past events to show',
        },
        message: switch (controller.scope) {
          EventScope.upcoming =>
            'New Taytay LGU events will appear here when they are '
                'announced.',
          EventScope.registered => 'Events you register for will appear here.',
          EventScope.past => 'Events that have finished will appear here.',
        },
        boxed: true,
      );
    }

    final events = controller.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < events.length; i++)
                EventCard(event: events[i], divider: i > 0),
            ],
          ),
        ),
        _Footer(controller: controller),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.pageFailure != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SoftNote(
              tone: NoteTone.warning,
              title: 'Could not load more. ',
              message: 'What you have already seen is still here.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.retryPage,
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: Spacing.lg),
        child: LoadingSkeleton(
          layout: SkeletonLayout.feed,
          count: 1,
          semanticLabel: 'Loading more events',
        ),
      );
    }

    if (controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.md),
        child: Center(
          child: TextButton(
            onPressed: controller.loadMore,
            child: const Text('Load more'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Text(
        'That is everything Taytay LGU has listed here.',
        textAlign: TextAlign.center,
        style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
      ),
    );
  }
}

/// One event in the list (Balita `.row`): the category, the registration the
/// resident holds, the title, when and where, the registration summary, and
/// the cover on the right when the office uploaded one.
///
/// Public so Home can render the same row rather than a second, subtly
/// different one.
class EventCard extends StatelessWidget {
  const EventCard({required this.event, this.divider = false, super.key});

  final LguEvent event;

  /// The hairline above the row, for every row after the first in a card.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final String? category = event.category;
    final DateTime? startsAt = event.startsAt;
    final EventVenue? venue = event.venue;

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.section),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (category != null && category.isNotEmpty) ...<Widget>[
                  Text(
                    category.toUpperCase(),
                    style: AppTypography.category.copyWith(
                      color: BrandColors.blue,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                ],

                if (event.isRegistered) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const TaytayIcon(
                        icon: TaytayIcons.badgeCheck,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.sm,
                        color: BrandColors.green,
                      ),
                      const SizedBox(width: Spacing.xs),
                      // Never colour alone — and `Expanded`, because these
                      // labels are sentences ("You are on the waitlist") that
                      // overflow a narrow row at a large text scale otherwise.
                      Expanded(
                        child: Text(
                          registrationStateLabel(
                            event.registrationState?.known,
                          ),
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.strong,
                            color: BrandColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                ],

                Text(
                  event.title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),

                if (startsAt != null) ...<Widget>[
                  const SizedBox(height: Spacing.xs),
                  // The whole point of the Manila formatter: the time is stated
                  // with the clock it belongs to, so a phone set to another
                  // timezone cannot mislead somebody into arriving on the
                  // wrong day.
                  _IconLine(
                    icon: TaytayIcons.clock,
                    text: ManilaTime.formatRange(startsAt, event.endsAt),
                  ),
                ],

                if (venue != null) ...<Widget>[
                  const SizedBox(height: Spacing.xxs),
                  _IconLine(icon: TaytayIcons.mapPin, text: venue.name),
                ],

                if (!event.isRegistered) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  _RegistrationSummary(event: event),
                ],
              ],
            ),
          ),
          EventCover(
            event: event,
            height: FeedRow.thumbnailSize,
            width: FeedRow.thumbnailSize,
            gapStart: Spacing.md,
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: BrandColors.divider))
            : null,
      ),
      child: InkWell(
        onTap: () => context.goNamed(
          AppRoute.eventDetail.routeName,
          pathParameters: <String, String>{'eventId': event.id},
        ),
        child: row,
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
    final state = event.registrationState?.known;
    final remaining = event.capacity.remaining;

    final parts = <String>[
      // A called-off event stays listed until its date passes. Its row says
      // so in words, ahead of "Registration closed", which alone would read
      // as an event that is still going ahead.
      if (event.isCalledOff)
        calledOffLabel
      else if (state != null)
        registrationStateLabel(state),
      // Only when the server said so. The app never subtracts a registered
      // count from a capacity to produce this — a number computed from a stale
      // page tells a resident there is room when there is not.
      if (remaining != null)
        remaining == 1 ? '1 place left' : '$remaining places left',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return StatusPill(
      label: parts.join(' · '),
      tone: event.isCalledOff ? PillTone.red : PillTone.blue,
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: Spacing.xxs),
          child: TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm - Spacing.xxs,
            color: BrandColors.muted,
          ),
        ),
        const SizedBox(width: Spacing.xs + Spacing.xxs),
        Expanded(
          child: Text(
            text,
            style: AppTypography.listDetail.copyWith(color: BrandColors.text),
          ),
        ),
      ],
    );
  }
}

/// An event cover, read through the API, with its space reserved and a failure
/// that does not take the event down with it.
///
/// **The one place an event's cover becomes a picture.** The bytes are read
/// from `GET events/{id}/cover` on the configured API base
/// (`MediaBytesApi.eventCover`), never from the address in the payload. The
/// office uploads a cover through the API (D-193), so there is no other host to
/// ask, and the address's own scheme and host are not taken on trust: a phone
/// that loads a cover talks to the API it was built for and nothing else. An
/// event with no cover draws nothing and takes no space.
///
/// The office's description of the picture, which it must write before
/// publishing, is read to a resident who cannot see it. With none, the picture
/// is unlabelled rather than described by words this app made up.
class EventCover extends StatelessWidget {
  const EventCover({
    required this.event,
    this.height,
    this.width,
    this.gapBelow,
    this.gapStart,
    this.radius = Radii.md,
    this.load,
    super.key,
  });

  final LguEvent event;

  /// Null draws 16:9 at the given width. [double.infinity] fills the parent
  /// (the detail page's hero).
  final double? height;

  /// Null takes the parent's width.
  final double? width;

  /// Space under a drawn cover. None when there is no cover to draw.
  final double? gapBelow;

  /// Space before a drawn cover in a row. None when there is no cover.
  final double? gapStart;

  /// Corner radius; 0 for the full-bleed hero.
  final double radius;

  /// Reads the cover by event id. Defaults to `MediaBytesApi.eventCover`, and
  /// to nothing in a mock build, which has no API to ask.
  final MediaBytesLoader? load;

  @override
  Widget build(BuildContext context) {
    final String? url = event.coverImageUrl;
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppDependencies dependencies = AppDependencies.of(context);
    final MediaBytesLoader? load =
        this.load ??
        (dependencies.config.usesMockData
            ? null
            : dependencies.mediaBytes.eventCover);
    // Shown while the bytes are on their way, and if they never come. It says
    // nothing to a screen reader: the title, date and venue carry every fact.
    const Widget placeholder = ExcludeSemantics(
      child: ColoredBox(
        color: BrandColors.blue50,
        child: Center(
          child: TaytayIcon(
            icon: TaytayIcons.calendar,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.md,
            color: BrandColors.blue,
          ),
        ),
      ),
    );

    return MediaBytesHost(
      id: event.id,
      load: load,
      builder: (Uint8List? bytes) {
        final Widget image = bytes == null
            ? placeholder
            : DecodedMemoryImage(
                bytes: bytes,
                placeholder: placeholder,
                semanticLabel: event.coverAltText,
              );
        final double? height = this.height;
        final Widget sized = height == null
            ? SizedBox(
                width: width,
                child: AspectRatio(aspectRatio: 16 / 9, child: image),
              )
            : SizedBox(
                height: height,
                width: width ?? double.infinity,
                child: image,
              );
        Widget cover = radius == 0
            ? sized
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: sized,
              );
        final double? gap = gapBelow;
        if (gap != null) {
          cover = Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: cover,
          );
        }
        final double? start = gapStart;
        if (start != null) {
          cover = Padding(
            padding: EdgeInsetsDirectional.only(start: start),
            child: cover,
          );
        }
        return cover;
      },
    );
  }
}

/// Placeholder rows while the first page loads.
class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const LoadingSkeleton(
      layout: SkeletonLayout.feed,
      semanticLabel: 'Loading events',
    );
  }
}

/// What a called-off event is labelled, in its list row and on its page.
const String calledOffLabel = 'Called off by Taytay LGU';

/// Resident-facing wording for a registration state.
///
/// One switch for the card and the detail screen, for the same reason the
/// request-status copy has one: two switches over an enum drift, and a resident
/// then reads two different words for one state.
String registrationStateLabel(EventRegistrationState? state) => switch (state) {
  // A walk-in event. Not "ask the office": there is nothing to ask (D-192).
  EventRegistrationState.notRequired => 'No registration needed',
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
