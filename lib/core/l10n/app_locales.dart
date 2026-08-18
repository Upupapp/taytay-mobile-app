import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../result/app_failure.dart';

/// The languages this app speaks, and the rule for choosing between them.
///
/// ---
///
/// ## Why Filipino is not optional
///
/// A municipal service in Taytay that only speaks English is a service a large
/// part of the population cannot use — and the people most likely to need
/// social-welfare assistance are not the ones most likely to read government
/// English. So Filipino is a first-class locale here rather than a later
/// feature, and both `.arb` files are kept complete.
///
/// English is the **template** because the backend contract, the design system
/// and every reviewer of this repository work in it. That is a tooling
/// decision, not a statement about which language matters.
///
/// ## The app never picks a language
///
/// There is no in-app language switcher and [resolve] takes the device's own
/// preference. A resident who has told their phone they read Filipino has
/// already answered the question, and an app that asks again — or that
/// remembers a different answer — is one where the two settings disagree and
/// the resident cannot tell which one is winning.
///
/// The one thing this class does decide is the **fallback**: an unsupported
/// device locale resolves to English rather than to whatever happens to be
/// first in the list.
abstract final class AppLocales {
  /// English. The template, and the fallback.
  static const Locale english = Locale('en');

  /// Filipino. `fil` rather than `tl`: `fil` is the ISO 639-2 code for the
  /// national language as the Constitution names it, and it is what Android
  /// and iOS both emit for the Philippines' own language setting.
  static const Locale filipino = Locale('fil');

  static const List<Locale> supported = <Locale>[english, filipino];

  /// Resolves the device's preference against what this app speaks.
  ///
  /// Matches on the **language** subtag, so a device set to `fil_PH`,
  /// `fil_PH_#Latn` or plain `fil` all resolve to Filipino rather than falling
  /// through to English on a region mismatch.
  static Locale resolve(Locale? device, Iterable<Locale> supportedLocales) {
    if (device == null) return english;
    for (final locale in supportedLocales) {
      if (locale.languageCode == device.languageCode) return locale;
    }
    return english;
  }
}

/// Resident-facing copy for a failure, in the reader's language.
///
/// ---
///
/// **Chosen by the failure's kind, never taken from the server.** That rule is
/// Article 5.5 and it survives localisation intact: the server's `message` is
/// operator-facing, written once in one language, and would arrive untranslated
/// in front of a Filipino-reading resident even if it were safe to show — which
/// it is not.
///
/// [AppFailure.residentMessage] stays as the English default for the places
/// that have no `BuildContext` — a log line, a controller under test, a value
/// captured before a widget exists. This is the widget-side door, and every
/// surface a resident actually reads should take it.
String localisedResidentMessage(BuildContext context, AppFailure failure) {
  final strings = AppStrings.of(context);
  return switch (failure) {
    NetworkFailure() => strings.failureNetwork,
    TimeoutFailure() => strings.failureTimeout,
    UnauthenticatedFailure() => strings.failureUnauthenticated,
    ForbiddenFailure() => strings.failureForbidden,
    NotFoundFailure() => strings.failureNotFound,
    ValidationFailure() => strings.failureValidation,
    UnacceptableUploadFailure(isTooLarge: final tooLarge) =>
      tooLarge ? strings.failureFileTooLarge : strings.failureFileType,
    ConflictFailure() => strings.failureConflict,
    RateLimitedFailure() => strings.failureRateLimited,
    ServerFailure() => strings.failureServer,
    ContractFailure() => strings.failureContract,
    UnexpectedFailure() => strings.failureUnexpected,
  };
}
