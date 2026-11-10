import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/shared/illustrations/illustration.dart';
import 'package:taytay_resident/shared/illustrations/state_illustrations.dart';

Widget host(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
  Size size = const Size(360, 640),
}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations, size: size),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// Every non-decorative illustration in the app, for the label rules.
Map<String, Widget> allScenes() => <String, Widget>{
  'empty': StateIllustrations.empty(),
  'error': StateIllustrations.error(),
  'success': StateIllustrations.success(),
};

/// Declared `Semantics` labels inside a subtree.
///
/// Read from the widgets rather than from `getSemantics`, whose nodes merge
/// upward and would report the label of an ancestor instead of the scene's own.
List<String> declaredLabels(WidgetTester tester, Finder subtree) => tester
    .widgetList<Semantics>(
      find.descendant(
        of: subtree,
        matching: find.byType(Semantics),
        matchRoot: true,
      ),
    )
    .map((s) => s.properties.label ?? '')
    .where((label) => label.isNotEmpty)
    .toList();

void main() {
  setUp(MotionPreference.reset);
  tearDown(MotionPreference.reset);

  group('illustration labelling', () {
    testWidgets('every scene is announced as an illustration', (tester) async {
      for (final entry in allScenes().entries) {
        await tester.pumpWidget(host(entry.value));
        await tester.pumpAndSettle();

        final labels = declaredLabels(tester, find.byWidget(entry.value));
        expect(
          labels,
          isNotEmpty,
          reason: '${entry.key} has no accessible name',
        );
        expect(
          labels.every(
            (label) => label.startsWith(AssetPolicy.illustrationLabelPrefix),
          ),
          isTrue,
          reason:
              '${entry.key}: a drawn scene must not be announced as though it '
              'were a photograph (got $labels)',
        );
      }
    });

    testWidgets('no scene claims to be documentary photography', (
      tester,
    ) async {
      for (final entry in allScenes().entries) {
        await tester.pumpWidget(host(entry.value));
        await tester.pumpAndSettle();

        for (final label in declaredLabels(
          tester,
          find.byWidget(entry.value),
        )) {
          for (final claim in AssetPolicy.forbiddenLabelClaims) {
            expect(
              label.toLowerCase(),
              isNot(contains(claim)),
              reason: '${entry.key} claims "$claim"',
            );
          }
        }
      }
    });

    testWidgets('a mislabelled illustration fails loudly in debug', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Illustration(
            size: const Size.square(80),
            semanticLabel: 'A municipal building',
            painterBuilder: (_) => _NullPainter(),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('a photographic claim fails loudly in debug', (tester) async {
      await tester.pumpWidget(
        host(
          Illustration(
            size: const Size.square(80),
            semanticLabel: 'Illustration: photo of the municipal hall',
            painterBuilder: (_) => _NullPainter(),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('decorative scenery is hidden from assistive technology', (
      tester,
    ) async {
      final backdrop = Illustration(
        decorative: true,
        semanticLabel: '',
        size: const Size(200, 80),
        painterBuilder: (_) => const _BlankPainter(),
      );
      await tester.pumpWidget(host(backdrop));
      await tester.pumpAndSettle();

      // ExcludeSemantics means no semantics node is produced for it at all.
      expect(
        find.descendant(
          of: find.byWidget(backdrop),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });

  group('rendering', () {
    testWidgets('every scene paints in light and dark without error', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        for (final entry in allScenes().entries) {
          await tester.pumpWidget(host(entry.value, brightness: brightness));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} in ${brightness.name}',
          );
        }
      }
    });

    testWidgets('scenes survive an extreme aspect ratio', (tester) async {
      // A painter that divides by a dimension breaks on a degenerate box; this
      // catches that before a resident on a small screen does.
      for (final size in <Size>[
        const Size(400, 40),
        const Size(40, 400),
        const Size(1, 1),
      ]) {
        await tester.pumpWidget(
          host(
            SizedBox.fromSize(size: size, child: StateIllustrations.error()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('scenes are wrapped in a RepaintBoundary', (tester) async {
      final scene = StateIllustrations.empty();
      await tester.pumpWidget(host(scene));
      expect(
        find.descendant(
          of: find.byWidget(scene),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });

  group('animation policy', () {
    testWidgets('success is the only animated illustration', (tester) async {
      // A scene that animates has to justify it. Everything except the success
      // tick declares willChange: false and paints once.
      for (final entry in allScenes().entries) {
        if (entry.key == 'success') continue;
        await tester.pumpWidget(host(entry.value));
        await tester.pumpAndSettle();

        final painters = tester.widgetList<CustomPaint>(
          find.descendant(
            of: find.byWidget(entry.value),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(painters, isNotEmpty, reason: entry.key);
        expect(
          painters.any((p) => p.willChange),
          isFalse,
          reason:
              '${entry.key} declares changing paint but is meant to be '
              'static',
        );
      }
    });

    testWidgets('the success tick animates once and settles', (tester) async {
      await tester.pumpWidget(host(StateIllustrations.success()));
      await tester.pump(const Duration(milliseconds: 50));

      // pumpAndSettle terminates, which a looping animation would prevent.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the success tick is drawn instantly under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(StateIllustrations.success(), disableAnimations: true),
      );
      // A single pump: with no animation there is nothing left to settle.
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('the in-app motion preference also skips the animation', (
      tester,
    ) async {
      MotionPreference.set(MotionPreference.reduced);
      await tester.pumpWidget(host(StateIllustrations.success()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });
}

class _NullPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Paints nothing: the decorative contract is about semantics, not pixels.
class _BlankPainter extends CustomPainter {
  const _BlankPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
