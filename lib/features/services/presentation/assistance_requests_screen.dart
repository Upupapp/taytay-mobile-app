import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/service_request_repository.dart';

/// The resident's own assistance requests, and the status of each.
///
/// ---
///
/// **`/me/` only.** The contract row is `GET /api/v1/me/assistance-requests`,
/// scoped `own-record`. There is no code path here that names another resident,
/// and none that could: the endpoint takes no resident identifier.
///
/// **What a citizen projection excludes.** The matrix says the detail response
/// carries "**no assessment, no internal notes, no staff identities**". This
/// screen renders a status and a reference number, which is what a resident
/// needs to quote at the counter, and has no field for anything else.
class AssistanceRequestsScreen extends StatefulWidget {
  const AssistanceRequestsScreen({super.key});

  @override
  State<AssistanceRequestsScreen> createState() =>
      _AssistanceRequestsScreenState();
}

class _AssistanceRequestsScreenState extends State<AssistanceRequestsScreen> {
  bool _loading = true;
  AppFailure? _failure;
  Paginated<ServiceRequest>? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == null && _failure == null) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceRequestRepository;
    setState(() => _loading = true);

    final result = await repository.listOwnRequests();
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
      appBar: AppBar(title: const Text('My requests')),
      body: SafeArea(
        // Belt and braces with the route guard: the route is verified-only, so
        // this can only render for a verified resident — but a screen that also
        // states its own requirement keeps working if it is ever reused inside a
        // route with a weaker one.
        child: CapabilityGate(
          capability: ResidentCapability.trackAssistanceRequests,
          child: switch ((_loading, _failure, page)) {
            (true, _, null) => const AppLoadingView(
              message: 'Loading your requests…',
            ),
            (_, final AppFailure _, _) => ListView(
              children: <Widget>[
                StatusView(
                  title: 'Not available yet',
                  kind: StatusKind.empty,
                  icon: Icons.assignment_outlined,
                  message:
                      'Taytay LGU has not switched on request tracking in this '
                      'app yet. The municipal hall can tell you where your '
                      'request stands.',
                  primaryAction: TextButton(
                    onPressed: _load,
                    child: const Text('Check again'),
                  ),
                ),
              ],
            ),
            (_, _, final Paginated<ServiceRequest> loaded)
                when loaded.isEmpty =>
              ListView(
                children: const <Widget>[
                  StatusView(
                    title: 'You have no requests',
                    kind: StatusKind.empty,
                    icon: Icons.assignment_outlined,
                    message:
                        'Anything you apply for with Taytay LGU will appear '
                        'here.',
                  ),
                ],
              ),
            (_, _, final Paginated<ServiceRequest> loaded) => ListView.builder(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: loaded.items.length,
              itemBuilder: (context, index) {
                final request = loaded.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: AppCard(
                    onTap: () => context.goNamed(
                      AppRoute.requestDetail.routeName,
                      pathParameters: <String, String>{'requestId': request.id},
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          request.serviceCode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(_stateLabel(request.state)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Not loading, no failure, no page: the first frame before
            // `didChangeDependencies` has run.
            _ => const AppLoadingView(),
          },
        ),
      ),
    );
  }
}

/// One request, and its outstanding requirements.
///
/// The identifier is re-validated here: this is the most sensitive deep-link
/// target in the app, and it is reached from a push notification.
class AssistanceRequestScreen extends StatefulWidget {
  const AssistanceRequestScreen({
    required this.requestId,
    this.showRequirements = false,
    super.key,
  });

  final String requestId;

  /// True for `/requests/:id/requirements` — the same record, opened at the
  /// list of documents the office is waiting for.
  final bool showRequirements;

  @override
  State<AssistanceRequestScreen> createState() =>
      _AssistanceRequestScreenState();
}

class _AssistanceRequestScreenState extends State<AssistanceRequestScreen> {
  bool _loading = true;
  AppFailure? _failure;
  ServiceRequest? _request;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.requestId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_request == null && _failure == null && _idIsValid) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceRequestRepository;
    setState(() => _loading = true);

    final result = await repository.loadOwnRequest(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (request) => _request = request,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showRequirements ? 'Documents needed' : 'Request status',
        ),
      ),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.trackAssistanceRequests,
          child: switch ((_idIsValid, _loading, request)) {
            (false, _, _) => _NotAvailable(
              message: DeepLinkRejection.invalidIdentifier.residentMessage,
            ),
            (_, true, null) => const AppLoadingView(
              message: 'Opening your request…',
            ),
            (_, _, null) => _NotAvailable(
              message: DeepLinkRejection.unknownTarget.residentMessage,
            ),
            (_, _, final ServiceRequest loaded) => ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                Text(
                  loaded.serviceCode,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(_stateLabel(loaded.state)),
                if (loaded.referenceNumber != null) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  Text('Reference: ${loaded.referenceNumber}'),
                ],
                const SizedBox(height: Spacing.xl),
                // Deliberately not an action. A notification may bring a
                // resident here, and a link must never submit, cancel or
                // confirm anything on their behalf.
                Text(
                  widget.showRequirements
                      ? 'Bring the documents Taytay LGU asked for to the '
                            'municipal hall. Uploading them in this app is not '
                            'available yet.'
                      : 'Taytay LGU will contact you about this request.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          },
        ),
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
      title: 'This request is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      message: message,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.requests.routeName),
        child: const Text('See my requests'),
      ),
    );
  }
}

/// Resident-facing status wording.
///
/// Derived from the app's own state enum, never printed from the server's raw
/// string: a raw lifecycle value is internal vocabulary, and an unrecognised one
/// must read as "being processed" rather than as something alarming.
String _stateLabel(ServiceRequestState? state) => switch (state) {
  ServiceRequestState.draft => 'Not sent yet',
  ServiceRequestState.submitted => 'Sent to Taytay LGU',
  ServiceRequestState.underReview => 'Being reviewed',
  ServiceRequestState.needsMoreInformation => 'More information needed',
  ServiceRequestState.approved => 'Approved',
  ServiceRequestState.readyForRelease => 'Ready for release',
  ServiceRequestState.completed => 'Completed',
  ServiceRequestState.rejected => 'Not approved',
  ServiceRequestState.cancelled => 'Cancelled',
  null => 'Being processed',
};
