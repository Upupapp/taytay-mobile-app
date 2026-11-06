@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/features/auth/presentation/account_wizard_screen.dart';

/// Stills of the registration wizard in the order the Node API needs, at
/// 390×844 @3×, for the demo video. Fictional sample data only. Not part of
/// `flutter test`.
///
/// ```
/// TAYTAY_FRAMES_DIR=/path/to/frames flutter test --tags recording \n///   --run-skipped test/recording/registration_frames_test.dart
/// ```
///
/// Without `TAYTAY_FRAMES_DIR` the frames go to the system temp folder.
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

const ValueKey<String> _frame = ValueKey<String>('registration-frame');

/// Wraps the navigator, so a modal sheet is inside the captured boundary.
Future<void> _show(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? navigator) =>
          RepaintBoundary(key: _frame, child: navigator),
      home: child,
    ),
  );
  await tester.pump();
  final images = find.byType(Image);
  if (images.evaluate().isNotEmpty) {
    final context = tester.element(images.first);
    for (final element in images.evaluate()) {
      final widget = element.widget;
      if (widget is Image) {
        await tester.runAsync(() => precacheImage(widget.image, context));
      }
    }
    await tester.pump();
  }
}

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary =
      tester.renderObject(find.byKey(_frame)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('registration wizard frames for the demo video', (tester) async {
    addTearDown(tester.view.reset);
    final String? configured = Platform.environment['TAYTAY_FRAMES_DIR'];
    final out = Directory(
      configured != null && configured.isNotEmpty
          ? configured
          : '${Directory.systemTemp.path}/taytay_registration_frames',
    );
    out.createSync(recursive: true);

    debugDisableShadows = false;
    try {
      final frames = <(String, AccountFixture)>[
        ('01-personal', AccountFixture.personal),
        ('03-account', AccountFixture.account),
        ('04-email-code', AccountFixture.code),
        ('05-terms', AccountFixture.terms),
        ('06-id-upload', AccountFixture.idCard),
        ('07-selfie', AccountFixture.selfie),
        ('08-review', AccountFixture.review),
        ('09-pending', AccountFixture.submitted),
        ('10-code-not-sent', AccountFixture.codeNotSent),
      ];
      for (final (String name, AccountFixture fixture) in frames) {
        await _show(
          tester,
          AccountWizardScreen(key: ValueKey<String>(name), fixture: fixture),
        );
        await _capture(tester, '${out.path}/$name.png');
      }

      // The barangay picker, open over the personal step.
      await _show(
        tester,
        const AccountWizardScreen(
          key: ValueKey<String>('02-barangay-picker'),
          fixture: AccountFixture.personal,
        ),
      );
      await tester.tap(find.byKey(const Key('barangay-picker')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Choose your barangay'), findsOneWidget);
      await _capture(tester, '${out.path}/02-barangay-picker.png');
    } finally {
      debugDisableShadows = true;
    }

    expect(
      out.listSync().whereType<File>().where((f) => f.path.endsWith('.png')),
      hasLength(greaterThanOrEqualTo(10)),
    );
  });
}
