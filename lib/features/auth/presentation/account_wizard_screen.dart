import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/send_key.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/l10n/core_copy.dart';
import '../../../core/l10n/verification_copy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/biometric_consent_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/barangay_picker.dart';
import '../../../shared/widgets/biometric_consent_dialog.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/legal_text_sheet.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/upload_slot.dart';
import '../../platform/domain/app_bootstrap.dart';
import '../../platform/domain/privacy_notice.dart';
import '../../registration/domain/registration_domain.dart';
import '../../verification/domain/verification_id_type.dart';
import '../../verification/domain/verification_submit_outcome.dart';
import '../domain/account_application.dart';
import '../domain/auth_repository.dart';
import '../domain/code_exchange.dart';
import '../domain/sign_in_challenge.dart';
import 'auth_bits.dart';

/// The office that verifies in person (D-210); its details are the
/// directory's (`GET /offices/{slug}`).
const String wizardInPersonOfficeSlug = 'mswdo';

/// Ends the wizard when no selfie can be sent: the account is kept. The
/// English default; the button reads `authWizardFinishForNow`.
const String wizardFinishForNow = 'Finish for now';
const Key wizardFinishForNowKey = Key('wizard-finish-for-now');
const Key wizardSelfieUnavailableKey = Key('wizard-selfie-unavailable');
const Key wizardConsentFailedKey = Key('wizard-consent-failed');

/// The ID step's other way: verify in person, with nothing uploaded (D-228).
const Key wizardChooseInPersonKey = Key('wizard-choose-in-person');
const Key wizardChosenInPersonKey = Key('wizard-chosen-in-person');
const Key wizardUndoInPersonKey = Key('wizard-undo-in-person');

/// The ID step's offer and its answer, said in the wizard's words (D-228).
/// The English defaults; the screen reads the `authWizardInPerson*` strings.
abstract final class WizardInPersonCopy {
  static const String offerHeading = 'Rather verify in person?';
  static const String offer =
      'You do not have to upload anything. Bring a valid ID to the MSWDO and '
      'staff verify your account there. No selfie is taken.';
  static const String offerAction = 'Verify in person instead';
  static const String chosenHeading = 'You chose to verify in person';
  static const String chosen =
      'Nothing about your ID is sent from the app. Your account is kept and '
      'works without it until staff verify you at the office.';
  static const String undo = 'Send my ID in the app instead';
  static const String stepTitle = 'Verify in person';
  static const String stepSubtitle =
      'Your account is ready. Staff verify it at the MSWDO counter.';
}

/// Which `02` frame the wizard paints.
enum AccountFixture {
  live,
  personal,
  account,
  codeNotSent,
  code,
  codeExpired,
  terms,
  idCard,
  selfie,
  review,
  submitted,
  errors,
}

/// Registration as `02-03` through `02-09`, and the `02-11` errors, drawn as
/// the redesign's step flow (`RegDetails` … `RegDone`): a wave header with
/// the step and a gold progress bar, filled fields on a white page, and the
/// action in the footer. The submitted step is the `RegDone` success screen.
///
/// The order is the server's, not the design file's. The Node API creates the
/// profile row empty on the first `GET /me`, and `POST /auth/email-otp/send`
/// refuses a profile with no email. So: personal details, then the Firebase
/// account, then `PATCH /me` with the profile and the barangay the resident
/// picked from `GET /barangays`, and only then the email code. Consent is
/// recorded at the terms step; the ID and selfie go up at the end as one
/// verification request. A code that could not be sent keeps the resident on
/// the account step and says so. Back keeps what was typed.
class AccountWizardScreen extends StatefulWidget {
  const AccountWizardScreen({this.fixture = AccountFixture.live, super.key});

  final AccountFixture fixture;

  @override
  State<AccountWizardScreen> createState() => _AccountWizardScreenState();
}

enum _Step { personal, account, code, terms, idCard, selfie, review, submitted }

/// Taytay's barangays for the design frames only. A live build reads
/// `GET /barangays` and never falls back to this list.
const List<Barangay> _sampleBarangays = <Barangay>[
  Barangay(id: 'sample-dolores', name: 'Dolores'),
  Barangay(id: 'sample-muzon', name: 'Muzon'),
  Barangay(id: 'sample-san-isidro', name: 'San Isidro'),
  Barangay(id: 'sample-san-juan', name: 'San Juan'),
  Barangay(id: 'sample-santa-ana', name: 'Santa Ana'),
];

/// Wizard error keys for the `ProfilePatch` fields `PATCH /me` can refuse.
const Map<String, String> _profileFieldKeys = <String, String>{
  'name': 'first',
  'mobile': 'mobile',
  'email': 'email',
  'barangay_id': 'barangay',
  'street': 'street',
};

const Set<String> _personalKeys = <String>{
  'first',
  'last',
  'mobile',
  'barangay',
  'street',
};

class _AccountWizardScreenState extends State<AccountWizardScreen> {
  late _Step _step;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _barangay = TextEditingController();
  final _street = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  /// The ID type's English label: what [AccountApplication.idTypeLabel]
  /// sends, which the repository maps back to its wire code. The screen shows
  /// [_idTypeWire] in the reader's language instead.
  final _idType = TextEditingController(text: 'PhilSys National ID');
  String _idTypeWire = 'philid';
  final _summary = FocusNode();

  /// The email code's field, so an empty Confirm opens the keyboard on it.
  final FocusNode _codeFocus = FocusNode();
  bool _terms = false;
  bool _privacy = false;
  bool _obscure = true;
  bool _busy = false;
  String? _status;
  CapturedDocument? _front;
  CapturedDocument? _idBack;
  CapturedDocument? _selfieShot;
  bool _selfie = false;
  CodeAttemptView _attempt = const CodeAttemptView();
  Map<String, String> _errors = <String, String>{};
  bool _codeExpired = false;

  /// A design frame's notes wait for [didChangeDependencies]: they are worded
  /// from the app's strings, which [initState] cannot read.
  bool _fixtureCopyPending = false;

  /// Redraws the resend countdown once a second on the code step.
  Timer? _clock;

  /// The UUID from `GET /barangays`. [_barangay] holds only its name.
  String? _barangayId;
  List<Barangay>? _barangays;

  /// The Firebase account exists and this session holds its token. From here
  /// the email is fixed: changing it would need Firebase to change it too.
  bool _accountCreated = false;

  /// A code was accepted for the saved email, so going forward does not ask
  /// for another one. Resend lives on the code step.
  bool _codeSent = false;

  /// What the server last said about the saved email.
  bool _emailVerified = false;

  /// Both consent versions are recorded on the server.
  bool _consented = false;

  /// An Edit link on the review step sent the resident back. The next step
  /// that completes returns there.
  bool _returnToReview = false;

  /// The selfie's consent, read once the terms are agreed (D-209). Null in a
  /// design frame and before that step.
  BiometricConsentController? _biometric;

  /// The resident chose "No, I'll verify in person" (D-210).
  bool _declinedSelfie = false;

  /// The resident chose in person on the ID step, before any photo (D-228).
  /// Nothing is uploaded and no selfie consent is asked for.
  bool _chosenInPerson = false;

  /// The verification request's idempotency key (D-213): minted on the first
  /// Submit, the same on every retry of it, and new once the ID type or a
  /// photo changes, because the server refuses a key reused for other
  /// content.
  final SendKey _submitKey = SendKey();

  /// Starts reading the selfie's consent, once, for a live sign-up.
  void _ensureBiometric() {
    if (widget.fixture != AccountFixture.live || _biometric != null) return;
    final AppDependencies dependencies = AppDependencies.of(context);
    final BiometricConsentController controller = BiometricConsentController(
      platform: dependencies.platformRepository,
      consents: dependencies.accountControlsRepository,
      inPersonOffice: () =>
          dependencies.citizenApi.loadOffice(wizardInPersonOfficeSlug),
    )..addListener(_onBiometric);
    _biometric = controller;
    unawaited(controller.load());
  }

  void _onBiometric() {
    final BiometricConsentController? controller = _biometric;
    if (controller == null) return;
    if (controller.status is BiometricConsentUnavailable) {
      unawaited(controller.loadInPersonOffice());
    }
    if (mounted) setState(() {});
  }

  /// No selfie can be sent: the text is not published, or the resident chose
  /// to verify in person. The wizard then ends here, with the account kept
  /// and the in-person way said (D-210, D-228).
  bool get _selfieWayClosed {
    if (_chosenInPerson) return true;
    final BiometricConsentController? controller = _biometric;
    if (controller == null) return false;
    return controller.status is BiometricConsentUnavailable || _declinedSelfie;
  }

  /// Verify in person, chosen on the ID step: no ID is asked for and any
  /// photo already picked is let go, because it would be held for nothing.
  void _chooseInPerson() {
    setState(() {
      _chosenInPerson = true;
      _front = null;
      _idBack = null;
      _status = null;
    });
    final BiometricConsentController? controller = _biometric;
    if (controller != null) unawaited(controller.loadInPersonOffice());
  }

  @override
  void initState() {
    super.initState();
    _applyFixture();
    if (authClockTicks && widget.fixture == AccountFixture.live) {
      _clock = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  /// Only the code step shows a countdown. One more frame after the wait ends
  /// turns "Resend in 0:01" back into a button that works.
  void _tick(Timer _) {
    if (!mounted || _step != _Step.code || _codeExpired) return;
    final DateTime? at = _attempt.resendAt;
    if (at == null) return;
    if (DateTime.now().isAfter(at.add(const Duration(seconds: 1)))) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(AccountWizardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixture != widget.fixture) {
      _applyFixture();
      _applyFixtureCopy();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fixtureCopyPending) _applyFixtureCopy();
  }

  void _applyFixture() {
    final sample = widget.fixture != AccountFixture.live;
    if (sample) {
      _first.text = 'Juana';
      _email.text = widget.fixture == AccountFixture.errors
          ? 'juana.delacruz@example'
          : 'juana.delacruz@example.com';
      _mobile.text = '0917 123 4567';
      _barangay.text = 'San Juan';
      _barangayId = 'sample-san-juan';
      _street.text = 'Purok 3';
      _password.text = widget.fixture == AccountFixture.errors
          ? 'Short'
          : 'Password1!';
      _last.text = widget.fixture == AccountFixture.errors ? '' : 'Dela Cruz';
      _terms = true;
      _privacy = true;
      _selfie = true;
      _code.text = widget.fixture == AccountFixture.codeExpired
          ? ''
          : AuthSample.code;
    }
    _codeExpired = widget.fixture == AccountFixture.codeExpired;
    _step = switch (widget.fixture) {
      AccountFixture.account || AccountFixture.codeNotSent => _Step.account,
      AccountFixture.code || AccountFixture.codeExpired => _Step.code,
      AccountFixture.terms => _Step.terms,
      AccountFixture.idCard => _Step.idCard,
      AccountFixture.selfie => _Step.selfie,
      AccountFixture.review => _Step.review,
      AccountFixture.submitted => _Step.submitted,
      AccountFixture.errors => _Step.personal,
      AccountFixture.personal || AccountFixture.live => _Step.personal,
    };
    // The frames follow the live order: from the code step on, the account
    // exists; from terms on, the email is confirmed.
    _accountCreated =
        (sample && _step.index >= _Step.code.index) ||
        widget.fixture == AccountFixture.codeNotSent;
    _codeSent = sample && _step.index >= _Step.code.index;
    _emailVerified = sample && _step.index >= _Step.terms.index;
    _consented = sample && _step.index > _Step.terms.index;
    _fixtureCopyPending = true;
  }

  /// The frame's status note and field errors, in the device's language.
  void _applyFixtureCopy() {
    _fixtureCopyPending = false;
    _status = widget.fixture == AccountFixture.codeNotSent
        ? _codeNotSentCopy(const ServerFailure(isTemporary: true))
        : null;
    _errors = widget.fixture == AccountFixture.errors
        ? _personalErrors()
        : <String, String>{};
  }

  @override
  void dispose() {
    _biometric
      ?..removeListener(_onBiometric)
      ..dispose();
    _clock?.cancel();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _mobile.dispose();
    _barangay.dispose();
    _street.dispose();
    _password.dispose();
    _code.dispose();
    _idType.dispose();
    _summary.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Every screen the resident moves through, done included.
  static final int _stepCount = _Step.values.length;

  /// The screen's own place in the wizard, so each Continue moves the counter.
  /// Personal details, account and email code once all read "Step 1", which
  /// looked like a Continue that had done nothing.
  int get _dot => _step.index + 1;

  Map<String, String> _personalErrors() {
    final AppStrings strings = AppStrings.of(context);
    final errors = <String, String>{};
    if (_first.text.trim().isEmpty) errors['first'] = strings.a11yRequired;
    if (_last.text.trim().isEmpty) errors['last'] = strings.a11yRequired;
    final mobile = _mobile.text.replaceAll(' ', '');
    if (!RegExp(r'^09\d{9}$').hasMatch(mobile)) {
      errors['mobile'] = strings.authMobileShape;
    }
    if (_barangayId == null || _barangay.text.trim().isEmpty) {
      errors['barangay'] = strings.authWizardChooseBarangay;
    }
    return errors;
  }

  Map<String, String> _accountErrors() {
    final errors = <String, String>{};
    if (_accountCreated) return errors;
    final AppStrings strings = AppStrings.of(context);
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = strings.authWizardEmailInvalid;
    }
    if (_password.text.length < 8) {
      errors['password'] = strings.authWizardPasswordShort;
    }
    return errors;
  }

  /// The step after one that just completed, or review when an Edit link on
  /// review sent the resident here.
  _Step _after(_Step next) {
    if (!_returnToReview) return next;
    _returnToReview = false;
    return _Step.review;
  }

  Future<void> _continue() async {
    final AppStrings strings = AppStrings.of(context);
    switch (_step) {
      case _Step.personal:
        final errors = _personalErrors();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) {
          _summary.requestFocus();
          return;
        }
        if (widget.fixture != AccountFixture.live || !_accountCreated) {
          setState(() {
            _status = null;
            _step = _Step.account;
          });
          return;
        }
        // The account exists, so an edit here is saved straight away.
        await _saveProfileThenCode();
      case _Step.account:
        final errors = _accountErrors();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) {
          _summary.requestFocus();
          return;
        }
        if (widget.fixture != AccountFixture.live) {
          setState(() {
            _accountCreated = true;
            _codeSent = true;
            _status = null;
            _step = _Step.code;
          });
          return;
        }
        if (!_accountCreated && !await _createAccount()) return;
        if (!mounted) return;
        await _saveProfileThenCode();
      case _Step.code:
        if (_codeExpired) {
          await _resendEmailCode();
          return;
        }
        final code = _code.text.trim();
        if (code.isEmpty) {
          // Nothing typed yet (a second tap on the button that opened this
          // step lands here): open the keyboard on the code, and say nothing
          // is wrong until she has typed or pressed Confirm on a code (A13).
          setState(() => _status = null);
          _codeFocus.requestFocus();
          return;
        }
        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
          setState(() => _status = strings.authWizardEnterCode);
          return;
        }
        // `000000` is the expired stand-in. It does not spend an attempt and
        // does not need the network, so the code step can show `02-04b`.
        // A real `code_expired` from the server takes the same branch below.
        if (code == CodeExchangeRules.expiredSentinel) {
          setState(() {
            _codeExpired = true;
            _code.clear();
            _status = null;
          });
          return;
        }
        if (widget.fixture != AccountFixture.live) {
          setState(() {
            _emailVerified = true;
            _step = _after(_Step.terms);
          });
          return;
        }
        setState(() => _busy = true);
        final result = await AppDependencies.of(
          context,
        ).authRepository.verifyEmailCode(code: code);
        if (!mounted) return;
        switch (result) {
          case Ok<EmailVerified>():
            setState(() {
              _busy = false;
              _codeExpired = false;
              _emailVerified = true;
              _status = null;
              _step = _after(_Step.terms);
            });
          case Err<EmailVerified>(:final failure):
            final DateTime now = DateTime.now();
            final CodeAttemptView next = _attempt.applyFailure(failure, now);
            setState(() {
              _busy = false;
              _attempt = next;
              if (next.expired) {
                _codeExpired = true;
                _code.clear();
                _status = null;
              } else if (next.unavailable) {
                _status = strings.authWizardServiceUnavailable;
              } else if (next.limited) {
                _status = null;
                unawaited(_openHold(now, next.resendAt));
              } else if (next.wrong && next.attemptsRemaining != null) {
                _status = strings.authWizardWrongCode(
                  next.attemptsRemaining ?? 0,
                  CodeExchangeRules.attempts,
                );
              } else {
                _status = localisedSignInMessage(
                  context,
                  SignInFeedback.forFailure(failure),
                );
              }
            });
        }
      case _Step.terms:
        if (!_terms || !_privacy) {
          setState(
            () => _status = !_terms && !_privacy
                ? strings.authWizardTermsBoth
                : !_terms
                ? strings.authWizardTermsOnly
                : strings.authWizardPrivacyOnly,
          );
          return;
        }
        if (widget.fixture == AccountFixture.live && !_consented) {
          setState(() {
            _busy = true;
            _status = null;
          });
          final AppDependencies dependencies = AppDependencies.of(context);
          final Result<void> recorded = await dependencies.authRepository
              .recordConsents();
          if (!mounted) return;
          if (recorded case Err<void>(:final failure)) {
            setState(() {
              _busy = false;
              // Recording is idempotent by version, so agreeing again is
              // safe. After a timeout the server may already have it, and
              // "not recorded" would be a guess.
              _status = failure.outcomeUnknown
                  ? strings.authWizardConsentUnknown
                  : strings.authWizardConsentNotRecorded(
                      localisedResidentMessage(context, failure),
                    );
            });
            return;
          }
          _consented = true;
          // The account was opened a few steps ago with nothing agreed yet.
          // Asking again now clears the re-consent gate with the server's
          // word rather than this screen's.
          unawaited(dependencies.consentGate.check());
        }
        _ensureBiometric();
        setState(() {
          _busy = false;
          _status = null;
          _step = _after(_Step.idCard);
        });
      case _Step.idCard:
        if (_selfieWayClosed) {
          _finishForNow();
          return;
        }
        if (_front == null && widget.fixture == AccountFixture.live) {
          setState(() => _status = strings.authWizardAddIdFront);
          return;
        }
        setState(() {
          _status = null;
          _step = _after(_Step.selfie);
        });
      case _Step.selfie:
        if (_selfieWayClosed) {
          _finishForNow();
          return;
        }
        if (_selfieShot == null && widget.fixture == AccountFixture.live) {
          setState(() => _status = strings.authWizardTakeSelfieFirst);
          return;
        }
        setState(() {
          _status = null;
          _returnToReview = false;
          _step = _Step.review;
        });
      case _Step.review:
        await _submit();
      case _Step.submitted:
        context.goNamed(AppRoute.home.routeName);
    }
  }

  /// Creates the Firebase user and opens the session with its ID token.
  ///
  /// Returns whether the account now exists. A refusal stays on this step.
  Future<bool> _createAccount() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final dependencies = AppDependencies.of(context);
    final created = await dependencies.authRepository.createAccount(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return false;
    switch (created) {
      case Ok<AuthOutcome>(:final value):
        await dependencies.session.signIn(
          resident: value.resident,
          accessToken: value.accessToken,
          expiresAt: value.expiresAt,
        );
        if (!mounted) return false;
        setState(() => _accountCreated = true);
        return true;
      case Err<AuthOutcome>(:final failure):
        final AppStrings strings = AppStrings.of(context);
        setState(() {
          _busy = false;
          switch (failure) {
            case ConflictFailure():
              _errors = <String, String>{'email': strings.authWizardEmailTaken};
              _status = strings.authWizardEmailExists;
            case final ValidationFailure weak
                when weak.fieldErrors.containsKey('password'):
              // Firebase's weak-password refusal, worded by this app: the
              // same sentence `firebase_identity.dart` carries, in the
              // device's language.
              _errors = <String, String>{
                'password': strings.authWizardPasswordWeak,
              };
              _status = null;
            case UnauthenticatedFailure():
              _errors = <String, String>{
                'email': strings.authWizardEmailInvalid,
              };
              _status = null;
            default:
              _status = localisedSignInMessage(
                context,
                SignInFeedback.forFailure(failure),
              );
          }
        });
        return false;
    }
  }

  /// `PATCH /me`, then the email code the server can now send.
  Future<void> _saveProfileThenCode() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final AuthRepository auth = AppDependencies.of(context).authRepository;
    final Result<SavedProfile> saved = await auth.saveRegistrationProfile(
      RegistrationProfile(
        givenName: _first.text.trim(),
        familyName: _last.text.trim(),
        mobile: _mobile.text.replaceAll(' ', ''),
        email: _email.text.trim(),
        barangayId: _barangayId ?? '',
        street: _street.text.trim(),
      ),
    );
    if (!mounted) return;
    switch (saved) {
      case Err<SavedProfile>(:final failure):
        setState(() {
          _busy = false;
          _status = _profileNotSavedCopy(failure);
          if (failure is ValidationFailure) {
            final Map<String, String> fields = <String, String>{
              for (final MapEntry<String, String> key
                  in _profileFieldKeys.entries)
                if (failure.firstErrorFor(key.key) case final String message)
                  key.value: message,
            };
            if (fields.isNotEmpty) {
              _errors = fields;
              if (fields.keys.any(_personalKeys.contains)) {
                _step = _Step.personal;
              }
            }
          }
        });
        return;
      case Ok<SavedProfile>(:final value):
        _emailVerified = value.emailVerified;
        // The account was opened with no name; the one just saved is what
        // Home greets and draws initials from (D-228).
        AppDependencies.of(
          context,
        ).session.applyGreetingName(_first.text.trim(), replace: true);
    }
    if (_emailVerified) {
      setState(() {
        _busy = false;
        _step = _after(_Step.terms);
      });
      return;
    }
    if (_codeSent) {
      // A code is already out for this address. Resend is on the code step;
      // asking again here would only meet the cooldown.
      setState(() {
        _busy = false;
        _step = _Step.code;
      });
      return;
    }
    final Result<CodeAcceptance> sent = await auth.sendEmailCode();
    if (!mounted) return;
    final DateTime now = DateTime.now();
    switch (sent) {
      case Ok<CodeAcceptance>(:final value):
        setState(() {
          _busy = false;
          _attempt = _attempt.applyAcceptance(value, now);
          _codeSent = true;
          _codeExpired = false;
          _code.clear();
          _step = _Step.code;
        });
      case Err<CodeAcceptance>(:final failure):
        final CodeAttemptView next = _attempt.applyFailure(failure, now);
        setState(() {
          _busy = false;
          _attempt = next;
          if (next.limited) {
            // A code went out moments ago; the hold screen counts down.
            _step = _Step.code;
            unawaited(_openHold(now, next.resendAt));
          } else {
            // Not sent, and said so. The resident stays here and Continue
            // asks again; nothing moves on as if a code were on its way.
            _step = _Step.account;
            _status = _codeNotSentCopy(failure);
          }
        });
    }
  }

  String _codeNotSentCopy(AppFailure failure) {
    final AppStrings strings = AppStrings.of(context);
    final String email = _email.text.trim().isEmpty
        ? strings.authYourEmail
        : _email.text.trim();
    final String next = switch (failure) {
      NetworkFailure() ||
      TimeoutFailure() => strings.authWizardCodeNotSentOffline,
      _ => strings.authWizardCodeNotSentLater,
    };
    return strings.authWizardCodeNotSent(email, next);
  }

  String _profileNotSavedCopy(AppFailure failure) {
    // `PATCH /me` sets each value outright, so sending it again is safe. After
    // a timeout the server may already hold them, and "not saved" would be a
    // guess.
    final AppStrings strings = AppStrings.of(context);
    if (failure.outcomeUnknown) return strings.authWizardDetailsUnknown;
    final String lead = strings.authWizardDetailsNotSaved;
    return switch (failure) {
      ValidationFailure() =>
        '$lead ${strings.authWizardDetailsCheckHighlighted}',
      ConflictFailure() => '$lead ${strings.authWizardDetailsEmailConflict}',
      _ => '$lead ${localisedResidentMessage(context, failure)}',
    };
  }

  void _back() {
    final previous = switch (_step) {
      _Step.personal => null,
      _Step.account => _Step.personal,
      _Step.code => _Step.account,
      // A confirmed email is not asked for again.
      _Step.terms => _emailVerified ? _Step.account : _Step.code,
      _Step.idCard => _Step.terms,
      _Step.selfie => _Step.idCard,
      _Step.review => _Step.selfie,
      _Step.submitted => null,
    };
    if (previous == null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(AppRoute.signIn.routeName);
      }
      return;
    }
    setState(() {
      _step = previous;
      _status = null;
      _errors = <String, String>{};
      _returnToReview = false;
      if (previous == _Step.terms) _chosenInPerson = false;
    });
  }

  Future<void> _submit() async {
    if (widget.fixture != AccountFixture.live) {
      setState(() => _step = _Step.submitted);
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    final dependencies = AppDependencies.of(context);
    final CapturedDocument? front = _front;
    final CapturedDocument? back = _idBack;
    final CapturedDocument? selfie = _selfieShot;
    // The photos compare by identity: one picked again is a new object, and
    // a retry sends the very same ones.
    final String key = _submitKey.takeFor((
      _idType.text.trim(),
      _SameObject(front?.bytes),
      _SameObject(back?.bytes),
      _SameObject(selfie?.bytes),
    ));
    final application = AccountApplication(
      email: _email.text.trim(),
      password: _password.text,
      mobile: _mobile.text.replaceAll(' ', ''),
      givenName: _first.text.trim(),
      familyName: _last.text.trim(),
      barangay: _barangay.text.trim(),
      hasGovernmentId: front != null,
      selfieTaken: _selfie || selfie != null,
      idTypeLabel: _idType.text.trim(),
      idFrontBytes: front?.bytes,
      idFrontName: front?.fileName,
      idFrontMime: front?.mimeType,
      idBackBytes: back?.bytes,
      idBackName: back?.fileName,
      idBackMime: back?.mimeType,
      selfieBytes: selfie?.bytes,
      selfieName: selfie?.fileName,
      selfieMime: selfie?.mimeType,
      idempotencyKey: key,
    );
    final profile = await dependencies.authRepository.submitProfile(
      application,
    );
    _submitKey.settle(profile);
    if (!mounted) return;
    if (profile case Err<void>(:final failure)) {
      if (failure is ForbiddenFailure && failure.requiresBiometricConsent) {
        // The consent no longer stands (a new text, or a withdrawal on
        // another device): read it again; the selfie step asks.
        unawaited(_biometric?.refusedForConsent());
      }
      switch (verificationSubmitOutcome(failure)) {
        case VerificationSubmitOutcome.pendingReview:
          setState(() => _busy = false);
          context.goNamed(
            AppRoute.verification.routeName,
            queryParameters: const <String, String>{'status': 'pending'},
          );
          return;
        case VerificationSubmitOutcome.continueVerified:
          // Staff and admin accounts are also answered with 403. The session
          // takes the tier GET /me reports, and home opens only when that
          // tier is verified.
          final me = await dependencies.residentProfileRepository
              .loadOwnDetail();
          if (!mounted) return;
          var home = false;
          if (me case Ok(:final value)) {
            final String? tier = value.verificationTier;
            if (tier != null && tier.isNotEmpty) {
              dependencies.session.applyVerificationTier(tier);
              home =
                  AccessLevel.fromVerificationTier(tier) ==
                  AccessLevel.verified;
            }
          }
          setState(() {
            _busy = false;
            if (!home) _status = localisedResidentMessage(context, failure);
          });
          if (home) context.goNamed(AppRoute.home.routeName);
          return;
        case VerificationSubmitOutcome.opened:
        case VerificationSubmitOutcome.failed:
          setState(() {
            _busy = false;
            _status = localisedResidentMessage(context, failure);
          });
          return;
      }
    }
    _front = null;
    _idBack = null;
    _selfieShot = null;
    setState(() {
      _busy = false;
      _step = _Step.submitted;
    });
  }

  /// Leaves the wizard with the account as it is: signed in, not verified.
  /// Nothing about the ID is sent, and verification waits in the account.
  void _finishForNow() {
    _front = null;
    _idBack = null;
    _selfieShot = null;
    context.goNamed(AppRoute.home.routeName);
  }

  Future<void> _takeSelfie() async {
    final BiometricConsentController? consent = _biometric;
    if (consent == null) {
      _ensureBiometric();
      return;
    }
    // The consent first, as its own act, before the camera opens: a selfie
    // the server would refuse is never taken (D-209).
    final BiometricConsentChoice choice = await ensureBiometricConsent(
      context,
      consent,
    );
    if (!mounted) return;
    if (choice == BiometricConsentChoice.declined) {
      setState(() => _declinedSelfie = true);
      unawaited(consent.loadInPersonOffice());
      return;
    }
    if (choice != BiometricConsentChoice.agreed) return;
    if (_declinedSelfie) setState(() => _declinedSelfie = false);
    final picker = AppDependencies.of(context).documentPicker;
    final CapturedDocument? picked = await picker.pick(
      DocumentSource.camera,
      UploadPolicy.fallback,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selfieShot = picked;
      _selfie = true;
      _status = null;
    });
  }

  Future<void> _pickFront() async {
    final picker = AppDependencies.of(context).documentPicker;
    final picked = await picker.pick(
      DocumentSource.gallery,
      UploadPolicy.fallback,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _front = picked;
      _status = null;
    });
  }

  Future<void> _pickBack() async {
    final picker = AppDependencies.of(context).documentPicker;
    final picked = await picker.pick(
      DocumentSource.gallery,
      UploadPolicy.fallback,
    );
    if (picked == null || !mounted) return;
    setState(() => _idBack = picked);
  }

  /// Opens the barangay list from `GET /barangays`.
  Future<void> _chooseBarangay() async {
    final BarangayDirectory? directory = widget.fixture == AccountFixture.live
        ? AppDependencies.of(context).barangayDirectory
        : null;
    Future<Result<List<Barangay>>> load() async {
      final List<Barangay>? cached = _barangays;
      if (cached != null) return Ok<List<Barangay>>(cached);
      if (directory == null) {
        return const Ok<List<Barangay>>(_sampleBarangays);
      }
      final Result<List<Barangay>> listed = await directory.listBarangays();
      if (listed case Ok<List<Barangay>>(:final value) when value.isNotEmpty) {
        _barangays = value;
      }
      return listed;
    }

    final Barangay? picked = await showBarangayPicker(
      context,
      load: load,
      selectedId: _barangayId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _barangayId = picked.id;
      _barangay.text = picked.name;
      _errors.remove('barangay');
    });
  }

  Future<void> _chooseIdType() async {
    final String? picked = await AppSheet.show<String>(
      context: context,
      title: AppStrings.of(context).verifIdType,
      builder: (BuildContext sheet) =>
          _IdTypeSheet(selectedLabel: _idType.text.trim()),
    );
    if (picked == null || !mounted) return;
    if (!verificationIdTypes.contains(picked)) return;
    setState(() {
      _idTypeWire = picked;
      _idType.text = idTypeLabel(picked);
    });
  }

  /// `terms.body_markdown` from `GET /app/config` (backend `77da0b2`), once a
  /// version other than the server's placeholder is published. Until then the
  /// sheet says the text is not out yet, never a dead link. Consent still
  /// records `terms_version`, which a published text shares.
  Future<void> _openTerms() {
    final Future<String?> markdown = widget.fixture == AccountFixture.live
        ? _publishedTerms(
            AppDependencies.of(context).platformRepository.loadBootstrap(),
          )
        : Future<String?>.value();
    return showLegalTextSheet(
      context,
      title: 'Terms of Use',
      markdown: markdown,
      pending: AppStrings.of(context).sharedTermsNotPublishedYet,
    );
  }

  static Future<String?> _publishedTerms(
    Future<Result<AppBootstrap>> loading,
  ) async {
    final Result<AppBootstrap> result = await loading;
    return switch (result) {
      Ok<AppBootstrap>(:final value) when value.terms.isPublished =>
        value.terms.bodyMarkdown,
      _ => null,
    };
  }

  /// `privacy_notice.body_markdown` from `GET /app/config`, once a version
  /// other than the server's placeholder is published.
  Future<void> _openPrivacyNotice() {
    final Future<String?> markdown = widget.fixture == AccountFixture.live
        ? _publishedPrivacyNotice(
            AppDependencies.of(context).platformRepository.loadBootstrap(),
          )
        : Future<String?>.value();
    return showLegalTextSheet(
      context,
      title: 'Privacy Notice',
      markdown: markdown,
      pending:
          '${AppStrings.of(context).sharedPrivacyNoticeNotPublishedYet} '
          '${AppStrings.of(context).authWizardSummaryIsDraft}',
    );
  }

  static Future<String?> _publishedPrivacyNotice(
    Future<Result<AppBootstrap>> loading,
  ) async {
    final Result<AppBootstrap> result = await loading;
    return switch (result) {
      Ok<AppBootstrap>(:final value)
          when !value.privacyNotice.usesBundledDraft =>
        value.privacyNotice.bodyMarkdown,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.submitted) return _pending();
    final AppStrings strings = AppStrings.of(context);
    final (String title, String? subtitle) = _heading(strings);
    return AuthFormPage(
      title: title,
      subtitle: subtitle,
      stepLabel: strings.welcomeStep(_dot, _stepCount),
      progress: _dot / _stepCount,
      progressSemanticLabel: strings.authWizardProgressLabel,
      onBack: _back,
      backEnabled: !_busy,
      footer: _footer(strings),
      child: switch (_step) {
        _Step.personal => _personal(strings),
        _Step.account => _accountBody(strings),
        _Step.code => _emailCode(strings),
        _Step.terms => _termsBody(),
        _Step.idCard => _idBody(strings),
        _Step.selfie => _selfieBody(strings),
        _Step.review => _review(strings),
        _Step.submitted => const SizedBox.shrink(),
      },
    );
  }

  /// The wave header's title and supporting line for the step.
  (String, String?) _heading(AppStrings strings) {
    final String address = _email.text.trim().isEmpty
        ? strings.authYourEmail
        : _email.text.trim();
    return switch (_step) {
      _Step.personal => (
        strings.authWizardPersonalTitle,
        strings.authWizardPersonalSubtitle,
      ),
      _Step.account =>
        _accountCreated
            ? (
                strings.authWizardAccountCreatedTitle,
                strings.authWizardAccountCreatedSubtitle,
              )
            : (
                strings.authWizardAccountTitle,
                strings.authWizardAccountSubtitle,
              ),
      _Step.code =>
        _codeExpired
            ? (
                strings.authWizardCodeExpiredTitle,
                strings.authWizardCodeExpiredSubtitle(address),
              )
            : (
                strings.authWizardCodeTitle,
                strings.authWizardCodeSubtitle(address),
              ),
      _Step.terms => (
        strings.authWizardTermsTitle,
        strings.authWizardTermsSubtitle,
      ),
      _Step.idCard when _chosenInPerson => (
        strings.authWizardInPersonStepTitle,
        strings.authWizardInPersonStepSubtitle,
      ),
      _Step.idCard => (strings.authWizardIdTitle, strings.authWizardIdSubtitle),
      _Step.selfie => (
        strings.authWizardSelfieTitle,
        strings.authWizardSelfieSubtitle,
      ),
      _Step.review => (strings.authWizardReviewTitle, null),
      _Step.submitted => ('', null),
    };
  }

  Widget _footer(AppStrings strings) {
    if (_step == _Step.code && _codeExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: strings.authWizardSendNewCode,
            onPressed: _busy ? null : _resendEmailCode,
          ),
          if (!_accountCreated)
            AuthLink(
              strings.authWizardChangeEmail,
              onPressed: () => setState(() {
                _codeExpired = false;
                _step = _Step.account;
              }),
            ),
        ],
      );
    }
    if (_step == _Step.code) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: strings.authWizardConfirmEmail,
            onPressed: _busy ? null : _continue,
          ),
          // Once the Firebase account exists its email is fixed, so the link
          // that sent the resident back to retype it is not offered.
          if (!_accountCreated)
            AuthLink(
              strings.authWizardChangeEmail,
              onPressed: () => setState(() => _step = _Step.account),
            ),
        ],
      );
    }
    if ((_step == _Step.idCard || _step == _Step.selfie) && _selfieWayClosed) {
      return PrimaryButton(
        key: wizardFinishForNowKey,
        label: strings.authWizardFinishForNow,
        onPressed: _busy ? null : _finishForNow,
      );
    }
    final primary = switch (_step) {
      _Step.review => strings.authWizardSubmit,
      _Step.account when !_accountCreated => strings.authWizardCreateAccount,
      _ => strings.gateActionContinue,
    };
    return PrimaryButton(label: primary, onPressed: _busy ? null : _continue);
  }

  /// The error summary: a red note that takes focus after a refused step.
  Widget _alert(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.formGap),
      child: SoftNote(tone: NoteTone.error, message: text, focusNode: _summary),
    );
  }

  /// A step's own failure, said under its fields.
  Widget _statusNote() {
    final String? status = _status;
    if (status == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.formGap),
      child: SoftNote(tone: NoteTone.error, message: status),
    );
  }

  Widget _personal(AppStrings strings) {
    final count = _errors.keys.where(_personalKeys.contains).length;
    final String? status = _status;
    final bool showAddress =
        _errors.isEmpty && _street.text.isNotEmpty && _barangay.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (status != null)
          _alert(status)
        else if (count > 0)
          _alert(strings.authWizardFixFields(count)),
        _box(
          strings.fieldFirstName,
          _first,
          icon: TaytayIcons.user,
          error: _errors['first'],
          requiredField: true,
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          strings.fieldLastName,
          _last,
          icon: TaytayIcons.user,
          error: _errors['last'],
          requiredField: true,
          autofillHints: const <String>[AutofillHints.familyName],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          strings.profNameAsPrinted,
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          strings.fieldMobileNumber,
          _mobile,
          icon: TaytayIcons.phone,
          error: _errors['mobile'],
          requiredField: true,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: Spacing.formGap),
        _picker(
          strings,
          strings.fieldBarangay,
          _barangay,
          icon: TaytayIcons.mapPin,
          error: _errors['barangay'],
          requiredField: true,
          placeholder: strings.authWizardChoose,
          tapKey: const Key('barangay-picker'),
          onTap: _busy ? null : _chooseBarangay,
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          strings.authWizardStreetLabel,
          _street,
          icon: TaytayIcons.house,
          error: _errors['street'],
          hint: showAddress
              ? strings.authWizardAddressHint(
                  _street.text.trim(),
                  _barangay.text.trim(),
                )
              : null,
        ),
      ],
    );
  }

  /// Email and password: the Firebase account. Once it exists the email is
  /// fixed and the password is not shown again.
  Widget _accountBody(AppStrings strings) {
    final count = _errors.keys.where((k) => !_personalKeys.contains(k)).length;
    final String? status = _status;
    final String password = _password.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (status != null)
          _alert(status)
        else if (count > 0)
          _alert(strings.authWizardFixFields(count)),
        _box(
          strings.fieldEmail,
          _email,
          icon: TaytayIcons.mail,
          error: _errors['email'],
          requiredField: true,
          readOnly: _accountCreated,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          strings.authPasswordLabel,
          _password,
          icon: TaytayIcons.lock,
          error: _errors['password'],
          requiredField: true,
          obscure: _accountCreated || _obscure,
          readOnly: _accountCreated,
          autofillHints: const <String>[AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
          trailing: _accountCreated
              ? null
              : ShowPasswordToggle(
                  shown: !_obscure,
                  showLabel: strings.authPasswordShow,
                  hideLabel: strings.authPasswordHide,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
        ),
        if (!_accountCreated) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.xs,
            children: <Widget>[
              for (final rule in <(String, bool)>[
                (strings.authWizardRuleLength, password.length >= 8),
                (
                  'Aa',
                  RegExp('[A-Z]').hasMatch(password) &&
                      RegExp('[a-z]').hasMatch(password),
                ),
                ('123', RegExp(r'\d').hasMatch(password)),
                ('#!@', RegExp('[^A-Za-z0-9]').hasMatch(password)),
              ])
                PasswordRule(
                  rule.$1,
                  met: password.isEmpty && _errors['password'] == null
                      ? null
                      : rule.$2,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openHold(DateTime now, DateTime? resumeAt) async {
    final Duration? wait = resumeAt?.difference(now);
    final Object? back = await context.pushNamed(
      AppRoute.tooMany.routeName,
      extra: CodeHold.fromWait(
        origin: CodeHoldOrigin.emailVerification,
        email: _email.text.trim(),
        now: now,
        wait: wait != null && wait.isNegative ? Duration.zero : wait,
      ),
    );
    if (!mounted || back is! CodeAcceptance) return;
    setState(() {
      _attempt = _attempt.applyAcceptance(back, DateTime.now());
      _codeExpired = false;
      _code.clear();
      _status = null;
      _step = _Step.code;
    });
  }

  Future<void> _resendEmailCode() async {
    if (widget.fixture == AccountFixture.live) {
      if (_busy) return;
      setState(() => _busy = true);
      final Result<CodeAcceptance> sent = await AppDependencies.of(
        context,
      ).authRepository.sendEmailCode();
      if (!mounted) return;
      final DateTime now = DateTime.now();
      setState(() {
        _busy = false;
        switch (sent) {
          case Ok<CodeAcceptance>(:final value):
            _attempt = _attempt.applyAcceptance(value, now);
            _codeExpired = false;
            _code.clear();
            _status = null;
          case Err<CodeAcceptance>(:final failure):
            _attempt = _attempt.applyFailure(failure, now);
            if (_attempt.unavailable) {
              _status = AppStrings.of(context).authWizardServiceUnavailable;
            } else if (_attempt.limited) {
              _status = null;
              unawaited(_openHold(now, _attempt.resendAt));
            } else {
              _status = localisedSignInMessage(
                context,
                SignInFeedback.forFailure(failure),
              );
            }
        }
      });
      return;
    }
    setState(() {
      _codeExpired = false;
      _code.clear();
      _status = null;
    });
  }

  Widget _emailCode(AppStrings strings) {
    if (_codeExpired) return _emailCodeExpired(strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SixDigitRow(digits: _code.text),
            // The field covers the cells, so a tap anywhere on them opens
            // the keyboard. Its own text and cursor are not drawn.
            if (widget.fixture == AccountFixture.live)
              Positioned.fill(
                child: TextField(
                  key: const Key('email-code-field'),
                  controller: _code,
                  focusNode: _codeFocus,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  style: AppTypography.tiny.copyWith(
                    color: BrandColors.transparent,
                  ),
                  decoration: bareField.copyWith(counterText: ''),
                  // Typing answers whatever was said about the last code.
                  onChanged: (_) => setState(() => _status = null),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        _resendRow(strings),
        _statusNote(),
      ],
    );
  }

  /// "Didn't get it?" and a real button, 48 dp. During the wait from the
  /// last `retry_after` the button is off and says how long is left. The
  /// server enforces that wait whatever this shows.
  Widget _resendRow(AppStrings strings) {
    final bool live = widget.fixture == AccountFixture.live;
    final DateTime now = DateTime.now();
    final bool ready = live && _attempt.canResendAt(now);
    final Duration left = _attempt.resendAt?.difference(now) ?? Duration.zero;
    final String label = ready
        ? strings.authWizardResendCode
        : strings.authWizardResendIn(
            live ? CodeExchangeRules.countdown(left) : '0:45',
          );
    final TextStyle note = AppTypography.listDetail.copyWith(
      color: BrandColors.muted,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(strings.authWizardDidntGetIt, style: note),
        CodeResendButton(
          buttonKey: const Key('email-code-resend'),
          label: label,
          onPressed: ready && !_busy ? _resendEmailCode : null,
        ),
        Text(strings.authWizardCheckSpam, style: note),
      ],
    );
  }

  Widget _emailCodeExpired(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftNote(
          tone: NoteTone.warning,
          title: strings.authWizardOldCodeTitle,
          message: strings.authWizardNewCodeTries,
        ),
        const SizedBox(height: Spacing.formGap),
        const SixDigitRow(digits: '', dim: true),
        const SizedBox(height: Spacing.md),
        Text(
          strings.authWizardCanResendNow,
          textAlign: TextAlign.center,
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
      ],
    );
  }

  Widget _termsBody() {
    final AppStrings strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PrivacyNoticeCard(
          load: widget.fixture == AccountFixture.live
              ? AppDependencies.of(context).platformRepository.loadBootstrap
              : null,
        ),
        const SizedBox(height: Spacing.formGap),
        _LegalLinks(onTerms: _openTerms, onPrivacy: _openPrivacyNotice),
        const SizedBox(height: Spacing.formGap),
        ConsentCheckCard(
          value: _terms,
          onChanged: (value) => setState(() => _terms = value),
          label: strings.sharedTermsConsentLabel,
        ),
        const SizedBox(height: Spacing.sm + Spacing.xxs),
        ConsentCheckCard(
          value: _privacy,
          onChanged: (value) => setState(() => _privacy = value),
          label: strings.sharedPrivacyConsentLabel,
        ),
        _statusNote(),
      ],
    );
  }

  /// Where the selfie's consent stands, said on the ID and selfie steps
  /// before any photo is taken: nothing while it can be asked for, otherwise
  /// why no selfie can be sent and the in-person way (D-209, D-210).
  Widget _consentNotes() {
    final AppStrings strings = AppStrings.of(context);
    final BiometricConsentController? controller = _biometric;
    if (_chosenInPerson) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Spacing.formGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SoftNote(
              key: wizardChosenInPersonKey,
              heading: strings.authWizardInPersonChosenHeading,
              message: strings.authWizardInPersonChosen,
            ),
            const SizedBox(height: Spacing.md),
            InPersonVerificationNote(office: controller?.inPersonOffice),
          ],
        ),
      );
    }
    if (controller == null) return const SizedBox.shrink();
    final BiometricConsentStatus status = controller.status;
    final List<Widget> notes = switch (status) {
      BiometricConsentChecking() => <Widget>[
        LoadingSkeleton(
          layout: SkeletonLayout.text,
          count: 1,
          semanticLabel: strings.authWizardCheckingConsent,
        ),
      ],
      BiometricConsentFailed() => <Widget>[
        SoftNote(
          key: wizardConsentFailedKey,
          tone: NoteTone.error,
          heading: strings.sharedBiometricFailedHeading,
          message: strings.sharedBiometricFailed,
          action: AuthLink(
            strings.actionTryAgain,
            onPressed: () => unawaited(controller.load()),
          ),
        ),
      ],
      BiometricConsentUnavailable() => <Widget>[
        SoftNote(
          key: wizardSelfieUnavailableKey,
          tone: NoteTone.warning,
          heading: strings.sharedBiometricUnavailableHeading,
          message: strings.sharedBiometricUnavailable,
        ),
        const SizedBox(height: Spacing.md),
        InPersonVerificationNote(office: controller.inPersonOffice),
      ],
      BiometricConsentOwed() || BiometricConsentGiven() =>
        _declinedSelfie
            ? <Widget>[
                SoftNote(
                  heading: strings.sharedBiometricDeclinedHeading,
                  message: strings.sharedBiometricDeclined,
                ),
                const SizedBox(height: Spacing.md),
                InPersonVerificationNote(office: controller.inPersonOffice),
              ]
            : const <Widget>[],
    };
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.formGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: notes,
      ),
    );
  }

  Widget _idBody(AppStrings strings) {
    final attached = _front != null || widget.fixture == AccountFixture.idCard;
    final String name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
    if (_biometric?.status is BiometricConsentUnavailable) {
      // No selfie can be sent, so no ID is asked for either: the request
      // needs both, and an ID uploaded for nothing is data held for nothing.
      return _consentNotes();
    }
    if (_chosenInPerson) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _consentNotes(),
          AuthLink(
            strings.authWizardInPersonUndo,
            key: wizardUndoInPersonKey,
            alignment: AlignmentDirectional.centerStart,
            onPressed: _busy
                ? null
                : () => setState(() => _chosenInPerson = false),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _consentNotes(),
        // The other way, offered before any photo is asked for: a resident
        // may verify in person without uploading anything (D-210, D-228).
        SoftNote(
          heading: strings.authWizardInPersonOfferHeading,
          message: strings.authWizardInPersonOffer,
          live: false,
          action: AuthLink(
            strings.authWizardInPersonOfferAction,
            key: wizardChooseInPersonKey,
            onPressed: _busy ? null : _chooseInPerson,
          ),
        ),
        const SizedBox(height: Spacing.formGap),
        _NameCheckCard(name: name),
        const SizedBox(height: Spacing.formGap),
        _picker(
          strings,
          strings.verifIdType,
          _idType,
          shown: localisedIdTypeLabel(strings, _idTypeWire),
          icon: TaytayIcons.idCard,
          requiredField: true,
          placeholder: strings.authWizardChoose,
          tapKey: const Key('id-type-picker'),
          onTap: _busy ? null : _chooseIdType,
        ),
        const SizedBox(height: Spacing.formGap),
        AuthFieldLabel(strings.authWizardIdFront, requiredField: true),
        const SizedBox(height: Spacing.sm),
        if (attached)
          _attached(
            strings,
            name: _front?.fileName ?? 'id_front.jpg',
            onChange: _pickFront,
          )
        else
          UploadSlot(
            key: const Key('id-front-pick'),
            label: strings.authWizardAddPhoto,
            onPressed: _pickFront,
          ),
        const SizedBox(height: Spacing.formGap),
        AuthFieldLabel(strings.authWizardIdBack),
        const SizedBox(height: Spacing.sm),
        if (_idBack case final CapturedDocument back)
          _attached(strings, name: back.fileName, onChange: _pickBack)
        else
          UploadSlot(
            key: const Key('id-back-pick'),
            label: strings.authWizardAddPhoto,
            onPressed: widget.fixture == AccountFixture.live ? _pickBack : null,
          ),
        _statusNote(),
      ],
    );
  }

  /// A picked file (CSS `.file`): its name, "Attached", and Change. The
  /// photo itself is not drawn back on this screen.
  Widget _attached(
    AppStrings strings, {
    required String name,
    required VoidCallback onChange,
  }) {
    return SoftCard(
      filled: true,
      padding: const EdgeInsets.fromLTRB(
        Spacing.section,
        Spacing.md,
        Spacing.xs,
        Spacing.md,
      ),
      child: Row(
        children: <Widget>[
          const _GradientIcon(icon: TaytayIcons.idCard),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Row(
                  children: <Widget>[
                    const TaytayIcon(
                      icon: TaytayIcons.circleCheck,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm - Spacing.xs,
                      color: BrandColors.green,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Flexible(
                      child: Text(
                        strings.authWizardAttached,
                        style: AppTypography.small.copyWith(
                          fontWeight: AppTypography.strong,
                          color: BrandColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AuthLink(strings.applyEdit, onPressed: onChange),
        ],
      ),
    );
  }

  Widget _selfieBody(AppStrings strings) {
    final BiometricConsentStatus? consent = _biometric?.status;
    final bool canAsk =
        consent == null ||
        consent is BiometricConsentOwed ||
        consent is BiometricConsentGiven;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _consentNotes(),
        _SelfieGuide(taken: _selfie),
        const SizedBox(height: Spacing.formGap),
        _SelfieTip(TaytayIcons.sun, strings.authWizardSelfieTipLight),
        const SizedBox(height: Spacing.md),
        _SelfieTip(TaytayIcons.scanFace, strings.authWizardSelfieTipFace),
        const SizedBox(height: Spacing.md),
        _SelfieTip(TaytayIcons.user, strings.authWizardSelfieTipAlone),
        const SizedBox(height: Spacing.formGap),
        SecondaryButton(
          label: strings.authWizardTakeSelfie,
          icon: const TaytayIcon(
            icon: TaytayIcons.camera,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.blue,
          ),
          onPressed: widget.fixture != AccountFixture.live
              ? () => setState(() => _selfie = true)
              : canAsk && !_busy
              ? _takeSelfie
              : null,
        ),
        _statusNote(),
      ],
    );
  }

  String get _addressLine {
    final street = _street.text.trim();
    final barangay = _barangay.text.trim();
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (barangay.isNotEmpty) 'Brgy. $barangay',
      if (street.isNotEmpty || barangay.isNotEmpty) 'Taytay, Rizal',
    ];
    return parts.join(', ');
  }

  String _idSummary(AppStrings strings) {
    final type = _idType.text.trim().isEmpty
        ? ''
        : localisedIdTypeLabel(strings, _idTypeWire);
    final captured =
        _front != null ||
        widget.fixture == AccountFixture.idCard ||
        widget.fixture == AccountFixture.selfie ||
        widget.fixture == AccountFixture.review ||
        widget.fixture == AccountFixture.submitted;
    final String sides = _idBack != null
        ? strings.authWizardIdSidesBoth
        : strings.authWizardIdSidesFront;
    if (type.isEmpty) {
      return captured
          ? strings.authWizardIdCaptured(sides)
          : strings.authWizardNotAdded;
    }
    return captured ? '$type · $sides' : type;
  }

  Widget _review(AppStrings strings) {
    final name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
    final List<Widget> rows = <Widget>[
      _row(strings, strings.authWizardRowName, name, _Step.personal),
      // The email is fixed with the account, so it has no Edit link.
      _row(
        strings,
        strings.authWizardRowEmail,
        _email.text.trim(),
        null,
        badge: _emailVerified ? strings.verifyStageVerifiedLabel : null,
      ),
      _row(
        strings,
        strings.authWizardRowMobile,
        _mobile.text.trim(),
        _Step.personal,
      ),
      _row(strings, strings.authWizardRowAddress, _addressLine, _Step.personal),
      _row(
        strings,
        strings.authWizardRowTerms,
        _consented
            ? strings.authWizardTermsAgreed
            : strings.authWizardTermsNotAgreed,
        _Step.terms,
      ),
      _row(strings, strings.authWizardRowId, _idSummary(strings), _Step.idCard),
      _row(
        strings,
        strings.authWizardRowSelfie,
        _selfie
            ? strings.authWizardSelfieTaken
            : strings.authWizardSelfieNotTaken,
        _Step.selfie,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftCard(
          filled: true,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: BrandColors.divider,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
        _statusNote(),
      ],
    );
  }

  /// `RegDone`: the medal, "You're all set", and the verification status.
  Widget _pending() {
    final AppStrings strings = AppStrings.of(context);
    final String first = _first.text.trim();
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: SuccessScreen(
        mark: SuccessMarkStyle.medal,
        stepLabel: strings.welcomeStep(_stepCount, _stepCount),
        progress: 1,
        progressSemanticLabel: strings.authWizardProgressLabel,
        showBack: true,
        onBack: _back,
        title: first.isEmpty
            ? strings.authWizardDoneTitle
            : strings.authWizardDoneTitleNamed(first),
        message: strings.authWizardDoneMessage,
        body: SoftCard(
          filled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: <Widget>[
                  Text(
                    strings.authWizardDoneVerification,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                  _StatusPill(strings.authWizardPendingReview),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                strings.authWizardDoneBody,
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.text,
                ),
              ),
            ],
          ),
        ),
        primaryLabel: strings.authWizardContinueToApp,
        onPrimary: _busy ? null : _continue,
      ),
    );
  }

  Widget _row(
    AppStrings strings,
    String label,
    String value,
    _Step? edit, {
    String? badge,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.listRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTypography.small.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Wrap(
                    spacing: Spacing.sm - Spacing.xxs,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        value,
                        style: AppTypography.listTitle.copyWith(
                          color: BrandColors.ink,
                        ),
                      ),
                      if (badge != null) _StatusPill(badge, done: true),
                    ],
                  ),
                ],
              ),
            ),
            if (edit != null)
              AuthLink(
                strings.authWizardEdit,
                onPressed: () => setState(() {
                  _returnToReview = true;
                  _status = null;
                  _step = edit;
                }),
              ),
          ],
        ),
      ),
    );
  }

  /// A filled field ([AuthField]) with the wizard's required mark.
  Widget _box(
    String label,
    TextEditingController controller, {
    IconData? icon,
    String? error,
    String? hint,
    bool requiredField = false,
    bool obscure = false,
    bool readOnly = false,
    Widget? trailing,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onChanged,
  }) {
    return AuthField(
      label: label,
      requiredField: requiredField,
      controller: controller,
      icon: icon,
      error: error,
      hint: hint,
      obscure: obscure,
      readOnly: readOnly,
      trailing: trailing,
      keyboardType: keyboardType,
      autofillHints: readOnly ? null : autofillHints,
      onChanged: onChanged,
    );
  }

  /// A picker drawn as a filled field: its value as text, one 48 dp button,
  /// rather than a text field a resident could type a barangay name into.
  Widget _picker(
    AppStrings strings,
    String label,
    TextEditingController controller, {
    required String placeholder,
    required Key tapKey,
    required VoidCallback? onTap,
    IconData? icon,
    String? error,
    bool requiredField = false,
    String? shown,
  }) {
    final String value = shown ?? controller.text;
    final bool bad = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthFieldLabel(label, requiredField: requiredField),
        const SizedBox(height: Spacing.sm),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: requiredField
              ? strings.authWizardPickerRequired(label)
              : label,
          value: value.isEmpty ? strings.authWizardNotChosen : value,
          // The children are excluded, so the action is given here or a
          // screen reader could not open the list.
          onTap: onTap,
          excludeSemantics: true,
          child: Material(
            color: bad ? BrandColors.errorFill : BrandColors.softFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.field),
              side: bad
                  ? const BorderSide(
                      color: BrandColors.red,
                      width: FocusRing.borderWidth,
                    )
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: tapKey,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ComponentSizes.fieldHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                  child: Row(
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        TaytayIcon(
                          icon: icon,
                          semanticLabel: '',
                          excludeSemantics: true,
                          size: IconSizes.sm,
                          color: BrandColors.muted,
                        ),
                        const SizedBox(width: Spacing.md),
                      ],
                      Expanded(
                        child: Text(
                          value.isEmpty ? placeholder : value,
                          style: AppTypography.fieldValue.copyWith(
                            fontWeight: value.isEmpty
                                ? AppTypography.body
                                : AppTypography.medium,
                            color: value.isEmpty
                                ? BrandColors.muted
                                : BrandColors.ink,
                          ),
                        ),
                      ),
                      const TaytayIcon(
                        icon: TaytayIcons.chevronDown,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.sm,
                        color: BrandColors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (bad)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              error,
              style: AppTypography.fieldHelp.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.redInk,
              ),
            ),
          ),
      ],
    );
  }
}

/// A 44 px gradient tile with a line icon (CSS `.gt`).
class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final BrandGradient tile = BrandGradients.tile(TileTone.blue);
    return Container(
      width: ComponentSizes.tile,
      height: ComponentSizes.tile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: tile.toLinearGradient(),
        borderRadius: BorderRadius.circular(Radii.tile),
      ),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: '',
        excludeSemantics: true,
        size: IconSizes.sm,
        color: tile.onColor,
      ),
    );
  }
}

/// A small status pill: gold "Pending review", or green with a check.
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, {this.done = false});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color ink = done ? BrandColors.green : BrandColors.goldInk;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: done ? BrandColors.green50 : BrandColors.gold50,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xxs,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TaytayIcon(
              icon: done ? TaytayIcons.circleCheck : TaytayIcons.clock,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xs,
              color: ink,
            ),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.pill.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RegID `.namechk`: the name on the account, and the sentence that the ID
/// must show it, before any photo is sent (D-195).
class _NameCheckCard extends StatelessWidget {
  const _NameCheckCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final String initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    return SoftCard(
      filled: true,
      padding: const EdgeInsets.all(Spacing.sm - Spacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (name.isNotEmpty)
            SoftCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.section,
                vertical: Spacing.md,
              ),
              radius: Radii.lg,
              child: Row(
                children: <Widget>[
                  ExcludeSemantics(
                    child: Container(
                      width: ComponentSizes.avatar,
                      height: ComponentSizes.avatar,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: BrandColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: AppTypography.listTitle.copyWith(
                          fontWeight: AppTypography.black,
                          color: BrandColors.navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.authWizardNameOnAccount,
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.medium,
                            color: BrandColors.muted,
                          ),
                        ),
                        Text(
                          name,
                          style: AppTypography.listTitle.copyWith(
                            fontWeight: AppTypography.strong,
                            color: BrandColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    strings.profNameBeforeSendingTitle,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm - Spacing.xxs),
                Text(
                  strings.profNameBeforeSending,
                  style: AppTypography.listDetail.copyWith(
                    color: BrandColors.muted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keys for the Privacy Notice card on the terms step.
const Key wizardNoticePublishedKey = Key('wizard-notice-published');
const Key wizardNoticeDraftKey = Key('wizard-notice-draft');
const Key wizardNoticeFailedKey = Key('wizard-notice-failed');

/// What the Privacy Notice card says while Taytay LGU has published none.
/// The English default; the card reads `authWizardNoticeDraftPill`.
const String wizardNoticeDraftPill = 'DRAFT · Not yet published by Taytay LGU';

/// RegTerms `.pn`: the Privacy Notice the resident acknowledges below it.
///
/// The text is the one `GET /app/config` publishes (`privacy_notice`), with
/// its version and date, drawn where it is agreed to, as the selfie's consent
/// is (D-209). While the API answers the `placeholder` version the card says
/// the notice is not published and keeps the summary marked as a draft; a
/// failed read is said as a failure with Try again, never as "not published"
/// (D-221). A design frame reads nothing and shows the draft (D-228).
class _PrivacyNoticeCard extends StatefulWidget {
  const _PrivacyNoticeCard({this.load});

  /// `GET /app/config`. Null in a design frame.
  final Future<Result<AppBootstrap>> Function()? load;

  @override
  State<_PrivacyNoticeCard> createState() => _PrivacyNoticeCardState();
}

class _PrivacyNoticeCardState extends State<_PrivacyNoticeCard> {
  bool _loading = false;
  PrivacyNotice? _notice;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loading = widget.load != null;
    unawaited(_read());
  }

  Future<void> _read() async {
    final Future<Result<AppBootstrap>> Function()? load = widget.load;
    if (load == null) return;
    if (!_loading) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    final Result<AppBootstrap> result = await load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok<AppBootstrap>(:final value):
          _notice = value.privacyNotice;
        case Err<AppBootstrap>():
          _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final PrivacyNotice? notice = _notice;
    final Widget body;
    if (_loading) {
      body = LoadingSkeleton(
        layout: SkeletonLayout.text,
        count: 4,
        semanticLabel: strings.authWizardNoticeLoading,
      );
    } else if (_failed) {
      body = SoftNote(
        key: wizardNoticeFailedKey,
        tone: NoteTone.error,
        heading: strings.authWizardNoticeFailedHeading,
        message: strings.authWizardNoticeFailedBody,
        action: AuthLink(
          strings.actionTryAgain,
          onPressed: () => unawaited(_read()),
        ),
      );
    } else if (notice != null && notice.isPublished) {
      final DateTime? updated = notice.updatedAt;
      final String version = strings.authWizardNoticeVersion(
        notice.version.trim(),
      );
      body = Column(
        key: wizardNoticePublishedKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _NoticePill(
            text: updated == null
                ? version
                : strings.authWizardNoticeUpdated(
                    version,
                    manilaDate(context, updated),
                  ),
            published: true,
          ),
          const SizedBox(height: Spacing.section),
          NoticeTextColumn(markdown: notice.bodyMarkdown),
        ],
      );
    } else {
      body = const _DraftSummary(key: wizardNoticeDraftKey);
    }
    return SoftCard(
      filled: true,
      radius: Radii.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _GradientIcon(icon: TaytayIcons.shieldCheck),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        'Privacy Notice',
                        style: AppTypography.listTitle.copyWith(
                          fontWeight: AppTypography.strong,
                          color: BrandColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      'Republic Act No. 10173 – Data Privacy Act of 2012',
                      style: AppTypography.small.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.section),
          body,
        ],
      ),
    );
  }
}

/// The version line over the published notice, or the draft marker.
class _NoticePill extends StatelessWidget {
  const _NoticePill({required this.text, required this.published});

  final String text;
  final bool published;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: published ? BrandColors.green50 : BrandColors.gold50,
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + Spacing.xxs,
            vertical: Spacing.xs,
          ),
          child: Text(
            text,
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.black,
              color: published ? BrandColors.green : BrandColors.goldInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's own summary, shown only while no notice is published and
/// marked as a draft: it is not the LGU's text.
class _DraftSummary extends StatelessWidget {
  const _DraftSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle point = AppTypography.listDetail.copyWith(
      color: BrandColors.text,
      height: 1.5,
    );
    final TextStyle pointTitle = AppTypography.listDetail.copyWith(
      fontWeight: AppTypography.strong,
      color: BrandColors.blue,
    );
    Widget item(String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: pointTitle),
          const SizedBox(height: Spacing.xxs),
          Text(body, style: point),
        ],
      ),
    );
    const Widget divider = Divider(
      height: 1,
      thickness: 1,
      color: BrandColors.divider,
    );
    final AppStrings strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _NoticePill(text: strings.authWizardNoticeDraftPill, published: false),
        const SizedBox(height: Spacing.section),
        Text(
          strings.authWizardDraftIntro,
          style: AppTypography.bodyStyle.copyWith(
            color: BrandColors.text,
            height: 1.55,
          ),
        ),
        const SizedBox(height: Spacing.section),
        SoftCard(
          radius: Radii.lg,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              item(
                strings.authWizardDraftUseTitle,
                strings.authWizardDraftUseBody,
              ),
              divider,
              item(
                strings.authWizardDraftWhoTitle,
                strings.authWizardDraftWhoBody,
              ),
              divider,
              item(
                strings.authWizardDraftRightsTitle,
                strings.authWizardDraftRightsBody,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// RegTerms `.rd`: the two full documents, one 54 px row each.
class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Semantics(
      container: true,
      label: strings.authWizardFullDocuments,
      child: Material(
        color: BrandColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            _LegalLink(
              key: const Key('terms-read-full'),
              icon: TaytayIcons.fileText,
              label: strings.authWizardReadTerms,
              onPressed: onTerms,
            ),
            const Divider(height: 1, thickness: 1, color: BrandColors.line),
            _LegalLink(
              key: const Key('privacy-read-full'),
              icon: TaytayIcons.shield,
              label: strings.authWizardReadPrivacy,
              onPressed: onPrivacy,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // A row that opens a text is one button reading its words.
    return Semantics(
      button: true,
      container: true,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ComponentSizes.fieldHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.section),
            child: Row(
              children: <Widget>[
                TaytayIcon(
                  icon: icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: BrandColors.blue,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.blue,
                    ),
                  ),
                ),
                const TaytayIcon(
                  icon: TaytayIcons.chevronRight,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: BrandColors.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// RegSelfie `.cam`: a drawn guide, never a photograph of a person, with
/// gold corner marks and a dashed oval that turns green once a selfie is in.
class _SelfieGuide extends StatelessWidget {
  const _SelfieGuide({required this.taken});

  final bool taken;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Semantics(
      image: true,
      label: taken
          ? strings.authWizardSelfieGuideTaken
          : strings.authWizardSelfieGuide,
      excludeSemantics: true,
      child: SizedBox(
        height: _camHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: BrandGradients.header.toLinearGradient(),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: _SelfieGuidePainter(taken: taken)),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: -Spacing.xl,
                child: Center(
                  child: TaytayIcon(
                    icon: TaytayIcons.userRound,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: _personSize,
                    color: BrandColors.onHeaderLede,
                  ),
                ),
              ),
              if (taken)
                const Positioned(
                  right: Spacing.xl + Spacing.xs,
                  top: Spacing.xl + Spacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrandColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.sm),
                      child: TaytayIcon(
                        icon: TaytayIcons.check,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.sm + Spacing.xxs,
                        color: BrandColors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: Spacing.section,
                child: Center(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: BrandColors.navy.withValues(alpha: 0.75),
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm + Spacing.xxs,
                        vertical: Spacing.xs,
                      ),
                      child: Text(
                        strings.authWizardIllustration,
                        style: AppTypography.tiny.copyWith(
                          fontWeight: AppTypography.medium,
                          color: BrandColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.cam { height: 300px }`, and the drawn head-and-shoulders inside it.
const double _camHeight = 300;
const double _personSize = 200;

/// The oval guide and the four gold corner marks of `.cam`.
class _SelfieGuidePainter extends CustomPainter {
  const _SelfieGuidePainter({required this.taken});

  final bool taken;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = Spacing.lg;
    const double arm = 26;
    const double stroke = 3;
    final Paint corner = Paint()
      ..color = BrandColors.gold
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (double x, double y, double dx, double dy)
        in <(double, double, double, double)>[
          (inset, inset, 1, 1),
          (size.width - inset, inset, -1, 1),
          (inset, size.height - inset, 1, -1),
          (size.width - inset, size.height - inset, -1, -1),
        ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + arm * dx, y), corner)
        ..drawLine(Offset(x, y), Offset(x, y + arm * dy), corner);
    }
    final Rect oval = Rect.fromCenter(
      center: Offset(size.width / 2, 34 + 106),
      width: 164,
      height: 212,
    );
    final Paint guide = Paint()
      ..color = taken
          ? BrandColors.green50
          : BrandColors.white.withValues(alpha: 0.9)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    if (taken) {
      canvas.drawOval(oval, guide);
      return;
    }
    final Path path = Path()..addOval(oval);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 9), guide);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelfieGuidePainter oldDelegate) =>
      oldDelegate.taken != taken;
}

/// One RegSelfie tip (CSS `.tips li`): a green disc with its icon, and the
/// sentence.
class _SelfieTip extends StatelessWidget {
  const _SelfieTip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(
            color: BrandColors.green50,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xs + Spacing.xxs),
            child: TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xxs,
              color: BrandColors.green,
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
          ),
        ),
      ],
    );
  }
}

/// The kinds of ID `POST /me/verification-requests` accepts for `id_type`.
/// Pops the wire value.
class _IdTypeSheet extends StatelessWidget {
  const _IdTypeSheet({required this.selectedLabel});

  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final String wire in verificationIdTypes)
          PickerChoiceRow(
            rowKey: Key('id-type-$wire'),
            label: localisedIdTypeLabel(AppStrings.of(context), wire),
            selected: idTypeLabel(wire) == selectedLabel,
            onTap: () => Navigator.of(context).pop(wire),
          ),
      ],
    );
  }
}

/// Equal only to the same object, for the submit key's content: a photo
/// picked again is a new attempt even when its bytes match.
@immutable
final class _SameObject {
  const _SameObject(this.value);

  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is _SameObject && identical(other.value, value);

  @override
  int get hashCode => identityHashCode(value);
}
