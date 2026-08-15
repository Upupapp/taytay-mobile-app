# TAB COMPLETION REPORT

**TAB:** 17 — Assistance Status, Case Timeline & Next Steps
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

The full admin lifecycle mapped to resident copy with the canonical value kept
visible; a resident-safe case timeline; a next-action component driven entirely
by what the backend offers; published-only outcome reasons, release instructions
and referral; and the deletion of the screen this replaced.

## Deliverables

* `lib/features/services/domain/assistance_case.dart` — `CaseTimelineEntry`,
  `NextActionKind`, `CaseNextAction`, `AssistanceCaseDetail`
* `lib/features/services/domain/request_status_copy.dart` — one status switch for
  the whole app, replacing two that had drifted apart
* `ServiceRequestState` widened to the 13 canonical states, each with a
  `wireValue`, plus `needsResident`
* `loadOwnCase` on the repository contract; planned implementation declines
* `lib/features/services/presentation/assistance_case_screen.dart`
* `/requests/:requestId` now renders it; the superseded `AssistanceRequestScreen`
  is deleted
* `docs/taytay-assistance-case-tracking.md`; decision log D-78 … D-84
* `test/features/assistance_case_test.dart` — 23 tests

## Material decisions

D-78 canonical status shown alongside friendly copy, labelled · D-79 one
status-copy switch in `domain/` · D-80 next steps only when offered; unknown
kinds described not linked · D-81 rejection reason only when published · D-82 the
case model has no field for staff data — structural, not filtered · D-83
`assigned` never names anyone · D-84 the superseded screen is deleted.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 794 tests (771 → 794) |
| `dart format` | **PASS** — clean |
| `flutter build apk --debug` | **PASS** — `build/app/outputs/flutter-apk/app-debug.apk` |
| Access tested from every session state | **PASS** — guest, unverified, verified |

## The build check the orchestrator asked for

`flutter build apk --debug` **succeeds**. TAB 16's two new plugins
(`image_picker`, `file_selector`) resolve, register and compile into an Android
debug APK.

Two earlier build attempts failed, and neither was a plugin problem: both raced
in-flight Dart edits from this TAB's refactor (a widened enum with two exhaustive
switches not yet updated, then a half-removed widget). Gradle reached
`kernel_snapshot` in both, so the Android and plugin layers were already fine.
The clean run confirms it.

## Environment / production-only gaps

* `ServiceDelivery` is `planned` — no case endpoint, so `loadOwnCase` declines
  rather than composing a plausible history.
* The APK is a debug build; it was not installed or run on a device, so the
  pickers are compiled but not exercised against a real camera.

## Outstanding tidy-up

`lib/features/services/presentation/request_status_copy.dart` is now a
re-export shim with no importers and should be deleted outright. It was left as
a shim rather than removed because a shell `rm` was declined mid-run; the file
defines nothing, so it is inert.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 18 — Assistance History, Referral & Release Resident View.**
Automatic advancement: AUTHORIZED.
