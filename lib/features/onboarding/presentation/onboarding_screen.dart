import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/illustrations/taytay_scenes.dart';
import '../../../shared/widgets/app_button.dart';

/// The welcome experience: three scenes, then into the app.
///
/// ---
///
/// **No onboarding trap.** Three properties, together:
///
/// 1. **Skip is on every scene**, in the app bar, from the first frame.
/// 2. **"Continue as guest" is an explicit, equal-weight action** on the last
///    scene — not a greyed-out link under a sign-in button. Browsing Taytay's
///    published services genuinely needs no account, and the welcome screens
///    must not imply otherwise.
/// 3. **Skipping counts as done.** Whether a resident reads all three scenes or
///    leaves on the first, the flag is set and they are not asked again. Showing
///    it again would override a decision they already made, which is precisely
///    what makes onboarding feel like a trap.
///
/// The route itself stays public (`AccessRequirement.public`) and the guard never
/// redirects *into* it except from the splash on a genuine first launch, so it
/// is a starting point rather than a gate.
///
/// **Nothing here asks for personal data.** The scenes explain what the app does
/// and what the LGU will later ask for; the first field a resident meets is on
/// sign-in, after they have been told why.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final List<_WelcomeScene> _scenes = <_WelcomeScene>[
    _WelcomeScene(
      scene: TaytayScenes.services(),
      title: 'Municipal services in one place',
      body:
          'Documents, real property tax, health programmes and job services — '
          'browse what Taytay LGU offers and track anything you apply for.',
    ),
    _WelcomeScene(
      scene: TaytayScenes.digitalId(),
      title: 'Your Taytay ID, on your phone',
      body:
          'Apply for and carry your Municipality of Taytay digital ID without '
          'queueing at the municipal hall.',
    ),
    _WelcomeScene(
      scene: TaytayScenes.privacy(),
      title: 'You choose what you share',
      body:
          'Taytay LGU asks only for what a service needs, and tells you why. '
          'Your information is protected under the Data Privacy Act of 2012.',
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastScene => _index == _scenes.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Marks the welcome as done and enters the app.
  ///
  /// Used by both "Skip" and "Continue as guest": the resident has decided, and
  /// which button they used does not change that.
  Future<void> _finish() async {
    final dependencies = AppDependencies.of(context);
    final router = GoRouter.of(context);

    await dependencies.launch.markWelcomeCompleted();
    if (!mounted) return;
    router.goNamed(AppRoute.home.routeName);
  }

  void _next() {
    unawaited(
      AppHaptics.fire(
        HapticIntent.selection,
        suppressed: Motion.reduced(context),
      ),
    );
    if (_isLastScene) {
      unawaited(_finish());
      return;
    }
    _controller.nextPage(
      // Functional motion: it says which way the scenes run. Shortened rather
      // than removed under reduced motion, so the page change stays legible.
      duration: Motion.duration(context, MotionTokens.standard),
      curve: MotionTokens.enterEase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(onPressed: _finish, child: const Text('Skip')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _scenes.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _scenes[index],
              ),
            ),
            _SceneProgress(current: _index, total: _scenes.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.lg,
                Spacing.xl,
                Spacing.xl,
              ),
              child: Column(
                children: <Widget>[
                  AppButton(
                    label: _isLastScene ? 'Get started' : 'Next',
                    icon: _isLastScene ? null : Icons.arrow_forward,
                    iconTrailing: true,
                    onPressed: _next,
                  ),
                  if (_isLastScene) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    AppButton(
                      label: 'Continue as guest',
                      variant: AppButtonVariant.secondary,
                      onPressed: _finish,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'You can browse municipal services without an account.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress through the scenes.
///
/// Carries a **text label for assistive technology** as well as the dots: a row
/// of coloured pills communicates nothing to a screen-reader user, and "step 2
/// of 3" is the part that actually matters. The dots themselves are excluded
/// from semantics so the position is announced once, not four times.
class _SceneProgress extends StatelessWidget {
  const _SceneProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = Motion.reduced(context);

    return Semantics(
      label: 'Step ${current + 1} of $total',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: AnimatedContainer(
                  // Decorative: the width change carries no information the
                  // colour and the label do not already carry, so it goes to
                  // zero under reduced motion rather than merely shortening.
                  duration: reduced ? MotionTokens.instant : MotionTokens.fast,
                  width: i == current ? Spacing.xl : Spacing.sm,
                  height: Spacing.sm,
                  decoration: BoxDecoration(
                    color: i == current
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({
    required this.scene,
    required this.title,
    required this.body,
  });

  /// A painted scene rather than a glyph: onboarding is the one place worth
  /// spending vertical space on artwork, because it is what tells a resident
  /// what kind of app this is before any text is read.
  final Widget scene;

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable so the content survives a 200% system text scale instead of
    // overflowing.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.xl,
        vertical: Spacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          scene,
          const SizedBox(height: Spacing.xl),
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
