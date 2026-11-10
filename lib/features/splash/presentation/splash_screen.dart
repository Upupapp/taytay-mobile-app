import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../shared/widgets/blue_header.dart';

/// Cold-start screen. Restores the session, then gets out of the way.
///
/// It navigates nowhere itself: it changes the session, and the router's
/// redirect moves the app on. Screens that push their own successor are how two
/// sources of navigation truth appear in a codebase.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final dependencies = AppDependencies.of(context);
    final reduced = Motion.reducedFromPlatform;

    // Both reads and the minimum display time run together: the resident waits
    // for whichever is slowest, not for all three in sequence. Reduced motion
    // shortens the hold — a splash is decoration, and decoration is what
    // reduced motion is allowed to take away.
    final minimumVisible = Future<void>.delayed(
      reduced ? MotionTokens.splashReduced : MotionTokens.splashMinimum,
    );

    await Future.wait<void>(<Future<void>>[
      // Publishing is held until the minimum, because publishing is what moves
      // the router.
      dependencies.session.restore(notBefore: minimumVisible),
      dependencies.launch.restore(),
      minimumVisible,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // The welcome's photo zone without the photo: the header gradient, the
    // seal and the municipality, and a short gold bar while the session
    // restores. Nothing here is data.
    return Scaffold(
      backgroundColor: BrandColors.navy,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BrandGradients.header.toLinearGradient(),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const HeaderSeal(diameter: _sealDiameter),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Bayan ng Taytay',
                    textAlign: TextAlign.center,
                    style: AppTypography.hero.copyWith(
                      color: BrandColors.white,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Lalawigan ng Rizal',
                    textAlign: TextAlign.center,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.gold,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxl),
                  SizedBox(
                    width: A11y.minTapTarget,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: BrandColors.gold,
                      backgroundColor: BrandColors.white.withValues(
                        alpha: Opacities.hairline,
                      ),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The seal at splash size: the welcome's 38 px header seal, scaled up.
const double _sealDiameter = 96;
