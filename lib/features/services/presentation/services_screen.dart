import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/result/result.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/lgu_service.dart';

/// The municipal service catalogue.
///
/// ---
///
/// **Public, on the backend's own instruction.** `GET /api/v1/services` is
/// unauthenticated with the reason written into the route file: *"citizens must
/// be able to browse it before registering."* A person deciding whether to
/// register should be able to see what they would be registering for.
///
/// **Locked services are shown with their requirement, not hidden.** Hiding
/// tells a resident nothing and makes the path to full access invisible; it also
/// discloses nothing to show, because the catalogue is public and the server
/// authorises regardless. What varies with access level is the *label on the
/// tile*, never which tiles exist.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _loading = true;
  AppFailure? _failure;
  Paginated<LguService>? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == null && _failure == null) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).serviceCatalogRepository;
    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await repository.listServices();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (page) => _page = page,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  /// Applying acts on the resident's civil record, so it runs through the same
  /// central evaluation as everything else and holds a bounded intent when the
  /// gate stops it.
  Future<void> _apply(LguService service) async {
    final dependencies = AppDependencies.of(context);
    final verdict = CapabilityService.evaluate(
      session: dependencies.session.state,
      capability: ResidentCapability.trackAssistanceRequests,
    );

    if (verdict is CapabilityUsable) {
      // The submission screen belongs to a later TAB. Nothing is submitted from
      // here, and no endpoint is invented to pretend otherwise.
      dependencies.intents.remember(
        ResidentIntentKind.applyForService,
        targetId: service.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Applications open in this app soon. Visit the municipal hall to '
            'apply today.',
          ),
        ),
      );
      return;
    }

    await AccessGateSheet.showForCapability(
      context: context,
      verdict: verdict,
      intent: ResidentIntentKind.applyForService,
      targetId: service.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: switch ((_loading, _failure, page)) {
            (true, _, null) => const AppLoadingView(
              message: 'Loading municipal services…',
            ),
            (_, final AppFailure _, _) => ListView(
              children: <Widget>[
                StatusView(
                  title: 'Could not load services',
                  kind: StatusKind.error,
                  message:
                      'We could not reach Taytay LGU just now. Check your '
                      'connection and try again.',
                  primaryAction: FilledButton(
                    onPressed: _load,
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
            (_, _, final Paginated<LguService> loaded) when loaded.isEmpty =>
              ListView(
                children: const <Widget>[
                  StatusView(
                    title: 'No services listed yet',
                    kind: StatusKind.empty,
                    message:
                        'Taytay LGU services will appear here once the '
                        'catalogue is published.',
                  ),
                ],
              ),
            (_, _, final Paginated<LguService> loaded) => ListView.builder(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: loaded.items.length,
              itemBuilder: (context, index) {
                final service = loaded.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: AppCard(
                    onTap: () => _apply(service),
                    semanticLabel: service.name,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
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
