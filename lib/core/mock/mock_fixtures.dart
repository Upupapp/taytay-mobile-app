import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads the synthetic JSON under `test/fixtures/mock/`.
///
/// On a device the files are bundled assets. In a unit test they are read from
/// the package root, which is the same bytes. Nothing in these files is a real
/// person's data: the resident is Juana Dela Cruz at an example.com address,
/// and uncertain facts are marked SAMPLE.
abstract final class MockFixtures {
  static const String directory = 'test/fixtures/mock';

  static Future<Map<String, Object?>> object(String name) async {
    final decoded = jsonDecode(await text(name));
    if (decoded is! Map) {
      return const <String, Object?>{};
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static Future<List<Object?>> list(String name) async {
    final decoded = jsonDecode(await text(name));
    if (decoded is! List) return const <Object?>[];
    return decoded;
  }

  static Future<String> text(String name) async {
    // Release binaries must not read synthetic fixtures, including when a
    // caller forgets to check usesMockData. kReleaseMode is a compile-time
    // constant: this branch is absent from debug and test runs.
    if (kReleaseMode) {
      throw StateError(
        'Synthetic fixtures are not available in a release build.',
      );
    }
    final relative = '$directory/$name.json';
    final file = File(relative);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    return rootBundle.loadString(relative);
  }
}
