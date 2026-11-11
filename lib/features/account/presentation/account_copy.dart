/// What the account screens' confirmations and notices say.
///
/// Held in one place so each dialog's real words can be opened at every phone
/// width and at 200% text by a test (`test/shared/dialog_callers_test.dart`,
/// D-202), and so the three screens that sign a resident out say it the same
/// way.
abstract final class AccountCopy {
  // Signing out of this device: My Account, Account home and Security.
  static const String signOutTitle = 'Sign out of this device?';
  static const String signOut =
      'You will need a new one-time code to sign in again. You can still '
      'browse Taytay services, offices and announcements as a guest.';
  static const String signOutAction = 'Sign out';

  // Security: another device, or every other device. Each states the
  // consequence, not just "are you sure": a confirmation that only asks
  // whether somebody meant to tap tests intent, not understanding.
  static String revokeOneTitle(String device) => 'Sign out $device?';
  static const String revokeOne =
      'That device will be signed out of your Taytay LGU IDS account. '
      'Whoever is using it will need a new one-time code sent to your '
      'mobile number to sign in again. This device stays signed in.';
  static const String revokeOneAction = 'Sign out that device';
  static const String revokeOthersTitle = 'Sign out all other devices?';
  static const String revokeOthers =
      'Every other phone, tablet or computer signed in to your Taytay LGU '
      'IDS account will be signed out. This device stays signed in. Anyone '
      'using the others will need a new one-time code sent to your mobile '
      'number.';
  static const String revokeOthersAction = 'Sign out the others';

  // A conversation with an office.
  static const String closeConversationTitle = 'Close this conversation?';
  static const String closeConversation =
      'The office will see it as closed. You can start a new message '
      'afterwards.';
  static const String closeConversationAction = 'Close conversation';

  // Edit profile, when a save did not go through.
  static const String nothingChangedTitle = 'Nothing was changed';
  static const String nothingChanged =
      'Your profile was not updated. You can try again.';
  static const String notConfirmedTitle = 'Not confirmed yet';
  static const String notConfirmed =
      'We could not confirm that your profile was updated. Saving again is '
      'safe: the same change is sent again.';
  static const String nameNotChangedTitle = 'Your name was not changed';

  /// Why a name change was refused ([explanation], the name lock's own
  /// sentence), and what became of the rest of the save.
  static String nameNotChanged(
    String explanation, {
    required bool otherChanges,
  }) => otherChanges
      ? '$explanation Nothing was saved. Save again to keep your other '
            'changes.'
      : '$explanation Nothing was saved.';

  // Settings.
  static const String languageTitle = 'Language';
  static const String language = 'The app follows the language of this phone.';
  static const String passwordUpdatedTitle = 'Password updated';
  static const String passwordUpdated =
      'Use the new password the next time you sign in.';
}
