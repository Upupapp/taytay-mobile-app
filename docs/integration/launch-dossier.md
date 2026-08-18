# Launch dossier and go/no-go — Taytay Resident Mobile App

**Decision: NO-GO.**

Recorded 18 August 2026, against `Upupapp/taytay-mobile-app` at the head of the
integration sequence, backend baseline `api-baseline-2026-08` (`eec71e6`).

Every figure below was **re-measured at decision time**, not copied from a
checkpoint. This programme exists because a confident status document turned out
to be forty-five commits out of date, and a dossier assembled from other
documents would repeat exactly that.

## Re-measured at decision time

| Check | Result |
| --- | --- |
| `flutter test` | **1,346 passing, 0 failing** |
| `flutter analyze` | clean |
| Backend still at the baseline tag | OK — 17 modules agree |
| Repositories bound to stubs | **1 of 16** (was 16 of 16 at TAB 00) |
| Release artifact | **cannot be built** — `SigningConfig "release" is missing required property "storeFile"` |
| `credential.enabled` | **false** — the digital ID is off server-side |
| Barangay directory route | **does not exist** |
| Self-registration route | **does not exist** |

## Why no-go, in one paragraph

At this baseline **a resident cannot create an account, cannot receive a code to
sign in to one, and could not become Verified if they did.** No release artifact
can be signed. Two hard store requirements have no endpoint behind them. The
municipality has no Data Protection Officer and no approved retention schedule.
The app itself is in good order — thirteen repositories wired, the suite green,
the analyzer clean — and that is not what a launch turns on.

## The twelve original findings

| ID | Sev | State | Evidence |
| --- | --- | --- | --- |
| F01 | P0 | **Closed** | `PlannedModule` holds two members; asserted against `backend-baseline.md` by test |
| F02 | P0 | **Closed (client half)** | `AuthApiRepository` wired; 17 tests. End-to-end blocked by F16 |
| F03 | P0 | **Open — LGU** | Client half closed: the build now *fails* unsigned rather than using the debug key. Re-verified failing at decision time |
| F04 | P1 | **Closed** | Both codes decode, with copy in two languages; drift test both directions |
| F05 | P1 | **Closed upstream** | Fixed at `eec71e6`; the published enum carries wire values |
| F06 | P1 | **Closed** | `app/bootstrap` consumed; force-upgrade and maintenance both render |
| F07 | P1 | **Closed** | Clock threaded through the composition root; the *class* swept, not just the instance |
| F08 | P2 | **Closed** | `ProgramApiRepository` wired; route opened to guests |
| F09 | P2 | **Open — coordinated** | `credential.enabled` re-read at decision time: **false**. Both states ship in one build |
| F10 | P2 | **Declined, documented** | `security-decisions.md` — rotation risk outweighs a rare CA compromise |
| F11 | P2 | **Closed** | `minSdk = 24`, `targetSdk = 36`, pinned literals |
| F12 | P2 | **Accepted** | `Verification` and `ServiceDelivery` remain planned. See residual scope |

## The seventeen raised during integration

**P0 — each one alone prevents a launch**

| ID | Finding | Owner |
| --- | --- | --- |
| **F14** | No barangay directory. `POST me/kyc` needs a `barangay_id` no route publishes → **nobody can become Verified**, so no digital ID and no service that rests on it | backend |
| **F15** | No self-registration route. Onboarding is staff-mediated by construction; the app ships a wizard with no server counterpart | product / LGU |
| **F16** | Sign-in codes are issued, recorded and **never dispatched** → nobody can sign in | backend |
| **F26** | No content-reporting route. Both stores require one for user-generated content | backend |

**P1**

F13 no account-deletion route *(store blocker)* · F22 no token refresh *(decided: one sign-out under concurrency)* · F23 KYC corrections keyed differently on the two sides · F24 no per-service intake form · F25 proxy body limit unknown, client ceiling is a guess · F27 push registration cannot be withdrawn at sign-out · F29 no data-portability export

**P2**

F17 four repositories named the wrong module *(closed)* · F19 programme contract wrong on four axes *(closed)* · F20 three "auth" endpoints are staff surfaces *(not wired, deliberately)* · F21 verification tier is not on `GET me` *(closed)* · F28 the release artifact declares four Android permissions, not the two the original audit reported *(accepted, now guarded)*

## Residual scope — say this before launch, not after

* **QR credential verification cannot be proven end-to-end.** `Verification` is
  planned, so the QR can be produced and never scanned by a real verifier. "The
  digital ID works" must not be reported when only half the loop is testable.
* **National service transactions are out of scope.** `ServiceDelivery` is
  planned.
* **There are no push notifications**, and the recommendation is to launch
  without them rather than adopt a processor the DPO has not reviewed.
* **Registration is staff-mediated.** Residents will expect to sign themselves
  up. If that is not the intended product, it is a backend change, not a screen.

## Non-engineering blockers — the ones a technical review waves through

| Blocker | Owner | Status |
| --- | --- | --- |
| Data Protection Officer appointed | LGU | **Open.** Nobody can answer a data-subject request the app raises |
| Retention schedule approved | LGU | **Open.** Blocks account deletion and the "how long is my data kept" answer |
| Signing keystore generated and held | LGU | **Open.** No artifact can be produced |
| Play / App Store developer account as the LGU | LGU | **Open** |
| Privacy policy published at a stable URL, both languages | DPO | **Open** |
| Backup restore tested | backend | **Open** (LGU's own declaration) |
| Independent security review | LGU | **Not commissioned** |
| UAT with residents and MSWDO staff, in Filipino | LGU | **Not run** |

## Rollback — rehearsed on paper only, and one thing must be understood

Staged rollout 5% → 20% → 50% → 100%, held a full day at each stage.

**Play halts distribution of a new version; it does not remove it from phones
that already updated.** A client defect that ships is fixed forward. That is the
argument for a small first stage — not for confidence in rollback. The halt must
be practised before the first release, because a safety net nobody has pulled is
not one.

Server-side mitigations available without a client release: the `digital_id`
feature flag, and `minimum_version` on `app/bootstrap`, which can force an upgrade
without waiting for residents to notice one.

## Support runbook

A resident reports a problem → they read out the **Reference** shown on the error
screen (selectable, TAB 14) → that is `request_id`, which joins directly to a
server log. The app never shows the server's own message, so what they can quote
is the reference and what they were doing.

**Not staffed.** No on-call rotation, no escalation path to the LGU, no monitored
support address — `app/bootstrap` publishes a support email and phone and both
are currently empty strings.

## What would change this decision

In order of what unblocks the most:

1. **F16** — dispatch sign-in codes. Nothing else about the app is reachable
   until a resident can get in.
2. **F15** — decide whether onboarding is staff-mediated. If yes, replace the
   registration wizard; if no, the backend needs a route.
3. **F14** — publish a barangay directory. Unblocks KYC, and with it the Verified
   state, the digital ID, and every service resting on them.
4. **The keystore**, so an artifact exists at all.
5. **F13 and F26**, without which no store will accept a submission.
6. **DPO and retention schedule** — longest lead time, start first.

Items 1–3 are days of backend work each. Items 4–6 are weeks of organisational
work, and are the ones that will decide the launch date.

## Post-decision addendum — one caveat narrowed, one finding added

After the go/no-go was recorded, the claim that no PHP toolchain existed on this
machine was checked and found to be **false** — it had been carried from the
Master Command through twenty-five TABs without verification. The backend runs
locally against sqlite.

That does not change the decision, and it improves the evidence behind it:

* Nine endpoints called for real; responses recorded as golden fixtures and
  decoded through the app's own decoders. The fixture drift check now **passes**
  instead of skipping.
* **F30 raised**: `GET newsfeed` answers 401 to a guest, because the controller
  gates anonymous readers on `newsfeed.public_access`, which defaults off. The
  route file carries no `auth:sanctum`, so reading it says public and calling it
  says otherwise. The app had been wired anonymously by construction, which would
  have broken the feed for signed-in residents too. Fixed.
* Also recorded: the server publishes `default_page_size: 15` for
  `citizen-mobile` and this app sends its own 25. Nothing breaks; it is a
  divergence that should be a decision.

The four blocking P0s are unchanged, and none of them became testable: F15 and
F16 mean no account can exist and no code can be sent, so **no authenticated
journey was exercised even with a server running**. That is the platform's gap,
not the tooling's.

## Dissents

One, recorded against myself and now demonstrated: I repeated a document's claim
about this machine for twenty-five TABs without checking it, and it was wrong.
The lesson is the one this whole programme is about — a status document is not
evidence, including the one that told me what I could not do.

Beyond that: This dossier was assembled by one engineer with no access to a
staging environment, a device, or the LGU. **That is itself the most important
caveat in it:** every "closed" above means closed against a contract read from
source and a suite run against scripted transports. Nothing here has been proven
against a running Taytay backend, and TAB 24's own instruction — re-measure at
decision time, call the endpoints — could only be half-followed, because there is
nothing to call.
