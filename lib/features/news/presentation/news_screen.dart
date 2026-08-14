import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/announcement_repository.dart';

/// News — municipal announcements (`balita`).
///
/// Public, because `GET /api/v1/announcements` is public. What a local
/// government publishes to its residents is the last thing that should be behind
/// a sign-in wall: the people most likely to lack an account are the people most
/// likely to need a typhoon advisory.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _loading = true;
  AppFailure? _failure;
  Paginated<Announcement>? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == null && _failure == null) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).announcementRepository;
    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await repository.listAnnouncements();
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
      appBar: AppBar(title: const Text('News')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: switch ((_loading, _failure, page)) {
            (true, _, null) => const AppLoadingView(
              message: 'Loading announcements…',
            ),
            (_, final AppFailure _, _) => ListView(
              children: <Widget>[
                StatusView(
                  title: 'No announcements yet',
                  kind: StatusKind.empty,
                  icon: Icons.campaign_outlined,
                  message:
                      'Taytay LGU has not published announcements in this app '
                      'yet. Municipal notices are still posted at the '
                      'municipal hall and barangay halls.',
                  primaryAction: TextButton(
                    onPressed: _load,
                    child: const Text('Check again'),
                  ),
                ),
              ],
            ),
            (_, _, final Paginated<Announcement> loaded) when loaded.isEmpty =>
              ListView(
                children: const <Widget>[
                  StatusView(
                    title: 'Nothing new right now',
                    kind: StatusKind.empty,
                    icon: Icons.campaign_outlined,
                    message: 'New Taytay LGU announcements will appear here.',
                  ),
                ],
              ),
            (_, _, final Paginated<Announcement> loaded) => ListView.builder(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: loaded.items.length,
              itemBuilder: (context, index) =>
                  _AnnouncementCard(announcement: loaded.items[index]),
            ),
            // Not loading, no failure, no page: the first frame before
            // `didChangeDependencies` has run. Never a resident-visible state
            // for more than a frame, and a spinner is the honest rendering.
            _ => const AppLoadingView(),
          },
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: AppCard(
        onTap: () => context.goNamed(
          AppRoute.newsPost.routeName,
          pathParameters: <String, String>{'postId': announcement.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(announcement.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              announcement.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
