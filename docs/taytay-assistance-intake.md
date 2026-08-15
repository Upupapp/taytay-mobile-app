# Taytay resident mobile — assistance request intake

How a verified resident files an application, and the several places this flow
deliberately refuses to be clever.

Implemented in `lib/features/services/` — `domain/assistance_intake.dart`,
`domain/assistance_intake_validation.dart`,
`presentation/assistance_intake_controller.dart`,
`presentation/assistance_intake_screen.dart`.

---

## 1. The app does not know what any service asks for

This is the decision the rest of the TAB hangs from.

`AssistanceIntakeForm` is **fetched**, never authored. There is no question list
in the client, no per-service branch, no `if (serviceCode == 'CEDULA')`. The
server describes the questions, their kinds, their choices, the documents, the
consent statements and the narrative prompt; the app renders that description
and sends the answers back under the server's own keys.

The alternative fails in a specific and expensive way. The municipal office
changes what it asks for. The released app keeps asking the old questions.
Residents fill in a form that produces an application the office then has to
reject — and nobody can patch a shipped APK on the day the policy changed.

A direct consequence: with `ServiceDelivery` still `planned` in the committed
boundary map, **no form can be loaded today**, and the wizard says so and names
the municipal hall. `PlannedServiceRequestRepository.loadIntakeForm` declines.
Mocking a form here would have been the most damaging fixture in the codebase —
it is the app asking a resident for personal data no office requested, under a
consent statement nobody with authority wrote.

### Server text that *is* rendered

Question prompts, help text, choice labels, requirement names and consent
statements are **content**, and are rendered as sent — the same standing as a
service name. This does not contradict "the server's `message` is never shown to
a resident": that rule is about the operator-facing `message` on a *failure*
envelope, which may name an internal state. Content the LGU authored for
residents is the opposite thing.

---

## 2. A wizard, not one long form

| Step | Shown when | Validated on |
| --- | --- | --- |
| Who this is for | always | confirmation checkbox |
| What you need | always | non-empty, server's length cap if any |
| Questions from the office | the form has questions | required / kind / length |
| What to bring | the form has requirements | nothing — see §5 |
| Before you send this | the form has consents | required consents |
| Check your answers | always | everything, again |

The step list is **derived from the form**, so the app cannot present a step the
office did not ask for. Movement never touches the draft, which is what makes
"go back without losing anything" true by construction rather than by
remembering to copy fields around. Forward movement is validated; backward
movement never is — a resident may always retreat, including out of a step they
have not finished.

Review re-validates **everything**, because a resident can reach review, step
back, clear a required field and return, at which point the per-step check that
let them past the first time is no longer true.

---

## 3. Validation is a courtesy, never a rule of its own

Two rules, and they are why the validation file is short:

1. **Nothing is stricter than what the server declared.** A length is enforced
   only when the form carried one. A question is required only when the form said
   so. The app adds no rule of its own, because a client-invented rule rejects an
   application the office would have accepted and there is no appeal path inside
   an app.
2. **Nothing here decides eligibility.** Whether a resident qualifies is a server
   decision. This file checks a form is filled in and has no opinion about
   whether it should succeed.

Two details worth naming:

* **`false` on a yes/no question is an answer, not a blank.** Treating it as
  missing would make "no" impossible to give.
* **A number question rejects free text**, because the *kind* is the server's own
  declaration. The numeric field keeps the raw text when it will not parse, so
  the resident is told "enter this as a number" rather than having a string sent
  and rejected with a message they never see.

---

## 4. A question this build cannot render blocks the whole application

A released app will meet an `IntakeAnswerKind` it has never heard of — the
backend contract is explicit that adding an enum value is not breaking. Three
options existed, and two are traps:

* **Skip it.** Files an application the office considers incomplete, and the
  resident never learns which answer was missing.
* **Guess a control for it.** Sends an answer in a shape nobody agreed.
* **Refuse, name the question, and send the resident to the counter.** Chosen.

So an unrenderable question is *not* reported as a field error — that would tell
someone to fix something they were never shown — and `canSubmit` is false while
one is present. The banner names the prompt the app could not put to them, and
the controller refuses independently of the UI, so a stale frame cannot submit.

---

## 5. Requirements are listed here; uploading is TAB 16

This step lists what the office will need and does **not** upload. Capture,
compression, progress, retry, readability-after-compression and "no file
contents in analytics" are TAB 16's rules, and they are owned once there so they
hold for both a new application and an existing one.

Listing them here still does the thing that matters most at this moment: a
resident learns what to bring *before* committing to the trip. The step is
deliberately not validated — the office accepts documents at the counter, so
nobody is blocked for lacking a file on their phone.

`AssistanceIntakeDraft.attachmentIds` carries **server-issued references only**,
never a local file path. A path is not a document, and sending one submits a
reference that means nothing to the server.

---

## 6. Duplicate applications — the server's statement, never ours

`ActiveRequestNotice` is set only when the server reports an application already
in progress. The app does not scan a request list and infer a duplicate: it
cannot see every channel a resident may have applied through, and a client that
guesses will eventually tell someone they have already applied when they have
not.

It is shown from the **first** step, so a resident who has already applied finds
out before filling the form in again — and it is a **warning, never a block**.
Only the server refuses a second application.

When submission returns `409`, the outcome is `alreadyOpen`, not an error:
nothing the resident did was wrong. `retrySubmission` is a deliberate no-op for
that outcome, because asking again only makes the server say so twice.

---

## 7. Idempotency, and what a failure means

One key is minted per submission **attempt** and reused across every retry of
that attempt, so a retry after a dropped connection replays rather than files a
second application. This is the operation the rule exists for: a dropped
connection *after* the server committed is indistinguishable from one before.

The key is discarded once the server has answered — success or conflict — because
a later attempt is then a genuinely new application, not a replay.

A failure never clears the draft. That is not a feature; it is what happens
because failure handling writes to a separate field. The copy says the thing a
resident most needs to hear: **nothing was submitted, so trying again does not
apply twice.**

---

## 8. Access

| | Guest | Unverified | Verified |
| --- | --- | --- | --- |
| `/apply/:serviceCode` | → sign-in | → verification | opens |

`ResidentCapability.applyForAssistance` is separate from
`trackAssistanceRequests` even though both are verified-only and both belong to
`ServiceDelivery`. Reading the status of something already filed and creating a
new obligation on a civil record are different acts, and an LGU that later opens
one before the other can do it by changing one line.

The route is **top-level, not nested under `/services/:serviceCode`**. The
catalogue is public and this is not; nesting would put a verified-only route
inside a public branch. Keeping the boundary in the path means a reader can see
which parts of the app are open by looking at the route table. It is also
full-screen rather than a shell destination — a resident part-way through an
application should not have a navigation bar under their thumb inviting them out
of it.

The screen carries a `CapabilityGate` as well as the route guard. Belt and
braces: a screen that states its own requirement keeps telling the truth if it is
ever opened from somewhere with a weaker one.

---

## 9. What this flow never shows

No assessment field, no priority score, no assigned staff, no internal note, no
approval or rejection control, no audit metadata. A test asserts the rendered
text of the wizard contains none of that vocabulary.

The review step ends with the only honest statement available: Taytay LGU decides
whether a resident qualifies and what they receive, this app cannot say in
advance, and sending an application does not guarantee approval.

---

## 10. A shared primitive moved

`FieldError` now lives in `lib/core/forms/`. It was written for the registration
wizard and kept in that feature's `domain/`, and two things then reached across
the boundary for it: `shared/widgets/form_support.dart` imported it, and this
wizard would have made it a feature-to-feature import. Both are the dependency
Article 2 rule 2 exists to stop. `registration_validation.dart` re-exports it, so
no existing importer changed.

---

## 11. Tests

`test/features/assistance_intake_test.dart` — 28 tests.

* the shipped repository declines rather than inventing questions
* an absent backend produces an honest screen with no form and nothing to send
* steps are derived from the form
* validation: confirmation, server-declared lengths only, required vs optional,
  `false` is an answer, numbers, required consents, unrenderable questions
* the draft survives back-navigation and a failed submission
* edit-from-review only goes backwards
* a retry replays the same idempotency key; a success retires it
* a conflict reports "already open" and is not retried
* an incomplete form and an unrenderable question both block submission
* consents travel as their own field, not folded into answers
* guest → sign-in, unverified → verification, verified → step 1
* a full application reaches a reference number
* an already-open application is warned about up front, without blocking
* no staff vocabulary appears in the rendered wizard
* the wizard survives a 200% text scale
