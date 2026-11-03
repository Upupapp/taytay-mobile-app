import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';

/// Locks the release-build rules that a behavioral test cannot flip.
///
/// `flutter test` is not a release build, so kReleaseMode is false here.
/// Deleting the guard from the source is the revert these checks catch.
void main() {
  test('usesMockData and fixture loading consult kReleaseMode', () {
    final String config = File(
      'lib/core/config/app_config.dart',
    ).readAsStringSync();
    expect(config, contains('isReleaseBuild: kReleaseMode'));
    expect(config, contains('kReleaseMode || isReleaseBuild'));

    final RegExpMatch? getter = RegExp(
      r'bool get usesMockData =>\s*([^;]+);',
      dotAll: true,
    ).firstMatch(config);
    expect(getter, isNotNull);
    expect(getter!.group(1), contains('!kReleaseMode'));

    final String fixtures = File(
      'lib/core/mock/mock_fixtures.dart',
    ).readAsStringSync();
    final RegExpMatch? text = RegExp(
      r'static Future<String> text\(String name\) async \{([\s\S]*?)\n  \}',
    ).firstMatch(fixtures);
    expect(text, isNotNull);
    final String body = text!.group(1)!;
    expect(body, contains('if (kReleaseMode)'));
    expect(
      body.indexOf('kReleaseMode'),
      lessThan(body.indexOf('readAsStringSync')),
    );
    expect(body.indexOf('kReleaseMode'), lessThan(body.indexOf('loadString')));
  });

  test('a release build with a bad base URL does not adopt a host', () {
    for (final String raw in <String>['', 'not a url', 'https://']) {
      final AppConfig config = AppConfig.from(
        rawEnvironment: 'prod',
        rawApiBaseUrl: raw,
        isReleaseBuild: true,
      );
      expect(config.isUsable, isFalse, reason: raw);
      expect(config.usesMockData, isFalse, reason: raw);
      expect(config.apiBaseUri.host, 'unconfigured.invalid', reason: raw);
      expect(config.apiBaseUri.host, isNot('10.0.2.2'), reason: raw);
    }
  });

  test('the signing path uses File.separator', () {
    // The Gradle Kotlin DSL binds `java` to the Java extension, so
    // `java.io.File` does not compile. File.separator is the form that does.
    final String source = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    expect(source, contains('import java.io.File'));
    expect(source, contains('File.separator'));
    // The import is the only mention. `java.io.File.separator` does not
    // compile: the Gradle Kotlin DSL binds `java` to the Java extension.
    expect('java.io.File'.allMatches(source).length, 1);
    expect(source, contains('verifyReleaseSigning'));
    expect(
      source,
      isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
    );
  });

  test('the committed Apple team id is the placeholder', () {
    final String xcconfig = File(
      'ios/Flutter/Release.xcconfig',
    ).readAsStringSync();
    expect(xcconfig, contains('DEVELOPMENT_TEAM = YOUR_APPLE_TEAM_ID'));
    expect(
      RegExp(
        r'^DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}\s*$',
        multiLine: true,
      ).hasMatch(xcconfig),
      isFalse,
    );

    final String project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(project, isNot(contains('DEVELOPMENT_TEAM')));
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = ph.gov.taytay.app;'));
  });
}
