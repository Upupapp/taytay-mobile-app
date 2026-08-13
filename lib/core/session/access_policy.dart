import 'package:flutter/foundation.dart';

import 'access_level.dart';
import 'session_state.dart';

/// The access requirement a destination declares.
///
/// Every route must declare one. A route with no declared requirement is a
/// defect — the client-side echo of the backend's "deny by default" rule
/// (ADR 0002 §6) — so the policy has no implicit default.
enum AccessRequirement {
  /// Reachable by anyone, including a guest: public information, sign-in,
  /// onboarding, the LGU directory.
  public(AccessLevel.guest),

  /// Requires a signed-in account, verified or not: account settings,
  /// verification progress, notifications.
  authenticated(AccessLevel.unverified),

  /// Requires a verified resident: LGU credential, service applications,
  /// anything that acts on the resident's civil record.
  verified(AccessLevel.verified);

  const AccessRequirement(this.minimumLevel);

  final AccessLevel minimumLevel;
}

/// What the app should do with a navigation attempt.
@immutable
sealed class AccessDecision {
  const AccessDecision();
}

/// The destination may be shown.
final class AccessAllowed extends AccessDecision {
  const AccessAllowed();

  @override
  bool operator ==(Object other) => other is AccessAllowed;

  @override
  int get hashCode => (AccessAllowed).hashCode;

  @override
  String toString() => 'AccessAllowed()';
}

/// The session is still being restored; hold on the splash rather than deciding.
final class AccessPending extends AccessDecision {
  const AccessPending();

  @override
  bool operator ==(Object other) => other is AccessPending;

  @override
  int get hashCode => (AccessPending).hashCode;

  @override
  String toString() => 'AccessPending()';
}

/// The resident must sign in first.
final class AccessNeedsAuthentication extends AccessDecision {
  const AccessNeedsAuthentication();

  @override
  bool operator ==(Object other) => other is AccessNeedsAuthentication;

  @override
  int get hashCode => (AccessNeedsAuthentication).hashCode;

  @override
  String toString() => 'AccessNeedsAuthentication()';
}

/// Signed in, but the account is not verified yet.
final class AccessNeedsVerification extends AccessDecision {
  const AccessNeedsVerification();

  @override
  bool operator ==(Object other) => other is AccessNeedsVerification;

  @override
  int get hashCode => (AccessNeedsVerification).hashCode;

  @override
  String toString() => 'AccessNeedsVerification()';
}

/// Decides whether the current session may *see* a destination.
///
/// This is navigation ergonomics, not security. It exists so a resident is sent
/// to the right next step instead of a screen that will fail, and so that
/// deep links into protected areas land somewhere sensible. Whether an operation
/// is permitted is decided by the server on every request; if this policy were
/// deleted the app would be less pleasant and no less safe.
abstract final class AccessPolicy {
  static AccessDecision evaluate({
    required SessionState session,
    required AccessRequirement requirement,
  }) {
    if (requirement == AccessRequirement.public) return const AccessAllowed();
    if (!session.isResolved) return const AccessPending();

    final level = session.accessLevel;
    if (!level.isAuthenticated) return const AccessNeedsAuthentication();
    if (!level.satisfies(requirement.minimumLevel)) {
      return const AccessNeedsVerification();
    }
    return const AccessAllowed();
  }
}
