import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// How urgent a [NextActionCard] is, and therefore how it is coloured.
enum NextActionTone {
  /// Something the LGU is waiting on from the resident. The only tone that
  /// raises its voice.
  needsYou,

  /// In hand, nothing to do. Reassurance, not an instruction.
  inProgress,

  /// An offer the resident can take up when they like.
  invitation,
}

/// The card that answers "what can I do now?".
///
/// ---
///
/// **One card, one action.** Acceptance 1 of this TAB is that Home answers that
/// question *quickly*, and the way a dashboard fails it is by offering six
/// equally-weighted things. Each card states one situation and at most one
/// primary action, with an optional quieter secondary.
///
/// **Colour is never the only signal.** Each tone carries a distinct icon and
/// distinct wording as well as a distinct container colour, so the difference
/// between "we need something from you" and "this is in hand" survives
/// monochrome vision and a greyscale screenshot (WCAG 2.2 §1.4.1).
///
/// **No counts, no numbers, no progress rings.** This app has no authoritative
/// source for "3 pending" or "60% complete", and a fabricated figure on a
/// government service is worse than an absent one. Cards describe a state and a
/// step, never a quantity.
class NextActionCard extends StatelessWidget {
  const NextActionCard({
    required this.tone,
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final NextActionTone tone;
  final String title;
  final String body;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color background, Color foreground, IconData icon) = switch (tone) {
      NextActionTone.needsYou => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.pending_actions_outlined,
      ),
      NextActionTone.inProgress => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.hourglass_top_outlined,
      ),
      NextActionTone.invitation => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        Icons.lightbulb_outline,
      ),
    };

    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, color: foreground),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            if (primaryAction != null || secondaryAction != null) ...<Widget>[
              const SizedBox(height: Spacing.lg),
              // Wraps rather than overflows: at 200% text two buttons will not
              // fit on one line on a phone, and a clipped action is an action
              // the resident cannot take.
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: <Widget>[?primaryAction, ?secondaryAction],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
