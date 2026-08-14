import '../../../core/result/result.dart';
import '../../../core/session/session_state.dart';

/// What a completed authentication yields.
///
/// The [resident] carries the server's verification tier already mapped to an
/// access level — the app never derives it. The [accessToken] goes straight into
/// the session store and is never held anywhere else.
class AuthOutcome {
  const AuthOutcome({
    required this.resident,
    required this.accessToken,
    this.expiresAt,
  });

  final ResidentSession resident;
  final String accessToken;

  /// The server's own `expires_at`, which `POST /api/v1/auth/otp/verify`
  /// returns alongside the token. Null when the server did not say.
  ///
  /// Carried so the app can stop presenting a token it can already see is dead.
  /// It is never treated as permission to *keep* using one: revocation is
  /// server-side and can happen at any moment before this time.
  final DateTime? expiresAt;

  /// Redacted: this object holds bearer credential material.
  @override
  String toString() => 'AuthOutcome(${resident.accessLevel.name})';
}

/// Authentication, expressed in domain terms.
///
/// **Deliberately wire-format-free.** The backend's `Identity` module — which
/// owns accounts, sessions and tokens — is not built yet
/// (`docs/architecture/domain-boundary-map.md` lists it as planned). Inventing
/// request and response schemas now would create a contract the server has never
/// agreed to, and it would be discovered wrong only once both sides were
/// written. The domain contract below is what the *app* needs; mapping it onto
/// real endpoints is the data layer's job, in the TAB that ships alongside the
/// server work.
///
/// The flow modelled here is one-time-code authentication on a mobile number,
/// matching the resident onboarding pattern already proven in the Esperanza
/// resident app. It avoids a resident-chosen password — the credential most
/// often reused across services, and the one an LGU is least able to help
/// recover safely.
abstract interface class AuthRepository {
  /// Asks the server to send a one-time code to [mobileNumber].
  ///
  /// The response never says whether the number is registered: that answer
  /// would let anyone test whether a person is a Taytay resident. Registration
  /// and sign-in must therefore look identical from the outside.
  Future<Result<void>> requestOneTimeCode({required String mobileNumber});

  /// Exchanges a one-time [code] for a session.
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  });

  /// Ends the session server-side so the token cannot be replayed.
  ///
  /// Local sign-out happens regardless of the result — a resident on a borrowed
  /// phone must be able to sign out with no connectivity.
  Future<Result<void>> signOut();
}
