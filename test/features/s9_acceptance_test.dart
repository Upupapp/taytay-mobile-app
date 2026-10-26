import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/features/onboarding/presentation/welcome_scene.dart';
import 'package:taytay_resident/shared/widgets/gold_thread_shell.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_thread.dart';

import 'welcome_and_gates_test.dart';

/// Headless stand-in for the S9 accessibility and frame-timing evidence.
///
/// These pumps run on the test host. They are not a device frame time and
/// not a TalkBack session. Set `TAYTAY_S9_REPORT=1` to write the two reports.
void main() {
  testWidgets('welcome semantics, 48dp targets, and 200% text', (tester) async {
    await boot(tester);
    await settle(tester);

    expect(find.byKey(welcomeSkipTargetKey), findsOneWidget);
    final SemanticsNode skip = tester.getSemantics(
      find.bySemanticsLabel('Skip'),
    );
    expect(skip.label, 'Skip');
    expect(skip.flagsCollection.isButton, isTrue);
    expect(skip.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    final SemanticsNode headline = tester.getSemantics(
      find.bySemanticsLabel('Serbisyong bayan, nasa isang app.'),
    );
    expect(headline.flagsCollection.isHeader, isTrue);
    _expectTargets(tester);
    final Finder next = find.ancestor(
      of: find.text('Next'),
      matching: find.byType(InkWell),
    );
    final Size nextSize = tester.getSize(next);
    expect(nextSize.height, greaterThanOrEqualTo(A11y.minTapTarget));
    expect(nextSize.width, greaterThanOrEqualTo(A11y.minTapTarget));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.byType(TaytayBackButton), findsWidgets);
    for (final element in find.byType(TaytayBackButton).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, greaterThanOrEqualTo(A11y.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget));
    }
  });

  testWidgets('welcome at 200% text still shows the title and a 48dp Skip', (
    tester,
  ) async {
    await boot(tester, textScaler: const TextScaler.linear(2));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Serbisyong bayan, nasa isang app.'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(welcomeSkipTargetKey)).height,
      greaterThanOrEqualTo(A11y.minTapTarget),
    );
    final RenderObject headlineBox = tester.renderObject(
      find.text('Serbisyong bayan,'),
    );
    expect((headlineBox as RenderBox).size.height, greaterThan(0));
  });

  testWidgets('reduced motion keeps the thread and hides the travelling tip', (
    tester,
  ) async {
    MotionPreference.set(MotionPreference.reduced);
    addTearDown(MotionPreference.reset);
    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);

    await boot(tester, disableAnimations: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.byType(SignInThreadOverlay), findsOneWidget);
    expect(find.byKey(TravellingLight.mark), findsNothing);
    final GoldThreadModel model = GoldThreadScope.maybeOf(
      tester.element(find.text('Skip')),
    )!;
    expect(model.clock.isAnimating, isFalse);
  });

  testWidgets('host frame pumps while the welcome thread advances', (
    tester,
  ) async {
    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);

    await boot(tester, disableAnimations: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Skip'), findsOneWidget);

    final GoldThreadModel model = GoldThreadScope.maybeOf(
      tester.element(find.text('Skip')),
    )!;
    expect(model.clock.isAnimating, isTrue);
    final double start = model.cycle;

    const int frames = 45;
    final List<int> micros = <int>[];
    final Stopwatch watch = Stopwatch();
    for (var i = 0; i < frames; i++) {
      watch
        ..reset()
        ..start();
      await tester.pump(const Duration(milliseconds: 33));
      watch.stop();
      micros.add(watch.elapsedMicroseconds);
    }
    expect(model.cycle, isNot(start));
    expect(tester.takeException(), isNull);

    final int slowest = micros.reduce((int a, int b) => a > b ? a : b);
    final int total = micros.reduce((int a, int b) => a + b);
    // A host pump is not a device frame. The bound only catches a stall.
    expect(slowest, lessThan(2000000));

    if (Platform.environment['TAYTAY_S9_REPORT'] == '1') {
      _writeReports(slowest: slowest, total: total, frames: frames);
    }
  });
}

void _expectTargets(WidgetTester tester) {
  expect(
    tester.getSize(find.byKey(welcomeSkipTargetKey)).height,
    A11y.minTapTarget,
  );
  expect(
    tester.getSize(find.byKey(welcomeSkipTargetKey)).width,
    greaterThanOrEqualTo(A11y.minTapTarget),
  );
}

void _writeReports({
  required int slowest,
  required int total,
  required int frames,
}) {
  final double meanMs = total / frames / 1000;
  final double slowMs = slowest / 1000;
  Directory('docs/frontend').createSync(recursive: true);
  File('docs/frontend/s9-accessibility.md').writeAsStringSync('''
# S9 accessibility report

Headless widget-test run on the development host. Light mode only. This is not a TalkBack or VoiceOver session, and it does not measure a device.

| Check | Result |
| --- | --- |
| Welcome Skip semantics | Button, label "Skip", tap action |
| Welcome headline semantics | Header |
| Skip target | 48dp tall and at least 48dp wide |
| Next control | At least 48dp tall and 48dp wide |
| Page 2 back control | At least 48×48dp |
| 200% text | Welcome still shows Skip and the headline, Skip stays at least 48dp, no exception |
| Reduced motion | The gold thread stays. The travelling tip is absent. The 7s clock does not run |

The same checks are `test/features/s9_acceptance_test.dart`. They run with `flutter test` on this machine. They are not a GitHub Actions job.
''');
  File('docs/frontend/s9-performance.md').writeAsStringSync('''
# S9 performance report

Headless stand-in for a device frame time. Light mode only. The welcome gold thread was already on screen. The test then pumped $frames steps of 33ms, which is the 30fps capture step, and timed each pump with a host stopwatch.

| Figure | Value |
| --- | --- |
| Pumps | $frames × 33ms |
| Mean host pump | ${meanMs.toStringAsFixed(2)} ms |
| Slowest host pump | ${slowMs.toStringAsFixed(2)} ms |
| Thread | The cycle value changed across the pumps |

These numbers are host `WidgetTester.pump` cost. They are not a frame time on a phone, not a cold start, and not the 60fps list budget in `docs/integration/performance-budgets.md`. No device figure is invented here. The bound in the test is 2000ms, so a stalled pump fails. The run is `test/features/s9_acceptance_test.dart` with `TAYTAY_S9_REPORT=1`. It is not a GitHub Actions job.
''');
}
