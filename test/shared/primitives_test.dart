import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/brand_assets.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/haptics/app_haptics.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/shared/widgets/app_banner.dart';
import 'package:taytay_resident/shared/widgets/app_button.dart';
import 'package:taytay_resident/shared/widgets/app_card.dart';
import 'package:taytay_resident/shared/widgets/app_dialog.dart';
import 'package:taytay_resident/shared/widgets/app_loading.dart';
import 'package:taytay_resident/shared/widgets/app_sheet.dart';
import 'package:taytay_resident/shared/widgets/brand_mark.dart';
import 'package:taytay_resident/shared/widgets/status_view.dart';

/// Hosts a widget in the real app theme, so every assertion runs against the
/// theme residents actually get rather than a bare default.
Widget host(
  Widget child, {
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  late List<String> hapticCalls;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    MotionPreference.reset();
    AppHaptics.setEnabled(true);
    hapticCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add('${call.arguments}');
          }
          return null;
        });
  });

  tearDown(() {
    MotionPreference.reset();
    AppHaptics.setEnabled(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('AppButton', () {
    testWidgets('fires its action and a haptic on press', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(AppButton(label: 'Continue', onPressed: () => pressed++)),
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(pressed, 1);
      expect(hapticCalls, hasLength(1));
    });

    testWidgets('meets the minimum tap target in every variant', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          host(
            AppButton(
              label: 'Tap',
              variant: variant,
              fullWidth: false,
              onPressed: () {},
            ),
          ),
        );
        final size = tester.getSize(find.byType(AppButton));
        expect(
          size.height,
          greaterThanOrEqualTo(A11y.minTapTarget),
          reason: variant.name,
        );
      }
    });

    testWidgets('a loading button is inert, keeps its size, and says so', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        host(
          AppButton(
            label: 'Send one-time code',
            fullWidth: false,
            onPressed: () => pressed++,
          ),
        ),
      );
      final idleSize = tester.getSize(find.byType(AppButton));

      await tester.pumpWidget(
        host(
          AppButton(
            label: 'Send one-time code',
            fullWidth: false,
            loading: true,
            onPressed: () => pressed++,
          ),
        ),
      );
      await tester.pump();

      // Inert: taps do nothing while loading.
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(pressed, 0);

      // Same size: the button must not move under the resident's thumb.
      expect(tester.getSize(find.byType(AppButton)), idleSize);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a disabled button does not fire a haptic', (tester) async {
      await tester.pumpWidget(
        host(const AppButton(label: 'Disabled', onPressed: null)),
      );
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(hapticCalls, isEmpty);
    });

    testWidgets('suppresses the haptic under reduced motion', (tester) async {
      await tester.pumpWidget(
        host(
          AppButton(label: 'Continue', onPressed: () {}),
          disableAnimations: true,
        ),
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(hapticCalls, isEmpty);
    });

    testWidgets('label wraps rather than clipping at 200% text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const AppButton(
            label: 'Magpatuloy sa pagpapatunay ng pagkakakilanlan',
            onPressed: null,
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('AppCard', () {
    testWidgets('is tappable and announces as a button when given an action', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          AppCard(
            semanticLabel: 'Digital ID',
            onTap: () => tapped++,
            child: const Text('My Taytay ID'),
          ),
        ),
      );

      await tester.tap(find.text('My Taytay ID'));
      await tester.pumpAndSettle();
      expect(tapped, 1);

      final semantics = tester.getSemantics(find.byType(AppCard).first);
      expect(semantics.label, contains('Digital ID'));
    });

    testWidgets('selected emphasis is not signalled by colour alone', (
      tester,
    ) async {
      // WCAG 1.4.1: selection carries a thicker, primary-coloured outline as
      // well as a tinted fill.
      await tester.pumpWidget(
        host(
          const AppCard(
            emphasis: CardEmphasis.selected,
            child: Text('Chosen'),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Material),
        ),
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.side.width, greaterThan(1));
    });
  });

  group('AppBanner', () {
    testWidgets('every tone renders a distinct icon, never colour alone', (
      tester,
    ) async {
      final icons = <IconData>{};
      for (final tone in BannerTone.values) {
        await tester.pumpWidget(
          host(AppBanner(message: 'Message', tone: tone)),
        );
        final icon = tester.widget<Icon>(
          find
              .descendant(of: find.byType(AppBanner), matching: find.byType(Icon))
              .first,
        );
        icons.add(icon.icon!);
      }
      expect(
        icons,
        hasLength(BannerTone.values.length),
        reason: 'Two tones share an icon, so they differ only by colour.',
      );
    });

    testWidgets('is a live region so it is announced when it appears', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const AppBanner(message: 'Check the highlighted fields.')),
      );
      final semantics = tester.getSemantics(find.byType(AppBanner));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('the dismiss control meets the minimum tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppBanner(message: 'Dismissible', onDismiss: () {})),
      );
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(A11y.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget));
    });
  });

  group('loading primitives', () {
    testWidgets('the skeleton animates normally and freezes when reduced', (
      tester,
    ) async {
      await tester.pumpWidget(host(const AppSkeleton(width: 120)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AnimatedBuilder), findsWidgets);

      await tester.pumpWidget(
        host(const AppSkeleton(width: 120), disableAnimations: true),
      );
      await tester.pump();
      // Under reduced motion a static block is drawn instead of the shimmer.
      expect(
        find.descendant(
          of: find.byType(AppSkeleton),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
    });

    testWidgets('the in-app motion preference also freezes the skeleton', (
      tester,
    ) async {
      MotionPreference.set(MotionPreference.reduced);
      await tester.pumpWidget(host(const AppSkeleton(width: 120)));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(AppSkeleton),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
    });

    testWidgets('the spinner carries an accessible name', (tester) async {
      await tester.pumpWidget(host(const AppSpinner(label: 'Submitting')));
      final semantics = tester.getSemantics(find.byType(AppSpinner));
      expect(semantics.label, 'Submitting');
    });
  });

  group('StatusView', () {
    testWidgets('empty offers no retry; error may', (tester) async {
      await tester.pumpWidget(
        host(
          const StatusView(
            kind: StatusKind.empty,
            title: 'No requests yet',
            message: 'Anything you apply for will appear here.',
          ),
        ),
      );
      expect(find.byType(AppButton), findsNothing);

      await tester.pumpWidget(
        host(
          StatusView(
            kind: StatusKind.error,
            title: 'Could not load your requests',
            primaryAction: AppButton(
              label: 'Try again',
              fullWidth: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('survives a 200% text scale on a short screen', (tester) async {
      tester.view.physicalSize = const Size(360, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          const StatusView(
            kind: StatusKind.error,
            title: 'Hindi ma-load ang iyong mga kahilingan sa ngayon',
            message:
                'Pakisuri ang iyong koneksyon sa internet at subukang muli.',
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('AppDialog', () {
    testWidgets('confirm resolves true, cancel resolves false', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        host(Builder(builder: (c) {
          context = c;
          return const SizedBox.shrink();
        })),
      );

      final future = AppDialog.confirm(
        context: context,
        title: 'Sign out?',
        message: 'You will need to sign in again.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await future, isTrue);
    });

    testWidgets('a destructive dialog is not dismissible by scrim tap', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        host(Builder(builder: (c) {
          context = c;
          return const SizedBox.shrink();
        })),
      );

      final future = AppDialog.confirm(
        context: context,
        title: 'Delete draft?',
        message: 'This cannot be undone.',
        destructive: true,
      );
      await tester.pumpAndSettle();

      // Tapping the scrim must not resolve a destructive prompt.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Delete draft?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, isFalse);
    });
  });

  group('AppSheet', () {
    testWidgets('shows a titled sheet that scrolls its content', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        host(Builder(builder: (c) {
          context = c;
          return const SizedBox.shrink();
        })),
      );

      unawaited(
        AppSheet.show<void>(
          context: context,
          title: 'Choose a service',
          builder: (_) => const Text('Cedula'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose a service'), findsOneWidget);
      expect(find.text('Cedula'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('BrandMark', () {
    testWidgets('renders a non-seal wordmark while no artwork is verified', (
      tester,
    ) async {
      expect(BrandAssets.hasVerifiedSeal, isFalse);
      await tester.pumpWidget(host(const BrandMark(size: 96)));

      // No image is loaded, because no official artwork is registered.
      expect(find.byType(Image), findsNothing);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('carries an accessible name and hides its internals', (
      tester,
    ) async {
      await tester.pumpWidget(host(const BrandMark(size: 96)));
      final semantics = tester.getSemantics(find.byType(BrandMark));
      expect(semantics.label, contains('Taytay'));
    });

    testWidgets('the mark does not grow with the OS text scale', (tester) async {
      await tester.pumpWidget(host(const BrandMark(size: 96)));
      final normal = tester.getSize(find.byType(BrandMark));

      await tester.pumpWidget(
        host(const BrandMark(size: 96), textScaler: const TextScaler.linear(2)),
      );
      // The graphic mark keeps its geometry; scaling it would burst its box.
      expect(tester.getSize(find.byType(BrandMark)), normal);
    });

    test('cannot be constructed below the legible minimum', () {
      expect(
        () => BrandMark(size: SealIntegrityRules.minRenderedSize - 1),
        throwsAssertionError,
      );
    });
  });

  group('BrandGradientSurface', () {
    testWidgets('supplies the contrast-checked foreground to its subtree', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BrandGradientSurface(
            gradient: BrandGradients.brand,
            child: Text('Kumusta'),
          ),
        ),
      );

      final style = DefaultTextStyle.of(
        tester.element(find.text('Kumusta')),
      ).style;
      expect(style.color, BrandGradients.brand.onColor);
    });
  });
}
