import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/onboarding/presentation/welcome_scene.dart';
import 'package:taytay_resident/features/splash/presentation/splash_screen.dart';
import 'package:taytay_resident/l10n/app_localizations_en.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';

import '../support/layout_matrix.dart';

/// Phase 3 batch P3a: the redesigned splash and welcome fit 360, 375 and
/// 430 wide at normal and 200% text, and keep what the welcome must say.
void main() {
  final List<WelcomePageCopy> scenes = WelcomePageCopy.fromStrings(
    AppStringsEn(),
  );

  Widget welcome(int page) => WelcomeCanvas(
    page: page,
    pageCount: scenes.length,
    copy: scenes[page],
    onSkip: () {},
    onNext: () {},
    onBack: () {},
    onGetStarted: () {},
    onGuest: () {},
  );

  group('welcome (Main.dc.html)', () {
    for (var page = 0; page < 3; page++) {
      testWidgets('page ${page + 1} fits every phone and 200% text', (
        tester,
      ) async {
        await expectCleanLayouts(
          tester,
          () => welcome(page),
          scrollable: false,
          frames: 2,
        );
      });
    }

    testWidgets('the photo zone holds the seal, Skip and the wave', (
      tester,
    ) async {
      await tester.pumpWidget(layoutHost(welcome(0), scrollable: false));
      expect(find.byType(HeaderSeal), findsOneWidget);
      expect(find.text('Bayan ng Taytay'), findsOneWidget);
      expect(find.text('Lalawigan ng Rizal'), findsOneWidget);
      expect(find.byKey(welcomeSkipTargetKey), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter is WavePainter &&
              (w.painter! as WavePainter).layers == WelcomeShapes.layers,
        ),
        findsOneWidget,
      );
      // The photo's CC BY-SA credit stays on the photo.
      expect(find.text(scenes[0].credit), findsOneWidget);
      // Next is the 64 px gold disc, named for screen readers.
      expect(tester.getSize(find.byKey(welcomeNextKey)), const Size(64, 64));
      expect(find.bySemanticsLabel(scenes[0].nextLabel), findsOneWidget);
      // No back control on the first page.
      expect(find.bySemanticsLabel('Back'), findsNothing);
    });

    testWidgets('the last page offers both ways in at equal weight', (
      tester,
    ) async {
      await tester.pumpWidget(layoutHost(welcome(2), scrollable: false));
      expect(find.byKey(welcomeNextKey), findsNothing);
      expect(find.text(scenes[2].getStartedLabel), findsOneWidget);
      expect(find.text(scenes[2].guestLabel), findsOneWidget);
      expect(find.text(scenes[2].guestNote), findsOneWidget);
      final Size started = tester.getSize(
        find
            .ancestor(
              of: find.text(scenes[2].getStartedLabel),
              matching: find.byType(Material),
            )
            .first,
      );
      final Size guest = tester.getSize(
        find
            .ancestor(
              of: find.text(scenes[2].guestLabel),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(guest, started);
    });

    testWidgets('nothing on the welcome casts a shadow', (tester) async {
      await tester.pumpWidget(layoutHost(welcome(0), scrollable: false));
      for (final Element element in find.byType(Material).evaluate()) {
        expect((element.widget as Material).elevation, 0);
      }
      for (final Element element in find.byType(DecoratedBox).evaluate()) {
        final Decoration decoration =
            (element.widget as DecoratedBox).decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.boxShadow, anyOf(isNull, isEmpty));
        }
      }
    });
  });

  group('splash', () {
    testWidgets('fits every phone and 200% text', (tester) async {
      final AppDependencies dependencies = AppDependencies.build(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
          rawDataMode: 'mock',
          rawMockLatencyMs: '0',
        ),
        secrets: InMemorySecretStore(),
        sessionStore: InMemorySessionStore(),
      );
      addTearDown(dependencies.dispose);
      await expectCleanLayouts(
        tester,
        () => AppDependenciesScope(
          dependencies: dependencies,
          child: const SplashScreen(),
        ),
        scrollable: false,
      );
      // The splash holds on a timer; let it run out.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    });
  });
}
