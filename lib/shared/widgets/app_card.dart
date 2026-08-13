import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';

/// A surface that groups related content.
///
/// Depth comes from Material 3 surface *tone* plus a hairline outline, not from a
/// shadow. Tonal elevation survives dark mode and high-contrast, where a shadow
/// tuned on a white background becomes invisible — and an outline is what
/// actually communicates the boundary to a low-vision resident.
///
/// When [onTap] is supplied the whole card becomes one target, with ink and a
/// focus ring from `InkWell`, so a card is not a place where keyboard focus
/// silently disappears.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.emphasis = CardEmphasis.normal,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final CardEmphasis emphasis;

  /// Accessible name for a tappable card, which otherwise announces as the
  /// concatenation of everything inside it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduced = Motion.reduced(context);
    final radius = BorderRadius.circular(Radii.lg);

    final (Color background, Color border) = switch (emphasis) {
      CardEmphasis.normal => (scheme.surfaceContainerLow, scheme.outlineVariant),
      CardEmphasis.raised => (scheme.surfaceContainer, scheme.outlineVariant),
      CardEmphasis.selected => (scheme.secondaryContainer, scheme.primary),
    };

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: () {
          unawaited(
            AppHaptics.fire(HapticIntent.selection, suppressed: reduced),
          );
          onTap!();
        },
        borderRadius: radius,
        child: content,
      );
    }

    final card = Material(
      color: background,
      elevation: Elevation.none,
      clipBehavior: Clip.antiAlias,
      // `shape` carries the radius; Material rejects both at once.
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: border,
          width: emphasis == CardEmphasis.selected ? 1.5 : 1,
        ),
      ),
      child: content,
    );

    if (semanticLabel == null) return card;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: card,
    );
  }
}

/// How much a card should stand out.
enum CardEmphasis {
  /// The default.
  normal,

  /// Slightly lifted — a card that summarises the ones below it.
  raised,

  /// Currently chosen. Carries a coloured outline as well as a tinted fill, so
  /// selection is not signalled by colour alone (WCAG 1.4.1).
  selected,
}
