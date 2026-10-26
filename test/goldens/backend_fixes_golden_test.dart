import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_screen.dart';

import '../../tool/golden_compare.dart';

/// 390×844 logical points at 3×, written as 1170×2532 PNG.
const Size _frame = Size(390, 844);

Future<void> _loadFonts() async {
  final jakarta = FontLoader('Plus Jakarta Sans');
  for (final file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

Future<void> paintDigitalId(WidgetTester tester, String path) async {
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: _frame,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RepaintBoundary(
          key: ValueKey<String>('backend-fix-frame'),
          child: DigitalIdScreen(),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      tester.renderObject(
            find.byKey(const ValueKey<String>('backend-fix-frame')),
          )
          as RenderRepaintBoundary;
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the wired digital ID screen matches the not-issued card', (
    tester,
  ) async {
    const beforePath =
        'test/goldens/compare/backend-fixes/before/digital_id.png';
    const afterPath = 'test/goldens/compare/backend-fixes/after/digital_id.png';
    await paintDigitalId(tester, afterPath);

    final img.Image? before = img.decodePng(File(beforePath).readAsBytesSync());
    final img.Image? after = img.decodePng(File(afterPath).readAsBytesSync());
    expect(before, isNotNull);
    expect(after, isNotNull);
    final report = compareImages(before!, after!);
    expect(report.sameSize, isTrue);
    expect(report.mismatchPercent, 0);
  });
}
