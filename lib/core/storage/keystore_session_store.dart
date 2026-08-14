import 'dart:convert';

import '../session/access_level.dart';
import '../session/session_state.dart';
import '../session/session_store.dart';
import 'secure_secret_store.dart';

/// [SessionStore] backed by the platform keystore.
///
/// This is the implementation TAB 01 deliberately deferred: the contract was
/// defined then, and `InMemorySessionStore` shipped as the safe default until
/// there was a real token to hold. It stores exactly two values:
///
/// * the **access token**, which is credential material;
/// * a **minimal resident summary** — account id, access level, greeting name.
///
/// Data minimisation (CLAUDE.md Article 5.1) is enforced by the shape of what is
/// written, not by a convention: [ResidentSession] carries only those three
/// fields, so there is nothing else to persist. Demographics, addresses, PhilSys
/// fragments and household links are fetched by the screen that displays them
/// and are never written here.
///
/// **Corrupt or partial state reads as "no session".** If the token is present
/// but the summary is not — an interrupted write, a restore that dropped one
/// entry — [read] returns `null` and clears both. Resuming half a session is how
/// an app ends up authenticated with an unknown access level.
class KeystoreSessionStore implements SessionStore {
  KeystoreSessionStore({required SecretStore secrets}) : _secrets = secrets;

  final SecretStore _secrets;

  @override
  Future<StoredSession?> read() async {
    final token = await _secrets.read(SecretKeys.accessToken);
    final rawResident = await _secrets.read(SecretKeys.residentSummary);

    if (token == null || token.isEmpty || rawResident == null) {
      // Partial state is not a session. Clear so the next launch is clean.
      if (token != null || rawResident != null) await clear();
      return null;
    }

    final resident = _decodeResident(rawResident);
    if (resident == null) {
      await clear();
      return null;
    }

    return StoredSession(resident: resident, accessToken: token);
  }

  @override
  Future<void> write(StoredSession session) async {
    // Token last: if the process dies between writes, the next read finds a
    // summary with no token, treats it as no session, and clears. The reverse
    // order would leave a live token with no idea whose it is.
    await _secrets.write(
      SecretKeys.residentSummary,
      _encodeResident(session.resident),
    );
    await _secrets.write(SecretKeys.accessToken, session.accessToken);
  }

  @override
  Future<void> clear() async {
    // Token first: the credential goes before the label. If clearing is
    // interrupted, what survives is a summary that cannot authenticate
    // anything, not a token nobody will clean up.
    await _secrets.delete(SecretKeys.accessToken);
    await _secrets.delete(SecretKeys.residentSummary);
  }

  static String _encodeResident(ResidentSession resident) =>
      jsonEncode(<String, Object?>{
        'account_id': resident.accountId,
        // Persisted as the server's own tier vocabulary rather than as this
        // build's enum index, so an app update that reorders the enum cannot
        // silently promote a stored session.
        'verification_tier': resident.accessLevel == AccessLevel.verified
            ? 'verified'
            : 'unverified',
        'display_name': resident.displayName,
      });

  static ResidentSession? _decodeResident(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final accountId = decoded['account_id'];
      if (accountId is! String || accountId.isEmpty) return null;

      final displayName = decoded['display_name'];
      final tier = decoded['verification_tier'];

      return ResidentSession(
        accountId: accountId,
        // Fails closed: anything that is not exactly 'verified' restores as
        // unverified, and the first authenticated call re-establishes the truth.
        accessLevel: AccessLevel.fromVerificationTier(
          tier is String ? tier : null,
        ),
        displayName: displayName is String && displayName.isNotEmpty
            ? displayName
            : null,
      );
    } on FormatException {
      return null;
    }
  }
}
