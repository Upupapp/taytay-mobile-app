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
