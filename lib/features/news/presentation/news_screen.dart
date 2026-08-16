import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/announcement_repository.dart';
import 'news_feed_controller.dart';

/// News — municipal announcements (`balita`).
///
/// ---
///
/// **Public, because `GET /api/v1/announcements` is public.** What a local
/// government publishes to its residents is the last thing that should sit
/// behind a sign-in wall: the people most likely to lack an account are the
/// people most likely to need a typhoon advisory. A guest reads the whole feed
/// and every post, and nothing on this screen asks them to register.
///
/// **This app consumes; it never publishes.** No compose button, no schedule, no
/// pin, no archive, no moderation. Those are admin-console actions, and the
/// repository has no method that could express one.
///
/// **Interactions arrive in TAB 20.** This screen renders the counts the office
/// publishes and does not offer a like or a comment control — a disabled one
/// would be an advertisement for a feature that does not exist yet.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsFeedController? _controller;
  final ScrollController _scroll = ScrollController();

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

  /// Loads the next page before the resident reaches the bottom, so an
  /// image-heavy feed does not stall at the end of every page.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining =
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: SafeArea(
        child: controller == null
            ? const _FeedSkeleton()
            : RefreshIndicator(
                onRefresh: controller.refresh,
                child: _Feed(controller: controller, scroll: _scroll),
              ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.controller, required this.scroll});

  final NewsFeedController controller;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingFirstPage) return const _FeedSkeleton();

    if (controller.failure != null) {
      // Distinct from an empty feed, deliberately. "Taytay LGU has published
      // nothing" and "we could not reach Taytay LGU" are different statements,
      // and during an emergency the difference is the whole point.
      return ListView(
        children: <Widget>[
          StatusView(
            title: 'Announcements are not available right now',
            kind: StatusKind.error,
            icon: Icons.wifi_off_outlined,
            message:
                'We could not reach Taytay LGU. Check your connection and try '
                'again. Municipal notices are also posted at the municipal hall '
                'and barangay halls.',
            primaryAction: TextButton(
              onPressed: controller.refresh,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (controller.isEmptyAndHealthy) {
      return ListView(
        children: const <Widget>[
          StatusView(
            title: 'Nothing new right now',
            kind: StatusKind.empty,
            icon: Icons.campaign_outlined,
            message: 'New Taytay LGU announcements will appear here.',
          ),
        ],
      );
    }

    final posts = controller.items;

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.all(Spacing.lg),
      // One extra row for the footer: a loader, a page-failure retry, or the
      // end of the feed.
      itemCount: posts.length + 1,
      itemBuilder: (context, index) {
        if (index == posts.length) {
          return _FeedFooter(controller: controller);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: AnnouncementCard(announcement: posts[index]),
        );
      },
    );
  }
}

/// What sits below the last post.
class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.controller});

  final NewsFeedController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.pageFailure != null) {
      // The pages already read stay on screen. Losing signal at post forty must
      // not empty the article somebody was reading.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: AppBanner(
          tone: BannerTone.warning,
          title: 'Could not load more',
          message: 'What you have already read is still here.',
          action: TextButton(
            onPressed: controller.retryPage,
            child: const Text('Try again'),
          ),
        ),
      );
    }

    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Text(
          'That is everything Taytay LGU has published here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return const SizedBox(height: Spacing.xl);
  }
}

/// One post in the feed.
///
/// Public so the home screen's preview can render the same card rather than a
/// second, subtly different one.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({required this.announcement, super.key});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advisory = announcement.advisoryLevel?.known;

    return AppCard(
      onTap: () => context.goNamed(
        AppRoute.newsPost.routeName,
        pathParameters: <String, String>{'postId': announcement.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (announcement.isPinned || announcement.isAdvisory) ...<Widget>[
            _EmphasisChip(pinned: announcement.isPinned, advisory: advisory),
            const SizedBox(height: Spacing.sm),
          ],

          if (announcement.media != null) ...<Widget>[
            _CoverImage(media: announcement.media!),
            const SizedBox(height: Spacing.md),
          ],

          Text(announcement.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text(
            announcement.preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: Spacing.sm),
          _Byline(announcement: announcement),

          if (announcement.engagement?.hasAny ?? false) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _Counts(engagement: announcement.engagement!),
          ],
        ],
      ),
    );
  }
}

/// Pinned and advisory emphasis, as words as well as colour.
class _EmphasisChip extends StatelessWidget {
  const _EmphasisChip({required this.pinned, required this.advisory});

  final bool pinned;
  final AdvisoryLevel? advisory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (String label, IconData icon, Color colour) = switch (advisory) {
      AdvisoryLevel.emergency => (
        'Emergency advisory',
        Icons.warning_amber_outlined,
        theme.colorScheme.error,
      ),
      AdvisoryLevel.advisory => (
        'Advisory',
        Icons.priority_high_outlined,
        theme.colorScheme.primary,
      ),
      // Pinned but not an advisory, or an advisory level this build does not
      // recognise: emphasised as pinned rather than dropped or guessed at.
      _ => (
        'Pinned by Taytay LGU',
        Icons.push_pin_outlined,
        theme.colorScheme.primary,
      ),
    };

    return Row(
      children: <Widget>[
        Icon(icon, size: IconSizes.sm, color: colour),
        const SizedBox(width: Spacing.xs),
        // Never colour alone — the word carries the meaning.
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: colour)),
      ],
    );
  }
}

/// The cover picture, with its space reserved before the bytes arrive.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.media});

  final AnnouncementMedia media;

  /// Used when the server did not send dimensions. A wide-ish default is less
  /// disruptive than an unbounded box, and the reflow when the real picture
  /// lands is one card rather than the whole list.
  static const double _fallbackAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: AspectRatio(
        aspectRatio: media.aspectRatio ?? _fallbackAspectRatio,
        child: Image.network(
          media.url,
          fit: BoxFit.cover,
          // Described by the LGU when it chose to; otherwise announced as
          // decorative rather than given a description this app invented for a
          // picture it cannot see.
          semanticLabel: media.alternativeText,
          excludeFromSemantics: media.alternativeText == null,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: IconSizes.md,
                      height: IconSizes.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
          // A picture that will not load must never take the post down with it:
          // the words are the part that matters in an advisory.
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Who published it, in which category, and when.
class _Byline extends StatelessWidget {
  const _Byline({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final parts = <String>[
      if (announcement.author != null) announcement.author!,
      if (announcement.category != null) announcement.category!,
      if (announcement.publishedAt != null)
        formatPublishedDate(announcement.publishedAt!),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Counts the office published. Never a zero the app inferred.
class _Counts extends StatelessWidget {
  const _Counts({required this.engagement});

  final AnnouncementEngagement engagement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: <Widget>[
        if (engagement.reactions != null) ...<Widget>[
          Icon(
            Icons.favorite_border,
            size: IconSizes.sm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.xxs),
          Text('${engagement.reactions}', style: style),
          const SizedBox(width: Spacing.md),
        ],
        if (engagement.comments != null) ...<Widget>[
          Icon(
            Icons.mode_comment_outlined,
            size: IconSizes.sm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.xxs),
          Text('${engagement.comments}', style: style),
          const SizedBox(width: Spacing.md),
        ],
        if (engagement.shares != null) ...<Widget>[
          Icon(
            Icons.share_outlined,
            size: IconSizes.sm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.xxs),
          Text('${engagement.shares}', style: style),
        ],
      ],
    );
  }
}

/// The first-load placeholder.
///
/// Card-shaped rather than a bare spinner, so the feed does not jump from a
/// centred circle to a dense list — and so a slow connection shows the shape of
/// what is coming instead of an ambiguous wait.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = theme.colorScheme.surfaceContainerHighest;

    return Semantics(
      liveRegion: true,
      label: 'Loading announcements',
      child: ExcludeSemantics(
        child: ListView.builder(
          padding: const EdgeInsets.all(Spacing.lg),
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: block,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  _SkeletonBar(width: 220, colour: block),
                  const SizedBox(height: Spacing.sm),
                  _SkeletonBar(width: double.infinity, colour: block),
                  const SizedBox(height: Spacing.xs),
                  _SkeletonBar(width: 160, colour: block),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.colour});

  final double width;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
    );
  }
}

/// `dd MMM yyyy`, written out because a numeric date is ambiguous between
/// Philippine and US conventions and there is no localisation seam yet.
String formatPublishedDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}
