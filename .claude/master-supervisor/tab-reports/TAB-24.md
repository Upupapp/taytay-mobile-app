# TAB COMPLETION REPORT

**TAB:** 24 — Settings, Privacy, Consent, Help & Account Controls
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A public settings hub a guest can read before handing over a mobile number; one
shared confirmation sheet whose `consequence` is a required parameter; an account
controls model that defaults to allowing nothing; consent history as resident-side
RA 10173 evidence; help with no invented contact details; accessibility controls
that never leave the device; and the event-cancellation control deferred from
TAB 22, now built on the same confirmation.

## Deliverables

* `lib/shared/widgets/confirm_sheet.dart` — `ConfirmSheet.show`, required
  `consequence`, danger variant, warning haptic, `false` on any dismissal
* `lib/features/settings/domain/account_controls.dart` — `AccountControls`
  (`none` + five flags, all false), `ConsentRecord`, `AccountControlsRepository`
* `lib/features/settings/data/planned_account_controls_repository.dart` —
  `loadControls` succeeds with `none`; the four acting methods decline
* `lib/features/settings/presentation/settings_screen.dart` — public hub,
  `_AccessibilitySection`, `_AboutSection`, confirmed sign-out, `kAppVersion`
* `lib/features/settings/presentation/privacy_controls_screen.dart` —
  `PrivacyControlsScreen` + `HelpScreen`
* Routes `/settings` (public), `/settings/help` (public), `/settings/privacy`
  (authenticated, plus `ResidentCapability.manageAccount`)
* `accountControlsRepository` wired into `AppDependencies` and all 15 harnesses
* `EventRegistration.canCancel` / `.isCancellable`, `LguEvent.withRegistration`,
  cancel control on `MyRegistrationCard`, handler in `EventDetailScreen`
* `docs/taytay-settings.md`; decision log D-130 … D-144
* `test/features/settings_test.dart` — 27 tests; `events_test.dart` — 9 added

## Material decisions

D-130 settings, help, privacy and accessibility are public · D-131 account
sections are absent for a guest, not disabled · D-132 `AccountControls` defaults
to nothing; no unsupported legal promise · D-133 `loadControls` succeeds with
`none` where every other planned repository declines · D-134 deactivation and
erasure never conflated · D-135 a retention period is the office's sentence or
nothing · D-136 a withdrawn consent keeps its row · D-137 a non-withdrawable
consent shows its reason, not a failing switch · D-138 no invented phone number,
address or opening hours · D-139 reduce motion never leaves the device · D-140
the OS setting is the floor and cannot be overridden downward · D-141 the version
row is omitted when the pipeline supplied none · D-142 one `ConfirmSheet`, with
`consequence` required · D-143 cancellability is the server's answer about that
place · D-144 a cancellation adopts the server's registration; a failure changes
nothing.

## The one planned repository that succeeds

Every other planned repository in this app declines rather than mock.
`PlannedAccountControlsRepository.loadControls()` returns `Ok(AccountControls.none)`
instead, and the exception is deliberate: "the office allows nothing yet" is a
**true answer**, not a failure, and declining would show an error where the honest
state is an empty one. The four acting methods — `listConsents`,
`withdrawConsent`, `requestDataCorrection`, `requestAccountClosure` — all decline
with `plannedBackendFailure(PlannedModule.residentProfile, …)`, because there they
would have to invent something. A test asserts both halves.

## The deferred TAB 22 item, closed

Event cancellation was held back from TAB 22 so it could be built on a shared
confirmation rather than a one-off dialog. Closed here.

`EventRegistration.canCancel` is a **new field**, separate from
`EventRegistrationForm.canCancel`, because they answer different questions at
different times: the form's flag is what the office promises before somebody
registers, this one is the answer now, for this place, and it can be false while
the form's is true — a cancellation window closes, the register is printed, the
event starts. `isCancellable` also requires an active state and a server-issued
id: "cancel the one I have" is not something this app will guess at.

A failure changes nothing on screen. A place the app quietly removed from view is
a place the resident stops turning up for while still holding it.

## Defects found and fixed during this TAB

* `MotionPreference` has `system`/`reduced` and a `set()` method, not a
  `reduceMotion` boolean — the first draft of the accessibility switch invented an
  API. Corrected against the real one.
* `AppConfig` exposes `environment`, and `isProduction`/`badgeLabel` live on
  `AppEnvironment`. The About banner read them off the wrong object.
* `events_test.dart` overrides `externalLinks` with its own recorder, so the sweep
  that added `accountControlsRepository` to the other 14 harnesses missed it. Found
  by `flutter analyze`, not by assumption.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 1028 tests (992 → 1028) |
| `dart format` | **PASS** — clean, 0 changed |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / unverified / verified | **PASS** — all three exercised, denied path included |

## Environment / production-only gaps

* The `ResidentProfile` module is `planned`, so consent history and every account
  request decline in the shipped build. Both screens render their honest states
  and say the municipal hall holds the record. Tests exercise the full flow
  through an injected repository.
* **No account-controls contract exists yet.** `AccountControls` is the client's
  reading of what such a block would carry; the wire names are unfixed until the
  backend publishes them. Nothing is decoded from a guess — the planned
  repository returns the type's own default.
* `TAYTAY_APP_VERSION` is not set by any pipeline in this repository, so the
  version row is absent in local builds. That is the designed behaviour, not a
  gap to patch client-side.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 25 — Network Loss, Offline/Degraded UX & Performance.**
Automatic advancement: AUTHORIZED.
