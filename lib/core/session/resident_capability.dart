import 'package:flutter/foundation.dart';

import '../router/app_routes.dart';
import 'access_policy.dart';
import 'session_state.dart';

/// Whether the backend can actually serve a capability today.
///
/// A second axis, orthogonal to access. "You need to sign in" and "the LGU has
/// not switched this on yet" are different sentences, and a resident told the
/// wrong one either registers for nothing or gives up on something they could
/// have used. Keeping them apart also stops an unbuilt feature from being
/// mistaken for a permission problem during LGU acceptance testing.
enum BackendAvailability {
  /// A committed, implemented endpoint backs this.
  available,

  /// The contract names the endpoint but the module is `planned`. The screen
  /// exists and declines honestly.
  planned;

  bool get isAvailable => this == BackendAvailability.available;
}

/// What a resident can do in this app, as a closed set.
///
/// ---
///
/// **One list, in one file, for the whole app.** Before this existed, "is this
/// person allowed to see it" was answered by `session.accessLevel` comparisons
/// scattered through screens. Each was correct in isolation and none of them
/// agreed about anything else — what to say when the answer was no, whether the
/// backend even existed, whether to hide or explain. Adding a capability here
/// forces all three answers to be given once.
///
/// **There is no administrative capability, and there cannot be one.** Not a
/// disabled one, not a hidden one, not one behind a flag. This app identifies
/// itself as `citizen-mobile` and the backend authorises from the actor, so a
/// staff capability here would be dead weight at best and a false suggestion of
/// authority at worst. A test asserts the vocabulary stays clean.
enum ResidentCapability {
  // --- Public: everything a person can use before they have an account. ------
  browseServices(
    AccessRequirement.public,
    'Browse municipal services',
    BackendAvailability.available,
    route: AppRoute.services,
  ),
  readNews(
    AccessRequirement.public,
    'Read Taytay announcements',
    BackendAvailability.planned,
    route: AppRoute.news,
  ),
  browseEvents(
    AccessRequirement.public,
    'See LGU events',
    BackendAvailability.planned,
    route: AppRoute.events,
  ),

  // --- Authenticated: needs an account, verified or not. --------------------
  manageAccount(
    AccessRequirement.authenticated,
    'Manage your account',
    BackendAvailability.planned,
    route: AppRoute.account,
  ),
  manageSecurity(
    AccessRequirement.authenticated,
    'Manage sign-in and security',
    BackendAvailability.available,
    route: AppRoute.security,
  ),

  /// The messages Taytay LGU has sent, and what to be told about.
  ///
  /// Authenticated rather than verified: a notification is addressed to a
  /// person, not to a confirmed civil record, and an unverified resident going
  /// through verification is precisely who needs to be told when it completes.
  readNotifications(
    AccessRequirement.authenticated,
    'See your notifications',
    BackendAvailability.planned,
    route: AppRoute.notifications,
  ),

  /// Assistance programmes. **Public and available**, both of which changed at
  /// TAB 07.
  ///
  /// This said the programme row was bearer-authenticated and planned. Neither
  /// was true at `backend@api-baseline-2026-08`: `GET programs` carries no
  /// `auth:sanctum`, and `ServiceCatalog` has served it all along. The service
  /// catalogue next door is public for the same reason and there was never a
  /// difference between them to draw.
  browsePrograms(
    AccessRequirement.public,
    'See assistance programmes',
    BackendAvailability.available,
    route: AppRoute.programs,
  ),
  completeVerification(
    AccessRequirement.authenticated,
    'Verify your identity',
    BackendAvailability.planned,
    route: AppRoute.verification,
  ),

  // --- Verified: acts on the resident's civil record. -----------------------
  holdDigitalId(
    AccessRequirement.verified,
    'Hold your Taytay digital ID',
    BackendAvailability.planned,
    route: AppRoute.digitalId,
  ),
  trackAssistanceRequests(
    AccessRequirement.verified,
    'Track your assistance requests',
    BackendAvailability.planned,
    route: AppRoute.requests,
  ),

  /// Filing an application for a municipal service.
  ///
  /// **Separate from [trackAssistanceRequests] on purpose**, even though both
  /// are verified-only and both belong to `ServiceDelivery`. Reading the status
  /// of something already filed and creating a new obligation on the resident's
  /// civil record are different acts, and an LGU that later opens one before the
  /// other — status first, applications when the office has capacity — can do it
  /// by changing one line here rather than by splitting a capability under
  /// pressure.
  applyForAssistance(
    AccessRequirement.verified,
    'Apply for a municipal service',
    BackendAvailability.planned,
    route: AppRoute.applyForService,
  ),

  /// Sending the documents an office asked for on an existing request.
  ///
  /// Distinct from applying, because the two open at different times: an LGU
  /// that has switched on applications still has to switch on attachment
  /// storage, and a resident who can apply but cannot yet upload should be told
  /// exactly that rather than meeting a generic refusal.
  submitRequirements(
    AccessRequirement.verified,
    'Send the documents Taytay LGU asked for',
    BackendAvailability.planned,
    route: AppRoute.requestRequirements,
  ),

  /// The household or family summary the Master Command asks for, **withheld**.
  ///
  /// The committed contract has exactly one household row —
  /// `GET /api/v1/households/{household_id}` — and it is a **staff** route
  /// requiring the `resident.view` permission under a role scope, with the
  /// sensitivity note "member list is other people's data — audited read".
  /// There is no `/me/household`.
  ///
  /// A household summary is other residents' personal data. Building it against
  /// the staff route would mean this app asking for a permission it must never
  /// hold; building it against an invented `/me/` route would mean shipping a
  /// screen whose contract nobody has agreed, for the most sensitive collection
  /// in the system. So the capability is declared and reported unavailable,
  /// which is the honest state and the one a future TAB can flip in one line.
  viewHouseholdSummary(
    AccessRequirement.verified,
    'See your household summary',
    BackendAvailability.planned,
    // TAB 13 gave it a screen. The capability stays `planned` because no
    // citizen endpoint exists — the screen explains that honestly rather than
    // showing an invented family — but access alone decides whether it opens.
    route: AppRoute.household,
  );

  const ResidentCapability(
    this.requirement,
    this.label,
    this.availability, {
    this.route,
  });

  /// The access this needs to be *shown*. Never a permission — the server
  /// authorises every request regardless (backend ADR 0002).
  final AccessRequirement requirement;

  /// Resident-facing name. Fixed text, never composed from server data.
  final String label;

  final BackendAvailability availability;

  /// Where it lives, when a route exists for it.
  final AppRoute? route;
}

/// The answer to "can this resident use this, and if not, why not".
@immutable
sealed class CapabilityVerdict {
  const CapabilityVerdict();

  /// Whether the resident can act on it right now.
  bool get isUsable => this is CapabilityUsable;
}

/// Usable now.
final class CapabilityUsable extends CapabilityVerdict {
  const CapabilityUsable();

  @override
  bool operator ==(Object other) => other is CapabilityUsable;

  @override
  int get hashCode => (CapabilityUsable).hashCode;

  @override
  String toString() => 'CapabilityUsable()';
}

/// The session is still restoring. Not a refusal — an unfinished question.
final class CapabilityPending extends CapabilityVerdict {
  const CapabilityPending();

  @override
  bool operator ==(Object other) => other is CapabilityPending;

  @override
  int get hashCode => (CapabilityPending).hashCode;

  @override
  String toString() => 'CapabilityPending()';
}

/// The resident must sign in first. Carries its own recovery route.
final class CapabilityNeedsSignIn extends CapabilityVerdict {
  const CapabilityNeedsSignIn();

  @override
  bool operator ==(Object other) => other is CapabilityNeedsSignIn;

  @override
  int get hashCode => (CapabilityNeedsSignIn).hashCode;

  @override
  String toString() => 'CapabilityNeedsSignIn()';
}

/// Signed in, not yet verified.
final class CapabilityNeedsVerification extends CapabilityVerdict {
  const CapabilityNeedsVerification();

  @override
  bool operator ==(Object other) => other is CapabilityNeedsVerification;

  @override
  int get hashCode => (CapabilityNeedsVerification).hashCode;

  @override
  String toString() => 'CapabilityNeedsVerification()';
}

/// The resident's access is fine; the LGU has not switched this on yet.
final class CapabilityNotYetAvailable extends CapabilityVerdict {
  const CapabilityNotYetAvailable();

  @override
  bool operator ==(Object other) => other is CapabilityNotYetAvailable;

  @override
  int get hashCode => (CapabilityNotYetAvailable).hashCode;

  @override
  String toString() => 'CapabilityNotYetAvailable()';
}

/// The one place the app decides what a resident may see.
///
/// ---
///
/// It composes [AccessPolicy] rather than replacing it, so the router's guard,
/// a tile on the home screen, a gate sheet and a deep link all reach the same
/// conclusion from the same rule. Two things it adds:
///
/// 1. **Availability.** Access and existence are separate reasons for "no".
/// 2. **A recovery route for every refusal.** Acceptance 2 of this TAB is that
///    no gate is a dead end, and the cheapest way to guarantee that is to make
///    it impossible to express a refusal without one.
///
/// **Order matters and is deliberate: access is evaluated before availability.**
/// A guest asking for a verified-only capability is told to sign in, not that
/// the feature is missing. Answering "not available yet" would leak that the
/// feature exists and is gated, would be a different answer for a guest than for
/// a verified resident, and would send someone away who should have been sent to
/// sign in.
abstract final class CapabilityService {
  static CapabilityVerdict evaluate({
    required SessionState session,
    required ResidentCapability capability,
  }) {
    final decision = AccessPolicy.evaluate(
      session: session,
      requirement: capability.requirement,
    );

    return switch (decision) {
      AccessPending() => const CapabilityPending(),
      AccessNeedsAuthentication() => const CapabilityNeedsSignIn(),
      AccessNeedsVerification() => const CapabilityNeedsVerification(),
      AccessAllowed() =>
        capability.availability.isAvailable
            ? const CapabilityUsable()
            : const CapabilityNotYetAvailable(),
    };
  }

  /// Whether navigation to this capability's screen should proceed.
  ///
  /// ---
  ///
  /// **Access only. Availability is deliberately not consulted here**, and the
  /// distinction is the whole reason both methods exist.
  ///
  /// Every screen in this app already handles an absent backend: it renders an
  /// honest "not published yet" state naming what the LGU does offer instead.
  /// Refusing to *open* such a screen would replace that specific, useful
  /// explanation with a generic one, and would hide a screen that works — the
  /// digital ID, the verification status, the request list — behind a flag
  /// describing something the resident cannot see and did not cause.
  ///
  /// So availability decides what a screen *says*; access decides whether it
  /// opens. `requirementLabel` still surfaces "Not available yet" on the tile,
  /// so nobody taps in expecting data that is not there.
  static bool canOpen({
    required SessionState session,
    required ResidentCapability capability,
  }) =>
      AccessPolicy.evaluate(
            session: session,
            requirement: capability.requirement,
          )
          is AccessAllowed;

  /// Where a resident should go to resolve [verdict].
  ///
  /// Never `null` for a refusal — that is the invariant behind acceptance 2,
  /// and it is asserted by a test over every capability in every session state.
  static AppRoute? recoveryRoute(CapabilityVerdict verdict) =>
      switch (verdict) {
        CapabilityUsable() => null,
        CapabilityPending() => null,
        CapabilityNeedsSignIn() => AppRoute.signIn,
        CapabilityNeedsVerification() => AppRoute.verification,
        // Nothing to unlock, but the resident is not left staring at a wall:
        // the catalogue tells them what the LGU does offer today, and the
        // municipal hall handles the rest.
        CapabilityNotYetAvailable() => AppRoute.services,
      };

  /// Resident-facing explanation. Fixed copy, chosen by verdict kind — never
  /// the server's `message`, which is operator-facing by definition.
  static String explain(CapabilityVerdict verdict) => switch (verdict) {
    CapabilityUsable() => '',
    CapabilityPending() => 'Checking your account…',
    CapabilityNeedsSignIn() =>
      'Sign in with your mobile number to use this. Browsing stays open to '
          'everyone.',
    CapabilityNeedsVerification() =>
      'Taytay LGU needs to confirm your identity before you can use this.',
    CapabilityNotYetAvailable() =>
      'Taytay LGU has not switched this on yet. Nothing is wrong with your '
          'account, and you can still use everything else in the app.',
  };

  /// Short label for a locked tile — what is missing, in two or three words.
  static String? requirementLabel(CapabilityVerdict verdict) =>
      switch (verdict) {
        CapabilityUsable() || CapabilityPending() => null,
        CapabilityNeedsSignIn() => 'Sign-in required',
        CapabilityNeedsVerification() => 'Verification required',
        CapabilityNotYetAvailable() => 'Not available yet',
      };
}
