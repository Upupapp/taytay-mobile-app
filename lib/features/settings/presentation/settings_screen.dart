import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_sheet.dart';

/// The build's version, supplied by the release pipeline.
///
/// **A `--dart-define`, not a package lookup.** Reading the real version needs a
/// plugin, and adding one to print a string is not a trade this app makes. When
/// the define is absent the row is omitted rather than showing "unknown" — an
/// app that reports a version it does not have is worse than one that says
/// nothing, because a support desk will act on it.
const String kAppVersion = String.fromEnvironment('TAYTAY_APP_VERSION');

/// Settings, help and the things a resident is entitled to read.
///
/// ---
///
/// **Public, and deliberately so.** Acceptance 1 of TAB 24 is that privacy text
/// is reachable without login, and the reasoning goes further than the privacy
/// notice: somebody deciding whether to register should be able to read what
/// they would be agreeing to, find out how to contact the LGU, and turn motion
/// down — all before handing over a mobile number.
///
/// So a guest sees help, about, terms, privacy, accessibility and a way in. The
/// account sections simply are not there, rather than being present and locked:
/// a wall of disabled rows tells somebody the app is not for them.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        // Through `AccessPolicy`, like every other "may they see it" question in
        // the app, rather than an `accessLevel` comparison.
        final signedIn =
            AccessPolicy.evaluate(
                  session: dependencies.session.state,
                  requirement: AccessRequirement.authenticated,
                )
                is AccessAllowed;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                if (signedIn) ...<Widget>[
                  const _SectionHeading('Your account'),
                  const _Row(
                    icon: Icons.person_outline,
                    title: 'Account',
                    subtitle: 'Your details and how you sign in',
                    route: AppRoute.account,
                  ),
                  const _Row(
                    icon: Icons.lock_outline,
                    title: 'Sign-in and security',
                    subtitle: 'App lock and devices',
                    route: AppRoute.security,
                  ),
                  const _Row(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    subtitle: 'What Taytay LGU tells you about',
                    route: AppRoute.notificationSettings,
                  ),
                  const SizedBox(height: Spacing.lg),
                ],

                const _SectionHeading('Privacy'),
                const _Row(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy notice',
                  subtitle: 'What Taytay LGU holds, and your rights',
                  route: AppRoute.profilePrivacy,
                ),
                if (signedIn)
                  const _Row(
                    icon: Icons.fact_check_outlined,
                    title: 'Your consents and account requests',
                    subtitle: 'What you agreed to, and asking for changes',
                    route: AppRoute.privacyControls,
                  ),

                const SizedBox(height: Spacing.lg),
                const _SectionHeading('Accessibility'),
                const _AccessibilitySection(),

                const SizedBox(height: Spacing.lg),
                const _SectionHeading('Help'),
                const _Row(
                  icon: Icons.help_outline,
                  title: 'Help and contacting Taytay LGU',
                  subtitle: 'Questions, and where to go in person',
                  route: AppRoute.help,
                ),

                const SizedBox(height: Spacing.lg),
                const _SectionHeading('About'),
                const _AboutSection(),

                const SizedBox(height: Spacing.xl),
                if (signedIn)
                  const _SignOutButton()
                else
                  AppButton(
                    label: 'Sign in',
                    onPressed: () => context.goNamed(AppRoute.signIn.routeName),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Motion and haptics, both of which work without an account.
///
/// **Both are device preferences and neither is sent anywhere.** Reduced motion
/// is an accessibility need, not a fact about a resident, and putting it on a
/// server would make it a preference the LGU holds about a person's disability.
class _AccessibilitySection extends StatefulWidget {
  const _AccessibilitySection();

  @override
  State<_AccessibilitySection> createState() => _AccessibilitySectionState();
}

class _AccessibilitySectionState extends State<_AccessibilitySection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final osReducesMotion = Motion.reducedFromPlatform;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile(
          value:
              MotionPreference.current == MotionPreference.reduced ||
              osReducesMotion,
          // The OS setting wins and cannot be overridden downward: somebody who
          // asked their phone to reduce motion has already answered, and an app
          // switch that could turn it back on would ignore them.
          onChanged: osReducesMotion
              ? null
              : (on) => setState(
                  () => MotionPreference.set(
                    on ? MotionPreference.reduced : MotionPreference.system,
                  ),
                ),
          contentPadding: EdgeInsets.zero,
          title: const Text('Reduce motion'),
          subtitle: Text(
            osReducesMotion
                ? 'Already on, because your phone is set to reduce motion.'
                : 'Shortens or removes animations.',
          ),
        ),
        SwitchListTile(
          value: AppHaptics.isEnabled,
          onChanged: (on) => setState(() => AppHaptics.setEnabled(on)),
          contentPadding: EdgeInsets.zero,
          title: const Text('Vibration feedback'),
          subtitle: const Text('Short buzzes when something is confirmed.'),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Text size follows your phone. This app is built to stay readable at '
          'the largest setting.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// About, terms and version.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final environment = AppDependencies.of(context).config.environment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Taytay LGU IDS is the resident app for the Municipality of Taytay, '
          'Rizal. It is published by the municipal government.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'This app is one way to reach Taytay LGU. The municipal hall and your '
          'barangay hall handle everything it does, and more.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Only when the pipeline supplied one. An invented version number is
        // something a support desk would act on.
        if (kAppVersion.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            'Version $kAppVersion',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // A staging build must never be mistaken for the real thing during LGU
        // acceptance testing.
        if (!environment.isProduction) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          AppBanner(
            tone: BannerTone.warning,
            title: 'Test build',
            message:
                'This is a ${environment.badgeLabel} build, not the app '
                'published to residents.',
          ),
        ],
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Sign out',
      variant: AppButtonVariant.secondary,
      onPressed: () async {
        final dependencies = AppDependencies.of(context);
        final confirmed = await ConfirmSheet.show(
          context: context,
          title: 'Sign out of this device?',
          consequence:
              'You will need your mobile number and a code to sign back in. '
              'Nothing you have sent Taytay LGU is removed.',
          confirmLabel: 'Sign out',
          cancelLabel: 'Stay signed in',
        );
        if (!confirmed) return;

        await dependencies.session.signOut();
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.goNamed(route.routeName),
    );
  }
}
