import '../../../core/result/result.dart';
import '../domain/code_exchange.dart';

/// The dev mock's copy of the published code rules.
///
/// The wire shapes match the OpenAPI envelopes. Attempt counts and the resend
/// window are not fields on those envelopes: a `202` during the 60 second
/// cooldown is the same body and does not start a new code.
class CodeChallengeBook {
  CodeChallengeBook({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, _IssuedCode> _codes = <String, _IssuedCode>{};
  final Map<String, _IssuedGrant> _grants = <String, _IssuedGrant>{};

  static const String profileKey = 'profile-email';

  /// `POST /auth/email-otp/send`. No body. Always the profile email.
  Result<CodeAcceptance> sendEmailCode() => _issue(profileKey);

  /// `POST /auth/email-otp/verify` with `{code}`.
  Result<EmailVerified> verifyEmailCode(String code) {
    final Result<void> verdict = _check(profileKey, code);
    if (verdict case Err<void>(:final failure)) {
      return Err<EmailVerified>(failure);
    }
    return const Ok<EmailVerified>(EmailVerified(emailVerified: true));
  }

  /// `POST /auth/password-reset/request`. A well-formed email is always `202`,
  /// including an address with no account, the cooldown, and a mailer failure.
  Result<CodeAcceptance> requestReset(String email) {
    final String trimmed = email.trim();
    if (!_email(trimmed)) {
      return const Err<CodeAcceptance>(
        ValidationFailure(debugMessage: 'An email address is required.'),
      );
    }
    return _issue(trimmed);
  }

  /// `POST /auth/password-reset/verify` with `{email, code}`.
  Result<PasswordResetGrant> verifyReset({
    required String email,
    required String code,
  }) {
    final Result<void> verdict = _check(email.trim(), code);
    if (verdict case Err<void>(:final failure)) {
      return Err<PasswordResetGrant>(failure);
    }
    final DateTime expires = _now().toUtc().add(
      CodeExchangeRules.resetTokenLife,
    );
    const String token = 'example-reset-token-not-a-secret';
    _grants[token] = _IssuedGrant(expiresAt: expires);
    return Ok<PasswordResetGrant>(
      PasswordResetGrant(resetToken: token, expiresAt: expires),
    );
  }

  /// `POST /auth/password-reset/complete`. A weak password does not spend the
  /// token. An unknown, used, or expired token is the same validation failure.
  Result<PasswordUpdated> complete({
    required String resetToken,
    required String newPassword,
  }) {
    final _IssuedGrant? grant = _grants[resetToken];
    final bool dead =
        grant == null ||
        grant.spent ||
        !grant.expiresAt.isAfter(_now().toUtc());
    if (dead) {
      return Err<PasswordUpdated>(_refused(CodeExchangeRules.expired));
    }
    if (!CodeExchangeRules.acceptablePassword(newPassword)) {
      return const Err<PasswordUpdated>(
        ValidationFailure(
          fieldErrors: <String, List<String>>{
            'new_password': <String>[CodeExchangeRules.weak],
          },
          debugMessage: 'Password does not meet the published rule.',
        ),
      );
    }
    grant.spent = true;
    return const Ok<PasswordUpdated>(PasswordUpdated(updated: true));
  }

  Result<CodeAcceptance> _issue(String key) {
    final DateTime now = _now().toUtc();
    final _IssuedCode? current = _codes[key];
    if (current != null &&
        !current.spent &&
        now.isBefore(current.resendUntil)) {
      return const Ok<CodeAcceptance>(CodeAcceptance(accepted: true));
    }
    _codes[key] = _IssuedCode(
      issuedAt: now,
      resendUntil: now.add(CodeExchangeRules.resendCooldown),
    );
    return const Ok<CodeAcceptance>(CodeAcceptance(accepted: true));
  }

  Result<void> _check(String key, String code) {
    final String digits = code.trim();
    if (digits == CodeExchangeRules.expiredSentinel) {
      return Err<void>(_refused(CodeExchangeRules.expired));
    }
    final _IssuedCode? issued = _codes[key];
    if (issued == null) {
      return Err<void>(_refused(CodeExchangeRules.wrong));
    }
    final DateTime now = _now().toUtc();
    if (!issued.issuedAt.add(CodeExchangeRules.codeLife).isAfter(now)) {
      return Err<void>(_refused(CodeExchangeRules.expired));
    }
    if (issued.spent || issued.attemptsLeft <= 0) {
      return Err<void>(_refused(CodeExchangeRules.locked));
    }
    if (digits != CodeExchangeRules.sampleCode) {
      issued.attemptsLeft -= 1;
      if (issued.attemptsLeft <= 0) {
        return Err<void>(_refused(CodeExchangeRules.locked));
      }
      return Err<void>(_refused(CodeExchangeRules.wrong));
    }
    issued.spent = true;
    return const Ok<void>(null);
  }

  ValidationFailure _refused(String kind) {
    return ValidationFailure(
      fieldErrors: <String, List<String>>{
        'code': <String>[kind],
      },
      debugMessage: 'Code was not accepted.',
    );
  }

  static bool _email(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class _IssuedCode {
  _IssuedCode({required this.issuedAt, required this.resendUntil});

  final DateTime issuedAt;
  final DateTime resendUntil;
  int attemptsLeft = CodeExchangeRules.attempts;
  bool spent = false;
}

class _IssuedGrant {
  _IssuedGrant({required this.expiresAt});

  final DateTime expiresAt;
  bool spent = false;
}
