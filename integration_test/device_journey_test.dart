import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';

/// The core journeys, walked on a real runtime.
///
/// ## Why this file exists
///
/// Everything this programme has claimed about the app on a device was an
/// inference from a widget test: `flutter test` runs headless against a fake
/// window, and `simctl` can install and launch an app but cannot tap it. This is
/// the first thing in twenty-eight build TABs and twenty-five integration TABs
/// that actually drives the app on an Apple runtime.
///
/// ## What it proves and what it does not
///
/// It runs on the **iOS Simulator**, which is a real Flutter engine, a real
/// Skia/Impeller raster path and a real touch dispatch. It is **not** a device:
/// nothing here says anything about thermals, a real camera, a real network
/// transition, real memory pressure, or a screen reader.
///
/// `docs/frontend/device-matrix.md` records that split per criterion. Nothing in
/// this file should be quoted as a device result.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  AppConfig config() => AppConfig.from(
    rawEnvironment: 'dev',
    // Deliberately unreachable. The journeys below are the ones a resident can
    // complete with no server — which, given F15 and F16, is every journey a
    // resident can complete at all today.
    rawApiBaseUrl: 'https://example.invalid/api/v1',
    isReleaseBuild: false,
  );

  // ── COLD START IS NOT MEASURED HERE, AND THAT IS THE FINDING ────────────────
  //
  // Two attempts, both discarded, and both for reasons worth recording rather
  // than working around:
  //
  //  1. `pumpAndSettle` reported over ten seconds. That was the instrument: it
  //     waits for every animation to stop, and the welcome screen animates. It
  //     measures "when the app finished moving", which is not what the budget
  //     names.
  //
  //  2. Pumping frame by frame until readable content appears measures the
  //     SPLASH HOLD. `_SplashScreenState._restore` deliberately waits
  //     `MotionTokens.splashMinimum` — 900ms, or 300ms under reduced motion —
  //     before publishing, because a splash that flashes is worse than one that
  //     holds. Any honest "first meaningful frame" for this app therefore has a
  //     900ms floor by design, and a number that is mostly a constant is not a
  //     measurement.
  //
  // The budget in `docs/integration/performance-budgets.md` says of every target
  // that it needs a low-end device. An iPhone 17 simulator on an Apple-silicon
  // Mac cannot falsify a 2.5s budget — it would pass whatever the app did — so
  // producing a figure here would manufacture evidence rather than gather it.
  //
  // Recorded as unmeasured in `docs/frontend/device-matrix.md`. It needs one
  // Android phone at `minSdk = 24`, and nothing here substitutes for that.

  testWidgets('a guest can reach the app and move between its sections', (
    tester,
  ) async {
    final AppDependencies dependencies = AppDependencies.build(
      config: config(),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Past the welcome scenes. "Skip" is the escape a returning resident takes
    // and the one most likely to be broken, because nobody uses it by hand.
    final Finder skip = find.text('Skip');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // The shell is up and every destination is reachable. With no server the
    // screens render their own empty and error states, which is exactly the
    // condition a resident on a bad connection meets.
    expect(find.byType(NavigationBar), findsOneWidget);

    final NavigationBar bar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );

    for (int i = 0; i < bar.destinations.length; i++) {
      await tester.tap(find.byType(NavigationDestination).at(i));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        tester.takeException(),
        isNull,
        reason: 'destination $i threw on a real runtime',
      );
    }
  });
}
