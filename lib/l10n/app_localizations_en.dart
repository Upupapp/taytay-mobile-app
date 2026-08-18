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
}
