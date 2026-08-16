# TAB COMPLETION REPORT

**TAB:** 21 — Events: Discovery & Event Detail
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

Events discovery with Upcoming / Registered / Past scopes, cover media, cards
carrying date, venue, registration state and stated capacity; an event detail
with hero, when/where facts, guarded directions, rules, capacity, reminders and
share; and a Manila-time seam every LGU date now renders through.

## Deliverables

* `lib/core/time/manila_time.dart` — PH wall time, 12-hour, written-out dates,
  same-day and cross-midnight ranges
* `lib/core/links/external_link_service.dart` + `platform_external_link_service.dart`
  — `https`-only validation, `LinkOutcome`, unavailable implementation
* `LguEvent` extended: venue with a guarded directions URL, category, cover,
  organiser, contact, registration rules, what-to-bring, share URL, capacity,
  registration state, publication state, `isResidentVisible`, `isPast`
* `EventScope`, `EventRegistrationState`, `EventVenue`, `EventCapacity`
* `lib/features/events/presentation/events_controller.dart`
* `events_screen.dart` and `event_detail_screen.dart` rewritten
* `AppDependencies.externalLinks`
* `docs/taytay-events.md`; decision log D-107 … D-113
* `test/features/events_test.dart` — 37 tests

## Material decisions

D-107 Manila time, stated · D-108 fixed +08:00 rather than a tz database ·
D-109 `https`-only external links, refused not repaired · D-110 a directions link
is the server's or absent · D-111 remaining places are stated, never computed ·
D-112 publication state enforced at list and detail · D-113 "Registered" hidden
from a guest via `AccessPolicy`.

## Two defects found and fixed during the run

Both real, and both caught by the repo's own gates rather than by inspection:

* **The security scan caught a scattered access check.** I wrote
  `session.accessLevel != AccessLevel.guest` in `events_screen.dart` to decide
  whether to show the "Registered" segment — exactly the pattern
  `test/core/security_scan_test.dart` forbids. Replaced with
  `AccessPolicy.evaluate(... AccessRequirement.authenticated)`.
* **A layout overflow on a narrow card.** The registration row put an icon and a
  sentence-length label ("You are on the waitlist") in an unconstrained `Row`,
  which overflows at 336dp. The `Text` is now `Expanded`.

## Dependency added

`url_launcher ^6.3.2` (flutter/packages), with a written review in `pubspec.yaml`.
No permissions; used for one thing — a server-supplied `https` map link — and
wrapped so no screen calls it directly.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 921 tests (884 → 921) |
| `dart format` | **PASS** — clean |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / authenticated / verified | **PASS** — guest and signed-in both exercised |

## Environment / production-only gaps

* `GET /api/v1/events` is `planned`, so `PlannedEventRepository` declines and the
  screens show their failure state against the real backend. Tests exercise the
  full flow through an injected repository.
* Registration, waitlist and attendance are **TAB 22**; this TAB displays state
  and offers no register control, and the detail says so in words.
* The OS launcher cannot run in a widget test; `PlatformExternalLinkService` is
  thin glue and all validation is unit-tested through `ExternalLink`.
* Cover images use `Image.network` with no disk cache; TAB 25 owns caching.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 22 — Events: Registration, Waitlist & Attendance Status.**
Automatic advancement: AUTHORIZED.
