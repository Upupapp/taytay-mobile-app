import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/taytay_states.dart';
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

class _NewsPostScreenState extends State<NewsPostScreen>
    with LiveRefresh<NewsPostScreen> {
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
    // An edit to the article shows without a pull (D-218).
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.news,
    }, () => unawaited(_controller?.refreshQuietly()));
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
        child: LoadingSkeleton(
          layout: SkeletonLayout.detail,
          semanticLabel: 'Loading the announcement',
        ),
      );
    }

    final Announcement? post = controller.post;
    // A read that trying again could fix (the network, a timeout, the
    // server) is a failure with Try again, not "not available"; a refusal or
    // an id nothing answers to keeps "not available" (D-220).
    final AppFailure? failure = controller.loadFailure;
    if (post == null && failure != null && failure.isRetryable) {
      return _Shell(
        child: FailureView(
          failure: failure,
          environment: AppDependencies.of(context).config.environment,
          onRetry: controller.load,
        ),
      );
    }
    if (post == null) {
      return _Shell(
        child: _NotAvailable(
          message: DeepLinkRejection.unknownTarget.residentMessage,
        ),
      );
    }

    return Scaffold(
      backgroundColor: BrandColors.white,
      body: BalitaCanvas(
        frame: BalitaFrame.article,
        article: post,
        loadCover: AppDependencies.of(context).config.usesMockData
            ? null
            : AppDependencies.of(context).mediaBytes.newsCover,
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
      backgroundColor: BrandColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          const BlueHeader(
            title: 'Balita',
            subtitle: 'Bayan ng Taytay · Rizal',
            showBack: true,
          ),
          Padding(padding: const EdgeInsets.all(Spacing.lg), child: child),
        ],
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'This announcement is not available',
      message: message,
      boxed: true,
      primaryAction: true,
      actionLabel: 'See all announcements',
      onAction: () => context.goNamed(AppRoute.news.routeName),
    );
  }
}
