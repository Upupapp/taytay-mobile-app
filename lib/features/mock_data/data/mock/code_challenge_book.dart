import '../../../../core/result/result.dart';
import '../../../auth/domain/code_exchange.dart';

/// The dev mock's copy of the published code rules (`90aa39e`).
///
/// A send answers `202` with `retry_after: 60`. A resend inside that window is
/// `429` and carries the remaining seconds. A wrong code answers `code_invalid`
/// with `attempts_remaining` from 4 down to 1. The fifth wrong code is
/// `code_locked`. `000000` and a code older than 10 minutes are `code_expired`
/// and do not spend an attempt.
class CodeChallengeBook {
  CodeChallengeBook({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, _IssuedCode> _codes = <String, _IssuedCode>{};
  final Map<String, _IssuedGrant> _grants = <String, _IssuedGrant>{};

  static const String profileKey = 'profile-email';

  /// `POST /auth/email-otp/send`. No body. Always the profile email.
  Result<CodeAcceptance> sendEmailCode() => _issue(profileKey, sample: true);

  /// `POST /auth/email-otp/verify` with `{code}`.
  Result<EmailVerified> verifyEmailCode(String code) {
    final Result<void> verdict = _check(profileKey, code, sample: true);
    if (verdict case Err<void>(:final failure)) {
      return Err<EmailVerified>(failure);
    }
    return const Ok<EmailVerified>(EmailVerified(emailVerified: true));
  }

  /// `POST /auth/password-reset/request`. A well-formed email is `202`,
  /// including an address with no account. The cooldown is `429` for both,
  /// so the body does not say whether the address exists.
  Result<CodeAcceptance> requestReset(String email) {
    final String trimmed = email.trim();
    if (!_email(trimmed)) {
      return const Err<CodeAcceptance>(
        ValidationFailure(debugMessage: 'An email address is required.'),
      );
    }
    return _issue(trimmed, sample: true);
  }

  /// `POST /auth/password-reset/verify` with `{email, code}`.
  Result<PasswordResetGrant> verifyReset({
    required String email,
    required String code,
  }) {
    final Result<void> verdict = _check(email.trim(), code, sample: true);
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
      return const Err<PasswordUpdated>(
        ValidationFailure(debugMessage: 'Reset token was not accepted.'),
      );
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

  Result<CodeAcceptance> _issue(String key, {required bool sample}) {
    final DateTime now = _now().toUtc();
    final _IssuedCode? current = _codes[key];
    if (current != null &&
        current.acceptsSample == sample &&
        !current.spent &&
        now.isBefore(current.resendUntil)) {
      return Err<CodeAcceptance>(
        RateLimitedFailure(
          retryAfter: Duration(seconds: _remaining(now, current.resendUntil)),
          debugMessage: 'Resend is still cooling down.',
        ),
      );
    }
    _codes[key] = _IssuedCode(
      issuedAt: now,
      resendUntil: now.add(CodeExchangeRules.resendCooldown),
      acceptsSample: sample,
    );
    return const Ok<CodeAcceptance>(
      CodeAcceptance(accepted: true, retryAfterSeconds: 60),
    );
  }

  Result<void> _check(String key, String code, {required bool sample}) {
    final String digits = code.trim();
    final DateTime now = _now().toUtc();
    final _IssuedCode issued = _codes.putIfAbsent(
      key,
      () => _IssuedCode(issuedAt: now, resendUntil: now, acceptsSample: false),
    );

    if (digits == CodeExchangeRules.expiredSentinel) {
      return Err<void>(
        CodeExchangeFailure(
          exchangeKind: CodeExchangeKind.expired,
          attemptsRemaining: issued.attemptsLeft,
          debugMessage: 'Code has expired.',
        ),
      );
    }
    if (!issued.issuedAt.add(CodeExchangeRules.codeLife).isAfter(now) &&
        issued.acceptsSample) {
      return Err<void>(
        CodeExchangeFailure(
          exchangeKind: CodeExchangeKind.expired,
          attemptsRemaining: issued.attemptsLeft,
          debugMessage: 'Code has expired.',
        ),
      );
    }
    if (issued.spent || issued.attemptsLeft <= 0) {
      return Err<void>(_locked(issued, now));
    }
    final bool matches =
        issued.acceptsSample &&
        sample &&
        digits == CodeExchangeRules.sampleCode;
    if (!matches) {
      issued.attemptsLeft -= 1;
      if (issued.attemptsLeft <= 0) {
        return Err<void>(_locked(issued, now));
      }
      return Err<void>(
        CodeExchangeFailure(
          exchangeKind: CodeExchangeKind.invalid,
          attemptsRemaining: issued.attemptsLeft,
          debugMessage: 'Code was not accepted.',
        ),
      );
    }
    issued.spent = true;
    return const Ok<void>(null);
  }

  CodeExchangeFailure _locked(_IssuedCode issued, DateTime now) {
    final int wait = now.isBefore(issued.resendUntil)
        ? _remaining(now, issued.resendUntil)
        : 0;
    return CodeExchangeFailure(
      exchangeKind: CodeExchangeKind.locked,
      attemptsRemaining: 0,
      retryAfter: Duration(seconds: wait),
      debugMessage: 'Code is locked.',
    );
  }

  /// Remaining whole seconds, at least 1 while [until] is still ahead, and
  /// never above the published 900 second cap.
  static int _remaining(DateTime now, DateTime until) {
    final int seconds = until.difference(now).inSeconds;
    if (seconds < 1) return 1;
    if (seconds > 900) return 900;
    return seconds;
  }

  static bool _email(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class _IssuedCode {
  _IssuedCode({
    required this.issuedAt,
    required this.resendUntil,
    required this.acceptsSample,
  });

  final DateTime issuedAt;
  final DateTime resendUntil;
  final bool acceptsSample;
  int attemptsLeft = CodeExchangeRules.attempts;
  bool spent = false;
}

class _IssuedGrant {
  _IssuedGrant({required this.expiresAt});

  final DateTime expiresAt;
  bool spent = false;
}
