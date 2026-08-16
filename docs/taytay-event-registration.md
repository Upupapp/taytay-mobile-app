# Taytay resident mobile — event registration, waitlist and attendance

Registering for an LGU event, with the server keeping every decision that
matters: who may register, whether a place exists, and who got it.

Implemented in `lib/features/events/domain/event_registration.dart`,
`presentation/event_registration_controller.dart` and
`presentation/event_registration_screen.dart`.

---

## 1. The server owns capacity

Nothing in this flow decides a place is available. There is no local slot
arithmetic, no "you'll probably get in", and no pre-emptive refusal derived from
a remaining count.

A full event is discovered by **asking**, and the answer comes back as an
outcome the resident reads:

| Outcome | Reads as |
| --- | --- |
| `registered` | You are registered |
| `waitlisted` | You are on the waitlist |
| `full` | This event is full |
| `closed` | Registration has closed |
| `refused` | Taytay LGU could not register you |
| `couldNotSend` | Not registered — nothing was sent |

**`full` and `closed` are states, not faults.** They render with a neutral icon
and no retry: somebody who reached the last place a second after another person
did nothing wrong, and an error treatment would send them to a support desk over
a queue. Only `couldNotSend` offers "Try again", because only there is there
anything left to try.

The register control on the event detail appears **only on the server's own
`open` state** — not on an unrecognised one, and never inferred from capacity.
Offering it otherwise sends a resident through a form to be refused at the end
of it.

---

## 2. Idempotency

One key per attempt, reused across retries of that attempt, discarded once the
server answers. A resident who retried into a double registration would be
holding a place somebody else could have had — which is a worse failure here
than in any other flow in the app, because the cost lands on a third party.

A retry after `full`, `closed` or `refused` is a deliberate no-op: the server has
stated the position, and asking again only makes it say so twice.

A failure keeps **every answer**. The draft is untouched by failure handling.

---

## 3. Verification is the server's call, per event

The Master Command's middle case — *"Authenticated/Unverified → allow only if
event/backend permits; otherwise verification gate"* — is a per-event policy, so
the client asks rather than assumes. A barangay clean-up may take anyone with an
account; a cash-aid orientation may not.

`EventRegistrationForm.allowsUnverifiedResidents` carries the answer and
**defaults to `false`**: an absent flag means the office did not say, and sending
somebody into a verification flow they did not need is recoverable, where
registering somebody the office would have refused is not.

That is also why the **route is `authenticated`, not `verified`**. Gating at
`verified` would refuse the first case outright; gating at `public` would open a
`/me`-scoped write to a guest. `authenticated` is the honest floor, and the
screen shows a verification gate when the form asks for one.

Blocks are ordered deliberately — an existing registration is reported *before* a
verification requirement, because telling somebody who already holds a place to
go and verify themselves is nonsense.

---

## 4. The form is the office's

Fields and consents are server-defined, using the same `ServerField` /
`ServerConsent` shapes the assistance intake uses. Those types moved to
`core/forms/server_form.dart` for this TAB: duplicating them would have produced
two enums and two `isRenderable` rules over one concept, which is the drift D-79
already records. `assistance_intake.dart` aliases the old names, so TAB 15 reads
exactly as it did.

An **unrenderable field blocks registration** rather than being skipped —
registering somebody without an answer the office requires produces a place they
may lose at the door.

Consents travel as their own argument, not folded into answers: what a person
agreed to under RA 10173 is a legal record, not a form value.

---

## 5. Waitlist position and attendance

Both are shown **only when the office publishes them**.

A **waitlist position** is a statement about other people as much as about this
resident. When the server does not send one, the app says they are on the
waitlist and stops — it does not estimate.

**Attendance** is recorded after the event. `notRecorded` says so explicitly
rather than implying absence: displaying "absent" for an event whose register the
office has not finished would accuse somebody of missing something they attended.

---

## 6. No tickets, no payments, no seat maps

The Master Command rules them out, and there is nothing in this flow that could
grow into one. A test scans the rendered registration screen for *ticket*,
*payment*, *pay now*, *seat*, *price* and *checkout*.

---

## 7. A defect this TAB found in itself

The first working version flipped straight from a successful registration to
*"You are already registered"* — because `block` recomputed `alreadyRegistered`
the moment the server confirmed the place, and the blocked view outranked the
outcome view. The reference the server had just issued, which is the one thing
the resident came for, never appeared.

`block` now returns `null` once an attempt has produced an outcome. Two tests pin
it: a short form registering end to end and showing its reference, and a waitlist
outcome showing its position.

---

## 8. Tests

`test/features/event_registration_test.dart` — 34 tests.

* the shipped repository declines form, register and cancel
* `full` is an outcome not a failure; `full`/`closed` are not retried
* a retry replays one key; a success retires it; a failure keeps every answer
* unverified blocked when the event says so, permitted when it says otherwise;
  the flag defaults false; an existing registration outranks verification
* an unrenderable field blocks; required fields and consents enforced; optional
  fields may be blank; a number field rejects text; steps derived from the form;
  consents travel as their own field
* a waitlist position only when sent; registered and waitlisted both hold a
  place; the record redacts its reference
* the route is `authenticated`; a guest goes to sign-in; an unverified resident
  reaches the screen and is gated *there*
* an absent backend explains; a short form registers end to end; waitlist shows
  its position; a full event reads as a state; a send failure offers a retry;
  an already-registered resident is told rather than re-asked; no ticketing
  vocabulary; 200% text scale
* the detail shows attendance only when recorded, `notRecorded` says so, the
  register control appears only on `open`, and tapping it opens the flow
