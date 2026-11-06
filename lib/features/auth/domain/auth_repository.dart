import '../../../core/result/result.dart';
import '../../../core/session/session_state.dart';
import 'account_application.dart';
import 'code_exchange.dart';

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
    this.requiresContactVerification = false,
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

  /// The account's mobile number is not marked verified on the server.
  ///
  /// A successful, expected branch of sign-in rather than a failure — the
  /// resident is authenticated and the session is real; there is simply one more
  /// step before some things will work. Routing to it is right; dead-ending on a
  /// permission error later is not.
  ///
  /// **There is deliberately no `mfaRequired` branch, and that is a measured
  /// fact rather than an omission.** The Master Command asks for one, because
  /// `POST auth/tokens` answers `{"status":"mfa-required"}`. Measured at
  /// `backend@api-baseline-2026-08`, that route filters
  /// `account_type = Staff` and takes an email and a password — it is the admin
  /// console's front door, and a citizen account can never authenticate through
  /// it. `verifySignInCode`, the citizen path, has no MFA branch at all. See
  /// F20 in `docs/integration/backend-baseline.md`.
  final bool requiresContactVerification;

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
  /// Asks Firebase to send a phone code to [mobileNumber], when that
  /// provider is enabled.
  ///
  /// The result never says whether the number is registered: that answer
  /// would let anyone test whether a person is a Taytay resident.
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

  /// Email and password on the Firebase SDK, as the sign-in screen draws it.
  ///
  /// A mobile number is not a Firebase password identifier. The live client
  /// refuses that shape locally. Nothing here sends a role.
  Future<Result<AuthOutcome>> signInWithPassword({
    required String identifier,
    required String password,
  });

  /// `POST /auth/email-otp/send`. Authenticated. No body. `202`.
  ///
  /// The code goes to the profile email, so the server refuses it (`422`)
  /// until [saveRegistrationProfile] has stored one. The wizard creates the
  /// account and saves the profile first, and a refusal keeps the resident on
  /// the account step with a message. It is never skipped.
  Future<Result<CodeAcceptance>> sendEmailCode();

  /// `POST /auth/email-otp/verify` with `{code}`.
  Future<Result<EmailVerified>> verifyEmailCode({required String code});

  /// `POST /auth/password-reset/request` with `{email}`.
  ///
  /// A well-formed email is always accepted, whether or not an account exists.
  Future<Result<CodeAcceptance>> requestPasswordReset({required String email});

  /// `POST /auth/password-reset/verify` with `{email, code}`.
  ///
  /// Returns a reset token that expires after 15 minutes.
  Future<Result<PasswordResetGrant>> verifyPasswordReset({
    required String email,
    required String code,
  });

  /// `POST /auth/password-reset/complete` with `{reset_token, new_password}`.
  Future<Result<PasswordUpdated>> completePasswordReset({
    required String resetToken,
    required String newPassword,
  });

  /// Email-only registration cannot open a Firebase account.
  ///
  /// Prefer [createAccount], which keeps the password with the draft.
  Future<Result<AuthOutcome>> registerAccount({required String email});

  /// Creates the Firebase user, then reads `GET /me` with the ID token.
  ///
  /// The password stays on the device. It is not posted to the API.
  Future<Result<AuthOutcome>> createAccount({
    required String email,
    required String password,
  });

  /// Asks for an email check. A 6-digit code uses [sendEmailCode]. A provider
  /// that sends a link uses this method; the published route is the same send,
  /// because no separate link route exists.
  Future<Result<CodeAcceptance>> sendEmailVerification({String? email});

  /// Confirms either a 6-digit [code] or a verification [link].
  ///
  /// A code uses [verifyEmailCode]. A link has no published exchange, so the
  /// live client declines without calling a staff route.
  Future<Result<EmailVerified>> confirmEmailVerification({
    String? code,
    String? link,
  });

  /// Asks for a password reset. The 6-digit path is [requestPasswordReset].
  /// This name stays for a provider that sends a link instead of a code.
  Future<Result<CodeAcceptance>> sendPasswordReset({required String email});

  /// `PATCH /me` with `name`, `mobile`, `email`, `barangay_id` and `street`.
  ///
  /// Sent once the account exists and before an email code is asked for. Only
  /// fields `ProfilePatch` declares are sent; never a role or an office.
  Future<Result<SavedProfile>> saveRegistrationProfile(
    RegistrationProfile profile,
  );

  /// `GET /app/config` for `privacy_version` and `terms_version`, then
  /// `POST /me/consents` for each (once when they match).
  ///
  /// A missing version is a contract failure. Nothing is sent as `draft`.
  Future<Result<void>> recordConsents();

  /// `POST /me/verification-requests` with the ID type, the front, an
  /// optional back, and the selfie. `201` opens the request for staff review.
  ///
  /// The account, the profile and consent are already on the server by now.
  /// The dev mock accepts the draft and stores nothing.
  Future<Result<void>> submitProfile(AccountApplication application);
}
