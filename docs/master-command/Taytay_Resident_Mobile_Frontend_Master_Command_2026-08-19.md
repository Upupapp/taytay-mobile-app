# Taytay Resident Mobile — Front-End Master Command

**Ten commands that close everything still owed by the Flutter client, and nothing that is owed by anybody else.**

| | |
| --- | --- |
| Repository | `/Users/user/development/taytay-mobile-app` — `Upupapp/taytay-mobile-app`, Flutter/Dart, `citizen-mobile` channel |
| Baseline | HEAD `bc9cdb5`, branch `main`, working tree clean, **61 commits ahead of `origin/main` and never pushed** |
| Measured | `flutter analyze` **clean** · `flutter test` **1,386 passing, 1 skipped** · **16 repositories wired, 1 stubbed** |
| Backend baseline | `api-baseline-2026-08` = `eec71e6` on `taytay-backend`, plus the routes closed since (`barangays`, `newsfeed-comments/{comment}/reports`, code dispatch) |
| Sweep date | 19 August 2026 |
| Basis | Direct measurement of this repository and of `taytay-backend` at HEAD |
| Boundary | Local commits only. No push, no remote administration, no deployment, no production. |

---

## Scope: this command is the client and only the client

The 25-TAB backend-integration sequence closed at **NO-GO**, and the four P0s it named have moved.
Three are no longer what they were: **F14 is closed on both sides**, **F26 is closed on both
sides**, and **F16's engineering half is closed** — what remains of it is an SMS contract. The
launch dossier records the first two struck through; `.claude/master-supervisor/integration/state.json`
still lists all four as open P0 and is stale. TAB 00 reconciles that.

What is left divides cleanly, and this document takes only the first half:

* **The client owes work** — a real defect in the upload path, a registration that cannot be
  withdrawn, an onboarding entry point that leads nowhere, a correction payload keyed differently
  from the server's, a page size that overrides the server's, and a body of verification that has
  never been run on a real device or with a screen reader. **These ten commands.**
* **Somebody else owes work** — an SMS provider, a DPO, a retention schedule, signing keys, store
  accounts, a staging environment, a self-registration policy, a per-service intake form, and the
  deployment's real body limit. Those live in `docs/integration/manual-tasks.md` and **must not be
  attempted here.** No command below waits on one; where a decision is missing, the command builds
  the seam so the decision later costs a line of configuration instead of a sprint. That is the
  shape F16 took, and it is the pattern to repeat.

**Nothing in this document changes `taytay-backend`.** A command that appears to need a server
change has been written wrong, or the change belongs on the other repository's list — stop and
say so rather than reaching across.

Prepared for sequential execution. Each command states its own preconditions, its scope boundary,
its acceptance criteria and the evidence it must leave behind. Commands are ordered so that no
command depends on a decision a later command makes.

---

## TAB 00 · FOUNDATION
### Re-baseline, and reconcile what the documents still claim

**OWNER** This repository
**OBJECTIVE** One measured statement of where the client actually is, and every status document
agreeing with it.
**WHY NOW** The programme's own lesson, recorded as a dissent in the launch dossier: *a status
document is not evidence, including the one that told me what I could not do.* Three of the four
blocking P0s have moved since the dossier was written and the supervisor state has not noticed.
Starting a new sequence on top of a stale finding list reproduces exactly the failure the last one
ended by confessing.

**PRECONDITIONS** None. This is the first command.

**DO**

1. **Re-measure, do not quote.** `flutter analyze`, `flutter test`, the wiring detector's stub
   count, and `tool/check_backend_baseline.sh`. Record the figures produced by the run, never the
   figures in this header — if they disagree, this header is wrong and the run is right.
2. **Reconcile the finding ledger against the backend at HEAD.** For every finding still marked
   open, establish by inspection of `taytay-backend` whether its route now exists. F14, F16 and F26
   are known to have moved; assume nothing about the rest.
3. **Update `.claude/master-supervisor/integration/state.json`** so `openFindings` states the
   measured truth, and add a note recording that the 25-TAB sequence is closed and this sequence
   has begun. Preserve the old state rather than overwriting its history.
4. **Split the residual list in two** — client-owed and other-owed — and put the client-owed half
   at `docs/frontend/open-work.md` as the working ledger for TABs 01–09. `manual-tasks.md` keeps
   the other half and does not grow.
5. **Record the divergence between documents** wherever one was found, with the file and line, so
   the next reader can see which document was believed and why.

**GUARDRAILS**
Never mark a finding closed because a commit message says so. Open the route.
Never delete a superseded status document; supersede it in place with a dated note.
No production, no deployment, no push.

**ACCEPTANCE**
A single table of client-owed work, every row traceable to a file and line in one of the two
repositories.
`state.json` and the launch dossier no longer contradict each other on any finding.

**EVIDENCE** Measurement transcript · the reconciliation table with per-row evidence · the diff to
`state.json`.

---

## TAB 01 · DEFECT
### One upload ceiling, and it is the server's

**OWNER** This repository
**STANDARDS** RA 10173 (data minimisation on what is captured), the server's published `accepts`
**OBJECTIVE** The client refuses exactly what the server would refuse, using the number the server
publishes, and says so in words a resident can act on.

**WHY NOW** **There are two ceilings in this app and they disagree.**

| Where | Value | Enforced |
| --- | --- | --- |
| `lib/core/documents/document_capture.dart:134` | **10 MB** | when the file is chosen |
| `lib/features/requirements/data/requirement_api_repository.dart:61` | **8 MB** | after downscaling, at send |

A resident who picks a 9 MB PDF passes the capture check, watches the app prepare the upload, and
is then refused by the repository. A PDF is not downscaled, so nothing between those two points can
save it. Both numbers are guesses, and the repository's own comment says so: *"it is a guess at a
value only the backend team knows, and it is recorded as one."*

**The server has published the answer all along.** `GET me/cases/{case}/requirements` carries an
`accepts` block — `{mime_types, max_bytes}` — built from `UploadPolicy::toArray()`
(`modules/Welfare/Http/Controllers/V1/MyRequirementController.php:80`). Nothing in `lib/` reads it.
The accepted MIME set is likewise hardcoded in two places and published in one.

This is the client half of **F25**. It does not close F25 — the deployed proxy's
`client_max_body_size` is still unknown and still item 6 on the manual list — but it removes the
part that is this repository's fault, and it does so in the direction that cannot drift.

**PRECONDITIONS** TAB 00 complete.

**DO**

1. **Read the policy from the response.** Decode `accepts` on the requirements checklist and carry
   it into the capture policy. One ceiling and one accepted-type set, sourced from the server,
   threaded to both enforcement points.
2. **Keep a fallback, and label it.** A checklist that arrives without `accepts` — an older server,
   a cached response — must still refuse something. Fall back to the *lower* of the two current
   constants, and make the fallback distinguishable in telemetry from a served policy, so nobody
   later reads a fallback as a measurement.
3. **Delete the second number.** After this command there is exactly one place in `lib/` that
   states a maximum upload size and exactly one that states accepted types. Guard it with a test
   that fails if a second literal appears.
4. **Say the real number.** The refusal copy names the actual limit and the actual file size, in
   both languages — "12 MB, and the office accepts up to 10" — never a bare "file too large".
5. **Refuse at the earliest honest moment.** The check runs when the file is chosen, before the
   resident waits through downscaling; and again before send, because downscaling changes the size.
6. **The signature check stays.** `DocumentCapturePolicy.inspect` matches leading bytes against the
   format and that behaviour is not weakened by taking the type list from the server — the served
   list decides *which* types, the signature check decides whether the file *is* one.

**GUARDRAILS**
Never raise the client ceiling above what the server published to make an upload succeed.
Never treat the client check as the boundary; the server's answer is the one that counts, and the
copy must not imply the app decided.
No hardcoded second copy of a published value, anywhere, ever again.

**ACCEPTANCE**
A file between the two old ceilings is accepted or refused *once*, at the moment it is chosen, with
the server's number in the message.
A checklist response without `accepts` still refuses oversized files, and the telemetry says the
policy was a fallback.
A test fails if a second size or type literal is introduced.

**EVIDENCE** Before/after of both enforcement points · the guard test proven red · refusal copy in
English and Filipino · a transcript of a checklist response showing `accepts` consumed.

---

## TAB 02 · DEFECT
### A push registration that can be withdrawn

**OWNER** This repository
**STANDARDS** RA 10173 §16 (rights of the data subject), least privilege
**OBJECTIVE** Signing out removes this device's push registration from the server, and a resident
who signs out stops receiving notifications addressed to them.

**WHY NOW** **F27.** `lib/features/notifications/data/notification_api_repository.dart:152` records
the reason it was left open: *"There is no route that removes a registration by push token;
`me/devices` deletes by device."* That is true and it is not the whole picture — the backend
publishes `DELETE me/devices/{device}` (`modules/Identity/Routes/api_v1.php:52`), and
`deviceSessionRepository` has been wired since TAB 03. The client registers the device and receives
its identifier; it can withdraw the registration it made.

Left as it is, a shared or handed-on phone keeps receiving a former user's municipal notifications,
and the person who signed out has no way to stop it. That is a disclosure with no record of having
happened.

**PRECONDITIONS** TAB 00 complete. `deviceSessionRepository` wired (it is).

**DO**

1. **Hold the device identifier** returned at registration, in the same store that holds the
   session, with the same lifetime.
2. **Withdraw on sign-out**, before the token is discarded — the call needs the credential it is
   revoking the registration for.
3. **Sign out anyway if the withdrawal fails.** A resident asking to sign out is not blocked by a
   server that will not answer. The local session ends; the failure is recorded and surfaced
   honestly rather than swallowed, because a registration that outlived its session is a fact
   somebody may need later.
4. **Withdraw on every path that ends a session**, not only the button: token revoked, account
   deactivated, forced sign-out on `401`. A path that forgets is the one that matters.
5. **Do not invent a token-keyed route.** If the device identifier is genuinely unavailable on some
   path, record that path and its reason rather than constructing a call the server does not
   publish.

**GUARDRAILS**
Never block sign-out on a network call.
Never delete a device the app did not register.
No new backend route, and no request to add one, from inside this command.

**ACCEPTANCE**
Sign-out issues `DELETE me/devices/{device}` for this device and no other.
Sign-out with the network unavailable still ends the local session, and says what could not be
done.
Every session-ending path is covered by a test that fails if the withdrawal is removed.

**EVIDENCE** Request transcript for each session-ending path · the failure path proven ·
the test proven red.

---

## TAB 03 · PRODUCT SEAM
### The registration wizard, and the answer nobody has given

**OWNER** This repository — **the decision belongs to the LGU and this command does not take it**
**STANDARDS** RA 10173 (identity assurance at enrolment), honest interface
**OBJECTIVE** The app stops presenting residents a path that cannot complete, without prejudging
whether self-registration is the intended product.

**WHY NOW** **F15**, and it is the last stub: `registrationRepository` is the single entry left in
the wiring detector's ledger, marked *"blocked — F15"*. This app ships a seven-field
self-registration wizard (`docs/taytay-registration-wizard.md`) and **there is no route on the
server by which a resident can create an account** — the public `Identity` surface is sign-in only,
and citizen accounts are made by staff on the admin console.

A resident who downloads this app today fills in seven fields and meets a dead end. That is worse
than an app that says "sign in with the number the office registered", because the wizard is a
promise the platform cannot keep.

Manual-tasks item 5 puts the choice fairly: staff-mediated onboarding, or a backend
self-registration route plus an LGU identity-assurance policy. **Nobody can pick that from the
code.** What the client can do is stop being wrong today and make either answer cheap.

**PRECONDITIONS** TAB 00 complete. No LGU answer required — this command is written so that it does
not need one.

**DO**

1. **Introduce an onboarding mode**, resolved at startup from what the server publishes on
   `app/bootstrap`, with exactly two values: staff-mediated and self-enrolled.
2. **Default to staff-mediated**, because that is what the platform does today, and a default that
   describes reality is the safe one. An absent field resolves to the default and is not an error.
3. **Build the staff-mediated entry properly** — not a disabled button. The resident is told, in
   both languages, that an account is created at the MSWDO office and what to bring; sign-in with a
   registered number is the primary action; the office's contact details come from the server, not
   from a constant.
4. **Keep the wizard, behind the mode.** It is built, tested and reviewed; deleting it destroys work
   that becomes correct the day the LGU chooses self-enrolment. Under staff-mediated it is
   unreachable from any route, which the router must enforce rather than the screen.
5. **Keep the stub honest.** `registrationRepository` stays stubbed and stays named in the wiring
   detector; this command does not wire it. Update its ledger entry to name this TAB and the
   decision it waits on.
6. **Do not guess at identity assurance.** No document capture, no selfie, no verification step
   added to the wizard on the theory it will be wanted. That is the LGU's policy and inventing it
   here is inventing a rule the office never agreed to.

**GUARDRAILS**
Never wire a self-registration call against a route that does not exist.
Never delete the wizard.
Never present an onboarding path whose next step cannot complete.
The mode is read from the server; no build-time flag, no environment constant.

**ACCEPTANCE**
With the field absent, the app opens on the staff-mediated entry and the wizard is unreachable by
route, deep link or back-stack.
With the field set to self-enrolled, the wizard is reachable and unchanged.
The stub count is still 1 and the ledger entry names this TAB.

**EVIDENCE** Both modes rendered, both languages · router-level unreachability proven by test ·
the bootstrap decode · the updated stub ledger.

---

## TAB 04 · CONTRACT
### KYC corrections, keyed the way the server keys them

**OWNER** This repository
**OBJECTIVE** A resident's correction reaches the field it is about.

**WHY NOW** **F23.** Corrections are keyed **by category** in this app and **by field** on the
server, and today only the unambiguous ones are sent — `lib/core/api/backend_gap.dart:108` records
the position. Every ambiguous correction a resident types is therefore either dropped or delivered
against the wrong field, and the resident is told neither.

The KYC path is now reachable end to end for the first time — F14 closed, the barangay directory is
published, a claim can be filed — so this is the moment the correction payload starts mattering to
real people rather than to a test.

**PRECONDITIONS** TAB 00 complete. The KYC claim path wired (it is, since F14).

**DO**

1. **Establish the server's field vocabulary by reading the server**, not by inference from the
   category names — the published request schema for the corrections endpoint at the pinned
   baseline is the authority.
2. **Map category to field explicitly**, one entry per case, with the ambiguous ones named as
   ambiguous rather than absent.
3. **Where a category genuinely spans several fields, ask the resident which.** Do not pick. A
   correction filed against the wrong field is a correction the office will refuse and the resident
   will not understand.
4. **Never drop silently.** A correction that cannot be mapped is refused *to the resident*, in
   words, before it is submitted — not accepted and discarded.
5. **Guard the map both directions**: a new server field with no category, and a category with no
   field, both fail the suite.

**GUARDRAILS**
No free-text field name constructed at runtime.
No correction submitted against a guessed field.
No change to the server's schema, and no request for one.

**ACCEPTANCE**
Every category maps to a published field or is refused with an explanation.
A resident correcting an ambiguous category is asked which field, and the answer is what is sent.
The drift guard fails when the published schema and the map disagree.

**EVIDENCE** The mapping table with its source · the drift guard proven red · the resident-facing
refusal copy in both languages.

---

## TAB 05 · CONTRACT
### Stop overriding the page size the server chose for this channel

**OWNER** This repository
**OBJECTIVE** One place decides how many records a `citizen-mobile` page holds, and it is the
server.

**WHY NOW** Manual-tasks item 9. `app/bootstrap` publishes `default_page_size: 15` **for this
channel specifically**, and `lib/core/api/api_envelope.dart:19` sends `defaultPerPage = 25`.
Nothing is broken. That is precisely why it is worth closing now: a number chosen for this channel
by the system of record is being silently overridden by a number chosen in a client, and the next
person to change either will not know the other exists.

It is also the cheapest possible demonstration of the rule TAB 01 establishes — a published value
is read, never copied.

**PRECONDITIONS** TAB 00 complete. TAB 01 complete, so the "read it, don't copy it" pattern already
exists.

**DO**

1. **Read `default_page_size` from `app/bootstrap`** and use it as the client's default.
2. **Keep the clamp.** A server value outside a sane range is clamped and the clamping is recorded —
   a client that will render whatever it is told is a client one bad config away from loading four
   thousand rows on a municipal connection.
3. **Fall back to the current 25 when the field is absent**, labelled as a fallback in telemetry,
   exactly as TAB 01 does.
4. **One constant.** After this, no screen and no repository states a page size of its own.

**GUARDRAILS** Never send a page size the server did not publish, except the labelled fallback.

**ACCEPTANCE** A bootstrap carrying 15 produces pages of 15 across every paged surface. An absent
field produces 25 and says it was a fallback. An absurd value is clamped and recorded.

**EVIDENCE** Request transcripts across the paged surfaces · the clamp proven · the guard test.

---

## TAB 06 · RESILIENCE
### One refresh is one sign-out, and the resident is told so

**OWNER** This repository
**OBJECTIVE** Concurrent expiry produces exactly one sign-out, once, with an explanation — not a
storm of failures and not a silent one.

**WHY NOW** **F22.** There is no token-refresh endpoint, and the decision recorded during
integration was to accept that: *"one refresh under concurrency is one sign-out."* Accepted is not
the same as implemented. What must be verified is that concurrency produces *one* sign-out and not
several, that in-flight requests do not each raise their own error, and that the resident is told
why they are back at the sign-in screen rather than being dropped there.

This is the failure mode a resident meets on a weak municipal connection, which is most of them.

**PRECONDITIONS** TAB 00 complete.

**DO**

1. **Single-flight the expiry.** Several requests meeting `401` at once end the session once.
2. **Say why.** The sign-in screen states that the session ended, in both languages, distinct from
   the copy shown to somebody who signed out deliberately and distinct from a network failure.
3. **Lose no work silently.** Anything a resident had typed and not submitted is either preserved
   or its loss is stated. Preserving it is preferable; claiming to have preserved it when it was not
   is the only unacceptable outcome.
4. **Do not build a refresh.** No refresh endpoint exists; a client-side approximation of one —
   retry loops, speculative re-auth — is a fiction that fails differently on every connection.
5. **Prove it under concurrency**, with several in-flight requests, not one.

**GUARDRAILS**
No token stored anywhere it outlives the session.
No silent re-authentication.
No retry that could re-submit a mutation.

**ACCEPTANCE** Ten concurrent requests meeting `401` produce one sign-out, one message, and no
duplicate submissions. The message distinguishes expiry from deliberate sign-out and from a
network failure.

**EVIDENCE** Concurrency test transcript · the three copy variants in both languages.

---

## TAB 07 · VERIFICATION
### The screen-reader session that has never been run

**OWNER** This repository
**STANDARDS** WCAG 2.2 AA, Android accessibility guidance, Apple Human Interface accessibility
**CONTENT** Filipino and English
**OBJECTIVE** The app is operable by a resident using a screen reader, in both languages, and the
claim is backed by a session somebody actually ran.

**WHY NOW** The 28-TAB build sequence closed classified `READY_FOR_HUMAN_REMOTE_AUTHORIZATION` with
**no TalkBack or VoiceOver session ever run** — the app was built on a Windows host. The automated
evidence is genuinely strong: `test/features/device_adaptation_test.dart` proves core routes survive
200% text scale, render in Filipino, clear the notch and meet hit-target sizes, and it passes today.

None of that is a screen reader. Text scale is not focus order; a hit target is not an announcement.
The app serves residents including senior citizens and persons with disability — two of the sectors
the office exists to serve, named in RA 9994 and RA 10754 — and shipping an unverified claim to
them is the failure this command exists to prevent.

**PRECONDITIONS** TAB 00 complete. A device or simulator with a screen reader. **If no physical
device is available, run on the iOS Simulator and an Android emulator and record every criterion
that genuinely needs hardware as environmentally deferred — do not claim it.**

**DO**

1. **Walk the core journeys under VoiceOver and TalkBack**, in Filipino and in English: launch and
   gates, sign-in, the home dashboard, the KYC claim, a document upload, the newsfeed, a service
   request.
2. **Fix what the walk finds**, in this order: unlabelled controls, focus order, announcements for
   async state, and anything conveyed by colour alone.
3. **Record the walk** — every journey, every finding, what was fixed and what was deferred, at
   `docs/frontend/accessibility-session.md`. A finding with no fix names its reason.
4. **Add a regression test for each fix** at the level the fix lives — a semantics test for a label,
   a widget test for focus order. The manual session is not repeatable; its findings must become
   things that are.
5. **Do not weaken the existing device-adaptation suite** to accommodate a change. If a fix breaks
   it, the fix is wrong or the suite is wrong, and which one must be argued.

**GUARDRAILS**
Never report an accessibility criterion as met on the strength of an automated test alone.
Never label a control with text a sighted user cannot see corresponding to.
No hardware-dependent criterion claimed from a simulator.

**ACCEPTANCE**
Every core journey completable under a screen reader in both languages, or the blocker named.
Every fix carries a regression test.
The session document distinguishes verified, fixed and deferred, per criterion.

**EVIDENCE** The session document · per-journey transcripts · the new tests proven red before green
· an explicit list of what the simulator could not prove.

---

## TAB 08 · VERIFICATION
### The first run on real hardware, and iOS from the machine that can build it

**OWNER** This repository
**OBJECTIVE** The app is proven to launch, sign in, upload and render on real devices of both
platforms — and every claim that still cannot be tested is named.

**WHY NOW** The dossier is explicit that no physical device run and no device matrix has ever
happened, and that the original host was Windows, so **this Mac is the first machine in the
programme's history that can build for iOS at all**. The integration sequence established that it
does build here, which moved `IPHONEOS_DEPLOYMENT_TARGET` to 15.0 — that is a build, not a run.

A client defect that ships is fixed forward: Play halts distribution of a new version but does not
remove it from phones that already updated. The device run is the last cheap opportunity to find
one.

**PRECONDITIONS** TABs 01–07 complete, so what is exercised is the finished client. Devices or, on
their absence, simulators — with the distinction recorded.

**DO**

1. **Define the matrix from the audience, not from convenience**: the oldest supported Android
   (`minSdk = 24`), a current mid-range Android, the smallest supported iPhone, and a current
   iPhone. State how each was chosen.
2. **Run the core journeys on each**, in both languages, including one upload over a deliberately
   throttled connection — the condition most residents will actually meet.
3. **Record startup time, the upload path and memory during image-heavy scrolling**, against
   `docs/integration/performance-budgets.md`. A budget nothing has ever been measured against is a
   guess with a number on it.
4. **Name what is simulated.** A simulator run is evidence of some things and of nothing about
   thermal behaviour, real camera capture, real network transitions or real screen readers on real
   hardware. The distinction goes in the record, per criterion.
5. **Do not touch signing.** The release build fails unsigned by design and must continue to. The
   keystore is the LGU's to generate and hold, and an agent must never generate, hold or rotate it.

**GUARDRAILS**
Never generate or install signing material.
Never report a simulator result as a device result.
No production endpoint; local backend only.

**ACCEPTANCE**
Every journey completed on every matrix entry, or the entry recorded as unavailable with the reason.
Performance figures measured, not estimated, and compared against the budgets.
The release build still fails without a keystore.

**EVIDENCE** Per-device transcripts · measured performance against budgets · the explicit
device-versus-simulator table · confirmation the unsigned build still fails.

---

## TAB 09 · GATE
### A client-only readiness statement, and the line where it stops

**OWNER** This repository
**OBJECTIVE** One document saying exactly what the client is ready for, what it is not, and which
of the remaining blockers belong to somebody else.

**WHY NOW** The previous sequence's go/no-go was a *platform* verdict, and it was NO-GO for reasons
almost entirely outside this repository. That was correct and it is not useful to a front-end team,
because it does not say whether the client is finished. This command produces the statement the last
one could not: **the client's own readiness, separated from the platform's.**

**PRECONDITIONS** TABs 00–08 complete.

**DO**

1. **Re-measure everything at decision time.** Analyzer, suite, stub count, baseline guard, both
   platform builds, the release build's continued refusal to sign itself. Figures from the run, not
   from TAB 00.
2. **Close each of TABs 01–06 with evidence or with a reason it stayed open.** No row is closed by
   a commit message.
3. **State the client verdict** — ready or not ready, on the client's own scope alone — with the
   reasoning, and record any dissent against yourself as the last dossier did.
4. **Restate the other-owed blockers without adopting them**: SMS provider, DPO, retention schedule,
   signing custody, store accounts, staging, the self-registration decision, per-service intake
   forms, the proxy body limit. Each with its owner. **The client verdict must not be softened by
   them, and must not claim them as its own excuse.**
5. **Say plainly what has still never been proven**: nothing in this programme has run against a
   deployed Taytay backend, only against one booted locally on sqlite. That sentence survives into
   this document.
6. **Checkpoint memory and the supervisor state**, and commit locally.

**GUARDRAILS**
Never report a client criterion as met on another party's behalf.
Never let an LGU blocker excuse an unfinished client item, or an unfinished client item hide behind
one.
Nothing pushed, nothing deployed.

**ACCEPTANCE**
A verdict on client scope alone, every supporting figure re-measured at decision time.
Every TAB 01–08 row closed or explained.
The other-owed list intact, unabsorbed, with owners.

**EVIDENCE** `docs/frontend/client-readiness.md` · the re-measurement transcript · the local commit.

---

## Standing rules for every command above

* **Auto-advance.** Move to the next indexed TAB when this one has evidence-backed local
  completion, a passing suite and build, its deliverables, a saved memory checkpoint, and its
  completion report issued. Same session throughout.
* **The completion report comes first.** A distinct 100%-completion report — TAB name, verdict,
  scope and deliverables, verification and build results, environmental gaps, memory checkpoint,
  commit and tree state, confirmation nothing was pushed, and the next indexed TAB — before any
  next-TAB progress is reported.
* **Decide, and show the work.** Product, privacy, authorization, schema and lifecycle decisions are
  taken without interrupting the owner: check this command and repository evidence first, research
  primary sources, compare options, choose the safest scalable design, record the rationale and the
  sources.
* **Prove every guard red before trusting it.** A guard that has never failed is a guard nobody has
  tested.
* **Boundary.** Local commits only. No push, no merge, no force-push, no remote administration, no
  deployment, no production access, no credential generation or custody.
