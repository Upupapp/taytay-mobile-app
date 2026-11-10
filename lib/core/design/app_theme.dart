import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion_tokens.dart';
import 'design_tokens.dart';
import 'ringed_input_border.dart';
import 'typography.dart';

/// Builds the app's Material 3 themes from [BrandColors].
///
/// **Why Material 3, and a bundled font.**
///
/// Material 3 is the accessibility foundation: its colour roles carry tested
/// contrast pairings, its components ship correct semantics and focus
/// indicators, and it responds to system text scaling and high-contrast settings
/// without per-widget work.
///
/// The typeface is Plus Jakarta Sans, shipped as an asset (OFL). It is not
/// fetched at runtime. A font from a third-party CDN on first launch is an
/// avoidable data disclosure, and it leaves unstyled text on the weak
/// connections many residents have.
///
/// **The 2026-11 redesign** (`design/README.md`). Every component is flat —
/// no elevation and no shadow colour anywhere — and the components a screen
/// reaches for without styling (app bar, card, filled field, filled and soft
/// buttons, chip, list row, navigation bar, centred dialog, bottom sheet) land
/// on the redesign's colours, radii and sizes.
///
/// **Light mode is what the app shows today** (decision D9). [dark] still
/// exists so the contrast suite and the later dark-scheme pass have a theme to
/// check. The running app uses [ThemeMode.light] until that pass lands.
abstract final class AppTheme {
  /// What [MaterialApp] is given. Light only, until a dark-scheme pass exists.
  static const ThemeMode themeMode = ThemeMode.light;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool light = brightness == Brightness.light;
    final ColorScheme seeded = ColorScheme.fromSeed(
      seedColor: BrandColors.blue,
      brightness: brightness,
    );
    // Light mode pins every role the redesign names, rather than letting the
    // tonal algorithm reinterpret the blue. Dark mode keeps the generated
    // tones, because the literal blue cannot reach 4.5:1 against a dark
    // surface; only the shadow goes.
    final ColorScheme scheme = light
        ? seeded.copyWith(
            primary: BrandColors.blue,
            onPrimary: Colors.white,
            primaryContainer: BrandColors.blue50,
            onPrimaryContainer: BrandColors.blue,
            secondary: BrandColors.blue,
            onSecondary: Colors.white,
            secondaryContainer: BrandColors.blue50,
            onSecondaryContainer: BrandColors.blue,
            tertiary: BrandColors.goldInk,
            onTertiary: Colors.white,
            tertiaryContainer: BrandColors.gold50,
            onTertiaryContainer: BrandColors.goldInk,
            error: BrandColors.danger,
            onError: Colors.white,
            errorContainer: BrandColors.red50,
            onErrorContainer: BrandColors.redInk,
            surface: BrandColors.background,
            onSurface: BrandColors.ink,
            onSurfaceVariant: BrandColors.muted,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainer: Colors.white,
            surfaceContainerHigh: Colors.white,
            // Skeletons, placeholders and the M3 filled field read this.
            surfaceContainerHighest: BrandColors.softFill,
            outlineVariant: BrandColors.divider,
            shadow: BrandColors.transparent,
          )
        : seeded.copyWith(shadow: BrandColors.transparent);

    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final TextTheme textTheme = AppTypography.apply(
      base.textTheme,
      bodyColor: light ? BrandColors.text : null,
      supportingColor: light ? BrandColors.muted : null,
    );

    // Light-mode values from the redesign; dark mode falls back to roles.
    final Color card = light ? Colors.white : scheme.surfaceContainerLow;
    final Color ink = light ? BrandColors.ink : scheme.onSurface;
    final Color muted = light ? BrandColors.muted : scheme.onSurfaceVariant;
    final Color fieldFill = light
        ? BrandColors.softFill
        : scheme.surfaceContainerHighest;
    final Color softFill = light
        ? BrandColors.blue50
        : scheme.secondaryContainer;
    final Color onSoft = light ? BrandColors.blue : scheme.onSecondaryContainer;
    final Color softPressed = light
        ? BrandColors.blue100
        : scheme.secondaryContainer;

    final OutlinedBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.button),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: light ? BrandColors.background : scheme.surface,
      visualDensity: VisualDensity.standard,
      // Ensures every Material tap target reserves at least 48x48 dp, including
      // icon buttons inside dense list rows and 36 dp chips.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      shadowColor: BrandColors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ReducedMotionPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // The blue header bar (CSS `.soft header.bar`). A theme cannot paint a
      // gradient or the two circles: those are Phase 2's BlueHeader. This is
      // the solid fallback a plain AppBar gets.
      appBarTheme: AppBarTheme(
        backgroundColor: light ? BrandColors.blue : scheme.surface,
        foregroundColor: light ? Colors.white : scheme.onSurface,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        elevation: Elevation.none,
        scrolledUnderElevation: Elevation.none,
        centerTitle: false,
        toolbarHeight: 72,
        // 48 dp target plus a little room so the circle is not clipped.
        leadingWidth: A11y.minTapTarget + Spacing.sm,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(Radii.header),
          ),
        ),
        iconTheme: IconThemeData(
          color: light ? Colors.white : scheme.onSurface,
          size: IconSizes.md,
        ),
        actionsIconTheme: IconThemeData(
          color: light ? Colors.white : scheme.onSurface,
          size: IconSizes.md,
        ),
        titleTextStyle: AppTypography.headerTitle.copyWith(
          color: light ? Colors.white : scheme.onSurface,
        ),
        systemOverlayStyle: light
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      // Soft card: white on the page, no border, radius 20.
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        elevation: Elevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      // Primary. No colours here, so FilledButton.tonal keeps the scheme's
      // secondaryContainer pair: blue-50 and blue, the soft secondary.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(ComponentSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          elevation: Elevation.none,
          shadowColor: BrandColors.transparent,
          textStyle: AppTypography.button,
        ),
      ),
      // Outlined secondary buttons are gone from the redesign: an
      // OutlinedButton is drawn as the soft secondary (blue-50, no border).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              backgroundColor: softFill,
              foregroundColor: onSoft,
              disabledBackgroundColor: light
                  ? BrandColors.chipFill
                  : scheme.surfaceContainerHighest,
              disabledForegroundColor: muted,
              side: BorderSide.none,
              minimumSize: const Size.fromHeight(ComponentSizes.buttonHeight),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: buttonShape,
              elevation: Elevation.none,
              shadowColor: BrandColors.transparent,
              textStyle: AppTypography.button,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed) ||
                    states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  return softPressed;
                }
                return null;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
          foregroundColor: light ? BrandColors.blue : scheme.primary,
          textStyle: AppTypography.link,
          shape: buttonShape,
        ),
      ),
      // Filter chips: fully round, 13.5 / 600, quiet fill, blue when selected.
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return light ? BrandColors.blue : scheme.primary;
          }
          if (states.contains(WidgetState.disabled)) {
            return light ? BrandColors.line : scheme.surfaceContainerHighest;
          }
          return light ? BrandColors.chipFill : scheme.surfaceContainerHighest;
        }),
        labelStyle: AppTypography.chip.copyWith(
          color: WidgetStateColor.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return light ? Colors.white : scheme.onPrimary;
            }
            if (states.contains(WidgetState.disabled)) {
              return muted;
            }
            return light ? BrandColors.text : scheme.onSurface;
          }),
        ),
        iconTheme: IconThemeData(size: IconSizes.sm, color: onSoft),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        showCheckmark: false,
        checkmarkColor: Colors.white,
        elevation: Elevation.none,
        pressElevation: Elevation.none,
        shadowColor: BrandColors.transparent,
        selectedShadowColor: BrandColors.transparent,
        surfaceTintColor: BrandColors.transparent,
        // 16.2 px of label + 2 × 9.9 = 36 tall; 6 + 8 = 14 px each side.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9.9),
        labelPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      ),
      // Filled field: soft fill and a transparent border at rest; white fill,
      // 1.5 px blue border and a 3 px ring at 14% when focused.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.focused)) {
            return light ? Colors.white : scheme.surface;
          }
          if (states.contains(WidgetState.error)) {
            return light ? BrandColors.errorFill : fieldFill;
          }
          return fieldFill;
        }),
        hoverColor: light
            ? BrandColors.softFillHover
            : scheme.surfaceContainerHigh,
        // bodyLarge is 14 × 1.5 = 21 px of line; 21 + 2 × 16.5 = 54.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: 16.5,
        ),
        hintStyle: AppTypography.fieldValue.copyWith(
          fontWeight: AppTypography.body,
          color: light ? BrandColors.fieldHint : muted,
        ),
        labelStyle: AppTypography.label.copyWith(
          color: light ? BrandColors.text : muted,
        ),
        floatingLabelStyle: AppTypography.label.copyWith(
          color: light ? BrandColors.blue : scheme.primary,
        ),
        helperStyle: AppTypography.fieldHelp.copyWith(color: muted),
        errorStyle: AppTypography.fieldHelp.copyWith(
          color: light ? BrandColors.redInk : scheme.error,
          fontWeight: AppTypography.strong,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.focused)
              ? (light ? BrandColors.blue : scheme.primary)
              : muted,
        ),
        suffixIconColor: muted,
        border: _fieldBorder(BrandColors.transparent),
        enabledBorder: _fieldBorder(BrandColors.transparent),
        disabledBorder: _fieldBorder(BrandColors.transparent),
        focusedBorder: _fieldBorder(
          light ? BrandColors.blue : scheme.primary,
          ring: FocusRing.ring,
        ),
        errorBorder: _fieldBorder(light ? BrandColors.red : scheme.error),
        focusedErrorBorder: _fieldBorder(
          light ? BrandColors.red : scheme.error,
          ring: FocusRing.errorRing,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: Elevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
        ),
      ),
      // List row (CSS `.soft .li`): 64 high, 14 / 16 padding, 12 to the tile.
      listTileTheme: ListTileThemeData(
        minTileHeight: ComponentSizes.listRow,
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        horizontalTitleGap: Spacing.md,
        iconColor: light ? BrandColors.blue : scheme.primary,
        textColor: ink,
        titleTextStyle: AppTypography.listTitle.copyWith(color: ink),
        subtitleTextStyle: AppTypography.listDetail.copyWith(color: muted),
        leadingAndTrailingTextStyle: AppTypography.small.copyWith(color: muted),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      // Bottom navigation (BottomNav.dc.html): labels stay 11.
      navigationBarTheme: NavigationBarThemeData(
        height: ComponentSizes.navigationBar,
        backgroundColor: card,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        elevation: Elevation.none,
        indicatorColor: light ? BrandColors.blue100 : scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? AppTypography.navLabelSelected.copyWith(
                  color: light ? BrandColors.blue : scheme.primary,
                )
              : AppTypography.navLabel.copyWith(color: muted);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
          Set<WidgetState> states,
        ) {
          return IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? (light ? BrandColors.blue : scheme.primary)
                : muted,
          );
        }),
      ),
      // Popups are centred, flat and rounded 22.
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        elevation: Elevation.dialog,
        alignment: Alignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.dialog),
        ),
        titleTextStyle: AppTypography.pageTitle.copyWith(color: ink),
        contentTextStyle: AppTypography.bodyStyle.copyWith(
          color: light ? BrandColors.text : scheme.onSurface,
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.xl,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        elevation: Elevation.floating,
        modalElevation: Elevation.floating,
        showDragHandle: true,
        dragHandleColor: light ? BrandColors.line2 : scheme.outlineVariant,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheetLarge),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        elevation: Elevation.none,
        surfaceTintColor: BrandColors.transparent,
        shadowColor: BrandColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.field),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: light ? BrandColors.blue : scheme.primary,
        linearTrackColor: light ? BrandColors.line : scheme.surfaceContainer,
        circularTrackColor: BrandColors.transparent,
      ),
      iconTheme: IconThemeData(
        size: IconSizes.md,
        color: scheme.onSurfaceVariant,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static RingedInputBorder _fieldBorder(Color color, {Color? ring}) {
    return RingedInputBorder(
      borderSide: BorderSide(color: color, width: FocusRing.borderWidth),
      ring: ring == null
          ? BorderSide.none
          : BorderSide(color: ring, width: FocusRing.ringWidth),
    );
  }

  /// Clamps the OS text scale into the range the layouts are tested against and
  /// disables animations when the platform asks for reduced motion.
  ///
  /// Applied once, at the app root, so no screen has to remember. Text scaling
  /// is *clamped, never ignored*: the resident's setting is honoured up to the
  /// point where the app can still be used.
  static Widget applyAccessibilityMediaQuery({
    required BuildContext context,
    required Widget child,
  }) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          minScaleFactor: A11y.minSupportedTextScale,
          maxScaleFactor: A11y.maxSupportedTextScale,
        ),
      ),
      child: child,
    );
  }
}

/// Page transition that fades and slides forward, in the spirit of Material 3's
/// forward transition, but which stops travelling when the platform asks for
/// reduced motion.
///
/// Flutter's own [FadeForwardsPageTransitionsBuilder] does not consult
/// `MediaQuery.disableAnimations`, so a resident with "Remove animations" set
/// would still see the screen slide. Owning the builder is the only place that
/// can be fixed once for every route.
class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = context != null && Motion.reduced(context);
    if (reduced) {
      // Under reduced motion the screen still needs to change; it just must not
      // travel. A cross-fade keeps the transition legible without movement.
      return FadeTransition(opacity: animation, child: child);
    }
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: MotionTokens.enterEase)).animate(animation),
        child: child,
      ),
    );
  }
}
