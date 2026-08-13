import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// The meaning a banner carries.
///
/// Each tone pairs a colour with a **distinct icon**, and the icon is not
/// optional. Colour alone must never be the only carrier of meaning (WCAG 1.4.1)
/// — roughly one in twelve men has a colour vision deficiency, and a
/// red-vs-amber distinction is exactly the pair they cannot make.
enum BannerTone {
  /// Neutral context a resident should know before acting.
  info,

  /// Something completed.
  success,

  /// Something needs attention before continuing, but nothing has failed.
  warning,

  /// Something failed, or is blocked.
  error,
}

/// An inline message attached to the content it concerns.
///
/// Inline rather than a snackbar for anything a resident may need to act on: a
/// snackbar disappears on a timer, which is a problem for anyone reading slowly,
/// using a screen reader, or filling a form while queueing. Snackbars stay for
/// transient confirmations only.
///
/// Marked as a live region so a screen reader announces it when it appears —
/// otherwise a validation banner is invisible to the residents most likely to
/// need it.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = BannerTone.info,
    this.title,
    this.action,
    this.onDismiss,
    super.key,
  });

  final String message;
  final BannerTone tone;
  final String? title;

  /// Optional trailing action, e.g. "Try again".
  final Widget? action;

  /// When supplied, a dismiss affordance is shown. Omit for anything that must
  /// not be dismissed, such as a blocking error.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Container/on-container pairs come from the ColorScheme so they stay
    // contrast-correct in dark mode. Only `warning` has no M3 role, so it uses
    // a brand token whose pairing is asserted in brand_test.dart.
    final (Color background, Color foreground, IconData icon) = switch (tone) {
      BannerTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline,
      ),
      BannerTone.success => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.check_circle_outline,
      ),
      BannerTone.warning => (
        const Color(0xFFFFF3D6),
        const Color(0xFF6B4400),
        Icons.warning_amber_outlined,
      ),
      BannerTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.md),
          // An outline as well as a fill, so the banner has an edge in
          // high-contrast mode where fills are flattened.
          border: Border.all(color: foreground.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: IconSizes.md, color: foreground),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                  ],
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (action != null) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    action!,
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: IconSizes.sm,
                color: foreground,
                tooltip: 'Dismiss',
                constraints: const BoxConstraints(
                  minWidth: A11y.minTapTarget,
                  minHeight: A11y.minTapTarget,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
