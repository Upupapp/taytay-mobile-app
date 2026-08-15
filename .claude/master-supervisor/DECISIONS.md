# Material decisions

One entry per material decision made under the autonomous protocol. The repo's
`docs/mobile-ui-decision-log.md` holds the canonical numbered index (D-01 … D-68).

---

## D-60 — The intake form is fetched from the server, never authored in the client

**CONTEXT:** TAB 15 requires the app to "answer only the resident-facing
assessment/intake questions supplied by backend". The `ServiceDelivery` module is
`planned` and publishes no endpoint, so there was nothing to fetch.

**OPTIONS:** (1) hard-code a plausible question set per service so the wizard is
demonstrable; (2) invent an endpoint and schema; (3) model the form as a
server-supplied contract, fetch it, and have the shipped repository decline.

**SELECTED:** 3.

**WHY:** A client-authored question list drifts the moment the office changes
what it asks for, and a shipped APK cannot be patched that day — residents would
fill in a form producing applications the office must reject. Option 1 is also
the most damaging possible fixture here: the app asking a resident for personal
data no office requested, under a consent statement nobody with authority wrote.
Option 2 creates a contract the server never agreed to.

**EVIDENCE:** `docs/architecture/domain-boundary-map.md` lists `ServiceDelivery`
as planned; the existing `PlannedModule` / `plannedBackendFailure` pattern already
establishes decline-not-mock for five other modules.

**PRIMARY SOURCES:** `CLAUDE.md` Article 3 (server is the only authority),
Article 5 (data minimisation, RA 10173).

**LOCAL IMPACT:** `AssistanceIntakeForm` + `loadIntakeForm` on the repository
contract; planned implementation declines; wizard renders an honest unavailable
state; tests inject a fake form.

**BACKWARD COMPATIBILITY:** Additive. One existing test fake needed the new
members. **PRODUCTION IMPACT:** none — nothing deployed. **DATE:** 2026-08-16

---

## D-61 — An unrenderable question blocks the application rather than being skipped

**CONTEXT:** The backend contract states adding an enum value is not breaking, so
a released build will meet an `IntakeAnswerKind` it does not know.

**OPTIONS:** skip it · guess a control · refuse and redirect to the counter.

**SELECTED:** Refuse, name the question, send the resident to the municipal hall.

**WHY:** Skipping files an application the office considers incomplete and the
resident never learns which answer was missing. Guessing sends an answer in a
shape nobody agreed. Refusing is the only option that leaves the resident able to
complete their business, and it fails closed.

**LOCAL IMPACT:** `IntakeQuestion.isRenderable`, `canSubmit` false, and `submit()`
refuses independently of the UI so a stale frame cannot send. Deliberately *not* a
`FieldError` — that would tell someone to fix something never shown.

**DATE:** 2026-08-16

---

## D-62 — Consent keys travel as their own field, not inside answers

**WHY:** A consent is a legal record of what a person agreed to under RA 10173,
not an answer to a question. Given its own repository argument so it cannot be
lost in a map merge, and asserted by a test that the consent key does **not**
appear in the answers map. **DATE:** 2026-08-16

---

## D-63 — The duplicate warning is the server's statement, never the client's inference

**OPTIONS:** infer from the resident's request list · use only a server-supplied
notice.

**SELECTED:** Server-supplied only (`ActiveRequestNotice`, plus `409` on submit).

**WHY:** The app cannot see every channel a resident may have applied through —
counter, web portal, another device — so a client-side inference will eventually
tell someone they have already applied when they have not, and discourage a
legitimate application for assistance. Shown from step 1 as a warning, never a
block: only the server refuses a second application. **DATE:** 2026-08-16

---

## D-64 — One idempotency key per attempt, retired on any server answer

**SELECTED:** Mint once per attempt; reuse across every retry of that attempt;
discard once the server answers (success *or* conflict).

**WHY:** A dropped connection after the server committed is indistinguishable
from one before, so a retry must replay rather than file a second application. A
key surviving a server answer would make a later, genuinely new application
replay the old one. Mirrors `RegistrationController`. Asserted by two tests.

**DATE:** 2026-08-16

---

## D-65 — Requirements are listed at intake; uploading belongs to TAB 16

**SELECTED:** TAB 15 lists requirements and carries an `attachmentIds` seam
(server-issued references only, never local paths). TAB 16 owns capture,
compression, progress, cancel/retry and secure references.

**WHY:** The upload rules — readability after compression, no file contents in
analytics, no unsafe caches — must hold identically for a new application and an
existing request, and owning them once in TAB 16 is the only way that is true.
The listing still does what matters most at intake: a resident learns what to
bring before committing to the trip. Recorded explicitly so it is not mistaken
for an omission. **DATE:** 2026-08-16

---

## D-66 — `/apply/:serviceCode` is top-level, not nested under the public catalogue

**WHY:** Nesting would place a verified-only route inside a public branch —
correct only because the guard says no on the way in. Keeping the boundary
visible in the path means a reader can see which parts of the app are open by
reading the route table. Full-screen rather than a shell destination, because a
navigation bar under the thumb invites a resident out of a half-finished
application. **DATE:** 2026-08-16

---

## D-67 — `FieldError` moved to `core/forms/`

**CONTEXT:** It lived in `features/registration/domain/`.
`shared/widgets/form_support.dart` imported it, and the intake wizard would have
made it a second feature-to-feature import — both the dependency Article 2 rule 2
exists to stop.

**SELECTED:** Move to `lib/core/forms/field_error.dart`, re-export from
`registration_validation.dart`.

**WHY:** A named field error is a form primitive, not a registration concept.
Strictly additive: the re-export means no existing importer changed, and the full
suite passed unmodified apart from the one fake needing the new interface members.

**DATE:** 2026-08-16

---

## D-68 — Autosave is off unless the server declares draft support

**SELECTED:** `AssistanceIntakeForm.supportsDrafts`, defaulting false. While
false the draft lives in memory for the life of the flow and nowhere else.

**WHY:** A draft containing a resident's account of why they need assistance is
sensitive personal data under RA 10173. Persisting it because the app felt
helpful is storage nobody authorised, nobody clears, and nobody declared a
retention period for. **DATE:** 2026-08-16
