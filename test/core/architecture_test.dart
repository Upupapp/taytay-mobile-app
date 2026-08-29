import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The four layering rules in CLAUDE.md Article 2, enforced rather than stated.
///
/// ## Why this exists
///
/// On 2026-08-29 a localiser for `InboxGroup` was written that made
/// `core/l10n/app_locales.dart` import
/// `features/notifications/presentation/notification_inbox_controller.dart`.
/// That is the violation Article 2.3 singles out, in the file that documents
/// the rule's one sanctioned exception. **Nothing failed.** It was caught by
/// reading the import list by eye, which is not a control.
///
/// Rules 1 and 2 turned out to be **clean on first measurement** — zero
/// violations — so they are enforced outright with no exception list. That is
/// worth saying, because a guard adopted with a long list of exemptions is
/// usually a guard that will never go red.
///
/// ## An open discrepancy this guard does NOT paper over
///
/// Article 2.3 says `core/` never imports `features/`, full stop, with
/// `app_router.dart` as the only exception. **The code has never obeyed that**:
/// thirteen imports cross from `core/` into `features/**/domain/`, and they are
/// not accidents — a localiser cannot translate an enum it may not name, and
/// `platform_controller` cannot drive a bootstrap contract it may not see.
/// Every one of them points at `domain/`, which is the layer with no Flutter
/// and no JSON in it, so none of them is the coupling the rule was written to
/// prevent.
///
/// So this file enforces the part that is absolute and was actually broken —
/// **`core/` must not reach a feature's `data/` or `presentation/`** — and
/// admits `core/ -> features/**/domain/` from a named list of files. It is
/// recorded here rather than quietly widened, because a test that redefines the
/// rule it claims to enforce is worse than no test.
///
/// **Somebody has to decide** whether Article 2.3 is amended to match the code
/// or the thirteen imports are removed. Until then this is a deviation held
/// still, not a settled design.
void main() {
  final List<File> dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String path(File f) => f.path.replaceAll(r'\', '/');

  /// Resolves a relative import to a repository path, or null if it is a
  /// package/dart import.
  String? resolve(File from, String import) {
    if (import.startsWith('package:') || import.startsWith('dart:')) {
      return null;
    }
    final base = Uri.file(path(from)).resolve(import).path;
    final index = base.indexOf('/lib/');
    return index == -1 ? base : base.substring(index + 1);
  }

  Iterable<String> importsOf(File f) => RegExp(
    r"^import '([^']+)';",
    multiLine: true,
  ).allMatches(f.readAsStringSync()).map((m) => m.group(1)!);

  test('the scan reads a real tree', () {
    // A walk that finds nothing proves nothing.
    expect(dartFiles.length, greaterThan(150));
    expect(
      dartFiles.expand(importsOf).length,
      greaterThan(300),
      reason: 'The import regex matched almost nothing; it is wrong.',
    );
  });

  test('Article 2.1 — domain imports neither data nor presentation', () {
    final offenders = <String>[];
    for (final file in dartFiles) {
      if (!path(file).contains('/domain/')) continue;
      for (final import in importsOf(file)) {
        final target = resolve(file, import);
        if (target == null) continue;
        if (target.contains('/data/') || target.contains('/presentation/')) {
          offenders.add('${path(file)}  ->  $target');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('Article 2.1 — domain does not import Flutter UI', () {
    // A domain file that imports material.dart has started making decisions
    // about how something looks.
    final offenders = <String>[];
    for (final file in dartFiles) {
      if (!path(file).contains('/domain/')) continue;
      for (final import in importsOf(file)) {
        if (import == 'package:flutter/material.dart' ||
            import == 'package:flutter/widgets.dart') {
          offenders.add('${path(file)}  ->  $import');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test("Article 2.2 — a feature never reaches another feature's data or "
      'presentation', () {
    final offenders = <String>[];
    final owner = RegExp(r'lib/features/([^/]+)/');
    for (final file in dartFiles) {
      final own = owner.firstMatch(path(file))?.group(1);
      if (own == null) continue;
      for (final import in importsOf(file)) {
        final target = resolve(file, import);
        if (target == null) continue;
        final match = RegExp(
          r'lib/features/([^/]+)/(data|presentation)/',
        ).firstMatch(target);
        if (match != null && match.group(1) != own) {
          offenders.add('${path(file)}  ->  $target');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('Article 2.3 — core never reaches a feature\'s data or presentation', () {
    // The absolute half of the rule, and the half that was actually broken.
    // `app_router.dart` is the sanctioned exception: binding routes to screens
    // is the whole reason it exists.
    final offenders = <String>[];
    for (final file in dartFiles) {
      final from = path(file);
      if (!from.startsWith('lib/core/')) continue;
      if (from.endsWith('core/router/app_router.dart')) continue;
      for (final import in importsOf(file)) {
        final target = resolve(file, import);
        if (target == null) continue;
        if (RegExp(
          r'lib/features/[^/]+/(data|presentation)/',
        ).hasMatch(target)) {
          offenders.add('$from  ->  $target');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'core/ reached into a feature\'s data or presentation layer. Move the '
          'type into core/, or publish it as a domain contract:\n'
          '${offenders.join('\n')}',
    );
  });

  test('Article 2.3 — only three core files reach feature domain at all', () {
    // The documented deviation, held still. New IMPORTS inside these files are
    // routine — every localiser needs the enum it translates. A new FILE in
    // this list is a decision somebody should make deliberately, which is the
    // granularity that makes this a ratchet rather than a rubber stamp.
    const Set<String> allowed = <String>{
      'lib/core/l10n/app_locales.dart',
      'lib/core/router/route_guard.dart',
      'lib/core/startup/platform_controller.dart',
    };

    final reaching = <String>{};
    for (final file in dartFiles) {
      final from = path(file);
      if (!from.startsWith('lib/core/')) continue;
      if (from.endsWith('core/router/app_router.dart')) continue;
      for (final import in importsOf(file)) {
        final target = resolve(file, import);
        if (target != null && target.startsWith('lib/features/')) {
          reaching.add(from);
        }
      }
    }

    expect(
      reaching.difference(allowed),
      isEmpty,
      reason:
          'A new core/ file reaches into features/. Article 2.3 forbids this '
          'outright; the three on the list are a recorded deviation, not a '
          'precedent: ${reaching.difference(allowed).join(', ')}',
    );
    expect(
      allowed.difference(reaching),
      isEmpty,
      reason:
          'These no longer reach into features/ — remove them from the list so '
          'it keeps shrinking: ${allowed.difference(reaching).join(', ')}',
    );
  });

  test('Article 2.4 — the wire format stops at the data layer', () {
    // `Map<String, dynamic>` above `data/` means the shape of the JSON has
    // escaped the only layer allowed to know it.
    const Map<String, String> decodeBoundaries = <String, String>{
      'lib/core/storage/keystore_session_store.dart':
          'Type-guards what this class itself wrote to the keystore. It is its '
          'own data layer; there is no repository beneath it.',
      'lib/core/documents/upload_policy.dart':
          'Type-guards the server-supplied `accepts` block before reading it. '
          'The map is inspected and discarded here, never carried upward.',
    };

    final offenders = <String>[];
    for (final file in dartFiles) {
      final from = path(file);
      if (from.contains('/data/')) continue;
      if (from.startsWith('lib/core/api/')) continue;
      if (from.startsWith('lib/l10n/')) continue;
      if (decodeBoundaries.containsKey(from)) continue;

      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (lines[i].contains('Map<String, dynamic>')) {
          offenders.add('$from:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'The wire format escaped the data layer:\n${offenders.join('\n')}',
    );
  });
}
