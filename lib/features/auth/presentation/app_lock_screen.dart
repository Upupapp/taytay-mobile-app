import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/session/app_lock_controller.dart';
import '../../../core/session/local_authenticator.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/wave_header.dart';

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
    // The notice pattern (RegTerms / DirectoryOffline): a centred wave header
    // with the lock tile, then the state in words and the two ways on. No back
    // control: the lock covers every route, and leaving is Sign out.
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const WaveHeader(
              centered: true,
              badge: IconTile.lucide(
                icon: TaytayIcons.lock,
                tileSize: IconTileSize.large,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.formGutter,
                Spacing.sm,
                Spacing.formGutter,
                Spacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      'Taytay LGU IDS is locked',
                      textAlign: TextAlign.center,
                      style: AppTypography.pageTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _explain(lock.lastOutcome),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.text,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  AppButton(
                    label: 'Unlock',
                    icon: TaytayIcons.scanFace,
                    loading: lock.isPrompting,
                    onPressed: lock.isPrompting ? null : onUnlock,
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Deliberately always available. See the class doc.
                  AuthLink(
                    'Sign out instead',
                    muted: true,
                    onPressed: lock.isPrompting ? null : onSignOut,
                  ),
                ],
              ),
            ),
          ],
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
