@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/features/tulong/data/mock_social_service_repository.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Stills of `07-01` through `07-12` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s7_frames_test.dart`
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
          key: const ValueKey<String>('s7-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s7-frame')))
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
              child: ShellTabBar(selectedIndex: 3, onSelected: _ignore),
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

  testWidgets('paint 07-01 through 07-12', (tester) async {
    final Directory out = Directory('/tmp/s7_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final MockSocialServiceRepository repository = MockSocialServiceRepository(
      MockBehaviorController(
        latency: Duration.zero,
        failure: MockFailureMode.none,
      ),
    );
    Future<SocialService> bySlug(String slug) async {
      final result = await repository.loadService(slug);
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => throw StateError(failure.debugMessage ?? slug),
      };
    }

    final SocialService pwd = await bySlug('pwd-assistance');
    final SocialService osca = await bySlug('senior-citizens');
    final SocialService solo = await bySlug('solo-parents');
    final SocialService aics = await bySlug('aics');
    final SocialService education = await bySlug('educational-assistance');
    final SocialService women = await bySlug('women-children');
    final SocialService peso = await bySlug('peso-jobs');
    final SocialService youth = await bySlug('youth');
    final SocialService gift = await bySlug('pwd-cash-gift');
    final List<SocialService> listed = <SocialService>[
      pwd,
      osca,
      solo,
      aics,
      education,
      women,
      peso,
      youth,
    ];
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    final Office mswdo = catalogue.offices.singleWhere(
      (Office office) => office.id == 'mswdo',
    );

    Future<void> frame(String name, Widget child) {
      return _paint(tester, _Phone(child: child), '${out.path}/$name.png');
    }

    await frame(
      '07-01',
      TulongCanvas(frame: TulongFrame.list, services: listed),
    );
    await frame(
      '07-02',
      TulongCanvas(frame: TulongFrame.detail, service: osca),
    );
    await frame(
      '07-03',
      DirectoryCanvas(
        frame: DirectoryFrame.detail,
        offices: const <Office>[],
        office: mswdo,
      ),
    );
    await frame(
      '07-04',
      TulongCanvas(frame: TulongFrame.detail, service: gift),
    );
    await frame(
      '07-05',
      TulongCanvas(
        frame: TulongFrame.offline,
        saved: <SocialService>[pwd, osca],
      ),
    );
    await frame('07-06', TulongCanvas(frame: TulongFrame.detail, service: pwd));
    await frame(
      '07-07',
      TulongCanvas(frame: TulongFrame.detail, service: solo),
    );
    await frame(
      '07-08',
      TulongCanvas(frame: TulongFrame.detail, service: aics),
    );
    await frame(
      '07-09',
      TulongCanvas(frame: TulongFrame.detail, service: education),
    );
    await frame(
      '07-10',
      TulongCanvas(frame: TulongFrame.detail, service: women),
    );
    await frame(
      '07-11',
      TulongCanvas(frame: TulongFrame.detail, service: peso),
    );
    await frame(
      '07-12',
      TulongCanvas(frame: TulongFrame.detail, service: youth),
    );
  });
}
