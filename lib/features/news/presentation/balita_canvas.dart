import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
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

/// The Balita list, filters, and article page.
///
/// The shell paints the tab bar, including the raised centre disc. This
/// canvas is the page above that bar.
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

  static const Color _pageTop = Color(0xFFEAF0FB);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: BrandColors.textPrimary,
        decoration: TextDecoration.none,
      ),
      // CSS line-height keeps half the extra leading above the first line
      // and below the last. Material's default trims both, which pulls
      // every following run up.
      textHeightBehavior: _cssHalfLeading,
      child: ColoredBox(
        color: BrandColors.surface,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[_pageTop, BrandColors.surface],
              stops: <double>[0, 260 / 844],
            ),
          ),
          child: Column(
            children: <Widget>[
              _header(),
              Expanded(child: _fade(_body(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return switch (frame) {
      BalitaFrame.filter || BalitaFrame.emptyCategory => MunicipalHeader(
        title: selectedChip == 'Advisory' ? 'Advisories' : selectedChip,
        subtitle: 'Balita · filtered',
        onBack: onBack,
        plainSeal: true,
      ),
      BalitaFrame.article => MunicipalHeader(
        title: 'Balita',
        subtitle: 'Bayan ng Taytay · Rizal',
        onBack: onBack,
        plainSeal: true,
      ),
      _ => _ListHeader(onBell: onBell),
    };
  }

  Widget _body(BuildContext context) {
    final Widget body = switch (frame) {
      BalitaFrame.loading => _LoadingBody(chips: chips),
      BalitaFrame.failed => _MessageBody(
        chips: chips,
        title: 'Announcements are not available right now',
        message:
            'We could not reach Taytay LGU. Check your connection and try '
            'again. Municipal notices are also posted at the municipal hall '
            'and barangay halls.',
        action: 'Try again',
        onAction: onRetry,
      ),
      BalitaFrame.emptyFeed => _MessageBody(
        chips: chips,
        title: 'Nothing new right now',
        message: 'New Taytay LGU announcements will appear here.',
      ),
      BalitaFrame.emptyCategory => _EmptyCategory(
        chips: chips,
        chip: selectedChip,
        onChip: onChip,
        onSeeAll: onSeeAll,
      ),
      BalitaFrame.article when article != null => _ArticleBody(
        article: article!,
        loadCover: loadCover,
      ),
      BalitaFrame.feed || BalitaFrame.filter => _FeedBody(
        chips: chips,
        articles: articles,
        selectedChip: selectedChip,
        showBanner:
            frame == BalitaFrame.filter ||
            articles.any((Announcement article) => article.isPinned),
        onChip: onChip,
        onArticle: onArticle,
        onShare: onShare,
        scrollController: scrollController,
        loadCover: loadCover,
      ),
      _ => const SizedBox.shrink(),
    };
    return AnimatedSwitcher(
      duration: Motion.decorative(context, MotionTokens.standard),
      switchInCurve: MotionTokens.enterEase,
      switchOutCurve: MotionTokens.exitEase,
      child: KeyedSubtree(
        key: ValueKey<String>('${frame.name}-$selectedChip'),
        child: body,
      ),
    );
  }

  /// Last 28 dp dissolve into the page colour.
  ///
  /// A [ShaderMask] here repainted the last card's line in the fade, which
  /// the designs do not have. An overlay matches the CSS mask on this
  /// background without a second copy of the glyphs.
  Widget _fade(Widget child) {
    return Stack(
      children: <Widget>[
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 28,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00F3F5FA), BrandColors.surface],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({this.onBell});

  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 46, 16, 14),
        child: Row(
          children: <Widget>[
            const _HeaderSeal(),
            const SizedBox(width: 11),
            const Expanded(
              child: MunicipalHeaderTitles(
                title: 'Balita',
                subtitle: 'Municipal news',
              ),
            ),
            const SizedBox(width: 11),
            _Bell(onTap: onBell),
          ],
        ),
      ),
    );
  }
}

class _HeaderSeal extends StatelessWidget {
  const _HeaderSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/brand/taytay_seal.png',
          fit: BoxFit.contain,
          semanticLabel: 'Seal of Taytay, Rizal',
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: const Key('balita-bell'),
      label: 'Notifications',
      width: 44,
      height: 44,
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Stack(
          children: <Widget>[
            Center(
              child: TaytayIcon(
                icon: TaytayIcons.bell,
                size: 19,
                color: Colors.white,
                semanticLabel: '',
                excludeSemantics: true,
              ),
            ),
            Positioned(
              top: 6,
              right: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BrandColors.sealGold,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: BrandColors.taytayBlue, width: 1.5),
                  ),
                ),
                child: SizedBox(width: 8, height: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody({
    required this.chips,
    required this.articles,
    required this.selectedChip,
    required this.showBanner,
    this.onChip,
    this.onArticle,
    this.onShare,
    this.scrollController,
    this.loadCover,
  });

  final List<BalitaChip> chips;
  final List<Announcement> articles;
  final String selectedChip;
  final bool showBanner;
  final ValueChanged<BalitaChip>? onChip;
  final ValueChanged<Announcement>? onArticle;
  final ValueChanged<Announcement>? onShare;
  final ScrollController? scrollController;
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    final Announcement? banner = _bannerOf(articles, showBanner);
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _Chips(chips: chips, selected: selectedChip, onChip: onChip),
        ),
        if (banner != null) ...<Widget>[
          _PinnedBanner(article: banner),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < articles.length; i++) ...<Widget>[
          _StoryCard(
            article: articles[i],
            loadCover: loadCover,
            onOpen: onArticle == null ? null : () => onArticle!(articles[i]),
            onShare: onShare == null ? null : () => onShare!(articles[i]),
          ),
          const SizedBox(height: 12),
        ],
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

class _Chips extends StatelessWidget {
  const _Chips({required this.chips, required this.selected, this.onChip});

  final List<BalitaChip> chips;
  final String selected;
  final ValueChanged<BalitaChip>? onChip;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: <Widget>[
        for (final BalitaChip chip in chips)
          _Hit(
            hitKey: Key('balita-chip-${chip.label}'),
            label: chip.label,
            height: 36,
            onTap: onChip == null ? null : () => onChip!(chip),
            child: _Chip(label: chip.label, on: chip.label == selected),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: on ? BrandColors.taytayBlue : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? BrandColors.taytayBlue : const Color(0xFFE1E6F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : const Color(0xFF33405C),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.article,
    this.onOpen,
    this.onShare,
    this.loadCover,
  });

  final Announcement article;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    final BalitaPresentation? presentation = article.presentation;
    final bool sample = presentation?.sample == true;
    final String? asset = presentation?.listCover == true
        ? presentation?.coverAsset
        : null;
    final bool remote = asset == null && _hasRemoteCover(article);
    return Opacity(
      opacity: sample ? 0.9 : 1,
      child: _Hit(
        hitKey: Key('balita-article-${article.id}'),
        label: article.title,
        onTap: onOpen,
        child: Container(
          decoration: _card,
          // Photo cards and the skeleton use 16 dp. A text card's first
          // line is on the specimen at a 15 dp top inset; 16 dp puts it
          // 3 px low. The bottom inset is 16 dp.
          padding: asset != null
              ? _cardPadding
              : const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (asset != null) ...<Widget>[
                _Cover(
                  asset: asset,
                  height: 150,
                  radius: 12,
                  label: presentation?.photoCredit ?? article.title,
                  darken: false,
                ),
                const SizedBox(height: 10),
              ] else if (remote)
                _RemoteCover(
                  id: article.id,
                  height: 150,
                  radius: 12,
                  label: presentation?.photoCredit ?? article.title,
                  reserve: _reservesCover(article),
                  gap: 10,
                  load: loadCover,
                ),
              Row(
                // Sample rows centre the tile on the copy. The other
                // cards pin it to the top, matching the specimens.
                crossAxisAlignment: sample
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  if (asset == null) ...<Widget>[
                    _Tile(
                      icon: _tileIcon(article),
                      background: _tileBackground(article),
                      color: _ink(article),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Eyebrow(article: article),
                        // Story cards set margin-top 3 on `.lt`. The sample
                        // card's title does not.
                        SizedBox(height: sample ? 0 : 3),
                        if (asset != null)
                          _CssLines(article.title, style: _storyTitle)
                        else
                          Text(article.title, style: _storyTitle),
                        const SizedBox(height: 4),
                        Text(article.preview, style: _storySummary),
                      ],
                    ),
                  ),
                ],
              ),
              if (!sample) ...<Widget>[
                // The action row's margin-top is 10. Save was the first
                // flex item. With it gone, Share is that first item and the
                // gap between the two actions collapses.
                const SizedBox(height: 10),
                _Hit(
                  hitKey: Key('balita-share-${article.id}'),
                  label: 'Share ${article.title}',
                  height: 16,
                  onTap: onShare,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TaytayIcon(
                        icon: TaytayIcons.share,
                        size: 16,
                        color: BrandColors.listMeta,
                        semanticLabel: '',
                        excludeSemantics: true,
                      ),
                      SizedBox(width: 6),
                      Text('Share', style: _action),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.article});

  final Announcement article;

  @override
  Widget build(BuildContext context) {
    final BalitaPresentation? presentation = article.presentation;
    final String date = _listDate(article);
    final String office = article.author ?? article.officeSlug ?? '';
    final String category = (article.category ?? '').toUpperCase();
    return Text.rich(
      TextSpan(
        style: _eyebrow.copyWith(color: _ink(article)),
        children: <InlineSpan>[
          if (category.isNotEmpty) TextSpan(text: category),
          if (office.isNotEmpty)
            TextSpan(text: category.isNotEmpty ? ' · $office' : office),
          if (presentation?.sample == true) ...<InlineSpan>[
            const TextSpan(text: ' · '),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              // `.sample` is 11 / 800 with no line-height, so the inline box
              // is the font's normal 1.26 plus the 2 px padding and 1 px
              // border. labelStrong is 1.2, which makes this line short and
              // pulls the title up.
              child: SampleTag(lineHeight: _cssNormal),
            ),
          ],
          if (date.isNotEmpty) TextSpan(text: ' · $date'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  const _PinnedBanner({required this.article});

  final Announcement article;

  @override
  Widget build(BuildContext context) {
    final bool emergency =
        article.advisoryLevel?.known == AdvisoryLevel.emergency;
    final String title = emergency
        ? 'Emergency advisory'
        : article.presentation?.pinnedTitle ?? 'Pinned advisory';
    final String body = article.presentation?.pinnedBody ?? article.title;
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2D77A)),
      ),
      // The specimen banner is the height of a 15 dp top inset. The other
      // three sides are the card's 16 dp.
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Row(
        children: <Widget>[
          const _Tile(
            icon: TaytayIcons.triangleAlert,
            background: Colors.white,
            color: BrandColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: _storyTitle),
                Text(
                  body,
                  style: _storySummary.copyWith(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.article, this.loadCover});

  final Announcement article;
  final MediaBytesLoader? loadCover;

  @override
  Widget build(BuildContext context) {
    final BalitaPresentation? presentation = article.presentation;
    final String? asset = presentation?.coverAsset;
    final bool remote = asset == null && _hasRemoteCover(article);
    final String lead = presentation?.lead ?? article.body;
    final String meta = <String>[
      if ((article.author ?? article.officeSlug ?? '').isNotEmpty)
        article.author ?? article.officeSlug!,
      if ((presentation?.dateLabel ?? _listDate(article)).isNotEmpty)
        presentation?.dateLabel?.isNotEmpty == true
            ? presentation!.dateLabel!
            : _listDate(article),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        if (asset != null)
          _Cover(
            asset: asset,
            height: presentation?.coverHeight ?? 180,
            radius: 16,
            label: presentation?.photoCredit ?? article.title,
            darken: true,
          )
        else if (remote)
          _RemoteCover(
            id: article.id,
            height: presentation?.coverHeight ?? 180,
            radius: 16,
            label: presentation?.photoCredit ?? article.title,
            reserve: _reservesCover(article),
            load: loadCover,
          ),
        if ((presentation?.photoCredit ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(presentation!.photoCredit!, style: _credit),
        ],
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: <Widget>[
            if ((article.category ?? '').isNotEmpty)
              _Tag(label: article.category!.toUpperCase(), article: article),
            if (meta.isNotEmpty) Text(meta, style: _credit),
          ],
        ),
        const SizedBox(height: 6),
        Text(article.title, style: _articleTitle),
        const SizedBox(height: 8),
        // `.cs` lead is 14 / 1.6. The engine rounds 22.4 dp to 22.
        _CssLines(lead, style: _lead),
        if ((presentation?.facts ?? const <BalitaFact>[])
            .isNotEmpty) ...<Widget>[
          // `.card` margin-top 12, padding 4 × 16. The border sits outside
          // the padding.
          const SizedBox(height: 12),
          Container(
            decoration: _card,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < presentation!.facts.length; i++)
                  _FactRow(
                    fact: presentation.facts[i],
                    last: i == presentation.facts.length - 1,
                  ),
              ],
            ),
          ),
        ],
        if ((presentation?.footer ?? '').isNotEmpty) ...<Widget>[
          // The card's margin-bottom is 12 and the footer's margin-top is
          // 4. Adjacent margins collapse to 12. `.cs` at 12px keeps
          // line-height 1.5.
          const SizedBox(height: 12),
          Text(presentation!.footer!, style: _storySummary),
        ],
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, required this.last});

  final BalitaFact fact;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Tile(
            icon: _namedIcon(fact.icon),
            background: BrandColors.chipBlueBg,
            color: BrandColors.taytayBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // `.ls` is 12 / 700, margin 0, with no line-height, so the
                // advance is the font's normal 1.26 (15.12 dp). The engine
                // rounds that line to 15 dp and trims the remainder off the
                // top. The label sits on the bottom of the CSS advance.
                SizedBox(
                  height: 12 * _cssNormal,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      fact.label,
                      style: _credit.copyWith(fontWeight: FontWeight.w700),
                      textHeightBehavior: _cssHalfLeading,
                      strutStyle: _strutFor(
                        _credit.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                _CssLines(fact.value, style: _factValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.article});

  final String label;
  final Announcement article;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tagBackground(article),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(label, style: _eyebrow.copyWith(color: _ink(article))),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({
    required this.chips,
    required this.chip,
    this.onChip,
    this.onSeeAll,
  });

  final List<BalitaChip> chips;
  final String chip;
  final ValueChanged<BalitaChip>? onChip;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final bool events = chip == 'Events';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _Chips(chips: chips, selected: chip, onChip: onChip),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
          child: Column(
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: BrandColors.chipBlueBg,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: TaytayIcon(
                      icon: TaytayIcons.calendarX,
                      size: 32,
                      color: BrandColors.taytayBlue,
                      semanticLabel: '',
                      excludeSemantics: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                events ? 'Walang events pa' : 'Walang ${chip.toLowerCase()} pa',
                textAlign: TextAlign.center,
                style: _storyTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                events
                    ? "No upcoming municipal events have been posted. We'll "
                          'notify you when the LGU announces one.'
                    : 'No ${chip.toLowerCase()} posts have been published yet.',
                textAlign: TextAlign.center,
                style: _storySummary.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              _Hit(
                hitKey: const Key('balita-see-all'),
                label: 'See all Balita',
                onTap: onSeeAll,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.taytayBlue,
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'See all Balita',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.taytayBlue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.chips});

  final List<BalitaChip> chips;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _Chips(chips: chips, selected: 'Lahat'),
        ),
        const _SkeletonCard(photo: true),
        const SizedBox(height: 12),
        const _SkeletonCard(),
        const SizedBox(height: 12),
        const _SkeletonCard(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.photo = false});

  final bool photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _card,
      padding: _cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (photo) ...<Widget>[
            const _Bone(height: 150, radius: 12),
            const SizedBox(height: 12),
          ],
          const _Bone(widthFactor: 0.35, height: 11),
          const SizedBox(height: 10),
          const _Bone(widthFactor: 0.9, height: 14),
          const SizedBox(height: 8),
          const _Bone(widthFactor: 0.75, height: 12),
          const SizedBox(height: 6),
          const _Bone(widthFactor: 0.55, height: 12),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.widthFactor, this.height = 12, this.radius = 8});

  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(
        height: height,
        width: widthFactor == null ? double.infinity : null,
      ),
    );
    if (widthFactor == null) return box;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: box,
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.chips,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final List<BalitaChip> chips;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _Chips(chips: chips, selected: 'Lahat'),
        ),
        Text(title, style: _storyTitle.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Text(message, style: _storySummary),
        if (action != null) ...<Widget>[
          const SizedBox(height: 12),
          _Hit(
            hitKey: const Key('balita-retry'),
            label: action!,
            onTap: onAction,
            child: SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BrandColors.taytayBlue,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: TaytayIcon(
            icon: icon,
            size: 20,
            color: color,
            semanticLabel: '',
            excludeSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({
    required this.child,
    required this.label,
    this.hitKey,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final String label;
  final Key? hitKey;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final double? slotW = width;
    final double? slotH = height;
    if (slotW == null && slotH == null) {
      return Semantics(
        button: onTap != null,
        label: label,
        child: GestureDetector(
          key: hitKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );
    }
    // A short control keeps its layout and grows the hit to 48 dp. The extra
    // area is transparent, so it does not move the ink the designs measure.
    if (slotW == null && slotH != null) {
      final double extra = slotH >= 48 ? 0 : (48 - slotH) / 2;
      return Semantics(
        button: onTap != null,
        label: label,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            Positioned(
              left: 0,
              right: 0,
              top: -extra,
              bottom: -extra,
              child: GestureDetector(
                key: hitKey,
                behavior: HitTestBehavior.translucent,
                onTap: onTap,
              ),
            ),
          ],
        ),
      );
    }
    if (slotH == null) {
      return Semantics(
        button: onTap != null,
        label: label,
        child: GestureDetector(
          key: hitKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );
    }
    final double w = slotW!;
    final double h = slotH;
    final double hitW = w < 48 ? 48 : w;
    final double hitH = h < 48 ? 48 : h;
    return SizedBox(
      width: w,
      height: h,
      child: OverflowBox(
        minWidth: hitW,
        maxWidth: hitW,
        minHeight: hitH,
        maxHeight: hitH,
        child: Semantics(
          button: onTap != null,
          label: label,
          child: GestureDetector(
            key: hitKey,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: hitW,
              height: hitH,
              child: Center(child: child),
            ),
          ),
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
    'abiso' => BrandColors.success,
    'negosyo' => BrandColors.inkGold,
    'safety' => BrandColors.danger,
    _ => BrandColors.taytayBlue,
  };
}

Color _tagBackground(Announcement article) {
  return switch ((article.category ?? '').toLowerCase()) {
    'abiso' => BrandColors.chipGreenBg,
    'negosyo' => BrandColors.chipGoldBg,
    'safety' => BrandColors.chipRedBg,
    _ => BrandColors.chipBlueBg,
  };
}

Color _tileBackground(Announcement article) {
  if ((article.category ?? '').toLowerCase() == 'negosyo') {
    return BrandColors.chipGoldBg;
  }
  if ((article.category ?? '').toLowerCase() == 'safety') {
    return BrandColors.chipRedBg;
  }
  return BrandColors.chipBlueBg;
}

IconData _tileIcon(Announcement article) {
  final String? named = article.presentation?.tileIcon;
  if (named != null && named.isNotEmpty) return _namedIcon(named);
  return switch ((article.category ?? '').toLowerCase()) {
    'negosyo' => TaytayIcons.briefcase,
    'safety' => TaytayIcons.siren,
    _ => TaytayIcons.landmark,
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

bool _hasRemoteCover(Announcement article) => _reservesCover(article);

bool _reservesCover(Announcement article) {
  final String? url = article.coverUrl;
  return url != null && url.isNotEmpty;
}

class _RemoteCover extends StatelessWidget {
  const _RemoteCover({
    required this.id,
    required this.height,
    required this.radius,
    required this.label,
    required this.reserve,
    this.gap = 0,
    this.load,
  });

  final String id;
  final double height;
  final double radius;
  final String label;
  final bool reserve;
  final double gap;
  final MediaBytesLoader? load;

  @override
  Widget build(BuildContext context) {
    final Widget hole = SizedBox(height: height, width: double.infinity);
    return MediaBytesHost(
      id: id,
      load: load,
      builder: (Uint8List? bytes) {
        if (!reserve && bytes == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: bytes == null
                  ? hole
                  : DecodedMemoryImage(
                      bytes: bytes,
                      height: height,
                      semanticLabel: label,
                      placeholder: hole,
                    ),
            ),
            if (gap > 0) SizedBox(height: gap),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.asset,
    required this.height,
    required this.radius,
    required this.label,
    required this.darken,
  });

  final String asset;
  final double height;
  final double radius;
  final String label;
  final bool darken;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      semanticLabel: label,
    );
    if (darken) {
      // The fixture photo sits one level above the design on a single row
      // of the 190 dp cover, which splits that photo into two runs.
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1,
          0,
          0,
          0,
          -2,
          0,
          1,
          0,
          0,
          -2,
          0,
          0,
          1,
          0,
          -2,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

/// `.card` padding is 16 dp on every side. The 1 dp border is painted on
/// that box; it is the inset, not a second padding.
const EdgeInsets _cardPadding = EdgeInsets.all(16);

const BoxDecoration _card = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: BrandColors.cardLine)),
  boxShadow: <BoxShadow>[
    BoxShadow(color: Color(0x0D101828), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 10, offset: Offset(0, 2)),
  ],
);

/// A paragraph whose line boxes are [TextStyle.fontSize] × [TextStyle.height].
///
/// The design sets `line-height: 1.6` on the article lead, which is 22.4 dp.
/// SkParagraph rounds the line box to a whole logical pixel (`round(descent
/// − ascent)`), so the lead is 22 dp and each further line is about 1 image
/// px short at 3×. The strut keeps the CSS half-leading. Lines then sit on
/// the unrounded advance, and the paragraph is `n` times that advance tall.
class _CssLines extends StatelessWidget {
  const _CssLines(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final double? fontSize = style.fontSize;
    final double? height = style.height;
    final StrutStyle strut = _strutFor(style);
    if (fontSize == null || height == null) {
      return Text(text, style: style, strutStyle: strut);
    }
    final double step = fontSize * height;
    if ((step - step.roundToDouble()).abs() < 0.001) {
      return Text(text, style: style, strutStyle: strut);
    }
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final TextPainter painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior: _cssHalfLeading,
              strutStyle: strut,
            )..layout(maxWidth: constraints.maxWidth);
            final List<String> lines = <String>[];
            var start = 0;
            while (start < text.length) {
              final TextRange range = painter.getLineBoundary(
                TextPosition(offset: start),
              );
              if (range.end <= start) {
                break;
              }
              lines.add(text.substring(range.start, range.end).trimRight());
              start = range.end;
            }
            painter.dispose();
            if (lines.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              width: constraints.maxWidth,
              height: step * lines.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: step * i,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        maxLines: 1,
                        softWrap: false,
                        textHeightBehavior: _cssHalfLeading,
                        strutStyle: strut,
                        style: style,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

StrutStyle _strutFor(TextStyle style) {
  return StrutStyle(
    fontFamily: style.fontFamily,
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    height: style.height,
    leadingDistribution: TextLeadingDistribution.even,
    forceStrutHeight: true,
  );
}

/// Plus Jakarta Sans `line-height: normal` (hhea 1038 / -222).
const double _cssNormal = 1.26;

/// CSS half-leading. The line box keeps the extra space above the first
/// ascent and below the last descent, split evenly.
const TextHeightBehavior _cssHalfLeading = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

const TextStyle _eyebrow = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  decoration: TextDecoration.none,
  height: _cssNormal,
);

const TextStyle _storyTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
  height: _cssNormal,
);

const TextStyle _storySummary = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
  height: 1.5,
);

const TextStyle _action = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _credit = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
  height: _cssNormal,
);

const TextStyle _articleTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 22,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.4,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
  height: _cssNormal,
);

const TextStyle _lead = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF33405C),
  decoration: TextDecoration.none,
  height: 1.6,
);

const TextStyle _factValue = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
  height: _cssNormal,
);
