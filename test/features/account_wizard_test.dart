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
import 'package:taytay_resident/features/auth/domain/code_exchange.dart';
import 'package:taytay_resident/features/auth/domain/sign_in_challenge.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

import 'auth_screens_test.dart' show FakeBarangayDirectory, boot, goTo, reveal;
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

const String _sanJuanId = '00000000-0000-4000-8000-0000000000a1';
const String _doloresId = '00000000-0000-4000-8000-0000000000d1';

class _Picker implements DocumentPicker {
  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async {
    return CapturedDocument(
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      fileName: source == DocumentSource.camera ? 'selfie.jpg' : 'id_front.jpg',
      mimeType: 'image/jpeg',
      source: source,
    );
  }

  @override
  bool supports(DocumentSource source) => true;
}

Future<void> _chooseBarangay(WidgetTester tester, String id) async {
  await reveal(tester, find.byKey(const Key('barangay-picker')));
  await tester.tap(find.byKey(const Key('barangay-picker')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('barangay-$id')));
  await tester.pumpAndSettle();
}

/// Names, mobile and street, then the barangay from the picker.
Future<void> _fillPersonal(
  WidgetTester tester, {
  String barangayId = _sanJuanId,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Juana');
  await tester.enterText(fields.at(1), 'Dela Cruz');
  await tester.enterText(fields.at(2), '0917 123 4567');
  await tester.enterText(fields.at(3), 'Purok 3');
  await _chooseBarangay(tester, barangayId);
}

Future<void> _fillAccount(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'juana.delacruz@example.com');
  await tester.enterText(fields.at(1), 'Password1!');
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Personal details, then the account. Leaves the wizard wherever the
/// account step sent it.
Future<void> _createAccount(WidgetTester tester) async {
  await _fillPersonal(tester);
  await _tapText(tester, 'Continue');
  await _fillAccount(tester);
  await _tapText(tester, 'Create my account');
}

const String _agree =
    'I have read and agree to the Terms of Use and the Privacy Notice.';
const String _consent =
    'I consent to Taytay LGU processing my personal data for account '
    'verification.';

void main() {
  group('access for sign-in and registration', () {
    test('a guest may open sign-in, register, and forgot password', () {
      for (final path in <String>[
        AppRoute.signIn.path,
        AppRoute.register.path,
        AppRoute.forgotPassword.path,
        AppRoute.resetCode.path,
        AppRoute.setPassword.path,
        AppRoute.tooMany.path,
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
          AppRoute.tooMany,
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
      password: 'Password1!',
      mobile: '09171234567',
      givenName: 'Juana',
      familyName: 'Dela Cruz',
      barangay: 'San Juan',
      hasGovernmentId: true,
      selfieTaken: true,
    );
    final text = draft.toString();
    expect(text, contains('redacted'));
    expect(text, isNot(contains('Juana')));
    expect(text, isNot(contains('0917')));
    expect(text, isNot(contains('example.com')));
    expect(text, isNot(contains('Password1!')));
    expect(text, isNot(contains('San Juan')));
  });

  testWidgets('each empty personal field is named', (tester) async {
    final auth = FakeAuthRepository();
    await boot(tester, auth: auth);
    await goTo(tester, 'register');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Please fix'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);
    expect(
      find.text('Enter an 11-digit mobile number starting with 09.'),
      findsOneWidget,
    );
    expect(find.text('Choose your barangay.'), findsOneWidget);
    expect(find.textContaining('exploded'), findsNothing);
    expect(auth.calls, isEmpty);
  });

  testWidgets('the account step names its own empty fields', (tester) async {
    final auth = FakeAuthRepository();
    await boot(tester, auth: auth);
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await _tapText(tester, 'Continue');

    expect(find.text('Create your account'), findsOneWidget);
    await _tapText(tester, 'Create my account');

    expect(
      find.text('Enter a valid email, e.g. name@example.com'),
      findsOneWidget,
    );
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  group('the barangay picker', () {
    testWidgets('lists GET /barangays and fills the field', (tester) async {
      final barangays = FakeBarangayDirectory();
      await boot(tester, barangays: barangays);
      await goTo(tester, 'register');

      await reveal(tester, find.byKey(const Key('barangay-picker')));
      expect(
        tester.getSize(find.byKey(const Key('barangay-picker'))).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(const Key('barangay-picker')));
      await tester.pumpAndSettle();

      expect(find.text('Choose your barangay'), findsOneWidget);
      expect(find.text('Dolores'), findsOneWidget);
      expect(find.text('San Juan'), findsOneWidget);
      for (final String id in <String>[_doloresId, _sanJuanId]) {
        expect(
          tester.getSize(find.byKey(Key('barangay-$id'))).height,
          greaterThanOrEqualTo(48),
        );
      }

      await tester.tap(find.byKey(const Key('barangay-$_doloresId')));
      await tester.pumpAndSettle();

      expect(find.text('Choose your barangay'), findsNothing);
      expect(find.text('Dolores'), findsOneWidget);
      expect(barangays.calls, 1);
      // The picker is announced as a button with its value, not a text box.
      expect(
        tester.getSemantics(find.byKey(const Key('barangay-picker'))),
        isSemantics(
          label: 'Barangay, required',
          value: 'Dolores',
          isButton: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('a failed list says so and can be tried again', (tester) async {
      final barangays = FakeBarangayDirectory(
        outcomes: <Result<List<Barangay>>>[
          const Err<List<Barangay>>(
            NetworkFailure(debugMessage: 'operator detail exploded'),
          ),
        ],
      );
      await boot(tester, barangays: barangays);
      await goTo(tester, 'register');

      await reveal(tester, find.byKey(const Key('barangay-picker')));
      await tester.tap(find.byKey(const Key('barangay-picker')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('We could not load the list of barangays'),
        findsOneWidget,
      );
      expect(find.textContaining('exploded'), findsNothing);
      expect(find.text('Dolores'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Dolores'), findsOneWidget);
      expect(barangays.calls, 2);
    });
  });

  testWidgets(
    'the account exists and the profile is saved before a code is sent',
    (tester) async {
      final auth = FakeAuthRepository();
      final dependencies = await boot(
        tester,
        auth: auth,
        documentPicker: _Picker(),
      );
      await goTo(tester, 'register');
      await _fillPersonal(tester, barangayId: _doloresId);
      await _tapText(tester, 'Continue');

      // Nothing has left the phone for the personal step.
      expect(auth.calls, isEmpty);
      await _fillAccount(tester);
      await _tapText(tester, 'Create my account');

      expect(auth.calls, <String>[
        'createAccount',
        'saveRegistrationProfile',
        'sendEmailCode',
      ]);
      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(find.text('Change email address'), findsNothing);
      expect(dependencies.session.accessLevel, AccessLevel.unverified);

      final RegistrationProfile? saved = auth.savedRegistration;
      expect(saved?.fullName, 'Juana Dela Cruz');
      expect(saved?.mobile, '09171234567');
      expect(saved?.email, 'juana.delacruz@example.com');
      expect(saved?.barangayId, _doloresId);
      expect(saved?.street, 'Purok 3');
    },
  );

  testWidgets('a code that could not be sent is said, and not skipped', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..emailCodeOutcomes.add(
        const Err<CodeAcceptance>(
          ServerFailure(
            isTemporary: true,
            debugMessage: 'operator detail mailer exploded',
          ),
        ),
      );
    await boot(tester, auth: auth);
    await goTo(tester, 'register');
    await _createAccount(tester);

    expect(find.text('Enter the 6-digit code'), findsNothing);
    expect(find.textContaining('We sent a code'), findsNothing);
    expect(
      find.textContaining(
        'we could not send a code to juana.delacruz@example.com',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('exploded'), findsNothing);
    expect(find.textContaining('operator'), findsNothing);
    expect(find.text('Account created'), findsOneWidget);

    // Continue asks again. The account is not created twice.
    await _tapText(tester, 'Continue');
    expect(auth.calls, <String>[
      'createAccount',
      'saveRegistrationProfile',
      'sendEmailCode',
      'saveRegistrationProfile',
      'sendEmailCode',
    ]);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);
  });

  testWidgets('a field the server refuses is shown beside that field', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..profileOutcome = const Err<SavedProfile>(
        ValidationFailure(
          fieldErrors: <String, List<String>>{
            'barangay_id': <String>['That barangay was not found.'],
          },
          debugMessage: 'operator detail exploded',
        ),
      );
    await boot(tester, auth: auth);
    await goTo(tester, 'register');
    await _createAccount(tester);

    expect(find.text('Tungkol sa iyo'), findsOneWidget);
    expect(find.text('That barangay was not found.'), findsOneWidget);
    expect(find.textContaining('Your details were not saved.'), findsOneWidget);
    expect(auth.calls, <String>['createAccount', 'saveRegistrationProfile']);
  });

  testWidgets('back keeps what was typed', (tester) async {
    await boot(tester);
    await goTo(tester, 'register');
    await _fillPersonal(tester);
    await _tapText(tester, 'Continue');

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byType(TaytayBackButton), findsOneWidget);
    await _tapText(tester, 'Back');

    expect(find.text('Juana'), findsOneWidget);
    expect(find.text('Dela Cruz'), findsOneWidget);
    expect(find.text('San Juan'), findsOneWidget);
  });

  testWidgets('an expired code stays on the code step', (tester) async {
    await boot(tester, auth: FakeAuthRepository());
    await goTo(tester, 'register');
    await _createAccount(tester);

    await tester.enterText(find.byKey(const Key('email-code-field')), '000000');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();

    expect(find.text('Nag-expire na ang code'), findsOneWidget);
    expect(find.text('Your data, protected'), findsNothing);
    expect(find.textContaining('debug'), findsNothing);
  });

  testWidgets('submit opens a verification request for staff review', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final dependencies = await boot(
      tester,
      auth: auth,
      documentPicker: _Picker(),
    );
    await goTo(tester, 'register');
    await _createAccount(tester);

    await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();

    await _tapText(tester, _agree);
    await _tapText(tester, _consent);
    await _tapText(tester, 'Continue');

    await _tapText(tester, 'Continue');
    expect(find.text('Add a photo of the front of your ID.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('id-front-pick')));
    await tester.pumpAndSettle();
    expect(find.text('id_front.jpg'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('id-back-pick')));
    await tester.tap(find.byKey(const Key('id-back-pick')));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Continue');

    // No selfie, no review.
    await _tapText(tester, 'Continue');
    expect(find.text('Take a selfie to continue.'), findsOneWidget);
    await _tapText(tester, 'Take selfie');
    await _tapText(tester, 'Continue');

    expect(find.text('Check your details'), findsOneWidget);
    expect(find.text('Juana Dela Cruz'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Agreed · consent given'), findsOneWidget);
    await _tapText(tester, 'Submit for verification');

    expect(find.text('Pending review'), findsOneWidget);
    expect(find.textContaining('TAY-2026-000123'), findsNothing);
    expect(find.textContaining("office's own system"), findsOneWidget);
    expect(find.text("You're all set, Juana!"), findsOneWidget);
    expect(auth.calls, <String>[
      'createAccount',
      'saveRegistrationProfile',
      'sendEmailCode',
      'verifyEmailCode',
      'recordConsents',
      'submitProfile',
    ]);
    expect(auth.createdPassword, 'Password1!');
    expect(auth.submittedProfile?.hasGovernmentId, isTrue);
    expect(auth.submittedProfile?.idBackBytes, isNotNull);
    expect(auth.submittedProfile?.selfieName, 'selfie.jpg');
    expect(auth.submittedProfile.toString(), isNot(contains('Password1!')));
    expect(dependencies.session.accessLevel, AccessLevel.unverified);
    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .join(' ');
    expect(rendered, isNot(contains('operator')));
    expect(rendered, isNot(contains('endpoint')));
  });

  testWidgets('consent that was not recorded keeps the resident on terms', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..consentOutcome = const Err<void>(
        ServerFailure(isTemporary: true, debugMessage: 'operator exploded'),
      );
    await boot(tester, auth: auth, documentPicker: _Picker());
    await goTo(tester, 'register');
    await _createAccount(tester);
    await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();
    await _tapText(tester, _agree);
    await _tapText(tester, _consent);
    await _tapText(tester, 'Continue');

    expect(find.text('Your data, protected'), findsOneWidget);
    expect(
      find.textContaining('Your consent was not recorded.'),
      findsOneWidget,
    );
    expect(find.textContaining('exploded'), findsNothing);
  });

  testWidgets('a declined registration does not show the server message', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      passwordOutcome: const Err<AuthOutcome>(
        ServerFailure(
          isTemporary: true,
          debugMessage: 'operator detail register exploded',
        ),
      ),
    );
    await boot(tester, auth: auth, documentPicker: _Picker());
    await goTo(tester, 'register');
    await _createAccount(tester);

    expect(find.text(SignInMessage.serviceUnavailable.text), findsOneWidget);
    expect(find.textContaining('exploded'), findsNothing);
    expect(find.textContaining('operator'), findsNothing);
    // No profile and no code without an account.
    expect(auth.calls, <String>['createAccount']);
  });
}
