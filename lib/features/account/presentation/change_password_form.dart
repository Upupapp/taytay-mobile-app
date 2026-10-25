import 'package:flutter/material.dart';

import '../../../core/result/result.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/taytay_text_field.dart';
import '../domain/account_password_client.dart';

/// Current password, then a new one. Firebase does the change.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({required this.client, this.onDone, super.key});

  final AccountPasswordClient client;
  final VoidCallback? onDone;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  String? _currentMessage;
  String? _nextMessage;
  String? _formMessage;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String current = _current.text;
    final String next = _next.text;
    setState(() {
      _currentMessage = current.isEmpty ? 'Enter your current password.' : null;
      _nextMessage = next.isEmpty ? 'Enter a new password.' : null;
      _formMessage = null;
    });
    if (current.isEmpty || next.isEmpty) return;
    if (next != _confirm.text) {
      setState(() => _nextMessage = 'Those passwords do not match.');
      return;
    }
    setState(() => _busy = true);
    final Result<void> result = await widget.client.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    switch (result) {
      case Ok<void>():
        widget.onDone?.call();
      case Err<void>(:final failure):
        final String? currentError = failure is ValidationFailure
            ? failure.firstErrorFor('current_password')
            : null;
        final String? nextError = failure is ValidationFailure
            ? failure.firstErrorFor('new_password')
            : null;
        setState(() {
          _busy = false;
          _currentMessage = currentError;
          _nextMessage = nextError;
          _formMessage = currentError == null && nextError == null
              ? failure.residentMessage
              : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TaytayTextField(
          label: 'Current password',
          controller: _current,
          obscureText: true,
          state: _currentMessage == null
              ? TaytayFieldState.normal
              : TaytayFieldState.error,
          message: _currentMessage,
        ),
        const SizedBox(height: 12),
        TaytayTextField(
          label: 'New password',
          controller: _next,
          obscureText: true,
          state: _nextMessage == null
              ? TaytayFieldState.normal
              : TaytayFieldState.error,
          message: _nextMessage,
        ),
        const SizedBox(height: 12),
        TaytayTextField(
          label: 'Repeat the new password',
          controller: _confirm,
          obscureText: true,
        ),
        if (_formMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(_formMessage!),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: _busy ? 'Saving' : 'Save password',
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
