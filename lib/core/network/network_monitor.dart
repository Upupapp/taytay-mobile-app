import 'package:flutter/foundation.dart';

import '../result/app_failure.dart';

/// Whether the app can currently reach Taytay LGU.
enum NetworkStatus {
  /// A request has succeeded, or the server has answered — including with a
  /// refusal. A `403` proves reachability as surely as a `200` does.
  reachable,

  /// A request failed before the server answered.
  unreachable,

  /// Nothing has been attempted yet.
  ///
  /// **Not the same as reachable, and not the same as offline.** At cold start
  /// the app genuinely does not know, and a banner shown on a guess is a banner
  /// residents learn to ignore.
  unknown,
}

/// Tracks whether Taytay LGU is reachable, from what the app has actually
/// observed.
///
/// ---
///
/// ## Why this is not a connectivity plugin
///
/// The obvious implementation reads the radio state — `connectivity_plus` and
/// its equivalents report "wifi", "mobile" or "none". That answers a different
/// question. A phone connected to a captive-portal wifi at a barangay hall, a
/// phone with data enabled and no load balance, and a phone on a connection too
/// weak to complete a handshake all report "connected" and can reach nothing.
/// The reverse also happens: a radio flag arrives late and the app claims to be
/// offline while a request is succeeding.
///
/// So this class answers the question the resident is actually asking — "did
/// that reach the office?" — from the only evidence that settles it: the
/// outcome of a real request.
///
/// | Observation | Verdict | Why |
/// | --- | --- | --- |
/// | Any `Ok` | reachable | The server answered. |
/// | `NetworkFailure` | unreachable | The request never arrived. |
/// | `TimeoutFailure` | unreachable | It may have arrived; it did not come back. |
/// | Any other failure | reachable | A `403`, `404` or `500` is the **server** speaking. |
///
/// That last row is the one worth stating plainly. A screen that showed
/// "you appear to be offline" over a `403` would send a resident to check their
/// data balance over a permission decision, and a resident who does that once
/// stops believing the banner.
///
/// It also avoids a dependency that would need a permissions and data-egress
/// review — the Article 1 rule — to tell the app something it can already
/// observe more accurately.
///
/// ## Timeouts are counted as unreachable, deliberately
///
/// A timed-out mutation may well have been received and acted on. Calling it
/// "unreachable" is a statement about **reachability**, not about whether the
/// work happened; nothing in this app treats it as proof that a submission did
/// not land. The submission surfaces make that distinction themselves, and the
/// idempotency key is what makes the retry safe.
///
/// ## Nothing personal is here
///
/// No URL, no payload, no identifier — only a verdict, a count and two
/// timestamps.
class NetworkMonitor extends ChangeNotifier {
  NetworkMonitor({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  NetworkStatus _status = NetworkStatus.unknown;
  DateTime? _lastReachableAt;
  DateTime? _unreachableSince;
  int _consecutiveFailures = 0;

  NetworkStatus get status => _status;

  /// True only once the app has evidence. `unknown` is not offline.
  bool get isUnreachable => _status == NetworkStatus.unreachable;

  /// When the office was last reached. Drives the "last updated" line.
  DateTime? get lastReachableAt => _lastReachableAt;

  /// When the run of failures started, for copy that says how long.
  DateTime? get unreachableSince => _unreachableSince;

  /// How many requests in a row have failed to arrive.
  ///
  /// Exposed so a surface can hold its nerve — one failed request on a Philippine
  /// mobile connection is ordinary, and a banner that appears on the first one
  /// flashes on every train journey.
  int get consecutiveFailures => _consecutiveFailures;

  /// How many failures in a row before the app says anything.
  ///
  /// Two, not one. A single dropped request is normal on the connections many
  /// residents have; two in a row is a pattern.
  static const int failuresBeforeReporting = 2;

  /// Whether a surface should show the offline banner.
  bool get shouldWarn =>
      _status == NetworkStatus.unreachable &&
      _consecutiveFailures >= failuresBeforeReporting;

  /// Records the outcome of one request.
  ///
  /// [failure] is null when the request succeeded. Any failure the **server**
  /// produced counts as reachable — see the table above.
  void recordOutcome(AppFailure? failure) {
    final reachable = switch (failure) {
      null => true,
      NetworkFailure() => false,
      TimeoutFailure() => false,
      _ => true,
    };
    reachable ? _recordReachable() : _recordUnreachable();
  }

  void _recordReachable() {
    final wasUnreachable = _status != NetworkStatus.reachable;
    _status = NetworkStatus.reachable;
    _lastReachableAt = _clock();
    _unreachableSince = null;
    _consecutiveFailures = 0;
    // Notify on the first success after a gap, and on the first success of the
    // run. Not on every subsequent one: a scrolling feed would rebuild the whole
    // shell per page.
    if (wasUnreachable) notifyListeners();
  }

  void _recordUnreachable() {
    final wasReachable = _status != NetworkStatus.unreachable;
    _status = NetworkStatus.unreachable;
    _unreachableSince ??= _clock();
    _consecutiveFailures++;
    // Notify while the count is still below the threshold too, so a surface
    // watching `consecutiveFailures` sees it cross.
    if (wasReachable || _consecutiveFailures <= failuresBeforeReporting) {
      notifyListeners();
    }
  }

  /// Forgets everything, returning to [NetworkStatus.unknown].
  ///
  /// **Not called on sign-out.** Reachability is a fact about the connection,
  /// not about the resident: clearing it when somebody signs out would hide a
  /// genuine outage from the next person to use the phone, and there is nothing
  /// personal in here to clear.
  void reset() {
    _status = NetworkStatus.unknown;
    _lastReachableAt = null;
    _unreachableSince = null;
    _consecutiveFailures = 0;
    notifyListeners();
  }

  @override
  String toString() =>
      'NetworkMonitor($_status, failures: $_consecutiveFailures)';
}
