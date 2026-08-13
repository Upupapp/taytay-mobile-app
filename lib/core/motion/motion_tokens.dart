import 'package:flutter/material.dart';

/// Every duration and curve in the app.
///
/// Motion is centralised for two reasons. It keeps transitions consistent, and
/// — more importantly — it puts reduced-motion handling in one place. Vestibular
/// disorders are common, and a government service is not optional for the people
/// who have one: if the OS asks for less motion, the app must comply everywhere,
/// not in the screens someone remembered.
///
/// Durations follow the Material 3 motion scale (short/medium/long), named for
/// what they are used for rather than their length.
abstract final class MotionTokens {
  /// Immediate state swap; also the reduced-motion substitute for decorative
  /// animation.
  static const Duration instant = Duration.zero;

  /// 100 ms — state layer changes, ripples, switch thumbs.
  static const Duration micro = Duration(milliseconds: 100);

  /// 160 ms — press feedback, small reveals.
  static const Duration fast = Duration(milliseconds: 160);

  /// 280 ms — page transitions, sheets, the default for most animation.
  static const Duration standard = Duration(milliseconds: 280);

  /// 420 ms — emphasis reveals, full-screen dialogs.
  static const Duration emphasised = Duration(milliseconds: 420);

  /// 650 ms — completion moments (application submitted, ID issued).
  static const Duration celebration = Duration(milliseconds: 650);

  /// Minimum time the splash screen stays up, so it reads as intentional rather
  /// than as a flash. Session restore usually finishes well inside this.
  static const Duration splashMinimum = Duration(milliseconds: 900);

  /// Splash duration when reduced motion is requested.
  static const Duration splashReduced = Duration(milliseconds: 300);

  /// Standard easing for changes that both begin and end on screen.
  static const Curve standardEase = Curves.easeInOut;

  /// Elements entering the screen: fast start, soft settle.
  static const Curve enterEase = Curves.easeOutCubic;

  /// Elements leaving: gentle start, quick exit.
  static const Curve exitEase = Curves.easeInCubic;

  /// Material 3 "emphasized" easing, for the one element a screen is about.
  static const Curve emphasisedEase = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Reduced-motion helpers.
///
/// The signal is `MediaQuery.disableAnimations`, which Flutter derives from
/// "Remove animations" on Android and "Reduce Motion" on iOS.
abstract final class Motion {
  /// True when the platform asks for less motion.
  ///
  /// Prefer this over the binding-level check inside `build`, so a change to the
  /// setting rebuilds the widget.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Binding-level check for code with no [BuildContext] (`initState`, a
  /// controller). Does not rebuild on change.
  static bool get reducedFromPlatform => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  /// Shortens [full] to [MotionTokens.fast] under reduced motion.
  ///
  /// Use for functional motion that orients the resident — a page transition
  /// still needs to say where the new screen came from. For purely decorative
  /// motion, check [reduced] and skip the animation entirely.
  static Duration duration(BuildContext context, Duration full) =>
      reduced(context) ? MotionTokens.fast : full;

  /// [MotionTokens.instant] under reduced motion, otherwise [full]. For
  /// decorative animation that should disappear rather than shrink.
  static Duration decorative(BuildContext context, Duration full) =>
      reduced(context) ? MotionTokens.instant : full;
}
