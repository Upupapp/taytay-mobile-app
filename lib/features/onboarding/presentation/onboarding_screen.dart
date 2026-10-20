import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/taytay_thread.dart';
import 'welcome_scene.dart';

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
///
/// Get started marks the welcome done and opens Sign-in. Self-registration stays
/// off, so Sign-in is the destination the guard already uses for that step. The
/// travelling light is handed across as [WelcomeThreadArrival]. Skip and
/// Continue as guest mark the welcome done and enter the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pages = PageController();
  late final AnimationController _light;

  @override
  void initState() {
    super.initState();
    _light = AnimationController(
      vsync: this,
      duration: MotionTokens.welcomeLight,
    );
    _pages.addListener(_onPageTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.decorativeLoop(context)) {
      _light.stop();
    } else if (!_light.isAnimating) {
      _light.repeat();
    }
  }

  void _onPageTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pages
      ..removeListener(_onPageTick)
      ..dispose();
    _light.dispose();
    super.dispose();
  }

  double get _page {
    if (!_pages.hasClients) return 0;
    return _pages.page ?? _pages.initialPage.toDouble();
  }

  /// Ambient travel on the settled page. During a swipe the speck rides the
  /// outgoing curve so the stitch stays one line.
  double? _lightT(int page) {
    if (!Motion.decorativeLoop(context)) return null;
    final current = _page;
    final travelling = (current - current.roundToDouble()).abs() > 0.001;
    if (travelling) {
      final from = current.floor();
      if (page != from) return null;
      return current - from;
    }
    if (page != current.round()) return null;
    return MotionTokens.welcomeLightCurve.transform(_light.value);
  }

  Duration get _turn => MotionTokens.standard;

  Future<void> _finish({required bool signIn}) async {
    final dependencies = AppDependencies.of(context);
    final router = GoRouter.of(context);
    final reduced = Motion.reduced(context);
    await dependencies.launch.markWelcomeCompleted();
    if (!mounted) return;
    if (signIn) {
      router.goNamed(
        AppRoute.signIn.routeName,
        extra: reduced ? null : const WelcomeThreadArrival(),
      );
      return;
    }
    router.goNamed(AppRoute.home.routeName);
  }

  void _go(int direction) {
    unawaited(
      AppHaptics.fire(
        HapticIntent.selection,
        suppressed: Motion.reduced(context),
      ),
    );
    final next = (_page.round() + direction).clamp(0, 2);
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
      backgroundColor: const Color(0xFFF3F5FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 390;
          const canvasHeight = 844.0;
          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: canvasHeight * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 390,
                  height: canvasHeight,
                  child: AnimatedBuilder(
                    animation: _light,
                    builder: (context, _) {
                      return PageView.builder(
                        controller: _pages,
                        itemCount: scenes.length,
                        itemBuilder: (context, index) {
                          return WelcomeCanvas(
                            page: index,
                            copy: scenes[index],
                            lightT: _lightT(index),
                            onSkip: () => unawaited(_finish(signIn: false)),
                            onNext: () => _go(1),
                            onBack: () => _go(-1),
                            onGetStarted: () =>
                                unawaited(_finish(signIn: true)),
                            onGuest: () => unawaited(_finish(signIn: false)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
