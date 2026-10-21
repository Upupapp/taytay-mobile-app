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
import 'package:taytay_resident/features/auth/presentation/forgot_password_screen.dart';
import 'package:taytay_resident/features/auth/presentation/reset_flow_screens.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';

/// Stills of `02-01` through `02-11` at 390×844 @3×, and a frame sequence of
/// the wizard. Not part of `flutter test`.
///
/// `flutter test --tags recording --run-skipped test/recording/sign_in_frames_test.dart`
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

Future<void> _paint(WidgetTester tester, Widget child, String path) async {
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: RepaintBoundary(
        key: const ValueKey<String>('s2-frame'),
        child: child,
      ),
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

  final boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s2-frame')))
          as RenderRepaintBoundary;
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture 02-01 through 02-11', (tester) async {
    final out = Directory('/tmp/s2_renders');
    out.createSync(recursive: true);
    final frames = <(String, Widget)>[
      (
        '02-01',
        const SignInScreen(
          key: ValueKey('02-01'),
          fixture: SignInFixture.design,
        ),
      ),
      (
        '02-02',
        const ForgotPasswordScreen(key: ValueKey('02-02'), fixture: true),
      ),
      (
        '02-03',
        const AccountWizardScreen(
          key: ValueKey('02-03'),
          fixture: AccountFixture.personal,
        ),
      ),
      (
        '02-04',
        const AccountWizardScreen(
          key: ValueKey('02-04'),
          fixture: AccountFixture.code,
        ),
      ),
      (
        '02-05',
        const AccountWizardScreen(
          key: ValueKey('02-05'),
          fixture: AccountFixture.terms,
        ),
      ),
      (
        '02-06',
        const AccountWizardScreen(
          key: ValueKey('02-06'),
          fixture: AccountFixture.idCard,
        ),
      ),
      (
        '02-07',
        const AccountWizardScreen(
          key: ValueKey('02-07'),
          fixture: AccountFixture.selfie,
        ),
      ),
      (
        '02-08',
        const AccountWizardScreen(
          key: ValueKey('02-08'),
          fixture: AccountFixture.review,
        ),
      ),
      (
        '02-09',
        const AccountWizardScreen(
          key: ValueKey('02-09'),
          fixture: AccountFixture.submitted,
        ),
      ),
      (
        '02-10',
        const SignInScreen(
          key: ValueKey('02-10'),
          fixture: SignInFixture.error,
        ),
      ),
      (
        '02-11',
        const AccountWizardScreen(
          key: ValueKey('02-11'),
          fixture: AccountFixture.errors,
        ),
      ),
    ];
    for (final frame in frames) {
      await _paint(tester, frame.$2, '${out.path}/${frame.$1}.png');
    }
    expect(out.listSync().length, 11);
  });

  testWidgets('capture 02-02b, 02-04b, 02-12, 02-12b and 02-13', (
    tester,
  ) async {
    final out = Directory('/tmp/s2_renders');
    out.createSync(recursive: true);
    final frames = <(String, Widget)>[
      (
        '02-02b',
        const ResetCodeScreen(
          key: ValueKey('02-02b'),
          fixture: ResetCodeFixture.sample,
        ),
      ),
      (
        '02-04b',
        const AccountWizardScreen(
          key: ValueKey('02-04b'),
          fixture: AccountFixture.codeExpired,
        ),
      ),
      (
        '02-12',
        const SetPasswordScreen(
          key: ValueKey('02-12'),
          fixture: SetPasswordFixture.mismatch,
        ),
      ),
      (
        '02-12b',
        const SetPasswordScreen(
          key: ValueKey('02-12b'),
          fixture: SetPasswordFixture.expired,
        ),
      ),
      ('02-13', const PasswordUpdatedScreen(key: ValueKey('02-13'))),
    ];
    for (final frame in frames) {
      await _paint(tester, frame.$2, '${out.path}/${frame.$1}.png');
    }
  });

  testWidgets('wizard frames for the flow recording', (tester) async {
    final out = Directory('/tmp/s2_wizard_frames');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    final steps = <AccountFixture>[
      AccountFixture.personal,
      AccountFixture.code,
      AccountFixture.terms,
      AccountFixture.idCard,
      AccountFixture.selfie,
      AccountFixture.review,
      AccountFixture.submitted,
    ];
    var index = 0;
    for (final step in steps) {
      for (var hold = 0; hold < 8; hold++) {
        final name = index.toString().padLeft(4, '0');
        await _paint(
          tester,
          AccountWizardScreen(key: ValueKey<String>(name), fixture: step),
          '${out.path}/f_$name.png',
        );
        index++;
      }
    }
    expect(index, 56);
  });
}
