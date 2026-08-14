import 'dart:typed_data';

import 'asset_manifest.dart';

/// One thing wrong with one asset.
class AssetViolation {
  const AssetViolation(this.assetKey, this.rule, this.detail);

  final String assetKey;

  /// Short machine-readable rule id, e.g. `budget`, `format`, `hash`.
  final String rule;

  final String detail;

  @override
  String toString() => '[$assetKey] $rule: $detail';
}

/// Validates manifest entries against the bytes actually on disk.
///
/// **Pure on purpose.** It takes bytes and a set of known paths rather than
/// touching the filesystem, so the rules can be unit-tested against synthetic
/// inputs — including deliberately broken ones — without writing files, and so
/// `lib/` stays free of `dart:io`. The test harness does the reading.
abstract final class AssetValidator {
  /// Magic-byte signatures. Format is checked by **content**, never by
  /// extension: the seal candidate rejected in TAB 03 was a JPEG named `.png`,
  /// which is precisely what an extension check cannot catch.
  static const Map<AssetFormat, List<int>> _signatures =
      <AssetFormat, List<int>>{
        AssetFormat.png: <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        // RIFF....WEBP — bytes 0-3 and 8-11; the length field between them
        // varies, so it is checked separately in [_matchesFormat].
        AssetFormat.webp: <int>[0x52, 0x49, 0x46, 0x46],
      };

  static const List<int> _jpegSignature = <int>[0xFF, 0xD8, 0xFF];
  static const List<int> _gifSignature = <int>[0x47, 0x49, 0x46, 0x38];

  /// Checks one entry.
  ///
  /// [bytes] is the file at [AssetEntry.path], or `null` when it is missing.
  /// [siblingPaths] is every path that exists in the bundle, used to confirm
  /// density variants. [computeSha256] is injected so this stays dependency-free.
  static List<AssetViolation> validate({
    required AssetEntry entry,
    required Uint8List? bytes,
    required Set<String> siblingPaths,
    required String Function(Uint8List bytes) computeSha256,
  }) {
    final violations = <AssetViolation>[];

    void fail(String rule, String detail) =>
        violations.add(AssetViolation(entry.key, rule, detail));

    // ── Naming and location ────────────────────────────────────────────────
    if (!AssetPolicy.keyPattern.hasMatch(entry.key)) {
      fail('key', 'must be snake_case: "${entry.key}"');
    }
    if (!entry.path.startsWith('${entry.kind.directory}/')) {
      fail(
        'path',
        '${entry.path} is not under ${entry.kind.directory}/, whose rules apply '
            'to a ${entry.kind.name}',
      );
    }
    if (entry.path.contains('2.0x/') || entry.path.contains('3.0x/')) {
      fail(
        'path',
        'declare the 1x path; Flutter resolves density variants itself',
      );
    }

    // ── Provenance and licence ─────────────────────────────────────────────
    if (entry.provenance.trim().isEmpty) {
      fail('provenance', 'every asset must record where it came from');
    }
    if (entry.licence != AssetLicence.originalWork &&
        entry.provenance.trim().length < 12) {
      fail(
        'provenance',
        '${entry.licence.name} requires a real reference — an LGU approval, or '
            'a licence name and attribution',
      );
    }

    // ── Accessible name ────────────────────────────────────────────────────
    if (entry.semanticLabel.trim().isEmpty) {
      fail(
        'semantics',
        'an asset with no accessible name is invisible to some '
            'residents',
      );
    }
    if (entry.kind == AssetKind.illustration &&
        !entry.semanticLabel.startsWith(AssetPolicy.illustrationLabelPrefix)) {
      fail(
        'semantics',
        'an illustration must be announced as one; label must start with '
            '"${AssetPolicy.illustrationLabelPrefix}"',
      );
    }
    final lowerLabel = entry.semanticLabel.toLowerCase();
    for (final claim in AssetPolicy.forbiddenLabelClaims) {
      if (lowerLabel.contains(claim)) {
        fail(
          'semantics',
          'label claims "$claim"; this app ships no documentary photography',
        );
      }
    }

    // ── Bytes ──────────────────────────────────────────────────────────────
    if (bytes == null) {
      fail('missing', '${entry.path} is registered but not present');
      return violations;
    }

    if (entry.sha256.length != 64) {
      fail('hash', 'declared sha256 is not 64 hex characters');
    } else {
      final actual = computeSha256(bytes).toLowerCase();
      if (actual != entry.sha256.toLowerCase()) {
        fail(
          'hash',
          'bytes changed since approval (expected ${entry.sha256}, got $actual)',
        );
      }
    }

    if (bytes.lengthInBytes > entry.effectiveMaxBytes) {
      fail(
        'budget',
        '${bytes.lengthInBytes} bytes exceeds the '
            '${entry.effectiveMaxBytes}-byte budget for ${entry.kind.name}',
      );
    }

    if (_startsWith(bytes, _jpegSignature)) {
      fail('format', 'JPEG carries no alpha and smears flat-colour edges');
    }
    if (_startsWith(bytes, _gifSignature)) {
      fail('format', 'GIF is limited to 256 colours');
    }
    if (!_matchesFormat(bytes, entry.format)) {
      fail(
        'format',
        'content is not ${entry.format.name} regardless of the file extension',
      );
    }
    if (entry.format == AssetFormat.png && !_pngHasAlpha(bytes)) {
      fail(
        'format',
        'PNG has no alpha channel, so it renders as an opaque rectangle',
      );
    }

    // ── Density variants ───────────────────────────────────────────────────
    if (entry.format.isDensityDependent) {
      final separator = entry.path.lastIndexOf('/');
      final directory = entry.path.substring(0, separator);
      final fileName = entry.path.substring(separator + 1);
      for (final density in AssetPolicy.requiredDensityDirectories) {
        final variant = '$directory/$density/$fileName';
        if (!siblingPaths.contains(variant)) {
          fail('density', 'missing $variant');
        }
      }
    }

    return violations;
  }

  /// Validates the startup precache allowlist as a whole.
  static List<AssetViolation> validatePrecache({
    required List<String> precacheKeys,
    required List<AssetEntry> manifest,
    required Map<String, int> byteSizes,
  }) {
    final violations = <AssetViolation>[];

    if (precacheKeys.length > AssetPolicy.maxPrecacheCount) {
      violations.add(
        AssetViolation(
          'precache',
          'count',
          '${precacheKeys.length} assets exceeds the '
              '${AssetPolicy.maxPrecacheCount} allowed at startup',
        ),
      );
    }

    var total = 0;
    for (final key in precacheKeys) {
      final entry = manifest.where((e) => e.key == key).firstOrNull;
      if (entry == null) {
        violations.add(
          AssetViolation(key, 'precache', 'not present in the manifest'),
        );
        continue;
      }
      total += byteSizes[key] ?? 0;
    }

    if (total > AssetPolicy.maxPrecacheBytes) {
      violations.add(
        AssetViolation(
          'precache',
          'budget',
          '$total bytes exceeds the ${AssetPolicy.maxPrecacheBytes}-byte '
              'startup budget',
        ),
      );
    }

    return violations;
  }

  static bool _matchesFormat(Uint8List bytes, AssetFormat format) {
    switch (format) {
      case AssetFormat.png:
        return _startsWith(bytes, _signatures[AssetFormat.png]!);
      case AssetFormat.webp:
        return _startsWith(bytes, _signatures[AssetFormat.webp]!) &&
            bytes.length > 12 &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
      case AssetFormat.svg:
        // SVG is text; look for the root element near the start, tolerating an
        // XML declaration, a BOM or a doctype ahead of it.
        final head = String.fromCharCodes(
          bytes.sublist(0, bytes.length < 1024 ? bytes.length : 1024),
        );
        return head.contains('<svg');
    }
  }

  /// True when a PNG declares an alpha-carrying colour type.
  ///
  /// IHDR colour type is byte 25: 4 = greyscale+alpha, 6 = truecolour+alpha.
  /// Type 3 (palette) may carry alpha in a `tRNS` chunk.
  static bool _pngHasAlpha(Uint8List bytes) {
    if (bytes.length < 26) return false;
    final colourType = bytes[25];
    if (colourType == 4 || colourType == 6) return true;
    if (colourType == 3) {
      final head = String.fromCharCodes(
        bytes.sublist(0, bytes.length < 4096 ? bytes.length : 4096),
      );
      return head.contains('tRNS');
    }
    return false;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
