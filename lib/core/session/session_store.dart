import 'session_state.dart';

/// Persistence seam for the signed-in session.
///
/// **Why this is an interface with no disk-backed implementation in TAB 01.**
/// An access token is bearer credential material for a government identity
/// service. It belongs in the platform keystore (Android Keystore / iOS
/// Keychain), never in `SharedPreferences`, never in a plain file, and never in
/// the app's own database. Writing that implementation before there is a real
/// token to store would mean choosing a storage plugin, and its backup/export
/// behaviour, with nothing to test it against.
///
/// So TAB 01 defines the contract and ships [InMemorySessionStore]: a session
/// that dies with the process. That is the *safe* default — the worst outcome is
/// that a resident signs in again, not that a credential survives on a shared
/// device.
///
/// Implementations must not log, export or copy the values they hold.
abstract interface class SessionStore {
  /// Returns the stored session, or `null` when there is none.
  Future<StoredSession?> read();

  /// Replaces the stored session.
  Future<void> write(StoredSession session);

  /// Removes everything. Must be safe to call when nothing is stored, and must
  /// leave no recoverable trace.
  Future<void> clear();
}

/// What is persisted between launches: the resident's identity summary plus the
/// credential material needed to resume.
class StoredSession {
  const StoredSession({
    required this.resident,
    required this.accessToken,
    this.expiresAt,
    this.deviceId,
  });

  final ResidentSession resident;

  /// Bearer token. Never logged, never rendered, never sent anywhere except the
  /// `Authorization` header of the Taytay API.
  final String accessToken;

  /// When the server said this token stops working, in UTC.
  ///
  /// Taken verbatim from the `expires_at` the committed contract returns
  /// alongside the token (`POST /api/v1/auth/otp/verify`). Null when the server
  /// did not say — an older response, or a build talking to a service that has
  /// not started sending it.
  ///
  /// **This is a courtesy, not an authorization decision.** A token is valid
  /// because the server accepts it, not because this timestamp has not passed;
  /// the server may revoke it at any moment, and a `401` is still the only
  /// verdict that ends a session for certain. What this buys is the *opposite*
  /// direction, which is always safe: when the app can already see the token is
  /// dead, it stops presenting it and asks the resident to sign in, instead of
  /// firing a doomed request and rendering a screen that is about to fail.
  final DateTime? expiresAt;

  /// Whether the token is known to have expired at [now].
  ///
  /// Fails **open toward the server**: an absent [expiresAt] returns false, so
  /// the app keeps using a token whose lifetime it does not know and lets the
  /// server decide. Guessing "probably expired" would sign residents out for a
  /// field the backend has not shipped yet.
  bool isExpiredAt(DateTime now) {
    final deadline = expiresAt;
    if (deadline == null) return false;
    return !now.toUtc().isBefore(deadline.toUtc());
  }

  /// The `me/devices` registration this install made, if it has made one.
  ///
  /// Held here rather than in the notifications feature so that it has **the
  /// same lifetime as the credential that can withdraw it**. A device id that
  /// outlived its token would name a registration the app could no longer
  /// revoke; one that died first would leave a registration nothing knew to
  /// revoke at all — which is F27.
  ///
  /// Null until this install registers. Not a hardware identifier: it is the
  /// server's own opaque handle for a registration this app created.
  final String? deviceId;

  /// A copy carrying [deviceId], for the moment registration returns one.
  StoredSession withDeviceId(String? id) => StoredSession(
    resident: resident,
    accessToken: accessToken,
    expiresAt: expiresAt,
    deviceId: id,
  );

  /// Redacted deliberately — see the class doc.
  @override
  String toString() => 'StoredSession(${resident.accessLevel.name})';
}

/// Process-lifetime session storage.
///
/// The default in every build until a keystore-backed implementation lands, and
/// permanently the implementation used by tests.
class InMemorySessionStore implements SessionStore {
  StoredSession? _session;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<void> write(StoredSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
