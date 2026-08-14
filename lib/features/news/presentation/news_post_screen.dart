import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/announcement_repository.dart';

/// One announcement, opened by tapping the list or by a push notification.
///
/// ---
///
/// **The identifier is re-validated here.** It was validated once by [DeepLink]
/// on the way in, but a path can also be typed, pasted or restored from the back
/// stack, and none of those routes pass through the resolver. Validating at the
/// point of use means there is no arrangement of navigation that reaches a
/// request built from an unchecked id.
///
/// **A missing post is an ordinary outcome, not an error.** An announcement can
/// be withdrawn between the notification being sent and the resident tapping it
/// — a correction to a typhoon advisory is exactly the case — so the screen says
/// so plainly and offers the list, rather than reporting a fault.
class NewsPostScreen extends StatefulWidget {
  const NewsPostScreen({required this.postId, super.key});

  final String postId;

  @override
  State<NewsPostScreen> createState() => _NewsPostScreenState();
}

class _NewsPostScreenState extends State<NewsPostScreen> {
  bool _loading = true;
  AppFailure? _failure;
  Announcement? _post;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.postId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_post == null && _failure == null && _idIsValid) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).announcementRepository;
    setState(() => _loading = true);

    final result = await repository.loadAnnouncement(widget.postId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (post) => _post = post,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: SafeArea(
        child: switch ((_idIsValid, _loading, post)) {
          // An id this app would never have produced. Same words as a missing
          // post: the app is not an oracle for which ids exist.
          (false, _, _) => _NotAvailable(
            message: DeepLinkRejection.invalidIdentifier.residentMessage,
          ),
          (_, true, null) => const AppLoadingView(
            message: 'Opening announcement…',
          ),
          (_, _, null) => _NotAvailable(
            message: DeepLinkRejection.unknownTarget.residentMessage,
          ),
          (_, _, final Announcement loaded) => ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Text(
                loaded.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Spacing.md),
              Text(loaded.body, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        },
      ),
    );
  }
}

/// The honest dead end for a link that cannot be opened.
class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'This announcement is not available',
      kind: StatusKind.empty,
      icon: Icons.link_off_outlined,
      message: message,
      primaryAction: FilledButton(
        onPressed: () => context.goNamed(AppRoute.news.routeName),
        child: const Text('See all announcements'),
      ),
    );
  }
}
