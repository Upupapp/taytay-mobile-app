import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';
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

  /// A field's error as the form or the password client wrote it, in English;
  /// [_say] puts it in the phone's language when it is drawn.
  String? _currentMessage;
  String? _nextMessage;

  /// Why the change failed when no field says so.
  AppFailure? _formFailure;
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
      _currentMessage = current.isEmpty ? _PasswordCopy.enterCurrent : null;
      _nextMessage = next.isEmpty ? _PasswordCopy.enterNew : null;
      _formFailure = null;
    });
    if (current.isEmpty || next.isEmpty) return;
    if (next != _confirm.text) {
      setState(() => _nextMessage = _PasswordCopy.mismatch);
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
          _formFailure = currentError == null && nextError == null
              ? failure
              : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final AppFailure? formFailure = _formFailure;
    final String? formMessage = formFailure == null
        ? null
        : localisedResidentMessage(context, formFailure);
    final VoidCallback? onCancel = widget.onCancel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthField(
          label: strings.acctCurrentPassword,
          controller: _current,
          obscure: true,
          error: _say(strings, _currentMessage),
          icon: TaytayIcons.lock,
        ),
        const SizedBox(height: Spacing.formGap),
        AuthField(
          label: strings.acctNewPassword,
          controller: _next,
          obscure: true,
          error: _say(strings, _nextMessage),
          icon: TaytayIcons.key,
        ),
        const SizedBox(height: Spacing.formGap),
        AuthField(
          label: strings.acctRepeatNewPassword,
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
            label: _busy ? strings.acctSaving : strings.acctSavePassword,
            onPressed: _busy ? null : _submit,
          ),
          text: onCancel == null
              ? null
              : DialogButton(label: strings.actionCancel, onPressed: onCancel),
        ),
      ],
    );
  }
}

/// A field error in the phone's language. The password clients
/// (`FirebaseAccountPasswordClient`, the dev mock) answer in English field
/// errors, the same sentences as below; one this form does not know is shown
/// as it came.
String? _say(AppStrings strings, String? message) => switch (message) {
  null => null,
  _PasswordCopy.enterCurrent => strings.acctEnterCurrentPassword,
  _PasswordCopy.enterNew => strings.acctEnterNewPassword,
  _PasswordCopy.mismatch => strings.acctPasswordsDoNotMatch,
  _PasswordCopy.wrongCurrent => strings.acctPasswordWrong,
  _PasswordCopy.weak => strings.acctPasswordWeak,
  final String other => other,
};

/// The English field errors, as the form and the password clients write them.
abstract final class _PasswordCopy {
  static const String enterCurrent = 'Enter your current password.';
  static const String enterNew = 'Enter a new password.';
  static const String mismatch = 'Those passwords do not match.';
  static const String wrongCurrent = 'That password does not match.';
  static const String weak =
      'Use at least 8 characters, with a letter and a number.';
}
