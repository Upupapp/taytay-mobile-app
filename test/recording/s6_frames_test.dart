@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/mock_data/data/mock/taytay_mocks.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Stills of `06-01` through `06-08` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s6_frames_test.dart`
Future<void> _loadFonts() async {
  final FontLoader jakarta = FontLoader('Plus Jakarta Sans');
  for (final String file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final FontLoader lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

Future<void> _paint(WidgetTester tester, Widget child, String path) async {
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: RepaintBoundary(
          key: const ValueKey<String>('s6-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s6-frame')))
          as RenderRepaintBoundary;
  try {
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      File(path).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _precache(WidgetTester tester) async {
  final Finder images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final BuildContext context = tester.element(images.first);
  for (final Element element in images.evaluate()) {
    final Widget widget = element.widget;
    if (widget is Image) {
      await tester.runAsync(() => precacheImage(widget.image, context));
    }
  }
  await tester.pump();
}

class _Phone extends StatelessWidget {
  const _Phone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 844,
      child: ColoredBox(
        color: BrandColors.surface,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: ShellTabBar.barHeight),
                child: child,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShellTabBar(selectedIndex: 2, onSelected: _ignore),
            ),
          ],
        ),
      ),
    );
  }
}

void _ignore(int index) {}

Future<List<Announcement>> _articles() async {
  final MockAnnouncementRepository repository = MockAnnouncementRepository(
    MockBehaviorController(
      latency: Duration.zero,
      failure: MockFailureMode.none,
    ),
  );
  final Result<Paginated<Announcement>> result = await repository
      .listAnnouncements(perPage: 20);
  return (result as Ok<Paginated<Announcement>>).value.items;
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('paint 06-01 through 06-08', (tester) async {
    final Directory out = Directory('/tmp/s6_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final List<Announcement> articles = await _articles();
    Announcement byId(String id) =>
        articles.singleWhere((Announcement item) => item.id == id);
    final Announcement pwd = byId('balita-pwd');
    final Announcement rpt = byId('balita-rpt');
    final Announcement boss = byId('balita-boss');
    final Announcement smile = byId('balita-smile');
    final Announcement weather = byId('balita-weather');

    Future<void> frame({
      required String name,
      required BalitaFrame kind,
      List<Announcement> stories = const <Announcement>[],
      Announcement? article,
      String chip = 'Lahat',
    }) {
      return _paint(
        tester,
        _Phone(
          child: BalitaCanvas(
            frame: kind,
            articles: stories,
            article: article,
            selectedChip: chip,
          ),
        ),
        '${out.path}/$name.png',
      );
    }

    await frame(
      name: '06-01',
      kind: BalitaFrame.feed,
      stories: <Announcement>[pwd, rpt, boss],
    );
    await frame(name: '06-02', kind: BalitaFrame.article, article: pwd);
    await frame(
      name: '06-03',
      kind: BalitaFrame.filter,
      chip: 'Advisory',
      stories: <Announcement>[rpt, smile, weather],
    );
    await frame(
      name: '06-04',
      kind: BalitaFrame.emptyCategory,
      chip: 'Events',
    );
    await frame(name: '06-05', kind: BalitaFrame.loading);
    await frame(name: '06-06', kind: BalitaFrame.article, article: rpt);
    await frame(name: '06-07', kind: BalitaFrame.article, article: boss);
    await frame(name: '06-08', kind: BalitaFrame.article, article: smile);

    expect(out.listSync().length, 8);
  });
}
