import '../../../core/session/access_level.dart';

/// Whether the resident may change her barangay from the app, read from the
/// `verification_status` that `GET /me` sent (D-235).
///
/// ---
///
/// **Once verified, the office records where she lives** (backend ADR 0015
/// decision 6, ADR 0016 decision 5). It checks a new address against proof at
/// the counter, and its edit of her registry record reaches the account. So
/// `PATCH /me` refuses a verified account's different `barangay_id` with `409`
/// `BARANGAY_HELD_BY_OFFICE`. An account not yet verified, pending or
/// rejected still sets its own.
///
/// Only [AccessLevel.fromVerificationTier] reads `verified`, as everywhere
/// else (CLAUDE.md Article 3.6). This decides what Edit profile offers; the
/// server decides what is allowed.
abstract final class BarangayLock {
  /// True when the barangay is the office's to change.
  static bool heldByOffice(String? tier) =>
      AccessLevel.fromVerificationTier(tier) == AccessLevel.verified;

  /// The one sentence under a locked barangay on Edit profile.
  static const String heldNote =
      'To change your barangay, visit the MSWDO office with proof of your new '
      'address.';

  /// Said when the server refused a change with `BARANGAY_HELD_BY_OFFICE`:
  /// the screen was drawn before the account was verified. The app's own
  /// words for the code (Article 5.5), the same as the API's.
  static const String refusedTitle = 'Your barangay was not changed';

  static const String refused =
      'Your account is verified, so your barangay is changed at the MSWDO '
      'office. $heldNote';
}
