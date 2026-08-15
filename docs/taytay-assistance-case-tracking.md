# Taytay resident mobile — assistance status, timeline and next steps

Where a request stands, what happens next, and the line between an admin case
file and what a citizen may see of it.

Implemented in `lib/features/services/` — `domain/assistance_case.dart`,
`domain/request_status_copy.dart`, `presentation/assistance_case_screen.dart`.

---

## 1. The canonical status is never replaced by the app's reading of it

Acceptance 1 of TAB 17 is that the backend status stays traceable. Two things
make that true:

* `ServiceRequest` keeps **`rawState`** — the office's own string — alongside the
  parsed enum, and `ServiceRequestState` carries a `wireValue` per case.
* The screen shows both: the friendly line as the heading, and the office's value
  under the label **"Status code used by the office"**.

That second row looks redundant until a resident is standing at a counter. The
clerk's screen says `waiting_requirements`; the app says "Waiting for your
documents". Showing only the friendly version means the two people in that
conversation have no shared vocabulary, and the resident cannot quote anything.

The full lifecycle, taken from the Master Command's admin list:

| Canonical | Resident reads | Whose turn |
| --- | --- | --- |
| `draft` | Not sent yet | resident |
| `submitted` | Sent to Taytay LGU | office |
| `pending_review` | Waiting to be reviewed | office |
| `under_verification` | Being checked | office |
| `assigned` | With a Taytay LGU officer | office |
| `processing` | Being processed | office |
| `waiting_requirements` | Waiting for your documents | **resident** |
| `approved` | Approved | office |
| `rejected` | Not approved | — |
| `ready_for_release` | Ready for you to collect | **resident** |
| `released` | Released to you | — |
| `completed` | Completed | — |
| `cancelled` | Cancelled | — |
| *unrecognised* | Being processed | office |

`pending_review` and `under_verification` are kept apart because they mean
different things to the person waiting: "in the queue" and "someone has it open".

---

## 2. `assigned` never names anyone

The Master Command says not to expose staff identity, so `assigned` reads as
"With a Taytay LGU officer" and there is **no field anywhere** for a staff name.
A name here would invite a resident to seek out an individual rather than a case
queue — which is worse for both of them, and is how a caseworker ends up
personally accountable for a municipal decision.

---

## 3. The model cannot carry staff data, so the screen cannot leak it

The admin case file behind this screen holds assessment scores, caseworker notes,
risk flags, desk-to-desk handoffs and audit metadata. `CaseTimelineEntry` has
fields for a date, a lifecycle value, a summary and an optional detail sentence —
**and nothing else. Not a nullable field, not a private one.**

That is deliberate and structural rather than a filter. A filter is a line of
code someone can weaken; an absent field is a compile error. A field that exists
is a field something eventually populates.

A test asserts the rendered screen contains none of: *caseworker, assessment,
risk, score, internal, audit, handoff, assigned to*.

---

## 4. Next steps appear only when the backend offers them

The Master Command lists the possible actions — upload a requirement, provide
information, await review, view release instructions, view referral, contact
office — and says **"only if backend says available"**.

That is not a UI preference. "View release instructions" on a case with no
release scheduled sends someone to a municipal hall on a day nothing is waiting
for them, and they lose a morning's wages to find out.

So `AssistanceCaseDetail.nextActions` is server-supplied, and the screen renders
what it was given. Two kinds have a destination in this build — upload a
requirement and provide information, both of which lead to TAB 16's requirements
screen. The rest are **described, not linked**: inventing a destination for
"contact office" would mean the app choosing which office, and it does not know.

An unrecognised action kind is likewise described and not actioned. The label
still tells the resident what the office wants; the app does not guess a
destination for a step it has never heard of.

---

## 5. A rejection reason appears only when the office published one

`outcomeReason` is `null` unless the backend intentionally exposes it, and the
screen shows nothing in its place. The reasoning is the same one that governs
every other staff field: an internal rejection heuristic shown to a resident is
both a privacy breach and an invitation to game it.

When the server sends nothing, the status copy says what is true — the office did
not approve it — and does not speculate about why.

---

## 6. One status switch, not two

Home and the request list had each grown their own exhaustive switch over
`ServiceRequestState`. Two switches over one enum drift: one gets a new case
worded carefully, the other gets whatever the person adding it typed, and a
resident reads two different sentences about one application depending on which
screen they are on.

The copy now lives in `services/domain/request_status_copy.dart`. It is in
`domain/` rather than beside a screen because Home needs it too and a feature may
not import another feature's `presentation/` (Article 2 rule 2) — the same
placement `AppFailure` and `DocumentRejection` already use for their resident
copy.

`requestStatusMeaning` is a second function answering a different question:
*whose turn is it?* That is what a resident actually opens the app to find out,
and answering it plainly is what stops someone queueing at the municipal hall to
ask something the app already told them.

---

## 7. The timeline

Rendered newest first, because the most recent update is what the app was opened
for. The server's own order is preserved in the model, so the app and a support
conversation agree on what happened when.

The rail — the dots and connecting line — is `ExcludeSemantics`. Every row states
its own date and summary in text, so nothing depends on seeing the graphic.

---

## 8. This screen never acts on the case

`/requests/:requestId` is a push-notification target. Every control on it
navigates; none of them submits, cancels or confirms. A link must not perform a
sensitive action on somebody's behalf, and the identifier is re-validated with
`DeepLink.isValidIdentifier` at the point of use rather than trusted because the
router matched it.

---

## 9. What was deleted

The old single-request screen has been replaced twice over and is removed rather
than left behind:

* `/requests/:id` is now `AssistanceCaseScreen`, showing a timeline and next
  steps instead of one status line.
* `/requests/:id/requirements` became `RequirementsScreen` in TAB 16, which
  actually sends documents.

Keeping it would have left a screen nothing routes to but anything could route to
by mistake — still carrying copy that said uploads were unavailable, which
stopped being true in TAB 16.

---

## 10. What is not built

`ServiceDelivery` remains `planned`, so `loadOwnCase` declines. A fabricated
timeline would be the most convincing lie this app could tell: it looks exactly
like progress, and a resident reading "Under verification — 12 August" would stop
chasing an application that does not exist.

---

## 11. Tests

`test/features/assistance_case_test.dart` — 23 tests.

* every canonical state has resident wording; an unrecognised one reads neutrally
* `assigned` never names a staff member
* waiting-on-resident states are marked; terminal states are exactly three
* an unknown next-action kind is described, not actioned
* the shipped repository declines rather than composing a history
* friendly copy shown *and* the canonical value kept visible
* the screen says whose turn it is
* timeline renders newest first
* only backend-supplied next actions appear; an actionable one navigates and
  submits nothing; an unknown one offers no button
* a rejection reason appears only when the office sent one
* release instructions and referral render when provided
* an absent backend explains rather than showing a blank case
* a malformed identifier is refused
* guest → sign-in, unverified → verification
* no internal vocabulary reaches the screen
* 200% text scale
