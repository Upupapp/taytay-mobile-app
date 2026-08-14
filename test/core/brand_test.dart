import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/brand_assets.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';

/// Magic-byte signatures, so format is checked by content rather than by file
/// extension. The candidate asset that failed this audit was a JPEG named
/// `.png`, which is exactly the case an extension check cannot catch.
const Map<String, List<int>> _signatures = <String, List<int>>{
  'png': <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
  'jpeg': <int>[0xFF, 0xD8, 0xFF],
  'gif': <int>[0x47, 0x49, 0x46, 0x38],
  'webp_riff': <int>[0x52, 0x49, 0x46, 0x46],
};

/// Removes `//` line comments and `/* */` blocks, so source scans test code
/// rather than the prose explaining it.
String _stripComments(String source) {
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  return withoutBlocks
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

bool _startsWith(Uint8List bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}

/// True when a PNG declares a colour type that carries alpha.
///
/// IHDR colour type is byte 25: 4 = greyscale+alpha, 6 = truecolour+alpha.
/// Type 3 (palette) may carry alpha in a tRNS chunk, which is also accepted.
bool _pngHasAlpha(Uint8List bytes) {
  if (!_startsWith(bytes, _signatures['png']!)) return false;
  final colourType = bytes[25];
  if (colourType == 4 || colourType == 6) return true;
  if (colourType == 3) {
    return utf8
        .decode(bytes.sublist(0, 2048), allowMalformed: true)
        .contains('tRNS');
  }
  return false;
}

void main() {
  group('brand asset registry', () {
    test('every registered asset declares a licence reference', () {
      // An asset with no recorded approval is artwork nobody can prove the LGU
      // authorised. The list is empty today, which makes this vacuous now and
      // load-bearing the moment a seal is added.
      for (final asset in BrandAssets.all) {
        expect(asset.approvalReference, isNotEmpty, reason: asset.key);
        expect(asset.semanticLabel, isNotEmpty, reason: asset.key);
        expect(asset.sha256, hasLength(64), reason: asset.key);
      }
    });

    test('registered asset files exist and match their declared checksum', () {
      for (final asset in BrandAssets.all) {
        final file = File(asset.assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: '${asset.key}: ${asset.assetPath} is registered but missing',
        );

        final bytes = file.readAsBytesSync();
        final digest = sha256.convert(bytes).toString();
        expect(
          digest,
          asset.sha256,
          reason:
              '${asset.key} has been re-encoded or replaced. Official artwork '
              'must be byte-identical to the approved file.',
        );
      }
    });

    test('registered artwork is lossless and, for PNG, carries alpha', () {
      for (final asset in BrandAssets.all) {
        final bytes = File(asset.assetPath).readAsBytesSync();

        expect(
          _startsWith(bytes, _signatures['jpeg']!),
          isFalse,
          reason:
              '${asset.key} is JPEG. Lossy compression degrades the fine '
              'linework of a seal and carries no alpha channel.',
        );
        expect(
          _startsWith(bytes, _signatures['gif']!),
          isFalse,
          reason: '${asset.key} is GIF — 256 colours cannot hold a seal.',
        );

        switch (asset.format) {
          case BrandAssetFormat.png:
            expect(
              _startsWith(bytes, _signatures['png']!),
              isTrue,
              reason: '${asset.key} is declared PNG but its bytes are not PNG.',
            );
            expect(
              _pngHasAlpha(bytes),
              isTrue,
              reason:
                  '${asset.key} has no alpha channel, so it renders as an '
                  'opaque rectangle on any surface.',
            );
          case BrandAssetFormat.svg:
            final head = utf8.decode(
              bytes.sublist(0, bytes.length < 512 ? bytes.length : 512),
              allowMalformed: true,
            );
            expect(head, contains('<svg'), reason: asset.key);
        }
      }
    });

    test('the seal is absent until verified artwork is supplied', () {
      // Guards the decision recorded in brand_assets.dart. If someone registers
      // a seal, this test fails and forces them to read that file, delete this
      // expectation deliberately, and record the approval.
      expect(
        BrandAssets.hasVerifiedSeal,
        isFalse,
        reason:
            'A seal was registered. Confirm it is losslessly encoded, carries '
            'alpha, and that its approvalReference points at real LGU '
            'permission — then update this test.',
      );
    });

    test('lossy formats are not expressible in the registry', () {
      // The format enum is the allow-list. Adding JPEG would require editing it,
      // which is a visible act in review rather than an incidental asset drop.
      expect(
        BrandAssetFormat.values.map((f) => f.name),
        unorderedEquals(<String>['svg', 'png']),
      );
    });
  });

  group('seal integrity rules', () {
    test('the rule set is stated, not merely implied', () {
      expect(SealIntegrityRules.rules, isNotEmpty);
      for (final rule in SealIntegrityRules.rules) {
        expect(rule, isNotEmpty);
      }
    });

    test('minimum rendered size keeps the mark legible', () {
      expect(
        SealIntegrityRules.minRenderedSize,
        greaterThanOrEqualTo(32),
        reason: 'Below 32dp a seal reads as an anonymous blob.',
      );
      expect(SealIntegrityRules.clearSpaceRatio, greaterThan(0));
    });
  });

  group('brand gradients', () {
    test('every gradient has at least two stops', () {
      for (final gradient in BrandGradients.all) {
        expect(
          gradient.colors.length,
          greaterThanOrEqualTo(2),
          reason: gradient.name,
        );
      }
    });

    test('declared foreground clears WCAG AA at the worst stop', () {
      // The point of the type: contrast is proved across the whole ramp,
      // including interpolated midpoints, not just at the endpoints someone
      // happened to look at.
      for (final gradient in BrandGradients.all) {
        expect(
          gradient.worstCaseContrastRatio(),
          greaterThanOrEqualTo(A11y.minBodyContrastRatio),
          reason:
              '${gradient.name}: text would fall below 4.5:1 somewhere along '
              'the gradient.',
        );
      }
    });

    test('worst-case sampling catches a midpoint an endpoint check misses', () {
      // A ramp from black to black-via-white: both endpoints pass against white
      // text, the middle does not. Proves the sampler is doing real work.
      const trap = BrandGradient(
        name: 'trap',
        colors: <Color>[Colors.black, Colors.white, Colors.black],
        onColor: Colors.white,
      );
      expect(contrastRatio(Colors.white, Colors.black), greaterThan(4.5));
      expect(trap.worstCaseContrastRatio(), lessThan(1.5));
    });
  });

  group('brand palette', () {
    test('the primary brand blue carries white text at AA', () {
      expect(
        contrastRatio(Colors.white, BrandColors.taytayBlue),
        greaterThanOrEqualTo(A11y.minBodyContrastRatio),
      );
      expect(
        contrastRatio(Colors.white, BrandColors.taytayBlueDark),
        greaterThanOrEqualTo(A11y.minBodyContrastRatio),
      );
    });

    test('gold is accent-only and is not used as text on white', () {
      // Asserted so the constraint is a fact in the suite rather than a comment:
      // gold on white is roughly 1.6:1 and is never legitimate body text.
      expect(
        contrastRatio(BrandColors.sealGold, Colors.white),
        lessThan(A11y.minBodyContrastRatio),
      );
    });

    test('status colours carry white text at AA', () {
      for (final entry in <String, Color>{
        'success': BrandColors.success,
        'warning': BrandColors.warning,
        'danger': BrandColors.danger,
        'info': BrandColors.info,
      }.entries) {
        expect(
          contrastRatio(Colors.white, entry.value),
          greaterThanOrEqualTo(A11y.minBodyContrastRatio),
          reason: entry.key,
        );
      }
    });

    test('no Pantone or ink specification is claimed anywhere in lib/', () {
      // This project must not invent an official colour standard. Comments are
      // stripped first: `design_tokens.dart` documents *why* no Pantone value
      // is asserted, and a disclaimer is the opposite of a claim.
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = _stripComments(entity.readAsStringSync()).toLowerCase();
        if (text.contains('pantone') ||
            RegExp(r'\bpms\s*\d').hasMatch(text) ||
            RegExp(r'\bcmyk\b').hasMatch(text)) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'No verified LGU colour specification has been supplied, so no '
            'Pantone/CMYK claim may appear in the source.',
      );
    });
  });
}
