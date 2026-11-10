import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

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
    // Redesign Phase 4: drawn as the soft note (CSS `.note`, the same look as
    // `SoftNote`): a tinted fill, no border, no shadow, a distinct Lucide icon
    // per tone so the tone never rests on colour alone.
    final (Color background, Color foreground, IconData icon) = switch (tone) {
      BannerTone.info => (
        BrandColors.blue50,
        BrandColors.text,
        TaytayIcons.info,
      ),
      BannerTone.success => (
        BrandColors.green50,
        BrandColors.green,
        TaytayIcons.circleCheck,
      ),
      BannerTone.warning => (
        BrandColors.gold50,
        BrandColors.goldInk,
        TaytayIcons.triangleAlert,
      ),
      BannerTone.error => (
        BrandColors.red50,
        BrandColors.redInk,
        TaytayIcons.circleAlert,
      ),
    };
    final String? title = this.title;
    final Widget? action = this.action;
    final VoidCallback? onDismiss = this.onDismiss;
    final TextStyle style = AppTypography.listDetail.copyWith(
      color: foreground,
      height: 1.45,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.note),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.section,
            Spacing.md,
            onDismiss == null ? Spacing.section : Spacing.xxs,
            Spacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TaytayIcon(
                icon: icon,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: foreground,
              ),
              const SizedBox(width: Spacing.sm + Spacing.xxs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (title != null) ...<Widget>[
                      Text(
                        title,
                        style: style.copyWith(fontWeight: AppTypography.strong),
                      ),
                      const SizedBox(height: Spacing.xxs),
                    ],
                    if (message.isNotEmpty) Text(message, style: style),
                    if (action != null) ...<Widget>[
                      const SizedBox(height: Spacing.sm),
                      action,
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const TaytayIcon(
                    icon: TaytayIcons.close,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                  ),
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
      ),
    );
  }
}
