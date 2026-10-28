import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';

/// TAB 21's guarantees, held where they can be checked without a keystore.
///
/// Key custody belongs to the LGU and no production key exists or should exist
/// in this repository. What can be asserted here is everything around it: that a
/// release build refuses to be built unsigned, refuses to *run* untargeted, and
/// that the SDK floor is a decision rather than an inheritance.
void main() {
  String gradle() => File('android/app/build.gradle.kts').readAsStringSync();

  group('a release build cannot be signed with the debug key (F03)', () {
    test('the release build type uses the release signing config', () {
      final String source = gradle();
      expect(
        source,
        contains('signingConfig = signingConfigs.getByName("release")'),
      );
      // The template's line, and the reason F03 survived twenty-eight TABs: it
      // *works*. The build succeeds, the artifact looks finished, and it is
      // unpublishable in a way nothing announces.
      expect(
        source,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
    });

    test('nothing credential-shaped is tracked', () {
      // The repository is public and git history is permanent: a key committed
      // once is a key rotated forever.
      for (final String path in <String>[
        'android/key.properties',
        'android/app/key.properties',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }

      final String ignores =
          File('.gitignore').readAsStringSync() +
          File('android/.gitignore').readAsStringSync();
      for (final String pattern in <String>[
        'key.properties',
        '.jks',
        '.keystore',
      ]) {
        expect(ignores, contains(pattern), reason: pattern);
      }
    });
  });

  group('the SDK floor is a decision, not an inheritance (F11)', () {
    test('minSdk and targetSdk are pinned literals', () {
      final String source = gradle();
      expect(source, contains('minSdk = 24'));
      expect(source, contains('targetSdk = 36'));
      // Inherited values move when the toolchain moves, which would change the
      // device base this app supports because somebody upgraded Flutter.
      expect(source, isNot(contains('minSdk = flutter.minSdkVersion')));
      expect(source, isNot(contains('targetSdk = flutter.targetSdkVersion')));
    });
  });

  group('a staging build cannot be mistaken for production', () {
    test('three flavours, each with its own application id', () {
      final String source = gradle();
      for (final String flavour in <String>['dev', 'staging', 'prod']) {
        expect(source, contains('create("$flavour")'), reason: flavour);
      }
      // The suffix is what the OS enforces; a label is only what somebody reads.
      expect(source, contains('applicationIdSuffix = ".dev"'));
      expect(source, contains('applicationIdSuffix = ".staging"'));
    });

    test('the flavours do not set the environment themselves', () {
      // A flavour whose Gradle config disagreed with the dart-define would be a
      // build that says "staging" on the icon and talks to production — worse
      // than having no flavours at all.
      // Comments stripped: the config explains at length why it does *not* set
      // the environment, and a check that flags the explanation is one somebody
      // switches off rather than reads.
      final String code = gradle()
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .where((String l) => !l.trimLeft().startsWith('*'))
          .where((String l) => !l.trimLeft().startsWith('/*'))
          .join('\n');
      expect(code, isNot(contains('TAYTAY_ENV')));
    });
  });

  group('a release build refuses to run untargeted', () {
    test('no environment in a release build is a blocking failure', () {
      final AppConfig config = AppConfig.from(
        rawEnvironment: '',
        rawApiBaseUrl: '',
        isReleaseBuild: true,
      );
      // A release build falling back to a development API would ship real
      // residents onto test data. There is also no baked-in host.
      expect(config.isUsable, isFalse);
      expect(config.apiBaseUri.host, 'unconfigured.invalid');
      final String messages = config.issues
          .map((ConfigIssue i) => i.message)
          .join(' ');
      expect(messages, contains('TAYTAY_ENV'));
      expect(messages, contains('TAYTAY_API_BASE_URL'));
    });

    test('and the same omission in a debug build is fine', () {
      // The guard is about shipping, not about developing.
      expect(
        AppConfig.from(
          rawEnvironment: '',
          rawApiBaseUrl: '',
          isReleaseBuild: false,
        ).isUsable,
        isTrue,
      );
    });

    test(
      'a release build with an environment but no API URL still refuses',
      () {
        final AppConfig config = AppConfig.from(
          rawEnvironment: 'prod',
          rawApiBaseUrl: '',
          isReleaseBuild: true,
        );
        expect(config.isUsable, isFalse);
        expect(
          config.issues.map((ConfigIssue i) => i.message).join(' '),
          contains('TAYTAY_API_BASE_URL'),
        );
        expect(config.apiBaseUri.toString(), isNot(contains('taytay.gov.ph')));
      },
    );

    test('cleartext stays impossible outside dev', () {
      for (final String environment in <String>['staging', 'prod']) {
        final AppConfig config = AppConfig.from(
          rawEnvironment: environment,
          rawApiBaseUrl: 'http://insecure.example/api/v1',
          isReleaseBuild: true,
        );
        expect(config.isUsable, isFalse, reason: environment);
      }
    });
  });

  group('release scaffolding stays free of secrets', () {
    test('pubspec version is 1.0.0+1', () {
      // versionName 1.0.0, versionCode 1. Flutter reads the + build number.
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: 1.0.0+1'));
    });

    test('the keystore example is tracked and points outside the repo', () {
      final File example = File('android/key.properties.example');
      expect(example.existsSync(), isTrue);
      expect(File('android/key.properties').existsSync(), isFalse);

      final String text = example.readAsStringSync();
      final RegExpMatch? storeFile = RegExp(
        r'^storeFile=(.+)$',
        multiLine: true,
      ).firstMatch(text);
      expect(storeFile, isNotNull);
      final String path = storeFile!.group(1)!;
      expect(path.startsWith('/'), isTrue, reason: path);
      expect(path.contains('android/'), isFalse);
      expect(text, isNot(contains('BEGIN')));
      expect(text.toLowerCase(), isNot(contains('taytay.gov.ph')));
    });

    test(
      'release packaging refuses a missing keystore without using debug',
      () {
        final String source = gradle();
        expect(source, contains('verifyReleaseSigning'));
        expect(source, contains('key.properties.example'));
        expect(
          source,
          contains('signingConfig = signingConfigs.getByName("release")'),
        );
        expect(
          source,
          isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
        );
      },
    );

    test('iOS release config commits no team id', () {
      final String project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(project, isNot(contains('DEVELOPMENT_TEAM')));
      expect(project, isNot(contains('PROVISIONING_PROFILE')));
      expect(
        project,
        contains(
          'PRODUCT_BUNDLE_IDENTIFIER = ph.gov.taytay.app;',
        ),
      );
      expect(project, contains('SWIFT_OPTIMIZATION_LEVEL = "-O"'));
      expect(project, contains('DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"'));
      expect(project, contains('ENABLE_BITCODE = NO'));

      final String export = File(
        'ios/ExportOptions.plist.example',
      ).readAsStringSync();
      expect(export, contains('YOUR_APPLE_TEAM_ID'));
      expect(export, contains('app-store-connect'));
      expect(
        RegExp(
          r'<key>teamID</key>\s*<string>([^<]*)</string>',
        ).firstMatch(export)!.group(1),
        'YOUR_APPLE_TEAM_ID',
      );
      expect(File('ios/ExportOptions.plist').existsSync(), isFalse);
      expect(
        File('ios/Flutter/Release-Signing.xcconfig').existsSync(),
        isFalse,
      );
      expect(
        File('ios/Flutter/Release-Signing.xcconfig.example').existsSync(),
        isTrue,
      );

      final String ignores = File('.gitignore').readAsStringSync();
      expect(ignores, contains('/ios/ExportOptions.plist'));
      expect(ignores, contains('Release-Signing.xcconfig'));
    });
  });
}
