import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/config/app_version.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/telemetry/telemetry.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/surface_cards.dart';

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

        return SoftPage(
          title: 'Settings',
          offlineBanner: true,
          children: <Widget>[
            if (signedIn) ...<Widget>[
              const SettingsSectionTitle('Your account'),
              const SettingsList(
                children: <Widget>[
                  _Row(
                    icon: TaytayIcons.circleUser,
                    title: 'Account',
                    subtitle: 'Your details and how you sign in',
                    route: AppRoute.account,
                  ),
                  _Row(
                    icon: TaytayIcons.lock,
                    title: 'Sign-in and security',
                    subtitle: 'App lock and devices',
                    route: AppRoute.security,
                  ),
                  _Row(
                    icon: TaytayIcons.bell,
                    title: 'Notifications',
                    subtitle: 'What Taytay LGU tells you about',
                    route: AppRoute.notificationSettings,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
            ],

            const SettingsSectionTitle('Privacy'),
            SettingsList(
              children: <Widget>[
                const _Row(
                  icon: TaytayIcons.fileText,
                  title: 'Privacy notice',
                  subtitle: 'What Taytay LGU holds, and your rights',
                  route: AppRoute.profilePrivacy,
                ),
                if (signedIn)
                  const _Row(
                    icon: TaytayIcons.shieldCheck,
                    title: 'Your consents and account requests',
                    subtitle: 'What you agreed to, and asking for changes',
                    route: AppRoute.privacyControls,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            const _TelemetrySection(),

            const SizedBox(height: Spacing.xl),
            const SettingsSectionTitle('Accessibility'),
            const _AccessibilitySection(),

            const SizedBox(height: Spacing.xl),
            const SettingsSectionTitle('Help'),
            const SettingsList(
              children: <Widget>[
                _Row(
                  icon: TaytayIcons.info,
                  title: 'Help and contacting Taytay LGU',
                  subtitle: 'Questions, and where to go in person',
                  route: AppRoute.help,
                ),
              ],
            ),

            if (dependencies.config.environment ==
                AppEnvironment.dev) ...<Widget>[
              const SizedBox(height: Spacing.xl),
              const SettingsSectionTitle('Development'),
              const SettingsList(
                children: <Widget>[
                  _Row(
                    icon: TaytayIcons.images,
                    title: 'Component gallery',
                    subtitle: 'Shared components, in this dev build only',
                    route: AppRoute.componentGallery,
                  ),
                ],
              ),
            ],

            const SizedBox(height: Spacing.xl),
            const SettingsSectionTitle('About'),
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
    final osReducesMotion = Motion.reducedFromPlatform;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsList(
          children: <Widget>[
            SettingsSwitchRow(
              value:
                  MotionPreference.current == MotionPreference.reduced ||
                  osReducesMotion,
              // The OS setting wins and cannot be overridden downward: somebody
              // who asked their phone to reduce motion has already answered,
              // and an app switch that could turn it back on would ignore them.
              onChanged: osReducesMotion
                  ? null
                  : (on) => setState(
                      () => MotionPreference.set(
                        on ? MotionPreference.reduced : MotionPreference.system,
                      ),
                    ),
              icon: TaytayIcons.pause,
              title: 'Reduce motion',
              detail: osReducesMotion
                  ? 'Already on, because your phone is set to reduce motion.'
                  : 'Shortens or removes animations.',
            ),
            SettingsSwitchRow(
              value: AppHaptics.isEnabled,
              onChanged: (on) => setState(() => AppHaptics.setEnabled(on)),
              icon: TaytayIcons.smartphone,
              title: 'Vibration feedback',
              detail: 'Short buzzes when something is confirmed.',
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Text size follows your phone. This app is built to stay readable at '
          'the largest setting.',
          style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
        ),
      ],
    );
  }
}

/// What the app sends about how it is used, and the switch when there is one.
///
/// ---
///
/// **The statement is shown even when there is nothing to switch.** A government
/// app that collects no usage data should say so, plainly, on the screen where a
/// resident goes looking — silence reads as "they are not telling me", and on a
/// municipal ID app that is the wrong impression to leave.
///
/// The switch appears only when telemetry could actually run: a resident asked
/// for permission to do something the app cannot do is a dialog that costs trust
/// and buys nothing.
class _TelemetrySection extends StatefulWidget {
  const _TelemetrySection();

  @override
  State<_TelemetrySection> createState() => _TelemetrySectionState();
}

class _TelemetrySectionState extends State<_TelemetrySection> {
  @override
  Widget build(BuildContext context) {
    final telemetry = AppDependencies.of(context).telemetry;

    return AnimatedBuilder(
      animation: telemetry,
      builder: (context, _) {
        final offerable =
            telemetry.shouldAskForConsent ||
            telemetry.consent != TelemetryConsent.notAsked;

        if (!offerable) {
          return Text(
            'This app sends no information about how you use it to anyone. It '
            'contacts Taytay LGU only to show you what you asked for.',
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          );
        }

        return SettingsList(
          children: <Widget>[
            SettingsSwitchRow(
              value: telemetry.consent == TelemetryConsent.granted,
              onChanged: (on) => telemetry.setConsent(
                on ? TelemetryConsent.granted : TelemetryConsent.declined,
              ),
              icon: TaytayIcons.info,
              title: 'Help improve this app',
              detail:
                  'Sends which screens are opened and whether things worked. '
                  'Never your name, your documents, what you applied for, or '
                  'anything you typed.',
            ),
          ],
        );
      },
    );
  }
}

/// About, terms and version.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final environment = AppDependencies.of(context).config.environment;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Taytay LGU IDS is the resident app for the Municipality of Taytay, '
            'Rizal. It is published by the municipal government.',
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'This app is one way to reach Taytay LGU. The municipal hall and '
            'your barangay hall handle everything it does, and more.',
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),

          // Only when the pipeline supplied one. An invented version number is
          // something a support desk would act on.
          if (kAppVersion.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'Version $kAppVersion',
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.medium,
                color: BrandColors.muted,
              ),
            ),
          ],

          // A staging build must never be mistaken for the real thing during
          // LGU acceptance testing.
          if (!environment.isProduction) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SoftNote(
              tone: NoteTone.warning,
              title: 'Test build. ',
              message:
                  'This is a ${environment.badgeLabel} build, not the app '
                  'published to residents.',
            ),
          ],
        ],
      ),
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
    return SettingsRow(
      icon: icon,
      title: title,
      detail: subtitle,
      onTap: () => context.goNamed(route.routeName),
    );
  }
}
