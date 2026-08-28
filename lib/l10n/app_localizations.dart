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
