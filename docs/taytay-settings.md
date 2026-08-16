# Settings, privacy, consent, help and account controls

TAB 24. Where a resident reads what the LGU holds, sees what they agreed to, asks
for changes the office actually accepts, turns motion down, and signs out.

---

## What is public, and why that matters

`/settings` and `/settings/help` are **public routes**. `/settings/privacy` is
`authenticated`.

The Master Command's first acceptance criterion is that privacy text is reachable
without login, and the reasoning runs further than the privacy notice itself:
somebody deciding whether to register should be able to read what they would be
agreeing to, find out how to reach the municipal hall, and reduce motion — all
before handing over a mobile number. A settings screen that demands an account is
a settings screen that answers none of those questions for the person most likely
to be asking them.

A guest therefore sees: Privacy notice · Accessibility · Help · About · Sign in.

A signed-in resident additionally sees: Your account · Sign-in and security ·
Notifications · Your consents and account requests · Sign out.

The account sections are **absent** for a guest, not present and disabled. A wall
of locked rows tells somebody the app is not for them (D-131).

| Route | Name | Requirement |
| --- | --- | --- |
| `/settings` | `settings` | public |
| `/settings/help` | `help` | public |
| `/settings/privacy` | `privacyControls` | authenticated |

`PrivacyControlsScreen` also sits behind `CapabilityGate(ResidentCapability.manageAccount)`,
so the route requirement and the capability both have to agree.

---

## `AccountControls` — nothing is offered that the backend did not offer first

```dart
const AccountControls({
  this.canRequestDataCorrection = false,
  this.canRequestDeactivation = false,
  this.canRequestDeletion = false,
  this.canWithdrawConsent = false,
  this.requiresReauthentication = false,
  this.deletionPolicyNote,
});

static const AccountControls none = AccountControls();
```

Every flag defaults to **false**. The Master Command is explicit that deletion,
consent withdrawal and correction paths exist "only if backend/policy supports",
and the acceptance criterion is that **no unsupported legal promise is invented in
the UI** (D-132).

On a government app that is stricter than it sounds. A "Delete my account" button
is a statement about what the LGU will do with a civil record, and retention of a
resident record is set by law and by municipal rule — not by a client. Showing the
button and hoping the server refuses would be this app making a promise on the
municipality's behalf.

Two consequences follow:

* **Deactivation and erasure are different requests** with different legal
  answers, and are never conflated (D-134). One repository method carries a
  `permanent` flag rather than the app implying a difference the office has not
  defined.
* **`deletionPolicyNote` is rendered verbatim or not at all** (D-135). A retention
  period this app guessed would be a legal statement nobody authorised.

### The one planned repository that succeeds

`PlannedAccountControlsRepository.loadControls()` returns `Ok(AccountControls.none)`.
Every other planned repository in this app declines — this one does not, and the
distinction is deliberate (D-133).

"The office allows nothing yet" is a **true answer**, not a failure. Declining
would make the screen show an error where the honest state is an empty one. The
four *acting* methods — `listConsents`, `withdrawConsent`, `requestDataCorrection`,
`requestAccountClosure` — all decline with
`plannedBackendFailure(PlannedModule.residentProfile, …)`, because there they
would have to invent something.

---

## Consent history

`ConsentRecord` is the resident's view of the LGU's own evidence. Under RA 10173
the municipality has to be able to show what a data subject agreed to and when;
this is the same record, from the resident's side, which is what makes the
transparency real rather than a paragraph in a notice.

* **A withdrawn consent keeps its row** (D-136). The record is the point;
  removing the row would erase the evidence it exists to provide. It renders with
  its `Withdrawn` date and no withdraw control.
* **A consent the office cannot operate without shows `withheldReason`** rather
  than a switch that would fail (D-137). Processing an application a resident
  themselves made is the obvious case.
* **The statement is the office's own sentence**, never a paraphrase.
* `ConsentRecord.toString()` is redacted of the statement — the type is reachable
  from a log line.

Withdrawal is idempotency-keyed: through a dropped connection it should record one
withdrawal, not two entries in a legal history.

---

## `ConfirmSheet` — one confirmation, and `consequence` is required

```dart
static Future<bool> show({
  required BuildContext context,
  required String title,
  required String consequence,
  required String confirmLabel,
  String? detail,
  bool isDestructive = true,
  String cancelLabel = 'Keep it as it is',
});
```

A confirmation that only says "Are you sure?" tests whether somebody meant to tap,
not whether they understand what happens. The useful part is the sentence naming
what they lose — so `consequence` is a **required** parameter (D-142). A caller
with nothing to put there is probably confirming something that does not need
confirming, and a dialog nobody needs is how residents learn to dismiss the ones
that matter.

* `confirmLabel` describes the act in its own words — "Give up my place", not
  "OK" — so it still says what it does when a screen reader reads it out of
  context.
* Any dismissal returns `false`: swipe, back gesture, cancel button.
* The confirm button fires `HapticIntent.warning`, not a confirm haptic. This is
  the moment to pause; the feedback should not feel like success.

Callers: sign out, consent withdrawal, account closure requests, and event
registration cancellation.

---

## Accessibility controls

Both are **device preferences and neither is sent anywhere** (D-139). Reduced
motion is an accessibility need, not a fact about a resident, and putting it on a
server would make it a preference the LGU holds about a person's disability.

**Reduce motion.** `MotionPreference` is OR-ed with the platform signal, never
AND-ed. The OS setting is the floor: when the phone asks for reduced motion the
switch reads on and is **disabled** (D-140). Somebody who told their phone to
reduce motion has already answered, and an app switch that could turn it back on
would be ignoring them. The reverse direction is offered because "Remove
animations" on Android is system-wide, and some residents want the calmer
government app without flattening their whole phone.

**Vibration feedback** toggles `AppHaptics`.

**Text size** follows the phone. There is no in-app override — a second text-size
control that disagreed with the OS is a second thing to get wrong.

---

## About

* The version comes from `--dart-define=TAYTAY_APP_VERSION`. **When the pipeline
  supplied nothing, the row is omitted** rather than showing "unknown" (D-141) —
  a support desk will act on a version number, so an invented one is worse than
  none.
* Non-production builds show a `Test build` banner naming the environment, so a
  staging build is never mistaken for the real thing during LGU acceptance
  testing.

---

## Help

Fixed text. It collects nothing and looks nothing up, so a guest reads it without
an account.

**No phone number, address or opening hours appears anywhere** (D-138). Publishing
contact details this app cannot verify is how a resident travels to a building
that closed. Instead it points at the contact the office itself published on the
service, programme or event in question, and at the barangay hall. A test asserts
the absence with regexes over the rendered text.

---

## Cancelling an event registration

Carried over from TAB 22, where it was deferred so it could be built on
`ConfirmSheet` rather than a one-off dialog.

### Whose answer is it

`EventRegistration.canCancel` is separate from `EventRegistrationForm.canCancel`,
and answers a later question (D-143):

| Flag | Question | When |
| --- | --- | --- |
| `EventRegistrationForm.canCancel` | "Will I be able to change my mind?" | before registering |
| `EventRegistration.canCancel` | "Can I give up **this** place, now?" | after registering |

The second can be false while the first is true: a cancellation window closes, the
register is printed, the event starts.

```dart
bool get isCancellable => canCancel && isActive && id != null;
```

Three conditions, all from the server: the office allows it, the place is live,
and there is an id to cancel against. A registration with no id is one the backend
has not made addressable, and "cancel the one I have" is not something this app
will guess at.

### What happens

1. The control is a **text** button on the registration card, not a red one.
   Giving up a place is an ordinary thing to do; the weight belongs on the
   confirmation.
2. `ConfirmSheet` names the consequence: the place goes to the next person
   waiting, and the event may be full if they change their mind.
3. An idempotency key is generated **on confirmation**, not on build — an
   abandoned confirmation leaves nothing behind.
4. On success the screen adopts the **server's** registration via
   `LguEvent.withRegistration`, which carries every other field across untouched.
5. On failure **nothing on screen changes** (D-144) and the message says "You
   still have your place." A place the app quietly removed from view is a place
   the resident stops turning up for while still holding it. The copy comes from
   `AppFailure.residentMessage`, never the server's operator-facing text.

---

## Tests

`test/features/settings_test.dart` — 27 tests.

* Access from guest, unverified and verified, including the denied path to
  `/settings/privacy`.
* Help reachable by a guest; no invented phone number, mobile number or opening
  hours (regex assertions over rendered text).
* Reduce motion set by the resident; the OS setting wins and disables the switch.
* `AccountControls.none` offers nothing; the planned repository succeeds with
  `none` and declines on every acting method.
* Erasure and deactivation confirmed, dismissal sends nothing, confirmation sends
  exactly one keyed request, failure says nothing was asked for.
* Consent withdrawal confirmed and keyed; a withdrawn consent keeps its row; a
  non-withdrawable consent shows its reason; failure says nothing changed.
* No server message, status code or exception text in resident copy.
* 200% text scale.
* Sign-out confirmation; dismissal keeps the session.

`test/features/events_test.dart` — 9 further tests covering cancellation:
offered only when the server allows it, not without an id, not once cancelled,
dismissal cancels nothing, one keyed request that adopts the server's answer, a
failure that keeps the place, plus `isCancellable`, `withRegistration` and
`toString` redaction.

---

## What this TAB deliberately does not do

* **No in-app language switch.** Localization is TAB 26.
* **No data export.** The Master Command does not ask for one, and a client that
  assembled a resident's record into a file would be making an export decision
  the office owns.
* **No correction form.** Corrections happen on the profile and household screens
  against the specific record; a free-text box here would produce requests the
  office cannot act on.
* **No environment switcher.** Article 7 — a build that can be re-pointed after
  shipping has no auditable API target.
