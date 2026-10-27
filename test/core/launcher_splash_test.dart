import 'dart:io';
import 'dart:math' as math;

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

      // The canvas stays 1152 px, so mdpi is 288 dp. The mark itself is the
      // centred 768 px artwork, which is 192 dp.
      final mark = img.decodePng(
        File(
          'android/app/src/main/res/drawable-mdpi/splash.png',
        ).readAsBytesSync(),
      )!;
      expect(mark.width, 288);
      expect(mark.height, 288);
      final markBox = _opaqueBounds(mark);
      expect(markBox.width, 192);
      expect(markBox.left, (288 - markBox.width) ~/ 2);

      // Android 12 icon is 240 dp. The system masks a 160 dp circle (radius 80).
      final android12 = img.decodePng(
        File(
          'android/app/src/main/res/drawable-mdpi/android12splash.png',
        ).readAsBytesSync(),
      )!;
      expect(android12.width, 240);
      expect(android12.height, 240);
      expect(_maxOpaqueRadius(android12), lessThanOrEqualTo(80));
      expect(_darkFringeCount(android12), 0);

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

    test('the Android 12 disc has no dark resize fringe', () {
      final paths = <String>[
        'release/assets/android12-splash-icon-960.png',
        for (final density in [
          'mdpi',
          'hdpi',
          'xhdpi',
          'xxhdpi',
          'xxxhdpi',
        ]) ...[
          'android/app/src/main/res/drawable-$density/android12splash.png',
          'android/app/src/main/res/drawable-night-$density/android12splash.png',
        ],
      ];
      for (final path in paths) {
        final image = img.decodePng(File(path).readAsBytesSync())!;
        expect(_darkFringeCount(image), 0, reason: path);
        expect(_exactBrandCount(image), greaterThan(0), reason: path);
        expect(_maxOpaqueRadius(image), lessThanOrEqualTo(80), reason: path);
      }
    });
  });
}

({int left, int top, int width, int height}) _opaqueBounds(img.Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = 0;
  var maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a.toInt() <= 12) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  return (
    left: minX,
    top: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

/// Pixels darkened by a resize that blended the blue disc with transparent
/// black. The reported fringe is RGBA(7, 41, 98, 117). A filled disc is
/// exact `#0B3D91` or fully transparent, so this stays at zero.
int _darkFringeCount(img.Image image) {
  var count = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      final alpha = pixel.a.toInt();
      if (alpha <= 16 || blue <= red) continue;
      if (red >= 0x0B || green >= 0x3D || blue >= 0x91) continue;
      final darkening = (0x0B - red) + (0x3D - green) + (0x91 - blue);
      if (darkening > 24) count++;
    }
  }
  return count;
}

/// Opaque pixels of the Android 12 disc, exact `#0B3D91`.
int _exactBrandCount(img.Image image) {
  var count = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r.toInt() == 0x0B &&
          pixel.g.toInt() == 0x3D &&
          pixel.b.toInt() == 0x91 &&
          pixel.a.toInt() == 255) {
        count++;
      }
    }
  }
  return count;
}

/// Radius, in dp, of the furthest opaque pixel from the image centre.
///
/// The Android 12 asset is a 4× image: 960 px is 240 dp.
double _maxOpaqueRadius(img.Image image) {
  final cx = (image.width - 1) / 2;
  final cy = (image.height - 1) / 2;
  var maxR = 0.0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a.toInt() <= 12) continue;
      final dx = x - cx;
      final dy = y - cy;
      final radius = math.sqrt((dx * dx) + (dy * dy));
      if (radius > maxR) maxR = radius;
    }
  }
  // 960 px is 240 dp, and the smaller densities use the same proportion.
  return maxR * 240 / image.width;
}
