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

/// The button [dialogOpener] draws.
const Key dialogOpenerKey = Key('layout-matrix-open-dialog');

/// A page with one button that calls [open] with a context under the
/// host's Navigator — the way a screen opens a dialog.
Widget dialogOpener(void Function(BuildContext context) open) {
  return Builder(
    builder: (BuildContext context) => Center(
      child: TextButton(
        key: dialogOpenerKey,
        onPressed: () => open(context),
        child: const Text('Open'),
      ),
    ),
  );
}

/// Pumps [build], taps [trigger] and lets the dialog open, at every width in
/// [widths] and every scale in [textScales], and fails on **any**
/// FlutterError raised meanwhile (overflow included), on a bottom sheet, and
/// on a dialog surface that is not centred on the screen — naming the width
/// and scale.
///
/// [host] wraps the page at a text scale; the default is [layoutHost]. Pass
/// one with an `AppDependenciesScope` and a router for a dialog that needs
/// them. The view has no system padding, so "centred" is exact.
///
/// ```dart
/// testWidgets('the confirmation fits every phone', (tester) async {
///   await expectCleanDialogLayouts(
///     tester,
///     () => dialogOpener((context) => ConfirmSheet.show(context: context, …)),
///   );
/// });
/// ```
Future<void> expectCleanDialogLayouts(
  WidgetTester tester,
  Widget Function() build, {
  Finder? trigger,
  Widget Function(Widget page, double textScale)? host,
  double height = 800,
  List<double> widths = layoutWidths,
  List<double> textScales = layoutTextScales,
  int frames = 8,
}) async {
  addTearDown(tester.view.reset);
  tester.view
    ..padding = FakeViewPadding.zero
    ..viewPadding = FakeViewPadding.zero;
  for (final double width in widths) {
    for (final double scale in textScales) {
      final String at = 'At $width × $height, text × $scale';
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, height);
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        // A fresh tree each time, so the dialog opens at this size rather
        // than being re-laid out from the last one.
        await tester.pumpWidget(const SizedBox.shrink());
        final Widget page = build();
        await tester.pumpWidget(
          host == null
              ? layoutHost(page, textScale: scale, scrollable: false)
              : host(page, scale),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        final Finder tap = trigger ?? find.byKey(dialogOpenerKey);
        await tester.ensureVisible(tap.first);
        await tester.pump();
        await tester.tap(tap.first);
        for (var i = 0; i < frames; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(
        errors,
        isEmpty,
        reason: '$at:\n${errors.map((e) => e.exceptionAsString()).join('\n')}',
      );
      expect(find.byType(BottomSheet), findsNothing, reason: '$at: a sheet');
      expect(find.byType(Dialog), findsOneWidget, reason: '$at: no dialog');
      final Rect surface = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        (surface.center.dx - width / 2).abs(),
        lessThan(1),
        reason: '$at: the dialog is not centred across ($surface)',
      );
      expect(
        (surface.center.dy - height / 2).abs(),
        lessThan(1),
        reason: '$at: the dialog is not centred down ($surface)',
      );
      expect(surface.left, greaterThanOrEqualTo(0), reason: at);
      expect(surface.right, lessThanOrEqualTo(width), reason: at);
      expect(surface.top, greaterThanOrEqualTo(0), reason: at);
      expect(surface.bottom, lessThanOrEqualTo(height), reason: at);
    }
  }
  // Unmount before the view resets, so nothing lays out at the default size.
  await tester.pumpWidget(const SizedBox.shrink());
}
