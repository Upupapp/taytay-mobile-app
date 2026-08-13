import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/intent_resumer.dart';

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

        return IntentResumer(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Taytay LGU IDS'),
              actions: <Widget>[
                IconButton(
                  onPressed: () => context.goNamed(AppRoute.account.routeName),
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Account',
                ),
              ],
            ),
            body: ListView(
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
                  requirement: AccessLevel.verified,
                  currentLevel: level,
                  onTap: () => _openGated(
                    context: context,
                    session: session,
                    intent: ResidentIntentKind.viewDigitalId,
                    destination: AppRoute.digitalId,
                  ),
                ),
                _ServiceTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Identity verification',
                  subtitle: 'Confirm who you are with the LGU',
                  requirement: AccessLevel.unverified,
                  currentLevel: level,
                  onTap: () => context.goNamed(AppRoute.verification.routeName),
                ),
                _ServiceTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account and preferences',
                  subtitle: 'Contact details, notifications, privacy',
                  requirement: AccessLevel.unverified,
                  currentLevel: level,
                  onTap: () => _openGated(
                    context: context,
                    session: session,
                    intent: ResidentIntentKind.manageNotifications,
                    destination: AppRoute.account,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Opens [destination], or explains the gate and remembers the intent.
  ///
  /// The evaluation is `AccessPolicy`'s — the same one the router uses — so a
  /// tap and a deep link to the same screen reach the same conclusion. The sheet
  /// grants nothing; it navigates, and the server authorises what follows.
  static Future<void> _openGated({
    required BuildContext context,
    required SessionState session,
    required ResidentIntentKind intent,
    required AppRoute destination,
  }) async {
    final decision = AccessPolicy.evaluate(
      session: session,
      requirement: destination.requirement,
    );

    if (decision is AccessAllowed) {
      context.goNamed(destination.routeName);
      return;
    }

    await AccessGateSheet.show(
      context: context,
      decision: decision,
      intent: intent,
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
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.requirement,
    required this.currentLevel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AccessLevel requirement;
  final AccessLevel currentLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meets = currentLevel.satisfies(requirement);
    final requirementLabel = switch (requirement) {
      AccessLevel.guest => null,
      AccessLevel.unverified => 'Sign-in required',
      AccessLevel.verified => 'Verification required',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(title),
          subtitle: Text(
            meets || requirementLabel == null
                ? subtitle
                : '$subtitle · $requirementLabel',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
