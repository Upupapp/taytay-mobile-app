import 'package:flutter/foundation.dart';

import '../session/access_policy.dart';
import '../session/session_state.dart';
import 'resident_intent.dart';

/// Holds the one thing a resident was part-way through when a gate stopped them.
///
/// ---
///
/// ## Rules this class exists to enforce
///
/// * **At most one.** Not a queue. A resident who taps three gated things before
///   signing in should resume the last one, not have three actions fire at them
///   afterwards. A queue also has no natural end, which is how "resume what you
///   were doing" becomes "replay everything you ever tried".
/// * **In memory only.** Never written to disk or to the keystore. An intent is
///   a fact about what someone was doing; surviving a process restart buys
///   almost nothing and means it can outlive the moment by days.
/// * **Time-bounded.** Expired intents are dropped on read
///   ([ResidentIntent.ttl]).
/// * **Cleared whenever the session changes.** Sign-out and expiry both wipe it.
///   Resuming an action across an account boundary is the failure this prevents.
/// * **Never grants anything.** [takeIfSatisfied] asks [AccessPolicy] whether
///   the *current* session meets the gate. It cannot make a session meet it, and
///   the server still authorises the request that follows.
class IntentController extends ChangeNotifier {
  IntentController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  ResidentIntent? _pending;

  /// The intent currently held, if it has not expired.
  ///
  /// Reading drops an expired intent rather than reporting it, so no caller has
  /// to remember to check the clock.
  ResidentIntent? get pending {
    final intent = _pending;
    if (intent == null) return null;
    if (intent.isExpired(_clock())) {
      _pending = null;
      return null;
    }
    return intent;
  }

  bool get hasPending => pending != null;

  /// Records what the resident was trying to do.
  ///
  /// Replaces any existing intent — see "at most one" above.
  void remember(ResidentIntentKind kind, {String? targetId}) {
    _pending = ResidentIntent(
      kind: kind,
      targetId: targetId,
      createdAt: _clock(),
    );
    notifyListeners();
  }

  /// Returns and consumes the pending intent **only if** [session] now satisfies
  /// the gate it was held for.
  ///
  /// Returns `null` when there is nothing pending, when it has expired, or when
  /// the session still does not meet the requirement — in which case the intent
  /// is *kept*, because a resident who signed in but is not yet verified is
  /// still on their way to the same goal.
  ///
  /// Consuming on success is what stops an intent firing twice: the caller gets
  /// it once, and a rebuild does not replay it.
  ResidentIntent? takeIfSatisfied(SessionState session) {
    final intent = pending;
    if (intent == null) return null;

    final decision = AccessPolicy.evaluate(
      session: session,
      requirement: intent.kind.requirement,
    );
    if (!intent.isSatisfiedBy(decision)) return null;

    _pending = null;
    notifyListeners();
    return intent;
  }

  /// Drops the pending intent — the resident dismissed the gate, or changed
  /// their mind.
  void clear() {
    if (_pending == null) return;
    _pending = null;
    notifyListeners();
  }

  /// Called when the session changes for any reason.
  ///
  /// Wired to sign-out and to fail-closed invalidation. Deliberately unconditional:
  /// deciding *which* intents are safe to keep across a session change is the
  /// kind of judgement that is wrong once and then wrong in production.
  void onSessionChanged() => clear();
}
