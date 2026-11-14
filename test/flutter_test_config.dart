import 'dart:async';

import 'package:taytay_resident/core/live/live_updates.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';

/// The welcome and sign-in speck repeats for 7s. Left on, `pumpAndSettle`
/// never returns. Tests that need the loop set [WelcomeMotion.enabled] and
/// pump frames themselves.
///
/// The change stream (D-218) is never meant to end either, so the app's own
/// is off; a test about live updates builds its own [LiveUpdates].
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WelcomeMotion.enabled = false;
  LiveUpdates.enabledByDefault = false;
  await testMain();
}
