// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppStringsEn extends AppStrings {
  AppStringsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taytay LGU IDS';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navNews => 'News';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionTrySendingAgain => 'Try sending again';

  @override
  String get networkUnreachableTitle => 'Not reaching Taytay LGU';

  @override
  String get networkUnreachableMessage =>
      'The app cannot get through right now. Anything you have typed is still here, and nothing has been sent.';

  @override
  String get unsentTitle => 'Not sent yet';

  @override
  String unsentMessage(String what) {
    return 'Taytay LGU does not have $what. Everything you typed is still on this phone. Nothing was filed, so sending again does not create a duplicate.';
  }

  @override
  String staleContentMessage(String timestamp) {
    return 'Showing what was saved on $timestamp. It may have changed.';
  }

  @override
  String get failureNetwork =>
      'The app could not reach Taytay LGU. Check your connection and try again.';

  @override
  String get failureTimeout =>
      'Taytay LGU took too long to answer. Please try again.';

  @override
  String get failureUnauthenticated =>
      'You have been signed out. Sign in again to continue.';

  @override
  String get failureForbidden => 'This is not available for your account.';

  @override
  String get failureNotFound => 'We could not find what you were looking for.';

  @override
  String get failureValidation => 'Some of what you entered needs changing.';

  @override
  String get failureFileTooLarge =>
      'That file is too large to send. Try a smaller photo, or take it again at a lower quality.';

  @override
  String get failureFileType =>
      'That kind of file cannot be sent. Try a photo or a PDF instead.';

  @override
  String get failureConflict =>
      'That has already been done, or something changed while you were working.';

  @override
  String get failureRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get failureServer =>
      'Something went wrong at Taytay LGU\'s end. This is not your fault.';

  @override
  String get failureContract =>
      'This version of the app could not understand Taytay LGU\'s answer.';

  @override
  String get failureUnexpected => 'Something went wrong. Please try again.';

  @override
  String get a11yLoading => 'Loading';

  @override
  String get a11yBusy => 'Working. Please wait.';

  @override
  String a11ySucceeded(String what) {
    return 'Done. $what';
  }

  @override
  String a11yFailed(String why) {
    return 'That did not work. $why';
  }

  @override
  String get a11yRequired => 'Required';

  @override
  String a11yFieldError(String message) {
    return 'Error: $message';
  }

  @override
  String get updateRequiredTitle => 'Update the app to continue';

  @override
  String get updateRequiredBody =>
      'This version of the Taytay LGU app is no longer supported. Please update it from your app store, then open it again.';

  @override
  String get maintenanceTitle => 'The LGU system is down for maintenance';

  @override
  String get maintenanceBody =>
      'Your account and requests are safe. You can still browse services and programmes while this is going on. Please try again shortly.';

  @override
  String get blockingNoticeSupport => 'If you need help now';

  @override
  String get signInCodeSent =>
      'If that number is registered with Taytay LGU, a code is on its way.';

  @override
  String get signInCodeNotAccepted =>
      'That code did not work. Check the code and try again, or ask for a new one.';

  @override
  String get signInTooManyAttempts =>
      'Too many attempts. Please wait a little while before trying again.';

  @override
  String get signInOffline =>
      'You appear to be offline. Check your internet connection and try again.';

  @override
  String get signInTimedOut => 'That took too long. Please try again.';

  @override
  String get signInServiceUnavailable =>
      'Signing in is temporarily unavailable. Please try again shortly.';

  @override
  String get signInUnexpected =>
      'Something went wrong. Please try again, or visit the Taytay municipal hall if it keeps happening.';

  @override
  String uploadRefusedTooLarge(int actual, int limit) {
    return 'That file is $actual MB. Taytay LGU accepts up to $limit MB. A photo taken in this app is usually small enough.';
  }

  @override
  String get uploadRefusedType =>
      'Taytay LGU can only accept a photo (JPEG or PNG) or a PDF. Take a photo of the document if you have it on paper.';

  @override
  String get uploadRefusedEmpty =>
      'That file is empty. Choose it again, or take a photo of the document instead.';

  @override
  String get uploadRefusedUnreadable =>
      'That file could not be read as a photo or a PDF. Take a photo of the document instead.';

  @override
  String get uploadRefusedTitle => 'That file cannot be sent';

  @override
  String get onboardingOfficeTitle => 'Accounts are made at the MSWDO office';

  @override
  String get onboardingOfficeBody =>
      'Taytay LGU creates your account for you. Visit the Municipal Social Welfare and Development Office with a valid ID, and staff will register the mobile number you want to use. Then sign in here with that number.';

  @override
  String onboardingOfficeContact(String email, String phone) {
    return 'Ask the office: $email · $phone';
  }

  @override
  String get correctionWhichDetail => 'Which detail needs correcting?';

  @override
  String get correctionNotByMessage =>
      'This one cannot be corrected by message — bring the document to the MSWDO office, or upload it again when the office asks.';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldMiddleName => 'Middle name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldSuffix => 'Suffix (Jr., III)';

  @override
  String get fieldBirthDate => 'Date of birth';

  @override
  String get fieldSex => 'Sex';

  @override
  String get fieldCivilStatus => 'Civil status';

  @override
  String get fieldBarangay => 'Barangay';

  @override
  String get fieldStreetAddress => 'House number and street';

  @override
  String get fieldPurokOrSitio => 'Purok or sitio';

  @override
  String get fieldMobileNumber => 'Mobile number';

  @override
  String get fieldEmail => 'Email address';

  @override
  String get sessionEndedTitle => 'Your session ended';

  @override
  String get sessionEndedBody =>
      'For your security, Taytay LGU IDS signed you out on this device. This happens after a period of time, or when the LGU ends a session.';

  @override
  String get sessionEndedUnsent =>
      'Anything you already sent is with the office. Anything you had typed and not yet sent is not kept on this phone — you will need to enter it again.';

  @override
  String get sessionEndedSignInAgain => 'Sign in again';

  @override
  String get signInNoticeExpired =>
      'Your session ended for your security. Please sign in again.';

  @override
  String get signInNoticeSignedOut =>
      'You are signed out on this device. You can still browse Taytay services as a guest.';

  @override
  String get signInNoticeReturnTo =>
      'Sign in to continue to the page you opened. We will take you straight there.';

  @override
  String get profileSectionAccountTitle => 'Your account details';

  @override
  String get profileSectionAccountExplanation =>
      'You can change these yourself. They are how Taytay LGU contacts you.';

  @override
  String get profileSectionLguTitle => 'Confirmed by Taytay LGU';

  @override
  String get profileSectionLguExplanation =>
      'Taytay LGU checked these against your documents. They decide what you are entitled to, so only the LGU can change them.';

  @override
  String get profileFieldMobileNumber => 'Mobile number';

  @override
  String get profileFieldEmailAddress => 'Email address';

  @override
  String get profileFieldStreetAddress => 'Street address';

  @override
  String get profileFieldPurokOrSitio => 'Purok or sitio';

  @override
  String get profileFieldFullName => 'Full name';

  @override
  String get profileFieldBirthDate => 'Date of birth';

  @override
  String get profileFieldSex => 'Sex';

  @override
  String get profileFieldCivilStatus => 'Civil status';

  @override
  String get profileFieldBarangay => 'Barangay';

  @override
  String get profileHintMobileNumber =>
      'How Taytay LGU sends your one-time codes and updates.';

  @override
  String get profileHintEmailAddress =>
      'Optional. Used for copies of what the LGU sends you.';

  @override
  String get profileHintStreetAddress =>
      'Your house number and street, as Taytay LGU has it.';

  @override
  String get profileHintPurokOrSitio =>
      'Optional. The purok or sitio within your barangay, if yours uses one.';

  @override
  String get profileHintFullName => 'As it appears on the ID you presented.';

  @override
  String get profileHintBirthDate =>
      'Decides age-based services such as senior citizen benefits.';

  @override
  String get profileHintBarangay => 'Decides which barangay office serves you.';

  @override
  String profileFieldOptionalSuffix(String label) {
    return '$label (optional)';
  }

  @override
  String get verifyStageNotStartedLabel => 'Not started';

  @override
  String get verifyStageNotStartedBody =>
      'You have not started verifying your identity yet.';

  @override
  String get verifyStageInProgressLabel => 'In progress';

  @override
  String get verifyStageInProgressBody =>
      'You started verifying your identity but have not sent it yet.';

  @override
  String get verifyStagePendingLabel => 'Waiting for review';

  @override
  String get verifyStagePendingBody =>
      'Taytay LGU has your details and is checking them.';

  @override
  String get verifyStageNeedsInfoLabel => 'More information needed';

  @override
  String get verifyStageNeedsInfoBody =>
      'Taytay LGU needs something corrected before it can finish checking.';

  @override
  String get verifyStageVerifiedLabel => 'Verified';

  @override
  String get verifyStageVerifiedBody =>
      'Taytay LGU has confirmed your identity.';

  @override
  String get verifyStageUnsuccessfulLabel => 'Could not be verified';

  @override
  String get verifyStageUnsuccessfulBody =>
      'Taytay LGU could not confirm your identity from what was sent.';

  @override
  String get verifyStageManualReviewLabel => 'Needs a person to check';

  @override
  String get verifyStageManualReviewBody =>
      'This needs Taytay LGU staff to check it in person.';

  @override
  String get kycDocIdentityLabel => 'Government-issued ID';

  @override
  String get kycDocIdentityBody =>
      'A PhilID, passport, driver\'s licence, postal ID or voter\'s ID.';

  @override
  String get kycDocAddressLabel => 'Proof of address';

  @override
  String get kycDocAddressBody =>
      'A utility bill or barangay certificate showing where you live.';

  @override
  String get kycDocSent => 'Sent to Taytay LGU.';

  @override
  String get kycDocSentChecking => 'Sent. Still being checked.';

  @override
  String get validateConfirmDetails =>
      'Confirm these are your details before you continue, so the office files this against the right record.';

  @override
  String get validateNarrativeMissing =>
      'Describe what you need help with, in your own words.';

  @override
  String validateNarrativeTooLong(int limit) {
    return 'Shorten this to $limit characters or fewer. The office can ask you for more detail later.';
  }

  @override
  String validateConsentRequired(String subject) {
    return 'You need to accept \"$subject\" to continue.';
  }

  @override
  String validateAnswerMissingChoice(String subject) {
    return 'Choose an answer for \"$subject\".';
  }

  @override
  String validateAnswerMissingYesNo(String subject) {
    return 'Answer yes or no to \"$subject\".';
  }

  @override
  String validateAnswerMissingDate(String subject) {
    return 'Enter a date for \"$subject\".';
  }

  @override
  String validateAnswerMissingNumber(String subject) {
    return 'Enter a number for \"$subject\".';
  }

  @override
  String validateAnswerMissingGeneric(String subject) {
    return 'Answer \"$subject\".';
  }

  @override
  String validateAnswerNotANumber(String subject) {
    return 'Enter \"$subject\" as a number, with digits only.';
  }

  @override
  String validateAnswerTooLong(int limit) {
    return 'Shorten this to $limit characters or fewer.';
  }

  @override
  String validateConsentRequiredToRegister(String subject) {
    return 'You need to accept \"$subject\" to register.';
  }

  @override
  String get capabilityBrowseServices => 'Browse municipal services';

  @override
  String get capabilityReadNews => 'Read Taytay announcements';

  @override
  String get capabilityBrowseEvents => 'See LGU events';

  @override
  String get capabilityManageAccount => 'Manage your account';

  @override
  String get capabilityManageSecurity => 'Manage sign-in and security';

  @override
  String get capabilityReadNotifications => 'See your notifications';

  @override
  String get capabilityBrowsePrograms => 'See assistance programmes';

  @override
  String get capabilityCompleteVerification => 'Verify your identity';

  @override
  String get capabilityHoldDigitalId => 'Hold your Taytay digital ID';

  @override
  String get capabilityTrackAssistanceRequests =>
      'Track your assistance requests';

  @override
  String get capabilityApplyForAssistance => 'Apply for a municipal service';

  @override
  String get capabilitySubmitRequirements =>
      'Send the documents Taytay LGU asked for';

  @override
  String get capabilityViewHouseholdSummary => 'See your household summary';

  @override
  String get gateSignInLikePost =>
      'You need a Taytay LGU account to like this post.';

  @override
  String get gateSignInCommentOnPost =>
      'You need a Taytay LGU account to comment.';

  @override
  String get gateSignInRegisterForEvent =>
      'You need a Taytay LGU account to register for this event.';

  @override
  String get gateSignInSaveService =>
      'You need a Taytay LGU account to save this service.';

  @override
  String get gateSignInManageNotifications =>
      'You need a Taytay LGU account to manage your notifications.';

  @override
  String get gateSignInApplyForService =>
      'You need a Taytay LGU account to apply for this service.';

  @override
  String get gateSignInViewDigitalId =>
      'You need a Taytay LGU account to open your digital ID.';

  @override
  String get gateSignInTrailer =>
      'Signing in also lets you track anything you apply for.';

  @override
  String get gateVerifyLikePost =>
      'Taytay LGU needs to confirm who you are before you can like this post.';

  @override
  String get gateVerifyCommentOnPost =>
      'Taytay LGU needs to confirm who you are before you can comment.';

  @override
  String get gateVerifyRegisterForEvent =>
      'Taytay LGU needs to confirm who you are before you can register for this event.';

  @override
  String get gateVerifySaveService =>
      'Taytay LGU needs to confirm who you are before you can save this service.';

  @override
  String get gateVerifyManageNotifications =>
      'Taytay LGU needs to confirm who you are before you can manage your notifications.';

  @override
  String get gateVerifyApplyForService =>
      'Taytay LGU needs to confirm who you are before you can apply for this service.';

  @override
  String get gateVerifyViewDigitalId =>
      'Taytay LGU needs to confirm who you are before you can open your digital ID.';

  @override
  String get gateVerifyTrailer => 'Verification is a one-time step.';

  @override
  String get documentSourceCamera => 'Take a photo';

  @override
  String get documentSourceGallery => 'Choose a photo';

  @override
  String get documentSourceFile => 'Choose a file';
}
