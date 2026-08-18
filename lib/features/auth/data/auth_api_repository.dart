import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
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
  const AuthApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'auth/otp',
      authenticated: false,
      body: <String, Object?>{'mobile_number': mobileNumber},
      // A dropped connection on a Philippine mobile network is ordinary, and a
      // blind repeat would send a second SMS and invalidate the first code —
      // leaving a resident holding the one that no longer works. The key makes
      // the repeat safe.
      //
      // It does NOT make a `429` repeatable: `RetryPolicy` refuses to retry a
      // throttled write, because rate limiting on this endpoint is a security
      // control and spending a resident's allowance inside the transport is
      // both invisible to them and the thing the throttle exists to stop.
      idempotencyKey: _idempotencyKeyFor(mobileNumber),
      decode: (_) {},
    );

    return response.map((_) {});
  }

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async {
    final tokenResult = await _apiClient.send<_IssuedToken>(
      method: HttpMethod.post,
      path: 'auth/otp/verify',
      authenticated: false,
      body: <String, Object?>{'mobile_number': mobileNumber, 'code': code},
      decode: _IssuedToken.decode,
    );

    switch (tokenResult) {
      case Err<ApiEnvelope<_IssuedToken>>(:final failure):
        return Err<AuthOutcome>(failure);
      case Ok<ApiEnvelope<_IssuedToken>>(:final value):
        final _IssuedToken issued = value.data;
        if (issued.token.isEmpty) {
          return const Err<AuthOutcome>(
            ContractFailure(
              debugMessage: 'auth/otp/verify answered without a token.',
            ),
          );
        }
        return _establishSession(issued);
    }
  }

  /// Asks the server who this is, then what they may do.
  ///
  /// Two reads because the answer lives in two modules. `GET me` is `Identity`
  /// and carries the account — its id, its display name, whether the mobile is
  /// verified, and the `resident_id` it may act for. It carries **no
  /// verification tier**; that is `ResidentProfile`'s, on `GET me/profile`.
  ///
  /// The Master Command says the tier comes from `GET me`. It does not, at this
  /// baseline — raised as F21. Reading it here is a deliberate, single-field
  /// crossing into TAB 04's endpoint, because without it no resident could ever
  /// reach the Verified state and TAB 02's own definition of done would be
  /// unmeetable.
  Future<Result<AuthOutcome>> _establishSession(_IssuedToken issued) async {
    final accountResult = await _apiClient.send<_Account>(
      method: HttpMethod.get,
      path: 'me',
      authenticated: true,
      bearerOverride: issued.token,
      decode: _Account.decode,
    );

    switch (accountResult) {
      case Err<ApiEnvelope<_Account>>(:final failure):
        // The token is real but we cannot say what it may do. Refusing is the
        // fail-closed answer: a session at a level nobody checked is exactly
        // what Article 3.6 forbids.
        return Err<AuthOutcome>(failure);
      case Ok<ApiEnvelope<_Account>>(:final value):
        final _Account account = value.data;

        final AccessLevel level = await _resolveAccessLevel(
          account: account,
          token: issued.token,
        );

        return Ok<AuthOutcome>(
          AuthOutcome(
            resident: ResidentSession(
              accountId: account.id,
              accessLevel: level,
              displayName: account.displayName,
            ),
            accessToken: issued.token,
            expiresAt: issued.expiresAt,
            requiresContactVerification: !account.mobileVerified,
          ),
        );
    }
  }

  /// Unverified unless the server says otherwise, on every path out.
  ///
  /// An account with no resident link has no civil record behind it, so there is
  /// no tier to read and nothing to ask for. A profile read that fails —
  /// because the link is new, because the connection dropped — leaves the
  /// resident authenticated and unverified, which costs them one screen. The
  /// opposite mistake grants the digital ID to somebody the LGU has not
  /// verified.
  Future<AccessLevel> _resolveAccessLevel({
    required _Account account,
    required String token,
  }) async {
    if (!account.isLinkedToResident) return AccessLevel.unverified;

    final tierResult = await _apiClient.send<String?>(
      method: HttpMethod.get,
      path: 'me/profile',
      authenticated: true,
      bearerOverride: token,
      decode: (Object? data) => data is Map<String, dynamic>
          ? data['verification_tier'] as String?
          : null,
    );

    return switch (tierResult) {
      Ok<ApiEnvelope<String?>>(:final value) =>
        AccessLevel.fromVerificationTier(value.data),
      Err<ApiEnvelope<String?>>() => AccessLevel.unverified,
    };
  }

  /// Ends the server session, and never blocks the local one.
  ///
  /// The stub this replaces succeeded unconditionally, and that behaviour is
  /// preserved on purpose: a resident on a borrowed phone with no signal must
  /// still be able to sign out. The caller clears local state regardless of what
  /// comes back from here.
  @override
  Future<Result<void>> signOut() async {
    await _apiClient.send<void>(
      method: HttpMethod.delete,
      path: 'auth/tokens/current',
      authenticated: true,
      decode: (_) {},
    );
    return const Ok<void>(null);
  }

  /// Stable for one number, so a repeat of the same request is recognised as
  /// the same request. Derived rather than random because a random key on a
  /// retry is a new request, which is the failure the key exists to prevent.
  ///
  /// The number is hashed, not carried: an `Idempotency-Key` travels in a header
  /// that is logged by proxies and load balancers, and a mobile number in a
  /// header is a mobile number in somebody's access log.
  static String _idempotencyKeyFor(String mobileNumber) {
    var hash = 0x811c9dc5;
    for (final int unit in mobileNumber.codeUnits) {
      hash = (hash ^ unit) * 0x01000193 & 0xFFFFFFFF;
    }
    return 'otp-${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

/// `{token, token_type, expires_at}` from `auth/otp/verify`.
class _IssuedToken {
  const _IssuedToken({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;

  static _IssuedToken decode(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? token = map['token'];
    return _IssuedToken(
      token: token is String ? token : '',
      expiresAt: DateTime.tryParse(
        map['expires_at'] is String ? map['expires_at'] as String : '',
      )?.toUtc(),
    );
  }

  /// Redacted: this holds bearer credential material (Article 5.2).
  @override
  String toString() => '_IssuedToken(expiresAt: $expiresAt)';
}

/// The parts of `GET me` this app is allowed to care about.
///
/// Not the whole payload. `email`, `mobile_number`, `permissions` and `roles`
/// are all in the response and none of them has a property here: a permission
/// list mirrored into a client is an authority-shaped value one refactor away
/// from being branched on, and a mobile number in the session object is
/// personal data outliving the screen that needed it (Article 5.1).
class _Account {
  const _Account({
    required this.id,
    required this.mobileVerified,
    required this.isLinkedToResident,
    this.displayName,
  });

  final String id;
  final bool mobileVerified;

  /// **Whether** this account is linked to a civil record — never *which* one.
  ///
  /// `GET me` returns a `resident_id` and this app has no use for the value: the
  /// only question sign-in asks is whether there is a tier to go and read. So
  /// the identifier is reduced to a boolean at the edge and never enters the
  /// app, which is Article 5.1 applied to a field it would have been easy to
  /// carry out of habit. A repository holding somebody's resident id is one
  /// refactor away from sending it.
  final bool isLinkedToResident;

  final String? displayName;

  static _Account decode(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? id = map['id'];
    final Object? name = map['display_name'];
    final Object? link = map['resident_id'];
    return _Account(
      id: id is String ? id : '',
      mobileVerified: map['mobile_verified'] == true,
      isLinkedToResident: link is String && link.isNotEmpty,
      displayName: name is String && name.isNotEmpty ? name : null,
    );
  }

  @override
  String toString() => '_Account(linked: \$isLinkedToResident)';
}
