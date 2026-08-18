import '../../../core/result/result.dart';

/// One place a resident's account is currently signed in.
///
/// Deliberately thin. A device list is a security feature, but it is also a
/// movement log: a full record of when and roughly where an account was used.
/// This carries a label the resident can recognise and the time it was last
/// seen — enough to answer "is that me?" — and no IP address, no coordinates,
/// no user agent, and no city. Those turn a safety screen into a surveillance
/// record that the resident's own device is now caching.
class DeviceSessionSummary {
  const DeviceSessionSummary({
    required this.id,
    required this.label,
    required this.isCurrentDevice,
    this.lastSeenAt,
  });

  /// Opaque server-side identifier, used only to ask for revocation.
  final String id;

  /// Something a resident recognises — the device name they chose, e.g.
  /// "Android phone". Never a network identifier.
  final String label;

  /// Whether this is the device the resident is holding.
  final bool isCurrentDevice;

  final DateTime? lastSeenAt;

  /// Redacted: a device label is chosen by the resident and can name a person.
  @override
  String toString() => 'DeviceSessionSummary(current: $isCurrentDevice)';
}

/// Listing and revoking the other places an account is signed in.
///
/// ---
///
/// **Wired at TAB 03 against `me/sessions`, and the day it was written this file
/// said no such route existed.** It was pinned to
/// `Taytay_Rizal_LGUIDS_Backend@75b251d` and an endpoint matrix that has since
/// been superseded; `Identity` has published `GET me/sessions`,
/// `DELETE me/sessions/{session}` and `POST me/sessions/revoke-all` since
/// backend TAB 05.
///
/// **The warning it carried was right and is kept.** `me/devices` is *not* a
/// session list — it is device registration whose purpose is a push token, and
/// presenting it as one would show residents the devices receiving
/// notifications and call them sign-ins. That is why this repository reads
/// `me/sessions` and nothing else, and why device registration waits for
/// TAB 13, where a push token exists and the row means something. Registering a
/// device with no push token now would create a record with no purpose and put
/// a second, different list in front of a resident asking one question: *is
/// somebody else signed in as me?*
abstract interface class DeviceSessionRepository {
  /// Every place this account is currently signed in, including this device.
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions();

  /// Ends one of them.
  ///
  /// The server decides whether the actor may revoke the named session; the app
  /// only asks. Revoking the current device is equivalent to signing out.
  ///
  /// A session that is not this account's answers `404`, never `403` —
  /// deliberately, because confirming that a session id exists but belongs to
  /// somebody else is itself a disclosure.
  Future<Result<void>> revokeSession({required String sessionId});

  /// Ends every session except the one making the request.
  ///
  /// The action a resident wants when they have lost a phone and cannot name
  /// which entry it is. Kept distinct from revoking one, because the two carry
  /// very different consequences and a screen must be able to confirm them
  /// differently.
  Future<Result<void>> revokeAllOtherSessions();
}
