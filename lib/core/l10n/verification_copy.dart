import '../../features/verification/domain/verification_status_detail.dart';
import '../../l10n/app_localizations.dart';

/// What the verification status screen calls a kind of submitted information,
/// in the resident's language.
///
/// These are the screen's own short labels (an issue's heading, a line under
/// "What Taytay LGU has from you"), which differ from the enum's `label` on
/// purpose: "ID photo" rather than "Proof of identity". The enum's English
/// stays as the no-context fallback, as [ResidentVerificationStage]'s does.
String verificationItemCategoryLabel(
  AppStrings strings,
  VerificationItemCategory category,
) => switch (category) {
  VerificationItemCategory.personalDetails =>
    strings.verifCategoryPersonalDetails,
  VerificationItemCategory.address => strings.verifAddress,
  VerificationItemCategory.contact => strings.verifCategoryContact,
  VerificationItemCategory.identityDocument => strings.verifCategoryIdPhoto,
  VerificationItemCategory.photo => strings.verifCategoryPhoto,
  VerificationItemCategory.other => strings.verifCategoryOther,
};

/// `VerificationRequest.id_type` in the resident's language.
///
/// Mirrors `idTypeLabel`, which stays as the no-context fallback. Names a
/// resident says the same way in both languages (PhilSys National ID, UMID,
/// Postal ID, Voter's ID, SSS) stay as they are; an unrecognised wire value is
/// shown as the server sent it, as there.
String localisedIdTypeLabel(AppStrings strings, String? wire) {
  final String value = wire?.trim() ?? '';
  if (value.isEmpty) return '';
  return switch (value) {
    'philid' => 'PhilSys National ID',
    'drivers_license' => strings.verifIdTypeDriversLicense,
    'passport' => strings.verifIdTypePassport,
    'umid' => 'UMID',
    'postal' => 'Postal ID',
    'voters' => "Voter's ID",
    'sss' => 'SSS',
    'other' => strings.verifIdTypeOther,
    _ => value,
  };
}

/// The sex the office's record holds, in the resident's language.
///
/// The resident-record repository hands the screen an English word
/// ("Female", "Male", "Unspecified") and reads that same word back when the
/// profile is saved, so the word stays English in the record and is only
/// translated where it is drawn. Anything else is shown as it came.
String localisedSexLabel(AppStrings strings, String label) =>
    switch (label.trim()) {
      'Female' => strings.verifSexFemale,
      'Male' => strings.verifSexMale,
      'Unspecified' => strings.verifSexUnspecified,
      _ => label,
    };
