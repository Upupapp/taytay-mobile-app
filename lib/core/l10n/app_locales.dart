import 'package:flutter/widgets.dart';

import '../../features/auth/domain/sign_in_challenge.dart';
import '../../features/household/domain/household_summary.dart';
import '../../features/news/domain/post_interaction.dart';
import '../../features/notifications/domain/notification_repository.dart';
import '../../features/profile/domain/profile_fields.dart';
import '../../features/services/domain/lgu_service.dart';
import '../../features/verification/domain/correctable_field.dart';
import '../../features/verification/domain/kyc_claim.dart';
import '../../features/verification/domain/verification_status_detail.dart';
import '../../l10n/app_localizations.dart';
import '../documents/document_capture.dart';
import '../documents/upload_policy.dart';
import '../forms/field_error.dart';
import '../forms/validation_message.dart';
import '../intent/resident_intent.dart';
import '../result/app_failure.dart';
import '../session/resident_capability.dart';

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
/// [actualBytes] is nullable because the screen does not always have it.
///
/// It used to be required, and `requirements_screen.dart` handled that by
/// rendering the RAW ENGLISH `rejection.residentMessage` whenever the size was
/// unknown and the localiser otherwise — so the same banner appeared in
/// Filipino or English depending on whether a size had been captured. Making
/// the parameter honest is what removes the branch: there is no longer a case
/// the localiser cannot answer, so no reason for a caller to go around it.
String localisedDocumentRejection(
  BuildContext context,
  DocumentRejection rejection, {
  required int? actualBytes,
  required UploadPolicy policy,
}) {
  final strings = AppStrings.of(context);

  return switch (rejection) {
    DocumentRejection.empty => strings.uploadRefusedEmpty,
    DocumentRejection.tooLarge when actualBytes == null =>
      // The limit is still worth stating; the file's own size is not knowable
      // here, and inventing a number would be worse than omitting one.
      strings.uploadRefusedTooLargeUnknown(policy.maxMegabytes),
    DocumentRejection.tooLarge => strings.uploadRefusedTooLarge(
      // Rounded up, and never below 1: a 400 KB file refused by a 0 MB policy
      // would otherwise read as "that file is 0 MB".
      (actualBytes! / (1024 * 1024)).ceil().clamp(1, 1 << 30),
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
    ResidentProfileField.sex || ResidentProfileField.civilStatus => null,
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

/// The words for a validation error, in the reader's language.
///
/// **Only for errors this app composed.** A [FieldError] with a null
/// [FieldError.kind] came from the server, and its text is shown exactly as
/// sent — the deliberate exception in Article 5.5, because only the server knows
/// what was wrong with a particular value.
///
/// [FieldError.message] stays as the English fallback for the places with no
/// `BuildContext`, and for the server's own text.
String localisedFieldError(BuildContext context, FieldError error) {
  final ValidationMessage? kind = error.kind;
  if (kind == null) return error.message;

  final strings = AppStrings.of(context);
  final String subject = error.subject ?? '';
  final int limit = error.limit ?? 0;

  return switch (kind) {
    ValidationMessage.confirmDetails => strings.validateConfirmDetails,
    ValidationMessage.narrativeMissing => strings.validateNarrativeMissing,
    ValidationMessage.narrativeTooLong => strings.validateNarrativeTooLong(
      limit,
    ),
    ValidationMessage.consentRequired => strings.validateConsentRequired(
      subject,
    ),
    ValidationMessage.consentRequiredToRegister =>
      strings.validateConsentRequiredToRegister(subject),
    ValidationMessage.answerMissingChoice =>
      strings.validateAnswerMissingChoice(subject),
    ValidationMessage.answerMissingYesNo => strings.validateAnswerMissingYesNo(
      subject,
    ),
    ValidationMessage.answerMissingDate => strings.validateAnswerMissingDate(
      subject,
    ),
    ValidationMessage.answerMissingNumber =>
      strings.validateAnswerMissingNumber(subject),
    ValidationMessage.answerMissingGeneric =>
      strings.validateAnswerMissingGeneric(subject),
    ValidationMessage.answerNotANumber => strings.validateAnswerNotANumber(
      subject,
    ),
    ValidationMessage.answerTooLong => strings.validateAnswerTooLong(limit),
  };
}

/// The heading a resident reads on a gate that names what they cannot yet do.
///
/// ## How this was found, and why the entry that hid it is worth remembering
///
/// `ResidentCapability` sat in the `notResidentFacing` list of
/// `test/core/resident_copy_localisation_test.dart` under the claim that its
/// label "names a capability for the gate sheet to look up; the sentence a
/// resident reads is composed there". That was wrong.
/// `capability_gate.dart:111` passes `capability.label` straight into
/// `StatusView(title:)`, which renders it at `titleMedium` — and `CapabilityGate`
/// is mounted on **twelve** screens. So the largest heading on every gated
/// screen in the app was English on a Filipino device, and the guard written to
/// catch exactly this was asserting it could not happen.
///
/// That claim was written by reading the code rather than following the value,
/// which is the same mistake that put `ConsentKind` on the wrong list. Reading
/// tells you what a name suggests; only tracing tells you where a string lands.
String capabilityLabel(BuildContext context, ResidentCapability capability) {
  final strings = AppStrings.of(context);
  return switch (capability) {
    ResidentCapability.browseServices => strings.capabilityBrowseServices,
    ResidentCapability.readNews => strings.capabilityReadNews,
    ResidentCapability.browseEvents => strings.capabilityBrowseEvents,
    ResidentCapability.manageAccount => strings.capabilityManageAccount,
    ResidentCapability.manageSecurity => strings.capabilityManageSecurity,
    ResidentCapability.readNotifications => strings.capabilityReadNotifications,
    ResidentCapability.browsePrograms => strings.capabilityBrowsePrograms,
    ResidentCapability.completeVerification =>
      strings.capabilityCompleteVerification,
    ResidentCapability.holdDigitalId => strings.capabilityHoldDigitalId,
    ResidentCapability.trackAssistanceRequests =>
      strings.capabilityTrackAssistanceRequests,
    ResidentCapability.applyForAssistance =>
      strings.capabilityApplyForAssistance,
    ResidentCapability.submitRequirements =>
      strings.capabilitySubmitRequirements,
    ResidentCapability.viewHouseholdSummary =>
      strings.capabilityViewHouseholdSummary,
  };
}

/// The sign-in gate's message, as a whole sentence rather than a fragment.
///
/// ## Why the fragment had to go
///
/// `access_gate_sheet.dart` built this sentence by interpolation:
/// `'You need a Taytay LGU account to ${intent.description}.'`, where
/// `description` is a lower-case English verb phrase like `like this post`.
/// `ResidentIntentKind` was recorded as never rendered on the strength of a
/// comment calling the field diagnostic. It is rendered, mid-sentence, on both
/// gate sheets.
///
/// Translating the fragment alone would not have fixed it. Filipino needs a
/// different verb form after `para` than after `bago ka`, so one fragment
/// cannot serve both sentences: `mag-apply` in the first, `makapag-apply` in
/// the second. Substituting a fragment into a sentence is a bug in any language
/// whose morphology depends on the frame — so the frame moves into the `.arb`
/// with the fragment inside it, and translators see a whole sentence.
///
/// The trailing sentence is separate because it genuinely does not vary, and
/// two independent sentences concatenate safely where two clauses do not.
String gateSignInMessage(BuildContext context, ResidentIntentKind intent) {
  final strings = AppStrings.of(context);
  final String lead = switch (intent) {
    ResidentIntentKind.likePost => strings.gateSignInLikePost,
    ResidentIntentKind.commentOnPost => strings.gateSignInCommentOnPost,
    ResidentIntentKind.registerForEvent => strings.gateSignInRegisterForEvent,
    ResidentIntentKind.saveService => strings.gateSignInSaveService,
    ResidentIntentKind.manageNotifications =>
      strings.gateSignInManageNotifications,
    ResidentIntentKind.applyForService => strings.gateSignInApplyForService,
    ResidentIntentKind.viewDigitalId => strings.gateSignInViewDigitalId,
  };
  return '$lead ${strings.gateSignInTrailer}';
}

/// The verification gate's message. See [gateSignInMessage] for why this is a
/// whole sentence and not a frame plus a fragment.
String gateVerificationMessage(
  BuildContext context,
  ResidentIntentKind intent,
) {
  final strings = AppStrings.of(context);
  final String lead = switch (intent) {
    ResidentIntentKind.likePost => strings.gateVerifyLikePost,
    ResidentIntentKind.commentOnPost => strings.gateVerifyCommentOnPost,
    ResidentIntentKind.registerForEvent => strings.gateVerifyRegisterForEvent,
    ResidentIntentKind.saveService => strings.gateVerifySaveService,
    ResidentIntentKind.manageNotifications =>
      strings.gateVerifyManageNotifications,
    ResidentIntentKind.applyForService => strings.gateVerifyApplyForService,
    ResidentIntentKind.viewDigitalId => strings.gateVerifyViewDigitalId,
  };
  return '$lead ${strings.gateVerifyTrailer}';
}

/// The label on an upload button — camera, gallery or file.
///
/// `DocumentSource` was recorded as "rendered through the picker sheet, which
/// composes its own copy". The picker sheet composes nothing:
/// `requirements_screen.dart:478` passes `source.label` to `AppButton(label:)`.
/// The enum's own doc comment says `Resident-facing action label` one line above
/// the field, so the claim contradicted the source it was written about.
String documentSourceLabel(BuildContext context, DocumentSource source) {
  final strings = AppStrings.of(context);
  return switch (source) {
    DocumentSource.camera => strings.documentSourceCamera,
    DocumentSource.gallery => strings.documentSourceGallery,
    DocumentSource.file => strings.documentSourceFile,
  };
}

/// Why a capability is locked, in the resident's language.
///
/// `CapabilityService.explain` keeps its English as the no-context fallback —
/// the same arrangement [AppFailure.residentMessage] uses — and every surface a
/// resident reads comes through here instead. It renders in two places that
/// must not diverge: the locked view inside a route, and the gate sheet.
String capabilityExplanation(BuildContext context, CapabilityVerdict verdict) {
  final strings = AppStrings.of(context);
  return switch (verdict) {
    CapabilityUsable() => '',
    CapabilityPending() => strings.capabilityExplainPending,
    CapabilityNeedsSignIn() => strings.capabilityExplainNeedsSignIn,
    CapabilityNeedsVerification() => strings.capabilityExplainNeedsVerification,
    CapabilityNotYetAvailable() => strings.capabilityExplainNotYetAvailable,
  };
}

/// The short badge on a locked tile — what is missing, in two or three words.
///
/// Null where nothing is missing, matching `CapabilityService.requirementLabel`.
String? capabilityRequirementLabel(
  BuildContext context,
  CapabilityVerdict verdict,
) {
  final strings = AppStrings.of(context);
  return switch (verdict) {
    CapabilityUsable() || CapabilityPending() => null,
    CapabilityNeedsSignIn() => strings.capabilityRequirementSignIn,
    CapabilityNeedsVerification() => strings.capabilityRequirementVerification,
    CapabilityNotYetAvailable() => strings.capabilityRequirementNotAvailable,
  };
}

/// The one thing to do next, on the locked view's primary button.
String capabilityActionLabel(BuildContext context, CapabilityVerdict verdict) {
  final strings = AppStrings.of(context);
  return switch (verdict) {
    CapabilityNeedsSignIn() => strings.gateActionSignIn,
    CapabilityNeedsVerification() => strings.gateActionVerify,
    CapabilityNotYetAvailable() => strings.gateActionSeeAvailable,
    _ => strings.gateActionContinue,
  };
}

/// The button on the verification card, or null where there is nothing to press.
///
/// Mirrors `ResidentVerificationStage.nextActionLabel`, which stays as the
/// no-context fallback. Added 2026-08-29 after a render-site scan found the raw
/// getter rendering on two screens: `nextActionLabel` was not in the coverage
/// guard's list of copy-bearing field names, so no guard was looking at it.
String? verificationStageActionLabel(
  BuildContext context,
  ResidentVerificationStage stage,
) {
  final strings = AppStrings.of(context);
  return switch (stage) {
    ResidentVerificationStage.notStarted => strings.verifyActionStart,
    ResidentVerificationStage.inProgress => strings.verifyActionContinue,
    ResidentVerificationStage.needsMoreInformation =>
      strings.verifyActionFixResend,
    ResidentVerificationStage.unsuccessful => strings.verifyActionTryAgain,
    ResidentVerificationStage.pendingReview => null,
    ResidentVerificationStage.verified => null,
    ResidentVerificationStage.manualReview => null,
  };
}

/// What a resident says is wrong with their household record.
({String label, String description}) householdCorrectionCopy(
  BuildContext context,
  HouseholdCorrectionKind kind,
) {
  final strings = AppStrings.of(context);
  return switch (kind) {
    HouseholdCorrectionKind.addressWrong => (
      label: strings.householdFixAddressLabel,
      description: strings.householdFixAddressBody,
    ),
    HouseholdCorrectionKind.roleWrong => (
      label: strings.householdFixRoleLabel,
      description: strings.householdFixRoleBody,
    ),
    HouseholdCorrectionKind.sizeWrong => (
      label: strings.householdFixSizeLabel,
      description: strings.householdFixSizeBody,
    ),
    HouseholdCorrectionKind.notMyHousehold => (
      label: strings.householdFixNotMineLabel,
      description: strings.householdFixNotMineBody,
    ),
    HouseholdCorrectionKind.somethingElse => (
      label: strings.householdFixOtherLabel,
      description: strings.householdFixOtherBody,
    ),
  };
}

/// Head or member, as the resident's own household card names it.
String householdRoleLabel(BuildContext context, HouseholdRole role) {
  final strings = AppStrings.of(context);
  return switch (role) {
    HouseholdRole.head => strings.householdRoleHead,
    HouseholdRole.member => strings.householdRoleMember,
  };
}

/// Why a resident is reporting a comment.
///
/// The wire value is deliberately untouched: the server's vocabulary and the
/// resident's are different things, and only one of them translates.
({String label, String description}) reportReasonCopy(
  BuildContext context,
  ReportReason reason,
) {
  final strings = AppStrings.of(context);
  return switch (reason) {
    ReportReason.abusive => (
      label: strings.reportAbusiveLabel,
      description: strings.reportAbusiveBody,
    ),
    ReportReason.harassment => (
      label: strings.reportHarassmentLabel,
      description: strings.reportHarassmentBody,
    ),
    ReportReason.falseInformation => (
      label: strings.reportFalseInfoLabel,
      description: strings.reportFalseInfoBody,
    ),
    ReportReason.spam => (
      label: strings.reportSpamLabel,
      description: strings.reportSpamBody,
    ),
    ReportReason.personalInformation => (
      label: strings.reportPersonalInfoLabel,
      description: strings.reportPersonalInfoBody,
    ),
  };
}

/// The kind of message, as the notification inbox groups them.
String notificationCategoryLabel(
  BuildContext context,
  NotificationCategory category,
) {
  final strings = AppStrings.of(context);
  return switch (category) {
    NotificationCategory.verificationUpdate => strings.notifCatVerification,
    NotificationCategory.assistanceStatus => strings.notifCatAssistance,
    NotificationCategory.missingRequirement =>
      strings.notifCatMissingRequirement,
    NotificationCategory.releaseInstruction => strings.notifCatRelease,
    NotificationCategory.referralUpdate => strings.notifCatReferral,
    NotificationCategory.eventRegistration => strings.notifCatEventRegistration,
    NotificationCategory.eventReminder => strings.notifCatEventReminder,
    NotificationCategory.publicAdvisory => strings.notifCatPublicAdvisory,
    NotificationCategory.accountSecurity => strings.notifCatAccountSecurity,
  };
}

/// The name a resident reads for a service category.
///
/// ## The defect this closes
///
/// `services_screen.dart` rendered `service.category.raw` on the category tag
/// and `category.wireValue` on the filter chips — the **backend's own codes**,
/// so residents read `dokumento`, `buwis`, `ids` and `national` where a name
/// belongs. Four of the six happen to be Filipino words, which is why it
/// survived: it looked like copy on a Filipino device and like nothing much on
/// an English one. `ids` and `national` are not words in either language, and a
/// lower-case wire code is not presentation copy in any of them.
///
/// The labels already existed, on `ServiceCategoryIcon` in
/// `shared/illustrations/feature_icons.dart`, and nothing rendered them because
/// nothing mounts `FeatureIcon`. That enum is now icon-only: two sources of
/// truth for the same six names is the thing this codebase forbids, and the one
/// that could not be translated is the one that went.
String serviceCategoryLabel(BuildContext context, ServiceCategory category) {
  final strings = AppStrings.of(context);
  return switch (category) {
    ServiceCategory.dokumento => strings.serviceCategoryDokumento,
    ServiceCategory.buwis => strings.serviceCategoryBuwis,
    ServiceCategory.kalusugan => strings.serviceCategoryKalusugan,
    ServiceCategory.trabaho => strings.serviceCategoryTrabaho,
    ServiceCategory.ids => strings.serviceCategoryIds,
    ServiceCategory.national => strings.serviceCategoryNational,
  };
}

/// What a resident is told after a gate they have just satisfied.
///
/// ## Found by type resolution, not by reading
///
/// `intent_resumer.dart:78` said `'You can now ${intent.kind.description}.'` —
/// an English sentence with an English enum fragment interpolated into it, the
/// same shape as the gate sheets before they were fixed, in a third place
/// nobody had found. The regex guard could not see it: `intent.kind` is a
/// property access whose type is never written down, and guessing types from
/// names is what the guard deliberately refuses to do.
///
/// It took the analyzer, with real type information, to find it. That is the
/// argument for `test/core/typed_render_test.dart` in one line.
String intentResumedMessage(BuildContext context, ResidentIntentKind intent) {
  final strings = AppStrings.of(context);
  return switch (intent) {
    ResidentIntentKind.likePost => strings.intentResumedLikePost,
    ResidentIntentKind.commentOnPost => strings.intentResumedCommentOnPost,
    ResidentIntentKind.registerForEvent =>
      strings.intentResumedRegisterForEvent,
    ResidentIntentKind.saveService => strings.intentResumedSaveService,
    ResidentIntentKind.manageNotifications =>
      strings.intentResumedManageNotifications,
    ResidentIntentKind.applyForService => strings.intentResumedApplyForService,
    ResidentIntentKind.viewDigitalId => strings.intentResumedViewDigitalId,
  };
}
