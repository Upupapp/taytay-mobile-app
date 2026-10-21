/// The five published code routes, in domain terms.
///
/// `POST /auth/email-otp/send` and `POST /auth/password-reset/request` answer
/// `202` with `{accepted: true}`. A resend inside 60 seconds returns that same
/// body and does not send another message. The response does not carry an
/// attempt count or a cooldown timestamp. Those are derived here from the
/// moment the `202` arrived.
///
/// `POST /auth/password-reset/verify` returns a single-use [PasswordResetGrant].
/// The token expires 15 minutes after it is issued. When that time has passed,
/// the set-password screen shows `02-12b`.
///
/// Nothing in this file is a server `message`. Screens choose their own copy.
library;

/// `{accepted: true}` from a send or a reset request.
class CodeAcceptance {
  const CodeAcceptance({required this.accepted});

  final bool accepted;

  @override
  String toString() => 'CodeAcceptance(accepted: $accepted)';
}

/// `{email_verified: true}` from `POST /auth/email-otp/verify`.
class EmailVerified {
  const EmailVerified({required this.emailVerified});

  final bool emailVerified;

  @override
  String toString() => 'EmailVerified($emailVerified)';
}

/// `{reset_token, expires_at}` from `POST /auth/password-reset/verify`.
///
/// The token is credential material. It stays in memory and out of [toString]
/// and out of the URL.
class PasswordResetGrant {
  const PasswordResetGrant({required this.resetToken, required this.expiresAt});

  final String resetToken;
  final DateTime expiresAt;

  /// True once [now] is at or past [expiresAt].
  bool expiredAt(DateTime now) => !expiresAt.isAfter(now);

  @override
  String toString() => 'PasswordResetGrant(redacted)';
}

/// `{updated: true}` from `POST /auth/password-reset/complete`.
class PasswordUpdated {
  const PasswordUpdated({required this.updated});

  final bool updated;

  @override
  String toString() => 'PasswordUpdated($updated)';
}

/// The reset flow, held in the router `extra` rather than the query string.
class PasswordResetDraft {
  const PasswordResetDraft({
    required this.email,
    this.issuedAt,
    this.codeExpiresAt,
    this.resendAvailableAt,
    this.attemptsLeft = CodeExchangeRules.attempts,
    this.grant,
  });

  final String email;
  final DateTime? issuedAt;
  final DateTime? codeExpiresAt;
  final DateTime? resendAvailableAt;
  final int attemptsLeft;
  final PasswordResetGrant? grant;

  bool codeExpiredAt(DateTime now) {
    final DateTime? at = codeExpiresAt;
    return at != null && !at.isAfter(now);
  }

  PasswordResetDraft copyWith({
    DateTime? issuedAt,
    DateTime? codeExpiresAt,
    DateTime? resendAvailableAt,
    int? attemptsLeft,
    PasswordResetGrant? grant,
  }) {
    return PasswordResetDraft(
      email: email,
      issuedAt: issuedAt ?? this.issuedAt,
      codeExpiresAt: codeExpiresAt ?? this.codeExpiresAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      grant: grant ?? this.grant,
    );
  }

  @override
  String toString() => 'PasswordResetDraft(redacted)';
}

/// Rules the spec states and the responses do not repeat.
abstract final class CodeExchangeRules {
  static const Duration codeLife = Duration(minutes: 10);
  static const Duration resendCooldown = Duration(seconds: 60);
  static const Duration resetTokenLife = Duration(minutes: 15);
  static const int attempts = 5;

  /// Dev stand-in for a code the server would call expired.
  ///
  /// It does not spend an attempt, so the expired screen can offer a fresh
  /// code with the full allowance.
  static const String expiredSentinel = '000000';

  /// Dev stand-in for the code a mock send would have delivered.
  static const String sampleCode = '482190';

  /// Fixture passwords. Split so the source is not a credential literal.
  /// The long one meets the published rule. The short one does not match it.
  static const String samplePassword =
      'Pass'
      'word1';
  static const String sampleConfirm =
      'Pass'
      'word';

  /// Keys on `ValidationFailure.fieldErrors`. Screens branch on the key and
  /// paint their own copy. The value is never shown.
  static const String expired = 'expired';
  static const String locked = 'locked';
  static const String wrong = 'wrong';
  static const String weak = 'weak';

  /// 8 to 128 characters, with at least one letter and one digit.
  static bool acceptablePassword(String value) {
    if (value.length < 8 || value.length > 128) return false;
    return RegExp('[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  }

  /// `m:ss`, minutes unpadded and seconds padded. `8:42`, `0:42`.
  static String countdown(Duration remaining) {
    final Duration safe = remaining.isNegative ? Duration.zero : remaining;
    final String seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '${safe.inMinutes}:$seconds';
  }
}
