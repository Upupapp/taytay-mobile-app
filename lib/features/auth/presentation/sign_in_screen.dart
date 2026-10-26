import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/sign_in_challenge.dart';
import 'auth_bits.dart';
import 'auth_stage.dart';
import 'sign_in_controller.dart';

export 'auth_stage.dart' show signInFormSheetKey;

/// How the sign-in sheet is painted.
///
/// [live] is the resident's form. [design] and [error] are the `02-01` and
/// `02-10` frames, with the sample values from the mockup and no debug chrome.
enum SignInFixture { live, design, error }

/// Sign-in as `02-01` draws it: email or mobile, password, and the arch.
///
/// The live repository declines. The dev mock returns a session. The staff
/// password route is never called. A refusal uses [SignInMessage], never the
/// server's message.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    this.returnTo,
    this.threadCycle = 0,
    this.fixture = SignInFixture.live,
    super.key,
  });

  final String? returnTo;
  final double threadCycle;
  final SignInFixture fixture;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  SignInController? _controller;
  bool _obscure = true;
  String? _identifierError;
  String? _passwordError;

  bool get _preview => widget.fixture != SignInFixture.live;

  @override
  void initState() {
    super.initState();
    if (widget.fixture == SignInFixture.design ||
        widget.fixture == SignInFixture.error) {
      _identifier.text = 'juana.delacruz@example.com';
      _password.text = 'password-sample';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preview || _controller != null) return;
    final dependencies = AppDependencies.of(context);
    _controller = SignInController(
      repository: dependencies.authRepository,
      session: dependencies.session,
    )..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.onboarding.routeName);
    }
  }

  Future<void> _submit() async {
    final controller = _controller;
    if (controller == null) return;
    final identifierError = AccountIdentifier.validate(_identifier.text);
    final passwordError = _password.text.isEmpty
        ? 'Enter your password.'
        : null;
    setState(() {
      _identifierError = identifierError;
      _passwordError = passwordError;
    });
    if (identifierError != null || passwordError != null) return;

    final reduced = Motion.reduced(context);
    final signedIn = await controller.signInWithPassword(
      identifier: _identifier.text,
      password: _password.text,
    );
    if (!mounted) return;
    await AppHaptics.fire(
      signedIn ? HapticIntent.success : HapticIntent.error,
      suppressed: reduced,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ended = !_preview && controller != null
        ? _endedReason(context)
        : SessionEndedReason.none;
    final rejected =
        widget.fixture == SignInFixture.error ||
        controller?.message == SignInMessage.credentialsRejected;
    final needsEmail = controller?.message == SignInMessage.passwordNeedsEmail;
    final other = !rejected && !needsEmail ? controller?.message : null;

    return AuthStage(
      sheetTop: rejected ? 276 : 332,
      arch: rejected ? AuthArch.hallShort : AuthArch.hall,
      threadCycle: widget.threadCycle,
      onBack: _back,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (ended == SessionEndedReason.expired)
                _Notice(text: AppStrings.of(context).signInNoticeExpired)
              else if (ended == SessionEndedReason.signedOut)
                _Notice(text: AppStrings.of(context).signInNoticeSignedOut)
              else if (widget.returnTo != null)
                _Notice(text: AppStrings.of(context).signInNoticeReturnTo),
              AuthCopy(
                eyebrow: 'Mag-sign in',
                title: 'Maligayang pagbabalik!',
                subtitle: rejected
                    ? null
                    : 'Sign in to your Taytay resident account.',
              ),
              if (rejected) ...<Widget>[
                const SizedBox(height: 10),
                _CredentialBanner(
                  attemptsLeft: widget.fixture == SignInFixture.error
                      ? 2
                      : controller?.passwordAttemptsShown ?? 2,
                ),
              ],
              if (needsEmail) ...<Widget>[
                const SizedBox(height: 10),
                _CredentialBanner.message(
                  SignInMessage.passwordNeedsEmail.text,
                ),
              ],
              if (other != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  other.text,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: AppTypography.medium,
                    height: 1.45,
                    color: Color(0xFF7A1C16),
                  ),
                ),
              ],
              SizedBox(height: rejected ? 13.63 : 12),
              _Field(
                label: 'Email or mobile number',
                controller: _identifier,
                error: _identifierError,
                focused: widget.fixture == SignInFixture.design,
                obscure: false,
              ),
              SizedBox(height: rejected ? 13.34 : 13.5),
              _Field(
                label: 'Password',
                controller: _password,
                error: rejected ? 'Incorrect password' : _passwordError,
                obscure: _obscure,
                previewMask: _preview,
                bad: rejected,
                trailing: _ShowPassword(
                  label: _obscure ? 'Show' : 'Hide',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              SizedBox(height: rejected ? 6 : 13.5),
              AuthTextLink(
                'Forgot password?',
                align: Alignment.centerRight,
                onPressed: () =>
                    context.goNamed(AppRoute.forgotPassword.routeName),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                kind: TaytayButtonKind.signIn,
                label: 'Sign in',
                onPressed: controller?.busy == true ? null : _submit,
              ),
              SizedBox(height: rejected ? 9 : 9),
              const _OrRule(),
              const SizedBox(height: 12),
              SecondaryButton(
                kind: TaytayButtonKind.signIn,
                label: 'Create an account',
                onPressed: () => context.goNamed(AppRoute.register.routeName),
              ),
              const SizedBox(height: 12),
              AuthTextLink(
                'Continue as guest',
                fontSize: 12,
                onPressed: () => context.goNamed(AppRoute.home.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SessionEndedReason _endedReason(BuildContext context) {
  final session = AppDependencies.of(context).session.state;
  return session is GuestSession
      ? session.endedReason
      : SessionEndedReason.none;
}

/// Email, or an 11-digit mobile number. The message is about the shape only.
abstract final class AccountIdentifier {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _mobile = RegExp(r'^09\d{9}$');

  static String? validate(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your email or mobile number.';
    final compact = input.replaceAll(' ', '');
    if (_email.hasMatch(input) || _mobile.hasMatch(compact)) return null;
    return 'Enter an email address or an 11-digit mobile number.';
  }
}

class _CredentialBanner extends StatelessWidget {
  const _CredentialBanner({required int this.attemptsLeft}) : message = null;

  const _CredentialBanner.message(String this.message) : attemptsLeft = null;

  final int? attemptsLeft;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final String? sentence = message;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3C1BE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const TaytayIcon(
              icon: TaytayIcons.circleAlert,
              semanticLabel: 'Error',
              size: 18,
              color: Color(0xFFB3261E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: sentence == null
                  ? Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: AppTypography.medium,
                          color: Color(0xFF7A1C16),
                        ),
                        children: <InlineSpan>[
                          const TextSpan(
                            text: 'Incorrect email or password.\n',
                            style: TextStyle(fontWeight: AppTypography.black),
                          ),
                          TextSpan(
                            text:
                                '$attemptsLeft attempts left before a '
                                '15-minute pause.',
                          ),
                        ],
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        text: sentence,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: AppTypography.medium,
                          color: Color(0xFF7A1C16),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.obscure,
    this.error,
    this.trailing,
    this.focused = false,
    this.bad = false,
    this.previewMask = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String? error;
  final Widget? trailing;
  final bool focused;
  final bool bad;
  final bool previewMask;

  @override
  Widget build(BuildContext context) {
    final border = bad
        ? BrandColors.danger
        : focused
        ? BrandColors.taytayBlue
        : BrandColors.fieldBorder;
    final fill = bad
        ? const Color(0xFFFFF7F7)
        : focused
        ? Colors.white
        : BrandColors.fieldFill;
    final ring = bad
        ? const Color(0x1AB3261E)
        : focused
        ? const Color(0x1F0B3D91)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.label.copyWith(color: BrandColors.fieldLabel),
        ),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.4),
            boxShadow: ring == null
                ? null
                : <BoxShadow>[BoxShadow(color: ring, spreadRadius: 3)],
          ),
          child: SizedBox(
            height: 44,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: previewMask && obscure
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '•••••••••••',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: AppTypography.medium,
                              color: BrandColors.fieldInk,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextFormField(
                            controller: controller,
                            obscureText: obscure,
                            textAlignVertical: TextAlignVertical.center,
                            style: AppTypography.fieldValue.copyWith(
                              color: BrandColors.fieldInk,
                            ),
                            decoration: bareField,
                          ),
                        ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 1.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  error!,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: AppTypography.strong,
                    color: BrandColors.danger,
                  ),
                ),
                const SizedBox(height: 3.7),
              ],
            ),
          ),
      ],
    );
  }
}

class _OrRule extends StatelessWidget {
  const _OrRule();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 11,
      fontWeight: AppTypography.strong,
      color: Color(0xFF6B6450),
    );
    return const Row(
      children: <Widget>[
        Expanded(child: _DashedRule()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Bago rito?', style: style),
        ),
        Expanded(child: _DashedRule()),
      ],
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1.4,
      child: CustomPaint(painter: _RulePainter()),
    );
  }
}

class _RulePainter extends CustomPainter {
  const _RulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0D6B8)
      ..strokeWidth = 1.4;
    var x = 0.0;
    while (x < size.width) {
      final next = math.min(x + 4, size.width);
      canvas.drawLine(Offset(x, 0.7), Offset(next, 0.7), paint);
      x = next + 3;
    }
  }

  @override
  bool shouldRepaint(covariant _RulePainter oldDelegate) => false;
}

class _ShowPassword extends StatelessWidget {
  const _ShowPassword({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 44,
      child: OverflowBox(
        maxHeight: 48,
        maxWidth: 72,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5B6680),
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.strong,
            ),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: AppTypography.body,
          height: 1.45,
          color: Color(0xFF4A5470),
        ),
      ),
    );
  }
}
