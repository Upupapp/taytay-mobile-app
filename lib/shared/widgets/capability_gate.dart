import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_dependencies.dart';
import '../../core/intent/resident_intent.dart';
import '../../core/l10n/app_locales.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/resident_capability.dart';
import 'app_button.dart';
import 'status_view.dart';

/// Shows [child] when the resident may use [capability], and an explanation with
/// a way forward when they may not.
///
/// ---
///
/// **Acceptance 2 lives here.** Every gated destination has an explanatory
/// recovery path, and the cheapest way to guarantee that across a growing app is
/// to make the refusal impossible to render without one:
/// `CapabilityService.recoveryRoute` returns a destination for every refusing
/// verdict, and this widget renders that destination as the primary action. A
/// screen cannot forget, because there is no code path in which it would.
///
/// **The intent is optional, bounded and grants nothing.** When [intent] is
/// given, the thing the resident was reaching for is held through the sign-in
/// round trip and resumed after — TAB 06's mechanism, unchanged. It carries a
/// kind and at most one opaque id, never form contents, and satisfying its gate
/// authorises nothing: the server decides on the request that follows.
///
/// **This is presentation.** If this widget were deleted the app would be less
/// pleasant and exactly as secure. The route guard covers navigation; this
/// covers content that sits inside a route a resident may legitimately open.
class CapabilityGate extends StatelessWidget {
  const CapabilityGate({
    required this.capability,
    required this.child,
    this.intent,
    this.targetId,
    super.key,
  });

  final ResidentCapability capability;
  final Widget child;

  /// What to hold through the gate, if anything.
  final ResidentIntentKind? intent;

  /// An opaque server identifier belonging to [intent]. Validated by
  /// `ResidentIntent` itself, which rejects anything that is not an id.
  final String? targetId;

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;
        // Access only: the wrapped screen handles an absent backend itself, and
        // its wording is more useful than a generic one. See
        // `CapabilityService.canOpen`.
        if (CapabilityService.canOpen(
          session: session,
          capability: capability,
        )) {
          return child;
        }
        final verdict = CapabilityService.evaluate(
          session: session,
          capability: capability,
        );

        return CapabilityLockedView(
          capability: capability,
          verdict: verdict,
          intent: intent,
          targetId: targetId,
        );
      },
    );
  }
}

/// The refusal itself: what is missing, why, and the one thing to do next.
class CapabilityLockedView extends StatelessWidget {
  const CapabilityLockedView({
    required this.capability,
    required this.verdict,
    this.intent,
    this.targetId,
    super.key,
  });

  final ResidentCapability capability;
  final CapabilityVerdict verdict;
  final ResidentIntentKind? intent;
  final String? targetId;

  @override
  Widget build(BuildContext context) {
    if (verdict is CapabilityPending) {
      return const Center(child: CircularProgressIndicator());
    }

    final recovery = CapabilityService.recoveryRoute(verdict);
    final dependencies = AppDependencies.of(context);

    return StatusView(
      // Names the capability rather than the failure, so the heading reads as
      // "here is what this is" instead of "you are not allowed".
      title: capabilityLabel(context, capability),
      kind: StatusKind.empty,
      icon: switch (verdict) {
        CapabilityNeedsSignIn() => Icons.login_outlined,
        CapabilityNeedsVerification() => Icons.verified_user_outlined,
        CapabilityNotYetAvailable() => Icons.construction_outlined,
        _ => Icons.lock_outline,
      },
      message: CapabilityService.explain(verdict),
      primaryAction: recovery == null
          ? null
          : AppButton(
              label: _actionLabel(verdict),
              fullWidth: false,
              onPressed: () {
                // Held before navigating, so the resident lands back here.
                // Nothing about the intent grants access; it only remembers.
                final held = intent;
                if (held != null) {
                  dependencies.intents.remember(held, targetId: targetId);
                }
                context.goNamed(recovery.routeName);
              },
            ),
      // Always present. A resident who does not want to sign in is not stuck on
      // a screen with one button — public Taytay information stays open.
      secondaryAction: TextButton(
        onPressed: () => context.goNamed(AppRoute.home.routeName),
        child: const Text('Back to Home'),
      ),
    );
  }

  static String _actionLabel(CapabilityVerdict verdict) => switch (verdict) {
    CapabilityNeedsSignIn() => 'Sign in',
    CapabilityNeedsVerification() => 'Verify my identity',
    CapabilityNotYetAvailable() => 'See what is available',
    _ => 'Continue',
  };
}
