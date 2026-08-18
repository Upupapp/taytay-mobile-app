import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_version.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    // The force-upgrade gate compares this constant against the server's
    // published minimum. A constant that has drifted from the shipped version
    // makes that comparison meaningless in whichever direction it drifted —
    // locking current residents out, or letting stale builds through.
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(appVersion, match!.group(1));
  });
}
