import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Redesign Phase 5: feature code draws with the theme, never with literals.
///
/// `docs/design/DESIGN_SYSTEM.md` ("Rules") and CLAUDE.md Article 6 say that
/// every colour, type size, radius and shadow decision is made once, in
/// `lib/core/design/` (the tokens and the theme) or in a shared widget in
/// `lib/shared/widgets/`. Everything else in `lib/` — every feature, `app/`,
/// the rest of `core/` — reads `BrandColors`, `AppTypography`, `Radii`,
/// `ComponentSizes` and the shared widgets. A literal in a feature is a second
/// source of truth that a token change cannot reach, which is how one screen
/// quietly keeps the old look after a redesign.
///
/// The scan reads source text. A line that is only a comment is ignored, so a
/// doc comment may name a rule; code on any line is read, across line breaks.
void main() {
  group('feature code uses design tokens', () {
    final List<File> files = _scannedFiles();

    test('the scan reads the feature tree, not an empty directory', () {
      final Set<String> paths = files.map(_path).toSet();
      expect(files.length, greaterThan(150));
      expect(
        paths,
        contains('lib/features/home/presentation/home_canvas.dart'),
      );
      expect(paths, contains('lib/app/taytay_resident_app.dart'));
      expect(
        paths.where(
          (String path) =>
              path.startsWith('lib/core/design/') ||
              path.startsWith('lib/shared/widgets/'),
        ),
        isEmpty,
      );
    });

    for (final _Rule rule in _rules) {
      test(
        'no ${rule.name} outside lib/core/design and lib/shared/widgets',
        () {
          final List<String> found = <String>[];
          for (final File file in files) {
            for (final _Finding finding in rule.scan(file.readAsStringSync())) {
              final String where = '${_path(file)}:${finding.line}';
              if (_allowed[where] != null) continue;
              found.add('$where: ${finding.text} — ${rule.advice}');
            }
          }
          expect(
            found,
            isEmpty,
            reason:
                'Feature code hard-codes ${rule.name}:\n${found.join('\n')}\n'
                'See docs/design/DESIGN_SYSTEM.md, "Rules".',
          );
        },
      );
    }

    test('every allow-list entry has a reason and still matches', () {
      for (final MapEntry<String, String> entry in _allowed.entries) {
        expect(
          entry.value.trim(),
          isNotEmpty,
          reason: '${entry.key} is allowed without a written reason.',
        );
        final int colon = entry.key.lastIndexOf(':');
        final File file = File(entry.key.substring(0, colon));
        final int line = int.parse(entry.key.substring(colon + 1));
        final String source = file.existsSync() ? file.readAsStringSync() : '';
        expect(
          _rules.any(
            (_Rule rule) =>
                rule.scan(source).any((_Finding f) => f.line == line),
          ),
          isTrue,
          reason: '${entry.key} is allowed but no longer matches: remove it.',
        );
      }
    });
  });

  group('popups open through AppDialog and AppSheet (rule 3)', () {
    // DESIGN_SYSTEM.md §8 rule 3 (D-197, D-202): every gate, notice,
    // confirmation and decision is a centred `AppDialog`; only a picker is a
    // sheet, through `AppSheet`. A direct `showDialog` or
    // `showModalBottomSheet` is how a one-off frame, colour, radius or a
    // sheet that explains something comes back. Only the two wrappers call
    // the framework's routes.
    final List<File> files = _dartFiles()
        .where((File file) => !_popupWrappers.contains(_path(file)))
        .toList();

    test('the scan reads the whole app but the two wrappers', () {
      final Set<String> paths = files.map(_path).toSet();
      expect(files.length, greaterThan(200));
      expect(paths, contains('lib/shared/widgets/access_gate_sheet.dart'));
      expect(
        paths,
        contains('lib/features/home/presentation/home_canvas.dart'),
      );
      expect(paths.intersection(_popupWrappers), isEmpty);
      for (final String wrapper in _popupWrappers) {
        expect(
          _popupRule.scan(File(wrapper).readAsStringSync()),
          isNotEmpty,
          reason: '$wrapper no longer opens the route it wraps',
        );
      }
    });

    test('nothing else calls showDialog, showModalBottomSheet or '
        'showGeneralDialog', () {
      final List<String> found = <String>[
        for (final File file in files)
          for (final _Finding finding in _popupRule.scan(
            file.readAsStringSync(),
          ))
            '${_path(file)}:${finding.line}: ${finding.text} — '
                '${_popupRule.advice}',
      ];
      expect(
        found,
        isEmpty,
        reason:
            'A popup bypasses AppDialog / AppSheet:\n${found.join('\n')}\n'
            'See docs/design/DESIGN_SYSTEM.md §8 rule 3.',
      );
    });

    const Map<String, String> plantedPopups = <String, String>{
      'showDialog': 'await showDialog<void>(context: c, builder: b);',
      'showDialog across a line break': 'return showDialog\n    <Barangay>(',
      'showModalBottomSheet': 'showModalBottomSheet(context: c, builder: b)',
      'showGeneralDialog': 'showGeneralDialog<void>(context: c)',
      'showCupertinoDialog': 'showCupertinoDialog(context: c, builder: b)',
      'showCupertinoModalPopup': 'showCupertinoModalPopup<int>(context: c)',
    };
    for (final MapEntry<String, String> entry in plantedPopups.entries) {
      test('finds a planted ${entry.key}', () {
        expect(_popupRule.scan(entry.value), hasLength(1), reason: entry.value);
      });
    }

    test('passes the wrappers, other show* helpers and comments', () {
      const String clean = '''
// A comment may say showDialog(context: c) or showModalBottomSheet<T>(.
/// So may a doc comment: `showGeneralDialog(`.
await AppDialog.show<void>(context: c, title: t, builder: b);
await AppSheet.show<String>(context: c, title: t, builder: b);
await showResubmitMessageDialog(context);
await showBarangayPicker(context, load: load);
await showLegalTextSheet(context, title: t, markdown: m, pending: p);
await showDatePicker(context: c, firstDate: a, lastDate: b);
_showDialogLater();
''';
      expect(_popupRule.scan(clean), isEmpty);
    });
  });

  group('the scanner itself', () {
    // Each rule is proved against a planted line, so a green run above means
    // "nothing was found", not "the pattern could not find anything".
    const Map<String, String> planted = <String, String>{
      'a hex colour': 'final c = Color(0xFF0A2071);',
      'a hex colour across a line break': 'final c = Color(\n  0xFF0A2071,\n);',
      'a component colour': 'final c = Color.fromARGB(255, 10, 32, 113);',
      'a raw font size': 'style: TextStyle(fontSize: 13.5),',
      'a raw font size on the next line': 'TextStyle(\n  fontSize:\n    14,\n)',
      'a box shadow': 'boxShadow: <BoxShadow>[],',
      'an elevation': 'Material(elevation: 2, child: x)',
      'a literal circular radius': 'BorderRadius.circular(12)',
      'a literal radius': 'Radius.circular(8.5)',
    };
    for (final MapEntry<String, String> entry in planted.entries) {
      test('finds ${entry.key}', () {
        final int hits = _rules.fold<int>(
          0,
          (int sum, _Rule rule) => sum + rule.scan(entry.value).length,
        );
        expect(hits, 1, reason: entry.value);
      });
    }

    test('reports the line the literal is on', () {
      final List<_Finding> found = _rules
          .expand((_Rule rule) => rule.scan('a\nb\nfinal c = Color(0x1);\n'))
          .toList();
      expect(found.single.line, 3);
    });

    test('passes tokens, zero elevation and comment-only lines', () {
      const String clean = '''
// A comment may say Color(0xFF000000), fontSize: 12 or BoxShadow.
/// So may a doc comment: BorderRadius.circular(12).
final c = BrandColors.blue;
final s = AppTypography.bodyStyle.copyWith(fontSize: AppTypography.minFontSize);
final r = BorderRadius.circular(Radii.card);
final q = Radius.circular(Radii.sheetLarge);
const m = Material(elevation: 0, child: x);
const n = Material(elevation: Elevation.none, child: x);
''';
      final List<_Finding> found = _rules
          .expand((_Rule rule) => rule.scan(clean))
          .toList();
      expect(found, isEmpty, reason: found.map((f) => f.text).join('\n'));
    });
  });
}

/// Literals that are allowed in feature code, keyed `path:line`, each with
/// the reason it cannot be a token. Empty: the tree passed without one when
/// the guard was added, after Phase 4's sweep. An entry without a reason, or
/// one that no longer matches, fails the build.
const Map<String, String> _allowed = <String, String>{};

const List<_Rule> _rules = <_Rule>[
  _Rule(
    name: 'colours',
    pattern:
        r'\bColor\s*\(\s*0[xX][0-9A-Fa-f]*\s*\)?'
        r'|\bColor\s*\.\s*from(?:ARGB|RGBO)\s*\(',
    advice: 'use a BrandColors token or the ColorScheme',
  ),
  _Rule(
    name: 'font sizes',
    pattern: r'\bfontSize\s*:\s*-?(?:\d+(?:\.\d+)?|\.\d+)',
    advice: 'use an AppTypography role',
  ),
  _Rule(
    name: 'shadows',
    pattern: r'\bBoxShadow\b|\belevation\s*:\s*(?:0*[1-9]|0*\.\d*[1-9])',
    advice: 'the redesign draws no shadows (Elevation.* is 0)',
  ),
  _Rule(
    name: 'radii',
    pattern:
        r'\b(?:BorderRadius|Radius)\s*\.\s*circular\s*\('
        r'\s*-?(?:\d+(?:\.\d+)?|\.\d+)\s*\)?',
    advice: 'use a Radii token',
  ),
];

class _Rule {
  const _Rule({
    required this.name,
    required this.pattern,
    required this.advice,
  });

  final String name;
  final String pattern;
  final String advice;

  /// Every match in [source], with its 1-based line. Lines that are only a
  /// comment are blanked first, keeping the line count, so a match's line is
  /// the line in the file.
  List<_Finding> scan(String source) {
    final String code = source
        .split('\n')
        .map((String line) => line.trimLeft().startsWith('//') ? '' : line)
        .join('\n');
    return RegExp(pattern).allMatches(code).map((RegExpMatch match) {
      final int line = '\n'.allMatches(code.substring(0, match.start)).length;
      final String text = code
          .substring(match.start, match.end)
          .replaceAll(RegExp(r'\s+'), ' ');
      return _Finding(line + 1, text);
    }).toList();
  }
}

class _Finding {
  const _Finding(this.line, this.text);

  final int line;
  final String text;
}

/// The two wrappers that may open the framework's popup routes.
const Set<String> _popupWrappers = <String>{
  'lib/shared/widgets/app_dialog.dart',
  'lib/shared/widgets/app_sheet.dart',
};

/// A call to one of the framework's popup routes, generic or not, across a
/// line break. `AppDialog.show`, `showDatePicker` (a picker the theme
/// centres) and the app's own `show…` helpers do not match.
const _Rule _popupRule = _Rule(
  name: 'popup routes',
  pattern:
      r'\bshow(?:Dialog|ModalBottomSheet|GeneralDialog|CupertinoDialog'
      r'|CupertinoModalPopup)\b\s*[<(]',
  advice:
      'open a gate, notice, confirmation or decision with AppDialog.show '
      '(or confirm / acknowledge), and a picker with AppSheet.show',
);

/// Every Dart file in `lib/`.
List<File> _dartFiles() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((File a, File b) => _path(a).compareTo(_path(b)));
}

/// Every Dart file in `lib/` outside the two places tokens are defined.
List<File> _scannedFiles() {
  return _dartFiles().where((File file) {
    final String path = _path(file);
    return !path.startsWith('lib/core/design/') &&
        !path.startsWith('lib/shared/widgets/');
  }).toList();
}

String _path(File file) => file.path.replaceAll(r'\', '/');
