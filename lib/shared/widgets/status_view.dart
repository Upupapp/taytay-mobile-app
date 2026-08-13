import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// What kind of situation a [StatusView] is reporting.
enum StatusKind {
  /// Nothing here yet, and nothing is wrong. No retry — retrying an empty list
  /// produces the same empty list, and offering the button implies a fault.
  empty,

  /// Something completed.
  success,

  /// Something failed. A retry is usually appropriate.
  error,
}

/// The full-surface "there is nothing to show, and here is why" state.
///
/// Empty and error are kept as separate kinds rather than one generic state
/// because they are genuinely different situations: "the office has no open
/// slots" and "we could not reach the office" call for different words and
/// different buttons, and collapsing them tells a resident their request failed
/// when it did not.
///
/// Scrolls rather than clipping, so it survives a 200% text scale on a short
/// screen.
class StatusView extends StatelessWidget {
  const StatusView({
    required this.title,
    required this.kind,
    this.message,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final String title;
  final StatusKind kind;
  final String? message;

  /// Overrides the default icon for the kind.
  final IconData? icon;

  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (IconData defaultIcon, Color iconColor) = switch (kind) {
      StatusKind.empty => (Icons.inbox_outlined, scheme.onSurfaceVariant),
      StatusKind.success => (Icons.check_circle_outline, scheme.primary),
      StatusKind.error => (Icons.error_outline, scheme.error),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight - Spacing.xxl
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(icon ?? defaultIcon, size: IconSizes.xxl, color: iconColor),
                const SizedBox(height: Spacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (primaryAction != null) ...<Widget>[
                  const SizedBox(height: Spacing.xl),
                  primaryAction!,
                ],
                if (secondaryAction != null) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  secondaryAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
