import 'package:flutter/material.dart';

import '../../core/a11y/announcements.dart';
import '../../core/design/design_tokens.dart';

/// Tells a resident how something turned out — on screen **and** aloud.
///
/// ---
///
/// ## The gap this closes
///
/// A `SnackBar` is added to an overlay away from the focused node. TalkBack does
/// not move focus to it, VoiceOver does not read it, and on Android it vanishes
/// on a timer a screen-reader user has no way to notice. A sighted resident sees
/// "Your place has been given up"; a blind resident presses the button and hears
/// nothing, then has to explore the whole screen to work out whether they still
/// hold a place at a medical mission.
///
/// So every snackbar in this app goes through here, and every one of them is
/// also announced. The visible confirmation is unchanged — the announcement is
/// a second channel over it, never instead of it.
///
/// ## Why the tone is a parameter and not a guess
///
/// The announcement is prefixed differently for a problem than for a success,
/// because "That did not work" arriving before the sentence is the part a
/// screen-reader user needs first. Nothing here infers tone from the wording:
/// an app that decided "Sharing is not available on this device" sounded
/// positive would announce a failure as a success.
abstract final class Outcome {
  /// Something worked.
  static void succeeded(BuildContext context, String message) {
    _show(context, message);
    Announce.success(context, message);
  }

  /// Something did not work, or is unavailable.
  ///
  /// Not necessarily an error — a device with no share sheet and an event that
  /// filled are both states to read rather than faults to report — which is why
  /// this takes copy the caller already chose rather than an `AppFailure`.
  static void problem(BuildContext context, String message) {
    _show(context, message);
    Announce.problem(context, message);
  }

  static void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Long enough to read at a large text size. The Material default of
        // four seconds assumes one line at the default scale, and this app
        // supports 200%.
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(Spacing.lg),
      ),
    );
  }
}
