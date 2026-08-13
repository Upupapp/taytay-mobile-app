import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/illustrations/taytay_scenes.dart';

/// First-run introduction.
///
/// Public and skippable by design. It explains what the app does and what it
/// will ask for *before* anyone hands over identity information — informed
/// consent is worth little if the explanation arrives after the form.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final List<_OnboardingPage> _pages = <_OnboardingPage>[
    _OnboardingPage(
      scene: TaytayScenes.digitalId(),
      title: 'Your Taytay ID, on your phone',
      body:
          'Apply for and carry your Municipality of Taytay digital ID without '
          'queueing at the municipal hall.',
    ),
    _OnboardingPage(
      scene: TaytayScenes.services(),
      title: 'Municipal services in one place',
      body:
          'Documents, real property tax, health programmes and job services — '
          'track every request from one app.',
    ),
    _OnboardingPage(
      scene: TaytayScenes.privacy(),
      title: 'You choose what you share',
      body:
          'Taytay LGU asks only for what a service needs, and tells you why. '
          'Your data is protected under the Data Privacy Act of 2012.',
    ),
  ];

  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastPage => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    unawaited(
      AppHaptics.fire(
        HapticIntent.selection,
        suppressed: Motion.reduced(context),
      ),
    );
    if (_isLastPage) {
      context.goNamed(AppRoute.home.routeName);
      return;
    }
    _controller.nextPage(
      duration: Motion.duration(context, MotionTokens.standard),
      curve: MotionTokens.enterEase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          TextButton(
            onPressed: () => context.goNamed(AppRoute.home.routeName),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < _pages.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    child: AnimatedContainer(
                      duration: Motion.duration(context, MotionTokens.fast),
                      width: i == _index ? Spacing.xl : Spacing.sm,
                      height: Spacing.sm,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLastPage ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
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
        vertical: Spacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          scene,
          const SizedBox(height: Spacing.xl),
          Text(title, style: theme.textTheme.headlineSmall),
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
