import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_thread.dart';
import '../domain/sign_in_challenge.dart';
import 'sign_in_controller.dart';

/// The white form sheet. Tests look for this to prove the copy sits on it.
const Key signInFormSheetKey = Key('sign-in-form-sheet');

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
  const SignInScreen({this.returnTo, this.threadCycle = 0, super.key});

  final String? returnTo;

  /// Where the 7s speck loop starts. Get started passes the live welcome
  /// cycle. Any other entry starts at the beginning of the loop. The thread
  /// stays on this screen; it is not a one-shot overlay.
  final double threadCycle;

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
      backgroundColor: BrandColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _SignInFrame(
            height: constraints.maxHeight,
            threadCycle: widget.threadCycle,
            header: WovenHeader(
              showBack: true,
              backEnabled:
                  !(controller.step == SignInStep.code && controller.busy),
              onBack: controller.step == SignInStep.code
                  ? controller.changeNumber
                  : null,
              // The page paints the field. The header painter draws an
              // 844-tall ramp and would put navy behind the form.
              paintField: false,
              includeSafeArea: false,
              padding: const EdgeInsets.fromLTRB(18, 0, 20, 0),
            ),
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Three distinct notices, and the distinction is the point of
                // TAB 06 step 2. An expiry is not a sign-out and neither is a
                // network failure; a resident dropped on this screen with one
                // generic sentence cannot tell whether something went wrong,
                // whether they did it, or whether to try again.
                if (endedReason == SessionEndedReason.expired)
                  _Notice(
                    icon: Icons.lock_clock_outlined,
                    text: AppStrings.of(context).signInNoticeExpired,
                  )
                else if (endedReason == SessionEndedReason.signedOut)
                  _Notice(
                    icon: Icons.check_circle_outline,
                    text: AppStrings.of(context).signInNoticeSignedOut,
                  )
                else if (widget.returnTo != null)
                  _Notice(
                    icon: Icons.login_outlined,
                    text: AppStrings.of(context).signInNoticeReturnTo,
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
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.taytayBlue,
                  ),
                  onPressed: () =>
                      context.goNamed(AppRoute.signInHelp.routeName),
                  child: const Text('Trouble signing in?'),
                ),
                if (controller.step == SignInStep.identifier) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  // TAB 03 / F15. Two states in one build, chosen by the server.
                  //
                  // Under staff-mediated onboarding this is NOT a disabled
                  // button. A control a resident cannot use tells them the app is
                  // broken; a sentence tells them where to go. There is no
                  // self-registration route on the server, so offering the wizard
                  // here would be a promise the platform cannot keep.
                  if (dependencies
                      .platform
                      .onboardingMode
                      .allowsSelfRegistration)
                    SecondaryButton(
                      kind: TaytayButtonKind.signIn,
                      onPressed: () =>
                          context.goNamed(AppRoute.register.routeName),
                      label: 'Create an account',
                    )
                  else
                    const _OfficeOnboardingPanel(),
                ],
                const SizedBox(height: Spacing.sm),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: AppTypography.linkGuest,
                    foregroundColor: BrandColors.taytayBlue,
                  ),
                  onPressed: () => context.goNamed(AppRoute.home.routeName),
                  child: const Text('Continue as guest'),
                ),
                if (kDebugMode) const _DebugSessionSimulator(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 02-01's frame: the field fades to the page colour around y = 330, the
/// stitch sits on that field, and the form sits on the white sheet in front
/// of the stitch.
class _SignInFrame extends StatelessWidget {
  const _SignInFrame({
    required this.height,
    required this.threadCycle,
    required this.header,
    required this.form,
  });

  /// The scaffold body, already shrunk for the keyboard.
  final double height;
  final double threadCycle;
  final Widget header;
  final Widget form;

  /// `.sheet { top: 332px; left/right: 14px; bottom: 20px }`.
  static const double designSheetTop = 332;
  static const double sheetSide = 14;
  static const double sheetBottom = 20;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final headerTop = padding.top > 44 ? padding.top : 44.0;
    final type = MediaQuery.textScalerOf(context).scale(1);
    final belowHeader = headerTop + math.max(56.0, 48 * type);
    final bottom = math.max(sheetBottom, padding.bottom);
    final side = math.max(sheetSide, math.max(padding.left, padding.right));
    // On the 844 frame the sheet starts at 332. A short window (landscape,
    // a small phone) keeps enough sheet to scroll instead of a 38 dp sliver.
    var sheetTop = designSheetTop;
    const minSheet = 160.0;
    if (height - bottom - sheetTop < minSheet) {
      sheetTop = math.max(belowHeader, height - bottom - minSheet);
    }
    if (sheetTop < belowHeader && belowHeader < height - bottom - 48) {
      sheetTop = belowHeader;
    }
    final maxTop = math.max(0.0, height - bottom - 48);
    if (sheetTop > maxTop) sheetTop = maxTop;

    return Stack(
      key: const Key('sign-in-stack'),
      children: <Widget>[
        const Positioned.fill(child: SignInBackdrop()),
        Positioned.fill(
          child: IgnorePointer(child: SignInThreadOverlay(cycle: threadCycle)),
        ),
        Positioned(
          top: headerTop,
          left: padding.left,
          right: padding.right,
          child: header,
        ),
        Positioned(
          top: sheetTop,
          left: side,
          right: side,
          bottom: bottom,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1F062358),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              key: signInFormSheetKey,
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.all(7),
                        child: CustomPaint(painter: _SheetSeamPainter()),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                      child: form,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `.sheet:before` — a 1.4 px gold dash, inset 7, radius 20.
class _SheetSeamPainter extends CustomPainter {
  const _SheetSeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x8CC9A227);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SheetSeamPainter oldDelegate) => false;
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
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Welcome to Taytay LGU IDS',
            style: AppTypography.h1SignIn.copyWith(
              color: BrandColors.taytayBlueDark,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Enter your mobile number and we will send you a one-time code. '
            'There is no password to remember.',
            style: AppTypography.bodyCompact.copyWith(
              color: BrandColors.sheetBody,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          TextFormField(
            controller: controller,
            style: AppTypography.fieldValue,
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
            kind: TaytayButtonKind.signIn,
            label: 'Send one-time code',
            loading: busy,
            onPressed: busy ? null : onSubmit,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Taytay LGU uses your mobile number to sign you in and to contact '
            'you about your requests. It is never shared for advertising.',
            style: AppTypography.listMeta.copyWith(
              fontSize: 11,
              color: BrandColors.textMuted,
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
    final cooldown = signIn.resendCooldownSeconds;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Enter your code',
            style: AppTypography.h1SignIn.copyWith(
              color: BrandColors.taytayBlueDark,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            // Masked: a resident can confirm the number without their full
            // number sitting on a screen readable over a shoulder in a queue.
            'We sent a ${OneTimeCodeRules.length}-digit code to '
            '${signIn.maskedMobileNumber}.',
            style: AppTypography.bodyCompact.copyWith(
              color: BrandColors.sheetBody,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          TextFormField(
            controller: controller,
            style: AppTypography.fieldValue,
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
            kind: TaytayButtonKind.signIn,
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

/// Where an account comes from, when it does not come from this app.
///
/// Shown instead of the wizard whenever the server has not said residents may
/// enrol themselves — which is every build today, because there is no route
/// behind self-registration (F15, manual-tasks item 5).
///
/// The office's contact details come from `app/bootstrap`, never from a
/// constant here: a phone number compiled into a released app is one the
/// municipality cannot correct without a store submission.
class _OfficeOnboardingPanel extends StatelessWidget {
  const _OfficeOnboardingPanel();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final support = AppDependencies.of(context).platform.bootstrap.support;
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              strings.onboardingOfficeTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              strings.onboardingOfficeBody,
              style: theme.textTheme.bodyMedium,
            ),
            // Rendered only when the server actually supplied them. A line
            // reading "Ask the office:  · " is worse than no line.
            if (support.email.isNotEmpty ||
                support.phone.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.sm),
              Text(
                strings.onboardingOfficeContact(support.email, support.phone),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
