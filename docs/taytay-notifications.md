# Taytay resident mobile — notifications, push, inbox and deep links

Connecting residents to workflow updates without spending the one chance the LGU
has to reach them, and without putting a case detail on a lock screen.

Implemented in `lib/core/push/push_service.dart` and
`lib/features/notifications/`.

---

## 1. The push prompt waits for a meaningful moment

The Master Command says the prompt must come "at a meaningful moment, not
immediately on first frame". That is easy to agree with and easy to lose — the
prompt is one line, and the tempting place for it is `initState` on the root
widget.

It matters because the OS permission is **one-shot**. On iOS a refusal is
permanent: the app cannot ask again, and the resident has to find it in Settings.
A prompt fired before the app has done anything for them is not merely rude, it
spends the LGU's only chance to reach that person about a case they have not yet
opened. And the people most likely to dismiss a cold prompt are the people least
familiar with the app — who are the people most in need of being told their
assistance was approved.

So the rule is a pure function with tests rather than a convention somebody
remembers:

```
shouldPrompt = moment != null
             && permission == notRequested
             && !hasPromptedBefore
```

A `PushMoment` is something the resident just did that the LGU will follow up on
— submitted an assistance request, sent a document, registered for an event, sent
identity documents. Each carries a reason shown **before** the OS dialog, naming
what they just did, so the one-shot system prompt is answered by somebody who
knows what it is for.

---

## 2. No push SDK until there is an endpoint

`PushService` is an interface with `UnavailablePushService` behind it. The
`Notification` module is `planned`: there is no endpoint to register a token
with and nothing to send one.

Adding a push SDK now would ship a third-party service that collects a device
identifier for a feature that cannot work. On a government app, a dependency
that phones home before it does anything useful is the wrong default. The seam
exists, the timing is decided and tested, and the implementation lands with the
endpoint.

A push token is a **stable device identifier**: it is sent to the backend and
never logged, cached or put in an analytics event.

---

## 3. A payload is a destination, not content

`PushPayload.toString()` redacts **everything, including the keys** — a payload
that wrongly carried a personal field would otherwise be copied into a log by the
very code meant to catch it.

Tapping resolves through `DeepLink` (TAB 10), which already:

* **rejects** a payload carrying a personal key rather than sanitising it — a
  payload with a resident's name has been mishandled server-side, and quietly
  dropping the field would hide a contract breach that needs fixing at source;
* **refuses** any target that would act (`cancel_request`, `confirm`, `approve`,
  `delete_account`);
* resolves only to places reachable by tapping through the app anyway.

The screen it lands on fetches its own detail under the live session. That is the
Master Command's rule — authorized detail is fetched after the tap, never read
from the message — and the router's guard re-evaluates access on the way in, so
an expired session lands on sign-in rather than on an empty screen.

A message whose target cannot be resolved **still reads**: the title and body are
the LGU's words to this resident, and dropping the row would hide the message as
well as the link.

---

## 4. Categories, and the two that have no switch

Nine categories, from the Master Command's list, each mapping to a workflow the
LGU actually runs — which is what makes a preference toggle meaningful rather
than a wall of switches nobody reads.

**Public advisories and account/security notices have no switch.** They are the
reason a municipality has a notification channel at all, and offering to silence
them would be offering a setting the LGU must then ignore. `withCategory` refuses
to record one as off even if a caller tries, and the screen says plainly why they
are always sent.

**A category the backend has not set defaults to on.** An absent entry means it
has not been chosen; defaulting a municipal message to off because a field was
missing is the wrong failure.

Preferences live on the server, not the device: a resident who silences SMS on
one phone expects it silenced everywhere.

---

## 5. The inbox

**Grouped by recency, not by date heading** — "Today", "Earlier this week",
"Earlier this month", "Older". That is what a resident is asking when they open
an inbox; a run of date headers makes them do the arithmetic.

Grouping uses **Manila days**. A message sent at 9 AM in Taytay reads as "today"
for a resident whose phone is set to another timezone, not as yesterday.

Empty groups are omitted rather than shown as headings with nothing under them,
and the server's order is kept inside each group.

**Reading is optimistic and reconciles.** Tapping clears the unread mark
immediately — a badge that lingers after a tap reads as a broken app — and the
mark comes back if the server refuses, because a badge that cleared for something
the server never recorded loses the resident track of what they have seen. Same
for "Mark all read", which restores the whole list on failure and is a no-op when
nothing is unread.

Unread is a dot **and** a weight **and** a semantic label, so a screen reader
hears it rather than inferring it from styling.

---

## 6. Access

`/notifications` and `/notifications/settings` are **authenticated, not
verified**. A notification is addressed to a person, not to a confirmed civil
record — and an unverified resident going through verification is precisely who
needs to be told when it completes.

A guest has no inbox and is sent to sign-in; public advisories remain readable in
the newsfeed, which is open to them.

---

## 7. Tests

`test/features/notifications_test.dart` — 36 tests.

* push timing: never on first frame; prompts after a qualifying moment; never
  asks twice; never re-asks after any decision; every moment has a reason naming
  the LGU; the shipped service reports unsupported; a payload redacts itself
  including its keys
* categories: critical ones cannot be switched off even by a direct call; the
  switchable list excludes them; an unset category defaults on; switching one
  moves nothing else; the shipped repository declines everything
* grouping: today / week / month / older / undated; Manila days rather than the
  device clock; empty groups omitted; server order kept
* reading: optimistic clear; a refusal restores; a second mark does not re-call;
  mark-all restores on failure and no-ops when nothing is unread
* screen: guest → sign-in; an unverified resident reads their inbox; absent
  backend ≠ empty inbox; category and Manila time shown; a targeted tap opens
  that place; an action payload is refused; a payload carrying a name is
  refused; an untargeted message still reads; mark-all appears only when
  something is unread; 200% text scale
* preferences: critical categories have no switch and it says why; turning one
  off saves it; a failed save puts the switch back and says so; an absent
  backend explains
