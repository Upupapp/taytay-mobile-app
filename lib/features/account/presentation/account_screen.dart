import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/taytay_icon.dart';

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

    // Confirmed, because it is not undoable without a new one-time code — and
    // the confirmation is where the resident is told what they keep.
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out of this device?',
      message:
          'You will need a new one-time code to sign in again. You can still '
          'browse Taytay services, offices and announcements as a guest.',
      confirmLabel: 'Sign out',
    );
    if (confirmed != true) return;

    // Revoke server-side first, then clear locally regardless of the outcome:
    // a resident on a borrowed phone must always be able to sign out.
    await dependencies.authRepository.signOut();
    await dependencies.session.signOut();
    await AppHaptics.fire(HapticIntent.warning, suppressed: reducedMotion);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final session = dependencies.session.state;
    final resident = session.residentOrNull;
    final healthFailure = _healthFailure;
    final healthSummary = _healthSummary;
    final TextStyle lede = AppTypography.bodyStyle.copyWith(
      color: BrandColors.muted,
    );

    return SoftPage(
      title: 'Account',
      offlineBanner: true,
      children: <Widget>[
        SettingsList(
          children: <Widget>[
            SettingsRow(
              icon: TaytayIcons.circleUser,
              tone: switch (session.accessLevel) {
                AccessLevel.verified => SettingsTone.green,
                AccessLevel.guest ||
                AccessLevel.unverified => SettingsTone.blue,
              },
              title: resident?.displayName ?? 'Resident',
              detail: switch (session.accessLevel) {
                AccessLevel.guest => 'Not signed in',
                AccessLevel.unverified => 'Account not yet verified',
                AccessLevel.verified => 'Verified resident',
              },
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('Preferences'),
        SettingsList(
          children: <Widget>[
            SettingsSwitchRow(
              value: _hapticsEnabled,
              onChanged: (enabled) {
                AppHaptics.setEnabled(enabled);
                setState(() => _hapticsEnabled = enabled);
              },
              icon: TaytayIcons.smartphone,
              title: 'Vibration feedback',
              detail: 'Short vibrations when an action succeeds or fails.',
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('Security'),
        SettingsList(
          children: <Widget>[
            SettingsRow(
              icon: TaytayIcons.shield,
              title: 'Sign-in and security',
              detail: 'App lock, signing out, and where you are signed in.',
              onTap: () => context.goNamed(AppRoute.security.routeName),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('Service status'),
        Text(
          'Check whether Taytay LGU services are reachable. This helps tell a '
          'service outage from a connection problem.',
          style: lede,
        ),
        const SizedBox(height: Spacing.md),
        FilledButton.tonal(
          onPressed: _checkingHealth ? null : _checkHealth,
          child: Text(_checkingHealth ? 'Checking…' : 'Check service status'),
        ),
        if (healthSummary != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          SoftNote(tone: NoteTone.success, message: healthSummary),
        ],
        if (healthFailure != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          FailureView(
            failure: healthFailure,
            environment: dependencies.config.environment,
            onRetry: _checkHealth,
          ),
        ],
        const SizedBox(height: Spacing.xxl),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const TaytayIcon(
            icon: TaytayIcons.logOut,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
          ),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
