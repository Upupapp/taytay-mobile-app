import 'package:flutter/foundation.dart';

import 'access_level.dart';
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
  SessionController({required SessionStore store, DateTime Function()? clock})
    : _store = store,
      _now = clock ?? DateTime.now;

  final SessionStore _store;

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

  void _set(SessionState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }
}
