import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/code_exchange.dart';
import 'auth_bits.dart';

/// Which `02-02b` frame to paint. [sample] is the design's error state.
enum ResetCodeFixture { live, sample }

/// `02-02b`. The code, the attempts left, the expiry, and the resend cooldown.
class ResetCodeScreen extends StatefulWidget {
  const ResetCodeScreen({
    this.fixture = ResetCodeFixture.live,
    this.draft,
    super.key,
  });

  final ResetCodeFixture fixture;
  final PasswordResetDraft? draft;

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final TextEditingController _code = TextEditingController();
  Timer? _clock;
  CodeAttemptView _view = const CodeAttemptView();
  bool _busy = false;

  bool get _sample => widget.fixture == ResetCodeFixture.sample;

  @override
  void initState() {
    super.initState();
    final PasswordResetDraft? draft = widget.draft;
    _view = _sample
        ? const CodeAttemptView(attemptsRemaining: 4, wrong: true)
        : CodeAttemptView(
            attemptsRemaining: draft?.attemptsRemaining,
            resendAt: draft?.resendAvailableAt,
            expiresAt: draft?.codeExpiresAt,
            limited: draft?.limited ?? false,
          );
    if (_sample) _code.text = AuthSample.code;
    _arm();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _arm() {
    _clock?.cancel();
    if (!authClockTicks || _sample) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String get _email {
    final String email = widget.draft?.email ?? '';
    if (_sample) return AuthSample.email;
    if (email.isEmpty) return 'your email';
    return email;
  }

  String get _expiryLabel {
    if (_sample) return AuthSample.expiry;
    final DateTime? at = _view.expiresAt;
    if (at == null) {
      return CodeExchangeRules.countdown(CodeExchangeRules.codeLife);
    }
    return CodeExchangeRules.countdown(at.difference(DateTime.now()));
  }

  String get _resendLabel {
    if (_sample) return AuthSample.resend;
    final DateTime? at = _view.resendAt;
    if (at == null) return '0:00';
    return CodeExchangeRules.countdown(at.difference(DateTime.now()));
  }

  bool get _canResend {
    if (_sample) return false;
    return _view.canResendAt(DateTime.now());
  }

  Future<void> _verify() async {
    if (_busy || _view.limited) return;
    final String code = _sample ? AuthSample.code : _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return;
    if (_sample) return;
    setState(() => _busy = true);
    final result = await AppDependencies.of(
      context,
    ).authRepository.verifyPasswordReset(email: _email, code: code);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _busy = false);
        unawaited(
          context.pushNamed(
            AppRoute.setPassword.routeName,
            extra: PasswordResetDraft(
              email: _email,
              issuedAt: widget.draft?.issuedAt,
              codeExpiresAt: _view.expiresAt,
              resendAvailableAt: _view.resendAt,
              attemptsRemaining: _view.attemptsRemaining,
              grant: value,
            ),
          ),
        );
      case Err(:final failure):
        _applyRefusal(failure);
    }
  }

  void _applyRefusal(AppFailure failure) {
    final DateTime now = DateTime.now();
    final CodeAttemptView next = _view.applyFailure(failure, now);
    setState(() {
      _busy = false;
      _view = next;
      if (next.expired) _code.clear();
    });
    if (next.limited) unawaited(_openHold(now, next.resendAt));
  }

  Future<void> _openHold(DateTime now, DateTime? resumeAt) async {
    final Duration? wait = resumeAt?.difference(now);
    final Object? back = await context.pushNamed(
      AppRoute.tooMany.routeName,
      extra: CodeHold.fromWait(
        origin: CodeHoldOrigin.passwordReset,
        email: _email == 'your email' ? '' : _email,
        now: now,
        wait: wait != null && wait.isNegative ? Duration.zero : wait,
      ),
    );
    if (!mounted || back is! CodeAcceptance) return;
    setState(() {
      _view = _view.applyAcceptance(back, DateTime.now());
      _code.clear();
    });
  }

  Future<void> _resend() async {
    if (!_canResend || _busy) return;
    setState(() => _busy = true);
    final result = await AppDependencies.of(
      context,
    ).authRepository.requestPasswordReset(email: _email);
    if (!mounted) return;
    final DateTime now = DateTime.now();
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _view = _view.applyAcceptance(value, now);
          _code.clear();
        case Err(:final failure):
          _view = _view.applyFailure(failure, now);
          if (_view.limited) unawaited(_openHold(now, _view.resendAt));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool wrong = _sample || _view.wrong;
    return AuthFormPage(
      title: 'Ilagay ang 6-digit na code',
      subtitle: 'Nagpadala kami ng code sa $_email.',
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.forgotPassword.routeName),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: _view.expired
                ? 'Magpadala ng bagong code'
                : 'I-verify ang code',
            onPressed: _busy
                ? null
                : _view.expired
                ? _resend
                : _verify,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Valid ang code nang 10 minuto. May 5 subok ka bawat code.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(color: BrandColors.muted),
          ),
          AuthLink(
            'Bumalik sa sign in',
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (wrong) ...<Widget>[
            SoftNote(
              tone: NoteTone.error,
              title: 'Mali ang code. ',
              message: _sample
                  ? '4 sa ${CodeExchangeRules.attempts} subok na lang ang '
                        'natitira.'
                  : _view.attemptsRemaining == null
                  ? 'May ${CodeExchangeRules.attempts} subok ka bawat code.'
                  : '${_view.attemptsRemaining} sa '
                        '${CodeExchangeRules.attempts} subok na lang ang '
                        'natitira.',
            ),
            const SizedBox(height: Spacing.formGap),
          ] else if (_view.expired) ...<Widget>[
            SoftNote(
              tone: NoteTone.warning,
              title: 'Nag-expire na ang code. ',
              message: _view.attemptsRemaining == null
                  ? 'Magpadala ng bago. May 5 subok ka ulit.'
                  : 'Magpadala ng bago. May ${_view.attemptsRemaining} '
                        'subok ka ulit.',
            ),
            const SizedBox(height: Spacing.formGap),
          ] else if (_view.unavailable) ...<Widget>[
            const SoftNote(
              tone: NoteTone.error,
              title: 'Subukan muli. ',
              message: CodeAttemptView.unavailableCopy,
            ),
            const SizedBox(height: Spacing.formGap),
          ],
          SixDigitRow(
            digits: _code.text,
            bad: wrong && !_view.expired,
            dim: _view.expired,
          ),
          if (!_sample)
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  key: const Key('reset-code-field'),
                  controller: _code,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: bareField.copyWith(counterText: ''),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              CodeExpiryChip(label: 'Mag-e-expire sa $_expiryLabel'),
              CodeResendButton(
                label: _canResend
                    ? 'Ipadala muli'
                    : 'Ipadala muli sa $_resendLabel',
                onPressed: _canResend ? _resend : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `02-12` and, when the reset token has expired, `02-12b`.
enum SetPasswordFixture { live, mismatch, expired }

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({
    this.fixture = SetPasswordFixture.live,
    this.draft,
    super.key,
  });

  final SetPasswordFixture fixture;
  final PasswordResetDraft? draft;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _busy = false;
  String? _matchError;

  bool get _sampleMismatch => widget.fixture == SetPasswordFixture.mismatch;
  bool get _sampleExpired => widget.fixture == SetPasswordFixture.expired;

  bool get _tokenExpired {
    if (_sampleExpired) return true;
    if (_sampleMismatch) return false;
    final PasswordResetGrant? grant = widget.draft?.grant;
    if (grant == null) return true;
    return grant.expiredAt(DateTime.now());
  }

  String get _email {
    final String email = widget.draft?.email ?? '';
    if (widget.fixture != SetPasswordFixture.live || email.isEmpty) {
      return AuthSample.email;
    }
    return email;
  }

  @override
  void initState() {
    super.initState();
    // The design frames show the sample passwords as dots.
    if (_sampleMismatch || _sampleExpired) {
      _password.text = CodeExchangeRules.samplePassword;
      _confirm.text = _sampleMismatch
          ? CodeExchangeRules.sampleConfirm
          : CodeExchangeRules.samplePassword;
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tokenExpired) {
      context.goNamed(AppRoute.forgotPassword.routeName);
      return;
    }
    final String password = _sampleMismatch
        ? CodeExchangeRules.samplePassword
        : _password.text;
    final String confirm = _sampleMismatch
        ? CodeExchangeRules.sampleConfirm
        : _confirm.text;
    if (password != confirm) {
      setState(() => _matchError = 'Hindi tugma ang password. Pakiulit.');
      return;
    }
    if (!CodeExchangeRules.acceptablePassword(password)) {
      setState(() => _matchError = null);
      return;
    }
    if (_sampleMismatch) return;
    final String? token = widget.draft?.grant?.resetToken;
    if (token == null) return;
    setState(() => _busy = true);
    final result = await AppDependencies.of(context).authRepository
        .completePasswordReset(resetToken: token, newPassword: password);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.goNamed(AppRoute.passwordUpdated.routeName);
      case Err(:final failure):
        final bool weak =
            failure is ValidationFailure &&
            (failure.fieldErrors['new_password']?.contains(
                  CodeExchangeRules.weak,
                ) ??
                false);
        final bool stillValid =
            widget.draft?.grant?.expiredAt(DateTime.now()) == false;
        setState(() {
          _busy = false;
          _matchError = !weak && stillValid && password != confirm
              ? 'Hindi tugma ang password. Pakiulit.'
              : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool expired = _tokenExpired;
    final String password = _sampleMismatch || _sampleExpired
        ? CodeExchangeRules.samplePassword
        : _password.text;
    final String confirm = _sampleMismatch
        ? CodeExchangeRules.sampleConfirm
        : _sampleExpired
        ? CodeExchangeRules.samplePassword
        : _confirm.text;
    final bool mismatch =
        _matchError != null || (_sampleMismatch && password != confirm);
    final bool matched =
        !mismatch && password.isNotEmpty && password == confirm;
    final bool live = widget.fixture == SetPasswordFixture.live && !expired;
    return AuthFormPage(
      title: 'Gumawa ng bagong password',
      subtitle: 'Para sa $_email. Gamitin ito sa susunod mong pag-sign in.',
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.forgotPassword.routeName),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: expired ? 'Humingi ng bagong code' : 'I-save ang password',
            onPressed: _busy ? null : _save,
          ),
          AuthLink(
            'Bumalik sa sign in',
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (expired) ...<Widget>[
            const SoftNote(
              tone: NoteTone.error,
              title: 'Nag-expire na ang reset link mo. ',
              message:
                  'Valid lang ito nang 15 minuto. Humingi ng bagong code '
                  'para makapagpatuloy.',
            ),
            const SizedBox(height: Spacing.formGap),
          ],
          AuthField(
            label: 'Bagong password *',
            controller: _password,
            icon: TaytayIcons.lock,
            obscure: !_showPassword,
            enabled: live,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) => setState(() => _matchError = null),
            trailing: ShowPasswordToggle(
              shown: _showPassword,
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          PasswordRules(
            password: widget.fixture == SetPasswordFixture.live
                ? password
                : CodeExchangeRules.samplePassword,
          ),
          const SizedBox(height: Spacing.formGap),
          AuthField(
            label: 'Ulitin ang bagong password *',
            controller: _confirm,
            icon: TaytayIcons.lock,
            obscure: !_showConfirm,
            enabled: live,
            error: mismatch ? 'Hindi tugma ang password. Pakiulit.' : null,
            hint: matched || _sampleExpired ? 'Tugma ang password' : null,
            autofillHints: const <String>[AutofillHints.newPassword],
            onChanged: (_) => setState(() => _matchError = null),
            trailing: ShowPasswordToggle(
              shown: _showConfirm,
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
            ),
          ),
        ],
      ),
    );
  }
}

/// `02-13`. The password was updated. Sign-in is the only next step.
class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void signIn() => context.goNamed(AppRoute.signIn.routeName);
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: SuccessScreen(
        title: 'Na-update na ang password mo',
        message:
            'Gamitin ang bagong password sa susunod mong pag-sign in sa '
            'Taytay LGUIDS.',
        showBack: true,
        onBack: signIn,
        body: const SoftNote(
          tone: NoteTone.success,
          live: false,
          title: 'Para sa iyong seguridad. ',
          message:
              'Kung hindi ikaw ang nagpalit ng password, tumawag sa '
              'Municipal Hall o pumunta sa MSWDO.',
        ),
        primaryLabel: 'Mag-sign in',
        onPrimary: signIn,
      ),
    );
  }
}
