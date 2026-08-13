import 'package:flutter/foundation.dart';

import '../router/app_routes.dart';
import '../session/access_policy.dart';

/// The things a resident can be part-way through when a gate interrupts them.
///
/// ---
///
/// **A closed set, deliberately.** An intent is remembered across a sign-in
/// prompt, so it is state that outlives the screen that created it. Letting a
/// caller invent one — a free-form action name, a callback, a builder — turns
/// this into a place where arbitrary behaviour is stored and later replayed with
/// whatever session happens to exist at that moment. An enum can be read, and
/// every case can be reasoned about in one place.
///
/// Each case declares the access it needs. That declaration decides **which gate
/// to show**, and nothing else: it is not a permission, and satisfying it does
/// not authorise the action. The server authorises on the request that follows
/// (backend ADR 0002).
enum ResidentIntentKind {
  /// React to a municipal post.
  likePost(AccessRequirement.authenticated, 'like this post'),

  /// Comment on a municipal post.
  commentOnPost(AccessRequirement.authenticated, 'comment'),

  /// Register attendance for an LGU event.
  registerForEvent(AccessRequirement.authenticated, 'register for this event'),

  /// Save a service for later.
  saveService(AccessRequirement.authenticated, 'save this service'),

  /// Manage notification preferences.
  manageNotifications(
    AccessRequirement.authenticated,
    'manage your notifications',
    destination: AppRoute.account,
  ),

  /// Apply for a municipal service. Acts on the resident's civil record.
  applyForService(AccessRequirement.verified, 'apply for this service'),

  /// Open the LGU digital ID.
  viewDigitalId(
    AccessRequirement.verified,
    'open your digital ID',
    destination: AppRoute.digitalId,
  );

  const ResidentIntentKind(
    this.requirement,
    this.description, {
    this.destination,
  });

  /// The gate this intent runs into. **Presentation only.**
  final AccessRequirement requirement;

  /// Lower-case fragment used in gate copy: `Sign in to <description>`.
  ///
  /// Fixed text, never resident-supplied, so a gate sheet cannot be made to
  /// display arbitrary content.
  final String description;

  /// Where resuming this intent takes the resident, when a route exists.
  ///
  /// `null` for the intents whose screens are not built — liking, commenting,
  /// event registration and service applications all belong to backend modules
  /// the committed contract lists as planned (TAB 05 gap D-2). Those intents are
  /// still remembered and still resumed; the resumer simply confirms rather than
  /// navigating, instead of inventing a destination that would only fail.
  final AppRoute? destination;
}

/// Something a resident started, held while they pass through a gate.
///
/// ---
///
/// **What may be stored, and what may not.**
///
/// A pending intent holds a [kind] and, at most, one opaque [targetId]. It holds
/// **no free text**, no form contents, no draft comment body, no personal data
/// and no callback. Two reasons:
///
/// 1. A gate can be reached from a guest session, so anything kept here may
///    outlive the account it belonged to. A draft comment is the resident's
///    words; it does not belong in a global holding area keyed to nobody.
/// 2. Anything stored is something that must be cleared correctly on sign-out,
///    on session expiry and on app suspend. Keeping the payload trivially small
///    makes that easy to get right and easy to prove.
///
/// The screen that resumes an intent is responsible for re-collecting whatever
/// input it needs. Losing a half-typed comment is a small cost; leaking one is
/// not.
@immutable
class ResidentIntent {
  ResidentIntent({
    required this.kind,
    required this.createdAt,
    this.targetId,
  }) : assert(
         targetId == null || _safeTargetId.hasMatch(targetId),
         'A target id must be an opaque server identifier, not free text.',
       );

  final ResidentIntentKind kind;

  /// An opaque server identifier — a UUID or a stable code such as `CEDULA`.
  ///
  /// Validated against a conservative pattern so that a caller cannot smuggle a
  /// sentence, a URL or personal data through this field.
  final String? targetId;

  final DateTime createdAt;

  /// Identifiers the app is willing to carry: UUIDs and `SCREAMING_SNAKE` codes.
  static final RegExp _safeTargetId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// How long a held intent stays meaningful.
  ///
  /// Bounded because an intent resumed much later surprises a resident: they
  /// signed in ten minutes ago for one reason and the app suddenly acts on
  /// something they have forgotten. Ten minutes covers a sign-in round trip
  /// including an SMS code, and little else.
  static const Duration ttl = Duration(minutes: 10);

  bool isExpired(DateTime now) => now.difference(createdAt) >= ttl;

  /// Whether [decision] satisfies the gate this intent was held for.
  ///
  /// The decision comes from `AccessPolicy`, the same evaluation the router
  /// uses, so there is one notion of "may see this" in the app rather than two
  /// that can disagree.
  bool isSatisfiedBy(AccessDecision decision) => decision is AccessAllowed;

  /// Redacted: the target id is opaque but still identifies a record the
  /// resident interacted with, which is a fact about them.
  @override
  String toString() => 'ResidentIntent(${kind.name})';
}
