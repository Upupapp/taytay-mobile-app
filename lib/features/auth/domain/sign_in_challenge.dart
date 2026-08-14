import '../../../core/result/result.dart';

/// Where a resident is in the sign-in flow.
///
/// Two steps, because the committed contract is two calls: `POST /auth/otp`
/// then `POST /auth/otp/verify`. There is no third identifier and no password
/// step, because the backend offers a citizen neither.
enum SignInStep {
  /// Entering the mobile number.
  identifier,

  /// Entering the one-time code sent to it.
  code,
}

/// The only identifier a citizen can sign in with, per the committed contract.
///
/// `POST /api/v1/auth/tokens` — the email-and-password route — exists, but the
/// endpoint matrix marks it **Admin sign-in**. It is not offered here, and the
/// resident app must never grow a field for it: a citizen app that accepts staff
/// credentials is a staff surface in a resident repository (CLAUDE.md
/// Article 0).
abstract final class SignInIdentifier {
  /// Philippine mobile numbers are 11 digits beginning `09`.
  static final RegExp pattern = RegExp(r'^09\d{9}$');

  static const int length = 11;

  /// Validates for the *keyboard*, not for the account.
  ///
  /// Returns an error message about the shape of the input only. It can never
  /// say whether the number belongs to an account, because the app does not know
  /// and must not find out — see [SignInFeedback].
  static String? validate(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter your mobile number.';
    if (!pattern.hasMatch(input)) {
      return 'Enter an 11-digit mobile number starting with 09.';
    }
    return null;
  }

  /// Renders a number for display with its middle digits hidden.
  ///
  /// Used on the code screen so a resident can confirm they typed the right
  /// number without the full number sitting on a screen in a queue. `09171234567`
  /// becomes `0917 ••• 4567`.
  static String mask(String mobileNumber) {
    final digits = mobileNumber.trim();
    if (digits.length < 8) return '•••';
    return '${digits.substring(0, 4)} ••• '
        '${digits.substring(digits.length - 4)}';
  }
}

/// Rules for the one-time code itself.
abstract final class OneTimeCodeRules {
  /// Six digits. Chosen to match the length the endpoint matrix implies for an
  /// SMS code and the shape residents already meet from banks and telcos;
  /// confirm against the Identity module when it ships.
  static const int length = 6;

  /// How long before "Send a new code" becomes available again.
  ///
  /// A client-side cooldown is a courtesy, not a control: the server is
  /// attempt-limited (endpoint matrix, §2) and its answer is the one that
  /// counts. This only stops a resident spending their attempts on a button
  /// that was always going to be throttled.
  static const Duration resendCooldown = Duration(seconds: 60);

  static String? validate(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Enter the code we sent you.';
    if (input.length != length || !RegExp(r'^\d+$').hasMatch(input)) {
      return 'Enter the $length-digit code.';
    }
    return null;
  }
}

/// What the resident is told, as a closed set.
///
/// ---
///
/// **The non-enumeration rule.** Nothing in this enum distinguishes "that number
/// has no account" from "that code was wrong" from "that account is locked".
/// There is no such value to select, so no screen can render one and no future
/// edit can add one by accident.
///
/// This matters more for an LGU than for a consumer app. A sign-in screen that
/// answers "no account with that number" is a free lookup service for whether a
/// given person is a registered Taytay resident — usable by a debt collector, an
/// abusive ex-partner, or anyone running a list of numbers. The backend already
/// requires this of itself ("must not reveal whether the number is registered",
/// endpoint matrix §2); the client keeps the same promise so that a future
/// server change cannot leak through a client that was assuming otherwise.
enum SignInMessage {
  /// After requesting a code. Phrased conditionally on purpose.
  codeSent(
    'If that number is registered with Taytay LGU, a code is on its way.',
  ),

  /// After a failed verify. Covers a wrong code, an expired code, an unknown
  /// number and a refused account — deliberately one message for all four.
  codeNotAccepted(
    'That code did not work. Check the code and try again, or ask for a new '
    'one.',
  ),

  /// The server is throttling. Honest and actionable without saying why.
  tooManyAttempts(
    'Too many attempts. Please wait a little while before trying again.',
  ),

  offline(
    'You appear to be offline. Check your internet connection and try again.',
  ),

  timedOut('That took too long. Please try again.'),

  serviceUnavailable(
    'Signing in is temporarily unavailable. Please try again shortly.',
  ),

  unexpected(
    'Something went wrong. Please try again, or visit the Taytay municipal '
    'hall if it keeps happening.',
  );

  const SignInMessage(this.text);

  /// Resident-facing copy. Never the server's `message` field, which
  /// `docs/api/conventions.md` §4 defines as operator-facing.
  final String text;

  /// Whether trying the same thing again could reasonably work.
  bool get suggestsRetry =>
      this == offline || this == timedOut || this == serviceUnavailable;
}

/// Maps a transport failure onto resident copy.
abstract final class SignInFeedback {
  /// For `POST /auth/otp` and `POST /auth/otp/verify` alike.
  ///
  /// **`NotFoundFailure`, `ForbiddenFailure`, `ValidationFailure` and
  /// `ConflictFailure` all collapse into [SignInMessage.codeNotAccepted].**
  /// That is the whole point: those are precisely the codes a server might use
  /// to distinguish "no such number" from "wrong code", and distinguishing them
  /// here would rebuild the enumeration oracle the backend refuses to be.
  ///
  /// Rate limiting is the one refusal kept separate, because it is not about the
  /// account: it says "not now" regardless of whether the number exists, so it
  /// discloses nothing while telling the resident something they need.
  static SignInMessage forFailure(AppFailure failure) => switch (failure) {
    NetworkFailure() => SignInMessage.offline,
    TimeoutFailure() => SignInMessage.timedOut,
    RateLimitedFailure() => SignInMessage.tooManyAttempts,
    ServerFailure() => SignInMessage.serviceUnavailable,
    NotFoundFailure() ||
    ForbiddenFailure() ||
    ValidationFailure() ||
    ConflictFailure() ||
    UnauthenticatedFailure() => SignInMessage.codeNotAccepted,
    ContractFailure() || UnexpectedFailure() => SignInMessage.unexpected,
  };
}
