import 'package:flutter/foundation.dart';

/// What an asset is for. Decides where it lives, what it may weigh, and which
/// rules apply to it.
enum AssetKind {
  /// A drawn scene. **Always an illustration, never a photograph** — see
  /// [AssetEntry.semanticLabel] and `illustrationLabelPrefix`.
  illustration('assets/illustrations'),

  /// A wide promotional or informational strip inside a screen.
  banner('assets/banners'),

  /// A small pictogram. Prefer a Material icon over a file: the icon font is
  /// already bundled and tree-shaken to the glyphs actually used.
  icon('assets/icons'),

  /// Stand-in artwork shown where remote content has not loaded — an event
  /// poster, a newsfeed image.
  placeholder('assets/placeholders'),

  /// Official artwork supplied by the LGU. Governed additionally by
  /// `BrandAssets` and `SealIntegrityRules`; never generated, never redrawn.
  officialArtwork('assets/brand'),

  /// A photograph the design ships with a credit. JPEG is allowed only here.
  /// One file, no density copies: the source is already wider than a 3× arch.
  photograph('assets/photos');

  const AssetKind(this.directory);

  /// The one directory this kind may live in. Enforced by
  /// `asset_manifest_test.dart`, so an asset cannot drift into a folder whose
  /// rules do not apply to it.
  final String directory;
}

/// Permitted container formats.
///
/// Flat-colour artwork stays lossless: JPEG carries no alpha, and its ringing
/// is worst on hard edges. A photograph is the exception, and only
/// [AssetKind.photograph] may use [AssetFormat.jpeg].
enum AssetFormat {
  /// Preferred for anything geometric. One file, every density.
  svg('image/svg+xml'),

  /// Lossless raster with alpha. Needs density variants.
  png('image/png'),

  /// Lossless-mode raster with alpha. Smaller than PNG at equal quality.
  webp('image/webp'),

  /// A photograph. Not density-dependent: one source file is downscaled.
  jpeg('image/jpeg');

  const AssetFormat(this.mimeType);

  final String mimeType;

  /// Whether this format needs `2.0x` / `3.0x` variants alongside it.
  bool get isDensityDependent =>
      this != AssetFormat.svg && this != AssetFormat.jpeg;
}

/// How the app came to have the right to ship an asset.
enum AssetLicence {
  /// Created for this project. The default, and the only one that needs no
  /// external permission.
  originalWork,

  /// Supplied by the Municipality of Taytay. Requires a written approval
  /// reference in [AssetEntry.provenance].
  lguSupplied,

  /// Third-party work used under a licence. Requires the licence name and the
  /// attribution text in [AssetEntry.provenance].
  thirdParty,
}

/// One shipped asset file.
///
/// Everything needed to answer "may we ship this, and is it still the file we
/// approved?" lives here rather than in a wiki: the licence basis, where it came
/// from, what it may weigh, and the hash of the bytes that were reviewed.
@immutable
class AssetEntry {
  const AssetEntry({
    required this.key,
    required this.path,
    required this.kind,
    required this.format,
    required this.licence,
    required this.provenance,
    required this.semanticLabel,
    required this.sha256,
    this.maxBytes,
  });

  /// Stable identifier used in code, e.g. `onboarding_services`.
  final String key;

  /// Bundle path. Must sit directly under [AssetKind.directory].
  final String path;

  final AssetKind kind;
  final AssetFormat format;
  final AssetLicence licence;

  /// Where it came from and on what basis it may be shipped.
  ///
  /// For [AssetLicence.originalWork]: who made it and when. For
  /// [AssetLicence.lguSupplied]: the LGU issuance or memorandum reference. For
  /// [AssetLicence.thirdParty]: the licence name and required attribution.
  final String provenance;

  /// Screen-reader description.
  ///
  /// For [AssetKind.illustration] this **must** begin with
  /// [AssetPolicy.illustrationLabelPrefix]: a drawn scene announced as though it
  /// were a photograph misrepresents it to the residents who cannot see it.
  final String semanticLabel;

  /// Lower-case hex SHA-256 of the approved bytes.
  final String sha256;

  /// Overrides the per-kind budget. Use sparingly and say why in [provenance].
  final int? maxBytes;

  /// The budget this entry is held to.
  int get effectiveMaxBytes => maxBytes ?? AssetPolicy.budgetFor(kind);

  @override
  String toString() => 'AssetEntry($key, ${kind.name}, $path)';
}

/// Byte budgets, density rules, precache limits and the naming rules that the
/// manifest tests enforce.
///
/// **Why budgets are a policy and not a guideline.** Install size and first-open
/// data are paid for by the resident, frequently on a prepaid connection metered
/// by the megabyte. An asset that is 400 KB instead of 40 KB is not a quality
/// decision, it is a decision to spend somebody else's money.
abstract final class AssetPolicy {
  /// Every illustration's accessible name starts with this.
  static const String illustrationLabelPrefix = 'Illustration:';

  /// Words that would claim drawn artwork is a photograph. A
  /// [AssetKind.photograph] label is the exception: it must start with "Photo:".
  static const List<String> forbiddenLabelClaims = <String>[
    'photo',
    'photograph',
    'photography',
    'picture of',
    'actual',
    'real footage',
  ];

  /// Per-kind byte budgets for a single density variant.
  static const Map<AssetKind, int> budgets = <AssetKind, int>{
    // A full-width drawn scene. Generous, because it is the largest thing shown.
    AssetKind.illustration: 120 * 1024,
    AssetKind.banner: 80 * 1024,
    // A pictogram this large is a mistake; the budget says so.
    AssetKind.icon: 12 * 1024,
    AssetKind.placeholder: 40 * 1024,
    AssetKind.officialArtwork: 200 * 1024,
    // Three welcome photographs. Each file stays under 1 MB. They are not
    // precached: the largest is well over the 256 KB startup budget.
    AssetKind.photograph: 1024 * 1024,
  };

  static int budgetFor(AssetKind kind) => budgets[kind]!;

  /// Density variants required beside a raster asset.
  ///
  /// Flutter resolves `assets/x/foo.png` to `assets/x/2.0x/foo.png` on a 2x
  /// screen. 1x is the declared path itself. 4x is not shipped: no meaningful
  /// Android or iOS device needs it, and it doubles the bytes for pixels nobody
  /// resolves.
  static const List<String> requiredDensityDirectories = <String>[
    '2.0x',
    '3.0x',
  ];

  /// Total bytes the startup precache allowlist may occupy.
  ///
  /// Precaching blocks nothing but does compete for bandwidth and memory during
  /// the first frames, which is exactly when a cheap device is busiest. Anything
  /// not needed in the first seconds is loaded lazily instead.
  static const int maxPrecacheBytes = 256 * 1024;

  /// Maximum number of precached assets, regardless of size.
  static const int maxPrecacheCount = 6;

  /// `snake_case`, so paths behave identically on case-sensitive CI and
  /// case-insensitive Windows checkouts.
  static final RegExp keyPattern = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');
}

/// Every asset file this build ships.
///
/// Illustrations, scenes and placeholders stay Flutter-painted compositions
/// (`lib/shared/illustrations/`). Raster files are the municipal seal and the
/// three welcome photographs. The seal is never redrawn. The photographs are
/// the design JPEGs, with the credits in `docs/frontend/PHOTO_CREDITS.md`.
abstract final class AppAssets {
  static const List<AssetEntry> all = <AssetEntry>[
    AssetEntry(
      key: 'taytay_seal',
      path: 'assets/brand/taytay_seal.png',
      kind: AssetKind.officialArtwork,
      format: AssetFormat.png,
      licence: AssetLicence.lguSupplied,
      provenance:
          'S0 design source src/taytay_seal.png, the official Municipality '
          'of Taytay seal. Shipped unaltered at 560 px, which is already '
          'sharper than a 3× render of the header mark. The 200 KB kind '
          'budget is overridden because recompressing it would change the '
          'artwork. No density copies: Flutter downscales this one file.',
      semanticLabel: 'Seal of the Municipality of Taytay, Rizal',
      sha256:
          '8541609af1ece1833cc9a03f326603315641bd8f44dc98b442c99545d529de8b',
      maxBytes: 357301,
    ),
    AssetEntry(
      key: 'municipal_hall',
      path: 'assets/photos/municipal_hall.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/1_municipal_hall.jpg. Ramon FVelasquez, '
          'CC BY-SA 3.0. Credit is shown on the welcome scene. Not precached.',
      semanticLabel: 'Photo: Taytay Municipal Hall',
      sha256:
          '97c0e6665a346d4dcc0ee40cdcace2434cb2ba6e04dbb4190e3acc3199bdaaf4',
      maxBytes: 521406,
    ),
    AssetEntry(
      key: 'tiangge',
      path: 'assets/photos/tiangge.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/2_tiangge.jpg. Ralff Nestor Nacor, '
          'CC BY-SA 4.0. Credit is shown on the welcome scene. Not precached.',
      semanticLabel: 'Photo: Taytay Tiangge',
      sha256:
          '158de5b27048b7f21a2069b2b27775437755e69135de4a54073cb4594f56b893',
      maxBytes: 975246,
    ),
    AssetEntry(
      key: 'parish_church',
      path: 'assets/photos/parish_church.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/3_church.jpg. Urbanroamer, CC BY-SA 3.0. '
          'Credit is shown on the welcome scene. Not precached.',
      semanticLabel: 'Photo: St. John the Baptist Parish Church',
      sha256:
          'a3c5512973fc1b88395ec4a777a6f5e8ecedd1c6a8880cc2284be18fa06a64e4',
      maxBytes: 673736,
    ),
    AssetEntry(
      key: 'tiangge_lane',
      path: 'assets/photos/tiangge_lane.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_tiangge2.jpg. Ralff Nestor Nacor, CC BY-SA 4.0. '
          'Credit is shown on the BPLO office page. Not precached.',
      semanticLabel: 'Photo: Taytay tiangge lane',
      sha256:
          'f1c1f88ea8b9f890f87a8c431cb56ce7b34931d1458a626feb2f2fb38fbd0475',
    ),
    AssetEntry(
      key: 'sari_sari',
      path: 'assets/photos/sari_sari.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_sarisari.jpg. Sayubis, CC BY-SA 4.0. '
          'Credit is shown on the BPLO office page. Not precached.',
      semanticLabel: 'Photo: a sari-sari store',
      sha256:
          'ce5ff7d6778b9266301ff44fa2efee6eadd8011dd5c4241fa9e8b316a888f213',
    ),
    AssetEntry(
      key: 'mswdo_relief',
      path: 'assets/photos/mswdo_relief.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_mswdo.jpg. Presidential Communications Office, '
          'public domain. Credit is shown on the MSWDO page. Not precached.',
      semanticLabel: 'Photo: a relief distribution',
      sha256:
          '1ad6043488491ef29d3f08e81cce94b91b1662cd4ceee445e8f900827aab9a9d',
    ),
    AssetEntry(
      key: 'peso_notes',
      path: 'assets/photos/peso_notes.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_peso_money.jpg. Tupungato, CC BY 3.0. '
          'Credit is shown on the Treasury page. Not precached.',
      semanticLabel: 'Photo: Philippine peso notes',
      sha256:
          '1ccc7ad6532fd3feca968f92e6d231ad4b2af3c06e49687c15299ea85ec12804',
    ),
    AssetEntry(
      key: 'muzon_street',
      path: 'assets/photos/muzon_street.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_muzon.jpg. Judgefloro, CC0. '
          'Credit is shown on the Assessor page. Not precached.',
      semanticLabel: 'Photo: a Muzon street',
      sha256:
          '504569960f68495d3fd0bf4858cf0f78a74fe53e1e2cf67027c6e0964ae1b3ac',
    ),
    AssetEntry(
      key: 'rizal_avenue',
      path: 'assets/photos/rizal_avenue.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_rizalave.jpg. Ralff Nestor Nacor, CC BY-SA 4.0. '
          'Credit is shown on the Assessor and PIO pages. Not precached.',
      semanticLabel: 'Photo: Rizal Avenue in Taytay',
      sha256:
          '529cce1422bd10ecb4ef13a04a95c413b961e7d5b059025247c78f6a7a28c4e3',
    ),
    AssetEntry(
      key: 'rescuers',
      path: 'assets/photos/rescuers.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_bfp.jpg. Angeles City Information Office, '
          'public domain. Credit is shown on the MDRRMO page. Not precached.',
      semanticLabel: 'Photo: emergency rescuers',
      sha256:
          '0acdf7d8706a0b42691104f39f365e1e3601c1533500e18975760fe014d3f188',
    ),
    AssetEntry(
      key: 'rescue_vehicle',
      path: 'assets/photos/rescue_vehicle.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_rescuevan.jpg. FroyAgta, CC BY-SA 4.0. '
          'Credit is shown on the MDRRMO page. Not precached.',
      semanticLabel: 'Photo: Rescue vehicle, Bula',
      sha256:
          'b7ba969a9c60835453d7b4e63ff21fbaefc045139e95b1ec243017cbea4d700c',
    ),
    AssetEntry(
      key: 'skills_training',
      path: 'assets/photos/skills_training.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_tesda.jpg. Presidential Communications Office, '
          'public domain. Credit is shown on the PESO page. Not precached.',
      semanticLabel: 'Photo: TESDA skills training',
      sha256:
          '5c9951b9b0648bcca45bdab337e51d57db596c94bdbcafb1406af8373bb77125',
    ),
    AssetEntry(
      key: 'sk_council',
      path: 'assets/photos/sk_council.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_sk.jpg. Halimawsabanga, CC BY-SA 4.0. '
          'Credit is shown on the youth office page. Not precached.',
      semanticLabel: 'Photo: Sangguniang Kabataan council',
      sha256:
          '1dfda285e10128123105075ba4150dd1d428efb55d8d8003263713ffef0cc0ad',
    ),
    AssetEntry(
      key: 'sk_court',
      path: 'assets/photos/sk_court.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_skhoop.jpg. Iloilo Wanderer, CC BY-SA 3.0. '
          'Credit is shown on the youth office page. Not precached.',
      semanticLabel: 'Photo: SK basketball court',
      sha256:
          '939e18a541b46f28b9f23ea6e858bcd3b49b9320b42a04d03183787e1595682c',
    ),
    AssetEntry(
      key: 'health_centre',
      path: 'assets/photos/health_centre.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_bhc.jpg. FroyAgta, CC BY-SA 4.0. '
          'Credit is shown on the health office page. Not precached.',
      semanticLabel: 'Photo: Barangay health center, Bula',
      sha256:
          '10ff68d33950dc38aa139d0d2d89035abe3d37e6655eafe0b1847cb68aa539d1',
    ),
    AssetEntry(
      key: 'vaccination',
      path: 'assets/photos/vaccination.jpg',
      kind: AssetKind.photograph,
      format: AssetFormat.jpeg,
      licence: AssetLicence.thirdParty,
      provenance:
          'Design source src/ph_vaccine.jpg. Province of Camarines Sur, '
          'public domain. Credit is shown on the health office page. '
          'Not precached.',
      semanticLabel: 'Photo: Vaccination, Camarines Sur',
      sha256:
          '288f8151506341175c98989a2c63335ae3da8497a81832f8ac5c2194abedf473',
    ),
    AssetEntry(
      key: 'icon_bank',
      path: 'assets/icons/bank.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/bank.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: bank',
      sha256:
          'a98d9ffdb295d63b37b8e503e08a95294c61b30c1ad942f9c08aa85754ee5d95',
    ),
    AssetEntry(
      key: 'icon_brief',
      path: 'assets/icons/brief.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/brief.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: briefcase',
      sha256:
          '800425199caa42f32d26db8f5ad7480942e48aa4912b5c6eb76d5146c15b236d',
    ),
    AssetEntry(
      key: 'icon_cap',
      path: 'assets/icons/cap.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/cap.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: graduation cap',
      sha256:
          'e2d692fc19655515a7ebafbec3fbe8976378894a6d544d67ea3b607a4e5984ea',
    ),
    AssetEntry(
      key: 'icon_chat',
      path: 'assets/icons/chat.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/chat.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: chat bubble',
      sha256:
          '125cd3f05e3bde8aac90ecde05cdbfba59565117eba2abeed3822a6877f9b83f',
    ),
    AssetEntry(
      key: 'icon_check',
      path: 'assets/icons/check.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/check.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: check mark',
      sha256:
          'ff4cbaa20efb9e2bfb8393572fcee3019236fe149ac18a0930b1a267f917eb7f',
    ),
    AssetEntry(
      key: 'icon_clock',
      path: 'assets/icons/clock.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/clock.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: clock',
      sha256:
          '8d05fc50fed628d482b6d0e4a1891095fec15521408cd1280a4eabcf56d77385',
    ),
    AssetEntry(
      key: 'icon_cloud',
      path: 'assets/icons/cloud.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/cloud.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: cloud',
      sha256:
          'd7e7829833de7f9746fd404ece5115ceaa94dc64d9a8c2906110a0ae6d3c6b56',
    ),
    AssetEntry(
      key: 'icon_cloudoff',
      path: 'assets/icons/cloudoff.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/cloudoff.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: cloud, crossed out',
      sha256:
          '9a39bd021795e72316417ab5fff76d9cb61cd2ae9fcf5d372d29b6e7cc8ef600',
    ),
    AssetEntry(
      key: 'icon_cross',
      path: 'assets/icons/cross.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/cross.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: medical cross',
      sha256:
          '2821b73d56bb2aabc19b095a88fe4c6d9c62ac71e8c514f4685b5363e52a03ec',
    ),
    AssetEntry(
      key: 'icon_dir',
      path: 'assets/icons/dir.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/dir.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: directory',
      sha256:
          '0abaada16bf0c635d6cc0d6b4088946e4c644cfa7ceab3a65e56e15c8bf18c86',
    ),
    AssetEntry(
      key: 'icon_doc',
      path: 'assets/icons/doc.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/doc.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: document',
      sha256:
          '89abab5a5bf572d66cc36425092fda301acced411c0dcd5f3f1102da84087527',
    ),
    AssetEntry(
      key: 'icon_globe',
      path: 'assets/icons/globe.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/globe.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: globe',
      sha256:
          'e426632b2943ffc83587d808d615367a900b9eeea2956d1bc64105b71eda7ba9',
    ),
    AssetEntry(
      key: 'icon_heart',
      path: 'assets/icons/heart.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/heart.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: heart',
      sha256:
          '42f285cdcba9f723a1f86959bb2655107b0e3037ebfae5939a52897d9f708481',
    ),
    AssetEntry(
      key: 'icon_mega',
      path: 'assets/icons/mega.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/mega.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: megaphone',
      sha256:
          'a4a6e524dc158732d0f115cec80cc213b01ed5a1d3005db8abf9eb9877a0b10e',
    ),
    AssetEntry(
      key: 'icon_phone',
      path: 'assets/icons/phone.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/phone.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: phone',
      sha256:
          '05f97d254e626433e236ee249a20a900c6bbbaf8e7d6dfc801c7ec5946627935',
    ),
    AssetEntry(
      key: 'icon_pin',
      path: 'assets/icons/pin.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/pin.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: map pin',
      sha256:
          'eb82c79eb179997aea8c0a9a54b84322fa1145bae279e9687f6ed229cbbea552',
    ),
    AssetEntry(
      key: 'icon_search',
      path: 'assets/icons/search.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/search.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: magnifying glass',
      sha256:
          'c76b843974f4eb77db594fea7c5a3f870376e34c877705ea9aad22ad05cd3ef7',
    ),
    AssetEntry(
      key: 'icon_send',
      path: 'assets/icons/send.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/send.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: send',
      sha256:
          '96e683bcb200161ed4c440379b146a502e0128d556103fd0aa3633510d5e4986',
    ),
    AssetEntry(
      key: 'icon_siren',
      path: 'assets/icons/siren.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/siren.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: siren',
      sha256:
          '5454f7454432f3feb851e1eabf8d3b0bd204c2037068871b2997ee8abc196f3c',
    ),
    AssetEntry(
      key: 'icon_users',
      path: 'assets/icons/users.svg',
      kind: AssetKind.icon,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/users.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Icon: people',
      sha256:
          '2d9c376f9f08b19eb4e52dbc949bcb2468a7af489daa409e4a112df9a19117d1',
    ),
    AssetEntry(
      key: 'empty_no_results',
      path: 'assets/illustrations/empty_no_results.svg',
      kind: AssetKind.illustration,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/empty_no_results.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel: 'Illustration: an empty search with a magnifying glass',
      sha256:
          '896ec184f21312bba0f4bfdee3492e64a805538bf25bae7dc2473e82fef70efc',
    ),
    AssetEntry(
      key: 'empty_offline',
      path: 'assets/illustrations/empty_offline.svg',
      kind: AssetKind.illustration,
      format: AssetFormat.svg,
      licence: AssetLicence.originalWork,
      provenance:
          'Redesign handoff pack, design/icons/empty_offline.svg, drawn for this '
          'project (2026-11-10). Shipped unaltered but for the trailing newline.',
      semanticLabel:
          'Illustration: a cloud with a red cross, for no connection',
      sha256:
          '210703014cf65ea7f8104f05263c337148509fcedf949a1622ad1cedf81d00f5',
    ),
  ];

  /// Assets warmed before the first screen needs them.
  ///
  /// Empty, and it stays empty while everything is painted: there is nothing to
  /// decode. The allowlist exists so precaching is an explicit, budgeted
  /// decision rather than something a screen does on its own.
  static const List<String> precacheKeys = <String>[];

  static AssetEntry? byKey(String key) {
    for (final entry in all) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  static List<AssetEntry> ofKind(AssetKind kind) =>
      all.where((entry) => entry.kind == kind).toList(growable: false);
}
