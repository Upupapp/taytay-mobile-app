import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_state.dart';
import '../../../core/sharing/share_service.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../domain/announcement_repository.dart';
import 'balita_canvas.dart';
import 'news_feed_controller.dart';

/// Balita — the municipal news list.
///
/// **Public.** A guest reads the whole feed. Nothing on this screen asks them
/// to register.
///
/// **This app consumes; it never publishes.** No compose, pin, or moderation
/// control. Saving a story declines: the news contract has no bookmark route,
/// and the screen says so in its own words.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsFeedController? _controller;
  final ScrollController _scroll = ScrollController();
  String _chip = 'Lahat';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    _controller =
        NewsFeedController(
            repository: AppDependencies.of(context).announcementRepository,
          )
          ..addListener(_onChanged)
          ..refresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Loads the next page before the resident reaches the bottom.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final double remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 600) _controller?.loadMore();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  BalitaFrame _frame(NewsFeedController? controller) {
    if (controller == null || controller.isLoadingFirstPage) {
      return BalitaFrame.loading;
    }
    if (controller.failure != null && controller.items.isEmpty) {
      return BalitaFrame.failed;
    }
    if (controller.isEmptyAndHealthy) {
      return _chip == 'Lahat'
          ? BalitaFrame.emptyFeed
          : BalitaFrame.emptyCategory;
    }
    return _chip == 'Lahat' ? BalitaFrame.feed : BalitaFrame.filter;
  }

  Future<void> _selectChip(String chip) async {
    if (_chip == chip) return;
    setState(() => _chip = chip);
    await _controller?.applyCategory(chip);
  }

  Future<void> _save(Announcement article) async {
    final Result<void> result = await AppDependencies.of(context)
        .announcementRepository
        .saveArticle(article.id);
    if (!mounted) return;
    // The server's debug text stays off the screen. There is no bookmark route.
    result.fold(
      onOk: (_) {},
      onErr: (_) => Outcome.problem(
        context,
        'Saving a story is not available yet.',
      ),
    );
  }

  Future<void> _share(Announcement article) async {
    final ShareOutcome outcome = await AppDependencies.of(context)
        .shareService
        .share(
          ShareableContent(
            title: article.title,
            body: '${article.preview}\n\nFrom Taytay LGU',
            // The server's link, or none. This app does not compose a URL.
            url: article.shareUrl,
          ),
        );
    if (!mounted) return;
    switch (outcome) {
      case ShareOutcome.copiedToClipboard:
        Outcome.succeeded(context, 'Copied. You can paste this into any app.');
      case ShareOutcome.unavailable:
        Outcome.problem(context, 'Sharing is not available on this device.');
      case ShareOutcome.shared:
      case ShareOutcome.dismissed:
        break;
    }
  }

  void _open(Announcement article) {
    context.goNamed(
      AppRoute.newsPost.routeName,
      pathParameters: <String, String>{'postId': article.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final NewsFeedController? controller = _controller;
    final bool guest =
        AppDependencies.of(context).session.state is! AuthenticatedSession;

    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: RefreshIndicator(
        onRefresh: () => controller?.refresh() ?? Future<void>.value(),
        child: BalitaCanvas(
          frame: _frame(controller),
          articles: controller?.items ?? const <Announcement>[],
          selectedChip: _chip,
          scrollController: _scroll,
          onChip: _selectChip,
          onArticle: _open,
          onSave: _save,
          onShare: _share,
          onBell: () => context.goNamed(
            guest
                ? AppRoute.signIn.routeName
                : AppRoute.notifications.routeName,
          ),
          onBack: () => _selectChip('Lahat'),
          onSeeAll: () => _selectChip('Lahat'),
          onRetry: () => controller?.refresh(),
        ),
      ),
    );
  }
}
