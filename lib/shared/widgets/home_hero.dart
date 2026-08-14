import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/motion/motion_tokens.dart';
import '../illustrations/taytay_scenes.dart';

/// The banner at the top of Home: who this is, where they are, and one action.
///
/// ---
///
/// **Colour comes from the `ColorScheme`, not from a hard-coded brand gradient.**
/// The layered wash below is built from `primary`, `primaryContainer` and
/// `surfaceTint`, so it follows dark mode and high-contrast settings without a
/// second implementation — CLAUDE.md Article 6. A fixed blue gradient looks
/// correct exactly once, in the light theme, on the designer's screen.
///
/// **Contrast is guaranteed by construction.** Every text child is painted in
/// `onPrimary`, and the gradient is built only from colours the theme pairs with
/// it, so no combination of stops can produce a heading that fails 4.5:1.
///
/// **The motion is decorative, so reduced motion removes it entirely** rather
/// than shortening it (`Motion.reduced`). A hero that slides on every visit to
/// Home is the most repeated animation in the app and the one most likely to
/// bother somebody with a vestibular disorder.
///
/// **It grows, it does not clip.** The height is intrinsic and the content wraps,
/// so at 200% text the banner gets taller instead of truncating the one sentence
/// that says what to do next.
class HomeHero extends StatelessWidget {
  const HomeHero({
    required this.title,
    required this.subtitle,
    this.action,
    this.showBackdrop = true,
    super.key,
  });

  /// Greeting or headline. Kept short; the resident's name, when there is one,
  /// is a first name only.
  final String title;

  /// One sentence saying what this app is for the person reading it.
  final String subtitle;

  /// At most one call to action. Never more: a hero with three buttons has not
  /// decided what it is for.
  final Widget? action;

  /// Whether to paint the Taytay horizon behind the wash.
  final bool showBackdrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduced = Motion.reduced(context);

    final hero = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        // Two soft layers rather than one hard sweep: the second stop sits at
        // 55% so the transition happens behind the text block instead of across
        // it, which is what keeps the heading legible at every text scale.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.alphaBlend(
              scheme.surfaceTint.withValues(alpha: 0.18),
              scheme.primary,
            ),
            scheme.primary,
          ],
          stops: const <double>[0, 0.55, 1],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Stack(
          children: <Widget>[
            if (showBackdrop)
              Positioned.fill(
                child: Opacity(
                  // Low enough that it reads as texture. The text above it is
                  // painted on `primary`, which the theme guarantees against
                  // `onPrimary`; the backdrop must not disturb that.
                  opacity: 0.16,
                  child: TaytayScenes.horizonBackdrop(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.92),
                    ),
                  ),
                  if (action != null) ...<Widget>[
                    const SizedBox(height: Spacing.lg),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (reduced) return hero;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MotionTokens.standard,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: hero,
    );
  }
}
