import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/auth/presentation/account_wizard_screen.dart';
import 'package:taytay_resident/features/auth/presentation/forgot_password_screen.dart';
import 'package:taytay_resident/features/auth/presentation/reset_flow_screens.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';
import 'package:taytay_resident/features/onboarding/presentation/welcome_scene.dart';
import 'package:taytay_resident/features/profile/domain/name_lock.dart';
import 'package:taytay_resident/features/splash/presentation/splash_screen.dart';
import 'package:taytay_resident/l10n/app_localizations_en.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/consent_check_card.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';
import 'package:taytay_resident/shared/widgets/success_screen.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../support/layout_matrix.dart';

/// Phase 3 batch P3a: the redesigned splash, welcome and sign-in screens fit
/// 360, 375 and 430 wide at normal and 200% text, and keep what they must
/// say.
void main() {
  final List<WelcomePageCopy> scenes = WelcomePageCopy.fromStrings(
    AppStringsEn(),
  );

  Widget welcome(int page) => WelcomeCanvas(
    page: page,
    pageCount: scenes.length,
    copy: scenes[page],
    onSkip: () {},
    onNext: () {},
    onBack: () {},
    onGetStarted: () {},
    onGuest: () {},
  );

  group('welcome (Main.dc.html)', () {
    for (var page = 0; page < 3; page++) {
      testWidgets('page ${page + 1} fits every phone and 200% text', (
        tester,
      ) async {
        await expectCleanLayouts(
          tester,
          () => welcome(page),
          scrollable: false,
          frames: 2,
        );
      });
    }

    testWidgets('the photo zone holds the seal, Skip and the wave', (
      tester,
    ) async {
      await tester.pumpWidget(layoutHost(welcome(0), scrollable: false));
      expect(find.byType(HeaderSeal), findsOneWidget);
      expect(find.text('Bayan ng Taytay'), findsOneWidget);
      expect(find.text('Lalawigan ng Rizal'), findsOneWidget);
      expect(find.byKey(welcomeSkipTargetKey), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter is WavePainter &&
              (w.painter! as WavePainter).layers == WelcomeShapes.layers,
        ),
        findsOneWidget,
      );
      // The photo's CC BY-SA credit stays on the photo.
      expect(find.text(scenes[0].credit), findsOneWidget);
      // Next is the 64 px gold disc, named for screen readers.
      expect(tester.getSize(find.byKey(welcomeNextKey)), const Size(64, 64));
      expect(find.bySemanticsLabel(scenes[0].nextLabel), findsOneWidget);
      // No back control on the first page.
      expect(find.byType(TaytayBackButton), findsNothing);
    });

    testWidgets('the last page offers both ways in at equal weight', (
      tester,
    ) async {
      await tester.pumpWidget(layoutHost(welcome(2), scrollable: false));
      expect(find.byKey(welcomeNextKey), findsNothing);
      expect(find.text(scenes[2].getStartedLabel), findsOneWidget);
      expect(find.text(scenes[2].guestLabel), findsOneWidget);
      expect(find.text(scenes[2].guestNote), findsOneWidget);
      final Size started = tester.getSize(
        find
            .ancestor(
              of: find.text(scenes[2].getStartedLabel),
              matching: find.byType(Material),
            )
            .first,
      );
      final Size guest = tester.getSize(
        find
            .ancestor(
              of: find.text(scenes[2].guestLabel),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(guest, started);
    });

    testWidgets('nothing on the welcome casts a shadow', (tester) async {
      await tester.pumpWidget(layoutHost(welcome(0), scrollable: false));
      for (final Element element in find.byType(Material).evaluate()) {
        expect((element.widget as Material).elevation, 0);
      }
      for (final Element element in find.byType(DecoratedBox).evaluate()) {
        final Decoration decoration =
            (element.widget as DecoratedBox).decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.boxShadow, anyOf(isNull, isEmpty));
        }
      }
    });
  });

  group('splash', () {
    testWidgets('fits every phone and 200% text', (tester) async {
      final AppDependencies dependencies = AppDependencies.build(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
          rawDataMode: 'mock',
          rawMockLatencyMs: '0',
        ),
        secrets: InMemorySecretStore(),
        sessionStore: InMemorySessionStore(),
      );
      addTearDown(dependencies.dispose);
      await expectCleanLayouts(
        tester,
        () => AppDependenciesScope(
          dependencies: dependencies,
          child: const SplashScreen(),
        ),
        scrollable: false,
      );
      // The splash holds on a timer; let it run out.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    });
  });

  group('sign-in and password reset (SignIn.dc.html)', () {
    final Map<String, Widget Function()> screens = <String, Widget Function()>{
      'sign-in': () => const SignInScreen(fixture: SignInFixture.design),
      'sign-in refused': () => const SignInScreen(fixture: SignInFixture.error),
      'forgot password': () => const ForgotPasswordScreen(fixture: true),
      'reset code': () =>
          const ResetCodeScreen(fixture: ResetCodeFixture.sample),
      'new password, mismatch': () =>
          const SetPasswordScreen(fixture: SetPasswordFixture.mismatch),
      'new password, expired': () =>
          const SetPasswordScreen(fixture: SetPasswordFixture.expired),
      'password updated': () => const PasswordUpdatedScreen(),
    };
    for (final MapEntry<String, Widget Function()> entry in screens.entries) {
      testWidgets('${entry.key} fits every phone and 200% text', (
        tester,
      ) async {
        await expectCleanLayouts(
          tester,
          entry.value,
          scrollable: false,
          frames: 2,
        );
      });
    }

    testWidgets('sign-in is a wave header over a white form page', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const SignInScreen(fixture: SignInFixture.error),
          scrollable: false,
        ),
      );
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.byType(HeaderSeal), findsOneWidget);
      expect(find.text('Bayan ng Taytay · Lalawigan ng Rizal'), findsOneWidget);
      // The refusal is a red note, and it names no account.
      expect(
        find.byWidgetPredicate(
          (w) => w is SoftNote && w.tone == NoteTone.error,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Incorrect email or password'),
        findsOneWidget,
      );
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);
      for (final Element element in find.byType(Material).evaluate()) {
        expect((element.widget as Material).elevation, 0);
      }
    });

    testWidgets('password updated is the success screen with a way back', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(const PasswordUpdatedScreen(), scrollable: false),
      );
      expect(find.byType(SuccessScreen), findsOneWidget);
      expect(find.byType(TaytayBackButton), findsOneWidget);
      expect(find.text('Mag-sign in'), findsOneWidget);
    });
  });

  group('SoftNote', () {
    testWidgets('each tone has its own icon and no shadow', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const Column(
          children: <Widget>[
            SoftNote(message: 'Info sentence that may wrap on a phone.'),
            SoftNote(tone: NoteTone.warning, title: 'Wait. ', message: 'x'),
            SoftNote(tone: NoteTone.error, title: 'Failed. ', message: 'y'),
            SoftNote(tone: NoteTone.success, message: 'Done.'),
          ],
        ),
      );
      await tester.pumpWidget(
        layoutHost(
          const SoftNote(tone: NoteTone.error, title: 'A. ', message: 'B'),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Error')), findsOneWidget);
      expect(find.text('A. B'), findsOneWidget);
    });
  });

  group('registration (RegDetails … RegDone)', () {
    for (final AccountFixture fixture in AccountFixture.values) {
      if (fixture == AccountFixture.live) continue;
      testWidgets('${fixture.name} fits every phone and 200% text', (
        tester,
      ) async {
        await expectCleanLayouts(
          tester,
          () => AccountWizardScreen(fixture: fixture),
          scrollable: false,
          frames: 2,
        );
      });
    }

    testWidgets('a step is a wave header with the step and its bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountWizardScreen(fixture: AccountFixture.terms),
          scrollable: false,
        ),
      );
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.text('Step 2 of 6'), findsOneWidget);
      expect(find.bySemanticsLabel('Create account progress'), findsWidgets);
      expect(find.byType(ConsentCheckCard), findsNWidgets(2));
      // The draft marker and the privacy notice's points stay.
      expect(
        find.text('DRAFT · LGU-approved Privacy Notice to be inserted'),
        findsOneWidget,
      );
      expect(
        find.textContaining('National Privacy Commission'),
        findsOneWidget,
      );
    });

    testWidgets('the ID step says the ID must show the account name', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountWizardScreen(fixture: AccountFixture.idCard),
          scrollable: false,
        ),
      );
      expect(find.text(NameCheckCopy.beforeSendingTitle), findsOneWidget);
      expect(find.text(NameCheckCopy.beforeSending), findsOneWidget);
      expect(find.text('Juana Dela Cruz'), findsOneWidget);
    });

    testWidgets('submitted is the medal success screen, step 6 of 6', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountWizardScreen(fixture: AccountFixture.submitted),
          scrollable: false,
        ),
      );
      final SuccessScreen done = tester.widget<SuccessScreen>(
        find.byType(SuccessScreen),
      );
      expect(done.mark, SuccessMarkStyle.medal);
      expect(done.stepLabel, 'Step 6 of 6');
      expect(find.text("You're all set, Juana!"), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
    });
  });
}
