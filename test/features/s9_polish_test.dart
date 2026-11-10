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
    final String source = File(
      'lib/features/account/presentation/account_canvas.dart',
    ).readAsStringSync();
    expect(
      source.contains(r"'Municipality of Taytay, Rizal · version $appVersion'"),
      isTrue,
    );
    expect(source.contains('design mockup'), isFalse);
    expect(source.contains(r"Rizal '"), isFalse);
  });

  test(
    'profile, registration, verification, household and requests do not invite an application',
    () {
      const List<String> files = <String>[
        'lib/features/profile/presentation/profile_screen.dart',
        'lib/features/verification/presentation/kyc_claim_screen.dart',
        'lib/features/household/presentation/household_screen.dart',
        'lib/features/services/presentation/assistance_requests_screen.dart',
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
