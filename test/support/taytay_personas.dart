/// The seven fictional Taytay residents the QA journeys are run against.
///
/// ---
///
/// ## Every name here is invented
///
/// CLAUDE.md Article 5.6 forbids real citizen data anywhere in this repository,
/// including in tests. The names below are ordinary Filipino names chosen to be
/// obviously synthetic in combination; the account ids are `acct-p1`-style
/// placeholders that no server ever issued; the reference numbers use a
/// `TR-2026-` prefix that is not a format the backend has published.
///
/// **No mobile number, address, PhilSys number or date of birth appears in this
/// file at all.** Not a fake one either. A fixture file full of plausible-looking
/// government identifiers is a file somebody eventually copies into a bug report,
/// and the safest fake identifier is the one that was never written down.
///
/// ## Why the dataset is linked
///
/// The Master Command asks for a *linked* dataset, and the linkage is what makes
/// the journeys real rather than seven unrelated screens: Rosa's missing
/// requirement belongs to Rosa's case, which belongs to a service in the
/// catalogue; Ben's waitlist place belongs to an event that is full. Ids that
/// agree across fixtures are the difference between testing a screen and testing
/// a resident's afternoon.
///
/// Each persona names only what it needs. A persona that carried every field
/// would tempt a test into asserting something the journey does not exercise.
library;

import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

/// One fictional resident, and what the LGU holds for them.
typedef Persona = ({
  /// Short handle used in test names.
  String handle,

  /// What the journey is about, in one line.
  String story,

  AccessLevel level,

  /// Null for the guest, who has no account by definition.
  ResidentSession? session,
});

// ─── Linked identifiers ─────────────────────────────────────────────────────
//
// Declared once so a fixture in one test cannot drift from the fixture in
// another. Every one of these is invented.

/// The catalogue entry Rosa and Marites both applied against.
const String medicalAssistanceCode = 'AICS-MED';
const String medicalAssistanceName = 'Medical assistance';

/// Marites' case: approved, nothing outstanding.
const String maritesRequestId = 'req-p4-0001';
const String maritesReference = 'TR-2026-000041';

/// Rosa's case: open, waiting on one document.
const String rosaRequestId = 'req-p5-0002';
const String rosaReference = 'TR-2026-000058';

/// The requirement Rosa has not sent.
const String rosaMissingRequirementCode = 'BRGY-CLEARANCE';
const String rosaMissingRequirementLabel = 'Barangay clearance';

/// The event Ben is waitlisted for — full, so his place is a queue position.
const String benEventId = 'evt-p6-0003';
const String benEventTitle = 'Free dental mission';
const String benRegistrationId = 'reg-p6-0003';
const String benRegistrationReference = 'TR-2026-000072';

/// The announcement Lito commented on.
const String litoPostId = 'post-p7-0004';
const String litoPostTitle = 'Road closure on M. L. Quezon Street';
const String litoCommentId = 'cmt-p7-0004';

// ─── The seven ──────────────────────────────────────────────────────────────

/// Nobody signed in. **A first-class state, not an error state** (Appendix A).
const Persona guest = (
  handle: 'guest',
  story: 'Has not registered. Browsing to decide whether to.',
  level: AccessLevel.guest,
  session: null,
);

/// Signed in, identity not yet confirmed by the LGU.
const Persona unverified = (
  handle: 'ana',
  story: 'Registered last night. Waiting for Taytay LGU to confirm who she is.',
  level: AccessLevel.unverified,
  session: ResidentSession(
    accountId: 'acct-p2',
    accessLevel: AccessLevel.unverified,
    displayName: 'Ana',
  ),
);

/// Verified, nothing in flight.
const Persona verified = (
  handle: 'jun',
  story: 'Verified resident with no open applications.',
  level: AccessLevel.verified,
  session: ResidentSession(
    accountId: 'acct-p3',
    accessLevel: AccessLevel.verified,
    displayName: 'Jun',
  ),
);

/// Verified, with a case the office has already approved.
const Persona verifiedWithAssistance = (
  handle: 'marites',
  story: 'Verified, one approved medical assistance case ($maritesReference).',
  level: AccessLevel.verified,
  session: ResidentSession(
    accountId: 'acct-p4',
    accessLevel: AccessLevel.verified,
    displayName: 'Marites',
  ),
);

/// Verified, with an open case blocked on one document.
const Persona verifiedWithMissingRequirement = (
  handle: 'rosa',
  story:
      'Verified, open case $rosaReference waiting on a '
      '$rosaMissingRequirementLabel.',
  level: AccessLevel.verified,
  session: ResidentSession(
    accountId: 'acct-p5',
    accessLevel: AccessLevel.verified,
    displayName: 'Rosa',
  ),
);

/// Verified, holding a waitlist place at a full event.
const Persona withWaitlistedEvent = (
  handle: 'ben',
  story: 'Verified, waitlisted for $benEventTitle — the event is full.',
  level: AccessLevel.verified,
  session: ResidentSession(
    accountId: 'acct-p6',
    accessLevel: AccessLevel.verified,
    displayName: 'Ben',
  ),
);

/// Signed in but unverified, and active in the newsfeed.
///
/// Deliberately unverified: reading and commenting on public municipal
/// announcements is not a resident-linked service, and a build that quietly
/// required verification for it would have narrowed the public square.
const Persona withNewsfeedEngagement = (
  handle: 'lito',
  story: 'Signed in, unverified, commented on "$litoPostTitle".',
  level: AccessLevel.unverified,
  session: ResidentSession(
    accountId: 'acct-p7',
    accessLevel: AccessLevel.unverified,
    displayName: 'Lito',
  ),
);

/// Every persona, in the order the Master Command lists them.
const List<Persona> personas = <Persona>[
  guest,
  unverified,
  verified,
  verifiedWithAssistance,
  verifiedWithMissingRequirement,
  withWaitlistedEvent,
  withNewsfeedEngagement,
];

/// A stored session for [persona], or null for the guest.
StoredSession? storedSessionFor(Persona persona) {
  final resident = persona.session;
  if (resident == null) return null;
  return StoredSession(
    resident: resident,
    // Obviously not a real token, and short enough that nobody mistakes it for
    // one that was ever issued.
    accessToken: 'test-token-${persona.handle}',
  );
}
