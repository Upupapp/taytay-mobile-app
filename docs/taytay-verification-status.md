# Taytay resident mobile — identity verification and status

How a resident sees where their verification stands, what they can do about it,
and what the app will never show them.

Implemented in `lib/features/verification/`.

---

## 1. What the committed backend supports

Audited against **`Taytay_Rizal_LGUIDS_Backend@68fa195`**, working tree clean.
`modules/` still holds only `Shared`, `AccessControl` and `ServiceCatalog`.

| Row | Endpoint | Status |
| --- | --- | --- |
| Verification status | `GET /api/v1/me/verification` → "tier + outstanding steps" | `planned` |
| Submit verification | `POST /api/v1/me/verification/submissions` → `202` | `planned` |
| Session bootstrap | `GET /api/v1/me` → `verification_tier` | `planned` |

Gap **G-08** states the backend "owns a canonical `VerificationState`
enumeration (not a boolean) … exposed as `verification_tier`", and that
"unknown tiers must degrade to the least-capable state".

**The wire values are not published.** So the app maps rather than assumes, and
every unrecognised value degrades — never upward.

---

## 2. Two vocabularies, one direction

| Layer | Type | Owned by |
| --- | --- | --- |
| Server state | `VerificationAttemptState` + `rawState` | the backend |
| Resident stage | `ResidentVerificationStage` | this app's copy |

`ResidentVerificationStage` has the seven situations a resident can be in:

| Stage | Headline | Next action |
| --- | --- | --- |
| `notStarted` | Not started | Start verification |
| `inProgress` | In progress | Continue verification |
| `pendingReview` | Waiting for review | — (check again) |
| `needsMoreInformation` | More information needed | Fix and resend |
| `verified` | Verified | — |
| `unsuccessful` | Could not be verified | Try again · municipal hall |
| `manualReview` | Needs a person to check | municipal hall |

**An unrecognised server state maps to `manualReview`**, not to `unsuccessful`
and never to `verified`. Three reasons, in order of importance: mapping unknown
to verified would grant capabilities the server never granted; mapping it to
unsuccessful would tell a resident they failed when nobody said so; and
`manualReview` is the one stage whose next step — go to the municipal hall —
works regardless of what the app understands.

The raw value is preserved for support but is **never rendered as the status a
resident reads**, so a resident is never shown `awaiting_barangay_endorsement`
and left to guess.

---

## 3. What the screen never shows

The Master Command names reviewer identities, fraud/risk scores, caseworker
notes, audit logs, private matching candidates, rejection heuristics and other
residents' data. The committed client-visibility matrix says the same of
reviewer identity and internal review notes: they "never appear in any citizen
or verifier response, in any endpoint, ever", and a citizen projection is built
"by naming the fields to include, never by taking the staff projection and
removing some".

That is implemented as an **allow-list decoder**. `VerificationStatusDto` reads
seven keys and ignores everything else:

```
state · verification_tier · submitted_categories · issues
resident_guidance · manual_review_available · submitted_at
```

A deny-list would be one forgotten key away from rendering a caseworker's note.
An allow-list cannot leak a field nobody wrote a line for.

`verification_test.dart` proves it by decoding a payload stuffed with
`reviewed_by`, `reviewer_name`, `risk_score`, `fraud_score`, `confidence`,
`internal_notes`, `remarks`, `caseworker_notes`, `audit_trail`,
`status_changes`, `match_candidates`, `matched_resident`, `rejection_code` and
`rejection_heuristic` — including another resident's name — then asserting none
of it appears anywhere in the decoded object.

`VerificationStatusDetail` also has **no field** any of it could occupy. The
shape is the control; the decoder is the second line.

### Categories, never contents

The screen tells a resident *which kinds* of information the LGU holds — "Your
details: name and date of birth", "Proof of identity: government-issued ID" —
and never echoes the values. Re-rendering a birth date or an ID photo on a
status screen puts personal data on a screen readable over a shoulder in a
queue, for no purpose the resident does not already know. An expandable panel
says exactly that, rather than leaving the absence to look like a bug.

---

## 4. No turnaround promises

Nothing on this screen says "within three working days". The app has no basis
for such a number, a municipal queue does not honour it, and a missed promise
from a government service costs more trust than saying nothing.

A test enforces it: every stage's copy is scanned for `N days/hours/weeks`,
"within" and "guarantee", and the rendered screen is scanned for the same.

---

## 5. Verified unlocks immediately — acceptance 2

A resident looking at a "Verified" screen who still cannot open their digital ID
until they restart has been told two contradictory things by the same product.

So `VerificationController.refresh` pushes the server's tier into
`SessionController.applyVerificationTier` — **the single place access level
changes**. The router already listens to that controller, so every gated route
re-evaluates in the same frame. No restart, no manual navigation, no second
source of truth.

The app still decides nothing:

- the tier is the server's answer;
- `AccessLevel.fromVerificationTier` fails closed on anything that is not
  exactly `verified`;
- a non-verified stage passes the raw state through, so a **revoked or suspended**
  verification takes the capability away again;
- `applyVerificationTier` ignores the call when nobody is signed in, so this path
  cannot manufacture a session for a guest.

All four are tested, including the end-to-end widget test that verifies, returns
home, taps the digital ID tile and reaches the credential — in one session.

---

## 6. The needs-more-information correction flow

When the office flags items, the screen shows **only those items**, each with the
office's own instruction and one field.

- A correction can only be entered for a **flagged** category —
  `updateCorrection` ignores anything else. The flow is a reply to a specific
  request, not an opportunity to resubmit.
- Sending is blocked until every flagged item is answered (whitespace does not
  count).
- One idempotency key per attempt, **reused on retry**: a resend that arrives
  twice is a second item in a municipal review queue.
- A failed send **keeps what was typed** — a resident should not retype after a
  dropped connection.
- A successful send clears the values and re-reads the status rather than
  assuming what the server now thinks.

Everything else the resident already sent stays with the LGU; the copy says so,
because "start again" is what makes people give up.

---

## 7. Every dead end has a next step — acceptance 3

`unsuccessful` and `manualReview` cannot be resolved in the app. Both end with
the municipal hall, and the copy states that the resident **does not need
anything from this app** to do that — a route that works when the software does
not.

A failed status *load* is also handled: the banner explains, offers a retry, and
the previously loaded status is deliberately **not cleared**, so a resident on a
weak connection keeps seeing what the LGU last said instead of watching their
verification state vanish.

---

## 8. Verification

`dart format` clean · `flutter analyze` clean · **423 tests pass** · debug and
release APKs build.

Verification-specific coverage (39 tests): every server state mapping; unknown
degrading to manual review and never to verified; all seven stages reachable,
labelled and summarised; no turnaround promise in copy or on screen; every
action-needing stage offering an action; both dead ends offering the municipal
hall; the hostile-payload privacy test; allow-list and forbidden-key sets being
disjoint; recognised wire states; unknown state preserved for support but not
rendered; unknown categories and instruction-less issues dropped; non-object
payloads; verified raising the session level and notifying; non-verified never
raising it; a revoked status lowering it; a failed load changing neither level
nor last-known status; guests unaffected; correction entry restricted to flagged
categories; send blocked until complete; idempotency key present and reused;
failed send retaining input; successful send clearing it; the shipped repository
declining; and the screen-level tests for each stage, the correction flow, the
no-restart unlock, and 200% text scale.

Two pre-existing tests asserted the old placeholder screen's copy. They were
**updated, not deleted**, to assert the new intended behaviour.

---

## 9. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| V-1 | No `GET /api/v1/me/verification` | The status screen shows an honest "could not check" banner; nothing is simulated. |
| V-2 | No correction-submission endpoint | `submitCorrections` declines; the flow is complete and inert. |
| V-3 | Wire values for `VerificationState` unpublished | The decoder recognises the spellings the boundary map implies and degrades everything else. Re-check when the module ships. |
| V-4 | `needsMoreInformation` has no server state to map from | It is reachable only when the server sends `issues`; there is no attempt-state that produces it, because none is published. |
| V-5 | Corrections are text-only | Re-uploading a document is impossible while the upload contract is unspecified (backend **G-18**). |
| V-6 | No push notification on status change | A resident must open the screen or pull to refresh. Belongs with the `Notification` module. |
| V-7 | English only | Filipino copy arrives with app-wide localisation. |
