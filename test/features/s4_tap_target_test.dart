import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/home/data/home_catalogue.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

void _noop() {}

/// The hit the resident actually touches. A key on the painted mark resolves
/// to the [GestureDetector] around it. A key on the detector is measured
/// directly.
Size _hitSize(WidgetTester tester, Key key) {
  final Finder marked = find.byKey(key);
  expect(marked, findsOneWidget, reason: '$key is missing');
  final Element element = marked.evaluate().single;
  if (element.widget is GestureDetector) {
    return tester.getSize(marked);
  }
  final Finder detector = find.ancestor(
    of: marked,
    matching: find.byType(GestureDetector),
  );
  expect(detector, findsWidgets, reason: '$key has no hit target');
  return tester.getSize(detector.first);
}

void _expectAtLeast48(WidgetTester tester, Key key) {
  final Size size = _hitSize(tester, key);
  expect(
    size.width,
    greaterThanOrEqualTo(A11y.minTapTarget),
    reason: '$key is ${size.width} dp wide',
  );
  expect(
    size.height,
    greaterThanOrEqualTo(A11y.minTapTarget),
    reason: '$key is ${size.height} dp tall',
  );
}

Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  tester.view.physicalSize = size ?? const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
}

void main() {
  test('live hero slides come from the bundled asset', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String source = File(
      'lib/features/home/data/home_catalogue.dart',
    ).readAsStringSync();
    final int start = source.indexOf(
      'static Future<List<HomeSlide>> slides()',
    );
    final int end = source.indexOf('static List<HomeSlide> withBanners');
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final String body = source.substring(start, end);
    expect(body.contains('MockFixtures'), isFalse);
    expect(source.contains('assets/home/slides.json'), isTrue);

    final List<HomeSlide> slides = await HomeCatalogue.slides();
    expect(slides.map((HomeSlide slide) => slide.focus), <double>[
      0.35,
      0.3,
      0.6,
    ]);
    expect(slides.map((HomeSlide slide) => slide.routeName), <String>[
      'news',
      'programs',
      'services',
    ]);
  });

  testWidgets('S4 controls are at least 48 dp', (tester) async {
    final List<HomeSlide> slides = await HomeCatalogue.slides();
    final ({List<HomeNewsItem> news, List<HomeHotline> hotlines}) feed =
        await HomeCatalogue.mockFeed();

    // The emergency call sits below an 844 dp phone. A taller surface builds
    // it without changing the control's own size.
    await _pump(
      tester,
      HomeCanvas(
        greeting: 'Magandang gabi, Juana!',
        initials: 'JD',
        bellCount: 2,
        slides: slides,
        news: feed.news,
        hotline: feed.hotlines.first,
        onBell: _noop,
        onAvatar: _noop,
        onSlide: (_) {},
        onQuickAction: (_) {},
        onCall: _noop,
      ),
      size: const Size(390, 2400),
    );

    for (final String name in <String>[
      'home-bell',
      'home-avatar',
      'home-hero-cta',
      'home-quick-services',
      'home-quick-programs',
      'home-quick-news',
      'home-quick-hotlines',
      'home-call',
    ]) {
      _expectAtLeast48(tester, Key(name));
    }

    await _pump(
      tester,
      const ShellTabBar(selectedIndex: 0, onSelected: _ignore),
    );
    _expectAtLeast48(tester, ShellTabBar.discKey);
    for (final String name in <String>[
      'home',
      'directory',
      'balita',
      'tulong',
      'account',
    ]) {
      _expectAtLeast48(tester, Key('shell-tab-$name'));
    }

    await _pump(
      tester,
      HotlinesCanvas(lines: feed.hotlines, onBack: _noop, onCall: (_) async {}),
      size: const Size(390, 2400),
    );
    expect(feed.hotlines, isNotEmpty);
    for (final HomeHotline line in feed.hotlines) {
      _expectAtLeast48(tester, Key('hotline-call-${line.id}'));
    }
  });
}

void _ignore(int index) {}
