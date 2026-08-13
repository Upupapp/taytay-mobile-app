import 'package:flutter/services.dart';

/// Intent behind a haptic, so call sites describe *why* they buzz rather than
/// how strong the buzz is. The mapping to platform feedback lives here and can
/// change without touching a single screen.
enum HapticIntent {
  /// Discrete selection: tab change, chip, radio, stepper.
  selection,

  /// A meaningful action landed: form submitted, OTP accepted, sign-in.
  confirm,

  /// A significant milestone completed: verification approved, ID issued.
  success,

  /// Something needs attention before continuing, or is destructive:
  /// sign-out confirmation, discarding a draft, an expired session.
  warning,

  /// The action failed. Fired once — never once per retry.
  error,
}

/// Centralised haptic feedback.
///
/// Rules, in priority order:
///
/// 1. **Haptics are never the only signal.** A vibration is invisible to a
///    person holding the phone in a stand and inaudible to everyone; every
///    haptic accompanies a visible change.
/// 2. **Never on typing or passive scrolling.** Keystroke haptics are the most
///    common reason people disable app feedback wholesale.
/// 3. **Never repeated for the same failure.** Retrying a request that keeps
///    failing must not turn the phone into a buzzer.
/// 4. **Respect the OS and the resident's preference.** Reduced-motion also
///    suppresses non-essential haptics: the accessibility settings that reduce
///    animation are frequently set by people who find repeated physical feedback
///    unpleasant too.
/// 5. **Never throw.** A device with no vibration motor, or a platform channel
///    that is not available in a test, must not break a flow.
abstract final class AppHaptics {
  static bool _enabled = true;

  /// Set from the resident's settings. Does not affect OS-level feedback such as
  /// the keyboard's own haptics.
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Current preference, for the settings screen.
  static bool get isEnabled => _enabled;

  /// Fires the feedback for [intent]. Fire-and-forget; failures are swallowed.
  ///
  /// Pass `suppressed: true` from a widget that knows reduced motion is active
  /// (`Motion.reduced(context)`), so the decision stays testable and this class
  /// stays free of a `BuildContext`.
  static Future<void> fire(HapticIntent intent, {bool suppressed = false}) async {
    if (!_enabled || suppressed) return;
    try {
      switch (intent) {
        case HapticIntent.selection:
          await HapticFeedback.selectionClick();
        case HapticIntent.confirm:
          await HapticFeedback.mediumImpact();
        case HapticIntent.success:
          await HapticFeedback.heavyImpact();
        case HapticIntent.warning:
        case HapticIntent.error:
          // `vibrate` is the platform's attention pattern; distinct enough from
          // an impact that a resident can tell a failure from a success without
          // looking, while still being paired with visible copy.
          await HapticFeedback.vibrate();
      }
    } on Object {
      // Deliberately ignored: a haptic is an enhancement, never a dependency.
    }
  }
}
