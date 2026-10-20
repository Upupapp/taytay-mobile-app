import 'package:flutter/foundation.dart';

/// Registry and integrity policy for official Municipality of Taytay artwork.
///
/// ---
///
/// The official seal of a Philippine local government unit is a government
/// symbol. It identifies acts of the municipality, and a resident who sees it on
/// a screen is entitled to read it as "this is the LGU speaking". Two duties
/// follow, and they pull in the same direction:
///
/// 1. **It must be reproduced exactly.** Not recoloured, not cropped, not
///    stretched, not redrawn, not tinted to match a theme, not given a drop
///    shadow, not placed on a background that changes what it looks like.
/// 2. **It must be the real one.** An approximation of a government seal
///    rendered in a government app is worse than no seal, because it is
///    indistinguishable from the real thing to the person looking at it.
///
/// The registered file is `assets/brand/taytay_seal.png`, copied byte for byte
/// from the S0 design source `src/taytay_seal.png`. It is a PNG with an alpha
/// channel. The mark widget draws it with `BoxFit.contain` and nothing else: no
/// colour filter and no recompression. The woven header may place that same
/// file in the mockup's circular container (white pad, gold ring). The file
/// itself is not redrawn. There is no wordmark stand-in.
///
/// An earlier prototype file named `taytay_logo.png` was a JPEG flattened onto
/// black. That file is not this asset and is not registered.
///
/// `flutter test test/core/brand_test.dart` checks that the bytes on disk match
/// the SHA-256 recorded here. Re-encoding the seal fails that test.
@immutable
class BrandAsset {
  const BrandAsset({
    required this.key,
    required this.assetPath,
    required this.sha256,
    required this.format,
    required this.semanticLabel,
    required this.approvalReference,
  });

  /// Stable identifier, e.g. `municipal_seal`.
  final String key;

  /// Bundle path, e.g. `assets/brand/municipal_seal.png`.
  final String assetPath;

  /// Lower-case hex SHA-256 of the approved file, as delivered.
  final String sha256;

  final BrandAssetFormat format;

  /// Screen-reader description. Required: a government mark that is invisible to
  /// a screen-reader user is a mark that only some residents can see.
  final String semanticLabel;

  /// Where the permission to use this artwork is recorded — an LGU issuance
  /// number, memorandum reference or ticket. Recorded so the licence basis is
  /// discoverable from the code that uses it.
  final String approvalReference;

  @override
  String toString() => 'BrandAsset($key, $format, $assetPath)';
}

/// Container formats permitted for official artwork.
///
/// Lossy formats are absent deliberately: JPEG re-encoding visibly degrades the
/// fine linework and lettering a seal is made of, and JPEG carries no alpha, so
/// the mark cannot sit on anything but its baked-in background.
enum BrandAssetFormat {
  /// Preferred. Scales to any density without resampling.
  svg('image/svg+xml'),

  /// Acceptable. Must carry an alpha channel.
  png('image/png');

  const BrandAssetFormat(this.mimeType);

  final String mimeType;
}

/// The official artwork this build is authorised to render.
abstract final class BrandAssets {
  /// The municipal seal, byte-identical to the S0 design source.
  static const BrandAsset municipalSeal = BrandAsset(
    key: 'municipal_seal',
    assetPath: 'assets/brand/taytay_seal.png',
    sha256: '8541609af1ece1833cc9a03f326603315641bd8f44dc98b442c99545d529de8b',
    format: BrandAssetFormat.png,
    semanticLabel: 'Seal of the Municipality of Taytay, Rizal',
    approvalReference:
        'S0 design source src/taytay_seal.png, supplied as the official '
        'Municipality of Taytay seal',
  );

  /// Every registered asset. Used by the integrity test.
  static List<BrandAsset> get all => <BrandAsset>[municipalSeal];

  /// Whether this build may render the official seal.
  static bool get hasVerifiedSeal => true;
}

/// Presentation rules for official artwork.
///
/// `BrandMark` enforces these structurally — it offers no parameter that could
/// break one. They are written down anyway, because the next component that
/// renders the seal will be written by someone who did not read this file, and a
/// rule that exists only as the absence of an API is a rule nobody can cite.
abstract final class SealIntegrityRules {
  /// Minimum rendered size. Below this the seal's lettering is illegible and the
  /// mark reads as an anonymous blob, which is its own kind of misrepresentation.
  static const double minRenderedSize = 32;

  /// Clear space around the mark, as a fraction of its rendered size. Keeps
  /// surrounding text and edges from crowding or appearing to be part of it.
  static const double clearSpaceRatio = 0.12;

  /// The rules, for documentation and for the human reading a review diff.
  static const List<String> rules = <String>[
    'Reproduce the artwork exactly as supplied — never redraw or trace it.',
    'Never recolour, tint, apply a colour filter, or convert to monochrome.',
    'Never stretch: preserve the intrinsic aspect ratio (BoxFit.contain only).',
    'Never crop or redraw the artwork. A circular container may frame it.',
    'Never rotate, skew, mirror or animate the mark itself.',
    'Never paint a shadow, glow or border onto the artwork. A ring may sit on the container around it.',
    'Never overlay text or graphics on it, and never use it as a background.',
    'Never render it below ${minRenderedSize}dp.',
    'Keep clear space of at least ${clearSpaceRatio}x its size on every side.',
    'Never use the seal as a decorative element or as an app-wide watermark.',
  ];
}
