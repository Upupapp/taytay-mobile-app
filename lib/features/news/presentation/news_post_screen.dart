import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/announcement_repository.dart';
import 'balita_canvas.dart';
import 'post_detail_controller.dart';

/// One announcement, opened from the feed or from a push notification.
///
/// **The identifier is re-validated here.** A path can be typed, pasted, or
/// restored, and none of those pass through the deep-link resolver.
///
/// **A missing post is an ordinary outcome.** An announcement can be withdrawn
/// between the notification and the tap.
///
/// **The page does not offer comments, reactions, or reports.** The news
/// contract a resident can call is the read. Those controls would tell someone
/// their words were recorded when the server has nowhere to put them. A guest
/// reads the article.
class NewsPostScreen extends StatefulWidget {
  const NewsPostScreen({required this.postId, super.key});

  final String postId;

  @override
  State<NewsPostScreen> createState() => _NewsPostScreenState();
}

class _NewsPostScreenState extends State<NewsPostScreen> {
  PostDetailController? _controller;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.postId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_idIsValid) return;

    _controller =
        PostDetailController(
            repository: AppDependencies.of(context).announcementRepository,
            postId: widget.postId,
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

  @override
  Widget build(BuildContext context) {
    if (!_idIsValid) {
      return _Shell(
        child: _NotAvailable(
          message: DeepLinkRejection.invalidIdentifier.residentMessage,
        ),
      );
    }

    final PostDetailController? controller = _controller;
    if (controller == null || controller.isLoading) {
      return const _Shell(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Announcement? post = controller.post;
    if (post == null) {
      return _Shell(
        child: _NotAvailable(
          message: DeepLinkRejection.unknownTarget.residentMessage,
        ),
      );
    }

    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: BalitaCanvas(
        frame: BalitaFrame.article,
        article: post,
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          const MunicipalHeader(
            title: 'Balita',
            subtitle: 'Bayan ng Taytay · Rizal',
            plainSeal: true,
          ),
          Expanded(child: child),
        ],
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
