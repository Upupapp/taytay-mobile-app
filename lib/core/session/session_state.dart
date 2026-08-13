import 'package:flutter/foundation.dart';

import 'access_level.dart';

/// The minimum a signed-in resident's session carries in memory.
///
/// Data minimisation (CLAUDE.md Article 5): this holds an opaque account id, a
/// greeting name and the server's verification tier — nothing else. Birth dates,
/// addresses, PhilSys numbers and household links are fetched by the screen that
/// actually displays them and are never cached in the session object, because a
/// session object ends up in logs, crash reports and hot-reload state.
@immutable
class ResidentSession {
  const ResidentSession({
    required this.accountId,
    required this.accessLevel,
    this.displayName,
  });

  /// Server-issued UUID for the account. Not a government identifier.
  final String accountId;

  /// Verification tier as resolved by the server, mapped to a level.
  final AccessLevel accessLevel;

  /// First name or preferred name, for greetings only. Optional.
  final String? displayName;

  ResidentSession copyWith({AccessLevel? accessLevel, String? displayName}) =>
      ResidentSession(
        accountId: accountId,
        accessLevel: accessLevel ?? this.accessLevel,
        displayName: displayName ?? this.displayName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResidentSession &&
          other.accountId == accountId &&
          other.accessLevel == accessLevel &&
          other.displayName == displayName);

  @override
  int get hashCode => Object.hash(accountId, accessLevel, displayName);

  /// Redacted: an account id is a pseudonymous identifier and the display name
  /// is personal data. Neither belongs in a log line.
  @override
  String toString() => 'ResidentSession(accessLevel: ${accessLevel.name})';
}

/// The app's session, as a closed set of states.
///
/// Modelled as a sealed hierarchy rather than a nullable user plus a loading
/// flag, so that "still restoring" can never be confused with "signed out". That
/// distinction matters: treating restore-in-progress as signed out redirects a
/// returning resident to the sign-in screen on every cold start.
@immutable
sealed class SessionState {
  const SessionState();

  /// Access level implied by this state. Restoring is treated as
  /// [AccessLevel.guest] for gating purposes, but routing must check
  /// [isResolved] first.
  AccessLevel get accessLevel => switch (this) {
    SessionRestoring() => AccessLevel.guest,
    GuestSession() => AccessLevel.guest,
    AuthenticatedSession(:final resident) => resident.accessLevel,
  };

  /// False only while the stored session is still being read.
  bool get isResolved => this is! SessionRestoring;

  ResidentSession? get residentOrNull => switch (this) {
    AuthenticatedSession(:final resident) => resident,
    _ => null,
  };
}

/// Startup state: the persisted session is being restored. Nothing is known yet.
final class SessionRestoring extends SessionState {
  const SessionRestoring();

  @override
  String toString() => 'SessionRestoring()';
}

/// Nobody is signed in.
///
/// [endedReason] explains *why* when the app moved here from an authenticated
/// state, so the sign-in screen can say "your session expired" instead of
/// silently appearing.
final class GuestSession extends SessionState {
  const GuestSession({this.endedReason = SessionEndedReason.none});

  final SessionEndedReason endedReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuestSession && other.endedReason == endedReason);

  @override
  int get hashCode => endedReason.hashCode;

  @override
  String toString() => 'GuestSession(${endedReason.name})';
}

/// A resident is signed in, at [ResidentSession.accessLevel].
final class AuthenticatedSession extends SessionState {
  const AuthenticatedSession(this.resident);

  final ResidentSession resident;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthenticatedSession && other.resident == resident);

  @override
  int get hashCode => resident.hashCode;

  @override
  String toString() => 'AuthenticatedSession(${resident.accessLevel.name})';
}

/// Why a session ended — drives the message shown on the sign-in screen.
enum SessionEndedReason {
  /// Never signed in during this install, or a normal cold start.
  none,

  /// The resident chose to sign out.
  signedOut,

  /// The server answered `401 UNAUTHENTICATED`.
  expired,
}
