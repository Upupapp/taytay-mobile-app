import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_dependencies.dart';
import '../../core/design/design_tokens.dart';
import '../../core/intent/resident_intent.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/access_policy.dart';
import '../../shared/illustrations/state_illustrations.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// What a resident chose when a gate interrupted them.
enum GateOutcome {
  /// They are heading to sign in or create an account.
  goingToAuthenticate,

  /// They are heading to identity verification.
  goingToVerify,

  /// They dismissed the gate and stayed where they were.
  dismissed,
}

/// The one place the app explains why an action needs an account or verification.
///
/// ---
///
/// **Why a single component rather than a message per feature.** A gate appears
/// on liking a post, commenting, registering for an event and applying for a
/// service. Written per feature, four teams write four different explanations,
/// three of them forget to say what to do next, and one implies the action was
/// refused rather than deferred. Written once, the resident meets the same
/// sentence shape everywhere and the copy can be reviewed by the LGU in one
/// place.
///
/// **It shows, it does not decide.** The sheet is chosen from an
/// [AccessDecision] the caller already obtained from [AccessPolicy]; it performs
/// no evaluation of its own and grants nothing. Its buttons navigate — the
/// server still authorises whatever happens next.
///
/// **The dismiss path is always available.** Every gate can be closed and the
/// resident returns to what they were reading. A gate that cannot be dismissed
/// is a wall.
abstract final class AccessGateSheet {
  /// Shows the gate appropriate to [decision], remembering [intent] so the
  /// resident resumes after they pass it.
  ///
  /// Returns what they chose. `null` means the sheet was swiped away, which is
  /// treated exactly like [GateOutcome.dismissed].
  static Future<GateOutcome?> show({
    required BuildContext context,
    required AccessDecision decision,
    required ResidentIntentKind intent,
    String? targetId,
  }) async {
    // Captured before any await: a BuildContext must not be used across an
    // async gap, and the sheet is one. Holding the controller and the router
    // directly also means the clear below cannot silently skip because the
    // element that opened the sheet was rebuilt while it was up.
    final intents = AppDependencies.of(context).intents;
    final router = GoRouter.of(context);

    // Remembering before navigating: the sheet may send the resident to another
    // route, and the intent has to survive that.
    intents.remember(intent, targetId: targetId);

    final outcome = await switch (decision) {
      AccessNeedsAuthentication() => _showAuthGate(context, router, intent),
      AccessNeedsVerification() => _showVerificationGate(
        context,
        router,
        intent,
      ),
      // Nothing to gate. Callers should not reach here, but returning a
      // dismissal is safer than asserting in a resident's face.
      AccessAllowed() ||
      AccessPending() => Future<GateOutcome?>.value(GateOutcome.dismissed),
    };

    if (outcome == null || outcome == GateOutcome.dismissed) {
      // They changed their mind; do not resume later.
      intents.clear();
    }
    return outcome;
  }

  static Future<GateOutcome?> _showAuthGate(
    BuildContext context,
    GoRouter router,
    ResidentIntentKind intent,
  ) {
    return AppSheet.show<GateOutcome>(
      context: context,
      title: 'Sign in to continue',
      builder: (sheetContext) => _GateBody(
        illustration: StateIllustrations.empty(size: 96),
        message:
            'You need a Taytay LGU account to ${intent.description}. '
            'Signing in also lets you track anything you apply for.',
        privacyNote:
            'Browsing stays open to everyone — you can keep reading without an '
            'account.',
        primary: AppButton(
          label: 'Sign in',
          icon: Icons.login,
          onPressed: () {
            Navigator.of(sheetContext).pop(GateOutcome.goingToAuthenticate);
            router.goNamed(AppRoute.signIn.routeName);
          },
        ),
        secondary: AppButton(
          label: 'Create an account',
          variant: AppButtonVariant.secondary,
          onPressed: () {
            Navigator.of(sheetContext).pop(GateOutcome.goingToAuthenticate);
            router.goNamed(AppRoute.register.routeName);
          },
        ),
        tertiary: AppButton(
          label: 'Keep browsing',
          variant: AppButtonVariant.text,
          onPressed: () =>
              Navigator.of(sheetContext).pop(GateOutcome.dismissed),
        ),
      ),
    );
  }

  static Future<GateOutcome?> _showVerificationGate(
    BuildContext context,
    GoRouter router,
    ResidentIntentKind intent,
  ) {
    return AppSheet.show<GateOutcome>(
      context: context,
      title: 'Verify your identity',
      builder: (sheetContext) => _GateBody(
        illustration: StateIllustrations.empty(size: 96),
        message:
            'Taytay LGU needs to confirm who you are before you can '
            '${intent.description}. Verification is a one-time step.',
        privacyNote:
            'The LGU asks only for what it needs to confirm your identity and '
            'residency, and tells you why.',
        primary: AppButton(
          label: 'Start verification',
          icon: Icons.arrow_forward,
          iconTrailing: true,
          onPressed: () {
            Navigator.of(sheetContext).pop(GateOutcome.goingToVerify);
            router.goNamed(AppRoute.verification.routeName);
          },
        ),
        secondary: AppButton(
          label: 'Not now',
          variant: AppButtonVariant.text,
          onPressed: () =>
              Navigator.of(sheetContext).pop(GateOutcome.dismissed),
        ),
      ),
    );
  }
}

class _GateBody extends StatelessWidget {
  const _GateBody({
    required this.illustration,
    required this.message,
    required this.privacyNote,
    required this.primary,
    required this.secondary,
    this.tertiary,
  });

  final Widget illustration;
  final String message;
  final String privacyNote;
  final Widget primary;
  final Widget secondary;

  /// Optional third action. Used by the sign-in gate, where a resident may
  /// have no account yet — offering only "Sign in" would strand them.
  final Widget? tertiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: illustration),
        const SizedBox(height: Spacing.lg),
        Text(message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: Spacing.md),
        Text(
          privacyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        primary,
        const SizedBox(height: Spacing.sm),
        secondary,
        if (tertiary != null) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          tertiary!,
        ],
      ],
    );
  }
}
