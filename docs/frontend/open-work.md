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
| **C-05** | P2 | The client overrides the page size the server published for this channel | **TAB 05 — CLOSED** |
| **C-06** | P1 | "One refresh is one sign-out" is decided but never proven under concurrency (F22) | **TAB 06 — CLOSED, and it was not holding** |
| **C-07** | P1 | No TalkBack or VoiceOver session has ever been run | **TAB 07 — PARTIAL; still no screen reader** |
| **C-08** | P1 | No physical device run; no iOS run of any kind | **TAB 08 — PARTIAL; iOS runs, Android has never run** |
| **C-09** | **P1** | The app calls **four** routes that do not exist at its own pinned baseline | **detected and guarded; resolution still blocked** |
| **C-10** | P3 | The baseline guard's network path cannot work in this programme | **TAB 00A — CLOSED** |
| **C-11** | **P1** | The verification correction flow cannot render against the real backend | **CLOSED — the app now reads what the server sends** |
| **C-12** | P2 | Three privacy-critical decoders, ~29 tests, and no production caller | **CLOSED — all three deleted, assurance moved onto the real decoders** |
| **C-13** | **P1** | The app told residents only the LGU could change a field the office lets them edit | **CLOSED** |

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

---

## C-05 closed — TAB 05, 19 August 2026

The finding said the client sent 25 where the server published 15. **It was worse than that.**

| | before | after |
| --- | --- | --- |
| declared defaults in `lib/` | **3** — `PageMeta`, `ProgramApiRepository`, `ServiceCatalogApiRepository` | 1, in `PagePolicy` |
| distinct values actually sent | **20 and 25**, depending on the screen | whatever the server publishes |
| inline ceilings (`clamp(1, 100)`) | **5** | 0 |

Nothing was broken, which is exactly why it was worth closing: three copies of a default agree
until one of them is edited, and no reader could have told which screen sent which number.

* `PagePolicy` holds the size and the contract's ceiling, and is **read** from
  `app/bootstrap`'s `client.default_page_size` — the per-channel value the server chose.
* It lives on `ApiClient` because every paged call already holds one, and because it is
  channel-level contract state of the same kind as the base URL — not because the transport
  decides it. `PlatformController` publishes it through a callback, so it still knows nothing
  about transport.
* **Clamped, not trusted.** An absurd value is brought into range rather than rejected, and
  `wasClamped` says it happened so the result is never read as the server's choice.
* **The fallback stays 25, not 15.** An app that quietly halved its page size on every screen the
  moment a fallback engaged would look like a performance regression with no cause anybody could
  find. Labelled `PagePolicySource.fallback` and recorded as
  `client_limitation_hit / unpublished_page_size`.
* **One deliberate exception, and it is argued in place**: the barangay directory asks for
  `PagePolicy.maxPerPage`, because a partial list of barangays is not a shorter list — it is an
  address a resident cannot select. It still goes through the policy so it cannot exceed what the
  server will serve.

An existing guard asserted each paged repository contained `clamp(`. It now asserts
`pages.clampRequest(` **and** the absence of `clamp(1, 100)` — a stronger statement, because the
old one would have passed a repository that clamped to a ceiling of its own.

**One red-proof in this TAB proved nothing and was redone.** It pointed at
`test/core/startup_test.dart`, which does not exist; the run "failed" on a missing file and looked
like a guard firing. Recorded because it is the exact failure this programme keeps finding — a
check that appears to work and is measuring nothing.

---

## C-06 closed — TAB 06, 19 August 2026

**The decision was recorded and the behaviour was not there.** Writing the concurrency test first
is what found it.

`SessionController.handleUnauthenticated` carried a doc comment reading *"Idempotent: several
in-flight requests can fail at once, and the resident should be told the session expired exactly
once."* That had been true — the body was synchronous up to `_set`, and `_set` collapses a repeated
state — and **TAB 02 ended it two hours earlier** by putting an `await` in front of it: the push
withdrawal.

Measured before the fix: **ten concurrent 401s produced ten teardowns.** The resident was still told
once, because the state still only changed once, so nothing visible was wrong. What actually
happened was **nine extra `DELETE me/devices` calls carrying a credential the server had just
refused**, on the connection of somebody whose session had died mid-screen. An expiry racing a
deliberate sign-out produced two.

* One `_endSession`, shared by both paths, single-flighted on an in-flight future rather than on a
  flag — a flag read before an `await` is a flag two callers read before either writes it.
* **The first reason wins** when an expiry races a sign-out. Neither is wrong, and inventing a
  precedence rule would mean claiming to know which the resident experienced.
* Clearing in `whenComplete`, so a teardown that fails cannot wedge the controller into a state
  where no session can ever end again.

**The sheet was making a promise the app cannot keep.** It said *"Nothing you submitted has been
lost."* Narrowly true and read as something else entirely — a resident does not separate what they
*submitted* from what they *typed*, and this app queues nothing (`DL-118`), so work not yet sent
when a session dies is gone. It now says what is true: what was sent is with the office, what was
not is not kept. That is `DL-87`'s rule about failed sends, applied to the moment a session ends.

Three notices, now localised and asserted distinct: expiry, deliberate sign-out, network failure.
Seven session-ending strings in both locales.

**No refresh was built, and a guard now says so.** There is no refresh endpoint at the pinned
baseline; the composition root registers no `TokenRefresher`, and a source-level test fails if one
appears — a behavioural test would pass just as well against a build that had quietly acquired one,
which is the change worth catching.

---

## C-07 — TAB 07, 19 August 2026: **PARTIAL, and the partiality is the point**

**No screen reader was run, and none could be.** No physical device has ever been attached to this
programme; no Android emulator image is installed; and **VoiceOver does not run on the iOS
Simulator**, which is the only runtime this machine has. `docs/frontend/accessibility-session.md`
records the whole of it, criterion by criterion.

What was delivered is the half a machine can prove — the semantics tree a screen reader reads:

* `labeledTapTargetGuideline`, `androidTapTargetGuideline` and `iOSTapTargetGuideline` across
  **11 routes × 3 access levels × 2 languages**, plus `/verification`. All pass. Both directions
  proven with planted defects.

**Two findings, and neither is a pass.**

**`textContrastGuideline` cannot judge this app.** It samples pixels; the primary buttons are a
brand gradient with white text, so the sample is nearly all fill and it called a 4.5:1 button
**1.06:1** — naming `#0B3D91`, which is `BrandColors.taytayBlue` exactly. It was dropped and
contrast was **not** weakened: `BrandGradient.worstCaseContrastRatio()` already proves the declared
foreground across the whole ramp including interpolated midpoints, which is stronger than sampling.

**This audit had a hole on its first draft.** The tap-target and Filipino sweeps ran only at
`verified`, and `resolveRedirect` moves a signed-in resident off `/sign-in` — so those routes booted,
redirected, and passed without rendering. A deliberately undersized button planted on the sign-in
screen **went undetected**. Fixed by running every level; re-planted to confirm it is caught now.

That is the **second** check in this sequence that appeared to work and measured nothing (the first
was a TAB 05 red-proof pointing at a file that does not exist). Recorded both times, because the
pattern is the finding.

**The single most valuable next step is one hour with a real Android phone and TalkBack, in
Filipino**, walking sign-in → home → KYC claim → upload. It answers most of the deferred table and
cannot be answered from here.

---

## C-08 — TAB 08, 19 August 2026: **PARTIAL**

**The app ran on an Apple runtime for the first time in this programme's history.** Built on a
Windows host through twenty-eight TABs, established as *compiling* for iOS during the integration
sequence — and never launched. On 19 August it was installed on an iPhone 17 simulator and rendered
its first screen correctly: brand blue, notch cleared, the `DEV` banner Article 7 requires, white
text on the brand-blue button.

That last detail settles TAB 07's contrast finding **by eye**: the button is white on blue, and
`textContrastGuideline`'s 1.06:1 really was the sampler weighing fill against fill.

`integration_test/device_journey_test.dart` is the first thing here to drive the app on a real
engine rather than a fake window — cold start to a readable frame, past the welcome scenes via
**Skip** (the escape nobody exercises by hand), and every shell destination in turn against an
unreachable API, so what is exercised is each screen's own empty and error state. Given F15 and
F16 that is **every journey a resident can complete today**: no account can be created and no code
is dispatched, so there is no authenticated journey to walk.

`integration_test` was added as a dev dependency with a stated reason (Article 1): it ships with the
Flutter SDK, adds nothing to a release artifact, and touches no identity, storage, networking or
crypto surface.

**Correction, made in TAB 09 before the gate: "neither could be run" was wrong.** `flutter
emulators` reports "unable to find any emulator sources", and that means *no AVD is configured*, not
*Android cannot run here*. Android Studio was installed the whole time, `sdkmanager` and
`avdmanager` were on disk, and `system-images;android-24;default;arm64-v8a` was one download away —
`minSdk = 24` exactly, and arm64, so it runs natively rather than under emulation.

The image was installed (4.2 GB), an AVD created, and **Android 7.0 / API 24 / arm64-v8a booted and
visible to Flutter**. It is the first time this app has run on Android in twenty-eight build TABs,
twenty-five integration TABs and eight TABs of this sequence.

**This is the fourth time in this sequence a tool said something true and I heard something
stronger** — after a red-proof pointing at a file that does not exist (TAB 05), an audit passing by
redirection (TAB 07), and a cold-start figure that was really `pumpAndSettle` timing out (TAB 08).
Recorded in place rather than quietly corrected, because four instances is a pattern and not a run
of bad luck.

An emulator is still not a handset: no thermals, no real camera, no network transitions, no screen
reader. And the row reading "Android, at any version" only **half** closes.

**Android builds, installs, launches and renders at API 24. Android journeys did not run.** The
driven walk was killed after 74 minutes having never left the onboarding screen, and a bounded
probe — an `integration_test` containing one `Text` widget — hung for twelve hours on a test that
cannot fail. That rules the app out of the diagnosis: **`integration_test` does not complete against
an emulated arm64 API 24 image on this machine**, while the same harness and the same file pass on
the iOS Simulator in ninety seconds.

A physical handset over `adb` would settle it in minutes and remains the thing worth an hour of
somebody's time.

**No performance figure here is a pass.** The budgets say each target needs a low-end device; an
iPhone 17 simulator on an Apple-silicon Mac is the opposite of one. Cold start is **reported and not
compared**, because comparing it would turn an untested claim into a green tick. The budgets stay
unmet in the honest sense: nothing has been measured on a device that could fail them.

The signing guardrail was re-verified rather than assumed: `key.properties` is absent and the
release build refuses instead of falling back to the debug key.

`docs/frontend/device-matrix.md` carries the per-criterion simulator-versus-device split. Nothing in
its right-hand column is claimed anywhere in this repository.

**Also corrected here:** `docs/integration/performance-budgets.md` still said "a feed page is 25
rows". TAB 05 made the page size the server's — 15 at the pinned baseline. Fixed rather than left
as a document contradicting the code.

---

## C-09 grew to four, and the guard earned itself twice on one day — 2026-08-27

The pre-push sweep ran the route guard and it went **red**. Both failures are worth recording,
because only one of them was real.

### The real one: two more routes ahead of the baseline

F28's client half — an applicant sending their identity document — calls `GET me/kyc/documents` and
`POST me/kyc/documents`. Verified both ways: **absent at `eec71e6`, present at backend HEAD**, added
on 24 August. Same condition as `GET barangays` and the comment-report route.

The ratchet refused the push until it was argued and written down, which is what an equality
assertion rather than a ceiling is for. **C-09 is now four routes**, and four is a different
statement from two: this app's baseline has been stale for a fortnight while both sides kept
building. The resolution is unchanged — move the pin.

### The false one: my own guard, defeated by a formatter

The guard also reported `POST newsfeed-comments/{}/reports` as an exception the baseline now
serves. **It does not.** `dart format` had wrapped the longer `BackendRoute(...)` constructors
across lines, and the guard's line-oriented extractor saw **37 of 53** declarations — so a declared
route looked undeclared, and the "stale exception" branch fired.

Two defects in one, and both mine:

* the extractor was line-oriented against a file a formatter owns;
* the failure message named only one of the two conditions that reach it — "the baseline DOES
  serve" — when "the app no longer declares it" reaches the same branch. It described the wrong
  cause with total confidence.

Fixed by squeezing newlines before matching, and by adding an assertion that the parser sees every
`BackendRoute(` in the file. That assertion was proven red: with the fix reverted it reports
`the manifest parser sees 37 of 52`. It would have caught the original bug on the day it appeared.

**This is the fifth instance of the sequence's own pattern, and the first inside code written to
prevent it.** A guard built to catch drift was silently defeated by a reformat, and reported a
cause that was not the cause. The lesson holds and now has a sharper edge: *a passing check is not
evidence until somebody has watched it fail* — and a **failing** check is not a diagnosis until
somebody has checked which branch produced it.

---

## C-11 — the correction flow cannot appear for a real resident (sweep, 2026-08-27)

**Three decoders, three different contracts, and only one of them exists.**

| | reads | |
| --- | --- | --- |
| **Server**, `GET me/kyc` → `applicantProjection` | `id`, `status`, `can_edit`, `submitted_at`, `message`, `claimed{}`, `resident_id`, `documents` | what is actually sent |
| **Production**, `KycApiRepository._decodeStatus` | `status`, `message` — **2 of 8** | drops `submitted_at`, `can_edit`, `documents` |
| **`VerificationStatusDto.fromJson`** — 145 lines, 12 tests | `state`, `issues`, `submitted_categories`, `resident_guidance`, `manual_review_available`, `submitted_at` | **the server sends none of these names** |

`loadOwnStatusDetail` builds a `VerificationStatusDetail` from **three** fields — stage, rawState,
residentGuidance — and never populates `issues`, `submittedCategories`, `manualReviewAvailable` or
`submittedAt`.

`verification_screen.dart:446` renders *"N things to fix"* from `status.issues`, and every input in
the correction section is built by iterating it. **`issues` is empty in production and the backend
has no `issues` key anywhere**, so that section renders for nobody.

**This is recorded against TAB 04's own work.** That TAB rebuilt the category→field keying for this
exact flow — modelled the server's twelve correctable fields, made the resident choose which detail,
refused documents before the input, added two guards and proved them red. All of it correct, and all
of it on a screen that cannot appear against the real backend. The mapping was traced meticulously;
where `issues` came from was never traced at all.

**It needs a decision, not a patch.** Either the backend publishes an `issues` projection for the
applicant — which is a real product question about how a reviewer's findings reach a resident — or
the correction UI comes out and the app tells a returned applicant to visit the office. Both are
defensible; neither is the client's to take alone.

**Until then the flow is dead, not broken.** Nothing misleads a resident today, because nothing
renders. That is the only reason this is P1 and not P0.

## C-12 — 403 lines of privacy decoder that nothing calls

`VerificationStatusDto` (145 lines, 12 test references), `ResidentProfileDto` (123, 8) and
`HouseholdDto` (135, 9) are **imported by no production file**. Each repository decodes inline with
its own private `_decode` static instead.

Their doc comments describe them as the privacy control — allow-list decoders whose tests feed
hostile payloads carrying `reviewed_by`, `risk_score`, `internal_notes`, `audit_trail` and another
resident's record, and assert none survives.

**Those ~29 tests certify a control the app does not use.** The production decoders were checked
during this sweep and are *also* allow-list — `_decodeStatus` names two keys and takes nothing else
— so **no leak is being claimed here**. What is claimed is that the assurance and the code have
come apart: the tests prove a property of a file, and the file is not on any path a resident's data
travels.

Same class as C-11 and found by the same scan. Closing it is a choice between adopting the DTOs in
the repositories or deleting them and moving their hostile-payload tests onto the private decoders —
the second is smaller and keeps the assurance where the data actually flows.

## Method note — the scan that found these was wrong twice first

The connectivity scan reported `app_lock_screen.dart` and `unwired_repository.dart` as orphans.
Both are false: the first is mounted by `taytay_resident_app.dart:162` rather than routed, and the
second **is** imported — the scan's import resolver missed it.

Both were caught by re-checking with an independent method before anything was reported. Recorded
because it is the same pattern this sequence has now hit six times, and because a stitch audit that
reports orphans without verifying them produces exactly the confident wrong answer it exists to
prevent.

---

## C-11 closed — and the defect was sharper than the finding

The finding said the correction flow could not render. True, and the more consequential half was
next to it: **`loadOwnStatusDetail` read three fields off an eight-field projection and dropped the
rest.**

* **`can_edit` is now read.** The office computes it from the case status
  (`KycStatus::isEditableByApplicant()`); this app inferred the same thing from its own reading of
  the stage and ignored the server's answer. `isEditableByApplicant` prefers the server and falls
  back to the inference **only when the field is absent**, so a response that does not carry it
  behaves exactly as before rather than locking a resident out of an open case.
* **`submitted_at` is now read.** That is why *"Sent on …"* never appeared for anybody — the screen
  had always known how to render it.
* `id`, `resident_id` and `claimed` are named in the decoder as deliberately not carried, so they
  read as considered rather than missed. `documents` is left to the endpoint that owns it, because
  taking it from two places gives the screen two answers the moment one goes stale.
* The document-upload affordance now gates on `status.isEditableByApplicant` rather than on the
  stage — a resident offered an upload the server will refuse has been invited to waste their data.

**Same class as the upload ceiling and the page size: a value the server publishes, derived locally
rather than read.** Third time this sequence has found it.

The `issues` question itself is untouched and stays with the backend: whether a reviewer's findings
reach a resident in-app is a product decision, and the flow remains dead rather than wrong.

## C-12 partial — and the three DTOs turned out not to be one case

Porting the first changed what was known about the other two, so they were **not** treated alike.

| DTO | Verdict | State |
| --- | --- | --- |
| `VerificationStatusDto` | **Fiction.** Read `state`, `in_progress`, `under_review`, `verified`. The server's `KycStatus` sends `draft`, `submitted`, `screening`, `manual-review`, `needs-more-information`, `approved`, `rejected`, `withdrawn`, `expired` — and **production's `VerificationAttemptState.parse` matches that list exactly**. | **Deleted**, its hostile-payload tests re-pointed at the repository |
| `HouseholdDto` | **Partly fiction** — reads `label`, `barangay`, `role`; the server sends `name`, `barangay_id`, `is_head`/`relationship_to_me`. **2 of 5 keys exist.** Also carries an `encodeCorrection` path with no production equivalent. | **Left in place** |
| `ResidentProfileDto` | **Unproven.** Its visible key constant (`verification_tier`) is one production also reads. | **Left in place** |

**The port caught me being wrong, and that is the strongest evidence in this entry.** The new
state-mapping assertions were written from the DTO's vocabulary; they failed, and the backend's own
enum settled it — production right, DTO fiction. A decoder whose tests certify an imagined API is
worse than no decoder, because the tests read as assurance.

The remaining two are **not** deleted in this pass. Porting the first revealed a contract mismatch
that needed care; `HouseholdDto` carries an encode path as well as a decode one; and rushing two
more on a pattern that has already surprised me once would be the seventh instance of this
sequence's own failure mode rather than a tidy finish.

**What is proven and should be believed:** no leak. The production decoders for all three surfaces
were read during this sweep and every one names its keys and walks past the rest.

---

## C-13 closed — a wrong statement about a resident's own rights

Found while establishing the profile contract for C-12, and the worst of the three because **it was
live on a screen that renders today**, unlike C-11's dead flow.

`GET me/profile` publishes `editable_fields` from `CorrectableField::selfServiceValues()`, and the
server's own comment says it is *"told explicitly rather than left for the client to infer from
which fields happen to be editable — an inference every client would implement slightly
differently."* **This app inferred it anyway**, from a `FieldOwnership` hardcoded into
`ResidentProfileField`, and named neither published field anywhere except a comment.

| Field | Server `isSelfService()` | App's declaration | |
| --- | --- | --- | --- |
| `mobile_number` | self-service | `accountOwned` | agrees |
| `email` | self-service | `accountOwned` | agrees |
| **`street_address`** | **self-service** | **`lguVerified`** | **wrong** |
| **`purok_or_sitio`** | **self-service** | **absent from the app entirely** | **wrong** |

So the profile screen told a resident *"Taytay LGU checked these against your documents. They decide
what you are entitled to, so only the LGU can change them"* about their own street address — which
the office lets them change themselves. That is not a cosmetic mismatch; it is the app misinforming
somebody about what they are allowed to do with their own record.

**Fixed by reading the list.** `ResidentProfileDetail.selfServiceFields` carries what the server
published; `ownershipOf` prefers it and falls back to the declaration only when the field is absent,
so an older response behaves exactly as before. An empty or malformed list stays **null** rather
than becoming an empty set — "the resident may change nothing" is the wrong way to fail. Both
surfaces follow it: the profile grouping and the contact editor's field list.

**Fourth instance of one pattern, and the clearest.** The upload ceiling (TAB 01), the page size
(TAB 05), `can_edit` (C-11) and now `editable_fields` — every time, a value the server publishes,
derived locally instead. Three of the four were found by reading the server rather than by any test
failing.

**And it lands on TAB 04.** That TAB hardcoded the twelve correctable fields into `CorrectableField`
and built `tool/check_correctable_fields.sh` — a guard requiring a local backend clone — to keep the
copy in sync. The list is on the wire. The guard exists because the app does not read it.

`purok_or_sitio` is **not** added here: the app has no label, hint or section for it, and inventing
those is a content decision rather than a decode fix. Recorded as open — a resident currently cannot
see or correct part of their own address.

---

## `purok_or_sitio` added, and an authorization rule corrected — 2026-08-28

Recorded as its own entry because what looked like adding a missing field turned into a conflict
between two rules, and the server settled it.

**The conflict.** This app holds a rule — *every eligibility-bearing field belongs to the LGU* —
with a sound reason: a resident who could edit their own birth date could grant themselves a senior
citizen benefit. It marked `street_address` eligibility-bearing. The server marks `street_address`
**self-service**.

**The server's own split resolves it.** `CorrectableField::isSelfService()` returns
`street_address`, `purok_or_sitio`, `mobile_number` and `email` — and **not** `barangay_id`. The
office distinguishes *which barangay serves you* from *where in it you live*. This app conflated the
two and put the eligibility flag on the wrong one.

So the rule keeps its teeth and the field wearing the flag wrongly was corrected. Birth date, sex,
civil status and **barangay** stay LGU-owned and eligibility-bearing — barangay is the case the rule
exists for, and it must never gain a control on the contact editor.

**The editable set is four because the office says four.** Changed across four layers: the field
enum, `ContactDetailsUpdate`, the repository's change map, and the editor's controls. The
declaration was corrected as well as the runtime read, so the **fallback** is right too — a response
that stops publishing `editable_fields` must not reintroduce the wrong sentence.

**A false comment found on the way.** The editor's field switch claimed *"adding an account-owned
field is a compile error until it has a control"*. The `_ =>` catch-all meant it never was: a new
editable field would have rendered as an **empty row**. Replaced with a test that asserts what the
comment described. Same shape as TAB 06's `Idempotent`, which was also false when checked.

## Still open

* **`check_correctable_fields.sh`'s future.** It can no longer catch "you will send a field the
  server refuses" — the runtime read does that. It can still catch "the office offers a field this
  build has no label for", which is exactly the `purok_or_sitio` gap. Owner decision.
* ~~**The profile field labels are not localised.**~~ **CLOSED 2026-08-28** — see below.

---

## The profile surface now speaks Filipino — 2026-08-28

`ResidentProfileField` carried English labels and hints as enum constants and the screens rendered
them directly, so **the one surface where a resident reads their own government record stayed in
English while the rest of the app translated.** In a municipality where Filipino is the language the
service is actually for, that is not a polish item.

21 keys in both locales: nine field labels, seven hints, both section headings and their
explanations, and the "(optional)" suffix. Every render on both profile screens goes through the
localiser — a grep for hardcoded copy on those surfaces returns nothing. The enum keeps its English
as the no-context fallback, the arrangement `AppFailure.residentMessage` already uses.

Guards, both proven red: a screen reverted to the enum's English, and one Filipino key deleted.

### A live bug, already caught, that I had explained away

The `purok_or_sitio` control's label was the literal string `${field.label} (optional)` — an escape
that survived an edit earlier the same evening, so the field rendered a raw Dart expression as its
label.

**It had already been caught.** `find.textContaining('Purok or sitio')` found nothing, and I read
that as *"the field is below the fold in a lazily-built ListView"*, removed the assertion, and moved
on. The finder was right, the diagnosis was wrong, and deleting the assertion deleted the evidence.

The assertion is restored with that history written into it. **This is the seventh instance of this
sequence's pattern and the first where a working check was actively removed** — the others were
checks that never worked. A failing assertion is a fact; the explanation for it is a hypothesis, and
they should not be given the same weight.

## Still open

* **`check_correctable_fields.sh`'s future** — owner decision, unchanged.
* **Other enums may carry the same untranslated copy.** `KycDocumentType`,
  `HouseholdCorrectionKind` and `VerificationItemCategory` all hold `label` constants.
  `ResidentProfileField` was fixed because it was the surface in hand, not because it was shown to
  be the only one. **Not yet swept.**

---

## The copy sweep — what it measured, and what it missed — 2026-08-28

Started as "localise the profile labels" and turned into three findings, two of them about my own
scanning rather than about the app.

**Localised in this pass:** the profile surface (21 keys), the verification surface (20 keys,
including the screen's **headline** — the sentence by which somebody learns whether they can hold a
digital ID), and the assistance-intake validation messages (11 keys).

**A guard now classifies every enum carrying resident-facing copy** —
`test/core/resident_copy_localisation_test.dart`. Eighteen of them: **6 localised, 4 argued as
never rendered, 8 recorded as untranslated debt on a ceiling that only shrinks.** A new enum with
copy fails the suite until somebody says which it is.

It is a **coverage** guard rather than a render-site scan, and the reason is written into it: a
`.label` scan cannot be honest without type information, and the ad-hoc version written during this
sweep reported every enum as rendered in thirty files. That result was discarded rather than acted
on.

### Two corrections to my own record

**The guard's first two entries were wrong.** `ConsentKind` was recorded as reaching
`event_registration_controller.dart`. It does not — that code operates on `ServerConsent`, whose
label comes from the server. And both `ConsentKind` and `RegistrationStep` render only in the
registration wizard, which **TAB 03 made unreachable**. I was one command from spending a TAB
translating a screen no resident can open, which is precisely the mistake TAB 04 made on the
correction flow and which this ledger criticises at length.

Caught by checking the type before editing. The corrections are kept in the guard rather than
edited out.

**The guard measures one class of the problem and I reported its number as the whole.** There are
**21 hardcoded English sentences in domain and controller code** — validation messages, not enum
copy — and no enum-based guard can see them. `assistance_intake_validation.dart` was live and
untranslated on the screen a resident uses to ask for help; it is fixed. The rest are not yet
audited.

### The design the validation fix needed

`FieldError.message` is a mixed carrier: some of it this app's prose, the rest the server's
validation text, which Article 5.5 deliberately allows through. That mix is *why* the client half
stayed English — a localiser cannot translate a `String` without knowing which half it came from.

So the client half now carries a `ValidationMessage` kind, with `subject` and `limit` held
separately rather than baked into the sentence, so a translation can place them where its own
grammar wants them. A `FieldError` with a kind is this app's and is translated; one without is the
server's and is shown as sent.

### The 4 "not resident-facing" claims — checked, and 3 were wrong (2026-08-28)

The line below predicted this was the likeliest place the guard was wrong. It was, and by a wider
margin than the prediction: **three of the four claims were false, and the fourth was right for the
wrong reason.**

| Enum | Claim | Truth |
|---|---|---|
| `ResidentCapability` | "the gate sheet composes the sentence" | **Wrong.** `capability_gate.dart:111` → `StatusView(title:)`, rendered at `titleMedium`, on **12 mounted screens**. |
| `ResidentIntentKind` | "diagnostic, never rendered" | **Wrong.** Interpolated into both gate sheets, `access_gate_sheet.dart:147` and `:190`. |
| `DocumentSource` | "the picker sheet composes its own copy" | **Wrong.** `requirements_screen.dart:478` → `AppButton(label:)`. The field's own comment reads *"Resident-facing action label"*. |
| `ServiceCategoryIcon` | "the label picks a glyph" | **Right conclusion, wrong reason.** `.icon` picks the glyph; `.label` is the screen-reader name. It is unrendered only because `FeatureIcon` has **no production caller at all**. |

So the single largest heading on every gated screen in the app was English on a Filipino device,
and the guard written to catch exactly that was asserting it could not happen.

**Every one of the four was written by reading the enum's doc comment instead of following the
value to a widget.** Two of them contradicted a comment sitting one line away in the same file.
Reading tells you what a name suggests; only tracing tells you where a string lands. This is the
same failure as the `ConsentKind` entry above, and it is now the third time in this programme.

**What changed as a result:**

* All three now have localisers — `capabilityLabel`, `gateSignInMessage` / `gateVerificationMessage`,
  `documentSourceLabel` — and 32 new keys in both `.arb` files.
* The gate sentences moved from **fragment substitution to whole sentences**. Translating
  `intent.description` alone would not have worked: Filipino needs `mag-apply` after *para* and
  `makapag-apply` after *bago ka*, so one fragment cannot serve both frames.
* **`test/core/gate_copy_render_test.dart` is new**, and is the real lesson. A coverage guard can
  only catch an enum nobody *classified*; it is structurally blind to one classified **wrongly**.
  The new file pumps the widgets in Filipino and reads what comes out. `CapabilityGate` — on 12
  screens — had **no test of any kind** before it, which is how this survived.
* **The guard was lying about itself.** `every enum called localised actually has a localiser` was
  `locales.contains(name)` — satisfied by an import line. Renaming `capabilityLabel` away left it
  green. It now requires a real signature. Found only by red-proofing; the check had passed every
  run since it was written.

## Still open

* **6 enums untranslated** (down from 8), two more gated behind TAB 03 and therefore not urgent.
* **`ServiceCategoryIcon` / `FeatureIcon` is built and never mounted** — a defect in its own right,
  not just a localisation question.
* **~20 hardcoded English literals on the access-gate screens** — `CapabilityService.explain`,
  `requirementLabel`, and the sheet's own titles and buttons. These sit on the very screens just
  fixed, and no enum-based guard can see them.
* **The other 20 hardcoded validation sentences** — not audited for reachability.
* **The guard cannot see hardcoded sentences at all.** Extending it is the honest next step.

