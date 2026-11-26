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
import '../../../l10n/app_localizations.dart';
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
    final AppStrings strings = AppStrings.of(context);

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
          title: strings.settingsTitle,
          offlineBanner: true,
          children: <Widget>[
            if (signedIn) ...<Widget>[
              SettingsSectionTitle(strings.settingsSectionYourAccount),
              SettingsList(
                children: <Widget>[
                  _Row(
                    icon: TaytayIcons.circleUser,
                    title: strings.settingsRowAccountTitle,
                    subtitle: strings.settingsRowAccountDetail,
                    route: AppRoute.account,
                  ),
                  _Row(
                    icon: TaytayIcons.lock,
                    title: strings.settingsRowSecurityTitle,
                    subtitle: strings.settingsRowSecurityDetail,
                    route: AppRoute.security,
                  ),
                  _Row(
                    icon: TaytayIcons.bell,
                    title: strings.settingsRowNotificationsTitle,
                    subtitle: strings.settingsRowNotificationsDetail,
                    route: AppRoute.notificationSettings,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl),
            ],

            SettingsSectionTitle(strings.settingsSectionPrivacy),
            SettingsList(
              children: <Widget>[
                _Row(
                  icon: TaytayIcons.fileText,
                  title: strings.settingsRowPrivacyNoticeTitle,
                  subtitle: strings.settingsRowPrivacyNoticeDetail,
                  route: AppRoute.profilePrivacy,
                ),
                if (signedIn)
                  _Row(
                    icon: TaytayIcons.shieldCheck,
                    title: strings.settingsRowConsentsTitle,
                    subtitle: strings.settingsRowConsentsDetail,
                    route: AppRoute.privacyControls,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            const _TelemetrySection(),

            const SizedBox(height: Spacing.xl),
            SettingsSectionTitle(strings.settingsSectionAccessibility),
            const _AccessibilitySection(),

            const SizedBox(height: Spacing.xl),
            SettingsSectionTitle(strings.settingsHelp),
            SettingsList(
              children: <Widget>[
                _Row(
                  icon: TaytayIcons.info,
                  title: strings.settingsRowHelpTitle,
                  subtitle: strings.settingsRowHelpDetail,
                  route: AppRoute.help,
                ),
              ],
            ),

            // Dev builds only, so its words stay English.
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
            SettingsSectionTitle(strings.settingsSectionAbout),
            const _AboutSection(),

            const SizedBox(height: Spacing.xl),
            if (signedIn)
              const _SignOutButton()
            else
              AppButton(
                label: strings.actionSignIn,
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
    final AppStrings strings = AppStrings.of(context);

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
              title: strings.settingsReduceMotionTitle,
              detail: osReducesMotion
                  ? strings.settingsReduceMotionOsOn
                  : strings.settingsReduceMotionDetail,
            ),
            SettingsSwitchRow(
              value: AppHaptics.isEnabled,
              onChanged: (on) => setState(() => AppHaptics.setEnabled(on)),
              icon: TaytayIcons.smartphone,
              title: strings.settingsVibrationTitle,
              detail: strings.settingsVibrationDetail,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Text(
          strings.settingsTextSizeNote,
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
    final AppStrings strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: telemetry,
      builder: (context, _) {
        final offerable =
            telemetry.shouldAskForConsent ||
            telemetry.consent != TelemetryConsent.notAsked;

        if (!offerable) {
          return Text(
            strings.settingsTelemetryNone,
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
              title: strings.settingsTelemetryTitle,
              detail: strings.settingsTelemetryDetail,
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
    final AppStrings strings = AppStrings.of(context);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.settingsAboutBody,
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            strings.settingsAboutReach,
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),

          // Only when the pipeline supplied one. An invented version number is
          // something a support desk would act on.
          if (kAppVersion.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              strings.settingsVersion(kAppVersion),
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
              title: strings.settingsTestBuildTitle,
              message: strings.settingsTestBuildBody(environment.badgeLabel),
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
    final AppStrings strings = AppStrings.of(context);
    return AppButton(
      label: strings.actionSignOut,
      variant: AppButtonVariant.secondary,
      onPressed: () async {
        final dependencies = AppDependencies.of(context);
        final confirmed = await ConfirmSheet.show(
          context: context,
          title: strings.settingsSignOutTitle,
          consequence: strings.settingsSignOutConsequence,
          confirmLabel: strings.actionSignOut,
          cancelLabel: strings.settingsStaySignedIn,
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
