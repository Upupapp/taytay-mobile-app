# Taytay resident mobile — startup, welcome and access gates

How the app decides where a resident lands on launch, what the welcome scenes
do, and how an interrupted action is preserved across an access gate.

Implemented in `lib/core/startup/`, `lib/core/intent/`, `lib/core/router/` and
`lib/shared/widgets/access_gate_sheet.dart`.

---

## 1. Startup routing

Two inputs decide the first screen, and **both** must be resolved before
anything is decided:

| Input | States |
| --- | --- |
| `SessionController` | restoring · guest · authenticated-unverified · verified |
| `LaunchController` | restoring · firstLaunch · returning |

`resolveRedirect` holds on the splash while *either* is still restoring.
Deciding early is what sends a signed-in resident to sign-in on every cold
start, and what flashes the welcome scenes at someone who has already seen them.

| Situation | Lands on |
| --- | --- |
| First launch (any session) | Welcome scenes |
| Returning guest | Home, browsing as a guest |
| Returning, authenticated-unverified | Home, with "One step to go" |
| Returning, verified | Home, with the digital ID available |
| Session expired / invalid | Guest home; a protected route bounces to sign-in, which says the session ended |

**Expiry is fail-closed and central.** A `401` reaches `AuthCoordinator`, which
invalidates the session, clears any held intent and empties the public cache. The
router reacts to the session change and moves the resident off any protected
screen. No screen handles this itself.

`LaunchState` is presentation only. It never weakens an access requirement — a
guest on first launch still cannot reach the digital ID, and a test asserts it.

---

## 2. The welcome scenes, and why they are not a trap

Three scenes, drawn with the TAB 03/04 painted illustration system: municipal
services, the digital ID, and what the LGU asks for and why. **No seal, no
unverified artwork, no copied imagery** — TAB 03's brand ruling stands.

Three properties make it escapable rather than a funnel:

1. **Skip is present on every scene**, in the app bar, from the first frame.
2. **"Continue as guest" is an explicit, equal-weight action** on the last
   scene — not a grey link under a sign-in button. Browsing Taytay's published
   catalogue genuinely needs no account, and the welcome must not imply
   otherwise.
3. **Skipping counts as completed.** Whether a resident reads all three scenes
   or leaves on the first, the flag is set and they are not asked again.
   Re-asking would override a decision they already made, which is exactly what
   makes onboarding feel like a trap.

The route stays `AccessRequirement.public` and the guard only ever routes *into*
it from the splash on a genuine first launch — so it is a starting point, never
a gate. A test asserts every session state can leave it.

**Nothing here asks for personal data.** The scenes explain; the first field a
resident meets is on sign-in, after they have been told why.

### Progress and motion

- Progress is announced as **"Step 2 of 3"** to assistive technology; the dots
  are `ExcludeSemantics`, because a row of coloured pills communicates nothing to
  a screen-reader user and would otherwise be read four times.
- Scene titles are marked as headers.
- Page transitions are **functional** motion, so they shorten under reduced
  motion rather than disappearing — the movement says which way the scenes run.
- The progress dot's width change is **decorative**, so it goes to zero.
- Both reduction switches apply: the OS setting and the in-app
  `MotionPreference`.
- Scenes scroll, so they survive a 200% text scale.

### Where first-launch state is stored

In the keystore, through `SecretStore`, alongside the session — under a
separate `taytay.launch.*` key.

It is not a secret. It is stored there because the app has exactly **one**
persistence mechanism, and adding a second unencrypted one for a single boolean
would mean a new dependency (`shared_preferences` is banned by CLAUDE.md
Article 5.3 and by a test), a second thing to clear, and a second place someone
might later put something that *is* sensitive. Encrypting a boolean costs
nothing measurable.

It is **not cleared on sign-out** — the flag belongs to the install, not the
account. A read failure degrades to `firstLaunch`: showing the scenes twice is a
minor annoyance, whereas skipping them for a genuine first-time resident means
they never learn what the app asks for.

---

## 3. Preserved intents

When a gate interrupts a resident, the app remembers **what they were trying to
do** so they resume after passing it.

### Bounded and non-sensitive by construction

| Rule | How it is enforced |
| --- | --- |
| **Closed set** | `ResidentIntentKind` is an enum. No free-form action names, no callbacks, no builders — nothing arbitrary can be stored and later replayed. |
| **No personal data** | An intent holds a kind and at most one `targetId`, validated against `^[A-Za-z0-9_-]{1,64}$`. A sentence, a URL or a phone number fails the assertion. No draft comment body, no form contents. |
| **At most one** | Not a queue. Tapping three gated things then signing in resumes the last, rather than firing three actions. |
| **In memory only** | Never written to disk or the keystore. |
| **Time-bounded** | 10-minute TTL, dropped on read. Long enough for a sign-in round trip including an SMS code, short enough that nothing surprising fires later. |
| **Cleared on any session change** | Sign-out and expiry both wipe it. Resuming an action across an account boundary is the failure this prevents. |
| **Redacted `toString`** | The target id identifies a record the resident interacted with, which is a fact about them. |

### It never grants authority

`IntentController.takeIfSatisfied` asks **`AccessPolicy`** — the same evaluation
the router uses — whether the *current* session meets the intent's requirement.
It cannot make a session meet it. If the resident signed in but is not yet
verified, a verified-only intent stays held and nothing happens.

Consuming on success is what stops an intent firing twice: the caller gets it
once, and a rebuild does not replay it.

**Resumption is a navigation, not an action.** `IntentResumer` takes the resident
to the screen where they can do the thing — it never performs it. Silently
completing an action minutes later, on the other side of a sign-in flow, is not
something an app should do on someone's behalf. And the server still authorises
whatever request follows (backend ADR 0002).

Intents whose screens do not exist yet — liking, commenting, event registration,
service applications, all belonging to backend modules the committed contract
lists as planned — carry **no destination**. They are still remembered and still
resumed; the resumer confirms rather than inventing a route that would only fail.

---

## 4. The gate sheets

One component, `AccessGateSheet`, for every gate in the app.

Written per feature, four teams write four different explanations, three forget
to say what to do next, and one implies the action was refused rather than
deferred. Written once, the resident meets the same sentence shape everywhere and
the LGU can review the copy in one place.

| Gate | Shown when | Actions |
| --- | --- | --- |
| Sign in | `AccessNeedsAuthentication` | Sign in · Keep browsing |
| Verify | `AccessNeedsVerification` | Start verification · Not now |

- The sheet is **chosen from an `AccessDecision` the caller already obtained**.
  It performs no evaluation and grants nothing; its buttons navigate.
- **Dismiss is always available**, and dismissing forgets the intent. A gate that
  cannot be dismissed is a wall.
- Copy is fixed and never resident-supplied, so a sheet cannot be made to display
  arbitrary content.
- Each sheet carries a privacy note: browsing stays open to everyone; the LGU
  asks only for what it needs.

### Honest destinations

Sign-in and verification are reached, and both then tell the truth: sign-in
declines with a temporary failure because the backend's `Identity` module does
not exist, and verification explains what will be asked for with an **inert**
button, collecting nothing. TAB 05's gaps are respected — no endpoint, field or
schema is invented.

---

## 5. Verification

`flutter analyze` clean · **335 tests pass** (280 → 335, +55) · debug and release
APKs build.

New cases include: launch state starting as *restoring* rather than "not seen";
first launch, returning guest, unverified and verified startup paths; expiry
dropping to guest with the reason preserved and the intent cleared; the guard
holding while either input restores; first launch never weakening an access
requirement; every session state being able to leave onboarding; skip and
"continue as guest" both marking the welcome done; a skipped welcome not
reappearing; progress announced as text; scene titles as headers; 200% text
scale; both reduced-motion switches; target ids rejecting free text, URLs and
phone numbers; TTL expiry; one-intent-only; no resumption while the session still
fails the gate; no resumption while restoring; resumption consuming the intent;
session change clearing it; gates not granting access; dismissal forgetting the
intent; and the two honest seams declining rather than pretending.

Two test-harness defects were found and fixed rather than worked around: the
default 800×600 surface clips lazily-built list content, and a bare
`MediaQueryData()` carries `size: Size.zero` which `MaterialApp` then reuses,
laying the whole app out at zero height — which had been making the
reduced-motion assertions pass without reaching the app.

---

## 6. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| S-1 | Sign-in cannot complete | The `Identity` module is unbuilt (TAB 05 gap D-1/D-2), so a held intent can only be resumed in tests or by a session that already satisfies it. |
| S-2 | No create-account flow | Registration is TAB 07's scope and was deliberately not implemented. |
| S-3 | Five intent kinds have no destination screen | They resume with a confirmation rather than a navigation until their features exist. |
| S-4 | Intents do not survive a process restart | Deliberate: an intent is a fact about the current moment. If sign-in later leaves the app (an SMS handoff), this needs revisiting. |
| S-5 | Welcome copy is English only | Filipino arrives with app-wide localisation. |
| S-6 | No deep-link entry into a gated action | A notification tap that should hold an intent is not wired; belongs with the `Notification` module. |
