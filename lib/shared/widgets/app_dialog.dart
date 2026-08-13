import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import 'app_button.dart';

/// The app's confirmation dialog.
///
/// **Built on Flutter's own [AlertDialog], deliberately.** A hand-rolled or
/// packaged dialog has to re-earn focus trapping, scrim semantics, correct
/// text scaling, dismissal handling and focus restoration — and the usual
/// outcome is that it earns most of them and loses one, which is the difference
/// between usable and unusable for a screen-reader or keyboard user. A dependency
/// added for visual polish can also hold a release hostage at store submission,
/// which is not a risk worth taking for rounded corners.
///
/// Callers that navigate afterwards must `await` the returned future: dismissing
/// a route while its dialog is still on top leaves the dialog orphaned over the
/// new screen.
abstract final class AppDialog {
  /// Shows a confirmation and resolves to `true` when confirmed, `false` when
  /// cancelled, and `null` when dismissed by back gesture or scrim tap.
  ///
  /// [destructive] styles the confirm action as danger and fires a warning
  /// haptic when the dialog appears — a physical cue that this one is different,
  /// paired with the visible styling rather than replacing it.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final reduced = Motion.reduced(context);
    if (destructive) {
      unawaited(AppHaptics.fire(HapticIntent.warning, suppressed: reduced));
    }

    return showDialog<bool>(
      context: context,
      // A destructive confirmation is not dismissible by tapping outside: an
      // accidental scrim tap resolving a "delete?" prompt is the wrong default.
      barrierDismissible: !destructive,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.lg,
        ),
        actions: <Widget>[
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.text,
            fullWidth: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: confirmLabel,
            variant: destructive
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            fullWidth: false,
            hapticIntent: destructive
                ? HapticIntent.warning
                : HapticIntent.confirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  /// Shows a message with a single acknowledging action.
  static Future<void> acknowledge({
    required BuildContext context,
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        actions: <Widget>[
          AppButton(
            label: actionLabel,
            variant: AppButtonVariant.text,
            fullWidth: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
