import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/feed_row.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';

import '../support/layout_matrix.dart';

/// Redesign P3b: Home, Balita and the digital ID at 360 / 375 / 430 dp and
/// 100% / 200% text, plus the content rules the restyle must keep.
void main() {
  group('home', () {
    testWidgets('guest Home lays out cleanly', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const HomeCanvas(
          greeting: 'Magandang umaga, Bisita!',
          status: HomeStatusKind.guest,
          slides: _slides,
        ),
        scrollable: false,
      );
    });

    testWidgets('pending Home with news and a hotline lays out cleanly', (
      tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => const HomeCanvas(
          greeting: 'Magandang umaga, Resident!',
          initials: 'RS',
          bellCount: 3,
          status: HomeStatusKind.pending,
          slides: _slides,
          news: _news,
          hotline: _hotline,
        ),
        height: 1400,
        scrollable: false,
      );
    });

    testWidgets('refreshing Home lays out cleanly', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const HomeCanvas(
          greeting: 'Magandang umaga, Resident!',
          initials: 'RS',
          refreshing: true,
          slides: _slides,
        ),
        scrollable: false,
      );
    });

    testWidgets('hotlines lay out cleanly when loaded, loading and empty', (
      tester,
    ) async {
      for (final HotlinesCanvas canvas in <HotlinesCanvas>[
        const HotlinesCanvas(lines: <HomeHotline>[_hotline, _barangay]),
        const HotlinesCanvas(lines: <HomeHotline>[], loading: true),
        const HotlinesCanvas(lines: <HomeHotline>[]),
      ]) {
        await expectCleanLayouts(tester, () => canvas, scrollable: false);
      }
    });

    testWidgets('Home is the glass tab under the blue header', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          const HomeCanvas(
            greeting: 'Magandang umaga, Resident!',
            initials: 'RS',
            bellCount: 3,
            slides: _slides,
            news: _news,
            hotline: _hotline,
          ),
          scrollable: false,
        ),
      );
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(find.byType(GlassOverlap), findsOneWidget);
      // The badge is the count passed in, and the label says it.
      expect(find.bySemanticsLabel('Notifications, 3 unread'), findsOneWidget);
      // Every Balita item is a row: no item is promoted as featured.
      expect(find.byType(FeedRow), findsNWidgets(_news.length));
    });

    testWidgets('an empty hotline list says so instead of a blank page', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const HotlinesCanvas(lines: <HomeHotline>[]),
          scrollable: false,
        ),
      );
      expect(find.text('No hotlines to show'), findsOneWidget);
    });
  });

  group('news', () {
    testWidgets('every Balita list frame lays out cleanly', (tester) async {
      for (final BalitaFrame frame in <BalitaFrame>[
        BalitaFrame.feed,
        BalitaFrame.loading,
        BalitaFrame.failed,
        BalitaFrame.emptyFeed,
      ]) {
        await expectCleanLayouts(
          tester,
          () => BalitaCanvas(
            frame: frame,
            articles: _articles,
            onShare: (_) {},
            onArticle: (_) {},
            onRetry: () {},
          ),
          height: 1200,
          scrollable: false,
        );
      }
      await expectCleanLayouts(
        tester,
        () => BalitaCanvas(
          frame: BalitaFrame.emptyCategory,
          selectedChip: 'Events',
          onSeeAll: () {},
        ),
        scrollable: false,
      );
      await expectCleanLayouts(
        tester,
        () => BalitaCanvas(
          frame: BalitaFrame.filter,
          selectedChip: 'Advisory',
          articles: _articles,
        ),
        height: 1200,
        scrollable: false,
      );
    });

    testWidgets('the article page lays out cleanly with and without a photo', (
      tester,
    ) async {
      for (final Announcement article in _articles) {
        await expectCleanLayouts(
          tester,
          () => BalitaCanvas(frame: BalitaFrame.article, article: article),
          height: 1200,
          scrollable: false,
        );
      }
    });

    testWidgets('Balita draws no featured story and keeps share', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          BalitaCanvas(
            frame: BalitaFrame.feed,
            articles: _articles,
            onShare: (_) {},
          ),
          scrollable: false,
        ),
      );
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Pinned advisory'), findsOneWidget);
      for (final Announcement article in _articles) {
        expect(find.byKey(Key('balita-share-${article.id}')), findsOneWidget);
      }
    });
  });

  test('restyled screens use tokens: no raw colours, sizes or shadows', () {
    final List<String> offenders = <String>[];
    for (final String path in _restyled) {
      final List<String> lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (RegExp(
          r'Color\(0x|BoxShadow|elevation:|fontSize:',
        ).hasMatch(line)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

const List<String> _restyled = <String>[
  'lib/features/home/presentation/home_canvas.dart',
  'lib/features/home/presentation/home_screen.dart',
  'lib/features/home/presentation/hotlines_screen.dart',
  'lib/features/news/presentation/balita_canvas.dart',
  'lib/features/news/presentation/news_screen.dart',
  'lib/features/news/presentation/news_post_screen.dart',
];

const List<HomeSlide> _slides = <HomeSlide>[
  HomeSlide(
    eyebrow: 'BALITA',
    title: 'A slide title that is long enough to wrap onto lines',
    body: 'A slide sentence for the layout check.',
    action: 'Read Balita',
    photoAsset: 'assets/photos/municipal_hall.jpg',
    credit: 'Photo credit',
    routeName: 'news',
  ),
  HomeSlide(
    eyebrow: 'TULONG',
    title: 'Second slide',
    body: '',
    action: 'Explore Tulong',
    photoAsset: 'assets/photos/parish_church.jpg',
    credit: 'Photo credit',
    routeName: 'programs',
  ),
];

const List<HomeNewsItem> _news = <HomeNewsItem>[
  HomeNewsItem(
    id: 'n1',
    eyebrow: 'ADVISORY · TREASURY',
    title: 'A synthetic advisory title for the layout check',
    alert: false,
  ),
  HomeNewsItem(
    id: 'n2',
    eyebrow: 'SAFETY',
    title: 'A synthetic safety notice',
    alert: true,
  ),
];

const HomeHotline _hotline = HomeHotline(
  id: 'line-1',
  name: 'Synthetic Command Center',
  number: '0900-000-0000',
  category: 'municipal',
);

const HomeHotline _barangay = HomeHotline(
  id: 'line-2',
  name: 'Synthetic Barangay',
  number: '0900-000-0001',
  category: 'barangay',
);

final List<Announcement> _articles = <Announcement>[
  Announcement(
    id: 'a1',
    title: 'A synthetic notice title that runs long enough to wrap twice',
    body: 'A synthetic body for the layout check.',
    category: 'Advisory',
    author: 'Synthetic Office With A Long Name',
    publishedAt: DateTime.utc(2026, 7, 1),
    isPinned: true,
    presentation: const BalitaPresentation(
      coverAsset: 'assets/photos/municipal_hall.jpg',
      listCover: true,
      photoCredit: 'Photo: synthetic credit line',
      facts: <BalitaFact>[
        BalitaFact(label: 'Where', value: 'A synthetic hall', icon: 'map-pin'),
      ],
      footer: 'A synthetic footer line.',
    ),
  ),
  Announcement(
    id: 'a2',
    title: 'A second synthetic notice',
    body: 'A second synthetic body.',
    category: 'Safety',
    publishedAt: DateTime.utc(2026, 6, 1),
  ),
];
