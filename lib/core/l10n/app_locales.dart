import 'package:flutter/widgets.dart';

import '../../features/auth/domain/sign_in_challenge.dart';
import '../../features/profile/domain/profile_fields.dart';
import '../../features/verification/domain/correctable_field.dart';
import '../../features/verification/domain/kyc_claim.dart';
import '../../features/verification/domain/verification_status_detail.dart';
import '../../l10n/app_localizations.dart';
import '../documents/document_capture.dart';
import '../documents/upload_policy.dart';
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
/// The resident-facing copy for a sign-in outcome, in the device's language.
///
/// Sign-in is where the largest number of residents meet this app, including
/// those who cannot use it in English at all — so it is localised here rather
/// than waiting for the general sweep in TAB 19.
///
/// [SignInMessage.text] stays as the English default for callers with no
/// `BuildContext`, the same arrangement as [AppFailure.residentMessage].
String localisedSignInMessage(BuildContext context, SignInMessage message) {
  final strings = AppStrings.of(context);
  return switch (message) {
    SignInMessage.codeSent => strings.signInCodeSent,
    SignInMessage.codeNotAccepted => strings.signInCodeNotAccepted,
    SignInMessage.tooManyAttempts => strings.signInTooManyAttempts,
    SignInMessage.offline => strings.signInOffline,
    SignInMessage.timedOut => strings.signInTimedOut,
    SignInMessage.serviceUnavailable => strings.signInServiceUnavailable,
    SignInMessage.unexpected => strings.signInUnexpected,
  };
}

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

/// The refusal a resident reads when a file cannot be sent, with real figures.
///
/// TAB 01. Two numbers appear and they are rounded in opposite directions on
/// purpose: the **file** rounds up and the **limit** rounds down, so the
/// sentence can never read as "that file is 10 MB and the limit is 10 MB". A
/// refusal that looks like it should have succeeded is one a resident retries
/// unchanged.
///
/// The limit is whatever the server published on this response — never a
/// constant in this repository. See [UploadPolicy].
String localisedDocumentRejection(
  BuildContext context,
  DocumentRejection rejection, {
  required int actualBytes,
  required UploadPolicy policy,
}) {
  final strings = AppStrings.of(context);

  return switch (rejection) {
    DocumentRejection.empty => strings.uploadRefusedEmpty,
    DocumentRejection.tooLarge => strings.uploadRefusedTooLarge(
      // Rounded up, and never below 1: a 400 KB file refused by a 0 MB policy
      // would otherwise read as "that file is 0 MB".
      (actualBytes / (1024 * 1024)).ceil().clamp(1, 1 << 30),
      policy.maxMegabytes,
    ),
    DocumentRejection.unsupportedType => strings.uploadRefusedType,
    DocumentRejection.contentsDoNotMatchType => strings.uploadRefusedUnreadable,
  };
}

/// The resident-facing name of a correctable profile field.
///
/// The server's own names — `purok_or_sitio`, `birth_date` — are operator-facing
/// and a resident has never seen them. Mapped here rather than on the enum so
/// that [CorrectableField] stays a statement about the contract and carries no
/// presentation.
String correctableFieldLabel(BuildContext context, CorrectableField field) {
  final strings = AppStrings.of(context);
  return switch (field) {
    CorrectableField.firstName => strings.fieldFirstName,
    CorrectableField.middleName => strings.fieldMiddleName,
    CorrectableField.lastName => strings.fieldLastName,
    CorrectableField.suffix => strings.fieldSuffix,
    CorrectableField.birthDate => strings.fieldBirthDate,
    CorrectableField.sex => strings.fieldSex,
    CorrectableField.civilStatus => strings.fieldCivilStatus,
    CorrectableField.barangayId => strings.fieldBarangay,
    CorrectableField.streetAddress => strings.fieldStreetAddress,
    CorrectableField.purokOrSitio => strings.fieldPurokOrSitio,
    CorrectableField.mobileNumber => strings.fieldMobileNumber,
    CorrectableField.email => strings.fieldEmail,
  };
}

/// The resident-facing name of a profile field, in the device's language.
///
/// ## Why these are not on the enum
///
/// `ResidentProfileField` carries an English `label` and `hint` as enum
/// constants, and until this was written the profile screen rendered them
/// directly — so the one surface where a resident reads their own government
/// record did not translate, while the rest of the app did. In a municipality
/// where Filipino is the language the service is actually for, that is not a
/// polish item.
///
/// The enum keeps its English as the no-context fallback, the same arrangement
/// [AppFailure.residentMessage] uses: a log line or a test has something to
/// print, and every surface a resident reads takes this door instead.
String profileFieldLabel(BuildContext context, ResidentProfileField field) {
  final strings = AppStrings.of(context);
  return switch (field) {
    ResidentProfileField.mobileNumber => strings.profileFieldMobileNumber,
    ResidentProfileField.emailAddress => strings.profileFieldEmailAddress,
    ResidentProfileField.streetAddress => strings.profileFieldStreetAddress,
    ResidentProfileField.purokOrSitio => strings.profileFieldPurokOrSitio,
    ResidentProfileField.fullName => strings.profileFieldFullName,
    ResidentProfileField.birthDate => strings.profileFieldBirthDate,
    ResidentProfileField.sex => strings.profileFieldSex,
    ResidentProfileField.civilStatus => strings.profileFieldCivilStatus,
    ResidentProfileField.barangay => strings.profileFieldBarangay,
  };
}

/// The explanatory line under a profile field, or null where there is none.
String? profileFieldHint(BuildContext context, ResidentProfileField field) {
  final strings = AppStrings.of(context);
  return switch (field) {
    ResidentProfileField.mobileNumber => strings.profileHintMobileNumber,
    ResidentProfileField.emailAddress => strings.profileHintEmailAddress,
    ResidentProfileField.streetAddress => strings.profileHintStreetAddress,
    ResidentProfileField.purokOrSitio => strings.profileHintPurokOrSitio,
    ResidentProfileField.fullName => strings.profileHintFullName,
    ResidentProfileField.birthDate => strings.profileHintBirthDate,
    ResidentProfileField.barangay => strings.profileHintBarangay,
    // Sex and civil status carry no hint: the label is the whole of it, and an
    // invented sentence beneath a two-word field is noise a screen reader also
    // has to read out.
    ResidentProfileField.sex ||
    ResidentProfileField.civilStatus => null,
  };
}

/// The heading and explanation for an ownership group.
({String title, String explanation}) profileSectionCopy(
  BuildContext context,
  FieldOwnership ownership,
) {
  final strings = AppStrings.of(context);
  return switch (ownership) {
    FieldOwnership.accountOwned => (
      title: strings.profileSectionAccountTitle,
      explanation: strings.profileSectionAccountExplanation,
    ),
    FieldOwnership.lguVerified => (
      title: strings.profileSectionLguTitle,
      explanation: strings.profileSectionLguExplanation,
    ),
  };
}

/// Where a resident's verification stands, in their language.
///
/// The stage label is the **headline of the verification screen** — the single
/// most consequential sentence this app renders, because it is how somebody
/// learns whether they can hold a digital ID. It was English for everybody until
/// this existed.
({String label, String explanation}) verificationStageCopy(
  BuildContext context,
  ResidentVerificationStage stage,
) {
  final strings = AppStrings.of(context);
  return switch (stage) {
    ResidentVerificationStage.notStarted => (
      label: strings.verifyStageNotStartedLabel,
      explanation: strings.verifyStageNotStartedBody,
    ),
    ResidentVerificationStage.inProgress => (
      label: strings.verifyStageInProgressLabel,
      explanation: strings.verifyStageInProgressBody,
    ),
    ResidentVerificationStage.pendingReview => (
      label: strings.verifyStagePendingLabel,
      explanation: strings.verifyStagePendingBody,
    ),
    ResidentVerificationStage.needsMoreInformation => (
      label: strings.verifyStageNeedsInfoLabel,
      explanation: strings.verifyStageNeedsInfoBody,
    ),
    ResidentVerificationStage.verified => (
      label: strings.verifyStageVerifiedLabel,
      explanation: strings.verifyStageVerifiedBody,
    ),
    ResidentVerificationStage.unsuccessful => (
      label: strings.verifyStageUnsuccessfulLabel,
      explanation: strings.verifyStageUnsuccessfulBody,
    ),
    ResidentVerificationStage.manualReview => (
      label: strings.verifyStageManualReviewLabel,
      explanation: strings.verifyStageManualReviewBody,
    ),
  };
}

/// What a KYC document slot is called, and what counts as one.
({String label, String description}) kycDocumentCopy(
  BuildContext context,
  KycDocumentType type,
) {
  final strings = AppStrings.of(context);
  return switch (type) {
    KycDocumentType.identityDocument => (
      label: strings.kycDocIdentityLabel,
      description: strings.kycDocIdentityBody,
    ),
    KycDocumentType.proofOfAddress => (
      label: strings.kycDocAddressLabel,
      description: strings.kycDocAddressBody,
    ),
  };
}

