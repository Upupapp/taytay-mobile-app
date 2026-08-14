import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/access_level.dart';
import '../../../shared/widgets/failure_view.dart';

/// Account and preferences for a signed-in resident.
///
/// It shows only what the session already holds. Demographics, addresses and
/// household links are deliberately absent: they belong to the resident-profile
/// screens that fetch them when they are actually displayed, so this screen
/// never becomes a cache of personal data.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _hapticsEnabled = AppHaptics.isEnabled;
  bool _checkingHealth = false;
  String? _healthSummary;
  AppFailure? _healthFailure;

  Future<void> _checkHealth() async {
    final dependencies = AppDependencies.of(context);
    setState(() {
      _checkingHealth = true;
      _healthFailure = null;
      _healthSummary = null;
    });

    final result = await dependencies.platformRepository.checkHealth();
    if (!mounted) return;

    setState(() {
      _checkingHealth = false;
      result.fold(
        onOk: (health) => _healthSummary =
            '${health.service} · ${health.status} '
            '· ${health.apiVersion}',
        onErr: (failure) => _healthFailure = failure,
      );
    });
  }

  Future<void> _signOut() async {
    final dependencies = AppDependencies.of(context);
    final reducedMotion = Motion.reduced(context);

    // Revoke server-side first, then clear locally regardless of the outcome:
    // a resident on a borrowed phone must always be able to sign out.
    await dependencies.authRepository.signOut();
    await dependencies.session.signOut();
    await AppHaptics.fire(HapticIntent.warning, suppressed: reducedMotion);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final theme = Theme.of(context);
    final session = dependencies.session.state;
    final resident = session.residentOrNull;
    final healthFailure = _healthFailure;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    resident?.displayName ?? 'Resident',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    switch (session.accessLevel) {
                      AccessLevel.guest => 'Not signed in',
                      AccessLevel.unverified => 'Account not yet verified',
                      AccessLevel.verified => 'Verified resident',
                    },
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Text('Preferences', style: theme.textTheme.titleMedium),
          SwitchListTile(
            value: _hapticsEnabled,
            onChanged: (enabled) {
              AppHaptics.setEnabled(enabled);
              setState(() => _hapticsEnabled = enabled);
            },
            title: const Text('Vibration feedback'),
            subtitle: const Text(
              'Short vibrations when an action succeeds or fails.',
            ),
          ),
          const Divider(),
          const SizedBox(height: Spacing.lg),
          Text('Service status', style: theme.textTheme.titleMedium),
          const SizedBox(height: Spacing.sm),
          Text(
            'Check whether Taytay LGU services are reachable. This helps tell a '
            'service outage from a connection problem.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton(
            onPressed: _checkingHealth ? null : _checkHealth,
            child: Text(_checkingHealth ? 'Checking…' : 'Check service status'),
          ),
          if (_healthSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: Text(_healthSummary!, style: theme.textTheme.bodyMedium),
            ),
          if (healthFailure != null)
            FailureView(
              failure: healthFailure,
              environment: dependencies.config.environment,
              onRetry: _checkHealth,
            ),
          const SizedBox(height: Spacing.xxl),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
