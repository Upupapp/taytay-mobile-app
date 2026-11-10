import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/account/domain/photo_credit.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_canvas.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/shared/widgets/app_button.dart';
import 'package:taytay_resident/shared/widgets/pills.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';

import '../support/layout_matrix.dart';

/// Redesign Phase 4: the header-overlap tap fix on every glass page, filter
/// chip semantics on Directory and Balita, the photo credits screen, and a
/// token scan of the files Phase 4 restyled.
void main() {
  group('a tap on the strip raised over the header reaches the content', () {
    testWidgets('the check fails on a list that keeps its item wrappers', (
      WidgetTester tester,
    ) async {
      // The planted defect: a default ListView wraps each child in a
      // RepaintBoundary that hit-tests only its own box, so the raised strip
      // goes to the header. If this stops failing the check, the check is
      // reading nothing.
      var taps = 0;
      await tester.pumpWidget(
        layoutHost(_plantedList(onTap: () => taps += 1), scrollable: false),
      );
      expect(_stripHitsContent(tester), isFalse);
      await tester.tapAt(_stripPoint(tester));
      expect(taps, 0);

      await tester.pumpWidget(
        layoutHost(
          _plantedList(onTap: () => taps += 1, flagsOff: true),
          scrollable: false,
        ),
      );
      expect(_stripHitsContent(tester), isTrue);
      await tester.tapAt(_stripPoint(tester));
      expect(taps, 1);
    });

    testWidgets('Home', (WidgetTester tester) async {
      await tester.pumpWidget(
        layoutHost(
          const HomeCanvas(
            greeting: 'Magandang umaga, Resident!',
            initials: 'RS',
            slides: _slides,
            news: _news,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);
    });

    testWidgets('Balita list and article', (WidgetTester tester) async {
      await tester.pumpWidget(
        layoutHost(
          BalitaCanvas(
            frame: BalitaFrame.feed,
            articles: _articles,
            onArticle: (_) {},
            onShare: (_) {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);

      await tester.pumpWidget(
        layoutHost(
          BalitaCanvas(frame: BalitaFrame.article, article: _articles.first),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);
    });

    testWidgets('My Account', (WidgetTester tester) async {
      await tester.pumpWidget(
        layoutHost(
          AccountCanvas(
            frame: AccountFrame.home,
            name: 'Resident Sample',
            initials: 'RS',
            location: 'Brgy. Sample, Taytay, Rizal',
            menu: AccountSpecimen.homeMenu,
            onDigitalId: () {},
            onSignOut: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);
    });

    testWidgets('the directory office page', (WidgetTester tester) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.detail,
            offices: const <Office>[],
            office: catalogue.offices.first,
            onCall: () {},
            onDirections: () {},
            onMessage: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);
    });

    testWidgets('the digital ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        layoutHost(
          DigitalIdView(now: DateTime(2026, 10, 22)),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(_stripHitsContent(tester), isTrue);
    });
  });

  group('filter chips are announced as selectable buttons', () {
    testWidgets('Directory category chips', (WidgetTester tester) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      final List<String> picked = <String>[];
      final String selected = catalogue.chips.first;
      final String other = catalogue.chips[1];
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.list,
            offices: catalogue.offices,
            chips: catalogue.chips,
            selectedChip: selected,
            onChip: picked.add,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.widgetWithText(SoftChoiceChip, selected)),
        isSemantics(
          label: selected,
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      final Finder otherChip = find.widgetWithText(SoftChoiceChip, other);
      expect(
        tester.getSemantics(otherChip),
        isSemantics(
          label: other,
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      // The announced tap is the chip's own: a screen reader's double tap
      // filters the list.
      tester.semantics.tap(
        find.semantics.byLabel(RegExp('^${RegExp.escape(other)}\$')),
      );
      expect(picked, <String>[other]);
      handle.dispose();
    });

    testWidgets('Balita header chips', (WidgetTester tester) async {
      final List<String> picked = <String>[];
      await tester.pumpWidget(
        layoutHost(
          BalitaCanvas(
            frame: BalitaFrame.feed,
            articles: _articles,
            selectedChip: 'Advisory',
            onChip: (BalitaChip chip) => picked.add(chip.label),
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(const Key('balita-chip-Advisory'))),
        isSemantics(
          label: 'Advisory',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('balita-chip-Lahat'))),
        isSemantics(
          label: 'Lahat',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel(RegExp(r'^Lahat$')));
      expect(picked, <String>['Lahat']);
      // Still 48 dp tall.
      expect(
        tester.getSize(find.byKey(const Key('balita-chip-Lahat'))).height,
        greaterThanOrEqualTo(A11y.minTapTarget),
      );
      handle.dispose();
    });
  });

  group('photo credits & about', () {
    testWidgets('the bundled photographs are credited from their data', (
      WidgetTester tester,
    ) async {
      // Tall enough that the list builds every row.
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(430, 2000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        layoutHost(
          AccountCanvas(
            frame: AccountFrame.about,
            title: 'Photo credits & about',
            showBack: true,
            onBanners: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.text('Photo credits'), findsOneWidget);
      for (final PhotoCredit credit in PhotoCredits.welcome) {
        expect(find.text(credit.title), findsOneWidget);
        expect(find.text(credit.byline), findsOneWidget);
      }
      expect(find.text('Office banner photos'), findsOneWidget);
      expect(find.text(PhotoCredits.officeBannerSummary), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets(
      'with no credits the lists are not drawn and the screen stays',
      (WidgetTester tester) async {
        // The API sends no image credit, so a credit list can be empty. Nothing
        // is invented for it: the heading and the banner row go, the about
        // card and its wording stay.
        await tester.pumpWidget(
          layoutHost(
            const AccountCanvas(
              frame: AccountFrame.about,
              title: 'Photo credits & about',
              showBack: true,
              credits: <PhotoCredit>[],
            ),
            scrollable: false,
          ),
        );
        await tester.pump();
        expect(find.text('Photo credits & about'), findsOneWidget);
        expect(find.text('Taytay Resident App'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
        expect(find.text('Photo credits'), findsNothing);
        expect(find.text('Office banner photos'), findsNothing);
        expect(find.textContaining('photos · Wikimedia Commons'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the about frame lays out at every width and 200% text', (
      WidgetTester tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => const AccountCanvas(
          frame: AccountFrame.about,
          title: 'Photo credits & about',
          showBack: true,
        ),
        scrollable: false,
      );
    });
  });

  testWidgets('a secondary AppButton is the soft button, with no border', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      layoutHost(
        AppButton(
          label: 'Sign out',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
    );
    final Material surface = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(OutlinedButton),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(surface.color, BrandColors.blue50);
    expect(surface.elevation, 0);
    expect(
      surface.shape,
      isA<OutlinedBorder>().having(
        (OutlinedBorder border) => border.side,
        'side',
        BorderSide.none,
      ),
    );
  });

  test('Phase 4 files use tokens: no raw colours, sizes, shadows or '
      'Material icons', () {
    final List<String> offenders = <String>[];
    for (final String path in _restyled) {
      final List<String> lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (RegExp(
          r'Color\(0x|Color\.fromRGBO|BoxShadow|elevation: *[1-9]|fontSize:|'
          r'(^|[^A-Za-z])Icons\.',
        ).hasMatch(line)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no feature file draws the retired headers, cards or banners', () {
    final List<String> offenders = <String>[];
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String source = entity.readAsStringSync();
      for (final String name in <String>[
        'InAppHeader(',
        'MunicipalHeader(',
        'WovenHeader(',
        'FramedSeal(',
        'AppCard(',
        'GoldThreadShell(',
      ]) {
        if (source.contains(name)) offenders.add('${entity.path}: $name');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

/// A point inside the strip [GlassOverlap] raises over the header: its own
/// box starts where the header ends, and its child is painted higher.
Offset _stripPoint(WidgetTester tester) {
  final Rect box = tester.getRect(find.byType(GlassOverlap));
  return Offset(box.center.dx, box.top - Spacing.sm);
}

/// Hit-tests the strip as a tap there would. True when the hit lands inside
/// the raised content rather than stopping at the header.
bool _stripHitsContent(WidgetTester tester) {
  final Finder overlap = find.byType(GlassOverlap);
  expect(overlap, findsOneWidget);
  final RenderObject raised = tester.renderObject(overlap);
  final HitTestResult result = HitTestResult();
  tester.binding.hitTestInView(result, _stripPoint(tester), tester.view.viewId);
  final List<HitTestTarget> path = <HitTestTarget>[
    for (final HitTestEntry entry in result.path) entry.target,
  ];
  if (!path.contains(raised)) return false;
  // The deepest render object hit (a text span may sit in front of it).
  RenderObject? node = path.whereType<RenderObject>().first;
  while (node != null) {
    if (identical(node, raised)) return true;
    node = node.parent;
  }
  return false;
}

/// A header and a raised card in a ListView, with or without the two flags.
Widget _plantedList({required VoidCallback onTap, bool flagsOff = false}) {
  final List<Widget> children = <Widget>[
    const SizedBox(height: 120, child: ColoredBox(color: BrandColors.blue)),
    GlassOverlap(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(width: double.infinity, height: 160),
      ),
    ),
  ];
  return flagsOff
      ? ListView(
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          children: children,
        )
      : ListView(children: children);
}

const List<String> _restyled = <String>[
  'lib/core/router/app_router.dart',
  'lib/features/gallery/presentation/component_gallery_screen.dart',
  'lib/features/verification/presentation/unverified_gate_sheet.dart',
  'lib/shared/widgets/app_banner.dart',
  'lib/shared/widgets/app_button.dart',
  'lib/shared/widgets/capability_gate.dart',
  'lib/shared/widgets/failure_view.dart',
  'lib/shared/widgets/form_support.dart',
  'lib/shared/widgets/remote_image.dart',
  'lib/shared/widgets/status_view.dart',
  'lib/shared/widgets/taytay_back_button.dart',
  'lib/shared/widgets/taytay_rows.dart',
];

const List<HomeSlide> _slides = <HomeSlide>[
  HomeSlide(
    eyebrow: 'BALITA',
    title: 'A slide title for the tap check',
    body: 'A slide sentence.',
    action: 'Read Balita',
    photoAsset: 'assets/photos/municipal_hall.jpg',
    credit: 'Photo credit',
    routeName: 'news',
  ),
];

const List<HomeNewsItem> _news = <HomeNewsItem>[
  HomeNewsItem(
    id: 'n1',
    eyebrow: 'ADVISORY · TREASURY',
    title: 'A synthetic advisory title',
    alert: false,
  ),
];

final List<Announcement> _articles = <Announcement>[
  Announcement(
    id: 'a1',
    title: 'A synthetic notice title',
    body: 'A synthetic body for the tap check.',
    category: 'Advisory',
    author: 'Synthetic Office',
    publishedAt: DateTime.utc(2026, 7, 1),
    isPinned: true,
    presentation: const BalitaPresentation(
      coverAsset: 'assets/photos/municipal_hall.jpg',
      listCover: true,
      photoCredit: 'Photo: synthetic credit line',
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
