import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/failure_view.dart';

/// Sign-in entry point: a mobile number, then a one-time code.
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dependencies = AppDependencies.of(context);
    final reducedMotion = Motion.reduced(context);
    setState(() {
      _submitting = true;
      _failure = null;
    });

    final result = await dependencies.authRepository.requestOneTimeCode(
      mobileNumber: _mobileController.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _failure = result.failureOrNull;
    });

    // One haptic per outcome — never one per retry (see AppHaptics rule 3).
    await AppHaptics.fire(
      result.isOk ? HapticIntent.confirm : HapticIntent.error,
      suppressed: reducedMotion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dependencies = AppDependencies.of(context);
    final session = dependencies.session.state;
    final endedReason = session is GuestSession
        ? session.endedReason
        : SessionEndedReason.none;
    final failure = _failure;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Form(
            key: _formKey,
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
                else if (widget.returnTo != null)
                  const _Notice(
                    icon: Icons.login_outlined,
                    text:
                        'Sign in to continue to the page you opened. We will '
                        'take you straight there.',
                  ),
                Text(
                  'Welcome to Taytay LGU IDS',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Enter your mobile number and we will send you a one-time '
                  'code.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const <String>[AutofillHints.telephoneNumber],
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '09XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                  ),
                  validator: _validateMobileNumber,
                ),
                const SizedBox(height: Spacing.xl),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send one-time code'),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Taytay LGU uses your mobile number to sign you in and to '
                  'contact you about your requests. It is never shared for '
                  'advertising.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (failure != null)
                  FailureView(
                    failure: failure,
                    environment: dependencies.config.environment,
                    onRetry: _submit,
                  ),
                const SizedBox(height: Spacing.xl),
                TextButton(
                  onPressed: () => context.goNamed(AppRoute.home.routeName),
                  child: const Text('Continue as guest'),
                ),
                if (kDebugMode) const _DebugSessionSimulator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Philippine mobile numbers are 11 digits beginning `09`.
  ///
  /// Client-side validation is a courtesy that saves a round trip; the server
  /// validates again and its answer is the one that counts.
  static String? _validateMobileNumber(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your mobile number.';
    if (!RegExp(r'^09\d{9}$').hasMatch(input)) {
      return 'Enter an 11-digit mobile number starting with 09.';
    }
    return null;
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
