import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/app_lock_controller.dart';
import '../../../core/session/local_authenticator.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/outcome_feedback.dart';
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
    final outcome = await lock.enable();
    if (!mounted) return;

    await AppHaptics.fire(
      outcome == LocalUnlockOutcome.unlocked
          ? HapticIntent.confirm
          : HapticIntent.error,
      suppressed: reduced,
    );
    if (outcome != LocalUnlockOutcome.unlocked && mounted) {
      Outcome.problem(context, _enableFailureCopy(outcome));
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
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out ${session.label}?',
      // States the consequence, not just "are you sure". A confirmation that
      // only asks whether somebody meant to tap tests intent, not understanding.
      message:
          'That device will be signed out of your Taytay LGU IDS account. '
          'Whoever is using it will need a new one-time code sent to your '
          'mobile number to sign in again. This device stays signed in.',
      confirmLabel: 'Sign out that device',
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
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out all other devices?',
      message:
          'Every other phone, tablet or computer signed in to your Taytay LGU '
          'IDS account will be signed out. This device stays signed in. Anyone '
          'using the others will need a new one-time code sent to your mobile '
          'number.',
      confirmLabel: 'Sign out the others',
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

    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out of this device?',
      message:
          'You will need a new one-time code to sign in again. You can still '
          'browse Taytay services, offices and announcements as a guest.',
      confirmLabel: 'Sign out',
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
    final theme = Theme.of(context);
    final dependencies = AppDependencies.of(context);
    final lock = dependencies.appLock;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign-in and security')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: lock,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Semantics(
                header: true,
                child: Text('App lock', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Ask for your fingerprint, face or screen lock before showing '
                'your details again after you leave the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.md),
              SwitchListTile(
                value: lock.isEnabled,
                onChanged: lock.canEnable && !lock.isPrompting
                    ? _toggleLock
                    : null,
                title: const Text('Lock this app'),
                subtitle: Text(_availabilityCopy(lock)),
              ),
              const SizedBox(height: Spacing.md),
              const AppBanner(
                tone: BannerTone.info,
                message:
                    'This lock protects this phone only. It is not how Taytay '
                    'LGU knows who you are, and turning it on does not change '
                    'what your account can do.',
              ),
              const SizedBox(height: Spacing.xxl),
              Semantics(
                header: true,
                child: Text(
                  'Where you are signed in',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              _DeviceSessions(
                loading: _loadingDevices,
                failure: _deviceFailure,
                devices: _devices,
                onLoad: _loadDevices,
                onRevoke: _revokeOne,
                onRevokeOthers: _revokeOthers,
              ),
              const SizedBox(height: Spacing.xxl),
              Semantics(
                header: true,
                child: Text('This device', style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Signing out removes your session from this phone. Public '
                'Taytay services stay available to you as a guest.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.md),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out of this device'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _availabilityCopy(AppLockController lock) =>
      switch (lock.availability) {
        LocalUnlockAvailability.available when lock.isEnabled =>
          'On. You will be asked to unlock when you come back to the app.',
        LocalUnlockAvailability.available => 'Off.',
        LocalUnlockAvailability.notEnrolled =>
          'Set up a fingerprint, face unlock or screen lock in your phone '
              'settings to use this.',
        LocalUnlockAvailability.unsupported =>
          'This phone cannot show an unlock prompt, so the app lock is not '
              'available here.',
      };

  static String _enableFailureCopy(LocalUnlockOutcome outcome) =>
      switch (outcome) {
        LocalUnlockOutcome.unlocked => '',
        LocalUnlockOutcome.cancelled =>
          'App lock was not turned on. You can try again any time.',
        LocalUnlockOutcome.failed =>
          'That did not match, so the app lock stays off.',
        LocalUnlockOutcome.unavailable =>
          'Your phone could not show the unlock prompt.',
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
    final theme = Theme.of(context);
    final list = devices;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (failure != null) {
      // Wired at TAB 03, so this is a real failure rather than a missing
      // endpoint — and it must not be reassuring. A resident who came here to
      // check for an intruder and is told nothing has learned nothing.
      return AppBanner(
        tone: BannerTone.warning,
        title: 'Could not check your sign-ins',
        message:
            'We could not reach Taytay LGU IDS to list where your account is '
            'signed in. Try again in a moment. Signing out here always ends '
            'this device\'s session.',
        action: TextButton(onPressed: onLoad, child: const Text('Try again')),
      );
    }

    if (list == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Check the devices your Taytay LGU IDS account is currently '
              'signed in on.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton(
              onPressed: onLoad,
              child: const Text('Check my devices'),
            ),
          ],
        ),
      );
    }

    final others = list.where((d) => !d.isCurrentDevice).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final device in list)
          ListTile(
            leading: const Icon(Icons.smartphone_outlined),
            title: Text(device.label),
            subtitle: Text(
              device.isCurrentDevice
                  ? 'This device'
                  : _lastSeenCopy(device.lastSeenAt),
            ),
            // Only other sign-ins get a revoke action. Ending the current one is
            // "sign out", which lives above with its own confirmation and its
            // own local-first behaviour — offering it twice under two names is
            // how a resident ends up unsure which button did what.
            trailing: device.isCurrentDevice
                ? null
                : TextButton(
                    onPressed: () => onRevoke(device),
                    child: const Text('Sign out'),
                  ),
          ),
        if (others.length > 1) ...<Widget>[
          const SizedBox(height: Spacing.md),
          // One request, not a loop over the list. A loop that fails halfway
          // leaves some phones signed out and some not, and no way for the
          // resident to tell which — on the screen they opened because they had
          // lost one.
          OutlinedButton.icon(
            onPressed: onRevokeOthers,
            icon: const Icon(Icons.logout_outlined),
            label: Text('Sign out all ${others.length} other devices'),
          ),
        ],
      ],
    );
  }

  /// A last-seen time a resident can judge "is that me?" against.
  static String _lastSeenCopy(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Signed in';
    final DateTime seen = ManilaTime.of(lastSeenAt);
    return 'Last used ${seen.day}/${seen.month}/${seen.year}';
  }
}
