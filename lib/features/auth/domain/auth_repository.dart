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

  /// Email or mobile, plus a password, as `02-01` draws it.
  ///
  /// The live repository declines. The Node contract has no citizen password
  /// route, and the staff token route is not this app's. The dev mock is the
  /// only implementation that returns a session. Nothing here sends a role.
  Future<Result<AuthOutcome>> signInWithPassword({
    required String identifier,
    required String password,
  });

  /// `POST /auth/email-otp/send`. Authenticated. No body. `202`.
  ///
  /// The code goes to the profile email. Registration asks for a code before
  /// an account exists, so a live call can be refused; the screen still
  /// advances and the dev mock accepts the same shape.
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

  /// Creates a resident account and returns an unverified session.
  ///
  /// The live repository declines: there is no citizen registration route.
  /// The dev mock returns an unverified session and does not upload the ID
  /// or the selfie. Those bytes stay on the device until a route exists.
  ///
  /// Prefer [createAccount], which keeps the password with the draft.
  Future<Result<AuthOutcome>> registerAccount({required String email});

  /// Email and password for a new resident account.
  ///
  /// The live client declines with the same gap as [registerAccount]. The
  /// password stays on [AccountApplication] and is not posted to a staff
  /// token route. The dev mock accepts it and returns an unverified session.
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

  /// Names, mobile, barangay, and whether an ID and a selfie were captured.
  ///
  /// The bytes stay on the device. The live client declines: there is no
  /// citizen upload route. The dev mock accepts the draft and stores nothing.
  Future<Result<void>> submitProfile(AccountApplication application);
}
