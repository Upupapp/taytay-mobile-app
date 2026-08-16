# Network loss, degraded UX and performance

TAB 25. What the app does on the connections many Taytay residents actually have,
and what it refuses to claim while it is on one.

---

## The rule everything here serves

**Nothing is ever shown as sent, saved or successful until Taytay LGU says so.**

That is the Master Command's first acceptance criterion for this TAB, and on a
government app it is the difference between a resident who chases a stalled
application and one who waits at home for a decision on an application that was
never filed. Every mechanism below either serves that rule or gets out of its
way.

---

## Reachability is observed, never guessed

`lib/core/network/network_monitor.dart`

The obvious implementation reads the radio: `connectivity_plus` reports "wifi",
"mobile" or "none". **It answers a different question.** A phone on a
captive-portal wifi at a barangay hall, a phone with data enabled and no load
balance, and a phone on a signal too weak to finish a handshake all report
"connected" and can reach nothing. The reverse happens too — a radio callback
arrives late and the app claims to be offline while a request is succeeding.

So `NetworkMonitor` answers the question the resident is actually asking — *did
that reach the office?* — from the only evidence that settles it:

| Observation | Verdict | Why |
| --- | --- | --- |
| Any `Ok` | reachable | The server answered. |
| `NetworkFailure` | unreachable | The request never arrived. |
| `TimeoutFailure` | unreachable | It may have arrived; it did not come back. |
| `403` / `404` / `409` / `422` / `429` / `500` / `401` | **reachable** | That is the **server** speaking. |

The last row is the one that matters. A screen showing "you appear to be offline"
over a `403` sends a resident to a load-up stall over a permission decision, and
a resident who does that once stops reading the banner (D-145).

It also avoids a dependency. Article 1 requires a permissions and data-egress
review for any package that touches networking; adding one to learn something the
app can already observe more accurately is a trade this app does not make (D-146).

`ApiClient` reports every outcome, in one place. A feature reporting it
separately is a feature that can forget to. **Nothing personal reaches the
monitor** — no URL, no payload, no identifier, only a verdict, a count and two
timestamps, and `toString` is asserted to carry none of them.

### Two failures, not one

`shouldWarn` requires **two consecutive** failures. One dropped request on a
Philippine mobile connection is ordinary; a banner that fires on every one of
them flashes on every jeepney ride and is scrolled past by the time it matters
(D-147).

`NetworkStatus.unknown` is the cold-start state and is **not** offline. The app
genuinely does not know until it has tried.

`reset()` is **not** called on sign-out: reachability is a fact about the
connection, not about the resident, and clearing it would hide a genuine outage
from the next person to pick up the phone.

---

## The offline banner

`OfflineBanner`, wired once into `RootShell` — above the branch content on the
bar layout and beside the rail on the wide one. Reachability is one app-wide
fact, and a per-screen banner is a banner some screens forget (D-148).

It says **"Not reaching Taytay LGU"**, not "you appear to be offline". The second
is a guess about the resident's phone; the first is what the app actually knows.

It disappears the moment anything gets through.

---

## Cached public content

`lib/core/storage/public_cache.dart`

### What may be cached

Responses to requests that were **not authenticated**, for paths on an explicit
allow-list: `services`, `health`, `announcements`, `events`, `programs`. `store`
takes `authenticated` as a **required** argument and refuses when it is true — a
caller cannot pass a personal response in by omission. The usual way personal
data ends up in a cache is not a decision, it is a generic wrapper applied to one
more endpoint.

### A defect this TAB fixed

The cache keyed entries by **path alone**. `services` was one key whatever the
query, so page 3 would have been served to a request for page 1, and the health
category's results to a request for social welfare. Nothing read from the cache
yet, so it had never fired — but this is the TAB that starts reading from it.

The key is now the path **and** its query, with parameters sorted so two
equivalent requests produce one entry. The allow-list is still checked against
the path, because what is public is a property of the endpoint, not of its
arguments (D-149).

`ServiceCatalogApiRepository` builds that query in one private helper used by
both the request and the cache lookup, which is what makes the two keys match.

### Serving stale on purpose

Two doors, and they behave differently:

| Method | Behaviour |
| --- | --- |
| `read` | Fresh only. **Evicts** a stale entry rather than returning it. |
| `readAllowingStale` | Returns it anyway, with `storedAt` and `isFresh` attached. Does not evict. |

A caller that receives data from `read` has no obligation to check whether it
should have. `readAllowingStale` is the deliberate opposite, and taking it
carries an obligation: the age comes back **attached to the value**, so the
screen showing it can say how old it is (D-150).

`ServiceCatalogRepository.lastKnownServices()` is the domain-level version of
that door — separate from `listServices` and synchronous, so nothing is ever
served from cache behind a caller's back.

`ServiceDirectoryController` uses it only when a load fails **and** it has
nothing on screen — a rebuilt controller, or a first load that never landed. It
adopts the cache's own `storedAt` as `loadedAt`, so the screen states when the
office answered rather than when the app gave up.

### Why in memory, and what that costs

Nothing is written to disk. A disk cache of public data would be legitimate, but
it introduces a file whose contents must be reviewed on every future change to
what passes through it, and the first authenticated response that reaches it by
mistake is personal data at rest, in clear text, outside the keystore.

**The cost, stated plainly:** a resident who force-quits the app and reopens it
on a dead connection sees nothing, where a disk cache would have shown them
yesterday's announcements. Within a process they keep everything. That is the
trade, and it is the same one `PublicCache` made before offline support existed
(D-151).

An entry ceiling (`maxEntries`, oldest first) keeps a long scroll from making the
cache the reason a low-memory phone kills the app.

---

## Last-updated and unsent

Three shared widgets, in `lib/shared/widgets/network_status_views.dart`.

**`StaleContentNotice`** states the age in Manila time and renders **nothing**
when the content is fresh. A timestamp on every screen is noise, and noise is how
the one that matters gets missed. A resident acting on a three-hour-old
announcement about a relief distribution needs to know it is three hours old
before they walk to the covered court.

The services screen's own stale banner now carries `Last updated <Manila
timestamp>` alongside its "check with the municipal hall" line — the timestamp
was missing, and the Master Command asks for it explicitly.

**`UnsentNotice`** says **"Not sent yet"** and never "saved" (D-152). "Saved" is
the word that breaks the rule this whole TAB serves: a resident who reads "saved"
on an assistance request believes the office has it. So the copy states what is
true from their side — Taytay LGU does not have it, everything typed is still on
the phone, and **sending again does not create a duplicate**, which is true
because every mutation in this app carries an idempotency key.

**`OfflineBanner`** as above.

---

## Performance audit

### Images — the one that would actually have hurt

`lib/shared/widgets/remote_image.dart`

`Image.network` decodes at **source** resolution. A 4000×3000 cover photo
uploaded from a staff phone is roughly **48 MB of ARGB in memory**, per card,
while being drawn into a 360 dp-wide box. Three on screen during a scroll is
enough to get the app killed on the sub-2 GB Android devices a large part of
Taytay uses.

`RemoteImage` measures its box, multiplies by the view's device pixel ratio, and
passes the result as `cacheWidth`:

| | Source decode | Right-sized decode |
| --- | --- | --- |
| 4000×3000 in a 360×203 dp card at 3× | ~48 MB | ~2.6 MB |

An **18× reduction**, visually identical, because the extra pixels were never
displayable (D-153). A ceiling caps it: `feedDecodeCeiling` 1440 px for a list,
`fullScreenDecodeCeiling` 2560 px for a picture opened on its own — the Master
Command's "thumbnail vs full-size media".

Both existing call sites — the news cover and the event cover — now go through
it. Each already reserved its space and had an error fallback; those behaviours
are preserved and now live in one place.

`RemoteImage.configureImageCache()` runs once in `main`, before the first frame:
300 entries / 64 MB. Resizing the image cache during a scroll evicts everything
it holds, which is the opposite of the intent.

**Still no disk cache**, and no `cached_network_image`. Same reasoning as
`PublicCache`, plus its transitive `sqflite` + `path_provider` write a store
keyed by URL that nothing stops an authenticated media URL from entering later.

### Lists — already correct, verified

Every feed uses `ListView.builder`: news, events, notifications, the service
directory, assistance requests, assistance history. The `ListView(children:)`
instances are all fixed-length detail and settings screens, where a builder would
add indirection for no gain.

Pagination is the server's `hasMore`, never a short page (D-94), and a page
failure keeps the pages already read (D-95). Both predate this TAB and are
unchanged.

### No infinite spinners

The guarantee is structural rather than a convention: `AppConfig.requestTimeout`
is finite, `ApiClient` applies it to every request, and every fallible call
returns a `Result` that resolves. A test asserts the timeout is both non-zero and
no longer than 30 seconds — a resident staring at a spinner for more than half a
minute has already decided the app is broken — and a second asserts that a failed
load lands on a terminal state with no `CircularProgressIndicator` left on
screen.

### Motion

`Motion.reduced(context)` is honoured throughout, and the offline banner's
`AnimatedSize` collapses to `MotionTokens.instant` under it. Decorative motion
disappears; functional motion shortens.

### Startup

`main` does three things before `runApp`: bind, size the image cache, resolve
config. No network call, no disk read, no plugin initialisation. Session
restoration is asynchronous and the router **waits** on protected routes rather
than resolving them to "signed out" — deciding early signs a returning resident
out on every cold start.

### Not measured here

DevTools timeline traces and a scroll profile on a physical mid-range Android
device. The decode ceiling is the change that moves that number, and it is
reasoned from Flutter's documented decode behaviour and asserted in a test rather
than from a trace. **Running one on a real device is outstanding** and is listed
as an environment gap.

---

## Tests

`test/core/network_and_cache_test.dart` — 25 tests.
Monitor verdicts for every failure kind, the two-failure threshold, notification
economy, `unreachableSince` as the start of a run, redacted `toString`; the
client reporting outcomes and **not** reporting a request it never attempted;
cache keying by query, sorted parameters, page-3-for-page-1, the allow-list on
the path, refusal of authenticated responses, stale reads that keep the entry,
and oldest-first eviction.

`test/features/offline_test.dart` — 25 tests.
The banner absent at unknown, absent after one failure, present after two, gone
on success, **never over a server refusal**, present on both shell layouts; an
expired session not raising it; no false success and no "saved"; the stale notice
silent when fresh and stating Manila time when not; `RemoteImage` decode sizing,
ceiling, semantics and reserved space; the catalogue falling back to what was
actually fetched and stating when the office answered.

---

## What this TAB deliberately does not do

* **No offline queue for submissions.** An assistance request held on the phone
  and sent later is a request whose eligibility, capacity and deadlines were all
  evaluated against a state that has since moved. The Master Command asks for
  drafts labelled unsent, not for background delivery, and the difference is the
  whole point of the rule at the top of this file.
* **No disk cache**, for the reasons above.
* **No radio-state plugin**, for the reasons above.
* **No prefetching.** Fetching pages a resident has not asked for spends data
  they are paying for by the megabyte.
