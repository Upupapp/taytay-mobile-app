import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/feed_row.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_glyph.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/home_content.dart';

/// Which verification card Home shows. Verified shows none.
enum HomeStatusKind { none, pending, guest }

/// Home (design `Home.dc.html`): the glass main tab under the blue header.
///
/// The shell paints the tab bar. Every name, headline and number on this
/// canvas comes from its parameters; the canvas invents none.
class HomeCanvas extends StatefulWidget {
  const HomeCanvas({
    required this.greeting,
    required this.slides,
    this.initials = '',
    this.bellCount = 0,
    this.status = HomeStatusKind.none,
    this.news = const <HomeNewsItem>[],
    this.hotline,
    this.initialSlide = 0,
    this.refreshing = false,
    this.autoplayInTests = false,
    this.onBell,
    this.onAvatar,
    this.onSignIn,
    this.onCreateAccount,
    this.onSlide,
    this.onNews,
    this.onSeeAllNews,
    this.onCall,
    this.onAllHotlines,
    this.onQuickAction,
    this.onRefresh,
    this.loadBanner,
    super.key,
  });

  final String greeting;
  final String initials;
  final int bellCount;
  final HomeStatusKind status;
  final List<HomeSlide> slides;
  final List<HomeNewsItem> news;
  final HomeHotline? hotline;
  final int initialSlide;
  final bool refreshing;

  /// Widget tests settle with `pumpAndSettle`. A repeating timer never
  /// settles, so autoplay stays off under the test binding unless a test
  /// asks for it and pumps frames itself.
  final bool autoplayInTests;

  final VoidCallback? onBell;
  final VoidCallback? onAvatar;
  final VoidCallback? onSignIn;
  final VoidCallback? onCreateAccount;
  final ValueChanged<HomeSlide>? onSlide;
  final ValueChanged<HomeNewsItem>? onNews;

  /// `GET /home/banners/{id}/image` for a slide whose banner has `image_url`.
  /// Null keeps the bundled photograph, including every dev mock.
  final MediaBytesLoader? loadBanner;
  final VoidCallback? onSeeAllNews;
  final VoidCallback? onCall;
  final VoidCallback? onAllHotlines;
  final ValueChanged<String>? onQuickAction;
  final Future<void> Function()? onRefresh;

  @override
  State<HomeCanvas> createState() => _HomeCanvasState();
}

class _HomeCanvasState extends State<HomeCanvas> {
  late final PageController _pages;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialSlide;
    _pages = PageController(initialPage: widget.initialSlide);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _armTimer();
  }

  @override
  void didUpdateWidget(HomeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlide != widget.initialSlide) {
      _index = _bounded(widget.initialSlide);
      if (_pages.hasClients) {
        // The index is already the destination, so the page callback does
        // not schedule another frame from inside this update.
        _pages.jumpToPage(_index);
      }
    }
    if (oldWidget.autoplayInTests != widget.autoplayInTests ||
        oldWidget.refreshing != widget.refreshing) {
      _armTimer();
    }
  }

  int _bounded(int requested) {
    if (widget.slides.isEmpty) return 0;
    return requested.clamp(0, widget.slides.length - 1);
  }

  bool get _testing => SchedulerBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.refreshing || widget.slides.length < 2) return;
    if (Motion.reduced(context)) return;
    if (_testing && !widget.autoplayInTests) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
  }

  void _advance() {
    if (!mounted || widget.slides.isEmpty) return;
    final int next = (_index + 1) % widget.slides.length;
    _pages.animateToPage(
      next,
      duration: MotionTokens.standard,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeHotline? hotline = widget.hotline;
    final List<Widget> body = <Widget>[
      if (!widget.refreshing && widget.status != HomeStatusKind.none)
        _StatusCard(
          kind: widget.status,
          onCreateAccount: widget.onCreateAccount,
        ),
      if (widget.refreshing || widget.slides.isEmpty)
        const LoadingSkeleton(
          layout: SkeletonLayout.cards,
          count: 1,
          semanticLabel: 'Loading featured stories',
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Hero(
              slides: widget.slides,
              controller: _pages,
              index: _index,
              loadBanner: widget.loadBanner,
              onChanged: (int index) {
                if (index == _index) return;
                setState(() => _index = index);
              },
              onOpen: widget.onSlide,
            ),
            const SizedBox(height: 10),
            _Dots(count: widget.slides.length, index: _index),
          ],
        ),
      _Section(
        title: 'Ano ang kailangan mo?',
        child: _Launcher(onTap: widget.onQuickAction),
      ),
      if (widget.refreshing || widget.news.isNotEmpty)
        _Section(
          title: 'Latest Balita',
          action: widget.refreshing ? null : 'See all',
          onAction: widget.onSeeAllNews,
          child: widget.refreshing
              ? const LoadingSkeleton(
                  layout: SkeletonLayout.feed,
                  count: 2,
                  semanticLabel: 'Loading Balita',
                )
              : _NewsCard(items: widget.news, onTap: widget.onNews),
        ),
      if (!widget.refreshing && hotline != null)
        _Section(
          title: 'Emergency',
          action: 'All hotlines',
          onAction: widget.onAllHotlines,
          child: _EmergencyCard(hotline: hotline, onCall: widget.onCall),
        ),
    ];
    // Material gives the page the theme's text style wherever it is hosted,
    // so no text falls back to the debug style outside a Scaffold.
    return Material(
      type: MaterialType.transparency,
      child: GlassBackground(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            children: <Widget>[
              _Header(
                greeting: widget.greeting,
                initials: widget.initials,
                bellCount: widget.bellCount,
                refreshing: widget.refreshing,
                onBell: widget.onBell,
                onAvatar: widget.onAvatar,
                onSignIn: widget.onSignIn,
              ),
              GlassOverlap(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (var i = 0; i < body.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: Spacing.section),
                        body[i],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `header.bar.tall`: seal, brand, bell, avatar; then the greeting.
class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.initials,
    required this.bellCount,
    required this.refreshing,
    this.onBell,
    this.onAvatar,
    this.onSignIn,
  });

  final String greeting;
  final String initials;
  final int bellCount;
  final bool refreshing;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return BlueHeader(
      overlap: true,
      leading: const HeaderSeal(),
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'BAYAN NG TAYTAY',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontWeight: AppTypography.black,
              letterSpacing: 1.75,
              color: BrandColors.white,
            ),
          ),
          Text(
            'Lalawigan ng Rizal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.strong,
              color: BrandColors.gold,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        HeaderIconButton(
          icon: TaytayIcons.bell,
          semanticLabel: bellCount > 0
              ? 'Notifications, $bellCount unread'
              : 'Notifications',
          badgeCount: bellCount > 0 ? bellCount : null,
          onPressed: onBell,
          visualKey: const Key('home-bell'),
        ),
        if (initials.isEmpty)
          _SignInPill(onTap: onSignIn)
        else
          _Avatar(initials: initials, onTap: onAvatar),
      ],
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              greeting,
              style: AppTypography.headerTitleLarge.copyWith(
                color: BrandColors.white,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          if (refreshing)
            const _UpdatingLine()
          else
            Text(
              'Ano ang maitutulong namin ngayon?',
              style: AppTypography.bodyStyle.copyWith(
                color: BrandColors.onHeaderLede,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      label: 'My Account',
      onTap: onTap,
      child: Container(
        key: const Key('home-avatar'),
        width: ComponentSizes.avatar,
        height: ComponentSizes.avatar,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: BrandColors.gold,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          maxLines: 1,
          style: AppTypography.listTitle.copyWith(
            fontWeight: AppTypography.black,
            color: BrandColors.navy,
          ),
        ),
      ),
    );
  }
}

class _SignInPill extends StatelessWidget {
  const _SignInPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // At large text the worded pill would push the brand off a 360 dp
    // header, so the same action becomes the round header button.
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return HeaderIconButton(
        icon: TaytayIcons.logIn,
        semanticLabel: 'Sign in',
        onPressed: onTap,
      );
    }
    return _Tap(
      label: 'Sign in',
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: ComponentSizes.headerIconButton,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          'Sign in',
          maxLines: 1,
          style: AppTypography.button.copyWith(color: BrandColors.white),
        ),
      ),
    );
  }
}

class _UpdatingLine extends StatelessWidget {
  const _UpdatingLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const TaytayIcon(
          icon: TaytayIcons.refreshCw,
          semanticLabel: '',
          excludeSemantics: true,
          size: IconSizes.sm,
          color: BrandColors.onHeaderLede,
        ),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            'Updating Balita and advisories…',
            style: AppTypography.bodyStyle.copyWith(
              color: BrandColors.onHeaderLede,
            ),
          ),
        ),
      ],
    );
  }
}

/// Guest and pending verification. A glass card in the header overlap.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.kind, this.onCreateAccount});

  final HomeStatusKind kind;
  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final bool guest = kind == HomeStatusKind.guest;
    return GlassCard(
      pinned: !guest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTile.glyph(
                glyph: guest ? TaytayGlyph.users : TaytayGlyph.clock,
                tone: guest ? TileTone.sky : TileTone.gold,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      guest ? 'Browsing as guest' : 'Verification pending',
                      style: AppTypography.listTitle.copyWith(
                        fontWeight: AppTypography.strong,
                        color: BrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      guest
                          ? 'Sign up to message offices.'
                          : 'Taytay LGU is reviewing your ID. Messaging '
                                'offices unlocks once verified.',
                      style: AppTypography.listDetail.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (guest) ...<Widget>[
            const SizedBox(height: Spacing.md),
            FilledButton(
              onPressed: onCreateAccount,
              child: const Text('Create account', maxLines: 1, softWrap: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlidePhoto extends StatelessWidget {
  const _SlidePhoto({required this.slide, this.load});

  final HomeSlide slide;
  final MediaBytesLoader? load;

  @override
  Widget build(BuildContext context) {
    // CSS `object-position: center <focus>` maps to Alignment y = focus*2-1.
    final Alignment alignment = Alignment(0, slide.focus * 2 - 1);
    final Widget bundled = Image.asset(
      slide.photoAsset,
      fit: BoxFit.cover,
      alignment: alignment,
      excludeFromSemantics: true,
    );
    final String? id = slide.bannerId;
    final MediaBytesLoader? load = this.load;
    if (id == null || id.isEmpty || load == null) return bundled;
    return MediaBytesHost(
      id: id,
      load: load,
      builder: (Uint8List? bytes) {
        if (bytes == null) return bundled;
        return DecodedMemoryImage(
          bytes: bytes,
          fit: BoxFit.cover,
          alignment: alignment,
          placeholder: bundled,
        );
      },
    );
  }
}

/// `.hero`: glass card, text on the left, the photo in a gold half-ring.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.slides,
    required this.controller,
    required this.index,
    required this.onChanged,
    this.onOpen,
    this.loadBanner,
  });

  final List<HomeSlide> slides;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<HomeSlide>? onOpen;
  final MediaBytesLoader? loadBanner;

  static const double _height = 212;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    // Large text takes the photo's room: the copy needs the whole card.
    final bool wide = scale > 1.3;
    return SizedBox(
      key: const Key('home-carousel'),
      height: _height * math.max(1, scale),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: PageView.builder(
          controller: controller,
          itemCount: slides.length,
          onPageChanged: onChanged,
          itemBuilder: (BuildContext context, int page) => _Slide(
            slide: slides[page],
            photo: !wide,
            loadBanner: loadBanner,
            onOpen: onOpen,
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.slide,
    required this.photo,
    this.loadBanner,
    this.onOpen,
  });

  final HomeSlide slide;
  final bool photo;
  final MediaBytesLoader? loadBanner;
  final ValueChanged<HomeSlide>? onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double photoWidth = photo ? constraints.maxWidth * 0.46 : 0;
        final double h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            if (photo) ...<Widget>[
              Positioned(
                right: -6,
                top: -12,
                bottom: -12,
                width: photoWidth + 12,
                child: const ExcludeSemantics(
                  child: CustomPaint(painter: _DashedRingPainter()),
                ),
              ),
              Positioned(
                right: -6,
                top: 0,
                bottom: 0,
                width: photoWidth,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
                  decoration: BoxDecoration(
                    color: BrandColors.gold,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(h / 2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(h / 2 - 5),
                    ),
                    child: _SlidePhoto(slide: slide, load: loadBanner),
                  ),
                ),
              ),
              if (slide.credit.isNotEmpty)
                Positioned(
                  right: Spacing.md,
                  bottom: Spacing.sm,
                  child: _Credit(slide.credit, maxWidth: photoWidth - 24),
                ),
            ],
            Positioned(
              left: Spacing.lg,
              top: Spacing.lg,
              bottom: Spacing.lg,
              right: photo ? photoWidth + Spacing.xs : Spacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    // The copy is clipped to the card rather than pushing the
                    // button off it; the slide's own screen has the rest.
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (slide.eyebrow.isNotEmpty)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: BrandColors.gold,
                                borderRadius: BorderRadius.circular(Radii.tag),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.sm,
                                  vertical: Spacing.xs,
                                ),
                                child: Text(
                                  slide.eyebrow.toUpperCase(),
                                  style: AppTypography.category.copyWith(
                                    color: BrandColors.navy,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            slide.title,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.storyTitle.copyWith(
                              fontWeight: AppTypography.black,
                              color: BrandColors.ink,
                            ),
                          ),
                          // A slide from a `GET /home` banner has no sentence.
                          if (slide.body.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              slide.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.small.copyWith(
                                height: 1.4,
                                color: BrandColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  _Tap(
                    label: slide.action,
                    onTap: () => onOpen?.call(slide),
                    child: Container(
                      key: const Key('home-hero-cta'),
                      constraints: const BoxConstraints(minHeight: 42),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.blue,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              slide.action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                fontWeight: AppTypography.strong,
                                color: BrandColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          const TaytayIcon(
                            icon: TaytayIcons.arrowRight,
                            semanticLabel: '',
                            excludeSemantics: true,
                            size: 15,
                            color: BrandColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit(this.text, {required this.maxWidth});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.max(0, maxWidth)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.navy.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xxs,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.tiny.copyWith(color: BrandColors.white),
          ),
        ),
      ),
    );
  }
}

/// `.hero .ring`: a dashed gold half-stadium around the photo.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.height / 2;
    final Path ring = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0.8, 0.8, size.width + r, size.height - 1.6),
          topLeft: Radius.circular(r),
          bottomLeft: Radius.circular(r),
        ),
      );
    final Paint paint = Paint()
      ..color = BrandColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final ui.PathMetric metric in ring.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final double next = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: i == index ? Spacing.xl : Spacing.sm,
              height: Spacing.sm,
              decoration: BoxDecoration(
                color: i == index ? BrandColors.blue : BrandColors.line2,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.sec2`: a 15/700 heading, an optional link, then the section.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? action = this.action;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xxs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                ),
              ),
              // Flexible: at 200% text on a small phone the link wraps
              // instead of pushing the row past the edge.
              if (action != null)
                Flexible(
                  child: _Tap(
                    label: action,
                    onTap: onAction,
                    child: Text(
                      action,
                      textAlign: TextAlign.end,
                      style: AppTypography.link.copyWith(
                        fontWeight: AppTypography.strong,
                        color: BrandColors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        child,
      ],
    );
  }
}

/// `.launch`: four gradient squares. Two columns at large text.
class _Launcher extends StatelessWidget {
  const _Launcher({this.onTap});

  final ValueChanged<String>? onTap;

  static const List<(String, String, TaytayGlyph, TileTone)> _tiles =
      <(String, String, TaytayGlyph, TileTone)>[
        ('Directory', 'services', TaytayGlyph.directory, TileTone.blue),
        ('Tulong', 'programs', TaytayGlyph.heart, TileTone.green),
        ('Balita', 'news', TaytayGlyph.megaphone, TileTone.gold),
        ('Hotlines', 'hotlines', TaytayGlyph.phone, TileTone.red),
      ];

  @override
  Widget build(BuildContext context) {
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Widget tile((String, String, TaytayGlyph, TileTone) t) {
      final BrandGradient gradient = BrandGradients.tile(t.$4);
      return _Tap(
        label: t.$1,
        onTap: () => onTap?.call(t.$2),
        child: Column(
          key: Key('home-quick-${t.$2}'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: ComponentSizes.launchTile,
              height: ComponentSizes.launchTile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradient.toLinearGradient(),
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: GlyphIcon(t.$3, size: 26, color: gradient.onColor),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.$1,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.label.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.ink,
              ),
            ),
          ],
        ),
      );
    }

    final int columns = largeText ? 2 : 4;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            (constraints.maxWidth - Spacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.md,
          children: <Widget>[
            for (final (String, String, TaytayGlyph, TileTone) t in _tiles)
              SizedBox(width: width, child: tile(t)),
          ],
        );
      },
    );
  }
}

/// Latest Balita: the newest items as feed rows in one glass card.
///
/// The design draws the first item large (`.feat`). The feed sends no
/// `featured` flag and Home receives no thumbnail, so every item is a row:
/// promoting the newest post would claim an editorial choice nobody made.
class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.items, this.onTap});

  final List<HomeNewsItem> items;
  final ValueChanged<HomeNewsItem>? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < items.length; i++)
            FeedRow(
              title: items[i].title,
              category: items[i].eyebrow.isEmpty
                  ? null
                  : items[i].eyebrow.toUpperCase(),
              categoryTone: items[i].alert
                  ? CategoryTone.red
                  : CategoryTone.blue,
              divider: i > 0,
              onTap: onTap == null ? null : () => onTap?.call(items[i]),
            ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.hotline, this.onCall});

  final HomeHotline hotline;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: <Widget>[
          const IconTile.glyph(glyph: TaytayGlyph.siren, tone: TileTone.red),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${hotline.name} · 24/7',
                  style: AppTypography.listDetail.copyWith(
                    fontWeight: AppTypography.medium,
                    color: BrandColors.redInk,
                  ),
                ),
                Text(
                  hotline.number,
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: AppTypography.black,
                    color: BrandColors.ink,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _Tap(
            label: 'Call ${hotline.name}',
            onTap: onCall,
            child: Container(
              key: const Key('home-call'),
              width: ComponentSizes.headerIconButton,
              height: ComponentSizes.headerIconButton,
              decoration: const BoxDecoration(
                color: BrandColors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: TaytayIcon(
                  icon: TaytayIcons.phone,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: BrandColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 48 dp target around a smaller mark. Keys go on the mark.
class _Tap extends StatelessWidget {
  const _Tap({required this.child, required this.label, this.onTap});

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: A11y.minTapTarget,
            minHeight: A11y.minTapTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
