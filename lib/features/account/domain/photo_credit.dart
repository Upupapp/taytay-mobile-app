import 'package:flutter/foundation.dart';

/// One bundled photograph and the credit a resident can read.
///
/// The list is the asset manifest, not a server field. The API publishes no
/// photo-credit body. Authors and licences are the ones recorded in
/// `docs/frontend/PHOTO_CREDITS.md`.
@immutable
class PhotoCredit {
  const PhotoCredit({
    required this.assetKey,
    required this.title,
    required this.author,
    required this.licence,
    this.offices = const <String>[],
    this.welcome = false,
    this.replace = false,
  });

  /// Manifest key. The credits test fails if a photograph is missing.
  final String assetKey;

  final String title;
  final String author;
  final String licence;

  /// Offices that use the file as a banner. Empty for a welcome-only photo.
  final List<String> offices;

  /// Shown on the about screen's three welcome rows.
  final bool welcome;

  /// The design's Replace chip: a photo of people, kept until the LGU
  /// supplies a consented one.
  final bool replace;

  bool get officeBanner => offices.isNotEmpty;

  String get byline => '$author · $licence';
}

/// Every photograph this app ships, in the order the credits screens use.
abstract final class PhotoCredits {
  static const List<PhotoCredit> all = <PhotoCredit>[
    PhotoCredit(
      assetKey: 'mswdo_relief',
      title: 'DSWD relief distribution (2026 earthquake)',
      author: 'Presidential Communications Office',
      licence: 'Public domain (PH gov)',
      offices: <String>['MSWDO'],
      replace: true,
    ),
    PhotoCredit(
      assetKey: 'municipal_hall',
      title: 'Taytay Municipal Hall',
      author: 'Ramon FVelasquez',
      licence: 'CC BY-SA 3.0',
      welcome: true,
      offices: <String>['MSWDO', 'TREASURY', 'PESO', 'PIO'],
    ),
    PhotoCredit(
      assetKey: 'tiangge',
      title: 'Taytay Tiangge',
      author: 'Ralff Nestor Nacor',
      licence: 'CC BY-SA 4.0',
      welcome: true,
    ),
    PhotoCredit(
      assetKey: 'parish_church',
      title: 'St. John the Baptist Parish Church',
      author: 'Urbanroamer',
      licence: 'CC BY-SA 3.0',
      welcome: true,
    ),
    PhotoCredit(
      assetKey: 'peso_notes',
      title: 'Philippine peso notes and coins',
      author: 'Tupungato',
      licence: 'CC BY 3.0',
      offices: <String>['TREASURY'],
    ),
    PhotoCredit(
      assetKey: 'muzon_street',
      title: 'Street in Muzon, Taytay',
      author: 'Judgefloro',
      licence: 'CC0',
      offices: <String>['ASSESSOR'],
    ),
    PhotoCredit(
      assetKey: 'rizal_avenue',
      title: 'Rizal Avenue, Taytay',
      author: 'Ralff Nestor Nacor',
      licence: 'CC BY-SA 4.0',
      offices: <String>['ASSESSOR', 'PIO'],
    ),
    PhotoCredit(
      assetKey: 'tiangge_lane',
      title: 'Taytay Capital Tiangge',
      author: 'Ralff Nestor Nacor',
      licence: 'CC BY-SA 4.0',
      offices: <String>['BPLO'],
    ),
    PhotoCredit(
      assetKey: 'sari_sari',
      title: 'Sari-sari store, Manila',
      author: 'Sayubis',
      licence: 'CC BY-SA 4.0',
      offices: <String>['BPLO'],
    ),
    PhotoCredit(
      assetKey: 'rescuers',
      title: 'BFP rescuers, Angeles City',
      author: 'Angeles City Information Office',
      licence: 'Public domain (PH gov)',
      offices: <String>['MDRRMO'],
      replace: true,
    ),
    PhotoCredit(
      assetKey: 'rescue_vehicle',
      title: 'Rescue vehicle, Bula',
      author: 'FroyAgta',
      licence: 'CC BY-SA 4.0',
      offices: <String>['MDRRMO'],
    ),
    PhotoCredit(
      assetKey: 'skills_training',
      title: 'TESDA skills training',
      author: 'Presidential Communications Office',
      licence: 'Public domain (PH gov)',
      offices: <String>['PESO'],
      replace: true,
    ),
    PhotoCredit(
      assetKey: 'sk_council',
      title: 'Sangguniang Kabataan council',
      author: 'Halimawsabanga',
      licence: 'CC BY-SA 4.0',
      offices: <String>['TYDO'],
      replace: true,
    ),
    PhotoCredit(
      assetKey: 'sk_court',
      title: 'A youth sports court',
      author: 'Iloilo Wanderer',
      licence: 'CC BY-SA 3.0',
      offices: <String>['TYDO'],
    ),
    PhotoCredit(
      assetKey: 'health_centre',
      title: 'Barangay health center, Bula',
      author: 'FroyAgta',
      licence: 'CC BY-SA 4.0',
      offices: <String>['HEALTH'],
    ),
    PhotoCredit(
      assetKey: 'vaccination',
      title: 'Vaccination',
      author: 'Province of Camarines Sur',
      licence: 'Public domain (PH gov)',
      offices: <String>['HEALTH'],
      replace: true,
    ),
  ];

  static List<PhotoCredit> get welcome =>
      all.where((PhotoCredit credit) => credit.welcome).toList(growable: false);

  static List<PhotoCredit> get officeBanners => all
      .where((PhotoCredit credit) => credit.officeBanner)
      .toList(growable: false);

  /// The about screen's sentence. The design counts the office banners.
  static String get officeBannerSummary =>
      '${officeBanners.length} photos · Wikimedia Commons';
}
