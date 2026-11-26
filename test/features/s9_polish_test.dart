import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sprint S9: the shared thread, the layout rule, and the softened copy.
void main() {
  test('onboarding and auth do not nudge with Transform.translate', () {
    final List<String> offenders = <String>[];
    for (final String folder in <String>[
      'lib/features/onboarding',
      'lib/features/auth',
    ]) {
      for (final FileSystemEntity entity in Directory(
        folder,
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('Transform.translate')) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  // Redesign P3c: the line used to read a fixed "version 0.1 (design
  // mockup)", a version this app does not have. It now names the build's own
  // `appVersion`, which app_version_test keeps equal to pubspec.yaml.
  test('the about version is one sentence with no hard break', () {
    // The words live in the ARB since D-237; the canvas passes appVersion in.
    final String source = File(
      'lib/features/account/presentation/account_canvas.dart',
    ).readAsStringSync();
    expect(source.contains('strings.acctAboutVersion(appVersion)'), isTrue);
    for (final String arb in <String>['app_en.arb', 'app_fil.arb']) {
      final String text = File('lib/l10n/$arb').readAsStringSync();
      final String line = RegExp(
        r'"acctAboutVersion": "([^"]*)"',
      ).firstMatch(text)!.group(1)!;
      expect(line, contains('Taytay, Rizal'), reason: arb);
      expect(line, contains('{version}'), reason: arb);
      expect(line, isNot(contains(r'\n')), reason: arb);
      expect(line, isNot(contains('design mockup')), reason: arb);
    }
  });

  test(
    'profile, registration, verification, household and requests do not invite an application',
    () {
      const List<String> files = <String>[
        'lib/features/profile/presentation/profile_screen.dart',
        'lib/features/verification/presentation/kyc_claim_screen.dart',
        'lib/features/household/presentation/household_screen.dart',
        'lib/features/assistance/presentation/my_requests_canvas.dart',
      ];
      for (final String path in files) {
        final String source = File(path).readAsStringSync();
        expect(source.contains('anything you apply'), isFalse, reason: path);
        expect(source.contains('apply for'), isFalse, reason: path);
        expect(source.contains('service applications'), isFalse, reason: path);
      }
    },
  );
}
