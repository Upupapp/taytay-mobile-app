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
  String get navServices => 'Directory';

  @override
  String get navNews => 'Balita';

  @override
  String get navTulong => 'Tulong';

  @override
  String get navProfile => 'My Account';

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
      'The app cannot get through right now. Anything you have typed is still here.';

  @override
  String get unsentTitle => 'Not confirmed yet';

  @override
  String unsentMessage(String what) {
    return 'We could not confirm that Taytay LGU has $what. Everything you typed is still on this phone.';
  }

  @override
  String get unsentResendSafe =>
      'Sending it again is safe: it will not be filed twice.';

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
  String get gateSignInMessageOffice =>
      'You need a Taytay LGU account to message offices.';

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
  String get gateVerifyMessageOffice =>
      'Taytay LGU needs to confirm who you are before you can message offices.';

  @override
  String get gateVerifyTrailer => 'Verification is a one-time step.';

  @override
  String get documentSourceCamera => 'Take a photo';

  @override
  String get documentSourceGallery => 'Choose a photo';

  @override
  String get documentSourceFile => 'Choose a file';

  @override
  String get capabilityExplainPending => 'Checking your account…';

  @override
  String get capabilityExplainNeedsSignIn =>
      'Sign in with your mobile number to use this. Browsing stays open to everyone.';

  @override
  String get capabilityExplainNeedsVerification =>
      'Taytay LGU needs to confirm your identity before you can use this.';

  @override
  String get capabilityExplainNotYetAvailable =>
      'Taytay LGU has not switched this on yet. Nothing is wrong with your account, and you can still use everything else in the app.';

  @override
  String get capabilityRequirementSignIn => 'Sign-in required';

  @override
  String get capabilityRequirementVerification => 'Verification required';

  @override
  String get capabilityRequirementNotAvailable => 'Not available yet';

  @override
  String get gateActionSignIn => 'Sign in';

  @override
  String get gateActionVerify => 'Verify my identity';

  @override
  String get gateActionSeeAvailable => 'See what is available';

  @override
  String get gateActionContinue => 'Continue';

  @override
  String get gateBackToHome => 'Back to Home';

  @override
  String get gateSheetNotAvailableTitle => 'Not available yet';

  @override
  String get gateSheetNotAvailablePrivacy =>
      'Nothing has been sent, and nothing is wrong with your account.';

  @override
  String get gateSheetClose => 'Close';

  @override
  String get gateSheetSignInTitle => 'Sign in to continue';

  @override
  String get gateSheetSignInPrivacy =>
      'Browsing stays open to everyone — you can keep reading without an account.';

  @override
  String get gateSheetSignInAction => 'Sign in';

  @override
  String get gateSheetCreateAccount => 'Create an account';

  @override
  String get gateSheetKeepBrowsing => 'Keep browsing';

  @override
  String get gateSheetVerifyTitle => 'Verify your identity';

  @override
  String get gateSheetVerifyPrivacy =>
      'The LGU asks only for what it needs to confirm your identity and residency, and tells you why.';

  @override
  String get gateSheetStartVerification => 'Start verification';

  @override
  String get gateSheetNotNow => 'Not now';

  @override
  String get verifyActionStart => 'Start verification';

  @override
  String get verifyActionContinue => 'Continue verification';

  @override
  String get verifyActionFixResend => 'Fix and resend';

  @override
  String get verifyActionTryAgain => 'Try again';

  @override
  String get homeVerifiedTitle => 'You are verified';

  @override
  String get homeVerifiedBody =>
      'Your Taytay digital ID and service applications are open to you.';

  @override
  String get homeOneStepTitle => 'One step to go';

  @override
  String get homeOneStepBody =>
      'Verify your identity with Taytay LGU to unlock your digital ID and service applications.';

  @override
  String get homeOpenDigitalId => 'Open my digital ID';

  @override
  String get homeCheckStatus => 'Check my status';

  @override
  String get householdFixAddressLabel => 'The address is wrong';

  @override
  String get householdFixAddressBody =>
      'The street address or barangay Taytay LGU has for this household is not correct.';

  @override
  String get householdFixRoleLabel => 'My role in the household is wrong';

  @override
  String get householdFixRoleBody =>
      'Taytay LGU records you differently from how the household actually works.';

  @override
  String get householdFixSizeLabel => 'The number of people is wrong';

  @override
  String get householdFixSizeBody =>
      'Someone is missing from the household record, or someone is listed who no longer lives here.';

  @override
  String get householdFixNotMineLabel => 'This is not my household';

  @override
  String get householdFixNotMineBody =>
      'You have been recorded in a household you do not belong to.';

  @override
  String get householdFixOtherLabel => 'Something else is wrong';

  @override
  String get householdFixOtherBody =>
      'You will be asked about it at the municipal hall.';

  @override
  String get householdRoleHead => 'Household head';

  @override
  String get householdRoleMember => 'Household member';

  @override
  String get reportAbusiveLabel => 'Abusive or threatening';

  @override
  String get reportAbusiveBody => 'Insults, threats, or hateful language.';

  @override
  String get reportHarassmentLabel => 'Targeting someone';

  @override
  String get reportHarassmentBody => 'Aimed at a particular person.';

  @override
  String get reportFalseInfoLabel => 'False information about services';

  @override
  String get reportFalseInfoBody =>
      'Wrong claims about Taytay LGU services or schedules.';

  @override
  String get reportSpamLabel => 'Spam or advertising';

  @override
  String get reportSpamBody => 'Selling something, or posted repeatedly.';

  @override
  String get reportPersonalInfoLabel => 'Someone\'s personal information';

  @override
  String get reportPersonalInfoBody =>
      'A phone number, address, or other private detail posted without consent.';

  @override
  String get notifCatVerification => 'Identity verification';

  @override
  String get notifCatAssistance => 'Assistance updates';

  @override
  String get notifCatMissingRequirement => 'Documents needed';

  @override
  String get notifCatRelease => 'Collecting assistance';

  @override
  String get notifCatReferral => 'Referrals';

  @override
  String get notifCatEventRegistration => 'Event registrations';

  @override
  String get notifCatEventReminder => 'Event reminders';

  @override
  String get notifCatPublicAdvisory => 'Public advisories';

  @override
  String get notifCatAccountSecurity => 'Account and security';

  @override
  String get notifSwitchDocumentRequests => 'Document requests';

  @override
  String get notifSwitchSectorApplications => 'Sector applications';

  @override
  String get notifSwitchOfficeReplies => 'Office replies';

  @override
  String get inboxGroupToday => 'Today';

  @override
  String get inboxGroupThisWeek => 'Earlier this week';

  @override
  String get inboxGroupThisMonth => 'Earlier this month';

  @override
  String get inboxGroupOlder => 'Older';

  @override
  String get inboxGroupUndated => 'No date';

  @override
  String get serviceCategoryDokumento => 'Documents';

  @override
  String get serviceCategoryBuwis => 'Taxes and fees';

  @override
  String get serviceCategoryKalusugan => 'Health';

  @override
  String get serviceCategoryTrabaho => 'Employment';

  @override
  String get serviceCategoryIds => 'Identification';

  @override
  String get serviceCategoryNational => 'National services';

  @override
  String uploadRefusedTooLargeUnknown(int limit) {
    return 'That file is too large. Taytay LGU accepts up to $limit MB. A photo taken in this app is usually small enough.';
  }

  @override
  String get intentResumedLikePost => 'You can now like this post.';

  @override
  String get intentResumedCommentOnPost => 'You can now comment.';

  @override
  String get intentResumedRegisterForEvent =>
      'You can now register for this event.';

  @override
  String get intentResumedSaveService => 'You can now save this service.';

  @override
  String get intentResumedManageNotifications =>
      'You can now manage your notifications.';

  @override
  String get intentResumedApplyForService =>
      'You can now apply for this service.';

  @override
  String get intentResumedViewDigitalId => 'You can now open your digital ID.';

  @override
  String get intentResumedMessageOffice => 'You can now message offices.';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeNext => 'Next';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeContinueAsGuest => 'Continue as guest';

  @override
  String get welcomeGuestNote =>
      'You can browse municipal services without an account.';

  @override
  String welcomeStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get welcomeServicesEyebrow => 'Municipal services in one place';

  @override
  String get welcomeServicesTitle => 'Serbisyong bayan,\nnasa isang app.';

  @override
  String get welcomeServicesBody =>
      'Documents, real property tax, health programmes and job services — browse what Taytay LGU offers and track anything you apply for.';

  @override
  String get welcomeServicesChipDocuments => 'Documents';

  @override
  String get welcomeServicesChipTax => 'Real property tax';

  @override
  String get welcomeServicesChipHealth => 'Health';

  @override
  String get welcomeServicesChipJobs => 'Jobs';

  @override
  String get welcomeServicesTag => 'Taytay Municipal Hall';

  @override
  String get welcomeServicesCredit => 'Photo: Ramon FVelasquez · CC BY-SA 3.0';

  @override
  String get welcomeIdEyebrow => 'Your Taytay ID, on your phone';

  @override
  String get welcomeIdTitle => 'Ang Taytay ID mo,\nnasa phone mo na.';

  @override
  String get welcomeIdBody =>
      'Apply for and carry your Municipality of Taytay digital ID without queueing at the municipal hall.';

  @override
  String get welcomeIdChipDigital => 'Digital ID';

  @override
  String get welcomeIdChipQueue => 'No queueing';

  @override
  String get welcomeIdTag => 'Taytay Tiangge · Garments & Woodcrafts Capital';

  @override
  String get welcomeIdCredit => 'Photo: Ralff Nestor Nacor · CC BY-SA 4.0';

  @override
  String get welcomePrivacyEyebrow => 'You choose what you share';

  @override
  String get welcomePrivacyTitle => 'Ikaw ang pipili\nng ibabahagi.';

  @override
  String get welcomePrivacyBody =>
      'Taytay LGU asks only for what a service needs, and tells you why. Your information is protected under the Data Privacy Act of 2012.';

  @override
  String get welcomePrivacyTag => 'St. John the Baptist Parish Church';

  @override
  String get welcomePrivacyCredit => 'Photo: Urbanroamer · CC BY-SA 3.0';

  @override
  String verificationReviewRange(int min, int max) {
    return '$min–$max working days';
  }

  @override
  String verificationReviewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days working days',
      one: '1 working day',
    );
    return '$_temp0';
  }

  @override
  String verificationReviewSentence(String duration) {
    return 'This usually takes $duration.';
  }

  @override
  String verificationReviewTimelineDetail(String duration) {
    return 'Usually $duration';
  }

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get myRequestsSubtitle => 'Assistance requests filed with the MSWDO';

  @override
  String get myRequestsInPerson =>
      'Some requests are discussed only in person at the MSWDO.';

  @override
  String get myRequestsEmptyTitle => 'No requests to show';

  @override
  String get myRequestsEmptyMessage =>
      'No request filed with the office is shown here.';

  @override
  String get myRequestsLoading => 'Loading your requests';

  @override
  String get myRequestsShowOlder => 'Show older requests';

  @override
  String get myRequestsLoadingMore => 'Loading…';

  @override
  String get myRequestsMoreFailed => 'Could not load more. Try again';

  @override
  String myRequestsFiled(String date) {
    return 'Filed $date';
  }

  @override
  String get myRequestsUnnamedProgramme => 'Assistance request';

  @override
  String get assistanceStageReceived => 'Received';

  @override
  String get assistanceStageBeingAssessed => 'Being assessed';

  @override
  String get assistanceStageApproved => 'Approved';

  @override
  String get assistanceStagePayoutScheduled => 'Payout scheduled';

  @override
  String get assistanceStageReleased => 'Released';

  @override
  String get assistanceStageNeedsMore =>
      'The office needs more from you — please visit or contact the MSWDO';

  @override
  String get assistanceStageNotApproved =>
      'Not approved — the MSWDO can tell you why';

  @override
  String get assistanceStageCancelled => 'Cancelled';

  @override
  String get assistanceStageExpired => 'Expired';

  @override
  String get assistanceStageUpdated => 'Status: updated';

  @override
  String get myRequestDetailTitle => 'Assistance request';

  @override
  String get myRequestReference => 'Reference number';

  @override
  String get myRequestFiledOn => 'Filed on';

  @override
  String get myRequestStatusChangedOn => 'Status last changed';

  @override
  String get myRequestApprovedAmount => 'Approved amount';

  @override
  String get myRequestPayoutDate => 'Payout date';

  @override
  String get myRequestPayoutVenue => 'Where to collect';

  @override
  String get myRequestReleasedOn => 'Released on';

  @override
  String get myRequestLoading => 'Loading the request';

  @override
  String get myRequestNotShownTitle => 'This request is not shown here';

  @override
  String get myRequestNotShownMessage =>
      'It is not among the requests shown for your account.';

  @override
  String get myRequestsSeeAll => 'See all my requests';

  @override
  String get applyCardTitle => 'Apply in the app';

  @override
  String get applyCardBody =>
      'Send your application and documents to the MSWDO from your phone. The office reviews it as it does at the counter.';

  @override
  String get applyCardButton => 'Apply';

  @override
  String get applyTitle => 'Apply for assistance';

  @override
  String applyStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get applyLoading => 'Opening the application';

  @override
  String get applyNotOfferedTitle =>
      'This programme does not take applications in the app';

  @override
  String get applyNotOfferedMessage =>
      'Visit or contact the MSWDO to apply. The programme page says how.';

  @override
  String get applyBackToProgramme => 'Back to the programme';

  @override
  String get applyBack => 'Back';

  @override
  String get applyNext => 'Next';

  @override
  String get applyAboutHeading => 'What this is';

  @override
  String get applyAboutBody =>
      'You are applying to the MSWDO for help under this programme. The office reads your application and documents, as it does at the counter, and decides. Sending it does not mean it is approved.';

  @override
  String get applyWhoHeading => 'Who can apply in the app';

  @override
  String get applyWhoBody =>
      'A resident whose account Taytay LGU has verified, and whom the MSWDO has linked to their record at the office. The MSWDO links your account when it reviews your ID, or at the counter.';

  @override
  String get applyNeedsHeading => 'What the office asks for';

  @override
  String get applyNeedsNone =>
      'The office asks for no documents in the app for this programme.';

  @override
  String get applyInPersonAlso => 'You can also apply in person at the MSWDO.';

  @override
  String get applyStart => 'Start';

  @override
  String get applyNotVerifiedTitle => 'Finish verifying your account first';

  @override
  String get applyNotVerifiedBody =>
      'Only a resident whose identity Taytay LGU has verified can apply in the app. Send your valid ID and selfie in the app, or verify in person at the Municipal Hall.';

  @override
  String get applyGoToVerification => 'Go to verification';

  @override
  String get applyNotLinkedTitle => 'The MSWDO needs to link your account';

  @override
  String get applyNotLinkedBody =>
      'Nothing was sent. Your account is verified, but the MSWDO has not yet linked it to your record at the office. It does this when it reviews your ID, or at the counter: bring a valid ID to the MSWDO and ask them to link your app account. Your answers stay here until you leave this page.';

  @override
  String get applyTryAgain => 'Try sending again';

  @override
  String get applyMessageOffice => 'Message the office';

  @override
  String get applyDetailsHeading => 'Your application';

  @override
  String get applyPurposeLabel => 'What do you need help with?';

  @override
  String get applyPurposeHint =>
      'For example: medicines for my mother after her operation';

  @override
  String get applyPurposeHelp => 'In your own words. The office reads this.';

  @override
  String get applyPurposeEmpty => 'Say what the assistance is for.';

  @override
  String applyPurposeTooShort(int min) {
    return 'Say a little more: at least $min characters.';
  }

  @override
  String applyPurposeTooLong(int max) {
    return 'Keep it to $max characters or fewer.';
  }

  @override
  String get applyAmountLabel => 'Amount you are asking for (optional)';

  @override
  String get applyAmountHint => 'For example: 5,000';

  @override
  String get applyAmountHelp =>
      'In pesos. Leave it blank if you are not sure. The office decides the amount.';

  @override
  String get applyAmountUnreadable =>
      'Write the amount in pesos, like 5000 or 5,000.50.';

  @override
  String get applyAmountZero =>
      'Write an amount above zero, or leave it blank.';

  @override
  String get applyAmountTooLarge =>
      'That amount is too large. Leave it blank if you are not sure.';

  @override
  String get applyServerFlagged =>
      'The office could not accept this. Check what you wrote.';

  @override
  String get applyDocumentsHeading => 'Documents';

  @override
  String applyDocumentsIntro(int limit) {
    return 'One file for each: a photo (JPEG or PNG) or a PDF, up to $limit MB each. Lay paper flat, fill the frame, and make every word readable.';
  }

  @override
  String get applyObligationRequired => 'Required';

  @override
  String get applyObligationOptional => 'Optional';

  @override
  String get applyObligationConditional => 'Only if this applies to you';

  @override
  String get applyConditionUnstated =>
      'The office will tell you if you need this.';

  @override
  String get applyAddFile => 'Add file';

  @override
  String get applyRemoveFile => 'Remove';

  @override
  String get applyFilePhoto => 'Photo';

  @override
  String get applyFilePdf => 'PDF';

  @override
  String applyFileAdded(String kind, String size) {
    return '$kind added · $size';
  }

  @override
  String get applyMissingFile => 'Add this file to continue.';

  @override
  String get applyFileFlagged =>
      'The office could not accept this file. Choose it again, or choose another.';

  @override
  String get applyRequiredMissing =>
      'Add the documents marked Required. If you do not have one, you can still apply in person at the MSWDO.';

  @override
  String applyChooseSource(String name) {
    return 'Add: $name';
  }

  @override
  String get applyNoPicker =>
      'This phone cannot pick a file. You can apply in person at the MSWDO instead.';

  @override
  String get applyReviewHeading => 'Check your application';

  @override
  String get applyReviewProgramme => 'Programme';

  @override
  String get applyReviewPurpose => 'What it is for';

  @override
  String get applyReviewAmount => 'Amount asked for';

  @override
  String get applyReviewNoAmount => 'None given';

  @override
  String get applyReviewDocuments => 'Documents you are sending';

  @override
  String applyReviewFile(String name, String kind, String size) {
    return '$name: $kind, $size';
  }

  @override
  String applyReviewNotSent(String name) {
    return '$name: not sent';
  }

  @override
  String get applyEdit => 'Change';

  @override
  String get applyReviewNote =>
      'The office reads it and may call or message you. You cannot change it after sending. If the office needs more, it returns the request and says what.';

  @override
  String get applySend => 'Send application';

  @override
  String get applySending => 'Sending…';

  @override
  String get applyUnconfirmedTitle => 'Not confirmed yet';

  @override
  String get applyUnconfirmedBody =>
      'We could not confirm that your application was received. Sending it again is safe: it will not be filed twice. You can also check My requests.';

  @override
  String get applyOfflineTitle => 'You are offline';

  @override
  String get applyOfflineBody =>
      'Nothing was sent. Your answers are still here on the phone. Connect to the internet and try again.';

  @override
  String get applyCheckTitle => 'Something needs another look';

  @override
  String get applyCheckBody =>
      'Nothing was sent. The office could not accept part of it. The items marked need checking.';

  @override
  String get applyFileTitle => 'A file could not be accepted';

  @override
  String get applyFileBody =>
      'Nothing was sent. A file was too large or could not be read. Choose a smaller photo or another file, and try again.';

  @override
  String get applyRateTitle => 'Too many tries';

  @override
  String get applyRateBody =>
      'Nothing was sent. Wait a few minutes, then try again.';

  @override
  String get applyClosedBody =>
      'Nothing was sent. The office stopped taking applications for this programme in the app. Visit or contact the MSWDO to apply.';

  @override
  String get applySessionTitle => 'Please sign in again';

  @override
  String get applySessionBody =>
      'Nothing was sent. Your session ended. Sign in, then try again.';

  @override
  String get applyNotAllowedTitle => 'Not available for this account';

  @override
  String get applyNotAllowedBody =>
      'Nothing was sent. Applying in the app is not open to this account. The MSWDO can tell you more.';

  @override
  String get applyServerTitle => 'It did not go through';

  @override
  String get applyServerBody =>
      'Nothing was sent. Something went wrong on our side. Try again in a moment.';

  @override
  String applyFailureReference(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get applyDoneTitle => 'The MSWDO has your application';

  @override
  String get applyDoneMessage =>
      'Keep this control number. The office uses it when you ask about your application.';

  @override
  String get applyDoneControlNumber => 'Control number';

  @override
  String get applyDoneNote =>
      'The office reviews it at intake. Where your requests stand is shown in My requests. Some requests are discussed only in person at the MSWDO.';

  @override
  String get applyOpenMyRequests => 'Open My requests';

  @override
  String get applyBackToTulong => 'Back to Tulong';

  @override
  String get addDocsTitle => 'Add documents';

  @override
  String addDocsIntro(int limit) {
    return 'The office returned this request and needs the documents below. Send a photo (JPEG or PNG) or a PDF of each, up to $limit MB each.';
  }

  @override
  String get addDocsStateNotSent => 'Not sent yet';

  @override
  String get addDocsStateSendAgain => 'Send it again';

  @override
  String get addDocsStateOther => 'Needed';

  @override
  String get addDocsSend => 'Send documents';

  @override
  String get addDocsNothingChosen => 'Add at least one document to send.';

  @override
  String get addDocsDoneTitle => 'Documents sent';

  @override
  String get addDocsDoneMessage =>
      'The office has them. It moves your request on from here.';

  @override
  String get addDocsBackToRequest => 'Back to the request';

  @override
  String get addDocsMovedTitle => 'The request has moved on';

  @override
  String get addDocsMovedBody =>
      'Nothing was sent. The office is no longer waiting for documents on this request. Open it again to see where it stands.';

  @override
  String get addDocsUnconfirmedBody =>
      'We could not confirm that your documents were received. Sending them again is safe: they will not be added twice. You can also open the request to check.';

  @override
  String get addDocsNoneNeeded =>
      'The office is not waiting for documents on this request.';

  @override
  String get myRequestsChannelOnline => 'Applied in the app';

  @override
  String get myRequestsChannelOffice => 'Filed at the office';

  @override
  String get myRequestChannel => 'How it was filed';

  @override
  String get myRequestMissingHeading => 'Documents the office needs';

  @override
  String get myRequestAddDocuments => 'Add documents';

  @override
  String get verifiedLinkNote =>
      'One more step happens at the office: the MSWDO links your account to your record there, usually when it reviews your ID, or at the counter. Once it has, My requests shows your assistance requests and you can apply for Tulong in the app.';

  @override
  String get verifiedApplyStep => 'Apply for Tulong';

  @override
  String get verifiedApplyStepDetail =>
      'From a programme page that offers Apply';

  @override
  String get verifiedRequestsStep => 'Follow your assistance requests';

  @override
  String get verifiedRequestsStepDetail =>
      'In My requests, once the MSWDO has linked your account';
}
