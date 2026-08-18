import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/sign_in_challenge.dart';
import 'sign_in_controller.dart';

/// Sign-in: a mobile number, then a one-time code.
///
/// ---
///
/// **One identifier, no password.** That is the committed contract, not a
/// simplification: the citizen routes are `POST /auth/otp` and
/// `POST /auth/otp/verify`. There is no citizen password to enter, and
/// therefore none to forget, reset, reuse across services, or ask a municipal
/// clerk to change over a counter.
///
/// **Nothing on this screen reveals whether an account exists.** Every refusal
/// resolves to one of a handful of messages in [SignInMessage], none of which
/// distinguishes an unknown number from a wrong code. See that enum for why an
/// LGU in particular must not answer that question.
///
/// [returnTo] is the location the resident was heading for before the guard
/// redirected them, so a deep link into a protected screen resumes after
/// sign-in instead of dumping them on the home screen.
class SignInScreen extends StatefulWidget {
  const SignInScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _identifierForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _codeForm = GlobalKey<FormState>();

  SignInController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

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
    _mobileController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!(_identifierForm.currentState?.validate() ?? false)) return;
    final controller = _controller!;
    final reduced = Motion.reduced(context);

    await controller.requestCode(_mobileController.text);
    if (!mounted) return;

    // One haptic per outcome — never one per retry (AppHaptics rule 3).
    await AppHaptics.fire(
      controller.message == SignInMessage.codeSent
          ? HapticIntent.confirm
          : HapticIntent.error,
      suppressed: reduced,
    );
  }

  Future<void> _verifyCode() async {
    if (!(_codeForm.currentState?.validate() ?? false)) return;
    final controller = _controller!;
    final reduced = Motion.reduced(context);

    final signedIn = await controller.verifyCode(_codeController.text);
    // Cleared either way: a code that has been spent is worthless, and one that
    // was refused should not be resubmitted by a stray tap.
    _codeController.clear();
    if (!mounted) return;

    await AppHaptics.fire(
      signedIn ? HapticIntent.success : HapticIntent.error,
      suppressed: reduced,
    );
    // No navigation here. The router listens to the session; a screen that
    // routed itself would be the second source of navigation truth that
    // CLAUDE.md Article 4 exists to prevent.
  }

  Future<void> _resend() async {
    final controller = _controller!;
    final reduced = Motion.reduced(context);
    await controller.resendCode();
    if (!mounted) return;
    await AppHaptics.fire(HapticIntent.selection, suppressed: reduced);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final dependencies = AppDependencies.of(context);
    final session = dependencies.session.state;
    final endedReason = session is GuestSession
        ? session.endedReason
        : SessionEndedReason.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        leading: controller.step == SignInStep.code
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Change number',
                onPressed: controller.busy ? null : controller.changeNumber,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (endedReason == SessionEndedReason.expired)
                const _Notice(
                  icon: Icons.lock_clock_outlined,
                  text:
                      'Your session ended for your security. Please sign in '
                      'again.',
                )
              else if (endedReason == SessionEndedReason.signedOut)
                const _Notice(
                  icon: Icons.check_circle_outline,
                  text:
                      'You are signed out on this device. You can still browse '
                      'Taytay services as a guest.',
                )
              else if (widget.returnTo != null)
                const _Notice(
                  icon: Icons.login_outlined,
                  text:
                      'Sign in to continue to the page you opened. We will '
                      'take you straight there.',
                ),
              switch (controller.step) {
                SignInStep.identifier => _IdentifierStep(
                  formKey: _identifierForm,
                  controller: _mobileController,
                  busy: controller.busy,
                  onSubmit: _requestCode,
                ),
                SignInStep.code => _CodeStep(
                  formKey: _codeForm,
                  controller: _codeController,
                  signIn: controller,
                  onSubmit: _verifyCode,
                  onResend: _resend,
                ),
              },
              if (controller.message != null) ...<Widget>[
                const SizedBox(height: Spacing.lg),
                _MessageBanner(message: controller.message!),
              ],
              const SizedBox(height: Spacing.xl),
              TextButton(
                onPressed: () => context.goNamed(AppRoute.signInHelp.routeName),
                child: const Text('Trouble signing in?'),
              ),
              if (controller.step == SignInStep.identifier) ...<Widget>[
                const SizedBox(height: Spacing.sm),
                OutlinedButton(
                  onPressed: () => context.goNamed(AppRoute.register.routeName),
                  child: const Text('Create an account'),
                ),
              ],
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () => context.goNamed(AppRoute.home.routeName),
                child: const Text('Continue as guest'),
              ),
              if (kDebugMode) const _DebugSessionSimulator(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 1 — the only identifier a citizen has.
class _IdentifierStep extends StatelessWidget {
  const _IdentifierStep({
    required this.formKey,
    required this.controller,
    required this.busy,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool busy;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Welcome to Taytay LGU IDS',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Enter your mobile number and we will send you a one-time code. '
            'There is no password to remember.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            autofillHints: const <String>[AutofillHints.telephoneNumber],
            enabled: !busy,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(SignInIdentifier.length),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '09XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_iphone_outlined),
            ),
            validator: SignInIdentifier.validate,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: Spacing.xl),
          AppButton(
            label: 'Send one-time code',
            loading: busy,
            onPressed: busy ? null : onSubmit,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Taytay LGU uses your mobile number to sign you in and to contact '
            'you about your requests. It is never shared for advertising.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 — the code, with a resend that respects a cooldown.
class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.formKey,
    required this.controller,
    required this.signIn,
    required this.onSubmit,
    required this.onResend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final SignInController signIn;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cooldown = signIn.resendCooldownSeconds;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Enter your code', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.sm),
          Text(
            // Masked: a resident can confirm the number without their full
            // number sitting on a screen readable over a shoulder in a queue.
            'We sent a ${OneTimeCodeRules.length}-digit code to '
            '${signIn.maskedMobileNumber}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !signIn.busy,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(OneTimeCodeRules.length),
            ],
            decoration: const InputDecoration(
              labelText: 'One-time code',
              prefixIcon: Icon(Icons.password_outlined),
            ),
            validator: OneTimeCodeRules.validate,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: Spacing.xl),
          AppButton(
            label: 'Sign in',
            loading: signIn.busy,
            onPressed: signIn.busy ? null : onSubmit,
          ),
          const SizedBox(height: Spacing.md),
          TextButton(
            onPressed: signIn.canResend ? onResend : null,
            child: Text(
              cooldown > 0
                  ? 'Send a new code in ${cooldown}s'
                  : 'Send a new code',
            ),
          ),
          TextButton(
            onPressed: signIn.busy ? null : signIn.changeNumber,
            child: const Text('Use a different number'),
          ),
        ],
      ),
    );
  }
}

/// Renders a [SignInMessage] and nothing else.
///
/// The screen never composes its own copy from a failure, so there is no path
/// by which a server `message` — operator-facing by definition — reaches a
/// resident's eyes.
class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final SignInMessage message;

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      tone: switch (message) {
        SignInMessage.codeSent => BannerTone.success,
        SignInMessage.tooManyAttempts => BannerTone.warning,
        _ => BannerTone.error,
      },
      message: localisedSignInMessage(context, message),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xl),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug-only control for entering the unverified and verified states while the
/// Identity backend does not exist yet.
///
/// Safe by construction, for three reasons: it is compiled out of release builds
/// by [kDebugMode]; it fabricates an obviously fake account with no personal
/// data; and — the point that matters — a local access level grants nothing,
/// because every protected operation is authorised server-side from the
/// authenticated actor (backend ADR 0002). Raising the level here only reveals
/// screens, which then fail their API calls exactly as they should.
class _DebugSessionSimulator extends StatelessWidget {
  const _DebugSessionSimulator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppDependencies.of(context).session;

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'DEBUG BUILD ONLY — simulate a session state',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => session.signIn(
                    resident: const ResidentSession(
                      accountId: 'debug-unverified',
                      accessLevel: AccessLevel.unverified,
                      displayName: 'Test',
                    ),
                    accessToken: 'debug-token',
                  ),
                  child: const Text('Unverified'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => session.signIn(
                    resident: const ResidentSession(
                      accountId: 'debug-verified',
                      accessLevel: AccessLevel.verified,
                      displayName: 'Test',
                    ),
                    accessToken: 'debug-token',
                  ),
                  child: const Text('Verified'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
