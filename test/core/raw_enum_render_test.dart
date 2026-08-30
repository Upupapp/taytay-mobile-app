import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No screen renders a localised enum's English constant directly.
///
/// ## The third blind spot
///
/// Two guards already watch resident-facing enum copy and neither can see this
/// one:
///
///  * `resident_copy_localisation_test.dart` asks whether every copy-bearing
///    enum is **classified**. It is satisfied the moment an enum has a
///    localiser — it never looks at whether the screens use it.
///  * `accessibility_and_locale_test.dart` asks whether every `.arb` key is
///    **translated**. A perfectly translated key helps nobody if the widget
///    reads the enum constant instead.
///
/// So an enum could be correctly classified, correctly localised, fully
/// translated — and still render in English. That is not hypothetical: it was
/// the state of `home_sections.dart:406` for the whole programme.
/// `verificationStageCopy` existed, the verification screen used it, and the
/// home screen's next-action card rendered `s.label` and `s.summary` raw, on
/// the first card a resident sees after signing in.
///
/// The first run of this file found **four** such sites, three of them unknown:
/// `home_sections.dart:406-407`, `profile_screen.dart:369` and
/// `verification_screen.dart:558`. The profile one sat a single line below an
/// edit made the day before — the subtitle was localised and the title was not.
///
/// ## What this guard can and cannot see
///
/// Stated plainly, because three checks in this suite have now turned out to
/// promise more than their bodies delivered.
///
/// **It sees:** a copy field read from a variable whose type is written down as
/// a localised enum (`final ResidentVerificationStage s`, a typed parameter, a
/// typed pattern match), and a constant accessed directly
/// (`DocumentSource.camera.label`).
///
/// **It does not see:** a copy field read from a variable whose type is
/// inferred. `final stage = _status?.stage;` followed by `stage.nextActionLabel`
/// is invisible here — a Dart test has no type information, and guessing from
/// names is what produced the discarded thirty-file scan described in
/// `resident_copy_localisation_test.dart`. Closing that would need the analyzer
/// package and a custom lint. Until then this is a floor, not a ceiling: it
/// proves the sites it can see are clean, and proves nothing about the rest.
void main() {
  /// Enums with a localiser. A raw copy-field read on one of these is a bug.
  const Set<String> localisedEnums = <String>{
    'ShellDestination',
    'ResidentProfileField',
    'FieldOwnership',
    'ResidentVerificationStage',
    'KycDocumentType',
    'DocumentRejection',
    'ResidentCapability',
    'ResidentIntentKind',
    'DocumentSource',
    // ADDED 2026-08-30, and they should have been here hours earlier. All six
    // were localised the same day and added to `localised` in
    // `resident_copy_localisation_test.dart` — and not here, so this guard was
    // watching NINE OF FIFTEEN enums while reporting clean. Nothing noticed
    // until `tool/check_typed_renders.dart` arrived with its own copy of the
    // list and the two were compared. A guard that silently narrows is worse
    // than one that was never written, because its green is believed.
    'ServiceCategory',
    'HouseholdCorrectionKind',
    'HouseholdRole',
    'ReportReason',
    'NotificationCategory',
    'InboxGroup',
  };

  /// Field names that hold copy a resident could read.
  ///
  /// `nextActionLabel` is here because it was missing from the equivalent list
  /// in `resident_copy_localisation_test.dart`, which is why a button label
  /// rendered untranslated on two screens with no guard objecting.
  const Set<String> copyFields = <String>{
    'label',
    'title',
    'description',
    'summary',
    'explanation',
    'sectionTitle',
    'sectionExplanation',
    'residentMessage',
    'hint',
    'instruction',
    'nextActionLabel',
  };

  /// Files allowed to read the raw constant. This list may only ever shrink.
  ///
  /// `app_locales.dart` is the localiser itself and `resident_capability.dart`
  /// and friends are the declarations, so none of them are screens.
  bool isScreen(String path) =>
      path.contains('/presentation/') || path.startsWith('lib/shared/');

  /// Comments are not renders.
  ///
  /// The first version of this scan flagged its own explanatory comment, which
  /// named `s.label` while describing the bug it had just fixed. Blanking
  /// comments rather than rewording the prose keeps the guard honest about what
  /// counts as a render — and newlines are preserved so line numbers stay true.
  String withoutComments(String source) => source
      .replaceAllMapped(
        RegExp(r'/\*.*?\*/', dotAll: true),
        (m) => '\n' * '\n'.allMatches(m.group(0)!).length,
      )
      .replaceAll(RegExp(r'//[^\n]*'), '');

  List<({String file, int line, String expression})> rawRenders() {
    final found = <({String file, int line, String expression})>[];
    final fields = copyFields.join('|');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (!isScreen(path)) continue;
      final source = withoutComments(entity.readAsStringSync());

      for (final enumName in localisedEnums) {
        if (!source.contains(enumName)) continue;

        // Variables whose type is written down: declarations, parameters and
        // typed pattern matches all take the form `EnumName[?] identifier`.
        final names = RegExp('\\b$enumName\\??\\s+(\\w+)\\b')
            .allMatches(source)
            .map((m) => m.group(1)!)
            .where((n) => n != 'values')
            .toSet();

        for (final name in names) {
          for (final m in RegExp(
            '\\b$name\\??\\.($fields)\\b',
          ).allMatches(source)) {
            found.add((
              file: path,
              line: '\n'.allMatches(source.substring(0, m.start)).length + 1,
              expression: m.group(0)!,
            ));
          }
        }

        // `EnumName.constant.label`
        for (final m in RegExp(
          '\\b$enumName\\.\\w+\\.($fields)\\b',
        ).allMatches(source)) {
          found.add((
            file: path,
            line: '\n'.allMatches(source.substring(0, m.start)).length + 1,
            expression: m.group(0)!,
          ));
        }
      }
    }
    return found;
  }

  test('the scan reaches screen files at all', () {
    // A scan that reads nothing reports nothing and passes everything.
    final screens = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && isScreen(f.path))
        .length;
    expect(
      screens,
      greaterThan(40),
      reason: 'Only $screens screen files were scanned; the filter is wrong.',
    );
  });

  test('the scan can still recognise a raw render', () {
    // Proves the matcher works, independently of the codebase being clean —
    // otherwise a broken regex and a clean repo look identical.
    const sample = 'final ResidentVerificationStage s = x;\nText(s.label);';
    final names = RegExp(
      r'\bResidentVerificationStage\??\s+(\w+)\b',
    ).allMatches(sample).map((m) => m.group(1)!).toSet();
    expect(names, contains('s'));
    expect(RegExp(r'\bs\??\.(label)\b').hasMatch(sample), isTrue);
  });

  test('the three copy-field lists have not drifted apart', () {
    // `copyFields` exists in THREE places: here, in
    // resident_copy_localisation_test.dart, and in
    // tool/check_typed_renders.dart. None can import the others — one is a
    // tool run under `dart run`, and tests do not export.
    //
    // They are identical today and nothing kept them that way. That is exactly
    // the state `localisedEnums` was in on 2026-08-30, when this guard turned
    // out to be watching nine of fifteen enums while reporting clean. A list
    // that can silently narrow will.
    Set<String> listIn(String path, String marker) {
      final String source = File(path).readAsStringSync();
      final int start = source.indexOf(marker);
      expect(
        start,
        isNot(-1),
        reason: '$marker no longer appears in $path — this check is blind.',
      );
      final String block = source.substring(start, source.indexOf('};', start));
      return RegExp(
        r"'(\w+)'",
      ).allMatches(block).map((RegExpMatch m) => m.group(1)!).toSet();
    }

    const String marker = 'const Set<String> copyFields';
    final Set<String> classifier = listIn(
      'test/core/resident_copy_localisation_test.dart',
      marker,
    );
    final Set<String> typed = listIn('tool/check_typed_renders.dart', marker);

    expect(classifier, copyFields, reason: 'classification guard has drifted');
    expect(typed, copyFields, reason: 'typed guard has drifted');
  });

  test('the typed guard watches the same enums this file does', () {
    // `tool/check_typed_renders.dart` keeps its own copy of the localised-enum
    // list, because it runs under `dart run` and cannot import a test. Two
    // hand-maintained lists of the same thing is how one of them goes stale and
    // quietly starts watching less than its name says — so they are compared
    // here rather than trusted to stay in step.
    final String typed = File(
      'tool/check_typed_renders.dart',
    ).readAsStringSync();
    final String block = typed.substring(
      typed.indexOf('const Set<String> localisedEnums'),
      typed.indexOf('};', typed.indexOf('const Set<String> localisedEnums')),
    );
    final Set<String> theirs = RegExp(
      r"'(\w+)'",
    ).allMatches(block).map((RegExpMatch m) => m.group(1)!).toSet();

    expect(
      theirs,
      localisedEnums,
      reason:
          'tool/check_typed_renders.dart and this file disagree about which '
          'enums are localised. The type-aware guard is the one with real type '
          'information; a stale list there is the more expensive mistake.',
    );
  });

  test('no screen renders a wire value as copy', () {
    // A different shape of the same defect, and the one that actually shipped.
    // `services_screen.dart` passed `service.category.raw` to the category tag
    // and `category.wireValue` to the filter chips, so residents read the
    // backend's own codes — `dokumento`, `buwis`, `ids`, `national` — where a
    // name belongs. Four of six are Filipino words by coincidence, which is how
    // it survived: it looked like copy on a Filipino device.
    //
    // `wireValue` and `raw` are correct everywhere else — they are what the API
    // is called with. What is banned is one reaching a Text or a label.
    final offenders = <String>[];
    final pattern = RegExp(
      r'(Text\(|label: *(Text\()?)[A-Za-z_.!\[\]]*\.(wireValue|raw)\b',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!isScreen(entity.path)) continue;
      final source = withoutComments(entity.readAsStringSync());
      for (final m in pattern.allMatches(source)) {
        offenders.add(
          '${entity.path}:'
          '${'\n'.allMatches(source.substring(0, m.start)).length + 1}  '
          '${m.group(0)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These render a server wire value as resident-facing copy. The wire '
          'value names a thing to the API, not to a person:\n'
          '${offenders.join('\n')}',
    );
  });

  test('no screen renders a localised enum constant directly', () {
    final offenders = rawRenders();
    expect(
      offenders.map((o) => '${o.file}:${o.line}  ${o.expression}').toList(),
      isEmpty,
      reason:
          'These read a localised enum\'s English constant instead of calling '
          'its localiser. The constant is the no-context fallback; a screen has '
          'a BuildContext and must use it.',
    );
  });
}
