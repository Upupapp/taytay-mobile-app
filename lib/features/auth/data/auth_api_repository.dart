import 'dart:async';
import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/account_application.dart';
import '../domain/auth_repository.dart';
import '../domain/code_exchange.dart';
import '../domain/sign_in_challenge.dart';
import 'firebase_identity.dart';

/// Firebase owns sign-in and registration. The API sees the ID token.
///
/// Email and password, and phone codes when that provider is enabled, stay
/// on the Firebase SDK. The first authenticated `GET /me` creates the citizen
/// record and is what this repository reads for the session. Password reset
/// and the signed-in email code remain HTTP routes on the contract. Password
/// change is Firebase reauthentication followed by `updatePassword`, in the
/// account feature, not a request from here.
class AuthApiRepository implements AuthRepository {
  const AuthApiRepository({
    required ApiClient apiClient,
    required FirebaseIdentity identity,
    Telemetry? telemetry,
  }) : _apiClient = apiClient,
       _identity = identity,
       _telemetry = telemetry;

  final ApiClient _apiClient;
  final FirebaseIdentity _identity;

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
    if (mobileNumber.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'A mobile number is required.'),
      );
    }
    return _identity.sendPhoneCode(phoneNumber: mobileNumber);
  }

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async {
    if (mobileNumber.trim().isEmpty || code.trim().isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'A code and a mobile number are required.',
        ),
      );
    }
    final Result<FirebaseCredentialSession> signed = await _identity
        .confirmPhoneCode(code: code);
    return switch (signed) {
      Ok(:final value) => _openSession(value),
      Err(:final failure) => Err<AuthOutcome>(failure),
    };
  }

  @override
  Future<Result<AuthOutcome>> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    final String trimmed = identifier.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'An identifier and a password are required.',
        ),
      );
    }
    if (!trimmed.contains('@')) {
      // Firebase password sign-in is an email. A mobile number uses a phone
      // code. Nothing is sent, and the refusal is not a wrong password.
      return const Err<AuthOutcome>(
        ValidationFailure(
          fieldErrors: <String, List<String>>{
            'identifier': <String>[passwordSignInNeedsEmail],
          },
          debugMessage: 'Password sign-in uses an email address.',
        ),
      );
    }
    final Result<FirebaseCredentialSession> signed = await _identity
        .signInWithEmailAndPassword(email: trimmed, password: password);
    return switch (signed) {
      Ok(:final value) => _openSession(value),
      Err(:final failure) => Err<AuthOutcome>(failure),
    };
  }

  /// `GET /me` with the ID token. The first authenticated call creates the row.
  Future<Result<AuthOutcome>> _openSession(
    FirebaseCredentialSession signed,
  ) async {
    final Result<ApiEnvelope<ResidentSession>> me = await _apiClient
        .send<ResidentSession>(
          method: HttpMethod.get,
          path: 'me',
          authenticated: true,
          bearerOverride: signed.idToken,
          decode: _decodeMe,
        );
    return switch (me) {
      Ok(:final value) => _accepted(
        AuthOutcome(resident: value.data, accessToken: signed.idToken),
      ),
      Err(:final failure) => Err<AuthOutcome>(failure),
    };
  }

  Future<Result<AuthOutcome>> _accepted(AuthOutcome outcome) async {
    unawaited(
      _telemetry?.record(
            const FlowStep(
              flow: TelemetryFlow.signIn,
              stage: TelemetryStage.completed,
            ),
          ) ??
          Future<bool>.value(false),
    );
    return Ok<AuthOutcome>(outcome);
  }

  static ResidentSession _decodeMe(Object? data) {
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final Object? id = map['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Profile omitted id.');
    }
    final Object? tier = map['verification_status'];
    final Object? name = map['name'];
    return ResidentSession(
      accountId: id,
      accessLevel: AccessLevel.fromVerificationTier(
        tier is String ? tier : null,
      ),
      displayName: _greeting(name),
    );
  }

  /// First word of the published name, for the greeting only.
  static String? _greeting(Object? name) {
    if (name is! String) return null;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final int space = trimmed.indexOf(' ');
    return space < 0 ? trimmed : trimmed.substring(0, space);
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
    if (email.trim().isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(debugMessage: 'An email address is required.'),
      );
    }
    return const Err<AuthOutcome>(
      ValidationFailure(
        debugMessage: 'Registration uses an email and a password.',
      ),
    );
  }

  @override
  Future<Result<AuthOutcome>> createAccount({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const Err<AuthOutcome>(
        ValidationFailure(
          debugMessage: 'An email address and a password are required.',
        ),
      );
    }
    final Result<FirebaseCredentialSession> created = await _identity
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    return switch (created) {
      Ok(:final value) => _openSession(value),
      Err(:final failure) => Err<AuthOutcome>(failure),
    };
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

    final Result<ApiEnvelope<void>> submitted = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/verification-requests',
      authenticated: true,
      requiredStatus: 201,
      // The key goes in the multipart body: this API reads no
      // `Idempotency-Key` header (backend `0ff7682`, D-213).
      body: <String, Object?>{
        'id_type': _idTypeWire(application.idTypeLabel),
        'idempotency_key': ?_key(application.idempotencyKey),
      },
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

  @override
  Future<Result<SavedProfile>> saveRegistrationProfile(
    RegistrationProfile profile,
  ) async {
    final String name = profile.fullName;
    final String email = profile.email.trim();
    final String mobile = profile.mobile.replaceAll(' ', '');
    final String barangayId = profile.barangayId.trim();
    if (name.isEmpty || email.isEmpty || mobile.isEmpty || barangayId.isEmpty) {
      return const Err<SavedProfile>(
        ValidationFailure(
          debugMessage: 'A name, email, mobile and barangay are required.',
        ),
      );
    }
    final String street = profile.street.trim();
    final response = await _apiClient.send<SavedProfile>(
      method: HttpMethod.patch,
      path: 'me',
      authenticated: true,
      // ProfilePatch is strict: an undeclared key is a 422. These five are
      // the ones it declares that the wizard collects. `null` clears a street
      // the resident emptied on the way back through the wizard.
      body: <String, Object?>{
        'name': name,
        'mobile': mobile,
        'email': email,
        'barangay_id': barangayId,
        'street': street.isEmpty ? null : street,
      },
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        return SavedProfile(emailVerified: map['email_verified'] == true);
      },
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<void>> recordConsents() async {
    final Result<({String privacy, String terms})> versions =
        await _consentVersions();
    if (versions case Err(:final failure)) return Err<void>(failure);
    final Ok<({String privacy, String terms})> published =
        versions as Ok<({String privacy, String terms})>;
    final String privacy = published.value.privacy;
    final String terms = published.value.terms;

    // Two acts, each with its kind, even when the two version strings are
    // equal: the server keeps one row per text (backend `6c82f32`, D-208). A
    // consent sent without a kind is recorded as `unspecified` and counts as
    // neither text.
    final Result<void> privacyConsent = await _recordConsent(
      privacy,
      kind: 'privacy',
    );
    if (privacyConsent case Err(:final failure)) return Err<void>(failure);
    final Result<void> termsConsent = await _recordConsent(
      terms,
      kind: 'terms',
    );
    if (termsConsent case Err(:final failure)) return Err<void>(failure);
    return const Ok<void>(null);
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

  Future<Result<void>> _recordConsent(
    String version, {
    required String kind,
  }) async {
    final Result<ApiEnvelope<void>> consent = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/consents',
      authenticated: true,
      body: <String, Object?>{'version': version, 'kind': kind},
      decode: (Object? _) {},
    );
    return consent.map((ApiEnvelope<void> _) {});
  }

  static String? _key(String? key) {
    final String trimmed = key?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
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
    try {
      await _identity.signOut();
    } on Object {
      // Local sign-out still proceeds. A missing Firebase app has nothing to end.
    }
    return const Ok<void>(null);
  }
}
