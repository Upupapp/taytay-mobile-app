/// Withdrawing this device's push registration when a session ends.
///
/// ## Why this interface exists in `core/session` rather than being a call
///
/// `SessionController` is the only place that knows a session is ending, and it
/// is the only place that can withdraw a registration at the right moment —
/// before the token it needs is discarded. But it lives in `core/`, which must
/// not import `features/` (Article 2.3), and the registration is the
/// notifications feature's.
///
/// So the direction is inverted: `core` states what it needs, the feature
/// implements it, and the composition root binds them. One method, because one
/// is what the session boundary actually needs.
///
/// ## What it is for
///
/// F27. A push registration that outlives its session means the next person to
/// hold a shared handset receives the previous resident's municipal
/// notifications — on a lock screen, where they need no password at all. On this
/// user base a handed-on phone is ordinary, not hypothetical.
abstract interface class PushRegistrationWithdrawal {
  /// Withdraws the registration identified by [deviceId].
  ///
  /// **Must not throw and must not block.** A resident asking to sign out is
  /// never held up by a server that will not answer; the caller ends the local
  /// session regardless of what this returns. Implementations report failure by
  /// returning false rather than by raising.
  Future<bool> withdraw(String deviceId);
}
