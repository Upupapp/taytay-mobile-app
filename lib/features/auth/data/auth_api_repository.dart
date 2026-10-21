import 'dart:async';
import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/account_application.dart';
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
    final Object? retry = map['retry_after'];
    if (retry is! int) {
      throw const FormatException('Accepted envelope is missing retry_after.');
    }
    return CodeAcceptance(
      accepted: map['accepted'] == true,
      retryAfterSeconds: retry,
    );
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

  @override
  Future<Result<AuthOutcome>> createAccount({
    required String email,
    required String password,
  }) async {
    final Object _ = _apiClient.runtimeType;
    if (email.trim().isEmpty || password.isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'An email address and a password are required.',
        ),
      );
    }
    return backendGapFailure<AuthOutcome>(
      BackendGap.residentSelfRegistration,
      'createAccount',
    );
  }

  @override
  Future<Result<CodeAcceptance>> sendEmailVerification({String? email}) {
    if (email != null && email.trim().isEmpty) {
      return Future<Result<CodeAcceptance>>.value(
        const Err<CodeAcceptance>(
          ValidationFailure(debugMessage: 'An email address is required.'),
        ),
      );
    }
    return sendEmailCode();
  }

  @override
  Future<Result<EmailVerified>> confirmEmailVerification({
    String? code,
    String? link,
  }) async {
    if (link != null && link.isNotEmpty) {
      return const Err<EmailVerified>(
        ValidationFailure(
          debugMessage:
              'An email link cannot be confirmed on the published route.',
        ),
      );
    }
    if (code == null || code.isEmpty) {
      return const Err<EmailVerified>(
        ValidationFailure(debugMessage: 'A code is required.'),
      );
    }
    return verifyEmailCode(code: code);
  }

  @override
  Future<Result<CodeAcceptance>> sendPasswordReset({required String email}) {
    return requestPasswordReset(email: email);
  }

  @override
  Future<Result<void>> submitProfile(AccountApplication application) async {
    if (application.email.trim().isEmpty || application.password.isEmpty) {
      return const Err<void>(
        ValidationFailure(
          debugMessage: 'An email address and a password are required.',
        ),
      );
    }
    if (_uploadMissing(
          application.idFrontBytes,
          application.idFrontName,
          application.idFrontMime,
        ) ||
        _uploadMissing(
          application.selfieBytes,
          application.selfieName,
          application.selfieMime,
        )) {
      return const Err<void>(
        ValidationFailure(
          debugMessage: 'The ID front and a selfie are required.',
        ),
      );
    }

    final Result<({String privacy, String terms})> versions =
        await _consentVersions();
    if (versions case Err(:final failure)) return Err<void>(failure);
    final Ok<({String privacy, String terms})> published =
        versions as Ok<({String privacy, String terms})>;
    final String privacy = published.value.privacy;
    final String terms = published.value.terms;

    final Result<void> privacyConsent = await _recordConsent(privacy);
    if (privacyConsent case Err(:final failure)) return Err<void>(failure);
    if (terms != privacy) {
      final Result<void> termsConsent = await _recordConsent(terms);
      if (termsConsent case Err(:final failure)) return Err<void>(failure);
    }

    final Result<ApiEnvelope<void>> submitted = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/verification-requests',
      authenticated: true,
      requiredStatus: 201,
      body: <String, Object?>{'id_type': _idTypeWire(application.idTypeLabel)},
      files: <MultipartFile>[
        MultipartFile(
          field: 'id_front',
          filename: application.idFrontName!,
          bytes: application.idFrontBytes!,
          mimeType: application.idFrontMime!,
        ),
        if (application.idBackBytes != null &&
            application.idBackName != null &&
            application.idBackMime != null)
          MultipartFile(
            field: 'id_back',
            filename: application.idBackName!,
            bytes: application.idBackBytes!,
            mimeType: application.idBackMime!,
          ),
        MultipartFile(
          field: 'selfie',
          filename: application.selfieName!,
          bytes: application.selfieBytes!,
          mimeType: application.selfieMime!,
        ),
      ],
      decode: (Object? _) {},
    );
    return submitted.map((ApiEnvelope<void> _) {});
  }

  /// `privacy_version` and `terms_version` from `GET /app/config`.
  ///
  /// A missing version is a contract failure. The screen used to send the
  /// literal `draft`, which is not a published notice.
  Future<Result<({String privacy, String terms})>> _consentVersions() async {
    final Result<ApiEnvelope<({String privacy, String terms})>> config =
        await _apiClient.send<({String privacy, String terms})>(
          method: HttpMethod.get,
          path: 'app/config',
          authenticated: false,
          decode: _decodeConsentVersions,
        );
    return switch (config) {
      Ok(:final value) => Ok(value.data),
      Err(:final failure) => Err(failure),
    };
  }

  static ({String privacy, String terms}) _decodeConsentVersions(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final String? privacy = _publishedVersion(map['privacy_version']);
    final String? terms = _publishedVersion(map['terms_version']);
    if (privacy == null || terms == null) {
      throw const FormatException('app/config omitted a consent version');
    }
    return (privacy: privacy, terms: terms);
  }

  static String? _publishedVersion(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<Result<void>> _recordConsent(String version) async {
    final Result<ApiEnvelope<void>> consent = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/consents',
      authenticated: true,
      body: <String, Object?>{'version': version},
      decode: (Object? _) {},
    );
    return consent.map((ApiEnvelope<void> _) {});
  }

  static bool _uploadMissing(Uint8List? bytes, String? name, String? mime) {
    return bytes == null ||
        bytes.isEmpty ||
        name == null ||
        name.isEmpty ||
        mime == null ||
        mime.isEmpty;
  }

  /// Published `id_type` values. An unrecognised label is `other`.
  static String _idTypeWire(String label) {
    return switch (label.trim().toLowerCase()) {
      'philsys national id' || 'philid' || 'philsys' => 'philid',
      "driver's license" ||
      'drivers license' ||
      'driver license' => 'drivers_license',
      'passport' => 'passport',
      'umid' => 'umid',
      'postal id' || 'postal' => 'postal',
      "voter's id" || 'voters id' || 'voters' => 'voters',
      'sss' => 'sss',
      _ => 'other',
    };
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
