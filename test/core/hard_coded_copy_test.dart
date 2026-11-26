import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No new English sentence is typed into a screen (D-237).
///
/// ## Why
///
/// A resident who set her phone to Filipino read English on about a third of
/// the app until D-237: error messages, document-request statuses, buttons,
/// whole screens. Not because anybody decided they should stay English, but
/// because a literal in a widget compiles, renders and passes every test in
/// English, and nothing asked. `resident_copy_localisation_test.dart` asks
/// about enums; this asks about every quoted sentence on the screen side —
/// `features/*/presentation/`, `shared/` and `app/`.
///
/// ## How it counts
///
/// A literal counts when, with its `$interpolations` taken out, it has two
/// words in a row (`"Try again"`) or is one capitalised word (`"Verified"`).
/// Comment lines, raw strings, and lines that build a key, an assert, a
/// `FlutterError`, a `throw`, a `RegExp` or debug text are skipped: those are
/// for developers. `properNames` are the same words in both languages.
///
/// ## Why a ceiling per file rather than zero
///
/// What is left is deliberate and recorded in D-237: the English **no-context
/// fallbacks** that the house pattern keeps beside each localiser
/// (`AccountCopy`, `SectorsCopy`, `BiometricConsentCopy`… — tests and code
/// with no `BuildContext` read them), the test-only design specimens, the
/// printed face of the digital ID, the dev-only settings row, and assert text
/// on a following line. Listing each sentence would make a second copy of the
/// app's English; counting them per file holds the line just as well.
///
/// The count must **equal** the ceiling. Above it, a sentence was typed into
/// a screen: put it in `lib/l10n/app_en.arb` and `app_fil.arb` and read it
/// through `AppStrings`. Below it, somebody moved one: lower the number here,
/// so it cannot quietly come back.
void main() {
  /// Words that read the same to a Filipino- and an English-language reader:
  /// the municipality's and the app's own names, the document titles the office
  /// publishes under, and an ID's official name. Keep this short; a sentence
  /// is never a proper name.
  const Set<String> properNames = <String>{
    'Taytay',
    'Taytay LGU',
    'Taytay LGU IDS',
    'Taytay, Rizal',
    'Bayan ng Taytay',
    'Bayan ng Taytay · Rizal',
    'Lalawigan ng Rizal',
    'Balita',
    'Tulong',
    'Lahat',
    'Terms of Use',
    'Privacy Notice',
    'PhilSys National ID',
  };

  /// English left on purpose, per file. See the class comment for what kind.
  const Map<String, int> ceilings = <String, int>{
    'lib/app/firebase_startup.dart': 3,
    'lib/features/account/presentation/account_canvas.dart': 44,
    'lib/features/account/presentation/account_copy.dart': 30,
    'lib/features/account/presentation/account_home_screen.dart': 1,
    'lib/features/account/presentation/change_password_form.dart': 5,
    'lib/features/auth/presentation/account_wizard_screen.dart': 23,
    'lib/features/auth/presentation/reset_flow_screens.dart': 5,
    'lib/features/credential/presentation/card_preparing_copy.dart': 19,
    'lib/features/credential/presentation/digital_id_canvas.dart': 6,
    'lib/features/directory/presentation/directory_canvas.dart': 12,
    'lib/features/events/presentation/event_detail_screen.dart': 4,
    'lib/features/events/presentation/event_registration_controller.dart': 7,
    'lib/features/events/presentation/events_screen.dart': 10,
    'lib/features/home/presentation/home_canvas.dart': 19,
    'lib/features/issuance/presentation/issuance_failure_copy.dart': 12,
    'lib/features/issuance/presentation/issuance_request_detail_screen.dart': 5,
    'lib/features/news/presentation/balita_canvas.dart': 9,
    'lib/features/notifications/presentation/notification_inbox_controller.dart':
        5,
    'lib/features/registration/presentation/registration_controller.dart': 2,
    'lib/features/sectors/presentation/sectors_copy.dart': 89,
    'lib/features/settings/presentation/privacy_controls_screen.dart': 1,
    'lib/features/settings/presentation/settings_screen.dart': 3,
    'lib/features/shell/presentation/shell_destinations.dart': 3,
    'lib/features/splash/presentation/splash_screen.dart': 1,
    'lib/features/tulong/presentation/tulong_canvas.dart': 9,
    'lib/features/verification/presentation/kyc_claim_screen.dart': 1,
    'lib/features/verification/presentation/manila_stamp.dart': 12,
    'lib/features/verification/presentation/profile_wizard_page.dart': 3,
    'lib/features/verification/presentation/unverified_gate_sheet.dart': 8,
    'lib/features/verification/presentation/verification_screen.dart': 15,
    'lib/shared/illustrations/illustration.dart': 3,
    'lib/shared/widgets/app_dialog.dart': 1,
    'lib/shared/widgets/barangay_picker.dart': 1,
    'lib/shared/widgets/biometric_consent_dialog.dart': 41,
    'lib/shared/widgets/blue_header.dart': 1,
    'lib/shared/widgets/form_page.dart': 1,
    'lib/shared/widgets/legal_text_sheet.dart': 7,
    'lib/shared/widgets/status_line.dart': 13,
    'lib/shared/widgets/taytay_icon.dart': 1,
    'lib/shared/widgets/wave_header.dart': 1,
  };

  final RegExp quoted = RegExp(
    r'''(?<![A-Za-z0-9_$])(r?)('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")''',
  );
  final RegExp developerLine = RegExp(
    r'(Key\(|ValueKey|debugLabel|restorationId|assert\(|FlutterError|throw |'
    r'debugPrint|debugMessage|toString\(|RegExp\()',
  );
  final RegExp twoWords = RegExp(r"[A-Za-z]{2,}[,.!?']?\s+[A-Za-z]{2,}");
  final RegExp oneWord = RegExp(r'^[A-Z][a-z]{2,}[.!?]?$');
  final RegExp interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');

  List<String> englishLiterals(String source) => <String>[
    for (final String line in source.split('\n'))
      if (!RegExp(r'^\s*(//|\*|import |export |part )').hasMatch(line) &&
          !developerLine.hasMatch(line))
        for (final RegExpMatch m in quoted.allMatches(line.split(' // ').first))
          if (m.group(1) != 'r')
            if (m.group(2)!.substring(1, m.group(2)!.length - 1)
                case final String body)
              if (body.replaceAll(interpolation, ' ').trim()
                  case final String text
                  when !properNames.contains(text) &&
                      (twoWords.hasMatch(text) || oneWord.hasMatch(text)))
                body,
  ];

  bool onScreenSide(String path) =>
      RegExp(
        r'^lib/(features/[^/]+/presentation/|shared/|app/)',
      ).hasMatch(path) &&
      !RegExp(r'^lib/features/(gallery|mock_data)/').hasMatch(path);

  test('the scan sees a typed sentence, and not what it should skip', () {
    // A scan that matches nothing passes everything; planted, it must bite.
    const String planted = '''
      Text('Nothing was sent.'),
      label: "Verified",
      title: strings.verifTitle,
      key: const Key('send-button'),
      // Text('a comment about a thing'),
      Text('Bayan ng Taytay · Rizal'),
      Text(r'raw text here'),
      'Hello \$name, welcome back',
      assert(x, 'developer words here'),
    ''';
    expect(englishLiterals(planted), <String>[
      'Nothing was sent.',
      'Verified',
      r'Hello $name, welcome back',
    ]);
  });

  test('no screen has more English typed into it than D-237 left', () {
    final Map<String, int> found = <String, int>{};
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String path = entity.path.replaceAll(r'\', '/');
      if (!onScreenSide(path)) continue;
      final int count = englishLiterals(entity.readAsStringSync()).length;
      if (count > 0) found[path] = count;
    }

    final List<String> over = <String>[
      for (final MapEntry<String, int> e in found.entries)
        if (e.value > (ceilings[e.key] ?? 0))
          '${e.key}: ${e.value} (allowed ${ceilings[e.key] ?? 0}):\n      '
              '${englishLiterals(File(e.key).readAsStringSync()).join('\n      ')}',
    ];
    expect(
      over,
      isEmpty,
      reason:
          'English typed into a screen. Add it to lib/l10n/app_en.arb with a '
          'Filipino entry in app_fil.arb, and read it through AppStrings:\n  '
          '${over.join('\n  ')}',
    );

    final List<String> under = <String>[
      for (final MapEntry<String, int> e in ceilings.entries)
        if ((found[e.key] ?? 0) < e.value)
          '${e.key}: ${found[e.key] ?? 0} (ceiling ${e.value})',
    ];
    expect(
      under,
      isEmpty,
      reason:
          'Fewer English literals than the ceiling: lower it here, so the '
          'English cannot come back:\n  ${under.join('\n  ')}',
    );
  });

  test('the scan still reaches the screens', () {
    expect(ceilings.length, greaterThanOrEqualTo(20));
    expect(
      Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => onScreenSide(f.path.replaceAll(r'\', '/')))
          .length,
      greaterThan(80),
      reason: 'the path filter has stopped matching; fix it',
    );
  });
}
