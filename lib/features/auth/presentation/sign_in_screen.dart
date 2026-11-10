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
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/sign_in_challenge.dart';
import 'auth_bits.dart';
import 'sign_in_controller.dart';

/// The white form page. Tests look for this to prove the copy sits on it.
const Key signInFormSheetKey = Key('sign-in-form-sheet');

/// How the sign-in sheet is painted.
///
/// [live] is the resident's form. [design] and [error] are the `02-01` and
/// `02-10` frames, with the sample values from the mockup and no debug chrome.
enum SignInFixture { live, design, error }

/// Sign-in as `SignIn.dc.html` draws it: the wave header with the seal and
/// the welcome back, email or mobile and password on the white page, and
/// Sign in, Create an account and Continue as guest in the footer.
///
/// The live repository declines. The dev mock returns a session. The staff
/// password route is never called. A refusal uses [SignInMessage], never the
/// server's message.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    this.returnTo,
    this.fixture = SignInFixture.live,
    super.key,
  });

  final String? returnTo;
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

    // Strings are read only when a notice is shown: the design frames are
    // pumped without the app's localisations.
    final String? notice = switch (ended) {
      SessionEndedReason.expired => AppStrings.of(context).signInNoticeExpired,
      SessionEndedReason.signedOut => AppStrings.of(
        context,
      ).signInNoticeSignedOut,
      _ =>
        widget.returnTo != null
            ? AppStrings.of(context).signInNoticeReturnTo
            : null,
    };
    final bool busy = controller?.busy == true;
    final int attemptsLeft = widget.fixture == SignInFixture.error
        ? 2
        : controller?.passwordAttemptsShown ?? 2;

    return Form(
      key: _formKey,
      child: AuthFormPage(
        pageKey: signInFormSheetKey,
        eyebrow: const AuthBrandRow(),
        title: 'Maligayang pagbabalik!',
        subtitle: 'Sign in to your Taytay resident account.',
        onBack: _back,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PrimaryButton(label: 'Sign in', onPressed: busy ? null : _submit),
            const SizedBox(height: Spacing.xs),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Bago rito?',
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.muted,
                  ),
                ),
                AuthLink(
                  'Create an account',
                  onPressed: () => context.goNamed(AppRoute.register.routeName),
                ),
              ],
            ),
            AuthLink(
              'Continue as guest',
              muted: true,
              onPressed: () => context.goNamed(AppRoute.home.routeName),
            ),
          ],
        ),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (notice != null) ...<Widget>[
                SoftNote(message: notice),
                const SizedBox(height: Spacing.formGap),
              ],
              if (rejected) ...<Widget>[
                SoftNote(
                  tone: NoteTone.error,
                  title: 'Incorrect email or password. ',
                  message:
                      '$attemptsLeft attempts left before a 15-minute pause.',
                ),
                const SizedBox(height: Spacing.formGap),
              ],
              if (needsEmail) ...<Widget>[
                SoftNote(
                  tone: NoteTone.error,
                  message: SignInMessage.passwordNeedsEmail.text,
                ),
                const SizedBox(height: Spacing.formGap),
              ],
              if (other != null) ...<Widget>[
                SoftNote(tone: NoteTone.error, message: other.text),
                const SizedBox(height: Spacing.formGap),
              ],
              AuthField(
                label: 'Email or mobile number',
                controller: _identifier,
                icon: TaytayIcons.mail,
                error: _identifierError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.username],
              ),
              const SizedBox(height: Spacing.formGap),
              AuthField(
                label: 'Password',
                controller: _password,
                icon: TaytayIcons.lock,
                obscure: _obscure,
                error: rejected ? 'Incorrect password' : _passwordError,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                trailing: ShowPasswordToggle(
                  shown: !_obscure,
                  showLabel: 'Show',
                  hideLabel: 'Hide',
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              AuthLink(
                'Forgot password?',
                alignment: AlignmentDirectional.centerStart,
                onPressed: () =>
                    context.goNamed(AppRoute.forgotPassword.routeName),
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
