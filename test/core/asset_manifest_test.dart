import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/assets/asset_validation.dart';

String _sha256(Uint8List bytes) => sha256.convert(bytes).toString();

/// A minimal valid PNG with an alpha-carrying colour type (6 = truecolour+alpha).
///
/// Hand-built rather than fixture-committed: the point of these tests is to
/// prove the validators reject bad input, and committing deliberately-broken
/// binaries to a government repository to test that is a poor trade.
Uint8List _fakePng({int colourType = 6, int padding = 0}) {
  final bytes = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
    0x00, 0x00, 0x00, 0x0D, // IHDR length
    0x49, 0x48, 0x44, 0x52, // 'IHDR'
    0x00, 0x00, 0x00, 0x10, // width 16
    0x00, 0x00, 0x00, 0x10, // height 16
    0x08, // bit depth (byte 24)
    colourType, // colour type (byte 25)
    0x00, 0x00, 0x00,
    ...List<int>.filled(padding, 0),
  ];
  return Uint8List.fromList(bytes);
}

Uint8List _fakeJpeg() => Uint8List.fromList(<int>[
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
  ...List<int>.filled(40, 0),
]);

Uint8List _fakeSvg() => Uint8List.fromList(
  utf8.encode('<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg"/>'),
);

AssetEntry _entry({
  String key = 'sample_scene',
  String? path,
  AssetKind kind = AssetKind.illustration,
  AssetFormat format = AssetFormat.svg,
  AssetLicence licence = AssetLicence.originalWork,
  String provenance = 'Drawn for this project, TAB 04.',
  String semanticLabel = 'Illustration: a sample scene.',
  String? sha,
  int? maxBytes,
}) => AssetEntry(
  key: key,
  path: path ?? '${kind.directory}/$key.${format.name}',
  kind: kind,
  format: format,
  licence: licence,
  provenance: provenance,
  semanticLabel: semanticLabel,
  sha256: sha ?? 'a' * 64,
  maxBytes: maxBytes,
);

List<AssetViolation> _validate(
  AssetEntry entry,
  Uint8List? bytes, {
  Set<String> siblings = const <String>{},
}) => AssetValidator.validate(
  entry: entry,
  bytes: bytes,
  siblingPaths: siblings,
  computeSha256: _sha256,
);

Set<String> _rulesOf(List<AssetViolation> violations) =>
    violations.map((v) => v.rule).toSet();

void main() {
  group('shipped manifest', () {
    test('every declared asset passes every rule', () {
      // Vacuous while everything is painted; load-bearing the moment a file is
      // added, which is exactly when nobody remembers this test exists.
      final existing = Directory('assets').existsSync()
          ? Directory('assets')
                .listSync(recursive: true)
                .whereType<File>()
                .map((f) => f.path.replaceAll(r'\', '/'))
                .toSet()
          : <String>{};

      for (final entry in AppAssets.all) {
        final file = File(entry.path);
        final violations = _validate(
          entry,
          file.existsSync() ? file.readAsBytesSync() : null,
          siblings: existing,
        );
        expect(violations, isEmpty, reason: violations.join('\n'));
      }
    });

    test('no undeclared file is sitting in the asset directories', () {
      // An undeclared asset has no licence, no budget and no approved hash.
      final undeclared = <String>[];
      final declared = AppAssets.all.map((e) => e.path).toSet();

      for (final kind in AssetKind.values) {
        final directory = Directory(kind.directory);
        if (!directory.existsSync()) continue;
        for (final file in directory.listSync(recursive: true).whereType<File>()) {
          final path = file.path.replaceAll(r'\', '/');
          final name = path.split('/').last;
          if (name == '.gitkeep' || name == 'README.md') continue;
          // Density variants are covered by their 1x declaration.
          if (path.contains('/2.0x/') || path.contains('/3.0x/')) {
            final base = path.replaceAll(RegExp(r'/[23]\.0x/'), '/');
            if (declared.contains(base)) continue;
          } else if (declared.contains(path)) {
            continue;
          }
          undeclared.add(path);
        }
      }

      expect(
        undeclared,
        isEmpty,
        reason:
            'Register these in asset_manifest.dart, or delete them:\n'
            '${undeclared.join('\n')}',
      );
    });

    test('keys are unique and snake_case', () {
      final keys = AppAssets.all.map((e) => e.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final key in keys) {
        expect(AssetPolicy.keyPattern.hasMatch(key), isTrue, reason: key);
      }
    });

    test('the asset directory structure exists', () {
      for (final kind in AssetKind.values) {
        expect(
          Directory(kind.directory).existsSync(),
          isTrue,
          reason: '${kind.directory} is missing',
        );
      }
    });
  });

  group('precache allowlist', () {
    test('is within its count and byte budgets', () {
      final violations = AssetValidator.validatePrecache(
        precacheKeys: AppAssets.precacheKeys,
        manifest: AppAssets.all,
        byteSizes: <String, int>{
          for (final entry in AppAssets.all)
            entry.key: File(entry.path).existsSync()
                ? File(entry.path).lengthSync()
                : 0,
        },
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('rejects a key that is not in the manifest', () {
      final violations = AssetValidator.validatePrecache(
        precacheKeys: <String>['ghost_asset'],
        manifest: const <AssetEntry>[],
        byteSizes: const <String, int>{},
      );
      expect(violations, isNotEmpty);
      expect(violations.first.rule, 'precache');
    });

    test('rejects too many assets and too many bytes', () {
      final manifest = <AssetEntry>[
        for (var i = 0; i <= AssetPolicy.maxPrecacheCount; i++)
          _entry(key: 'scene_$i'),
      ];
      final tooMany = AssetValidator.validatePrecache(
        precacheKeys: manifest.map((e) => e.key).toList(),
        manifest: manifest,
        byteSizes: <String, int>{for (final e in manifest) e.key: 1},
      );
      expect(_rulesOf(tooMany), contains('count'));

      final tooHeavy = AssetValidator.validatePrecache(
        precacheKeys: <String>['sample_scene'],
        manifest: <AssetEntry>[_entry()],
        byteSizes: <String, int>{
          'sample_scene': AssetPolicy.maxPrecacheBytes + 1,
        },
      );
      expect(_rulesOf(tooHeavy), contains('budget'));
    });
  });

  group('validator — provenance and licence', () {
    test('accepts an original work with a stated origin', () {
      final bytes = _fakeSvg();
      final entry = _entry(sha: _sha256(bytes));
      expect(_validate(entry, bytes), isEmpty);
    });

    test('rejects an empty provenance', () {
      final bytes = _fakeSvg();
      final entry = _entry(provenance: '   ', sha: _sha256(bytes));
      expect(_rulesOf(_validate(entry, bytes)), contains('provenance'));
    });

    test('requires a real reference for non-original licences', () {
      final bytes = _fakeSvg();
      for (final licence in <AssetLicence>[
        AssetLicence.lguSupplied,
        AssetLicence.thirdParty,
      ]) {
        final entry = _entry(
          licence: licence,
          provenance: 'ok',
          sha: _sha256(bytes),
        );
        expect(
          _rulesOf(_validate(entry, bytes)),
          contains('provenance'),
          reason: licence.name,
        );
      }
    });
  });

  group('validator — accessible naming', () {
    test('an illustration must be announced as an illustration', () {
      final bytes = _fakeSvg();
      final entry = _entry(
        semanticLabel: 'A municipal building.',
        sha: _sha256(bytes),
      );
      expect(_rulesOf(_validate(entry, bytes)), contains('semantics'));
    });

    test('no asset may claim to be a photograph', () {
      final bytes = _fakeSvg();
      for (final label in <String>[
        'Illustration: photo of the municipal hall',
        'Illustration: a picture of the mayor',
        'Illustration: actual footage of the event',
      ]) {
        final entry = _entry(semanticLabel: label, sha: _sha256(bytes));
        expect(
          _rulesOf(_validate(entry, bytes)),
          contains('semantics'),
          reason: label,
        );
      }
    });

    test('rejects an empty accessible name', () {
      final bytes = _fakeSvg();
      final entry = _entry(semanticLabel: '', sha: _sha256(bytes));
      expect(_rulesOf(_validate(entry, bytes)), contains('semantics'));
    });
  });

  group('validator — bytes', () {
    test('rejects a missing file', () {
      expect(_rulesOf(_validate(_entry(), null)), contains('missing'));
    });

    test('rejects bytes that no longer match the approved hash', () {
      final entry = _entry(sha: 'b' * 64);
      expect(_rulesOf(_validate(entry, _fakeSvg())), contains('hash'));
    });

    test('rejects a malformed hash declaration', () {
      final bytes = _fakeSvg();
      final entry = _entry(sha: 'abc');
      expect(_rulesOf(_validate(entry, bytes)), contains('hash'));
    });

    test('rejects an asset over its budget', () {
      final bytes = _fakeSvg();
      final entry = _entry(sha: _sha256(bytes), maxBytes: 4);
      expect(_rulesOf(_validate(entry, bytes)), contains('budget'));
    });

    test('per-kind budgets are ordered sensibly', () {
      expect(
        AssetPolicy.budgetFor(AssetKind.icon),
        lessThan(AssetPolicy.budgetFor(AssetKind.placeholder)),
      );
      expect(
        AssetPolicy.budgetFor(AssetKind.banner),
        lessThan(AssetPolicy.budgetFor(AssetKind.illustration)),
      );
      for (final kind in AssetKind.values) {
        expect(AssetPolicy.budgetFor(kind), greaterThan(0), reason: kind.name);
      }
    });
  });

  group('validator — format', () {
    test('rejects JPEG regardless of the declared format or extension', () {
      // The exact failure mode of the seal candidate rejected in TAB 03: a JPEG
      // wearing a .png extension.
      final bytes = _fakeJpeg();
      final entry = _entry(
        key: 'seal_like',
        format: AssetFormat.png,
        path: '${AssetKind.illustration.directory}/seal_like.png',
        sha: _sha256(bytes),
      );
      final rules = _rulesOf(_validate(entry, bytes));
      expect(rules, contains('format'));
    });

    test('rejects a PNG with no alpha channel', () {
      // Colour type 2 is truecolour without alpha — it would render as an
      // opaque rectangle, which is how the rejected seal behaved.
      final bytes = _fakePng(colourType: 2);
      final entry = _entry(
        format: AssetFormat.png,
        path: '${AssetKind.illustration.directory}/sample_scene.png',
        sha: _sha256(bytes),
        maxBytes: 1024,
      );
      expect(_rulesOf(_validate(entry, bytes)), contains('format'));
    });

    test('accepts a PNG with alpha when its density variants exist', () {
      final bytes = _fakePng();
      const path = 'assets/illustrations/sample_scene.png';
      final entry = _entry(
        format: AssetFormat.png,
        path: path,
        sha: _sha256(bytes),
        maxBytes: 1024,
      );
      final violations = _validate(
        entry,
        bytes,
        siblings: <String>{
          'assets/illustrations/2.0x/sample_scene.png',
          'assets/illustrations/3.0x/sample_scene.png',
        },
      );
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('requires 2x and 3x variants for raster assets', () {
      final bytes = _fakePng();
      final entry = _entry(
        format: AssetFormat.png,
        path: 'assets/illustrations/sample_scene.png',
        sha: _sha256(bytes),
        maxBytes: 1024,
      );
      final violations = _validate(entry, bytes);
      expect(_rulesOf(violations), contains('density'));
      expect(
        violations.where((v) => v.rule == 'density'),
        hasLength(2),
        reason: 'both 2.0x and 3.0x should be reported',
      );
    });

    test('SVG needs no density variants', () {
      final bytes = _fakeSvg();
      final entry = _entry(sha: _sha256(bytes));
      expect(_rulesOf(_validate(entry, bytes)), isNot(contains('density')));
      expect(AssetFormat.svg.isDensityDependent, isFalse);
      expect(AssetFormat.png.isDensityDependent, isTrue);
      expect(AssetFormat.webp.isDensityDependent, isTrue);
    });

    test('lossy formats are not expressible in the manifest', () {
      expect(
        AssetFormat.values.map((f) => f.name),
        unorderedEquals(<String>['svg', 'png', 'webp']),
      );
    });
  });

  group('validator — paths', () {
    test('rejects an asset filed under the wrong kind directory', () {
      final bytes = _fakeSvg();
      final entry = _entry(
        kind: AssetKind.icon,
        path: 'assets/illustrations/sample_scene.svg',
        semanticLabel: 'A sample icon.',
        sha: _sha256(bytes),
      );
      expect(_rulesOf(_validate(entry, bytes)), contains('path'));
    });

    test('rejects a density directory in the declared path', () {
      final bytes = _fakePng();
      final entry = _entry(
        format: AssetFormat.png,
        path: 'assets/illustrations/2.0x/sample_scene.png',
        sha: _sha256(bytes),
        maxBytes: 1024,
      );
      expect(_rulesOf(_validate(entry, bytes)), contains('path'));
    });

    test('rejects a non-snake_case key', () {
      final bytes = _fakeSvg();
      final entry = _entry(key: 'SampleScene', sha: _sha256(bytes));
      expect(_rulesOf(_validate(entry, bytes)), contains('key'));
    });

    test('each kind owns a distinct directory under assets/', () {
      final directories = AssetKind.values.map((k) => k.directory).toList();
      expect(directories.toSet(), hasLength(directories.length));
      for (final directory in directories) {
        expect(directory, startsWith('assets/'));
      }
    });
  });
}
