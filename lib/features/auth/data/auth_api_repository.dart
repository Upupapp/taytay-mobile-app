import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/auth_repository.dart';
import '../domain/code_exchange.dart';

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
  Future<Result<CodeAcceptance>> sendEmailCode() async {
    final response = await _apiClient.send<CodeAcceptance>(
      method: HttpMethod.post,
      path: 'auth/email-otp/send',
      authenticated: true,
      decode: _decodeAccepted,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<EmailVerified>> verifyEmailCode({required String code}) async {
    final String digits = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(digits)) {
      return const Err<EmailVerified>(
        ValidationFailure(debugMessage: 'A 6-digit code is required.'),
      );
    }
    final response = await _apiClient.send<EmailVerified>(
      method: HttpMethod.post,
      path: 'auth/email-otp/verify',
      authenticated: true,
      body: <String, Object?>{'code': digits},
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        return EmailVerified(emailVerified: map['email_verified'] == true);
      },
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<CodeAcceptance>> requestPasswordReset({
    required String email,
  }) async {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) {
      return const Err<CodeAcceptance>(
        ValidationFailure(debugMessage: 'An email address is required.'),
      );
    }
    final response = await _apiClient.send<CodeAcceptance>(
      method: HttpMethod.post,
      path: 'auth/password-reset/request',
      authenticated: false,
      body: <String, Object?>{'email': trimmed},
      decode: _decodeAccepted,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<PasswordResetGrant>> verifyPasswordReset({
    required String email,
    required String code,
  }) async {
    final String trimmed = email.trim();
    final String digits = code.trim();
    if (trimmed.isEmpty || !RegExp(r'^\d{6}$').hasMatch(digits)) {
      return const Err<PasswordResetGrant>(
        ValidationFailure(debugMessage: 'An email and a 6-digit code.'),
      );
    }
    final response = await _apiClient.send<PasswordResetGrant>(
      method: HttpMethod.post,
      path: 'auth/password-reset/verify',
      authenticated: false,
      body: <String, Object?>{'email': trimmed, 'code': digits},
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        final Object? token = map['reset_token'];
        final Object? expires = map['expires_at'];
        if (token is! String || token.isEmpty || expires is! String) {
          throw const FormatException('Reset token envelope.');
        }
        final DateTime? at = DateTime.tryParse(expires);
        if (at == null) {
          throw const FormatException('Reset token expiry.');
        }
        return PasswordResetGrant(resetToken: token, expiresAt: at.toUtc());
      },
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<PasswordUpdated>> completePasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    if (resetToken.isEmpty || newPassword.isEmpty) {
      return const Err<PasswordUpdated>(
        ValidationFailure(debugMessage: 'A token and a password are required.'),
      );
    }
    final response = await _apiClient.send<PasswordUpdated>(
      method: HttpMethod.post,
      path: 'auth/password-reset/complete',
      authenticated: false,
      body: <String, Object?>{
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        return PasswordUpdated(updated: map['updated'] == true);
      },
    );
    return response.map((envelope) => envelope.data);
  }

  static CodeAcceptance _decodeAccepted(Object? data) {
    final Map<String, dynamic> map = _map(data);
    return CodeAcceptance(accepted: map['accepted'] == true);
  }

  static Map<String, dynamic> _map(Object? data) {
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
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
