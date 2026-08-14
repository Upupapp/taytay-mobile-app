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

/// Resident dashboard, and the app's landing screen for everyone.
///
/// The same screen serves guest, unverified and verified residents. It does not
/// hide the LGU's services from a guest: it shows them, and says what each one
/// needs. A person deciding whether to register should be able to see what they
/// would be registering *for*.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;
        final level = session.accessLevel;
        final name = session.residentOrNull?.displayName;

        // No `IntentResumer` here: the shell owns exactly one for all five
        // branches, so a held intent cannot be resumed once per live branch.
        return Scaffold(
          appBar: AppBar(title: const Text('Taytay LGU IDS')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                Text(
                  name == null ? 'Kumusta!' : 'Kumusta, $name!',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _subtitleFor(level),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                _AccessStateCard(session: session),
                const SizedBox(height: Spacing.xl),
                Text('Municipal services', style: theme.textTheme.titleMedium),
                const SizedBox(height: Spacing.md),
                _ServiceTile(
                  icon: Icons.badge_outlined,
                  title: 'My Taytay digital ID',
                  subtitle: 'Carry and present your municipal ID',
                  capability: ResidentCapability.holdDigitalId,
                  session: session,
                  intent: ResidentIntentKind.viewDigitalId,
                ),
                _ServiceTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Identity verification',
                  subtitle: 'Confirm who you are with the LGU',
                  capability: ResidentCapability.completeVerification,
                  session: session,
                ),
                _ServiceTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account and preferences',
                  subtitle: 'Contact details, notifications, privacy',
                  capability: ResidentCapability.manageAccount,
                  session: session,
                  intent: ResidentIntentKind.manageNotifications,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _subtitleFor(AccessLevel level) => switch (level) {
    AccessLevel.guest => 'Browse municipal services. Sign in to use them.',
    AccessLevel.unverified => 'Your account is not verified yet.',
    AccessLevel.verified => 'Your account is verified.',
  };
}

/// Explains the resident's current state and what the next step is.
class _AccessStateCard extends StatelessWidget {
  const _AccessStateCard({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (
      icon,
      title,
      body,
      actionLabel,
      route,
    ) = switch (session.accessLevel) {
      AccessLevel.guest => (
        Icons.person_outline,
        'You are browsing as a guest',
        'Sign in with your mobile number to apply for services and to hold your '
            'digital ID.',
        'Sign in',
        AppRoute.signIn,
      ),
      AccessLevel.unverified => (
        Icons.pending_actions_outlined,
        'One step to go',
        'Verify your identity with Taytay LGU to unlock your digital ID and '
            'service applications.',
        'Start verification',
        AppRoute.verification,
      ),
      AccessLevel.verified => (
        Icons.verified_outlined,
        'Verified resident',
        'You have full access to Taytay municipal services in this app.',
        'Open my digital ID',
        AppRoute.digitalId,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => context.goNamed(route.routeName),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A service entry that states its requirement rather than disappearing.
///
/// Hiding a locked service tells a resident nothing; showing it with "needs
/// verification" tells them what to do next. It also reflects reality — the
/// service exists whether or not this person can use it yet — and it gives away
/// nothing, because the server, not this tile, decides access.
///
/// **The tile takes no decision of its own.** Since TAB 10 it asks
/// [CapabilityService] and renders the verdict. A tile that compared access
/// levels itself was how the home screen and the profile screen came to
/// disagree about what "locked" meant.
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.capability,
    required this.session,
    this.intent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ResidentCapability capability;
  final SessionState session;

  /// Held through the gate when there is something to come back to.
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

    // Guaranteed non-null for every refusal — acceptance 2.
    final recovery = CapabilityService.recoveryRoute(verdict);
    if (recovery != null && context.mounted) {
      context.goNamed(recovery.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = CapabilityService.evaluate(
      session: session,
      capability: capability,
    );
    final requirementLabel = CapabilityService.requirementLabel(verdict);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          subtitle: Text(
            requirementLabel == null
                ? subtitle
                : '$subtitle · $requirementLabel',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, verdict),
        ),
      ),
    );
  }
}
