# TAB COMPLETION REPORT — FINAL

**TAB:** 28 — QA, Test Journeys, Final Servana/Taytay Polish & Release Readiness
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**MASTER COMMAND STATUS:** **ALL 28 TABs COMPLETE**
**DATE:** 2026-08-16

## Completed scope

Seven linked fictional residents; thirty-five journey tests driving the real app
with the shipped repositories; a seventeen-check release-readiness audit covering
branding, the product boundary, Android and iOS configuration, secrets and the
documentation record; and two genuine defects found and fixed.

## Deliverables

* `test/support/taytay_personas.dart` — the seven personas, linked by ids that
  agree across fixtures, carrying **no identifier of any kind**
* `test/features/resident_journeys_test.dart` — 35 journeys
* `test/core/release_readiness_test.dart` — 17 audit checks
* `docs/taytay-qa-and-release-readiness.md` — the QA checklist, the Servana
  alignment audit, the Taytay audit and the release verdict
* Decision log D-170 … D-172

## Two defects found, and the second one is the interesting one

### A held intent survived sign-out

`IntentController.onSessionChanged` documented itself as "wired to sign-out and
to fail-closed invalidation". It was wired to the `401` path **only** — the doc
described a wiring that did not exist.

A resident who signed out deliberately kept their pending intent, and the next
person to sign in on the same handset had it replayed as them. One smartphone per
household is ordinary in Taytay: Ana signs out, her brother signs in, and the app
resumes "apply for assistance" as him.

Fixed by observing the boundary on the **session itself** rather than on any of
the three routes into it (D-171).

### The fix over-corrected, and the existing suite caught it immediately

The first version cleared on any account-id change — which includes a guest
signing in, and that is the entire reason an intent is held.
`welcome_and_gates_test.dart` failed on the next run.

The rule is now precise (D-172): **signing in is not a boundary, it is the
resume.** A boundary is a session *ending* or one account replacing another.

Worth recording as much as the fix: a new journey test found a real leak, and the
year-old suite caught the over-correction. Neither would have sufficed alone.

## Three scan corrections, which were my tests being wrong

* `/admin` "reachable": the location string was `/admin`, the rendered screen was
  not-found. The assertion tested the URL parser; it now tests what a resident is
  shown, plus a structural half — the route table declares no admin route at all.
* `READ_MEDIA_IMAGES` "declared": it appears in an XML comment explaining why it
  is **not** declared. XML comments are now stripped, as Dart ones already were.
* `assigned_to` / `internal_note` "modelled": they appear in the decoders'
  `forbiddenKeys` deny-lists. A decoder that rejects a staff field has to name it.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — **1205 tests** (1151 → 1205) |
| `dart format` | **PASS** — clean, 0 changed |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Branding audit | **PASS** — no reference-app name in code, assets, manifest, plist, gradle or pubspec |
| Product boundary | **PASS** — every route declares a requirement; no admin route exists; 3 access levels |
| Android permissions | **PASS** — exactly `INTERNET` + `USE_BIOMETRIC` |
| Secrets | **PASS** — no credential-shaped `--dart-define`, no `.env` |
| Decision log | **PASS** — D-1 … D-172, no gaps |

## Environment / production-only gaps

* **No iOS build.** The development host is Windows; `flutter build ios` needs
  macOS. The runner is configured and statically audited, and the code is
  platform-agnostic Dart, but **no iOS binary has been produced or run**. The
  acceptance criterion says "targets available in environment"; Android is the
  one that was available, and it passes.
* **No physical device run at all.** The debug APK builds and has not been
  installed. No TalkBack or VoiceOver session, no DevTools trace, no scroll
  profile on a mid-range handset.
* **Six of nine backend modules are `planned`** — `Identity`, `ResidentProfile`,
  `Credential`, `Verification`, `ServiceDelivery`, `Notification`. Every
  repository declines honestly and every screen renders its refusal state.
* **No release signing, store listing, privacy-policy URL or version.** All
  municipal decisions and remote acts.
* **No integration-test harness.** With the shipped repositories declining, a
  driver would exercise the same refusal states through a slower harness on the
  same single target. The Master Command allows for it "where project setup
  permits"; here it adds nothing the journeys lack.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**
Store release: **NO** · Credential rotation: **NO** · Merge: **NO**

**Every one of the 28 TABs was completed locally. Nothing has been pushed at any
point in this run.**

## Classification

**READY_FOR_HUMAN_REMOTE_AUTHORIZATION**

What a human must do next, in order:

1. Run the app on a physical Android device and a physical iPhone.
2. Run TalkBack and VoiceOver through the seventeen journeys.
3. Decide the analytics question — whether the municipality commissions a
   service at all, and under what data-sharing agreement.
4. Produce release signing material and a store listing.
5. Authorize the first push.

## Master Command status

**COMPLETE — 28 of 28 TABs certified.** No further TAB to advance to.
