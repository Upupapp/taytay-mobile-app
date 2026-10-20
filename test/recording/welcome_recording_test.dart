@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

/// Opt-in capture of the welcome thread. Not part of `flutter test`.
///
/// `flutter test --tags recording --run-skipped test/recording/welcome_recording_test.dart`
///
/// Writes `/tmp/welcome_frames/f_####.png` at 2× of the 390×844 canvas.
void main() {
  testWidgets('thread and light across welcome into sign-in', (tester) async {
    final out = Directory('/tmp/welcome_frames');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    WelcomeMotion.animateInTests = true;
    addTearDown(() => WelcomeMotion.animateInTests = false);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final dependencies = AppDependencies.build(
      config: AppConfig.from(
        rawEnvironment: 'prod',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      secrets: InMemorySecretStore(),
      sessionStore: InMemorySessionStore(),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: RepaintBoundary(
          key: const ValueKey<String>('welcome-recording'),
          child: TaytayResidentApp(dependencies: dependencies),
        ),
      ),
    );

    // Splash minimum, then the first welcome scene.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Skip'), findsOneWidget);

    var frame = 0;
    Future<void> shot() async {
      final boundary =
          tester.renderObject(
                find.byKey(const ValueKey<String>('welcome-recording')),
              )
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final name = frame.toString().padLeft(4, '0');
        File(
          '${out.path}/f_$name.png',
        ).writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
      frame++;
    }

    Future<void> hold(Duration step, int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(step);
        await shot();
      }
    }

    // Page 1. The speck loops for 7s; four seconds shows it travel the stitch.
    await hold(const Duration(milliseconds: 100), 40);

    await tester.tap(find.text('Next'));
    await hold(const Duration(milliseconds: 50), 8);

    // Page 2.
    await hold(const Duration(milliseconds: 100), 35);

    await tester.tap(find.text('Next'));
    await hold(const Duration(milliseconds: 50), 8);

    // Page 3.
    await hold(const Duration(milliseconds: 100), 30);

    await tester.tap(find.text('Get started'));
    await tester.pump();
    // Sign-in carry is 2333ms. Capture through it and a beat after it ends.
    await hold(const Duration(milliseconds: 100), 28);

    expect(find.text('Send one-time code'), findsOneWidget);
    expect(frame, 149);
  });
}
