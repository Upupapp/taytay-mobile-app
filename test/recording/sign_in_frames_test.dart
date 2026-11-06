@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/features/auth/presentation/account_wizard_screen.dart';
import 'package:taytay_resident/features/auth/presentation/forgot_password_screen.dart';
import 'package:taytay_resident/features/auth/presentation/reset_flow_screens.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';
import 'package:taytay_resident/features/auth/presentation/too_many_attempts_screen.dart';

import '../features/auth_screens_test.dart' show boot;
import '../features/auth_session_test.dart' show FakeAuthRepository;

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
    if (out.existsSync()) out.deleteSync(recursive: true);
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

  testWidgets(
    'capture 02-02b, 02-04b, 02-12, 02-12b, 02-13, 02-14 and 02-14b',
    (tester) async {
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
        (
          '02-14',
          const TooManyAttemptsScreen(
            key: ValueKey('02-14'),
            fixture: TooManyFixture.waiting,
          ),
        ),
        (
          '02-14b',
          const TooManyAttemptsScreen(
            key: ValueKey('02-14b'),
            fixture: TooManyFixture.ready,
          ),
        ),
      ];
      for (final frame in frames) {
        await _paint(tester, frame.$2, '${out.path}/${frame.$1}.png');
      }
    },
  );

  testWidgets('wizard frames for the flow recording', (tester) async {
    final out = Directory('/tmp/s2_wizard_frames');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    final steps = <AccountFixture>[
      AccountFixture.personal,
      AccountFixture.account,
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
    expect(index, 64);
  });

  testWidgets('reset frames for the flow recording', (tester) async {
    final out = Directory('/tmp/s2_reset_frames');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    final frames = <Widget>[
      const ForgotPasswordScreen(key: ValueKey('reset-0'), fixture: true),
      const ResetCodeScreen(
        key: ValueKey('reset-1'),
        fixture: ResetCodeFixture.sample,
      ),
      const SetPasswordScreen(
        key: ValueKey('reset-2'),
        fixture: SetPasswordFixture.mismatch,
      ),
      const SetPasswordScreen(
        key: ValueKey('reset-3'),
        fixture: SetPasswordFixture.expired,
      ),
      const PasswordUpdatedScreen(key: ValueKey('reset-4')),
      const TooManyAttemptsScreen(
        key: ValueKey('reset-5'),
        fixture: TooManyFixture.waiting,
      ),
      const TooManyAttemptsScreen(
        key: ValueKey('reset-6'),
        fixture: TooManyFixture.ready,
      ),
    ];
    var index = 0;
    for (var scene = 0; scene < frames.length; scene++) {
      // 02-14 holds for 2s and the clock steps from 14:32 to 14:31.
      final bool clock = scene == 5;
      final int count = clock ? 16 : 8;
      for (var hold = 0; hold < count; hold++) {
        final Widget painted = clock
            ? TooManyAttemptsScreen(
                key: ValueKey<String>('reset-5-$hold'),
                fixture: TooManyFixture.waiting,
                shownRemaining: Duration(
                  minutes: 14,
                  seconds: hold < 8 ? 32 : 31,
                ),
              )
            : frames[scene];
        final name = index.toString().padLeft(4, '0');
        await _paint(tester, painted, '${out.path}/f_$name.png');
        index++;
      }
    }
    expect(index, 64);
  });

  testWidgets('wizard flow with motion and taps', (tester) async {
    final out = Directory('/tmp/s2_wizard_motion');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final auth = FakeAuthRepository();
    await boot(tester, auth: auth, documentPicker: _RecordingPicker());
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    await tester.pump();

    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);
    debugDisableShadows = false;

    var frame = 0;
    Future<void> hold(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final name = frame.toString().padLeft(4, '0');
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${out.path}/f_$name.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        frame++;
      }
    }

    Future<void> tapText(String label) async {
      final finder = find.text(label);
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(finder);
      await hold(8);
    }

    try {
      // Navigate without pumpAndSettle: a live speck never goes idle.
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).goNamed('register');
      await hold(12);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Juana');
      await tester.enterText(fields.at(1), 'Dela Cruz');
      await tester.enterText(fields.at(2), '09171234567');
      await tester.enterText(fields.at(3), 'Purok 3');
      await tester.tap(find.byKey(const Key('barangay-picker')));
      await hold(8);
      await tapText('San Juan');
      await hold(6);
      await tapText('Continue');

      final account = find.byType(TextFormField);
      await tester.enterText(account.at(0), 'juana.delacruz@example.com');
      await tester.enterText(account.at(1), 'Password1!');
      await hold(8);
      await tapText('Create my account');

      await tester.enterText(
        find.byKey(const Key('email-code-field')),
        '482190',
      );
      await hold(8);
      await tapText('Confirm email');

      await tapText(
        'I have read and agree to the Terms of Use and the Privacy Notice.',
      );
      await tapText(
        'I consent to Taytay LGU processing my personal data for account verification.',
      );
      await tapText('Continue');

      await tester.tap(find.byKey(const Key('id-front-pick')));
      await hold(8);
      await tapText('Continue');

      await tapText('Take selfie');
      await tapText('Continue');

      expect(find.text('Check your details'), findsOneWidget);
      await hold(10);
      await tapText('Submit for verification');
      expect(find.text("You're all set, Juana!"), findsOneWidget);
      await hold(24);
      expect(frame, greaterThan(40));
    } finally {
      debugDisableShadows = true;
    }
  });
}

class _RecordingPicker implements DocumentPicker {
  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async {
    return CapturedDocument(
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      fileName: 'id_front.jpg',
      mimeType: 'image/jpeg',
      source: source,
    );
  }

  @override
  bool supports(DocumentSource source) => true;
}
