import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_thread.dart';
import '../../registration/domain/registration_domain.dart';
import '../../verification/domain/verification_submit_outcome.dart';
import '../domain/account_application.dart';
import '../domain/auth_repository.dart';
import '../domain/code_exchange.dart';
import '../domain/sign_in_challenge.dart';
import 'auth_bits.dart';
import 'auth_stage.dart';

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

/// Registration as `02-03` through `02-09`, and the `02-11` errors.
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

  String get _caption {
    return switch (_step) {
      _Step.personal => 'Personal info',
      _Step.account || _Step.code => 'Your account',
      _Step.terms => 'Terms & privacy',
      _Step.idCard => 'Valid ID',
      _Step.selfie => 'Selfie',
      _Step.review => 'Review',
      _Step.submitted => 'Submitted',
    };
  }

  bool _fieldOk(String key, String value) {
    if (value.trim().isEmpty) return false;
    if (_errors.isEmpty) return true;
    return !_errors.containsKey(key);
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
            () => _status = 'Agree to the Terms and the Privacy Notice.',
          );
          return;
        }
        if (widget.fixture == AccountFixture.live && !_consented) {
          setState(() {
            _busy = true;
            _status = null;
          });
          final Result<void> recorded = await AppDependencies.of(
            context,
          ).authRepository.recordConsents();
          if (!mounted) return;
          if (recorded case Err<void>(:final failure)) {
            setState(() {
              _busy = false;
              _status =
                  'Your consent was not recorded. ${failure.residentMessage}';
            });
            return;
          }
          _consented = true;
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

    final Barangay? picked = await showModalBottomSheet<Barangay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) =>
          _BarangaySheet(load: load, selectedId: _barangayId),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _barangayId = picked.id;
      _barangay.text = picked.name;
      _errors.remove('barangay');
    });
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _step == _Step.submitted;
    final showFooter = _step != _Step.code;
    final errors =
        (_step == _Step.personal || _step == _Step.account) &&
        (_errors.isNotEmpty || _status != null);
    final code = _step == _Step.code;
    return AuthStage(
      sheetTop: submitted
          ? 494
          : code
          ? 300
          : 150,
      sheetBottom: errors ? 34 : 20,
      wrapSheet: !submitted,
      arch: submitted ? AuthArch.submitted : AuthArch.none,
      step: submitted ? null : _dot,
      stepLabel: _caption,
      bleed: code,
      atmosphere: _atmosphere,
      curve: submitted ? ThreadCurve.submitted : ThreadCurve.wizard,
      onBack: _back,
      greeting: _first.text.trim(),
      footer: showFooter ? _footer() : null,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          code
              ? 24
              : submitted
              ? 18
              : 20,
          switch (_step) {
            _Step.code => 14,
            _Step.terms || _Step.idCard || _Step.selfie => 22,
            _Step.submitted => 16.3,
            _ => 18,
          },
          code
              ? 24
              : submitted
              ? 18
              : 20,
          submitted ? 18 : 22,
        ),
        child: switch (_step) {
          _Step.personal => _personal(),
          _Step.account => _accountBody(),
          _Step.code => _emailCode(),
          _Step.terms => _termsBody(),
          _Step.idCard => _idBody(),
          _Step.selfie => _selfieBody(),
          _Step.review => _review(),
          _Step.submitted => _pending(),
        },
      ),
    );
  }

  SignInAtmosphere get _atmosphere {
    return switch (_step) {
      _Step.personal =>
        widget.fixture == AccountFixture.errors
            ? SignInAtmosphere.errors
            : SignInAtmosphere.personal,
      _Step.account =>
        _status != null ? SignInAtmosphere.errors : SignInAtmosphere.personal,
      _Step.code =>
        _codeExpired ? SignInAtmosphere.codeExpired : SignInAtmosphere.code,
      _Step.terms => SignInAtmosphere.terms,
      _Step.idCard => SignInAtmosphere.idCard,
      _Step.selfie => SignInAtmosphere.selfie,
      _Step.review => SignInAtmosphere.review,
      _Step.submitted => SignInAtmosphere.submitted,
    };
  }

  Widget _footer() {
    final primary = switch (_step) {
      _Step.review => 'Submit for verification',
      _Step.submitted => 'Continue to app',
      _Step.account when !_accountCreated => 'Create my account',
      _ => 'Continue',
    };
    final showBack = _step != _Step.personal && _step != _Step.submitted;
    return Row(
      children: <Widget>[
        if (showBack)
          SizedBox(
            width: 110,
            child: SecondaryButton(
              kind: TaytayButtonKind.signIn,
              label: 'Back',
              onPressed: _back,
            ),
          ),
        if (showBack) const SizedBox(width: 10),
        Expanded(
          child: PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: primary,
            onPressed: _busy ? null : _continue,
          ),
        ),
      ],
    );
  }

  Widget _alert(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        focusable: true,
        child: Focus(
          focusNode: _summary,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const TaytayIcon(
                  icon: TaytayIcons.circleAlert,
                  semanticLabel: 'Error',
                  size: 16,
                  color: Color(0xFFB3261E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: AppTypography.strong,
                      color: Color(0xFF7A1C16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fixCount(int count) =>
      'Please fix $count ${count == 1 ? 'field' : 'fields'} to continue.';

  Widget _personal() {
    final count = _errors.keys.where(_personalKeys.contains).length;
    final String? status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthCopy(
          eyebrow: 'Personal information',
          title: 'Tungkol sa iyo',
          titleSize: 22,
          subtitleSize: 12,
          subtitle: count > 0 || status != null
              ? null
              : 'Basic details only. You can complete your full '
                    'Resident Profile later.',
        ),
        if (status != null)
          _alert(status)
        else if (count > 0)
          _alert(_fixCount(count)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _box(
                'First name',
                _first,
                error: _errors['first'],
                requiredField: true,
                ok: _fieldOk('first', _first.text),
                padTop: count > 0 ? 12 : 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _box(
                'Last name',
                _last,
                error: _errors['last'],
                requiredField: true,
                ok: _fieldOk('last', _last.text),
                padTop: count > 0 ? 12 : 14,
              ),
            ),
          ],
        ),
        _box(
          'Mobile number',
          _mobile,
          error: _errors['mobile'],
          requiredField: true,
          ok: _fieldOk('mobile', _mobile.text),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _box(
                'Barangay',
                _barangay,
                error: _errors['barangay'],
                requiredField: true,
                ok: _fieldOk('barangay', _barangay.text),
                padTop: 12 + 4 / 3,
                placeholder: 'Choose',
                tapKey: const Key('barangay-picker'),
                onTap: _busy ? null : _chooseBarangay,
                trailing: const TaytayIcon(
                  icon: TaytayIcons.chevronDown,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 16,
                  color: Color(0xFF5A6480),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _box(
                'Street / Purok',
                _street,
                error: _errors['street'],
                padTop: 12 + 4 / 3,
              ),
            ),
          ],
        ),
        if (_errors.isEmpty &&
            _street.text.isNotEmpty &&
            _barangay.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'Address: ${_street.text.trim()}, Brgy. ${_barangay.text.trim()}, '
              'Taytay, Rizal',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                color: Color(0xFF5B6680),
              ),
            ),
          ),
      ],
    );
  }

  /// Email and password: the Firebase account. Once it exists the email is
  /// fixed and the password is not shown again.
  Widget _accountBody() {
    final count = _errors.keys.where((k) => !_personalKeys.contains(k)).length;
    final String? status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthCopy(
          eyebrow: 'Your account',
          title: _accountCreated ? 'Account created' : 'Create your account',
          titleSize: 22,
          subtitleSize: 12,
          subtitle: count > 0 || status != null
              ? null
              : _accountCreated
              ? 'You sign in with this email. Next we send a 6-digit code '
                    'to it.'
              : 'You sign in with this email and password. Next we send a '
                    '6-digit code to the email.',
        ),
        if (status != null)
          _alert(status)
        else if (count > 0)
          _alert(_fixCount(count)),
        _box(
          'Email address',
          _email,
          error: _errors['email'],
          requiredField: true,
          readOnly: _accountCreated,
          ok: _accountCreated,
          focused: !_accountCreated && _errors.isEmpty,
          padTop: count > 0 || status != null ? 12 : 14,
        ),
        _box(
          'Password',
          _password,
          error: _errors['password'],
          padTop: 13.33 - 4 / 3,
          labelGap: 5,
          boxDy: 1.35,
          requiredField: true,
          obscure: _obscure,
          bad: _errors.containsKey('password'),
          readOnly: _accountCreated,
          previewMask: _accountCreated
              ? '••••••••'
              : widget.fixture != AccountFixture.live && _obscure
              ? '•••••••••••'
              : null,
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
          const SizedBox(height: 3),
          Wrap(
            spacing: 10,
            runSpacing: count > 0 ? 4 : 1.32,
            children: <Widget>[
              for (final rule in <(String, bool)>[
                ('8+ characters', _password.text.length >= 8),
                (
                  'Aa',
                  RegExp(r'[A-Z]').hasMatch(_password.text) &&
                      RegExp(r'[a-z]').hasMatch(_password.text),
                ),
                ('123', RegExp(r'\d').hasMatch(_password.text)),
                ('#!@', RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text)),
              ])
                _Chip(
                  rule.$1,
                  met: _password.text.isEmpty && _errors['password'] == null
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
      final Result<CodeAcceptance> sent = await AppDependencies.of(
        context,
      ).authRepository.sendEmailCode();
      if (!mounted) return;
      final DateTime now = DateTime.now();
      setState(() {
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
    final raw = _code.text.padRight(6);
    final address = _email.text.trim().isEmpty
        ? 'your email'
        : _email.text.trim();
    final nextEmpty = _code.text.length.clamp(0, 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(
          child: SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE0D6B8),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AuthCopy(
          eyebrow: 'I-verify ang email',
          title: 'Enter the 6-digit code',
          subtitle: 'We sent a code to $address. It expires in 10 minutes.',
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (var i = 0; i < 6; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _otp(
                      raw[i].trim(),
                      filled: i < _code.text.length,
                      focused: i == nextEmpty && i >= _code.text.length,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.fixture == AccountFixture.live)
              TextField(
                key: const Key('email-code-field'),
                controller: _code,
                maxLength: 6,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: bareField.copyWith(counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
          ],
        ),
        const SizedBox(height: 6.33),
        Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.body,
              color: Color(0xFF5B6680),
            ),
            children: <InlineSpan>[
              const TextSpan(text: "Didn't get it? "),
              TextSpan(
                text: widget.fixture == AccountFixture.live
                    ? (_attempt.canResendAt(DateTime.now())
                          ? 'Resend'
                          : 'Resend in ${CodeExchangeRules.countdown(_attempt.resendAt == null ? Duration.zero : _attempt.resendAt!.difference(DateTime.now()))}')
                    : 'Resend in 0:45',
                style: const TextStyle(
                  color: BrandColors.taytayBlue,
                  fontWeight: AppTypography.black,
                ),
              ),
              const TextSpan(text: ' · Check spam folder'),
            ],
          ),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _status!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BrandColors.danger,
                fontWeight: AppTypography.strong,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 20.67),
        PrimaryButton(
          kind: TaytayButtonKind.signIn,
          label: 'Confirm email',
          onPressed: _busy ? null : _continue,
        ),
        // Once the Firebase account exists its email is fixed, so the link
        // that sent the resident back to retype it is not offered.
        if (!_accountCreated) ...<Widget>[
          const SizedBox(height: 10),
          AuthTextLink(
            'Change email address',
            fontSize: 12,
            onPressed: () => setState(() => _step = _Step.account),
          ),
        ],
      ],
    );
  }

  Widget _emailCodeExpired() {
    final String address = _email.text.trim().isEmpty
        ? AuthSample.email
        : _email.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Center(
          child: SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE0D6B8),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AuthCopy(
          eyebrow: 'I-verify ang email',
          title: 'Nag-expire na ang code',
          subtitle:
              'Valid lang ang code nang 10 minuto. Magpadala ng bago sa $address.',
        ),
        const SizedBox(height: 12),
        const AuthNoticeBanner(
          amber: true,
          title: 'Hindi na magagamit ang lumang code. ',
          detail: 'Bago ang code, may 5 subok ka ulit.',
        ),
        const SizedBox(height: 16),
        const SixDigitRow(digits: ''),
        const SizedBox(height: 6),
        const Text(
          'Puwede nang magpadala muli · Tingnan din ang spam folder',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: AppTypography.body,
            color: Color(0xFF5B6680),
          ),
        ),
        const SizedBox(height: 15.67),
        PrimaryButton(
          kind: TaytayButtonKind.signIn,
          label: 'Magpadala ng bagong code',
          onPressed: _busy ? null : _resendEmailCode,
        ),
        if (!_accountCreated) ...<Widget>[
          const SizedBox(height: 26.33),
          AuthTextLink(
            'Palitan ang email address',
            fontSize: 12,
            onPressed: () => setState(() {
              _codeExpired = false;
              _step = _Step.account;
            }),
          ),
        ],
      ],
    );
  }

  Widget _otp(String digit, {required bool filled, required bool focused}) {
    final border = filled
        ? const Color(0xFF0F7A4D)
        : focused
        ? BrandColors.taytayBlue
        : BrandColors.fieldBorder;
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: focused ? Colors.white : BrandColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.4),
        boxShadow: focused
            ? const <BoxShadow>[
                BoxShadow(color: Color(0x1F0B3D91), spreadRadius: 3),
              ]
            : null,
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 22,
          fontWeight: AppTypography.black,
          color: BrandColors.fieldInk,
        ),
      ),
    );
  }

  Widget _termsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthCopy(
          eyebrow: 'Terms at Privacy',
          title: 'Your data, protected',
          titleSize: 22,
        ),
        const SizedBox(height: 10),
        const SizedBox(
          height: 290,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: ColoredBox(
              color: Color(0xFFF4F1E6),
              child: Stack(
                children: <Widget>[
                  Padding(
                    // 12px in the stylesheet. The shared eyebrow above this
                    // card paints one logical pixel short of CSS normal, so
                    // the notice starts one pixel lower and the links stay.
                    padding: EdgeInsets.fromLTRB(14, 13, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF4CC),
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              'DRAFT · LGU-approved Privacy Notice to be inserted',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                height: 17.05 / 11,
                                fontWeight: AppTypography.black,
                                color: Color(0xFF8A5A00),
                              ),
                              strutStyle: StrutStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                height: 17.05 / 11,
                                forceStrutHeight: true,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(child: _TermsNotice()),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x00F4F1E6), Color(0xFFF4F1E6)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: <Widget>[
            Flexible(
              child: Text(
                'Read full Terms ›',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.black,
                  color: BrandColors.taytayBlue,
                ),
              ),
            ),
            SizedBox(width: 14),
            Flexible(
              child: Text(
                'Read full Privacy Notice ›',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.black,
                  color: BrandColors.taytayBlue,
                ),
              ),
            ),
          ],
        ),
        _check(
          'I have read and agree to the Terms of Use and the Privacy Notice.',
          _terms,
          (value) => setState(() => _terms = value),
          top: 10,
        ),
        _check(
          'I consent to Taytay LGU processing my personal data for account verification.',
          _privacy,
          (value) => setState(() => _privacy = value),
          top: 0,
        ),
        if (_status != null)
          Text(_status!, style: const TextStyle(color: BrandColors.danger)),
      ],
    );
  }

  Widget _idBody() {
    final attached = _front != null || widget.fixture == AccountFixture.idCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthCopy(
          eyebrow: 'Valid ID',
          title: 'Upload a valid government ID',
          titleSize: 22,
          subtitleSize: 12,
          subtitle:
              'The LGU uses it to confirm who you are. Make sure all four '
              'corners and your name are clear.',
        ),
        _box(
          'Type of ID',
          _idType,
          requiredField: true,
          readOnly: true,
          ok: true,
          padTop: 13.67,
          trailing: const TaytayIcon(
            icon: TaytayIcons.chevronDown,
            semanticLabel: 'ID types',
            size: 16,
            color: Color(0xFF5A6480),
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Front of ID', requiredField: true),
        const SizedBox(height: 2.67),
        if (attached) ...<Widget>[
          _attached(
            name: _front?.fileName ?? 'id_front.jpg',
            onChange: _pickFront,
          ),
          const SizedBox(height: 1),
        ] else
          _UploadSlot(key: const Key('id-front-pick'), onPressed: _pickFront),
        const SizedBox(height: 12),
        const _FieldLabel('Back of ID (optional)'),
        const SizedBox(height: 5),
        if (_idBack case final CapturedDocument back)
          _attached(name: back.fileName, onChange: _pickBack)
        else
          _UploadSlot(
            key: const Key('id-back-pick'),
            onPressed: widget.fixture == AccountFixture.live ? _pickBack : null,
          ),
        if (_status != null)
          Text(_status!, style: const TextStyle(color: BrandColors.danger)),
      ],
    );
  }

  Widget _attached({required String name, required VoidCallback onChange}) {
    return CustomPaint(
      foregroundPainter: const _DashedRoundPainter(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SampleIdCard(),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14.66),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: AppTypography.strong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: <Widget>[
                          TaytayIcon(
                            icon: TaytayIcons.circleCheck,
                            semanticLabel: '',
                            excludeSemantics: true,
                            size: 13,
                            color: Color(0xFF0F7A4D),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Attached',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: AppTypography.strong,
                                color: Color(0xFF0F7A4D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8 / 3),
                      _ChangeLink(onPressed: onChange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selfieBody() {
    return Column(
      children: <Widget>[
        const AuthCopy(
          eyebrow: 'Selfie',
          title: 'Take a quick selfie',
          titleSize: 22,
          subtitleSize: 12,
          centered: true,
          subtitle:
              'LGU staff compare it with your ID. It is not used as your '
              'profile photo.',
        ),
        const SizedBox(height: 16),
        const _SelfieFrame(),
        const SizedBox(height: 16),
        const SizedBox(
          width: 270,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SelfieRule(
                TaytayIcons.sun,
                'Good light, facing the camera',
                bottom: 2 - 4 / 3,
              ),
              _SelfieRule(
                TaytayIcons.scanFace,
                'Whole face visible: no sunglasses, mask or',
                tail: 'cap',
                tailGap: 3,
                bottom: 2 - 5 / 3,
              ),
              _SelfieRule(TaytayIcons.user, 'Only you in the photo'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 220,
          child: GoldButton(
            label: 'Take selfie',
            icon: const TaytayIcon(
              icon: TaytayIcons.camera,
              semanticLabel: '',
              excludeSemantics: true,
              size: 18,
              color: BrandColors.taytayBlueDark,
            ),
            onPressed: widget.fixture == AccountFixture.live
                ? _takeSelfie
                : () => setState(() => _selfie = true),
          ),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _status!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BrandColors.danger),
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthCopy(
          eyebrow: 'Review',
          title: 'Check your details',
          titleSize: 22,
        ),
        const SizedBox(height: 7.67),
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
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _status!,
              style: const TextStyle(color: BrandColors.danger),
            ),
          ),
      ],
    );
  }

  Widget _pending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Account verification',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: AppTypography.black,
                  color: BrandColors.taytayBlueDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Pending review',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: AppTypography.black,
                  color: Color(0xFF8A5A00),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.7),
        const Text(
          'Taytay LGU staff check your ID and selfie at the municipal '
          "office, in the office's own system. You'll get a notification "
          'in this app when they decide. Meanwhile you can browse services '
          'and news.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            height: 1.53,
            color: Color(0xFF4A5470),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, _Step? edit, {String? badge}) {
    return CustomPaint(
      foregroundPainter: const _RowDashPainter(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x00EADFC0), width: 1.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: AppTypography.strong,
                      color: Color(0xFF5B6680),
                    ),
                  ),
                  // CSS margin-top is 2px. Flutter's line box leaves the
                  // value ink 1.7dp lower than that margin's top, so the
                  // margin is split around the text and the next row stays.
                  const SizedBox(height: 0.3),
                  Text.rich(
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: AppTypography.strong,
                        color: BrandColors.fieldInk,
                      ),
                      children: <InlineSpan>[
                        if (badge != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4EC),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const TaytayIcon(
                                    icon: TaytayIcons.circleCheck,
                                    semanticLabel: '',
                                    excludeSemantics: true,
                                    size: 11,
                                    color: Color(0xFF0F7A4D),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    badge,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11,
                                      fontWeight: AppTypography.black,
                                      color: Color(0xFF0F7A4D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1.7),
                ],
              ),
            ),
            if (edit != null)
              Padding(
                padding: const EdgeInsets.only(top: 8 / 3),
                child: _EditLink(
                  onPressed: () => setState(() {
                    _returnToReview = true;
                    _status = null;
                    _step = edit;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _check(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    double top = 10,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? BrandColors.taytayBlue : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: value
                      ? null
                      : Border.all(color: BrandColors.fieldBorder, width: 1.4),
                ),
                child: value
                    ? const TaytayIcon(
                        icon: TaytayIcons.check,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: 14,
                        color: Color(0xFFFCD116),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1.3),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: AppTypography.medium,
                      color: BrandColors.fieldInk,
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

  Widget _tapArea({
    required bool picker,
    required String label,
    required String value,
    required bool requiredField,
    required VoidCallback? onTap,
    required Key? tapKey,
    required Widget child,
  }) {
    if (!picker) return child;
    return OverflowBox(
      alignment: Alignment.center,
      minHeight: A11y.minTapTarget,
      maxHeight: A11y.minTapTarget,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: requiredField ? '$label, required' : label,
        value: value.isEmpty ? 'Not chosen' : value,
        // The children are excluded, so the action is given here or a
        // screen reader could not open the list.
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: tapKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: A11y.minTapTarget, child: child),
          ),
        ),
      ),
    );
  }

  Widget _box(
    String label,
    TextEditingController controller, {
    String? error,
    bool requiredField = false,
    bool ok = false,
    bool focused = false,
    bool obscure = false,
    bool bad = false,
    bool readOnly = false,
    String? previewMask,
    Widget? trailing,
    double padTop = 12,
    double labelGap = 5,
    double boxDy = 0,
    VoidCallback? onTap,
    String? placeholder,
    Key? tapKey,
  }) {
    // A picker draws its value as text and is one 48 dp button, rather than a
    // text field a resident could type a barangay name into.
    final bool picker = placeholder != null;
    final border = bad || error != null
        ? BrandColors.danger
        : focused
        ? BrandColors.taytayBlue
        : ok
        ? const Color(0xFF0F7A4D)
        : BrandColors.fieldBorder;
    return Padding(
      padding: EdgeInsets.only(top: padTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              text: label,
              style: AppTypography.label.copyWith(
                color: BrandColors.fieldLabel,
              ),
              children: <InlineSpan>[
                if (requiredField)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: BrandColors.danger),
                  ),
              ],
            ),
          ),
          SizedBox(height: labelGap),
          Padding(
            padding: EdgeInsets.only(top: boxDy),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: error != null
                    ? const Color(0xFFFFF7F7)
                    : focused
                    ? Colors.white
                    : BrandColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.4),
                boxShadow: focused
                    ? const <BoxShadow>[
                        BoxShadow(color: Color(0x1F0B3D91), spreadRadius: 3),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: 44,
                child: _tapArea(
                  picker: picker,
                  label: label,
                  value: controller.text,
                  requiredField: requiredField,
                  onTap: onTap,
                  tapKey: tapKey,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: picker
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  controller.text.isEmpty
                                      ? placeholder
                                      : controller.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: controller.text.isEmpty
                                      ? AppTypography.fieldValue.copyWith(
                                          color: const Color(0xFF5B6680),
                                        )
                                      : AppTypography.fieldValue,
                                ),
                              )
                            : previewMask != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  previewMask,
                                  style: AppTypography.fieldValue,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: AuthBareField(
                                  controller: controller,
                                  readOnly: readOnly,
                                  obscureText: obscure,
                                ),
                              ),
                      ),
                      ?trailing,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 5.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const TaytayIcon(
                        icon: TaytayIcons.circleAlert,
                        semanticLabel: 'Error',
                        size: 14,
                        color: Color(0xFFB3261E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            height: 1.2,
                            fontWeight: AppTypography.strong,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1.2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.met});

  final String label;

  /// Null until the resident has typed a password.
  final bool? met;

  @override
  Widget build(BuildContext context) {
    final color = switch (met) {
      true => const Color(0xFF0F7A4D),
      false => const Color(0xFFB3261E),
      null => const Color(0xFF5B6680),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (met != null)
          TaytayIcon(
            icon: met! ? TaytayIcons.check : TaytayIcons.close,
            semanticLabel: '',
            excludeSemantics: true,
            size: 12,
            color: color,
          ),
        if (met != null) const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: AppTypography.strong,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.requiredField = false});

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AppTypography.label.copyWith(color: BrandColors.fieldLabel),
        children: <InlineSpan>[
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: BrandColors.danger),
            ),
        ],
      ),
    );
  }
}

class _UploadSlot extends StatelessWidget {
  const _UploadSlot({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: const CustomPaint(
          painter: _DashedRoundPainter(),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TaytayIcon(
                  icon: TaytayIcons.plus,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 16,
                  color: BrandColors.taytayBlue,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add a photo · JPG or PNG',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: AppTypography.black,
                      color: BrandColors.taytayBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundPainter extends CustomPainter {
  const _DashedRoundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFC9A227);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 5, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundPainter oldDelegate) => false;
}

/// A drawn stand-in for the sample ID. No photograph of a person.
class _SampleIdCard extends StatelessWidget {
  const _SampleIdCard();

  @override
  Widget build(BuildContext context) {
    // Design thumbnail is 120×77 logical, sitting 5 below the previous top so
    // its bottom stays on the red run the line bar already matches.
    return const Padding(
      padding: EdgeInsets.only(top: 5),
      child: SizedBox(
        width: 120,
        height: 77,
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFDFE8F7), Color(0xFFF7F1DF)],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 8,
                  top: 16,
                  width: 28,
                  height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFB8C4D8),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                Positioned(left: 44, top: 18, child: _IdLine(width: 60)),
                Positioned(
                  left: 44,
                  top: 28,
                  child: _IdLine(width: 48, color: Color(0xFFB8C4D8)),
                ),
                Positioned(
                  left: 44,
                  top: 38,
                  child: _IdLine(width: 40, color: Color(0xFFB8C4D8)),
                ),
                Positioned(
                  right: -2,
                  bottom: 2 + 29 / 3 + 1,
                  child: _SampleRibbon(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 'Edit' on the label's top edge. The 48dp hit target hangs below the line.
class _EditLink extends StatelessWidget {
  const _EditLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 16,
      child: OverflowBox(
        maxWidth: 80,
        maxHeight: 48,
        alignment: Alignment.topRight,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.taytayBlue,
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.topRight,
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.black,
            ),
          ),
          onPressed: onPressed,
          child: const Text('Edit'),
        ),
      ),
    );
  }
}

/// 'Change' under the readable line. Layout height is the line; the hit
/// target is 48dp.
class _ChangeLink extends StatelessWidget {
  const _ChangeLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 16,
      child: OverflowBox(
        maxWidth: 96,
        maxHeight: 48,
        alignment: Alignment.topLeft,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.taytayBlue,
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.topLeft,
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.black,
            ),
          ),
          onPressed: onPressed,
          child: const Text('Change'),
        ),
      ),
    );
  }
}

/// Light dashed hairline along the bottom of a review row.
class _RowDashPainter extends CustomPainter {
  const _RowDashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEADFC0)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    final double y = size.height - 0.5;
    var x = 0.0;
    while (x < size.width) {
      final double end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RowDashPainter oldDelegate) => false;
}

class _SampleRibbon extends StatelessWidget {
  const _SampleRibbon();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.46,
      alignment: Alignment.bottomRight,
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFB3261E)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            'SAMPLE',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 8,
              letterSpacing: 0.6,
              fontWeight: AppTypography.black,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _IdLine extends StatelessWidget {
  const _IdLine({required this.width, this.color = const Color(0xFF9AA6BC)});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );
  }
}

class _SelfieFrame extends StatelessWidget {
  const _SelfieFrame();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(95),
      topRight: Radius.circular(95),
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    );
    return const SizedBox(
      width: 190,
      height: 230,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFDFE6F2), Color(0xFFC9D3E6)],
          ),
          // Same order as the auth arches: the white ring paints last.
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x33062358),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
            BoxShadow(color: Colors.white, spreadRadius: 4),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 62,
              top: 52,
              width: 66,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF9FB0CC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 30,
              top: 140,
              width: 130,
              height: 110,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF9FB0CC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(65)),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10 - 5 / 3,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      'Illustration · no real person',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: AppTypography.black,
                        color: BrandColors.taytayBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  static const TextStyle _style = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.55,
    color: Color(0xFF3A4560),
  );

  /// 12px at line-height 1.55. CSS `normal` is not this step; the notice sets 1.55.
  static const double _step = 18.6;

  static const StrutStyle _strut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.55,
    forceStrutHeight: true,
  );

  // Step counts lines on the 18.6 grid, including each blank paragraph line.
  // The design leaves an empty line before "Your rights", so that line is step 11.
  static const List<(int, List<(String, bool)>)>
  _lines = <(int, List<(String, bool)>)>[
    (
      0,
      <(String, bool)>[('Privacy Notice (Republic Act No. 10173 – Data', true)],
    ),
    (1, <(String, bool)>[('Privacy Act of 2012)', true)]),
    (
      2,
      <(String, bool)>[
        ('The Municipality of Taytay collects your name,', false),
      ],
    ),
    (
      3,
      <(String, bool)>[
        ('contact details, address, valid ID and selfie to create', false),
      ],
    ),
    (
      4,
      <(String, bool)>[
        ('and verify your resident account and to deliver', false),
      ],
    ),
    (5, <(String, bool)>[('municipal services you request.', false)]),
    (6, <(String, bool)>[]),
    (
      7,
      <(String, bool)>[
        ('How we use it: ', true),
        ('identity and residency verification,', false),
      ],
    ),
    (
      8,
      <(String, bool)>[
        ('service requests, and notices from the LGU. ', false),
        ('Who', true),
      ],
    ),
    (
      9,
      <(String, bool)>[
        ('can see it: ', true),
        ('authorised Taytay LGU personnel only.', false),
      ],
    ),
    (10, <(String, bool)>[]),
    (
      11,
      <(String, bool)>[
        ('Your rights: ', true),
        (
          'to be informed, to access, correct, object and erase, and to file a complaint with the National Privacy Commission. Contact the LGU Data Protection Officer for requests.',
          false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final (int step, List<(String, bool)> spans) in _lines)
          if (spans.isNotEmpty)
            Positioned(
              top: step * _step,
              left: 0,
              right: 0,
              child: Text.rich(
                TextSpan(
                  style: _style,
                  children: <InlineSpan>[
                    for (final (String text, bool strong) in spans)
                      TextSpan(
                        text: text,
                        style: strong
                            ? _style.copyWith(fontWeight: AppTypography.black)
                            : null,
                      ),
                  ],
                ),
                strutStyle: _strut,
                maxLines: step == 11 ? 4 : 1,
                softWrap: step == 11,
                overflow: TextOverflow.visible,
              ),
            ),
      ],
    );
  }
}

class _SelfieRule extends StatelessWidget {
  const _SelfieRule(
    this.icon,
    this.label, {
    this.tail,
    this.tailGap = 0,
    this.bottom = 2,
  });

  final IconData icon;
  final String label;
  final String? tail;
  final double tailGap;
  final double bottom;

  static const TextStyle _style = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.67,
    fontWeight: AppTypography.medium,
    color: Color(0xFF3A4560),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: bottom),
      child: Row(
        crossAxisAlignment: tail == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: tail == null ? 0 : 14),
            child: TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: 16,
              color: BrandColors.taytayBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: tail == null
                ? Text(label, style: _style)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(label, style: _style),
                      SizedBox(height: tailGap),
                      Text(tail!, style: _style),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Taytay's barangays, from `GET /barangays`, one 48 dp row each.
///
/// A modal sheet so focus stays inside it and Back closes it. Loading and a
/// failed read are said in words, with a way to try again; nothing is picked
/// on the resident's behalf and there is no typed fallback.
class _BarangaySheet extends StatefulWidget {
  const _BarangaySheet({required this.load, required this.selectedId});

  final Future<Result<List<Barangay>>> Function() load;
  final String? selectedId;

  @override
  State<_BarangaySheet> createState() => _BarangaySheetState();
}

class _BarangaySheetState extends State<_BarangaySheet> {
  Result<List<Barangay>>? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    setState(() => _result = null);
    final Result<List<Barangay>> result = await widget.load();
    if (!mounted) return;
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle note = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 13,
      height: 1.45,
      color: Color(0xFF4A5470),
    );
    final Result<List<Barangay>>? result = _result;
    final Widget body = switch (result) {
      null => Semantics(
        liveRegion: true,
        label: 'Loading barangays',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      Ok<List<Barangay>>(:final value) when value.isNotEmpty => Flexible(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final Barangay barangay in value)
              _BarangayRow(
                barangay: barangay,
                selected: barangay.id == widget.selectedId,
              ),
          ],
        ),
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              result is Ok<List<Barangay>>
                  ? 'No barangays are listed yet. Please try again later.'
                  : 'We could not load the list of barangays. Check your '
                        'connection and try again.',
              style: note,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: 'Try again',
            onPressed: _fetch,
          ),
        ],
      ),
    };
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: const Text(
                  'Choose your barangay',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: AppTypography.black,
                    color: BrandColors.taytayBlueDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text('Taytay, Rizal', style: note),
              const SizedBox(height: 8),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _BarangayRow extends StatelessWidget {
  const _BarangayRow({required this.barangay, required this.selected});

  final Barangay barangay;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: barangay.name,
      onTap: () => Navigator.of(context).pop(barangay),
      excludeSemantics: true,
      child: InkWell(
        key: Key('barangay-${barangay.id}'),
        onTap: () => Navigator.of(context).pop(barangay),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    barangay.name,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: selected
                          ? AppTypography.black
                          : AppTypography.medium,
                      color: selected
                          ? BrandColors.taytayBlue
                          : BrandColors.fieldInk,
                    ),
                  ),
                ),
                if (selected)
                  const TaytayIcon(
                    icon: TaytayIcons.check,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 18,
                    color: BrandColors.taytayBlue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
