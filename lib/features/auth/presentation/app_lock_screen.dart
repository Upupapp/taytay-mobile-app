import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/session/app_lock_controller.dart';
import '../../../core/session/local_authenticator.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Covers the app while the local lock is unsatisfied.
///
/// ---
///
/// **Why an overlay and not a route.** The lock hides *whatever is already on
/// screen*, so it must cover every route including one a resident deep-linked
/// into. A route would have to be redirected to from the guard, which would put
/// a device-local convenience into the same mechanism that expresses server
/// authority — two very different things sharing one switch. This covers the
/// router's output instead, so the navigation stack is untouched and the
/// resident returns exactly where they were.
///
/// **There is always a way out.** [onSignOut] is unconditional. A resident whose
/// sensor has failed, whose enrolled finger is bandaged, or who simply cannot
/// pass the prompt must be able to leave — and signing out is safe, because it
/// destroys the session this lock was protecting.
class AppLockScreen extends StatelessWidget {
  const AppLockScreen({
    required this.lock,
    required this.onUnlock,
    required this.onSignOut,
    super.key,
  });

  final AppLockController lock;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(child: BrandMark(size: 72)),
                const SizedBox(height: Spacing.xl),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    'Taytay LGU IDS is locked',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _explain(lock.lastOutcome),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xxl),
                AppButton(
                  label: 'Unlock',
                  icon: Icons.fingerprint,
                  loading: lock.isPrompting,
                  onPressed: lock.isPrompting ? null : onUnlock,
                ),
                const SizedBox(height: Spacing.md),
                // Deliberately always available. See the class doc.
                TextButton(
                  onPressed: lock.isPrompting ? null : onSignOut,
                  child: const Text('Sign out instead'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _explain(LocalUnlockOutcome? outcome) => switch (outcome) {
    null =>
      'You turned on the app lock, so Taytay LGU IDS asks for your fingerprint, '
          'face or screen lock before showing your details again.',
    LocalUnlockOutcome.unlocked => 'Unlocking…',
    LocalUnlockOutcome.cancelled => 'Unlock to see your details again.',
    LocalUnlockOutcome.failed =>
      'That did not match. Try again, or sign out and sign back in.',
    LocalUnlockOutcome.unavailable =>
      'Your device could not show the unlock prompt. You can sign out and sign '
          'back in instead — nothing is wrong with your account.',
  };
}
