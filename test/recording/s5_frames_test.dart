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
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Stills of `05-01` through `05-23` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s5_frames_test.dart`
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
          key: const ValueKey<String>('s5-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s5-frame')))
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
  const _Phone({required this.child, required this.showBar});

  final Widget child;
  final bool showBar;

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
                padding: EdgeInsets.only(
                  bottom: showBar ? ShellTabBar.barHeight : 0,
                ),
                child: child,
              ),
            ),
            if (showBar)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ShellTabBar(selectedIndex: 1, onSelected: _ignore),
              ),
          ],
        ),
      ),
    );
  }
}

void _ignore(int index) {}

void main() {
  setUpAll(_loadFonts);

  testWidgets('paint 05-01 through 05-23', (tester) async {
    final Directory out = Directory('/tmp/s5_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    final ({String dayLabel, List<DirectoryThreadBubble> messages}) thread =
        await OfficeCatalogue.thread();
    Office office(String id) =>
        catalogue.offices.singleWhere((Office item) => item.id == id);

    Future<void> frame({
      required String name,
      required DirectoryFrame kind,
      Office? current,
      bool bar = true,
    }) {
      return _paint(
        tester,
        _Phone(
          showBar: bar,
          child: DirectoryCanvas(
            frame: kind,
            offices: catalogue.offices,
            chips: catalogue.chips,
            office: current,
            bubbles: thread.messages,
            dayLabel: thread.dayLabel,
            onHotlines: () {},
          ),
        ),
        '${out.path}/$name.png',
      );
    }

    await frame(name: '05-01', kind: DirectoryFrame.list);
    await frame(
      name: '05-02',
      kind: DirectoryFrame.detail,
      current: office('bplo'),
    );
    await frame(
      name: '05-03',
      kind: DirectoryFrame.compose,
      current: office('bplo'),
      bar: false,
    );
    await frame(
      name: '05-04',
      kind: DirectoryFrame.thread,
      current: office('bplo'),
      bar: false,
    );
    await frame(name: '05-05', kind: DirectoryFrame.searchSpecimen);
    await frame(name: '05-06', kind: DirectoryFrame.loading);
    await frame(name: '05-07', kind: DirectoryFrame.offline);
    await frame(
      name: '05-08',
      kind: DirectoryFrame.detail,
      current: office('mswdo'),
    );
    await frame(
      name: '05-09',
      kind: DirectoryFrame.detail,
      current: office('treasury'),
    );
    await frame(
      name: '05-10',
      kind: DirectoryFrame.detail,
      current: office('assessor'),
    );
    await frame(
      name: '05-11',
      kind: DirectoryFrame.detail,
      current: office('mdrrmo'),
    );
    await frame(
      name: '05-12',
      kind: DirectoryFrame.detail,
      current: office('peso'),
    );
    await frame(
      name: '05-13',
      kind: DirectoryFrame.detail,
      current: office('pio'),
    );
    await frame(
      name: '05-14',
      kind: DirectoryFrame.detail,
      current: office('tydo'),
    );
    await frame(
      name: '05-15',
      kind: DirectoryFrame.detail,
      current: office('health'),
    );
    await frame(name: '05-16', kind: DirectoryFrame.sent);
    await frame(
      name: '05-17',
      kind: DirectoryFrame.compose,
      current: office('mswdo'),
      bar: false,
    );
    await frame(
      name: '05-18',
      kind: DirectoryFrame.compose,
      current: office('treasury'),
      bar: false,
    );
    await frame(
      name: '05-19',
      kind: DirectoryFrame.compose,
      current: office('assessor'),
      bar: false,
    );
    await frame(
      name: '05-20',
      kind: DirectoryFrame.compose,
      current: office('peso'),
      bar: false,
    );
    await frame(
      name: '05-21',
      kind: DirectoryFrame.compose,
      current: office('pio'),
      bar: false,
    );
    await frame(
      name: '05-22',
      kind: DirectoryFrame.compose,
      current: office('tydo'),
      bar: false,
    );
    await frame(
      name: '05-23',
      kind: DirectoryFrame.compose,
      current: office('health'),
      bar: false,
    );

    expect(out.listSync().length, 23);
  });
}
