import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/app_lock_controller.dart';
import '../../../core/session/local_authenticator.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/soft_page.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../auth/domain/device_session_repository.dart';

/// Sign-in and security: the controls a resident has over their own session.
///
/// Three things, in the order they matter to somebody worried about their
/// account: lock this app, sign out of this device, and see where else the
/// account is signed in. The third is honest about not existing yet.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loadingDevices = false;
  AppFailure? _deviceFailure;
  List<DeviceSessionSummary>? _devices;

  Future<void> _toggleLock(bool enable) async {
    final lock = AppDependencies.of(context).appLock;
    final reduced = Motion.reduced(context);

    if (!enable) {
      await lock.disable();
      if (!mounted) return;
      await AppHaptics.fire(HapticIntent.selection, suppressed: reduced);
      return;
    }

    // Enabling requires passing the prompt once, so a resident cannot switch on
    // a lock their device turns out not to be able to satisfy.
    final String reason = AppStrings.of(context).coreAppLockEnableReason;
    final outcome = await lock.enable(reason: reason);
    if (!mounted) return;

    await AppHaptics.fire(
      outcome == LocalUnlockOutcome.unlocked
          ? HapticIntent.confirm
          : HapticIntent.error,
      suppressed: reduced,
    );
    if (outcome != LocalUnlockOutcome.unlocked && mounted) {
      Outcome.problem(
        context,
        _enableFailureCopy(AppStrings.of(context), outcome),
      );
    }
  }

  Future<void> _loadDevices() async {
    final repository = AppDependencies.of(context).deviceSessionRepository;
    setState(() {
      _loadingDevices = true;
      _deviceFailure = null;
      _devices = null;
    });

    final result = await repository.listActiveSessions();
    if (!mounted) return;
    setState(() {
      _loadingDevices = false;
      result.fold(
        onOk: (sessions) => _devices = sessions,
        onErr: (failure) => _deviceFailure = failure,
      );
    });
  }

  Future<void> _revokeOne(DeviceSessionSummary session) async {
    final AppStrings strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings.acctRevokeOneTitle(session.label),
      message: strings.acctRevokeOneBody,
      confirmLabel: strings.acctRevokeOneAction,
    );
    if (confirmed != true || !mounted) return;

    final result = await AppDependencies.of(
      context,
    ).deviceSessionRepository.revokeSession(sessionId: session.id);
    if (!mounted) return;

    // Re-read rather than removing the row locally. A place the app quietly
    // stopped showing is a place the resident stops worrying about while it is
    // still signed in.
    result.fold(
      onOk: (_) => unawaited(_loadDevices()),
      onErr: (failure) =>
          Outcome.problem(context, localisedResidentMessage(context, failure)),
    );
  }

  Future<void> _revokeOthers() async {
    final AppStrings strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings.acctRevokeOthersTitle,
      message: strings.acctRevokeOthersBody,
      confirmLabel: strings.acctRevokeOthersAction,
    );
    if (confirmed != true || !mounted) return;

    final result = await AppDependencies.of(
      context,
    ).deviceSessionRepository.revokeAllOtherSessions();
    if (!mounted) return;

    result.fold(
      onOk: (_) => unawaited(_loadDevices()),
      onErr: (failure) =>
          Outcome.problem(context, localisedResidentMessage(context, failure)),
    );
  }

  Future<void> _signOut() async {
    final dependencies = AppDependencies.of(context);
    final reduced = Motion.reduced(context);
    final AppStrings strings = AppStrings.of(context);

    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings.acctSignOutTitle,
      message: strings.acctSignOutBody,
      confirmLabel: strings.actionSignOut,
    );
    if (confirmed != true) return;

    // Revoke server-side first, then clear locally regardless of the outcome: a
    // resident on a borrowed phone must always be able to sign out, and a failed
    // network call must never be the reason a token stays on a device.
    await dependencies.authRepository.signOut();
    await dependencies.session.signOut();
    await AppHaptics.fire(HapticIntent.warning, suppressed: reduced);
    // No navigation: the router reacts to the session. This screen requires
    // authentication, so it is left automatically.
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final AppStrings strings = AppStrings.of(context);
    final lock = dependencies.appLock;
    final TextStyle lede = AppTypography.bodyStyle.copyWith(
      color: BrandColors.muted,
    );

    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) => SoftPage(
        title: strings.acctSecurityTitle,
        offlineBanner: true,
        children: <Widget>[
          SettingsSectionTitle(strings.acctAppLock),
          Text(strings.acctAppLockLede, style: lede),
          const SizedBox(height: Spacing.md),
          SettingsList(
            children: <Widget>[
              SettingsSwitchRow(
                value: lock.isEnabled,
                onChanged: lock.canEnable && !lock.isPrompting
                    ? _toggleLock
                    : null,
                icon: TaytayIcons.lock,
                title: strings.acctLockThisApp,
                detail: _availabilityCopy(strings, lock),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SoftNote(message: strings.acctAppLockNote),
          const SizedBox(height: Spacing.xl),
          SettingsSectionTitle(strings.acctWhereSignedIn),
          _DeviceSessions(
            loading: _loadingDevices,
            failure: _deviceFailure,
            devices: _devices,
            onLoad: _loadDevices,
            onRevoke: _revokeOne,
            onRevokeOthers: _revokeOthers,
          ),
          const SizedBox(height: Spacing.xl),
          SettingsSectionTitle(strings.acctThisDevice),
          Text(strings.acctSignOutLede, style: lede),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const TaytayIcon(
              icon: TaytayIcons.logOut,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
            ),
            label: Text(strings.acctSignOutThisDevice),
          ),
        ],
      ),
    );
  }

  static String _availabilityCopy(AppStrings strings, AppLockController lock) =>
      switch (lock.availability) {
        LocalUnlockAvailability.available when lock.isEnabled =>
          strings.acctLockOn,
        LocalUnlockAvailability.available => strings.acctLockOff,
        LocalUnlockAvailability.notEnrolled => strings.acctLockNotEnrolled,
        LocalUnlockAvailability.unsupported => strings.acctLockUnsupported,
      };

  static String _enableFailureCopy(
    AppStrings strings,
    LocalUnlockOutcome outcome,
  ) => switch (outcome) {
    LocalUnlockOutcome.unlocked => '',
    LocalUnlockOutcome.cancelled => strings.acctLockCancelled,
    LocalUnlockOutcome.failed => strings.acctLockFailed,
    LocalUnlockOutcome.unavailable => strings.acctLockUnavailable,
  };
}

/// The device list, or the honest reason there is not one.
///
/// It never renders a placeholder list. A resident opening this screen is
/// usually asking "is someone else in my account?", and a fabricated answer to
/// that question is worse than no answer.
class _DeviceSessions extends StatelessWidget {
  const _DeviceSessions({
    required this.loading,
    required this.failure,
    required this.devices,
    required this.onLoad,
    required this.onRevoke,
    required this.onRevokeOthers,
  });

  final bool loading;
  final AppFailure? failure;
  final List<DeviceSessionSummary>? devices;
  final Future<void> Function() onLoad;
  final void Function(DeviceSessionSummary) onRevoke;
  final VoidCallback onRevokeOthers;

  @override
  Widget build(BuildContext context) {
    final list = devices;
    final failure = this.failure;
    final AppStrings strings = AppStrings.of(context);

    if (loading) {
      return LoadingSkeleton(
        count: 2,
        semanticLabel: strings.acctCheckingSignIns,
      );
    }

    if (failure != null) {
      // Wired at TAB 03, so this is a real failure rather than a missing
      // endpoint — and it must not be reassuring. A resident who came here to
      // check for an intruder and is told nothing has learned nothing.
      return ErrorState(
        title: strings.acctSignInsErrorTitle,
        message: strings.acctSignInsErrorBody,
        onRetry: onLoad,
        boxed: true,
      );
    }

    if (list == null) {
      return SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              strings.acctCheckDevicesLede,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
            const SizedBox(height: Spacing.md),
            FilledButton.tonal(
              onPressed: onLoad,
              child: Text(strings.acctCheckMyDevices),
            ),
          ],
        ),
      );
    }

    final others = list.where((d) => !d.isCurrentDevice).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsList(
          children: <Widget>[
            for (final device in list)
              SettingsRow(
                icon: TaytayIcons.smartphone,
                tone: device.isCurrentDevice
                    ? SettingsTone.green
                    : SettingsTone.blue,
                title: device.label,
                detail: device.isCurrentDevice
                    ? strings.acctThisDevice
                    : _lastSeenCopy(strings, device.lastSeenAt),
                // Only other sign-ins get a revoke action. Ending the current
                // one is "sign out", which lives below with its own
                // confirmation and its own local-first behaviour — offering it
                // twice under two names is how a resident ends up unsure which
                // button did what.
                trailing: device.isCurrentDevice
                    ? null
                    : TextButton(
                        onPressed: () => onRevoke(device),
                        child: Text(strings.actionSignOut),
                      ),
              ),
          ],
        ),
        if (others.length > 1) ...<Widget>[
          const SizedBox(height: Spacing.md),
          // One request, not a loop over the list. A loop that fails halfway
          // leaves some phones signed out and some not, and no way for the
          // resident to tell which — on the screen they opened because they had
          // lost one.
          OutlinedButton.icon(
            onPressed: onRevokeOthers,
            icon: const TaytayIcon(
              icon: TaytayIcons.logOut,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
            ),
            label: Text(strings.acctSignOutOtherDevices(others.length)),
          ),
        ],
      ],
    );
  }

  /// A last-seen time a resident can judge "is that me?" against.
  static String _lastSeenCopy(AppStrings strings, DateTime? lastSeenAt) {
    if (lastSeenAt == null) return strings.acctSignedIn;
    final DateTime seen = ManilaTime.of(lastSeenAt);
    return strings.acctLastUsed('${seen.day}/${seen.month}/${seen.year}');
  }
}
