# Offline, caching and degraded mode

The per-feature policy the Master Command asks to be written **before** the
implementation. It lives in code as `lib/core/storage/offline_policy.dart`, and
`test/core/offline_policy_test.dart` fails when the code stops matching it — in
both directions, so a path in the cache and not the policy is caught as an
undocumented cache, and a path in the policy and not the cache is caught as a
promise the app does not keep.

## Three postures, and the boundary is who the data is about

| Posture | Meaning |
| --- | --- |
| **Stale-readable** | Cached, readable offline, and readable *old* — with its age shown |
| **Online-only** | Not cached. Needs a connection and says so |
| **Never cached** | Not cached, and re-read on every use even when a connection exists |

**Public municipal content is the same for everybody**, so a stale copy is a
service rather than a risk. A resident who opens the app to check which documents
a clearance needs should get that answer on a dead connection — that is most of
what this app is for on a weak network.

**Anything about one resident is not cached at all.** Not encrypted-and-cached:
not cached. Shared handsets are ordinary in this user base, and a cached case
narrative, inbox or household record is the most likely privacy incident this app
can have. The Master Command permits encrypting personal data at rest and
clearing it on sign-out; this app takes the stricter option because the weaker
one depends on sign-out actually happening, and the phone that gets handed to a
relative is precisely the one nobody signed out of.

**Authority-shaped values are never cached, even briefly.** A cached "verified"
is a permission the server did not grant today.

## What is cacheable

`services` · `programs` · `newsfeed` · `events` · `health`

That list is the cache's allow-list and the policy's, asserted equal. Note what
is *not* on it despite sitting next to something that is: **event availability**.
The listing is public and cacheable; the availability inside it is derived
server-side on every read, because a cached copy always wins the check that reads
it (ADR 0030 §2). A stale "open" sends somebody to a covered court for a place
that went hours ago.

## Two rules that make the allow-list safe

1. **An authenticated response is never stored, whatever its path.** The server
   downgrades the cache directive to `private` the moment there is a caller
   behind the request, because the same URL returns drafts to staff. The client
   honours that by refusing to store any authenticated response at all.
2. **The cache key is path *and* sorted query.** A key of `services` alone would
   store page 3 and serve it to a request for page 1.

## There is no offline write queue, and that is a decision

The Master Command allows queuing genuinely idempotent writes. This app does not
queue any, and the reason is that the writes it has are the wrong ones for a
queue — **their meaning depends on when they arrive**:

* An **event registration** queued on Tuesday and sent on Thursday claims a place
  at an event that filled on Wednesday.
* An **assistance submission** sent from a queue reaches the office after the
  resident has already walked in and asked in person — which is what somebody
  does when the app said nothing happened.
* A **document upload** is large, and replaying it silently on a metered
  connection spends money the resident did not agree to spend then.

What the app does instead is say **"not sent"**, never "saved". A resident who
reads "saved" on an assistance request believes the office has it and stops
chasing it; one who reads "not sent" chases it themselves, which is the outcome
that actually gets them help.

Adding a queue later is a deliberate act, and a test exists so that whoever adds
one meets this reasoning first.

## Captive portals

A request that succeeds at the socket level and returns a login page is treated
as a connectivity problem, not a server fault — the envelope decoder reports
non-JSON as a `ContractFailure` and the network monitor infers reachability from
observed outcomes rather than from a radio flag. A banner over a 403 would send
somebody to a barangay hall over a permission decision.

## What is not proven

No airplane-mode journey has been run on a device. The policy is asserted against
the cache's behaviour in tests; it has not been walked through on a handset with
the radio off, and TAB 23 owns that.
