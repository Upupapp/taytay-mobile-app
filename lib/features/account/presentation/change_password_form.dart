import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/result/result.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/soft_note.dart';
import '../domain/account_password_client.dart';

/// Current password, then a new one. Firebase does the change.
///
/// Opened in a dialog (`AppDialog.show`); its buttons are the dialog's
/// actions, drawn here because Save follows the form's own state.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    required this.client,
    this.onDone,
    this.onCancel,
    super.key,
  });

  final AccountPasswordClient client;
  final VoidCallback? onDone;

  /// Closes the form without saving; no Cancel button when null.
  final VoidCallback? onCancel;

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
    final String? formMessage = _formMessage;
    final VoidCallback? onCancel = widget.onCancel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthField(
          label: 'Current password',
          controller: _current,
          obscure: true,
          error: _currentMessage,
          icon: TaytayIcons.lock,
        ),
        const SizedBox(height: Spacing.formGap),
        AuthField(
          label: 'New password',
          controller: _next,
          obscure: true,
          error: _nextMessage,
          icon: TaytayIcons.key,
        ),
        const SizedBox(height: Spacing.formGap),
        AuthField(
          label: 'Repeat the new password',
          controller: _confirm,
          obscure: true,
          icon: TaytayIcons.key,
        ),
        if (formMessage != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          SoftNote(tone: NoteTone.error, message: formMessage),
        ],
        AppDialogActions(
          primary: DialogButton(
            label: _busy ? 'Saving' : 'Save password',
            onPressed: _busy ? null : _submit,
          ),
          text: onCancel == null
              ? null
              : DialogButton(label: 'Cancel', onPressed: onCancel),
        ),
      ],
    );
  }
}
