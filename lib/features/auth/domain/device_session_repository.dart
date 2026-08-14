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
/// **Nothing implements this against a real endpoint, because none exists.**
/// The committed contract (`Taytay_Rizal_LGUIDS_Backend@75b251d`,
/// `docs/contracts/frontend-endpoint-matrix.md` §2) publishes exactly one
/// session-ending route — `DELETE /api/v1/auth/tokens/current` — which revokes
/// *this* token. There is no route to enumerate an account's other tokens and
/// none to revoke one by id. `POST /api/v1/me/devices` is push-notification
/// registration (§13) and is not a session list; presenting it as one would show
/// residents a screen that lists the devices receiving notifications and calls
/// them sign-ins.
///
/// The contract is declared here anyway, for one reason: the honest failure has
/// to be reachable. With the seam in place the security screen can say "this is
/// not available yet" from a real typed answer, and the day the Identity module
/// ships a route, one data-layer class replaces one line of wiring. Without it,
/// the temptation is a mock list — and a fake device list is worse than no
/// device list, because a resident checking for an intruder would be reassured
/// by fiction.
abstract interface class DeviceSessionRepository {
  /// Every place this account is currently signed in, including this device.
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions();

  /// Ends one of them.
  ///
  /// The server decides whether the actor may revoke the named session; the app
  /// only asks. Revoking the current device is equivalent to signing out.
  Future<Result<void>> revokeSession({required String sessionId});
}
