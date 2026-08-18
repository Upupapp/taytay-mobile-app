import '../../../core/api/backend_gap.dart';
import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/auth_repository.dart';

/// The [AuthRepository] this build ships with: it declines, honestly.
///
/// **The premise here was wrong, and it cost the app its front door.** This
/// file said `Identity` was still planned. `Identity` has been implemented since
/// backend TAB 05 and serves `auth/otp`, `auth/otp/verify`, `auth/tokens` and
/// `auth/tokens/mfa` today — so this build shipped guest-only, and every
/// authenticated and verified feature behind it was unreachable, against a
/// server that was answering the whole time. Wiring it is TAB 02.
///
/// One method is blocked for a second and unrelated reason: an issued sign-in
/// code is never dispatched on any channel (`F16`), so `requestOneTimeCode` has
/// a route and still cannot finish the job it exists for. That is a backend
/// change with a named owner, not wiring, and TAB 02's definition of done
/// depends on it.
///
/// Declining meanwhile remains right. The two alternatives were both worse:
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

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async => backendGapFailure<void>(
    BackendGap.signInCodeDelivery,
    'requestOneTimeCode',
  );

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async => unwiredRepositoryFailure<AuthOutcome>(
    UnwiredRepository.auth,
    'verifyOneTimeCode',
  );

  /// Succeeds: local sign-out must never be blocked by the network, and there is
  /// no server session to revoke in this build.
  @override
  Future<Result<void>> signOut() async => const Ok<void>(null);
}
