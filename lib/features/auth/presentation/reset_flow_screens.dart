import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_thread.dart';
import '../domain/code_exchange.dart';
import 'auth_bits.dart';
import 'auth_stage.dart';

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
    final bool short = MediaQuery.sizeOf(context).height < 800;
    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthCopy(
            eyebrow: 'Nakalimutan ang password',
            title: 'Ilagay ang 6-digit na code',
            subtitle: 'Nagpadala kami ng code sa $_email.',
          ),
          if (_sample || _view.wrong) ...<Widget>[
            const SizedBox(height: 12),
            AuthNoticeBanner(
              title: 'Mali ang code. ',
              detail: _sample
                  ? '4 sa ${CodeExchangeRules.attempts} subok na lang ang natitira.'
                  : _view.attemptsRemaining == null
                  ? 'May ${CodeExchangeRules.attempts} subok ka bawat code.'
                  : '${_view.attemptsRemaining} sa ${CodeExchangeRules.attempts} subok na lang ang natitira.',
            ),
          ] else if (_view.expired) ...<Widget>[
            const SizedBox(height: 12),
            AuthNoticeBanner(
              title: 'Nag-expire na ang code. ',
              detail: _view.attemptsRemaining == null
                  ? 'Magpadala ng bago. May 5 subok ka ulit.'
                  : 'Magpadala ng bago. May ${_view.attemptsRemaining} subok ka ulit.',
              amber: true,
            ),
          ] else if (_view.unavailable) ...<Widget>[
            const SizedBox(height: 12),
            const AuthNoticeBanner(
              title: 'Subukan muli. ',
              detail: CodeAttemptView.unavailableCopy,
            ),
          ],
          const SizedBox(height: 16),
          SixDigitRow(
            digits: _code.text,
            bad: (_sample || _view.wrong) && !_view.expired,
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
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Flexible(
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const TaytayIcon(
                        icon: TaytayIcons.clock,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: 14,
                        color: BrandColors.taytayBlue,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Mag-e-expire sa $_expiryLabel',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: AppTypography.black,
                            color: BrandColors.taytayBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 152,
                height: 18,
                child: OverflowBox(
                  maxHeight: 48,
                  maxWidth: 180,
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF5B6680),
                      disabledForegroundColor: const Color(0xFF5B6680),
                      textStyle: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: AppTypography.strong,
                      ),
                    ),
                    onPressed: _canResend ? _resend : null,
                    child: Text(
                      _canResend
                          ? 'Ipadala muli'
                          : 'Ipadala muli sa $_resendLabel',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: _view.expired
                ? 'Magpadala ng bagong code'
                : 'I-verify ang code',
            onPressed: _busy
                ? null
                : _view.expired
                ? _resend
                : _verify,
          ),
          const SizedBox(height: 10),
          const Text(
            'Valid ang code nang 10 minuto. May 5 subok ka bawat code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.body,
              color: Color(0xFF5B6680),
            ),
          ),
          const SizedBox(height: 18),
          AuthTextLink(
            'Bumalik sa sign in',
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
    );
    return AuthStage(
      sheetTop: 252,
      wrapSheet: short,
      arch: AuthArch.smallKey,
      atmosphere: SignInAtmosphere.resetCode,
      curve: ThreadCurve.reset,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.forgotPassword.routeName),
      child: short ? SingleChildScrollView(child: body) : body,
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
    final bool short = MediaQuery.sizeOf(context).height < 800;
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
    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthCopy(
            eyebrow: 'Bagong password',
            title: 'Gumawa ng bagong password',
            subtitle:
                'Para sa $_email. Gamitin ito sa susunod mong pag-sign in.',
          ),
          if (expired) ...<Widget>[
            const SizedBox(height: 11),
            const AuthNoticeBanner(
              title: 'Nag-expire na ang reset link mo. ',
              detail:
                  'Valid lang ito nang 15 minuto. Humingi ng bagong code para makapagpatuloy.',
            ),
          ],
          SizedBox(height: expired ? 14 : 12),
          _SecretField(
            label: 'Bagong password *',
            bullets: _sampleMismatch || _sampleExpired ? 10 : password.length,
            ok:
                password.isNotEmpty &&
                CodeExchangeRules.acceptablePassword(password),
            shown: _showPassword,
            controller: _password,
            live: widget.fixture == SetPasswordFixture.live && !expired,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            onChanged: () => setState(() => _matchError = null),
          ),
          SizedBox(height: expired ? 5 : 6),
          PasswordRules(
            password: widget.fixture == SetPasswordFixture.live
                ? password
                : CodeExchangeRules.samplePassword,
          ),
          const SizedBox(height: 12),
          _SecretField(
            label: 'Ulitin ang bagong password *',
            bullets: _sampleMismatch ? 9 : confirm.length,
            ok: matched,
            bad: mismatch,
            shown: _showConfirm,
            controller: _confirm,
            live: widget.fixture == SetPasswordFixture.live && !expired,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            onChanged: () => setState(() => _matchError = null),
          ),
          if (mismatch)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Hindi tugma ang password. Pakiulit.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.strong,
                  color: Color(0xFFB3261E),
                ),
              ),
            )
          else if (matched || _sampleExpired)
            Padding(
              padding: EdgeInsets.only(top: expired ? 1 : 5),
              child: const Text(
                'Tugma ang password',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.strong,
                  color: Color(0xFF0F7A4D),
                ),
              ),
            ),
          SizedBox(height: expired ? 19 : 16),
          PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: expired ? 'Humingi ng bagong code' : 'I-save ang password',
            onPressed: _busy ? null : _save,
          ),
          SizedBox(height: expired ? 20 : 22),
          AuthTextLink(
            'Bumalik sa sign in',
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
    );
    return AuthStage(
      sheetTop: 252,
      wrapSheet: short,
      arch: AuthArch.lock,
      atmosphere: expired
          ? SignInAtmosphere.setPasswordExpired
          : SignInAtmosphere.setPassword,
      curve: ThreadCurve.reset,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.forgotPassword.routeName),
      child: short ? SingleChildScrollView(child: body) : body,
    );
  }
}

class _SecretField extends StatelessWidget {
  const _SecretField({
    required this.label,
    required this.bullets,
    required this.shown,
    required this.controller,
    required this.live,
    required this.onToggle,
    required this.onChanged,
    this.ok = false,
    this.bad = false,
  });

  final String label;
  final int bullets;
  final bool shown;
  final TextEditingController controller;
  final bool live;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final bool ok;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final Color border = bad
        ? const Color(0xFFB3261E)
        : ok
        ? const Color(0xFF0F7A4D)
        : BrandColors.fieldBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.label.copyWith(color: BrandColors.fieldLabel),
        ),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: bad ? const Color(0xFFFFF7F7) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.4),
          ),
          child: SizedBox(
            height: 44,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: live
                      ? TextField(
                          controller: controller,
                          obscureText: !shown,
                          textAlignVertical: TextAlignVertical.center,
                          style: AppTypography.fieldValue,
                          decoration: bareField,
                          onChanged: (_) => onChanged(),
                        )
                      : Text(
                          '•' * bullets.clamp(0, 24),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                            letterSpacing: 1,
                            color: Color(0xFF1C2540),
                          ),
                        ),
                ),
                ShowPasswordToggle(shown: shown, onPressed: onToggle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `02-13`. The password was updated. Sign-in is the only next step.
class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool short = MediaQuery.sizeOf(context).height < 800;
    const Widget sheet = Padding(
      padding: EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TaytayIcon(
            icon: TaytayIcons.shieldCheck,
            semanticLabel: 'Verified',
            size: 20,
            color: Color(0xFF0F7A4D),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Para sa iyong seguridad',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: AppTypography.black,
                    color: Color(0xFF062358),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kung hindi ikaw ang nagpalit ng password, tumawag sa '
                  'Municipal Hall o pumunta sa MSWDO.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: AppTypography.body,
                    color: Color(0xFF4A5470),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return AuthStage(
      sheetTop: 500,
      sheetBottom: 20,
      wrapSheet: short,
      arch: AuthArch.shield,
      atmosphere: SignInAtmosphere.passwordUpdated,
      curve: ThreadCurve.submitted,
      onBack: () => context.goNamed(AppRoute.signIn.routeName),
      fieldCaption: const AuthCopy(
        eyebrow: 'Tapos na',
        title: 'Na-update na ang password mo',
        subtitle:
            'Gamitin ang bagong password sa susunod mong pag-sign in sa Taytay LGUIDS.',
        titleSize: 28,
        centered: true,
      ),
      footer: PrimaryButton(
        kind: TaytayButtonKind.signIn,
        label: 'Mag-sign in',
        onPressed: () => context.goNamed(AppRoute.signIn.routeName),
      ),
      child: short ? const SingleChildScrollView(child: sheet) : sheet,
    );
  }
}
