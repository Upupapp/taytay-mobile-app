# Taytay resident mobile — assistance history, referral and release

A resident's own longitudinal record of what they asked Taytay LGU for and what
came of it, and the line between that and the office's accounting.

Implemented in `lib/features/services/` — `domain/assistance_history.dart`,
`presentation/assistance_requests_screen.dart`,
`presentation/release_and_referral.dart`.

---

## 1. One list with two scopes, not two screens

"Where is my application?" and "what did I receive last year?" are the same
person asking about the same records. Splitting them into separate destinations
means a resident has to know which screen a request has moved to in order to find
it — and the move happens without warning, on a day the office decided something.

So `/requests` carries an **Open / Past** segmented control, and
`listOwnHistory(scope:)` is one endpoint with a filter. Both segments are always
present, so the shape of the screen does not change under a resident as their
record changes.

`/me`-scoped like everything else here: the call takes no resident identifier, so
there is no code path that could ask for somebody else's history.

---

## 2. An amount is a string the server authored

`ReleaseDetail.amountDescription` is rendered **exactly as sent** — not parsed,
not rounded, not re-symbolised. Two reasons:

* A release is often **in kind**: "one sack of rice, 25 kg". No currency
  formatter can express that, and a numeric field would force the backend to
  either lie or send null.
* Where it *is* money, the figure a resident reads must be the figure the office
  approved, character for character. An app that parses a value and re-renders it
  is one rounding rule away from telling someone they are owed a different amount
  than the record says — and the resident has no way to know which is right.

Tests assert both a peso string and an in-kind description render untouched.

---

## 3. Nothing about funding has anywhere to go

TAB 18 names the exclusions explicitly: funding and accounting internals, other
beneficiaries, staff workload, internal manifests, and approval-chain details not
intended for citizens.

`ReleaseDetail` has five fields — schedule, location, approved description,
instructions, acknowledgement — and `ReferralDetail` has five. **There is no
field for a budget line, a fund source, a disbursement batch, a manifest or
another beneficiary.** As with the case timeline in TAB 17, this is structural
rather than a filter: a filter is a line someone can weaken, an absent field is a
compile error.

A test asserts the rendered release card contains none of: *budget, fund source,
disbursement, batch, manifest, beneficiar, voucher no*.

---

## 4. A receipt is a reference, not a download

The Master Command asks for a "downloadable resident-safe receipt **only if
backend provides**". The contract publishes no document endpoint, so
`receiptReference` is a string the resident can quote, and the card says the
municipal hall can print a copy.

A download button that fetches nothing is worse than an absent one: it teaches a
resident the receipt is theirs to hold when the office's copy is still the
authoritative one, and it would need a file-storage and permission story that
TAB 16 deliberately minimised. When a document endpoint exists, this field
becomes the id it is fetched by, and the button arrives with it.

---

## 5. Acknowledgement is stated, never offered

When the office tracks receipt, the card says either *"You have confirmed you
received this"* or *"Taytay LGU will ask you to confirm receipt when you collect
this."*

There is no checkbox and no button. Acknowledging receipt is a signature at a
counter; an app that let a resident tap it in advance would record a confirmation
for something they may not have — against their own interest, in a system where
that record is the evidence.

---

## 6. "No record" and "could not load" are different sentences

An empty scope says *"You have no open requests"* or *"Nothing finished yet"*. A
failed load says *"Not available yet"* and names the municipal hall.

Showing the first one wrongly is the app telling a resident their record does not
exist — which, for someone checking whether assistance they were promised was
ever registered, is the most damaging thing it could say. The two paths are
separate branches in the screen and a test pins each.

`PlannedRequirementRepository`'s counterpart here declines for the same reason:
with `ServiceDelivery` unpublished there is no history, and an empty list would
be a claim rather than an absence.

---

## 7. Referral

Shown only when intended for the resident: destination office, what it was for,
the referral's own status, instructions, and a contact **only when the backend
published one**. A caseworker's direct line is not a published contact, and there
is no field for one.

`declined` is worded as a fact about the receiving office rather than a judgement
about the resident, and it always points somewhere — *"Taytay LGU can tell you
what happens next."* A referral that stops with no next step is how someone gives
up on a service they are entitled to.

---

## 8. Release and referral are structured once

TAB 17 carried these as prose sentences on the case detail. TAB 18 needs the same
records in the history list, and two prose representations of one record drift.
They are now `ReleaseDetail` and `ReferralDetail`, rendered by `ReleaseCard` and
`ReferralCard`, which the case screen and the history list share — along with one
date formatter, so a single record does not print three different ways.

---

## 9. Tests

`test/features/assistance_history_test.dart` — 26 tests.

* terminal detection; an unrecognised status is not assumed finished
* an entry redacts its outcome in `toString`
* empty-release detection; every referral status has wording including unknown;
  a declined referral still points somewhere
* the shipped repository declines rather than showing an empty record
* the release card prints a peso string and an in-kind description untouched,
  omits absent fields, states rather than offers acknowledgement, and carries no
  accounting vocabulary
* the referral card shows a contact only when published
* the list opens on Open and asks for it; switching to Past refetches with the
  past scope and renders the outcome and completion date
* an empty scope reads differently from a failure, and each scope has its own
  empty wording
* a card falls back to the service code; a receipt renders as a reference with no
  download control; tapping opens the case
* no staff vocabulary; guest → sign-in; unverified → verification; 200% text scale
