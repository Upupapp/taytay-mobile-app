import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/lgu_service.dart';
import 'service_directory_controller.dart';

/// Programs and services — the municipal directory.
///
/// ---
///
/// **Public, on the backend's own instruction** (acceptance 1).
/// `GET /api/v1/services` is unauthenticated with the reason written into the
/// route file: *"citizens must be able to browse it before registering."* A
/// person deciding whether to register should be able to see what they would be
/// registering for, and the residents least likely to have an account are the
/// ones most likely to need the directory.
///
/// **Search happens on the phone.** The endpoint accepts `?category=` and
/// `?channel=` and no search parameter, so a server-side search would have to be
/// invented — but the local choice is also the better one. A search term on a
/// municipal app is a sentence about somebody's circumstances; filtering here
/// means the LGU never learns what a resident was looking for. See
/// `ServiceDirectoryController`.
///
/// **Nothing on this screen judges eligibility.** It filters a public catalogue
/// by words. There is no "recommended for you", no profile read and no rule
/// evaluation (acceptance 2).
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  ServiceDirectoryController? _controller;
  final TextEditingController _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

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
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _SearchField(
              controller: _search,
              onChanged: controller.search,
              enabled: controller.totalCount > 0,
            ),
            if (controller.availableCategories.isNotEmpty)
              _CategoryChips(controller: controller),
            if (controller.isShowingStale)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: AppBanner(
                  tone: BannerTone.warning,
                  title: 'Showing what was saved on your phone',
                  // The timestamp is the point: a resident deciding whether to
                  // travel to the municipal hall on the strength of a
                  // requirement list needs to know how old the list is.
                  message: <String>[
                    if (controller.loadedAt != null)
                      'Last updated '
                          '${ManilaTime.formatDateTime(controller.loadedAt!)}.',
                    'Taytay LGU could not be reached, so this may be out of '
                        'date. Check with the municipal hall before relying on '
                        'dates or requirements.',
                  ].join(' '),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: _Body(controller: controller, search: _search),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list, or the honest reason there is not one.
class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.search});

  final ServiceDirectoryController controller;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && controller.totalCount == 0) {
      return const AppLoadingView(message: 'Loading municipal services…');
    }

    if (controller.hasNothingToShow) {
      return ListView(
        children: <Widget>[
          StatusView(
            title: 'Could not load services',
            kind: StatusKind.error,
            message:
                'We could not reach Taytay LGU just now. Check your connection '
                'and try again. The municipal hall can help in person either '
                'way.',
            primaryAction: FilledButton(
              onPressed: controller.load,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final visible = controller.visible;

    if (visible.isEmpty) {
      // Two genuinely different situations, two different sentences.
      return ListView(
        children: <Widget>[
          if (controller.isFiltered)
            StatusView(
              title: 'Nothing matches that',
              kind: StatusKind.empty,
              icon: Icons.search_off_outlined,
              message:
                  'Try a different word, or clear the filters to see every '
                  'Taytay LGU service.',
              primaryAction: TextButton(
                onPressed: () {
                  search.clear();
                  controller.clearFilters();
                },
                child: const Text('Clear filters'),
              ),
            )
          else
            const StatusView(
              title: 'No services listed yet',
              kind: StatusKind.empty,
              message:
                  'Taytay LGU services will appear here once the catalogue is '
                  'published.',
            ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: visible.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: _ServiceCard(service: visible[index]),
      ),
    );
  }
}

/// One catalogue entry, showing only contract-backed fields.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final LguService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: () => context.goNamed(
        AppRoute.serviceDetail.routeName,
        // The stable code, not the UUID: it is what an office quotes, it is
        // legible in a link, and it survives a re-seed of the catalogue.
        pathParameters: <String, String>{'serviceCode': service.code},
      ),
      semanticLabel: service.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(service.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            service.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (service.category.isRecognised) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _CategoryTag(
              label: serviceCategoryLabel(context, service.category.known!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.sm,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search services',
          prefixIcon: const Icon(Icons.search),
          // Announced by a screen reader; the icon alone is decoration.
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Category filters, built from what was actually returned.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final ServiceDirectoryController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        children: <Widget>[
          for (final category in controller.availableCategories)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: FilterChip(
                label: Text(serviceCategoryLabel(context, category)),
                selected: controller.category == category,
                onSelected: (_) => controller.filterByCategory(category),
              ),
            ),
        ],
      ),
    );
  }
}
