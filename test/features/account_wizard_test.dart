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
import 'package:taytay_resident/features/auth/presentation/account_wizard_screen.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart'
    hide ConsentKind;
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/features/verification/domain/verification_id_type.dart';
import 'package:taytay_resident/shared/widgets/biometric_consent_dialog.dart';
import 'package:taytay_resident/shared/widgets/legal_text_sheet.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

import '../support/biometric_fakes.dart';
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

/// `GET /app/config` answering with one privacy notice.
class _Bootstrap implements PlatformRepository {
  const _Bootstrap(this.notice, {this.terms = TermsOfUse.missing});

  final PrivacyNotice notice;
  final TermsOfUse terms;

  @override
  Future<Result<ServiceHealth>> checkHealth() async => const Ok<ServiceHealth>(
    ServiceHealth(service: 'taytay', status: 'ok', apiVersion: '1'),
  );

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async => Ok<AppBootstrap>(
    AppBootstrap(
      service: '',
      apiVersion: '',
      timezone: 'Asia/Manila',
      channel: 'citizen-mobile',
      defaultPageSize: 25,
      minimumVersion: '',
      features: FeatureFlags.none,
      support: SupportContact.none,
      privacyNotice: notice,
      terms: terms,
    ),
  );
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

/// Account, then the email code, which leaves the wizard on terms.
Future<void> _toTerms(WidgetTester tester) async {
  await _createAccount(tester);
  await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
  await tester.tap(find.text('Confirm email'));
  await tester.pumpAndSettle();
}

const String _agree = termsConsentLabel;
const String _consent = privacyConsentLabel;

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
    // Redesign P3a: back is the wave header's control only (RegDetails …
    // RegReview have no footer Back button).
    await tester.tap(find.byType(TaytayBackButton));
    await tester.pumpAndSettle();

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
      // The selfie consent published and already given (D-209).
      platform: BiometricPlatform(),
      accountControls: BiometricConsents(),
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

  testWidgets('consent whose answer was lost is not called unrecorded', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..consentOutcome = const Err<void>(TimeoutFailure());
    await boot(tester, auth: auth, documentPicker: _Picker());
    await goTo(tester, 'register');
    await _createAccount(tester);
    await tester.enterText(find.byKey(const Key('email-code-field')), '482190');
    await tester.tap(find.text('Confirm email'));
    await tester.pumpAndSettle();
    await _tapText(tester, _agree);
    await _tapText(tester, _consent);
    await _tapText(tester, 'Continue');

    // Still on the terms step, and honest about not knowing.
    expect(find.text('Your data, protected'), findsOneWidget);
    expect(
      find.textContaining('could not confirm that your consent was recorded'),
      findsOneWidget,
    );
    expect(find.textContaining('was not recorded'), findsNothing);
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

  group('resending the email code', () {
    testWidgets('waits out retry_after as a disabled 48 dp button', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await boot(tester, auth: auth);
      await goTo(tester, 'register');
      await _createAccount(tester);

      final Finder resend = find.byKey(const Key('email-code-resend'));
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      expect(
        find.textContaining(RegExp(r'^Resend in [01]:\d\d$')),
        findsOneWidget,
      );
      final Size size = tester.getSize(resend);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));

      await tester.tap(resend, warnIfMissed: false);
      await tester.pumpAndSettle();
      final int sends = auth.calls
          .where((String call) => call == 'sendEmailCode')
          .length;
      expect(sends, 1);
    });

    testWidgets('sends a new code once the wait is over', (tester) async {
      final auth = FakeAuthRepository()
        ..emailCodeOutcomes.add(
          const Ok<CodeAcceptance>(
            CodeAcceptance(accepted: true, retryAfterSeconds: 0),
          ),
        );
      await boot(tester, auth: auth);
      await goTo(tester, 'register');
      await _createAccount(tester);

      final Finder resend = find.byKey(const Key('email-code-resend'));
      expect(find.text('Resend code'), findsOneWidget);
      expect(tester.widget<TextButton>(resend).onPressed, isNotNull);

      await tester.tap(resend);
      await tester.pumpAndSettle();

      expect(auth.calls, <String>[
        'createAccount',
        'saveRegistrationProfile',
        'sendEmailCode',
        'sendEmailCode',
      ]);
      // The new code starts the server's wait again.
      expect(find.text('Resend code'), findsNothing);
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      expect(find.text('Enter the 6-digit code'), findsOneWidget);
    });
  });

  group('the full Terms and Privacy Notice', () {
    testWidgets('Terms says it is not published, and Privacy shows the text', (
      tester,
    ) async {
      await boot(
        tester,
        auth: FakeAuthRepository(),
        platform: const _Bootstrap(
          PrivacyNotice(
            version: '2026-11',
            bodyMarkdown: '## Ano ang kinokolekta\n\n- Ang iyong **pangalan**.',
          ),
        ),
      );
      await goTo(tester, 'register');
      await _toTerms(tester);
      expect(find.text('Your data, protected'), findsOneWidget);

      final Finder terms = find.byKey(const Key('terms-read-full'));
      await reveal(tester, terms);
      expect(tester.getSize(terms).height, greaterThanOrEqualTo(48));
      await tester.tap(terms);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The full Terms of Use will be available soon'),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('privacy-read-full')));
      await tester.pumpAndSettle();
      expect(find.text('Ano ang kinokolekta'), findsOneWidget);
      expect(find.textContaining('Ang iyong pangalan.'), findsOneWidget);
      expect(find.textContaining('will be available soon'), findsNothing);
    });

    testWidgets('the server placeholder is not shown as the notice', (
      tester,
    ) async {
      await boot(
        tester,
        auth: FakeAuthRepository(),
        platform: const _Bootstrap(
          PrivacyNotice(version: 'placeholder', bodyMarkdown: 'TODO notice'),
        ),
      );
      await goTo(tester, 'register');
      await _toTerms(tester);

      final Finder privacy = find.byKey(const Key('privacy-read-full'));
      await reveal(tester, privacy);
      await tester.tap(privacy);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('The full Privacy Notice will be available soon'),
        findsOneWidget,
      );
      expect(find.textContaining('TODO notice'), findsNothing);
    });

    Future<void> openTerms(WidgetTester tester, TermsOfUse terms) async {
      await boot(
        tester,
        auth: FakeAuthRepository(),
        platform: _Bootstrap(PrivacyNotice.missing, terms: terms),
      );
      await goTo(tester, 'register');
      await _toTerms(tester);
      final Finder link = find.byKey(const Key('terms-read-full'));
      await reveal(tester, link);
      await tester.tap(link);
      await tester.pumpAndSettle();
    }

    testWidgets('published Terms are shown from terms.body_markdown', (
      tester,
    ) async {
      await openTerms(
        tester,
        const TermsOfUse(
          version: '2026-12',
          bodyMarkdown: '## Paggamit ng app\n\n- Ang iyong **account** ay iyo.',
        ),
      );
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Paggamit ng app'), findsOneWidget);
      expect(find.textContaining('Ang iyong account ay iyo.'), findsOneWidget);
      expect(find.textContaining('will be available soon'), findsNothing);
    });

    testWidgets('the server placeholder is not shown as the Terms', (
      tester,
    ) async {
      await openTerms(
        tester,
        const TermsOfUse(version: 'placeholder', bodyMarkdown: 'TODO terms'),
      );
      expect(
        find.textContaining('The full Terms of Use will be available soon'),
        findsOneWidget,
      );
      expect(find.textContaining('TODO terms'), findsNothing);
    });

    testWidgets('a server that sends no terms object says the same', (
      tester,
    ) async {
      await openTerms(tester, TermsOfUse.missing);
      expect(
        find.textContaining('The full Terms of Use will be available soon'),
        findsOneWidget,
      );
    });
  });

  testWidgets('the ID type offers every kind the API accepts', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await boot(tester, auth: FakeAuthRepository(), documentPicker: _Picker());
    await goTo(tester, 'register');
    await _toTerms(tester);
    await _tapText(tester, _agree);
    await _tapText(tester, _consent);
    await _tapText(tester, 'Continue');
    expect(find.text('Upload a valid government ID'), findsOneWidget);
    expect(find.text('PhilSys National ID'), findsOneWidget);

    await tester.tap(find.byKey(const Key('id-type-picker')));
    await tester.pumpAndSettle();
    for (final String wire in verificationIdTypes) {
      final Finder row = find.byKey(Key('id-type-$wire'));
      expect(row, findsOneWidget, reason: wire);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(row),
        isSemantics(
          label: idTypeLabel(wire),
          isButton: true,
          hasTapAction: true,
        ),
        reason: wire,
      );
    }
    await tester.tap(find.byKey(const Key('id-type-drivers_license')));
    await tester.pumpAndSettle();

    expect(find.text("Driver's license"), findsOneWidget);
    expect(find.text('PhilSys National ID'), findsNothing);
    semantics.dispose();
  });
  group('the selfie consent in sign-up (D-209, D-210)', () {
    /// Personal details through terms, leaving the wizard on the ID step.
    Future<void> toIdStep(WidgetTester tester) async {
      await goTo(tester, 'register');
      await _createAccount(tester);
      await tester.enterText(
        find.byKey(const Key('email-code-field')),
        '482190',
      );
      await tester.tap(find.text('Confirm email'));
      await tester.pumpAndSettle();
      await _tapText(tester, _agree);
      await _tapText(tester, _consent);
      await _tapText(tester, 'Continue');
    }

    /// The ID photo, then on to the selfie step.
    Future<void> toSelfieStep(WidgetTester tester) async {
      await toIdStep(tester);
      await tester.tap(find.byKey(const Key('id-front-pick')));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Continue');
    }

    testWidgets('owed: the consent is asked before the camera opens', (
      tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      );
      await boot(
        tester,
        auth: auth,
        documentPicker: _Picker(),
        platform: BiometricPlatform(),
        accountControls: consents,
      );
      await toSelfieStep(tester);

      await _tapText(tester, 'Take selfie');
      expect(find.text(BiometricConsentCopy.dialogTitle), findsOneWidget);
      expect(find.text(sampleBiometricBody.split('\n').last), findsOneWidget);
      await reveal(tester, find.byKey(biometricConsentTickKey));
      await tester.tap(find.byKey(biometricConsentTickKey));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(biometricConsentAgreeKey));
      await tester.tap(find.byKey(biometricConsentAgreeKey));
      await tester.pumpAndSettle();

      expect(consents.accepted.single.kind, ConsentKind.biometric);
      await _tapText(tester, 'Continue');
      expect(find.text('Check your details'), findsOneWidget);
    });

    testWidgets('declined: the in-person way, and Finish for now goes home', (
      tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      );
      await boot(
        tester,
        auth: auth,
        documentPicker: _Picker(),
        platform: BiometricPlatform(),
        accountControls: consents,
      );
      await toSelfieStep(tester);
      await _tapText(tester, 'Take selfie');
      await reveal(tester, find.byKey(biometricConsentDeclineKey));
      await tester.tap(find.byKey(biometricConsentDeclineKey));
      await tester.pumpAndSettle();

      expect(consents.accepted, isEmpty);
      expect(find.text(BiometricConsentCopy.declinedHeading), findsOneWidget);
      expect(find.byKey(inPersonVerificationNoteKey), findsOneWidget);
      expect(find.byKey(wizardFinishForNowKey), findsOneWidget);

      await reveal(tester, find.byKey(wizardFinishForNowKey));
      await tester.tap(find.byKey(wizardFinishForNowKey));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('submitProfile')));
      expect(find.text('Take a quick selfie'), findsNothing);
    });

    testWidgets('unpublished: no ID is asked for, in person is offered', (
      tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      await boot(
        tester,
        auth: auth,
        documentPicker: _Picker(),
        platform: BiometricPlatform(published: false),
        accountControls: BiometricConsents(start: BiometricStart.unpublished),
      );
      await toIdStep(tester);

      expect(find.byKey(wizardSelfieUnavailableKey), findsOneWidget);
      expect(
        find.text(BiometricConsentCopy.unavailableHeading),
        findsOneWidget,
      );
      expect(find.byKey(inPersonVerificationNoteKey), findsOneWidget);
      expect(find.byKey(const Key('id-front-pick')), findsNothing);
      await reveal(tester, find.byKey(wizardFinishForNowKey));
      await tester.tap(find.byKey(wizardFinishForNowKey));
      await tester.pumpAndSettle();
      expect(auth.calls, isNot(contains('submitProfile')));
    });

    testWidgets('the unpublished ID step fits every phone at 200% text', (
      tester,
    ) async {
      for (final double width in <double>[360, 375, 430]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await boot(
          tester,
          auth: FakeAuthRepository(),
          documentPicker: _Picker(),
          platform: BiometricPlatform(published: false),
          accountControls: BiometricConsents(start: BiometricStart.unpublished),
          textScaler: const TextScaler.linear(2),
        );
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        await toIdStep(tester);
        expect(tester.takeException(), isNull, reason: '$width');
        expect(find.byKey(inPersonVerificationNoteKey), findsOneWidget);
      }
    });
  });

  group('a retried sign-up submission opens one request (D-213)', () {
    testWidgets('the same key on a retry, a new one for a new selfie', (
      tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      auth.submitOutcomes.addAll(<Result<void>>[
        const Err<void>(TimeoutFailure()),
        const Err<void>(TimeoutFailure()),
      ]);
      await boot(
        tester,
        auth: auth,
        documentPicker: _Picker(),
        platform: BiometricPlatform(),
        accountControls: BiometricConsents(),
      );
      await goTo(tester, 'register');
      await _createAccount(tester);
      await tester.enterText(
        find.byKey(const Key('email-code-field')),
        '482190',
      );
      await tester.tap(find.text('Confirm email'));
      await tester.pumpAndSettle();
      await _tapText(tester, _agree);
      await _tapText(tester, _consent);
      await _tapText(tester, 'Continue');
      await tester.tap(find.byKey(const Key('id-front-pick')));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Continue');
      await _tapText(tester, 'Take selfie');
      await _tapText(tester, 'Continue');

      await _tapText(tester, 'Submit for verification');
      await _tapText(tester, 'Submit for verification');
      expect(auth.submittedKeys, hasLength(2));
      final String? first = auth.submittedKeys.first;
      expect(first, isNotNull);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(first ?? ''),
        isTrue,
        reason: 'a UUID v4, as the API requires',
      );
      expect(auth.submittedKeys.last, first);

      // A new selfie is new content: a new key.
      await tester.tap(find.byType(TaytayBackButton).first);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Take selfie');
      await _tapText(tester, 'Continue');
      await _tapText(tester, 'Submit for verification');
      expect(auth.submittedKeys, hasLength(3));
      expect(auth.submittedKeys.last, isNot(first));
      expect(find.text('Pending review'), findsOneWidget);
    });
  });
}
