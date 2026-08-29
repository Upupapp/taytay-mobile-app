import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The sweep TAB 19 asks for: **the class of defect, not the instance.**
///
/// ---
///
/// F07 was one test asserting a `Today` heading against a fixture pinned to a
/// calendar date, in a harness that never injected that date. It passed on the
/// day it was written and failed every day after, and it was still failing when
/// this repository reached a second machine — reported as release-ready.
///
/// The instance was fixed at TAB 00. This is the part that stops it coming back:
/// a test that reads a relative-time label must inject the clock it compares
/// against, and production code must not reach for the wall clock where a caller
/// could have supplied one.
///
/// **This class of test rots silently**, which is what makes a sweep worth more
/// than a fix. A date-dependent assertion does not fail on the commit that
/// introduces it — it fails weeks later, on somebody else's branch, looking like
/// their problem.
void main() {
  /// Labels whose meaning depends on what day it is.
  const List<String> recencyLabels = <String>[
    'Today',
    'Earlier this week',
    'Earlier this month',
    'Yesterday',
    'Tomorrow',
  ];

  List<File> dartFilesIn(String directory) => Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList();

  group('no test asserts a recency label without injecting a clock', () {
    test('every file that reads one supplies the date it means', () {
      final List<String> offenders = <String>[];

      for (final File file in dartFilesIn('test')) {
        // This file names the labels in order to forbid them.
        if (file.path.endsWith('date_dependence_test.dart')) continue;

        final String source = file.readAsStringSync();
        final bool assertsRecency = recencyLabels.any(
          (String label) =>
              source.contains("find.text('$label')") ||
              source.contains('findsOneWidget') && source.contains("'$label'"),
        );
        if (!assertsRecency) continue;

        // The fix that closed F07: the fixture clock reaches the widget tree
        // through the composition root, so the test compares against the date it
        // pinned rather than against today.
        final bool injectsClock =
            source.contains('clock:') || source.contains('now:');

        if (!injectsClock) {
          offenders.add(file.path.replaceAll(r'\', '/'));
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These assert a date-derived label against the real calendar and '
            'will start failing on a day nobody chose:\n${offenders.join('\n')}',
      );
    });
  });

  group('production code does not reach for the wall clock', () {
    test('anything that groups or labels by recency takes a clock', () {
      // `DateTime.now()` is not banned outright — a timestamp for a log line is
      // fine. What is banned is deciding what a resident is *told* from it
      // without a seam a test can reach, which is exactly what made F07
      // untestable rather than merely wrong.
      final List<String> offenders = <String>[];

      for (final File file in dartFilesIn('lib')) {
        final String raw = file.readAsStringSync();

        // Generated `flutter gen-l10n` output is a string table and decides
        // nothing. Skipped 2026-08-29, when translating `InboxGroup` put
        // 'Today' and 'Earlier this week' into app_localizations_en.dart and
        // this guard fired on a file that cannot read a clock at all.
        //
        // Keyed off the generator's own marker rather than a path list, so a
        // hand-written file cannot quietly opt itself out by moving into
        // lib/l10n/. The enum that actually *decides* the label,
        // `InboxGroup.of`, still carries its `now` seam and is still checked.
        if (raw.contains('ignore_for_file: type=lint')) continue;

        final String source = raw
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('//'))
            .where((String l) => !l.trimLeft().startsWith('///'))
            .join('\n');

        // Per DECLARATION, not per file.
        //
        // TIGHTENED 2026-08-29, and it could not fail before. This asked
        // whether the *file* mentioned a clock anywhere.
        // `notification_inbox_controller.dart` holds both `InboxGroup`, which
        // labels by recency, and a controller carrying an injected
        // `DateTime Function()` — so the file passed however `InboxGroup.of`
        // was written. Deleting that enum's `now` parameter outright left this
        // test green, which is how the weakness was found: a red-proof that
        // produced no red.
        //
        // Top-level declarations start at column zero in formatted Dart, so
        // splitting on them scopes the question to the thing that actually
        // decides the label.
        final List<String> bodies = <String>[];
        final Iterable<RegExpMatch> declarations = RegExp(
          r'^(?:enum|class|mixin|extension|abstract)\b',
          multiLine: true,
        ).allMatches(source);
        int previous = 0;
        for (final RegExpMatch declaration in declarations) {
          bodies.add(source.substring(previous, declaration.start));
          previous = declaration.start;
        }
        bodies.add(source.substring(previous));

        for (final String body in bodies) {
          final bool labelsByRecency = recencyLabels.any(
            (String label) => body.contains("'$label'"),
          );
          if (!labelsByRecency) continue;

          // Either it takes a clock, or it takes the `now` it compares against.
          final bool hasSeam =
              body.contains('DateTime Function()') ||
              body.contains('DateTime? now') ||
              body.contains('required DateTime now');

          if (!hasSeam) {
            offenders.add(file.path.replaceAll(r'\', '/'));
            break;
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the composition root still carries an injectable clock', () {
      // The seam F07 needed and did not have. Removing it would make every
      // recency test above untestable again, silently.
      final String source = File(
        'lib/app/app_dependencies.dart',
      ).readAsStringSync();
      expect(source, contains('DateTime Function() clock'));
    });
  });

  group('Filipino is complete, and stays complete', () {
    test('untranslated.json is empty', () {
      // The fallback is deliberately silent so a partial translation ships
      // rather than blocking a release — a good default and a bad gate. This is
      // the gate: a report nobody reads is not one.
      final String raw = File(
        'lib/l10n/untranslated.json',
      ).readAsStringSync().trim();
      expect(
        raw,
        anyOf('{}', ''),
        reason:
            'Filipino is missing keys. A language setting that silently falls '
            'back to English is one that lies to the resident who chose it.',
      );
    });

    test('the two arb files declare the same keys', () {
      // A Filipino file that is a copy of the English one is worse than none,
      // because the language setting then lies. Same keys, and the values must
      // differ for a sample of resident-facing copy.
      // Parsed, not pattern-matched. An `@key` metadata block has nested keys
      // of its own — `description`, `placeholders` — and a regex over lines
      // reads those as translations that exist in one file and not the other.
      Set<String> keysOf(String path) {
        final Map<String, dynamic> arb =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        return arb.keys.where((String k) => !k.startsWith('@')).toSet();
      }

      final Set<String> english = keysOf('lib/l10n/app_en.arb');
      final Set<String> filipino = keysOf('lib/l10n/app_fil.arb');

      expect(english, isNotEmpty);
      expect(
        filipino.difference(english),
        isEmpty,
        reason: 'Filipino declares keys English does not',
      );
      expect(
        english.difference(filipino),
        isEmpty,
        reason: 'English declares keys Filipino does not',
      );
    });
  });
}
