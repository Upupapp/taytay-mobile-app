import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_glyphs.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/consent_check_card.dart';
import 'package:taytay_resident/shared/widgets/error_state.dart';
import 'package:taytay_resident/shared/widgets/feed_row.dart';
import 'package:taytay_resident/shared/widgets/icon_tile.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';
import 'package:taytay_resident/shared/widgets/network_status_views.dart';
import 'package:taytay_resident/shared/widgets/photo_carousel.dart';
import 'package:taytay_resident/shared/widgets/pill_button_row.dart';
import 'package:taytay_resident/shared/widgets/status_line.dart';
import 'package:taytay_resident/shared/widgets/success_screen.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';
import 'package:taytay_resident/shared/widgets/taytay_glyph.dart';
import 'package:taytay_resident/shared/widgets/taytay_states.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../support/layout_matrix.dart';

/// A long string, so the layout matrix tries wrapping at 200%.
const String _long =
    'A deliberately long line that has to wrap on a narrow phone at large text';

/// 1 × 1 transparent PNG: a real image provider with no file behind it.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const WeeklyHours _weekdays = WeeklyHours(<int, DayHours>{
  DateTime.monday: DayHours.of(8, 0, 17, 0),
  DateTime.tuesday: DayHours.of(8, 0, 17, 0),
  DateTime.wednesday: DayHours.of(8, 0, 17, 0),
  DateTime.thursday: DayHours.of(8, 0, 17, 0),
  DateTime.friday: DayHours.of(8, 0, 17, 0),
});

/// Manila wall time as a UTC instant (Manila is UTC+8, no DST).
DateTime _manila(int year, int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(year, month, day, hour - 8, minute);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(layoutHost(child));
  await tester.pump(const Duration(milliseconds: 50));
}

bool _hasShadow(WidgetTester tester, Finder of) {
  for (final DecoratedBox box in tester.widgetList<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)),
  )) {
    final Decoration decoration = box.decoration;
    if (decoration is BoxDecoration &&
        (decoration.boxShadow?.isNotEmpty ?? false)) {
      return true;
    }
  }
  return false;
}

void main() {
  testWidgets('the layout matrix fails on a planted overflow', (tester) async {
    // The helper is only worth reusing if it actually catches the failure it
    // exists for: a row wider than a 360 px phone.
    TestFailure? failure;
    try {
      await expectCleanLayouts(
        tester,
        () => const Row(children: <Widget>[SizedBox(width: 400, height: 10)]),
        widths: const <double>[360],
        textScales: const <double>[1],
      );
    } on TestFailure catch (error) {
      failure = error;
    }
    expect(failure?.message, contains('overflowed'));
    expect(failure?.message, contains('360'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('assets', () {
    test('every glyph and illustration is a declared SVG asset', () {
      final Map<String, AssetEntry> byPath = <String, AssetEntry>{
        for (final AssetEntry entry in AppAssets.all) entry.path: entry,
      };
      for (final TaytayGlyph glyph in TaytayGlyph.values) {
        final AssetEntry? entry = byPath[glyph.assetPath];
        expect(entry, isNotNull, reason: glyph.assetPath);
        expect(entry?.kind, AssetKind.icon);
        expect(entry?.format, AssetFormat.svg);
      }
      for (final TaytayIllustration art in TaytayIllustration.values) {
        final AssetEntry? entry = byPath[art.assetPath];
        expect(entry, isNotNull, reason: art.assetPath);
        expect(entry?.kind, AssetKind.illustration);
      }
    });

    testWidgets('a glyph is silent unless it is given a name', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Row(
          children: <Widget>[
            GlyphIcon(TaytayGlyph.phone),
            GlyphIcon(TaytayGlyph.siren, semanticLabel: 'Emergency'),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Emergency'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNWidgets(2));
      handle.dispose();
    });
  });

  group('IconTile', () {
    testWidgets('the glyph tile draws each size and the gold tone in navy', (
      tester,
    ) async {
      await _pump(
        tester,
        const Row(
          children: <Widget>[
            IconTile.glyph(
              glyph: TaytayGlyph.bank,
              tone: TileTone.gold,
              tileSize: IconTileSize.small,
            ),
            IconTile.glyph(glyph: TaytayGlyph.bank),
            IconTile.glyph(
              glyph: TaytayGlyph.bank,
              tileSize: IconTileSize.large,
            ),
          ],
        ),
      );
      final List<Size> sizes = tester
          .widgetList(find.byType(IconTile))
          .map((w) => tester.getSize(find.byWidget(w)))
          .toList();
      expect(sizes, const <Size>[Size(36, 36), Size(44, 44), Size(56, 56)]);
      final GlyphIcon gold = tester.widget<GlyphIcon>(
        find.byType(GlyphIcon).first,
      );
      expect(gold.color, BrandGradients.tile(TileTone.gold).onColor);
      expect(gold.color, BrandColors.navy);
      expect(_hasShadow(tester, find.byType(IconTile).first), isFalse);
    });

    testWidgets('the earlier flat tile still draws as it did', (tester) async {
      await _pump(
        tester,
        const IconTile(
          icon: TaytayIcons.phone,
          fill: BrandColors.blue50,
          ink: BrandColors.blue,
        ),
      );
      expect(tester.getSize(find.byType(IconTile)), const Size(40, 40));
      expect(find.byIcon(TaytayIcons.phone), findsOneWidget);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => Wrap(
          children: <Widget>[
            for (final TileTone tone in TileTone.values)
              IconTile.glyph(glyph: TaytayGlyph.users, tone: tone),
          ],
        ),
      );
    });
  });

  group('BlueHeader', () {
    testWidgets('renders its title, subtitle, seal and actions', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var bell = 0;
      await _pump(
        tester,
        BlueHeader(
          title: 'Title',
          subtitle: 'Subtitle',
          leading: const HeaderSeal(),
          actions: <Widget>[
            HeaderIconButton(
              icon: TaytayIcons.bell,
              semanticLabel: 'Notifications, 3 unread',
              badgeCount: 3,
              onPressed: () => bell++,
            ),
          ],
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Seal of the Municipality of Taytay, Rizal'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byType(HeaderIconButton)),
        isSemantics(
          label: 'Notifications, 3 unread',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(HeaderIconButton));
      expect(bell, 1);
      expect(
        tester.getSize(find.byType(HeaderIconButton)),
        const Size(A11y.minTapTarget, A11y.minTapTarget),
      );
      expect(_hasShadow(tester, find.byType(BlueHeader)), isFalse);
      handle.dispose();
    });

    testWidgets('a badge caps at 99+ and hides at zero or none', (
      tester,
    ) async {
      Widget button(int? count) => HeaderIconButton(
        icon: TaytayIcons.bell,
        semanticLabel: 'Notifications',
        badgeCount: count,
        onPressed: () {},
      );
      await _pump(tester, Row(children: <Widget>[button(120), button(0)]));
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await _pump(tester, button(null));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a back control replaces the leading slot and calls onBack', (
      tester,
    ) async {
      var back = 0;
      await _pump(
        tester,
        BlueHeader(
          title: 'Detail',
          showBack: true,
          onBack: () => back++,
          leading: const HeaderSeal(),
        ),
      );
      expect(find.byType(HeaderSeal), findsNothing);
      await tester.tap(find.byType(InkWell).first);
      expect(back, 1);
    });

    testWidgets('a glass tab leaves room for the body to ride up', (
      tester,
    ) async {
      await _pump(tester, const BlueHeader(title: 'Tab'));
      final double flat = tester.getSize(find.byType(BlueHeader)).height;
      await _pump(tester, const BlueHeader(title: 'Tab', overlap: true));
      final double glass = tester.getSize(find.byType(BlueHeader)).height;
      expect(glass - flat, 46 - 18);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => BlueHeader(
          title: _long,
          subtitle: _long,
          leading: const HeaderSeal(),
          actions: <Widget>[
            for (var i = 0; i < 2; i++)
              HeaderIconButton(
                icon: TaytayIcons.bell,
                semanticLabel: 'Notifications',
                badgeCount: 120,
                onPressed: () {},
              ),
          ],
          bottom: const Text(_long),
        ),
      );
    });
  });

  group('WaveHeader', () {
    testWidgets('renders the step, progress, title and subtitle', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const WaveHeader(
          title: 'Title',
          subtitle: 'Subtitle',
          stepLabel: 'Step 2 of 6',
          progress: 0.5,
          progressSemanticLabel: 'Progress',
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Step 2 of 6'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Progress')),
        isSemantics(label: 'Progress', value: '50%'),
      );
      handle.dispose();
    });

    testWidgets('without a top row or bar it draws the title alone', (
      tester,
    ) async {
      await _pump(tester, const WaveHeader(title: 'Only'));
      expect(find.text('Only'), findsOneWidget);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => WaveHeader(
          title: _long,
          subtitle: _long,
          showBack: true,
          onBack: () {},
          stepLabel: 'Step 2 of 6',
          progress: 1 / 3,
          badge: const SuccessMark(style: SuccessMarkStyle.medal),
        ),
      );
    });
  });

  group('SoftCard and GlassCard', () {
    testWidgets('render their child, take a tap, and cast no shadow', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(
        tester,
        GlassBackground(
          child: Column(
            children: <Widget>[
              SoftCard(
                semanticLabel: 'Soft',
                onTap: () => taps++,
                child: const Text('Soft body'),
              ),
              const SoftCard(filled: true, child: Text('Filled body')),
              const GlassCard(child: Text('Glass body')),
              const GlassCard(pinned: true, child: Text('Pinned body')),
            ],
          ),
        ),
      );
      for (final String text in <String>[
        'Soft body',
        'Filled body',
        'Glass body',
        'Pinned body',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      await tester.tap(find.text('Soft body'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^Soft'))),
        isSemantics(label: 'Soft\nSoft body', isButton: true),
      );
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(_hasShadow(tester, find.byType(GlassBackground)), isFalse);
      handle.dispose();
    });

    testWidgets('fit every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const Column(
          children: <Widget>[
            SoftCard(child: Text(_long)),
            GlassCard(child: Text(_long)),
          ],
        ),
      );
    });
  });

  group('PillButtonRow', () {
    testWidgets('renders each action with a 48 px target', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> tapped = <String>[];
      await _pump(
        tester,
        PillButtonRow(
          actions: <PillAction>[
            PillAction(
              label: 'Call',
              glyph: TaytayGlyph.phone,
              primary: true,
              semanticLabel: 'Call the office',
              onPressed: () => tapped.add('call'),
            ),
            PillAction(label: 'Map', onPressed: () => tapped.add('map')),
            const PillAction(label: 'Off', onPressed: null),
          ],
        ),
      );
      await tester.tap(find.text('Call'));
      await tester.tap(find.text('Map'));
      await tester.tap(find.text('Off'));
      expect(tapped, <String>['call', 'map']);
      expect(find.bySemanticsLabel('Call the office'), findsOneWidget);
      for (final Element button in find.byType(TextButton).evaluate()) {
        expect(
          tester.getSize(find.byWidget(button.widget)).height,
          greaterThanOrEqualTo(A11y.minTapTarget),
        );
      }
      handle.dispose();
    });

    testWidgets('scrolls rather than overflowing on every phone', (
      tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => PillButtonRow(
          actions: <PillAction>[
            for (final String label in <String>[
              'Call',
              'Directions',
              'Message',
              'Website',
              'Share',
            ])
              PillAction(
                label: label,
                glyph: TaytayGlyph.globe,
                onPressed: () {},
              ),
          ],
        ),
      );
    });
  });

  group('StatusLine', () {
    testWidgets('draws nothing without structured hours', (tester) async {
      await _pump(
        tester,
        StatusLine(hours: null, now: _manila(2026, 10, 20, 9)),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('open: says when it closes', (tester) async {
      await _pump(
        tester,
        StatusLine(hours: _weekdays, now: _manila(2026, 10, 20, 9, 5)),
      );
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Closes 5:00 PM'), findsOneWidget);
    });

    testWidgets('closed: says when it next opens', (tester) async {
      Future<String> next(DateTime now) async {
        await _pump(tester, StatusLine(hours: _weekdays, now: now));
        expect(find.text('Closed'), findsOneWidget);
        return tester.widgetList<Text>(find.byType(Text)).last.data ?? '';
      }

      // Tuesday 20 Oct 2026, 7:00 AM: later today.
      expect(await next(_manila(2026, 10, 20, 7)), 'Opens 8:00 AM today');
      // Tuesday at 5:00 PM sharp: closing time is closed.
      expect(await next(_manila(2026, 10, 20, 17)), 'Opens 8:00 AM tomorrow');
      // Friday evening and Saturday: Monday.
      expect(await next(_manila(2026, 10, 23, 18)), 'Opens 8:00 AM Monday');
      expect(await next(_manila(2026, 10, 24, 10)), 'Opens 8:00 AM Monday');
    });

    test('reads the Manila clock, not the phone timezone', () {
      // 01:30 UTC is 9:30 AM in Manila on a Tuesday.
      final OpenStatus status = _weekdays.statusAt(
        DateTime.utc(2026, 10, 20, 1, 30),
      );
      expect(status, isA<OpenNow>());
      // 10:00 UTC Tuesday is 6:00 PM in Manila: closed.
      expect(
        _weekdays.statusAt(DateTime.utc(2026, 10, 20, 10)),
        isA<ClosedNow>(),
      );
    });

    test('a week with no hours is closed with no next opening', () {
      final OpenStatus status = const WeeklyHours(
        <int, DayHours>{},
      ).statusAt(DateTime.utc(2026, 10, 20));
      expect(status, isA<ClosedNow>());
      expect((status as ClosedNow).nextOpening, isNull);
    });

    test('formats minutes the way ManilaTime writes a time', () {
      expect(StatusLine.formatMinutes(0), '12:00 AM');
      expect(StatusLine.formatMinutes(8 * 60), '8:00 AM');
      expect(StatusLine.formatMinutes(12 * 60 + 30), '12:30 PM');
      expect(StatusLine.formatMinutes(17 * 60), '5:00 PM');
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => StatusLine(
          hours: _weekdays,
          now: _manila(2026, 10, 23, 18),
          labels: StatusLineLabels(opensOn: (time, day) => '$_long $day'),
        ),
      );
    });
  });

  group('EmptyState', () {
    testWidgets('renders art, words and an optional action', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        EmptyState(
          title: 'Empty title',
          message: 'Empty message',
          actionLabel: 'Browse',
          onAction: () => taps++,
        ),
      );
      expect(find.text('Empty title'), findsOneWidget);
      expect(find.text('Empty message'), findsOneWidget);
      expect(find.byType(IllustrationArt), findsOneWidget);
      await tester.tap(find.text('Browse'));
      expect(taps, 1);

      await _pump(
        tester,
        const EmptyState(title: 'T', message: 'M', illustration: null),
      );
      expect(find.byType(IllustrationArt), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const EmptyState(
          title: _long,
          message: _long,
          actionLabel: _long,
          boxed: true,
        ),
      );
    });
  });

  group('ErrorState', () {
    testWidgets('offers Try again only when there is a retry', (tester) async {
      var retries = 0;
      await _pump(
        tester,
        ErrorState(
          title: 'Could not load',
          message: 'Check your connection.',
          offline: true,
          onRetry: () => retries++,
          details: const <Widget>[Text('Reference: abc')],
        ),
      );
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Reference: abc'), findsOneWidget);
      expect(find.byType(IllustrationArt), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);

      await _pump(tester, const ErrorState(title: 'Failed'));
      expect(find.text('Try again'), findsNothing);
      expect(find.byType(IllustrationArt), findsNothing);
      expect(find.byIcon(TaytayIcons.circleAlert), findsOneWidget);
    });

    testWidgets('OfflineError is drawn as the offline ErrorState', (
      tester,
    ) async {
      await _pump(tester, OfflineError(onRetry: () {}));
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => ErrorState(
          title: _long,
          message: _long,
          offline: true,
          boxed: true,
          onRetry: () {},
        ),
      );
    });
  });

  group('LoadingSkeleton', () {
    testWidgets('is announced once and draws every layout', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final SkeletonLayout layout in SkeletonLayout.values) {
        await _pump(tester, LoadingSkeleton(layout: layout, count: 2));
        expect(find.bySemanticsLabel('Loading'), findsOneWidget);
        expect(find.byType(SkeletonBlock), findsWidgets);
      }
      handle.dispose();
    });

    testWidgets('fits every phone', (tester) async {
      for (final SkeletonLayout layout in SkeletonLayout.values) {
        await expectCleanLayouts(tester, () => LoadingSkeleton(layout: layout));
      }
    });
  });

  group('OfflineNotice', () {
    testWidgets('renders its two lines and an optional retry', (tester) async {
      var retries = 0;
      await _pump(
        tester,
        OfflineNotice(
          title: 'Offline',
          message: 'Showing saved data',
          retryLabel: 'Try again',
          onRetry: () => retries++,
        ),
      );
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Showing saved data'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      expect(_hasShadow(tester, find.byType(OfflineNotice)), isFalse);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => OfflineNotice(
          title: _long,
          message: _long,
          retryLabel: 'Try again',
          onRetry: () {},
        ),
      );
    });
  });

  group('FeedRow', () {
    testWidgets('renders category, title, date and a thumbnail', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        Column(
          children: <Widget>[
            FeedRow(
              category: 'CATEGORY',
              categoryTone: CategoryTone.red,
              title: 'Row title',
              dateLabel: 'Date',
              thumbnail: Image.memory(_png, fit: BoxFit.cover),
              onTap: () => taps++,
            ),
            const FeedRow(
              title: 'Placeholder row',
              placeholderGlyph: TaytayGlyph.megaphone,
              divider: true,
            ),
            const FeedRow(title: 'Bare row'),
          ],
        ),
      );
      final Text category = tester.widget<Text>(find.text('CATEGORY'));
      expect(category.style?.color, BrandColors.redInk);
      expect(find.text('Date'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(GlyphIcon), findsOneWidget);
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(FeedRow).first,
            matching: find.byType(ClipRRect),
          ),
        ),
        const Size.square(FeedRow.thumbnailSize),
      );
      await tester.tap(find.text('Row title'));
      expect(taps, 1);
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => FeedRow(
          category: _long,
          title: _long,
          dateLabel: _long,
          placeholderGlyph: TaytayGlyph.document,
          onTap: () {},
        ),
      );
    });
  });

  group('PhotoCarousel', () {
    List<CarouselPhoto> photos(int n) => <CarouselPhoto>[
      for (var i = 0; i < n; i++)
        CarouselPhoto.provider(MemoryImage(_png), semanticLabel: 'Photo $i'),
    ];

    testWidgets('draws nothing for no photos and no dots for one', (
      tester,
    ) async {
      await _pump(tester, PhotoCarousel(photos: photos(0)));
      expect(find.byType(PageView), findsNothing);
      await _pump(tester, PhotoCarousel(photos: photos(1)));
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('names each photo, swipes, and moves the dot', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<int> pages = <int>[];
      final List<int> taps = <int>[];
      await _pump(
        tester,
        PhotoCarousel(
          photos: photos(3),
          height: 200,
          onPageChanged: pages.add,
          onTap: taps.add,
          overlayBuilder: (context, index) => Text('Overlay $index'),
        ),
      );
      expect(find.bySemanticsLabel('Photo 0'), findsOneWidget);
      expect(find.text('Overlay 0'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
      // Each dot's box includes its 3 px margin either side.
      double widthOf(int i) =>
          tester.getSize(find.byType(AnimatedContainer).at(i)).width - 6;
      expect(widthOf(0), 22);

      await tester.tap(find.text('Overlay 0'));
      expect(taps, <int>[0]);

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(pages, <int>[1]);
      expect(widthOf(0), 7);
      expect(widthOf(1), 22);
      handle.dispose();
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => PhotoCarousel(photos: photos(4), viewportFraction: 0.86),
      );
    });
  });

  group('ConsentCheckCard', () {
    testWidgets('announces as a checkbox and reports a tap', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<bool> changes = <bool>[];
      await _pump(
        tester,
        ConsentCheckCard(
          value: false,
          onChanged: changes.add,
          label: 'I agree',
          description: 'What this covers',
        ),
      );
      expect(
        tester.getSemantics(find.byType(ConsentCheckCard)),
        isSemantics(
          label: 'I agree',
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
          isEnabled: true,
        ),
      );
      await tester.tap(find.text('I agree'));
      expect(changes, <bool>[true]);

      await _pump(
        tester,
        const ConsentCheckCard(value: true, onChanged: null, label: 'Locked'),
      );
      expect(
        tester.getSemantics(find.byType(ConsentCheckCard)),
        isSemantics(isChecked: true, isEnabled: false),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => ConsentCheckCard(
          value: true,
          onChanged: (_) {},
          label: _long,
          description: _long,
        ),
      );
    });
  });

  group('SuccessScreen', () {
    Widget screen({VoidCallback? onPrimary, VoidCallback? onSecondary}) =>
        SuccessScreen(
          title: 'Sent title',
          message: 'Sent message',
          details: const <SuccessDetail>[
            SuccessDetail(label: 'To', value: 'Office'),
          ],
          note: 'Receipt note',
          body: const Text('Extra body'),
          primaryLabel: 'Primary',
          onPrimary: onPrimary,
          secondaryLabel: 'Secondary',
          onSecondary: onSecondary,
          mark: SuccessMarkStyle.medal,
          stepLabel: 'Step 6 of 6',
          progress: 1,
        );

    testWidgets('renders its data and both actions', (tester) async {
      final List<String> taps = <String>[];
      await tester.pumpWidget(
        layoutHost(
          screen(
            onPrimary: () => taps.add('primary'),
            onSecondary: () => taps.add('secondary'),
          ),
          scrollable: false,
        ),
      );
      for (final String text in <String>[
        'Sent title',
        'Sent message',
        'To',
        'Office',
        'Receipt note',
        'Extra body',
        'Step 6 of 6',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byType(SuccessMark), findsOneWidget);
      await tester.tap(find.text('Primary'));
      await tester.tap(find.text('Secondary'));
      expect(taps, <String>['primary', 'secondary']);
    });

    testWidgets('fits every phone, scrolling its body at 200%', (tester) async {
      await expectCleanLayouts(
        tester,
        () => SuccessScreen(
          title: _long,
          message: _long,
          details: const <SuccessDetail>[
            SuccessDetail(label: _long, value: _long),
          ],
          note: _long,
          primaryLabel: 'Primary',
          onPrimary: () {},
          secondaryLabel: 'Secondary',
          onSecondary: () {},
        ),
        scrollable: false,
      );
    });
  });
}
