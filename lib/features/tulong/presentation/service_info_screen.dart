import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/sharing/share_service.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'tulong_canvas.dart';

/// One social service. The same screen paints every slug.
///
/// Information only. There is no apply control. Message is gated the same
/// way an office message is: a guest signs in, an unverified resident is
/// asked to verify, a verified resident opens compose.
class ServiceInfoScreen extends StatefulWidget {
  const ServiceInfoScreen({required this.slug, super.key});

  /// The service slug. The route parameter is still `programId` so existing
  /// links keep working. The value is a service slug, not a programme id.
  final String slug;

  @override
  State<ServiceInfoScreen> createState() => _ServiceInfoScreenState();
}

class _ServiceInfoScreenState extends State<ServiceInfoScreen> {
  SocialService? _service;
  bool _missing = false;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  SocialServiceRepository get _repository =>
      AppDependencies.of(context).socialServiceRepository;

  Future<void> _load() async {
    final Result<SocialService> result = await _repository.loadService(
      widget.slug,
    );
    if (!mounted) return;
    switch (result) {
      case Ok<SocialService>(:final value):
        setState(() {
          _service = value;
          _missing = false;
          _failed = false;
        });
      case Err<SocialService>(:final failure):
        setState(() {
          _missing = failure is NotFoundFailure;
          _failed = failure is! NotFoundFailure;
        });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRoute.programs.routeName);
  }

  Future<void> _call() async {
    final String? phone = _service?.dialable;
    if (phone == null) {
      Outcome.problem(context, 'This office has not published a phone number.');
      return;
    }
    final LinkOutcome outcome = await AppDependencies.of(
      context,
    ).externalLinks.dial(phone);
    if (!mounted) return;
    if (outcome == LinkOutcome.unavailable || outcome == LinkOutcome.refused) {
      Outcome.problem(context, 'Calling is not available on this device.');
    }
  }

  Future<void> _directions() async {
    final String? query = _service?.directionsQuery;
    if (query == null) {
      Outcome.problem(context, 'This office has not published an address.');
      return;
    }
    final String url = Uri.https(
      'www.google.com',
      '/maps/search/',
      <String, String>{'api': '1', 'query': query},
    ).toString();
    final LinkOutcome outcome = await AppDependencies.of(
      context,
    ).externalLinks.open(url);
    if (!mounted) return;
    if (outcome == LinkOutcome.unavailable || outcome == LinkOutcome.refused) {
      Outcome.problem(context, 'Maps could not be opened on this device.');
    }
  }

  Future<void> _message() async {
    final SocialService? service = _service;
    final String? office = service?.officeSlug;
    if (service == null || office == null || office.isEmpty) {
      Outcome.problem(context, 'This programme is not linked to an office.');
      return;
    }
    final AccessDecision decision = AccessPolicy.evaluate(
      session: AppDependencies.of(context).session.state,
      requirement: ResidentIntentKind.messageOffice.requirement,
    );
    if (decision is! AccessAllowed) {
      await AccessGateSheet.show(
        context: context,
        decision: decision,
        intent: ResidentIntentKind.messageOffice,
        targetId: office,
      );
      return;
    }
    if (!mounted) return;
    await context.pushNamed(
      AppRoute.officeCompose.routeName,
      pathParameters: <String, String>{'officeId': office},
    );
  }

  void _office() {
    final String? office = _service?.officeSlug;
    if (office == null || office.isEmpty) return;
    context.pushNamed(
      AppRoute.tulongOffice.routeName,
      pathParameters: <String, String>{'officeId': office},
    );
  }

  Future<void> _share() async {
    final SocialService? service = _service;
    if (service == null) return;
    final String headline = service.featuredHeadline ?? service.name;
    final ShareOutcome outcome = await AppDependencies.of(context).shareService
        .share(
          ShareableContent(
            title: headline,
            body: '${service.details}\n\nFrom Taytay LGU',
          ),
        );
    if (!mounted) return;
    switch (outcome) {
      case ShareOutcome.copiedToClipboard:
        Outcome.succeeded(context, 'Copied. You can paste this into any app.');
      case ShareOutcome.unavailable:
        Outcome.problem(context, 'Sharing is not available on this device.');
      case ShareOutcome.shared:
      case ShareOutcome.dismissed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SocialService? service = _service;
    if (service != null) {
      return Scaffold(
        backgroundColor: BrandColors.white,
        body: TulongCanvas(
          frame: TulongFrame.detail,
          service: service,
          onBack: _back,
          onCall: _call,
          onDirections: _directions,
          onMessage: _message,
          onOffice: _office,
          onShare: _share,
          loadHero: AppDependencies.of(context).config.usesMockData
              ? null
              : AppDependencies.of(context).mediaBytes.serviceHero,
        ),
      );
    }
    // Loading, not found and failed share the page: the blue header with
    // the back control, then the state on the soft background.
    final Widget state = _missing
        ? const EmptyState(
            title: 'This programme is not available',
            message: 'Go back to Tulong to see the programmes listed now.',
            boxed: true,
          )
        : _failed
        ? ErrorState(
            title: 'Programme pages need a connection',
            message: 'Check your connection and try again.',
            offline: true,
            boxed: true,
            onRetry: () {
              setState(() => _failed = false);
              _load();
            },
          )
        : const LoadingSkeleton(
            layout: SkeletonLayout.detail,
            count: 1,
            semanticLabel: 'Loading programme',
          );
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          BlueHeader(
            title: 'Tulong',
            subtitle: TulongCanvas.listSubtitle,
            showBack: true,
            onBack: _back,
          ),
          Padding(padding: const EdgeInsets.all(Spacing.lg), child: state),
        ],
      ),
    );
  }
}
