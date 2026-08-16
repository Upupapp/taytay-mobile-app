# TAB COMPLETION REPORT

**TAB:** 22 — Events: Registration, Waitlist & Attendance Status
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A registration flow gated by the server's own per-event policy; registered,
waitlisted, full, closed, refused and could-not-send outcomes; a My Registration
card carrying reference, waitlist position, instructions and attendance; and an
event-detail register control that appears only when the office says
registration is open.

## Deliverables

* `lib/features/events/domain/event_registration.dart` —
  `EventRegistrationForm`, `EventRegistration`, `AttendanceResult`,
  `RegistrationOutcome`, `RegistrationAttempt`
* Three registration methods on `EventRepository`; planned implementation
  declines all of them
* `LguEvent.myRegistration`
* `lib/features/events/presentation/event_registration_controller.dart` —
  blocks, derived steps, validation, idempotency
* `event_registration_screen.dart`; `MyRegistrationCard` and the register CTA on
  the detail
* Route `/events/:eventId/register` (`authenticated`)
* `lib/core/forms/server_form.dart` and `lib/core/api/server_value.dart` —
  promoted shapes, aliased and re-exported so TAB 15 and every existing importer
  read unchanged
* `docs/taytay-event-registration.md`; decision log D-114 … D-121
* `test/features/event_registration_test.dart` — 34 tests

## Material decisions

D-114 full and closed are outcomes, not errors · D-115 the register control
appears only on `open` · D-116 unverified eligibility is a per-event server
answer · D-117 the route is `authenticated`, the form gates verification ·
D-118 form shapes promoted to `core/forms/` · D-119 `ServerValue` promoted to
`core/api/` · D-120 waitlist position and attendance only when published ·
D-121 `block` yields to an outcome once an attempt has answered.

## A defect this TAB found in itself

The first working version flipped from a successful registration straight to
"You are already registered", because `block` recomputed `alreadyRegistered` the
moment the server confirmed the place and the blocked view outranked the outcome
view — swallowing the reference the resident came for. Fixed by having `block`
return `null` once an attempt has produced an outcome, and pinned by two tests.

## Refactor carried out under this TAB

`ServerField`, `ServerFieldChoice`, `ServerFieldKind` and `ServerConsent` moved
from `features/services/domain/assistance_intake.dart` to `core/forms/`, and
`ServerValue` from `features/services/domain/lgu_service.dart` to `core/api/`.
Both were forced: `core/forms/` may not import a feature, and duplicating the
field shapes for events would have produced two enums over one concept.

Every old name is aliased or re-exported, so no existing file changed and the
full suite passed unmodified across the move.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 956 tests (921 → 956) |
| `dart format` | **PASS** — clean |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / unverified / verified | **PASS** — all three exercised |

## Environment / production-only gaps

* `GET /api/v1/events` and every registration endpoint are `planned`, so
  `PlannedEventRepository` declines and the screens show their honest states.
  Tests exercise the full flow through an injected repository.
* **Cancelling is contracted but not surfaced.** `cancelRegistration` exists on
  the repository and `EventRegistrationForm.canCancel` carries the permission,
  but no cancel control is built: giving up a place is irreversible from the
  resident's side, and it deserves the confirmation treatment TAB 24 (account
  controls) establishes rather than a bare button added here. Recorded so it is
  not mistaken for an omission.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 23 — Notifications, Push, Inbox & Deep Links.**
Automatic advancement: AUTHORIZED.
