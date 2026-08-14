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
  officialArtwork('assets/brand');

  const AssetKind(this.directory);

  /// The one directory this kind may live in. Enforced by
  /// `asset_manifest_test.dart`, so an asset cannot drift into a folder whose
  /// rules do not apply to it.
  final String directory;
}

/// Permitted container formats.
///
/// JPEG is deliberately absent. Every asset in this app is flat-colour artwork
/// with transparency: JPEG carries no alpha, and its ringing artifacts are worst
/// exactly where this artwork is strongest — hard edges between flat fills. The
/// one case JPEG suits, a photograph, is a case this app does not have (see
/// [AssetLicence.originalWork] and the no-photography rule).
enum AssetFormat {
  /// Preferred for anything geometric. One file, every density.
  svg('image/svg+xml'),

  /// Lossless raster with alpha. Needs density variants.
  png('image/png'),

  /// Lossless-mode raster with alpha. Smaller than PNG at equal quality.
  webp('image/webp');

  const AssetFormat(this.mimeType);

  final String mimeType;

  /// Whether this format needs `2.0x` / `3.0x` variants alongside it.
  bool get isDensityDependent => this != AssetFormat.svg;
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

  /// Words that would claim an image is a photograph of a real place, event or
  /// person. None of this app's artwork is photographic, and a label implying
  /// otherwise is a factual claim the app cannot support.
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
/// **Currently empty, deliberately.** TAB 04's illustrations, scenes, state art
/// and placeholders are implemented as Flutter-painted compositions
/// (`lib/shared/illustrations/`) rather than as image files, because for flat
/// geometric artwork that is strictly better: zero install bytes, no density
/// variants to keep in sync, exact colour from the theme in both light and dark
/// mode, and no licence surface at all.
///
/// A raster file earns its place only when it is *materially* better — a
/// photographic or hand-painted texture that cannot be expressed as geometry.
/// This registry, its budgets and its tests exist so that the day such a file
/// arrives it is checked rather than merely dropped in.
abstract final class AppAssets {
  static const List<AssetEntry> all = <AssetEntry>[];

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
