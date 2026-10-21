import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/features/auth/domain/account_application.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';
import 'package:taytay_resident/features/auth/domain/sign_in_challenge.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

import 'auth_screens_test.dart' show boot, goTo, reveal;
import 'auth_session_test.dart' show FakeAuthRepository;

const SessionState _guest = GuestSession();
const SessionState _unverified = AuthenticatedSession(
  ResidentSession(
    accountId: 'acct-sample',
    accessLevel: AccessLevel.unverified,
  ),
);
const SessionState _verified = AuthenticatedSession(
  ResidentSession(accountId: 'acct-sample', accessLevel: AccessLevel.verified),
);

class _Picker implements DocumentPicker {
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

Future<void> _fillPersonal(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Juana');
  await tester.enterText(fields.at(1), 'Dela Cruz');
  await tester.enterText(fields.at(2), 'juana.delacruz@example.com');
  await tester.enterText(fields.at(3), '0917 123 4567');
  await tester.enterText(fields.at(4), 'San Juan');
  await tester.enterText(fields.at(5), 'Purok 3');
  await tester.enterText(fields.at(6), 'Password1!');
}

void main() {
  group('access for sign-in and registration', () {
    test('a guest may open sign-in, register, and forgot password', () {
      for (final path in <String>[
        AppRoute.signIn.path,
        AppRoute.register.path,
        AppRoute.forgotPassword.path,
        AppRoute.resetCode.path,
        AppRoute.setPassword.path,
        AppRoute.passwordUpdated.path,
      ]) {
        expect(resolveRedirect(session: _guest, location: path), isNull);
      }
    });

    test('an authenticated resident is sent home from sign-in only', () {
      for (final session in <SessionState>[_unverified, _verified]) {
        expect(
          resolveRedirect(session: session, location: AppRoute.signIn.path),
          AppRoute.home.path,
          reason: session.accessLevel.name,
        );
        expect(
          resolveRedirect(session: session, location: AppRoute.register.path),
          isNull,
          reason: session.accessLevel.name,
        );
        for (final AppRoute route in <AppRoute>[
          AppRoute.forgotPassword,
          AppRoute.resetCode,
          AppRoute.setPassword,
          AppRoute.passwordUpdated,
        ]) {
          expect(
            resolveRedirect(session: session, location: route.path),
            isNull,
            reason: '${session.accessLevel.name} ${route.name}',
          );
        }
      }
    });
  });

  test('an application draft does not render its fields', () {
    const draft = AccountApplication(
      email: 'juana.delacruz@example.com',
      mobile: '09171234567',
      givenName: 'Juana',
      familyName: 'Dela Cruz',
    );
    final text = draft.toString();
    expect(text, contains('redacted'));
    expect(text, isNot(contains('Juana')));
    expect(text, isNot(contains('0917')));
    expect(text, isNot(contains('example.com')));
  });

  testWidgets('each empty personal field is named', (tester) async {
    await boot(tester);
    await goTo(tester, 'register');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Please fix'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);
    expect(
      find.text('Enter a valid email, e.g. name@example.com'),
      findsOneWidget,
    );
    expect(
      find.text('Enter an 11-digit mobile number starting with 09.'),
      findsOneWidget,
    );
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.textContaining('exploded'), findsNothing);
  });

  testWidgets('back keeps what was typed', (tester) async {
    await boot(tester);
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    expect(find.byType(TaytayBackButton), findsOneWidget);
    await tester.tap(find.text('Change email address'));
    await tester.pumpAndSettle();

    expect(find.text('Juana'), findsOneWidget);
    expect(find.text('Dela Cruz'), findsOneWidget);
  });

  testWidgets('an expired code stays on the code step', (tester) async {
    await boot(tester);
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email-code-field')), '000000');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();

    expect(find.text('Nag-expire na ang code'), findsOneWidget);
    expect(find.text('Your data, protected'), findsNothing);
    expect(find.textContaining('debug'), findsNothing);
  });

  testWidgets('submit signs the resident in as unverified', (tester) async {
    final auth = FakeAuthRepository();
    final dependencies = await boot(
      tester,
      auth: auth,
      documentPicker: _Picker(),
    );
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();

    await reveal(
      tester,
      find.text(
        'I have read and agree to the Terms of Use and the Privacy Notice.',
      ),
    );
    await tester.tap(
      find.text(
        'I have read and agree to the Terms of Use and the Privacy Notice.',
      ),
    );
    await reveal(
      tester,
      find.text(
        'I consent to Taytay LGU processing my personal data for account verification.',
      ),
    );
    await tester.tap(
      find.text(
        'I consent to Taytay LGU processing my personal data for account verification.',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Add a photo of the front of your ID.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('id-front-pick')));
    await tester.pumpAndSettle();
    expect(find.text('id_front.jpg'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take selfie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Check your details'), findsOneWidget);
    expect(find.text('Juana Dela Cruz'), findsOneWidget);
    await tester.tap(find.text('Submit for verification'));
    await tester.pumpAndSettle();

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.textContaining('TAY-2026-000123'), findsWidgets);
    expect(dependencies.session.accessLevel, AccessLevel.unverified);
    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .join(' ');
    expect(rendered, isNot(contains('operator')));
    expect(rendered, isNot(contains('endpoint')));
  });

  testWidgets('a declined registration does not show the server message', (
    tester,
  ) async {
    await boot(
      tester,
      auth: FakeAuthRepository(
        passwordOutcome: const Err<AuthOutcome>(
          ServerFailure(
            isTemporary: true,
            debugMessage: 'operator detail register exploded',
          ),
        ),
      ),
      documentPicker: _Picker(),
    );
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.text(
        'I have read and agree to the Terms of Use and the Privacy Notice.',
      ),
    );
    await tester.tap(
      find.text(
        'I have read and agree to the Terms of Use and the Privacy Notice.',
      ),
    );
    await reveal(
      tester,
      find.text(
        'I consent to Taytay LGU processing my personal data for account verification.',
      ),
    );
    await tester.tap(
      find.text(
        'I consent to Taytay LGU processing my personal data for account verification.',
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('id-front-pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take selfie'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit for verification'));
    await tester.pumpAndSettle();

    expect(find.text(SignInMessage.serviceUnavailable.text), findsOneWidget);
    expect(find.textContaining('exploded'), findsNothing);
    expect(find.textContaining('operator'), findsNothing);
  });
}
