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
