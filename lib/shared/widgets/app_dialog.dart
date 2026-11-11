import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import 'app_button.dart';

/// The app's centred dialogs: every gate, notice, confirmation and decision
/// (design rule: popups are centred). `AppSheet` is for pickers only — a list
/// of choices the resident picks one from.
///
/// **Built on Flutter's own [showDialog] route and [Dialog], deliberately.**
/// The route is what traps focus inside the dialog, puts a dismissible scrim
/// behind it, scopes it for a screen reader and hands focus back to whatever
/// opened it when it closes. A hand-rolled or packaged dialog has to re-earn
/// each of those and usually loses one, which is the difference between usable
/// and unusable for a screen-reader or keyboard user.
///
/// **One way to draw one** (D-202). [show] lays out every dialog the same:
/// an optional hero icon, the title (a heading that names the route, so a
/// screen reader says what opened), the content, then the actions in
/// [AppDialogActions] — a primary button over a text button. [confirm] and
/// [acknowledge] are [show] with a sentence and the actions filled in. The
/// theme's dialog draws the surface: centred, radius 22, flat.
///
/// Callers that navigate afterwards must `await` the returned future:
/// dismissing a route while its dialog is still on top leaves the dialog
/// orphaned over the new screen.
abstract final class AppDialog {
  /// Space between a centred dialog and the screen edges. Narrower than
  /// Material's 40 at the sides, so a 360 dp phone at 200% text keeps a usable
  /// line length.
  static const EdgeInsets panelInset = EdgeInsets.symmetric(
    horizontal: Spacing.formGutter,
    vertical: Spacing.xl,
  );

  /// Shows a centred dialog with a [title] and the content [builder] returns,
  /// and resolves to whatever it pops with (`null` for Back or a scrim tap).
  ///
  /// [actions] draws the buttons under the content from the dialog's own
  /// context, so a button can pop it: `(dialog) => AppDialogActions(...)`.
  /// Content whose buttons follow its own state (a form, a step that changes)
  /// draws [AppDialogActions] as its last child instead; it looks the same.
  ///
  /// [scrollable] (the default) puts the title, the content and the actions in
  /// one scroll view, so 200% text on a 360 dp phone scrolls and never clips.
  /// Pass false for content that scrolls itself (a long list): the content
  /// then takes the height left between the title and the actions, which stay
  /// in view.
  ///
  /// [icon] is a hero icon above the title, which is then centred (Material
  /// 3's dialog). [dismissible] false keeps a scrim tap from closing it. The
  /// dialog rises above the keyboard when a field inside it has focus.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    AppDialogActions Function(BuildContext dialogContext)? actions,
    Widget? icon,
    bool scrollable = true,
    bool dismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext dialogContext) => Dialog(
        insetPadding: panelInset,
        child: AppDialogPanel(
          title: title,
          icon: icon,
          scrollable: scrollable,
          actions: actions?.call(dialogContext),
          child: builder(dialogContext),
        ),
      ),
    );
  }

  /// Shows a confirmation and resolves to `true` when confirmed, `false` when
  /// cancelled, and `null` when dismissed by back gesture or scrim tap.
  ///
  /// [destructive] styles the confirm action as danger and fires a warning
  /// haptic when the dialog appears — a physical cue that this one is different,
  /// paired with the visible styling rather than replacing it. A destructive
  /// confirmation is not dismissed by a scrim tap: an accidental tap resolving
  /// a "delete?" prompt is the wrong default.
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
    return show<bool>(
      context: context,
      title: title,
      dismissible: !destructive,
      builder: (BuildContext dialog) => AppDialogMessage(message),
      actions: (BuildContext dialog) => AppDialogActions(
        primary: DialogButton(
          label: confirmLabel,
          destructive: destructive,
          hapticIntent: destructive
              ? HapticIntent.warning
              : HapticIntent.confirm,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
        text: DialogButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
      ),
    );
  }

  /// Shows a message with a single acknowledging action, drawn as the text
  /// action like every other way out of a dialog.
  static Future<void> acknowledge({
    required BuildContext context,
    required String title,
    required String message,
    String actionLabel = 'OK',
  }) {
    return show<void>(
      context: context,
      title: title,
      builder: (BuildContext dialog) => AppDialogMessage(message),
      actions: (BuildContext dialog) =>
          AppDialogActions.close(dialog, label: actionLabel),
    );
  }
}

/// A dialog's message: the body style the theme gives dialog content.
class AppDialogMessage extends StatelessWidget {
  const AppDialogMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      message,
      style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium,
    );
  }
}

/// One button in [AppDialogActions].
///
/// [onPressed] null disables it. [destructive] draws the primary button as
/// danger. [loading] keeps the button's size while it shows progress.
@immutable
class DialogButton {
  const DialogButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.icon,
    this.loading = false,
    this.hapticIntent = HapticIntent.selection,
    this.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final IconData? icon;
  final bool loading;
  final HapticIntent hapticIntent;
  final Key? key;
}

/// The buttons at the foot of every dialog, drawn one way: the [primary]
/// button (the way forward), an optional [secondary] soft button (a second
/// way forward, as "Create account" is beside "Sign in"), then the [text]
/// button — Cancel, Close, Not now, Keep browsing. Each is full width and at
/// least 48 dp tall, stacked, so 200% text never pushes one off the dialog.
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({this.primary, this.secondary, this.text, super.key})
    : assert(
        primary != null || secondary != null || text != null,
        'A dialog actions bar needs at least one button.',
      );

  /// The one way out of a notice: a text button that closes the dialog
  /// [dialogContext] belongs to. "Close" unless [label] says otherwise.
  factory AppDialogActions.close(
    BuildContext dialogContext, {
    String label = 'Close',
    Key? closeKey,
  }) {
    return AppDialogActions(
      text: DialogButton(
        label: label,
        key: closeKey,
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  final DialogButton? primary;
  final DialogButton? secondary;
  final DialogButton? text;

  @override
  Widget build(BuildContext context) {
    final DialogButton? primary = this.primary;
    final DialogButton? secondary = this.secondary;
    final DialogButton? text = this.text;
    final List<Widget> buttons = <Widget>[
      if (primary != null)
        _button(
          primary,
          primary.destructive
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
        ),
      if (secondary != null) _button(secondary, AppButtonVariant.secondary),
      if (text != null) _button(text, AppButtonVariant.text),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < buttons.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: Spacing.sm),
            buttons[i],
          ],
        ],
      ),
    );
  }

  static Widget _button(DialogButton button, AppButtonVariant variant) {
    return AppButton(
      key: button.key,
      label: button.label,
      variant: variant,
      icon: button.icon,
      loading: button.loading,
      hapticIntent: button.hapticIntent,
      onPressed: button.onPressed,
    );
  }
}

/// The inside of an [AppDialog.show] dialog: the hero icon, the title
/// announced as a heading that names the route, the content, the actions.
///
/// Public so a specimen (the gallery, a recording frame) can draw a dialog
/// exactly as it opens, inside a [Dialog], without opening a route.
class AppDialogPanel extends StatelessWidget {
  const AppDialogPanel({
    required this.title,
    required this.child,
    this.actions,
    this.icon,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final Widget child;
  final AppDialogActions? actions;
  final Widget? icon;
  final bool scrollable;

  static const EdgeInsets _padding = EdgeInsets.all(Spacing.xl);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget? icon = this.icon;
    final AppDialogActions? actions = this.actions;
    final Widget heading = Semantics(
      container: true,
      header: true,
      // Names the dialog's route, so a screen reader says what opened rather
      // than only that something did — as the bottom sheets this replaced did.
      namesRoute: true,
      child: Text(
        title,
        textAlign: icon == null ? TextAlign.start : TextAlign.center,
        style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge,
      ),
    );
    final List<Widget> top = <Widget>[
      if (icon != null) ...<Widget>[
        Center(child: icon),
        const SizedBox(height: Spacing.lg),
      ],
      heading,
      const SizedBox(height: Spacing.md),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ComponentSizes.dialogMaxWidth,
      ),
      child: scrollable
          ? SingleChildScrollView(
              padding: _padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[...top, child, ?actions],
              ),
            )
          : Padding(
              padding: _padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...top,
                  Flexible(child: child),
                  ?actions,
                ],
              ),
            ),
    );
  }
}
