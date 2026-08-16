# TAB COMPLETION REPORT

**TAB:** 25 — Network Loss, Offline/Degraded UX & Performance
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

Reachability inferred from real request outcomes rather than a radio flag; one
offline banner in the shell that waits for evidence before it speaks; a public
cache whose keys now include the query and which can serve stale content **with
its age attached**; an unsent vocabulary that never says "saved"; and remote
images decoded at the size of the box they are drawn into.

## Deliverables

* `lib/core/network/network_monitor.dart` — `NetworkStatus`, `NetworkMonitor`,
  `failuresBeforeReporting`, `shouldWarn`, `lastReachableAt`, `unreachableSince`
* `ApiClient` reports every outcome, in one place, with nothing personal attached
* `lib/core/storage/public_cache.dart` — rewritten: `keyFor`/`pathOf`,
  `CacheEntry.storedAt`, `CachedRead`, `readAllowingStale`, `maxEntries`,
  allow-list widened to the public collections
* `lib/shared/widgets/network_status_views.dart` — `OfflineBanner`,
  `StaleContentNotice`, `UnsentNotice`
* `lib/shared/widgets/remote_image.dart` — right-sized decode, feed and
  full-size ceilings, reserved space, error fallback, `configureImageCache()`
* `RootShell` carries the banner on both layouts; `main` sizes the image cache
* `ServiceCatalogRepository.lastKnownServices` + implementation;
  `ServiceDirectoryController` adopts it when a load fails with nothing on screen
* The services stale banner now states **when** the office answered
* `docs/taytay-offline-and-performance.md`; decision log D-145 … D-153
* `test/core/network_and_cache_test.dart` (25) and
  `test/features/offline_test.dart` (25)

## Material decisions

D-145 reachability from real outcomes, never a radio flag · D-146 no connectivity
plugin · D-147 two consecutive failures before the app speaks · D-148 one banner,
in the shell · D-149 the cache key is the path **and** its sorted query · D-150
`read` evicts stale, `readAllowingStale` returns it with its age · D-151 the
public cache stays in memory, and the cost is stated · D-152 unsent work says
"not sent", never "saved" · D-153 images decode to the size of the box.

## A latent defect found and fixed

`PublicCache` keyed entries by **path alone**. `services` was one key whatever
the query, so page 3 would have been served to a request for page 1, and one
category's results to a request for another. Nothing read from the cache yet, so
it had never fired — but this is the TAB that starts reading from it, and the
first read would have been a resident shown the wrong page of the municipal
catalogue.

The key is now path + sorted query; the allow-list is still checked against the
path, because what is public is a property of the endpoint rather than of its
arguments. `ServiceCatalogApiRepository` builds that query in one helper used by
both the request and the lookup, which is what makes the two keys agree.

## Why there is no connectivity plugin

The obvious implementation reads the radio. It answers a different question: a
phone on a captive-portal wifi at a barangay hall, a phone with data enabled and
no load balance, and a phone on a signal too weak to finish a handshake all
report "connected" and can reach nothing.

`NetworkMonitor` answers the question the resident is asking — did that reach the
office — from the outcome of a real request, and treats **every server-produced
failure as proof of reachability**. A `403` is the server speaking; a banner over
it would send somebody to a load-up stall over a permission decision. Adding a
dependency that would need an Article 1 permissions and data-egress review, to
learn the same thing less accurately, is not a trade this app makes.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 1078 tests (1028 → 1078) |
| `dart format` | **PASS** — clean, 0 changed |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / unverified / verified | **PASS** — the offline path is exercised as a guest, which is who it is for |

## Environment / production-only gaps

* **No DevTools trace or on-device scroll profile.** The decode ceiling is the
  change that moves that number; it is reasoned from Flutter's documented decode
  behaviour and asserted in a test rather than measured on hardware. Running one
  on a physical mid-range Android device is outstanding.
* **No disk cache**, deliberately (D-151). A resident who force-quits and reopens
  on a dead connection sees nothing; within a process they keep everything. The
  cost is stated in the docs rather than hidden.
* The public collections — announcements, events, programmes — are allow-listed
  for caching but their modules are `planned`, so nothing populates those entries
  yet. The catalogue is the one live endpoint and is the one exercised end to end.
* **No offline submission queue**, deliberately. A request held on the phone and
  sent later is one whose eligibility, capacity and deadlines were evaluated
  against a state that has since moved.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 26 — Accessibility, Localization & Device Adaptation.**
Automatic advancement: AUTHORIZED.
