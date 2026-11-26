import '../../l10n/app_localizations.dart';

/// A bundled photograph's caption in the phone's language.
///
/// [assetKey] and [title] are a `PhotoCredit`'s own. The caption is what a
/// resident reads about the picture, so it is translated; the author and the
/// licence (`PhotoCredit.byline`) are a credit and stay exactly as the licence
/// asks. A caption that is a place's own name ("Taytay Tiangge", "Rizal
/// Avenue, Taytay") is the same in both languages and falls through to
/// [title], as does a photograph added to the manifest before its caption is
/// translated.
String photoCreditTitle(
  AppStrings strings, {
  required String assetKey,
  required String title,
}) => switch (assetKey) {
  'mswdo_relief' => strings.acctPhotoReliefDistribution,
  'municipal_hall' => strings.acctPhotoMunicipalHall,
  'parish_church' => strings.acctPhotoParishChurch,
  'peso_notes' => strings.acctPhotoPesoNotes,
  'muzon_street' => strings.acctPhotoMuzonStreet,
  'sari_sari' => strings.acctPhotoSariSari,
  'rescuers' => strings.acctPhotoRescuers,
  'rescue_vehicle' => strings.acctPhotoRescueVehicle,
  'skills_training' => strings.acctPhotoSkillsTraining,
  'sk_council' => strings.acctPhotoSkCouncil,
  'sk_court' => strings.acctPhotoSkCourt,
  'health_centre' => strings.acctPhotoHealthCentre,
  'vaccination' => strings.acctPhotoVaccination,
  _ => title,
};
