@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/home/data/home_catalogue.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_centre.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/municipal_header.dart';

/// Stills of `04-01` through `04-08` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s4_frames_test.dart`
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
          key: const ValueKey<String>('s4-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s4-frame')))
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

/// The phone frame the designs paint: page above a 90 dp bar, disc lifted
/// over it. No environment banner.
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
              child: ShellTabBar(selectedIndex: 0, onSelected: _ignore),
            ),
          ],
        ),
      ),
    );
  }
}

void _ignore(int index) {}

void _noop() {}

NoticeRow _notice({
  required String eyebrow,
  required String title,
  required String when,
  required bool unread,
  required Color tone,
  required Color tile,
  required IconData icon,
}) {
  return NoticeRow(
    eyebrow: eyebrow,
    title: title,
    when: when,
    unread: unread,
    tone: tone,
    tile: tile,
    icon: icon,
    onTap: _noop,
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture 04-01 through 04-08', (tester) async {
    final List<HomeSlide> slides = await HomeCatalogue.slides();
    final ({List<HomeNewsItem> news, List<HomeHotline> hotlines}) feed =
        await HomeCatalogue.mockFeed();
    final HomeHotline sagip = feed.hotlines.first;

    final Directory out = Directory('/tmp/s4_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    HomeCanvas home({
      required String greeting,
      required HomeStatusKind status,
      String initials = 'JD',
      int bellCount = 2,
      int initialSlide = 0,
      bool refreshing = false,
      bool newsAndHotline = true,
    }) {
      return HomeCanvas(
        key: ValueKey<String>(
          's4-${status.name}-$initials-$bellCount-$initialSlide-$refreshing',
        ),
        greeting: greeting,
        initials: initials,
        bellCount: bellCount,
        status: status,
        slides: slides,
        news: newsAndHotline && !refreshing
            ? feed.news
            : const <HomeNewsItem>[],
        hotline: newsAndHotline && !refreshing ? sagip : null,
        initialSlide: initialSlide,
        refreshing: refreshing,
      );
    }

    final List<(String, Widget)> frames = <(String, Widget)>[
      (
        '04-01',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Juana!',
            status: HomeStatusKind.none,
          ),
        ),
      ),
      (
        '04-02',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Juana!',
            status: HomeStatusKind.pending,
          ),
        ),
      ),
      (
        '04-03',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Bisita!',
            status: HomeStatusKind.guest,
            initials: '',
            bellCount: 0,
            newsAndHotline: true,
          ),
        ),
      ),
      (
        '04-04',
        _Phone(
          child: HotlinesCanvas(lines: feed.hotlines, onBack: _noop),
        ),
      ),
      (
        '04-05',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Juana!',
            status: HomeStatusKind.none,
            refreshing: true,
          ),
        ),
      ),
      (
        '04-06',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Juana!',
            status: HomeStatusKind.none,
            initialSlide: 1,
          ),
        ),
      ),
      (
        '04-07',
        _Phone(
          child: home(
            greeting: 'Magandang gabi, Juana!',
            status: HomeStatusKind.none,
            initialSlide: 2,
          ),
        ),
      ),
      (
        '04-08',
        _Phone(
          child: Column(
            children: <Widget>[
              const MunicipalHeader(
                title: 'Notifications',
                subtitle: 'Bayan ng Taytay · Rizal',
                onBack: _noop,
              ),
              Expanded(
                child: NotificationCentre(
                  showIllustration: true,
                  onMarkAllRead: _noop,
                  sections: <NoticeSection>[
                    NoticeSection(
                      heading: 'Today',
                      rows: <NoticeRow>[
                        _notice(
                          eyebrow: 'MESSAGE · BPLO',
                          title: 'New reply about your business permit renewal',
                          when: '9:05 AM',
                          unread: true,
                          tone: BrandColors.taytayBlue,
                          tile: const Color(0xFFEAF0FB),
                          icon: NoticeIcons.message,
                        ),
                        _notice(
                          eyebrow: 'VERIFICATION',
                          title: 'Your ID is being reviewed by Taytay LGU',
                          when: '8:12 AM',
                          unread: true,
                          tone: const Color(0xFF8A5A00),
                          tile: const Color(0xFFFFF4D6),
                          icon: NoticeIcons.verification,
                        ),
                      ],
                    ),
                    NoticeSection(
                      heading: 'Earlier',
                      rows: <NoticeRow>[
                        _notice(
                          eyebrow: 'ADVISORY · TREASURY',
                          title: 'Advisory for 2026 Real Property Tax Payment',
                          when: 'Oct 12',
                          unread: false,
                          tone: BrandColors.taytayBlue,
                          tile: const Color(0xFFEAF0FB),
                          icon: NoticeIcons.advisory,
                        ),
                        _notice(
                          eyebrow: 'ABISO · MSWDO',
                          title:
                              'Unclaimed 2026 PWD Cash Gift: payout at the Treasury Office',
                          when: 'Jul 30',
                          unread: false,
                          tone: BrandColors.success,
                          tile: const Color(0xFFE6F4EC),
                          icon: NoticeIcons.welfare,
                        ),
                        _notice(
                          eyebrow: 'SAFETY · PIO',
                          title:
                              'Get the SMILE SAFE Taytay app for emergency reports',
                          when: 'Mar 27',
                          unread: false,
                          tone: BrandColors.danger,
                          tile: const Color(0xFFFDECEC),
                          icon: NoticeIcons.safety,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    for (final (String name, Widget frame) in frames) {
      await _paint(tester, frame, '${out.path}/$name.png');
    }
  });
}
