import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';

void main() {
  group('reading what the server published', () {
    test('a well-formed accepts block is used', () {
      final policy = UploadPolicy.decode(<String, dynamic>{
        'max_bytes': 10 * 1024 * 1024,
        'mime_types': <dynamic>['image/jpeg', 'application/pdf'],
      });

      expect(policy.source, UploadPolicySource.served);
      expect(policy.maxBytes, 10 * 1024 * 1024);
      expect(policy.mimeTypes, <String>{'image/jpeg', 'application/pdf'});
    });

    test('unknown fields are ignored, not rejected', () {
      // API conventions §1. A server that starts publishing something new must
      // not break a released app.
      final policy = UploadPolicy.decode(<String, dynamic>{
        'max_bytes': 1024,
        'mime_types': <dynamic>['image/png'],
        'something_new': 'whatever',
      });

      expect(policy.source, UploadPolicySource.served);
    });

    test('a missing block falls back, labelled', () {
      expect(UploadPolicy.decode(null).source, UploadPolicySource.fallback);
      expect(
        UploadPolicy.decode(<String, dynamic>{}).source,
        UploadPolicySource.fallback,
      );
    });

    test('a half-present block falls back rather than being assembled', () {
      // A ceiling with no type list, or types with no ceiling, is not a policy
      // anybody published. Taking the half that arrived and inventing the rest
      // is how a client ends up enforcing a rule the server never stated.
      expect(
        UploadPolicy.decode(<String, dynamic>{'max_bytes': 5}).source,
        UploadPolicySource.fallback,
      );
      expect(
        UploadPolicy.decode(<String, dynamic>{
          'mime_types': <dynamic>['image/png'],
        }).source,
        UploadPolicySource.fallback,
      );
    });

    test('a nonsensical ceiling falls back', () {
      for (final Object? bytes in <Object?>[0, -1, '10', 10.5, null]) {
        expect(
          UploadPolicy.decode(<String, dynamic>{
            'max_bytes': bytes,
            'mime_types': <dynamic>['image/png'],
          }).source,
          UploadPolicySource.fallback,
          reason: 'max_bytes of $bytes should not be trusted',
        );
      }
    });

    test('an empty type list falls back', () {
      expect(
        UploadPolicy.decode(<String, dynamic>{
          'max_bytes': 1024,
          'mime_types': <dynamic>[],
        }).source,
        UploadPolicySource.fallback,
      );
    });

    test('the fallback is the lower of the two ceilings TAB 01 replaced', () {
      // 8 MB, not 10. Being conservative when uninformed costs a retry; being
      // permissive costs the upload and the resident's data.
      expect(UploadPolicy.fallback.maxBytes, 8 * 1024 * 1024);
      expect(UploadPolicy.fallback.source, UploadPolicySource.fallback);
    });
  });

  group('what a resident is told', () {
    test('the ceiling rounds down, so copy never promises more', () {
      expect(
        const UploadPolicy(
          maxBytes: 10 * 1024 * 1024,
          mimeTypes: <String>{'image/png'},
          source: UploadPolicySource.served,
        ).maxMegabytes,
        10,
      );

      // 10,000,000 bytes is 9.5 MB. A resident told "up to 10 MB" who sends a
      // 10 MB file would be refused by a server that never said 10.
      expect(
        const UploadPolicy(
          maxBytes: 10000000,
          mimeTypes: <String>{'image/png'},
          source: UploadPolicySource.served,
        ).maxMegabytes,
        9,
      );
    });

    test('picker extensions are derived from the served types', () {
      expect(
        const UploadPolicy(
          maxBytes: 1024,
          mimeTypes: <String>{'image/jpeg', 'application/pdf'},
          source: UploadPolicySource.served,
        ).pickerExtensions,
        <String>['jpeg', 'jpg', 'pdf'],
      );
    });

    test('a served type this build cannot map contributes no extension', () {
      // Rather than guessing one. An extension offered for a type the picker
      // cannot produce is a dead entry in a system dialog.
      expect(
        const UploadPolicy(
          maxBytes: 1024,
          mimeTypes: <String>{'image/heic'},
          source: UploadPolicySource.served,
        ).pickerExtensions,
        isEmpty,
      );
    });
  });

  group('there is only one of each, and this is what keeps it that way', () {
    /// Files on the upload path, other than `upload_policy.dart` itself.
    ///
    /// Scoped by what a file *talks about* rather than by where it sits. The
    /// alternative — every file under `lib/` — flags `asset_manifest.dart`,
    /// whose `maxBytes` is a budget for a bundled app asset and has nothing to
    /// do with what a resident may upload. Two different limits that happen to
    /// share a word, and a guard that cannot tell them apart is one somebody
    /// silences.
    ///
    /// A ceiling declared in a file that mentions none of these symbols cannot
    /// be enforcing an upload, because nothing there has a document to measure.
    Iterable<({String path, String source})> uploadPathFiles() sync* {
      const List<String> markers = <String>[
        'CapturedDocument',
        'UploadPolicy',
        'uploadRequirementDocument',
      ];

      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/documents/upload_policy.dart')) continue;

        final String source = entity.readAsStringSync();
        if (!markers.any(source.contains)) continue;

        yield (path: entity.path, source: source);
      }
    }

    test('the scan actually reaches the upload path', () {
      // A scope that matched nothing would make both guards below vacuous.
      expect(
        uploadPathFiles().map((f) => f.path),
        contains(endsWith('requirement_api_repository.dart')),
      );
    });

    test('no second upload ceiling is declared', () {
      // Catches a *declaration* whose name says ceiling and whose value is a
      // byte literal — which is what both of TAB 01's constants looked like.
      // A bare `1024 * 1024` used to convert bytes for display is not one, and
      // is deliberately not matched.
      final RegExp ceiling = RegExp(
        r'(?:static\s+)?(?:const|final)\s+int\s+\w*(?:[Mm]ax|[Cc]eiling|[Ll]imit)\w*'
        r'[Bb]ytes?\s*=\s*[^;]*\d',
      );

      final List<String> offenders = <String>[
        for (final file in uploadPathFiles())
          if (ceiling.hasMatch(file.source)) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'A second upload ceiling is declared in:\n  ${offenders.join('\n  ')}\n'
            'There was one of these before TAB 01 and it disagreed with the '
            'other by 2 MB, so a 9 MB PDF passed the first check and died at '
            'the second. The ceiling comes from the server, on the requirements '
            'response, and lives in UploadPolicy.',
      );
    });

    test('no second list of accepted types is declared', () {
      // A *collection* naming two or more accepted types. One type on its own
      // is dispatch — matching a signature, mapping an extension — and stays
      // legal.
      final RegExp collection = RegExp(
        r'<String>[\{\[][^\}\]]*'
        r"'(?:image/jpeg|image/png|application/pdf)'[^\}\]]*"
        r"'(?:image/jpeg|image/png|application/pdf)'",
      );

      final List<String> offenders = <String>[
        for (final file in uploadPathFiles())
          if (collection.hasMatch(file.source)) file.path,
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'A second list of accepted types is declared in:\n  ${offenders.join('\n  ')}\n'
            'The server publishes its own on the requirements response. A copy '
            'here is what lets the picker offer a type the upload then refuses.',
      );
    });
  });

  group('the refusal names real numbers, in both languages', () {
    // The rounding pair, asserted directly: the file rounds UP and the ceiling
    // rounds DOWN, so a refusal can never read "that file is 10 MB and the
    // limit is 10 MB" — a sentence a resident would reasonably retry unchanged.
    test('a file just over the line does not read as equal to it', () {
      const UploadPolicy tenMegabytes = UploadPolicy(
        maxBytes: 10 * 1024 * 1024,
        mimeTypes: <String>{'application/pdf'},
        source: UploadPolicySource.served,
      );

      // 10 MB + 1 byte.
      const int actual = 10 * 1024 * 1024 + 1;

      final int shown = (actual / (1024 * 1024)).ceil();
      expect(shown, 11);
      expect(tenMegabytes.maxMegabytes, 10);
      expect(
        shown,
        greaterThan(tenMegabytes.maxMegabytes),
        reason:
            'the refusal must not read as though the file were within the limit',
      );
    });

    test('both locales carry the two placeholders', () {
      // A translation that dropped a placeholder would render a sentence with a
      // number missing, which is worse than the untranslated original.
      for (final String path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_fil.arb',
      ]) {
        final String text = File(path).readAsStringSync();
        expect(
          text,
          contains('uploadRefusedTooLarge'),
          reason: '$path is missing the refusal copy',
        );

        final RegExp line = RegExp('"uploadRefusedTooLarge": "([^"]*)"');
        final RegExpMatch? match = line.firstMatch(text);
        expect(
          match,
          isNotNull,
          reason: '$path has no uploadRefusedTooLarge value',
        );

        final String copy = match!.group(1)!;
        expect(copy, contains('{actual}'), reason: '$path drops the file size');
        expect(copy, contains('{limit}'), reason: '$path drops the ceiling');
      }
    });

    test('every refusal reason has copy in both locales', () {
      const List<String> keys = <String>[
        'uploadRefusedTooLarge',
        'uploadRefusedType',
        'uploadRefusedEmpty',
        'uploadRefusedUnreadable',
        'uploadRefusedTitle',
      ];

      for (final String path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_fil.arb',
      ]) {
        final String text = File(path).readAsStringSync();
        for (final String key in keys) {
          expect(text, contains('"$key"'), reason: '$path is missing $key');
        }
      }
    });
  });
}
