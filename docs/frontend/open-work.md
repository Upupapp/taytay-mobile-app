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
| **C-01** | P1 | Two upload ceilings disagree, and neither is the server's | **TAB 01 — CLOSED** |
| **C-02** | P1 | A push registration cannot be withdrawn (F27) | **TAB 02 — CLOSED, as a seam** |
| **C-03** | P1 | A registration wizard with no server counterpart (F15, client half) | **TAB 03 — CLOSED, client half** |
| **C-04** | P1 | KYC corrections keyed by category here, by field on the server (F23) | **TAB 04 — CLOSED** |
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

---

## C-01 closed — TAB 01, 19 August 2026

The client now refuses what the server refuses, using the server's own number.

* `UploadPolicy` (`lib/core/documents/upload_policy.dart`) is **the only place in
  `lib/` that states an upload ceiling or an accepted-type set.** It is decoded from the
  `accepts` block the requirements response has been carrying all along.
* Both enforcement points take it as a parameter — `DocumentCapturePolicy.inspect` when the
  file is chosen, and the repository before the body is sent. The 8 MB constant is gone.
* The system picker's extension list is **derived** from the served MIME types rather than
  hand-listed, so it cannot offer a type the upload would refuse.
* A response without a usable `accepts` falls back to **8 MB — the lower** of the two ceilings
  replaced — labelled `UploadPolicySource.fallback` and recorded as
  `client_limitation_hit / unpublished_upload_policy` telemetry, so a fallback can never later
  be read as a measurement.
* Refusal copy names both real figures in English and Filipino. The file rounds **up** and the
  ceiling rounds **down**, so a refusal can never read "that file is 10 MB and the limit is
  10 MB".

**What this does not close.** F25 stays open: the deployed proxy's `client_max_body_size` is
still unknown (manual item 6), and it is a different limit from the application's. The client no
longer guesses low against it — a guess that was refusing documents the office would have
accepted — and a body refused by the proxy still surfaces through `ApiEnvelope`'s non-JSON
non-2xx path.

---

## C-02 closed — TAB 02, 19 August 2026

**F27 was misdiagnosed, and the misdiagnosis is the finding.** The note in
`notification_api_repository.dart` read: *"There is no route that removes a registration by push
token; `me/devices` deletes by device id, which this app does not hold."* Both halves are true and
the conclusion did not follow. `DELETE me/devices/{device}` exists, it existed at the pinned
baseline, and the id was **not unavailable — it was being discarded.** `POST me/devices` answers
`{"id": …}` with 201, and the client decoded it as `(_) {}`.

What changed:

* `registerPushToken` returns the server's id instead of throwing it away.
* `StoredSession.deviceId` holds it, with **exactly the lifetime of the token that can revoke
  it** — an id outliving its token names a registration the app can no longer revoke; a token
  outliving its id leaves a registration nothing knows to revoke, which is F27 itself.
* `PushRegistrationWithdrawal` is a port in `core/session`, because `SessionController` is the only
  thing that knows a session is ending and `core/` may not import `features/` (Article 2.3). The
  notifications repository implements it; the composition root binds it after `apiClient` exists,
  which is where the cycle had to be broken.
* Withdrawal runs on **both** session-ending paths — deliberate sign-out and `401` — and **before**
  the store is cleared, because the call needs the credential the sign-out is about to discard.
  All three properties are asserted, and each was proven red.
* **Sign-out is never blocked.** A refusal is recorded on `lastWithdrawalSucceeded`; an
  implementation that throws is caught. The port says implementations must not throw and the
  controller catches anyway — a rule this important should not rest on every future implementer
  having read a doc comment.

**What this does not do, stated plainly: nothing in production calls `registerPushToken`.** There
is no push service in this build — the launch dossier recommends launching without one until a DPO
has reviewed a processor — so today there is never a registration to withdraw. This is therefore a
**seam, not a live path**: it is complete, tested and proven red, and the day push is adopted the
withdrawal is already correct instead of being remembered. That is the shape F16 took, and it is
the shape this programme keeps choosing on purpose.

**The route guard earned itself here.** `DELETE me/devices/{}` was added by this TAB, and
`backend_routes_test.dart` failed the suite until it was declared — one TAB after being built, on
the first new route anybody wrote.

---

## C-03 closed — TAB 03, 19 August 2026

**The LGU's decision was not taken, and could not have been.** Whether residents should enrol
themselves is manual-tasks item 5 and it needs the municipality, not this repository. What the
client owed was to stop being wrong in the meantime: there is no self-registration route on the
server, so a resident who downloads this app fills in seven fields and meets a dead end.

* `OnboardingMode` has exactly two values and is read from `app/bootstrap`'s
  `features.self_registration` — the same arrangement `digital_id` already uses, where **both
  states ship in one build and the server decides which one a resident sees.** The day the LGU
  answers, it costs a line of configuration rather than a store release.
* **Default is staff-mediated**, including before the bootstrap has answered and if it never
  answers. A default that describes the platform is the safe one; a default that describes an
  intention is a bug waiting for the intention to change. The backend publishes no such flag
  today, which is correct — it has no route behind it.
* **The wizard is kept**, and made unreachable **in the route guard** rather than by hiding a
  button. A screen that hides its own entrance is still reachable by deep link, by the back stack
  and by the two other places in this app that navigate to it. `/register` resolves to sign-in,
  which is the honest next step.
* The staff-mediated entry is **a panel, not a disabled control**: what the office does, what to
  bring, and the office's own contact details **taken from the server**, because a phone number
  compiled into a released app is one the municipality cannot correct without a store submission.
  Both languages; both modes asserted by widget test.
* `registrationRepository` **stays stubbed** and its ledger entry now names this TAB. The stub
  count is still 1. TAB 03 built the seam around it and deliberately did not wire it.

**No identity-assurance step was invented.** No document capture, no selfie, no verification added
to the wizard on the theory that it will be wanted — that is the LGU's policy, and writing it here
would be inventing a rule the office never agreed to.

---

## C-04 closed — TAB 04, 19 August 2026

F23 was recorded as needing "a decision rather than code — either this app models corrections per
field, or the server accepts a KYC-shaped one". **The first was always available**, and it is what
TAB 04 built. No server change.

* `CorrectableField` models the server's **twelve** fields, read from
  `Modules\ResidentProfile\Contracts\CorrectableField` at the pinned baseline rather than
  inferred from the category names.
* Categories now carry a **list** of fields, not an optional single one. The old shape made "one
  field" the normal case and "several" the exception; it is the other way round, and every
  correctable category spans more than one.
* **The resident is asked which detail.** `address` is a barangay, a street *and* a purok — the old
  code silently sent `street_address`, so a resident correcting their barangay filed a street
  correction the office would read, find nothing wrong with, and close.
* **A document is refused before the input, not after the typing.** `identityDocument` and `photo`
  map to no profile field; the screen says so where the text box used to be. A refusal that arrives
  after the form is a refusal disguised as a form.
* Changing the chosen detail **drops the text typed against the old one**, so nothing is re-filed
  against a field the resident no longer means.
* Twelve field labels in English and Filipino — the server's own names are operator-facing and no
  resident has seen `purok_or_sitio`.

**Two guards, both directions each.** `tool/check_correctable_fields.sh` fails on a field this app
invents (the server refuses the whole request on an unknown key) **and** on a field the server
accepts that no category offers — a correction nobody can ask for, which nothing would otherwise
report. `test/features/correctable_field_test.dart` holds coverage inside the app. All proven red.

The vendored contract could not be used for this: it publishes the path and no request schema
(backend finding L-11), so the guard reads the backend clone like the route check does.

