import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/router/app_routes.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_state.dart';
import '../../l10n/app_localizations.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// Explains an ended session and offers two ways forward.
///
/// ---
///
/// **Why a sheet at all, when the router already moved them.** The guard is
/// correct but silent: a resident looking at their digital ID one moment and a
/// sign-in screen the next has been given no reason, and the reason matters —
/// it is the difference between "the app is broken" and "this is how it protects
/// me". The screen change is the mechanism; this is the explanation.
///
/// **Both exits are real.** "Sign in again" is the recovery. "Continue as guest"
/// is not a dismissal — it is the honest second option, because everything
/// public in this app stays available to someone who is not signed in, and a
/// resident who is out of signal or in a queue should not be told their only
/// choice is to authenticate.
///
/// It appears once per expiry: [SessionExpiryWatcher] tracks the transition, not
/// the state, so it cannot re-open every time the widget rebuilds.
abstract final class SessionExpiredSheet {
  static Future<void> show(BuildContext context) async {
    final router = GoRouter.of(context);
    final reduced = Motion.reduced(context);

    // Not awaited. The haptic is a platform round trip, and the sheet is the
    // explanation a resident is waiting for — delaying the words until the
    // vibration comes back is the wrong order, and on a device with no haptic
    // support it would delay them on a call that resolves late or not at all.
    unawaited(AppHaptics.fire(HapticIntent.warning, suppressed: reduced));

    await AppSheet.show<void>(
      context: context,
      title: AppStrings.of(context).sessionEndedTitle,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            AppStrings.of(sheetContext).sessionEndedBody,
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.sm),
          // WHAT THIS USED TO SAY WAS "Nothing you submitted has been lost."
          //
          // Narrowly true and read as something else entirely. A resident does
          // not distinguish what they *submitted* from what they *typed*, and
          // this app queues nothing (`DL-118`): work not yet sent when a session
          // dies is gone. Telling somebody nothing was lost, and having them
          // find out otherwise, is worse than losing it — it is the app's own
          // rule about failed sends (`DL-87`) applied to the moment a session
          // ends.
          Text(
            AppStrings.of(sheetContext).sessionEndedUnsent,
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.xl),
          AppButton(
            label: AppStrings.of(sheetContext).sessionEndedSignInAgain,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              router.goNamed(AppRoute.signIn.routeName);
            },
          ),
          const SizedBox(height: Spacing.sm),
          AppButton(
            label: 'Continue as guest',
            variant: AppButtonVariant.text,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              router.goNamed(AppRoute.home.routeName);
            },
          ),
        ],
      ),
    );
  }
}

/// Shows [SessionExpiredSheet] once, each time a session ends unexpectedly.
///
/// Sits above the router's output so it works from any screen, and reacts to the
/// *transition* into `GuestSession(expired)` rather than to the state, so a
/// rebuild cannot re-open it. A deliberate sign-out is excluded: the resident
/// asked for that and does not need it explained.
///
/// [navigatorKey] is the router's own navigator. The sheet is shown against it
/// rather than against this widget's context, because this widget sits *above*
/// the router's `Navigator` in order to survive route changes — and a modal
/// sheet needs a `Navigator` below it, not above.
class SessionExpiryWatcher extends StatefulWidget {
  const SessionExpiryWatcher({
    required this.session,
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final SessionController session;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<SessionExpiryWatcher> createState() => _SessionExpiryWatcherState();
}

class _SessionExpiryWatcherState extends State<SessionExpiryWatcher> {
  bool _showing = false;

  /// Assigned eagerly in [initState], **not** as a `late` initialiser. A `late`
  /// field is not evaluated until it is first read, which here would be inside
  /// the listener — after the session had already become a guest. It would then
  /// initialise to "was not authenticated", the transition would never be
  /// detected, and the sheet would never appear.
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _wasAuthenticated = widget.session.state is AuthenticatedSession;
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final state = widget.session.state;
    final isAuthenticated = state is AuthenticatedSession;
    final expired =
        _wasAuthenticated &&
        state is GuestSession &&
        state.endedReason == SessionEndedReason.expired;
    _wasAuthenticated = isAuthenticated;

    if (!expired || _showing || !mounted) return;
    _showing = true;

    // Deferred: the router is redirecting in this same frame, and pushing a
    // route during a navigation is how a sheet ends up orphaned above a screen
    // that no longer exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigatorContext = widget.navigatorKey.currentContext;
      if (!mounted || navigatorContext == null) {
        _showing = false;
        return;
      }
      await SessionExpiredSheet.show(navigatorContext);
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
