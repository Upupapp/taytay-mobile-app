import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/features/auth/presentation/account_wizard_screen.dart';
import 'package:taytay_resident/features/auth/presentation/forgot_password_screen.dart';
import 'package:taytay_resident/features/auth/presentation/reset_flow_screens.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';

/// Every tappable control on `02-01` through `02-13` is at least 48 dp.
void main() {
  final screens = <String, Widget>{
    '02-01': const SignInScreen(fixture: SignInFixture.design),
    '02-02': const ForgotPasswordScreen(fixture: true),
    '02-02b': const ResetCodeScreen(fixture: ResetCodeFixture.sample),
    '02-03': const AccountWizardScreen(fixture: AccountFixture.personal),
    '02-04': const AccountWizardScreen(fixture: AccountFixture.code),
    '02-04b': const AccountWizardScreen(fixture: AccountFixture.codeExpired),
    '02-05': const AccountWizardScreen(fixture: AccountFixture.terms),
    '02-06': const AccountWizardScreen(fixture: AccountFixture.idCard),
    '02-07': const AccountWizardScreen(fixture: AccountFixture.selfie),
    '02-08': const AccountWizardScreen(fixture: AccountFixture.review),
    '02-09': const AccountWizardScreen(fixture: AccountFixture.submitted),
    '02-10': const SignInScreen(fixture: SignInFixture.error),
    '02-11': const AccountWizardScreen(fixture: AccountFixture.errors),
    '02-12': const SetPasswordScreen(fixture: SetPasswordFixture.mismatch),
    '02-12b': const SetPasswordScreen(fixture: SetPasswordFixture.expired),
    '02-13': const PasswordUpdatedScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} tap targets are at least 48 dp', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = FakeViewPadding.zero;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: entry.value,
        ),
      );
      await tester.pump();

      final small = <String>[];
      final controls = <Element>[
        ...find.byType(ButtonStyleButton).evaluate(),
        ...find.byType(InkWell).evaluate(),
      ];
      expect(controls, isNotEmpty, reason: '${entry.key} has no controls');
      for (final element in controls) {
        final box = element.renderObject;
        if (box is! RenderBox || !box.hasSize) continue;
        final size = box.size;
        if (size.width < 48 || size.height < 48) {
          small.add(
            '${element.widget.runtimeType} ${size.width}x${size.height}',
          );
        }
      }
      expect(small, isEmpty, reason: '${entry.key} under 48 dp: $small');
    });
  }
}
