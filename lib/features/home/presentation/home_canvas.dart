import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/design/brand_assets.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/home_content.dart';

/// Which verification card Home shows. Verified shows none.
enum HomeStatusKind { none, pending, guest }

/// The Home canvas from `04-01` through `04-07`, without the tab bar.
///
/// The shell paints the bar. A capture composes this canvas and the bar into
/// the 844 dp frame. Spacing follows the design CSS. Text stays in the
/// layout; nothing on this canvas is shifted after it is placed.
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
    final double top = MediaQuery.paddingOf(context).top;
    // The design padding is 50. The wordmark ink sits 2 dp lower than that
    // padding: 6 device px at the 3× capture. The gap under the wordmark
    // gives those 2 dp back, so the lines below stay where they are.
    final double padTop = top == 0 ? 52 : top;
    return ColoredBox(
      color: BrandColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFE3EBFA), BrandColors.surface],
            stops: <double>[0, 0.4],
          ),
        ),
        child: Stack(
          children: <Widget>[
            if (!widget.refreshing) const Positioned.fill(child: _GoldGlow()),
            RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, padTop, 16, 24),
                children: <Widget>[
                  _Wordmark(
                    initials: widget.initials,
                    bellCount: widget.bellCount,
                    onBell: widget.onBell,
                    onAvatar: widget.onAvatar,
                    onSignIn: widget.onSignIn,
                  ),
                  if (widget.refreshing) ...<Widget>[
                    // Spinner row is 36 dp. 12 above and 10 below place its
                    // ink on the same rows as the design. The 2 dp taken
                    // from this gap offset the wordmark's extra top inset.
                    const SizedBox(height: 12),
                    const _UpdatingLine(),
                    const SizedBox(height: 10),
                  ],
                  if (!widget.refreshing) const SizedBox(height: 16),
                  Text(widget.greeting, style: _greeting),
                  if (!widget.refreshing) ...<Widget>[
                    const SizedBox(height: 4),
                    const Text(
                      'Ano ang maitutulong namin ngayon?',
                      style: _subtitle,
                    ),
                    if (widget.status != HomeStatusKind.none) ...<Widget>[
                      const SizedBox(height: 14),
                      _StatusCard(
                        kind: widget.status,
                        onCreateAccount: widget.onCreateAccount,
                      ),
                    ],
                    // The unverified card's text box ends 2 device px above
                    // the design hero. Two thirds of a logical pixel is that
                    // gap; the other homes keep the design's 14.
                    SizedBox(
                      height: widget.status == HomeStatusKind.pending
                          ? 14 + 2 / 3
                          : 14,
                    ),
                    _Hero(
                      slides: widget.slides,
                      controller: _pages,
                      index: _index,
                      onChanged: (int index) {
                        if (index == _index) return;
                        setState(() => _index = index);
                      },
                      onOpen: widget.onSlide,
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 14),
                    const _Skeleton(height: 200, radius: 24),
                  ],
                  const SizedBox(height: 4),
                  _Dots(count: 3, index: widget.refreshing ? 0 : _index),
                  const SizedBox(height: 18),
                  const _SectionTitle('Ano ang kailangan mo?'),
                  const SizedBox(height: 12),
                  _QuickActions(onTap: widget.onQuickAction),
                  if (widget.refreshing || widget.news.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    _SectionLink(
                      title: 'Latest Balita',
                      action: widget.refreshing ? null : 'See all',
                      onAction: widget.onSeeAllNews,
                    ),
                    // `.sec-h` margin-bottom is 8.
                    const SizedBox(height: 8),
                    if (widget.refreshing)
                      const _NewsSkeleton()
                    else
                      _NewsCard(items: widget.news, onTap: widget.onNews),
                  ],
                  if (!widget.refreshing && widget.hotline != null) ...<Widget>[
                    // Default `.sec-h` margin-top is 16, then margin-bottom 8,
                    // and the emergency card adds margin-top 12.
                    const SizedBox(height: 16),
                    _SectionLink(
                      title: 'Emergency',
                      action: 'All hotlines',
                      onAction: widget.onAllHotlines,
                    ),
                    const SizedBox(height: 20),
                    _EmergencyCard(
                      hotline: widget.hotline!,
                      onCall: widget.onCall,
                    ),
                  ],
                ],
              ),
            ),
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
        ),
      ),
    );
  }
}

/// `radial-gradient(120% 60% at 100% 0, rgba(252,209,22,.16), transparent 60%)`
/// on the page background. The refresh screen's background is the linear
/// wash only, so this painter is not mounted while [HomeCanvas.refreshing].
class _GoldGlow extends StatelessWidget {
  const _GoldGlow();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(child: CustomPaint(painter: _GoldGlowPainter()));
  }
}

class _GoldGlowPainter extends CustomPainter {
  const _GoldGlowPainter();

  static const Color _gold = Color.fromRGBO(252, 209, 22, 0.16);

  @override
  void paint(Canvas canvas, Size size) {
    final double radiusX = size.width * 1.2;
    final double radiusY = size.height * 0.6;
    if (radiusX <= 0 || radiusY <= 0) return;
    final Offset center = Offset(size.width, 0);
    // The shader matrix maps a device point into the circular gradient.
    // Scaling Y by radiusX/radiusY turns that circle into the 120% by 60%
    // ellipse. Transparent arrives at 60% of the ellipse.
    final Matrix4 matrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1, radiusX / radiusY, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    final Paint paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radiusX,
        const <Color>[_gold, Color.fromRGBO(252, 209, 22, 0)],
        const <double>[0, 0.6],
        TileMode.clamp,
        matrix.storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.initials,
    required this.bellCount,
    this.onBell,
    this.onAvatar,
    this.onSignIn,
  });

  final String initials;
  final int bellCount;
  final VoidCallback? onBell;
  final VoidCallback? onAvatar;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Seal, its gap, the bell, and the gap before the trailing control.
        // The pill may use whatever is left; the wordmark takes the rest.
        final double pillCap = constraints.maxWidth.isFinite
            ? constraints.maxWidth - 48 - 10 - 44 - 8
            : double.infinity;
        return Row(
          children: <Widget>[
            const _HomeSeal(),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'BAYAN NG TAYTAY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _wordmark,
                  ),
                  Text(
                    'Lalawigan ng Rizal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _province,
                  ),
                ],
              ),
            ),
            _Bell(count: bellCount, onTap: onBell),
            const SizedBox(width: 8),
            if (initials.isEmpty)
              _SignInPill(onTap: onSignIn, maxWidth: pillCap)
            else
              _Avatar(initials: initials, onTap: onAvatar),
          ],
        );
      },
    );
  }
}

class _HomeSeal extends StatelessWidget {
  const _HomeSeal();

  @override
  Widget build(BuildContext context) {
    const BrandAsset seal = BrandAssets.municipalSeal;
    return Semantics(
      label: seal.semanticLabel,
      image: true,
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x24062358),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
            BoxShadow(color: Color(0x99C9A227), spreadRadius: 1.5),
          ],
        ),
        child: Image.asset(seal.assetPath, fit: BoxFit.contain),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: count > 0 ? 'Notifications, $count unread' : 'Notifications',
      width: 44,
      height: 44,
      onTap: onTap,
      badge: count > 0 ? '$count' : null,
      child: Container(
        key: const Key('home-bell'),
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: Color(0xFFE1E6F0), spreadRadius: 1),
            BoxShadow(
              color: Color(0x14062358),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: TaytayIcon(
            icon: TaytayIcons.bell,
            semanticLabel: '',
            excludeSemantics: true,
            size: 20,
            color: BrandColors.taytayBlue,
          ),
        ),
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
    return _Hit(
      label: 'My Account',
      width: 44,
      height: 44,
      onTap: onTap,
      child: Container(
        key: const Key('home-avatar'),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: BrandColors.taytayBlue,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: BrandColors.sealGold, spreadRadius: 3.5),
            BoxShadow(color: Colors.white, spreadRadius: 2),
          ],
        ),
        child: Text(initials, style: _initials),
      ),
    );
  }
}

class _SignInPill extends StatelessWidget {
  const _SignInPill({required this.maxWidth, this.onTap});

  final double maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Design: width auto, height 44, padding 0 16. The slot is the label
    // plus that padding, and never wider than the row has left, so a large
    // text scale cannot push the wordmark out of the row.
    final double wanted = _textWidth(context, 'Sign in', _pill) + 32;
    final double slot = !wanted.isFinite || wanted < maxWidth
        ? wanted
        : maxWidth;
    return _Hit(
      label: 'Sign in',
      width: slot,
      height: 44,
      onTap: onTap,
      child: Container(
        width: slot,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.taytayBlue,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Sign in',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _pill,
        ),
      ),
    );
  }
}

class _UpdatingLine extends StatelessWidget {
  const _UpdatingLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x26062358),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: TaytayIcon(
                  icon: TaytayIcons.refreshCw,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 18,
                  color: BrandColors.taytayBlue,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Loose fit keeps the spinner and the label centred when the
          // type fits, and ellipsizes only when a fallback face is wider
          // than the row.
          Flexible(
            child: Text(
              'Updating Balita and advisories…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textWidthBasis: TextWidthBasis.longestLine,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BrandColors.listMeta,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.kind, this.onCreateAccount});

  final HomeStatusKind kind;
  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final bool guest = kind == HomeStatusKind.guest;
    return Container(
      // Guest padding is the design's 12, minus a third of a pixel so the
      // hero below stays on the design row. The pending card is unchanged.
      padding: EdgeInsets.fromLTRB(
        12,
        guest ? 12 : 10,
        12,
        guest ? 12 - 1 / 3 : 10,
      ),
      decoration: BoxDecoration(
        color: guest ? Colors.white : const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: guest ? BrandColors.cardLine : const Color(0xFFF2D77A),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scale = MediaQuery.textScalerOf(context).scale(1);
          final bool beside = !guest || constraints.maxWidth >= 280 * scale;
          final Widget copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                guest ? 'Browsing as guest' : 'Verification pending',
                maxLines: guest ? 1 : null,
                overflow: guest ? TextOverflow.ellipsis : null,
                style: _cardTitle,
              ),
              // Guest sub-line is `.cs` with margin-top 2. The pending
              // card keeps the 1 dp gap its hero was lined up against.
              SizedBox(height: guest ? 2 : 1),
              Text(
                guest
                    ? 'Sign up to message offices.'
                    : 'Taytay LGU is reviewing your ID. Messaging offices '
                          'unlocks once verified.',
                style: _cardBody,
              ),
            ],
          );
          final bool largeText = scale > 1.05;
          // Design: width auto, height 44, padding 0 14. A fixed 154 slot
          // wraps "Browsing as guest". When the row is the one place the
          // button can sit, the slot stops at the room beside the icon.
          final double wanted =
              _textWidth(context, 'Create account', _account) + 28;
          final double cap = constraints.maxWidth - 44 - (guest ? 12 + 12 : 10);
          final bool room = cap >= 48;
          final bool shrink = beside && !largeText && room && wanted <= cap;
          final double? buttonWidth = shrink
              ? wanted
              : (beside && !largeText && room ? cap : null);
          final Widget button = _Hit(
            label: 'Create account',
            onTap: onCreateAccount,
            width: buttonWidth,
            height: largeText ? null : 44,
            child: Container(
              height: largeText ? null : 44,
              constraints: largeText
                  ? const BoxConstraints(minWidth: 48, minHeight: 48)
                  : null,
              // Design padding is 14. A border on the background decoration
              // is added to that padding and the label ellipsizes. The
              // stroke is painted in front, the same way the design's
              // inset shadow sits on the padding.
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandColors.taytayBlue, width: 1.5),
              ),
              child: const Text(
                'Create account',
                maxLines: 1,
                softWrap: false,
                style: _account,
              ),
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _IconTile(
                background: guest
                    ? BrandColors.surfaceMuted
                    : const Color(0xFFFFFFFF),
                icon: guest ? TaytayIcons.user : TaytayIcons.clock,
                color: guest ? BrandColors.taytayBlue : const Color(0xFF8A5A00),
              ),
              SizedBox(width: guest ? 12 : 10),
              Expanded(
                child: beside
                    ? copy
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          copy,
                          const SizedBox(height: 8),
                          button,
                        ],
                      ),
              ),
              if (beside && guest) ...<Widget>[
                const SizedBox(width: 12),
                button,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.slides,
    required this.controller,
    required this.index,
    required this.onChanged,
    this.onOpen,
  });

  final List<HomeSlide> slides;
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<HomeSlide>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) {
      return const _Skeleton(height: 200, radius: 24);
    }
    final HomeSlide slide = slides[index.clamp(0, slides.length - 1)];
    return SizedBox(
      key: const Key('home-carousel'),
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: controller,
              itemCount: slides.length,
              onPageChanged: onChanged,
              itemBuilder: (BuildContext context, int page) {
                final HomeSlide item = slides[page];
                // CSS `background-position: center <focus>` maps to
                // Alignment y = focus * 2 - 1.
                return ColoredBox(
                  color: BrandColors.taytayBlueDark,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: 0.58,
                      heightFactor: 1,
                      child: Image.asset(
                        item.photoAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment(0, item.focus * 2 - 1),
                      ),
                    ),
                  ),
                );
              },
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      BrandColors.taytayBlueDark,
                      BrandColors.taytayBlue,
                      Color(0xDB0B3D91),
                      Color(0x1A062358),
                      Color(0x00062358),
                    ],
                    stops: <double>[0, 0.4, 0.58, 0.8, 1],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: CustomPaint(painter: _ArcPainter())),
            Positioned(
              left: 18,
              top: 16,
              width: 196,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // The pill is inline and may be wider than the 196 dp
                  // title column. CSS lets it paint past that box.
                  OverflowBox(
                    alignment: Alignment.centerLeft,
                    fit: OverflowBoxFit.deferToChild,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: _Eyebrow(slide.eyebrow, slide.routeName),
                  ),
                  const SizedBox(height: 8),
                  Text(slide.title, style: _heroTitle),
                  const SizedBox(height: 4),
                  Text(slide.body, style: _heroBody),
                ],
              ),
            ),
            Positioned(
              left: 18,
              bottom: 16,
              child: _Hit(
                label: slide.action,
                onTap: () => onOpen?.call(slide),
                child: Container(
                  key: const Key('home-hero-cta'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(slide.action, style: _cta),
                      const SizedBox(width: 6),
                      const TaytayIcon(
                        icon: TaytayIcons.arrowRight,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: 16,
                        color: BrandColors.taytayBlueDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xB8061432),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(slide.credit, style: _credit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path solid = Path()
      ..moveTo(250, -10)
      ..cubicTo(206, 60, 206, 140, 244, 210);
    canvas.drawPath(
      solid,
      Paint()
        ..color = BrandColors.sealGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final Path dashed = Path()
      ..moveTo(260, -10)
      ..cubicTo(218, 60, 218, 140, 256, 210);
    final Paint dashPaint = Paint()
      ..color = BrandColors.threadGold.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final ui.PathMetric metric in dashed.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), dashPaint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, this.routeName);

  final String text;
  final String routeName;

  IconData get _icon => switch (routeName) {
    'programs' => TaytayIcons.handHeart,
    'services' => TaytayIcons.briefcase,
    _ => TaytayIcons.newspaper,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.sealGold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TaytayIcon(
            icon: _icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: 12,
            color: BrandColors.taytayBlueDark,
          ),
          const SizedBox(width: 5),
          Text(text, style: _eyebrow),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Container(
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? BrandColors.taytayBlue
                    : const Color(0xFFC3CBDA),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(text, style: _section),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 4,
          decoration: BoxDecoration(
            color: BrandColors.sealGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _SectionLink extends StatelessWidget {
  const _SectionLink({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? action = this.action;
    // The 32 dp row is the 1x design. Larger text has to grow the row: a
    // fixed height plus an intrinsic title overflows the list at 200%.
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    final Widget link = action == null
        ? const SizedBox.shrink()
        : largeText
        ? _Hit(
            label: action,
            onTap: onAction,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(action, style: _link),
              ),
            ),
          )
        : _Hit(
            label: action,
            width: 88,
            height: 19,
            onTap: onAction,
            child: Text(
              action,
              style: _link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          );
    final Widget row = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: _linkTitle,
            maxLines: largeText ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) link,
      ],
    );
    if (largeText) return row;
    return row;
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({this.onTap});

  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    const List<(String, String, IconData, Color, Color)> tiles =
        <(String, String, IconData, Color, Color)>[
          (
            'Directory',
            'services',
            TaytayIcons.building2,
            Color(0xFFEAF0FB),
            BrandColors.taytayBlue,
          ),
          (
            'Tulong',
            'programs',
            TaytayIcons.handHeart,
            Color(0xFFE6F4EC),
            BrandColors.success,
          ),
          (
            'Balita',
            'news',
            TaytayIcons.newspaper,
            Color(0xFFFFF6CC),
            BrandColors.inkGold,
          ),
          (
            'Hotlines',
            'hotlines',
            TaytayIcons.phone,
            Color(0xFFFDECEC),
            BrandColors.danger,
          ),
        ];
    final bool largeText = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    Widget tile(int i) {
      return _Hit(
        label: tiles[i].$1,
        onTap: () => onTap?.call(tiles[i].$2),
        child: Container(
          key: Key('home-quick-${tiles[i].$2}'),
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandColors.cardLine),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tiles[i].$4,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TaytayIcon(
                    icon: tiles[i].$3,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 22,
                    color: tiles[i].$5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tiles[i].$1,
                style: _quick,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // Four columns match the design. At large text a word such as Directory
    // no longer fits a quarter of a 320 dp phone, so the row becomes two.
    if (largeText) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (var i = 0; i < tiles.length; i++)
                SizedBox(width: width, child: tile(i)),
            ],
          );
        },
      );
    }
    return Row(
      children: <Widget>[
        for (var i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tile(i)),
        ],
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.items, this.onTap});

  final List<HomeNewsItem> items;
  final ValueChanged<HomeNewsItem>? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < items.length; i++)
            _NewsRow(
              item: items[i],
              border: i < items.length - 1,
              onTap: () => onTap?.call(items[i]),
            ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.item, required this.border, this.onTap});

  final HomeNewsItem item;
  final bool border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = item.alert ? BrandColors.danger : BrandColors.taytayBlue;
    return _Hit(
      label: item.title,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: border
              ? const Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            _IconTile(
              background: item.alert
                  ? const Color(0xFFFDECEC)
                  : BrandColors.surfaceMuted,
              icon: item.alert ? TaytayIcons.siren : TaytayIcons.landmark,
              color: ink,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.eyebrow, style: _eyebrowSmall.copyWith(color: ink)),
                  Text(item.title, style: _newsTitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
      ),
      child: const Column(
        children: <Widget>[
          _SkeletonRow(),
          SizedBox(height: 12),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _Skeleton(height: 44, width: 44, radius: 12),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Skeleton(height: 10, width: 120, radius: 6),
              SizedBox(height: 8),
              _Skeleton(height: 12, radius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.hotline, this.onCall});

  final HomeHotline hotline;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.danger,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const _IconTile(
            background: Color(0x2EFFFFFF),
            icon: TaytayIcons.siren,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${hotline.name} · 24/7', style: _emergencyLabel),
                Text(hotline.number, style: _emergencyNumber),
              ],
            ),
          ),
          _Hit(
            label: 'Call ${hotline.name}',
            width: 44,
            height: 44,
            onTap: onCall,
            child: Container(
              key: const Key('home-call'),
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: TaytayIcon(
                  icon: TaytayIcons.phone,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 18,
                  color: BrandColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.background,
    required this.icon,
    required this.color,
    this.size = 20,
  });

  final Color background;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TaytayIcon(
          icon: icon,
          semanticLabel: '',
          excludeSemantics: true,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lays out [child] at its own size and keeps a 48 dp hit target when the
/// visual is smaller, without growing the layout.
class _Hit extends StatelessWidget {
  const _Hit({
    required this.child,
    required this.label,
    this.onTap,
    this.width,
    this.height,
    this.badge,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final Widget visual = badge == null
        ? child
        : Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              child,
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.danger,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(badge!, style: _badge),
                ),
              ),
            ],
          );
    final double? slotW = width;
    final double? slotH = height;
    if (slotW == null || slotH == null) {
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: visual,
        ),
      );
    }
    final double hitW = slotW < 48 ? 48 : slotW;
    final double hitH = slotH < 48 ? 48 : slotH;
    // The semantics node is the 48 dp well. Wrapping the visual slot instead
    // made screen readers measure the smaller mark.
    return SizedBox(
      width: slotW,
      height: slotH,
      child: OverflowBox(
        minWidth: hitW,
        maxWidth: hitW,
        minHeight: hitH,
        maxHeight: hitH,
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: hitW,
              height: hitH,
              child: Center(child: visual),
            ),
          ),
        ),
      ),
    );
  }
}

const TextStyle _greeting = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 28,
  fontWeight: FontWeight.w800,
  height: 1.15,
  letterSpacing: -0.6,
  color: BrandColors.taytayBlueDark,
  decoration: TextDecoration.none,
);

const TextStyle _subtitle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: BrandColors.sheetBody,
  decoration: TextDecoration.none,
);

const TextStyle _wordmark = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.2,
  color: BrandColors.taytayBlueDark,
  decoration: TextDecoration.none,
);

const TextStyle _province = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.4,
  color: BrandColors.inkGold,
  decoration: TextDecoration.none,
);

const TextStyle _initials = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _pill = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _account = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

/// Width of [text] in the same style the button paints, so the slot can
/// shrink-wrap without a second layout pass.
double _textWidth(BuildContext context, String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  return painter.width;
}

const TextStyle _badge = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  decoration: TextDecoration.none,
  height: 1,
);

const TextStyle _cardTitle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _cardBody = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.5,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _heroTitle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 18,
  fontWeight: FontWeight.w800,
  height: 1.18,
  letterSpacing: -0.3,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _heroBody = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.4,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _cta = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlueDark,
  decoration: TextDecoration.none,
);

const TextStyle _credit = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _eyebrow = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.8,
  color: BrandColors.taytayBlueDark,
  decoration: TextDecoration.none,
);

const TextStyle _section = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 18,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlueDark,
  decoration: TextDecoration.none,
);

const TextStyle _linkTitle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _link = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _quick = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 12,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _eyebrowSmall = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w800,
  decoration: TextDecoration.none,
);

const TextStyle _newsTitle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 13,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _emergencyLabel = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _emergencyNumber = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 18,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  decoration: TextDecoration.none,
);
