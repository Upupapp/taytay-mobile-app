import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'icon_tile.dart';

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
    this.illustration,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final String title;
  final StatusKind kind;
  final String? message;

  /// Overrides the default icon for the kind.
  final IconData? icon;

  /// A drawn scene shown instead of the icon.
  ///
  /// Preferred for the states a resident lands on and reads — an empty list, a
  /// failed load, a completed submission — because a scene carries the tone of
  /// the message where a 56dp glyph cannot. The icon remains the default for
  /// dense or repeated states, where a full illustration would be noise.
  final Widget? illustration;

  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    // Redesign Phase 4: the state panel's look (CSS `.es`) — a large gradient
    // tile with a Lucide glyph, the title in ink, the sentence in muted.
    final (IconData defaultIcon, TileTone tone) = switch (kind) {
      StatusKind.empty => (TaytayIcons.inbox, TileTone.blue),
      StatusKind.success => (TaytayIcons.circleCheck, TileTone.green),
      StatusKind.error => (TaytayIcons.circleAlert, TileTone.red),
    };
    final String? message = this.message;
    final Widget? primaryAction = this.primaryAction;
    final Widget? secondaryAction = this.secondaryAction;

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
                illustration ??
                    IconTile.lucide(
                      icon: icon ?? defaultIcon,
                      tone: tone,
                      tileSize: IconTileSize.large,
                    ),
                const SizedBox(height: Spacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: AppTypography.strong,
                    color: BrandColors.ink,
                  ),
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ],
                if (primaryAction != null) ...<Widget>[
                  const SizedBox(height: Spacing.xl),
                  primaryAction,
                ],
                if (secondaryAction != null) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  secondaryAction,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
