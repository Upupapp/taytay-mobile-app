import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/sharing/share_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'tulong_canvas.dart';

/// One social service. The same screen paints every slug.
///
/// Message is gated the same way an office message is: a guest signs in, an
/// unverified resident is asked to verify, a verified resident opens compose.
///
/// A page whose `can_apply` is true also offers Apply (D-226), gated the same
/// way, which opens the wizard. The wizard's first step says who may apply
/// and what to do first.
class ServiceInfoScreen extends StatefulWidget {
  const ServiceInfoScreen({required this.slug, super.key});

  /// The service slug. The route parameter is still `programId` so existing
  /// links keep working. The value is a service slug, not a programme id.
  final String slug;

  @override
  State<ServiceInfoScreen> createState() => _ServiceInfoScreenState();
}

class _ServiceInfoScreenState extends State<ServiceInfoScreen>
    with LiveRefresh<ServiceInfoScreen> {
  SocialService? _service;
  bool _missing = false;

  /// The read failed for a reason other than "no such programme".
  AppFailure? _failure;
  bool _started = false;
  bool _reading = false;

  /// `linked_to_office_record` from `GET /me`, read only for a verified
  /// resident on a page that takes applications. Null is "not said" (a
  /// guest, an older API, a failed read), and the Apply card then says
  /// nothing about the link (D-226).
  bool? _linked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    // The office's edits to this programme show without a pull (D-218,
    // D-221).
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.services,
    }, () => unawaited(_load(quiet: true)));
    // The office links the account on ID review or at the counter; the card
    // says so without a restart.
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.account,
    }, () => unawaited(_loadLink()));
  }

  /// Whether the MSWDO has linked the account, for the Apply card. Quiet: a
  /// failed read leaves the card as it was.
  Future<void> _loadLink() async {
    final SocialService? service = _service;
    if (service == null || !service.takesApplications) return;
    final AppDependencies dependencies = AppDependencies.of(context);
    final bool verified =
        AccessPolicy.evaluate(
              session: dependencies.session.state,
              requirement: ResidentIntentKind.applyForService.requirement,
            )
            is AccessAllowed;
    if (!verified) return;
    final Result<ResidentProfileDetail> me = await dependencies
        .residentProfileRepository
        .loadOwnDetail();
    if (!mounted) return;
    if (me case Ok(:final ResidentProfileDetail value)) {
      setState(() => _linked = value.linkedToOfficeRecord);
    }
  }

  SocialServiceRepository get _repository =>
      AppDependencies.of(context).socialServiceRepository;

  /// Shows the skeleton while trying again, so a tap is seen to do something
  /// and cannot be repeated while the read is on its way (D-221).
  void _retry() {
    if (_reading) return;
    setState(() => _failure = null);
    unawaited(_load());
  }

  /// Reads the programme. A [quiet] re-read (D-218) only replaces a page
  /// already on screen, and keeps it when the read fails. A `404` is an
  /// answer, not a failure: the office archived the programme, so the page
  /// says it is not available instead of keeping it (D-222).
  Future<void> _load({bool quiet = false}) async {
    if (_reading || (quiet && _service == null)) return;
    _reading = true;
    final Result<SocialService> result = await _repository.loadService(
      widget.slug,
    );
    _reading = false;
    if (!mounted) return;
    switch (result) {
      case Ok<SocialService>(:final value):
        final bool first = _service == null;
        setState(() {
          _service = value;
          _missing = false;
          _failure = null;
        });
        if (first) unawaited(_loadLink());
      case Err<SocialService>(:final failure):
        final bool gone = failure is NotFoundFailure;
        if (quiet && !gone) return;
        setState(() {
          if (gone) _service = null;
          _missing = gone;
          _failure = gone ? null : failure;
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
      Outcome.problem(context, AppStrings.of(context).tulongNoPhone);
      return;
    }
    final LinkOutcome outcome = await AppDependencies.of(
      context,
    ).externalLinks.dial(phone);
    if (!mounted) return;
    if (outcome == LinkOutcome.unavailable || outcome == LinkOutcome.refused) {
      Outcome.problem(context, AppStrings.of(context).tulongNoCalling);
    }
  }

  Future<void> _directions() async {
    final String? query = _service?.directionsQuery;
    if (query == null) {
      Outcome.problem(context, AppStrings.of(context).tulongNoAddress);
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
      Outcome.problem(context, AppStrings.of(context).tulongNoMaps);
    }
  }

  Future<void> _message() async {
    final SocialService? service = _service;
    final String? office = service?.officeSlug;
    if (service == null || office == null || office.isEmpty) {
      Outcome.problem(context, AppStrings.of(context).tulongNoOffice);
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

  /// Gated as Message is: a guest is asked to sign in and an unverified
  /// resident to verify, in the gate's own words; a verified resident opens
  /// the wizard, whose first step says who may apply (D-226).
  Future<void> _apply() async {
    final SocialService? service = _service;
    if (service == null || !service.takesApplications) return;
    final AccessDecision decision = AccessPolicy.evaluate(
      session: AppDependencies.of(context).session.state,
      requirement: ResidentIntentKind.applyForService.requirement,
    );
    if (decision is! AccessAllowed) {
      await AccessGateSheet.show(
        context: context,
        decision: decision,
        intent: ResidentIntentKind.applyForService,
        targetId: service.slug,
      );
      return;
    }
    if (!mounted) return;
    await context.pushNamed(
      AppRoute.applyForTulong.routeName,
      pathParameters: <String, String>{'serviceSlug': service.slug},
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
    final AppStrings strings = AppStrings.of(context);
    final ShareOutcome outcome = await AppDependencies.of(context).shareService
        .share(
          ShareableContent(
            title: headline,
            body: '${service.details}\n\n${strings.tulongShareSignature}',
          ),
        );
    if (!mounted) return;
    switch (outcome) {
      case ShareOutcome.copiedToClipboard:
        Outcome.succeeded(context, strings.tulongCopied);
      case ShareOutcome.unavailable:
        Outcome.problem(context, strings.tulongNoSharing);
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
          onApply: service.takesApplications ? () => unawaited(_apply()) : null,
          accountLinked: _linked,
          loadHero: AppDependencies.of(context).config.usesMockData
              ? null
              : AppDependencies.of(context).mediaBytes.serviceHero,
        ),
      );
    }
    // Loading, not found and failed share the page: the blue header with
    // the back control, then the state on the soft background. Only no
    // connection is said as one; the office's side failing is said in the
    // failure's own words (D-221).
    final AppFailure? failure = _failure;
    final AppStrings strings = AppStrings.of(context);
    final Widget state = _missing
        ? EmptyState(
            title: strings.tulongNotAvailableTitle,
            message: strings.tulongNotAvailableBody,
            boxed: true,
          )
        : failure != null && !FailureView.isOffline(failure)
        ? FailureView(
            failure: failure,
            environment: AppDependencies.of(context).config.environment,
            onRetry: _retry,
            boxed: true,
          )
        : failure != null
        ? ErrorState(
            title: strings.tulongOfflineTitle,
            message: strings.tulongCheckConnection,
            offline: true,
            boxed: true,
            onRetry: _retry,
          )
        : LoadingSkeleton(
            layout: SkeletonLayout.detail,
            count: 1,
            semanticLabel: strings.tulongLoadingOne,
          );
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          BlueHeader(
            title: strings.navTulong,
            subtitle: strings.tulongSubtitle,
            showBack: true,
            onBack: _back,
          ),
          Padding(padding: const EdgeInsets.all(Spacing.lg), child: state),
        ],
      ),
    );
  }
}
