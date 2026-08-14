# Taytay resident mobile — root shell, navigation and access gating

How a resident moves through the app, who may see what, and what happens when a
notification link arrives.

Implemented in `lib/features/shell/`, `lib/core/router/` and
`lib/core/session/resident_capability.dart`.

---

## 1. Five destinations, and only five

| # | Destination | Route | Requirement |
| --- | --- | --- | --- |
| 1 | Home | `/home` | public |
| 2 | Services | `/services` | public |
| 3 | News | `/news` | public |
| 4 | Events | `/events` | public |
| 5 | Profile | `/profile` | public |

**The same five, in the same order, for a guest, an unverified resident and a
verified resident** — acceptance 3. Three reasons, in the order they matter:

1. **Learnability.** Municipal software is used rarely and under pressure — a
   deadline, a queue, a form somebody needs today. Navigation that moves between
   visits has to be relearned every visit, and the people worst served by that
   are the ones with the least practice.
2. **Stability discloses nothing.** The catalogue is public and the server
   authorises every request, so a visible tab is not a leak. What a *growing* tab
   bar leaks is that this person's status changed — visible to anyone glancing at
   their phone.
3. **Verifiability.** "Five, never varying" is one assertion that holds forever.
   "The right subset for each of three states" is nine that drift.

Every destination route is therefore `public`, asserted by a test: a tab that
redirected would be a tab that bounces. What varies is the *content*, and only
where the content is genuinely gated — which is where the explanation belongs.

**Profile is public on purpose.** It has to open for a guest, and for them it is
not a locked door but the explanation of what an account is for.

---

## 2. Three layouts, one information architecture

`ShellLayout` uses the published Material 3 window size classes:

| Class | Width | Navigation |
| --- | --- | --- |
| compact | `< 600` | `NavigationBar` |
| medium | `600–839` | collapsed `NavigationRail`, labels shown |
| expanded | `≥ 840` | extended `NavigationRail` |

Driven by `LayoutBuilder`, not `MediaQuery`: on a foldable or in split-screen the
space the shell is given is not the size of the window.

**The routes are identical at every width.** `/services` is `/services` on a
phone and on a tablet; a deep link lands in the same place; a resident told "open
the Services tab" by an LGU clerk finds it either way. Labels are always visible —
icon-only navigation is a memory test, and the icons for News and Events are not
distinguishable to someone who opens the app twice a year.

`StatefulShellRoute.indexedStack` gives each destination its own navigator, so
switching tabs and coming back returns to where the resident was. Re-tapping the
current tab pops that branch to its root — the standard gesture, and the escape
hatch from a screen someone deep-linked into.

---

## 3. One capability service, no scattered checks

`ResidentCapability` lists what a resident can do, each declaring **two**
independent things:

* an `AccessRequirement` — who may see it;
* a `BackendAvailability` — whether the LGU has switched it on.

`CapabilityService` answers both, composing `AccessPolicy` rather than replacing
it, so the router's guard, a home tile, a profile row, a gate sheet and a deep
link all reach the same conclusion from the same rule.

**Access is evaluated before availability.** A guest asking for a verified-only
capability is told to sign in, not that the feature is missing. The other order
would give a different answer to a guest than to a verified resident — which
leaks that the feature exists and is gated — and would send away someone who
should have been sent to sign in.

### The two questions, and why they are separate

| Method | Question | Consults |
| --- | --- | --- |
| `evaluate` | Can this resident get a *result*? | access, then availability |
| `canOpen` | Should the screen *open*? | access only |

This split was a bug first. Every screen in this app already handles an absent
backend by rendering an honest "not published yet" state naming what the LGU does
offer instead. Refusing to open such a screen replaced that specific explanation
with a generic one and hid working screens — the digital ID, verification, the
account — behind a flag describing something the resident cannot see and did not
cause.

So **availability decides what a screen says; access decides whether it opens**,
and the tile still shows "Not available yet" so nobody taps in expecting data
that is not there.

A source scan enforces the centralisation: no file outside `core/session/` may
branch on `AccessLevel` comparisons.

### No admin capability — acceptance 1

There is no administrative capability, route or destination, and there cannot be
one: not disabled, not hidden, not behind a flag. Five tests assert it —
over route names and paths, capability names and labels, shell destinations,
deep-link targets, and a source scan for any `'/admin'`, `'/staff'` or
`'/console'` literal anywhere in `lib/`.

### The household summary, withheld

The Master Command asks for a household/family summary for verified residents,
"only where backend capability evidence permits". **It does not permit.**

The committed contract has exactly one household row —
`GET /api/v1/households/{household_id}` — and it is a **staff** route requiring
`resident.view` under a role scope, with the sensitivity note *"member list is
other people's data — audited read"*. There is no `/me/household`.

A household summary is other residents' personal data. Building it against the
staff route would mean this app asking for a permission it must never hold;
building it against an invented `/me/` route would mean shipping a screen whose
contract nobody has agreed, for the most sensitive collection in the system. So
the capability is declared and reported unavailable — the honest state, and one a
future TAB flips in one line.

---

## 4. Every gate has a way out — acceptance 2

`CapabilityService.recoveryRoute` returns a destination for **every** refusing
verdict. That is the mechanism behind the acceptance criterion: it is impossible
to express a refusal without one, so a screen cannot forget.

| Verdict | Recovery | Wording |
| --- | --- | --- |
| needs sign-in | `/sign-in` | "Sign in with your mobile number to use this. Browsing stays open to everyone." |
| needs verification | `/verification` | "Taytay LGU needs to confirm your identity before you can use this." |
| not yet available | `/services` | "Taytay LGU has not switched this on yet. Nothing is wrong with your account." |

A test walks every capability in every session state and asserts a non-null
route, a non-empty explanation and a requirement label, then asserts each
recovery route is itself reachable by the session that would be sent there — a
recovery that redirected would be a dead end wearing a button. Another asserts
no refusal message contains "denied", "forbidden", "not allowed", "error" or
"invalid": the resident has done nothing wrong.

`CapabilityGate` renders this, and `AccessGateSheet.showForCapability` is the
same answer as a sheet. The intent held through a gate is TAB 06's, unchanged:
one kind, at most one opaque id, no free text, ten-minute TTL, cleared on any
session change, and it grants nothing.

---

## 5. Deep links

A push notification, an SMS link or a printed QR code. All three are
**attacker-writable** — anyone who can message a resident can put a string in
front of `DeepLink.resolve` — so it is treated as untrusted input.

### Targets

| Payload `target` | Route | Needs `id` |
| --- | --- | --- |
| `news_post`, `announcement` | `/news/:postId` | yes |
| `news` | `/news` | no |
| `event` | `/events/:eventId` | yes |
| `events` | `/events` | no |
| `assistance_request` | `/requests/:requestId` | yes |
| `assistance_requirements` | `/requests/:requestId/requirements` | yes |
| `assistance_requests` | `/requests` | no |
| `verification` | `/verification` | no |
| `services`, `home` | those routes | no |

### The rules, and the failure each prevents

1. **An allow-list of targets, not a path.** Accepting a path would let the
   server — or anyone imitating it — choose which screen opens, including screens
   added later that were never meant to be linkable.
2. **One bounded identifier: `[A-Za-z0-9_-]{1,64}`.** That excludes `/`, `.`,
   `%`, `?` and `#`, so an id cannot carry a path segment, traverse upward,
   smuggle a query string, or reach a route other than the one whose access was
   evaluated. `AppRoute`'s matcher independently allows no parameter to span a
   slash.
3. **No personal data in a payload — rejected, not sanitised.** A notification is
   stored by the OS, shown on a lock screen, and often mirrored to a watch or a
   car display; anything readable there has been disclosed to whoever is nearby.
   Eighteen keys (`name`, `address`, `philsys_number`, `amount`, `diagnosis`,
   `remarks`, `reviewer`, …) cause outright refusal, because a payload carrying
   one has already been mishandled server-side and quietly dropping it would hide
   a contract breach.
4. **Links open; they never act.** Seven action targets (`submit_request`,
   `cancel_request`, `confirm`, `acknowledge`, `approve`, `sign_out`,
   `delete_account`) are refused by name, so the refusal is explicit and testable
   rather than incidental. A link that could act is a link that can be forged into
   acting, and the resident would never see the request made in their name. The
   screens a link opens carry no submit, cancel or confirm control at all —
   asserted by a widget test.
5. **Authorization is re-run afterwards.** `DeepLink` decides *where*, never
   *whether*. `resolveRedirect` then evaluates the resolved route against the live
   session, so a link into a verified-only screen is gated exactly as a tap
   would be — including on a cold start, before any shell exists. A link arriving
   while the session is still restoring **waits** on the splash rather than
   resolving to "signed out".
6. **Identifiers are re-validated at the point of use.** A path can be typed,
   pasted or restored from the back stack without passing through `resolve`, so
   each detail screen checks the same rule before it builds a request.

### Honest failure

Unknown target, invalid identifier and wrong arity all produce **the same
sentence**: *"That link could not be opened. It may be for a newer version of the
app, or the item may no longer be available."* Distinguishing them would tell
whoever sent the link whether their guess landed; the app is not an oracle for
what exists. An action refusal is the one that differs, because it says something
useful: *"Taytay LGU IDS never acts from a link."*

A withdrawn announcement — a corrected typhoon advisory, say — is an ordinary
outcome, not an error, and each detail screen offers its list rather than
reporting a fault.

---

## 6. What was built against what evidence

| Screen | Contract row | Status |
| --- | --- | --- |
| Services | `GET /api/v1/services` | **implemented** — real repository |
| News | `GET /api/v1/announcements` (public) | `planned` — declines |
| Events | `GET /api/v1/events` (public) | `planned` — declines |
| My requests | `GET /api/v1/me/assistance-requests` | `planned` — declines |
| Request detail | `GET /api/v1/me/assistance-requests/{id}` | `planned` — declines |

Nothing is mocked. Sample announcements would be a fabricated statement by a
local government; an invented event would send residents to a municipal hall on a
date the LGU never announced.

The assistance-request screens render a status and a reference number — what a
resident quotes at the counter. The matrix says the citizen projection carries
"**no assessment, no internal notes, no staff identities**", and these screens
have no field any of that could occupy.

`Paginated` moved from the service catalogue's domain to `core/api/` when a
second feature needed it, re-exported so existing importers keep working.

---

## 7. Verification

`dart format` clean · `flutter analyze` clean · **554 tests pass** · debug and
release APKs build.

TAB 10 coverage (63 tests): the route table's uniqueness, parameter declaration,
exact-beats-parameterised matching, slash exclusion and location building; five
admin-absence assertions; the five destinations at every access level, unchanged
by verification, mapping back from a branch route; the Material 3 breakpoints;
the capability service agreeing with `AccessPolicy` across every capability and
session; access answered before availability; nothing usable the backend cannot
serve; the household withholding; the access-versus-availability split with its
regression; recovery routes, explanations and labels for every refusal in every
state; recovery routes being reachable; blame-free copy; every Master Command
deep-link target; locations resolving back to the route the guard evaluates;
unknown targets, action targets, malformed and over-long identifiers, arity in
both directions, and PII-bearing payloads; identical refusal copy; the guard
re-authorising each resolved link at all three levels and during restore; and
screen-level tests for the bar, the rail at two widths, branch state, tab-root
popping, gated content at each level, deep-link dead ends, the not-found screen,
absence of actions on link-reachable screens, and 200% text scale.

---

## 8. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| N-1 | No announcements or events endpoint | Both destinations render an honest "not published yet" state. Nothing simulated. |
| N-2 | No `/me/household` row | The household summary is declared and reported unavailable. |
| N-3 | No assistance-request endpoints | My requests declines; no request can be submitted or cancelled from this app. |
| N-4 | Notification payload keys are this app's convention | `target` and `id` are not published. Confirm when the `Notification` module ships. |
| N-5 | No OS-level deep-link registration | `DeepLink.resolve` is wired and tested, but no Android App Link or iOS Universal Link is declared, so nothing outside the app can hand it a payload yet. |
| N-6 | Requirement resubmission is not built | The requirements screen explains and points at the municipal hall. Blocked on backend gap **G-18**. |
| N-7 | English only | Filipino copy arrives with app-wide localisation. |
