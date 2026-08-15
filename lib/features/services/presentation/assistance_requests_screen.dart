import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/request_status_copy.dart';
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
                        Text(requestStatusLabel(request.state)),
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

// The single-request screen that used to live here has been replaced twice
// over, and is deleted rather than left behind:
//
// * `/requests/:id` is now `AssistanceCaseScreen` (TAB 17), which shows the
//   resident-safe timeline and next steps instead of one status line.
// * `/requests/:id/requirements` is now `RequirementsScreen` (TAB 16), which
//   actually sends documents instead of telling a resident to walk them in.
//
// Keeping the old widget around would have left a screen nothing routes to but
// anything could route to by mistake — and it still carried the copy saying
// uploads were unavailable, which stopped being true in TAB 16.

// Status wording moved to `../domain/request_status_copy.dart` when a second
// screen needed it. See that file for why there is exactly one switch.
