import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/sharing/share_service.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/event_repository.dart';
import 'events_screen.dart' show EventCover, registrationStateLabel;

/// One LGU event, opened from the list or from a notification.
///
/// ---
///
/// **The identifier is re-validated here** for the same reason it is on an
/// announcement: a path can be typed or restored from the back stack without
/// passing through [DeepLink].
///
/// **Nothing on this screen registers attendance.** Registration is TAB 22, with
/// its capacity and waitlist rules; a button here that could not complete would
/// be worse than none. Opening an event shows it — and a link must never act on
/// a resident's behalf in any case.
///
/// **A guest sees the whole thing.** Every fact on this screen is public: what
/// is happening, when, where, and who to ask.
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
        onOk: (event) {
          // An event the office has not published must not open from a stale
          // link either. Same rule as the list, applied at the second door.
          _event = event.isResidentVisible ? event : null;
          _failure = event.isResidentVisible ? null : const NotFoundFailure();
        },
        onErr: (failure) => _failure = failure,
      );
    });
  }

  Future<void> _openDirections(EventVenue venue) async {
    final outcome = await AppDependencies.of(
      context,
    ).externalLinks.open(venue.directionsUrl!);
    if (!mounted || outcome == LinkOutcome.opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome == LinkOutcome.refused
              // The app declined the link rather than the device failing, and
              // saying so plainly beats blaming the phone.
              ? 'That map link could not be opened safely.'
              : 'No app on this device can open a map.',
        ),
      ),
    );
  }

  Future<void> _share(LguEvent event) async {
    final outcome = await AppDependencies.of(context).shareService.share(
      ShareableContent(
        title: event.title,
        body: <String>[
          event.title,
          if (event.startsAt != null)
            ManilaTime.formatRange(event.startsAt!, event.endsAt),
          if (event.venue != null) event.venue!.name,
          'From Taytay LGU',
        ].join('\n'),
        // The server's link or none. This app does not compose a public URL.
        url: event.shareUrl,
      ),
    );
    if (!mounted) return;

    final message = switch (outcome) {
      ShareOutcome.shared || ShareOutcome.dismissed => null,
      ShareOutcome.copiedToClipboard =>
        'Copied. You can paste this into any app.',
      ShareOutcome.unavailable => 'Sharing is not available on this device.',
    };
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
          (_, _, final LguEvent loaded) => _Detail(
            event: loaded,
            onDirections: _openDirections,
            onShare: () => _share(loaded),
          ),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.event,
    required this.onDirections,
    required this.onShare,
  });

  final LguEvent event;
  final Future<void> Function(EventVenue) onDirections;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venue = event.venue;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        if (event.coverImageUrl != null)
          EventCover(url: event.coverImageUrl!, height: 200),

        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (event.category != null) ...<Widget>[
                Text(
                  event.category!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
              ],

              Semantics(
                header: true,
                child: Text(event.title, style: theme.textTheme.headlineSmall),
              ),

              if (event.myRegistration != null) ...<Widget>[
                const SizedBox(height: Spacing.md),
                MyRegistrationCard(registration: event.myRegistration!),
              ] else if (event.isRegistered) ...<Widget>[
                const SizedBox(height: Spacing.md),
                AppBanner(
                  tone: BannerTone.success,
                  title: registrationStateLabel(event.registrationState?.known),
                  message:
                      'Taytay LGU has your registration for this event. Bring a '
                      'valid ID.',
                ),
              ],

              const SizedBox(height: Spacing.lg),

              // ── When and where ──────────────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (event.startsAt != null)
                      _Fact(
                        icon: Icons.schedule_outlined,
                        label: 'When',
                        // Stated with the clock it belongs to. A phone set to
                        // another timezone cannot make somebody arrive on the
                        // wrong day.
                        value: ManilaTime.formatRange(
                          event.startsAt!,
                          event.endsAt,
                        ),
                      ),
                    if (venue != null)
                      _Fact(
                        icon: Icons.place_outlined,
                        label: 'Where',
                        value: <String>[
                          venue.name,
                          if (venue.address != null) venue.address!,
                        ].join('\n'),
                      ),
                    if (event.organiser != null)
                      _Fact(
                        icon: Icons.account_balance_outlined,
                        label: 'Organised by',
                        value: event.organiser!,
                      ),
                    if (event.contact != null)
                      _Fact(
                        icon: Icons.call_outlined,
                        label: 'Questions',
                        value: event.contact!,
                      ),

                    // Offered only when the server supplied a link this app is
                    // willing to open. See `ExternalLink.isSafe`.
                    if (venue != null && venue.hasSafeDirections) ...<Widget>[
                      const SizedBox(height: Spacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => onDirections(venue),
                        icon: const Icon(
                          Icons.directions_outlined,
                          size: IconSizes.sm,
                        ),
                        label: const Text('Open directions'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: Spacing.lg),
              Text(event.description, style: theme.textTheme.bodyLarge),

              if (event.registrationRules != null) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                _Section(title: 'Who can join', body: event.registrationRules!),
              ],

              if (event.capacity.isStated) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                _Capacity(capacity: event.capacity),
              ],

              if (event.whatToBring != null) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                _Section(title: 'What to bring', body: event.whatToBring!),
              ],

              const SizedBox(height: Spacing.xl),

              // Offered only when the server says registration is open and the
              // resident does not already hold a place. Capacity is never
              // judged here — the server decides on submission, and a resident
              // who reaches the last place a second late reads that on the
              // outcome screen rather than being pre-emptively refused.
              if (_canOfferRegistration(event)) ...<Widget>[
                AppButton(
                  label: 'Register for this event',
                  onPressed: () => context.goNamed(
                    AppRoute.eventRegistration.routeName,
                    pathParameters: <String, String>{'eventId': event.id},
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Taytay LGU decides whether a place is available.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],

              OutlinedButton.icon(
                onPressed: onShare.call,
                icon: const Icon(Icons.share_outlined, size: IconSizes.sm),
                label: const Text('Share this event'),
              ),

              if (!_canOfferRegistration(event) &&
                  event.myRegistration == null) ...<Widget>[
                const SizedBox(height: Spacing.md),
                // Says plainly what this screen does and does not do, so a
                // resident does not leave believing they have a place.
                Text(
                  registrationStateLabel(event.registrationState?.known),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether to offer the register control at all.
///
/// **Only on the server's own `open` state.** Not on an unrecognised one, and
/// never inferred from a capacity number: offering registration for a full or
/// closed event sends a resident through a form to be refused at the end of it.
bool _canOfferRegistration(LguEvent event) =>
    event.myRegistration == null &&
    !event.isRegistered &&
    event.registrationState?.known == EventRegistrationState.open;

/// The resident's own registration: reference, position, instructions,
/// attendance — and a way to give the place up when the office allows it.
class MyRegistrationCard extends StatelessWidget {
  const MyRegistrationCard({required this.registration, super.key});

  final EventRegistration registration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendance = registration.attendance?.known;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                registration.isCancelled
                    ? Icons.event_busy_outlined
                    : Icons.how_to_reg_outlined,
                size: IconSizes.md,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    registrationStateLabel(registration.state.known),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          if (registration.reference != null)
            _Fact(
              icon: Icons.confirmation_number_outlined,
              label: 'Reference',
              value: registration.reference!,
            ),

          // Only when the office publishes it. A queue position is a statement
          // about other people as much as about this resident, and an estimate
          // would be the app inventing one.
          if (registration.isWaitlisted &&
              registration.waitlistPosition != null)
            _Fact(
              icon: Icons.format_list_numbered_outlined,
              label: 'Waitlist position',
              value: '${registration.waitlistPosition}',
            ),

          if (registration.instructions != null) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Text(registration.instructions!, style: theme.textTheme.bodyMedium),
          ],

          // Recorded after the event, and only when the office exposes it.
          // `notRecorded` says so rather than implying absence.
          if (attendance != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            Text(
              switch (attendance) {
                AttendanceResult.attended =>
                  'Taytay LGU recorded you as having attended.',
                AttendanceResult.absent =>
                  'Taytay LGU did not record you as attending. If that is '
                      'wrong, contact the office.',
                AttendanceResult.notRecorded =>
                  'Attendance for this event has not been recorded yet.',
              },
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

/// Places left, only as the office stated them.
class _Capacity extends StatelessWidget {
  const _Capacity({required this.capacity});

  final EventCapacity capacity;

  @override
  Widget build(BuildContext context) {
    final remaining = capacity.remaining;
    final total = capacity.capacity;

    final line = switch ((remaining, total)) {
      (final int r, final int t) when r > 0 => '$r of $t places left',
      (final int r, null) when r > 0 => '$r places left',
      (final int r, _) when r <= 0 => 'No places left',
      (null, final int t) => 'Room for $t people',
      _ => null,
    };
    if (line == null) return const SizedBox.shrink();

    return AppBanner(
      tone: capacity.isFull ? BannerTone.warning : BannerTone.info,
      title: 'Places',
      message: capacity.isFull
          ? '$line. The office can tell you whether a waitlist is open.'
          : line,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.xs),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: IconSizes.md, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
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
