import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import 'welcome_scene.dart';

/// The welcome experience: three scenes, then into the app.
///
/// ---
///
/// **No onboarding trap.** Three properties, together:
///
/// 1. **Skip is on every scene**, on the photo's top row, from the first
///    frame.
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
///
/// Get started marks the welcome done and opens Sign-in. Self-registration stays
/// off, so Sign-in is the destination the guard already uses for that step.
/// Skip and Continue as guest mark the welcome done and enter the app.
///
/// The look is `design/mobile/screens/Main.dc.html` (Welcome): each scene is a
/// full page ([WelcomeCanvas]) that scrolls at large text sizes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double get _page {
    if (!_pages.hasClients) return 0;
    return _pages.page ?? _pages.initialPage.toDouble();
  }

  Duration get _turn => MotionTokens.standard;

  Future<void> _finish({required bool signIn}) async {
    final dependencies = AppDependencies.of(context);
    final router = GoRouter.of(context);
    await dependencies.launch.markWelcomeCompleted();
    if (!mounted) return;
    if (signIn) {
      router.goNamed(AppRoute.signIn.routeName);
      return;
    }
    router.goNamed(AppRoute.home.routeName);
  }

  void _go(int direction, int count) {
    unawaited(
      AppHaptics.fire(
        HapticIntent.selection,
        suppressed: Motion.reduced(context),
      ),
    );
    final next = (_page.round() + direction).clamp(0, count - 1);
    if (Motion.reduced(context)) {
      // A zero-duration page animation is rejected by the scroll activity.
      // Reduced motion jumps. The gesture swipe still works.
      _pages.jumpToPage(next);
      return;
    }
    final turn = direction > 0 ? _pages.nextPage : _pages.previousPage;
    unawaited(turn(duration: _turn, curve: Curves.ease));
  }

  @override
  Widget build(BuildContext context) {
    final scenes = WelcomePageCopy.fromStrings(AppStrings.of(context));
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: PageView.builder(
        controller: _pages,
        itemCount: scenes.length,
        itemBuilder: (context, index) {
          return WelcomeCanvas(
            page: index,
            pageCount: scenes.length,
            copy: scenes[index],
            onSkip: () => unawaited(_finish(signIn: false)),
            onNext: () => _go(1, scenes.length),
            onBack: () => _go(-1, scenes.length),
            onGetStarted: () => unawaited(_finish(signIn: true)),
            onGuest: () => unawaited(_finish(signIn: false)),
          );
        },
      ),
    );
  }
}
