# Taytay resident mobile — Profile and account centre

What a resident sees about themselves, what they may change, what only Taytay
LGU may change, and what this app refuses to fabricate.

Implemented in `lib/features/profile/`.

---

## 1. Two kinds of fact, kept visibly apart — acceptance 1

| | Your account details | Confirmed by Taytay LGU |
| --- | --- | --- |
| Owner | the resident | the municipality |
| Fields | mobile number, email | full name, date of birth, sex, civil status, barangay, street address |
| Affordance | chevron → editor | lock → correction path |
| Backing | `PATCH /api/v1/me/profile` | staff routes this app must never hold |

A resident looking at "Ana Dela Cruz, born 3 March 1990, Barangay San Juan"
alongside "0917 123 4567" sees one list of facts about themselves, with no way
to know that changing the last is a setting and changing the first would be a
claim against a municipal registry. So the screen states it: two headings, two
explanations, two affordances — legible before anything is tapped, and carried
by words as well as by iconography so it survives monochrome vision
(WCAG 2.2 §1.4.1).

**The split is the server's, not this app's invention.** The committed matrix
gives `PATCH /api/v1/me/profile` the request column *"contact fields only"* and
the sensitivity note *"a citizen may not edit their own eligibility-bearing
fields"*. The app's job is to make that visible in advance rather than to
discover it at a `403`.

`FieldOwnership.isEditableInApp` is the single gate. No screen decides for
itself, and a test asserts every eligibility-bearing field answers false.

---

## 2. Canonical data cannot be overwritten — acceptance 2

Three independent mechanisms, each sufficient on its own:

1. **There is no editor.** `ContactDetailsScreen` builds its fields by filtering
   `ResidentProfileField` on ownership, so a field added to the LGU-verified
   group can never appear there by accident.
2. **There is no type that can carry it.** `updateContactDetails` takes a
   `ContactDetailsUpdate`, which has properties for a mobile number and an email
   and nothing else. A canonical change cannot be expressed, let alone sent.
3. **There is no wire key.** `encodeContactUpdate` emits `mobile_number` and
   `email`; there is no branch that could add another.

### Why those fields in particular

A resident who could edit their own **date of birth** could grant themselves a
senior citizen benefit. One who could edit their own **barangay** could move
themselves into a different office's caseload. Neither is hypothetical — they are
the two most common fraud patterns in municipal assistance, and the reason the
backend refuses the edit rather than trusting a client not to offer it.

### The correction pattern is a sentence, not a form

The committed contract defines **no resident-initiated correction endpoint**.
`PATCH /me/profile` is contact-only; `PATCH /api/v1/residents/{resident_id}`
requires the `resident.update` permission under a staff role scope, which a
citizen app must never hold (CLAUDE.md Article 0).

So tapping a locked field opens a sheet that explains why, and names the real
next step: the municipal hall, with a valid ID and the document showing the
correct detail. A form here would collect a resident's evidence and have nowhere
to send it — and a submission that silently goes nowhere is worse than an
instruction, because the resident who followed the instruction gets their record
fixed.

The one shortcut offered is verification: a resident mid-verification is already
being asked for information by the LGU, and answering that is cheaper than a
second trip.

---

## 3. Own record only — acceptance 3

* `loadOwnDetail()` takes **no identifier**, and there is no overload that does.
  An API that cannot express "fetch someone else" cannot be talked into it. A
  test asserts the repository source contains no `residentId`, `byId(` or
  `loadDetail(String`.
* No file under `lib/features/profile/` builds a `/residents/` path — asserted
  by a source scan.
* `ResidentProfileDetail` is a map keyed by a closed enum, so there is **no
  property** a household member, a relative or a dependant could occupy.
* The decoder is an **allow-list of eight keys**. Twenty forbidden keys are
  listed and asserted disjoint — registry internals (`resident_id`,
  `record_number`, `psgc_code`, `philsys_number`), staff and review material
  (`assessment`, `internal_notes`, `reviewed_by`, `risk_score`), other people
  (`household_members`, `relatives`, `dependents`), and audit metadata
  (`audit_trail`, `created_by`, `deactivation_reason`).
* A nested object under an allowed key is **dropped, not flattened** — that is
  how a household list would otherwise be rendered as an address.

A hostile-payload test feeds all twenty forbidden keys plus another resident's
name and asserts none survives.

### A guest reads nothing

`ProfileScreen._load` gates on `CapabilityService.canOpen` before the fetch, not
on the widget that would draw it. The read is the disclosure; a guest issues
none, so there is nothing in a cache, a log or a screenshot. Tested with a
counting repository asserting `detailCalls == 0`, and again after sign-out.

The privacy screen goes further: it reaches for **no dependency at all**, proven
by a source assertion, so it renders identically for everyone.

---

## 4. Completeness: removed, not hidden

`ResidentProfileSummary.completionPercent` existed before TAB 12. It is gone.

* **No authoritative definition exists.** The `ResidentProfile` module publishes
  no endpoint and no notion of "complete", so any figure would count the fields
  *this build* knows about — drifting from what the LGU requires the moment
  either changes, and counting staff-only fields a resident will never see.
* **A number invites the wrong behaviour.** "Your profile is 60% complete" reads
  as an instruction on a government service, and a resident who chases it to
  100% may hand over data the LGU never asked for — the opposite of
  minimisation.

Two tests enforce it: the summary type carries no such field, and no file under
`lib/features/profile/` computes a percentage.

If the backend ever defines completeness, it arrives as a server-supplied field
and the app renders what it is told.

---

## 5. What was withheld, and why

| Asked for | Status | Evidence |
| --- | --- | --- |
| Household / family shortcut | **withheld** | TAB 10 (D-44): the only household row is `GET /api/v1/households/{household_id}`, a staff route needing `resident.view`, noted "other people's data — audited read". No `/me/household` exists. The capability is declared and reported unavailable. |
| Notification preferences | **withheld** | §11 of the matrix has an inbox, mark-read, mark-all-read and device registration — **no preferences row at all**. The `NotificationRepository` seam still declares them and declines; the UI offers nothing. |
| Consent toggles | **withheld** | No consent endpoint. Under the Data Privacy Act a consent record must be *demonstrable by the controller*; a toggle whose state lives only on a phone proves nothing and tells a resident they withdrew something the LGU never heard about. |
| Record deletion | **withheld** | The matrix marks deactivation "never a hard delete — retention is statutory". The screen says so plainly rather than offering a button that would be refused. |
| Assistance history shortcut | **built** | `GET /api/v1/me/assistance-requests` exists; the capability routes to `/requests`. |

Nothing is fabricated: no sample resident, no invented consent state, no
household content, no preference defaults, no history.

---

## 6. Privacy screen

Public, so someone deciding whether to register can read what they would be
agreeing to first. Fixed copy throughout — categories, never values.

It states what the app keeps on the phone (a keystore token, a greeting name, a
verification level, all removed on sign-out), what it never keeps (address, birth
date, ID images, household details), what the LGU holds, and who else can see it
(nobody outside the LGU; no advertiser). It lists the five Data Privacy Act
rights and names the municipal hall as the place to exercise them.

It is explicit about the two things it does **not** do: change recorded consent,
and delete a record.

---

## 7. Verification

`dart format` clean · `flutter analyze` clean · **627 tests pass** · debug and
release APKs build.

TAB 12 coverage (46 tests): ownership and eligibility invariants; the editable
set matching the contract exactly; every field classified; an update carrying
only account-owned fields; correction copy naming a real step and promising no
submission; the hostile-payload decoder test; nested objects dropped; allow and
forbidden sets disjoint; every allowed key mapping to a named field; non-object
payloads; encoded updates carrying only contact keys; own-record signatures and
no `/residents/` path anywhere; the shipped repository declining; completeness
absent from both the type and the sources; both sections rendering with their own
explanations, chevrons and locks; known values shown and absent ones named; an
unreadable record explained without blame; the badge at all three levels; the
correction sheet with no input; the mid-verification shortcut; the editor
offering exactly two fields and no canonical label; saving carrying only contact
fields with an idempotency key; a failed save saying nothing changed and hiding
the debug text; validation before sending; a guest fetching nothing and seeing
nothing personal; a guest redirected off the editor; sign-out clearing personal
content; the privacy screen public, toggle-free, honest about retention and
dependency-free; withheld shortcuts staying withheld; and 200% text scale plus a
wide surface.

Two defects were found and fixed while building: the verification badge
overflowed by 24px because its label was not `Flexible`, and two scattered
`AccessLevel` comparisons had crept into the new code (routed through
`CapabilityService` and an exhaustive switch instead).

Five pre-existing tests were updated: the Profile shortcut list now sits below
the two field sections, so the helpers that reach it scroll first. Three
test-harness traps were fixed along the way — the shell's `IndexedStack` keeps
every branch alive so `find.byType(Scrollable).first` scrolled Home; a
requirement label matches several tiles, which `scrollUntilVisible` rejects; and
`.first` on a not-yet-built finder throws rather than resolving to empty. All
three are now handled by an anchored, bounded drag loop.

---

## 8. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| P-1 | No `GET /api/v1/me/profile` | Every field reads "Not available in this app yet". Nothing is simulated. |
| P-2 | The eight wire keys are provisional | The `ResidentProfile` module publishes no schema; these are this app's reading of the categories the boundary map names. One line per field changes when it ships. |
| P-3 | No resident-initiated correction endpoint | The correction path is the municipal hall. Re-open if `/me/profile/corrections` is ever defined. |
| P-4 | No consent endpoint | Consent is explained, not managed. |
| P-5 | No notification-preferences endpoint | The seam declines; no UI. |
| P-6 | No household route for citizens | Withheld since TAB 10. |
| P-7 | No completeness definition | Removed entirely — see §4. |
| P-8 | English only | Filipino copy arrives with app-wide localisation. |
