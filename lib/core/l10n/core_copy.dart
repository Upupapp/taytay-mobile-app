import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../assets/asset_manifest.dart';
import '../design/brand_assets.dart';
import '../router/deep_link.dart';
import '../time/manila_time.dart';

// Resident-facing copy for values that live in `core/` with no
// `BuildContext`: a refused link, the seal's and the welcome photos' spoken
// names, and Manila dates in the reader's language (D-237).
//
// Each value keeps its English in `core/` as the no-context fallback, the
// arrangement `AppFailure.residentMessage` uses; a screen comes through here.

/// Why a link could not be opened. Mirrors [DeepLinkRejection.residentMessage]:
/// the first three reasons share one sentence on purpose (the app is not an
/// oracle for what exists), so they share one key.
String deepLinkRejectionMessage(
  BuildContext context,
  DeepLinkRejection rejection,
) {
  final strings = AppStrings.of(context);
  return switch (rejection) {
    DeepLinkRejection.unknownTarget ||
    DeepLinkRejection.invalidIdentifier ||
    DeepLinkRejection.wrongArity => strings.coreDeepLinkUnavailable,
    DeepLinkRejection.actionNotPermitted => strings.coreDeepLinkActionRefused,
  };
}

/// What a screen reader says for official artwork. Mirrors
/// [BrandAsset.semanticLabel]; an asset this does not name keeps its English.
String brandAssetSemanticLabel(AppStrings strings, BrandAsset asset) =>
    asset.key == BrandAssets.municipalSeal.key
    ? strings.coreSealSemanticLabel
    : asset.semanticLabel;

/// What a screen reader says for an asset in the manifest, by its key.
///
/// Only the assets a screen renders with their manifest label are named: the
/// seal and the three welcome photos. Any other key keeps the manifest's
/// English, which `AssetPolicy` checks for its `Photo:` / `Icon:` prefixes and
/// which is therefore also a developer's record, not only copy.
String assetSemanticLabel(AppStrings strings, String key) => switch (key) {
  'taytay_seal' => strings.coreSealSemanticLabel,
  'municipal_hall' => strings.corePhotoMunicipalHall,
  'tiangge' => strings.corePhotoTiangge,
  'parish_church' => strings.corePhotoParishChurch,
  _ => AppAssets.byKey(key)?.semanticLabel ?? '',
};

/// The reader's language, as `ManilaTime` takes it.
String _language(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// [ManilaTime.formatDate] with the month named in the reader's language:
/// `05 Aug 2026`, or `05 Ago 2026` in Filipino. The order of day, month and
/// year is the same in both, so the two can never name different days.
String manilaDate(BuildContext context, DateTime instant) =>
    ManilaTime.formatDate(instant, languageCode: _language(context));

/// [ManilaTime.formatDateWithWeekday] in the reader's language.
String manilaDateWithWeekday(BuildContext context, DateTime instant) =>
    ManilaTime.formatDateWithWeekday(instant, languageCode: _language(context));

/// [ManilaTime.formatDateTime] in the reader's language. `PHT`, `AM` and `PM`
/// read the same in both.
String manilaDateTime(BuildContext context, DateTime instant) =>
    ManilaTime.formatDateTime(instant, languageCode: _language(context));

/// [ManilaTime.formatRange] in the reader's language.
String manilaRange(BuildContext context, DateTime start, DateTime? end) =>
    ManilaTime.formatRange(start, end, languageCode: _language(context));
