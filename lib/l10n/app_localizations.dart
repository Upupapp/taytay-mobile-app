import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppStrings
/// returned by `AppStrings.of(context)`.
///
/// Applications need to include `AppStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppStrings.localizationsDelegates,
///   supportedLocales: AppStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppStrings.supportedLocales
/// property.
abstract class AppStrings {
  AppStrings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// The app's name. Not translated — it is the municipality's own identity.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU IDS'**
  String get appTitle;

  /// Shell destination: the resident's dashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Shell destination: the municipal service catalogue.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get navServices;

  /// Shell destination: LGU announcements.
  ///
  /// In en, this message translates to:
  /// **'Balita'**
  String get navNews;

  /// Shell destination: social welfare programmes.
  ///
  /// In en, this message translates to:
  /// **'Tulong'**
  String get navTulong;

  /// Shell destination: the resident's own account.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get navProfile;

  /// Retries whatever just failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Fetches the content again.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// Retries a submission that never reached the office.
  ///
  /// In en, this message translates to:
  /// **'Try sending again'**
  String get actionTrySendingAgain;

  /// Offline banner heading. Deliberately not 'you appear to be offline' — that is a guess about the resident's phone, where this is what the app actually knows.
  ///
  /// In en, this message translates to:
  /// **'Not reaching Taytay LGU'**
  String get networkUnreachableTitle;

  /// Offline banner body. Says only what the app knows about the connection and never what happened to a send: the failures that raise the banner include timeouts and connections that dropped after the request left the phone, which the office may already hold. Each send says for itself whether it went (D-188, D-189). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The app cannot get through right now. Anything you have typed is still here.'**
  String get networkUnreachableMessage;

  /// Heading for work the resident finished that the office has not confirmed it has. Never translate this as 'saved': a resident who reads 'saved' believes the office has it and stops chasing it. Not 'not sent' either: a send that timed out may have reached the office (D-188, D-191). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get unsentTitle;

  /// Body for work whose send failed. True whether the send never left the phone or its answer was lost, so it never says nothing was filed (D-188, D-191). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that Taytay LGU has {what}. Everything you typed is still on this phone.'**
  String unsentMessage(String what);

  /// Added after unsentMessage only when the send keeps its idempotency key for the retry, the one case where a second send cannot file twice (D-191). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sending it again is safe: it will not be filed twice.'**
  String get unsentResendSafe;

  /// Last-updated line over cached content. The timestamp is pre-formatted in Manila time by ManilaTime, so it is passed in as a string rather than a DateTime.
  ///
  /// In en, this message translates to:
  /// **'Showing what was saved on {timestamp}. It may have changed.'**
  String staleContentMessage(String timestamp);

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get failureNotFound;

  /// No description provided for @failureFileType.
  ///
  /// In en, this message translates to:
  /// **'That kind of file cannot be sent. Try a photo or a PDF instead.'**
  String get failureFileType;

  /// No description provided for @failureRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get failureRateLimited;

  /// Screen-reader hint on a control that is working.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get a11yLoading;

  /// Announced when an async action starts.
  ///
  /// In en, this message translates to:
  /// **'Working. Please wait.'**
  String get a11yBusy;

  /// Announced when an async action succeeds. A screen reader user gets no visual confirmation, so the outcome has to be spoken.
  ///
  /// In en, this message translates to:
  /// **'Done. {what}'**
  String a11ySucceeded(String what);

  /// Announced when an async action fails.
  ///
  /// In en, this message translates to:
  /// **'That did not work. {why}'**
  String a11yFailed(String why);

  /// Spoken alongside a required field's label, because an asterisk is not announced.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get a11yRequired;

  /// Prefix so a field's error is announced as an error rather than read as ordinary text.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String a11yFieldError(String message);

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update the app to continue'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of the Taytay LGU app is no longer supported. Please update it from your app store, then open it again.'**
  String get updateRequiredBody;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'The LGU system is down for maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and requests are safe. You can still browse services and programmes while this is going on. Please try again shortly.'**
  String get maintenanceBody;

  /// No description provided for @blockingNoticeSupport.
  ///
  /// In en, this message translates to:
  /// **'If you need help now'**
  String get blockingNoticeSupport;

  /// No description provided for @signInCodeSent.
  ///
  /// In en, this message translates to:
  /// **'If that number is registered with Taytay LGU, a code is on its way.'**
  String get signInCodeSent;

  /// No description provided for @signInCodeNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. Check the code and try again, or ask for a new one.'**
  String get signInCodeNotAccepted;

  /// No description provided for @signInTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a little while before trying again.'**
  String get signInTooManyAttempts;

  /// No description provided for @signInOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your internet connection and try again.'**
  String get signInOffline;

  /// No description provided for @signInTimedOut.
  ///
  /// In en, this message translates to:
  /// **'That took too long. Please try again.'**
  String get signInTimedOut;

  /// No description provided for @signInServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Signing in is temporarily unavailable. Please try again shortly.'**
  String get signInServiceUnavailable;

  /// No description provided for @signInUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again, or visit the Taytay municipal hall if it keeps happening.'**
  String get signInUnexpected;

  /// Shown when a chosen file is larger than the ceiling the API published. Both figures are real: the file, and the limit the server actually enforces.
  ///
  /// In en, this message translates to:
  /// **'That file is {actual} MB. Taytay LGU accepts up to {limit} MB. A photo taken in this app is usually small enough.'**
  String uploadRefusedTooLarge(int actual, int limit);

  /// Shown when a chosen file is a type the office does not accept.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU can only accept a photo (JPEG or PNG) or a PDF. Take a photo of the document if you have it on paper.'**
  String get uploadRefusedType;

  /// Shown when a chosen file has no contents.
  ///
  /// In en, this message translates to:
  /// **'That file is empty. Choose it again, or take a photo of the document instead.'**
  String get uploadRefusedEmpty;

  /// Shown when a file’s contents do not match the type it claims.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read as a photo or a PDF. Take a photo of the document instead.'**
  String get uploadRefusedUnreadable;

  /// Heading of the panel shown when onboarding is staff-mediated.
  ///
  /// In en, this message translates to:
  /// **'Accounts are made at the MSWDO office'**
  String get onboardingOfficeTitle;

  /// Body of the staff-mediated onboarding panel. Says what to do and what to bring.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU creates your account for you. Visit the Municipal Social Welfare and Development Office with a valid ID, and staff will register the mobile number you want to use. Then sign in here with that number.'**
  String get onboardingOfficeBody;

  /// Support line under the staff-mediated panel. Both values come from the server, never from a constant.
  ///
  /// In en, this message translates to:
  /// **'Ask the office: {email} · {phone}'**
  String onboardingOfficeContact(String email, String phone);

  /// Correction flow copy.
  ///
  /// In en, this message translates to:
  /// **'Which detail needs correcting?'**
  String get correctionWhichDetail;

  /// Correction flow copy.
  ///
  /// In en, this message translates to:
  /// **'This one cannot be corrected by message — bring the document to the MSWDO office, or upload it again when the office asks.'**
  String get correctionNotByMessage;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get fieldMiddleName;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Suffix (Jr., III)'**
  String get fieldSuffix;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fieldBirthDate;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get fieldSex;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Civil status'**
  String get fieldCivilStatus;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get fieldBarangay;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'House number and street'**
  String get fieldStreetAddress;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Purok or sitio'**
  String get fieldPurokOrSitio;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get fieldMobileNumber;

  /// Resident-facing label for a correctable profile field.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get fieldEmail;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'Your session ended'**
  String get sessionEndedTitle;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'For your security, Taytay LGU IDS signed you out on this device. This happens after a period of time, or when the LGU ends a session.'**
  String get sessionEndedBody;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'Anything you already sent is with the office. Anything you had typed and not yet sent is not kept on this phone — you will need to enter it again.'**
  String get sessionEndedUnsent;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get sessionEndedSignInAgain;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'Your session ended for your security. Please sign in again.'**
  String get signInNoticeExpired;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'You are signed out on this device. You can still browse Taytay services as a guest.'**
  String get signInNoticeSignedOut;

  /// Session-ending copy (TAB 06 / F22).
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to the page you opened. We will take you straight there.'**
  String get signInNoticeReturnTo;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Your account details'**
  String get profileSectionAccountTitle;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'You can change these yourself. They are how Taytay LGU contacts you.'**
  String get profileSectionAccountExplanation;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by Taytay LGU'**
  String get profileSectionLguTitle;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU checked these against your documents. They decide what you are entitled to, so only the LGU can change them.'**
  String get profileSectionLguExplanation;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profileFieldMobileNumber;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get profileFieldEmailAddress;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get profileFieldStreetAddress;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Purok or sitio'**
  String get profileFieldPurokOrSitio;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFieldFullName;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileFieldBirthDate;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get profileFieldSex;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Civil status'**
  String get profileFieldCivilStatus;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get profileFieldBarangay;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'How Taytay LGU sends your one-time codes and updates.'**
  String get profileHintMobileNumber;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Optional. Used for copies of what the LGU sends you.'**
  String get profileHintEmailAddress;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Your house number and street, as Taytay LGU has it.'**
  String get profileHintStreetAddress;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Optional. The purok or sitio within your barangay, if yours uses one.'**
  String get profileHintPurokOrSitio;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'As it appears on the ID you presented.'**
  String get profileHintFullName;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Decides age-based services such as senior citizen benefits.'**
  String get profileHintBirthDate;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'Decides which barangay office serves you.'**
  String get profileHintBarangay;

  /// Profile surface copy, localised in the C-13 follow-up.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String profileFieldOptionalSuffix(String label);

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get verifyStageNotStartedLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'You have not started verifying your identity yet.'**
  String get verifyStageNotStartedBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get verifyStageInProgressLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'You started verifying your identity but have not sent it yet.'**
  String get verifyStageInProgressBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get verifyStagePendingLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has your details and is checking them.'**
  String get verifyStagePendingBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'More information needed'**
  String get verifyStageNeedsInfoLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs something corrected before it can finish checking.'**
  String get verifyStageNeedsInfoBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifyStageVerifiedLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has confirmed your identity.'**
  String get verifyStageVerifiedBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Could not be verified'**
  String get verifyStageUnsuccessfulLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not confirm your identity from what was sent.'**
  String get verifyStageUnsuccessfulBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Needs a person to check'**
  String get verifyStageManualReviewLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'This needs Taytay LGU staff to check it in person.'**
  String get verifyStageManualReviewBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Government-issued ID'**
  String get kycDocIdentityLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'A PhilID, passport, driver\'s licence, postal ID or voter\'s ID.'**
  String get kycDocIdentityBody;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Proof of address'**
  String get kycDocAddressLabel;

  /// Verification surface copy, localised in the C-13 follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'A utility bill or barangay certificate showing where you live.'**
  String get kycDocAddressBody;

  /// Verification document status, localised in the follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Sent to Taytay LGU.'**
  String get kycDocSent;

  /// Verification document status, localised in the follow-up sweep.
  ///
  /// In en, this message translates to:
  /// **'Sent. Still being checked.'**
  String get kycDocSentChecking;

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Confirm these are your details before you continue, so the office files this against the right record.'**
  String get validateConfirmDetails;

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need help with, in your own words.'**
  String get validateNarrativeMissing;

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Shorten this to {limit} characters or fewer. The office can ask you for more detail later.'**
  String validateNarrativeTooLong(int limit);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'You need to accept \"{subject}\" to continue.'**
  String validateConsentRequired(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Choose an answer for \"{subject}\".'**
  String validateAnswerMissingChoice(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Answer yes or no to \"{subject}\".'**
  String validateAnswerMissingYesNo(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Enter a date for \"{subject}\".'**
  String validateAnswerMissingDate(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Enter a number for \"{subject}\".'**
  String validateAnswerMissingNumber(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Answer \"{subject}\".'**
  String validateAnswerMissingGeneric(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Enter \"{subject}\" as a number, with digits only.'**
  String validateAnswerNotANumber(String subject);

  /// Client-side validation message, localised in the copy sweep.
  ///
  /// In en, this message translates to:
  /// **'Shorten this to {limit} characters or fewer.'**
  String validateAnswerTooLong(int limit);

  /// Consent gate on an event registration form.
  ///
  /// In en, this message translates to:
  /// **'You need to accept \"{subject}\" to register.'**
  String validateConsentRequiredToRegister(String subject);

  /// Heading on the gate shown when a resident cannot yet browse services.
  ///
  /// In en, this message translates to:
  /// **'Browse municipal services'**
  String get capabilityBrowseServices;

  /// Heading on the news gate.
  ///
  /// In en, this message translates to:
  /// **'Read Taytay announcements'**
  String get capabilityReadNews;

  /// Heading on the events gate.
  ///
  /// In en, this message translates to:
  /// **'See LGU events'**
  String get capabilityBrowseEvents;

  /// Heading on the account gate.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get capabilityManageAccount;

  /// Heading on the security gate.
  ///
  /// In en, this message translates to:
  /// **'Manage sign-in and security'**
  String get capabilityManageSecurity;

  /// Heading on the notifications gate.
  ///
  /// In en, this message translates to:
  /// **'See your notifications'**
  String get capabilityReadNotifications;

  /// Heading on the programmes gate.
  ///
  /// In en, this message translates to:
  /// **'See assistance programmes'**
  String get capabilityBrowsePrograms;

  /// Heading on the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get capabilityCompleteVerification;

  /// Heading on the digital ID gate.
  ///
  /// In en, this message translates to:
  /// **'Hold your Taytay digital ID'**
  String get capabilityHoldDigitalId;

  /// Heading on the assistance requests gate.
  ///
  /// In en, this message translates to:
  /// **'Track your assistance requests'**
  String get capabilityTrackAssistanceRequests;

  /// Heading on the assistance application gate.
  ///
  /// In en, this message translates to:
  /// **'Apply for a municipal service'**
  String get capabilityApplyForAssistance;

  /// Heading on the requirements gate.
  ///
  /// In en, this message translates to:
  /// **'Send the documents Taytay LGU asked for'**
  String get capabilitySubmitRequirements;

  /// Heading on the household gate.
  ///
  /// In en, this message translates to:
  /// **'See your household summary'**
  String get capabilityViewHouseholdSummary;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to like this post.'**
  String get gateSignInLikePost;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to comment.'**
  String get gateSignInCommentOnPost;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to register for this event.'**
  String get gateSignInRegisterForEvent;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to save this service.'**
  String get gateSignInSaveService;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to manage your notifications.'**
  String get gateSignInManageNotifications;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to apply for this service.'**
  String get gateSignInApplyForService;

  /// First sentence of the sign-in gate.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to open your digital ID.'**
  String get gateSignInViewDigitalId;

  /// No description provided for @gateSignInMessageOffice.
  ///
  /// In en, this message translates to:
  /// **'You need a Taytay LGU account to message offices.'**
  String get gateSignInMessageOffice;

  /// Second sentence of the sign-in gate, the same for every intent.
  ///
  /// In en, this message translates to:
  /// **'Signing in also lets you track anything you apply for.'**
  String get gateSignInTrailer;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can like this post.'**
  String get gateVerifyLikePost;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can comment.'**
  String get gateVerifyCommentOnPost;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can register for this event.'**
  String get gateVerifyRegisterForEvent;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can save this service.'**
  String get gateVerifySaveService;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can manage your notifications.'**
  String get gateVerifyManageNotifications;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can apply for this service.'**
  String get gateVerifyApplyForService;

  /// First sentence of the verification gate.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can open your digital ID.'**
  String get gateVerifyViewDigitalId;

  /// No description provided for @gateVerifyMessageOffice.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm who you are before you can message offices.'**
  String get gateVerifyMessageOffice;

  /// Second sentence of the verification gate, the same for every intent.
  ///
  /// In en, this message translates to:
  /// **'Verification is a one-time step.'**
  String get gateVerifyTrailer;

  /// Button on the document upload sheet.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get documentSourceCamera;

  /// Button on the document upload sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get documentSourceGallery;

  /// Button on the document upload sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get documentSourceFile;

  /// Shown while the app is still deciding whether a capability is open.
  ///
  /// In en, this message translates to:
  /// **'Checking your account…'**
  String get capabilityExplainPending;

  /// Why a capability is locked: no account.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number to use this. Browsing stays open to everyone.'**
  String get capabilityExplainNeedsSignIn;

  /// Why a capability is locked: not verified.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs to confirm your identity before you can use this.'**
  String get capabilityExplainNeedsVerification;

  /// Why a capability is locked: the LGU has not enabled it.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not switched this on yet. Nothing is wrong with your account, and you can still use everything else in the app.'**
  String get capabilityExplainNotYetAvailable;

  /// Short badge on a locked tile.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get capabilityRequirementSignIn;

  /// Short badge on a locked tile.
  ///
  /// In en, this message translates to:
  /// **'Verification required'**
  String get capabilityRequirementVerification;

  /// Short badge on a locked tile.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get capabilityRequirementNotAvailable;

  /// Primary action on the locked view.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get gateActionSignIn;

  /// Primary action on the locked view.
  ///
  /// In en, this message translates to:
  /// **'Verify my identity'**
  String get gateActionVerify;

  /// Primary action on the locked view.
  ///
  /// In en, this message translates to:
  /// **'See what is available'**
  String get gateActionSeeAvailable;

  /// Fallback primary action on the locked view.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get gateActionContinue;

  /// Secondary action on the locked view.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get gateBackToHome;

  /// Title of the not-yet-available gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get gateSheetNotAvailableTitle;

  /// Reassurance on the not-yet-available gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been sent, and nothing is wrong with your account.'**
  String get gateSheetNotAvailablePrivacy;

  /// Dismisses the not-yet-available gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get gateSheetClose;

  /// Title of the sign-in gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get gateSheetSignInTitle;

  /// Reassurance on the sign-in gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Browsing stays open to everyone — you can keep reading without an account.'**
  String get gateSheetSignInPrivacy;

  /// Primary action on the sign-in gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get gateSheetSignInAction;

  /// Secondary action on the sign-in gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get gateSheetCreateAccount;

  /// Dismisses the sign-in gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Keep browsing'**
  String get gateSheetKeepBrowsing;

  /// Title of the verification gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get gateSheetVerifyTitle;

  /// Reassurance on the verification gate sheet.
  ///
  /// In en, this message translates to:
  /// **'The LGU asks only for what it needs to confirm your identity and residency, and tells you why.'**
  String get gateSheetVerifyPrivacy;

  /// Primary action on the verification gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get gateSheetStartVerification;

  /// Dismisses the verification gate sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get gateSheetNotNow;

  /// Button on the verification card when nothing has been sent.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get verifyActionStart;

  /// Button when verification was started but not sent.
  ///
  /// In en, this message translates to:
  /// **'Continue verification'**
  String get verifyActionContinue;

  /// Button when the LGU asked for a correction.
  ///
  /// In en, this message translates to:
  /// **'Fix and resend'**
  String get verifyActionFixResend;

  /// Button after an unsuccessful verification.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get verifyActionTryAgain;

  /// Home next-action card headline for a verified resident.
  ///
  /// In en, this message translates to:
  /// **'You are verified'**
  String get homeVerifiedTitle;

  /// Home next-action card body for a verified resident.
  ///
  /// In en, this message translates to:
  /// **'Your Taytay digital ID and service applications are open to you.'**
  String get homeVerifiedBody;

  /// Home next-action card headline before verification.
  ///
  /// In en, this message translates to:
  /// **'One step to go'**
  String get homeOneStepTitle;

  /// Home next-action card body before verification.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity with Taytay LGU to unlock your digital ID and service applications.'**
  String get homeOneStepBody;

  /// Home next-action button for a verified resident.
  ///
  /// In en, this message translates to:
  /// **'Open my digital ID'**
  String get homeOpenDigitalId;

  /// Home next-action fallback button.
  ///
  /// In en, this message translates to:
  /// **'Check my status'**
  String get homeCheckStatus;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'The address is wrong'**
  String get householdFixAddressLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'The street address or barangay Taytay LGU has for this household is not correct.'**
  String get householdFixAddressBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'My role in the household is wrong'**
  String get householdFixRoleLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU records you differently from how the household actually works.'**
  String get householdFixRoleBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'The number of people is wrong'**
  String get householdFixSizeLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Someone is missing from the household record, or someone is listed who no longer lives here.'**
  String get householdFixSizeBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'This is not my household'**
  String get householdFixNotMineLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'You have been recorded in a household you do not belong to.'**
  String get householdFixNotMineBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Something else is wrong'**
  String get householdFixOtherLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'You will be asked about it at the municipal hall.'**
  String get householdFixOtherBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Household head'**
  String get householdRoleHead;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Household member'**
  String get householdRoleMember;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Abusive or threatening'**
  String get reportAbusiveLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Insults, threats, or hateful language.'**
  String get reportAbusiveBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Targeting someone'**
  String get reportHarassmentLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Aimed at a particular person.'**
  String get reportHarassmentBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'False information about services'**
  String get reportFalseInfoLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Wrong claims about Taytay LGU services or schedules.'**
  String get reportFalseInfoBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get reportSpamLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Selling something, or posted repeatedly.'**
  String get reportSpamBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Someone\'s personal information'**
  String get reportPersonalInfoLabel;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'A phone number, address, or other private detail posted without consent.'**
  String get reportPersonalInfoBody;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get notifCatVerification;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Assistance updates'**
  String get notifCatAssistance;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Documents needed'**
  String get notifCatMissingRequirement;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Collecting assistance'**
  String get notifCatRelease;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get notifCatReferral;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Event registrations'**
  String get notifCatEventRegistration;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Event reminders'**
  String get notifCatEventReminder;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Public advisories'**
  String get notifCatPublicAdvisory;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Account and security'**
  String get notifCatAccountSecurity;

  /// Notification settings switch for a move on a document request the resident filed (issuance_request_updated).
  ///
  /// In en, this message translates to:
  /// **'Document requests'**
  String get notifSwitchDocumentRequests;

  /// Notification settings switch for the office's decision on a sector application (sector_application_decided).
  ///
  /// In en, this message translates to:
  /// **'Sector applications'**
  String get notifSwitchSectorApplications;

  /// Notification settings switch for the MSWDO office linking, unlinking or correcting the resident's registry record (registry_record_updated).
  ///
  /// In en, this message translates to:
  /// **'Changes to your record at the office'**
  String get notifSwitchRegistryRecord;

  /// Notification settings switch for a new message from an office (message_received).
  ///
  /// In en, this message translates to:
  /// **'Office replies'**
  String get notifSwitchOfficeReplies;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get inboxGroupToday;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Earlier this week'**
  String get inboxGroupThisWeek;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Earlier this month'**
  String get inboxGroupThisMonth;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get inboxGroupOlder;

  /// Resident-facing enum copy.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get inboxGroupUndated;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get serviceCategoryDokumento;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'Taxes and fees'**
  String get serviceCategoryBuwis;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get serviceCategoryKalusugan;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get serviceCategoryTrabaho;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get serviceCategoryIds;

  /// Service category name shown to residents.
  ///
  /// In en, this message translates to:
  /// **'National services'**
  String get serviceCategoryNational;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'That file is too large. Taytay LGU accepts up to {limit} MB. A photo taken in this app is usually small enough.'**
  String uploadRefusedTooLargeUnknown(int limit);

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now like this post.'**
  String get intentResumedLikePost;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now comment.'**
  String get intentResumedCommentOnPost;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now register for this event.'**
  String get intentResumedRegisterForEvent;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now save this service.'**
  String get intentResumedSaveService;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now manage your notifications.'**
  String get intentResumedManageNotifications;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now apply for this service.'**
  String get intentResumedApplyForService;

  /// Resident-facing copy.
  ///
  /// In en, this message translates to:
  /// **'You can now open your digital ID.'**
  String get intentResumedViewDigitalId;

  /// No description provided for @intentResumedMessageOffice.
  ///
  /// In en, this message translates to:
  /// **'You can now message offices.'**
  String get intentResumedMessageOffice;

  /// Skip control on every welcome scene.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// Advances to the next welcome scene.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get welcomeNext;

  /// Leaves the welcome and opens sign-in.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// Leaves the welcome and enters the app without an account.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get welcomeContinueAsGuest;

  /// Explains that browsing needs no account.
  ///
  /// In en, this message translates to:
  /// **'You can browse municipal services without an account.'**
  String get welcomeGuestNote;

  /// Announced progress through the welcome scenes.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String welcomeStep(int current, int total);

  /// English eyebrow on welcome scene 1. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'Municipal services in one place'**
  String get welcomeServicesEyebrow;

  /// Filipino title on welcome scene 1. Shown in both locales.
  ///
  /// In en, this message translates to:
  /// **'Serbisyong bayan,\nnasa isang app.'**
  String get welcomeServicesTitle;

  /// English body on welcome scene 1. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'Documents, real property tax, health programmes and job services — browse what Taytay LGU offers and track anything you apply for.'**
  String get welcomeServicesBody;

  /// Chip on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get welcomeServicesChipDocuments;

  /// Chip on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Real property tax'**
  String get welcomeServicesChipTax;

  /// Chip on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get welcomeServicesChipHealth;

  /// Chip on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get welcomeServicesChipJobs;

  /// Photo caption on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Taytay Municipal Hall'**
  String get welcomeServicesTag;

  /// Photo credit on welcome scene 1.
  ///
  /// In en, this message translates to:
  /// **'Photo: Ramon FVelasquez · CC BY-SA 3.0'**
  String get welcomeServicesCredit;

  /// English eyebrow on welcome scene 2. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'Your Taytay ID, on your phone'**
  String get welcomeIdEyebrow;

  /// Filipino title on welcome scene 2. Shown in both locales.
  ///
  /// In en, this message translates to:
  /// **'Ang Taytay ID mo,\nnasa phone mo na.'**
  String get welcomeIdTitle;

  /// English body on welcome scene 2. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'Apply for and carry your Municipality of Taytay digital ID without queueing at the municipal hall.'**
  String get welcomeIdBody;

  /// Chip on welcome scene 2.
  ///
  /// In en, this message translates to:
  /// **'Digital ID'**
  String get welcomeIdChipDigital;

  /// Chip on welcome scene 2.
  ///
  /// In en, this message translates to:
  /// **'No queueing'**
  String get welcomeIdChipQueue;

  /// Photo caption on welcome scene 2.
  ///
  /// In en, this message translates to:
  /// **'Taytay Tiangge · Garments & Woodcrafts Capital'**
  String get welcomeIdTag;

  /// Photo credit on welcome scene 2.
  ///
  /// In en, this message translates to:
  /// **'Photo: Ralff Nestor Nacor · CC BY-SA 4.0'**
  String get welcomeIdCredit;

  /// English eyebrow on welcome scene 3. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'You choose what you share'**
  String get welcomePrivacyEyebrow;

  /// Filipino title on welcome scene 3. Shown in both locales.
  ///
  /// In en, this message translates to:
  /// **'Ikaw ang pipili\nng ibabahagi.'**
  String get welcomePrivacyTitle;

  /// English body on welcome scene 3. The English locale matches the design. Filipino translates this line.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU asks only for what a service needs, and tells you why. Your information is protected under the Data Privacy Act of 2012.'**
  String get welcomePrivacyBody;

  /// Photo caption on welcome scene 3.
  ///
  /// In en, this message translates to:
  /// **'St. John the Baptist Parish Church'**
  String get welcomePrivacyTag;

  /// Photo credit on welcome scene 3.
  ///
  /// In en, this message translates to:
  /// **'Photo: Urbanroamer · CC BY-SA 3.0'**
  String get welcomePrivacyCredit;

  /// How long an ID review usually takes, as the office's range of working days from GET /app/config (verification_review_working_days, min below max). Composed into verificationReviewSentence and verificationReviewTimelineDetail. Today the verification pages are literal English on every device, so the app reads the English text there and keeps a paragraph in one language (D-200). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} working days'**
  String verificationReviewRange(int min, int max);

  /// How long an ID review usually takes when the office's range is one number (min equals max). Singular for one day. Today the verification pages are literal English on every device, so the app reads the English text there and keeps a paragraph in one language (D-200). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 working day} other{{days} working days}}'**
  String verificationReviewDays(int days);

  /// The pending verification page's sentence on the review time. {duration} is verificationReviewRange or verificationReviewDays. Not shown at all when the office states no review time. Today the verification pages are literal English on every device, so the app reads the English text there and keeps a paragraph in one language (D-200). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This usually takes {duration}.'**
  String verificationReviewSentence(String duration);

  /// The supporting line under 'LGU review' on the profile wizard's submitted frame. {duration} is verificationReviewRange or verificationReviewDays. Not shown at all when the office states no review time. Today the verification pages are literal English on every device, so the app reads the English text there and keeps a paragraph in one language (D-200). The Filipino text was reviewed for grammar and consistency in D-217, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Usually {duration}'**
  String verificationReviewTimelineDetail(String duration);

  /// Title of My requests, the resident's own assistance requests (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequestsTitle;

  /// Subtitle of My requests, and the My Account row's line (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Assistance requests filed with the MSWDO'**
  String get myRequestsSubtitle;

  /// Shown on My requests to every resident, whatever the list holds, so an empty list reveals nothing about anyone (D-223, ADR 0003 C: VAWC and CICL). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Some requests are discussed only in person at the MSWDO.'**
  String get myRequestsInPerson;

  /// Empty My requests: the title. Says nothing about why (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'No requests to show'**
  String get myRequestsEmptyTitle;

  /// Empty My requests: the sentence under the title. Plain, and says nothing about why; the in-person sentence follows it (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'No request filed with the office is shown here.'**
  String get myRequestsEmptyMessage;

  /// Screen-reader label of the My requests skeleton. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading your requests'**
  String get myRequestsLoading;

  /// Button under My requests when the API says more exist (has_more). Never a page count: the API sends none. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Show older requests'**
  String get myRequestsShowOlder;

  /// The Show older requests button while the next page is read. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get myRequestsLoadingMore;

  /// The Show older requests button after the next page failed; tapping it tries again. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Could not load more. Try again'**
  String get myRequestsMoreFailed;

  /// A My requests row: the filing date, pre-formatted in Manila time. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Filed {date}'**
  String myRequestsFiled(String date);

  /// A My requests row whose programme the API does not name. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Assistance request'**
  String get myRequestsUnnamedProgramme;

  /// Status of an assistance request: submitted or intake-review (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get assistanceStageReceived;

  /// Status of an assistance request: assessment or endorsed (D-223). Which desk holds it is never said. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Being assessed'**
  String get assistanceStageBeingAssessed;

  /// Status of an assistance request: approved (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get assistanceStageApproved;

  /// Status of an assistance request: scheduled (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Payout scheduled'**
  String get assistanceStagePayoutScheduled;

  /// Status of an assistance request: released or completed (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get assistanceStageReleased;

  /// Status of an assistance request: returned (D-223). The office's reason is never sent to the app. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office needs more from you — please visit or contact the MSWDO'**
  String get assistanceStageNeedsMore;

  /// Status of an assistance request the office returned, once the resident has sent from the app every document it named (A10). The Filipino text was written by Claude and not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sent — waiting for the office to review what you sent'**
  String get assistanceStageDocumentsSent;

  /// Status of an assistance request: rejected (D-223). The office's reason is never sent to the app. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not approved — the MSWDO can tell you why'**
  String get assistanceStageNotApproved;

  /// Status of an assistance request: cancelled (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get assistanceStageCancelled;

  /// Status of an assistance request: expired (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get assistanceStageExpired;

  /// Status of an assistance request this build does not know (D-223): neutral, never a guess. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Status: updated'**
  String get assistanceStageUpdated;

  /// Title of one request on My requests (D-223). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Assistance request'**
  String get myRequestDetailTitle;

  /// Label: the request's control number. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get myRequestReference;

  /// Label: when the request was filed. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Filed on'**
  String get myRequestFiledOn;

  /// Label: when the request's status last changed. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Status last changed'**
  String get myRequestStatusChangedOn;

  /// Label: the approved amount, shown once approved (pesos from integer centavos). The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Approved amount'**
  String get myRequestApprovedAmount;

  /// Label: the payout session's date, while the payout is scheduled. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Payout date'**
  String get myRequestPayoutDate;

  /// Label: the payout session's venue, while the payout is scheduled. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Where to collect'**
  String get myRequestPayoutVenue;

  /// Label: when the assistance was handed over. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Released on'**
  String get myRequestReleasedOn;

  /// Screen-reader label of one request's skeleton. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading the request'**
  String get myRequestLoading;

  /// One request the list does not carry. Says nothing about why (D-223); the in-person sentence follows. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This request is not shown here'**
  String get myRequestNotShownTitle;

  /// Under myRequestNotShownTitle. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'It is not among the requests shown for your account.'**
  String get myRequestNotShownMessage;

  /// Button from one request that is not shown to My requests. The Filipino text was written by Claude for D-223 and reviewed for consistency with D-217's terms, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'See all my requests'**
  String get myRequestsSeeAll;

  /// Title of the card on a Tulong page whose can_apply is true (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Apply in the app'**
  String get applyCardTitle;

  /// Body of the Apply card on a Tulong page (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send your application and documents to the MSWDO from your phone. The office reviews it as it does at the counter.'**
  String get applyCardBody;

  /// The Apply button on a Tulong page (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyCardButton;

  /// Title of every step of the Apply wizard (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Apply for assistance'**
  String get applyTitle;

  /// The Apply wizard's step counter (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String applyStepOf(int step, int total);

  /// Skeleton label while the Tulong page is read for the wizard (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Opening the application'**
  String get applyLoading;

  /// The wizard opened for a page whose can_apply is false, or that stopped taking applications (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This programme does not take applications in the app'**
  String get applyNotOfferedTitle;

  /// Under applyNotOfferedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Visit or contact the MSWDO to apply. The programme page says how.'**
  String get applyNotOfferedMessage;

  /// Button back to the Tulong page (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Back to the programme'**
  String get applyBackToProgramme;

  /// The wizard's back button on a step (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get applyBack;

  /// Moves to the next step of the Apply wizard (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get applyNext;

  /// Step 1 heading (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What this is'**
  String get applyAboutHeading;

  /// Step 1: what applying in the app is (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You are applying to the MSWDO for help under this programme. The office reads your application and documents, as it does at the counter, and decides. Sending it does not mean it is approved.'**
  String get applyAboutBody;

  /// Step 1 heading (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Who can apply in the app'**
  String get applyWhoHeading;

  /// Step 1: who may apply, and the account link (ADR 0004 decision 1, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'A resident whose account Taytay LGU has verified, and whom the MSWDO has linked to their record at the office. The MSWDO links your account when it reviews your ID, or at the counter.'**
  String get applyWhoBody;

  /// Step 1 heading over the document list (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What the office asks for'**
  String get applyNeedsHeading;

  /// Step 1 when application_requirements is empty (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office asks for no documents in the app for this programme.'**
  String get applyNeedsNone;

  /// Step 1 and the blocked states: the counter is always another way (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You can also apply in person at the MSWDO.'**
  String get applyInPersonAlso;

  /// Step 1 button (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get applyStart;

  /// Shown instead of the wizard to a resident who is not verified, or when the server says VERIFICATION_REQUIRED (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Finish verifying your account first'**
  String get applyNotVerifiedTitle;

  /// Under applyNotVerifiedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Only a resident whose identity Taytay LGU has verified can apply in the app. Send your valid ID and selfie in the app, or verify in person at the Municipal Hall.'**
  String get applyNotVerifiedBody;

  /// Button to verification (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Go to verification'**
  String get applyGoToVerification;

  /// After the server's 409: the verified account is not linked to a registry record (ADR 0004, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The MSWDO needs to link your account'**
  String get applyNotLinkedTitle;

  /// Under applyNotLinkedTitle. Never a dead end: the counter, messaging the office and sending again are offered (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Your account is verified, but the MSWDO has not yet linked it to your record at the office. It does this when it reviews your ID, or at the counter: bring a valid ID to the MSWDO and ask them to link your app account. Your answers stay here until you leave this page.'**
  String get applyNotLinkedBody;

  /// After not linked: sends the same application again (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Try sending again'**
  String get applyTryAgain;

  /// After not linked: opens a message to the programme's office (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Message the office'**
  String get applyMessageOffice;

  /// The Apply wizard's first step when GET /me said linked_to_office_record is false, under applyNotLinkedTitle and before any form (D-226). Nothing was typed, so it says nothing about answers kept. The Filipino text was written by Claude in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is verified, but the MSWDO has not yet linked it to your record at the office, so an application from the app cannot be sent yet. It does this when it reviews your ID, or at the counter: bring a valid ID to the MSWDO and ask them to link your app account. Once it has, come back to this page to apply.'**
  String get applyUnlinkedBody;

  /// On a Tulong page's Apply card when GET /me said linked_to_office_record is true (D-226). The Filipino text was written by Claude in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is linked to your MSWDO record.'**
  String get accountLinkedNote;

  /// On a Tulong page's Apply card, and under an empty My requests, when GET /me said linked_to_office_record is false (D-226). Never shown when the flag is unknown. The Filipino text was written by Claude in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is not yet linked to your MSWDO record. The MSWDO links it when it reviews your ID, or at the counter.'**
  String get accountNotLinkedNote;

  /// Step 2 heading (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your application'**
  String get applyDetailsHeading;

  /// Label of the purpose field (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get applyPurposeLabel;

  /// Hint in the purpose field. Synthetic example (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'For example: medicines for my mother after her operation'**
  String get applyPurposeHint;

  /// Helper under the purpose field (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'In your own words. The office reads this.'**
  String get applyPurposeHelp;

  /// Purpose left empty (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Say what the assistance is for.'**
  String get applyPurposeEmpty;

  /// Purpose shorter than the server's minimum (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Say a little more: at least {min} characters.'**
  String applyPurposeTooShort(int min);

  /// Purpose longer than the server's maximum (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Keep it to {max} characters or fewer.'**
  String applyPurposeTooLong(int max);

  /// Label of the amount field (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Amount you are asking for (optional)'**
  String get applyAmountLabel;

  /// Hint in the amount field (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'For example: 5,000'**
  String get applyAmountHint;

  /// Helper under the amount field (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'In pesos. Leave it blank if you are not sure. The office decides the amount.'**
  String get applyAmountHelp;

  /// An amount that cannot be read (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Write the amount in pesos, like 5000 or 5,000.50.'**
  String get applyAmountUnreadable;

  /// A zero amount (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Write an amount above zero, or leave it blank.'**
  String get applyAmountZero;

  /// An amount above ten digits of centavos (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'That amount is too large. Leave it blank if you are not sure.'**
  String get applyAmountTooLarge;

  /// A field the server named in a 422 (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office could not accept this. Check what you wrote.'**
  String get applyServerFlagged;

  /// Step 3 heading (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get applyDocumentsHeading;

  /// Step 3: the size limit said before any pick (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'One file for each: a photo (JPEG or PNG) or a PDF, up to {limit} MB each. Lay paper flat, fill the frame, and make every word readable.'**
  String applyDocumentsIntro(int limit);

  /// A required document (DL-76, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get applyObligationRequired;

  /// An optional document (DL-76, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get applyObligationOptional;

  /// A conditional document (DL-76, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Only if this applies to you'**
  String get applyObligationConditional;

  /// A conditional document whose condition the office did not write (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office will tell you if you need this.'**
  String get applyConditionUnstated;

  /// An empty document slot (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get applyAddFile;

  /// Removes a chosen file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get applyRemoveFile;

  /// The kind of a chosen file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get applyFilePhoto;

  /// The kind of a chosen file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get applyFilePdf;

  /// A chosen file's line (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{kind} added · {size}'**
  String applyFileAdded(String kind, String size);

  /// A required document with no file, after Next (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add this file to continue.'**
  String get applyMissingFile;

  /// A document the server named in a 422 (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office could not accept this file. Choose it again, or choose another.'**
  String get applyFileFlagged;

  /// Under the slots when a required document has no file (ADR 0004: an online applicant cannot excuse one, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add the documents marked Required. If you do not have one, you can still apply in person at the MSWDO.'**
  String get applyRequiredMissing;

  /// Title of the sheet that asks camera, photo or file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add: {name}'**
  String applyChooseSource(String name);

  /// The source sheet when the phone offers no picker (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot pick a file. You can apply in person at the MSWDO instead.'**
  String get applyNoPicker;

  /// Step 4 heading (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Check your application'**
  String get applyReviewHeading;

  /// Review and done: the programme (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get applyReviewProgramme;

  /// Review: the purpose (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What it is for'**
  String get applyReviewPurpose;

  /// Review: the amount (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Amount asked for'**
  String get applyReviewAmount;

  /// Review: no amount typed (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'None given'**
  String get applyReviewNoAmount;

  /// Review: the documents (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Documents you are sending'**
  String get applyReviewDocuments;

  /// Review: a document with a file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{name}: {kind}, {size}'**
  String applyReviewFile(String name, String kind, String size);

  /// Review: a document with no file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{name}: not sent'**
  String applyReviewNotSent(String name);

  /// Review: goes back to a step to change it (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get applyEdit;

  /// Review: what happens after sending (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office reads it and may call or message you. You cannot change it after sending. If the office needs more, it returns the request and says what.'**
  String get applyReviewNote;

  /// Review: the send button (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send application'**
  String get applySend;

  /// The send button while sending (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get applySending;

  /// A send whose answer never came (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get applyUnconfirmedTitle;

  /// Under applyUnconfirmedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your application was received. Sending it again is safe: it will not be filed twice. You can also check My requests.'**
  String get applyUnconfirmedBody;

  /// A send that could not leave the phone (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get applyOfflineTitle;

  /// Under applyOfflineTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Your answers are still here on the phone. Connect to the internet and try again.'**
  String get applyOfflineBody;

  /// A 422 on the send (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Something needs another look'**
  String get applyCheckTitle;

  /// Under applyCheckTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. The office could not accept part of it. The items marked need checking.'**
  String get applyCheckBody;

  /// A 413 or refused upload (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'A file could not be accepted'**
  String get applyFileTitle;

  /// Under applyFileTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. A file was too large or could not be read. Choose a smaller photo or another file, and try again.'**
  String get applyFileBody;

  /// A 429 (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Too many tries'**
  String get applyRateTitle;

  /// Under applyRateTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Wait a few minutes, then try again.'**
  String get applyRateBody;

  /// A 422 keyed by service_slug, under applyNotOfferedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. The office stopped taking applications for this programme in the app. Visit or contact the MSWDO to apply.'**
  String get applyClosedBody;

  /// A 401 on the send (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get applySessionTitle;

  /// Under applySessionTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Your session ended. Sign in, then try again.'**
  String get applySessionBody;

  /// A plain 403 (a staff account) (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not available for this account'**
  String get applyNotAllowedTitle;

  /// Under applyNotAllowedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Applying in the app is not open to this account. The MSWDO can tell you more.'**
  String get applyNotAllowedBody;

  /// Any other refusal (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'It did not go through'**
  String get applyServerTitle;

  /// Under applyServerTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Something went wrong on our side. Try again in a moment.'**
  String get applyServerBody;

  /// The request id of a failed send, to quote at the support desk (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Reference: {reference}'**
  String applyFailureReference(String reference);

  /// Done: the control number follows (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The MSWDO has your application'**
  String get applyDoneTitle;

  /// Done (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Keep this control number. The office uses it when you ask about your application.'**
  String get applyDoneMessage;

  /// Done: the label of the control number (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Control number'**
  String get applyDoneControlNumber;

  /// Done: the same for every resident, so nothing reveals that a request will not be listed (ADR 0004, VAWC and CICL; D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office reviews it at intake. Where your requests stand is shown in My requests. Some requests are discussed only in person at the MSWDO.'**
  String get applyDoneNote;

  /// Done: primary button (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Open My requests'**
  String get applyOpenMyRequests;

  /// Done: secondary button (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Back to Tulong'**
  String get applyBackToTulong;

  /// Title of the screen that sends documents to a returned request (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add documents'**
  String get addDocsTitle;

  /// Add documents: what and the size limit, said before any pick (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office returned this request and needs the documents below. Send a photo (JPEG or PNG) or a PDF of each, up to {limit} MB each.'**
  String addDocsIntro(int limit);

  /// missing_documents state not-sent (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get addDocsStateNotSent;

  /// missing_documents state send-again (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get addDocsStateSendAgain;

  /// A missing_documents state this build does not know (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Needed'**
  String get addDocsStateOther;

  /// Add documents: the send button (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send documents'**
  String get addDocsSend;

  /// Add documents: send with no file (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add at least one document to send.'**
  String get addDocsNothingChosen;

  /// Add documents: done (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Documents sent'**
  String get addDocsDoneTitle;

  /// Add documents, done, when the office names nothing more: what happens next (D-226, D-231). No time is promised (D-37). The Filipino text was written by Claude for D-231 in D-217's terms ("hiling", "tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The MSWDO will review what you sent. Until then, your request shows that it is waiting for the office.'**
  String get addDocsDoneMessage;

  /// Add documents: back (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Back to the request'**
  String get addDocsBackToRequest;

  /// A 409: the request is no longer returned (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The request has moved on'**
  String get addDocsMovedTitle;

  /// Under addDocsMovedTitle (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. The office is no longer waiting for documents on this request. Open it again to see where it stands.'**
  String get addDocsMovedBody;

  /// Add documents: a send whose answer never came (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your documents were received. Sending them again is safe: they will not be added twice. You can also open the request to check.'**
  String get addDocsUnconfirmedBody;

  /// Add documents opened for a request with nothing missing (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office is not waiting for documents on this request.'**
  String get addDocsNoneNeeded;

  /// A request filed from this app (channel online, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Applied in the app'**
  String get myRequestsChannelOnline;

  /// A request filed at the office (channel office, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Filed at the office'**
  String get myRequestsChannelOffice;

  /// A request imported from the office's old paper records (channel imported, D-227). The Filipino text was written by Claude for D-227 in D-217's terms ("tanggapan"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'From the office\'s records'**
  String get myRequestsChannelImported;

  /// An imported request: the control or voucher number printed on the office's old paper records she holds (source_reference, D-227), shown before this system's reference. The Filipino text was written by Claude for D-227 in D-217's terms ("tanggapan"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Control no. {number}'**
  String myRequestControlNumber(String number);

  /// One imported request: label of this system's own reference number, shown below the control number on her papers (D-227). The Filipino text was written by Claude for D-227 in D-217's terms ("tanggapan"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'System reference'**
  String get myRequestSystemReference;

  /// One request: label of the channel fact (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'How it was filed'**
  String get myRequestChannel;

  /// One returned request: the missing documents (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Documents the office needs'**
  String get myRequestMissingHeading;

  /// One returned request: opens Add documents (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add documents'**
  String get myRequestAddDocuments;

  /// A returned request's document, in the request and in Add documents: heading of the note an officer wrote for the resident about that document (missing_documents[].applicant_note, ADR 0009). The note below it is the office's own words, shown exactly; never the office's remarks. The Filipino text was written by Claude for D-230 in D-217's terms ("tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'From the MSWDO:'**
  String get myRequestApplicantNoteFrom;

  /// One returned request: label of the date she last sent documents from the app since the office returned it (documents_sent_at, ADR 0009). The Filipino text was written by Claude for D-230 in D-217's terms ("tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Documents sent on'**
  String get myRequestDocumentsSentOn;

  /// The Verified status page: the account link that makes My requests and Apply work (ADR 0004 decision 1, D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'One more step happens at the office: the MSWDO links your account to your record there, usually when it reviews your ID, or at the counter. Once it has, My requests shows your assistance requests and you can apply for Tulong in the app.'**
  String get verifiedLinkNote;

  /// The Verified status page in place of verifiedLinkNote when GET /me said linked_to_office_record is true (D-226). The Filipino text was written by Claude in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is linked to your MSWDO record. My requests shows your assistance requests, and you can apply for Tulong in the app.'**
  String get verifiedLinkedNote;

  /// Verified page: a 'You can now' line (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Apply for Tulong'**
  String get verifiedApplyStep;

  /// Under verifiedApplyStep (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'From a programme page that offers Apply'**
  String get verifiedApplyStepDetail;

  /// Verified page: a 'You can now' line (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Follow your assistance requests'**
  String get verifiedRequestsStep;

  /// Under verifiedRequestsStep (D-226). The Filipino text was written by Claude for D-226 in D-217's terms ("hiling", "tanggapan ng MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'In My requests, once the MSWDO has linked your account'**
  String get verifiedRequestsStepDetail;

  /// Add documents, done, when the request still names documents she has not sent (D-231). {documents} is their names from the API, joined with commas. NOTE
  ///
  /// In en, this message translates to:
  /// **'The office still needs: {documents}. Send them from the request when you have them.'**
  String addDocsDoneStillNeeded(String documents);

  /// Add documents, done: the value beside a document's name, what file was sent for it (applyFilePhoto or applyFilePdf, then its size) (D-231). Filipino joins the two with the linker "na" ("Litrato na 1.2 MB"). The Filipino text was written by Claude for D-231 in D-217's terms ("hiling", "tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{kind}, {size}'**
  String addDocsDoneFile(String kind, String size);

  /// Add documents, done: label of when the API recorded the send (documents_sent_at, ADR 0009), as a Manila date and time (D-231). The Filipino text was written by Claude for D-231 in D-217's terms ("hiling", "tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sent on'**
  String get addDocsDoneSentOn;

  /// Add documents, done: the note under the receipt (D-231). No time is promised (D-37). The Filipino text was written by Claude for D-231 in D-217's terms ("hiling", "tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Open the request any time to see where it stands. If the office needs anything more, the request will say so.'**
  String get addDocsDoneNote;

  /// My Account: the line under Sectors and benefits. A general list of the sectors the page takes applications for, worded so it is never read as the resident's own sectors (D-231). The Filipino text was written by Claude for D-231 in D-217's terms ("hiling", "tanggapan", "MSWDO"), not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Who it can help: senior citizens, PWDs and solo parents'**
  String get accountSectorsSubtitle;

  /// Sign-in help: page title.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authHelpTitle;

  /// Sign-in help: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Sign-in help'**
  String get authHelpSubtitle;

  /// Sign-in help: how to reset, and that the app never says whether an account exists.
  ///
  /// In en, this message translates to:
  /// **'Reset it from the sign-in screen. We send a code to the email or mobile number on the account, and we never say whether that account exists.'**
  String get authHelpIntro;

  /// Sign-in help: card title.
  ///
  /// In en, this message translates to:
  /// **'The code did not arrive'**
  String get authHelpNoCodeTitle;

  /// Sign-in help: what to do when no code arrived.
  ///
  /// In en, this message translates to:
  /// **'Check that you typed the number correctly, and that your phone has signal. Messages can take a few minutes. You can ask for a new code from the sign-in screen.'**
  String get authHelpNoCodeBody;

  /// Sign-in help: card title.
  ///
  /// In en, this message translates to:
  /// **'The code did not work'**
  String get authHelpCodeFailedTitle;

  /// Sign-in help: why a code may not work.
  ///
  /// In en, this message translates to:
  /// **'Codes are short-lived and single-use. Ask for a new one and enter it as soon as it arrives.'**
  String get authHelpCodeFailedBody;

  /// Sign-in help: card title.
  ///
  /// In en, this message translates to:
  /// **'It says too many attempts'**
  String get authHelpTooManyTitle;

  /// Sign-in help: the attempt limit.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU limits sign-in attempts to protect your account. Wait a little while, then try again. Nothing is wrong with your account.'**
  String get authHelpTooManyBody;

  /// Sign-in help: card title.
  ///
  /// In en, this message translates to:
  /// **'You no longer have that number'**
  String get authHelpLostNumberTitle;

  /// Sign-in help: a lost number is changed in person.
  ///
  /// In en, this message translates to:
  /// **'Changing the number on an account is an identity decision, so Taytay LGU makes it in person. Visit the municipal hall with a valid ID and ask to update your registered mobile number. You do not need this app or your old phone to do it.'**
  String get authHelpLostNumberBody;

  /// Sign-in help: card title.
  ///
  /// In en, this message translates to:
  /// **'Someone else may have used your account'**
  String get authHelpMisuseTitle;

  /// Sign-in help: suspected misuse. 'Sign-in and security' names a settings page.
  ///
  /// In en, this message translates to:
  /// **'Sign in and sign out of this device from Sign-in and security. If you cannot sign in, report it at the municipal hall — staff there can act on your account directly.'**
  String get authHelpMisuseBody;

  /// Sign-in help: warning heading.
  ///
  /// In en, this message translates to:
  /// **'What we will never ask you'**
  String get authHelpNeverAskHeading;

  /// Sign-in help: never share the one-time code.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU staff will never ask for your one-time code, by phone, text or message. If somebody asks you for it, they are not from the LGU. Do not share it.'**
  String get authHelpNeverAskBody;

  /// Link or button back to the sign-in screen (help page, forgot password).
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// App lock screen: heading.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU IDS is locked'**
  String get authLockTitle;

  /// App lock screen: button that asks for the fingerprint, face or screen lock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get authLockUnlock;

  /// App lock screen: the always-available way out.
  ///
  /// In en, this message translates to:
  /// **'Sign out instead'**
  String get authLockSignOutInstead;

  /// App lock screen: why the app is locked.
  ///
  /// In en, this message translates to:
  /// **'You turned on the app lock, so Taytay LGU IDS asks for your fingerprint, face or screen lock before showing your details again.'**
  String get authLockExplainIdle;

  /// App lock screen: the unlock prompt succeeded.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get authLockExplainUnlocking;

  /// App lock screen: the resident closed the unlock prompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see your details again.'**
  String get authLockExplainCancelled;

  /// App lock screen: the fingerprint, face or screen lock did not match.
  ///
  /// In en, this message translates to:
  /// **'That did not match. Try again, or sign out and sign back in.'**
  String get authLockExplainFailed;

  /// App lock screen: the device could not show its unlock prompt.
  ///
  /// In en, this message translates to:
  /// **'Your device could not show the unlock prompt. You can sign out and sign back in instead — nothing is wrong with your account.'**
  String get authLockExplainUnavailable;

  /// Sign-in: the wave header's greeting. The design writes it in Filipino in both languages, like the welcome titles.
  ///
  /// In en, this message translates to:
  /// **'Maligayang pagbabalik!'**
  String get authSignInTitle;

  /// Sign-in: line under the greeting.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Taytay resident account.'**
  String get authSignInSubtitle;

  /// Sign-in: words before the Create an account link.
  ///
  /// In en, this message translates to:
  /// **'Bago rito?'**
  String get authSignInNewHere;

  /// Sign-in: bold start of the refusal note; the attempts sentence follows it. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. '**
  String get authSignInIncorrectTitle;

  /// Sign-in: how many password attempts remain before the account pauses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt left before a 15-minute pause.} other{{count} attempts left before a 15-minute pause.}}'**
  String authSignInAttemptsLeft(int count);

  /// Sign-in and forgot password: field label.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get authIdentifierLabel;

  /// Password field label (sign-in, create account).
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Sign-in: error under the password field after a refusal.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authSignInIncorrectPassword;

  /// Button inside a password field that shows the password.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get authPasswordShow;

  /// Button inside a password field that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get authPasswordHide;

  /// Sign-in: link to the reset flow.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordLink;

  /// Sign-in: the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authEnterPassword;

  /// Sign-in and forgot password: the identifier field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number.'**
  String get authIdentifierEmpty;

  /// Sign-in and forgot password: the identifier is neither an email nor a mobile number.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address or an 11-digit mobile number.'**
  String get authIdentifierShape;

  /// Forgot password: page title; also the button on Sign-in help.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// Forgot password: what to enter and what happens.
  ///
  /// In en, this message translates to:
  /// **'Enter the email or mobile number on your account. We\'ll send a 6-digit code to reset your password.'**
  String get authResetSubtitle;

  /// Forgot password: main button.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get authResetSendCode;

  /// Forgot password: the app never says whether an account exists.
  ///
  /// In en, this message translates to:
  /// **'For your security, we don\'t say whether an account exists for this address.'**
  String get authResetNoEnumeration;

  /// Forgot password: after sending, without saying whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account matches, a code is on its way.'**
  String get authResetSent;

  /// Stands in for the address when the screen does not have it, inside a sentence ('We sent a code to your email').
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get authYourEmail;

  /// Reset code (02-02b): page title.
  ///
  /// In en, this message translates to:
  /// **'Ilagay ang 6-digit na code'**
  String get authResetCodeTitle;

  /// Reset code: where the code went.
  ///
  /// In en, this message translates to:
  /// **'Nagpadala kami ng code sa {email}.'**
  String authResetCodeSubtitle(String email);

  /// Reset code: button once the code expired.
  ///
  /// In en, this message translates to:
  /// **'Magpadala ng bagong code'**
  String get authResetSendNewCode;

  /// Reset code: main button.
  ///
  /// In en, this message translates to:
  /// **'I-verify ang code'**
  String get authResetVerifyCode;

  /// Reset code: how long a code lasts and how many tries it allows.
  ///
  /// In en, this message translates to:
  /// **'Valid ang code nang 10 minuto. May 5 subok ka bawat code.'**
  String get authResetCodeRules;

  /// Reset flow and too-many-attempts: link back to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Bumalik sa sign in'**
  String get authResetBackToSignIn;

  /// Reset code: bold start of the wrong-code note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Mali ang code. '**
  String get authResetWrongTitle;

  /// Reset code: tries left on this code.
  ///
  /// In en, this message translates to:
  /// **'{remaining} sa {total} subok na lang ang natitira.'**
  String authResetAttemptsLeft(int remaining, int total);

  /// Reset code: tries per code when the server named no count.
  ///
  /// In en, this message translates to:
  /// **'May {total} subok ka bawat code.'**
  String authResetAttemptsPerCode(int total);

  /// Reset code: bold start of the expired note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Nag-expire na ang code. '**
  String get authResetExpiredTitle;

  /// Reset code: send a new code; tries on it.
  ///
  /// In en, this message translates to:
  /// **'Magpadala ng bago. May {count} subok ka ulit.'**
  String authResetExpiredBody(int count);

  /// Reset code: bold start of the service-unavailable note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Subukang muli. '**
  String get authResetUnavailableTitle;

  /// Reset code and too-many-attempts: the code service is down. Same words as CodeAttemptView.unavailableCopy.
  ///
  /// In en, this message translates to:
  /// **'Hindi available ang serbisyo ngayon. Subukang muli.'**
  String get authCodeServiceUnavailable;

  /// Reset code: countdown chip, e.g. 'Mag-e-expire sa 8:42'.
  ///
  /// In en, this message translates to:
  /// **'Mag-e-expire sa {time}'**
  String authResetExpiresIn(String time);

  /// Reset code: resend button when it works.
  ///
  /// In en, this message translates to:
  /// **'Ipadala muli'**
  String get authResetResend;

  /// Reset code: resend button while waiting, e.g. 'Ipadala muli sa 0:42'.
  ///
  /// In en, this message translates to:
  /// **'Ipadala muli sa {time}'**
  String authResetResendIn(String time);

  /// New password: the two passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Hindi tugma ang password. Pakiulit.'**
  String get authResetMismatch;

  /// New password (02-12): page title.
  ///
  /// In en, this message translates to:
  /// **'Gumawa ng bagong password'**
  String get authResetNewPasswordTitle;

  /// New password: whose password, and when it is used.
  ///
  /// In en, this message translates to:
  /// **'Para sa {email}. Gamitin ito sa susunod mong pag-sign in.'**
  String authResetNewPasswordSubtitle(String email);

  /// New password (link expired) and too-many-attempts: ask for a new code.
  ///
  /// In en, this message translates to:
  /// **'Humingi ng bagong code'**
  String get authRequestNewCode;

  /// New password: main button.
  ///
  /// In en, this message translates to:
  /// **'I-save ang password'**
  String get authResetSavePassword;

  /// New password: bold start of the save-failure note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Hindi pa napalitan ang password. '**
  String get authResetNotChangedTitle;

  /// New password (02-12b): bold start of the expired note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Nag-expire na ang reset link mo. '**
  String get authResetLinkExpiredTitle;

  /// New password (02-12b): the reset link lasts 15 minutes.
  ///
  /// In en, this message translates to:
  /// **'Valid lang ito nang 15 minuto. Humingi ng bagong code para makapagpatuloy.'**
  String get authResetLinkExpiredBody;

  /// New password: first field label (the star marks it required).
  ///
  /// In en, this message translates to:
  /// **'Bagong password *'**
  String get authResetNewPasswordLabel;

  /// New password: second field label.
  ///
  /// In en, this message translates to:
  /// **'Ulitin ang bagong password *'**
  String get authResetConfirmLabel;

  /// New password: the two passwords match.
  ///
  /// In en, this message translates to:
  /// **'Tugma ang password'**
  String get authResetMatched;

  /// New password: button that shows the password.
  ///
  /// In en, this message translates to:
  /// **'Ipakita'**
  String get authResetShowPassword;

  /// New password: button that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Itago'**
  String get authResetHidePassword;

  /// New password: rule chip, at least 8 characters.
  ///
  /// In en, this message translates to:
  /// **'Hindi bababa sa 8 character'**
  String get authResetRuleLength;

  /// New password: rule chip, has a number.
  ///
  /// In en, this message translates to:
  /// **'May numero'**
  String get authResetRuleDigit;

  /// New password: rule chip, has a letter.
  ///
  /// In en, this message translates to:
  /// **'May letra'**
  String get authResetRuleLetter;

  /// Screen-reader label for a password rule that is met.
  ///
  /// In en, this message translates to:
  /// **'{rule}, met'**
  String authPasswordRuleMet(String rule);

  /// Screen-reader label for a password rule not met yet.
  ///
  /// In en, this message translates to:
  /// **'{rule}, not met'**
  String authPasswordRuleNotMet(String rule);

  /// New password save failed: no connection.
  ///
  /// In en, this message translates to:
  /// **'Walang koneksyon. Ikonekta ang telepono at subukang muli.'**
  String get authResetFailOffline;

  /// New password save failed: rate limited.
  ///
  /// In en, this message translates to:
  /// **'Masyadong maraming subok. Maghintay nang ilang minuto bago subukang muli.'**
  String get authResetFailRateLimited;

  /// New password save failed: the reset token is no longer valid.
  ///
  /// In en, this message translates to:
  /// **'Hindi na magagamit ang reset link na ito. Humingi ng bagong code.'**
  String get authResetFailLinkUsed;

  /// New password save failed: the password is too weak.
  ///
  /// In en, this message translates to:
  /// **'Kailangan ng password na may 8 o higit pang titik, may letra at numero.'**
  String get authResetFailWeak;

  /// New password save failed: any other reason.
  ///
  /// In en, this message translates to:
  /// **'Hindi ito natapos ngayon. Subukang muli mamaya.'**
  String get authResetFailOther;

  /// Password updated (02-13): title.
  ///
  /// In en, this message translates to:
  /// **'Na-update na ang password mo'**
  String get authResetDoneTitle;

  /// Password updated: what next.
  ///
  /// In en, this message translates to:
  /// **'Gamitin ang bagong password sa susunod mong pag-sign in sa Taytay LGUIDS.'**
  String get authResetDoneBody;

  /// Password updated: bold start of the security note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Para sa iyong seguridad. '**
  String get authResetDoneSecurityTitle;

  /// Password updated: what to do if the resident did not change it.
  ///
  /// In en, this message translates to:
  /// **'Kung hindi ikaw ang nagpalit ng password, tumawag sa Municipal Hall o pumunta sa MSWDO.'**
  String get authResetDoneSecurityBody;

  /// Password updated: main button.
  ///
  /// In en, this message translates to:
  /// **'Mag-sign in'**
  String get authResetDoneSignIn;

  /// Too many attempts (02-14b): sentence start; the email follows in bold, then a full stop. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Puwede ka nang humingi ng bagong code. Ipapadala namin ito sa '**
  String get authHoldLeadReady;

  /// Too many attempts (02-14): sentence start; the email follows in bold, then a full stop. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Para protektahan ang account mo, pansamantala naming itinigil ang pagpapadala at pag-verify ng code para sa '**
  String get authHoldLeadLocked;

  /// Too many attempts: title once the hold is over.
  ///
  /// In en, this message translates to:
  /// **'Subukan ulit ngayon'**
  String get authHoldTitleReady;

  /// Too many attempts: title while held.
  ///
  /// In en, this message translates to:
  /// **'Masyadong maraming subok'**
  String get authHoldTitleLocked;

  /// Too many attempts: line under the title once the hold is over.
  ///
  /// In en, this message translates to:
  /// **'Puwede na ulit'**
  String get authHoldSubtitleReady;

  /// Too many attempts: line under the title while held.
  ///
  /// In en, this message translates to:
  /// **'Pansamantalang naka-lock'**
  String get authHoldSubtitleLocked;

  /// Too many attempts: note heading.
  ///
  /// In en, this message translates to:
  /// **'Bakit ito nangyari?'**
  String get authHoldWhyHeading;

  /// Too many attempts: why the hold happened.
  ///
  /// In en, this message translates to:
  /// **'Masyadong maraming maling code o hiling ng bagong code sa maikling oras. Hindi mo kailangang gumawa ng bagong account.'**
  String get authHoldWhyBody;

  /// Too many attempts: screen-reader sentence once the wait is over.
  ///
  /// In en, this message translates to:
  /// **'Tapos na ang paghihintay. 00:00'**
  String get authHoldSpokenReady;

  /// Too many attempts: screen-reader sentence with the time left, e.g. 14:32.
  ///
  /// In en, this message translates to:
  /// **'Subukang muli sa {time}'**
  String authHoldSpokenWaiting(String time);

  /// Too many attempts: label over the clock once the wait is over.
  ///
  /// In en, this message translates to:
  /// **'Tapos na ang paghihintay'**
  String get authHoldClockReady;

  /// Too many attempts: label over the countdown (the time is shown below it).
  ///
  /// In en, this message translates to:
  /// **'Subukang muli sa'**
  String get authHoldClockWaiting;

  /// Create account: a mobile number that is not 11 digits starting with 09.
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit mobile number starting with 09.'**
  String get authMobileShape;

  /// Create account: ends the wizard when no selfie can be sent; the account is kept.
  ///
  /// In en, this message translates to:
  /// **'Finish for now'**
  String get authWizardFinishForNow;

  /// Create account, ID step: heading of the offer to verify at the office instead.
  ///
  /// In en, this message translates to:
  /// **'Rather verify in person?'**
  String get authWizardInPersonOfferHeading;

  /// Create account, ID step: the in-person way.
  ///
  /// In en, this message translates to:
  /// **'You do not have to upload anything. Bring a valid ID to the MSWDO and staff verify your account there. No selfie is taken.'**
  String get authWizardInPersonOffer;

  /// Create account, ID step: chooses the in-person way.
  ///
  /// In en, this message translates to:
  /// **'Verify in person instead'**
  String get authWizardInPersonOfferAction;

  /// Create account, ID step: heading once in person was chosen.
  ///
  /// In en, this message translates to:
  /// **'You chose to verify in person'**
  String get authWizardInPersonChosenHeading;

  /// Create account, ID step: what choosing in person means.
  ///
  /// In en, this message translates to:
  /// **'Nothing about your ID is sent from the app. Your account is kept and works without it until staff verify you at the office.'**
  String get authWizardInPersonChosen;

  /// Create account, ID step: undoes the in-person choice.
  ///
  /// In en, this message translates to:
  /// **'Send my ID in the app instead'**
  String get authWizardInPersonUndo;

  /// Create account: ID step title once in person was chosen.
  ///
  /// In en, this message translates to:
  /// **'Verify in person'**
  String get authWizardInPersonStepTitle;

  /// Create account: ID step subtitle once in person was chosen.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Staff verify it at the MSWDO counter.'**
  String get authWizardInPersonStepSubtitle;

  /// Create account: no barangay chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose your barangay.'**
  String get authWizardChooseBarangay;

  /// Create account: the email is not valid. The example address stays as is.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, e.g. name@example.com'**
  String get authWizardEmailInvalid;

  /// Create account: the password is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authWizardPasswordShort;

  /// Create account: Firebase refused the password as weak (the sentence firebase_identity.dart carries).
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters, with a letter and a number.'**
  String get authWizardPasswordWeak;

  /// Create account, email code: the code is not 6 digits.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authWizardEnterCode;

  /// Create account, email code: the code service is down.
  ///
  /// In en, this message translates to:
  /// **'The service is not available right now. Try again.'**
  String get authWizardServiceUnavailable;

  /// Create account, email code: the code was wrong; tries left.
  ///
  /// In en, this message translates to:
  /// **'Wrong code. {remaining} of {total} tries left.'**
  String authWizardWrongCode(int remaining, int total);

  /// Create account, terms: neither box is ticked.
  ///
  /// In en, this message translates to:
  /// **'Agree to the Terms of Use and acknowledge the Privacy Notice: tick each one.'**
  String get authWizardTermsBoth;

  /// Create account, terms: the Terms box is not ticked.
  ///
  /// In en, this message translates to:
  /// **'Agree to the Terms of Use to continue.'**
  String get authWizardTermsOnly;

  /// Create account, terms: the Privacy Notice box is not ticked.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge the Privacy Notice to continue.'**
  String get authWizardPrivacyOnly;

  /// Create account, terms: recording consent timed out.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your consent was recorded. Agreeing again is safe: it is recorded only once.'**
  String get authWizardConsentUnknown;

  /// Create account, terms: consent was refused; {reason} is the failure sentence.
  ///
  /// In en, this message translates to:
  /// **'Your consent was not recorded. {reason}'**
  String authWizardConsentNotRecorded(String reason);

  /// Create account, ID: no front photo yet.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the front of your ID.'**
  String get authWizardAddIdFront;

  /// Create account, selfie: no selfie yet.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie to continue.'**
  String get authWizardTakeSelfieFirst;

  /// Create account: error under the email field.
  ///
  /// In en, this message translates to:
  /// **'This email already has a Taytay account.'**
  String get authWizardEmailTaken;

  /// Create account: the email already has an account.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead, or use another email.'**
  String get authWizardEmailExists;

  /// Create account: the email code could not be sent; {next} is what to do.
  ///
  /// In en, this message translates to:
  /// **'Your account is saved, but we could not send a code to {email}. {next}'**
  String authWizardCodeNotSent(String email, String next);

  /// Create account: what to do when the code was not sent for lack of connection. 'Continue'/'Magpatuloy' is the button's own label (gateActionContinue).
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then press Continue to try again.'**
  String get authWizardCodeNotSentOffline;

  /// Create account: what to do when the code was not sent. 'Continue'/'Magpatuloy' is the button's own label.
  ///
  /// In en, this message translates to:
  /// **'Press Continue to try again in a moment.'**
  String get authWizardCodeNotSentLater;

  /// Create account: saving the profile timed out.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your details were saved. Press Continue to send them again: it is safe to repeat.'**
  String get authWizardDetailsUnknown;

  /// Create account: start of the profile-save failure; a reason sentence follows.
  ///
  /// In en, this message translates to:
  /// **'Your details were not saved.'**
  String get authWizardDetailsNotSaved;

  /// Create account: follows authWizardDetailsNotSaved when fields were refused.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted details.'**
  String get authWizardDetailsCheckHighlighted;

  /// Create account: follows authWizardDetailsNotSaved when the email is taken.
  ///
  /// In en, this message translates to:
  /// **'This email is already on another Taytay account. Please ask the municipal hall for help.'**
  String get authWizardDetailsEmailConflict;

  /// Privacy Notice sheet: follows the shared 'not published yet' sentence.
  ///
  /// In en, this message translates to:
  /// **'The summary on this step is a draft.'**
  String get authWizardSummaryIsDraft;

  /// Create account: screen-reader name of the progress bar.
  ///
  /// In en, this message translates to:
  /// **'Create account progress'**
  String get authWizardProgressLabel;

  /// Create account, step 1: wave header title, written in Filipino by the design.
  ///
  /// In en, this message translates to:
  /// **'Tungkol sa iyo'**
  String get authWizardPersonalTitle;

  /// Create account, step 1: subtitle. 'Resident Profile' names a page.
  ///
  /// In en, this message translates to:
  /// **'Basic details only. You can complete your Resident Profile once your account is verified.'**
  String get authWizardPersonalSubtitle;

  /// Create account, account step once the account exists.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get authWizardAccountCreatedTitle;

  /// Create account, account step once the account exists.
  ///
  /// In en, this message translates to:
  /// **'You sign in with this email. Next we send a 6-digit code to it.'**
  String get authWizardAccountCreatedSubtitle;

  /// Create account, account step title.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authWizardAccountTitle;

  /// Create account, account step subtitle.
  ///
  /// In en, this message translates to:
  /// **'You sign in with this email and password. Next we send a 6-digit code to the email.'**
  String get authWizardAccountSubtitle;

  /// Create account, email code expired (02-04b): title, written in Filipino by the design.
  ///
  /// In en, this message translates to:
  /// **'Nag-expire na ang code'**
  String get authWizardCodeExpiredTitle;

  /// Create account, email code expired: subtitle.
  ///
  /// In en, this message translates to:
  /// **'The code is valid for 10 minutes only. Send a new one to {address}.'**
  String authWizardCodeExpiredSubtitle(String address);

  /// Create account, email code: title.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authWizardCodeTitle;

  /// Create account, email code: subtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {address}. It expires in 10 minutes.'**
  String authWizardCodeSubtitle(String address);

  /// Create account, terms step: title.
  ///
  /// In en, this message translates to:
  /// **'Your data, protected'**
  String get authWizardTermsTitle;

  /// Create account, terms step: subtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy'**
  String get authWizardTermsSubtitle;

  /// Create account, ID step: title.
  ///
  /// In en, this message translates to:
  /// **'Upload a valid government ID'**
  String get authWizardIdTitle;

  /// Create account, ID step: subtitle.
  ///
  /// In en, this message translates to:
  /// **'The LGU uses it to confirm who you are. Make sure all four corners and your name are clear.'**
  String get authWizardIdSubtitle;

  /// Create account, selfie step: title.
  ///
  /// In en, this message translates to:
  /// **'Take a quick selfie'**
  String get authWizardSelfieTitle;

  /// Create account, selfie step: subtitle.
  ///
  /// In en, this message translates to:
  /// **'LGU staff compare it with your ID. It is not used as your profile photo.'**
  String get authWizardSelfieSubtitle;

  /// Create account, review step: title.
  ///
  /// In en, this message translates to:
  /// **'Check your details'**
  String get authWizardReviewTitle;

  /// Create account, code expired: main button.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get authWizardSendNewCode;

  /// Create account, email code: link back to retype the email (both the live and the expired code step).
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get authWizardChangeEmail;

  /// Create account, email code: main button.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get authWizardConfirmEmail;

  /// Create account, review: main button.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get authWizardSubmit;

  /// Create account, account step: main button.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get authWizardCreateAccount;

  /// Create account: error summary above refused fields.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Please fix 1 field to continue.} other{Please fix {count} fields to continue.}}'**
  String authWizardFixFields(int count);

  /// Create account: placeholder in a picker with nothing chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get authWizardChoose;

  /// Create account: street field label.
  ///
  /// In en, this message translates to:
  /// **'Street / Purok'**
  String get authWizardStreetLabel;

  /// Create account: the address as it will read, under the street field.
  ///
  /// In en, this message translates to:
  /// **'Address: {street}, Brgy. {barangay}, Taytay, Rizal'**
  String authWizardAddressHint(String street, String barangay);

  /// Create account: password rule chip. The other chips (Aa, 123, #!@) are symbols.
  ///
  /// In en, this message translates to:
  /// **'8+ characters'**
  String get authWizardRuleLength;

  /// Create account, email code: resend button when it works.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authWizardResendCode;

  /// Create account, email code: resend button while waiting, e.g. 'Resend in 0:45'.
  ///
  /// In en, this message translates to:
  /// **'Resend in {time}'**
  String authWizardResendIn(String time);

  /// Create account, email code: before the resend button.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it?'**
  String get authWizardDidntGetIt;

  /// Create account, email code: after the resend button.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder too.'**
  String get authWizardCheckSpam;

  /// Create account, code expired: bold start of the note; keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'The old code can no longer be used. '**
  String get authWizardOldCodeTitle;

  /// Create account, code expired: tries on the new code.
  ///
  /// In en, this message translates to:
  /// **'With a new code, you get 5 tries again.'**
  String get authWizardNewCodeTries;

  /// Create account, code expired: line under the dimmed code cells.
  ///
  /// In en, this message translates to:
  /// **'You can send a new one now · Check your spam folder too'**
  String get authWizardCanResendNow;

  /// Create account: screen-reader label of the loading placeholder while the selfie consent is read.
  ///
  /// In en, this message translates to:
  /// **'Checking the selfie consent'**
  String get authWizardCheckingConsent;

  /// Create account, ID step: label over the front photo.
  ///
  /// In en, this message translates to:
  /// **'Front of ID'**
  String get authWizardIdFront;

  /// Create account, ID step: label over the back photo.
  ///
  /// In en, this message translates to:
  /// **'Back of ID (optional)'**
  String get authWizardIdBack;

  /// Create account, ID step: the empty upload slot.
  ///
  /// In en, this message translates to:
  /// **'Add a photo · JPG or PNG'**
  String get authWizardAddPhoto;

  /// Create account, ID step: a photo is attached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get authWizardAttached;

  /// Create account, selfie tip.
  ///
  /// In en, this message translates to:
  /// **'Good light, facing the camera'**
  String get authWizardSelfieTipLight;

  /// Create account, selfie tip.
  ///
  /// In en, this message translates to:
  /// **'Whole face visible: no sunglasses, mask or cap'**
  String get authWizardSelfieTipFace;

  /// Create account, selfie tip.
  ///
  /// In en, this message translates to:
  /// **'Only you in the photo'**
  String get authWizardSelfieTipAlone;

  /// Create account, selfie step: camera button.
  ///
  /// In en, this message translates to:
  /// **'Take selfie'**
  String get authWizardTakeSelfie;

  /// Create account, review: which sides of the ID were added (mid-sentence, lower case).
  ///
  /// In en, this message translates to:
  /// **'front and back'**
  String get authWizardIdSidesBoth;

  /// Create account, review: only the front of the ID was added (mid-sentence, lower case).
  ///
  /// In en, this message translates to:
  /// **'front'**
  String get authWizardIdSidesFront;

  /// Create account, review: ID added with no type named.
  ///
  /// In en, this message translates to:
  /// **'Captured: {sides}'**
  String authWizardIdCaptured(String sides);

  /// Create account, review: no ID added.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get authWizardNotAdded;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authWizardRowName;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authWizardRowEmail;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get authWizardRowMobile;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get authWizardRowAddress;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Notice'**
  String get authWizardRowTerms;

  /// Create account, review: consent recorded.
  ///
  /// In en, this message translates to:
  /// **'Agreed · consent given'**
  String get authWizardTermsAgreed;

  /// Create account, review: consent not recorded yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet agreed'**
  String get authWizardTermsNotAgreed;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Valid ID'**
  String get authWizardRowId;

  /// Create account, review row label.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get authWizardRowSelfie;

  /// Create account, review: a selfie was taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get authWizardSelfieTaken;

  /// Create account, review: no selfie yet.
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get authWizardSelfieNotTaken;

  /// Create account, review: goes back to a step.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get authWizardEdit;

  /// Create account done (RegDone): title with no first name.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get authWizardDoneTitle;

  /// Create account done: title with the first name.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set, {name}!'**
  String authWizardDoneTitleNamed(String name);

  /// Create account done: message.
  ///
  /// In en, this message translates to:
  /// **'Your account is created and your details were sent to Taytay LGU for verification.'**
  String get authWizardDoneMessage;

  /// Create account done: card heading.
  ///
  /// In en, this message translates to:
  /// **'Account verification'**
  String get authWizardDoneVerification;

  /// Create account done: status pill.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get authWizardPendingReview;

  /// Create account done: what happens next.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU staff check your ID and selfie at the municipal office, in the office\'s own system. You\'ll get a notification in this app when they decide. Meanwhile you can browse services and news.'**
  String get authWizardDoneBody;

  /// Create account done: main button.
  ///
  /// In en, this message translates to:
  /// **'Continue to app'**
  String get authWizardContinueToApp;

  /// Screen-reader label of a required picker (barangay, type of ID).
  ///
  /// In en, this message translates to:
  /// **'{label}, required'**
  String authWizardPickerRequired(String label);

  /// Screen-reader value of a picker with nothing chosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get authWizardNotChosen;

  /// Create account, ID step: label over the account name the ID must show.
  ///
  /// In en, this message translates to:
  /// **'Name on your account'**
  String get authWizardNameOnAccount;

  /// Create account, terms: pill over the app's draft privacy summary.
  ///
  /// In en, this message translates to:
  /// **'DRAFT · Not yet published by Taytay LGU'**
  String get authWizardNoticeDraftPill;

  /// Create account, terms: screen-reader label while the notice loads.
  ///
  /// In en, this message translates to:
  /// **'Loading the Privacy Notice'**
  String get authWizardNoticeLoading;

  /// Create account, terms: the notice did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the Privacy Notice'**
  String get authWizardNoticeFailedHeading;

  /// Create account, terms: what to do when the notice did not load.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Read it before you acknowledge it below.'**
  String get authWizardNoticeFailedBody;

  /// Create account, terms: the published notice's version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String authWizardNoticeVersion(String version);

  /// Create account, terms: version and update date; {version} is authWizardNoticeVersion, {date} is ManilaTime.formatDate.
  ///
  /// In en, this message translates to:
  /// **'{version} · Updated {date}'**
  String authWizardNoticeUpdated(String version, String date);

  /// Create account, terms: the app's draft privacy summary (shown only while no notice is published).
  ///
  /// In en, this message translates to:
  /// **'The Municipality of Taytay collects your name, contact details, address, valid ID and selfie to create and verify your resident account and to deliver municipal services you request.'**
  String get authWizardDraftIntro;

  /// Draft privacy summary: point title.
  ///
  /// In en, this message translates to:
  /// **'How we use it'**
  String get authWizardDraftUseTitle;

  /// Draft privacy summary: how the data is used.
  ///
  /// In en, this message translates to:
  /// **'Identity and residency verification, service requests, and notices from the LGU.'**
  String get authWizardDraftUseBody;

  /// Draft privacy summary: point title.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get authWizardDraftWhoTitle;

  /// Draft privacy summary: who sees the data.
  ///
  /// In en, this message translates to:
  /// **'Authorised Taytay LGU personnel only.'**
  String get authWizardDraftWhoBody;

  /// Draft privacy summary: point title.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get authWizardDraftRightsTitle;

  /// Draft privacy summary: the data subject's rights (RA 10173).
  ///
  /// In en, this message translates to:
  /// **'To be informed, to access, correct, object and erase, and to file a complaint with the National Privacy Commission. Contact the LGU Data Protection Officer for requests.'**
  String get authWizardDraftRightsBody;

  /// Create account, terms: screen-reader name of the two document links.
  ///
  /// In en, this message translates to:
  /// **'Full documents'**
  String get authWizardFullDocuments;

  /// Create account, terms: opens the Terms of Use.
  ///
  /// In en, this message translates to:
  /// **'Read full Terms'**
  String get authWizardReadTerms;

  /// Create account, terms: opens the Privacy Notice.
  ///
  /// In en, this message translates to:
  /// **'Read full Privacy Notice'**
  String get authWizardReadPrivacy;

  /// Create account, selfie: screen-reader label of the drawn guide once a selfie is in.
  ///
  /// In en, this message translates to:
  /// **'Selfie guide, selfie taken. Illustration, no real person.'**
  String get authWizardSelfieGuideTaken;

  /// Create account, selfie: screen-reader label of the drawn guide.
  ///
  /// In en, this message translates to:
  /// **'Selfie guide. Illustration, no real person.'**
  String get authWizardSelfieGuide;

  /// Create account, selfie: caption on the drawn guide.
  ///
  /// In en, this message translates to:
  /// **'Illustration · no real person'**
  String get authWizardIllustration;

  /// Confirmation title before signing out of this phone.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get acctSignOutTitle;

  /// Sign-out confirmation: what signing out means.
  ///
  /// In en, this message translates to:
  /// **'You will need a new one-time code to sign in again. You can still browse Taytay services, offices and announcements as a guest.'**
  String get acctSignOutBody;

  /// Confirmation title before signing out another device. device = the device's name as the server lists it.
  ///
  /// In en, this message translates to:
  /// **'Sign out {device}?'**
  String acctRevokeOneTitle(String device);

  /// Confirmation body before signing out one other device.
  ///
  /// In en, this message translates to:
  /// **'That device will be signed out of your Taytay LGU IDS account. Whoever is using it will need a new one-time code sent to your mobile number to sign in again. This device stays signed in.'**
  String get acctRevokeOneBody;

  /// Confirm button: sign out one other device.
  ///
  /// In en, this message translates to:
  /// **'Sign out that device'**
  String get acctRevokeOneAction;

  /// Confirmation title before signing out every other device.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices?'**
  String get acctRevokeOthersTitle;

  /// Confirmation body before signing out every other device.
  ///
  /// In en, this message translates to:
  /// **'Every other phone, tablet or computer signed in to your Taytay LGU IDS account will be signed out. This device stays signed in. Anyone using the others will need a new one-time code sent to your mobile number.'**
  String get acctRevokeOthersBody;

  /// Confirm button: sign out every other device.
  ///
  /// In en, this message translates to:
  /// **'Sign out the others'**
  String get acctRevokeOthersAction;

  /// Confirmation title before the resident closes a conversation with an office.
  ///
  /// In en, this message translates to:
  /// **'Close this conversation?'**
  String get acctCloseConversationTitle;

  /// Confirmation body before closing a conversation.
  ///
  /// In en, this message translates to:
  /// **'The office will see it as closed. You can start a new message afterwards.'**
  String get acctCloseConversationBody;

  /// Button and menu row that closes a conversation with an office.
  ///
  /// In en, this message translates to:
  /// **'Close conversation'**
  String get acctCloseConversationAction;

  /// Dialog title when a profile save did not go through.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed'**
  String get acctNothingChangedTitle;

  /// Dialog body when a profile save did not go through.
  ///
  /// In en, this message translates to:
  /// **'Your profile was not updated. You can try again.'**
  String get acctNothingChangedBody;

  /// Dialog title when the app could not tell whether a profile save reached the LGU.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get acctNotConfirmedTitle;

  /// Dialog body when the outcome of a profile save is unknown.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your profile was updated. Saving again is safe: the same change is sent again.'**
  String get acctNotConfirmedBody;

  /// Dialog title when the LGU refused a name change.
  ///
  /// In en, this message translates to:
  /// **'Your name was not changed'**
  String get acctNameNotChangedTitle;

  /// A refused change (name or barangay): reason = the lock's own sentence, then that nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'{reason} Nothing was saved.'**
  String acctRefusedNothingSaved(String reason);

  /// A refused change when the save also held other changes: reason = the lock's sentence.
  ///
  /// In en, this message translates to:
  /// **'{reason} Nothing was saved. Save again to keep your other changes.'**
  String acctRefusedNothingSavedKeepOthers(String reason);

  /// Settings row and dialog title: the app's language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get acctLanguageTitle;

  /// Dialog: how the app chooses its language.
  ///
  /// In en, this message translates to:
  /// **'The app follows the language of this phone.'**
  String get acctLanguageBody;

  /// Dialog title after a password change.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get acctPasswordUpdatedTitle;

  /// Dialog body after a password change.
  ///
  /// In en, this message translates to:
  /// **'Use the new password the next time you sign in.'**
  String get acctPasswordUpdatedBody;

  /// Bell button label in the header, and the Notifications heading on Settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get acctNotifications;

  /// Screen-reader label of the skeleton while My Account loads.
  ///
  /// In en, this message translates to:
  /// **'Loading your account'**
  String get acctLoadingAccount;

  /// Gold button on My Account that opens the digital ID.
  ///
  /// In en, this message translates to:
  /// **'My Taytay ID'**
  String get acctMyTaytayId;

  /// Screen-reader label of the thread's three-dot menu button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get acctMore;

  /// Screen-reader part of an inbox row: how many unread replies.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String acctUnreadCount(int count);

  /// Beside the SAMPLE tag under the inbox, only in a build on sample data.
  ///
  /// In en, this message translates to:
  /// **'messages for illustration'**
  String get acctSampleMessages;

  /// Beside the SAMPLE tag under a conversation, only in a build on sample data.
  ///
  /// In en, this message translates to:
  /// **'conversation for illustration'**
  String get acctSampleConversation;

  /// Link and button that retries a failed read.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get acctRetry;

  /// Empty inbox title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get acctInboxEmptyTitle;

  /// Empty inbox message.
  ///
  /// In en, this message translates to:
  /// **'Questions you send to municipal offices and their replies will appear here.'**
  String get acctInboxEmptyBody;

  /// Empty inbox button that opens the office directory.
  ///
  /// In en, this message translates to:
  /// **'Message an office'**
  String get acctMessageAnOffice;

  /// Small line under the empty inbox.
  ///
  /// In en, this message translates to:
  /// **'Messaging is available to verified residents.'**
  String get acctMessagingVerifiedOnly;

  /// Inbox error title when there is no connection.
  ///
  /// In en, this message translates to:
  /// **'Messages did not load'**
  String get acctInboxErrorTitle;

  /// Inbox error message when there is no connection.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not be reached. You can try again.'**
  String get acctInboxErrorBody;

  /// Edit profile footer button.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get acctSaveChanges;

  /// Screen-reader label of the Edit profile skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile'**
  String get acctLoadingProfile;

  /// Screen-reader label of the initials disc on Edit profile.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get acctProfilePhoto;

  /// Line beside the initials disc on Edit profile.
  ///
  /// In en, this message translates to:
  /// **'Profile photo · reviewed by LGU before it appears on your ID'**
  String get acctProfilePhotoNote;

  /// Screen-reader label of the lock icon on a read-only field.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed here'**
  String get acctCannotChangeHere;

  /// Design line under the display name on Edit profile.
  ///
  /// In en, this message translates to:
  /// **'Legal name changes go through Resident Profile and re-verification.'**
  String get acctLegalNameNote;

  /// Settings row that opens the notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get acctNotificationSettings;

  /// Detail under Notification settings.
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU tells you about'**
  String get acctNotificationSettingsDetail;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get acctSectionApp;

  /// Detail under the Language row: the two languages the app speaks.
  ///
  /// In en, this message translates to:
  /// **'English · Filipino'**
  String get acctLanguageOptions;

  /// Settings row and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get acctChangePassword;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get acctSectionPrivacy;

  /// Document title (the LGU's RA 10173 notice): settings row, page title and notice heading.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get acctPrivacyNotice;

  /// Detail under the Privacy Notice row.
  ///
  /// In en, this message translates to:
  /// **'Data Privacy Act of 2012 · LGU-approved text pending'**
  String get acctPrivacyNoticeDetail;

  /// Settings row that opens the consents page.
  ///
  /// In en, this message translates to:
  /// **'Your consents'**
  String get acctYourConsents;

  /// Detail under Your consents.
  ///
  /// In en, this message translates to:
  /// **'Review or withdraw what you agreed to'**
  String get acctYourConsentsDetail;

  /// Data-export row and button (hidden while the API has no export).
  ///
  /// In en, this message translates to:
  /// **'Request a copy of my data'**
  String get acctRequestDataCopy;

  /// Detail under the data-export row (hidden while the API has no export).
  ///
  /// In en, this message translates to:
  /// **'Right to access'**
  String get acctRightToAccess;

  /// Screen-reader label of the municipal seal image.
  ///
  /// In en, this message translates to:
  /// **'Seal of Taytay, Rizal'**
  String get acctSealLabel;

  /// Line under the app name on About. version = the app version number.
  ///
  /// In en, this message translates to:
  /// **'Municipality of Taytay, Rizal · version {version}'**
  String acctAboutVersion(String version);

  /// Section heading listing the welcome photographs and who took them.
  ///
  /// In en, this message translates to:
  /// **'Photo credits'**
  String get acctPhotoCredits;

  /// Row on About and the title of the office-banner credits page.
  ///
  /// In en, this message translates to:
  /// **'Office banner photos'**
  String get acctOfficeBannerPhotos;

  /// Detail under Office banner photos: how many photos, and where they come from.
  ///
  /// In en, this message translates to:
  /// **'{count} photos · Wikimedia Commons'**
  String acctBannerSummary(int count);

  /// Section heading on the About page.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get acctSectionAbout;

  /// Row on About.
  ///
  /// In en, this message translates to:
  /// **'Municipal seal'**
  String get acctMunicipalSeal;

  /// Detail under Municipal seal.
  ///
  /// In en, this message translates to:
  /// **'Described on taytayrizal.gov.ph/seal · Wikimedia'**
  String get acctMunicipalSealDetail;

  /// Screen-reader label of the privacy notice skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading the privacy notice'**
  String get acctLoadingPrivacyNotice;

  /// Pill on the bundled draft notice (non-production builds only).
  ///
  /// In en, this message translates to:
  /// **'DRAFT · LGU-approved text to be inserted'**
  String get acctDraftPill;

  /// Draft privacy notice point heading (non-production builds only).
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get acctNoticeCollectTitle;

  /// Draft privacy notice point (non-production builds only).
  ///
  /// In en, this message translates to:
  /// **'Name, contact details, address, valid ID and selfie, and messages you send to offices.'**
  String get acctNoticeCollectBody;

  /// Draft privacy notice point heading.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get acctNoticeWhyTitle;

  /// Draft privacy notice point.
  ///
  /// In en, this message translates to:
  /// **'To verify that you are a Taytay resident and to deliver the services you request.'**
  String get acctNoticeWhyBody;

  /// Draft privacy notice point heading.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get acctNoticeWhoTitle;

  /// Draft privacy notice point.
  ///
  /// In en, this message translates to:
  /// **'Authorised LGU staff of the office you deal with. Not sold or shared for marketing.'**
  String get acctNoticeWhoBody;

  /// Draft privacy notice point heading.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get acctNoticeRightsTitle;

  /// Draft privacy notice point; a SAMPLE tag and a full stop follow it on screen.
  ///
  /// In en, this message translates to:
  /// **'Access, correction, objection and erasure. Contact the LGU Data Protection Officer'**
  String get acctNoticeRightsBody;

  /// Shown when the LGU has not published its notice yet (production).
  ///
  /// In en, this message translates to:
  /// **'The privacy notice will appear here when Taytay LGU publishes it.'**
  String get acctNoticePending;

  /// First half of the banner page intro; the gold 'Replace' pill is drawn after it, then acctBannersIntroAfter. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'All from Wikimedia Commons. Photos marked '**
  String get acctBannersIntroBefore;

  /// Second half of the banner page intro, after the 'Replace' pill. Keep the leading space.
  ///
  /// In en, this message translates to:
  /// **' show people and are placeholders until Taytay LGU supplies its own consented photos.'**
  String get acctBannersIntroAfter;

  /// Gold pill on a placeholder photo of people, to be replaced by an LGU photo.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get acctReplaceMark;

  /// Screen-reader label of the message list in a conversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get acctConversation;

  /// Shown where the composer was, on a closed conversation.
  ///
  /// In en, this message translates to:
  /// **'This conversation is closed.'**
  String get acctConversationClosed;

  /// A file in a message, and the composer label for a chosen earlier file.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get acctAttachment;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'DSWD relief distribution (2026 earthquake)'**
  String get acctPhotoReliefDistribution;

  /// Photo caption in the credits (matches welcomeServicesTag).
  ///
  /// In en, this message translates to:
  /// **'Taytay Municipal Hall'**
  String get acctPhotoMunicipalHall;

  /// Photo caption in the credits (matches welcomePrivacyTag).
  ///
  /// In en, this message translates to:
  /// **'St. John the Baptist Parish Church'**
  String get acctPhotoParishChurch;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Philippine peso notes and coins'**
  String get acctPhotoPesoNotes;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Street in Muzon, Taytay'**
  String get acctPhotoMuzonStreet;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Sari-sari store, Manila'**
  String get acctPhotoSariSari;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'BFP rescuers, Angeles City'**
  String get acctPhotoRescuers;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Rescue vehicle, Bula'**
  String get acctPhotoRescueVehicle;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'TESDA skills training'**
  String get acctPhotoSkillsTraining;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Sangguniang Kabataan council'**
  String get acctPhotoSkCouncil;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'SK basketball court'**
  String get acctPhotoSkCourt;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Barangay health center, Bula'**
  String get acctPhotoHealthCentre;

  /// Photo caption in the credits.
  ///
  /// In en, this message translates to:
  /// **'Vaccination, Camarines Sur'**
  String get acctPhotoVaccination;

  /// Messages row detail when no thread has an unread reply.
  ///
  /// In en, this message translates to:
  /// **'No new replies'**
  String get acctMessagesNoneUnread;

  /// Messages row detail: unread replies, and the office of the newest thread (its name as the server gives it).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new reply from {office}} other{{count} new replies from {office}}}'**
  String acctMessagesUnread(int count, String office);

  /// Name stand-in when the record has none; Account screen status line.
  ///
  /// In en, this message translates to:
  /// **'Verified resident'**
  String get acctVerifiedResident;

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Resident Profile'**
  String get acctMenuProfile;

  /// Detail under Resident Profile before the record loads.
  ///
  /// In en, this message translates to:
  /// **'Name, contact, barangay'**
  String get acctMenuProfileDetail;

  /// Detail under Resident Profile: how much of the profile is filled.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String acctMenuProfileComplete(int percent);

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Sectors and benefits'**
  String get acctMenuSectors;

  /// Menu row and the title of the inbox and a conversation (until its office loads).
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get acctMessages;

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get acctMenuVerification;

  /// Detail under Verification status: the date the LGU verified the account (Manila calendar date).
  ///
  /// In en, this message translates to:
  /// **'Verified · {date}'**
  String acctVerifiedOn(String date);

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Request documents'**
  String get acctMenuRequestDocuments;

  /// Detail under Request documents.
  ///
  /// In en, this message translates to:
  /// **'Certificates and copies from offices'**
  String get acctMenuRequestDocumentsDetail;

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get acctMenuHousehold;

  /// Detail under Household.
  ///
  /// In en, this message translates to:
  /// **'Address and your place in it'**
  String get acctMenuHouseholdDetail;

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get acctMenuSettings;

  /// Detail under Settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications, language'**
  String get acctMenuSettingsDetail;

  /// Menu row.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get acctMenuPrivacy;

  /// Detail under Privacy & data.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice, your data rights'**
  String get acctMenuPrivacyDetail;

  /// Menu row and the About page title.
  ///
  /// In en, this message translates to:
  /// **'Photo credits & about'**
  String get acctMenuCredits;

  /// Detail under Photo credits & about.
  ///
  /// In en, this message translates to:
  /// **'Licences, app version'**
  String get acctMenuCreditsDetail;

  /// Line under the error when the verified home could not read the record.
  ///
  /// In en, this message translates to:
  /// **'Verified by Taytay LGU'**
  String get acctVerifiedByLgu;

  /// Error under a conversation.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot attach a file.'**
  String get acctCannotAttach;

  /// Error under a conversation.
  ///
  /// In en, this message translates to:
  /// **'Write a message before sending.'**
  String get acctWriteBeforeSending;

  /// Page title.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get acctEditProfile;

  /// Field label on Edit profile.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get acctFieldEmail;

  /// Page title.
  ///
  /// In en, this message translates to:
  /// **'Settings & privacy'**
  String get acctSettingsTitle;

  /// Page title and the Account row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and security'**
  String get acctSecurityTitle;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get acctAppLock;

  /// Explains the app lock.
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint, face or screen lock before showing your details again after you leave the app.'**
  String get acctAppLockLede;

  /// Switch row.
  ///
  /// In en, this message translates to:
  /// **'Lock this app'**
  String get acctLockThisApp;

  /// Note under the app lock switch.
  ///
  /// In en, this message translates to:
  /// **'This lock protects this phone only. It is not how Taytay LGU knows who you are, and turning it on does not change what your account can do.'**
  String get acctAppLockNote;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Where you are signed in'**
  String get acctWhereSignedIn;

  /// Section heading, and the detail on the row for the phone in hand.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get acctThisDevice;

  /// Explains signing out.
  ///
  /// In en, this message translates to:
  /// **'Signing out removes your session from this phone. Public Taytay services stay available to you as a guest.'**
  String get acctSignOutLede;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device'**
  String get acctSignOutThisDevice;

  /// App lock switch detail when on.
  ///
  /// In en, this message translates to:
  /// **'On. You will be asked to unlock when you come back to the app.'**
  String get acctLockOn;

  /// App lock switch detail when off.
  ///
  /// In en, this message translates to:
  /// **'Off.'**
  String get acctLockOff;

  /// App lock switch detail when the phone has no lock set up.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint, face unlock or screen lock in your phone settings to use this.'**
  String get acctLockNotEnrolled;

  /// App lock switch detail when the phone has no unlock prompt.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot show an unlock prompt, so the app lock is not available here.'**
  String get acctLockUnsupported;

  /// Message after the resident cancelled the unlock prompt.
  ///
  /// In en, this message translates to:
  /// **'App lock was not turned on. You can try again any time.'**
  String get acctLockCancelled;

  /// Message after a failed unlock.
  ///
  /// In en, this message translates to:
  /// **'That did not match, so the app lock stays off.'**
  String get acctLockFailed;

  /// Message after the prompt could not show.
  ///
  /// In en, this message translates to:
  /// **'Your phone could not show the unlock prompt.'**
  String get acctLockUnavailable;

  /// Screen-reader label of the device list skeleton.
  ///
  /// In en, this message translates to:
  /// **'Checking where you are signed in'**
  String get acctCheckingSignIns;

  /// Error title when the device list could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not check your sign-ins'**
  String get acctSignInsErrorTitle;

  /// Error message when the device list could not be read.
  ///
  /// In en, this message translates to:
  /// **'We could not reach Taytay LGU IDS to list where your account is signed in. Try again in a moment. Signing out here always ends this device\'s session.'**
  String get acctSignInsErrorBody;

  /// Explains the Check my devices button.
  ///
  /// In en, this message translates to:
  /// **'Check the devices your Taytay LGU IDS account is currently signed in on.'**
  String get acctCheckDevicesLede;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Check my devices'**
  String get acctCheckMyDevices;

  /// Button (shown only when there are two or more other devices).
  ///
  /// In en, this message translates to:
  /// **'Sign out all {count} other devices'**
  String acctSignOutOtherDevices(int count);

  /// Device row detail when the server gives no last-used time.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get acctSignedIn;

  /// Device row detail. date = day/month/year in Manila, digits only (e.g. 22/10/2026).
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String acctLastUsed(String date);

  /// Page title.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get acctAccountTitle;

  /// Name stand-in when the session holds no name.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get acctResident;

  /// Status line for a guest.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get acctNotSignedIn;

  /// Status line for an unverified account.
  ///
  /// In en, this message translates to:
  /// **'Account not yet verified'**
  String get acctNotYetVerified;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get acctPreferences;

  /// Switch row.
  ///
  /// In en, this message translates to:
  /// **'Vibration feedback'**
  String get acctVibration;

  /// Switch detail.
  ///
  /// In en, this message translates to:
  /// **'Short vibrations when an action succeeds or fails.'**
  String get acctVibrationDetail;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get acctSectionSecurity;

  /// Detail under Sign-in and security.
  ///
  /// In en, this message translates to:
  /// **'App lock, signing out, and where you are signed in.'**
  String get acctSecurityDetail;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Service status'**
  String get acctServiceStatus;

  /// Explains the service status check.
  ///
  /// In en, this message translates to:
  /// **'Check whether Taytay LGU services are reachable. This helps tell a service outage from a connection problem.'**
  String get acctServiceStatusLede;

  /// Button label while the status check runs.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get acctChecking;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Check service status'**
  String get acctCheckServiceStatus;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get acctCurrentPassword;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get acctNewPassword;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Repeat the new password'**
  String get acctRepeatNewPassword;

  /// Field error.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get acctEnterCurrentPassword;

  /// Field error.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password.'**
  String get acctEnterNewPassword;

  /// Field error: new and repeated password differ.
  ///
  /// In en, this message translates to:
  /// **'Those passwords do not match.'**
  String get acctPasswordsDoNotMatch;

  /// Field error: Firebase refused the current password.
  ///
  /// In en, this message translates to:
  /// **'That password does not match.'**
  String get acctPasswordWrong;

  /// Field error: the new password is too weak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters, with a letter and a number.'**
  String get acctPasswordWeak;

  /// Save button label while the change runs.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get acctSaving;

  /// Save button.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get acctSavePassword;

  /// Settings page title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings: section heading for account rows (signed in only).
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get settingsSectionYourAccount;

  /// Settings: row that opens the account page.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsRowAccountTitle;

  /// Settings: detail under the Account row.
  ///
  /// In en, this message translates to:
  /// **'Your details and how you sign in'**
  String get settingsRowAccountDetail;

  /// Settings: row that opens sign-in and security.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and security'**
  String get settingsRowSecurityTitle;

  /// Settings: detail under Sign-in and security.
  ///
  /// In en, this message translates to:
  /// **'App lock and devices'**
  String get settingsRowSecurityDetail;

  /// Settings: row that opens notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsRowNotificationsTitle;

  /// Settings: detail under Notifications.
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU tells you about'**
  String get settingsRowNotificationsDetail;

  /// Settings: section heading for privacy rows.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// Settings: row that opens the privacy notice. Document name, kept in English.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get settingsRowPrivacyNoticeTitle;

  /// Settings: detail under Privacy notice.
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU holds, and your rights'**
  String get settingsRowPrivacyNoticeDetail;

  /// Settings: row that opens the consents and account requests page.
  ///
  /// In en, this message translates to:
  /// **'Your consents and account requests'**
  String get settingsRowConsentsTitle;

  /// Settings: detail under the consents row.
  ///
  /// In en, this message translates to:
  /// **'What you agreed to, and asking for changes'**
  String get settingsRowConsentsDetail;

  /// Settings: section heading for motion and vibration.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsSectionAccessibility;

  /// Settings section heading, and the Help page title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Settings: row that opens the Help page.
  ///
  /// In en, this message translates to:
  /// **'Help and contacting Taytay LGU'**
  String get settingsRowHelpTitle;

  /// Settings: detail under the Help row.
  ///
  /// In en, this message translates to:
  /// **'Questions, and where to go in person'**
  String get settingsRowHelpDetail;

  /// Settings: section heading for the about card.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings: switch that reduces animations.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotionTitle;

  /// Settings: detail under Reduce motion when the phone already asks for it.
  ///
  /// In en, this message translates to:
  /// **'Already on, because your phone is set to reduce motion.'**
  String get settingsReduceMotionOsOn;

  /// Settings: detail under Reduce motion.
  ///
  /// In en, this message translates to:
  /// **'Shortens or removes animations.'**
  String get settingsReduceMotionDetail;

  /// Settings: switch for haptic feedback.
  ///
  /// In en, this message translates to:
  /// **'Vibration feedback'**
  String get settingsVibrationTitle;

  /// Settings: detail under Vibration feedback.
  ///
  /// In en, this message translates to:
  /// **'Short buzzes when something is confirmed.'**
  String get settingsVibrationDetail;

  /// Settings: note under the accessibility switches.
  ///
  /// In en, this message translates to:
  /// **'Text size follows your phone. This app is built to stay readable at the largest setting.'**
  String get settingsTextSizeNote;

  /// Settings: statement shown when the app collects no usage data.
  ///
  /// In en, this message translates to:
  /// **'This app sends no information about how you use it to anyone. It contacts Taytay LGU only to show you what you asked for.'**
  String get settingsTelemetryNone;

  /// Settings: switch for usage data.
  ///
  /// In en, this message translates to:
  /// **'Help improve this app'**
  String get settingsTelemetryTitle;

  /// Settings: detail under the usage-data switch.
  ///
  /// In en, this message translates to:
  /// **'Sends which screens are opened and whether things worked. Never your name, your documents, what you applied for, or anything you typed.'**
  String get settingsTelemetryDetail;

  /// Settings: about card, first paragraph.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU IDS is the resident app for the Municipality of Taytay, Rizal. It is published by the municipal government.'**
  String get settingsAboutBody;

  /// Settings: about card, second paragraph.
  ///
  /// In en, this message translates to:
  /// **'This app is one way to reach Taytay LGU. The municipal hall and your barangay hall handle everything it does, and more.'**
  String get settingsAboutReach;

  /// Settings: the app version line.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// Settings: bold lead-in of the test-build note. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Test build. '**
  String get settingsTestBuildTitle;

  /// Settings: test-build note. environment is a short badge like STAGING.
  ///
  /// In en, this message translates to:
  /// **'This is a {environment} build, not the app published to residents.'**
  String settingsTestBuildBody(String environment);

  /// Settings: sign-out confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get settingsSignOutTitle;

  /// Settings: sign-out confirmation consequence.
  ///
  /// In en, this message translates to:
  /// **'You will need your mobile number and a code to sign back in. Nothing you have sent Taytay LGU is removed.'**
  String get settingsSignOutConsequence;

  /// Settings: cancel button of the sign-out confirmation.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in'**
  String get settingsStaySignedIn;

  /// Consents page title.
  ///
  /// In en, this message translates to:
  /// **'Consents and account requests'**
  String get settingsConsentsTitle;

  /// Consents page: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your consents'**
  String get settingsLoadingConsents;

  /// Consents page section heading, and the name of a selfie consent row.
  ///
  /// In en, this message translates to:
  /// **'Selfie consent'**
  String get settingsSelfieConsent;

  /// Consents page: section heading for the consent history.
  ///
  /// In en, this message translates to:
  /// **'What you agreed to'**
  String get settingsSectionAgreed;

  /// Consents page: empty history.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has no consents recorded for you.'**
  String get settingsNoConsents;

  /// Consents page: section heading for account requests.
  ///
  /// In en, this message translates to:
  /// **'Asking Taytay LGU for changes'**
  String get settingsSectionAskingChanges;

  /// Consents page: account requests are not offered.
  ///
  /// In en, this message translates to:
  /// **'These requests are not switched on in this app yet. The municipal hall can take them in person, and your barangay hall can tell you where to go.'**
  String get settingsRequestsNotOn;

  /// Consents page: button for a record correction.
  ///
  /// In en, this message translates to:
  /// **'Ask for a correction'**
  String get settingsAskCorrection;

  /// Consents page: notice after Ask for a correction.
  ///
  /// In en, this message translates to:
  /// **'Corrections to your resident record are made by Taytay LGU. Use the correction path on your household or profile screen so the office knows which record you mean.'**
  String get settingsCorrectionNotice;

  /// Consents page: bold lead-in of the re-authentication note. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'You may be asked to sign in again. '**
  String get settingsReauthTitle;

  /// Consents page: re-authentication note.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU asks residents to confirm who they are before changes like these.'**
  String get settingsReauthBody;

  /// Consents page: screen-reader label while the selfie consent loads.
  ///
  /// In en, this message translates to:
  /// **'Checking the selfie consent'**
  String get settingsCheckingSelfieConsent;

  /// Consents page: the selfie consent could not be read.
  ///
  /// In en, this message translates to:
  /// **'Where your selfie consent stands could not be read. Check your connection and try again.'**
  String get settingsSelfieConsentUnreadable;

  /// Consents page: no selfie consent is published.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not published a selfie consent yet, so the app takes no selfie and holds no consent for one.'**
  String get settingsSelfieConsentUnpublished;

  /// Consents page: the resident has not agreed to the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'You have not agreed to the selfie consent. The app asks before it takes any selfie, and you can verify in person instead.'**
  String get settingsSelfieConsentOwed;

  /// Consents page: the selfie consent is given, no date known.
  ///
  /// In en, this message translates to:
  /// **'You agreed that Taytay LGU may take and use your selfie (version {version}).'**
  String settingsSelfieConsentGiven(String version);

  /// Consents page: the selfie consent is given, with its date.
  ///
  /// In en, this message translates to:
  /// **'You agreed on {date} that Taytay LGU may take and use your selfie (version {version}).'**
  String settingsSelfieConsentGivenOn(String date, String version);

  /// Consents page: heading of the note that says what withdrawing the selfie consent does.
  ///
  /// In en, this message translates to:
  /// **'What withdrawing does'**
  String get settingsWhatWithdrawingDoes;

  /// Consents page: after withdrawing the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has recorded your withdrawal, and your selfies were erased.'**
  String get settingsBiometricWithdrawn;

  /// Consents page: a withdrawal whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your withdrawal was recorded. Trying again is safe: it is recorded only once.'**
  String get settingsWithdrawalUnconfirmed;

  /// Consents page: a withdrawal that failed.
  ///
  /// In en, this message translates to:
  /// **'That withdrawal was not recorded. Nothing has changed, and you can try again.'**
  String get settingsWithdrawalNotRecorded;

  /// Consents page: after withdrawing a consent.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has recorded your withdrawal.'**
  String get settingsWithdrawalRecorded;

  /// Consents page: after accepting a withdrawn consent again.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has recorded this consent again.'**
  String get settingsConsentRecordedAgain;

  /// Consents page: an acceptance whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your consent was recorded. Trying again is safe: it is recorded only once.'**
  String get settingsConsentUnconfirmed;

  /// Consents page: an acceptance that failed.
  ///
  /// In en, this message translates to:
  /// **'That consent was not recorded. Nothing has changed, and you can try again.'**
  String get settingsConsentNotRecorded;

  /// Consents page: withdrawal confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this consent?'**
  String get settingsWithdrawConsentTitle;

  /// Consents page: withdrawal confirmation consequence.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU will stop relying on this consent from the moment it is recorded. Anything already done under it stays as it is — a withdrawal is not backdated.'**
  String get settingsWithdrawConsentConsequence;

  /// Consents page: confirm button of the withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdraw it'**
  String get settingsWithdrawIt;

  /// Consents page: cancel button of the withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Leave it in place'**
  String get settingsLeaveInPlace;

  /// Consents page: date line on a consent card.
  ///
  /// In en, this message translates to:
  /// **'Agreed {date}'**
  String settingsConsentAgreedOn(String date);

  /// Consents page: date line on a withdrawn consent card.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn {date}'**
  String settingsConsentWithdrawnOn(String date);

  /// Consents page: screen-reader label of an active consent's icon.
  ///
  /// In en, this message translates to:
  /// **'In force'**
  String get settingsConsentInForce;

  /// Consents page: screen-reader label of a withdrawn consent's icon.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get settingsConsentWithdrawn;

  /// Consents page: button on a consent card.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this consent'**
  String get settingsWithdrawConsent;

  /// Consents page: button on a withdrawn consent card.
  ///
  /// In en, this message translates to:
  /// **'Accept again'**
  String get settingsAcceptAgain;

  /// Name of the Terms of Use document (consent rows, read sheet title). Kept in English.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsConsentKindTerms;

  /// Name of the Privacy Notice document (consent rows, read sheet title). Kept in English.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get settingsConsentKindPrivacy;

  /// Consents page: name of a row an older app recorded for both texts at once.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Notice (earlier agreement)'**
  String get settingsConsentKindUnspecified;

  /// Fills {version} in the consent statements when the server named no version.
  ///
  /// In en, this message translates to:
  /// **'in force at the time'**
  String get settingsConsentVersionAtTheTime;

  /// Consents page: statement of a Terms of Use row.
  ///
  /// In en, this message translates to:
  /// **'Agreed to the Terms of Use, version {version}'**
  String settingsConsentStatementTerms(String version);

  /// Consents page: statement of a Privacy Notice row. Acknowledged, not agreed.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged the Privacy Notice, version {version}'**
  String settingsConsentStatementPrivacy(String version);

  /// Consents page: statement of a selfie consent row.
  ///
  /// In en, this message translates to:
  /// **'Agreed that Taytay LGU may use your selfie, version {version}'**
  String settingsConsentStatementBiometric(String version);

  /// Consents page: statement of a row an older app recorded for both texts.
  ///
  /// In en, this message translates to:
  /// **'Agreed to the Terms and the Privacy Notice together, version {version}'**
  String settingsConsentStatementUnspecified(String version);

  /// Consents page: the account-closing button and its confirm label.
  ///
  /// In en, this message translates to:
  /// **'Close my account'**
  String get settingsCloseAction;

  /// Consents page: what closing the account does, shown before the button (D-235).
  ///
  /// In en, this message translates to:
  /// **'Closing your account takes effect at once, and you cannot sign in to it again. Your name, birth date, contact details, address and profile photo are removed from it, your digital ID is cancelled, and the ID photos and selfies you sent are deleted. Your phones stop getting notices from this app. If you head a household in the app, that household is removed. Records that Taytay LGU offices keep about you, such as your record at the MSWDO office and the requests you filed, stay with those offices. This cannot be undone in the app.'**
  String get settingsCloseEffects;

  /// Consents page: account-closing confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Close your account?'**
  String get settingsCloseConfirmTitle;

  /// Consents page: account-closing confirmation consequence.
  ///
  /// In en, this message translates to:
  /// **'Your account closes now and you cannot sign in to it again. Your digital ID is cancelled, and your details, photos and ID pictures are removed from the account. Records that Taytay LGU offices keep about you stay with them. This cannot be undone in the app.'**
  String get settingsCloseConfirm;

  /// Consents page: after the account was closed.
  ///
  /// In en, this message translates to:
  /// **'Your account is closed. You cannot sign in to it again, and your digital ID is cancelled. Records that Taytay LGU offices keep about you stay with them.'**
  String get settingsClosed;

  /// Consents page: the account was closed by an earlier try.
  ///
  /// In en, this message translates to:
  /// **'Your account is already closed. You cannot sign in to it again.'**
  String get settingsCloseAlreadyClosed;

  /// Consents page: a close whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your account was closed. Trying again is safe: an account is closed only once.'**
  String get settingsCloseNotConfirmed;

  /// Consents page: a close that failed.
  ///
  /// In en, this message translates to:
  /// **'Your account was not closed. Nothing has changed, and you can try again.'**
  String get settingsCloseNotClosed;

  /// Help page: section heading.
  ///
  /// In en, this message translates to:
  /// **'Getting help'**
  String get settingsHelpGettingHelp;

  /// Help page: introduction.
  ///
  /// In en, this message translates to:
  /// **'Everything in this app is also handled at the Taytay municipal hall and at your barangay hall. If something here will not work, going in person is never the wrong answer.'**
  String get settingsHelpIntro;

  /// Help page FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account to use this app?'**
  String get settingsFaqAccountQuestion;

  /// Help page FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'No. Announcements, events and the list of municipal services are open to everyone. You only need an account for things about you — your applications, your documents, your ID.'**
  String get settingsFaqAccountAnswer;

  /// Help page FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Why does it ask me to verify my identity?'**
  String get settingsFaqVerifyQuestion;

  /// Help page FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Some services act on your resident record with Taytay LGU, so the office has to know it is you. Verifying is done once and unlocks those services.'**
  String get settingsFaqVerifyAnswer;

  /// Help page FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How long will my application take?'**
  String get settingsFaqDurationQuestion;

  /// Help page FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU decides that, and it depends on the service and the documents. This app shows you where your application is and what is needed next, but it cannot promise a date.'**
  String get settingsFaqDurationAnswer;

  /// Help page FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Something in my record is wrong.'**
  String get settingsFaqRecordQuestion;

  /// Help page FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'You can report it from your profile or household screen. The office checks and corrects it — the app never changes your record directly.'**
  String get settingsFaqRecordAnswer;

  /// Help page FAQ question.
  ///
  /// In en, this message translates to:
  /// **'I lost my phone.'**
  String get settingsFaqLostPhoneQuestion;

  /// Help page FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Sign in on your new phone. If you think somebody else is using your account, tell the municipal hall, and sign out other devices from the sign-in and security screen.'**
  String get settingsFaqLostPhoneAnswer;

  /// Help page: bold lead-in of the contact note. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'Contacting Taytay LGU. '**
  String get settingsHelpContactTitle;

  /// Help page: contact note.
  ///
  /// In en, this message translates to:
  /// **'Use the contact details published on the service, programme or event you are asking about — those come from the office running it. Your barangay hall can always point you to the right desk.'**
  String get settingsHelpContactBody;

  /// Consent update: title when both texts changed.
  ///
  /// In en, this message translates to:
  /// **'The Terms of Use and the Privacy Notice have changed'**
  String get platformConsentBothChanged;

  /// Consent update: title when the Terms changed.
  ///
  /// In en, this message translates to:
  /// **'The Terms of Use have changed'**
  String get platformConsentTermsChanged;

  /// Consent update: title when the Privacy Notice changed.
  ///
  /// In en, this message translates to:
  /// **'The Privacy Notice has changed'**
  String get platformConsentPrivacyChanged;

  /// Consent update: changed line, no date published.
  ///
  /// In en, this message translates to:
  /// **'The Terms of Use were updated.'**
  String get platformTermsUpdated;

  /// Consent update: changed line with the date.
  ///
  /// In en, this message translates to:
  /// **'The Terms of Use were updated on {date}.'**
  String platformTermsUpdatedOn(String date);

  /// Consent update: changed line, no date published.
  ///
  /// In en, this message translates to:
  /// **'The Privacy Notice was updated.'**
  String get platformPrivacyUpdated;

  /// Consent update: changed line with the date.
  ///
  /// In en, this message translates to:
  /// **'The Privacy Notice was updated on {date}.'**
  String platformPrivacyUpdatedOn(String date);

  /// Consent update: agree button while recording.
  ///
  /// In en, this message translates to:
  /// **'Recording your agreement…'**
  String get platformConsentRecording;

  /// Consent update: agree button.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get platformConsentAgree;

  /// Consent update: continue without recording, after a failure.
  ///
  /// In en, this message translates to:
  /// **'Continue for now'**
  String get platformConsentContinueForNow;

  /// Consent update: explanation.
  ///
  /// In en, this message translates to:
  /// **'Please read what changed. To keep using your account, tick each text below to agree to it. If you do not agree, you can sign out and keep using the app as a guest.'**
  String get platformConsentReadChanges;

  /// Consent update: button that opens the Terms.
  ///
  /// In en, this message translates to:
  /// **'Read the Terms of Use'**
  String get platformReadTerms;

  /// Consent update: button that opens the Privacy Notice.
  ///
  /// In en, this message translates to:
  /// **'Read the Privacy Notice'**
  String get platformReadPrivacy;

  /// Consent update: recording's answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your agreement was recorded. Agreeing again is safe: it is recorded only once.'**
  String get platformAgreementUnconfirmed;

  /// Consent update: recording failed; reason is the failure's own sentence.
  ///
  /// In en, this message translates to:
  /// **'Your agreement was not recorded. {reason}'**
  String platformAgreementNotRecorded(String reason);

  /// Consent update: under a recording failure.
  ///
  /// In en, this message translates to:
  /// **'You can also continue for now without it. The app will ask again the next time you return to it.'**
  String get platformConsentContinueNote;

  /// Message composer: a first message whose answer was lost. 'Messages' is the screen name.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your message was received. Sending it again is safe: it will not be posted twice. You can also check Messages.'**
  String get messagingStartUnconfirmed;

  /// Message thread: a reply whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your message was received. Sending it again is safe: it will not be posted twice.'**
  String get messagingReplyUnconfirmed;

  /// Message composer: lead sentence of a failure that certainly did not send.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent.'**
  String get messagingNotSent;

  /// Message composer: a first message refused with a conflict.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Something went wrong on our side. Open Messages to check what the office has before trying again.'**
  String get messagingStartConflict;

  /// A calendar date on the verification and resident-profile screens, e.g. "Oct 22, 2026". The month name and order come from the locale (intl yMMMd).
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String verifDate(DateTime date);

  /// Empty ID photo slot: tap to choose a photo.
  ///
  /// In en, this message translates to:
  /// **'Upload new photo'**
  String get verifUploadNewPhoto;

  /// Empty optional slot (back of ID): tap to add a photo.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get verifAddPhoto;

  /// Selfie slot when the selfie already sent is kept for the resubmission.
  ///
  /// In en, this message translates to:
  /// **'Previous selfie kept'**
  String get verifPreviousSelfieKept;

  /// Empty selfie slot: tap to open the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a selfie'**
  String get verifTakeSelfie;

  /// Screen-reader label while the status loads.
  ///
  /// In en, this message translates to:
  /// **'Checking your verification status'**
  String get verifCheckingStatus;

  /// Error title when the status could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not check your status'**
  String get verifCouldNotCheckStatus;

  /// Photo slot after a replacement photo was sent to the office.
  ///
  /// In en, this message translates to:
  /// **'New photo sent'**
  String get verifNewPhotoSent;

  /// Photo slot after a photo was chosen but not yet sent.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get verifPhotoAdded;

  /// Field label and picker title: which kind of government ID.
  ///
  /// In en, this message translates to:
  /// **'Type of ID'**
  String get verifIdType;

  /// A kind of government ID in the ID-type picker.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s license'**
  String get verifIdTypeDriversLicense;

  /// A kind of government ID in the ID-type picker.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get verifIdTypePassport;

  /// A kind of government ID in the ID-type picker.
  ///
  /// In en, this message translates to:
  /// **'Other government ID'**
  String get verifIdTypeOther;

  /// Screen-reader label while the biometric (selfie) consent is read.
  ///
  /// In en, this message translates to:
  /// **'Checking the selfie consent'**
  String get verifSelfieConsentChecking;

  /// Heading of the note shown after the resident withdrew their selfie consent.
  ///
  /// In en, this message translates to:
  /// **'Your selfie was erased'**
  String get verifSelfieErasedHeading;

  /// Selfie slot after the selfie was erased.
  ///
  /// In en, this message translates to:
  /// **'Selfie erased: take a new one'**
  String get verifSelfieErasedSlot;

  /// Button: take a replacement selfie.
  ///
  /// In en, this message translates to:
  /// **'Take a new selfie'**
  String get verifSelfieRetake;

  /// Pending request whose selfie was erased after the consent was withdrawn. {date} is an already formatted date.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your selfie consent on {date}, so the selfie you sent was erased. Staff cannot approve this request until you send a new selfie, or you can verify in person instead.'**
  String verifSelfieErasedPendingOn(String date);

  /// As verifSelfieErasedPendingOn, when the server gave no time.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your selfie consent, so the selfie you sent was erased. Staff cannot approve this request until you send a new selfie, or you can verify in person instead.'**
  String get verifSelfieErasedPending;

  /// Returned request whose selfie was erased after the consent was withdrawn. {date} is an already formatted date.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your selfie consent on {date}, so the selfie you sent was erased. Send a new one with your ID, or verify in person instead.'**
  String verifSelfieErasedRejectedOn(String date);

  /// As verifSelfieErasedRejectedOn, when the server gave no time.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your selfie consent, so the selfie you sent was erased. Send a new one with your ID, or verify in person instead.'**
  String get verifSelfieErasedRejected;

  /// Card heading above the ID and selfie slots on a first start.
  ///
  /// In en, this message translates to:
  /// **'Send your valid ID'**
  String get verifSendValidId;

  /// Photo slot label.
  ///
  /// In en, this message translates to:
  /// **'Front of ID'**
  String get verifIdFront;

  /// Photo slot label.
  ///
  /// In en, this message translates to:
  /// **'Back of ID (optional)'**
  String get verifIdBackOptional;

  /// Photo slot label.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get verifSelfie;

  /// How the account was verified.
  ///
  /// In en, this message translates to:
  /// **'Verified in person at the Taytay LGU office.'**
  String get verifMethodInPerson;

  /// How the account was verified.
  ///
  /// In en, this message translates to:
  /// **'Verified with your valid ID and selfie.'**
  String get verifMethodSelfie;

  /// A selfie request the office closed because it verified the account in person, and the selfie was erased.
  ///
  /// In en, this message translates to:
  /// **'Replaced: you were verified in person at the office, so your selfie request was closed and the selfie you sent was erased.'**
  String get verifReplacedErased;

  /// A selfie request the office closed because it verified the account in person.
  ///
  /// In en, this message translates to:
  /// **'Replaced: you were verified in person at the office, so your selfie request was closed.'**
  String get verifReplaced;

  /// Header title of the verification status screens.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verifStatusTitle;

  /// Dialog title: optional note sent with a resubmission.
  ///
  /// In en, this message translates to:
  /// **'Message to Taytay LGU'**
  String get verifResubmitDialogTitle;

  /// Button that sends the corrected verification again.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for verification'**
  String get verifResubmit;

  /// Kind of information the office holds or asked to correct: name, birth date, civil status.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get verifCategoryPersonalDetails;

  /// Kind of information (issue label), and the address section/row title in the resident profile.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get verifAddress;

  /// Kind of information: mobile number or email.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get verifCategoryContact;

  /// Kind of information: the photo of the government ID.
  ///
  /// In en, this message translates to:
  /// **'ID photo'**
  String get verifCategoryIdPhoto;

  /// Kind of information: the selfie.
  ///
  /// In en, this message translates to:
  /// **'Photo of you'**
  String get verifCategoryPhoto;

  /// Kind of information this build does not recognise; the office's instruction is shown under it.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get verifCategoryOther;

  /// Status card title while the ID is under review.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your account'**
  String get verifPendingTitle;

  /// Status pill: waiting for the office to review.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get verifPendingChip;

  /// Status card body while pending.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU staff are checking your valid ID and selfie.'**
  String get verifPendingBody;

  /// Appended to the pending status body.
  ///
  /// In en, this message translates to:
  /// **'No action needed.'**
  String get verifNoActionNeeded;

  /// Card heading above the review timeline.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get verifProgress;

  /// Timeline step.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get verifStepAccountCreated;

  /// Timeline step.
  ///
  /// In en, this message translates to:
  /// **'Email confirmed'**
  String get verifStepEmailConfirmed;

  /// Timeline step.
  ///
  /// In en, this message translates to:
  /// **'Valid ID and selfie received'**
  String get verifStepIdReceived;

  /// Timeline step: the office reviews it.
  ///
  /// In en, this message translates to:
  /// **'LGU review'**
  String get verifStepLguReview;

  /// Timeline step detail: waiting its turn.
  ///
  /// In en, this message translates to:
  /// **'In queue'**
  String get verifStepInQueue;

  /// Timeline step detail under "Verified".
  ///
  /// In en, this message translates to:
  /// **'Unlocks document requests, messaging offices and applying for Tulong'**
  String get verifStepVerifiedDetail;

  /// When the ID was sent. {date} is an already formatted date and time.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String verifSubmittedOn(String date);

  /// Note under the pending status.
  ///
  /// In en, this message translates to:
  /// **'While pending you can browse services, news and events, and use emergency hotlines.'**
  String get verifPendingBrowseNote;

  /// Verified status body when no date is known.
  ///
  /// In en, this message translates to:
  /// **'You now have full access to resident services.'**
  String get verifVerifiedBody;

  /// Verified status body. {date} is an already formatted date.
  ///
  /// In en, this message translates to:
  /// **'Verified by Taytay LGU on {date}. You now have full access to resident services.'**
  String verifVerifiedBodyOn(String date);

  /// Footer button: back to the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get verifGoHome;

  /// Status card title.
  ///
  /// In en, this message translates to:
  /// **'Your account is verified'**
  String get verifVerifiedTitle;

  /// Card heading; the list below completes the sentence (Request documents, Message municipal offices...).
  ///
  /// In en, this message translates to:
  /// **'You can now'**
  String get verifYouCanNow;

  /// Item under "You can now".
  ///
  /// In en, this message translates to:
  /// **'Request documents'**
  String get verifCanRequestDocuments;

  /// Item detail.
  ///
  /// In en, this message translates to:
  /// **'Certificates, clearances and permits'**
  String get verifCanRequestDocumentsDetail;

  /// Item under "You can now".
  ///
  /// In en, this message translates to:
  /// **'Message municipal offices'**
  String get verifCanMessage;

  /// Item detail.
  ///
  /// In en, this message translates to:
  /// **'Ask questions and follow up requests'**
  String get verifCanMessageDetail;

  /// Item under "You can now".
  ///
  /// In en, this message translates to:
  /// **'Use your Taytay digital ID'**
  String get verifCanUseId;

  /// Item detail.
  ///
  /// In en, this message translates to:
  /// **'Show it at the municipal hall'**
  String get verifCanUseIdDetail;

  /// Row that opens the resident profile.
  ///
  /// In en, this message translates to:
  /// **'Complete your Resident Profile'**
  String get verifCompleteProfile;

  /// How complete the resident profile is.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String verifPercentComplete(int percent);

  /// Shown when the office returned the request without a reason.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU needs a correction before it can finish checking.'**
  String get verifCorrectionFallbackReason;

  /// Status title and pill: the office returned the request for a correction.
  ///
  /// In en, this message translates to:
  /// **'Needs correction'**
  String get verifNeedsCorrection;

  /// Heading above the note the resident sent with a correction.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get verifYourMessage;

  /// Card heading above the replacement photo slots.
  ///
  /// In en, this message translates to:
  /// **'Send a new valid ID'**
  String get verifSendNewValidId;

  /// Link on the kept selfie: take it again.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get verifRetake;

  /// Status title before verification starts.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get verifNotVerified;

  /// Status body before verification starts.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not confirmed this account. You can browse services while you send your valid ID and selfie, or verify in person.'**
  String get verifNotVerifiedBody;

  /// Heading over the kinds of information the office holds (never the values).
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU has from you'**
  String get verifHeldFromYou;

  /// Uppercase eyebrow over the office's reason, in its own words.
  ///
  /// In en, this message translates to:
  /// **'REASON FROM TAYTAY LGU'**
  String get verifReasonHeading;

  /// When the office reviewed it. {date} is an already formatted date.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String verifReviewedOn(String date);

  /// Second sentence of the verified-only gate.
  ///
  /// In en, this message translates to:
  /// **'Your account is not verified yet.'**
  String get verifGateNotVerifiedYet;

  /// Gate dialog title.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to open your digital ID'**
  String get verifGateTitleDigitalId;

  /// Gate dialog title.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to message offices'**
  String get verifGateTitleMessage;

  /// Gate dialog title.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to continue'**
  String get verifGateTitleOther;

  /// First sentence of the gate.
  ///
  /// In en, this message translates to:
  /// **'Messaging municipal offices is for verified Taytay residents.'**
  String get verifGateLeadMessage;

  /// First sentence of the gate.
  ///
  /// In en, this message translates to:
  /// **'Your Taytay digital ID is for verified Taytay residents.'**
  String get verifGateLeadDigitalId;

  /// First sentence of the gate.
  ///
  /// In en, this message translates to:
  /// **'This action is for verified Taytay residents.'**
  String get verifGateLeadOther;

  /// Screen-reader label while the barangay list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading barangays…'**
  String get verifKycLoadingBarangays;

  /// Form intro.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU checks these details against the municipal resident register. Enter them as they appear on your birth certificate or valid ID.'**
  String get verifKycIntro;

  /// Warning heading when the barangay list failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load barangays'**
  String get verifKycBarangaysFailed;

  /// Warning heading when opening the case failed.
  ///
  /// In en, this message translates to:
  /// **'Could not start your verification'**
  String get verifKycStartFailed;

  /// Hint under the first-name label.
  ///
  /// In en, this message translates to:
  /// **'As it appears on your ID.'**
  String get verifKycAsOnId;

  /// Name suffix field (Jr, Sr, III).
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get verifSuffix;

  /// Date-picker button before a date is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose your date of birth'**
  String get verifKycChooseBirthDate;

  /// Hint under the sex label.
  ///
  /// In en, this message translates to:
  /// **'As recorded on your birth certificate.'**
  String get verifKycSexHint;

  /// Sex, as on the civil register.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get verifSexFemale;

  /// Sex, as on the civil register.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get verifSexMale;

  /// Sex value when the record does not state it.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get verifSexUnspecified;

  /// Why-we-ask panel title.
  ///
  /// In en, this message translates to:
  /// **'Why does Taytay LGU need these?'**
  String get verifKycWhyTitle;

  /// Why-we-ask: purpose (Data Privacy Act notice).
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU matches these details against the municipal resident register to confirm you are who you say you are.'**
  String get verifKycWhyPurpose;

  /// Why-we-ask: who sees it.
  ///
  /// In en, this message translates to:
  /// **'Staff reviewing verification for your barangay. Your details are not shown to other residents and are not used for anything else.'**
  String get verifKycWhyWho;

  /// Why-we-ask: if you decline.
  ///
  /// In en, this message translates to:
  /// **'You can keep using this app to browse municipal services and announcements. You will not be able to hold a digital ID until Taytay LGU confirms who you are. Programme pages are information only.'**
  String get verifKycWhyDecline;

  /// Form button: saves the draft case, sends nothing.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get verifKycSaveContinue;

  /// Small print under the button.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent to Taytay LGU yet. You can check your details before sending them for review.'**
  String get verifKycNothingSentYet;

  /// Error when this build has no profile repository.
  ///
  /// In en, this message translates to:
  /// **'Profile is not available right now.'**
  String get verifProfileUnavailable;

  /// Header while the resident profile loads or fails.
  ///
  /// In en, this message translates to:
  /// **'Resident profile'**
  String get verifProfileHeader;

  /// Screen-reader label while the profile loads.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile'**
  String get verifProfileLoading;

  /// Title of the resident profile and subtitle of its steps.
  ///
  /// In en, this message translates to:
  /// **'Resident Profile'**
  String get verifProfileTitle;

  /// Success title.
  ///
  /// In en, this message translates to:
  /// **'Profile submitted'**
  String get verifProfileSubmittedTitle;

  /// Success message.
  ///
  /// In en, this message translates to:
  /// **'Your resident profile was sent to Taytay LGU. We\'ll notify you when it has been reviewed.'**
  String get verifProfileSubmittedMessage;

  /// Success screen button.
  ///
  /// In en, this message translates to:
  /// **'Back to profile'**
  String get verifBackToProfile;

  /// Section and step title.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get verifPersonalInfo;

  /// Step button.
  ///
  /// In en, this message translates to:
  /// **'Save & continue'**
  String get verifSaveAndContinue;

  /// Section and step title.
  ///
  /// In en, this message translates to:
  /// **'Household & address'**
  String get verifHouseholdAddress;

  /// Section and step title.
  ///
  /// In en, this message translates to:
  /// **'Review & submit'**
  String get verifReviewSubmit;

  /// Review step button.
  ///
  /// In en, this message translates to:
  /// **'Submit to Taytay LGU'**
  String get verifSubmitToLgu;

  /// Placeholder when the record has no name yet.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get verifYourName;

  /// Label beside the completeness percentage.
  ///
  /// In en, this message translates to:
  /// **'Profile completeness'**
  String get verifProfileCompleteness;

  /// Under the completeness bar.
  ///
  /// In en, this message translates to:
  /// **'Complete all sections to submit your profile to Taytay LGU.'**
  String get verifCompleteAllSections;

  /// Section state.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get verifSectionComplete;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Supporting documents'**
  String get verifSupportingDocuments;

  /// Field label (half-width field).
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get verifBirthdate;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get verifAge;

  /// Section title: mobile number and email.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get verifContact;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get verifEmail;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'House no. / Street'**
  String get verifHouseNoStreet;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Purok / Sitio'**
  String get verifPurokSitio;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Municipality / Province'**
  String get verifMunicipalityProvince;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get verifHousehold;

  /// Field label: how many years the resident has lived here.
  ///
  /// In en, this message translates to:
  /// **'Years at this address'**
  String get verifYearsAtThisAddress;

  /// Field label / review row: how many people.
  ///
  /// In en, this message translates to:
  /// **'Household members'**
  String get verifHouseholdMembers;

  /// Field label (owned, rented...).
  ///
  /// In en, this message translates to:
  /// **'Residence type'**
  String get verifResidenceType;

  /// Review row label: the full name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get verifName;

  /// Review row label.
  ///
  /// In en, this message translates to:
  /// **'Sex · Birthdate'**
  String get verifSexBirthdate;

  /// Review row label: mobile number.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get verifMobile;

  /// Review row label.
  ///
  /// In en, this message translates to:
  /// **'Years at address'**
  String get verifYearsAtAddress;

  /// Certification and consent tick before the profile is submitted.
  ///
  /// In en, this message translates to:
  /// **'I certify that the information is true and correct, and I consent to its processing under the Data Privacy Act of 2012 per Taytay LGU\'s Privacy Notice.'**
  String get verifCertify;

  /// Timeline step.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get verifSubmitted;

  /// Timeline step.
  ///
  /// In en, this message translates to:
  /// **'Profile verified'**
  String get verifProfileVerified;

  /// Link on a review card: change this section.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get verifEdit;

  /// Document request status: submitted, not yet picked up by the office. Also a history line.
  ///
  /// In en, this message translates to:
  /// **'Sent to the office'**
  String get issuanceStatusSubmitted;

  /// Document request status: the office is reviewing it.
  ///
  /// In en, this message translates to:
  /// **'Being reviewed'**
  String get issuanceStatusUnderReview;

  /// Document request status: the office asked the resident for more.
  ///
  /// In en, this message translates to:
  /// **'Needs more from you'**
  String get issuanceStatusNeedsInfo;

  /// Document request status: approved; the document is being prepared.
  ///
  /// In en, this message translates to:
  /// **'Approved, being prepared'**
  String get issuanceStatusApproved;

  /// Document request status: ready to collect at the office. Also a history line and the next step on the timeline.
  ///
  /// In en, this message translates to:
  /// **'Ready to claim'**
  String get issuanceStatusReadyForPickup;

  /// Document request status: the resident has collected the document.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get issuanceStatusReleased;

  /// Document request status: the office refused to issue the document.
  ///
  /// In en, this message translates to:
  /// **'Not issued'**
  String get issuanceStatusRejected;

  /// Document request status this app version does not know (newer server).
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get issuanceStatusUpdated;

  /// Under the status: what Sent to the office means.
  ///
  /// In en, this message translates to:
  /// **'The office has your request. Nobody has started on it yet.'**
  String get issuanceExplainSubmitted;

  /// Under the status: what Being reviewed means.
  ///
  /// In en, this message translates to:
  /// **'The office is checking your request and your files. Nothing is needed from you now.'**
  String get issuanceExplainUnderReview;

  /// Under the status: what Needs more from you means.
  ///
  /// In en, this message translates to:
  /// **'The office needs something more before it can go on. Read what they asked for, then send it here.'**
  String get issuanceExplainNeedsInfo;

  /// Under the status: what Approved, being prepared means.
  ///
  /// In en, this message translates to:
  /// **'The office approved your request and is preparing the document. You will be told here when it is ready.'**
  String get issuanceExplainApproved;

  /// Under the status: what Ready to claim means.
  ///
  /// In en, this message translates to:
  /// **'Your document is ready. Read below when and where to claim it.'**
  String get issuanceExplainReadyForPickup;

  /// Under the status: what Claimed means.
  ///
  /// In en, this message translates to:
  /// **'The office released the document to you.'**
  String get issuanceExplainReleased;

  /// Under the status: what Not issued means.
  ///
  /// In en, this message translates to:
  /// **'The office could not issue this document. Their reason is below.'**
  String get issuanceExplainRejected;

  /// Under the status: what Cancelled means.
  ///
  /// In en, this message translates to:
  /// **'This request was cancelled.'**
  String get issuanceExplainCancelled;

  /// Under an unknown status.
  ///
  /// In en, this message translates to:
  /// **'The office updated this request. Ask the office if anything is unclear.'**
  String get issuanceExplainUpdated;

  /// Timeline line: the resident filed the request.
  ///
  /// In en, this message translates to:
  /// **'You sent the request'**
  String get issuanceHistorySent;

  /// Timeline line: the resident cancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the request'**
  String get issuanceHistoryCancelled;

  /// Timeline line: the resident answered a request for more.
  ///
  /// In en, this message translates to:
  /// **'You sent what the office asked for'**
  String get issuanceHistoryAnswered;

  /// Timeline line.
  ///
  /// In en, this message translates to:
  /// **'The office started reviewing it'**
  String get issuanceHistoryReviewStarted;

  /// Timeline line.
  ///
  /// In en, this message translates to:
  /// **'The office asked for more'**
  String get issuanceHistoryAskedForMore;

  /// Timeline line.
  ///
  /// In en, this message translates to:
  /// **'The office approved it'**
  String get issuanceHistoryApproved;

  /// Timeline line: refused.
  ///
  /// In en, this message translates to:
  /// **'The office could not issue it'**
  String get issuanceHistoryRefused;

  /// Timeline line: collected.
  ///
  /// In en, this message translates to:
  /// **'The office released the document'**
  String get issuanceHistoryReleased;

  /// Timeline line for a status this build does not know.
  ///
  /// In en, this message translates to:
  /// **'The request was updated'**
  String get issuanceHistoryUpdated;

  /// Greyed next step on the timeline once the document is ready.
  ///
  /// In en, this message translates to:
  /// **'Claimed at the office'**
  String get issuanceHistoryClaimedNext;

  /// Under the greyed next step.
  ///
  /// In en, this message translates to:
  /// **'You will see it here'**
  String get issuanceHistoryUpcoming;

  /// Timeline date line for a move the resident made.
  ///
  /// In en, this message translates to:
  /// **'{date} · You'**
  String issuanceHistoryByYou(String date);

  /// Timeline date line for a move the office made.
  ///
  /// In en, this message translates to:
  /// **'{date} · Office'**
  String issuanceHistoryByOffice(String date);

  /// Label (shown upper case) over the resident's own note.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get issuanceYourNote;

  /// Label (shown upper case) over the office's own words.
  ///
  /// In en, this message translates to:
  /// **'From the office'**
  String get issuanceFromOffice;

  /// Notice for a guest.
  ///
  /// In en, this message translates to:
  /// **'Sign in to request a document'**
  String get issuanceAccessSignInTitle;

  /// Notice for a guest.
  ///
  /// In en, this message translates to:
  /// **'You can read what each document needs now. To send a request, sign in with a verified Taytay account.'**
  String get issuanceAccessSignInBody;

  /// Notice for a signed-in, unverified resident.
  ///
  /// In en, this message translates to:
  /// **'Verify your account first'**
  String get issuanceAccessVerifyTitle;

  /// Notice for a signed-in, unverified resident.
  ///
  /// In en, this message translates to:
  /// **'Only verified Taytay residents can send a document request, because the office issues it in your name. You can read what each document needs now.'**
  String get issuanceAccessVerifyBody;

  /// Title when the thing asked for does not exist.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get issuanceLoadNotFoundTitle;

  /// Body when the thing asked for does not exist.
  ///
  /// In en, this message translates to:
  /// **'This is not available. It may have been removed, or it belongs to another account.'**
  String get issuanceLoadNotFoundBody;

  /// Body when offline.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not be reached. Check your connection and try again.'**
  String get issuanceLoadOfflineBody;

  /// Title of a load failure, generic.
  ///
  /// In en, this message translates to:
  /// **'Could not load this'**
  String get issuanceLoadFailedThis;

  /// Title: the catalogue did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load the documents'**
  String get issuanceLoadFailedDocuments;

  /// Title: one document type did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document'**
  String get issuanceLoadFailedDocument;

  /// Title: one request did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this request'**
  String get issuanceLoadFailedRequest;

  /// Title: the list of requests did not load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your requests'**
  String get issuanceLoadFailedRequests;

  /// Cancel confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get issuanceCancelTitle;

  /// Cancel confirmation body; reference is the request number.
  ///
  /// In en, this message translates to:
  /// **'The office will stop working on {reference}. A cancelled request cannot be opened again; you would send a new one.'**
  String issuanceCancelMessage(String reference);

  /// Cancel confirmation: destructive button.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get issuanceCancelConfirm;

  /// Cancel confirmation: keep the request.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get issuanceCancelKeep;

  /// Toast after cancelling.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled.'**
  String get issuanceCancelDone;

  /// Button at the foot of the request.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request'**
  String get issuanceCancelButton;

  /// Header of one request.
  ///
  /// In en, this message translates to:
  /// **'Document request'**
  String get issuanceDetailTitle;

  /// Screen-reader label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Opening your request'**
  String get issuanceDetailLoading;

  /// Label (upper case) over the office's request for more.
  ///
  /// In en, this message translates to:
  /// **'What the office asked for'**
  String get issuanceAskedLabel;

  /// Card title: collecting the document.
  ///
  /// In en, this message translates to:
  /// **'How to claim it'**
  String get issuanceHowToClaim;

  /// Fact line when ready to claim.
  ///
  /// In en, this message translates to:
  /// **'Bring a valid ID and your reference number.'**
  String get issuanceBringId;

  /// Label (upper case) over the office's refusal reason.
  ///
  /// In en, this message translates to:
  /// **'The office\'s reason'**
  String get issuanceRefusalLabel;

  /// Card title over the timeline.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get issuanceProgress;

  /// Card title over purpose, fee and files.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get issuanceYourRequest;

  /// Label (upper case) over what the document is for.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get issuancePurpose;

  /// Heading over the attachments.
  ///
  /// In en, this message translates to:
  /// **'Files you sent'**
  String get issuanceFilesSent;

  /// Attachment whose requirement has no name.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get issuanceFile;

  /// Attachment line: a file sent again.
  ///
  /// In en, this message translates to:
  /// **'version {version}'**
  String issuanceAttachmentVersion(int version);

  /// Attachment line: an older version.
  ///
  /// In en, this message translates to:
  /// **'replaced later'**
  String get issuanceAttachmentReplaced;

  /// Button that opens a sent photo.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get issuanceView;

  /// Screen-reader label while a sent photo loads.
  ///
  /// In en, this message translates to:
  /// **'Loading the photo you sent for {label}'**
  String issuancePhotoLoading(String label);

  /// Screen-reader label of a sent photo.
  ///
  /// In en, this message translates to:
  /// **'The photo you sent for {label}'**
  String issuancePhotoSemantic(String label);

  /// A sent photo could not load: offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Connect and try again.'**
  String get issuancePhotoOffline;

  /// A sent photo could not load.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be shown here. The office still has it.'**
  String get issuancePhotoUnavailable;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'Send what the office asked for'**
  String get issuanceResubmitTitle;

  /// Card intro.
  ///
  /// In en, this message translates to:
  /// **'Add a note, a new file, or both. A new file is kept beside the one you sent before; nothing you sent is replaced.'**
  String get issuanceResubmitIntro;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Note to the office (optional)'**
  String get issuanceResubmitNoteLabel;

  /// Replaces 'Optional' beside each file.
  ///
  /// In en, this message translates to:
  /// **'New file, if asked'**
  String get issuanceResubmitOptional;

  /// Error: nothing to send.
  ///
  /// In en, this message translates to:
  /// **'Add a note or a file first.'**
  String get issuanceResubmitEmpty;

  /// Send button.
  ///
  /// In en, this message translates to:
  /// **'Send to the office'**
  String get issuanceSendToOffice;

  /// Toast after sending.
  ///
  /// In en, this message translates to:
  /// **'Sent. The office will review it again.'**
  String get issuanceResubmitDone;

  /// Form title; also the button on My document requests.
  ///
  /// In en, this message translates to:
  /// **'Request a document'**
  String get issuanceRequestTitle;

  /// Screen-reader label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Opening the form'**
  String get issuanceFormLoading;

  /// Step 1 footer button.
  ///
  /// In en, this message translates to:
  /// **'Review request'**
  String get issuanceReviewButton;

  /// Purpose field label.
  ///
  /// In en, this message translates to:
  /// **'What is the document for?'**
  String get issuancePurposeLabel;

  /// Purpose field hint.
  ///
  /// In en, this message translates to:
  /// **'For example: for a school enrolment requirement'**
  String get issuancePurposeHint;

  /// Purpose field helper.
  ///
  /// In en, this message translates to:
  /// **'The office reads this. Keep it short.'**
  String get issuancePurposeHelp;

  /// Purpose error: empty.
  ///
  /// In en, this message translates to:
  /// **'Say what the document is for, for example \"for a school enrolment\".'**
  String get issuancePurposeEmpty;

  /// Heading over the file slots.
  ///
  /// In en, this message translates to:
  /// **'Files the office needs'**
  String get issuanceFilesNeeded;

  /// accepted is e.g. 'JPEG, PDF or PNG, up to 10 MB each'.
  ///
  /// In en, this message translates to:
  /// **'One file each: {accepted}. Lay paper flat, fill the frame, and make every word readable.'**
  String issuanceFilesIntro(String accepted);

  /// Error note under the form.
  ///
  /// In en, this message translates to:
  /// **'Some answers are missing. They are marked above.'**
  String get issuanceMissingAnswers;

  /// Step 2 title.
  ///
  /// In en, this message translates to:
  /// **'Review your request'**
  String get issuanceReviewTitle;

  /// Step 2 send button.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get issuanceSendRequest;

  /// Step 2: back to editing.
  ///
  /// In en, this message translates to:
  /// **'Change something'**
  String get issuanceChangeSomething;

  /// Step 2 card title over the purpose.
  ///
  /// In en, this message translates to:
  /// **'You are asking for it'**
  String get issuanceAskingFor;

  /// Step 2 card title.
  ///
  /// In en, this message translates to:
  /// **'Files you are sending'**
  String get issuanceFilesSending;

  /// Lower-case file kind in '{name}: {kind}, {size}' (applyReviewFile).
  ///
  /// In en, this message translates to:
  /// **'photo'**
  String get issuanceKindPhoto;

  /// Step 2: an optional file left out.
  ///
  /// In en, this message translates to:
  /// **'{name}: not sent (optional)'**
  String issuanceReviewNotSent(String name);

  /// Step 2 note.
  ///
  /// In en, this message translates to:
  /// **'Check it before sending. You can cancel the request yourself until the office starts on it. After that, message the office.'**
  String get issuanceReviewNote;

  /// Success page title.
  ///
  /// In en, this message translates to:
  /// **'The office has your request'**
  String get issuanceDoneTitle;

  /// Success page message.
  ///
  /// In en, this message translates to:
  /// **'Keep this number. The office uses it when you ask about your request.'**
  String get issuanceDoneMessage;

  /// Success page detail label.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get issuanceDocument;

  /// Success page detail label.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get issuanceOffice;

  /// Success page note.
  ///
  /// In en, this message translates to:
  /// **'The office will review it. Each step shows here and in your notifications, including when it is ready to claim.'**
  String get issuanceDoneNote;

  /// Success page primary button.
  ///
  /// In en, this message translates to:
  /// **'Follow this request'**
  String get issuanceFollowRequest;

  /// Success page secondary button.
  ///
  /// In en, this message translates to:
  /// **'Back to documents'**
  String get issuanceBackToDocuments;

  /// First sentence of a send failure.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent.'**
  String get issuanceNothingSent;

  /// First sentence of a cancel failure.
  ///
  /// In en, this message translates to:
  /// **'Nothing was cancelled.'**
  String get issuanceNothingCancelled;

  /// Submit outcome unknown.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your request was received. Sending the same request again is safe: it will not be filed twice. You can also check My document requests.'**
  String get issuanceUnconfirmedSubmit;

  /// Resubmit outcome unknown.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your changes were received. Sending them again is safe: they will not be filed twice. You can also go back and open the request to check.'**
  String get issuanceUnconfirmedResubmit;

  /// Cancel outcome unknown.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your cancellation was received. Trying again is safe: the request is cancelled only once. You can also go back and open the request to check.'**
  String get issuanceUnconfirmedCancel;

  /// Server said verification is required.
  ///
  /// In en, this message translates to:
  /// **'Only verified residents can do this'**
  String get issuanceFailVerifyTitle;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU does not have your account as verified. Finish verification first, then come back to this page.'**
  String get issuanceFailVerifyBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Document requests are not open to this account. The municipal hall can tell you more.'**
  String get issuanceFailForbiddenBody;

  /// Follows issuanceNothingSent / issuanceNothingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your answers are still here on the phone. Connect to the internet and try again.'**
  String get issuanceFailOfflineBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'The office could not accept part of it. The items marked below need checking.'**
  String get issuanceFailCheckBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'A file was too large or could not be read. Choose a smaller photo or another file, and try again.'**
  String get issuanceFailFileBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Wait a few minutes, then try again.'**
  String get issuanceFailRateBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Open My document requests to check what the office has before trying again.'**
  String get issuanceFailKeyConflictBody;

  /// Follows issuanceNothingSent / issuanceNothingCancelled.
  ///
  /// In en, this message translates to:
  /// **'The office has already acted on it. Go back and open it again to see where it stands.'**
  String get issuanceFailMovedBody;

  /// The document or request is gone.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get issuanceFailGoneTitle;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'The office no longer lists this. Go back to the list to see what is available.'**
  String get issuanceFailGoneBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in, then try again.'**
  String get issuanceFailSessionBody;

  /// Follows issuanceNothingSent.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again in a moment.'**
  String get issuanceFailServerBody;

  /// The office stated no fee (not the same as free).
  ///
  /// In en, this message translates to:
  /// **'No fee stated'**
  String get issuanceFeeNotStated;

  /// A stated fee of nothing.
  ///
  /// In en, this message translates to:
  /// **'No fee'**
  String get issuanceFeeNone;

  /// amount is e.g. '₱50.00'. Never paid in the app.
  ///
  /// In en, this message translates to:
  /// **'Fee: {amount}, paid at the office'**
  String issuanceFee(String amount);

  /// No processing time stated.
  ///
  /// In en, this message translates to:
  /// **'Processing time not stated'**
  String get issuanceProcessingNotStated;

  /// Processing time of zero days.
  ///
  /// In en, this message translates to:
  /// **'Usually the same working day'**
  String get issuanceProcessingSameDay;

  /// Processing time from the Citizen's Charter.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{About 1 working day} other{About {days} working days}}'**
  String issuanceProcessingDays(int days);

  /// File kinds when the server named none.
  ///
  /// In en, this message translates to:
  /// **'a file'**
  String get issuanceAcceptedAnyFile;

  /// e.g. 'JPEG, PDF or PNG'.
  ///
  /// In en, this message translates to:
  /// **'{first} or {last}'**
  String issuanceAcceptedOr(String first, String last);

  /// e.g. 'JPEG, PDF or PNG, up to 10 MB each'.
  ///
  /// In en, this message translates to:
  /// **'{kinds}, up to {limit} MB each'**
  String issuanceAcceptedLine(String kinds, int limit);

  /// Catalogue header.
  ///
  /// In en, this message translates to:
  /// **'Request documents'**
  String get issuanceCatalogueTitle;

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get issuanceSearchHint;

  /// Row and screen title.
  ///
  /// In en, this message translates to:
  /// **'My document requests'**
  String get issuanceMyRequests;

  /// Row detail.
  ///
  /// In en, this message translates to:
  /// **'Follow what you have sent'**
  String get issuanceMyRequestsDetail;

  /// Intro paragraph.
  ///
  /// In en, this message translates to:
  /// **'Certificates and certified copies the municipal offices issue. Choose one to see what it needs. Any fee is paid at the office, never in the app.'**
  String get issuanceCatalogueIntro;

  /// Screen-reader label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading documents'**
  String get issuanceCatalogueLoading;

  /// Empty catalogue.
  ///
  /// In en, this message translates to:
  /// **'No documents listed yet'**
  String get issuanceCatalogueEmptyTitle;

  /// Empty catalogue.
  ///
  /// In en, this message translates to:
  /// **'The municipal offices have not listed any documents in the app yet. You can still ask at the Municipal Hall.'**
  String get issuanceCatalogueEmptyMessage;

  /// Search found nothing.
  ///
  /// In en, this message translates to:
  /// **'No document matches'**
  String get issuanceNoMatchTitle;

  /// Search found nothing.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or clear the search to see them all.'**
  String get issuanceNoMatchMessage;

  /// Header.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get issuanceTypeTitle;

  /// Footer button.
  ///
  /// In en, this message translates to:
  /// **'Request this document'**
  String get issuanceRequestThis;

  /// Screen-reader label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Opening this document'**
  String get issuanceTypeLoading;

  /// Fact row label.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get issuanceFeeLabel;

  /// Fact row label.
  ///
  /// In en, this message translates to:
  /// **'Processing time'**
  String get issuanceProcessingLabel;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'What you need to send'**
  String get issuanceWhatToSend;

  /// No requirements.
  ///
  /// In en, this message translates to:
  /// **'No files. The purpose of your request is enough.'**
  String get issuanceNoFilesNeeded;

  /// accepted is e.g. 'JPEG, PDF or PNG, up to 10 MB each'.
  ///
  /// In en, this message translates to:
  /// **'Send each one as a photo or a file: {accepted}.'**
  String issuanceSendEachAs(String accepted);

  /// When the office gave no claim instructions.
  ///
  /// In en, this message translates to:
  /// **'The office will tell you here when and where to claim it, once it is ready.'**
  String get issuanceClaimFallback;

  /// Add-file sheet when the phone has no picker.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot pick a file. The office can take the document in person at the Municipal Hall.'**
  String get issuanceNoPicker;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'No document requests yet'**
  String get issuanceMyRequestsEmptyTitle;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'When you request a certificate or a copy from a municipal office, you can follow it here.'**
  String get issuanceMyRequestsEmptyMessage;

  /// List row: the date the request was sent.
  ///
  /// In en, this message translates to:
  /// **'Sent {date}'**
  String issuanceSentOn(String date);

  /// Header of the digital ID page.
  ///
  /// In en, this message translates to:
  /// **'My Taytay ID'**
  String get digitalIdTitle;

  /// Screen-reader label of the loading skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading your digital ID'**
  String get digitalIdLoading;

  /// A card in a status this build cannot read.
  ///
  /// In en, this message translates to:
  /// **'Your digital ID will appear here once Taytay LGU issues it.'**
  String get digitalIdUnknownStatus;

  /// Note under the card.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU issued this card. A scanner checks the code. This phone does not decide that the card is genuine.'**
  String get digitalIdGenuineNote;

  /// Words on the not-issued card.
  ///
  /// In en, this message translates to:
  /// **'Not yet issued'**
  String get digitalIdNotYetIssued;

  /// Screen-reader label of the card portrait.
  ///
  /// In en, this message translates to:
  /// **'ID photo'**
  String get digitalIdPhotoSemantic;

  /// Screen-reader label of the empty portrait box.
  ///
  /// In en, this message translates to:
  /// **'Photo placeholder'**
  String get digitalIdPhotoPlaceholder;

  /// Status pill on the card.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get digitalIdStatusActive;

  /// Status pill on the card.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get digitalIdStatusSuspended;

  /// Status pill on the card.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get digitalIdStatusRevoked;

  /// Screen-reader label of the status pill.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String digitalIdStatusSemantic(String status);

  /// Under the QR when no expiry was sent.
  ///
  /// In en, this message translates to:
  /// **'Code refreshes'**
  String get digitalIdCodeRefreshes;

  /// time e.g. '9:42 PM', zone 'PHT'.
  ///
  /// In en, this message translates to:
  /// **'Code refreshes · valid until {time} {zone}'**
  String digitalIdCodeValidUntil(String time, String zone);

  /// QR card heading.
  ///
  /// In en, this message translates to:
  /// **'Show this code to be scanned'**
  String get digitalIdShowCode;

  /// In the QR box while a new code is fetched.
  ///
  /// In en, this message translates to:
  /// **'Refreshing code…'**
  String get digitalIdRefreshingCode;

  /// Under a suspended/revoked/expired notice.
  ///
  /// In en, this message translates to:
  /// **'No code is shown while the card is not active.'**
  String get digitalIdNoCodeWhileInactive;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Your ID is suspended'**
  String get digitalIdSuspendedTitle;

  /// Notice body.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has paused this card. Visit the Municipal Hall or message the LGU to find out why.'**
  String get digitalIdSuspendedBody;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'This ID is no longer valid'**
  String get digitalIdRevokedTitle;

  /// Notice body.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has revoked this card. Visit the Municipal Hall if you need a new one.'**
  String get digitalIdRevokedBody;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Your ID has expired'**
  String get digitalIdExpiredTitle;

  /// Notice body.
  ///
  /// In en, this message translates to:
  /// **'This card passed its expiry date. Visit the Municipal Hall to renew it.'**
  String get digitalIdExpiredBody;

  /// Ghost card heading.
  ///
  /// In en, this message translates to:
  /// **'Your card is being prepared'**
  String get digitalIdPreparingTitle;

  /// Ghost card body.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified. The MSWDO issues your card next, and it appears here with a QR code.'**
  String get digitalIdPreparingBody;

  /// Steps card heading.
  ///
  /// In en, this message translates to:
  /// **'Where your card is'**
  String get digitalIdStepsTitle;

  /// Step.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get digitalIdStepAccountCreated;

  /// Step.
  ///
  /// In en, this message translates to:
  /// **'ID and selfie sent'**
  String get digitalIdStepIdSent;

  /// Step.
  ///
  /// In en, this message translates to:
  /// **'Verified by Taytay LGU'**
  String get digitalIdStepVerified;

  /// Current step (not done yet).
  ///
  /// In en, this message translates to:
  /// **'Card issued by the MSWDO'**
  String get digitalIdStepIssued;

  /// Current step detail.
  ///
  /// In en, this message translates to:
  /// **'Check this page again later. The card photo is usually your verification selfie.'**
  String get digitalIdStepIssuedDetail;

  /// Upcoming step.
  ///
  /// In en, this message translates to:
  /// **'Show your card'**
  String get digitalIdStepShow;

  /// Upcoming step detail.
  ///
  /// In en, this message translates to:
  /// **'Staff scan its QR code. Each code works for a short time, and the app gets a new one.'**
  String get digitalIdStepShowDetail;

  /// About card heading.
  ///
  /// In en, this message translates to:
  /// **'About your card'**
  String get digitalIdAboutTitle;

  /// About card fact.
  ///
  /// In en, this message translates to:
  /// **'It is Taytay\'s own resident card, not a national government ID. The card shows the date it expires.'**
  String get digitalIdAboutWhat;

  /// About card fact.
  ///
  /// In en, this message translates to:
  /// **'If it is suspended or expires, the app stops showing its QR code. Message the MSWDO to find out what to do.'**
  String get digitalIdAboutStops;

  /// Button that opens a message to the MSWDO.
  ///
  /// In en, this message translates to:
  /// **'Message the MSWDO'**
  String get digitalIdMessageMswdo;

  /// Title of the household screen, and subtitle of its report-an-error form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Household and family'**
  String get hhTitle;

  /// Screen-reader label of the loading skeleton on the household screen. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading your household record'**
  String get hhLoading;

  /// Section heading above the household's address and size. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your household'**
  String get hhSectionHousehold;

  /// Row label: the household's name, when the LGU publishes one. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get hhRowHousehold;

  /// Row label: how many people the LGU records in the household. The value is a number; no names are shown. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'People recorded here'**
  String get hhRowPeople;

  /// Section heading above the resident's own role in the household. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your family record'**
  String get hhSectionFamily;

  /// Under the role 'Household head': what that role means. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU records you as the person who answers for this household. The office keeps that record. This app does not take applications.'**
  String get hhRoleHeadBody;

  /// Under the role 'Household member': what that role means. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU records you as part of this household. This app does not take applications.'**
  String get hhRoleMemberBody;

  /// Heading of the card explaining why other household members are not listed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Why you cannot see the other people here'**
  String get hhHiddenTitle;

  /// Body of the card explaining why other household members are not listed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The details of everyone else in your household belong to them, not to your account — so this app does not show their names, their situation or anything they have applied for. Taytay LGU staff can go through the household record with you in person.'**
  String get hhHiddenBody;

  /// Empty state: the API says the account belongs to no household. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'No household on your account yet'**
  String get hhNoneTitle;

  /// Empty state body: the account belongs to no household. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is not part of a household in this app, and this version of the app cannot set one up. The municipal hall keeps its own household record, and staff can go through it with you.'**
  String get hhNoneBody;

  /// Section heading above the Report an error button. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Is something wrong?'**
  String get hhCorrectionHeading;

  /// Lead-in above the Report an error button. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Tell Taytay LGU what looks wrong and they will check the record. Nothing changes until staff review it.'**
  String get hhCorrectionLead;

  /// Button on the household screen, and title of the form it opens. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Report an error'**
  String get hhReportError;

  /// Value of a household row the LGU holds nothing for. Never a blank or a dash. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not on file'**
  String get hhNotOnFile;

  /// Heading of the household report form, above the closed list of kinds. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What looks wrong?'**
  String get hhFixQuestion;

  /// Lead-in under 'What looks wrong?'. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Pick the closest one. Taytay LGU staff will check the record — nothing changes until they do.'**
  String get hhFixLead;

  /// Warning note heading on the household report form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Please do not type personal details here'**
  String get hhFixNoDetailsTitle;

  /// Warning note body on the household report form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This app asks only what kind of thing is wrong. Names, health information and reasons belong in the conversation with staff, who can record them properly and act on them.'**
  String get hhFixNoDetailsBody;

  /// Note heading on the household report form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Bring it to the municipal hall'**
  String get hhFixHallTitle;

  /// Note body on the household report form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Household records are changed by Taytay LGU staff after they look at your documents. Visit the municipal hall with a valid ID — you do not need this app or your phone to be served there.'**
  String get hhFixHallBody;

  /// Success note heading after the household report was sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has your report'**
  String get hhFixSentTitle;

  /// Success note body after the household report was sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Staff will check the record. Nothing has been changed yet, and you will be told what they find.'**
  String get hhFixSentBody;

  /// Warning note heading when the household report failed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Could not send your report'**
  String get hhFixFailedTitle;

  /// Warning note body when the household report failed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not switched on household reports in this app yet. Nothing was sent, and nothing has changed. The municipal hall can take it in person.'**
  String get hhFixFailedBody;

  /// Primary button of the household report form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get hhFixSend;

  /// Small print under Send report. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sending this does not change your household record.'**
  String get hhFixNoChange;

  /// Header title of the resident record when it is opened from Edit profile (not the My Account root). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profTitle;

  /// Identity card heading on My Account for a guest. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You are browsing as a guest'**
  String get profGuestTitle;

  /// Identity card body on My Account for a guest. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number to hold your digital ID. Browsing stays open either way. Programme pages are information only.'**
  String get profGuestBody;

  /// My Account: section heading above the shortcuts, and the identity card heading for an unverified resident whose name is not known. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get profYourAccount;

  /// Identity card body on My Account for a signed-in resident who is not verified. 'Tulong' is the name of the app's assistance section. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not confirmed your identity yet. Verifying unlocks your digital ID and applying for Tulong in the app.'**
  String get profUnverifiedBody;

  /// Identity card heading for a verified resident whose first name is not known. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Verified resident'**
  String get profVerifiedResident;

  /// My Account: section heading above Privacy and Help rows. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Privacy and help'**
  String get profSectionPrivacyHelp;

  /// My Account row, and the title of the privacy screen it opens. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Privacy and your data'**
  String get profPrivacyRow;

  /// Detail line under Privacy and your data. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU holds, why, and your rights over it.'**
  String get profPrivacyRowDetail;

  /// My Account row opening sign-in help. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get profHelpRow;

  /// Detail line under Help and support. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Trouble signing in, and where to get help.'**
  String get profHelpRowDetail;

  /// My Account row opening the document request catalogue. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Request documents'**
  String get profRequestDocuments;

  /// Detail under Request documents when the account is not verified. The catalogue still opens. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sending a request needs a verified account'**
  String get profRequestDocumentsNeedsVerified;

  /// My Account row opening the office inbox. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Message an office'**
  String get profMessageOffice;

  /// Screen-reader label of the loading skeleton under a profile field group. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading your record'**
  String get profLoadingRecord;

  /// Under the account-details group when the record could not be read. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not switched on account details in this app yet. Your account still works.'**
  String get profAccountDetailsUnavailable;

  /// Under the LGU-verified group when the record could not be read. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not switched on your record in this app yet. The municipal hall can tell you what is on file.'**
  String get profRecordUnavailable;

  /// Value of a profile field when the record could not be read. Never a blank or a dash. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not available in this app yet'**
  String get profNotAvailableYet;

  /// Title of the dialog opened by tapping an LGU-verified profile field, and a heading on the privacy screen. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU keeps this correct'**
  String get profCanonicalTitle;

  /// Why an LGU-verified field cannot be edited (dialog and privacy screen). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This detail was checked against your documents, and other Taytay services rely on it. Changing it is a decision Taytay LGU makes, so it cannot be edited in this app.'**
  String get profCanonicalExplanation;

  /// What to do about a wrong LGU-verified field. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'If it is wrong, visit the Taytay municipal hall with a valid ID and the document that shows the correct detail. Staff can update your record directly. You do not need this app or your phone to do it.'**
  String get profCanonicalNextStep;

  /// Added to the dialog while the resident is mid-verification. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You are part-way through identity verification. If Taytay LGU asked you for a correction there, answering it is the quickest way to fix this.'**
  String get profCanonicalDuringVerification;

  /// Dialog button opening the verification screen. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Check my verification'**
  String get profCheckMyVerification;

  /// Verification badge on My Account for a guest. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profBadgeNotSignedIn;

  /// Verification badge on My Account for a signed-in, unverified resident. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not yet verified'**
  String get profBadgeNotVerified;

  /// Verification badge on My Account for a verified resident. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Verified by Taytay LGU'**
  String get profBadgeVerified;

  /// Footer button of the contact details form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profSaveChanges;

  /// Screen-reader label of the contact details loading skeleton. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading your details'**
  String get profLoadingDetails;

  /// Heading of the 'why we ask' panel on the contact details form. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Why Taytay LGU keeps this'**
  String get profContactWhyTitle;

  /// Why-we-ask panel: purpose. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number is how Taytay LGU signs you in and tells you about your requests. Your email is optional and is used only to send you copies.'**
  String get profContactWhyPurpose;

  /// Why-we-ask panel: who sees it. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Staff handling something you applied for. It is never shared for advertising.'**
  String get profContactWhoSees;

  /// Why-we-ask panel: what happens if you decline. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Without a mobile number you cannot sign in. Email can be left blank.'**
  String get profContactIfDecline;

  /// Success note after the contact details were saved. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your contact details were updated.'**
  String get profContactSaved;

  /// Bold lead of the note when the save's outcome is unknown (timeout after sending). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your changes may not have been saved.'**
  String get profContactMaybeNotSavedTitle;

  /// Body of the note when the save's outcome is unknown. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm them. Saving again is safe: the same details are sent again.'**
  String get profContactMaybeNotSavedBody;

  /// Bold lead of the note when the save failed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes.'**
  String get profContactNotSavedTitle;

  /// Body of the note when the save failed. {reason} is the app's own sentence for the failure, already localised. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{reason} Nothing was changed, and the municipal hall can update them for you.'**
  String profContactNotSavedBody(String reason);

  /// Helper under the mobile number field: changing it changes how the resident signs in. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This is also how you sign in.'**
  String get profContactMobileHelper;

  /// Field error: the mobile number is empty. Same rule as sign-in. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number.'**
  String get profMobileEmpty;

  /// Field error: the mobile number is not 11 digits starting with 09. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Enter an 11-digit mobile number starting with 09.'**
  String get profMobileShape;

  /// Field error for an optional email that does not look like one. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address, or leave this blank.'**
  String get profContactEmailInvalid;

  /// Heading of the privacy notice panel. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU is responsible for your information'**
  String get profPrivacyResponsibleTitle;

  /// Intro of the privacy notice panel. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This app is one way to reach the Municipality of Taytay, Rizal. Your information belongs to your municipal record, not to the app on your phone.'**
  String get profPrivacyResponsibleIntro;

  /// Privacy notice point heading. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What this app keeps on your phone'**
  String get profPrivacyKeptTitle;

  /// Privacy notice point: what is stored on the phone. A factual claim about storage; keep it exact. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Only what is needed to keep you signed in: a sign-in token in your phone’s secure keystore, your first name for the greeting, and whether Taytay LGU has verified you. Signing out removes all of it from this device.'**
  String get profPrivacyKeptBody;

  /// Privacy notice point heading. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What this app never keeps'**
  String get profPrivacyNeverKeptTitle;

  /// Privacy notice point: what is never stored on the phone. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your address, date of birth, ID images and household details are not stored on your phone. Screens fetch them when they show them, and nothing is written to a file or a cache.'**
  String get profPrivacyNeverKeptBody;

  /// Privacy notice point heading. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What Taytay LGU holds'**
  String get profPrivacyLguHoldsTitle;

  /// Privacy notice point: what the LGU holds. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your municipal resident record: your name, date of birth, address and barangay, together with anything you have applied for. Staff see only what their work requires.'**
  String get profPrivacyLguHoldsBody;

  /// Privacy notice point heading. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Who else can see it'**
  String get profPrivacyWhoElseTitle;

  /// Privacy notice point: who else can see the data. A legal statement; keep it exact. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nobody outside Taytay LGU, and no advertiser. Your information is not sold or shared for marketing. Sharing with another government office happens only where the law requires it.'**
  String get profPrivacyWhoElseBody;

  /// Heading of the rights card on the privacy screen. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get profPrivacyRightsTitle;

  /// The data subject's rights under RA 10173. The law's and the commission's names stay in English. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Under the Data Privacy Act of 2012 you can ask Taytay LGU what it holds about you, ask for a copy, ask for a mistake to be corrected, object to how it is used, and complain to the National Privacy Commission.'**
  String get profPrivacyRightsBody;

  /// How to exercise the rights above. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Ask at the Taytay municipal hall with a valid ID. Staff there can act on your record directly. You do not need this app or your phone to do it.'**
  String get profPrivacyRightsHow;

  /// Bold lead of a note on the privacy screen. A full stop ends it; the body follows on the same line. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Changing what you agreed to.'**
  String get profPrivacyConsentTitle;

  /// Why consent is not toggled in the app. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The permissions you gave when you registered are held with your Taytay LGU record, not in this app. To change or withdraw one, ask at the municipal hall — that way the change is recorded where it counts.'**
  String get profPrivacyConsentBody;

  /// Bold lead of a note on the privacy screen. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Deleting your record.'**
  String get profPrivacyDeleteTitle;

  /// Why a resident record is not deleted on request. A legal statement; keep it exact. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'A municipal resident record is kept for as long as the law requires, so it is not deleted on request. Taytay LGU can deactivate an account and correct what is wrong.'**
  String get profPrivacyDeleteBody;

  /// Under the name field while the resident may still change it (NameLock.open). Also on the account wizard. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Write your name exactly as it is printed on your government ID. Taytay LGU checks it against your ID.'**
  String get profNameAsPrinted;

  /// Under the name while an ID is under review (NameLock.underReview). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU is checking this name against your ID, so it cannot be changed while the check is pending.'**
  String get profNameUnderReview;

  /// Under the name once approved (NameLock.checked). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU checked this name against your ID, so it cannot be changed here. To change it, ask Taytay LGU.'**
  String get profNameChecked;

  /// Under the name when the status is unknown (NameLock.unknown). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not check whether your name can be changed. Try again later.'**
  String get profNameUnknown;

  /// Heading said before an ID is sent (start and resubmit pages). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your name and your ID'**
  String get profNameBeforeSendingTitle;

  /// Body said before an ID is sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU will check that your ID shows the name on your account. Make sure the two match before you send. Your name cannot be changed while the check is pending or after it is approved.'**
  String get profNameBeforeSending;

  /// Button on the verification resubmit page opening Edit profile. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Check the name on your account'**
  String get profNameCheckName;

  /// Field error: the name is empty. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Enter your name exactly as it is printed on your government ID.'**
  String get profNameEmpty;

  /// Field error: the name is longer than the API takes. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your name can be up to {max} characters.'**
  String profNameTooLong(int max);

  /// Under a barangay the office holds (verified account) on Edit profile. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'To change your barangay, visit the MSWDO office with proof of your new address.'**
  String get profBarangayHeldNote;

  /// Heading when the API refused a barangay change with BARANGAY_HELD_BY_OFFICE. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your barangay was not changed'**
  String get profBarangayRefusedTitle;

  /// Body when the API refused a barangay change. Its second sentence is profBarangayHeldNote. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your account is verified, so your barangay is changed at the MSWDO office. To change your barangay, visit the MSWDO office with proof of your new address.'**
  String get profBarangayRefused;

  /// Heading of the office's own registry record on My Account. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your record at the MSWDO office'**
  String get profOfficeRecordTitle;

  /// Under the office's record. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office keeps this record. If something here is wrong, visit the MSWDO office with your ID.'**
  String get profOfficeRecordKeptByOffice;

  /// Row label in the office's record. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profOfficeRecordName;

  /// Row label in the office's record. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get profOfficeRecordBirthDate;

  /// Value of a row this build cannot name (an unknown sex, a barangay not in the list). Never the raw id. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Ask the MSWDO office'**
  String get profOfficeRecordNotShown;

  /// The office's recorded sex, female. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profSexFemale;

  /// The office's recorded sex, male. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profSexMale;

  /// Title of the Sectors and benefits page (D-215). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sectors and benefits'**
  String get sectorsTitle;

  /// Intro card on Sectors and benefits. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your sectors are part of your record at Taytay LGU. Offices use them to see which programmes may fit you.'**
  String get sectorsIntro;

  /// Section heading above the recorded sectors and open applications. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your sectors'**
  String get sectorsYoursHeading;

  /// Shown when no sector is recorded yet. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'No sectors are on your record in the app yet. They show here once the MSWDO links your account to its records, which it does when it approves your first application.'**
  String get sectorsNone;

  /// Section heading on Sectors and benefits, and the title of the apply form's first step. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Apply for a sector'**
  String get sectorsApplyHeading;

  /// Shown when all three sectors are recorded or pending. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Senior citizen, person with disability and solo parent are each on your record or being checked. The MSWDO can tell you how to renew an ID.'**
  String get sectorsNothingToApply;

  /// Small print at the foot of Sectors and benefits. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This page shows senior citizen, person with disability and solo parent. Other sectors are recorded by the MSWDO in person and are not shown here.'**
  String get sectorsInPerson;

  /// Screen-reader label of the loading skeleton. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Loading your sectors'**
  String get sectorsLoading;

  /// Status pill: the sector is on the resident's record. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get sectorsRecorded;

  /// Status pill: an application is with the MSWDO. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Being checked'**
  String get sectorsBeingChecked;

  /// Status pill: the MSWDO returned the application. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get sectorsReturned;

  /// Status pill: the recorded sector ID has passed its validity date. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'ID expired'**
  String get sectorsLapsed;

  /// Sector name (RA 9994). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Senior citizen'**
  String get sectorsLabelSenior;

  /// Sector name (RA 7277 as amended by RA 10754). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Person with disability'**
  String get sectorsLabelPwd;

  /// Sector name (RA 8972 as amended by RA 11861). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Solo parent'**
  String get sectorsLabelSoloParent;

  /// Line under the senior citizen offer card. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'60 and over · your Senior Citizen ID or birth certificate'**
  String get sectorsOfferSenior;

  /// Line under the PWD offer card. PDAO is the Persons with Disability Affairs Office. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your PWD ID from the PDAO'**
  String get sectorsOfferPwd;

  /// Line under the solo parent offer card. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Your Solo Parent ID'**
  String get sectorsOfferSoloParent;

  /// Under the senior citizen choice on step 1. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'For residents 60 and over. Have your Senior Citizen ID or birth certificate ready.'**
  String get sectorsChoiceSenior;

  /// Under the PWD choice on step 1. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Have your PWD ID from the PDAO ready.'**
  String get sectorsChoicePwd;

  /// Under the solo parent choice on step 1. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Have your Solo Parent ID ready.'**
  String get sectorsChoiceSoloParent;

  /// Part of a recorded sector's detail line: the day the office recorded it. Parts are joined with ' · '. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String sectorsSince(String date);

  /// Part of a recorded sector's detail line: the last four characters of the sector ID. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'ID ending {lastFour}'**
  String sectorsIdEnding(String lastFour);

  /// Part of a recorded sector's detail line. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String sectorsValidUntil(String date);

  /// Detail of a pending application with no date. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You applied'**
  String get sectorsYouApplied;

  /// Detail of a pending application. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'You applied {date}'**
  String sectorsYouAppliedOn(String date);

  /// Detail of a returned application the office gave no reason for. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office returned it. You can apply again.'**
  String get sectorsReturnedNoReason;

  /// Detail of a returned application. {reason} is the office's own words, passed through untranslated. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The office said: {reason}'**
  String sectorsOfficeSaid(String reason);

  /// Subtitle of step 1 of Apply for a sector. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Choose the sector that fits you. You\'ll add a photo of your ID next.'**
  String get sectorsChooseSubtitle;

  /// Label of the sector radio group on step 1, and a row label on the sent receipt. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sectorsSector;

  /// Title of step 2. {idName} is the ID's printed name (Senior Citizen ID, PWD ID, Solo Parent ID), kept in English. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add your {idName}'**
  String sectorsProofTitle(String idName);

  /// Subtitle of step 2. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'MSWDO staff check it against their records before the sector is added.'**
  String get sectorsProofSubtitle;

  /// Label above the photo slot on step 2. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Photo of the ID'**
  String get sectorsPhotoLabel;

  /// The empty photo slot on step 2. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get sectorsAddPhoto;

  /// Status of the attached photo. {size} is the file's size, e.g. 1.2 MB. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Photo added · {size}'**
  String sectorsPhotoAdded(String size);

  /// Note under the photo on step 2. Who looks at the photo is stated as 'Taytay LGU staff' on purpose (any LGU staff account can read an upload). The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU staff look at this photo to record your sector. Take it in good light, with the whole ID in the frame.'**
  String get sectorsPhotoNote;

  /// Confirmation tick on step 2. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This ID is mine'**
  String get sectorsConfirmLabel;

  /// Under the confirmation tick. Written in the first person, as the resident's own statement. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'I am sending it so Taytay LGU can record this sector on my profile.'**
  String get sectorsConfirmDescription;

  /// Primary button on step 2. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Send for checking'**
  String get sectorsSend;

  /// Title of the sheet choosing camera or gallery. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Add the photo'**
  String get sectorsSourceTitle;

  /// In the photo sheet when neither camera nor gallery is available. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot add a photo here. The MSWDO can record the sector at the municipal hall.'**
  String get sectorsNoSource;

  /// Title of the receipt after an application was sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get sectorsSentTitle;

  /// Subtitle of the receipt. 'Bayan ng Taytay' is the seal's own words, kept in both. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'{sector} · Bayan ng Taytay'**
  String sectorsSentSubtitle(String sector);

  /// Row label on the receipt: when it was sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sectorsSentAt;

  /// Heading above the receipt's timeline. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get sectorsNextHeading;

  /// Timeline step 1 on the receipt. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Sent to the MSWDO'**
  String get sectorsStepSent;

  /// Timeline step 2 on the receipt. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Staff check your ID'**
  String get sectorsStepCheck;

  /// Timeline step 2 detail. The notice is in-app only, never pushed. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'They may ask for a clearer photo. You will get a notice in this app when they decide.'**
  String get sectorsStepCheckDetail;

  /// Timeline step 3 on the receipt. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Added to your profile'**
  String get sectorsStepAdded;

  /// Timeline step 3 detail. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Then it shows as recorded on Sectors and benefits.'**
  String get sectorsStepAddedDetail;

  /// Primary button on the receipt. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Back to Sectors and benefits'**
  String get sectorsBackToSectors;

  /// Secondary button on the receipt. 'Home' is the tab's name. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get sectorsGoHome;

  /// A send whose outcome is unknown. Never say it was or was not sent. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your application arrived. Before you send it again, open Sectors and benefits: if it shows as being checked, it arrived.'**
  String get sectorsUnconfirmed;

  /// A send that could not leave the phone. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Your choice and photo are still here on the phone. Connect to the internet and send again.'**
  String get sectorsOffline;

  /// Heading when the API refused the photo. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'The photo was not accepted'**
  String get sectorsRefusedTitle;

  /// Body when the API refused the photo. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Choose a clearer JPEG or PNG photo of the ID, up to 5 MB, and send again.'**
  String get sectorsRefused;

  /// Heading when the API answered conflict. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Already on your record or being checked'**
  String get sectorsWaitingTitle;

  /// Body when the API answered conflict. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing new was sent. This sector is already on your record, or an application for it is with the MSWDO. Sectors and benefits shows which.'**
  String get sectorsWaiting;

  /// Heading when the API answered forbidden. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not available for this account'**
  String get sectorsNotOpenTitle;

  /// Body when the API answered forbidden. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Applying for a sector is open to verified residents. The municipal hall can tell you more.'**
  String get sectorsNotOpen;

  /// Heading for any other failed send. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get sectorsFailedSendTitle;

  /// Body for any other failed send. The Filipino text was written by Claude for D-237, following the terms of app_fil.arb, not by a native speaker; a native Filipino speaker from the MSWDO should still read it during UAT.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Something went wrong on our side. Try again in a little while.'**
  String get sectorsFailedSend;

  /// Events list: page title.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// Events list: screen-reader label of the scope chips.
  ///
  /// In en, this message translates to:
  /// **'Show events'**
  String get eventsScopeSemantics;

  /// Events list: chip for upcoming events.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsScopeUpcoming;

  /// Events list: chip for events the resident registered for.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get eventsScopeRegistered;

  /// Events list: chip for finished events.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get eventsScopePast;

  /// Events list: heading when the phone could not reach the office.
  ///
  /// In en, this message translates to:
  /// **'Events are not available right now'**
  String get eventsUnavailableTitle;

  /// Events list: body when offline.
  ///
  /// In en, this message translates to:
  /// **'We could not reach Taytay LGU. Check your connection and try again. Event notices are also posted at the municipal hall and barangay halls.'**
  String get eventsUnavailableBody;

  /// Events list, Upcoming: empty heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled right now'**
  String get eventsEmptyUpcomingTitle;

  /// Events list, Registered: empty heading.
  ///
  /// In en, this message translates to:
  /// **'You have not registered for anything'**
  String get eventsEmptyRegisteredTitle;

  /// Events list, Past: empty heading.
  ///
  /// In en, this message translates to:
  /// **'No past events to show'**
  String get eventsEmptyPastTitle;

  /// Events list, Upcoming: empty body.
  ///
  /// In en, this message translates to:
  /// **'New Taytay LGU events will appear here when they are announced.'**
  String get eventsEmptyUpcomingBody;

  /// Events list, Registered: empty body.
  ///
  /// In en, this message translates to:
  /// **'Events you register for will appear here.'**
  String get eventsEmptyRegisteredBody;

  /// Events list, Past: empty body.
  ///
  /// In en, this message translates to:
  /// **'Events that have finished will appear here.'**
  String get eventsEmptyPastBody;

  /// Events list: title of the note when the next page failed. The trailing space is in the English and kept.
  ///
  /// In en, this message translates to:
  /// **'Could not load more. '**
  String get eventsLoadMoreFailed;

  /// Events list and notifications: the next page failed, what is shown stays.
  ///
  /// In en, this message translates to:
  /// **'What you have already seen is still here.'**
  String get eventsSeenStillHere;

  /// Events list: screen-reader label while the next page loads.
  ///
  /// In en, this message translates to:
  /// **'Loading more events'**
  String get eventsLoadingMore;

  /// Events list: button that loads the next page.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get eventsLoadMore;

  /// Events list: end of the list.
  ///
  /// In en, this message translates to:
  /// **'That is everything Taytay LGU has listed here.'**
  String get eventsListEnd;

  /// Events list row: places left, only as the office stated them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place left} other{{count} places left}}'**
  String eventsPlacesLeft(int count);

  /// Events list: screen-reader label while the first page loads.
  ///
  /// In en, this message translates to:
  /// **'Loading events'**
  String get eventsLoading;

  /// Events list row and event page: an event the office called off.
  ///
  /// In en, this message translates to:
  /// **'Called off by Taytay LGU'**
  String get eventsCalledOff;

  /// Registration state: a walk-in event.
  ///
  /// In en, this message translates to:
  /// **'No registration needed'**
  String get eventsStateNotRequired;

  /// Registration state.
  ///
  /// In en, this message translates to:
  /// **'Registration not open yet'**
  String get eventsStateNotOpen;

  /// Registration state.
  ///
  /// In en, this message translates to:
  /// **'Registration open'**
  String get eventsStateOpen;

  /// Registration state; also the outcome heading for a held place.
  ///
  /// In en, this message translates to:
  /// **'You are registered'**
  String get eventsStateRegistered;

  /// Registration state; also the outcome heading for a waitlist place.
  ///
  /// In en, this message translates to:
  /// **'You are on the waitlist'**
  String get eventsStateWaitlisted;

  /// Registration state: the resident gave up the place.
  ///
  /// In en, this message translates to:
  /// **'You cancelled your place'**
  String get eventsStateCancelled;

  /// Registration state.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get eventsStateFull;

  /// Registration state.
  ///
  /// In en, this message translates to:
  /// **'Registration closed'**
  String get eventsStateClosed;

  /// Registration state this build does not know.
  ///
  /// In en, this message translates to:
  /// **'Ask the office about registering'**
  String get eventsStateUnknown;

  /// Event page: confirmation sheet heading before cancelling a registration.
  ///
  /// In en, this message translates to:
  /// **'Give up your place?'**
  String get eventsGiveUpTitle;

  /// Event page: what giving up the place does.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU will offer your place to the next person waiting. If you change your mind you will have to register again, and the event may be full by then.'**
  String get eventsGiveUpConsequence;

  /// Event page: button that gives up the place (card and sheet).
  ///
  /// In en, this message translates to:
  /// **'Give up my place'**
  String get eventsGiveUpConfirm;

  /// Event page: cancel button of the sheet.
  ///
  /// In en, this message translates to:
  /// **'Keep my place'**
  String get eventsGiveUpKeep;

  /// Event page: the cancellation was answered.
  ///
  /// In en, this message translates to:
  /// **'Your place has been given up. Taytay LGU has been told.'**
  String get eventsGiveUpDone;

  /// Event page: a cancellation that may have arrived (D-188). English is cancellationUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your place was given up. Trying again is safe: it will not be done twice.'**
  String get eventsGiveUpUnconfirmed;

  /// Event page: 409 on a cancellation. English is cancellationTooLate.
  ///
  /// In en, this message translates to:
  /// **'Your place can no longer be given up in the app. Contact Taytay LGU if you cannot go.'**
  String get eventsGiveUpTooLate;

  /// Event page: a cancellation that did not reach the office. {message} is the failure sentence.
  ///
  /// In en, this message translates to:
  /// **'{message} You still have your place.'**
  String eventsGiveUpFailedStillHeld(String message);

  /// Event page: the app refused the directions link.
  ///
  /// In en, this message translates to:
  /// **'That map link could not be opened safely.'**
  String get eventsMapRefused;

  /// Event page: no map app.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can open a map.'**
  String get eventsMapNoApp;

  /// Event page: header title.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventsEventTitle;

  /// Event page: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Opening event…'**
  String get eventsOpening;

  /// Event page: notice on a called-off event.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has called this event off. It will not take place as listed. Ask the office if you have questions.'**
  String get eventsCalledOffBody;

  /// Event page: pill that opens the map.
  ///
  /// In en, this message translates to:
  /// **'Open directions'**
  String get eventsOpenDirections;

  /// Event page: share pill.
  ///
  /// In en, this message translates to:
  /// **'Share this event'**
  String get eventsShareEvent;

  /// Event page: the resident holds a place but the server sent no registration detail.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has your registration for this event. Bring a valid ID.'**
  String get eventsRegisteredNotice;

  /// Event page: fact label.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventsFactWhen;

  /// Event page: fact label.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get eventsFactWhere;

  /// Event page: fact label; the value is the office name.
  ///
  /// In en, this message translates to:
  /// **'Organised by'**
  String get eventsFactOrganiser;

  /// Event page: fact label for the contact.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get eventsFactQuestions;

  /// Event page: section heading over the office's rules.
  ///
  /// In en, this message translates to:
  /// **'Who can join'**
  String get eventsWhoCanJoin;

  /// Event page: section heading over who registration is open to.
  ///
  /// In en, this message translates to:
  /// **'Who can register'**
  String get eventsWhoCanRegister;

  /// Event page: section heading.
  ///
  /// In en, this message translates to:
  /// **'What to bring'**
  String get eventsWhatToBring;

  /// Event page: button that opens registration.
  ///
  /// In en, this message translates to:
  /// **'Register for this event'**
  String get eventsRegisterForEvent;

  /// Event page: under the register button.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU decides whether a place is available.'**
  String get eventsLguDecides;

  /// Event page: label of the registration's reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get eventsReference;

  /// Event page: label of the waitlist position.
  ///
  /// In en, this message translates to:
  /// **'Waitlist position'**
  String get eventsWaitlistPosition;

  /// Event page: attendance recorded.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU recorded you as having attended.'**
  String get eventsAttended;

  /// Event page: attendance not recorded for this resident.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU did not record you as attending. If that is wrong, contact the office.'**
  String get eventsAbsent;

  /// Event page: attendance not yet taken.
  ///
  /// In en, this message translates to:
  /// **'Attendance for this event has not been recorded yet.'**
  String get eventsAttendanceNotRecorded;

  /// Event page: places left out of the capacity.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} places left'**
  String eventsCapacityOfTotal(int remaining, int total);

  /// Event page: places left, no capacity stated. English kept as it was (no singular).
  ///
  /// In en, this message translates to:
  /// **'{remaining} places left'**
  String eventsCapacityLeft(int remaining);

  /// Event page: capacity reached.
  ///
  /// In en, this message translates to:
  /// **'No places left'**
  String get eventsCapacityNone;

  /// Event page: capacity, no count of places left.
  ///
  /// In en, this message translates to:
  /// **'Room for {total} people'**
  String eventsCapacityRoomFor(int total);

  /// Event page: heading of the capacity notice.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get eventsCapacityTitle;

  /// Event page: no places left. {line} is eventsCapacityNone or a count.
  ///
  /// In en, this message translates to:
  /// **'{line}. The office can tell you whether a waitlist is open.'**
  String eventsCapacityFull(String line);

  /// Event page: registration open to verified residents (D-194).
  ///
  /// In en, this message translates to:
  /// **'Residents whose ID Taytay LGU has verified. Verifying takes a few steps and only has to be done once.'**
  String get eventsOpenToVerified;

  /// Event page: registration open to any app account (D-194).
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in to the app. You do not need a verified ID to register for this event.'**
  String get eventsOpenToAccounts;

  /// Event page: unknown or unpublished event.
  ///
  /// In en, this message translates to:
  /// **'This event is not available'**
  String get eventsNotAvailableTitle;

  /// Event page and registration: button back to the list.
  ///
  /// In en, this message translates to:
  /// **'See all events'**
  String get eventsSeeAll;

  /// Registration: screen-reader label while the form loads.
  ///
  /// In en, this message translates to:
  /// **'Opening the registration form…'**
  String get eventsOpeningForm;

  /// Registration: the event has no form.
  ///
  /// In en, this message translates to:
  /// **'Registering in this app is not switched on yet. The Taytay office running this event can tell you how to join.'**
  String get eventsRegistrationNotSwitchedOn;

  /// Registration: screen-reader label while sending.
  ///
  /// In en, this message translates to:
  /// **'Registering you…'**
  String get eventsRegisteringYou;

  /// Registration: page title and the final button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get eventsRegister;

  /// Registration blocked: a place is held.
  ///
  /// In en, this message translates to:
  /// **'You are already registered'**
  String get eventsBlockedAlreadyTitle;

  /// Registration blocked: a place is held.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has your place for this event. Your reference is on the event page.'**
  String get eventsBlockedAlreadyBody;

  /// Registration: button back to the event page.
  ///
  /// In en, this message translates to:
  /// **'Back to the event'**
  String get eventsBackToEvent;

  /// Registration blocked: verification needed.
  ///
  /// In en, this message translates to:
  /// **'This event needs a verified account'**
  String get eventsBlockedVerifyTitle;

  /// Registration blocked: verification needed.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU asks for a confirmed identity before registering for this one. Verifying takes a few steps and only has to be done once.'**
  String get eventsBlockedVerifyBody;

  /// Registration blocked: the form has a field this build cannot show.
  ///
  /// In en, this message translates to:
  /// **'This registration needs the office'**
  String get eventsBlockedUnsupportedTitle;

  /// Registration blocked: the form has a field this build cannot show.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has added something to this form that this version of the app cannot show. Updating the app may help. Until then the office running the event can register you in person.'**
  String get eventsBlockedUnsupportedBody;

  /// Registration blocked: not open.
  ///
  /// In en, this message translates to:
  /// **'Registration is not open'**
  String get eventsBlockedNotOpenTitle;

  /// Registration blocked: not open.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU is not taking registrations for this event right now.'**
  String get eventsBlockedNotOpenBody;

  /// Registration: header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Event registration'**
  String get eventsRegistrationSubtitle;

  /// Registration step title.
  ///
  /// In en, this message translates to:
  /// **'Confirm your registration'**
  String get eventsStepConfirm;

  /// Registration step title.
  ///
  /// In en, this message translates to:
  /// **'Questions from the office'**
  String get eventsStepQuestions;

  /// Registration step title.
  ///
  /// In en, this message translates to:
  /// **'Before you register'**
  String get eventsStepConsent;

  /// Registration step title while sending.
  ///
  /// In en, this message translates to:
  /// **'Registering'**
  String get eventsStepSubmitting;

  /// Registration step title of the result.
  ///
  /// In en, this message translates to:
  /// **'Your registration'**
  String get eventsStepOutcome;

  /// Registration, confirm step: over the event title.
  ///
  /// In en, this message translates to:
  /// **'You are registering for'**
  String get eventsRegisteringFor;

  /// Registration, confirm step.
  ///
  /// In en, this message translates to:
  /// **'This registration will be filed against the account you are signed in with.'**
  String get eventsFiledAgainstAccount;

  /// Registration, confirm step: heading over the office's note.
  ///
  /// In en, this message translates to:
  /// **'From the office'**
  String get eventsFromTheOffice;

  /// Registration, confirm step: said before they commit.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU decides whether a place is available. You will see the answer on the next screen.'**
  String get eventsLguDecidesNextScreen;

  /// Registration: yes/no answer to an office's question.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get eventsAnswerYes;

  /// Registration: yes/no answer to an office's question.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get eventsAnswerNo;

  /// Registration, consent step: an optional consent. {label} is the office's own words.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String eventsConsentOptional(String label);

  /// Registration outcome heading.
  ///
  /// In en, this message translates to:
  /// **'This event is full'**
  String get eventsOutcomeFullTitle;

  /// Registration outcome heading.
  ///
  /// In en, this message translates to:
  /// **'Registration has closed'**
  String get eventsOutcomeClosedTitle;

  /// Registration outcome heading: the server refused.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not register you'**
  String get eventsOutcomeRefusedTitle;

  /// Registration outcome heading: a send that may have arrived (D-188).
  ///
  /// In en, this message translates to:
  /// **'Registration not confirmed'**
  String get eventsOutcomeUnconfirmedTitle;

  /// Registration outcome heading: nothing was sent.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get eventsOutcomeNotRegisteredTitle;

  /// Registration outcome: the waitlist position the office published.
  ///
  /// In en, this message translates to:
  /// **'You are number {position} on the waitlist.'**
  String eventsWaitlistNumber(int position);

  /// Registration outcome: the correlation id to quote.
  ///
  /// In en, this message translates to:
  /// **'If you contact the office, quote {requestId}.'**
  String eventsQuoteRequestId(String requestId);

  /// Registration unavailable heading.
  ///
  /// In en, this message translates to:
  /// **'You cannot register here yet'**
  String get eventsCannotRegisterHere;

  /// Registration outcome: a place is held. English is registrationHeldCopy.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has your place. Quote your reference at the door.'**
  String get eventsOutcomeRegisteredBody;

  /// Registration outcome: waitlisted.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has you on the waitlist. The office moves people up when a place opens, and you will see a notice in the app if it does.'**
  String get eventsOutcomeWaitlistedBody;

  /// Registration outcome: full.
  ///
  /// In en, this message translates to:
  /// **'Every place was taken before your registration arrived, and this event keeps no waitlist. Nothing was registered.'**
  String get eventsOutcomeFullBody;

  /// Registration outcome: closed.
  ///
  /// In en, this message translates to:
  /// **'Registration for this event closed before your registration arrived. Nothing was registered.'**
  String get eventsOutcomeClosedBody;

  /// Registration refused: 403 naming verification.
  ///
  /// In en, this message translates to:
  /// **'This event takes registrations from verified accounts. Verify your account first, then register.'**
  String get eventsRefusedNeedsVerification;

  /// Registration refused: 403.
  ///
  /// In en, this message translates to:
  /// **'Event registration is not available for this account in the app.'**
  String get eventsRefusedNotAllowed;

  /// Registration refused: 404.
  ///
  /// In en, this message translates to:
  /// **'This event is no longer listed, so Taytay LGU could not take a registration for it.'**
  String get eventsRefusedNotListed;

  /// Registration refused: 409.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU is not taking registrations for this event right now. The event page says whether registration opens later.'**
  String get eventsRefusedNotTaking;

  /// Registration refused: 422.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not accept this registration as it was sent. If it happens again, quote the reference below to the office.'**
  String get eventsRefusedNotAccepted;

  /// Registration outcome: a send that may have arrived (D-188, D-191). English is registrationUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your registration was received. Trying again is safe: you will not be registered twice.'**
  String get eventsRegistrationUnconfirmed;

  /// Registration outcome: the connection failed before sending. {message} is the network failure sentence.
  ///
  /// In en, this message translates to:
  /// **'We could not send your registration, so nothing was registered. {message}'**
  String eventsRegistrationNotSent(String message);

  /// Balita: header title when the 'Advisory' category is selected.
  ///
  /// In en, this message translates to:
  /// **'Advisories'**
  String get balitaAdvisoriesTitle;

  /// Balita: header subtitle while a category is selected.
  ///
  /// In en, this message translates to:
  /// **'Balita · filtered'**
  String get balitaFilteredSubtitle;

  /// Balita: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Balita'**
  String get balitaLoading;

  /// Balita: heading when offline.
  ///
  /// In en, this message translates to:
  /// **'Announcements are not available right now'**
  String get balitaUnavailableTitle;

  /// Balita: body when offline.
  ///
  /// In en, this message translates to:
  /// **'We could not reach Taytay LGU. Check your connection and try again. Municipal notices are also posted at the municipal hall and barangay halls.'**
  String get balitaUnavailableBody;

  /// Balita: empty feed heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing new right now'**
  String get balitaEmptyTitle;

  /// Balita: empty feed body.
  ///
  /// In en, this message translates to:
  /// **'New Taytay LGU announcements will appear here.'**
  String get balitaEmptyBody;

  /// Balita: screen-reader label of the category chips.
  ///
  /// In en, this message translates to:
  /// **'Filter Balita'**
  String get balitaFilterSemantics;

  /// Balita: section heading over the list.
  ///
  /// In en, this message translates to:
  /// **'Latest Balita'**
  String get balitaLatest;

  /// Balita: screen-reader label of a row's share button. {title} is the article title.
  ///
  /// In en, this message translates to:
  /// **'Share {title}'**
  String balitaShareArticle(String title);

  /// Balita: share button on a row.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get balitaShare;

  /// Balita: eyebrow of an emergency advisory card.
  ///
  /// In en, this message translates to:
  /// **'Emergency advisory'**
  String get balitaEmergencyAdvisory;

  /// Balita: eyebrow of a pinned advisory card.
  ///
  /// In en, this message translates to:
  /// **'Pinned advisory'**
  String get balitaPinnedAdvisory;

  /// Balita, 'Events' category empty. The heading 'Walang events pa' is Filipino in both languages.
  ///
  /// In en, this message translates to:
  /// **'No upcoming municipal events have been posted. We\'ll notify you when the LGU announces one.'**
  String get balitaEmptyEventsBody;

  /// Balita: a category with no posts. {category} is the server's category name, lower-cased.
  ///
  /// In en, this message translates to:
  /// **'No {category} posts have been published yet.'**
  String balitaEmptyCategoryBody(String category);

  /// Balita: button back to all categories.
  ///
  /// In en, this message translates to:
  /// **'See all Balita'**
  String get balitaSeeAll;

  /// Shared text of an article or event: last line.
  ///
  /// In en, this message translates to:
  /// **'From Taytay LGU'**
  String get balitaShareFooter;

  /// Balita and event page: sharing fell back to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied. You can paste this into any app.'**
  String get balitaShareCopied;

  /// Balita and event page: no share sheet.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available on this device.'**
  String get balitaShareUnavailable;

  /// Balita article: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading the announcement'**
  String get balitaLoadingArticle;

  /// Balita article: unknown or unpublished.
  ///
  /// In en, this message translates to:
  /// **'This announcement is not available'**
  String get balitaArticleNotAvailable;

  /// Balita article: button back to the list.
  ///
  /// In en, this message translates to:
  /// **'See all announcements'**
  String get balitaSeeAllAnnouncements;

  /// Notifications: page title; also the Balita bell label.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get inboxTitle;

  /// Notifications: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications'**
  String get inboxLoading;

  /// Notifications: empty heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get inboxEmptyTitle;

  /// Notifications: empty body.
  ///
  /// In en, this message translates to:
  /// **'Updates about your requests, documents and events will appear here.'**
  String get inboxEmptyBody;

  /// Notifications: heading over everything before today.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get inboxEarlier;

  /// Notifications: eyebrow of a notice with no known category; shown upper-cased.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get inboxEyebrowUpdate;

  /// Notifications: heading when the next page failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load more'**
  String get inboxLoadMoreFailed;

  /// Notifications: screen-reader label while older ones load.
  ///
  /// In en, this message translates to:
  /// **'Loading older'**
  String get inboxLoadingOlder;

  /// Notifications: button that loads older ones.
  ///
  /// In en, this message translates to:
  /// **'Load older'**
  String get inboxLoadOlder;

  /// Notifications: chip showing every notice.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inboxFilterAll;

  /// Notifications: chip showing unread notices, with their count.
  ///
  /// In en, this message translates to:
  /// **'Unread · {count}'**
  String inboxFilterUnread(int count);

  /// Notifications: link that marks every notice read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get inboxMarkAllRead;

  /// Notifications: screen-reader label of the unread dot.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get inboxUnread;

  /// Notification settings: page title.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get inboxSettingsTitle;

  /// Notification settings: screen-reader label while loading.
  ///
  /// In en, this message translates to:
  /// **'Loading notification settings'**
  String get inboxSettingsLoading;

  /// Notification settings: a save whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'Your change may not have been saved'**
  String get inboxSaveUnconfirmedTitle;

  /// Notification settings: a save whose answer was lost.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm it. The switch shows your setting before the change. Setting it again is safe.'**
  String get inboxSaveUnconfirmedBody;

  /// Notification settings: a save that failed.
  ///
  /// In en, this message translates to:
  /// **'That change was not saved'**
  String get inboxSaveFailedTitle;

  /// Notification settings: a save that failed.
  ///
  /// In en, this message translates to:
  /// **'Your setting is unchanged. Check your connection and try again.'**
  String get inboxSaveFailedBody;

  /// Notification settings: over the switches.
  ///
  /// In en, this message translates to:
  /// **'Choose what Taytay LGU tells you about.'**
  String get inboxSettingsIntro;

  /// Notification settings: heading of the note on notices with no switch.
  ///
  /// In en, this message translates to:
  /// **'Always sent'**
  String get inboxAlwaysSentTitle;

  /// Notification settings: why two kinds of notice have no switch.
  ///
  /// In en, this message translates to:
  /// **'Public advisories and messages about your account and security are always sent. They are how Taytay LGU reaches you in an emergency, or tells you if somebody signs in as you.'**
  String get inboxAlwaysSentBody;

  /// Directory: header subtitle on an office page while it loads or fails.
  ///
  /// In en, this message translates to:
  /// **'Office details'**
  String get dirOfficeDetails;

  /// Directory: title when an office page read came back without an office.
  ///
  /// In en, this message translates to:
  /// **'This office could not be shown'**
  String get dirOfficeNotShownTitle;

  /// Directory: body under dirOfficeNotShownTitle.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not be reached, or the office is no longer listed. You can try again.'**
  String get dirOfficeNotShownBody;

  /// Directory: screen-reader label of the skeleton while an office loads.
  ///
  /// In en, this message translates to:
  /// **'Loading the office'**
  String get dirLoadingOffice;

  /// Directory: header title of the search page.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get dirSearchTitle;

  /// Directory: header subtitle of the office list.
  ///
  /// In en, this message translates to:
  /// **'Municipal offices'**
  String get dirMunicipalOffices;

  /// Header bell button: screen-reader label (Directory, Home).
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dirNotifications;

  /// Directory: search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search offices or services'**
  String get dirSearchHint;

  /// Directory: screen-reader label of the category chip row.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get dirCategory;

  /// Directory: the category chip that shows every office.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dirChipAll;

  /// Directory: empty list with no search typed.
  ///
  /// In en, this message translates to:
  /// **'No offices in this category'**
  String get dirNoOfficesInCategory;

  /// Directory: empty search result. query = what the resident typed.
  ///
  /// In en, this message translates to:
  /// **'No offices found for “{query}”'**
  String dirNoOfficesFound(String query);

  /// Directory: hint under an empty search.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or browse by category.'**
  String get dirTryAnotherWord;

  /// Directory: button that clears the search.
  ///
  /// In en, this message translates to:
  /// **'Browse all offices'**
  String get dirBrowseAll;

  /// Directory: the word after the bold number in the list count ("9 offices"). The number is drawn separately before it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{office} other{offices}}'**
  String dirOfficeCountNoun(int count);

  /// Directory: screen-reader label of the list skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading the directory'**
  String get dirLoadingDirectory;

  /// Directory offline: boxed state title.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load the directory'**
  String get dirCantLoadTitle;

  /// Directory offline: boxed state body.
  ///
  /// In en, this message translates to:
  /// **'Check your mobile data or Wi-Fi, then try again. Saved office numbers are listed below.'**
  String get dirCantLoadBody;

  /// Directory offline: section title over the saved office numbers.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get dirSavedOnPhone;

  /// Directory offline strip: title.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get dirOfflineTitle;

  /// Directory offline strip: line under the title.
  ///
  /// In en, this message translates to:
  /// **'Showing what was saved on this phone'**
  String get dirOfflineShowingSaved;

  /// A call button naming who is called (an office, a hotline). name = server text.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String dirCallName(String name);

  /// Office page: tag on a photo that stands for the office but is not of it.
  ///
  /// In en, this message translates to:
  /// **'Representative photo'**
  String get dirRepresentativePhoto;

  /// Office page: dirRepresentativePhoto with the photo credit.
  ///
  /// In en, this message translates to:
  /// **'Representative photo · {credit}'**
  String dirRepresentativePhotoCredit(String credit);

  /// Office page: call pill button.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get dirActionCall;

  /// Office page: pill button that opens maps.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get dirActionDirections;

  /// Office page: pill button that opens a new message to the office.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get dirActionMessage;

  /// Office page: pill button that opens the office's own app (offices that take no message).
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get dirActionApp;

  /// Office page: fact label for the address.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get dirFactLocation;

  /// Office page: fact label for opening hours.
  ///
  /// In en, this message translates to:
  /// **'Office hours'**
  String get dirFactHours;

  /// Office page: fact label for the phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get dirFactPhone;

  /// Office page: fact label for the email address.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get dirFactEmail;

  /// Office page: fact label for the head of office.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get dirFactHead;

  /// Office page: section title over the office's services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get dirServices;

  /// New message to an office: header title.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get dirNewMessage;

  /// New message: the office read answered with nothing.
  ///
  /// In en, this message translates to:
  /// **'This office did not load'**
  String get dirOfficeDidNotLoadTitle;

  /// New message: body under dirOfficeDidNotLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Try again, or go back to the directory.'**
  String get dirOfficeDidNotLoadBody;

  /// New message: label of the topic field (and its screen-reader label when empty).
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get dirTopic;

  /// New message: screen-reader label of the topic field with its value.
  ///
  /// In en, this message translates to:
  /// **'Topic, {topic}'**
  String dirTopicValue(String topic);

  /// New message: the topic shown when the office publishes none. The office still receives the English subject.
  ///
  /// In en, this message translates to:
  /// **'General enquiry'**
  String get dirGeneralTopic;

  /// New message: label of the message field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get dirFieldMessage;

  /// New message: message field hint.
  ///
  /// In en, this message translates to:
  /// **'Write your message'**
  String get dirMessageHint;

  /// New message: send button.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get dirSendMessage;

  /// New message: warning under the form, after the office's own privacy sentence.
  ///
  /// In en, this message translates to:
  /// **'Don’t share passwords or one-time codes in a message.'**
  String get dirPrivacyWarning;

  /// New message / Message sent: label before the office's name.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dirTo;

  /// New message: attach button.
  ///
  /// In en, this message translates to:
  /// **'Attach photo or PDF (optional)'**
  String get dirAttach;

  /// Message sent: bold heading of the emergency note.
  ///
  /// In en, this message translates to:
  /// **'For emergencies don\'t wait for a reply'**
  String get dirEmergencyHeading;

  /// Message sent: emergency note when no command center is marked.
  ///
  /// In en, this message translates to:
  /// **'Call an emergency hotline.'**
  String get dirEmergencyBody;

  /// Message sent: emergency note naming the command center. name/number = server text.
  ///
  /// In en, this message translates to:
  /// **'Call {name}: {number}.'**
  String dirEmergencyCallLine(String name, String number);

  /// Message sent: button to the Emergency hotlines page.
  ///
  /// In en, this message translates to:
  /// **'See emergency hotlines'**
  String get dirSeeHotlines;

  /// Message sent: screen-reader label while the hotlines load.
  ///
  /// In en, this message translates to:
  /// **'Loading the emergency hotline'**
  String get dirLoadingHotline;

  /// Message sent: page title.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get dirMessageSentTitle;

  /// Message sent: what happens next. Names the My Account > Messages screen.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you, and the conversation is saved in My Account › Messages.'**
  String get dirMessageSentBody;

  /// Message sent: primary button.
  ///
  /// In en, this message translates to:
  /// **'Go to Messages'**
  String get dirGoToMessages;

  /// Message sent: secondary button.
  ///
  /// In en, this message translates to:
  /// **'Back to Directory'**
  String get dirBackToDirectory;

  /// Office thread: screen-reader label of the bubbles.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get dirConversation;

  /// New message: the phone has no file picker.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot attach a file.'**
  String get dirCannotAttach;

  /// New message: Send pressed with an empty message.
  ///
  /// In en, this message translates to:
  /// **'Write a message before sending.'**
  String get dirWriteBeforeSending;

  /// A call button pressed on a phone with no dialler (Directory, Home, Hotlines).
  ///
  /// In en, this message translates to:
  /// **'This phone has no app that can place a call.'**
  String get dirNoDialer;

  /// Tulong tab: header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Social services & programmes'**
  String get tulongSubtitle;

  /// Tulong offline: header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Social services · MSWDO'**
  String get tulongSubtitleMswdo;

  /// Tulong: note under a list where no page takes applications in the app.
  ///
  /// In en, this message translates to:
  /// **'Information on municipal programmes. These are information pages, not applications.'**
  String get tulongNoteInformationOnly;

  /// Tulong: note under a list where at least one page takes applications.
  ///
  /// In en, this message translates to:
  /// **'Information on municipal programmes. Some pages also take applications in the app: open a page to see whether it does.'**
  String get tulongNoteSomeApply;

  /// Tulong: heading of the note over a list a refresh could not replace.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh the list'**
  String get tulongStaleHeading;

  /// Tulong: when the list on screen was read. timestamp = Manila date and time, formatted by the app.
  ///
  /// In en, this message translates to:
  /// **'Showing the list from {timestamp}. It may have changed.'**
  String tulongStaleMessage(String timestamp);

  /// Tulong: the catalogue is longer than the app reads. shown = how many were read.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU lists more programmes than this app loads. This list and the search cover the first {shown} only.'**
  String tulongIncomplete(int shown);

  /// Tulong: search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search programmes'**
  String get tulongSearchHint;

  /// Tulong: screen-reader label of the list skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading programmes'**
  String get tulongLoading;

  /// Tulong: the Try again button while its read is on its way.
  ///
  /// In en, this message translates to:
  /// **'Trying again…'**
  String get tulongTryingAgain;

  /// Tulong: empty search result title.
  ///
  /// In en, this message translates to:
  /// **'No programmes match that search.'**
  String get tulongNoMatchTitle;

  /// Tulong: empty search result body.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or clear the search to see every programme.'**
  String get tulongNoMatchBody;

  /// Tulong: the catalogue is empty.
  ///
  /// In en, this message translates to:
  /// **'No programmes listed yet'**
  String get tulongEmptyTitle;

  /// Tulong: body under tulongEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Programme information from Taytay LGU will appear here.'**
  String get tulongEmptyBody;

  /// Tulong / programme page: no connection.
  ///
  /// In en, this message translates to:
  /// **'Programme pages need a connection'**
  String get tulongOfflineTitle;

  /// Tulong offline: body when no pages are saved.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the latest programme information.'**
  String get tulongOfflineBody;

  /// Tulong offline: body when saved pages are listed below.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the latest programme information. Pages you opened before are saved below.'**
  String get tulongOfflineBodySaved;

  /// Tulong offline: section title over saved pages.
  ///
  /// In en, this message translates to:
  /// **'Saved pages'**
  String get tulongSavedPages;

  /// Programme page: section title over the eligibility text (server text).
  ///
  /// In en, this message translates to:
  /// **'Who can avail'**
  String get tulongWhoCanAvail;

  /// Programme page: section title over the requirements; followed by tulongInformationOnly.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get tulongRequirements;

  /// Programme page: muted words after the Requirements title.
  ///
  /// In en, this message translates to:
  /// **'(information only)'**
  String get tulongInformationOnly;

  /// Featured programme page: section title over the claim steps.
  ///
  /// In en, this message translates to:
  /// **'How to claim'**
  String get tulongHowToClaim;

  /// Featured programme page: fact label.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tulongSchedule;

  /// Featured programme page: fact label for whom to ask, when the server gives none.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get tulongQuestions;

  /// Featured programme page: share button, when the server gives no label.
  ///
  /// In en, this message translates to:
  /// **'Share with a family member'**
  String get tulongShare;

  /// Programme page: fact label over the office's name.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get tulongFactOffice;

  /// Programme page: fact label over office hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get tulongFactHours;

  /// Programme page: contact label when the server sent none (type landline).
  ///
  /// In en, this message translates to:
  /// **'Landline'**
  String get tulongContactLandline;

  /// Programme page: contact label when the server sent none (type hotline).
  ///
  /// In en, this message translates to:
  /// **'Hotline'**
  String get tulongContactHotline;

  /// Programme page: contact label when the server sent none (type email).
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get tulongContactEmail;

  /// Programme page: contact label when the server sent none (type mobile).
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get tulongContactMobile;

  /// Programme page: contact label when the server sent none and the type is unknown.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get tulongContactOther;

  /// Programme page: Call pressed with no number.
  ///
  /// In en, this message translates to:
  /// **'This office has not published a phone number.'**
  String get tulongNoPhone;

  /// Programme page: the dialler could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Calling is not available on this device.'**
  String get tulongNoCalling;

  /// Programme page: Directions pressed with no address.
  ///
  /// In en, this message translates to:
  /// **'This office has not published an address.'**
  String get tulongNoAddress;

  /// Programme page: maps could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Maps could not be opened on this device.'**
  String get tulongNoMaps;

  /// Programme page: Message pressed with no office.
  ///
  /// In en, this message translates to:
  /// **'This programme is not linked to an office.'**
  String get tulongNoOffice;

  /// Programme page: last line of the text shared to a family member.
  ///
  /// In en, this message translates to:
  /// **'From Taytay LGU'**
  String get tulongShareSignature;

  /// Programme page: share fell back to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied. You can paste this into any app.'**
  String get tulongCopied;

  /// Programme page: sharing unavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available on this device.'**
  String get tulongNoSharing;

  /// Programme page: the programme is no longer listed.
  ///
  /// In en, this message translates to:
  /// **'This programme is not available'**
  String get tulongNotAvailableTitle;

  /// Programme page: body under tulongNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to Tulong to see the programmes listed now.'**
  String get tulongNotAvailableBody;

  /// Programme page offline: body.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get tulongCheckConnection;

  /// Programme page: screen-reader label of the skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading programme'**
  String get tulongLoadingOne;

  /// Home status card (guest): title.
  ///
  /// In en, this message translates to:
  /// **'Browsing as guest'**
  String get homeGuestTitle;

  /// Home status card (guest): body.
  ///
  /// In en, this message translates to:
  /// **'Sign up to message offices.'**
  String get homeGuestBody;

  /// Home status card: title when the account is not verified (no ID sent, or not yet known).
  ///
  /// In en, this message translates to:
  /// **'Not yet verified'**
  String get homeNotVerifiedTitle;

  /// Home status card: no ID sent yet.
  ///
  /// In en, this message translates to:
  /// **'No ID has been sent yet. Send one in the app, or verify in person at the MSWDO. Messaging offices unlocks once verified.'**
  String get homeNotSentBody;

  /// Home status card: an ID is under review.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get homePendingTitle;

  /// Home status card: body while the ID is reviewed.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU is reviewing your ID. Messaging offices unlocks once verified.'**
  String get homePendingBody;

  /// Home status card: the ID was not accepted.
  ///
  /// In en, this message translates to:
  /// **'Your ID was not accepted'**
  String get homeRejectedTitle;

  /// Home status card: body when the ID was not accepted.
  ///
  /// In en, this message translates to:
  /// **'See what to fix and send it again, or verify in person at the MSWDO. Messaging offices unlocks once verified.'**
  String get homeRejectedBody;

  /// Home status card: body while the verification state is not yet known.
  ///
  /// In en, this message translates to:
  /// **'Messaging offices unlocks once verified.'**
  String get homeUnlocksOnceVerified;

  /// Home status card: button when the ID was not accepted.
  ///
  /// In en, this message translates to:
  /// **'See what to fix'**
  String get homeFixAction;

  /// Home status card: button while the state is not yet known.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get homeStatusAction;

  /// Home status card (guest): button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get homeCreateAccount;

  /// Home: screen-reader label of the slide skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading featured stories'**
  String get homeLoadingStories;

  /// Home: section title over the newest news.
  ///
  /// In en, this message translates to:
  /// **'Latest Balita'**
  String get homeLatestBalita;

  /// Home: link at the end of a section title.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// Home: screen-reader label of the news skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading Balita'**
  String get homeLoadingBalita;

  /// Home: section title over the emergency hotline.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get homeEmergency;

  /// Home: link to the Emergency hotlines page.
  ///
  /// In en, this message translates to:
  /// **'All hotlines'**
  String get homeAllHotlines;

  /// Home header bell: screen-reader label with unread count.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String homeNotificationsUnread(int count);

  /// Home header: line while the page refreshes.
  ///
  /// In en, this message translates to:
  /// **'Updating Balita and advisories…'**
  String get homeUpdating;

  /// Home quick launcher tile (and a slide eyebrow) for the Emergency hotlines page.
  ///
  /// In en, this message translates to:
  /// **'Hotlines'**
  String get homeHotlines;

  /// Home slide eyebrow for a banner that opens Events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get homeEvents;

  /// Home slide button that opens Balita.
  ///
  /// In en, this message translates to:
  /// **'Read Balita'**
  String get homeReadBalita;

  /// Home slide button that opens Tulong.
  ///
  /// In en, this message translates to:
  /// **'Explore Tulong'**
  String get homeExploreTulong;

  /// Home slide button that opens the Directory.
  ///
  /// In en, this message translates to:
  /// **'Open Directory'**
  String get homeOpenDirectory;

  /// Home slide button that opens Emergency hotlines.
  ///
  /// In en, this message translates to:
  /// **'See hotlines'**
  String get homeSeeHotlines;

  /// Home slide button that opens Events.
  ///
  /// In en, this message translates to:
  /// **'See events'**
  String get homeSeeEvents;

  /// Home slide button when the banner's link names no known page.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpen;

  /// Emergency hotlines page: header title.
  ///
  /// In en, this message translates to:
  /// **'Emergency hotlines'**
  String get homeHotlinesTitle;

  /// Emergency hotlines: screen-reader label of the skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading hotlines'**
  String get homeLoadingHotlines;

  /// Emergency hotlines: empty state title.
  ///
  /// In en, this message translates to:
  /// **'No hotlines to show'**
  String get homeNoHotlinesTitle;

  /// Emergency hotlines: empty state body.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not published any hotlines here yet.'**
  String get homeNoHotlinesBody;

  /// Emergency hotlines: heading over the municipal lines (the other heading is Barangay).
  ///
  /// In en, this message translates to:
  /// **'Municipal'**
  String get homeHotlinesMunicipal;

  /// Emergency hotlines: source line under the list.
  ///
  /// In en, this message translates to:
  /// **'Source: Taytay LGU / Taytay Public Information Office.'**
  String get homeHotlinesSource;

  /// Failure message: the server did not answer in time (TimeoutFailure). Mirrors AppFailure.residentMessage.
  ///
  /// In en, this message translates to:
  /// **'The request is taking longer than expected. Please try again.'**
  String get coreFailureTimeout;

  /// Failure message: the sign-in is no longer valid (UnauthenticatedFailure).
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again to continue.'**
  String get coreFailureUnauthenticated;

  /// Failure message: a plain FORBIDDEN, which does not say why.
  ///
  /// In en, this message translates to:
  /// **'This service is not available for your account right now.'**
  String get coreFailureForbidden;

  /// Failure message: the server answered VERIFICATION_REQUIRED.
  ///
  /// In en, this message translates to:
  /// **'Verify your account first to use this service.'**
  String get coreFailureVerificationRequired;

  /// Failure message: the server answered BIOMETRIC_CONSENT_REQUIRED; no consent to the current published selfie (biometric) text stands. Consent wording: do not soften.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. A selfie needs your consent to the selfie text Taytay LGU publishes now. Agree to it, or verify in person.'**
  String get coreFailureBiometricConsent;

  /// Failure message: server-side validation failed; field errors are shown beside the fields.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted details and try again.'**
  String get coreFailureValidation;

  /// Failure message: a plain CONFLICT (duplicate submission or concurrent change).
  ///
  /// In en, this message translates to:
  /// **'This was already submitted. Refresh to see the latest status.'**
  String get coreFailureConflict;

  /// Failure message: INVALID_STATE_TRANSITION, the request is no longer in the state the action needs.
  ///
  /// In en, this message translates to:
  /// **'This request has already moved forward. Refresh to see its current status.'**
  String get coreFailureInvalidStateTransition;

  /// Failure message: BARANGAY_HELD_BY_OFFICE (D-235). Same sentence as BarangayLock.refused in the account feature.
  ///
  /// In en, this message translates to:
  /// **'Your account is verified, so your barangay is changed at the MSWDO office. To change your barangay, visit the MSWDO office with proof of your new address.'**
  String get coreFailureBarangayHeldByOffice;

  /// Failure message: RATE_LIMITED with a Retry-After the server gave. Without one, failureRateLimited is used.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again in {seconds} seconds.'**
  String coreFailureRateLimitedFor(int seconds);

  /// Failure message: 503 / maintenance, or a list too long to send; retrying later is right.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again shortly.'**
  String get coreFailureServiceUnavailable;

  /// Failure message: a 5xx other than 503.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get coreFailureServer;

  /// Failure message: the server's answer did not match the contract.
  ///
  /// In en, this message translates to:
  /// **'We could not read the response from the server. Please try again.'**
  String get coreFailureContract;

  /// Failure message: an error inside the app.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again, or contact the LGU if it keeps happening.'**
  String get coreFailureUnexpected;

  /// Failure message: PAYLOAD_TOO_LARGE / HTTP 413 on an upload.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to send. Try a smaller photo or a lower quality setting.'**
  String get coreFailureFileTooLarge;

  /// Failure message: code_invalid, a 6-digit email or reset code was refused; another try is allowed.
  ///
  /// In en, this message translates to:
  /// **'That code was not accepted.'**
  String get coreFailureCodeInvalid;

  /// Failure message: code_expired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Request a new one.'**
  String get coreFailureCodeExpired;

  /// Failure message: code_locked, too many wrong codes.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait before requesting another code.'**
  String get coreFailureCodeLocked;

  /// Sign-in (02-10): wrong password or unknown email, one sentence for both. The numbers are the designed lockout notice, fixed in the English too.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. 2 attempts left before a 15-minute pause.'**
  String get coreSignInCredentialsRejected;

  /// Sign-in: a mobile number was typed into password sign-in. Does not say whether the number has an account.
  ///
  /// In en, this message translates to:
  /// **'Use your email to sign in with a password, or get a code sent to your mobile.'**
  String get coreSignInPasswordNeedsEmail;

  /// A deep link or notification tap named nothing this build can open (unknown target, bad id, wrong arity). One sentence on purpose: the app does not say what exists.
  ///
  /// In en, this message translates to:
  /// **'That link could not be opened. It may be for a newer version of the app, or the item may no longer be available.'**
  String get coreDeepLinkUnavailable;

  /// A deep link asked the app to perform an action (submit, cancel, approve...). Refused.
  ///
  /// In en, this message translates to:
  /// **'That link tried to do something on your behalf. Taytay LGU IDS never acts from a link — open the item and choose for yourself.'**
  String get coreDeepLinkActionRefused;

  /// Header of the screen shown for a route the app does not have.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get coreRouteNotFoundTitle;

  /// Body of the page-not-found screen.
  ///
  /// In en, this message translates to:
  /// **'That link does not lead anywhere in this app.'**
  String get coreRouteNotFoundBody;

  /// Button on the page-not-found screen. 'Home' is the tab name (navHome), the same in both languages.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get coreRouteGoHome;

  /// Line the OS prints on its fingerprint/face/screen-lock prompt when the resident switches the app lock on. No full stop, as the OS shows it as a subtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it is you before turning on the app lock'**
  String get coreAppLockEnableReason;

  /// Line the OS prints on its fingerprint/face/screen-lock prompt to unlock the app. 'Taytay LGU IDS' is the app's name.
  ///
  /// In en, this message translates to:
  /// **'Unlock Taytay LGU IDS'**
  String get coreAppLockUnlockReason;

  /// Screen-reader name of the official municipal seal (header, digital ID).
  ///
  /// In en, this message translates to:
  /// **'Seal of the Municipality of Taytay, Rizal'**
  String get coreSealSemanticLabel;

  /// Screen-reader name of the welcome photo of the municipal hall.
  ///
  /// In en, this message translates to:
  /// **'Photo: Taytay Municipal Hall'**
  String get corePhotoMunicipalHall;

  /// Screen-reader name of the welcome photo of the Taytay tiangge (market).
  ///
  /// In en, this message translates to:
  /// **'Photo: Taytay Tiangge'**
  String get corePhotoTiangge;

  /// Screen-reader name of the welcome photo of St. John the Baptist Parish Church, Taytay.
  ///
  /// In en, this message translates to:
  /// **'Photo: St. John the Baptist Parish Church'**
  String get corePhotoParishChurch;

  /// Selfie consent dialog: title (registration, verification).
  ///
  /// In en, this message translates to:
  /// **'Your consent before a selfie'**
  String get sharedBiometricDialogTitle;

  /// Selfie consent dialog: heading over what is collected and why.
  ///
  /// In en, this message translates to:
  /// **'What the app collects, and why'**
  String get sharedBiometricWhatHeading;

  /// Selfie consent dialog: what is collected and why (RA 10173 informed consent). Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'A selfie: a photo of your face. Taytay LGU staff compare it with the photo on your ID to confirm that this account is yours, and it is the photo on your Taytay digital ID once you are verified. A photo of a face used to confirm who someone is counts as biometric data, so the app asks for your consent before the camera opens.'**
  String get sharedBiometricWhat;

  /// Selfie consent dialog: heading over the consent text the LGU published.
  ///
  /// In en, this message translates to:
  /// **'The consent Taytay LGU published'**
  String get sharedBiometricTextHeading;

  /// Selfie consent dialog: version of the published consent text.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String sharedBiometricVersion(String version);

  /// Selfie consent dialog: consent is free and can be withdrawn. Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'Agreeing is your choice. If you do not agree, you can still be verified in person, without a selfie. You can withdraw this consent at any time under Account, Consents and account requests; withdrawing erases your selfies.'**
  String get sharedBiometricChoice;

  /// Selfie consent dialog: the consent tick box. Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'I agree that Taytay LGU may take and use my selfie as described above.'**
  String get sharedBiometricTick;

  /// Selfie consent dialog: primary button.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get sharedBiometricAgree;

  /// Selfie consent dialog: primary button while the consent is being recorded.
  ///
  /// In en, this message translates to:
  /// **'Recording your consent…'**
  String get sharedBiometricRecording;

  /// Selfie consent dialog: decline button, leading to in-person verification.
  ///
  /// In en, this message translates to:
  /// **'No, I\'ll verify in person'**
  String get sharedBiometricDecline;

  /// Note heading when the LGU has not published the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'Selfie verification is not available yet'**
  String get sharedBiometricUnavailableHeading;

  /// Note body when the LGU has not published the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU has not yet published the consent the app needs before it can take a selfie, so no selfie can be sent for now. Your account works without it.'**
  String get sharedBiometricUnavailable;

  /// In-person verification note: heading.
  ///
  /// In en, this message translates to:
  /// **'Verify in person'**
  String get sharedBiometricInPersonHeading;

  /// In-person verification note: body.
  ///
  /// In en, this message translates to:
  /// **'Bring a valid ID to the MSWDO. Staff check it and verify your account. No selfie is taken.'**
  String get sharedBiometricInPerson;

  /// In-person verification note: the office's hours as the directory gives them.
  ///
  /// In en, this message translates to:
  /// **'Hours: {hours}'**
  String sharedBiometricInPersonHours(String hours);

  /// In-person verification note: the office's phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String sharedBiometricInPersonPhone(String phone);

  /// Note heading after the resident declined the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'No selfie was taken'**
  String get sharedBiometricDeclinedHeading;

  /// Note body after the resident declined the selfie consent.
  ///
  /// In en, this message translates to:
  /// **'You did not agree to the selfie consent, and that is fine. Nothing was recorded or sent.'**
  String get sharedBiometricDeclined;

  /// Note heading when the consent status could not be read.
  ///
  /// In en, this message translates to:
  /// **'Could not check the selfie consent'**
  String get sharedBiometricFailedHeading;

  /// Note body when the consent status could not be read.
  ///
  /// In en, this message translates to:
  /// **'No selfie can be taken until the app knows where your consent stands. Check your connection and try again.'**
  String get sharedBiometricFailed;

  /// Selfie consent dialog: the server refused to record the consent.
  ///
  /// In en, this message translates to:
  /// **'Your consent was not recorded, so no selfie was taken. You can try again.'**
  String get sharedBiometricNotRecorded;

  /// Selfie consent dialog: the outcome of recording is unknown; retry is idempotent.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm that your consent was recorded, so no selfie was taken yet. Trying again is safe: it is recorded only once.'**
  String get sharedBiometricNotConfirmed;

  /// Privacy controls: what withdrawing the selfie consent does, shown before the button (NPC Circular 2023-04). Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'Withdrawing erases every selfie you sent, in the same moment. A verification request still waiting for review then needs a new selfie before staff can approve it, and a Taytay digital ID loses its photo. What was already done stays as it is: a withdrawal is not backdated.'**
  String get sharedBiometricWithdrawEffects;

  /// Privacy controls: button that opens the withdrawal confirmation.
  ///
  /// In en, this message translates to:
  /// **'Withdraw the selfie consent'**
  String get sharedBiometricWithdrawButton;

  /// Privacy controls: withdrawal confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Withdraw the selfie consent?'**
  String get sharedBiometricWithdrawTitle;

  /// Privacy controls: confirming button of the withdrawal dialog.
  ///
  /// In en, this message translates to:
  /// **'Withdraw and erase my selfies'**
  String get sharedBiometricWithdrawConfirm;

  /// Privacy controls: cancel button of the withdrawal dialog.
  ///
  /// In en, this message translates to:
  /// **'Keep my consent'**
  String get sharedBiometricWithdrawCancel;

  /// Legal text dialog: shown when the Terms of Use are not published.
  ///
  /// In en, this message translates to:
  /// **'The full Terms of Use will be available soon. Taytay LGU has not published them in the app yet.'**
  String get sharedTermsNotPublishedYet;

  /// Legal text dialog: shown when the Privacy Notice is not published.
  ///
  /// In en, this message translates to:
  /// **'The full Privacy Notice will be available soon. Taytay LGU has not published it in the app yet.'**
  String get sharedPrivacyNoticeNotPublishedYet;

  /// Tick box for accepting the Terms of Use (recorded as its own act, D-208). Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Use.'**
  String get sharedTermsConsentLabel;

  /// Tick box acknowledging the Privacy Notice. Legal wording: meaning must stay exact.
  ///
  /// In en, this message translates to:
  /// **'I have read the Privacy Notice and understand how Taytay LGU uses my personal data.'**
  String get sharedPrivacyConsentLabel;

  /// Screen-reader label while a legal text (Terms of Use, Privacy Notice) loads.
  ///
  /// In en, this message translates to:
  /// **'Loading {title}'**
  String sharedLegalTextLoading(String title);

  /// Barangay picker sheet: title.
  ///
  /// In en, this message translates to:
  /// **'Choose your barangay'**
  String get sharedBarangayPickerTitle;

  /// Barangay picker: screen-reader label while the list loads.
  ///
  /// In en, this message translates to:
  /// **'Loading barangays'**
  String get sharedBarangayPickerLoading;

  /// Barangay picker: the API returned an empty list.
  ///
  /// In en, this message translates to:
  /// **'No barangays are listed yet. Please try again later.'**
  String get sharedBarangayPickerEmpty;

  /// Barangay picker: the list could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'We could not load the list of barangays. Check your connection and try again.'**
  String get sharedBarangayPickerFailed;

  /// Office hours line: the office is open now (bold, green).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get sharedHoursOpen;

  /// Office hours line: the office is closed now (bold, red).
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get sharedHoursClosed;

  /// Office hours line: when an open office closes. {time} is like 5:00 PM.
  ///
  /// In en, this message translates to:
  /// **'Closes {time}'**
  String sharedHoursCloses(String time);

  /// Office hours line: a closed office opens later today.
  ///
  /// In en, this message translates to:
  /// **'Opens {time} today'**
  String sharedHoursOpensToday(String time);

  /// Office hours line: a closed office opens tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Opens {time} tomorrow'**
  String sharedHoursOpensTomorrow(String time);

  /// Office hours line: a closed office opens on a later weekday. {weekday} is one of the sharedWeekday… strings.
  ///
  /// In en, this message translates to:
  /// **'Opens {time} {weekday}'**
  String sharedHoursOpensOn(String time, String weekday);

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get sharedWeekdayMonday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get sharedWeekdayTuesday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get sharedWeekdayWednesday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get sharedWeekdayThursday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get sharedWeekdayFriday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get sharedWeekdaySaturday;

  /// Weekday name in the office hours line.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sharedWeekdaySunday;

  /// Form error summary heading, above the list of what to fix.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{There is a problem} other{There are {count} problems}}'**
  String sharedFormErrorSummaryHeading(int count);

  /// Expandable panel title explaining why a sensitive field is collected (RA 10173).
  ///
  /// In en, this message translates to:
  /// **'Why we ask for this'**
  String get sharedWhyWeAskTitle;

  /// Why-we-ask panel: label before the purpose.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get sharedWhyWeAskWhy;

  /// Why-we-ask panel: label before who inside the LGU sees the data.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get sharedWhyWeAskWhoSeesIt;

  /// Why-we-ask panel: label before what happens if the resident does not give it.
  ///
  /// In en, this message translates to:
  /// **'If you would rather not'**
  String get sharedWhyWeAskIfYouDecline;

  /// Screen-reader name of the icon on an information note.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get sharedNoteToneInfo;

  /// Screen-reader name of the icon on a warning note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get sharedNoteToneWarning;

  /// Screen-reader name of the icon on an error note.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get sharedNoteToneError;

  /// Screen-reader name of the icon on a success note.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sharedNoteToneSuccess;

  /// Screen-reader name of the icon on an emergency note.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sharedNoteToneEmergency;

  /// Conversation composer: placeholder in the message field.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get sharedComposerHint;

  /// Conversation composer: screen-reader label of the button that removes the chosen file.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get sharedComposerRemoveAttachment;

  /// Conversation composer: screen-reader label of the attach button.
  ///
  /// In en, this message translates to:
  /// **'Attach photo or PDF'**
  String get sharedComposerAttach;

  /// Conversation composer: screen-reader label of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sharedComposerSend;

  /// Default confirm button of a confirmation dialog when the screen gives none.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get sharedDialogConfirm;

  /// Default cancel button of a consequence confirmation (the safe choice).
  ///
  /// In en, this message translates to:
  /// **'Keep it as it is'**
  String get sharedConfirmKeepAsItIs;

  /// Confirmation dialog: banner title over the consequence.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get sharedConfirmWhatHappens;

  /// Tooltip and screen-reader label of a banner's close button.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get sharedBannerDismiss;

  /// Label above a multi-line message field.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get sharedMessageFieldLabel;

  /// Screen-reader part of a settings row: how many new items its red badge counts.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String sharedBadgeNew(int count);

  /// Default offline error message under 'You are offline'.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU could not be reached. Check your connection and try again.'**
  String get sharedOfflineMessage;

  /// Small gold tag marking a fact the LGU has not confirmed yet (sample content). Upper case.
  ///
  /// In en, this message translates to:
  /// **'SAMPLE'**
  String get sharedSampleTag;

  /// Prefix every drawn illustration's screen-reader label starts with. The three sharedIllustration… labels must start with exactly this text in each language.
  ///
  /// In en, this message translates to:
  /// **'Illustration:'**
  String get sharedIllustrationLabelPrefix;

  /// Screen-reader label of the empty-state drawing.
  ///
  /// In en, this message translates to:
  /// **'Illustration: an empty tray, meaning there is nothing here yet.'**
  String get sharedIllustrationEmpty;

  /// Screen-reader label of the error-state drawing (a broken chain link).
  ///
  /// In en, this message translates to:
  /// **'Illustration: a disconnected link, meaning something could not be loaded.'**
  String get sharedIllustrationError;

  /// Screen-reader label of the animated success tick.
  ///
  /// In en, this message translates to:
  /// **'Illustration: a check mark, meaning the request was completed.'**
  String get sharedIllustrationSuccess;

  /// Startup stop screen headline. A release build can show it if Firebase refuses to start on the phone; the technical issues listed under it stay English.
  ///
  /// In en, this message translates to:
  /// **'This build is not configured correctly and cannot start.'**
  String get sharedConfigStopTitle;

  /// Screen-reader name of the settings icon on the startup stop screen.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get sharedConfigStopIconLabel;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(lookupAppStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

AppStrings lookupAppStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppStringsEn();
    case 'fil':
      return AppStringsFil();
  }

  throw FlutterError(
    'AppStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
