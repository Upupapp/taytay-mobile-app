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
  String get failureNotFound => 'We could not find what you were looking for.';

  @override
  String get failureFileType =>
      'That kind of file cannot be sent. Try a photo or a PDF instead.';

  @override
  String get failureRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

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
  String get notifSwitchRegistryRecord =>
      'Changes to your record at the office';

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
  String get assistanceStageDocumentsSent =>
      'Sent — waiting for the office to review what you sent';

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
  String get applyUnlinkedBody =>
      'Your account is verified, but the MSWDO has not yet linked it to your record at the office, so an application from the app cannot be sent yet. It does this when it reviews your ID, or at the counter: bring a valid ID to the MSWDO and ask them to link your app account. Once it has, come back to this page to apply.';

  @override
  String get accountLinkedNote =>
      'Your account is linked to your MSWDO record.';

  @override
  String get accountNotLinkedNote =>
      'Your account is not yet linked to your MSWDO record. The MSWDO links it when it reviews your ID, or at the counter.';

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
      'The MSWDO will review what you sent. Until then, your request shows that it is waiting for the office.';

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
  String get myRequestsChannelImported => 'From the office\'s records';

  @override
  String myRequestControlNumber(String number) {
    return 'Control no. $number';
  }

  @override
  String get myRequestSystemReference => 'System reference';

  @override
  String get myRequestChannel => 'How it was filed';

  @override
  String get myRequestMissingHeading => 'Documents the office needs';

  @override
  String get myRequestAddDocuments => 'Add documents';

  @override
  String get myRequestApplicantNoteFrom => 'From the MSWDO:';

  @override
  String get myRequestDocumentsSentOn => 'Documents sent on';

  @override
  String get verifiedLinkNote =>
      'One more step happens at the office: the MSWDO links your account to your record there, usually when it reviews your ID, or at the counter. Once it has, My requests shows your assistance requests and you can apply for Tulong in the app.';

  @override
  String get verifiedLinkedNote =>
      'Your account is linked to your MSWDO record. My requests shows your assistance requests, and you can apply for Tulong in the app.';

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

  @override
  String addDocsDoneStillNeeded(String documents) {
    return 'The office still needs: $documents. Send them from the request when you have them.';
  }

  @override
  String addDocsDoneFile(String kind, String size) {
    return '$kind, $size';
  }

  @override
  String get addDocsDoneSentOn => 'Sent on';

  @override
  String get addDocsDoneNote =>
      'Open the request any time to see where it stands. If the office needs anything more, the request will say so.';

  @override
  String get accountSectorsSubtitle =>
      'Who it can help: senior citizens, PWDs and solo parents';

  @override
  String get authHelpTitle => 'Forgot your password?';

  @override
  String get authHelpSubtitle => 'Sign-in help';

  @override
  String get authHelpIntro =>
      'Reset it from the sign-in screen. We send a code to the email or mobile number on the account, and we never say whether that account exists.';

  @override
  String get authHelpNoCodeTitle => 'The code did not arrive';

  @override
  String get authHelpNoCodeBody =>
      'Check that you typed the number correctly, and that your phone has signal. Messages can take a few minutes. You can ask for a new code from the sign-in screen.';

  @override
  String get authHelpCodeFailedTitle => 'The code did not work';

  @override
  String get authHelpCodeFailedBody =>
      'Codes are short-lived and single-use. Ask for a new one and enter it as soon as it arrives.';

  @override
  String get authHelpTooManyTitle => 'It says too many attempts';

  @override
  String get authHelpTooManyBody =>
      'Taytay LGU limits sign-in attempts to protect your account. Wait a little while, then try again. Nothing is wrong with your account.';

  @override
  String get authHelpLostNumberTitle => 'You no longer have that number';

  @override
  String get authHelpLostNumberBody =>
      'Changing the number on an account is an identity decision, so Taytay LGU makes it in person. Visit the municipal hall with a valid ID and ask to update your registered mobile number. You do not need this app or your old phone to do it.';

  @override
  String get authHelpMisuseTitle => 'Someone else may have used your account';

  @override
  String get authHelpMisuseBody =>
      'Sign in and sign out of this device from Sign-in and security. If you cannot sign in, report it at the municipal hall — staff there can act on your account directly.';

  @override
  String get authHelpNeverAskHeading => 'What we will never ask you';

  @override
  String get authHelpNeverAskBody =>
      'Taytay LGU staff will never ask for your one-time code, by phone, text or message. If somebody asks you for it, they are not from the LGU. Do not share it.';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authLockTitle => 'Taytay LGU IDS is locked';

  @override
  String get authLockUnlock => 'Unlock';

  @override
  String get authLockSignOutInstead => 'Sign out instead';

  @override
  String get authLockExplainIdle =>
      'You turned on the app lock, so Taytay LGU IDS asks for your fingerprint, face or screen lock before showing your details again.';

  @override
  String get authLockExplainUnlocking => 'Unlocking…';

  @override
  String get authLockExplainCancelled => 'Unlock to see your details again.';

  @override
  String get authLockExplainFailed =>
      'That did not match. Try again, or sign out and sign back in.';

  @override
  String get authLockExplainUnavailable =>
      'Your device could not show the unlock prompt. You can sign out and sign back in instead — nothing is wrong with your account.';

  @override
  String get authSignInTitle => 'Maligayang pagbabalik!';

  @override
  String get authSignInSubtitle => 'Sign in to your Taytay resident account.';

  @override
  String get authSignInNewHere => 'Bago rito?';

  @override
  String get authSignInIncorrectTitle => 'Incorrect email or password. ';

  @override
  String authSignInAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts left before a 15-minute pause.',
      one: '1 attempt left before a 15-minute pause.',
    );
    return '$_temp0';
  }

  @override
  String get authIdentifierLabel => 'Email or mobile number';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInIncorrectPassword => 'Incorrect password';

  @override
  String get authPasswordShow => 'Show';

  @override
  String get authPasswordHide => 'Hide';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authEnterPassword => 'Enter your password.';

  @override
  String get authIdentifierEmpty => 'Enter your email or mobile number.';

  @override
  String get authIdentifierShape =>
      'Enter an email address or an 11-digit mobile number.';

  @override
  String get authResetTitle => 'Reset your password';

  @override
  String get authResetSubtitle =>
      'Enter the email or mobile number on your account. We\'ll send a 6-digit code to reset your password.';

  @override
  String get authResetSendCode => 'Send reset code';

  @override
  String get authResetNoEnumeration =>
      'For your security, we don\'t say whether an account exists for this address.';

  @override
  String get authResetSent => 'If an account matches, a code is on its way.';

  @override
  String get authYourEmail => 'your email';

  @override
  String get authResetCodeTitle => 'Ilagay ang 6-digit na code';

  @override
  String authResetCodeSubtitle(String email) {
    return 'Nagpadala kami ng code sa $email.';
  }

  @override
  String get authResetSendNewCode => 'Magpadala ng bagong code';

  @override
  String get authResetVerifyCode => 'I-verify ang code';

  @override
  String get authResetCodeRules =>
      'Valid ang code nang 10 minuto. May 5 subok ka bawat code.';

  @override
  String get authResetBackToSignIn => 'Bumalik sa sign in';

  @override
  String get authResetWrongTitle => 'Mali ang code. ';

  @override
  String authResetAttemptsLeft(int remaining, int total) {
    return '$remaining sa $total subok na lang ang natitira.';
  }

  @override
  String authResetAttemptsPerCode(int total) {
    return 'May $total subok ka bawat code.';
  }

  @override
  String get authResetExpiredTitle => 'Nag-expire na ang code. ';

  @override
  String authResetExpiredBody(int count) {
    return 'Magpadala ng bago. May $count subok ka ulit.';
  }

  @override
  String get authResetUnavailableTitle => 'Subukang muli. ';

  @override
  String get authCodeServiceUnavailable =>
      'Hindi available ang serbisyo ngayon. Subukang muli.';

  @override
  String authResetExpiresIn(String time) {
    return 'Mag-e-expire sa $time';
  }

  @override
  String get authResetResend => 'Ipadala muli';

  @override
  String authResetResendIn(String time) {
    return 'Ipadala muli sa $time';
  }

  @override
  String get authResetMismatch => 'Hindi tugma ang password. Pakiulit.';

  @override
  String get authResetNewPasswordTitle => 'Gumawa ng bagong password';

  @override
  String authResetNewPasswordSubtitle(String email) {
    return 'Para sa $email. Gamitin ito sa susunod mong pag-sign in.';
  }

  @override
  String get authRequestNewCode => 'Humingi ng bagong code';

  @override
  String get authResetSavePassword => 'I-save ang password';

  @override
  String get authResetNotChangedTitle => 'Hindi pa napalitan ang password. ';

  @override
  String get authResetLinkExpiredTitle => 'Nag-expire na ang reset link mo. ';

  @override
  String get authResetLinkExpiredBody =>
      'Valid lang ito nang 15 minuto. Humingi ng bagong code para makapagpatuloy.';

  @override
  String get authResetNewPasswordLabel => 'Bagong password *';

  @override
  String get authResetConfirmLabel => 'Ulitin ang bagong password *';

  @override
  String get authResetMatched => 'Tugma ang password';

  @override
  String get authResetShowPassword => 'Ipakita';

  @override
  String get authResetHidePassword => 'Itago';

  @override
  String get authResetRuleLength => 'Hindi bababa sa 8 character';

  @override
  String get authResetRuleDigit => 'May numero';

  @override
  String get authResetRuleLetter => 'May letra';

  @override
  String authPasswordRuleMet(String rule) {
    return '$rule, met';
  }

  @override
  String authPasswordRuleNotMet(String rule) {
    return '$rule, not met';
  }

  @override
  String get authResetFailOffline =>
      'Walang koneksyon. Ikonekta ang telepono at subukang muli.';

  @override
  String get authResetFailRateLimited =>
      'Masyadong maraming subok. Maghintay nang ilang minuto bago subukang muli.';

  @override
  String get authResetFailLinkUsed =>
      'Hindi na magagamit ang reset link na ito. Humingi ng bagong code.';

  @override
  String get authResetFailWeak =>
      'Kailangan ng password na may 8 o higit pang titik, may letra at numero.';

  @override
  String get authResetFailOther =>
      'Hindi ito natapos ngayon. Subukang muli mamaya.';

  @override
  String get authResetDoneTitle => 'Na-update na ang password mo';

  @override
  String get authResetDoneBody =>
      'Gamitin ang bagong password sa susunod mong pag-sign in sa Taytay LGUIDS.';

  @override
  String get authResetDoneSecurityTitle => 'Para sa iyong seguridad. ';

  @override
  String get authResetDoneSecurityBody =>
      'Kung hindi ikaw ang nagpalit ng password, tumawag sa Municipal Hall o pumunta sa MSWDO.';

  @override
  String get authResetDoneSignIn => 'Mag-sign in';

  @override
  String get authHoldLeadReady =>
      'Puwede ka nang humingi ng bagong code. Ipapadala namin ito sa ';

  @override
  String get authHoldLeadLocked =>
      'Para protektahan ang account mo, pansamantala naming itinigil ang pagpapadala at pag-verify ng code para sa ';

  @override
  String get authHoldTitleReady => 'Subukan ulit ngayon';

  @override
  String get authHoldTitleLocked => 'Masyadong maraming subok';

  @override
  String get authHoldSubtitleReady => 'Puwede na ulit';

  @override
  String get authHoldSubtitleLocked => 'Pansamantalang naka-lock';

  @override
  String get authHoldWhyHeading => 'Bakit ito nangyari?';

  @override
  String get authHoldWhyBody =>
      'Masyadong maraming maling code o hiling ng bagong code sa maikling oras. Hindi mo kailangang gumawa ng bagong account.';

  @override
  String get authHoldSpokenReady => 'Tapos na ang paghihintay. 00:00';

  @override
  String authHoldSpokenWaiting(String time) {
    return 'Subukang muli sa $time';
  }

  @override
  String get authHoldClockReady => 'Tapos na ang paghihintay';

  @override
  String get authHoldClockWaiting => 'Subukang muli sa';

  @override
  String get authMobileShape =>
      'Enter an 11-digit mobile number starting with 09.';

  @override
  String get authWizardFinishForNow => 'Finish for now';

  @override
  String get authWizardInPersonOfferHeading => 'Rather verify in person?';

  @override
  String get authWizardInPersonOffer =>
      'You do not have to upload anything. Bring a valid ID to the MSWDO and staff verify your account there. No selfie is taken.';

  @override
  String get authWizardInPersonOfferAction => 'Verify in person instead';

  @override
  String get authWizardInPersonChosenHeading => 'You chose to verify in person';

  @override
  String get authWizardInPersonChosen =>
      'Nothing about your ID is sent from the app. Your account is kept and works without it until staff verify you at the office.';

  @override
  String get authWizardInPersonUndo => 'Send my ID in the app instead';

  @override
  String get authWizardInPersonStepTitle => 'Verify in person';

  @override
  String get authWizardInPersonStepSubtitle =>
      'Your account is ready. Staff verify it at the MSWDO counter.';

  @override
  String get authWizardChooseBarangay => 'Choose your barangay.';

  @override
  String get authWizardEmailInvalid =>
      'Enter a valid email, e.g. name@example.com';

  @override
  String get authWizardPasswordShort => 'Use at least 8 characters.';

  @override
  String get authWizardPasswordWeak =>
      'Use at least 8 characters, with a letter and a number.';

  @override
  String get authWizardEnterCode => 'Enter the 6-digit code.';

  @override
  String get authWizardServiceUnavailable =>
      'The service is not available right now. Try again.';

  @override
  String authWizardWrongCode(int remaining, int total) {
    return 'Wrong code. $remaining of $total tries left.';
  }

  @override
  String get authWizardTermsBoth =>
      'Agree to the Terms of Use and acknowledge the Privacy Notice: tick each one.';

  @override
  String get authWizardTermsOnly => 'Agree to the Terms of Use to continue.';

  @override
  String get authWizardPrivacyOnly =>
      'Acknowledge the Privacy Notice to continue.';

  @override
  String get authWizardConsentUnknown =>
      'We could not confirm that your consent was recorded. Agreeing again is safe: it is recorded only once.';

  @override
  String authWizardConsentNotRecorded(String reason) {
    return 'Your consent was not recorded. $reason';
  }

  @override
  String get authWizardAddIdFront => 'Add a photo of the front of your ID.';

  @override
  String get authWizardTakeSelfieFirst => 'Take a selfie to continue.';

  @override
  String get authWizardEmailTaken => 'This email already has a Taytay account.';

  @override
  String get authWizardEmailExists =>
      'An account with this email already exists. Sign in instead, or use another email.';

  @override
  String authWizardCodeNotSent(String email, String next) {
    return 'Your account is saved, but we could not send a code to $email. $next';
  }

  @override
  String get authWizardCodeNotSentOffline =>
      'Check your connection, then press Continue to try again.';

  @override
  String get authWizardCodeNotSentLater =>
      'Press Continue to try again in a moment.';

  @override
  String get authWizardDetailsUnknown =>
      'We could not confirm that your details were saved. Press Continue to send them again: it is safe to repeat.';

  @override
  String get authWizardDetailsNotSaved => 'Your details were not saved.';

  @override
  String get authWizardDetailsCheckHighlighted =>
      'Please check the highlighted details.';

  @override
  String get authWizardDetailsEmailConflict =>
      'This email is already on another Taytay account. Please ask the municipal hall for help.';

  @override
  String get authWizardSummaryIsDraft => 'The summary on this step is a draft.';

  @override
  String get authWizardProgressLabel => 'Create account progress';

  @override
  String get authWizardPersonalTitle => 'Tungkol sa iyo';

  @override
  String get authWizardPersonalSubtitle =>
      'Basic details only. You can complete your Resident Profile once your account is verified.';

  @override
  String get authWizardAccountCreatedTitle => 'Account created';

  @override
  String get authWizardAccountCreatedSubtitle =>
      'You sign in with this email. Next we send a 6-digit code to it.';

  @override
  String get authWizardAccountTitle => 'Create your account';

  @override
  String get authWizardAccountSubtitle =>
      'You sign in with this email and password. Next we send a 6-digit code to the email.';

  @override
  String get authWizardCodeExpiredTitle => 'Nag-expire na ang code';

  @override
  String authWizardCodeExpiredSubtitle(String address) {
    return 'The code is valid for 10 minutes only. Send a new one to $address.';
  }

  @override
  String get authWizardCodeTitle => 'Enter the 6-digit code';

  @override
  String authWizardCodeSubtitle(String address) {
    return 'We sent a code to $address. It expires in 10 minutes.';
  }

  @override
  String get authWizardTermsTitle => 'Your data, protected';

  @override
  String get authWizardTermsSubtitle => 'Terms and Privacy';

  @override
  String get authWizardIdTitle => 'Upload a valid government ID';

  @override
  String get authWizardIdSubtitle =>
      'The LGU uses it to confirm who you are. Make sure all four corners and your name are clear.';

  @override
  String get authWizardSelfieTitle => 'Take a quick selfie';

  @override
  String get authWizardSelfieSubtitle =>
      'LGU staff compare it with your ID. It is not used as your profile photo.';

  @override
  String get authWizardReviewTitle => 'Check your details';

  @override
  String get authWizardSendNewCode => 'Send a new code';

  @override
  String get authWizardChangeEmail => 'Change email address';

  @override
  String get authWizardConfirmEmail => 'Confirm email';

  @override
  String get authWizardSubmit => 'Submit for verification';

  @override
  String get authWizardCreateAccount => 'Create my account';

  @override
  String authWizardFixFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Please fix $count fields to continue.',
      one: 'Please fix 1 field to continue.',
    );
    return '$_temp0';
  }

  @override
  String get authWizardChoose => 'Choose';

  @override
  String get authWizardStreetLabel => 'Street / Purok';

  @override
  String authWizardAddressHint(String street, String barangay) {
    return 'Address: $street, Brgy. $barangay, Taytay, Rizal';
  }

  @override
  String get authWizardRuleLength => '8+ characters';

  @override
  String get authWizardResendCode => 'Resend code';

  @override
  String authWizardResendIn(String time) {
    return 'Resend in $time';
  }

  @override
  String get authWizardDidntGetIt => 'Didn\'t get it?';

  @override
  String get authWizardCheckSpam => 'Check your spam folder too.';

  @override
  String get authWizardOldCodeTitle => 'The old code can no longer be used. ';

  @override
  String get authWizardNewCodeTries =>
      'With a new code, you get 5 tries again.';

  @override
  String get authWizardCanResendNow =>
      'You can send a new one now · Check your spam folder too';

  @override
  String get authWizardCheckingConsent => 'Checking the selfie consent';

  @override
  String get authWizardIdFront => 'Front of ID';

  @override
  String get authWizardIdBack => 'Back of ID (optional)';

  @override
  String get authWizardAddPhoto => 'Add a photo · JPG or PNG';

  @override
  String get authWizardAttached => 'Attached';

  @override
  String get authWizardSelfieTipLight => 'Good light, facing the camera';

  @override
  String get authWizardSelfieTipFace =>
      'Whole face visible: no sunglasses, mask or cap';

  @override
  String get authWizardSelfieTipAlone => 'Only you in the photo';

  @override
  String get authWizardTakeSelfie => 'Take selfie';

  @override
  String get authWizardIdSidesBoth => 'front and back';

  @override
  String get authWizardIdSidesFront => 'front';

  @override
  String authWizardIdCaptured(String sides) {
    return 'Captured: $sides';
  }

  @override
  String get authWizardNotAdded => 'Not added';

  @override
  String get authWizardRowName => 'Name';

  @override
  String get authWizardRowEmail => 'Email';

  @override
  String get authWizardRowMobile => 'Mobile';

  @override
  String get authWizardRowAddress => 'Address';

  @override
  String get authWizardRowTerms => 'Terms & Privacy Notice';

  @override
  String get authWizardTermsAgreed => 'Agreed · consent given';

  @override
  String get authWizardTermsNotAgreed => 'Not yet agreed';

  @override
  String get authWizardRowId => 'Valid ID';

  @override
  String get authWizardRowSelfie => 'Selfie';

  @override
  String get authWizardSelfieTaken => 'Taken';

  @override
  String get authWizardSelfieNotTaken => 'Not taken';

  @override
  String get authWizardEdit => 'Edit';

  @override
  String get authWizardDoneTitle => 'You\'re all set!';

  @override
  String authWizardDoneTitleNamed(String name) {
    return 'You\'re all set, $name!';
  }

  @override
  String get authWizardDoneMessage =>
      'Your account is created and your details were sent to Taytay LGU for verification.';

  @override
  String get authWizardDoneVerification => 'Account verification';

  @override
  String get authWizardPendingReview => 'Pending review';

  @override
  String get authWizardDoneBody =>
      'Taytay LGU staff check your ID and selfie at the municipal office, in the office\'s own system. You\'ll get a notification in this app when they decide. Meanwhile you can browse services and news.';

  @override
  String get authWizardContinueToApp => 'Continue to app';

  @override
  String authWizardPickerRequired(String label) {
    return '$label, required';
  }

  @override
  String get authWizardNotChosen => 'Not chosen';

  @override
  String get authWizardNameOnAccount => 'Name on your account';

  @override
  String get authWizardNoticeDraftPill =>
      'DRAFT · Not yet published by Taytay LGU';

  @override
  String get authWizardNoticeLoading => 'Loading the Privacy Notice';

  @override
  String get authWizardNoticeFailedHeading =>
      'Could not load the Privacy Notice';

  @override
  String get authWizardNoticeFailedBody =>
      'Check your connection and try again. Read it before you acknowledge it below.';

  @override
  String authWizardNoticeVersion(String version) {
    return 'Version $version';
  }

  @override
  String authWizardNoticeUpdated(String version, String date) {
    return '$version · Updated $date';
  }

  @override
  String get authWizardDraftIntro =>
      'The Municipality of Taytay collects your name, contact details, address, valid ID and selfie to create and verify your resident account and to deliver municipal services you request.';

  @override
  String get authWizardDraftUseTitle => 'How we use it';

  @override
  String get authWizardDraftUseBody =>
      'Identity and residency verification, service requests, and notices from the LGU.';

  @override
  String get authWizardDraftWhoTitle => 'Who can see it';

  @override
  String get authWizardDraftWhoBody => 'Authorised Taytay LGU personnel only.';

  @override
  String get authWizardDraftRightsTitle => 'Your rights';

  @override
  String get authWizardDraftRightsBody =>
      'To be informed, to access, correct, object and erase, and to file a complaint with the National Privacy Commission. Contact the LGU Data Protection Officer for requests.';

  @override
  String get authWizardFullDocuments => 'Full documents';

  @override
  String get authWizardReadTerms => 'Read full Terms';

  @override
  String get authWizardReadPrivacy => 'Read full Privacy Notice';

  @override
  String get authWizardSelfieGuideTaken =>
      'Selfie guide, selfie taken. Illustration, no real person.';

  @override
  String get authWizardSelfieGuide =>
      'Selfie guide. Illustration, no real person.';

  @override
  String get authWizardIllustration => 'Illustration · no real person';

  @override
  String get acctSignOutTitle => 'Sign out of this device?';

  @override
  String get acctSignOutBody =>
      'You will need a new one-time code to sign in again. You can still browse Taytay services, offices and announcements as a guest.';

  @override
  String acctRevokeOneTitle(String device) {
    return 'Sign out $device?';
  }

  @override
  String get acctRevokeOneBody =>
      'That device will be signed out of your Taytay LGU IDS account. Whoever is using it will need a new one-time code sent to your mobile number to sign in again. This device stays signed in.';

  @override
  String get acctRevokeOneAction => 'Sign out that device';

  @override
  String get acctRevokeOthersTitle => 'Sign out all other devices?';

  @override
  String get acctRevokeOthersBody =>
      'Every other phone, tablet or computer signed in to your Taytay LGU IDS account will be signed out. This device stays signed in. Anyone using the others will need a new one-time code sent to your mobile number.';

  @override
  String get acctRevokeOthersAction => 'Sign out the others';

  @override
  String get acctCloseConversationTitle => 'Close this conversation?';

  @override
  String get acctCloseConversationBody =>
      'The office will see it as closed. You can start a new message afterwards.';

  @override
  String get acctCloseConversationAction => 'Close conversation';

  @override
  String get acctNothingChangedTitle => 'Nothing was changed';

  @override
  String get acctNothingChangedBody =>
      'Your profile was not updated. You can try again.';

  @override
  String get acctNotConfirmedTitle => 'Not confirmed yet';

  @override
  String get acctNotConfirmedBody =>
      'We could not confirm that your profile was updated. Saving again is safe: the same change is sent again.';

  @override
  String get acctNameNotChangedTitle => 'Your name was not changed';

  @override
  String acctRefusedNothingSaved(String reason) {
    return '$reason Nothing was saved.';
  }

  @override
  String acctRefusedNothingSavedKeepOthers(String reason) {
    return '$reason Nothing was saved. Save again to keep your other changes.';
  }

  @override
  String get acctLanguageTitle => 'Language';

  @override
  String get acctLanguageBody => 'The app follows the language of this phone.';

  @override
  String get acctPasswordUpdatedTitle => 'Password updated';

  @override
  String get acctPasswordUpdatedBody =>
      'Use the new password the next time you sign in.';

  @override
  String get acctNotifications => 'Notifications';

  @override
  String get acctLoadingAccount => 'Loading your account';

  @override
  String get acctMyTaytayId => 'My Taytay ID';

  @override
  String get acctMore => 'More';

  @override
  String acctUnreadCount(int count) {
    return '$count new';
  }

  @override
  String get acctSampleMessages => 'messages for illustration';

  @override
  String get acctSampleConversation => 'conversation for illustration';

  @override
  String get acctRetry => 'Retry';

  @override
  String get acctInboxEmptyTitle => 'No messages yet';

  @override
  String get acctInboxEmptyBody =>
      'Questions you send to municipal offices and their replies will appear here.';

  @override
  String get acctMessageAnOffice => 'Message an office';

  @override
  String get acctMessagingVerifiedOnly =>
      'Messaging is available to verified residents.';

  @override
  String get acctInboxErrorTitle => 'Messages did not load';

  @override
  String get acctInboxErrorBody =>
      'Taytay LGU could not be reached. You can try again.';

  @override
  String get acctSaveChanges => 'Save changes';

  @override
  String get acctLoadingProfile => 'Loading your profile';

  @override
  String get acctProfilePhoto => 'Profile photo';

  @override
  String get acctProfilePhotoNote =>
      'Profile photo · reviewed by LGU before it appears on your ID';

  @override
  String get acctCannotChangeHere => 'Cannot be changed here';

  @override
  String get acctLegalNameNote =>
      'Legal name changes go through Resident Profile and re-verification.';

  @override
  String get acctNotificationSettings => 'Notification settings';

  @override
  String get acctNotificationSettingsDetail =>
      'What Taytay LGU tells you about';

  @override
  String get acctSectionApp => 'App';

  @override
  String get acctLanguageOptions => 'English · Filipino';

  @override
  String get acctChangePassword => 'Change password';

  @override
  String get acctSectionPrivacy => 'Privacy';

  @override
  String get acctPrivacyNotice => 'Privacy Notice';

  @override
  String get acctPrivacyNoticeDetail =>
      'Data Privacy Act of 2012 · LGU-approved text pending';

  @override
  String get acctYourConsents => 'Your consents';

  @override
  String get acctYourConsentsDetail => 'Review or withdraw what you agreed to';

  @override
  String get acctRequestDataCopy => 'Request a copy of my data';

  @override
  String get acctRightToAccess => 'Right to access';

  @override
  String get acctSealLabel => 'Seal of Taytay, Rizal';

  @override
  String acctAboutVersion(String version) {
    return 'Municipality of Taytay, Rizal · version $version';
  }

  @override
  String get acctPhotoCredits => 'Photo credits';

  @override
  String get acctOfficeBannerPhotos => 'Office banner photos';

  @override
  String acctBannerSummary(int count) {
    return '$count photos · Wikimedia Commons';
  }

  @override
  String get acctSectionAbout => 'About';

  @override
  String get acctMunicipalSeal => 'Municipal seal';

  @override
  String get acctMunicipalSealDetail =>
      'Described on taytayrizal.gov.ph/seal · Wikimedia';

  @override
  String get acctLoadingPrivacyNotice => 'Loading the privacy notice';

  @override
  String get acctDraftPill => 'DRAFT · LGU-approved text to be inserted';

  @override
  String get acctNoticeCollectTitle => 'What we collect';

  @override
  String get acctNoticeCollectBody =>
      'Name, contact details, address, valid ID and selfie, and messages you send to offices.';

  @override
  String get acctNoticeWhyTitle => 'Why';

  @override
  String get acctNoticeWhyBody =>
      'To verify that you are a Taytay resident and to deliver the services you request.';

  @override
  String get acctNoticeWhoTitle => 'Who can see it';

  @override
  String get acctNoticeWhoBody =>
      'Authorised LGU staff of the office you deal with. Not sold or shared for marketing.';

  @override
  String get acctNoticeRightsTitle => 'Your rights';

  @override
  String get acctNoticeRightsBody =>
      'Access, correction, objection and erasure. Contact the LGU Data Protection Officer';

  @override
  String get acctNoticePending =>
      'The privacy notice will appear here when Taytay LGU publishes it.';

  @override
  String get acctBannersIntroBefore =>
      'All from Wikimedia Commons. Photos marked ';

  @override
  String get acctBannersIntroAfter =>
      ' show people and are placeholders until Taytay LGU supplies its own consented photos.';

  @override
  String get acctReplaceMark => 'Replace';

  @override
  String get acctConversation => 'Conversation';

  @override
  String get acctConversationClosed => 'This conversation is closed.';

  @override
  String get acctAttachment => 'Attachment';

  @override
  String get acctPhotoReliefDistribution =>
      'DSWD relief distribution (2026 earthquake)';

  @override
  String get acctPhotoMunicipalHall => 'Taytay Municipal Hall';

  @override
  String get acctPhotoParishChurch => 'St. John the Baptist Parish Church';

  @override
  String get acctPhotoPesoNotes => 'Philippine peso notes and coins';

  @override
  String get acctPhotoMuzonStreet => 'Street in Muzon, Taytay';

  @override
  String get acctPhotoSariSari => 'Sari-sari store, Manila';

  @override
  String get acctPhotoRescuers => 'BFP rescuers, Angeles City';

  @override
  String get acctPhotoRescueVehicle => 'Rescue vehicle, Bula';

  @override
  String get acctPhotoSkillsTraining => 'TESDA skills training';

  @override
  String get acctPhotoSkCouncil => 'Sangguniang Kabataan council';

  @override
  String get acctPhotoSkCourt => 'SK basketball court';

  @override
  String get acctPhotoHealthCentre => 'Barangay health center, Bula';

  @override
  String get acctPhotoVaccination => 'Vaccination, Camarines Sur';

  @override
  String get acctMessagesNoneUnread => 'No new replies';

  @override
  String acctMessagesUnread(int count, String office) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies from $office',
      one: '1 new reply from $office',
    );
    return '$_temp0';
  }

  @override
  String get acctVerifiedResident => 'Verified resident';

  @override
  String get acctMenuProfile => 'Resident Profile';

  @override
  String get acctMenuProfileDetail => 'Name, contact, barangay';

  @override
  String acctMenuProfileComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get acctMenuSectors => 'Sectors and benefits';

  @override
  String get acctMessages => 'Messages';

  @override
  String get acctMenuVerification => 'Verification status';

  @override
  String acctVerifiedOn(String date) {
    return 'Verified · $date';
  }

  @override
  String get acctMenuRequestDocuments => 'Request documents';

  @override
  String get acctMenuRequestDocumentsDetail =>
      'Certificates and copies from offices';

  @override
  String get acctMenuHousehold => 'Household';

  @override
  String get acctMenuHouseholdDetail => 'Address and your place in it';

  @override
  String get acctMenuSettings => 'Settings';

  @override
  String get acctMenuSettingsDetail => 'Notifications, language';

  @override
  String get acctMenuPrivacy => 'Privacy & data';

  @override
  String get acctMenuPrivacyDetail => 'Privacy Notice, your data rights';

  @override
  String get acctMenuCredits => 'Photo credits & about';

  @override
  String get acctMenuCreditsDetail => 'Licences, app version';

  @override
  String get acctVerifiedByLgu => 'Verified by Taytay LGU';

  @override
  String get acctCannotAttach => 'This phone cannot attach a file.';

  @override
  String get acctWriteBeforeSending => 'Write a message before sending.';

  @override
  String get acctEditProfile => 'Edit profile';

  @override
  String get acctFieldEmail => 'Email';

  @override
  String get acctSettingsTitle => 'Settings & privacy';

  @override
  String get acctSecurityTitle => 'Sign-in and security';

  @override
  String get acctAppLock => 'App lock';

  @override
  String get acctAppLockLede =>
      'Ask for your fingerprint, face or screen lock before showing your details again after you leave the app.';

  @override
  String get acctLockThisApp => 'Lock this app';

  @override
  String get acctAppLockNote =>
      'This lock protects this phone only. It is not how Taytay LGU knows who you are, and turning it on does not change what your account can do.';

  @override
  String get acctWhereSignedIn => 'Where you are signed in';

  @override
  String get acctThisDevice => 'This device';

  @override
  String get acctSignOutLede =>
      'Signing out removes your session from this phone. Public Taytay services stay available to you as a guest.';

  @override
  String get acctSignOutThisDevice => 'Sign out of this device';

  @override
  String get acctLockOn =>
      'On. You will be asked to unlock when you come back to the app.';

  @override
  String get acctLockOff => 'Off.';

  @override
  String get acctLockNotEnrolled =>
      'Set up a fingerprint, face unlock or screen lock in your phone settings to use this.';

  @override
  String get acctLockUnsupported =>
      'This phone cannot show an unlock prompt, so the app lock is not available here.';

  @override
  String get acctLockCancelled =>
      'App lock was not turned on. You can try again any time.';

  @override
  String get acctLockFailed => 'That did not match, so the app lock stays off.';

  @override
  String get acctLockUnavailable =>
      'Your phone could not show the unlock prompt.';

  @override
  String get acctCheckingSignIns => 'Checking where you are signed in';

  @override
  String get acctSignInsErrorTitle => 'Could not check your sign-ins';

  @override
  String get acctSignInsErrorBody =>
      'We could not reach Taytay LGU IDS to list where your account is signed in. Try again in a moment. Signing out here always ends this device\'s session.';

  @override
  String get acctCheckDevicesLede =>
      'Check the devices your Taytay LGU IDS account is currently signed in on.';

  @override
  String get acctCheckMyDevices => 'Check my devices';

  @override
  String acctSignOutOtherDevices(int count) {
    return 'Sign out all $count other devices';
  }

  @override
  String get acctSignedIn => 'Signed in';

  @override
  String acctLastUsed(String date) {
    return 'Last used $date';
  }

  @override
  String get acctAccountTitle => 'Account';

  @override
  String get acctResident => 'Resident';

  @override
  String get acctNotSignedIn => 'Not signed in';

  @override
  String get acctNotYetVerified => 'Account not yet verified';

  @override
  String get acctPreferences => 'Preferences';

  @override
  String get acctVibration => 'Vibration feedback';

  @override
  String get acctVibrationDetail =>
      'Short vibrations when an action succeeds or fails.';

  @override
  String get acctSectionSecurity => 'Security';

  @override
  String get acctSecurityDetail =>
      'App lock, signing out, and where you are signed in.';

  @override
  String get acctServiceStatus => 'Service status';

  @override
  String get acctServiceStatusLede =>
      'Check whether Taytay LGU services are reachable. This helps tell a service outage from a connection problem.';

  @override
  String get acctChecking => 'Checking…';

  @override
  String get acctCheckServiceStatus => 'Check service status';

  @override
  String get acctCurrentPassword => 'Current password';

  @override
  String get acctNewPassword => 'New password';

  @override
  String get acctRepeatNewPassword => 'Repeat the new password';

  @override
  String get acctEnterCurrentPassword => 'Enter your current password.';

  @override
  String get acctEnterNewPassword => 'Enter a new password.';

  @override
  String get acctPasswordsDoNotMatch => 'Those passwords do not match.';

  @override
  String get acctPasswordWrong => 'That password does not match.';

  @override
  String get acctPasswordWeak =>
      'Use at least 8 characters, with a letter and a number.';

  @override
  String get acctSaving => 'Saving';

  @override
  String get acctSavePassword => 'Save password';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionYourAccount => 'Your account';

  @override
  String get settingsRowAccountTitle => 'Account';

  @override
  String get settingsRowAccountDetail => 'Your details and how you sign in';

  @override
  String get settingsRowSecurityTitle => 'Sign-in and security';

  @override
  String get settingsRowSecurityDetail => 'App lock and devices';

  @override
  String get settingsRowNotificationsTitle => 'Notifications';

  @override
  String get settingsRowNotificationsDetail =>
      'What Taytay LGU tells you about';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsRowPrivacyNoticeTitle => 'Privacy notice';

  @override
  String get settingsRowPrivacyNoticeDetail =>
      'What Taytay LGU holds, and your rights';

  @override
  String get settingsRowConsentsTitle => 'Your consents and account requests';

  @override
  String get settingsRowConsentsDetail =>
      'What you agreed to, and asking for changes';

  @override
  String get settingsSectionAccessibility => 'Accessibility';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsRowHelpTitle => 'Help and contacting Taytay LGU';

  @override
  String get settingsRowHelpDetail => 'Questions, and where to go in person';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsReduceMotionTitle => 'Reduce motion';

  @override
  String get settingsReduceMotionOsOn =>
      'Already on, because your phone is set to reduce motion.';

  @override
  String get settingsReduceMotionDetail => 'Shortens or removes animations.';

  @override
  String get settingsVibrationTitle => 'Vibration feedback';

  @override
  String get settingsVibrationDetail =>
      'Short buzzes when something is confirmed.';

  @override
  String get settingsTextSizeNote =>
      'Text size follows your phone. This app is built to stay readable at the largest setting.';

  @override
  String get settingsTelemetryNone =>
      'This app sends no information about how you use it to anyone. It contacts Taytay LGU only to show you what you asked for.';

  @override
  String get settingsTelemetryTitle => 'Help improve this app';

  @override
  String get settingsTelemetryDetail =>
      'Sends which screens are opened and whether things worked. Never your name, your documents, what you applied for, or anything you typed.';

  @override
  String get settingsAboutBody =>
      'Taytay LGU IDS is the resident app for the Municipality of Taytay, Rizal. It is published by the municipal government.';

  @override
  String get settingsAboutReach =>
      'This app is one way to reach Taytay LGU. The municipal hall and your barangay hall handle everything it does, and more.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsTestBuildTitle => 'Test build. ';

  @override
  String settingsTestBuildBody(String environment) {
    return 'This is a $environment build, not the app published to residents.';
  }

  @override
  String get settingsSignOutTitle => 'Sign out of this device?';

  @override
  String get settingsSignOutConsequence =>
      'You will need your mobile number and a code to sign back in. Nothing you have sent Taytay LGU is removed.';

  @override
  String get settingsStaySignedIn => 'Stay signed in';

  @override
  String get settingsConsentsTitle => 'Consents and account requests';

  @override
  String get settingsLoadingConsents => 'Loading your consents';

  @override
  String get settingsSelfieConsent => 'Selfie consent';

  @override
  String get settingsSectionAgreed => 'What you agreed to';

  @override
  String get settingsNoConsents =>
      'Taytay LGU has no consents recorded for you.';

  @override
  String get settingsSectionAskingChanges => 'Asking Taytay LGU for changes';

  @override
  String get settingsRequestsNotOn =>
      'These requests are not switched on in this app yet. The municipal hall can take them in person, and your barangay hall can tell you where to go.';

  @override
  String get settingsAskCorrection => 'Ask for a correction';

  @override
  String get settingsCorrectionNotice =>
      'Corrections to your resident record are made by Taytay LGU. Use the correction path on your household or profile screen so the office knows which record you mean.';

  @override
  String get settingsReauthTitle => 'You may be asked to sign in again. ';

  @override
  String get settingsReauthBody =>
      'Taytay LGU asks residents to confirm who they are before changes like these.';

  @override
  String get settingsCheckingSelfieConsent => 'Checking the selfie consent';

  @override
  String get settingsSelfieConsentUnreadable =>
      'Where your selfie consent stands could not be read. Check your connection and try again.';

  @override
  String get settingsSelfieConsentUnpublished =>
      'Taytay LGU has not published a selfie consent yet, so the app takes no selfie and holds no consent for one.';

  @override
  String get settingsSelfieConsentOwed =>
      'You have not agreed to the selfie consent. The app asks before it takes any selfie, and you can verify in person instead.';

  @override
  String settingsSelfieConsentGiven(String version) {
    return 'You agreed that Taytay LGU may take and use your selfie (version $version).';
  }

  @override
  String settingsSelfieConsentGivenOn(String date, String version) {
    return 'You agreed on $date that Taytay LGU may take and use your selfie (version $version).';
  }

  @override
  String get settingsWhatWithdrawingDoes => 'What withdrawing does';

  @override
  String get settingsBiometricWithdrawn =>
      'Taytay LGU has recorded your withdrawal, and your selfies were erased.';

  @override
  String get settingsWithdrawalUnconfirmed =>
      'We could not confirm that your withdrawal was recorded. Trying again is safe: it is recorded only once.';

  @override
  String get settingsWithdrawalNotRecorded =>
      'That withdrawal was not recorded. Nothing has changed, and you can try again.';

  @override
  String get settingsWithdrawalRecorded =>
      'Taytay LGU has recorded your withdrawal.';

  @override
  String get settingsConsentRecordedAgain =>
      'Taytay LGU has recorded this consent again.';

  @override
  String get settingsConsentUnconfirmed =>
      'We could not confirm that your consent was recorded. Trying again is safe: it is recorded only once.';

  @override
  String get settingsConsentNotRecorded =>
      'That consent was not recorded. Nothing has changed, and you can try again.';

  @override
  String get settingsWithdrawConsentTitle => 'Withdraw this consent?';

  @override
  String get settingsWithdrawConsentConsequence =>
      'Taytay LGU will stop relying on this consent from the moment it is recorded. Anything already done under it stays as it is — a withdrawal is not backdated.';

  @override
  String get settingsWithdrawIt => 'Withdraw it';

  @override
  String get settingsLeaveInPlace => 'Leave it in place';

  @override
  String settingsConsentAgreedOn(String date) {
    return 'Agreed $date';
  }

  @override
  String settingsConsentWithdrawnOn(String date) {
    return 'Withdrawn $date';
  }

  @override
  String get settingsConsentInForce => 'In force';

  @override
  String get settingsConsentWithdrawn => 'Withdrawn';

  @override
  String get settingsWithdrawConsent => 'Withdraw this consent';

  @override
  String get settingsAcceptAgain => 'Accept again';

  @override
  String get settingsConsentKindTerms => 'Terms of Use';

  @override
  String get settingsConsentKindPrivacy => 'Privacy Notice';

  @override
  String get settingsConsentKindUnspecified =>
      'Terms and Privacy Notice (earlier agreement)';

  @override
  String get settingsConsentVersionAtTheTime => 'in force at the time';

  @override
  String settingsConsentStatementTerms(String version) {
    return 'Agreed to the Terms of Use, version $version';
  }

  @override
  String settingsConsentStatementPrivacy(String version) {
    return 'Acknowledged the Privacy Notice, version $version';
  }

  @override
  String settingsConsentStatementBiometric(String version) {
    return 'Agreed that Taytay LGU may use your selfie, version $version';
  }

  @override
  String settingsConsentStatementUnspecified(String version) {
    return 'Agreed to the Terms and the Privacy Notice together, version $version';
  }

  @override
  String get settingsCloseAction => 'Close my account';

  @override
  String get settingsCloseEffects =>
      'Closing your account takes effect at once, and you cannot sign in to it again. Your name, birth date, contact details, address and profile photo are removed from it, your digital ID is cancelled, and the ID photos and selfies you sent are deleted. Your phones stop getting notices from this app. If you head a household in the app, that household is removed. Records that Taytay LGU offices keep about you, such as your record at the MSWDO office and the requests you filed, stay with those offices. This cannot be undone in the app.';

  @override
  String get settingsCloseConfirmTitle => 'Close your account?';

  @override
  String get settingsCloseConfirm =>
      'Your account closes now and you cannot sign in to it again. Your digital ID is cancelled, and your details, photos and ID pictures are removed from the account. Records that Taytay LGU offices keep about you stay with them. This cannot be undone in the app.';

  @override
  String get settingsClosed =>
      'Your account is closed. You cannot sign in to it again, and your digital ID is cancelled. Records that Taytay LGU offices keep about you stay with them.';

  @override
  String get settingsCloseAlreadyClosed =>
      'Your account is already closed. You cannot sign in to it again.';

  @override
  String get settingsCloseNotConfirmed =>
      'We could not confirm that your account was closed. Trying again is safe: an account is closed only once.';

  @override
  String get settingsCloseNotClosed =>
      'Your account was not closed. Nothing has changed, and you can try again.';

  @override
  String get settingsHelpGettingHelp => 'Getting help';

  @override
  String get settingsHelpIntro =>
      'Everything in this app is also handled at the Taytay municipal hall and at your barangay hall. If something here will not work, going in person is never the wrong answer.';

  @override
  String get settingsFaqAccountQuestion =>
      'Do I need an account to use this app?';

  @override
  String get settingsFaqAccountAnswer =>
      'No. Announcements, events and the list of municipal services are open to everyone. You only need an account for things about you — your applications, your documents, your ID.';

  @override
  String get settingsFaqVerifyQuestion =>
      'Why does it ask me to verify my identity?';

  @override
  String get settingsFaqVerifyAnswer =>
      'Some services act on your resident record with Taytay LGU, so the office has to know it is you. Verifying is done once and unlocks those services.';

  @override
  String get settingsFaqDurationQuestion =>
      'How long will my application take?';

  @override
  String get settingsFaqDurationAnswer =>
      'Taytay LGU decides that, and it depends on the service and the documents. This app shows you where your application is and what is needed next, but it cannot promise a date.';

  @override
  String get settingsFaqRecordQuestion => 'Something in my record is wrong.';

  @override
  String get settingsFaqRecordAnswer =>
      'You can report it from your profile or household screen. The office checks and corrects it — the app never changes your record directly.';

  @override
  String get settingsFaqLostPhoneQuestion => 'I lost my phone.';

  @override
  String get settingsFaqLostPhoneAnswer =>
      'Sign in on your new phone. If you think somebody else is using your account, tell the municipal hall, and sign out other devices from the sign-in and security screen.';

  @override
  String get settingsHelpContactTitle => 'Contacting Taytay LGU. ';

  @override
  String get settingsHelpContactBody =>
      'Use the contact details published on the service, programme or event you are asking about — those come from the office running it. Your barangay hall can always point you to the right desk.';

  @override
  String get platformConsentBothChanged =>
      'The Terms of Use and the Privacy Notice have changed';

  @override
  String get platformConsentTermsChanged => 'The Terms of Use have changed';

  @override
  String get platformConsentPrivacyChanged => 'The Privacy Notice has changed';

  @override
  String get platformTermsUpdated => 'The Terms of Use were updated.';

  @override
  String platformTermsUpdatedOn(String date) {
    return 'The Terms of Use were updated on $date.';
  }

  @override
  String get platformPrivacyUpdated => 'The Privacy Notice was updated.';

  @override
  String platformPrivacyUpdatedOn(String date) {
    return 'The Privacy Notice was updated on $date.';
  }

  @override
  String get platformConsentRecording => 'Recording your agreement…';

  @override
  String get platformConsentAgree => 'I agree';

  @override
  String get platformConsentContinueForNow => 'Continue for now';

  @override
  String get platformConsentReadChanges =>
      'Please read what changed. To keep using your account, tick each text below to agree to it. If you do not agree, you can sign out and keep using the app as a guest.';

  @override
  String get platformReadTerms => 'Read the Terms of Use';

  @override
  String get platformReadPrivacy => 'Read the Privacy Notice';

  @override
  String get platformAgreementUnconfirmed =>
      'We could not confirm that your agreement was recorded. Agreeing again is safe: it is recorded only once.';

  @override
  String platformAgreementNotRecorded(String reason) {
    return 'Your agreement was not recorded. $reason';
  }

  @override
  String get platformConsentContinueNote =>
      'You can also continue for now without it. The app will ask again the next time you return to it.';

  @override
  String get messagingStartUnconfirmed =>
      'We could not confirm that your message was received. Sending it again is safe: it will not be posted twice. You can also check Messages.';

  @override
  String get messagingReplyUnconfirmed =>
      'We could not confirm that your message was received. Sending it again is safe: it will not be posted twice.';

  @override
  String get messagingNotSent => 'Nothing was sent.';

  @override
  String get messagingStartConflict =>
      'Nothing was sent. Something went wrong on our side. Open Messages to check what the office has before trying again.';

  @override
  String verifDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get verifUploadNewPhoto => 'Upload new photo';

  @override
  String get verifAddPhoto => 'Add';

  @override
  String get verifPreviousSelfieKept => 'Previous selfie kept';

  @override
  String get verifTakeSelfie => 'Take a selfie';

  @override
  String get verifCheckingStatus => 'Checking your verification status';

  @override
  String get verifCouldNotCheckStatus => 'Could not check your status';

  @override
  String get verifNewPhotoSent => 'New photo sent';

  @override
  String get verifPhotoAdded => 'Photo added';

  @override
  String get verifIdType => 'Type of ID';

  @override
  String get verifIdTypeDriversLicense => 'Driver\'s license';

  @override
  String get verifIdTypePassport => 'Passport';

  @override
  String get verifIdTypeOther => 'Other government ID';

  @override
  String get verifSelfieConsentChecking => 'Checking the selfie consent';

  @override
  String get verifSelfieErasedHeading => 'Your selfie was erased';

  @override
  String get verifSelfieErasedSlot => 'Selfie erased: take a new one';

  @override
  String get verifSelfieRetake => 'Take a new selfie';

  @override
  String verifSelfieErasedPendingOn(String date) {
    return 'You withdrew your selfie consent on $date, so the selfie you sent was erased. Staff cannot approve this request until you send a new selfie, or you can verify in person instead.';
  }

  @override
  String get verifSelfieErasedPending =>
      'You withdrew your selfie consent, so the selfie you sent was erased. Staff cannot approve this request until you send a new selfie, or you can verify in person instead.';

  @override
  String verifSelfieErasedRejectedOn(String date) {
    return 'You withdrew your selfie consent on $date, so the selfie you sent was erased. Send a new one with your ID, or verify in person instead.';
  }

  @override
  String get verifSelfieErasedRejected =>
      'You withdrew your selfie consent, so the selfie you sent was erased. Send a new one with your ID, or verify in person instead.';

  @override
  String get verifSendValidId => 'Send your valid ID';

  @override
  String get verifIdFront => 'Front of ID';

  @override
  String get verifIdBackOptional => 'Back of ID (optional)';

  @override
  String get verifSelfie => 'Selfie';

  @override
  String get verifMethodInPerson =>
      'Verified in person at the Taytay LGU office.';

  @override
  String get verifMethodSelfie => 'Verified with your valid ID and selfie.';

  @override
  String get verifReplacedErased =>
      'Replaced: you were verified in person at the office, so your selfie request was closed and the selfie you sent was erased.';

  @override
  String get verifReplaced =>
      'Replaced: you were verified in person at the office, so your selfie request was closed.';

  @override
  String get verifStatusTitle => 'Verification status';

  @override
  String get verifResubmitDialogTitle => 'Message to Taytay LGU';

  @override
  String get verifResubmit => 'Resubmit for verification';

  @override
  String get verifCategoryPersonalDetails => 'Your details';

  @override
  String get verifAddress => 'Address';

  @override
  String get verifCategoryContact => 'Contact details';

  @override
  String get verifCategoryIdPhoto => 'ID photo';

  @override
  String get verifCategoryPhoto => 'Photo of you';

  @override
  String get verifCategoryOther => 'Details';

  @override
  String get verifPendingTitle => 'We\'re reviewing your account';

  @override
  String get verifPendingChip => 'Pending review';

  @override
  String get verifPendingBody =>
      'Taytay LGU staff are checking your valid ID and selfie.';

  @override
  String get verifNoActionNeeded => 'No action needed.';

  @override
  String get verifProgress => 'Progress';

  @override
  String get verifStepAccountCreated => 'Account created';

  @override
  String get verifStepEmailConfirmed => 'Email confirmed';

  @override
  String get verifStepIdReceived => 'Valid ID and selfie received';

  @override
  String get verifStepLguReview => 'LGU review';

  @override
  String get verifStepInQueue => 'In queue';

  @override
  String get verifStepVerifiedDetail =>
      'Unlocks document requests, messaging offices and applying for Tulong';

  @override
  String verifSubmittedOn(String date) {
    return 'Submitted $date';
  }

  @override
  String get verifPendingBrowseNote =>
      'While pending you can browse services, news and events, and use emergency hotlines.';

  @override
  String get verifVerifiedBody =>
      'You now have full access to resident services.';

  @override
  String verifVerifiedBodyOn(String date) {
    return 'Verified by Taytay LGU on $date. You now have full access to resident services.';
  }

  @override
  String get verifGoHome => 'Go to Home';

  @override
  String get verifVerifiedTitle => 'Your account is verified';

  @override
  String get verifYouCanNow => 'You can now';

  @override
  String get verifCanRequestDocuments => 'Request documents';

  @override
  String get verifCanRequestDocumentsDetail =>
      'Certificates, clearances and permits';

  @override
  String get verifCanMessage => 'Message municipal offices';

  @override
  String get verifCanMessageDetail => 'Ask questions and follow up requests';

  @override
  String get verifCanUseId => 'Use your Taytay digital ID';

  @override
  String get verifCanUseIdDetail => 'Show it at the municipal hall';

  @override
  String get verifCompleteProfile => 'Complete your Resident Profile';

  @override
  String verifPercentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get verifCorrectionFallbackReason =>
      'Taytay LGU needs a correction before it can finish checking.';

  @override
  String get verifNeedsCorrection => 'Needs correction';

  @override
  String get verifYourMessage => 'Your message';

  @override
  String get verifSendNewValidId => 'Send a new valid ID';

  @override
  String get verifRetake => 'Retake';

  @override
  String get verifNotVerified => 'Not verified';

  @override
  String get verifNotVerifiedBody =>
      'Taytay LGU has not confirmed this account. You can browse services while you send your valid ID and selfie, or verify in person.';

  @override
  String get verifHeldFromYou => 'What Taytay LGU has from you';

  @override
  String get verifReasonHeading => 'REASON FROM TAYTAY LGU';

  @override
  String verifReviewedOn(String date) {
    return 'Reviewed $date';
  }

  @override
  String get verifGateNotVerifiedYet => 'Your account is not verified yet.';

  @override
  String get verifGateTitleDigitalId =>
      'Verify your account to open your digital ID';

  @override
  String get verifGateTitleMessage => 'Verify your account to message offices';

  @override
  String get verifGateTitleOther => 'Verify your account to continue';

  @override
  String get verifGateLeadMessage =>
      'Messaging municipal offices is for verified Taytay residents.';

  @override
  String get verifGateLeadDigitalId =>
      'Your Taytay digital ID is for verified Taytay residents.';

  @override
  String get verifGateLeadOther =>
      'This action is for verified Taytay residents.';

  @override
  String get verifKycLoadingBarangays => 'Loading barangays…';

  @override
  String get verifKycIntro =>
      'Taytay LGU checks these details against the municipal resident register. Enter them as they appear on your birth certificate or valid ID.';

  @override
  String get verifKycBarangaysFailed => 'Could not load barangays';

  @override
  String get verifKycStartFailed => 'Could not start your verification';

  @override
  String get verifKycAsOnId => 'As it appears on your ID.';

  @override
  String get verifSuffix => 'Suffix';

  @override
  String get verifKycChooseBirthDate => 'Choose your date of birth';

  @override
  String get verifKycSexHint => 'As recorded on your birth certificate.';

  @override
  String get verifSexFemale => 'Female';

  @override
  String get verifSexMale => 'Male';

  @override
  String get verifSexUnspecified => 'Unspecified';

  @override
  String get verifKycWhyTitle => 'Why does Taytay LGU need these?';

  @override
  String get verifKycWhyPurpose =>
      'Taytay LGU matches these details against the municipal resident register to confirm you are who you say you are.';

  @override
  String get verifKycWhyWho =>
      'Staff reviewing verification for your barangay. Your details are not shown to other residents and are not used for anything else.';

  @override
  String get verifKycWhyDecline =>
      'You can keep using this app to browse municipal services and announcements. You will not be able to hold a digital ID until Taytay LGU confirms who you are. Programme pages are information only.';

  @override
  String get verifKycSaveContinue => 'Save and continue';

  @override
  String get verifKycNothingSentYet =>
      'Nothing is sent to Taytay LGU yet. You can check your details before sending them for review.';

  @override
  String get verifProfileUnavailable => 'Profile is not available right now.';

  @override
  String get verifProfileHeader => 'Resident profile';

  @override
  String get verifProfileLoading => 'Loading your profile';

  @override
  String get verifProfileTitle => 'Resident Profile';

  @override
  String get verifProfileSubmittedTitle => 'Profile submitted';

  @override
  String get verifProfileSubmittedMessage =>
      'Your resident profile was sent to Taytay LGU. We\'ll notify you when it has been reviewed.';

  @override
  String get verifBackToProfile => 'Back to profile';

  @override
  String get verifPersonalInfo => 'Personal information';

  @override
  String get verifSaveAndContinue => 'Save & continue';

  @override
  String get verifHouseholdAddress => 'Household & address';

  @override
  String get verifReviewSubmit => 'Review & submit';

  @override
  String get verifSubmitToLgu => 'Submit to Taytay LGU';

  @override
  String get verifYourName => 'Your name';

  @override
  String get verifProfileCompleteness => 'Profile completeness';

  @override
  String get verifCompleteAllSections =>
      'Complete all sections to submit your profile to Taytay LGU.';

  @override
  String get verifSectionComplete => 'Complete';

  @override
  String get verifSupportingDocuments => 'Supporting documents';

  @override
  String get verifBirthdate => 'Birthdate';

  @override
  String get verifAge => 'Age';

  @override
  String get verifContact => 'Contact';

  @override
  String get verifEmail => 'Email';

  @override
  String get verifHouseNoStreet => 'House no. / Street';

  @override
  String get verifPurokSitio => 'Purok / Sitio';

  @override
  String get verifMunicipalityProvince => 'Municipality / Province';

  @override
  String get verifHousehold => 'Household';

  @override
  String get verifYearsAtThisAddress => 'Years at this address';

  @override
  String get verifHouseholdMembers => 'Household members';

  @override
  String get verifResidenceType => 'Residence type';

  @override
  String get verifName => 'Name';

  @override
  String get verifSexBirthdate => 'Sex · Birthdate';

  @override
  String get verifMobile => 'Mobile';

  @override
  String get verifYearsAtAddress => 'Years at address';

  @override
  String get verifCertify =>
      'I certify that the information is true and correct, and I consent to its processing under the Data Privacy Act of 2012 per Taytay LGU\'s Privacy Notice.';

  @override
  String get verifSubmitted => 'Submitted';

  @override
  String get verifProfileVerified => 'Profile verified';

  @override
  String get verifEdit => 'Edit';

  @override
  String get issuanceStatusSubmitted => 'Sent to the office';

  @override
  String get issuanceStatusUnderReview => 'Being reviewed';

  @override
  String get issuanceStatusNeedsInfo => 'Needs more from you';

  @override
  String get issuanceStatusApproved => 'Approved, being prepared';

  @override
  String get issuanceStatusReadyForPickup => 'Ready to claim';

  @override
  String get issuanceStatusReleased => 'Claimed';

  @override
  String get issuanceStatusRejected => 'Not issued';

  @override
  String get issuanceStatusUpdated => 'Updated';

  @override
  String get issuanceExplainSubmitted =>
      'The office has your request. Nobody has started on it yet.';

  @override
  String get issuanceExplainUnderReview =>
      'The office is checking your request and your files. Nothing is needed from you now.';

  @override
  String get issuanceExplainNeedsInfo =>
      'The office needs something more before it can go on. Read what they asked for, then send it here.';

  @override
  String get issuanceExplainApproved =>
      'The office approved your request and is preparing the document. You will be told here when it is ready.';

  @override
  String get issuanceExplainReadyForPickup =>
      'Your document is ready. Read below when and where to claim it.';

  @override
  String get issuanceExplainReleased =>
      'The office released the document to you.';

  @override
  String get issuanceExplainRejected =>
      'The office could not issue this document. Their reason is below.';

  @override
  String get issuanceExplainCancelled => 'This request was cancelled.';

  @override
  String get issuanceExplainUpdated =>
      'The office updated this request. Ask the office if anything is unclear.';

  @override
  String get issuanceHistorySent => 'You sent the request';

  @override
  String get issuanceHistoryCancelled => 'You cancelled the request';

  @override
  String get issuanceHistoryAnswered => 'You sent what the office asked for';

  @override
  String get issuanceHistoryReviewStarted => 'The office started reviewing it';

  @override
  String get issuanceHistoryAskedForMore => 'The office asked for more';

  @override
  String get issuanceHistoryApproved => 'The office approved it';

  @override
  String get issuanceHistoryRefused => 'The office could not issue it';

  @override
  String get issuanceHistoryReleased => 'The office released the document';

  @override
  String get issuanceHistoryUpdated => 'The request was updated';

  @override
  String get issuanceHistoryClaimedNext => 'Claimed at the office';

  @override
  String get issuanceHistoryUpcoming => 'You will see it here';

  @override
  String issuanceHistoryByYou(String date) {
    return '$date · You';
  }

  @override
  String issuanceHistoryByOffice(String date) {
    return '$date · Office';
  }

  @override
  String get issuanceYourNote => 'Your note';

  @override
  String get issuanceFromOffice => 'From the office';

  @override
  String get issuanceAccessSignInTitle => 'Sign in to request a document';

  @override
  String get issuanceAccessSignInBody =>
      'You can read what each document needs now. To send a request, sign in with a verified Taytay account.';

  @override
  String get issuanceAccessVerifyTitle => 'Verify your account first';

  @override
  String get issuanceAccessVerifyBody =>
      'Only verified Taytay residents can send a document request, because the office issues it in your name. You can read what each document needs now.';

  @override
  String get issuanceLoadNotFoundTitle => 'Not found';

  @override
  String get issuanceLoadNotFoundBody =>
      'This is not available. It may have been removed, or it belongs to another account.';

  @override
  String get issuanceLoadOfflineBody =>
      'Taytay LGU could not be reached. Check your connection and try again.';

  @override
  String get issuanceLoadFailedThis => 'Could not load this';

  @override
  String get issuanceLoadFailedDocuments => 'Could not load the documents';

  @override
  String get issuanceLoadFailedDocument => 'Could not load this document';

  @override
  String get issuanceLoadFailedRequest => 'Could not load this request';

  @override
  String get issuanceLoadFailedRequests => 'Could not load your requests';

  @override
  String get issuanceCancelTitle => 'Cancel this request?';

  @override
  String issuanceCancelMessage(String reference) {
    return 'The office will stop working on $reference. A cancelled request cannot be opened again; you would send a new one.';
  }

  @override
  String get issuanceCancelConfirm => 'Cancel request';

  @override
  String get issuanceCancelKeep => 'Keep it';

  @override
  String get issuanceCancelDone => 'Request cancelled.';

  @override
  String get issuanceCancelButton => 'Cancel this request';

  @override
  String get issuanceDetailTitle => 'Document request';

  @override
  String get issuanceDetailLoading => 'Opening your request';

  @override
  String get issuanceAskedLabel => 'What the office asked for';

  @override
  String get issuanceHowToClaim => 'How to claim it';

  @override
  String get issuanceBringId => 'Bring a valid ID and your reference number.';

  @override
  String get issuanceRefusalLabel => 'The office\'s reason';

  @override
  String get issuanceProgress => 'Progress';

  @override
  String get issuanceYourRequest => 'Your request';

  @override
  String get issuancePurpose => 'Purpose';

  @override
  String get issuanceFilesSent => 'Files you sent';

  @override
  String get issuanceFile => 'File';

  @override
  String issuanceAttachmentVersion(int version) {
    return 'version $version';
  }

  @override
  String get issuanceAttachmentReplaced => 'replaced later';

  @override
  String get issuanceView => 'View';

  @override
  String issuancePhotoLoading(String label) {
    return 'Loading the photo you sent for $label';
  }

  @override
  String issuancePhotoSemantic(String label) {
    return 'The photo you sent for $label';
  }

  @override
  String get issuancePhotoOffline => 'You are offline. Connect and try again.';

  @override
  String get issuancePhotoUnavailable =>
      'This file cannot be shown here. The office still has it.';

  @override
  String get issuanceResubmitTitle => 'Send what the office asked for';

  @override
  String get issuanceResubmitIntro =>
      'Add a note, a new file, or both. A new file is kept beside the one you sent before; nothing you sent is replaced.';

  @override
  String get issuanceResubmitNoteLabel => 'Note to the office (optional)';

  @override
  String get issuanceResubmitOptional => 'New file, if asked';

  @override
  String get issuanceResubmitEmpty => 'Add a note or a file first.';

  @override
  String get issuanceSendToOffice => 'Send to the office';

  @override
  String get issuanceResubmitDone => 'Sent. The office will review it again.';

  @override
  String get issuanceRequestTitle => 'Request a document';

  @override
  String get issuanceFormLoading => 'Opening the form';

  @override
  String get issuanceReviewButton => 'Review request';

  @override
  String get issuancePurposeLabel => 'What is the document for?';

  @override
  String get issuancePurposeHint =>
      'For example: for a school enrolment requirement';

  @override
  String get issuancePurposeHelp => 'The office reads this. Keep it short.';

  @override
  String get issuancePurposeEmpty =>
      'Say what the document is for, for example \"for a school enrolment\".';

  @override
  String get issuanceFilesNeeded => 'Files the office needs';

  @override
  String issuanceFilesIntro(String accepted) {
    return 'One file each: $accepted. Lay paper flat, fill the frame, and make every word readable.';
  }

  @override
  String get issuanceMissingAnswers =>
      'Some answers are missing. They are marked above.';

  @override
  String get issuanceReviewTitle => 'Review your request';

  @override
  String get issuanceSendRequest => 'Send request';

  @override
  String get issuanceChangeSomething => 'Change something';

  @override
  String get issuanceAskingFor => 'You are asking for it';

  @override
  String get issuanceFilesSending => 'Files you are sending';

  @override
  String get issuanceKindPhoto => 'photo';

  @override
  String issuanceReviewNotSent(String name) {
    return '$name: not sent (optional)';
  }

  @override
  String get issuanceReviewNote =>
      'Check it before sending. You can cancel the request yourself until the office starts on it. After that, message the office.';

  @override
  String get issuanceDoneTitle => 'The office has your request';

  @override
  String get issuanceDoneMessage =>
      'Keep this number. The office uses it when you ask about your request.';

  @override
  String get issuanceDocument => 'Document';

  @override
  String get issuanceOffice => 'Office';

  @override
  String get issuanceDoneNote =>
      'The office will review it. Each step shows here and in your notifications, including when it is ready to claim.';

  @override
  String get issuanceFollowRequest => 'Follow this request';

  @override
  String get issuanceBackToDocuments => 'Back to documents';

  @override
  String get issuanceNothingSent => 'Nothing was sent.';

  @override
  String get issuanceNothingCancelled => 'Nothing was cancelled.';

  @override
  String get issuanceUnconfirmedSubmit =>
      'We could not confirm that your request was received. Sending the same request again is safe: it will not be filed twice. You can also check My document requests.';

  @override
  String get issuanceUnconfirmedResubmit =>
      'We could not confirm that your changes were received. Sending them again is safe: they will not be filed twice. You can also go back and open the request to check.';

  @override
  String get issuanceUnconfirmedCancel =>
      'We could not confirm that your cancellation was received. Trying again is safe: the request is cancelled only once. You can also go back and open the request to check.';

  @override
  String get issuanceFailVerifyTitle => 'Only verified residents can do this';

  @override
  String get issuanceFailVerifyBody =>
      'Taytay LGU does not have your account as verified. Finish verification first, then come back to this page.';

  @override
  String get issuanceFailForbiddenBody =>
      'Document requests are not open to this account. The municipal hall can tell you more.';

  @override
  String get issuanceFailOfflineBody =>
      'Your answers are still here on the phone. Connect to the internet and try again.';

  @override
  String get issuanceFailCheckBody =>
      'The office could not accept part of it. The items marked below need checking.';

  @override
  String get issuanceFailFileBody =>
      'A file was too large or could not be read. Choose a smaller photo or another file, and try again.';

  @override
  String get issuanceFailRateBody => 'Wait a few minutes, then try again.';

  @override
  String get issuanceFailKeyConflictBody =>
      'Something went wrong on our side. Open My document requests to check what the office has before trying again.';

  @override
  String get issuanceFailMovedBody =>
      'The office has already acted on it. Go back and open it again to see where it stands.';

  @override
  String get issuanceFailGoneTitle => 'No longer available';

  @override
  String get issuanceFailGoneBody =>
      'The office no longer lists this. Go back to the list to see what is available.';

  @override
  String get issuanceFailSessionBody =>
      'Your session ended. Sign in, then try again.';

  @override
  String get issuanceFailServerBody =>
      'Something went wrong on our side. Try again in a moment.';

  @override
  String get issuanceFeeNotStated => 'No fee stated';

  @override
  String get issuanceFeeNone => 'No fee';

  @override
  String issuanceFee(String amount) {
    return 'Fee: $amount, paid at the office';
  }

  @override
  String get issuanceProcessingNotStated => 'Processing time not stated';

  @override
  String get issuanceProcessingSameDay => 'Usually the same working day';

  @override
  String issuanceProcessingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'About $days working days',
      one: 'About 1 working day',
    );
    return '$_temp0';
  }

  @override
  String get issuanceAcceptedAnyFile => 'a file';

  @override
  String issuanceAcceptedOr(String first, String last) {
    return '$first or $last';
  }

  @override
  String issuanceAcceptedLine(String kinds, int limit) {
    return '$kinds, up to $limit MB each';
  }

  @override
  String get issuanceCatalogueTitle => 'Request documents';

  @override
  String get issuanceSearchHint => 'Search documents';

  @override
  String get issuanceMyRequests => 'My document requests';

  @override
  String get issuanceMyRequestsDetail => 'Follow what you have sent';

  @override
  String get issuanceCatalogueIntro =>
      'Certificates and certified copies the municipal offices issue. Choose one to see what it needs. Any fee is paid at the office, never in the app.';

  @override
  String get issuanceCatalogueLoading => 'Loading documents';

  @override
  String get issuanceCatalogueEmptyTitle => 'No documents listed yet';

  @override
  String get issuanceCatalogueEmptyMessage =>
      'The municipal offices have not listed any documents in the app yet. You can still ask at the Municipal Hall.';

  @override
  String get issuanceNoMatchTitle => 'No document matches';

  @override
  String get issuanceNoMatchMessage =>
      'Try another word, or clear the search to see them all.';

  @override
  String get issuanceTypeTitle => 'Document details';

  @override
  String get issuanceRequestThis => 'Request this document';

  @override
  String get issuanceTypeLoading => 'Opening this document';

  @override
  String get issuanceFeeLabel => 'Fee';

  @override
  String get issuanceProcessingLabel => 'Processing time';

  @override
  String get issuanceWhatToSend => 'What you need to send';

  @override
  String get issuanceNoFilesNeeded =>
      'No files. The purpose of your request is enough.';

  @override
  String issuanceSendEachAs(String accepted) {
    return 'Send each one as a photo or a file: $accepted.';
  }

  @override
  String get issuanceClaimFallback =>
      'The office will tell you here when and where to claim it, once it is ready.';

  @override
  String get issuanceNoPicker =>
      'This phone cannot pick a file. The office can take the document in person at the Municipal Hall.';

  @override
  String get issuanceMyRequestsEmptyTitle => 'No document requests yet';

  @override
  String get issuanceMyRequestsEmptyMessage =>
      'When you request a certificate or a copy from a municipal office, you can follow it here.';

  @override
  String issuanceSentOn(String date) {
    return 'Sent $date';
  }

  @override
  String get digitalIdTitle => 'My Taytay ID';

  @override
  String get digitalIdLoading => 'Loading your digital ID';

  @override
  String get digitalIdUnknownStatus =>
      'Your digital ID will appear here once Taytay LGU issues it.';

  @override
  String get digitalIdGenuineNote =>
      'Taytay LGU issued this card. A scanner checks the code. This phone does not decide that the card is genuine.';

  @override
  String get digitalIdNotYetIssued => 'Not yet issued';

  @override
  String get digitalIdPhotoSemantic => 'ID photo';

  @override
  String get digitalIdPhotoPlaceholder => 'Photo placeholder';

  @override
  String get digitalIdStatusActive => 'Active';

  @override
  String get digitalIdStatusSuspended => 'Suspended';

  @override
  String get digitalIdStatusRevoked => 'Revoked';

  @override
  String digitalIdStatusSemantic(String status) {
    return 'Status: $status';
  }

  @override
  String get digitalIdCodeRefreshes => 'Code refreshes';

  @override
  String digitalIdCodeValidUntil(String time, String zone) {
    return 'Code refreshes · valid until $time $zone';
  }

  @override
  String get digitalIdShowCode => 'Show this code to be scanned';

  @override
  String get digitalIdRefreshingCode => 'Refreshing code…';

  @override
  String get digitalIdNoCodeWhileInactive =>
      'No code is shown while the card is not active.';

  @override
  String get digitalIdSuspendedTitle => 'Your ID is suspended';

  @override
  String get digitalIdSuspendedBody =>
      'Taytay LGU has paused this card. Visit the Municipal Hall or message the LGU to find out why.';

  @override
  String get digitalIdRevokedTitle => 'This ID is no longer valid';

  @override
  String get digitalIdRevokedBody =>
      'Taytay LGU has revoked this card. Visit the Municipal Hall if you need a new one.';

  @override
  String get digitalIdExpiredTitle => 'Your ID has expired';

  @override
  String get digitalIdExpiredBody =>
      'This card passed its expiry date. Visit the Municipal Hall to renew it.';

  @override
  String get digitalIdPreparingTitle => 'Your card is being prepared';

  @override
  String get digitalIdPreparingBody =>
      'You\'re verified. The MSWDO issues your card next, and it appears here with a QR code.';

  @override
  String get digitalIdStepsTitle => 'Where your card is';

  @override
  String get digitalIdStepAccountCreated => 'Account created';

  @override
  String get digitalIdStepIdSent => 'ID and selfie sent';

  @override
  String get digitalIdStepVerified => 'Verified by Taytay LGU';

  @override
  String get digitalIdStepIssued => 'Card issued by the MSWDO';

  @override
  String get digitalIdStepIssuedDetail =>
      'Check this page again later. The card photo is usually your verification selfie.';

  @override
  String get digitalIdStepShow => 'Show your card';

  @override
  String get digitalIdStepShowDetail =>
      'Staff scan its QR code. Each code works for a short time, and the app gets a new one.';

  @override
  String get digitalIdAboutTitle => 'About your card';

  @override
  String get digitalIdAboutWhat =>
      'It is Taytay\'s own resident card, not a national government ID. The card shows the date it expires.';

  @override
  String get digitalIdAboutStops =>
      'If it is suspended or expires, the app stops showing its QR code. Message the MSWDO to find out what to do.';

  @override
  String get digitalIdMessageMswdo => 'Message the MSWDO';

  @override
  String get hhTitle => 'Household and family';

  @override
  String get hhLoading => 'Loading your household record';

  @override
  String get hhSectionHousehold => 'Your household';

  @override
  String get hhRowHousehold => 'Household';

  @override
  String get hhRowPeople => 'People recorded here';

  @override
  String get hhSectionFamily => 'Your family record';

  @override
  String get hhRoleHeadBody =>
      'Taytay LGU records you as the person who answers for this household. The office keeps that record. This app does not take applications.';

  @override
  String get hhRoleMemberBody =>
      'Taytay LGU records you as part of this household. This app does not take applications.';

  @override
  String get hhHiddenTitle => 'Why you cannot see the other people here';

  @override
  String get hhHiddenBody =>
      'The details of everyone else in your household belong to them, not to your account — so this app does not show their names, their situation or anything they have applied for. Taytay LGU staff can go through the household record with you in person.';

  @override
  String get hhNoneTitle => 'No household on your account yet';

  @override
  String get hhNoneBody =>
      'Your account is not part of a household in this app, and this version of the app cannot set one up. The municipal hall keeps its own household record, and staff can go through it with you.';

  @override
  String get hhCorrectionHeading => 'Is something wrong?';

  @override
  String get hhCorrectionLead =>
      'Tell Taytay LGU what looks wrong and they will check the record. Nothing changes until staff review it.';

  @override
  String get hhReportError => 'Report an error';

  @override
  String get hhNotOnFile => 'Not on file';

  @override
  String get hhFixQuestion => 'What looks wrong?';

  @override
  String get hhFixLead =>
      'Pick the closest one. Taytay LGU staff will check the record — nothing changes until they do.';

  @override
  String get hhFixNoDetailsTitle => 'Please do not type personal details here';

  @override
  String get hhFixNoDetailsBody =>
      'This app asks only what kind of thing is wrong. Names, health information and reasons belong in the conversation with staff, who can record them properly and act on them.';

  @override
  String get hhFixHallTitle => 'Bring it to the municipal hall';

  @override
  String get hhFixHallBody =>
      'Household records are changed by Taytay LGU staff after they look at your documents. Visit the municipal hall with a valid ID — you do not need this app or your phone to be served there.';

  @override
  String get hhFixSentTitle => 'Taytay LGU has your report';

  @override
  String get hhFixSentBody =>
      'Staff will check the record. Nothing has been changed yet, and you will be told what they find.';

  @override
  String get hhFixFailedTitle => 'Could not send your report';

  @override
  String get hhFixFailedBody =>
      'Taytay LGU has not switched on household reports in this app yet. Nothing was sent, and nothing has changed. The municipal hall can take it in person.';

  @override
  String get hhFixSend => 'Send report';

  @override
  String get hhFixNoChange =>
      'Sending this does not change your household record.';

  @override
  String get profTitle => 'Profile';

  @override
  String get profGuestTitle => 'You are browsing as a guest';

  @override
  String get profGuestBody =>
      'Sign in with your mobile number to hold your digital ID. Browsing stays open either way. Programme pages are information only.';

  @override
  String get profYourAccount => 'Your account';

  @override
  String get profUnverifiedBody =>
      'Taytay LGU has not confirmed your identity yet. Verifying unlocks your digital ID and applying for Tulong in the app.';

  @override
  String get profVerifiedResident => 'Verified resident';

  @override
  String get profSectionPrivacyHelp => 'Privacy and help';

  @override
  String get profPrivacyRow => 'Privacy and your data';

  @override
  String get profPrivacyRowDetail =>
      'What Taytay LGU holds, why, and your rights over it.';

  @override
  String get profHelpRow => 'Help and support';

  @override
  String get profHelpRowDetail => 'Trouble signing in, and where to get help.';

  @override
  String get profRequestDocuments => 'Request documents';

  @override
  String get profRequestDocumentsNeedsVerified =>
      'Sending a request needs a verified account';

  @override
  String get profMessageOffice => 'Message an office';

  @override
  String get profLoadingRecord => 'Loading your record';

  @override
  String get profAccountDetailsUnavailable =>
      'Taytay LGU has not switched on account details in this app yet. Your account still works.';

  @override
  String get profRecordUnavailable =>
      'Taytay LGU has not switched on your record in this app yet. The municipal hall can tell you what is on file.';

  @override
  String get profNotAvailableYet => 'Not available in this app yet';

  @override
  String get profCanonicalTitle => 'Taytay LGU keeps this correct';

  @override
  String get profCanonicalExplanation =>
      'This detail was checked against your documents, and other Taytay services rely on it. Changing it is a decision Taytay LGU makes, so it cannot be edited in this app.';

  @override
  String get profCanonicalNextStep =>
      'If it is wrong, visit the Taytay municipal hall with a valid ID and the document that shows the correct detail. Staff can update your record directly. You do not need this app or your phone to do it.';

  @override
  String get profCanonicalDuringVerification =>
      'You are part-way through identity verification. If Taytay LGU asked you for a correction there, answering it is the quickest way to fix this.';

  @override
  String get profCheckMyVerification => 'Check my verification';

  @override
  String get profBadgeNotSignedIn => 'Not signed in';

  @override
  String get profBadgeNotVerified => 'Not yet verified';

  @override
  String get profBadgeVerified => 'Verified by Taytay LGU';

  @override
  String get profSaveChanges => 'Save changes';

  @override
  String get profLoadingDetails => 'Loading your details';

  @override
  String get profContactWhyTitle => 'Why Taytay LGU keeps this';

  @override
  String get profContactWhyPurpose =>
      'Your mobile number is how Taytay LGU signs you in and tells you about your requests. Your email is optional and is used only to send you copies.';

  @override
  String get profContactWhoSees =>
      'Staff handling something you applied for. It is never shared for advertising.';

  @override
  String get profContactIfDecline =>
      'Without a mobile number you cannot sign in. Email can be left blank.';

  @override
  String get profContactSaved => 'Your contact details were updated.';

  @override
  String get profContactMaybeNotSavedTitle =>
      'Your changes may not have been saved.';

  @override
  String get profContactMaybeNotSavedBody =>
      'We could not confirm them. Saving again is safe: the same details are sent again.';

  @override
  String get profContactNotSavedTitle => 'Could not save your changes.';

  @override
  String profContactNotSavedBody(String reason) {
    return '$reason Nothing was changed, and the municipal hall can update them for you.';
  }

  @override
  String get profContactMobileHelper => 'This is also how you sign in.';

  @override
  String get profMobileEmpty => 'Enter your mobile number.';

  @override
  String get profMobileShape =>
      'Enter an 11-digit mobile number starting with 09.';

  @override
  String get profContactEmailInvalid =>
      'Enter an email address, or leave this blank.';

  @override
  String get profPrivacyResponsibleTitle =>
      'Taytay LGU is responsible for your information';

  @override
  String get profPrivacyResponsibleIntro =>
      'This app is one way to reach the Municipality of Taytay, Rizal. Your information belongs to your municipal record, not to the app on your phone.';

  @override
  String get profPrivacyKeptTitle => 'What this app keeps on your phone';

  @override
  String get profPrivacyKeptBody =>
      'Only what is needed to keep you signed in: a sign-in token in your phone’s secure keystore, your first name for the greeting, and whether Taytay LGU has verified you. Signing out removes all of it from this device.';

  @override
  String get profPrivacyNeverKeptTitle => 'What this app never keeps';

  @override
  String get profPrivacyNeverKeptBody =>
      'Your address, date of birth, ID images and household details are not stored on your phone. Screens fetch them when they show them, and nothing is written to a file or a cache.';

  @override
  String get profPrivacyLguHoldsTitle => 'What Taytay LGU holds';

  @override
  String get profPrivacyLguHoldsBody =>
      'Your municipal resident record: your name, date of birth, address and barangay, together with anything you have applied for. Staff see only what their work requires.';

  @override
  String get profPrivacyWhoElseTitle => 'Who else can see it';

  @override
  String get profPrivacyWhoElseBody =>
      'Nobody outside Taytay LGU, and no advertiser. Your information is not sold or shared for marketing. Sharing with another government office happens only where the law requires it.';

  @override
  String get profPrivacyRightsTitle => 'Your rights';

  @override
  String get profPrivacyRightsBody =>
      'Under the Data Privacy Act of 2012 you can ask Taytay LGU what it holds about you, ask for a copy, ask for a mistake to be corrected, object to how it is used, and complain to the National Privacy Commission.';

  @override
  String get profPrivacyRightsHow =>
      'Ask at the Taytay municipal hall with a valid ID. Staff there can act on your record directly. You do not need this app or your phone to do it.';

  @override
  String get profPrivacyConsentTitle => 'Changing what you agreed to.';

  @override
  String get profPrivacyConsentBody =>
      'The permissions you gave when you registered are held with your Taytay LGU record, not in this app. To change or withdraw one, ask at the municipal hall — that way the change is recorded where it counts.';

  @override
  String get profPrivacyDeleteTitle => 'Deleting your record.';

  @override
  String get profPrivacyDeleteBody =>
      'A municipal resident record is kept for as long as the law requires, so it is not deleted on request. Taytay LGU can deactivate an account and correct what is wrong.';

  @override
  String get profNameAsPrinted =>
      'Write your name exactly as it is printed on your government ID. Taytay LGU checks it against your ID.';

  @override
  String get profNameUnderReview =>
      'Taytay LGU is checking this name against your ID, so it cannot be changed while the check is pending.';

  @override
  String get profNameChecked =>
      'Taytay LGU checked this name against your ID, so it cannot be changed here. To change it, ask Taytay LGU.';

  @override
  String get profNameUnknown =>
      'We could not check whether your name can be changed. Try again later.';

  @override
  String get profNameBeforeSendingTitle => 'Your name and your ID';

  @override
  String get profNameBeforeSending =>
      'Taytay LGU will check that your ID shows the name on your account. Make sure the two match before you send. Your name cannot be changed while the check is pending or after it is approved.';

  @override
  String get profNameCheckName => 'Check the name on your account';

  @override
  String get profNameEmpty =>
      'Enter your name exactly as it is printed on your government ID.';

  @override
  String profNameTooLong(int max) {
    return 'Your name can be up to $max characters.';
  }

  @override
  String get profBarangayHeldNote =>
      'To change your barangay, visit the MSWDO office with proof of your new address.';

  @override
  String get profBarangayRefusedTitle => 'Your barangay was not changed';

  @override
  String get profBarangayRefused =>
      'Your account is verified, so your barangay is changed at the MSWDO office. To change your barangay, visit the MSWDO office with proof of your new address.';

  @override
  String get profOfficeRecordTitle => 'Your record at the MSWDO office';

  @override
  String get profOfficeRecordKeptByOffice =>
      'The office keeps this record. If something here is wrong, visit the MSWDO office with your ID.';

  @override
  String get profOfficeRecordName => 'Name';

  @override
  String get profOfficeRecordBirthDate => 'Birth date';

  @override
  String get profOfficeRecordNotShown => 'Ask the MSWDO office';

  @override
  String get profSexFemale => 'Female';

  @override
  String get profSexMale => 'Male';

  @override
  String get sectorsTitle => 'Sectors and benefits';

  @override
  String get sectorsIntro =>
      'Your sectors are part of your record at Taytay LGU. Offices use them to see which programmes may fit you.';

  @override
  String get sectorsYoursHeading => 'Your sectors';

  @override
  String get sectorsNone =>
      'No sectors are on your record in the app yet. They show here once the MSWDO links your account to its records, which it does when it approves your first application.';

  @override
  String get sectorsApplyHeading => 'Apply for a sector';

  @override
  String get sectorsNothingToApply =>
      'Senior citizen, person with disability and solo parent are each on your record or being checked. The MSWDO can tell you how to renew an ID.';

  @override
  String get sectorsInPerson =>
      'This page shows senior citizen, person with disability and solo parent. Other sectors are recorded by the MSWDO in person and are not shown here.';

  @override
  String get sectorsLoading => 'Loading your sectors';

  @override
  String get sectorsRecorded => 'Recorded';

  @override
  String get sectorsBeingChecked => 'Being checked';

  @override
  String get sectorsReturned => 'Returned';

  @override
  String get sectorsLapsed => 'ID expired';

  @override
  String get sectorsLabelSenior => 'Senior citizen';

  @override
  String get sectorsLabelPwd => 'Person with disability';

  @override
  String get sectorsLabelSoloParent => 'Solo parent';

  @override
  String get sectorsOfferSenior =>
      '60 and over · your Senior Citizen ID or birth certificate';

  @override
  String get sectorsOfferPwd => 'Your PWD ID from the PDAO';

  @override
  String get sectorsOfferSoloParent => 'Your Solo Parent ID';

  @override
  String get sectorsChoiceSenior =>
      'For residents 60 and over. Have your Senior Citizen ID or birth certificate ready.';

  @override
  String get sectorsChoicePwd => 'Have your PWD ID from the PDAO ready.';

  @override
  String get sectorsChoiceSoloParent => 'Have your Solo Parent ID ready.';

  @override
  String sectorsSince(String date) {
    return 'Since $date';
  }

  @override
  String sectorsIdEnding(String lastFour) {
    return 'ID ending $lastFour';
  }

  @override
  String sectorsValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get sectorsYouApplied => 'You applied';

  @override
  String sectorsYouAppliedOn(String date) {
    return 'You applied $date';
  }

  @override
  String get sectorsReturnedNoReason =>
      'The office returned it. You can apply again.';

  @override
  String sectorsOfficeSaid(String reason) {
    return 'The office said: $reason';
  }

  @override
  String get sectorsChooseSubtitle =>
      'Choose the sector that fits you. You\'ll add a photo of your ID next.';

  @override
  String get sectorsSector => 'Sector';

  @override
  String sectorsProofTitle(String idName) {
    return 'Add your $idName';
  }

  @override
  String get sectorsProofSubtitle =>
      'MSWDO staff check it against their records before the sector is added.';

  @override
  String get sectorsPhotoLabel => 'Photo of the ID';

  @override
  String get sectorsAddPhoto => 'Add a photo';

  @override
  String sectorsPhotoAdded(String size) {
    return 'Photo added · $size';
  }

  @override
  String get sectorsPhotoNote =>
      'Taytay LGU staff look at this photo to record your sector. Take it in good light, with the whole ID in the frame.';

  @override
  String get sectorsConfirmLabel => 'This ID is mine';

  @override
  String get sectorsConfirmDescription =>
      'I am sending it so Taytay LGU can record this sector on my profile.';

  @override
  String get sectorsSend => 'Send for checking';

  @override
  String get sectorsSourceTitle => 'Add the photo';

  @override
  String get sectorsNoSource =>
      'This phone cannot add a photo here. The MSWDO can record the sector at the municipal hall.';

  @override
  String get sectorsSentTitle => 'Application sent';

  @override
  String sectorsSentSubtitle(String sector) {
    return '$sector · Bayan ng Taytay';
  }

  @override
  String get sectorsSentAt => 'Sent';

  @override
  String get sectorsNextHeading => 'What happens next';

  @override
  String get sectorsStepSent => 'Sent to the MSWDO';

  @override
  String get sectorsStepCheck => 'Staff check your ID';

  @override
  String get sectorsStepCheckDetail =>
      'They may ask for a clearer photo. You will get a notice in this app when they decide.';

  @override
  String get sectorsStepAdded => 'Added to your profile';

  @override
  String get sectorsStepAddedDetail =>
      'Then it shows as recorded on Sectors and benefits.';

  @override
  String get sectorsBackToSectors => 'Back to Sectors and benefits';

  @override
  String get sectorsGoHome => 'Go to Home';

  @override
  String get sectorsUnconfirmed =>
      'We could not confirm that your application arrived. Before you send it again, open Sectors and benefits: if it shows as being checked, it arrived.';

  @override
  String get sectorsOffline =>
      'Nothing was sent. Your choice and photo are still here on the phone. Connect to the internet and send again.';

  @override
  String get sectorsRefusedTitle => 'The photo was not accepted';

  @override
  String get sectorsRefused =>
      'Nothing was sent. Choose a clearer JPEG or PNG photo of the ID, up to 5 MB, and send again.';

  @override
  String get sectorsWaitingTitle => 'Already on your record or being checked';

  @override
  String get sectorsWaiting =>
      'Nothing new was sent. This sector is already on your record, or an application for it is with the MSWDO. Sectors and benefits shows which.';

  @override
  String get sectorsNotOpenTitle => 'Not available for this account';

  @override
  String get sectorsNotOpen =>
      'Nothing was sent. Applying for a sector is open to verified residents. The municipal hall can tell you more.';

  @override
  String get sectorsFailedSendTitle => 'Not sent';

  @override
  String get sectorsFailedSend =>
      'Nothing was sent. Something went wrong on our side. Try again in a little while.';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsScopeSemantics => 'Show events';

  @override
  String get eventsScopeUpcoming => 'Upcoming';

  @override
  String get eventsScopeRegistered => 'Registered';

  @override
  String get eventsScopePast => 'Past';

  @override
  String get eventsUnavailableTitle => 'Events are not available right now';

  @override
  String get eventsUnavailableBody =>
      'We could not reach Taytay LGU. Check your connection and try again. Event notices are also posted at the municipal hall and barangay halls.';

  @override
  String get eventsEmptyUpcomingTitle => 'Nothing scheduled right now';

  @override
  String get eventsEmptyRegisteredTitle =>
      'You have not registered for anything';

  @override
  String get eventsEmptyPastTitle => 'No past events to show';

  @override
  String get eventsEmptyUpcomingBody =>
      'New Taytay LGU events will appear here when they are announced.';

  @override
  String get eventsEmptyRegisteredBody =>
      'Events you register for will appear here.';

  @override
  String get eventsEmptyPastBody =>
      'Events that have finished will appear here.';

  @override
  String get eventsLoadMoreFailed => 'Could not load more. ';

  @override
  String get eventsSeenStillHere => 'What you have already seen is still here.';

  @override
  String get eventsLoadingMore => 'Loading more events';

  @override
  String get eventsLoadMore => 'Load more';

  @override
  String get eventsListEnd => 'That is everything Taytay LGU has listed here.';

  @override
  String eventsPlacesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places left',
      one: '1 place left',
    );
    return '$_temp0';
  }

  @override
  String get eventsLoading => 'Loading events';

  @override
  String get eventsCalledOff => 'Called off by Taytay LGU';

  @override
  String get eventsStateNotRequired => 'No registration needed';

  @override
  String get eventsStateNotOpen => 'Registration not open yet';

  @override
  String get eventsStateOpen => 'Registration open';

  @override
  String get eventsStateRegistered => 'You are registered';

  @override
  String get eventsStateWaitlisted => 'You are on the waitlist';

  @override
  String get eventsStateCancelled => 'You cancelled your place';

  @override
  String get eventsStateFull => 'Fully booked';

  @override
  String get eventsStateClosed => 'Registration closed';

  @override
  String get eventsStateUnknown => 'Ask the office about registering';

  @override
  String get eventsGiveUpTitle => 'Give up your place?';

  @override
  String get eventsGiveUpConsequence =>
      'Taytay LGU will offer your place to the next person waiting. If you change your mind you will have to register again, and the event may be full by then.';

  @override
  String get eventsGiveUpConfirm => 'Give up my place';

  @override
  String get eventsGiveUpKeep => 'Keep my place';

  @override
  String get eventsGiveUpDone =>
      'Your place has been given up. Taytay LGU has been told.';

  @override
  String get eventsGiveUpUnconfirmed =>
      'We could not confirm that your place was given up. Trying again is safe: it will not be done twice.';

  @override
  String get eventsGiveUpTooLate =>
      'Your place can no longer be given up in the app. Contact Taytay LGU if you cannot go.';

  @override
  String eventsGiveUpFailedStillHeld(String message) {
    return '$message You still have your place.';
  }

  @override
  String get eventsMapRefused => 'That map link could not be opened safely.';

  @override
  String get eventsMapNoApp => 'No app on this device can open a map.';

  @override
  String get eventsEventTitle => 'Event';

  @override
  String get eventsOpening => 'Opening event…';

  @override
  String get eventsCalledOffBody =>
      'Taytay LGU has called this event off. It will not take place as listed. Ask the office if you have questions.';

  @override
  String get eventsOpenDirections => 'Open directions';

  @override
  String get eventsShareEvent => 'Share this event';

  @override
  String get eventsRegisteredNotice =>
      'Taytay LGU has your registration for this event. Bring a valid ID.';

  @override
  String get eventsFactWhen => 'When';

  @override
  String get eventsFactWhere => 'Where';

  @override
  String get eventsFactOrganiser => 'Organised by';

  @override
  String get eventsFactQuestions => 'Questions';

  @override
  String get eventsWhoCanJoin => 'Who can join';

  @override
  String get eventsWhoCanRegister => 'Who can register';

  @override
  String get eventsWhatToBring => 'What to bring';

  @override
  String get eventsRegisterForEvent => 'Register for this event';

  @override
  String get eventsLguDecides =>
      'Taytay LGU decides whether a place is available.';

  @override
  String get eventsReference => 'Reference';

  @override
  String get eventsWaitlistPosition => 'Waitlist position';

  @override
  String get eventsAttended => 'Taytay LGU recorded you as having attended.';

  @override
  String get eventsAbsent =>
      'Taytay LGU did not record you as attending. If that is wrong, contact the office.';

  @override
  String get eventsAttendanceNotRecorded =>
      'Attendance for this event has not been recorded yet.';

  @override
  String eventsCapacityOfTotal(int remaining, int total) {
    return '$remaining of $total places left';
  }

  @override
  String eventsCapacityLeft(int remaining) {
    return '$remaining places left';
  }

  @override
  String get eventsCapacityNone => 'No places left';

  @override
  String eventsCapacityRoomFor(int total) {
    return 'Room for $total people';
  }

  @override
  String get eventsCapacityTitle => 'Places';

  @override
  String eventsCapacityFull(String line) {
    return '$line. The office can tell you whether a waitlist is open.';
  }

  @override
  String get eventsOpenToVerified =>
      'Residents whose ID Taytay LGU has verified. Verifying takes a few steps and only has to be done once.';

  @override
  String get eventsOpenToAccounts =>
      'Anyone signed in to the app. You do not need a verified ID to register for this event.';

  @override
  String get eventsNotAvailableTitle => 'This event is not available';

  @override
  String get eventsSeeAll => 'See all events';

  @override
  String get eventsOpeningForm => 'Opening the registration form…';

  @override
  String get eventsRegistrationNotSwitchedOn =>
      'Registering in this app is not switched on yet. The Taytay office running this event can tell you how to join.';

  @override
  String get eventsRegisteringYou => 'Registering you…';

  @override
  String get eventsRegister => 'Register';

  @override
  String get eventsBlockedAlreadyTitle => 'You are already registered';

  @override
  String get eventsBlockedAlreadyBody =>
      'Taytay LGU has your place for this event. Your reference is on the event page.';

  @override
  String get eventsBackToEvent => 'Back to the event';

  @override
  String get eventsBlockedVerifyTitle => 'This event needs a verified account';

  @override
  String get eventsBlockedVerifyBody =>
      'Taytay LGU asks for a confirmed identity before registering for this one. Verifying takes a few steps and only has to be done once.';

  @override
  String get eventsBlockedUnsupportedTitle =>
      'This registration needs the office';

  @override
  String get eventsBlockedUnsupportedBody =>
      'Taytay LGU has added something to this form that this version of the app cannot show. Updating the app may help. Until then the office running the event can register you in person.';

  @override
  String get eventsBlockedNotOpenTitle => 'Registration is not open';

  @override
  String get eventsBlockedNotOpenBody =>
      'Taytay LGU is not taking registrations for this event right now.';

  @override
  String get eventsRegistrationSubtitle => 'Event registration';

  @override
  String get eventsStepConfirm => 'Confirm your registration';

  @override
  String get eventsStepQuestions => 'Questions from the office';

  @override
  String get eventsStepConsent => 'Before you register';

  @override
  String get eventsStepSubmitting => 'Registering';

  @override
  String get eventsStepOutcome => 'Your registration';

  @override
  String get eventsRegisteringFor => 'You are registering for';

  @override
  String get eventsFiledAgainstAccount =>
      'This registration will be filed against the account you are signed in with.';

  @override
  String get eventsFromTheOffice => 'From the office';

  @override
  String get eventsLguDecidesNextScreen =>
      'Taytay LGU decides whether a place is available. You will see the answer on the next screen.';

  @override
  String get eventsAnswerYes => 'Yes';

  @override
  String get eventsAnswerNo => 'No';

  @override
  String eventsConsentOptional(String label) {
    return '$label (optional)';
  }

  @override
  String get eventsOutcomeFullTitle => 'This event is full';

  @override
  String get eventsOutcomeClosedTitle => 'Registration has closed';

  @override
  String get eventsOutcomeRefusedTitle => 'Taytay LGU could not register you';

  @override
  String get eventsOutcomeUnconfirmedTitle => 'Registration not confirmed';

  @override
  String get eventsOutcomeNotRegisteredTitle => 'Not registered';

  @override
  String eventsWaitlistNumber(int position) {
    return 'You are number $position on the waitlist.';
  }

  @override
  String eventsQuoteRequestId(String requestId) {
    return 'If you contact the office, quote $requestId.';
  }

  @override
  String get eventsCannotRegisterHere => 'You cannot register here yet';

  @override
  String get eventsOutcomeRegisteredBody =>
      'Taytay LGU has your place. Quote your reference at the door.';

  @override
  String get eventsOutcomeWaitlistedBody =>
      'Taytay LGU has you on the waitlist. The office moves people up when a place opens, and you will see a notice in the app if it does.';

  @override
  String get eventsOutcomeFullBody =>
      'Every place was taken before your registration arrived, and this event keeps no waitlist. Nothing was registered.';

  @override
  String get eventsOutcomeClosedBody =>
      'Registration for this event closed before your registration arrived. Nothing was registered.';

  @override
  String get eventsRefusedNeedsVerification =>
      'This event takes registrations from verified accounts. Verify your account first, then register.';

  @override
  String get eventsRefusedNotAllowed =>
      'Event registration is not available for this account in the app.';

  @override
  String get eventsRefusedNotListed =>
      'This event is no longer listed, so Taytay LGU could not take a registration for it.';

  @override
  String get eventsRefusedNotTaking =>
      'Taytay LGU is not taking registrations for this event right now. The event page says whether registration opens later.';

  @override
  String get eventsRefusedNotAccepted =>
      'Taytay LGU could not accept this registration as it was sent. If it happens again, quote the reference below to the office.';

  @override
  String get eventsRegistrationUnconfirmed =>
      'We could not confirm that your registration was received. Trying again is safe: you will not be registered twice.';

  @override
  String eventsRegistrationNotSent(String message) {
    return 'We could not send your registration, so nothing was registered. $message';
  }

  @override
  String get balitaAdvisoriesTitle => 'Advisories';

  @override
  String get balitaFilteredSubtitle => 'Balita · filtered';

  @override
  String get balitaLoading => 'Loading Balita';

  @override
  String get balitaUnavailableTitle =>
      'Announcements are not available right now';

  @override
  String get balitaUnavailableBody =>
      'We could not reach Taytay LGU. Check your connection and try again. Municipal notices are also posted at the municipal hall and barangay halls.';

  @override
  String get balitaEmptyTitle => 'Nothing new right now';

  @override
  String get balitaEmptyBody =>
      'New Taytay LGU announcements will appear here.';

  @override
  String get balitaFilterSemantics => 'Filter Balita';

  @override
  String get balitaLatest => 'Latest Balita';

  @override
  String balitaShareArticle(String title) {
    return 'Share $title';
  }

  @override
  String get balitaShare => 'Share';

  @override
  String get balitaEmergencyAdvisory => 'Emergency advisory';

  @override
  String get balitaPinnedAdvisory => 'Pinned advisory';

  @override
  String get balitaEmptyEventsBody =>
      'No upcoming municipal events have been posted. We\'ll notify you when the LGU announces one.';

  @override
  String balitaEmptyCategoryBody(String category) {
    return 'No $category posts have been published yet.';
  }

  @override
  String get balitaSeeAll => 'See all Balita';

  @override
  String get balitaShareFooter => 'From Taytay LGU';

  @override
  String get balitaShareCopied => 'Copied. You can paste this into any app.';

  @override
  String get balitaShareUnavailable =>
      'Sharing is not available on this device.';

  @override
  String get balitaLoadingArticle => 'Loading the announcement';

  @override
  String get balitaArticleNotAvailable => 'This announcement is not available';

  @override
  String get balitaSeeAllAnnouncements => 'See all announcements';

  @override
  String get inboxTitle => 'Notifications';

  @override
  String get inboxLoading => 'Loading notifications';

  @override
  String get inboxEmptyTitle => 'Nothing yet';

  @override
  String get inboxEmptyBody =>
      'Updates about your requests, documents and events will appear here.';

  @override
  String get inboxEarlier => 'Earlier';

  @override
  String get inboxEyebrowUpdate => 'Update';

  @override
  String get inboxLoadMoreFailed => 'Could not load more';

  @override
  String get inboxLoadingOlder => 'Loading older';

  @override
  String get inboxLoadOlder => 'Load older';

  @override
  String get inboxFilterAll => 'All';

  @override
  String inboxFilterUnread(int count) {
    return 'Unread · $count';
  }

  @override
  String get inboxMarkAllRead => 'Mark all read';

  @override
  String get inboxUnread => 'Unread';

  @override
  String get inboxSettingsTitle => 'Notification settings';

  @override
  String get inboxSettingsLoading => 'Loading notification settings';

  @override
  String get inboxSaveUnconfirmedTitle => 'Your change may not have been saved';

  @override
  String get inboxSaveUnconfirmedBody =>
      'We could not confirm it. The switch shows your setting before the change. Setting it again is safe.';

  @override
  String get inboxSaveFailedTitle => 'That change was not saved';

  @override
  String get inboxSaveFailedBody =>
      'Your setting is unchanged. Check your connection and try again.';

  @override
  String get inboxSettingsIntro => 'Choose what Taytay LGU tells you about.';

  @override
  String get inboxAlwaysSentTitle => 'Always sent';

  @override
  String get inboxAlwaysSentBody =>
      'Public advisories and messages about your account and security are always sent. They are how Taytay LGU reaches you in an emergency, or tells you if somebody signs in as you.';

  @override
  String get dirOfficeDetails => 'Office details';

  @override
  String get dirOfficeNotShownTitle => 'This office could not be shown';

  @override
  String get dirOfficeNotShownBody =>
      'Taytay LGU could not be reached, or the office is no longer listed. You can try again.';

  @override
  String get dirLoadingOffice => 'Loading the office';

  @override
  String get dirSearchTitle => 'Search';

  @override
  String get dirMunicipalOffices => 'Municipal offices';

  @override
  String get dirNotifications => 'Notifications';

  @override
  String get dirSearchHint => 'Search offices or services';

  @override
  String get dirCategory => 'Category';

  @override
  String get dirChipAll => 'All';

  @override
  String get dirNoOfficesInCategory => 'No offices in this category';

  @override
  String dirNoOfficesFound(String query) {
    return 'No offices found for “$query”';
  }

  @override
  String get dirTryAnotherWord => 'Try another word, or browse by category.';

  @override
  String get dirBrowseAll => 'Browse all offices';

  @override
  String dirOfficeCountNoun(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'offices',
      one: 'office',
    );
    return '$_temp0';
  }

  @override
  String get dirLoadingDirectory => 'Loading the directory';

  @override
  String get dirCantLoadTitle => 'Can\'t load the directory';

  @override
  String get dirCantLoadBody =>
      'Check your mobile data or Wi-Fi, then try again. Saved office numbers are listed below.';

  @override
  String get dirSavedOnPhone => 'Saved on this phone';

  @override
  String get dirOfflineTitle => 'You\'re offline';

  @override
  String get dirOfflineShowingSaved => 'Showing what was saved on this phone';

  @override
  String dirCallName(String name) {
    return 'Call $name';
  }

  @override
  String get dirRepresentativePhoto => 'Representative photo';

  @override
  String dirRepresentativePhotoCredit(String credit) {
    return 'Representative photo · $credit';
  }

  @override
  String get dirActionCall => 'Call';

  @override
  String get dirActionDirections => 'Directions';

  @override
  String get dirActionMessage => 'Message';

  @override
  String get dirActionApp => 'App';

  @override
  String get dirFactLocation => 'Location';

  @override
  String get dirFactHours => 'Office hours';

  @override
  String get dirFactPhone => 'Phone';

  @override
  String get dirFactEmail => 'Email';

  @override
  String get dirFactHead => 'Head';

  @override
  String get dirServices => 'Services';

  @override
  String get dirNewMessage => 'New message';

  @override
  String get dirOfficeDidNotLoadTitle => 'This office did not load';

  @override
  String get dirOfficeDidNotLoadBody =>
      'Try again, or go back to the directory.';

  @override
  String get dirTopic => 'Topic';

  @override
  String dirTopicValue(String topic) {
    return 'Topic, $topic';
  }

  @override
  String get dirGeneralTopic => 'General enquiry';

  @override
  String get dirFieldMessage => 'Message';

  @override
  String get dirMessageHint => 'Write your message';

  @override
  String get dirSendMessage => 'Send message';

  @override
  String get dirPrivacyWarning =>
      'Don’t share passwords or one-time codes in a message.';

  @override
  String get dirTo => 'To';

  @override
  String get dirAttach => 'Attach photo or PDF (optional)';

  @override
  String get dirEmergencyHeading => 'For emergencies don\'t wait for a reply';

  @override
  String get dirEmergencyBody => 'Call an emergency hotline.';

  @override
  String dirEmergencyCallLine(String name, String number) {
    return 'Call $name: $number.';
  }

  @override
  String get dirSeeHotlines => 'See emergency hotlines';

  @override
  String get dirLoadingHotline => 'Loading the emergency hotline';

  @override
  String get dirMessageSentTitle => 'Message sent';

  @override
  String get dirMessageSentBody =>
      'We\'ll notify you, and the conversation is saved in My Account › Messages.';

  @override
  String get dirGoToMessages => 'Go to Messages';

  @override
  String get dirBackToDirectory => 'Back to Directory';

  @override
  String get dirConversation => 'Conversation';

  @override
  String get dirCannotAttach => 'This phone cannot attach a file.';

  @override
  String get dirWriteBeforeSending => 'Write a message before sending.';

  @override
  String get dirNoDialer => 'This phone has no app that can place a call.';

  @override
  String get tulongSubtitle => 'Social services & programmes';

  @override
  String get tulongSubtitleMswdo => 'Social services · MSWDO';

  @override
  String get tulongNoteInformationOnly =>
      'Information on municipal programmes. These are information pages, not applications.';

  @override
  String get tulongNoteSomeApply =>
      'Information on municipal programmes. Some pages also take applications in the app: open a page to see whether it does.';

  @override
  String get tulongStaleHeading => 'Couldn\'t refresh the list';

  @override
  String tulongStaleMessage(String timestamp) {
    return 'Showing the list from $timestamp. It may have changed.';
  }

  @override
  String tulongIncomplete(int shown) {
    return 'Taytay LGU lists more programmes than this app loads. This list and the search cover the first $shown only.';
  }

  @override
  String get tulongSearchHint => 'Search programmes';

  @override
  String get tulongLoading => 'Loading programmes';

  @override
  String get tulongTryingAgain => 'Trying again…';

  @override
  String get tulongNoMatchTitle => 'No programmes match that search.';

  @override
  String get tulongNoMatchBody =>
      'Try another word, or clear the search to see every programme.';

  @override
  String get tulongEmptyTitle => 'No programmes listed yet';

  @override
  String get tulongEmptyBody =>
      'Programme information from Taytay LGU will appear here.';

  @override
  String get tulongOfflineTitle => 'Programme pages need a connection';

  @override
  String get tulongOfflineBody =>
      'We couldn\'t load the latest programme information.';

  @override
  String get tulongOfflineBodySaved =>
      'We couldn\'t load the latest programme information. Pages you opened before are saved below.';

  @override
  String get tulongSavedPages => 'Saved pages';

  @override
  String get tulongWhoCanAvail => 'Who can avail';

  @override
  String get tulongRequirements => 'Requirements';

  @override
  String get tulongInformationOnly => '(information only)';

  @override
  String get tulongHowToClaim => 'How to claim';

  @override
  String get tulongSchedule => 'Schedule';

  @override
  String get tulongQuestions => 'Questions';

  @override
  String get tulongShare => 'Share with a family member';

  @override
  String get tulongFactOffice => 'Office';

  @override
  String get tulongFactHours => 'Hours';

  @override
  String get tulongContactLandline => 'Landline';

  @override
  String get tulongContactHotline => 'Hotline';

  @override
  String get tulongContactEmail => 'Email';

  @override
  String get tulongContactMobile => 'Mobile';

  @override
  String get tulongContactOther => 'Contact';

  @override
  String get tulongNoPhone => 'This office has not published a phone number.';

  @override
  String get tulongNoCalling => 'Calling is not available on this device.';

  @override
  String get tulongNoAddress => 'This office has not published an address.';

  @override
  String get tulongNoMaps => 'Maps could not be opened on this device.';

  @override
  String get tulongNoOffice => 'This programme is not linked to an office.';

  @override
  String get tulongShareSignature => 'From Taytay LGU';

  @override
  String get tulongCopied => 'Copied. You can paste this into any app.';

  @override
  String get tulongNoSharing => 'Sharing is not available on this device.';

  @override
  String get tulongNotAvailableTitle => 'This programme is not available';

  @override
  String get tulongNotAvailableBody =>
      'Go back to Tulong to see the programmes listed now.';

  @override
  String get tulongCheckConnection => 'Check your connection and try again.';

  @override
  String get tulongLoadingOne => 'Loading programme';

  @override
  String get homeGuestTitle => 'Browsing as guest';

  @override
  String get homeGuestBody => 'Sign up to message offices.';

  @override
  String get homeNotVerifiedTitle => 'Not yet verified';

  @override
  String get homeNotSentBody =>
      'No ID has been sent yet. Send one in the app, or verify in person at the MSWDO. Messaging offices unlocks once verified.';

  @override
  String get homePendingTitle => 'Verification pending';

  @override
  String get homePendingBody =>
      'Taytay LGU is reviewing your ID. Messaging offices unlocks once verified.';

  @override
  String get homeRejectedTitle => 'Your ID was not accepted';

  @override
  String get homeRejectedBody =>
      'See what to fix and send it again, or verify in person at the MSWDO. Messaging offices unlocks once verified.';

  @override
  String get homeUnlocksOnceVerified =>
      'Messaging offices unlocks once verified.';

  @override
  String get homeFixAction => 'See what to fix';

  @override
  String get homeStatusAction => 'Verification status';

  @override
  String get homeCreateAccount => 'Create account';

  @override
  String get homeLoadingStories => 'Loading featured stories';

  @override
  String get homeLatestBalita => 'Latest Balita';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeLoadingBalita => 'Loading Balita';

  @override
  String get homeEmergency => 'Emergency';

  @override
  String get homeAllHotlines => 'All hotlines';

  @override
  String homeNotificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get homeUpdating => 'Updating Balita and advisories…';

  @override
  String get homeHotlines => 'Hotlines';

  @override
  String get homeEvents => 'Events';

  @override
  String get homeReadBalita => 'Read Balita';

  @override
  String get homeExploreTulong => 'Explore Tulong';

  @override
  String get homeOpenDirectory => 'Open Directory';

  @override
  String get homeSeeHotlines => 'See hotlines';

  @override
  String get homeSeeEvents => 'See events';

  @override
  String get homeOpen => 'Open';

  @override
  String get homeHotlinesTitle => 'Emergency hotlines';

  @override
  String get homeLoadingHotlines => 'Loading hotlines';

  @override
  String get homeNoHotlinesTitle => 'No hotlines to show';

  @override
  String get homeNoHotlinesBody =>
      'Taytay LGU has not published any hotlines here yet.';

  @override
  String get homeHotlinesMunicipal => 'Municipal';

  @override
  String get homeHotlinesSource =>
      'Source: Taytay LGU / Taytay Public Information Office.';

  @override
  String get coreFailureTimeout =>
      'The request is taking longer than expected. Please try again.';

  @override
  String get coreFailureUnauthenticated =>
      'Your session has ended. Please sign in again to continue.';

  @override
  String get coreFailureForbidden =>
      'This service is not available for your account right now.';

  @override
  String get coreFailureVerificationRequired =>
      'Verify your account first to use this service.';

  @override
  String get coreFailureBiometricConsent =>
      'Nothing was sent. A selfie needs your consent to the selfie text Taytay LGU publishes now. Agree to it, or verify in person.';

  @override
  String get coreFailureValidation =>
      'Please check the highlighted details and try again.';

  @override
  String get coreFailureConflict =>
      'This was already submitted. Refresh to see the latest status.';

  @override
  String get coreFailureInvalidStateTransition =>
      'This request has already moved forward. Refresh to see its current status.';

  @override
  String get coreFailureBarangayHeldByOffice =>
      'Your account is verified, so your barangay is changed at the MSWDO office. To change your barangay, visit the MSWDO office with proof of your new address.';

  @override
  String coreFailureRateLimitedFor(int seconds) {
    return 'Too many attempts. Please try again in $seconds seconds.';
  }

  @override
  String get coreFailureServiceUnavailable =>
      'The service is temporarily unavailable. Please try again shortly.';

  @override
  String get coreFailureServer =>
      'Something went wrong on our side. Please try again.';

  @override
  String get coreFailureContract =>
      'We could not read the response from the server. Please try again.';

  @override
  String get coreFailureUnexpected =>
      'Something went wrong. Please try again, or contact the LGU if it keeps happening.';

  @override
  String get coreFailureFileTooLarge =>
      'That file is too large to send. Try a smaller photo or a lower quality setting.';

  @override
  String get coreFailureCodeInvalid => 'That code was not accepted.';

  @override
  String get coreFailureCodeExpired =>
      'That code has expired. Request a new one.';

  @override
  String get coreFailureCodeLocked =>
      'Too many attempts. Please wait before requesting another code.';

  @override
  String get coreSignInCredentialsRejected =>
      'Incorrect email or password. 2 attempts left before a 15-minute pause.';

  @override
  String get coreSignInPasswordNeedsEmail =>
      'Use your email to sign in with a password, or get a code sent to your mobile.';

  @override
  String get coreDeepLinkUnavailable =>
      'That link could not be opened. It may be for a newer version of the app, or the item may no longer be available.';

  @override
  String get coreDeepLinkActionRefused =>
      'That link tried to do something on your behalf. Taytay LGU IDS never acts from a link — open the item and choose for yourself.';

  @override
  String get coreRouteNotFoundTitle => 'Page not found';

  @override
  String get coreRouteNotFoundBody =>
      'That link does not lead anywhere in this app.';

  @override
  String get coreRouteGoHome => 'Go to home';

  @override
  String get coreAppLockEnableReason =>
      'Confirm it is you before turning on the app lock';

  @override
  String get coreAppLockUnlockReason => 'Unlock Taytay LGU IDS';

  @override
  String get coreSealSemanticLabel =>
      'Seal of the Municipality of Taytay, Rizal';

  @override
  String get corePhotoMunicipalHall => 'Photo: Taytay Municipal Hall';

  @override
  String get corePhotoTiangge => 'Photo: Taytay Tiangge';

  @override
  String get corePhotoParishChurch =>
      'Photo: St. John the Baptist Parish Church';

  @override
  String get sharedBiometricDialogTitle => 'Your consent before a selfie';

  @override
  String get sharedBiometricWhatHeading => 'What the app collects, and why';

  @override
  String get sharedBiometricWhat =>
      'A selfie: a photo of your face. Taytay LGU staff compare it with the photo on your ID to confirm that this account is yours, and it is the photo on your Taytay digital ID once you are verified. A photo of a face used to confirm who someone is counts as biometric data, so the app asks for your consent before the camera opens.';

  @override
  String get sharedBiometricTextHeading => 'The consent Taytay LGU published';

  @override
  String sharedBiometricVersion(String version) {
    return 'Version $version';
  }

  @override
  String get sharedBiometricChoice =>
      'Agreeing is your choice. If you do not agree, you can still be verified in person, without a selfie. You can withdraw this consent at any time under Account, Consents and account requests; withdrawing erases your selfies.';

  @override
  String get sharedBiometricTick =>
      'I agree that Taytay LGU may take and use my selfie as described above.';

  @override
  String get sharedBiometricAgree => 'Agree and continue';

  @override
  String get sharedBiometricRecording => 'Recording your consent…';

  @override
  String get sharedBiometricDecline => 'No, I\'ll verify in person';

  @override
  String get sharedBiometricUnavailableHeading =>
      'Selfie verification is not available yet';

  @override
  String get sharedBiometricUnavailable =>
      'Taytay LGU has not yet published the consent the app needs before it can take a selfie, so no selfie can be sent for now. Your account works without it.';

  @override
  String get sharedBiometricInPersonHeading => 'Verify in person';

  @override
  String get sharedBiometricInPerson =>
      'Bring a valid ID to the MSWDO. Staff check it and verify your account. No selfie is taken.';

  @override
  String sharedBiometricInPersonHours(String hours) {
    return 'Hours: $hours';
  }

  @override
  String sharedBiometricInPersonPhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get sharedBiometricDeclinedHeading => 'No selfie was taken';

  @override
  String get sharedBiometricDeclined =>
      'You did not agree to the selfie consent, and that is fine. Nothing was recorded or sent.';

  @override
  String get sharedBiometricFailedHeading =>
      'Could not check the selfie consent';

  @override
  String get sharedBiometricFailed =>
      'No selfie can be taken until the app knows where your consent stands. Check your connection and try again.';

  @override
  String get sharedBiometricNotRecorded =>
      'Your consent was not recorded, so no selfie was taken. You can try again.';

  @override
  String get sharedBiometricNotConfirmed =>
      'We could not confirm that your consent was recorded, so no selfie was taken yet. Trying again is safe: it is recorded only once.';

  @override
  String get sharedBiometricWithdrawEffects =>
      'Withdrawing erases every selfie you sent, in the same moment. A verification request still waiting for review then needs a new selfie before staff can approve it, and a Taytay digital ID loses its photo. What was already done stays as it is: a withdrawal is not backdated.';

  @override
  String get sharedBiometricWithdrawButton => 'Withdraw the selfie consent';

  @override
  String get sharedBiometricWithdrawTitle => 'Withdraw the selfie consent?';

  @override
  String get sharedBiometricWithdrawConfirm => 'Withdraw and erase my selfies';

  @override
  String get sharedBiometricWithdrawCancel => 'Keep my consent';

  @override
  String get sharedTermsNotPublishedYet =>
      'The full Terms of Use will be available soon. Taytay LGU has not published them in the app yet.';

  @override
  String get sharedPrivacyNoticeNotPublishedYet =>
      'The full Privacy Notice will be available soon. Taytay LGU has not published it in the app yet.';

  @override
  String get sharedTermsConsentLabel =>
      'I have read and agree to the Terms of Use.';

  @override
  String get sharedPrivacyConsentLabel =>
      'I have read the Privacy Notice and understand how Taytay LGU uses my personal data.';

  @override
  String sharedLegalTextLoading(String title) {
    return 'Loading $title';
  }

  @override
  String get sharedBarangayPickerTitle => 'Choose your barangay';

  @override
  String get sharedBarangayPickerLoading => 'Loading barangays';

  @override
  String get sharedBarangayPickerEmpty =>
      'No barangays are listed yet. Please try again later.';

  @override
  String get sharedBarangayPickerFailed =>
      'We could not load the list of barangays. Check your connection and try again.';

  @override
  String get sharedHoursOpen => 'Open';

  @override
  String get sharedHoursClosed => 'Closed';

  @override
  String sharedHoursCloses(String time) {
    return 'Closes $time';
  }

  @override
  String sharedHoursOpensToday(String time) {
    return 'Opens $time today';
  }

  @override
  String sharedHoursOpensTomorrow(String time) {
    return 'Opens $time tomorrow';
  }

  @override
  String sharedHoursOpensOn(String time, String weekday) {
    return 'Opens $time $weekday';
  }

  @override
  String get sharedWeekdayMonday => 'Monday';

  @override
  String get sharedWeekdayTuesday => 'Tuesday';

  @override
  String get sharedWeekdayWednesday => 'Wednesday';

  @override
  String get sharedWeekdayThursday => 'Thursday';

  @override
  String get sharedWeekdayFriday => 'Friday';

  @override
  String get sharedWeekdaySaturday => 'Saturday';

  @override
  String get sharedWeekdaySunday => 'Sunday';

  @override
  String sharedFormErrorSummaryHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'There are $count problems',
      one: 'There is a problem',
    );
    return '$_temp0';
  }

  @override
  String get sharedWhyWeAskTitle => 'Why we ask for this';

  @override
  String get sharedWhyWeAskWhy => 'Why';

  @override
  String get sharedWhyWeAskWhoSeesIt => 'Who sees it';

  @override
  String get sharedWhyWeAskIfYouDecline => 'If you would rather not';

  @override
  String get sharedNoteToneInfo => 'Information';

  @override
  String get sharedNoteToneWarning => 'Note';

  @override
  String get sharedNoteToneError => 'Error';

  @override
  String get sharedNoteToneSuccess => 'Done';

  @override
  String get sharedNoteToneEmergency => 'Emergency';

  @override
  String get sharedComposerHint => 'Write a message…';

  @override
  String get sharedComposerRemoveAttachment => 'Remove attachment';

  @override
  String get sharedComposerAttach => 'Attach photo or PDF';

  @override
  String get sharedComposerSend => 'Send';

  @override
  String get sharedDialogConfirm => 'Confirm';

  @override
  String get sharedConfirmKeepAsItIs => 'Keep it as it is';

  @override
  String get sharedConfirmWhatHappens => 'What happens';

  @override
  String get sharedBannerDismiss => 'Dismiss';

  @override
  String get sharedMessageFieldLabel => 'Message';

  @override
  String sharedBadgeNew(int count) {
    return '$count new';
  }

  @override
  String get sharedOfflineMessage =>
      'Taytay LGU could not be reached. Check your connection and try again.';

  @override
  String get sharedSampleTag => 'SAMPLE';

  @override
  String get sharedIllustrationLabelPrefix => 'Illustration:';

  @override
  String get sharedIllustrationEmpty =>
      'Illustration: an empty tray, meaning there is nothing here yet.';

  @override
  String get sharedIllustrationError =>
      'Illustration: a disconnected link, meaning something could not be loaded.';

  @override
  String get sharedIllustrationSuccess =>
      'Illustration: a check mark, meaning the request was completed.';

  @override
  String get sharedConfigStopTitle =>
      'This build is not configured correctly and cannot start.';

  @override
  String get sharedConfigStopIconLabel => 'Configuration';
}
