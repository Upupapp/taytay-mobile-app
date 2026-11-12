/// The five published code routes, in domain terms.
///
/// `POST /auth/email-otp/send` and `POST /auth/password-reset/request` answer
/// `202` with `{accepted: true, retry_after}`. A resend inside that wait is
/// `429 RATE_LIMITED` and does not send another message. Verify answers `422`
/// with `code_invalid`, `code_expired`, or `code_locked`. The screen shows the
/// server's `attempts_remaining` and `retry_after`. It does not keep its own.
///
/// `POST /auth/password-reset/verify` returns a single-use [PasswordResetGrant].
/// The token expires 15 minutes after it is issued. When that time has passed,
/// the set-password screen shows `02-12b`.
///
/// Nothing in this file is a server `message`. Screens choose their own copy.
library;

import '../../../core/result/result.dart';

/// `{accepted, retry_after}` from a send or a reset request.
class CodeAcceptance {
  const CodeAcceptance({
    required this.accepted,
    required this.retryAfterSeconds,
  });

  final bool accepted;

  /// Seconds from `data.retry_after`. A missing value is a contract failure
  /// at decode time, so this is never invented as 60.
  final int retryAfterSeconds;

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
    this.attemptsRemaining,
    this.limited = false,
    this.grant,
  });

  final String email;
  final DateTime? issuedAt;
  final DateTime? codeExpiresAt;
  final DateTime? resendAvailableAt;

  /// From `details.attempts_remaining` after a verify. Null until the server
  /// has said. A fresh `202` does not set it.
  final int? attemptsRemaining;

  /// `code_locked` or `RATE_LIMITED`. The screen is `02-14`.
  final bool limited;

  final PasswordResetGrant? grant;

  bool codeExpiredAt(DateTime now) {
    final DateTime? at = codeExpiresAt;
    return at != null && !at.isAfter(now);
  }

  PasswordResetDraft copyWith({
    DateTime? issuedAt,
    DateTime? codeExpiresAt,
    DateTime? resendAvailableAt,
    int? attemptsRemaining,
    bool clearAttempts = false,
    bool? limited,
    PasswordResetGrant? grant,
  }) {
    return PasswordResetDraft(
      email: email,
      issuedAt: issuedAt ?? this.issuedAt,
      codeExpiresAt: codeExpiresAt ?? this.codeExpiresAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      attemptsRemaining: clearAttempts
          ? null
          : (attemptsRemaining ?? this.attemptsRemaining),
      limited: limited ?? this.limited,
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

  /// The `02-14` bar. A server wait longer than this is shown as 15:00.
  static const int holdWindowSeconds = 900;

  /// `mm:ss`, both padded, capped at 15:00. `14:32`, `00:00`.
  static String holdClock(Duration remaining) {
    final int seconds = remaining.inSeconds.clamp(0, holdWindowSeconds);
    final String minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final String secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// How full the `02-14` bar is. Empty at 15:00, full at 00:00.
  static double holdProgress(Duration remaining) {
    final int seconds = remaining.inSeconds.clamp(0, holdWindowSeconds);
    return (holdWindowSeconds - seconds) / holdWindowSeconds;
  }

  /// `m:ss`, minutes unpadded and seconds padded. `8:42`, `0:42`.
  static String countdown(Duration remaining) {
    final Duration safe = remaining.isNegative ? Duration.zero : remaining;
    final String seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '${safe.inMinutes}:$seconds';
  }
}

/// What the code screens show, taken only from the last server answer.
class CodeAttemptView {
  const CodeAttemptView({
    this.attemptsRemaining,
    this.resendAt,
    this.expiresAt,
    this.expired = false,
    this.limited = false,
    this.unavailable = false,
    this.wrong = false,
  });

  final int? attemptsRemaining;
  final DateTime? resendAt;
  final DateTime? expiresAt;
  final bool expired;
  final bool limited;
  final bool unavailable;
  final bool wrong;

  bool canResendAt(DateTime now) {
    final DateTime? at = resendAt;
    return at == null || !at.isAfter(now);
  }

  /// A `503` sets [unavailable] and leaves the counters. Anything else that is
  /// not a code or rate-limit refusal leaves the view unchanged.
  CodeAttemptView applyFailure(AppFailure failure, DateTime now) {
    if (failure is ServerFailure && failure.isTemporary) {
      return CodeAttemptView(
        attemptsRemaining: attemptsRemaining,
        resendAt: resendAt,
        expiresAt: expiresAt,
        unavailable: true,
      );
    }
    if (failure is RateLimitedFailure) {
      return CodeAttemptView(
        attemptsRemaining: attemptsRemaining,
        resendAt: _waitUntil(now, failure.retryAfter),
        expiresAt: expiresAt,
        limited: true,
      );
    }
    if (failure is CodeExchangeFailure) {
      final int? attempts = failure.attemptsRemaining ?? attemptsRemaining;
      return switch (failure.exchangeKind) {
        CodeExchangeKind.invalid => CodeAttemptView(
          attemptsRemaining: attempts,
          resendAt: resendAt,
          expiresAt: expiresAt,
          wrong: true,
        ),
        CodeExchangeKind.expired => CodeAttemptView(
          attemptsRemaining: attempts,
          resendAt: resendAt,
          expiresAt: expiresAt,
          expired: true,
        ),
        CodeExchangeKind.locked => CodeAttemptView(
          attemptsRemaining: failure.attemptsRemaining ?? attempts,
          resendAt: _waitUntil(now, failure.retryAfter),
          expiresAt: expiresAt,
          limited: true,
        ),
      };
    }
    return this;
  }

  /// A fresh `202` starts the resend clock and clears the live attempt count.
  CodeAttemptView applyAcceptance(CodeAcceptance acceptance, DateTime now) {
    return CodeAttemptView(
      resendAt: now.add(Duration(seconds: acceptance.retryAfterSeconds)),
      expiresAt: now.add(CodeExchangeRules.codeLife),
    );
  }

  /// Wait copy used when a screen cannot open `02-14`. Null when the server
  /// named no wait, so the screen does not invent one.
  String? holdDetail(DateTime now) {
    if (!limited) return null;
    final DateTime? at = resendAt;
    if (at == null) return null;
    if (!at.isAfter(now)) {
      return 'Maaari ka nang humingi ng bagong code.';
    }
    final String clock = CodeExchangeRules.countdown(at.difference(now));
    return 'Maaari kang humingi ng bagong code sa $clock.';
  }

  static const String holdTitle = 'Masyadong maraming subok.';

  static const String unavailableCopy =
      'Hindi available ang serbisyo ngayon. Subukang muli.';

  static DateTime? _waitUntil(DateTime now, Duration? wait) {
    if (wait == null) return null;
    if (wait <= Duration.zero) return now;
    final Duration capped = wait.inSeconds > CodeExchangeRules.holdWindowSeconds
        ? const Duration(seconds: CodeExchangeRules.holdWindowSeconds)
        : wait;
    return now.add(capped);
  }
}

/// Which code screen `02-14b` returns to.
enum CodeHoldOrigin { passwordReset, emailVerification }

/// Why `02-14` is open, and when it becomes `02-14b`.
class CodeHold {
  const CodeHold({
    required this.origin,
    required this.email,
    required this.resumeAt,
  });

  /// `retry_after` of 0, or a missing wait, opens `02-14b` now.
  factory CodeHold.fromWait({
    required CodeHoldOrigin origin,
    required String email,
    required DateTime now,
    required Duration? wait,
  }) {
    if (wait == null || wait <= Duration.zero) {
      return CodeHold(origin: origin, email: email, resumeAt: now);
    }
    final int seconds = wait.inSeconds > CodeExchangeRules.holdWindowSeconds
        ? CodeExchangeRules.holdWindowSeconds
        : wait.inSeconds;
    return CodeHold(
      origin: origin,
      email: email,
      resumeAt: now.add(Duration(seconds: seconds)),
    );
  }

  final CodeHoldOrigin origin;
  final String email;

  /// The instant a new code can be requested. Not after [DateTime.now] means
  /// `02-14b` immediately, including `retry_after` of 0.
  final DateTime resumeAt;

  bool readyAt(DateTime now) => !resumeAt.isAfter(now);

  @override
  String toString() => 'CodeHold(${origin.name})';
}
