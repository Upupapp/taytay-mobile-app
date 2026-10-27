import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// The store icon, native splash, and bundle id from the release spec.
///
/// Signing stays where it was: these checks read the public identifiers and
/// the generated resources, and they do not look at a keystore.
void main() {
  String gradle() => File('android/app/build.gradle.kts').readAsStringSync();

  group('the resident app id is ph.gov.taytay.app', () {
    test('Android applicationId and namespace match the iOS bundle id', () {
      final source = gradle();
      expect(source, contains('namespace = "ph.gov.taytay.app"'));
      expect(source, contains('applicationId = "ph.gov.taytay.app"'));
      expect(source, isNot(contains('lguids')));
      expect(source, isNot(contains('TODO(paul)')));

      final activity = File(
        'android/app/src/main/kotlin/ph/gov/taytay/app/MainActivity.kt',
      ).readAsStringSync();
      expect(activity, contains('package ph.gov.taytay.app'));
      expect(
        Directory(
          'android/app/src/main/kotlin/ph/gov/taytay/lguids',
        ).existsSync(),
        isFalse,
      );

      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = ph.gov.taytay.app;'),
      );
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = ph.gov.taytay.app.RunnerTests;'),
      );
      expect(project, isNot(contains('lguids')));

      final xcconfig = File('ios/Flutter/Release.xcconfig').readAsStringSync();
      expect(xcconfig, isNot(contains('TODO(paul)')));
      expect(xcconfig, isNot(contains('lguids')));
    });

    test('the home-screen name is Taytay', () {
      final source = gradle();
      expect(source, contains('resValue("string", "app_name", "Taytay")'));
      expect(
        source,
        contains('resValue("string", "app_name", "Taytay (dev)")'),
      );
      expect(
        source,
        contains('resValue("string", "app_name", "Taytay (staging)")'),
      );

      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        RegExp(
          r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>',
        ).firstMatch(plist)!.group(1),
        'Taytay',
      );
      expect(
        RegExp(
          r'<key>CFBundleName</key>\s*<string>([^<]*)</string>',
        ).firstMatch(plist)!.group(1),
        'Taytay',
      );
    });
  });

  group('the generated icon and splash match the release spec', () {
    test('the iOS marketing icon is opaque and matches the spec file', () {
      final iconBytes = File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).readAsBytesSync();
      final opaqueBytes = File(
        'release/assets/icon-ios-1024-opaque.png',
      ).readAsBytesSync();
      // PNG colour type sits at byte 25 of a standard IHDR. 2 is RGB.
      // 6 is RGBA, which App Store rejects on the 1024 icon. The generator
      // re-encodes the file, so the check is the pixels, not the container.
      expect(iconBytes[25], 2);
      final icon = img.decodePng(iconBytes)!;
      final opaque = img.decodePng(opaqueBytes)!;
      expect(icon.width, 1024);
      expect(icon.height, 1024);
      expect(icon.getBytes(), opaque.getBytes());
    });

    test(
      'Android adaptive icon has foreground, background, and monochrome',
      () {
        final xml = File(
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
        ).readAsStringSync();
        expect(xml, contains('ic_launcher_background'));
        expect(xml, contains('ic_launcher_foreground'));
        expect(xml, contains('ic_launcher_monochrome'));
        expect(xml, contains('android:inset="0%"'));

        final manifest = File(
          'android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      },
    );

    test('both splashes use #0B3D91, including Android 12', () {
      final background = img.decodePng(
        File(
          'android/app/src/main/res/drawable/background.png',
        ).readAsBytesSync(),
      )!;
      final pixel = background.getPixel(0, 0);
      expect(pixel.r.toInt(), 0x0B);
      expect(pixel.g.toInt(), 0x3D);
      expect(pixel.b.toInt(), 0x91);

      // The generator treats the 1152 px mark as a 4× asset, so mdpi is 288 dp.
      final mark = img.decodePng(
        File(
          'android/app/src/main/res/drawable-mdpi/splash.png',
        ).readAsBytesSync(),
      )!;
      expect(mark.width, 288);
      expect(mark.height, 288);

      // Android 12 icon is 240 dp. mdpi is 240 px. The system masks the circle.
      final android12 = img.decodePng(
        File(
          'android/app/src/main/res/drawable-mdpi/android12splash.png',
        ).readAsBytesSync(),
      )!;
      expect(android12.width, 240);
      expect(android12.height, 240);

      for (final path in <String>[
        'android/app/src/main/res/values/styles.xml',
        'android/app/src/main/res/values-night/styles.xml',
        'android/app/src/main/res/values-v31/styles.xml',
        'android/app/src/main/res/values-night-v31/styles.xml',
      ]) {
        final styles = File(path).readAsStringSync();
        expect(styles, contains('#0B3D91'), reason: path);
        expect(
          styles,
          contains('android:windowLightStatusBar">false'),
          reason: path,
        );
        expect(
          styles,
          contains('android:windowDrawsSystemBarBackgrounds">true'),
          reason: path,
        );
      }

      final android12Theme = File(
        'android/app/src/main/res/values-v31/styles.xml',
      ).readAsStringSync();
      expect(android12Theme, contains('android:windowSplashScreenBackground'));
      expect(
        android12Theme,
        contains(
          'android:windowSplashScreenAnimatedIcon">@drawable/android12splash',
        ),
      );

      final launch = File(
        'android/app/src/main/res/drawable/launch_background.xml',
      ).readAsStringSync();
      expect(launch, contains('@drawable/splash'));
      expect(launch, contains('@drawable/background'));
    });
  });
}
