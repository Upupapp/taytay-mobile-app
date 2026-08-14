import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

/// Profile — the fifth destination, and the resident's own area.
///
/// ---
///
/// **Public, so the tab exists for a guest.** Acceptance 3 requires the same
/// five destinations at every access level, which means Profile has to open for
/// someone with no account. For them it is not a locked door: it is the
/// explanation of what an account is for and the way to get one. Everything
/// inside that genuinely needs an account states its own requirement.
///
/// **No personal data is fetched here.** The screen shows what the session
/// already holds — a greeting name and an access level — and links to the
/// screens that fetch the rest when they display it. A profile hub that
/// preloaded demographics would make every visit a disclosure, and would cache
/// personal data in a widget that stays alive behind an `IndexedStack`.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                _IdentityCard(session: session),
                const SizedBox(height: Spacing.xl),
                Semantics(
                  header: true,
                  child: Text(
                    'Your account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                for (final entry in _entries)
                  _CapabilityTile(capability: entry.$1, intent: entry.$2),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Everything reachable from Profile, each named by its capability.
  ///
  /// Listing capabilities rather than routes is the point: the tile asks
  /// `CapabilityService` what to render, so a level change or a backend module
  /// shipping updates every entry without touching this list.
  static const List<(ResidentCapability, ResidentIntentKind?)> _entries =
      <(ResidentCapability, ResidentIntentKind?)>[
        (ResidentCapability.completeVerification, null),
        (ResidentCapability.holdDigitalId, ResidentIntentKind.viewDigitalId),
        (ResidentCapability.trackAssistanceRequests, null),
        (ResidentCapability.viewHouseholdSummary, null),
        (
          ResidentCapability.manageAccount,
          ResidentIntentKind.manageNotifications,
        ),
        (ResidentCapability.manageSecurity, null),
      ];
}

/// Who the resident is to this app, and nothing more.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = session.residentOrNull?.displayName;

    final (
      String title,
      String body,
      String? action,
      AppRoute? route,
    ) = switch (session.accessLevel) {
      AccessLevel.guest => (
        'You are browsing as a guest',
        'Sign in with your mobile number to hold your digital ID and to '
            'track anything you apply for. Browsing stays open either way.',
        'Sign in',
        AppRoute.signIn,
      ),
      AccessLevel.unverified => (
        name ?? 'Your account',
        'Taytay LGU has not confirmed your identity yet. Verifying unlocks '
            'your digital ID and service applications.',
        'Verify my identity',
        AppRoute.verification,
      ),
      AccessLevel.verified => (
        name ?? 'Verified resident',
        'Taytay LGU has confirmed your identity.',
        null,
        null,
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null && route != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: action,
                fullWidth: false,
                onPressed: () => context.goNamed(route.routeName),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One entry, rendered from the central verdict rather than from a local check.
class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({required this.capability, this.intent});

  final ResidentCapability capability;
  final ResidentIntentKind? intent;

  Future<void> _open(BuildContext context, CapabilityVerdict verdict) async {
    final route = capability.route;
    final session = AppDependencies.of(context).session.state;

    // Access decides whether it opens; availability only decides what the
    // screen then says. See `CapabilityService.canOpen`.
    if (route != null &&
        CapabilityService.canOpen(session: session, capability: capability)) {
      context.goNamed(route.routeName);
      return;
    }

    final held = intent;
    if (held != null) {
      await AccessGateSheet.showForCapability(
        context: context,
        verdict: verdict,
        intent: held,
      );
      return;
    }

    // No intent to hold — send them to the recovery route, which
    // `CapabilityService` guarantees exists for every refusal (acceptance 2).
    final recovery = CapabilityService.recoveryRoute(verdict);
    if (recovery != null && context.mounted) {
      context.goNamed(recovery.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final verdict = CapabilityService.evaluate(
      session: dependencies.session.state,
      capability: capability,
    );
    final requirement = CapabilityService.requirementLabel(verdict);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _iconFor(capability),
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(capability.label),
      // States the requirement instead of hiding the row. A resident can see
      // what the app offers and what it would take to reach it.
      subtitle: requirement == null ? null : Text(requirement),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context, verdict),
    );
  }

  static IconData _iconFor(ResidentCapability capability) =>
      switch (capability) {
        ResidentCapability.completeVerification => Icons.verified_user_outlined,
        ResidentCapability.holdDigitalId => Icons.badge_outlined,
        ResidentCapability.trackAssistanceRequests => Icons.assignment_outlined,
        ResidentCapability.viewHouseholdSummary =>
          Icons.family_restroom_outlined,
        ResidentCapability.manageAccount => Icons.manage_accounts_outlined,
        ResidentCapability.manageSecurity => Icons.shield_outlined,
        _ => Icons.chevron_right,
      };
}
