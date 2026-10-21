import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/taytay_buttons.dart';
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
  late int _attempts;
  DateTime? _expiresAt;
  DateTime? _resendAt;
  bool _wrong = false;
  bool _expired = false;
  bool _locked = false;
  bool _busy = false;

  bool get _sample => widget.fixture == ResetCodeFixture.sample;

  @override
  void initState() {
    super.initState();
    final PasswordResetDraft? draft = widget.draft;
    _attempts = _sample
        ? 4
        : (draft?.attemptsLeft ?? CodeExchangeRules.attempts);
    _expiresAt = draft?.codeExpiresAt;
    _resendAt = draft?.resendAvailableAt;
    _wrong = _sample;
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
    final DateTime? at = _expiresAt;
    if (at == null) {
      return CodeExchangeRules.countdown(CodeExchangeRules.codeLife);
    }
    return CodeExchangeRules.countdown(at.difference(DateTime.now()));
  }

  String get _resendLabel {
    if (_sample) return AuthSample.resend;
    final DateTime? at = _resendAt;
    if (at == null) return '0:00';
    return CodeExchangeRules.countdown(at.difference(DateTime.now()));
  }

  bool get _canResend {
    if (_sample) return false;
    final DateTime? at = _resendAt;
    return at == null || !at.isAfter(DateTime.now());
  }

  Future<void> _verify() async {
    if (_busy || _locked) return;
    final String code = _sample ? AuthSample.code : _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return;
    if (_sample) return;
    final DateTime now = DateTime.now();
    if (code == CodeExchangeRules.expiredSentinel ||
        (widget.draft?.codeExpiredAt(now) ?? false)) {
      setState(() {
        _expired = true;
        _wrong = false;
        _code.clear();
      });
      return;
    }
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
              codeExpiresAt: _expiresAt,
              resendAvailableAt: _resendAt,
              attemptsLeft: _attempts,
              grant: value,
            ),
          ),
        );
      case Err(:final failure):
        _applyRefusal(failure);
    }
  }

  void _applyRefusal(AppFailure failure) {
    final List<String>? codes = failure is ValidationFailure
        ? failure.fieldErrors['code']
        : null;
    final String? kind = codes == null || codes.isEmpty ? null : codes.first;
    setState(() {
      _busy = false;
      if (kind == CodeExchangeRules.expired) {
        _expired = true;
        _wrong = false;
        _code.clear();
        return;
      }
      if (kind == CodeExchangeRules.locked || _attempts <= 1) {
        _attempts = 0;
        _locked = true;
        _wrong = true;
        return;
      }
      _attempts = (_attempts - 1).clamp(0, CodeExchangeRules.attempts);
      _wrong = true;
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
      if (result.isOk) {
        _expiresAt = now.add(CodeExchangeRules.codeLife);
        _resendAt = now.add(CodeExchangeRules.resendCooldown);
        _attempts = CodeExchangeRules.attempts;
        _wrong = false;
        _expired = false;
        _locked = false;
        _code.clear();
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
          if (_expired) ...<Widget>[
            const SizedBox(height: 12),
            const AuthNoticeBanner(
              title: 'Nag-expire na ang code. ',
              detail: 'Magpadala ng bago. May 5 subok ka ulit.',
              amber: true,
            ),
          ] else if (_wrong) ...<Widget>[
            const SizedBox(height: 12),
            AuthNoticeBanner(
              title: _locked ? 'Naka-lock ang code. ' : 'Mali ang code. ',
              detail: _locked
                  ? 'Humiling ng bagong code para makapagpatuloy.'
                  : '$_attempts sa ${CodeExchangeRules.attempts} subok na lang ang natitira.',
            ),
          ],
          const SizedBox(height: 16),
          SixDigitRow(digits: _code.text, bad: _wrong && !_expired),
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
                  decoration: const InputDecoration(counterText: ''),
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
                      const Icon(
                        Icons.schedule,
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
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF5B6680),
                  textStyle: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: AppTypography.strong,
                  ),
                ),
                onPressed: _canResend ? _resend : null,
                child: Text(
                  _canResend ? 'Ipadala muli' : 'Ipadala muli sa $_resendLabel',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: _expired ? 'Magpadala ng bagong code' : 'I-verify ang code',
            onPressed: _busy
                ? null
                : _expired
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
            const SizedBox(height: 12),
            const AuthNoticeBanner(
              title: 'Nag-expire na ang reset link mo. ',
              detail:
                  'Valid lang ito nang 10 minuto. Humingi ng bagong code para makapagpatuloy.',
            ),
          ],
          const SizedBox(height: 12),
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
          const SizedBox(height: 6),
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
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Tugma ang password',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.strong,
                  color: Color(0xFF0F7A4D),
                ),
              ),
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            kind: TaytayButtonKind.signIn,
            label: expired ? 'Humingi ng bagong code' : 'I-save ang password',
            onPressed: _busy ? null : _save,
          ),
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
                          style: AppTypography.fieldValue,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                          ),
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
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.verified_user_outlined,
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
                SizedBox(height: 4),
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
