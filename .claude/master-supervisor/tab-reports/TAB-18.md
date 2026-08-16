# TAB COMPLETION REPORT

**TAB:** 18 — Assistance History, Referral & Release Resident View
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A resident's longitudinal record as one list with Open/Past scopes; structured
release and referral detail shared by the history list and the case screen;
receipt references; and an exclusion boundary for accounting internals that is
structural rather than filtered.

## Deliverables

* `lib/features/services/domain/assistance_history.dart` — `HistoryScope`,
  `AssistanceHistoryEntry`, `ReferralDetail`, `ReferralStatus`, `ReleaseDetail`,
  `ReleaseAcknowledgement`
* `listOwnHistory({scope, page, perPage})` on the repository contract; planned
  implementation declines
* `lib/features/services/presentation/release_and_referral.dart` — `ReleaseCard`,
  `ReferralCard`, `referralStatusLabel`, shared `formatCaseDate`
* `assistance_requests_screen.dart` rewritten as the history list with a
  segmented Open/Past scope, outcome summaries, references, dates and receipt
  references
* `AssistanceCaseDetail.releaseInstructions`/`referral` upgraded from prose
  strings to the structured types, so one record has one representation
* `docs/taytay-assistance-history.md`; decision log D-85 … D-91
* `test/features/assistance_history_test.dart` — 26 tests

## Material decisions

D-85 one list with Open/Past scopes · D-86 an approved amount is a server-authored
string, never parsed · D-87 a receipt is a reference, not a download · D-88
acknowledgement stated, never offered · D-89 "no record" and "could not load" are
separate sentences · D-90 referral contact only when published, `declined` always
points somewhere · D-91 release and referral structured once and shared.

## TAB 17 behaviour preserved

The case screen keeps its status card, timeline, next actions and outcome reason
unchanged. Only the release and referral representations changed — from two prose
fields to two structured ones — and the TAB 17 test that covered them was updated
to the new shape rather than removed. All 23 TAB 17 tests still pass.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 820 tests (794 → 820) |
| `dart format` | **PASS** — clean |
| `flutter build apk --debug` | **PASS** — `build/app/outputs/flutter-apk/app-debug.apk` |
| Access tested from every session state | **PASS** — guest, unverified, verified |

## Environment / production-only gaps

* `ServiceDelivery` is `planned` — `listOwnHistory` declines rather than showing
  an empty record, which would be the app claiming a resident has no history.
* No document endpoint exists, so a receipt is a reference rather than a
  download. The field becomes a document id when one is published.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 19 — Newsfeed, Resident Feed.**
Automatic advancement: AUTHORIZED.
