import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';

/// The phone widths every redesigned widget and screen must fit
/// (MOBILE_TASK Phase 3: 360, 375 and 430).
const List<double> layoutWidths = <double>[360, 375, 430];

/// Normal text and the 200% ceiling Article 6 honours.
const List<double> layoutTextScales = <double>[1, 2];

/// Hosts [child] on the light theme at [textScale].
///
/// [scrollable] wraps it in a vertical scroll view, as a screen body would,
/// so only overflow a resident could actually hit is reported: a row too wide
/// for the phone, or a fixed box too small for its text. Pass false for a
/// widget that fills the screen and scrolls itself.
Widget layoutHost(
  Widget child, {
  double textScale = 1,
  bool scrollable = true,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
}

/// Pumps [build] at every width in [widths] and every scale in [textScales]
/// ([height] tall, 1 logical px per physical px) and fails on **any**
/// FlutterError raised while building, laying out or painting — a
/// RenderFlex overflow included — naming the width and scale that raised it.
///
/// Settling is bounded rather than `pumpAndSettle`, because a skeleton
/// shimmers forever; [frames] pumps of 50 ms let bundled SVGs and images
/// arrive. Phase 3 screens reuse this:
///
/// ```dart
/// testWidgets('fits every phone', (tester) async {
///   await expectCleanLayouts(tester, () => const MyScreen(...));
/// });
/// ```
Future<void> expectCleanLayouts(
  WidgetTester tester,
  Widget Function() build, {
  double height = 800,
  bool scrollable = true,
  List<double> widths = layoutWidths,
  List<double> textScales = layoutTextScales,
  int frames = 3,
}) async {
  addTearDown(tester.view.reset);
  for (final double width in widths) {
    for (final double scale in textScales) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, height);
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await tester.pumpWidget(
          layoutHost(build(), textScale: scale, scrollable: scrollable),
        );
        for (var i = 0; i < frames; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(
        errors,
        isEmpty,
        reason:
            'At $width × $height, text × $scale:\n'
            '${errors.map((e) => e.exceptionAsString()).join('\n')}',
      );
    }
  }
  // Unmount before the view resets, so nothing lays out at the default size.
  await tester.pumpWidget(const SizedBox.shrink());
}
