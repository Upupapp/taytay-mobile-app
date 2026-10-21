import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock fixtures are obviously synthetic', () {
    final directory = Directory('test/fixtures/mock');
    expect(directory.existsSync(), isTrue);
    final combined = directory
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(combined, contains('Juana Dela Cruz'));
    expect(combined, contains('@example.com'));
    expect(combined, contains('SAMPLE'));
    expect(combined, contains('0917-000-0000'));
    // The compose screens warn "Don't share passwords or OTPs." That sentence
    // is the design's privacy line, not a credential stored in the fixture.
    final String withoutWarning = combined.replaceAll(
      "Don't share passwords or OTPs.",
      '',
    );
    expect(withoutWarning.toLowerCase(), isNot(contains('password')));
    expect(combined, isNot(contains('sample-session-token')));
  });
}
