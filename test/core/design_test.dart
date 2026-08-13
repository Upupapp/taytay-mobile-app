import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/haptics/app_haptics.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';

void main() {
  group('contrast helper', () {
    test('matches known WCAG reference ratios', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.05));
      expect(contrastRatio(Colors.white, Colors.white), closeTo(1.0, 0.001));
    });
  });

  group('theme accessibility', () {
    for (final entry in <String, ThemeData Function()>{
      'light': AppTheme.light,
      'dark': AppTheme.dark,
    }.entries) {
      final label = entry.key;
      final theme = entry.value();
      final scheme = theme.colorScheme;

      test('$label: body text meets WCAG AA on every surface role', () {
        final pairs = <String, (Color, Color)>{
          'onSurface/surface': (scheme.onSurface, scheme.surface),
          'onPrimary/primary': (scheme.onPrimary, scheme.primary),
          'onError/error': (scheme.onError, scheme.error),
          'onSecondaryContainer/secondaryContainer': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'onSurfaceVariant/surface': (scheme.onSurfaceVariant, scheme.surface),
        };

        pairs.forEach((name, pair) {
          expect(
            contrastRatio(pair.$1, pair.$2),
            greaterThanOrEqualTo(A11y.minBodyContrastRatio),
            reason: '$label $name',
          );
        });
      });

      test('$label: uses Material 3 and reserves 48dp tap targets', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      test('$label: buttons are at least the minimum tap target tall', () {
        final size = theme.filledButtonTheme.style?.minimumSize?.resolve(
          <WidgetState>{},
        );
        expect(size!.height, greaterThanOrEqualTo(A11y.minTapTarget));
      });
    }

    test('light mode keeps the official Taytay blue exactly', () {
      expect(AppTheme.light().colorScheme.primary, BrandColors.taytayBlue);
    });

    test('the dark scheme is actually dark', () {
      expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
      expect(
        AppTheme.dark().colorScheme.surface,
        isNot(AppTheme.light().colorScheme.surface),
      );
    });
  });

  group('accessibility media query', () {
    testWidgets('clamps an extreme system text scale', (tester) async {
      late TextScaler observed;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(4)),
          child: Builder(
            builder: (context) => AppTheme.applyAccessibilityMediaQuery(
              context: context,
              child: Builder(
                builder: (inner) {
                  observed = MediaQuery.textScalerOf(inner);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(observed.scale(10), 10 * A11y.maxSupportedTextScale);
    });

    testWidgets('still honours a moderate resident preference', (tester) async {
      late TextScaler observed;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Builder(
            builder: (context) => AppTheme.applyAccessibilityMediaQuery(
              context: context,
              child: Builder(
                builder: (inner) {
                  observed = MediaQuery.textScalerOf(inner);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(observed.scale(10), closeTo(16, 0.001));
    });
  });

  group('motion', () {
    testWidgets('shortens functional motion and removes decoration when the '
        'platform asks for reduced motion', (tester) async {
      late BuildContext reducedContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reducedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(Motion.reduced(reducedContext), isTrue);
      expect(
        Motion.duration(reducedContext, MotionTokens.celebration),
        MotionTokens.fast,
      );
      expect(
        Motion.decorative(reducedContext, MotionTokens.celebration),
        MotionTokens.instant,
      );
    });

    testWidgets('leaves motion alone by default', (tester) async {
      late BuildContext normalContext;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              normalContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(Motion.reduced(normalContext), isFalse);
      expect(
        Motion.duration(normalContext, MotionTokens.standard),
        MotionTokens.standard,
      );
    });

    test('durations are ordered and bounded', () {
      expect(MotionTokens.micro, lessThan(MotionTokens.fast));
      expect(MotionTokens.fast, lessThan(MotionTokens.standard));
      expect(MotionTokens.standard, lessThan(MotionTokens.emphasised));
      expect(MotionTokens.emphasised, lessThan(MotionTokens.celebration));
      // Nothing may make a resident wait a full second for a transition.
      expect(MotionTokens.celebration.inMilliseconds, lessThanOrEqualTo(700));
    });
  });

  group('haptics', () {
    late List<String> platformCalls;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      AppHaptics.setEnabled(true);
      platformCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            platformCalls.add('${call.method}:${call.arguments}');
            return null;
          });
    });

    tearDown(() {
      AppHaptics.setEnabled(true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('the preference is respected', () {
      AppHaptics.setEnabled(false);
      expect(AppHaptics.isEnabled, isFalse);
      AppHaptics.setEnabled(true);
      expect(AppHaptics.isEnabled, isTrue);
    });

    test('every intent reaches the platform exactly once', () async {
      for (final intent in HapticIntent.values) {
        await AppHaptics.fire(intent);
      }
      expect(platformCalls, hasLength(HapticIntent.values.length));
    });

    test('a suppressed haptic never reaches the platform', () async {
      // Reduced-motion sessions are frequently set by people who find repeated
      // physical feedback unpleasant too.
      for (final intent in HapticIntent.values) {
        await AppHaptics.fire(intent, suppressed: true);
      }
      expect(platformCalls, isEmpty);
    });

    test('the resident preference switches feedback off entirely', () async {
      AppHaptics.setEnabled(false);
      for (final intent in HapticIntent.values) {
        await AppHaptics.fire(intent);
      }
      expect(platformCalls, isEmpty);
    });

    test('a platform that throws never breaks the caller', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async => throw PlatformException(code: 'NO_VIBRATOR'),
          );

      for (final intent in HapticIntent.values) {
        await AppHaptics.fire(intent);
      }
    });
  });

  group('spacing and radii scales', () {
    test('spacing is a strictly increasing 4-point scale', () {
      const scale = <double>[
        Spacing.xxs,
        Spacing.xs,
        Spacing.sm,
        Spacing.md,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxl,
        Spacing.xxxl,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('the minimum tap target satisfies Material and WCAG 2.2', () {
      expect(A11y.minTapTarget, greaterThanOrEqualTo(48));
    });
  });
}
