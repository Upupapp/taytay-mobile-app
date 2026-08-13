/// What the app may *show* a person, ordered from least to most capable.
///
/// This is a **presentation** concept. The authoritative decision about what a
/// person may *do* is made server-side from the authenticated actor
/// (backend ADR 0002). Every level here exists so the app can route sensibly and
/// explain the next step — not so it can grant anything. A build that hides a
/// button has not implemented access control; it has implemented a hint.
///
/// The three resident states this app supports:
///
/// * [guest] — nobody is signed in. Public information only.
/// * [unverified] — signed in, identity not yet verified by the LGU. Can manage
///   the account and start verification; cannot hold or use an LGU credential.
/// * [verified] — identity verified by the LGU. Full resident services.
///
/// There is no staff or administrator level, by design: this app is the
/// `citizen-mobile` channel and holds no admin surface at all.
enum AccessLevel {
  guest(0),
  unverified(1),
  verified(2);

  const AccessLevel(this.rank);

  /// Ordering used by [satisfies]. Never persisted or sent to the server.
  final int rank;

  bool get isAuthenticated => this != AccessLevel.guest;

  /// Whether this level meets a [required] minimum.
  bool satisfies(AccessLevel required) => rank >= required.rank;

  /// Maps the server's verification tier onto a level for an authenticated
  /// resident.
  ///
  /// Unknown tiers deliberately fall back to [unverified] — the least
  /// capable authenticated state — so that a tier this build has never heard of
  /// can never be read as "more trusted".
  static AccessLevel fromVerificationTier(String? tier) =>
      tier == 'verified' ? AccessLevel.verified : AccessLevel.unverified;
}
