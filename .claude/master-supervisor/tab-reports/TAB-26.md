# TAB COMPLETION REPORT

**TAB:** 26 — Accessibility, Localization & Device Adaptation
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A real localisation architecture with a **complete Filipino translation**, not a
placeholder; async outcomes spoken to a screen reader instead of shown only in a
snackbar it never announces; form errors announced; keyboard behaviour fixed
across every data-entry form; and a device matrix that renders the core routes
at five shapes, three session states, four text scales and two languages.

## Deliverables

* `pubspec.yaml` + `l10n.yaml` — `flutter_localizations`, `intl`, `generate: true`
* `lib/l10n/app_en.arb` (template) and `lib/l10n/app_fil.arb` (**complete**),
  generating `AppStrings`
* `lib/core/l10n/app_locales.dart` — `AppLocales.supported`, `resolve` on the
  language subtag with an explicit English fallback, `localisedResidentMessage`
* `MaterialApp.router` wired with delegates, `supportedLocales` and
  `localeResolutionCallback`
* `lib/core/a11y/announcements.dart` — `Announce.success` / `.failure` /
  `.problem` / `.busy`, view-addressed, assertive, nothing personal spoken
* `lib/shared/widgets/outcome_feedback.dart` — `Outcome.succeeded` / `.problem`;
  every snackbar in the app now routes through it
* `FormErrorSummary` is a live region carrying every message as one label
* `textInputAction` across registration, sign-in, contact details, verification,
  assistance intake, event registration, comments
* `ShellDestination.labelIn(AppStrings)`; both shell layouts translated
* The whole TAB 25 offline/unsent/stale vocabulary translated
* `docs/taytay-accessibility-and-localization.md`; decision log D-154 … D-160
* `test/core/accessibility_and_locale_test.dart` (24) and
  `test/features/device_adaptation_test.dart` (17)

## Material decisions

D-154 Filipino is a first-class locale, complete and test-guarded · D-155 no
in-app language switcher; the device decides · D-156 failure copy translated by
kind, `residentMessage` stays the context-free English default · D-157 dates
never follow the device locale · D-158 every snackbar is announced as well as
shown, tone as a parameter · D-159 the form error summary is a live region ·
D-160 keyboard action follows field shape.

## The gap this TAB actually closed

A `SnackBar` is **not reliably announced** — it is added to an overlay away from
the focused node, TalkBack does not move focus to it, and on Android it vanishes
on a timer a screen-reader user cannot notice. A sighted resident saw "Your place
has been given up"; a blind resident pressed the button, heard nothing, and had
to explore the screen to find out whether they still held a place at a medical
mission. Eight snackbar sites now announce as well as show.

The second was mechanical and no less real: **15 of 19 text fields declared no
`textInputAction`**, so every field on the seven-field registration form showed
a "done" key that dismissed the keyboard.

## What was already right — verified, not assumed

Colour is never the only signal (every chip pairs an icon with a word);
required/optional is stated in words rather than an asterisk; gradients carry
contrast-checked foregrounds; decorative images are excluded from semantics;
reduced motion is honoured with the OS setting as a floor; text scaling is
clamped 0.85–2.0 and layouts scroll. **No text is drawn over a remote image
anywhere in the app**, so no scrim was built — machinery for a case that does not
exist is untested machinery.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 1119 tests (1078 → 1119) |
| `dart format` | **PASS** — clean, 0 changed |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / unverified / verified | **PASS** — every core route, every state |
| Devices | **PASS** — 5 shapes incl. notch and landscape |
| Text scale | **PASS** — 1.0 / 1.3 / 1.6 / 2.0, and 2.0 on a 320 dp phone |
| Languages | **PASS** — English and Filipino, including at 200% |

## Environment / production-only gaps

* **Screen-specific copy is still English literals.** The architecture is proven
  end to end on the cross-cutting vocabulary — navigation, actions, failures,
  the offline set, the screen-reader phrasings — and the rest is a mechanical
  lift. Stated rather than quietly claimed.
* **No real screen-reader run.** Announcements, live regions and semantics are
  asserted through Flutter's semantics tree; TalkBack and VoiceOver on physical
  devices have not been exercised. That is a device gap, not a code gap.
* **No right-to-left support**, deliberately: neither language this app speaks
  is RTL, and untested RTL machinery is a claim rather than a capability.
* **Contrast over remote images is not asserted**, because nothing draws text
  over one. If a future design does, it needs a scrim and a test before it ships.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 27 — Analytics/Telemetry, Crash Safety & Privacy Guardrails.**
Automatic advancement: AUTHORIZED.
