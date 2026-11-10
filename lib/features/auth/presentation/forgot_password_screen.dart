import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/code_exchange.dart';
import 'auth_form_page.dart';
import 'sign_in_controller.dart';
import 'sign_in_screen.dart';

/// `02-02`. A reset code is requested without saying whether the account exists.
///
/// Drawn as the redesign's form page (`SignIn.dc.html` pattern): the wave
/// header, one filled field, and the action in the footer.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({this.fixture = false, super.key});

  /// Paints the design's sample address and does not touch the repository.
  final bool fixture;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifier = TextEditingController();
  SignInController? _controller;
  String? _error;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixture) _identifier.text = 'juana.delacruz@example.com';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.fixture || _controller != null) return;
    final dependencies = AppDependencies.of(context);
    _controller =
        SignInController(
          repository: dependencies.authRepository,
          session: dependencies.session,
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = AccountIdentifier.validate(_identifier.text);
    setState(() => _error = error);
    if (error != null) return;
    final controller = _controller;
    if (controller == null) return;
    final ok = await controller.requestPasswordReset(_identifier.text);
    if (!mounted) return;
    final DateTime now = DateTime.now();
    final String email = _identifier.text.trim();
    if (!ok) {
      final AppFailure? failure = controller.refusal;
      final bool hold =
          failure is RateLimitedFailure ||
          (failure is CodeExchangeFailure &&
              failure.exchangeKind == CodeExchangeKind.locked);
      if (hold) {
        final Duration? wait = failure is RateLimitedFailure
            ? failure.retryAfter
            : (failure! as CodeExchangeFailure).retryAfter;
        unawaited(
          context.pushNamed(
            AppRoute.tooMany.routeName,
            extra: CodeHold.fromWait(
              origin: CodeHoldOrigin.passwordReset,
              email: email,
              now: now,
              wait: wait,
            ),
          ),
        );
        return;
      }
      setState(() => _sent = false);
      return;
    }
    final CodeAcceptance? accepted = controller.acceptance;
    if (accepted == null) return;
    unawaited(
      context.pushNamed(
        AppRoute.resetCode.routeName,
        extra: PasswordResetDraft(
          email: email,
          issuedAt: now,
          codeExpiresAt: now.add(CodeExchangeRules.codeLife),
          resendAvailableAt: now.add(
            Duration(seconds: accepted.retryAfterSeconds),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = _controller?.message;
    final String? error = _error;
    return AuthFormPage(
      title: 'Reset your password',
      subtitle:
          "Enter the email or mobile number on your account. We'll "
          'send a 6-digit code to reset your password.',
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.signIn.routeName),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            label: 'Send reset code',
            onPressed: _controller?.busy == true ? null : _send,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            "For your security, we don't say whether an account exists "
            'for this address.',
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(color: BrandColors.muted),
          ),
          AuthLink(
            'Back to sign in',
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthField(
            label: 'Email or mobile number',
            controller: _identifier,
            icon: TaytayIcons.mail,
            error: error,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const <String>[AutofillHints.username],
          ),
          if (_sent) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            const SoftNote(
              tone: NoteTone.success,
              message: 'If an account matches, a code is on its way.',
            ),
          ],
          if (message != null) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            SoftNote(tone: NoteTone.error, message: message.text),
          ],
        ],
      ),
    );
  }
}
