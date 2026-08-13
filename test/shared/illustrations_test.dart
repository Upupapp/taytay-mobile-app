import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/shared/illustrations/feature_banner.dart';
import 'package:taytay_resident/shared/illustrations/feature_icons.dart';
import 'package:taytay_resident/shared/illustrations/illustration.dart';
import 'package:taytay_resident/shared/illustrations/placeholders.dart';
import 'package:taytay_resident/shared/illustrations/state_illustrations.dart';
import 'package:taytay_resident/shared/illustrations/taytay_scenes.dart';

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
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          size: size,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// Every non-decorative illustration in the app, for the label rules.
Map<String, Widget> allScenes() => <String, Widget>{
  'services': TaytayScenes.services(),
  'digitalId': TaytayScenes.digitalId(),
  'privacy': TaytayScenes.privacy(),
  'empty': StateIllustrations.empty(),
  'error': StateIllustrations.error(),
  'success': StateIllustrations.success(),
  'eventPoster': ImagePlaceholders.eventPoster(width: 120),
  'newsfeed': ImagePlaceholders.newsfeed(width: 200),
  'squarePlaceholder': ImagePlaceholders.square(),
};

/// Declared `Semantics` labels inside a subtree.
///
/// Read from the widgets rather than from `getSemantics`, whose nodes merge
/// upward and would report the label of an ancestor instead of the scene's own.
List<String> declaredLabels(WidgetTester tester, Finder subtree) => tester
    .widgetList<Semantics>(
      find.descendant(of: subtree, matching: find.byType(Semantics), matchRoot: true),
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
        expect(labels, isNotEmpty, reason: '${entry.key} has no accessible name');
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

    testWidgets('no scene claims to be documentary photography', (tester) async {
      for (final entry in allScenes().entries) {
        await tester.pumpWidget(host(entry.value));
        await tester.pumpAndSettle();

        for (final label in declaredLabels(tester, find.byWidget(entry.value))) {
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
      final backdrop = TaytayScenes.horizonBackdrop();
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
          host(SizedBox.fromSize(size: size, child: TaytayScenes.services())),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('scenes are wrapped in a RepaintBoundary', (tester) async {
      final scene = TaytayScenes.privacy();
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
          reason: '${entry.key} declares changing paint but is meant to be '
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

  group('placeholders', () {
    testWidgets('reserve their aspect ratio so content does not reflow', (
      tester,
    ) async {
      await tester.pumpWidget(host(ImagePlaceholders.newsfeed(width: 320)));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(AspectRatio));
      expect(
        size.width / size.height,
        closeTo(ImagePlaceholders.newsfeedAspect, 0.01),
      );
    });

    testWidgets('the event poster is portrait, matching a printed notice', (
      tester,
    ) async {
      expect(ImagePlaceholders.eventPosterAspect, lessThan(1));
      await tester.pumpWidget(host(ImagePlaceholders.eventPoster(width: 150)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('feature icons', () {
    test('cover every authoritative backend service category', () {
      // Codes come from Modules\ServiceCatalog\Domain\ServiceCategory.
      const backendCategories = <String>[
        'dokumento',
        'buwis',
        'kalusugan',
        'trabaho',
        'ids',
        'national',
      ];
      for (final code in backendCategories) {
        expect(
          ServiceCategoryIcon.fromCode(code),
          isNotNull,
          reason: 'no icon for category "$code"',
        );
      }
      expect(
        ServiceCategoryIcon.values.map((v) => v.categoryCode),
        unorderedEquals(backendCategories),
      );
    });

    test('an unknown category resolves to null rather than throwing', () {
      // The backend may add a category without a version bump.
      expect(ServiceCategoryIcon.fromCode('brand_new_category'), isNull);
      expect(ServiceCategoryIcon.fromCode(null), isNull);
    });

    test('every category has a distinct icon and a label', () {
      final icons = ServiceCategoryIcon.values.map((v) => v.icon).toSet();
      expect(icons, hasLength(ServiceCategoryIcon.values.length));
      for (final value in ServiceCategoryIcon.values) {
        expect(value.label, isNotEmpty, reason: value.name);
      }
    });

    testWidgets('an unknown code falls back to a neutral mark', (tester) async {
      await tester.pumpWidget(host(FeatureIcon.categoryCode('nope')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.apps_outlined), findsOneWidget);
    });

    testWidgets('an unlabelled icon is hidden from assistive technology', (
      tester,
    ) async {
      // Correct when adjacent text already names the thing.
      const icon = FeatureIcon(icon: Icons.badge_outlined);
      await tester.pumpWidget(host(icon));
      // No declared label anywhere in the subtree, so nothing is announced.
      expect(declaredLabels(tester, find.byWidget(icon)), isEmpty);
    });

    testWidgets('a labelled category icon announces its category', (
      tester,
    ) async {
      final icon = FeatureIcon.category(ServiceCategoryIcon.kalusugan);
      await tester.pumpWidget(host(icon));
      expect(declaredLabels(tester, find.byWidget(icon)), contains('Health'));
    });
  });

  group('feature banner', () {
    testWidgets('renders its copy on the gradient foreground', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 340,
            child: FeatureBanner(
              title: 'Verify your account',
              message: 'Unlock your digital ID.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify your account'), findsOneWidget);
      expect(find.text('Unlock your digital ID.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the decorative motif is hidden from assistive technology', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 340,
            child: FeatureBanner(title: 'Verify your account'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(FeatureBanner),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('every motif paints without error', (tester) async {
      for (final motif in BannerMotif.values) {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 340,
              child: FeatureBanner(title: 'Taytay', motif: motif),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: motif.name);
      }
    });

    testWidgets('is tappable when given an action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 340,
            child: FeatureBanner(title: 'Verify', onTap: () => taps++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      expect(taps, 1);
    });
  });
}

class _NullPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
