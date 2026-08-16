# Taytay resident mobile — events discovery and detail

What the LGU has scheduled, when it happens in the clock it happens in, and
where — without this app inventing a link, a place or a number.

Implemented in `lib/features/events/`, `lib/core/time/manila_time.dart` and
`lib/core/links/`.

---

## 1. Asia/Manila, stated

The Master Command asks for "date/time and Asia/Manila clarity", and it is the
requirement with the most failure modes behind it.

A phone can be set to any timezone, and often is: a handset bought abroad, one
whose automatic timezone is off, an OFW reading a Taytay schedule from Dubai.
Rendering an event in the *device's* local time is worse than useless — the
resident arrives on the wrong day.

So every LGU time is rendered in **Manila** time and **says so**. `PHT` on the
end of a timestamp is not decoration; it is what makes the number unambiguous.

### A fixed offset, not a timezone database

The Philippines observes **UTC+08:00 all year** and has had no DST since 1978.
That rule fits in one constant and cannot drift, where a tz database is ~400KB of
install size, a dependency to keep current, and a bug when it is not. If the
country ever reintroduces DST, `ManilaTime.offset` is the single line that
changes and every date moves with it.

Two rendering decisions:

* **Dates are written out** — `05 Aug 2026`, never `05/08/2026`, which is the
  fifth of August to a Filipino reader and the eighth of May to an American one.
* **A range repeats the day when it changes.** `10:00 PM – 2:00 AM` collapsed to
  one date misreports an event running past midnight, which is exactly the kind
  that does.

---

## 2. Links this app is willing to open

A directions URL comes from the **server**, and a URL from a payload is
attacker-influenced in the same way a path parameter is. Handing one straight to
the platform launcher is how an app opens a `javascript:` URI, a `file:` URI
pointing at its own sandbox, or an `intent:` URI starting another app's private
activity.

`ExternalLink.isSafe` therefore requires a well-formed absolute **`https`** URL
with a host, and refuses everything else rather than repairing it — repairing an
untrusted URL is guessing at what somebody meant, and the safe guess does not
exist. **`http` is refused too**: the constitution already forbids cleartext for
the API, and a link an intermediary can rewrite would send a resident somewhere
the LGU did not choose.

The "Open directions" control appears only when the server supplied a link that
passes. **The app never composes one** — the same rule as an announcement's share
link (D-104): this client does not know which mapping service the LGU uses or how
it addresses a barangay hall, and a guessed URL sends a resident to the wrong
place, which is the exact failure a directions link exists to prevent.

When the launcher refuses, the copy says the *app* declined it. When the device
has nothing to open it with, the copy says that instead. Blaming the phone for an
app decision is a small lie that costs a resident a support call.

---

## 3. Places left are stated, never computed

`EventCapacity.remaining` is shown only when the server sent it. The app **never**
subtracts a registered count from a capacity: a number computed from a page that
is thirty seconds stale tells a resident there is room when there is not, and
they travel for nothing. `isFull` is likewise true only when the server said so.

---

## 4. Three scopes, one collection

Upcoming · Registered · Past — filtered by the server, not re-sorted by the app.
The office decides the order.

**"Registered" is not shown to a guest at all.** An empty "My events" would imply
they had lost registrations they never had. The check goes through
`AccessPolicy`, not an `accessLevel` comparison — the repo's own security scan
catches the latter, and it caught this during development. One place decides
"may this person see it".

`isPast` is decided by the event's **end** where there is one, so an event still
running is not filed as past halfway through it.

---

## 5. Publication state

Same asymmetry as the newsfeed (D-92): an unrecognised state is **shown** because
the server chose to send it; a recognised non-public one — draft, scheduled,
archived — is **hidden**, because a cancelled fun run advertised as current sends
people out on a Saturday morning for nothing.

Applied at **two doors**: the list filters, and the detail screen refuses to open
a withdrawn event reached from a stale link or a notification.

---

## 6. Registration is displayed, not offered

This TAB shows the registration state the server reports and has **no register
button**. Registration is TAB 22, where capacity and waitlist rules belong
together; a control here that could not complete would be worse than none.

The detail screen says so in words, so a resident does not leave believing they
have a place: *"Registering in this app is not switched on yet. The office above
can tell you how to join."*

There is no create, edit, publish, cancel or capacity control anywhere, and no
repository method that could express one.

---

## 7. Tests

`test/features/events_test.dart` — 37 tests.

* Manila time: UTC → PH wall time; a device in another timezone reads the same;
  midnight and noon in 12-hour; same-day ranges collapse; ranges crossing
  midnight repeat the day; the offset is +08:00 with no DST
* links: `https` accepted; `http`, `javascript:`, `file:`, `intent:`, `geo:`,
  scheme-relative, bare host and empty-host all refused; a venue offers
  directions only for a safe link; the unavailable service distinguishes refused
  from absent
* visibility: published shown, withdrawn hidden, unrecognised shown; past decided
  by the end; capacity stated never computed; the shipped repository declines
* controller: non-visible events filtered; scope change refetches; re-selecting
  the same scope does not; a page failure keeps the list; first-page failure is
  distinct from empty
* list: a guest browses and sees no "Registered"; a signed-in resident gets it;
  the card states the time with its clock; remaining places only when stated; a
  held registration is called out; failure ≠ empty; no management control;
  tapping opens the event
* detail: a guest reads everything; directions only for a safe server link, and
  it opens; an unopenable link blames the device; a withdrawn event does not open
  from a stale link; registering is stated as unavailable; a full event says so;
  200% text scale
