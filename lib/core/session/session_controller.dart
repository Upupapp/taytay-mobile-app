import 'package:flutter/foundation.dart';

import 'access_level.dart';
import 'push_registration.dart';
import 'session_state.dart';
import 'session_store.dart';

/// Owns the app's [SessionState] and is the only thing allowed to change it.
///
/// It is a [ChangeNotifier] because the router listens to it: navigation is a
/// *consequence* of session state, never the other way round. No screen may
/// construct an [AuthenticatedSession] for itself — that is the mechanism by
/// which a UI-only "logged in" flag drifts away from what the server believes.
///
/// State transitions:
/// ```
///   SessionRestoring ──restore()──> GuestSession | AuthenticatedSession
///   GuestSession ──signIn()──────> AuthenticatedSession
///   AuthenticatedSession ──signOut()───────> GuestSession(signedOut)
///   AuthenticatedSession ──handleUnauthenticated()──> GuestSession(expired)
///   AuthenticatedSession ──applyVerificationTier()──> AuthenticatedSession
///   AuthenticatedSession ──endSessionIfTokenExpired()──> GuestSession(expired)
/// ```
class SessionController extends ChangeNotifier {
  SessionController({
    required SessionStore store,
    DateTime Function()? clock,
    PushRegistrationWithdrawal? pushRegistration,
  }) : _store = store,
       _now = clock ?? DateTime.now,
       _pushRegistration = pushRegistration;

  final SessionStore _store;

  /// Bound at the composition root, usually *after* construction.
  ///
  /// Not final, and that is the composition root's shape rather than laziness:
  /// the thing that withdraws a registration needs the API client, the API
  /// client needs this controller for its bearer token, and something has to be
  /// built first. A constructor argument is still accepted so a test can pass
  /// one straight in.
  ///
  /// Null in tests and in any build with no push registration at all, where
  /// there is nothing to withdraw and nothing to bind.
  PushRegistrationWithdrawal? _pushRegistration;

  /// Binds the withdrawal once the API client exists. See [_pushRegistration].
  void bindPushRegistration(PushRegistrationWithdrawal withdrawal) {
    _pushRegistration = withdrawal;
  }

  /// Injectable so expiry can be tested without waiting for real time to pass.
  final DateTime Function() _now;

  SessionState _state = const SessionRestoring();

  SessionState get state => _state;

  AccessLevel get accessLevel => _state.accessLevel;

  /// Reads persisted credentials once at startup.
  ///
  /// A stored session is *resumed optimistically*: the app trusts it enough to
  /// render, and the first authenticated API call is what actually confirms it.
  /// If that call returns 401, [handleUnauthenticated] pulls the session down.
  /// The alternative — blocking the splash screen on a network round trip —
  /// makes the app unusable on a weak connection for no security gain, since the
  /// server re-authorises every request anyway.
  ///
  /// [notBefore] delays *publishing* the result, without delaying the read. The
  /// splash screen passes its minimum display time here so the app cannot flash
  /// past it on a fast device. Publishing is what moves the router, so holding
  /// the state is the only thing that actually holds the screen — awaiting a
  /// delay in the widget would not, because the state would already have changed
  /// underneath it.
  ///
  /// A token the app already knows is dead is *not* resumed: it is cleared and
  /// the resident is told their session ended, which is both true and quicker
  /// than a round trip that can only return `401`.
  Future<void> restore({Future<void>? notBefore}) async {
    final stored = await _store.read();
    if (notBefore != null) await notBefore;

    if (stored == null) {
      _set(const GuestSession());
      return;
    }
    if (stored.isExpiredAt(_now())) {
      await _store.clear();
      _set(const GuestSession(endedReason: SessionEndedReason.expired));
      return;
    }
    _set(AuthenticatedSession(stored.resident));
  }

  /// Records a successful authentication.
  ///
  /// [resident] must be built from the server's response. The access level comes
  /// from the server's verification tier; the app never decides it.
  ///
  /// [expiresAt] is the server's own `expires_at`. Passing it lets the app stop
  /// using a token it can see is dead; omitting it simply defers to the server.
  Future<void> signIn({
    required ResidentSession resident,
    required String accessToken,
    DateTime? expiresAt,
  }) async {
    await _store.write(
      StoredSession(
        resident: resident,
        accessToken: accessToken,
        expiresAt: expiresAt,
      ),
    );
    _set(AuthenticatedSession(resident));
  }

  /// Deliberate sign-out by the resident.
  Future<void> signOut() async {
    await _withdrawPushRegistration();
    await _store.clear();
    _set(const GuestSession(endedReason: SessionEndedReason.signedOut));
  }

  /// The server said `401 UNAUTHENTICATED`. Wired into `ApiClient` so every
  /// endpoint gets this behaviour without remembering to ask for it.
  ///
  /// Idempotent: several in-flight requests can fail at once, and the resident
  /// should be told the session expired exactly once.
  Future<void> handleUnauthenticated() async {
    if (_state is GuestSession) return;
    // Attempted here too, and expected to fail: the credential it would need is
    // the one the server has just refused. It is still attempted rather than
    // skipped, because a 401 on one endpoint does not always mean the token is
    // dead for all of them, and the cost of trying is one request that is
    // already known not to block anything.
    await _withdrawPushRegistration();
    await _store.clear();
    _set(const GuestSession(endedReason: SessionEndedReason.expired));
  }

  /// Applies a verification tier the server has just reported, e.g. after the
  /// LGU approves a verification request while the app is open.
  ///
  /// Ignored when nobody is signed in — an unauthenticated app cannot acquire a
  /// verified level.
  void applyVerificationTier(String? tier) {
    final current = _state;
    if (current is! AuthenticatedSession) return;
    final level = AccessLevel.fromVerificationTier(tier);
    if (level == current.resident.accessLevel) return;
    _set(AuthenticatedSession(current.resident.copyWith(accessLevel: level)));
  }

  /// The access token for the API layer, or `null` for a guest.
  ///
  /// A token past its own `expires_at` is withheld rather than sent. Presenting
  /// a credential the app knows is dead cannot succeed, and it puts an expired
  /// bearer token on the wire for no reason.
  Future<String?> currentAccessToken() async {
    final stored = await _store.read();
    if (stored == null || stored.isExpiredAt(_now())) return null;
    return stored.accessToken;
  }

  /// Ends the session if the stored token's own deadline has passed.
  ///
  /// Called at the moments a resident would otherwise meet a screen that is
  /// about to fail: app resume, and before an action that needs authority.
  /// Returns true when it ended a session.
  ///
  /// This is the *only* locally-decided way a session ends besides deliberate
  /// sign-out, and it is safe precisely because it can only ever take access
  /// away. Nothing here can extend a session or raise a level — that remains a
  /// server verdict (CLAUDE.md Article 3.5).
  Future<bool> endSessionIfTokenExpired() async {
    if (_state is! AuthenticatedSession) return false;
    final stored = await _store.read();
    if (stored != null && !stored.isExpiredAt(_now())) return false;
    await handleUnauthenticated();
    return true;
  }

  /// Withdraws this device's push registration, if there is one, before the
  /// token that could withdraw it is discarded.
  ///
  /// **Never blocks the sign-out and never throws.** A resident who asks to sign
  /// out is signed out; a registration that could not be withdrawn is recorded
  /// as still standing rather than reported as gone. The alternative — holding
  /// the local session open until the network answers — punishes the resident
  /// for the server's availability at the exact moment they are trying to leave.
  Future<void> _withdrawPushRegistration() async {
    final withdrawal = _pushRegistration;
    if (withdrawal == null) return;

    final stored = await _store.read();
    final deviceId = stored?.deviceId;
    // Nothing registered by this install: there is nothing to withdraw, and
    // deleting a device this app did not register is not this app's business.
    if (deviceId == null) return;

    // [PushRegistrationWithdrawal] says implementations must not throw, and
    // this catches it anyway. The rule above — a resident who asks to sign out
    // is signed out — is too important to rest on every future implementer
    // having read a doc comment, and the cost of being wrong is that somebody
    // cannot leave a shared phone.
    try {
      lastWithdrawalSucceeded = await withdrawal.withdraw(deviceId);
    } on Object {
      lastWithdrawalSucceeded = false;
    }
  }

  /// Whether the last session-ending withdrawal reached the server.
  ///
  /// Null when no withdrawal has been attempted. False is a fact worth keeping:
  /// it means a registration outlived its session, which is exactly the
  /// condition F27 is about, and something may need to say so.
  bool? lastWithdrawalSucceeded;

  /// Records the registration this install just made, so it can be withdrawn.
  Future<void> rememberDeviceRegistration(String deviceId) async {
    final stored = await _store.read();
    if (stored == null) return;
    await _store.write(stored.withDeviceId(deviceId));
  }

  void _set(SessionState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }
}
