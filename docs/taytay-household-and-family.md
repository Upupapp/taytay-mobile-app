# Taytay resident mobile — household and family

What a resident may see about their own home, what they may never see about the
people in it, and how a mistake gets corrected.

Implemented in `lib/features/household/`.

---

## 1. The two sentences that decide this whole feature

Both from the committed **client-visibility matrix**
(`Taytay_Rizal_LGUIDS_Backend@9e3a501`):

> `household` membership | citizen: **own household only**

> Any other resident's data — **`Household.members`**, another resident's
> `monthly_income` | Cross-resident access is a **critical defect**
> (CLAUDE.md Article 5.3).

Read together they are precise and they are not in tension. A resident may know
**that** they belong to a household and see **its** details. They may not see
**who else** is in it. The people in a household are separate data subjects whose
information belongs to them, not to whoever happens to open this app.

The only household endpoint in the matrix is
`GET /api/v1/households/{household_id}` — **staff**, `resident.view`, role scope,
noted *"member list is other people's data — audited read"*. There is no
`/me/household`, and no correction route of any kind.

---

## 2. What is shown — acceptance 1

| Shown | Why it is safe |
| --- | --- |
| Household label | A human name for the home, when the LGU publishes one. Not an identifier. |
| Barangay, street address | The resident's **own** address. |
| The resident's own role | Head or member. Fails closed to member. |
| Number of people recorded | An aggregate. It lets a resident notice the office is serving the wrong number of people **while naming nobody**. |

That is the whole list, and it is enforced by the shape rather than by
discipline: `HouseholdSummary` has five fields and there is **no
`HouseholdMember` class in this app**. A member's name cannot be rendered by a
screen that has nowhere to read one from, and adding that type later would have
to be a deliberate act against a contract change.

**Head-of-household fails closed.** `HouseholdRole.fromRaw` recognises `head` and
`household_head`; everything else — including an unrecognised value, a different
case, or nothing at all — reads as `member`. "Head of household" carries weight
at a municipal counter: it is who the office speaks to and, in some programmes,
who receives on behalf of everyone. Guessing it upward from an unknown string
would tell a resident they hold a standing the LGU never gave them.

**No household identifier anywhere**, including in the route. `/household`, not
`/household/:id`. A registry number is not useful to a resident, is never quoted
at a counter, and its only effect on screen is to invite someone to pass it
around.

---

## 3. What can never leak — acceptance 2

`HouseholdDto` reads **five keys** and ignores everything else. Twenty-seven
forbidden keys are listed and asserted disjoint, in five groups:

| Group | Keys | Why |
| --- | --- | --- |
| Other people | `members`, `residents`, `relatives`, `dependents`, `head_name` | Named by the matrix as cross-resident data; its exposure is a critical defect. |
| Vulnerability signals | `sectors`, `vulnerability_score`, `risk_score`, `is_indigent`, `monthly_income` | `sectors` is where `vawc-survivor` and `cicl` live. The backend **omits** those values server-side rather than masking them — *"A masked field that travels to the browser is one devtools panel away from being unmasked."* |
| Staff and casework | `caseworker_notes`, `assessment`, `internal_notes`, `remarks`, `assigned_to`, `reviewed_by` | *"Naming the handling social worker exposes staff to pressure and, in VAWC cases, to danger."* |
| Other members' cases | `assistance_requests`, `disbursements`, `referrals` | A resident's own requests live on their own screen. A relative's are not theirs to read. |
| Registry and audit | `household_id`, `id`, `record_number`, `psgc_code`, `audit_trail`, `created_by`, `updated_by`, `match_candidates` | Internal identifiers and staff oversight material. |

A hostile-payload test feeds **all twenty-seven** plus three synthetic member
names and asserts none survives. Nested objects and lists under an allowed key
are **dropped, not flattened** — precisely how a member list would otherwise
arrive rendered as an address.

The member count is bounded to 1–60: a zero is not a household and a thousand is
a decoding accident, and rendering either would tell a resident something false
about their own record.

Two app-wide source scans back this up: no file may declare a `HouseholdMember`
class, a `household_members` key, a `residentId` or a `householdId`; and no file
may model `vulnerabilityScore`, `riskScore`, `isIndigent`, `monthlyIncome`,
`caseworkerNotes` or `sensitiveSectors`. Deny-list declarations are stripped
before scanning, because a decoder that rejects a key has to name it.

**The screen says the absence out loud.** A card explains that the other people's
details belong to them, so a resident reads it as a decision rather than as a
broken screen.

---

## 4. Corrections raise a question; they never make a change — acceptance 3

`HouseholdCorrectionRequest` carries **one field**: a category from a closed
list. No target value, no replacement address, no person, no household
identifier. It is structurally incapable of expressing "change X to Y", so
nothing sent from here could be read by any server — today or after the endpoint
exists — as an instruction to rewrite canonical membership.

**No free-text box, deliberately.** A text field on a household screen invites a
resident to type the things this app must never hold: a relative's medical
condition, why somebody left, an allegation about another household. That text
would sit in memory, in a crash report and in the OS task-switcher snapshot — for
a submission that currently has nowhere to go. A category routes them to the
right counter, which is what the correction needs; the detail belongs to the
conversation with the person who can act on it. The screen asks them not to type
personal details, and gives them no way to.

**Nobody can be moved between households.** There is no category for it and no
field that could name a destination — asserted by a test that scans every
category label for "move", "transfer", "reassign", "merge" and "split".
Household composition is a registry decision with eligibility consequences for
*two* households at once, and it is not something one member of one of them
should be able to start from a phone.

The five categories: address wrong, role wrong, size wrong, not my household,
something else.

**The municipal hall is stated up front, not offered after a failure.** Even once
the endpoint exists, a correction is reviewed by a person and the counter is
where evidence is shown and the record actually changes.

---

## 5. Own-record scope is structural

* `loadOwnHousehold()` takes **no identifier**, and there is no overload that
  does. Not "takes one and validates it" — takes none. An interface that cannot
  express "fetch household 42" cannot be talked into unrestricted registry
  browsing by any future caller.
* No file under `lib/features/household/` builds a `/households/` or
  `/residents/` path.
* Both routes are `AccessRequirement.verified` and identifier-free.
* Every read is gated on `CapabilityService.canOpen` **before it is issued** —
  the read is the disclosure. A guest and an unverified resident each issue
  zero calls, asserted with a counting repository.

---

## 6. Honest seams, no simulation

Both operations decline. Mocking would be worse here than anywhere else in the
app: a fabricated household is a claim by a local government about who somebody
lives with — the sort of thing that decides whether a family is counted as one
household or two for assistance — and a correction form that pretended to submit
would leave a resident believing the office had been told something it never
heard.

So the screen shows "Not available in this app yet", says the record still exists
at the municipal hall, and offers the correction path anyway. The capability
stays `BackendAvailability.planned`; TAB 10's rule holds, so **access** decides
whether the screen opens and **availability** decides what it says.

---

## 7. Verification

`dart format` clean · `flutter analyze` clean · **668 tests pass** · debug and
release APKs build.

TAB 13 coverage (41 tests): no member type anywhere in the feature; no
identifier or member field on the summary; the role failing closed for six
inputs; a redacted `toString`; the hostile-payload decoder test across all
twenty-seven forbidden keys; allow and forbidden sets disjoint; the forbidden set
naming every category the matrix protects; nested objects dropped; implausible
member counts refused; non-object payloads; a correction body carrying only a
category; no category expressing a move; the request type having no target field;
every category labelled and described; a loggable request; no repository method
taking an identifier; no registry path in any household source; both routes
identifier-free and verified-only; the shipped repository declining both
operations; the capability still reporting the backend absent; both summaries
rendering with no member named; the explanation of why others are hidden; a
member seeing their own role; absent fields naming which kind of absent;
unreadable records explained without a fabricated household; no staff or
vulnerability wording on screen; guests and unverified residents reading nothing
and being routed correctly; the correction screen offering categories and no text
field; sending blocked until a category is chosen; a sent report carrying only a
category and a key; a failed report saying nothing was sent while hiding the
debug text; double-send prevented; and 200% text scale plus a wide surface.

Two app-wide scans were added, and one pre-existing assertion was updated: the
household capability now has a screen, so "a capability with no screen can never
be opened" was replaced by the stronger invariant that **no capability may point
at a route with weaker access** — a verified-only capability pointing at a public
route would be a leak with a green test.

One test-harness trap was hit and fixed: the hostile fixture originally used
"Juan Dela Cruz", and "San Juan" is a real barangay shown legitimately, so a
naive substring check passed for the wrong reason. The fixture now uses names
that cannot collide.

---

## 8. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| F-1 | No `GET /api/v1/me/household` | The screen renders "Not available in this app yet". Nothing is simulated. |
| F-2 | No correction endpoint | The report declines. The screen still routes the resident to the municipal hall. |
| F-3 | The five wire keys are provisional | No citizen household schema is published; these are this app's reading of what the matrix authorises. |
| F-4 | Member names and relationship labels are **withheld**, not deferred | The matrix names `Household.members` as data a citizen never receives. Showing them needs a contract change, not a feature flag. |
| F-5 | No relationship-correction beyond "my role is wrong" | There is no relationship model in the citizen contract to correct against. |
| F-6 | No programme or service context per household | No citizen endpoint exposes household-level eligibility. |
| F-7 | English only | Filipino copy arrives with app-wide localisation. |
