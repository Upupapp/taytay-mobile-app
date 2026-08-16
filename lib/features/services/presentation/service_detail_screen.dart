import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/lgu_service.dart';
import 'service_directory_controller.dart';

/// One catalogue entry in full.
///
/// ---
///
/// **Rendered from the list, because there is no detail endpoint.** The
/// committed contract has `GET /api/v1/services` and nothing addressed by id, so
/// this screen loads the catalogue and finds the entry by its stable `code`.
/// Inventing `/services/{id}` would be a contract the server never agreed to.
///
/// **The identifier is a code, not a UUID**, and it is re-validated here. A code
/// is what an office quotes, it is legible in a link, it survives a re-seed of
/// the catalogue, and it fits the deep-link character class. A path can also be
/// typed or restored from the back stack without passing through `DeepLink`, so
/// the check happens at the point of use.
///
/// **The CTA is access-aware and never acts by itself** (acceptance 2 and the
/// Master Command's rule about gate recovery). Applying is gated centrally; when
/// the gate is passed the resident lands back here and reads what to do — the
/// app does not submit anything, because there is no submission endpoint and
/// because a link or a gate must never perform a sensitive action on somebody's
/// behalf.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({required this.serviceCode, super.key});

  final String serviceCode;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceDirectoryController? _controller;

  bool get _codeIsValid => DeepLink.isValidIdentifier(widget.serviceCode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_codeIsValid) return;

    _controller =
        ServiceDirectoryController(
            repository: AppDependencies.of(context).serviceCatalogRepository,
            telemetry: AppDependencies.of(context).telemetry,
          )
          ..addListener(_onChanged)
          ..load();
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

  /// Opens the application, after the central gate allows it.
  ///
  /// ---
  ///
  /// **Opening is not submitting.** A resident who arrives here straight from a
  /// sign-in gate lands on the first step of a wizard, and every step is
  /// reversible until they press send on the review. A link, a notification or
  /// a gate must never complete a sensitive action on somebody's behalf.
  ///
  /// **Access is checked, availability is not** — `canOpen`, not `evaluate`.
  /// The wizard already tells the truth when `ServiceDelivery` is unpublished,
  /// and its wording names the municipal hall; refusing to open it would
  /// replace that with a generic "not available" and hide a screen that works.
  Future<void> _apply(LguService service) async {
    final dependencies = AppDependencies.of(context);
    final session = dependencies.session.state;

    if (CapabilityService.canOpen(
      session: session,
      capability: ResidentCapability.applyForAssistance,
    )) {
      context.goNamed(
        AppRoute.applyForService.routeName,
        pathParameters: <String, String>{'serviceCode': service.code},
      );
      return;
    }

    // Held so the resident returns to this service after the gate, rather than
    // to wherever sign-in happens to finish. Remembering grants nothing.
    await AccessGateSheet.showForCapability(
      context: context,
      verdict: CapabilityService.evaluate(
        session: session,
        capability: ResidentCapability.applyForAssistance,
      ),
      intent: ResidentIntentKind.applyForService,
      targetId: service.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final service = controller?.byCode(widget.serviceCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Service')),
      body: SafeArea(
        child: switch ((_codeIsValid, controller, service)) {
          (false, _, _) => const _NotAvailable(),
          (_, final ServiceDirectoryController c, null) when !c.hasLoaded =>
            const AppLoadingView(message: 'Opening service…'),
          (_, _, null) => const _NotAvailable(),
          (_, _, final LguService loaded) => _Detail(
            service: loaded,
            stale: controller?.isShowingStale ?? false,
            onApply: () => _apply(loaded),
          ),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.service,
    required this.stale,
    required this.onApply,
  });

  final LguService service;
  final bool stale;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        if (stale) ...<Widget>[
          const AppBanner(
            tone: BannerTone.warning,
            title: 'Showing what was saved on your phone',
            message:
                'Taytay LGU could not be reached, so this may be out of date.',
          ),
          const SizedBox(height: Spacing.lg),
        ],
        Semantics(
          header: true,
          child: Text(service.name, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: Spacing.sm),
        Text(service.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: Spacing.xl),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  'About this service',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              _Line(label: 'Reference code', value: service.code),
              _Line(label: 'Category', value: service.category.raw),
              _Line(
                label: 'Where you can do this',
                // The server's own list of channels, rendered as reported. It
                // answers "does the LGU offer this here?" — a fact about the
                // service, never a statement about the resident.
                value: service.availableChannels
                    .map((channel) => channel.raw)
                    .join(', '),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Guidance, never a verdict.
        const AppBanner(
          tone: BannerTone.info,
          title: 'What Taytay LGU decides',
          message:
              'Whether you qualify, and what you receive, is decided by Taytay '
              'LGU staff when they look at your documents. This app does not '
              'assess applications and cannot tell you the outcome in advance.',
        ),
        const SizedBox(height: Spacing.xl),

        AppButton(label: 'Apply for this service', onPressed: onApply),
        const SizedBox(height: Spacing.sm),
        Text(
          'Nothing is submitted by tapping this.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
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
    );
  }
}

/// The honest dead end for a code that does not resolve.
class _NotAvailable extends StatelessWidget {
  const _NotAvailable();

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'This service is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      // The same sentence a bad identifier gets: the app is not an oracle for
      // which codes exist.
      message: DeepLinkRejection.unknownTarget.residentMessage,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.services.routeName),
        child: const Text('See all services'),
      ),
    );
  }
}
