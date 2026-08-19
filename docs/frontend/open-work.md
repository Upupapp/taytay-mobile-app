# Client-owed open work

**The working ledger for the front-end command sequence (TABs 01–09).** Everything here can be
closed by writing Dart in this repository. Nothing here waits on a person.

Its counterpart is `docs/integration/manual-tasks.md`, which holds what *cannot* be closed by a
commit. The two lists are disjoint by construction: an item moves between them only when its
nature changes, and the move is recorded. That split is the lesson F16 taught — most blockers that
look organisational have a seam somebody can build before the decision arrives.

Established by **TAB 00 of the front-end sequence, 19 August 2026**, against
`taytay-mobile-app@bc9cdb5` and `taytay-backend@4236b51`.

---

## Measured at TAB 00

Figures from the run, not from any document.

| | |
| --- | --- |
| `flutter analyze` | **clean** — no issues |
| `flutter test` | **1,386 passing, 1 skipped** |
| Wiring detector | **16 wired, 1 stubbed** (`registrationRepository`, blocked — F15) |
| `tool/check_backend_baseline.sh` | **OK — 17 modules agree** at `api-baseline-2026-08` (`eec71e6`) |
| Working tree | clean at start |
| `origin/main` | **61 commits behind local; nothing has ever been pushed** |

---

## The client-owed rows

| ID | Sev | Finding | Closes in |
| --- | --- | --- | --- |
| **C-01** | P1 | Two upload ceilings disagree, and neither is the server's | TAB 01 |
| **C-02** | P1 | A push registration cannot be withdrawn (F27) | TAB 02 |
| **C-03** | P1 | A registration wizard with no server counterpart (F15, client half) | TAB 03 |
| **C-04** | P1 | KYC corrections keyed by category here, by field on the server (F23) | TAB 04 |
| **C-05** | P2 | The client overrides the page size the server published for this channel | TAB 05 |
| **C-06** | P1 | "One refresh is one sign-out" is decided but never proven under concurrency (F22) | TAB 06 |
| **C-07** | P1 | No TalkBack or VoiceOver session has ever been run | TAB 07 |
| **C-08** | P1 | No physical device run; no iOS run of any kind | TAB 08 |
| **C-09** | **P1** | The app calls two routes that do not exist at its own pinned baseline | **TAB 00A — detected and guarded; resolution still blocked** |
| **C-10** | P3 | The baseline guard's network path cannot work in this programme | **TAB 00A — CLOSED** |

C-01 through C-08 are the findings the front-end command was written from, each already carrying a
TAB. **C-09 and C-10 were found by TAB 00 and the command did not anticipate them.** They were
recorded here rather than quietly folded into a neighbouring TAB, and then taken as an inserted
**TAB 00A** on the owner's instruction.

**TAB 00A closed C-10 and closed the part of C-09 that a repository can close.** The app can now
*see* route-level drift — `lib/core/api/backend_routes.dart` declares all 49 routes it calls, a Dart
test keeps that declaration honest against the source, and `tool/check_backend_routes.sh` checks
each one against the pinned baseline. What remains open in C-09 is the resolution: two routes are
still ahead of the pin, and moving the pin needs the backend repository to be still.

---

## C-09 — the app is wired to routes newer than the baseline it pins itself to

**Severity P1. Found by TAB 00, step 2.**

`lib/core/api/backend_baseline.dart` pins this app to `api-baseline-2026-08` = `eec71e6`, and
`docs/integration/backend-baseline.md` is described as the authority for module status, guarded in
both directions. Two wired client features call routes that **do not exist at that commit**:

| Client call site | Route | At `eec71e6` | At backend HEAD `4236b51` |
| --- | --- | --- | --- |
| `lib/features/registration/data/barangay_api_repository.dart:32` | `GET barangays` | **absent** | present (`BarangayDirectoryController`) |
| `lib/features/news/data/newsfeed_api_repository.dart:208` | `POST newsfeed-comments/{comment}/reports` | **absent** | present (`EngagementController::reportComment`) |

Thirty-three commits separate the tag from backend HEAD. Both routes landed inside that gap — they
are what closed F14 and F26.

**Why the guard did not catch it, and this is the important half.**
`check_backend_baseline.sh` compares **module status** — seventeen rows of built/enabled — and both
routes were added *inside modules that were already implemented at the tag*. `ResidentProfile` and
`Content` did not change status, so the guard passed, and it will keep passing no matter how many
routes appear or disappear inside a module the client depends on. **The guard is structurally blind
to the drift that actually breaks a client.** It answers "does this module exist" when the question
a client needs answered is "does this route exist".

Nothing is broken today: the app is correct against the backend as it stands, and both features
were proven against the API running locally. What is wrong is the *claim*. The repository states a
baseline it has already moved past, and its own guard reports agreement.

**Two honest closures, and why neither was taken in TAB 00:**

1. **Move the baseline forward** to a tag at or after the commit that added both routes, re-derive
   `backend-baseline.md`, and re-pin. This is the correct fix and it is **blocked right now**:
   `taytay-backend` is under another session's active control — its HEAD moved from `5bdc7d6` to
   `4236b51` during this TAB — and a baseline taken from a repository that is moving is stale
   before it is written. It also requires creating a tag in a repository this sequence does not own.
2. **Extend the guard to assert routes, not only modules** — the app declares the routes it calls
   and the guard checks each exists at the pinned baseline. This belongs in this repository and
   would have caught C-09 on the day it was introduced.

**Taken as TAB 00A, 19 August 2026.** Option 2 is done. Option 1 remains blocked and is the whole
of what is still open here: `routesAheadOfBaseline` in `backend_routes.dart` names the two routes,
and the guard fails if a third appears **or** if one of the two turns out to be served — so the
list can only shrink, and it cannot outlive the finding.

---

## C-10 — the baseline guard's network path is dead in a no-push programme

**Severity P3. Found by TAB 00, step 1.**

`tool/check_backend_baseline.sh` fetches the backend's boundary map from
`raw.githubusercontent.com` at the pinned tag unless `TAYTAY_BACKEND` names a local clone. Run
without that variable it fails:

```
curl: (56) The requested URL returned error: 404
FAIL: could not fetch docs/architecture/domain-boundary-map.md at api-baseline-2026-08.
```

**The tag exists only locally.** `api-baseline-2026-08` was created as a local annotated tag on
`taytay-backend` and, under this programme's standing boundary, has never been pushed — so GitHub
has never heard of it and the HTTP path can never succeed. The script's own header calls the local
clone "preferred in CI"; here it is not preferred, it is **the only path that can work**.

Nothing is wrong with the check — it passes correctly with `TAYTAY_BACKEND` set, which is how it
was run in TAB 00. What is wrong is that the documented default is one that cannot work, so the
first person to run it plainly reads a 404 as a broken guard rather than a missing variable.

**CLOSED in TAB 00A.** The guard now defaults to the conventional sibling checkout, keeps
`TAYTAY_BACKEND` as an override, distinguishes "that is not a checkout" from "that checkout lacks
the tag", and — if it ever does fall through to the network — says that a 404 is the *expected*
answer for an unpushed tag rather than reporting a broken guard.

---

## Not client-owed — restated, not adopted

Unchanged by TAB 00 and re-verified against `taytay-backend@4236b51`. Detail lives in
`docs/integration/manual-tasks.md`; this is the index, so that no front-end TAB adopts one by
accident.

| Finding | Route at backend HEAD | Owner |
| --- | --- | --- |
| **F03** signing keystore custody | n/a | LGU |
| **F13** no account-closure route | **still absent** | LGU (needs the retention schedule first) + backend |
| **F15** no self-registration route | **still absent** | LGU product decision, then backend |
| **F16** codes reach nobody | seam present (`TransactionalSender`); bound to `NullTransactionalSender`, no vendor adapter exists | LGU procurement |
| **F24** no per-service intake form | **still absent** | the office that adjudicates each service |
| **F25** proxy body limit unknown | n/a — a deployment fact | whoever operates the deployment |
| **F29** no data-portability export | **still absent** | backend |
| KYC case has nowhere to put a document | **still absent** under `me/kyc` | backend |
| DPO, retention schedule, store accounts, staging, privacy policy | n/a | LGU |

**F14 and F26 are closed and leave this list.** Verified by opening the routes, not by reading a
commit message.

---

## Document divergences found, and what each was believed to be

TAB 00's fifth step. Recorded with file and line so the next reader can see which document was
trusted and why.

| # | Divergence | Resolution |
| --- | --- | --- |
| D-1 | `.claude/master-supervisor/integration/state.json` lists **F14, F16 and F26 as open P0**. F14 and F26 are closed on both sides; F16's engineering half is closed and only procurement remains. | `state.json` corrected in this TAB. The routes were opened to confirm it. |
| D-2 | `docs/integration/launch-dossier.md` strikes F14 and F26 through, and `state.json` was never updated to match — the two documents have contradicted each other since the dossier was amended. | Dossier was right. `state.json` now agrees. |
| D-3 | **`F28` names two different findings.** The dossier's F28 is "the release artifact declares four Android permissions, not two" (accepted, guarded). `manual-tasks.md`'s F28 is "a KYC case has nowhere to put a document". Two findings, one identifier, in the same repository. | Both are real. Neither is renumbered here — renumbering breaks every back-reference. The KYC-document one is listed **by description, not by number**, in the table above, and `manual-tasks.md`'s own rule ("items refer to each other by name, never by number") is the right one to extend to findings. |
| D-4 | The front-end master command's header states the backend baseline "plus the routes closed since". That phrasing is accurate but it conceals C-09 — it reads as though the pin covers those routes. | Accurate, and now qualified by C-09. |

---

## What this TAB did not establish

* **Nothing here has run against a deployed Taytay backend.** Every "present at HEAD" above was
  established by reading `taytay-backend` at `4236b51` on this machine. That repository was being
  actively modified by another session throughout this TAB, so its HEAD is a moving reference and
  is recorded as the commit observed rather than as a stable baseline.
* The 25-TAB integration sequence's own state is **preserved, not superseded**. Its verdict
  (NO-GO, platform scope) stands and is not restated as a client verdict — that is TAB 09's job.
