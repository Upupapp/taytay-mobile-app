import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/motion/motion_tokens.dart';

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

    // The read and the minimum display time run together: the resident waits for
    // whichever is slower, not for both in sequence. Reduced motion shortens the
    // hold — a splash is decoration, and decoration is what reduced motion is
    // allowed to take away.
    await dependencies.session.restore(
      notBefore: Future<void>.delayed(
        reduced ? MotionTokens.splashReduced : MotionTokens.splashMinimum,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              label: 'Municipality of Taytay, Rizal',
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: BrandColors.taytayBlue,
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'T',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text('Taytay LGU IDS', style: theme.textTheme.titleLarge),
            const SizedBox(height: Spacing.xs),
            Text(
              'Municipality of Taytay, Rizal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xxl),
            const SizedBox(
              width: A11y.minTapTarget,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ],
        ),
      ),
    );
  }
}
