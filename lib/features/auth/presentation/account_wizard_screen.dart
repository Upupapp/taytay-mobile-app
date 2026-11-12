import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/barangay_picker.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/legal_text_sheet.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../platform/domain/app_bootstrap.dart';
import '../../profile/domain/name_lock.dart';
import '../../registration/domain/registration_domain.dart';
import '../../verification/domain/verification_id_type.dart';
import '../../verification/domain/verification_submit_outcome.dart';
import '../domain/account_application.dart';
import '../domain/auth_repository.dart';
import '../domain/code_exchange.dart';
import '../domain/sign_in_challenge.dart';
import 'auth_bits.dart';

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
  final _idType = TextEditingController(text: 'PhilSys National ID');
  final _summary = FocusNode();
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
    if (oldWidget.fixture != widget.fixture) _applyFixture();
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
    _status = widget.fixture == AccountFixture.codeNotSent
        ? _codeNotSentCopy(const ServerFailure(isTemporary: true))
        : null;
    _errors = widget.fixture == AccountFixture.errors
        ? _personalErrors()
        : <String, String>{};
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  int get _dot {
    return switch (_step) {
      _Step.personal || _Step.account || _Step.code => 1,
      _Step.terms => 2,
      _Step.idCard => 3,
      _Step.selfie => 4,
      _Step.review => 5,
      _Step.submitted => 6,
    };
  }

  Map<String, String> _personalErrors() {
    final errors = <String, String>{};
    if (_first.text.trim().isEmpty) errors['first'] = 'Required';
    if (_last.text.trim().isEmpty) errors['last'] = 'Required';
    final mobile = _mobile.text.replaceAll(' ', '');
    if (!RegExp(r'^09\d{9}$').hasMatch(mobile)) {
      errors['mobile'] = 'Enter an 11-digit mobile number starting with 09.';
    }
    if (_barangayId == null || _barangay.text.trim().isEmpty) {
      errors['barangay'] = 'Choose your barangay.';
    }
    return errors;
  }

  Map<String, String> _accountErrors() {
    final errors = <String, String>{};
    if (_accountCreated) return errors;
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email, e.g. name@example.com';
    }
    if (_password.text.length < 8) {
      errors['password'] = 'Use at least 8 characters.';
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
        if (!RegExp(r'^\d{6}$').hasMatch(code)) {
          setState(() => _status = 'Enter the 6-digit code.');
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
                _status = CodeAttemptView.unavailableCopy;
              } else if (next.limited) {
                _status = null;
                unawaited(_openHold(now, next.resendAt));
              } else if (next.wrong && next.attemptsRemaining != null) {
                _status =
                    'Mali ang code. ${next.attemptsRemaining} sa '
                    '${CodeExchangeRules.attempts} subok na lang ang natitira.';
              } else {
                _status = SignInFeedback.forFailure(failure).text;
              }
            });
        }
      case _Step.terms:
        if (!_terms || !_privacy) {
          setState(
            () => _status = !_terms && !_privacy
                ? 'Agree to the Terms of Use and acknowledge the Privacy '
                      'Notice: tick each one.'
                : !_terms
                ? 'Agree to the Terms of Use to continue.'
                : 'Acknowledge the Privacy Notice to continue.',
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
                  ? 'We could not confirm that your consent was recorded. '
                        'Agreeing again is safe: it is recorded only once.'
                  : 'Your consent was not recorded. ${failure.residentMessage}';
            });
            return;
          }
          _consented = true;
          // The account was opened a few steps ago with nothing agreed yet.
          // Asking again now clears the re-consent gate with the server's
          // word rather than this screen's.
          unawaited(dependencies.consentGate.check());
        }
        setState(() {
          _busy = false;
          _status = null;
          _step = _after(_Step.idCard);
        });
      case _Step.idCard:
        if (_front == null && widget.fixture == AccountFixture.live) {
          setState(() => _status = 'Add a photo of the front of your ID.');
          return;
        }
        setState(() {
          _status = null;
          _step = _after(_Step.selfie);
        });
      case _Step.selfie:
        if (_selfieShot == null && widget.fixture == AccountFixture.live) {
          setState(() => _status = 'Take a selfie to continue.');
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
        setState(() {
          _busy = false;
          switch (failure) {
            case ConflictFailure():
              _errors = <String, String>{
                'email': 'This email already has a Taytay account.',
              };
              _status =
                  'An account with this email already exists. Sign in '
                  'instead, or use another email.';
            case final ValidationFailure weak
                when weak.fieldErrors.containsKey('password'):
              // Firebase's weak-password refusal, worded by this app.
              _errors = <String, String>{
                'password':
                    weak.firstErrorFor('password') ??
                    'Use at least 8 characters.',
              };
              _status = null;
            case UnauthenticatedFailure():
              _errors = <String, String>{
                'email': 'Enter a valid email, e.g. name@example.com',
              };
              _status = null;
            default:
              _status = SignInFeedback.forFailure(failure).text;
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
    final String email = _email.text.trim().isEmpty
        ? 'your email'
        : _email.text.trim();
    final String next = switch (failure) {
      NetworkFailure() || TimeoutFailure() =>
        'Check your connection, then press Continue to try again.',
      _ => 'Press Continue to try again in a moment.',
    };
    return 'Your account is saved, but we could not send a code to $email. '
        '$next';
  }

  String _profileNotSavedCopy(AppFailure failure) {
    // `PATCH /me` sets each value outright, so sending it again is safe. After
    // a timeout the server may already hold them, and "not saved" would be a
    // guess.
    if (failure.outcomeUnknown) {
      return 'We could not confirm that your details were saved. Press '
          'Continue to send them again: it is safe to repeat.';
    }
    const String lead = 'Your details were not saved.';
    return switch (failure) {
      ValidationFailure() => '$lead Please check the highlighted details.',
      ConflictFailure() =>
        '$lead This email is already on another Taytay account. Please ask '
            'the municipal hall for help.',
      _ => '$lead ${failure.residentMessage}',
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
    );
    final profile = await dependencies.authRepository.submitProfile(
      application,
    );
    if (!mounted) return;
    if (profile case Err<void>(:final failure)) {
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
            if (!home) _status = failure.residentMessage;
          });
          if (home) context.goNamed(AppRoute.home.routeName);
          return;
        case VerificationSubmitOutcome.opened:
        case VerificationSubmitOutcome.failed:
          setState(() {
            _busy = false;
            _status = failure.residentMessage;
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

  Future<void> _takeSelfie() async {
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
      title: _IdTypeSheet.title,
      builder: (BuildContext sheet) =>
          _IdTypeSheet(selectedLabel: _idType.text.trim()),
    );
    if (picked == null || !mounted) return;
    if (!verificationIdTypes.contains(picked)) return;
    setState(() => _idType.text = idTypeLabel(picked));
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
      pending: termsNotPublishedYet,
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
          '$privacyNoticeNotPublishedYet The summary on this step is a draft.',
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
    final (String title, String? subtitle) = _heading;
    return AuthFormPage(
      title: title,
      subtitle: subtitle,
      stepLabel: 'Step $_dot of 6',
      progress: _dot / 6,
      progressSemanticLabel: 'Create account progress',
      onBack: _back,
      backEnabled: !_busy,
      footer: _footer(),
      child: switch (_step) {
        _Step.personal => _personal(),
        _Step.account => _accountBody(),
        _Step.code => _emailCode(),
        _Step.terms => _termsBody(),
        _Step.idCard => _idBody(),
        _Step.selfie => _selfieBody(),
        _Step.review => _review(),
        _Step.submitted => const SizedBox.shrink(),
      },
    );
  }

  /// The wave header's title and supporting line for the step.
  (String, String?) get _heading {
    final String address = _email.text.trim().isEmpty
        ? 'your email'
        : _email.text.trim();
    return switch (_step) {
      _Step.personal => (
        'Tungkol sa iyo',
        'Basic details only. You can complete your full Resident Profile '
            'later.',
      ),
      _Step.account =>
        _accountCreated
            ? (
                'Account created',
                'You sign in with this email. Next we send a 6-digit code '
                    'to it.',
              )
            : (
                'Create your account',
                'You sign in with this email and password. Next we send a '
                    '6-digit code to the email.',
              ),
      _Step.code =>
        _codeExpired
            ? (
                'Nag-expire na ang code',
                'Valid lang ang code nang 10 minuto. Magpadala ng bago sa '
                    '$address.',
              )
            : (
                'Enter the 6-digit code',
                'We sent a code to $address. It expires in 10 minutes.',
              ),
      _Step.terms => ('Your data, protected', 'Terms at Privacy'),
      _Step.idCard => (
        'Upload a valid government ID',
        'The LGU uses it to confirm who you are. Make sure all four corners '
            'and your name are clear.',
      ),
      _Step.selfie => (
        'Take a quick selfie',
        'LGU staff compare it with your ID. It is not used as your profile '
            'photo.',
      ),
      _Step.review => ('Check your details', null),
      _Step.submitted => ('', null),
    };
  }

  Widget _footer() {
    if (_step == _Step.code && _codeExpired) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: 'Magpadala ng bagong code',
            onPressed: _busy ? null : _resendEmailCode,
          ),
          if (!_accountCreated)
            AuthLink(
              'Palitan ang email address',
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
            label: 'Confirm email',
            onPressed: _busy ? null : _continue,
          ),
          // Once the Firebase account exists its email is fixed, so the link
          // that sent the resident back to retype it is not offered.
          if (!_accountCreated)
            AuthLink(
              'Change email address',
              onPressed: () => setState(() => _step = _Step.account),
            ),
        ],
      );
    }
    final primary = switch (_step) {
      _Step.review => 'Submit for verification',
      _Step.account when !_accountCreated => 'Create my account',
      _ => 'Continue',
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

  String _fixCount(int count) =>
      'Please fix $count ${count == 1 ? 'field' : 'fields'} to continue.';

  Widget _personal() {
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
          _alert(_fixCount(count)),
        _box(
          'First name',
          _first,
          icon: TaytayIcons.user,
          error: _errors['first'],
          requiredField: true,
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          'Last name',
          _last,
          icon: TaytayIcons.user,
          error: _errors['last'],
          requiredField: true,
          autofillHints: const <String>[AutofillHints.familyName],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          NameCheckCopy.asPrinted,
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          'Mobile number',
          _mobile,
          icon: TaytayIcons.phone,
          error: _errors['mobile'],
          requiredField: true,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
        ),
        const SizedBox(height: Spacing.formGap),
        _picker(
          'Barangay',
          _barangay,
          icon: TaytayIcons.mapPin,
          error: _errors['barangay'],
          requiredField: true,
          placeholder: 'Choose',
          tapKey: const Key('barangay-picker'),
          onTap: _busy ? null : _chooseBarangay,
        ),
        const SizedBox(height: Spacing.formGap),
        _box(
          'Street / Purok',
          _street,
          icon: TaytayIcons.house,
          error: _errors['street'],
          hint: showAddress
              ? 'Address: ${_street.text.trim()}, Brgy. '
                    '${_barangay.text.trim()}, Taytay, Rizal'
              : null,
        ),
      ],
    );
  }

  /// Email and password: the Firebase account. Once it exists the email is
  /// fixed and the password is not shown again.
  Widget _accountBody() {
    final count = _errors.keys.where((k) => !_personalKeys.contains(k)).length;
    final String? status = _status;
    final String password = _password.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (status != null)
          _alert(status)
        else if (count > 0)
          _alert(_fixCount(count)),
        _box(
          'Email address',
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
          'Password',
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
                  showLabel: 'Show',
                  hideLabel: 'Hide',
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
                ('8+ characters', password.length >= 8),
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
              _status = CodeAttemptView.unavailableCopy;
            } else if (_attempt.limited) {
              _status = null;
              unawaited(_openHold(now, _attempt.resendAt));
            } else {
              _status = SignInFeedback.forFailure(failure).text;
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

  Widget _emailCode() {
    if (_codeExpired) return _emailCodeExpired();
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
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  style: AppTypography.tiny.copyWith(
                    color: BrandColors.transparent,
                  ),
                  decoration: bareField.copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        _resendRow(),
        _statusNote(),
      ],
    );
  }

  /// "Didn't get it?" and a real button, 48 dp. During the wait from the
  /// last `retry_after` the button is off and says how long is left. The
  /// server enforces that wait whatever this shows.
  Widget _resendRow() {
    final bool live = widget.fixture == AccountFixture.live;
    final DateTime now = DateTime.now();
    final bool ready = live && _attempt.canResendAt(now);
    final Duration left = _attempt.resendAt?.difference(now) ?? Duration.zero;
    final String label = ready
        ? 'Resend code'
        : live
        ? 'Resend in ${CodeExchangeRules.countdown(left)}'
        : 'Resend in 0:45';
    final TextStyle note = AppTypography.listDetail.copyWith(
      color: BrandColors.muted,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text("Didn't get it?", style: note),
        CodeResendButton(
          buttonKey: const Key('email-code-resend'),
          label: label,
          onPressed: ready && !_busy ? _resendEmailCode : null,
        ),
        Text('Check your spam folder too.', style: note),
      ],
    );
  }

  Widget _emailCodeExpired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SoftNote(
          tone: NoteTone.warning,
          title: 'Hindi na magagamit ang lumang code. ',
          message: 'Bago ang code, may 5 subok ka ulit.',
        ),
        const SizedBox(height: Spacing.formGap),
        const SixDigitRow(digits: '', dim: true),
        const SizedBox(height: Spacing.md),
        Text(
          'Puwede nang magpadala muli · Tingnan din ang spam folder',
          textAlign: TextAlign.center,
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
      ],
    );
  }

  Widget _termsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _PrivacyNoticeCard(),
        const SizedBox(height: Spacing.formGap),
        _LegalLinks(onTerms: _openTerms, onPrivacy: _openPrivacyNotice),
        const SizedBox(height: Spacing.formGap),
        ConsentCheckCard(
          value: _terms,
          onChanged: (value) => setState(() => _terms = value),
          label: termsConsentLabel,
        ),
        const SizedBox(height: Spacing.sm + Spacing.xxs),
        ConsentCheckCard(
          value: _privacy,
          onChanged: (value) => setState(() => _privacy = value),
          label: privacyConsentLabel,
        ),
        _statusNote(),
      ],
    );
  }

  Widget _idBody() {
    final attached = _front != null || widget.fixture == AccountFixture.idCard;
    final String name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _NameCheckCard(name: name),
        const SizedBox(height: Spacing.formGap),
        _picker(
          'Type of ID',
          _idType,
          icon: TaytayIcons.idCard,
          requiredField: true,
          placeholder: 'Choose',
          tapKey: const Key('id-type-picker'),
          onTap: _busy ? null : _chooseIdType,
        ),
        const SizedBox(height: Spacing.formGap),
        const AuthFieldLabel('Front of ID', requiredField: true),
        const SizedBox(height: Spacing.sm),
        if (attached)
          _attached(
            name: _front?.fileName ?? 'id_front.jpg',
            onChange: _pickFront,
          )
        else
          _UploadSlot(key: const Key('id-front-pick'), onPressed: _pickFront),
        const SizedBox(height: Spacing.formGap),
        const AuthFieldLabel('Back of ID (optional)'),
        const SizedBox(height: Spacing.sm),
        if (_idBack case final CapturedDocument back)
          _attached(name: back.fileName, onChange: _pickBack)
        else
          _UploadSlot(
            key: const Key('id-back-pick'),
            onPressed: widget.fixture == AccountFixture.live ? _pickBack : null,
          ),
        _statusNote(),
      ],
    );
  }

  /// A picked file (CSS `.file`): its name, "Attached", and Change. The
  /// photo itself is not drawn back on this screen.
  Widget _attached({required String name, required VoidCallback onChange}) {
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
                        'Attached',
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
          AuthLink('Change', onPressed: onChange),
        ],
      ),
    );
  }

  Widget _selfieBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SelfieGuide(taken: _selfie),
        const SizedBox(height: Spacing.formGap),
        const _SelfieTip(TaytayIcons.sun, 'Good light, facing the camera'),
        const SizedBox(height: Spacing.md),
        const _SelfieTip(
          TaytayIcons.scanFace,
          'Whole face visible: no sunglasses, mask or cap',
        ),
        const SizedBox(height: Spacing.md),
        const _SelfieTip(TaytayIcons.user, 'Only you in the photo'),
        const SizedBox(height: Spacing.formGap),
        SecondaryButton(
          label: 'Take selfie',
          icon: const TaytayIcon(
            icon: TaytayIcons.camera,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.blue,
          ),
          onPressed: widget.fixture == AccountFixture.live
              ? _takeSelfie
              : () => setState(() => _selfie = true),
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

  String get _idSummary {
    final type = _idType.text.trim();
    final captured =
        _front != null ||
        widget.fixture == AccountFixture.idCard ||
        widget.fixture == AccountFixture.selfie ||
        widget.fixture == AccountFixture.review ||
        widget.fixture == AccountFixture.submitted;
    final String sides = _idBack != null ? 'front and back' : 'front';
    if (type.isEmpty) return captured ? 'Captured: $sides' : 'Not added';
    return captured ? '$type · $sides' : type;
  }

  Widget _review() {
    final name = '${_first.text.trim()} ${_last.text.trim()}'.trim();
    final List<Widget> rows = <Widget>[
      _row('Name', name, _Step.personal),
      // The email is fixed with the account, so it has no Edit link.
      _row(
        'Email',
        _email.text.trim(),
        null,
        badge: _emailVerified ? 'Verified' : null,
      ),
      _row('Mobile', _mobile.text.trim(), _Step.personal),
      _row('Address', _addressLine, _Step.personal),
      _row(
        'Terms & Privacy Notice',
        _consented ? 'Agreed · consent given' : 'Not yet agreed',
        _Step.terms,
      ),
      _row('Valid ID', _idSummary, _Step.idCard),
      _row('Selfie', _selfie ? 'Taken' : 'Not taken', _Step.selfie),
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
    final String first = _first.text.trim();
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: SuccessScreen(
        mark: SuccessMarkStyle.medal,
        stepLabel: 'Step 6 of 6',
        progress: 1,
        progressSemanticLabel: 'Create account progress',
        showBack: true,
        onBack: _back,
        title: first.isEmpty ? "You're all set!" : "You're all set, $first!",
        message:
            'Your account is created and your details were sent to Taytay '
            'LGU for verification.',
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
                    'Account verification',
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                  const _StatusPill('Pending review'),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Taytay LGU staff check your ID and selfie at the municipal '
                "office, in the office's own system. You'll get a "
                'notification in this app when they decide. Meanwhile you '
                'can browse services and news.',
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.text,
                ),
              ),
            ],
          ),
        ),
        primaryLabel: 'Continue to app',
        onPrimary: _busy ? null : _continue,
      ),
    );
  }

  Widget _row(String label, String value, _Step? edit, {String? badge}) {
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
                'Edit',
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
    String label,
    TextEditingController controller, {
    required String placeholder,
    required Key tapKey,
    required VoidCallback? onTap,
    IconData? icon,
    String? error,
    bool requiredField = false,
  }) {
    final String value = controller.text;
    final bool bad = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthFieldLabel(label, requiredField: requiredField),
        const SizedBox(height: Spacing.sm),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: requiredField ? '$label, required' : label,
          value: value.isEmpty ? 'Not chosen' : value,
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

/// Add a photo (CSS `.add`): a dashed white box with a round plus.
class _UploadSlot extends StatelessWidget {
  const _UploadSlot({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color ink = onPressed == null ? BrandColors.muted : BrandColors.blue;
    return Material(
      color: BrandColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: CustomPaint(
          painter: const _DashedBorderPainter(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _uploadHeight),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DecoratedBox(
                    decoration: const ShapeDecoration(
                      color: BrandColors.blue50,
                      shape: CircleBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: TaytayIcon(
                        icon: TaytayIcons.plus,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.sm,
                        color: ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm - Spacing.xxs),
                  Text(
                    'Add a photo · JPG or PNG',
                    textAlign: TextAlign.center,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.add { min-height: 96px }`.
const double _uploadHeight = 96;

/// `.add { border: 2px dashed var(--line2); border-radius: 16px }`.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2;
    final Paint paint = Paint()
      ..color = BrandColors.line2
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(stroke / 2),
          const Radius.circular(Radii.lg),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

/// RegID `.namechk`: the name on the account, and the sentence that the ID
/// must show it, before any photo is sent (D-195).
class _NameCheckCard extends StatelessWidget {
  const _NameCheckCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
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
                          'Name on your account',
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
                    NameCheckCopy.beforeSendingTitle,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm - Spacing.xxs),
                Text(
                  NameCheckCopy.beforeSending,
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

/// RegTerms `.pn`: the privacy notice summary. The full notice is a tap away
/// ([_LegalLinks]); this card is marked a draft until the LGU approves it.
class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard();

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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: const ShapeDecoration(
                color: BrandColors.gold50,
                shape: StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm + Spacing.xxs,
                  vertical: Spacing.xs,
                ),
                child: Text(
                  'DRAFT · LGU-approved Privacy Notice to be inserted',
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.black,
                    color: BrandColors.goldInk,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.section),
          Text(
            'The Municipality of Taytay collects your name, contact details, '
            'address, valid ID and selfie to create and verify your resident '
            'account and to deliver municipal services you request.',
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
                  'How we use it',
                  'Identity and residency verification, service requests, '
                      'and notices from the LGU.',
                ),
                divider,
                item('Who can see it', 'Authorised Taytay LGU personnel only.'),
                divider,
                item(
                  'Your rights',
                  'To be informed, to access, correct, object and erase, and '
                      'to file a complaint with the National Privacy '
                      'Commission. Contact the LGU Data Protection Officer '
                      'for requests.',
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Semantics(
      container: true,
      label: 'Full documents',
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
              label: 'Read full Terms',
              onPressed: onTerms,
            ),
            const Divider(height: 1, thickness: 1, color: BrandColors.line),
            _LegalLink(
              key: const Key('privacy-read-full'),
              icon: TaytayIcons.shield,
              label: 'Read full Privacy Notice',
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
    return InkWell(
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
    return Semantics(
      image: true,
      label: taken
          ? 'Selfie guide, selfie taken. Illustration, no real person.'
          : 'Selfie guide. Illustration, no real person.',
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
                        'Illustration · no real person',
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

  static const String title = 'Type of ID';

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
            label: idTypeLabel(wire),
            selected: idTypeLabel(wire) == selectedLabel,
            onTap: () => Navigator.of(context).pop(wire),
          ),
      ],
    );
  }
}
