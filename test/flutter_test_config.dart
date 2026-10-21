import 'dart:async';

import 'package:taytay_resident/core/motion/motion_tokens.dart';

/// The welcome and sign-in speck repeats for 7s. Left on, `pumpAndSettle`
/// never returns. Tests that need the loop set [WelcomeMotion.enabled] and
/// pump frames themselves.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WelcomeMotion.enabled = false;
  await testMain();
}
