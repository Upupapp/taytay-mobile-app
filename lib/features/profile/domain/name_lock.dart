import '../../../core/session/access_level.dart';

/// Whether the resident may change the name on their account, read from the
/// `verification_status` that `GET /me` sent (D-195).
///
/// ---
///
/// **Taytay LGU checks the account's name against the ID** (the staff
/// console's DL-197, backend `c5e1a7d`). While that check is pending, and after
/// it was approved, `PATCH /me` refuses a different `name` with `409`, because
/// the digital ID shows the account's name. Before a request, and after a
/// rejection, the name is the resident's to set. A request rejected because
/// the name does not match the ID can only be answered by changing it.
///
/// This decides what a screen *offers*. The server decides what is allowed
/// (CLAUDE.md Article 3.1). A status this build does not know offers no
/// change: a field that looks editable and is then refused is worse than one
/// that says the app could not tell.
enum NameLock {
  /// `unverified` or `rejected`: no ID is under review or approved.
  open,

  /// `pending`: an ID is being checked against this name.
  underReview,

  /// `verified`: Taytay LGU approved an ID that shows this name.
  checked,

  /// No status, or one this build does not know.
  unknown;

  /// `ProfilePatch.name` on the Node API: trimmed, 1 to 120 characters.
  static const int maxLength = 120;

  /// Maps the server's status word. Only [AccessLevel.fromVerificationTier]
  /// reads `verified`, as everywhere else in the app.
  static NameLock forTier(String? tier) {
    if (AccessLevel.fromVerificationTier(tier) == AccessLevel.verified) {
      return NameLock.checked;
    }
    return switch (tier) {
      'unverified' || 'rejected' => NameLock.open,
      'pending' => NameLock.underReview,
      _ => NameLock.unknown,
    };
  }

  bool get allowsChange => this == NameLock.open;

  /// The one sentence under the name on Edit profile.
  String get explanation => switch (this) {
    NameLock.open => NameCheckCopy.asPrinted,
    NameLock.underReview => NameCheckCopy.underReview,
    NameLock.checked => NameCheckCopy.checked,
    NameLock.unknown => NameCheckCopy.unknown,
  };
}

/// What a resident reads about the name check. Literal English, as the
/// account and verification screens are (D-195).
abstract final class NameCheckCopy {
  static const String fieldLabel = 'Full name';

  static const String asPrinted =
      'Write your name exactly as it is printed on your government ID. '
      'Taytay LGU checks it against your ID.';

  static const String underReview =
      'Taytay LGU is checking this name against your ID, so it cannot be '
      'changed while the check is pending.';

  static const String checked =
      'Taytay LGU checked this name against your ID, so it cannot be changed '
      'here. To change it, ask Taytay LGU.';

  static const String unknown =
      'We could not check whether your name can be changed. Try again later.';

  /// Said before an ID is sent, on the start and the resubmit pages.
  static const String beforeSendingTitle = 'Your name and your ID';

  static const String beforeSending =
      'Taytay LGU will check that your ID shows the name on your account. '
      'Make sure the two match before you send. Your name cannot be changed '
      'while the check is pending or after it is approved.';

  static const String checkName = 'Check the name on your account';

  static const String emptyName =
      'Enter your name exactly as it is printed on your government ID.';

  static const String tooLong =
      'Your name can be up to ${NameLock.maxLength} characters.';
}
