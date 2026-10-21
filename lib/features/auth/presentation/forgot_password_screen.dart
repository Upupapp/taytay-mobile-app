import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_thread.dart';
import 'auth_stage.dart';
import 'sign_in_controller.dart';
import 'sign_in_screen.dart';

/// `02-02`. A reset code is requested without saying whether the account exists.
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
    setState(() => _sent = ok);
  }

  @override
  Widget build(BuildContext context) {
    final message = _controller?.message;
    return AuthStage(
      sheetTop: 300,
      wrapSheet: false,
      arch: AuthArch.key,
      atmosphere: SignInAtmosphere.reset,
      curve: ThreadCurve.reset,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.signIn.routeName),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AuthCopy(
              eyebrow: 'Nakalimutan ang password',
              title: 'Reset your password',
              subtitle:
                  "Enter the email or mobile number on your account. We'll "
                  'send a 6-digit code to reset your password.',
            ),
            const SizedBox(height: 12),
            Text(
              'Email or mobile number',
              style: AppTypography.label.copyWith(
                color: BrandColors.fieldLabel,
              ),
            ),
            const SizedBox(height: 5),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandColors.taytayBlue, width: 1.4),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x1F0B3D91), spreadRadius: 3),
                ],
              ),
              child: SizedBox(
                height: 44,
                child: TextFormField(
                  controller: _identifier,
                  style: AppTypography.fieldValue,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: BrandColors.danger,
                    fontWeight: AppTypography.strong,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_sent)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'If an account matches, a code is on its way.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: AppTypography.body,
                    color: Color(0xFF5B6680),
                  ),
                ),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message.text),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
              kind: TaytayButtonKind.signIn,
              label: 'Send reset code',
              onPressed: _controller?.busy == true ? null : _send,
            ),
            const SizedBox(height: 10),
            const Text(
              "For your security, we don't say whether an account exists "
              'for this address.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: AppTypography.body,
                color: Color(0xFF5B6680),
              ),
            ),
            const SizedBox(height: 14),
            AuthTextLink(
              'Back to sign in',
              onPressed: () => context.goNamed(AppRoute.signIn.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
