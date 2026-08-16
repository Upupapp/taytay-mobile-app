import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/next_action_card.dart';
import '../../events/domain/event_repository.dart';
import '../../news/domain/announcement_repository.dart';
import '../../services/domain/lgu_service.dart';
import '../../services/domain/request_status_copy.dart';
import '../../services/domain/service_request_repository.dart';
import '../../verification/domain/verification_status_detail.dart';

/// How many items a Home preview shows.
///
/// Three. Home is a summary; a resident who wants the fourth taps through to the
/// destination that exists for exactly that. A longer list turns Home into a
/// worse copy of the News tab.
const int _previewLimit = 3;

/// A titled block with a "see all" affordance.
class HomeSectionFrame extends StatelessWidget {
  const HomeSectionFrame({
    required this.title,
    required this.child,
    this.seeAllRoute,
    this.seeAllLabel = 'See all',
    super.key,
  });

  final String title;
  final Widget child;
  final AppRoute? seeAllRoute;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = seeAllRoute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Wrapped rather than a Row: at 200% text a title and a "See all" link
        // do not fit side by side, and the link must not be pushed off screen.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: Spacing.sm,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            if (route != null)
              TextButton(
                onPressed: () => context.goNamed(route.routeName),
                child: Text(seeAllLabel),
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        child,
      ],
    );
  }
}

/// Loads a preview and renders nothing when there is nothing to show.
///
/// **The Home rule, in one place.** A destination screen explains why it is
/// empty, because the resident chose to open it. A Home section that cannot load
/// simply disappears, because a summary made of apologies answers "what can I do
/// now?" with a shrug. The sections that never disappear — the hero, the
/// catalogue, the municipal hall — are what keep Home worth opening.
class _PreviewSection<T> extends StatefulWidget {
  const _PreviewSection({
    required this.title,
    required this.load,
    required this.itemBuilder,
    required this.seeAllRoute,
    super.key,
  });

  final String title;
  final Future<Result<Paginated<T>>> Function(AppDependencies) load;
  final Widget Function(BuildContext, T) itemBuilder;
  final AppRoute seeAllRoute;

  @override
  State<_PreviewSection<T>> createState() => _PreviewSectionState<T>();
}

class _PreviewSectionState<T> extends State<_PreviewSection<T>> {
  bool _started = false;
  bool _loading = true;
  List<T> _items = <T>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    final result = await widget.load(dependencies);
    if (!mounted) return;
    setState(() {
      _loading = false;
      // A failure and an empty page are the same on Home: nothing to preview.
      // The reason belongs on the destination screen, which says it properly.
      _items = result.valueOrNull?.items.take(_previewLimit).toList() ?? <T>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return HomeSectionFrame(
        title: widget.title,
        seeAllRoute: widget.seeAllRoute,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    return HomeSectionFrame(
      title: widget.title,
      seeAllRoute: widget.seeAllRoute,
      child: Column(
        children: <Widget>[
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: widget.itemBuilder(context, item),
            ),
        ],
      ),
    );
  }
}

/// Latest announcements. Public content, shown to everyone.
class HomeNewsSection extends StatelessWidget {
  const HomeNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _PreviewSection<Announcement>(
      title: 'Latest from Taytay LGU',
      seeAllRoute: AppRoute.news,
      load: (dependencies) => dependencies.announcementRepository
          .listAnnouncements(perPage: _previewLimit),
      itemBuilder: (context, announcement) => AppCard(
        onTap: () => context.goNamed(
          AppRoute.newsPost.routeName,
          pathParameters: <String, String>{'postId': announcement.id},
        ),
        semanticLabel: announcement.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              announcement.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming events. Public content, shown to everyone.
///
/// **Not "your registered events".** The endpoint matrix has no event
/// registration row, so there is no authoritative source for which events a
/// resident signed up to, and a list captioned "yours" built from anything else
/// would be a claim this app cannot support.
class HomeEventsSection extends StatelessWidget {
  const HomeEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _PreviewSection<LguEvent>(
      title: 'Coming up in Taytay',
      seeAllRoute: AppRoute.events,
      load: (dependencies) =>
          dependencies.eventRepository.listEvents(perPage: _previewLimit),
      itemBuilder: (context, event) => AppCard(
        onTap: () => context.goNamed(
          AppRoute.eventDetail.routeName,
          pathParameters: <String, String>{'eventId': event.id},
        ),
        semanticLabel: event.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(event.title, style: Theme.of(context).textTheme.titleSmall),
            if (event.venue != null) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              Text(
                event.venue!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shortcuts into the catalogue. The one section backed by a live endpoint.
///
/// It never disappears: when the catalogue cannot be reached it still points at
/// the Services destination, so Home always offers somewhere to go.
class HomeServicesSection extends StatelessWidget {
  const HomeServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _ServicesShortcuts();
  }
}

class _ServicesShortcuts extends StatefulWidget {
  @override
  State<_ServicesShortcuts> createState() => _ServicesShortcutsState();
}

class _ServicesShortcutsState extends State<_ServicesShortcuts> {
  bool _started = false;
  bool _loading = true;
  List<LguService> _services = const <LguService>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceCatalogRepository;
    final result = await repository.listServices(perPage: _previewLimit);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _services =
          result.valueOrNull?.items.take(_previewLimit).toList() ??
          const <LguService>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSectionFrame(
      title: 'Municipal services',
      seeAllRoute: AppRoute.services,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          : _services.isEmpty
          // Still useful with nothing loaded: the destination is one tap away
          // and the municipal hall is named below.
          ? AppCard(
              onTap: () => context.goNamed(AppRoute.services.routeName),
              child: Text(
                'Browse everything Taytay LGU offers, and what each service '
                'needs from you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Column(
              children: <Widget>[
                for (final service in _services)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: AppCard(
                      onTap: () => context.goNamed(AppRoute.services.routeName),
                      semanticLabel: service.name,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.description_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              service.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The verification next-action card, for a signed-in resident.
///
/// Reads `GET /api/v1/me/verification` through the existing repository. Reuses
/// `ResidentVerificationStage` from TAB 08 rather than re-deriving status here,
/// so Home and the verification screen cannot disagree about what state a
/// resident is in — and so the fail-closed rule (an unrecognised state degrades
/// to "needs a person to check", never to "verified") holds on both.
class HomeVerificationSection extends StatefulWidget {
  const HomeVerificationSection({super.key});

  @override
  State<HomeVerificationSection> createState() =>
      _HomeVerificationSectionState();
}

class _HomeVerificationSectionState extends State<HomeVerificationSection> {
  bool _started = false;
  VerificationStatusDetail? _status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    // Gated centrally. A guest never reaches this widget, but reading `/me/`
    // data is exactly the operation that must not depend on being reached only
    // by the right caller.
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.completeVerification,
    )) {
      return;
    }

    final result = await dependencies.verificationRepository
        .loadOwnStatusDetail();
    if (!mounted) return;
    setState(() => _status = result.valueOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    // "Can they open their digital ID" is the same question as "are they
    // verified", asked through the one service that answers it — so this card
    // and the route guard cannot drift apart.
    final verified = CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.holdDigitalId,
    );
    final stage = _status?.stage;

    // No status yet — still loading, or the module is not built. The card falls
    // back to what the session already knows, which is true regardless.
    final (NextActionTone tone, String title, String body) = switch (stage) {
      null when verified => (
        NextActionTone.inProgress,
        'You are verified',
        'Your Taytay digital ID and service applications are open to you.',
      ),
      null => (
        NextActionTone.needsYou,
        'One step to go',
        'Verify your identity with Taytay LGU to unlock your digital ID and '
            'service applications.',
      ),
      final ResidentVerificationStage s => (
        s.needsResidentAction
            ? NextActionTone.needsYou
            : NextActionTone.inProgress,
        s.label,
        s.summary,
      ),
    };

    return NextActionCard(
      tone: tone,
      title: title,
      body: body,
      // A verified resident's useful next action is their ID, not another look
      // at a status that says "verified" — whether or not the status loaded.
      primaryAction: verified
          ? AppButton(
              label: 'Open my digital ID',
              fullWidth: false,
              onPressed: () => context.goNamed(AppRoute.digitalId.routeName),
            )
          : AppButton(
              label: stage?.nextActionLabel ?? 'Check my status',
              fullWidth: false,
              onPressed: () => context.goNamed(AppRoute.verification.routeName),
            ),
    );
  }
}

/// A verified resident's own assistance requests, in summary.
///
/// **Status words only — no counts, no amounts, no assessment.** The citizen
/// projection carries "no assessment, no internal notes, no staff identities",
/// and this card has no field any of that could occupy. It disappears entirely
/// when there is nothing to show, so a resident with no requests is not shown an
/// empty box about requests.
class HomeRequestsSection extends StatelessWidget {
  const HomeRequestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _PreviewSection<ServiceRequest>(
      title: 'Your requests',
      seeAllRoute: AppRoute.requests,
      load: (dependencies) {
        // Central gate, again at the point of the read.
        if (!CapabilityService.canOpen(
          session: dependencies.session.state,
          capability: ResidentCapability.trackAssistanceRequests,
        )) {
          return Future<Result<Paginated<ServiceRequest>>>.value(
            const Err<Paginated<ServiceRequest>>(ForbiddenFailure()),
          );
        }
        return dependencies.serviceRequestRepository.listOwnRequests(
          perPage: _previewLimit,
        );
      },
      itemBuilder: (context, request) => AppCard(
        onTap: () => context.goNamed(
          AppRoute.requestDetail.routeName,
          pathParameters: <String, String>{'requestId': request.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              request.serviceCode,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              requestStatusLabel(request.state),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The route that works when the software does not.
///
/// Always present, at every access level. Every other section on Home depends on
/// a module that may not be built, a connection that may not be there, or an
/// account the reader may not have. This one depends on none of them.
class HomeMunicipalHallSection extends StatelessWidget {
  const HomeMunicipalHallSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.location_city_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Taytay Municipal Hall',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Anything this app cannot do yet, Taytay LGU staff can do in '
            'person. You do not need this app or an account to be served at '
            'the counter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Status wording moved to `services/presentation/request_status_copy.dart`
// when a second screen needed it. Home and the request list had grown separate
// exhaustive switches over the same enum, which is how a resident ends up
// reading two different sentences about one application.
