import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';

/// The [AuthRepository] this build ships with: it declines, honestly.
///
/// The backend's `Identity` module (accounts, sessions, tokens) is still
/// planned, so there is no endpoint to call. The two alternatives were both
/// worse:
///
/// * a mock that hands out a session — which would put a fake "signed in" state
///   in front of residents and testers and quietly become the thing people
///   demo; and
/// * omitting the repository — which would leave the sign-in screen, the session
///   controller and the router untested against a real failure path.
///
/// Declining with a temporary [ServerFailure] exercises the whole error seam and
/// tells the truth: the service is not available yet.
class PendingBackendAuthRepository implements AuthRepository {
  const PendingBackendAuthRepository();

  static const String _reason =
      'Identity endpoints are not available in this build.';

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async =>
      const Err<void>(ServerFailure(isTemporary: true, debugMessage: _reason));

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async => const Err<AuthOutcome>(
    ServerFailure(isTemporary: true, debugMessage: _reason),
  );

  /// Succeeds: local sign-out must never be blocked by the network, and there is
  /// no server session to revoke in this build.
  @override
  Future<Result<void>> signOut() async => const Ok<void>(null);
}
