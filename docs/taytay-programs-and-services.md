# Taytay resident mobile — programs and services directory

What the LGU offers, who it is meant to help, and the line this app will not
cross between publishing guidance and making a decision.

Implemented in `lib/features/services/` and `lib/features/programs/`.

---

## 1. Two surfaces, because the contract has two rows

| | Endpoint | Auth | Status |
| --- | --- | --- | --- |
| **Service catalogue** | `GET /api/v1/services` | **public** | **implemented** |
| **Assistance programmes** | `GET /api/v1/programs?status=active` | **bearer** | `planned` |

A guest browses services freely; programmes ask for sign-in. **That line is the
server's, not a product preference**, and drawing it in the client means a
resident is told before the request rather than by a `401`.

The service catalogue is the one repository in this app backed by a real,
implemented endpoint — which makes it the surface that carries acceptance 1.

---

## 2. Guests can use the directory — acceptance 1

`GET /api/v1/services` is unauthenticated with the reason written into the route
file: *"citizens must be able to browse it before registering."* A guest gets the
full list, search, category filters, and every detail screen, with no gate
anywhere and no personal read of any kind.

Deep links work for them too: `/services/CEDULA` opens for a guest exactly as it
does for a verified resident.

---

## 3. Search runs on the phone

The endpoint accepts `?category=` and `?channel=`, and **no `?search=`**. A
server-side search would have to be invented — but the local choice is also the
better one, and for a reason worth stating:

> A search term is a disclosure. "burial assistance", "solo parent", "medical" —
> typed into a municipal app by a named account — is a sentence about somebody's
> circumstances.

Filtering on the device means the LGU never learns what a resident was looking
for, and the catalogue is small enough that it costs nothing. Search matches
name, description and the server's category label; it deliberately does **not**
match the code, because `JOBFAIR` is not a word a resident searches for and
matching it produces a result they cannot explain.

Category chips are built from what was actually returned, so the row never
offers a filter that would produce an empty list or advertises a category the LGU
does not currently publish.

Empty and no-match are different sentences — "No services listed yet" versus
"Nothing matches that", with a clear-filters action on the second.

---

## 4. Guidance, never a verdict — acceptance 2

**The app has nowhere to put a rule.** `EligibilityCriterion` carries the
office's own sentence and an optional grouping label. There is no operator, no
threshold and no field to compare a resident against, so no screen can evaluate
anything. `eligibility_rules` — a machine-readable rule set — is in the forbidden
key list precisely because it is what would make local evaluation possible.

The visibility matrix is explicit that publishing the criteria is the point:

> *"Eligibility rules are deliberately public. Publishing the criteria for a
> public benefit is good administration, and it lets a citizen self-screen
> instead of queueing to be refused."*

Self-screen — by **reading**, and deciding for themselves.

An app that evaluated eligibility locally would be a second rule set: it would
drift from the office's the moment either changed, it would be wrong in a
released build nobody can patch quickly, and — worst — it would tell a resident
they do not qualify for a benefit they are entitled to, at which point they stop
asking.

**The maximum grant is text**, not a number, so no arithmetic can turn a ceiling
into "you will receive ₱10,000".

**Requirements are optional only when the server says so.** Never inferred:
telling somebody a document is optional when it is not sends them home from a
counter.

Two app-wide scans enforce this: no file may declare `isEligible`, `canApply`,
`qualifies`, `computeEligibility`, `approvalChance` or `incomeCeiling`; and no
file may model `slotsRemaining`, `budgetRemaining`, `beneficiaryCount`,
`priorityScore`, `queuePosition` or `fundingSource`.

A widget test scans the rendered programme detail for "you qualify for", "you are
eligible", "you will receive", "has been approved" and "guaranteed" — while the
*correct* copy, "whether you qualify is decided by staff", passes.

---

## 5. Availability stays backend-driven — acceptance 3

**The app never turns dates into "open" or "closed".** `availabilityNote` quotes
what the office published — "Taytay LGU lists this for 1 January to 31 December"
— and nothing more.

A window that has passed on a resident's phone clock may still be open at the
counter: an office extends a deadline far more often than it publishes the
extension the same afternoon. An app that said "closed" would send somebody away
from help they could still have received.

**Status is refused, not interpreted.** The citizen row is `?status=active`, so a
programme reaching this app is active by construction — and the decoder
additionally **drops anything whose status is not `active`**, including an absent
one. A server change that widened the projection could not leak a draft
programme into a resident's list.

**Staleness is explicit.** When a refresh fails and previously-loaded entries are
still on screen, a banner says *"Showing what was saved on your phone"* and warns
against relying on dates or requirements. Silently keeping the old list would
show a resident a window that closed last week and look identical to a working
app.

---

## 6. Access-aware CTAs that never act by themselves

| Session | Tapping "How to apply" |
| --- | --- |
| Guest | Sign-in gate, intent held |
| Authenticated, unverified | Verification gate, intent held |
| Verified | Guidance: bring the listed documents to the municipal hall |

Every branch goes through `CapabilityService` — the same evaluation the router
and every tile use — and every refusal holds a **bounded** intent (a kind plus
the programme or service `code`, nothing else).

**No branch submits anything.** `POST /api/v1/me/assistance-requests` is
`planned`, so there is nothing to send; and even once there is, a resident
arriving straight back from a sign-in gate must be *shown* what applying involves
rather than have it done for them. The screen says so under the button: *"Nothing
is submitted by tapping this."*

---

## 7. Deep links and identifiers

`/services/:serviceCode` and `/programs/:programCode`, both using the **stable
code** rather than the UUID. A code is what a municipal office quotes, it is
legible in a link, it survives a re-seed of the catalogue, and it fits the
deep-link character class unchanged.

Both are registered as `DeepLink` targets (`service`, `program`, `programs`), so
they inherit TAB 10's rules whole: an allow-listed target, one bounded
identifier, PII keys rejected, no action targets, and the guard re-authorising
the resolved route against the live session.

**There is no service-detail endpoint** — the contract has the list and nothing
addressed by id — so the detail screen loads the catalogue and finds the entry by
code. Inventing `/services/{id}` would be a contract the server never agreed to.

---

## 8. What the decoder refuses

`ProgramDto` reads fourteen keys, every one marked ✅ for a citizen in the
visibility matrix §5. Eighteen forbidden keys in four groups:

| Group | Keys |
| --- | --- |
| Marked ⛔ in the matrix | `funding_source` (*"meaningless and misleading to an applicant"*), `audit`, `created_by`, `updated_by` |
| Operational capacity | `slots_remaining`, `quota`, `capacity`, `budget_remaining`, `beneficiary_count` |
| Ranking and rules | `priority_score`, `ranking`, `weight`, `eligibility_rules` |
| Draft and internal | `internal_notes`, `remarks`, `draft`, `applicants`, `beneficiaries` |

A hostile-payload test feeds all eighteen and asserts none survives. A malformed
or non-active entry is **dropped rather than failing the page**: one bad row must
not take the whole directory down.

---

## 9. Verification

`dart format` clean · `flutter analyze` clean · **712 tests pass** · debug and
release APKs build.

TAB 14 coverage (44 tests): local search issuing no request; matching name,
description and category but never the code; category toggling; combined
filters; categories offered being only those returned; lookup by code and not by
UUID; a failed refresh keeping entries and flagging them stale; a first-load
failure having nothing to show; a criterion having nowhere to put a rule; no
source computing eligibility or promising approval; availability quoted and never
computed into open or closed; the maximum grant staying text; the
hostile-payload decoder across all eighteen forbidden keys; a machine-readable
rule set ignored; non-active and unstated statuses refused; entries without a
code or name refused; a bad entry dropped without taking the page down;
eligibility and requirements read in both shapes; allow and forbidden sets
disjoint; the shipped repository declining; services public and programmes
authenticated; path resolution; both deep links resolving with bounded codes; a
guest browsing, searching and opening detail without a gate; unknown codes
handled; empty versus no-match; an unreachable catalogue; a guest fetching no
programmes; a signed-in resident seeing the guidance notice; a guest deep-link to
a programme fetching nothing; eligibility labelled as guidelines; no promise on
screen; requirements and details rendering only published fields; the CTA
explaining and submitting nothing; the verification gate holding a bounded
intent; and 200% text scale plus a wide surface.

Two app-wide scans were added. One UI ambiguity was fixed on the way: "How to
apply" appeared as both a detail label and the button, which is ambiguous for a
screen reader as well as for a test — the label is now "Where to apply".

Two fixture traps recurred and were fixed: `12` collides with the legal basis
"Ordinance 2019-12", and the *correct* copy "whether you qualify is decided by
staff" contains "you qualify", so promise checks assert phrases rather than
words.

---

## 10. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| S-1 | No `GET /api/v1/programs` for citizens yet | The programmes list and detail decline honestly. Nothing is simulated. |
| S-2 | The fourteen programme wire keys are provisional | The matrix names the citizen *fields*; it does not publish their JSON spelling. |
| S-3 | No service-detail endpoint | Detail is rendered from the list. A very large catalogue would want a detail route. |
| S-4 | No application endpoint | Every CTA is guidance. `POST /me/assistance-requests` is `planned`. |
| S-5 | Search and filter are local | Correct for a small catalogue and better for privacy; a large one would need server-side paging, and then a search term would leave the device. |
| S-6 | No offline persistence | "Stale" means "loaded earlier this session". `PublicCache` is in-memory and dies with the process; nothing is written to disk. |
| S-7 | English only | Filipino copy arrives with app-wide localisation. |
