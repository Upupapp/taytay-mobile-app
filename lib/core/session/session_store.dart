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
  const StoredSession({required this.resident, required this.accessToken});

  final ResidentSession resident;

  /// Bearer token. Never logged, never rendered, never sent anywhere except the
  /// `Authorization` header of the Taytay API.
  final String accessToken;

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
