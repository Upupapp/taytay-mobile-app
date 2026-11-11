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

  /// Space between a centred panel dialog and the screen edges. Narrower than
  /// Material's 40 at the sides, so a 360 dp phone at 200% text keeps a usable
  /// line length.
  static const EdgeInsets panelInset = EdgeInsets.symmetric(
    horizontal: Spacing.formGutter,
    vertical: Spacing.xl,
  );

  /// Shows a centred dialog with a [title] and the content [builder] returns,
  /// and resolves to whatever the content pops with.
  ///
  /// The panel counterpart of `AppSheet`: every gate, notice, confirmation and
  /// decision opens here (design rule: popups are centred). `AppSheet` is for
  /// pickers only — a list of choices the resident picks one from.
  ///
  /// The theme's dialog draws it (centred, radius 22, flat). The content
  /// scrolls inside the dialog, so 200% text never clips it, and the dialog
  /// rises above the keyboard when a field inside it has focus.
  /// [dismissible] false keeps a scrim tap from closing it.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    bool dismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) => Dialog(
        insetPadding: panelInset,
        child: _DialogFrame(title: title, child: builder(dialogContext)),
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

/// The inside of an [AppDialog.show] panel: the title, announced as a
/// heading, then the content in a scroll view that takes what height is left.
class _DialogFrame extends StatelessWidget {
  const _DialogFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ComponentSizes.dialogMaxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.xl,
              Spacing.xl,
              Spacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style:
                    theme.dialogTheme.titleTextStyle ??
                    theme.textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                0,
                Spacing.xl,
                Spacing.xl,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
