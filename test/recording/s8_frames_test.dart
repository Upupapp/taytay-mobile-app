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
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Stills of `08-01` through `08-10` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s8_frames_test.dart`
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
          key: const ValueKey<String>('s8-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s8-frame')))
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
  const _Phone({required this.child, this.bar = true});

  final Widget child;
  final bool bar;

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
                  bottom: bar ? ShellTabBar.barHeight : 0,
                ),
                child: child,
              ),
            ),
            if (bar)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ShellTabBar(selectedIndex: 4, onSelected: _ignore),
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

  testWidgets('paint 08-01 through 08-10', (tester) async {
    final Directory out = Directory('/tmp/s8_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    Future<void> frame(String name, Widget child) {
      return _paint(tester, child, '${out.path}/$name.png');
    }

    await frame(
      '08-01',
      const _Phone(child: AccountCanvas(frame: AccountFrame.home)),
    );
    await frame(
      '08-02',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.inbox,
          title: 'Messages',
          showBack: true,
        ),
      ),
    );
    await frame(
      '08-03',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.editProfile,
          title: 'Edit profile',
          showBack: true,
          showBell: false,
        ),
      ),
    );
    await frame(
      '08-04',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.settings,
          title: 'Settings & privacy',
          showBack: true,
          showBell: false,
        ),
      ),
    );
    await frame(
      '08-05',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.about,
          title: 'Photo credits & about',
          showBack: true,
          showBell: false,
        ),
      ),
    );
    await frame(
      '08-06',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.inboxEmpty,
          title: 'Messages',
          showBack: true,
        ),
      ),
    );
    await frame(
      '08-07',
      const _Phone(
        bar: false,
        child: AccountCanvas(
          frame: AccountFrame.thread,
          title: 'MSWDO',
          subtitle: 'Municipal Social Welfare and Development Office',
          subtitleLines: 2,
          showBack: true,
          showBell: false,
          bubbles: AccountSpecimen.mswdoBubbles,
        ),
      ),
    );
    await frame(
      '08-08',
      const _Phone(
        bar: false,
        child: AccountCanvas(
          frame: AccountFrame.thread,
          title: 'Treasury',
          subtitle: "Municipal Treasurer's Office",
          showBack: true,
          showBell: false,
          bubbles: AccountSpecimen.treasurerBubbles,
          dayLabel: 'Mon',
        ),
      ),
    );
    await frame(
      '08-09',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.privacy,
          title: 'Privacy Notice',
          showBack: true,
          showBell: false,
        ),
      ),
    );
    await frame(
      '08-10',
      const _Phone(
        child: AccountCanvas(
          frame: AccountFrame.banners,
          title: 'Office banner photos',
          showBack: true,
          showBell: false,
        ),
      ),
    );
  });
}
