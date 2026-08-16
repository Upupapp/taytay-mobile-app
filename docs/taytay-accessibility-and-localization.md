# Accessibility, localization and device adaptation

TAB 26. Keeping the polish usable for the whole of Taytay — including the
resident using a screen reader, the one at 200% text on a five-inch phone, and
the one who reads Filipino.

---

## Localization

### The architecture

Standard Flutter `gen-l10n`, configured in `l10n.yaml`:

| | |
| --- | --- |
| Template | `lib/l10n/app_en.arb` |
| Translation | `lib/l10n/app_fil.arb` |
| Generated class | `AppStrings` (`lib/l10n/app_localizations.dart`) |
| Untranslated report | `lib/l10n/untranslated.json` — asserted empty by a test |

Two SDK dependencies were added, `flutter_localizations` and `intl`. Both ship
with Flutter, so the Article 1 review is short: no third-party maintainer, no
permission, no byte of data egress. `flutter_localizations` matters beyond app
copy — without it a Filipino build shows translated content inside an
**untranslated** date picker and "Back" button.

### Filipino is a first-class locale, not a later feature

A municipal service in Taytay that only speaks English is a service a large part
of the population cannot use, and the residents most likely to need
social-welfare assistance are not the ones most likely to read government
English (D-154).

English is the **template** because the backend contract, the design system and
every reviewer of this repository work in it. That is a tooling decision, not a
statement about which language matters. A test asserts the Filipino file is
complete, that the two files actually differ (a Filipino file that is an English
copy is worse than none — the language setting then lies), and that placeholders
survive translation.

### The app never picks a language

There is no in-app language switcher. `AppLocales.resolve` takes the device's
own preference (D-155). A resident who has told their phone they read Filipino
has already answered; an app that asks again — or remembers a different answer —
is one where two settings disagree and the resident cannot tell which is winning.

Resolution matches on the **language subtag**, so `fil_PH`, `fil_PH_#Latn` and
plain `fil` all reach Filipino rather than falling through on a region mismatch.
An unsupported locale falls back to English explicitly, rather than to whatever
is first in the list.

`fil`, not `tl`: it is the ISO 639-2 code for the national language as the
Constitution names it, and it is what Android and iOS both emit.

### Failure copy is translated by kind

Article 5.5 — the server's `message` is operator-facing and never rendered to a
resident — survives localisation intact, and gains a second reason: server text
arrives in one language and would sit untranslated in front of a Filipino
reader even if it were safe to show.

`localisedResidentMessage(context, failure)` maps the closed `AppFailure` set to
translated copy. `AppFailure.residentMessage` remains the English default for
places with no `BuildContext` — a log line, a controller under test, a value
captured before a widget exists (D-156). A test feeds it a failure carrying
`SQLSTATE[23505] duplicate key value` and asserts none of it reaches the output.

### What is translated so far

The cross-cutting vocabulary — the five navigation destinations, the common
actions, the whole offline/unsent/stale set from TAB 25, every failure kind, and
the screen-reader phrasings. These are the strings that appear on every screen,
and they are the slice a translator starts with.

**Screen-specific copy is still English literals.** That is stated rather than
hidden: the architecture is in place and demonstrated end to end, and the
remaining migration is mechanical — lift the literal into `app_en.arb`,
translate it in `app_fil.arb`, read it from `AppStrings.of(context)`.

### Dates never follow the device locale

`ManilaTime` formats from its own month and weekday tables, so the same instant
renders identically whatever the phone says. Formatting through the device
locale would render `08/05/2026` on a US-configured phone and `05/08/2026` on a
Philippine one — the same string meaning two different days, on a screen that
tells a resident when to turn up (D-157). Every LGU timestamp carries `PHT`.

The stale-content string takes a **pre-formatted** timestamp as a placeholder,
so no translation can reorder a date.

---

## Accessibility

### Async outcomes are spoken

The gap this TAB closed. This app confirms most outcomes with a `SnackBar`, and
a `SnackBar` is **not reliably announced**: it is added to an overlay away from
the focused node, TalkBack does not move focus to it, and on Android it
disappears on a timer a screen-reader user has no way to notice. A sighted
resident saw "Your place has been given up"; a blind resident pressed the button
and heard nothing, then had to explore the screen to work out whether they still
held a place at a medical mission.

Every snackbar in the app now goes through `Outcome.succeeded` /
`Outcome.problem`, which shows it **and** announces it (D-158). The visible
confirmation is unchanged — the announcement is a second channel over it, never
instead of it, which is the same rule that forbids depending on animation or
haptics alone.

Tone is a parameter, not a guess: an app that decided "Sharing is not available
on this device" sounded positive would announce a failure as a success.

`Announce` addresses the announcement to the **view this widget is in** via
`SemanticsService.sendAnnouncement`, not to the implicit view — on a foldable in
two-pane mode the implicit view is not necessarily the one being looked at.
Nothing personal is ever spoken: callers pass the same fixed copy they render,
and the failure door derives its sentence from the failure's *kind*.

The snackbar's duration was raised to six seconds. Material's four-second
default assumes one line at the default text scale; this app supports 200%.

### Form errors are announced

`FormErrorSummary` is now a live region carrying the heading and every message
as one label, so a screen reader reads it when it appears (D-159). Previously a
resident pressed "Send", validation failed, and nothing was said — they
discovered it by exploration.

Messages are joined into single sentences: each already ends in a full stop, and
appending another makes a screen reader say "period period", which is exactly
the kind of thing that trains a resident to stop listening.

### Keyboard behaviour on forms

**15 of 19 text fields declared no `textInputAction`**, so every one showed a
"done" key that dismissed the keyboard. On the seven-field registration form a
resident tapped back into the keyboard seven times.

Now (D-160):

| Field shape | Action |
| --- | --- |
| One of several on a step | `next` |
| Last of a run, or alone on a step | `done` |
| Multi-line by design (address, narrative, comment, a `longText` question) | `newline` |

The office decides whether its own intake question wants a paragraph, and the
keyboard follows: `ServerFieldKind.longText` gets a return key that actually
returns, everything else gets `next`.

### What was already right — verified, not assumed

* **Colour is never the only signal.** Every status chip and emphasis marker
  pairs an icon with a word (`Emergency advisory`, `Pinned by Taytay LGU`).
  Material 3's selected-icon fill, not colour, marks the selected navigation
  destination.
* **Required vs optional is stated in words.** `FieldLabel` marks *optional*
  fields rather than required ones, so nothing depends on an asterisk a screen
  reader does not announce.
* **Gradients carry contrast-checked foregrounds.** `BrandGradient.onColor` is
  asserted against the palette; `HomeHero` places its second stop at 55% so the
  transition happens behind the text block rather than across it. **No text is
  drawn over a remote image anywhere in the app** — covers stand alone with
  their title beneath — so no scrim was needed. Building one for a case that
  does not exist would be untested machinery.
* **Decorative images are excluded from semantics**, and an LGU-supplied
  `alternativeText` is used when there is one. A description this app invented
  for a picture it cannot see would be worse than silence.
* **Reduced motion** is honoured throughout via `Motion.reduced`, with the OS
  setting as a floor no in-app switch can lower.
* **Haptics** are declared by intent, never the only signal, and switchable off.
* **Text scaling** is clamped to 0.85–2.0 and layouts scroll rather than shrink.

---

## Device adaptation checklist

`test/features/device_adaptation_test.dart` renders the seven backend-free core
routes across the matrix below and fails on any overflow.

### Devices

| Device | Size | Insets |
| --- | --- | --- |
| Small phone | 320×568 | none |
| Phone with a notch | 390×844 | top 47, bottom 34 |
| Large phone | 430×932 | none |
| Phone in landscape | 844×390 | left 47, right 47 |
| Tablet | 1024×1366 | none |

The small phone is the floor, and it is the size that clips first — a five-inch
Android handset is still very much in service in Taytay.

### The matrix

| Dimension | Values |
| --- | --- |
| Session state | guest · unverified · verified |
| Text scale | 1.0 · 1.3 · 1.6 · 2.0 |
| Language | English · Filipino |
| Hardest combination | small phone + 200% + Filipino |

Filipino runs longer than English — "Mga Kaganapan" against "Events" — so a
navigation bar that fits one and clips the other is a bar that was only ever
looked at in one language. A test asserts the bar is genuinely rendering
Filipino before the layout assertions run, so they are measuring the translation
rather than English on a Filipino device.

### Also asserted

* Every `IconButton`, `FilledButton`, `OutlinedButton` and `TextButton` on the
  core routes is at least 48 dp tall.
* No app bar is positioned above the viewport under a status-bar cutout.
* Both shell layouts — bottom bar and navigation rail — carry the offline
  banner and the translated destinations.

---

## Tests

`test/core/accessibility_and_locale_test.dart` — 24 tests. Locale resolution and
fallback; Filipino completeness, difference and placeholder survival; both
locales resolving at runtime; Material delegates present; every failure kind
translated in both languages; no server text reaching resident copy;
locale-independent Manila formatting; the outcome snackbar and its duration; the
form error summary as a live region with the right label; the accessibility
floors.

`test/features/device_adaptation_test.dart` — 17 tests over the matrix above.

---

## What this TAB deliberately does not do

* **No in-app language switcher**, for the reason above.
* **No full migration of screen copy.** The architecture is proven end to end on
  the cross-cutting vocabulary; the rest is mechanical and is stated as
  outstanding rather than quietly claimed.
* **No scrim widget.** Nothing in this app draws text over a remote image.
* **No right-to-left support.** Neither language this app speaks is RTL, and
  untested RTL machinery is a claim rather than a capability.
