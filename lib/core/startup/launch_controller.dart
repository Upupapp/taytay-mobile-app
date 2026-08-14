import 'package:flutter/foundation.dart';

import '../storage/secure_secret_store.dart';

/// Whether this install has finished the welcome scenes.
///
/// Three states rather than a boolean, for the same reason the session has a
/// "restoring" state: "not read yet" must never be mistaken for "not seen". If
/// it were, every cold start would flash the welcome screens at a returning
/// resident before correcting itself.
enum LaunchState {
  /// The flag has not been read yet.
  restoring,

  /// This install has never completed the welcome scenes.
  firstLaunch,

  /// The welcome scenes have been completed or skipped.
  returning,
}

/// Owns [LaunchState].
///
/// ---
///
/// **Why this lives in the keystore alongside the session.**
///
/// "Welcome seen" is not a secret — it says nothing about a resident beyond the
/// fact that this app was opened before. It is stored through [SecretStore]
/// anyway because the app has exactly **one** persistence mechanism, and adding
/// a second, unencrypted one to hold a single boolean would mean a new
/// dependency (`shared_preferences` is banned by CLAUDE.md Article 5.3 and by a
/// test), a second thing to clear on sign-out, and a second place a future
/// contributor might put something that *is* sensitive. Encrypting a boolean
/// costs nothing measurable.
///
/// **It is not cleared on sign-out.** The flag belongs to the install, not to
/// the account: a resident who signs out has still seen the welcome scenes, and
/// replaying them would be a small insult. It *is* cleared by
/// [SecretStore.clear], which is a whole-app reset.
///
/// **It grants nothing.** Completing onboarding is not a capability. Nothing in
/// the app reads this to decide what a resident may do — only whether to show
/// the welcome scenes once.
class LaunchController extends ChangeNotifier {
  LaunchController({required SecretStore secrets}) : _secrets = secrets;

  final SecretStore _secrets;

  /// Namespaced apart from the session keys so a whole-session clear cannot
  /// accidentally take it, and so the key list stays readable.
  static const String welcomeCompletedKey = 'taytay.launch.welcome_completed';

  static const String _completedValue = 'true';

  LaunchState _state = LaunchState.restoring;

  LaunchState get state => _state;

  bool get isFirstLaunch => _state == LaunchState.firstLaunch;

  bool get isResolved => _state != LaunchState.restoring;

  /// Reads the flag once at startup.
  ///
  /// A read failure is treated as [LaunchState.firstLaunch]: showing the welcome
  /// scenes to someone who has seen them is a minor annoyance, while skipping
  /// them for a genuine first-time resident means they never learn what the app
  /// asks for or why — which is the one thing onboarding exists to do.
  Future<void> restore() async {
    String? stored;
    try {
      stored = await _secrets.read(welcomeCompletedKey);
    } on Object {
      stored = null;
    }
    _set(
      stored == _completedValue
          ? LaunchState.returning
          : LaunchState.firstLaunch,
    );
  }

  /// Records that the welcome scenes are done — whether completed or skipped.
  ///
  /// Skipping counts. A resident who chose to skip has made a decision, and
  /// asking again on the next launch overrides it, which is the behaviour that
  /// makes onboarding feel like a trap.
  Future<void> markWelcomeCompleted() async {
    if (_state == LaunchState.returning) return;
    try {
      await _secrets.write(welcomeCompletedKey, _completedValue);
    } on Object {
      // A failed write means the scenes appear again next launch. Annoying,
      // never blocking: the resident still reaches the app.
    }
    _set(LaunchState.returning);
  }

  /// Test and support hook for re-running the welcome experience.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _secrets.delete(welcomeCompletedKey);
    _set(LaunchState.firstLaunch);
  }

  void _set(LaunchState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }
}
