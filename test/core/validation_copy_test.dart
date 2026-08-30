import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A validation message this app composed must be translatable.
///
/// ## The rule, and why it can be stated precisely
///
/// `FieldError.message` carries two different things. Some of it is this app's
/// own prose. The rest is the server's validation text, which Article 5.5
/// deliberately lets through — a message shown beside the field it belongs to is
/// the one piece of server prose a resident may read, because only the server
/// knows what was wrong with a particular value.
///
/// Those two are distinguishable in the source without any type information: a
/// server message arrives in a variable, and this app's own is a **string
/// literal**. So the rule is exact — **a `FieldError` whose `message:` is a
/// literal must also carry a `kind:`** — and it needs none of the guesswork that
/// made the enum-copy scan unreliable.
///
/// ## Why this guard exists separately
///
/// `resident_copy_localisation_test.dart` classifies enums that hold copy. It is
/// blind to this entirely: a sentence written inline in a validation function is
/// not enum copy, and eighteen of them were sitting in `domain/` and controller
/// code while that guard reported the problem as "eight enums". Reporting one
/// class of a problem as the whole of it is how the count looked smaller than it
/// was.
void main() {
  /// Every `FieldError(...)` invocation in `lib/`, with its file and line.
  Iterable<({String file, int line, String body})> fieldErrors() sync* {
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String source = entity.readAsStringSync();
      if (!source.contains('FieldError(')) continue;

      for (final Match m in 'FieldError('.allMatches(source)) {
        final int open = source.indexOf('(', m.start + 'FieldError'.length - 1);
        if (open < 0) continue;

        // Balanced, because an argument list contains its own parentheses.
        int depth = 0;
        int i = open;
        for (; i < source.length; i++) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') {
            depth--;
            if (depth == 0) break;
          }
        }

        yield (
          file: entity.path,
          line: '\n'.allMatches(source.substring(0, m.start)).length + 1,
          body: source.substring(open, i + 1),
        );
      }
    }
  }

  /// Literal messages that predate the rule, with where they render.
  ///
  /// **A ceiling that only shrinks.** Fourteen of these are behind TAB 03's gate
  /// — `route_guard.dart` redirects `/register` to sign-in while onboarding is
  /// staff-mediated, so no resident reaches the registration wizard. Four are
  /// live: a resident can register for an event today and meet every one of
  /// them in English.
  ///
  /// The split matters more than the total. Translating the gated fourteen would
  /// be a TAB spent on a screen nobody can open, which is the mistake TAB 04
  /// made on the correction flow.
  const Map<String, int> knownLiteralErrors = <String, int>{
    // GATED — the registration wizard is unreachable (TAB 03 / F15). These are
    // the whole of the remaining debt, and none of it is reachable today.
    'lib/features/registration/domain/registration_validation.dart': 14,
    //
    // event_registration_controller.dart was 4 and is now 0 — localised once
    // this guard established that it was the only LIVE file in the list. It is
    // deliberately not left here at zero: an entry that has been paid is noise,
    // and the map should read as the debt that remains.
  };

  test('the scan finds FieldError constructions at all', () {
    expect(
      fieldErrors().length,
      greaterThanOrEqualTo(25),
      reason: 'the scan has stopped matching; fix it, do not lower this',
    );
  });

  test('a literal validation message carries a kind, or is a known exception', () {
    final Map<String, List<int>> offenders = <String, List<int>>{};

    for (final e in fieldErrors()) {
      final bool literal = RegExp(r"message:\s*'").hasMatch(e.body);
      if (!literal) continue; // the server's own text, shown as sent
      if (e.body.contains('kind:')) continue; // translatable

      offenders.putIfAbsent(e.file, () => <int>[]).add(e.line);
    }

    // EVERY FILE IN EITHER MAP, not just the ones with offenders.
    //
    // The first version of this iterated `offenders` alone, so a file dropping
    // to zero was never compared against its ceiling and the guard passed
    // silently — while its own comment claimed the list "only shrinks". It was
    // caught on the first localisation that lowered a count, which is the only
    // reason it did not sit here claiming a property it did not have.
    final Set<String> files = <String>{
      ...offenders.keys,
      ...knownLiteralErrors.keys,
    };

    final List<String> unexpected = <String>[
      for (final String file in files)
        if ((offenders[file]?.length ?? 0) != (knownLiteralErrors[file] ?? 0))
          '$file: ${offenders[file]?.length ?? 0} literal errors without a kind '
              '(recorded ${knownLiteralErrors[file] ?? 0})'
              '${offenders[file] == null ? '' : ' at lines ${offenders[file]!.join(', ')}'}',
    ];

    expect(
      unexpected,
      isEmpty,
      reason:
          'A validation message this app composed cannot be translated:\n'
          '  ${unexpected.join('\n  ')}\n'
          'Give it a ValidationMessage kind and copy in both locales. If a count '
          'went DOWN, lower it here — this list only shrinks.',
    );
  });

  test('nothing reachable is left untranslated', () {
    // The finding this guard was built to produce, and now its result.
    //
    // It began as eighteen literal messages across two files. The enum guard had
    // reported the problem as "eight enums" and could not see any of these. Of
    // the eighteen, fourteen sit behind TAB 03's gate and four were live — and
    // the four are done.
    //
    // So: every validation message a resident can currently reach is
    // translatable, and the remainder is gated. If the wizard is ever
    // un-gated — the LGU answers F15 — those fourteen become live and this
    // assertion is where somebody should be reminded.
    expect(
      knownLiteralErrors.keys,
      <String>['lib/features/registration/domain/registration_validation.dart'],
      reason:
          'the only remaining untranslated validation messages should be the '
          'gated registration wizard; anything else here is reachable debt',
    );
    expect(knownLiteralErrors.values.single, 14);
  });
}
