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

Future<img.Image> paintDigitalId(WidgetTester tester) async {
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
    final img.Image? decoded = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final img.Image? parsed = img.decodePng(data!.buffer.asUint8List());
      if (parsed == null) {
        throw StateError('The digital ID frame did not decode.');
      }
      return parsed;
    });
    if (decoded == null) {
      throw StateError('The digital ID frame did not decode.');
    }
    return decoded;
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the wired digital ID screen matches the not-issued card', (
    tester,
  ) async {
    const afterPath = 'test/goldens/compare/backend-fixes/after/digital_id.png';
    final img.Image rendered = await paintDigitalId(tester);
    if (autoUpdateGoldenFiles) {
      final File file = File(afterPath);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(img.encodePng(rendered));
    }

    final img.Image? committed = img.decodePng(
      File(afterPath).readAsBytesSync(),
    );
    expect(committed, isNotNull);
    final report = compareImages(committed!, rendered);
    expect(report.sameSize, isTrue);
    expect(report.mismatchPercent, 0);
  });
}
