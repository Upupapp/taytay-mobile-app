import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/button_styles.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/ringed_input_border.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/features/gallery/presentation/theme_gallery_section.dart';

/// Phase 1 of the redesign: the tokens are the README's, and the Material
/// components a screen reaches for without styling land on them.
void main() {
  final ThemeData theme = AppTheme.light();

  group('redesign tokens', () {
    test('colours are the README values', () {
      expect(BrandColors.blue, const Color(0xFF0A2071));
      expect(BrandColors.navy, const Color(0xFF08124A));
      expect(BrandColors.gold, const Color(0xFFF5DA18));
      expect(BrandColors.red, const Color(0xFFE0090A));
      expect(BrandColors.green, const Color(0xFF17663A));
      expect(BrandColors.ink, const Color(0xFF0E1733));
      expect(BrandColors.text, const Color(0xFF2B3550));
      expect(BrandColors.muted, const Color(0xFF5B6680));
      expect(BrandColors.background, const Color(0xFFF4F6FA));
      expect(BrandColors.softFill, const Color(0xFFF2F4F8));
      expect(BrandColors.divider, const Color(0xFFEEF1F6));
      expect(BrandColors.blue50, const Color(0xFFECF1FC));
      expect(BrandColors.blue100, const Color(0xFFDCE5FA));
    });

    test('old names feature code uses point at the redesign values', () {
      expect(BrandColors.taytayBlue, BrandColors.blue);
      expect(BrandColors.taytayBlueDark, BrandColors.navy);
      expect(BrandColors.sealGold, BrandColors.gold);
      expect(BrandColors.textPrimary, BrandColors.ink);
      expect(BrandColors.surface, BrandColors.background);
      expect(BrandGradients.inAppHeader, same(BrandGradients.header));
      expect(TaytayButtonMetrics.of(TaytayButtonKind.signIn).height, 52);
      expect(AppTypography.button.fontSize, 14);
      expect(AppTypography.button.fontWeight, FontWeight.w600);
    });

    test('there are no shadows to hand out', () {
      expect(TaytayShadows.card, isEmpty);
      expect(TaytayShadows.raised, isEmpty);
      expect(TaytayShadows.digitalId, isEmpty);
      for (final TaytayButtonKind kind in TaytayButtonKind.values) {
        expect(TaytayButtonMetrics.of(kind).primaryShadow, isNull);
      }
    });

    test('readable text on the light surfaces', () {
      for (final Color background in <Color>[
        Colors.white,
        BrandColors.background,
        BrandColors.softFill,
      ]) {
        for (final Color ink in <Color>[
          BrandColors.ink,
          BrandColors.text,
          BrandColors.muted,
          BrandColors.redInk,
          BrandColors.goldInk,
          BrandColors.fieldHint,
        ]) {
          expect(
            contrastRatio(ink, background),
            greaterThanOrEqualTo(A11y.minBodyContrastRatio),
            reason: '$ink on $background',
          );
        }
      }
      expect(
        contrastRatio(BrandColors.blue, BrandColors.blue50),
        greaterThanOrEqualTo(A11y.minBodyContrastRatio),
      );
    });

    test('every icon tile carries its icon at 3:1 or better', () {
      expect(BrandGradients.tiles, hasLength(TileTone.values.length));
      for (final TileTone tone in TileTone.values) {
        final BrandGradient tile = BrandGradients.tile(tone);
        expect(
          tile.worstCaseContrastRatio(),
          greaterThanOrEqualTo(A11y.minLargeTextContrastRatio),
          reason: tile.name,
        );
      }
      expect(BrandGradients.tile(TileTone.gold).onColor, BrandColors.navy);
    });

    test('the type scale is the README scale', () {
      expect(AppTypography.hero.fontSize, 22);
      expect(AppTypography.headerTitleLarge.fontSize, 20);
      expect(AppTypography.headerTitle.fontSize, 15);
      expect(AppTypography.pageTitle.fontSize, 18);
      expect(AppTypography.sectionTitle.fontSize, 15);
      expect(AppTypography.bodyStyle.fontSize, 13.5);
      expect(AppTypography.listTitle.fontWeight, FontWeight.w600);
      expect(AppTypography.listDetail.fontSize, 12.5);
      expect(AppTypography.chip.fontSize, 13.5);
      expect(AppTypography.navLabel.fontSize, 11);
      expect(AppTypography.category.fontSize, AppTypography.minFontSize);
      expect(AppTypography.category.fontWeight, FontWeight.w800);
    });
  });

  group('CSS gradient angle', () {
    test('135° on a square runs corner to corner', () {
      const Rect square = Rect.fromLTWH(0, 0, 100, 100);
      final Matrix4 m = const CssGradientAngle(135).transform(square);
      final Offset start = MatrixUtils.transformPoint(m, const Offset(0, 50));
      final Offset end = MatrixUtils.transformPoint(m, const Offset(100, 50));
      expect(start.dx, moreOrLessEquals(0, epsilon: 1e-6));
      expect(start.dy, moreOrLessEquals(0, epsilon: 1e-6));
      expect(end.dx, moreOrLessEquals(100, epsilon: 1e-6));
      expect(end.dy, moreOrLessEquals(100, epsilon: 1e-6));
    });

    test('150° on a wide header keeps the CSS length and direction', () {
      const Rect header = Rect.fromLTWH(0, 0, 390, 200);
      final Matrix4 m = const CssGradientAngle(150).transform(header);
      final Offset start = MatrixUtils.transformPoint(m, const Offset(0, 100));
      final Offset end = MatrixUtils.transformPoint(m, const Offset(390, 100));
      final Offset line = end - start;
      // CSS: |w·sin a| + |h·cos a| = 195 + 173.2.
      expect(line.distance, moreOrLessEquals(368.2, epsilon: 0.1));
      // Pointing down and to the right, 60° below the horizontal.
      expect(line.direction, moreOrLessEquals(60 * 3.141592653589793 / 180));
    });
  });

  group('themed Material components', () {
    test('nothing is elevated and nothing casts a shadow', () {
      expect(theme.colorScheme.shadow, BrandColors.transparent);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.dialogTheme.elevation, 0);
      expect(theme.bottomSheetTheme.elevation, 0);
      expect(theme.bottomSheetTheme.modalElevation, 0);
      expect(theme.navigationBarTheme.elevation, 0);
      expect(theme.chipTheme.elevation, 0);
      expect(theme.chipTheme.pressElevation, 0);
      expect(theme.snackBarTheme.elevation, 0);
      expect(
        theme.filledButtonTheme.style?.elevation?.resolve(<WidgetState>{}),
        0,
      );
    });

    test('app bar is the blue header fallback, title 15 / 600', () {
      expect(theme.appBarTheme.backgroundColor, BrandColors.blue);
      expect(theme.appBarTheme.foregroundColor, Colors.white);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 15);
      expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w600);
    });

    test('a soft card is white, borderless, radius 20', () {
      final ShapeBorder? shape = theme.cardTheme.shape;
      expect(theme.cardTheme.color, Colors.white);
      expect(shape, isA<RoundedRectangleBorder>());
      final RoundedRectangleBorder rounded = shape as RoundedRectangleBorder;
      expect(rounded.borderRadius, BorderRadius.circular(Radii.card));
      expect(rounded.side, BorderSide.none);
    });

    test('primary and soft buttons are 52 high with radius 16', () {
      final ButtonStyle? filled = theme.filledButtonTheme.style;
      final ButtonStyle? soft = theme.outlinedButtonTheme.style;
      for (final ButtonStyle? style in <ButtonStyle?>[filled, soft]) {
        expect(style?.minimumSize?.resolve(<WidgetState>{})?.height, 52);
        expect(
          style?.shape?.resolve(<WidgetState>{}),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      }
      expect(
        soft?.backgroundColor?.resolve(<WidgetState>{}),
        BrandColors.blue50,
      );
      expect(soft?.foregroundColor?.resolve(<WidgetState>{}), BrandColors.blue);
      expect(soft?.side?.resolve(<WidgetState>{}), BorderSide.none);
      expect(
        soft?.overlayColor?.resolve(<WidgetState>{WidgetState.pressed}),
        BrandColors.blue100,
      );
      // FilledButton.tonal reads the scheme: the same soft pair.
      expect(theme.colorScheme.secondaryContainer, BrandColors.blue50);
      expect(theme.colorScheme.onSecondaryContainer, BrandColors.blue);
    });

    test('a filled field rests soft and focuses white with a ring', () {
      final InputDecorationThemeData input = theme.inputDecorationTheme;
      final Color? fill = input.fillColor;
      expect(input.filled, isTrue);
      expect(
        WidgetStateProperty.resolveAs<Color?>(fill, <WidgetState>{}),
        BrandColors.softFill,
      );
      expect(
        WidgetStateProperty.resolveAs<Color?>(fill, <WidgetState>{
          WidgetState.focused,
        }),
        Colors.white,
      );
      expect(
        WidgetStateProperty.resolveAs<Color?>(fill, <WidgetState>{
          WidgetState.error,
        }),
        BrandColors.errorFill,
      );

      final RingedInputBorder rest = input.enabledBorder as RingedInputBorder;
      expect(rest.borderSide.color, BrandColors.transparent);
      expect(rest.borderSide.width, 1.5);
      expect(rest.borderRadius, BorderRadius.circular(Radii.field));
      expect(rest.ring, BorderSide.none);

      final RingedInputBorder focused =
          input.focusedBorder as RingedInputBorder;
      expect(focused.borderSide.color, BrandColors.blue);
      expect(focused.borderSide.width, 1.5);
      expect(focused.ring.color, FocusRing.ring);
      expect(focused.ring.width, 3);
      expect(FocusRing.ring, BrandColors.blue.withAlpha(0x24));
    });

    test('chips are fully round, 13.5 / 600, blue when selected', () {
      final ChipThemeData chip = theme.chipTheme;
      expect(chip.shape, const StadiumBorder());
      expect(chip.side, BorderSide.none);
      expect(chip.labelStyle?.fontSize, 13.5);
      expect(chip.labelStyle?.fontWeight, FontWeight.w600);
      expect(
        chip.color?.resolve(<WidgetState>{WidgetState.selected}),
        BrandColors.blue,
      );
      expect(chip.color?.resolve(<WidgetState>{}), BrandColors.chipFill);
    });

    test('list rows are 64 high with 13.5 / 600 titles', () {
      expect(theme.listTileTheme.minTileHeight, 64);
      expect(theme.listTileTheme.titleTextStyle?.fontSize, 13.5);
      expect(theme.listTileTheme.subtitleTextStyle?.fontSize, 12.5);
    });

    test('navigation labels stay 11', () {
      final WidgetStateProperty<TextStyle?>? label =
          theme.navigationBarTheme.labelTextStyle;
      expect(label?.resolve(<WidgetState>{})?.fontSize, 11);
      expect(label?.resolve(<WidgetState>{WidgetState.selected})?.fontSize, 11);
      expect(theme.navigationBarTheme.indicatorColor, BrandColors.blue100);
    });

    test('dialogs are centred, flat and rounded 22', () {
      expect(theme.dialogTheme.alignment, Alignment.center);
      expect(
        theme.dialogTheme.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      );
    });

    test('bottom sheets are white with top corners 28', () {
      expect(theme.bottomSheetTheme.backgroundColor, Colors.white);
      expect(
        theme.bottomSheetTheme.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      );
    });
  });

  group('ringed input border', () {
    test('paints the ring outside the border, then the border', () {
      const Rect field = Rect.fromLTWH(0, 0, 200, 54);
      const RingedInputBorder border = RingedInputBorder(
        borderSide: BorderSide(color: BrandColors.blue, width: 1.5),
        ring: BorderSide(color: FocusRing.ring, width: 3),
      );
      final RRect outer = BorderRadius.circular(Radii.field).toRRect(field);
      expect(
        (Canvas canvas) => border.paint(canvas, field),
        paints
          ..rrect(
            rrect: outer.inflate(1.5),
            color: FocusRing.ring,
            strokeWidth: 3,
          )
          ..rrect(
            rrect: outer.deflate(0.75),
            color: BrandColors.blue,
            strokeWidth: 1.5,
          ),
      );
    });

    test('keeps its ring through copyWith, scale and lerp', () {
      const RingedInputBorder rest = RingedInputBorder(
        borderSide: BorderSide(color: BrandColors.transparent, width: 1.5),
      );
      const RingedInputBorder focused = RingedInputBorder(
        borderSide: BorderSide(color: BrandColors.blue, width: 1.5),
        ring: BorderSide(color: FocusRing.ring, width: 3),
      );
      expect(focused.copyWith(gapPadding: 2).ring, focused.ring);
      expect(focused.scale(1).ring, focused.ring);
      final ShapeBorder? end = ShapeBorder.lerp(rest, focused, 1);
      expect(end, isA<RingedInputBorder>());
      expect((end as RingedInputBorder).ring, focused.ring);
      final ShapeBorder? middle = ShapeBorder.lerp(rest, focused, 0.5);
      expect(middle, isA<RingedInputBorder>());
    });
  });

  group('under the theme', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      double scale = 1,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: (BuildContext context, Widget? widget) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: widget ?? const SizedBox.shrink(),
          ),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('a text field is 54 high', (WidgetTester tester) async {
      await pump(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(decoration: InputDecoration(hintText: 'Name')),
        ),
      );
      expect(tester.getSize(find.byType(TextField)).height, 54);
    });

    testWidgets('a filled button is 52 high', (WidgetTester tester) async {
      await pump(
        tester,
        const Center(
          child: FilledButton(onPressed: _noop, child: Text('Continue')),
        ),
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52),
      );
    });

    for (final double scale in <double>[1, 2]) {
      testWidgets('the gallery theme section lays out at ${scale}x', (
        WidgetTester tester,
      ) async {
        await pump(
          tester,
          const SingleChildScrollView(child: ThemeGallerySection()),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Primary'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      });
    }

    testWidgets('the gallery opens a centred dialog', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const SingleChildScrollView(child: ThemeGallerySection()),
      );
      await tester.scrollUntilVisible(
        find.text('Dialog'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();
      final Rect dialog = tester.getRect(find.byType(AlertDialog));
      expect(dialog.center.dx, moreOrLessEquals(180, epsilon: 1));
      expect(dialog.center.dy, moreOrLessEquals(400, epsilon: 1));
    });
  });
}

void _noop() {}
