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
  /// **'Services'**
  String get navServices;

  /// Shell destination: LGU announcements.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get navNews;

  /// Shell destination: LGU events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// Shell destination: the resident's own account.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
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

  /// Offline banner body. Must keep the promise that nothing was sent.
  ///
  /// In en, this message translates to:
  /// **'The app cannot get through right now. Anything you have typed is still here, and nothing has been sent.'**
  String get networkUnreachableMessage;

  /// Heading for work the resident finished that the office has not received. Never translate this as 'saved': a resident who reads 'saved' believes the office has it and stops chasing it.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get unsentTitle;

  /// Body for unsent work.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU does not have {what}. Everything you typed is still on this phone. Nothing was filed, so sending again does not create a duplicate.'**
  String unsentMessage(String what);

  /// Last-updated line over cached content. The timestamp is pre-formatted in Manila time by ManilaTime, so it is passed in as a string rather than a DateTime.
  ///
  /// In en, this message translates to:
  /// **'Showing what was saved on {timestamp}. It may have changed.'**
  String staleContentMessage(String timestamp);

  /// Resident copy for a request that never arrived. Chosen by failure kind, never taken from the server's message, which is operator-facing.
  ///
  /// In en, this message translates to:
  /// **'The app could not reach Taytay LGU. Check your connection and try again.'**
  String get failureNetwork;

  /// No description provided for @failureTimeout.
  ///
  /// In en, this message translates to:
  /// **'Taytay LGU took too long to answer. Please try again.'**
  String get failureTimeout;

  /// No description provided for @failureUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Sign in again to continue.'**
  String get failureUnauthenticated;

  /// No description provided for @failureForbidden.
  ///
  /// In en, this message translates to:
  /// **'This is not available for your account.'**
  String get failureForbidden;

  /// No description provided for @failureNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get failureNotFound;

  /// No description provided for @failureValidation.
  ///
  /// In en, this message translates to:
  /// **'Some of what you entered needs changing.'**
  String get failureValidation;

  /// No description provided for @failureFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large to send. Try a smaller photo, or take it again at a lower quality.'**
  String get failureFileTooLarge;

  /// No description provided for @failureFileType.
  ///
  /// In en, this message translates to:
  /// **'That kind of file cannot be sent. Try a photo or a PDF instead.'**
  String get failureFileType;

  /// No description provided for @failureConflict.
  ///
  /// In en, this message translates to:
  /// **'That has already been done, or something changed while you were working.'**
  String get failureConflict;

  /// No description provided for @failureRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get failureRateLimited;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong at Taytay LGU\'s end. This is not your fault.'**
  String get failureServer;

  /// No description provided for @failureContract.
  ///
  /// In en, this message translates to:
  /// **'This version of the app could not understand Taytay LGU\'s answer.'**
  String get failureContract;

  /// No description provided for @failureUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureUnexpected;

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

  /// Banner heading above any upload refusal.
  ///
  /// In en, this message translates to:
  /// **'That file cannot be sent'**
  String get uploadRefusedTitle;

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
