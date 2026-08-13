import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';

/// What a button is for, which decides how it looks.
///
/// Named by role rather than by appearance (`primary`, not `blue`) so the visual
/// treatment can change once without a rename across the app.
enum AppButtonVariant {
  /// The one action a screen is asking for. At most one per screen.
  primary,

  /// A real alternative to the primary action.
  secondary,

  /// A tertiary action — "Skip", "Not now", "Learn more".
  text,

  /// Destructive or irreversible. Deliberately styled apart from `primary` so a
  /// resident cannot confuse "Submit" with "Delete".
  danger,
}

/// The app's button.
///
/// Wraps Material's own buttons rather than replacing them, which keeps focus
/// rings, state layers, ink, disabled semantics and text scaling that Material 3
/// already gets right, and adds the three things every call site would otherwise
/// hand-roll: a **loading state that stays the same size**, a haptic tied to the
/// press, and a guaranteed minimum tap target.
///
/// The loading state matters more than it looks: swapping a label for a spinner
/// of a different size makes the button resize mid-press, which moves whatever is
/// under the resident's thumb.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconTrailing = false,
    this.loading = false,
    this.fullWidth = true,
    this.hapticIntent = HapticIntent.selection,
    this.semanticLabel,
    super.key,
  });

  final String label;

  /// `null` disables the button. A disabled button is announced as disabled by
  /// Material's own semantics.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;
  final bool iconTrailing;

  /// While true the button is inert and shows a progress indicator, without
  /// changing size.
  final bool loading;

  final bool fullWidth;

  /// Feedback fired on press. `confirm` for a submission, `selection` otherwise.
  final HapticIntent hapticIntent;

  /// Overrides the accessible name when the visible label is not enough on its
  /// own — "Continue" in a wizard, for example.
  final String? semanticLabel;

  bool get _isEnabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = Motion.reduced(context);

    void handlePress() {
      // The haptic never gates or delays the action.
      unawaited(AppHaptics.fire(hapticIntent, suppressed: reduced));
      onPressed!();
    }

    final child = _AppButtonContent(
      label: label,
      icon: icon,
      iconTrailing: iconTrailing,
      loading: loading,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: _isEnabled ? handlePress : null,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: _isEnabled ? handlePress : null,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: _isEnabled ? handlePress : null,
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: _isEnabled ? handlePress : null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
        ),
        child: child,
      ),
    };

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel,
      // While loading, tell a screen-reader user that something is happening —
      // a silently inert button reads as a broken one.
      hint: loading ? 'Loading' : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
        child: fullWidth ? SizedBox(width: double.infinity, child: button) : button,
      ),
    );
  }
}

class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.label,
    required this.icon,
    required this.iconTrailing,
    required this.loading,
  });

  final String label;
  final IconData? icon;
  final bool iconTrailing;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      // Stack keeps the label in the layout — invisible but still measured — so
      // the button holds exactly the width it had before the press.
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(opacity: 0, child: _label(context)),
          const SizedBox(
            width: IconSizes.sm,
            height: IconSizes.sm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    final iconWidget = icon == null
        ? null
        : Icon(icon, size: IconSizes.md);

    if (iconWidget == null) return _label(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!iconTrailing) ...<Widget>[
          iconWidget,
          const SizedBox(width: Spacing.sm),
        ],
        Flexible(child: _label(context)),
        if (iconTrailing) ...<Widget>[
          const SizedBox(width: Spacing.sm),
          iconWidget,
        ],
      ],
    );
  }

  Widget _label(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    // Two lines, so a long Filipino label at a large text scale wraps instead
    // of being clipped.
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );
}
