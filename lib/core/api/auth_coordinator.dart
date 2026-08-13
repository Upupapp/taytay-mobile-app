import 'dart:async';

import 'package:flutter/foundation.dart';

/// What happened when the app tried to recover from a `401`.
enum AuthRecovery {
  /// A fresh token was obtained. The caller may replay its request once.
  refreshed,

  /// Recovery is impossible or was refused. The session must end.
  failed,
}

/// Obtains a fresh access token.
///
/// **Deliberately unimplemented in this build.**
///
/// The committed backend contract (`Taytay_Rizal_LGUIDS_Backend@7844859`) has
/// ADR 0005 accepted — first-party Sanctum bearer tokens, with *"short token
/// lifetimes with refresh"* named as a required mitigation — but it publishes
/// **no Identity module and no refresh endpoint**. The committed route surface is
/// `GET /api/v1/health`, `GET /api/v1/services` and
/// `GET /api/v1/admin/services`, and nothing else.
///
/// Inventing a path, request shape or response shape for refresh would create a
/// contract the server has never agreed to, discovered wrong only once both
/// sides were written. So the *mechanism* below is built and tested, and the
/// *call* is left as this seam. With no refresher registered the app fails
/// closed: a `401` ends the session.
abstract interface class TokenRefresher {
  /// Returns the new access token, or `null` when refresh is not possible.
  ///
  /// Must not throw. Must not itself retry on `401` — that is what the
  /// coordinator is for.
  Future<String?> refresh();
}

/// Serialises recovery from `401` so that N concurrent failures cause at most
/// one refresh.
///
/// **Why single-flight matters.** A screen typically issues several requests at
/// once — profile, credential, notifications. When a token expires they all
/// return `401` within milliseconds of each other. Without coordination each one
/// triggers its own refresh: the server sees a burst of refreshes for the same
/// account (which a well-built server will rate-limit or treat as replay), and
/// on a rotating-refresh-token scheme the racing calls invalidate each other and
/// log the resident out despite a valid session.
///
/// So the first `401` performs the refresh; every other caller awaits the *same*
/// future and receives the same verdict.
///
/// **Fail closed.** Any outcome that is not a definite success — no refresher
/// registered, a `null` token, an exception — is [AuthRecovery.failed], and the
/// session ends. There is no path where an uncertain result leaves the app
/// believing it is still authenticated.
class AuthCoordinator {
  AuthCoordinator({TokenRefresher? refresher, this.onSessionInvalidated})
    : _refresher = refresher;

  final TokenRefresher? _refresher;

  /// Called exactly once per invalidation, after recovery has failed.
  final Future<void> Function()? onSessionInvalidated;

  Future<AuthRecovery>? _inFlight;

  /// True while a refresh is running. For tests and diagnostics.
  @visibleForTesting
  bool get isRefreshing => _inFlight != null;

  /// Whether this build can attempt recovery at all.
  bool get canRefresh => _refresher != null;

  /// Handles a `401`.
  ///
  /// Concurrent calls share one attempt. The returned verdict tells the caller
  /// whether replaying its request once is worthwhile.
  Future<AuthRecovery> handleUnauthenticated() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final attempt = _attemptRecovery();
    _inFlight = attempt;
    // Cleared in a `whenComplete` so a failed refresh cannot wedge the
    // coordinator into a permanently "refreshing" state.
    unawaited(attempt.whenComplete(() => _inFlight = null));
    return attempt;
  }

  Future<AuthRecovery> _attemptRecovery() async {
    final refresher = _refresher;

    if (refresher == null) {
      // No refresh exists in this build. This is the fail-closed path, and it
      // is the *only* path today.
      await _invalidate();
      return AuthRecovery.failed;
    }

    String? token;
    try {
      token = await refresher.refresh();
    } on Object {
      // A refresher that throws is a refresher that failed. Never treated as
      // "probably fine".
      token = null;
    }

    if (token == null || token.isEmpty) {
      await _invalidate();
      return AuthRecovery.failed;
    }
    return AuthRecovery.refreshed;
  }

  Future<void> _invalidate() async {
    final callback = onSessionInvalidated;
    if (callback == null) return;
    try {
      await callback();
    } on Object {
      // Invalidation must not itself throw into a request path; the session
      // controller's own idempotency is what guarantees the state is correct.
    }
  }
}
