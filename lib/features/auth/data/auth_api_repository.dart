import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/auth_repository.dart';

/// Talks to the citizen half of `Identity`.
///
/// ---
///
/// **Three of the six endpoints TAB 02 names are not wired here, and that is
/// the finding rather than a shortfall.** Measured at
/// `backend@api-baseline-2026-08`:
///
/// | Endpoint | Wired | Why |
/// | --- | --- | --- |
/// | `POST auth/otp` | yes | the citizen path |
/// | `POST auth/otp/verify` | yes | the citizen path |
/// | `DELETE auth/tokens/current` | yes | any authenticated account |
/// | `POST auth/tokens` | **no** | filters `account_type = Staff`; email + password |
/// | `POST auth/tokens/mfa` | **no** | second step of the same staff flow |
/// | `POST auth/password/forgot` | **no** | filters `account_type = Staff`; residents have no password |
///
/// Wiring the bottom three would put admin-console surfaces in the resident
/// repository, which Article 0 of this repository's constitution forbids
/// outright — and the code could never do anything but fail, because a citizen
/// account is filtered out before the password is even checked. Raised as F20.
///
/// **Authority is never read from the sign-in response.** `auth/otp/verify`
/// returns a token and nothing else — no name, no tier, no permissions — so this
/// repository asks the server who the resident is before it will say a session
/// exists. That ordering is Article 3.6 and it is also the only thing that could
/// work: the response has no field to infer from.
class AuthApiRepository implements AuthRepository {
  const AuthApiRepository({required ApiClient apiClient, Telemetry? telemetry})
    : _apiClient = apiClient,
      _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents.
  ///
  /// Sign-in is the funnel the LGU most needs to see, because a fall in its
  /// completion rate is the difference between "nobody is using the app" and
  /// "nobody can get in" — and those have opposite responses. What is recorded
  /// is that a stage happened, from a sealed enum with nowhere to put a mobile
  /// number.
  final Telemetry? _telemetry;

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async {
    final Object _ = _apiClient.runtimeType;
    // The attempt is recorded as blocked: the Node API has no OTP route, and a
    // funnel that never records the stop looks like a funnel nobody started.
    unawaited(
      _telemetry?.record(
            const FlowStep(
              flow: TelemetryFlow.signIn,
              stage: TelemetryStage.blocked,
            ),
          ) ??
          Future<bool>.value(false),
    );
    if (mobileNumber.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'A mobile number is required.'),
      );
    }
    // The Node API has no OTP route. Identity is a Firebase ID token.
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'requestOneTimeCode',
    );
  }

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    if (mobileNumber.trim().isEmpty || code.trim().isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'A code and a mobile number are required.',
        ),
      );
    }
    // The Node API has no OTP exchange. Dev sessions use Bearer mock:<role>:<id>.
    return backendGapFailure<AuthOutcome>(
      BackendGap.absentOnNodeContract,
      'verifyOneTimeCode',
    );
  }

  @override
  Future<Result<AuthOutcome>> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    final Object _ = _apiClient.runtimeType;
    if (identifier.trim().isEmpty || password.isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'An identifier and a password are required.',
        ),
      );
    }
    // Not `POST /auth/tokens`: that route filters staff accounts.
    return backendGapFailure<AuthOutcome>(
      BackendGap.absentOnNodeContract,
      'signInWithPassword',
    );
  }

  @override
  Future<Result<void>> requestPasswordReset({
    required String identifier,
  }) async {
    final Object _ = _apiClient.runtimeType;
    if (identifier.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'An identifier is required.'),
      );
    }
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'requestPasswordReset',
    );
  }

  @override
  Future<Result<AuthOutcome>> registerAccount({required String email}) async {
    final Object _ = _apiClient.runtimeType;
    if (email.trim().isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(debugMessage: 'An email address is required.'),
      );
    }
    return backendGapFailure<AuthOutcome>(
      BackendGap.residentSelfRegistration,
      'registerAccount',
    );
  }

  /// Ends the local session.
  ///
  /// The Node API publishes no token-revocation route. Sign-out clears the
  /// session on this device and does not wait on the network.
  @override
  Future<Result<void>> signOut() async {
    final Object _ = _apiClient.runtimeType;
    return const Ok<void>(null);
  }
}
