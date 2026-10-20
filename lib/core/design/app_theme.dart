import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../motion/motion_tokens.dart';
import 'design_tokens.dart';
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
/// **Light mode is what the app shows today** (decision D9). [dark] still
/// exists so the contrast suite and the later dark-scheme pass have a theme to
/// check. The running app uses [ThemeMode.light] until that pass lands.
abstract final class AppTheme {
  /// What [MaterialApp] is given. Light only, until a dark-scheme pass exists.
  static const ThemeMode themeMode = ThemeMode.light;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: BrandColors.taytayBlue,
          brightness: brightness,
        ).copyWith(
          // Keep the chosen blue exact in light mode rather than letting the
          // tonal algorithm reinterpret it. In dark mode the
          // generated tone is kept, because the literal blue cannot reach 4.5:1
          // against a dark surface.
          primary: brightness == Brightness.light
              ? BrandColors.taytayBlue
              : null,
          onPrimary: brightness == Brightness.light ? Colors.white : null,
          error: brightness == Brightness.light ? BrandColors.danger : null,
          onError: brightness == Brightness.light ? Colors.white : null,
          surface: brightness == Brightness.light ? BrandColors.surface : null,
          onSurface: brightness == Brightness.light
              ? BrandColors.textPrimary
              : null,
          onSurfaceVariant: brightness == Brightness.light
              ? BrandColors.textSecondary
              : null,
          surfaceContainerLowest: brightness == Brightness.light
              ? BrandColors.surfaceCard
              : null,
          surfaceContainerLow: brightness == Brightness.light
              ? BrandColors.surfaceMuted
              : null,
          surfaceContainerHighest: brightness == Brightness.light
              ? BrandColors.surfaceCard
              : null,
        );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      textTheme: AppTypography.apply(base.textTheme),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? BrandColors.surface
          : scheme.surface,
      visualDensity: VisualDensity.standard,
      // Ensures every Material tap target reserves at least 48x48 dp, including
      // icon buttons inside dense list rows.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ReducedMotionPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: Elevation.none,
        scrolledUnderElevation: Elevation.scrolledUnder,
        centerTitle: false,
        // 48 dp target plus a little room so the circle is not clipped.
        leadingWidth: A11y.minTapTarget + Spacing.sm,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: Elevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(A11y.minTapTarget + Spacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(A11y.minTapTarget + Spacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.lg,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: Spacing.md,
        contentPadding: EdgeInsets.symmetric(horizontal: Spacing.lg),
      ),
      dividerTheme: DividerThemeData(space: 1, color: scheme.outlineVariant),
      dialogTheme: DialogThemeData(
        elevation: Elevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: Elevation.floating,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      iconTheme: IconThemeData(
        size: IconSizes.md,
        color: scheme.onSurfaceVariant,
      ),
      splashFactory: InkSparkle.splashFactory,
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
