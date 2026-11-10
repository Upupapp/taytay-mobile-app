import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/feed_row.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_glyph.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/announcement_repository.dart';

/// Which Balita frame the canvas is painting.
enum BalitaFrame {
  feed,
  filter,
  emptyCategory,
  emptyFeed,
  failed,
  loading,
  article,
}

/// One chip on the Balita list. [slug] is empty for Lahat, which sends no filter.
@immutable
class BalitaChip {
  const BalitaChip({required this.slug, required this.label});

  final String slug;
  final String label;

  static const BalitaChip all = BalitaChip(slug: '', label: 'Lahat');

  /// The design set, and the mock catalogue. Live chips come from
  /// `GET /news/categories`, with Lahat added on the client.
  static const List<BalitaChip> design = <BalitaChip>[
    all,
    BalitaChip(slug: 'abiso', label: 'Abiso'),
    BalitaChip(slug: 'advisory', label: 'Advisory'),
    BalitaChip(slug: 'negosyo', label: 'Negosyo'),
    BalitaChip(slug: 'safety', label: 'Safety'),
    BalitaChip(slug: 'events', label: 'Events'),
  ];
}

/// The Balita list (design `Balita.dc.html`) and the article page, which
/// follows the Office detail pattern (photo, white sheet, pill actions).
///
/// The shell paints the tab bar. Balita is read-only: a resident reads and
/// shares; nothing here publishes, reacts or comments.
class BalitaCanvas extends StatelessWidget {
  const BalitaCanvas({
    required this.frame,
    this.articles = const <Announcement>[],
    this.article,
    this.selectedChip = 'Lahat',
    this.chips = BalitaChip.design,
    this.onChip,
    this.onArticle,
    this.onShare,
    this.onBell,
    this.onBack,
    this.onSeeAll,
    this.onRetry,
    this.scrollController,
    this.loadCover,
    super.key,
  });

  final BalitaFrame frame;
  final List<Announcement> articles;
  final Announcement? article;
  final String selectedChip;
  final List<BalitaChip> chips;
  final ValueChanged<BalitaChip>? onChip;
  final ValueChanged<Announcement>? onArticle;
  final ValueChanged<Announcement>? onShare;
  final VoidCallback? onBell;
  final VoidCallback? onBack;
  final VoidCallback? onSeeAll;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;

  /// `GET /news/{id}/cover`. Null on a dev mock, where covers are assets.
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    // Material gives the page the theme's text style wherever it is hosted,
    // so no text falls back to the debug style outside a Scaffold.
    return Material(type: MaterialType.transparency, child: _page(context));
  }

  Widget _page(BuildContext context) {
    if (frame == BalitaFrame.article) {
      return _ArticlePage(
        article: article,
        loadCover: loadCover,
        onBack: onBack,
      );
    }
    final bool all = selectedChip == BalitaChip.all.label;
    return GlassBackground(
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          BlueHeader(
            overlap: true,
            leading: const HeaderSeal(),
            title: all
                ? 'Balita'
                : (selectedChip == 'Advisory' ? 'Advisories' : selectedChip),
            subtitle: all ? 'Bayan ng Taytay · Rizal' : 'Balita · filtered',
            actions: <Widget>[
              HeaderIconButton(
                key: const Key('balita-bell'),
                icon: TaytayIcons.bell,
                semanticLabel: 'Notifications',
                onPressed: onBell,
              ),
            ],
            bottom: _Chips(
              chips: chips,
              selected: frame == BalitaFrame.loading
                  ? BalitaChip.all.label
                  : selectedChip,
              onChip: onChip,
            ),
          ),
          GlassOverlap(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: AnimatedSwitcher(
                duration: Motion.decorative(context, MotionTokens.standard),
                switchInCurve: MotionTokens.enterEase,
                switchOutCurve: MotionTokens.exitEase,
                layoutBuilder: (Widget? current, List<Widget> previous) =>
                    Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previous, ?current],
                    ),
                child: KeyedSubtree(
                  key: ValueKey<String>('${frame.name}-$selectedChip'),
                  child: _body(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return switch (frame) {
      BalitaFrame.loading => const LoadingSkeleton(
        layout: SkeletonLayout.feed,
        count: 4,
        semanticLabel: 'Loading Balita',
      ),
      BalitaFrame.failed => ErrorState(
        title: 'Announcements are not available right now',
        message:
            'We could not reach Taytay LGU. Check your connection and try '
            'again. Municipal notices are also posted at the municipal hall '
            'and barangay halls.',
        onRetry: onRetry,
        offline: true,
        boxed: true,
      ),
      BalitaFrame.emptyFeed => const EmptyState(
        title: 'Nothing new right now',
        message: 'New Taytay LGU announcements will appear here.',
        boxed: true,
      ),
      BalitaFrame.emptyCategory => _EmptyCategory(
        chip: selectedChip,
        onSeeAll: onSeeAll,
      ),
      _ => _Feed(
        articles: articles,
        showBanner:
            frame == BalitaFrame.filter ||
            articles.any((Announcement article) => article.isPinned),
        onArticle: onArticle,
        onShare: onShare,
        loadCover: loadCover,
      ),
    };
  }
}

/// Header chips (`.chip.bar` / `.chip.onbar`), scrolling sideways.
class _Chips extends StatelessWidget {
  const _Chips({required this.chips, required this.selected, this.onChip});

  final List<BalitaChip> chips;
  final String selected;
  final ValueChanged<BalitaChip>? onChip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Filter Balita',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Spacing.sm),
              _Chip(
                chip: chips[i],
                on: chips[i].label == selected,
                onTap: onChip == null ? null : () => onChip?.call(chips[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.chip, required this.on, this.onTap});

  final BalitaChip chip;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: chip.label,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('balita-chip-${chip.label}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: ComponentSizes.chipHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: Spacing.xs,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? BrandColors.white : BrandColors.transparent,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: on
                      ? BrandColors.white
                      : BrandColors.white.withValues(alpha: 0.4),
                  width: FocusRing.borderWidth,
                ),
              ),
              child: Text(
                chip.label,
                maxLines: 1,
                style: AppTypography.chip.copyWith(
                  color: on ? BrandColors.blue : BrandColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({
    required this.articles,
    required this.showBanner,
    this.onArticle,
    this.onShare,
    this.loadCover,
  });

  final List<Announcement> articles;
  final bool showBanner;
  final ValueChanged<Announcement>? onArticle;
  final ValueChanged<Announcement>? onShare;
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    final Announcement? banner = _bannerOf(articles, showBanner);
    // The design's featured carousel needs a `featured` flag the feed does
    // not send. It is not drawn, and no post is promoted in its place.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (banner != null) ...<Widget>[
          _PinnedCard(
            article: banner,
            onOpen: onArticle == null ? null : () => onArticle?.call(banner),
          ),
          const SizedBox(height: Spacing.section),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xs,
            Spacing.xxs,
            Spacing.xs,
            Spacing.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'Latest Balita',
              style: AppTypography.sectionTitle.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.ink,
              ),
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < articles.length; i++)
                _StoryRow(
                  article: articles[i],
                  divider: i > 0,
                  loadCover: loadCover,
                  onOpen: onArticle == null
                      ? null
                      : () => onArticle?.call(articles[i]),
                  onShare: onShare == null
                      ? null
                      : () => onShare?.call(articles[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Announcement? _bannerOf(List<Announcement> articles, bool showBanner) {
  for (final Announcement article in articles) {
    if (article.isPinned) return article;
    if (showBanner && article.presentation?.pinnedTitle != null) {
      return article;
    }
  }
  return null;
}

/// `.row`: eyebrow, title, date, and the 76 px cover (or a sky tile).
class _StoryRow extends StatelessWidget {
  const _StoryRow({
    required this.article,
    required this.divider,
    this.onOpen,
    this.onShare,
    this.loadCover,
  });

  final Announcement article;
  final bool divider;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    final String date = _listDate(article);
    final Widget row = Padding(
      padding: const EdgeInsets.only(top: 14, bottom: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Eyebrow(article: article),
                const SizedBox(height: Spacing.xs),
                Text(
                  article.title,
                  style: AppTypography.listTitle.copyWith(
                    fontWeight: AppTypography.strong,
                    color: BrandColors.ink,
                  ),
                ),
                if (date.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    date,
                    style: AppTypography.small.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          _Thumbnail(article: article, load: loadCover),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(
                top: BorderSide(color: BrandColors.ink.withValues(alpha: 0.07)),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            label: article.title,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: Key('balita-article-${article.id}'),
                onTap: onOpen,
                child: row,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Share ${article.title}',
              excludeSemantics: true,
              child: GestureDetector(
                key: Key('balita-share-${article.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: onShare,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: A11y.minTapTarget,
                    minHeight: A11y.minTapTarget,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const TaytayIcon(
                        icon: TaytayIcons.share,
                        size: 16,
                        color: BrandColors.muted,
                        semanticLabel: '',
                        excludeSemantics: true,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: AppTypography.label.copyWith(
                          color: BrandColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.article});

  final Announcement article;

  @override
  Widget build(BuildContext context) {
    final String office = article.author ?? article.officeSlug ?? '';
    final String category = (article.category ?? '').toUpperCase();
    final bool sample = article.presentation?.sample == true;
    return Text.rich(
      TextSpan(
        style: AppTypography.category.copyWith(color: _ink(article)),
        children: <InlineSpan>[
          if (category.isNotEmpty) TextSpan(text: category),
          if (office.isNotEmpty)
            TextSpan(text: category.isNotEmpty ? ' · $office' : office),
          // Dev mock rows are marked so nobody reads a fixture as a notice.
          if (sample) ...const <InlineSpan>[
            TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SampleTag(),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.article, this.load});

  final Announcement article;
  final MediaBytesLoader? load;

  @override
  Widget build(BuildContext context) {
    final BalitaPresentation? presentation = article.presentation;
    final String? asset = presentation?.listCover == true
        ? presentation?.coverAsset
        : null;
    final Widget placeholder = _placeholder();
    Widget? photo;
    if (asset != null) {
      photo = Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      );
    } else if (_reservesCover(article) && load != null) {
      photo = MediaBytesHost(
        id: article.id,
        load: load,
        builder: (Uint8List? bytes) => bytes == null
            ? placeholder
            : DecodedMemoryImage(bytes: bytes, placeholder: placeholder),
      );
    }
    if (photo == null) return placeholder;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: SizedBox.square(dimension: FeedRow.thumbnailSize, child: photo),
      ),
    );
  }

  Widget _placeholder() {
    final BrandGradient sky = BrandGradients.tile(TileTone.sky);
    return ExcludeSemantics(
      child: Container(
        width: FeedRow.thumbnailSize,
        height: FeedRow.thumbnailSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: sky.toLinearGradient(),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: GlyphIcon(_glyph(article), size: 28, color: sky.onColor),
      ),
    );
  }
}

/// `.card.pin3`: the pinned or emergency advisory, gold-tinted glass.
class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.article, this.onOpen});

  final Announcement article;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final bool emergency =
        article.advisoryLevel?.known == AdvisoryLevel.emergency;
    final String title = emergency
        ? 'Emergency advisory'
        : article.presentation?.pinnedTitle ?? 'Pinned advisory';
    final String body = article.presentation?.pinnedBody ?? article.title;
    return GlassCard(
      key: Key('balita-pinned-${article.id}'),
      pinned: true,
      padding: const EdgeInsets.all(Spacing.md),
      onTap: onOpen,
      semanticLabel: '$title. $body',
      child: Row(
        children: <Widget>[
          IconTile.glyph(
            glyph: emergency ? TaytayGlyph.siren : TaytayGlyph.megaphone,
            tone: emergency ? TileTone.red : TileTone.gold,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.category.copyWith(
                    color: emergency ? BrandColors.redInk : BrandColors.goldInk,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  body,
                  style: AppTypography.listTitle.copyWith(
                    fontWeight: AppTypography.strong,
                    color: BrandColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (onOpen != null) ...<Widget>[
            const SizedBox(width: Spacing.sm),
            const TaytayIcon(
              icon: TaytayIcons.chevronRight,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.chevron,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.chip, this.onSeeAll});

  final String chip;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final bool events = chip == 'Events';
    return GlassCard(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        children: <Widget>[
          EmptyState(
            title: events
                ? 'Walang events pa'
                : 'Walang ${chip.toLowerCase()} pa',
            message: events
                ? "No upcoming municipal events have been posted. We'll "
                      'notify you when the LGU announces one.'
                : 'No ${chip.toLowerCase()} posts have been published yet.',
          ),
          FilledButton.tonal(
            key: const Key('balita-see-all'),
            onPressed: onSeeAll,
            child: const Text('See all Balita'),
          ),
        ],
      ),
    );
  }
}

/// The article (Office detail pattern): cover photo, white sheet pulled up
/// over it, the category and byline, the title and the text. The article
/// offers no actions, so the pattern's pill row is not drawn.
class _ArticlePage extends StatelessWidget {
  const _ArticlePage({required this.article, this.loadCover, this.onBack});

  final Announcement? article;
  final MediaBytesLoader? loadCover;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Announcement? article = this.article;
    final BalitaPresentation? presentation = article?.presentation;
    final String? asset = presentation?.coverAsset;
    final bool remote =
        article != null && asset == null && _reservesCover(article);
    final bool hero = asset != null || remote;
    final Widget header = hero
        ? _ArticleHero(
            article: article,
            asset: asset,
            loadCover: loadCover,
            onBack: onBack,
          )
        : BlueHeader(
            title: 'Balita',
            subtitle: 'Bayan ng Taytay · Rizal',
            showBack: true,
            onBack: onBack,
          );
    final Widget sheet = article == null
        ? const SizedBox.shrink()
        : _Sheet(article: article);
    return ColoredBox(
      color: BrandColors.white,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          header,
          if (hero)
            GlassOverlap(amount: Radii.sheetLarge, child: sheet)
          else
            sheet,
        ],
      ),
    );
  }
}

class _ArticleHero extends StatelessWidget {
  const _ArticleHero({
    required this.article,
    required this.asset,
    this.loadCover,
    this.onBack,
  });

  final Announcement? article;
  final String? asset;
  final MediaBytesLoader? loadCover;
  final VoidCallback? onBack;

  static const double _height = 250;

  @override
  Widget build(BuildContext context) {
    final Announcement? article = this.article;
    final String? asset = this.asset;
    final String? credit = article?.presentation?.photoCredit;
    final String label = credit ?? article?.title ?? '';
    final MediaBytesLoader? load = loadCover;
    Widget photo = const SizedBox.expand();
    if (asset != null) {
      photo = Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: label,
      );
    } else if (article != null && load != null) {
      photo = MediaBytesHost(
        id: article.id,
        load: load,
        builder: (Uint8List? bytes) => bytes == null
            ? const SizedBox.expand()
            : DecodedMemoryImage(
                bytes: bytes,
                height: _height,
                semanticLabel: label,
                placeholder: const SizedBox.expand(),
              ),
      );
    }
    final double top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: _height + top,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: BrandColors.navy, child: photo),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  BrandColors.navy.withValues(alpha: 0.55),
                  BrandColors.navy.withValues(alpha: 0),
                ],
                stops: const <double>[0, 0.38],
              ),
            ),
          ),
          Positioned(
            left: Spacing.lg,
            right: Spacing.lg,
            top: top + 14,
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: A11y.backButtonVisual,
                      height: A11y.backButtonVisual,
                      decoration: BoxDecoration(
                        color: BrandColors.navy.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    TaytayBackButton(onPressed: onBack, translucent: true),
                  ],
                ),
                const Spacer(),
                const HeaderSeal(),
              ],
            ),
          ),
          if (credit != null && credit.isNotEmpty)
            Positioned(
              right: 14,
              left: Spacing.lg,
              bottom: 42,
              child: Align(
                alignment: Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.navy.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: Spacing.xs,
                    ),
                    child: Text(
                      credit,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.tiny.copyWith(
                        fontWeight: AppTypography.medium,
                        color: BrandColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.article});

  final Announcement article;

  @override
  Widget build(BuildContext context) {
    final BalitaPresentation? presentation = article.presentation;
    final String lead = presentation?.lead ?? article.body;
    final String office = article.author ?? article.officeSlug ?? '';
    final String labelled = presentation?.dateLabel ?? '';
    final String date = labelled.isNotEmpty ? labelled : _listDate(article);
    final String meta = <String>[
      if (office.isNotEmpty) office,
      if (date.isNotEmpty) date,
    ].join(' · ');
    final List<BalitaFact> facts = presentation?.facts ?? const <BalitaFact>[];
    final String category = (article.category ?? '').toUpperCase();
    final String footer = presentation?.footer ?? '';
    final List<Widget> blocks = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (category.isNotEmpty || meta.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              children: <Widget>[
                if (category.isNotEmpty)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _tagBackground(article),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: Spacing.xs,
                      ),
                      child: Text(
                        category,
                        style: AppTypography.category.copyWith(
                          color: _ink(article),
                        ),
                      ),
                    ),
                  ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: Spacing.sm),
          Semantics(
            header: true,
            child: Text(
              article.title,
              style: AppTypography.pageTitle.copyWith(color: BrandColors.ink),
            ),
          ),
        ],
      ),
      if (lead.isNotEmpty)
        Semantics(
          container: true,
          label: lead,
          child: ExcludeSemantics(
            child: Text(
              lead,
              style: AppTypography.bodyStyle.copyWith(
                height: 1.55,
                color: BrandColors.text,
              ),
            ),
          ),
        ),
      if (facts.isNotEmpty)
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: BrandColors.divider)),
          ),
          child: Column(
            children: <Widget>[for (final BalitaFact f in facts) _Fact(f)],
          ),
        ),
      if (footer.isNotEmpty)
        Text(
          footer,
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.sheetLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.formGutter,
          22,
          Spacing.formGutter,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var i = 0; i < blocks.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: Spacing.formGap),
              blocks[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// `.fact`: a 36 px glyph square, the label and the value.
class _Fact extends StatelessWidget {
  const _Fact(this.fact);

  final BalitaFact fact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrandColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: ComponentSizes.tileSmall,
              height: ComponentSizes.tileSmall,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.background,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: TaytayIcon(
                icon: _namedIcon(fact.icon),
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    fact.label,
                    style: AppTypography.small.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    fact.value,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _listDate(Announcement article) {
  final String? listed = article.presentation?.listDate;
  if (listed != null) return listed;
  final String? labelled = article.presentation?.dateLabel;
  if (labelled != null && labelled.isNotEmpty) return labelled;
  final DateTime? at = article.publishedAt;
  if (at == null) return '';
  return ManilaTime.formatDate(at);
}

Color _ink(Announcement article) {
  return switch ((article.category ?? '').toLowerCase()) {
    'abiso' => CategoryTone.green.color,
    'negosyo' => CategoryTone.gold.color,
    'safety' => CategoryTone.red.color,
    _ => CategoryTone.blue.color,
  };
}

Color _tagBackground(Announcement article) {
  return switch ((article.category ?? '').toLowerCase()) {
    'abiso' => BrandColors.green50,
    'negosyo' => BrandColors.gold50,
    'safety' => BrandColors.red50,
    _ => BrandColors.blue50,
  };
}

TaytayGlyph _glyph(Announcement article) {
  final String? named = article.presentation?.tileIcon;
  return switch (named ?? (article.category ?? '').toLowerCase()) {
    'cloud' || 'cloud-rain' => TaytayGlyph.cloud,
    'briefcase' || 'negosyo' => TaytayGlyph.briefcase,
    'bell' || 'siren' || 'safety' => TaytayGlyph.siren,
    'calendar' || 'calendar-x' || 'events' => TaytayGlyph.clock,
    'phone' => TaytayGlyph.phone,
    'map-pin' => TaytayGlyph.pin,
    'file-text' => TaytayGlyph.document,
    'globe' => TaytayGlyph.globe,
    'message-square' => TaytayGlyph.chat,
    _ => TaytayGlyph.megaphone,
  };
}

IconData _namedIcon(String name) {
  return switch (name) {
    'bookmark' => TaytayIcons.bookmark,
    'briefcase' => TaytayIcons.briefcase,
    'bell' || 'siren' => TaytayIcons.siren,
    'cloud' || 'cloud-rain' => TaytayIcons.cloudRain,
    'map-pin' => TaytayIcons.mapPin,
    'file-text' => TaytayIcons.fileText,
    'phone' => TaytayIcons.phone,
    'calendar' => TaytayIcons.calendar,
    'calendar-x' => TaytayIcons.calendarX,
    'globe' => TaytayIcons.globe,
    'smartphone' => TaytayIcons.smartphone,
    'message-square' => TaytayIcons.messageSquare,
    'triangle-alert' => TaytayIcons.triangleAlert,
    'share' => TaytayIcons.share,
    _ => TaytayIcons.landmark,
  };
}

/// A cover is read only when the item says it has one (`cover_url`), and
/// always through `GET /news/{id}/cover`, never from that address.
bool _reservesCover(Announcement article) {
  final String? url = article.coverUrl;
  return url != null && url.isNotEmpty;
}
