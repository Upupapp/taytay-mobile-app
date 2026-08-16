# TAB COMPLETION REPORT

**TAB:** 27 — Analytics/Telemetry, Crash Safety & Privacy Guardrails
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A telemetry catalogue that is a **sealed type set with no free-text field**, so
PII cannot reach a payload by mistake rather than merely being forbidden from it;
crash reports with **no field for the exception message**; three crash doors
wired to one redactor; three-state consent that gates diagnostics as well as
analytics; and a shipped configuration that collects nothing at all.

## Deliverables

* `lib/core/telemetry/telemetry_events.dart` — `TelemetrySignal` (sealed) with
  seven signal shapes; `TelemetryFlow`, `TelemetryStage`, `TelemetryOperation`,
  `TelemetryResult`, `TelemetrySpan`, `TelemetryLimitation`, and the
  `TelemetryDurationBucket` / `TelemetryCountBucket` bucketers
* `lib/core/telemetry/telemetry.dart` — `TelemetrySink`,
  `DisabledTelemetrySink`, `CrashReport`, `CrashRedaction`, `TelemetryConsent`,
  `Telemetry`
* `lib/core/telemetry/telemetry_route_observer.dart` — path → `AppRoute` enum,
  or nothing
* `main.dart` — `runZonedGuarded` + `FlutterError.onError` +
  `PlatformDispatcher.onError`, all three redacted
* `AppDependencies.telemetry`; the observer wired into the router; the catalogue
  load instrumented; Settings → Privacy states what is collected
* `docs/taytay-telemetry-and-crash-safety.md`; decision log D-161 … D-169
* `test/core/telemetry_test.dart` — 32 tests

## Material decisions

D-161 no analytics or crash SDK · D-162 the catalogue is a sealed type set with
no free-text field · D-163 a screen view carries an `AppRoute`, and an
unresolvable path sends nothing · D-164 durations and counts are buckets ·
D-165 `CrashReport` has no message field · D-166 stacks are scrubbed and bounded
· D-167 consent gates crash reports too · D-168 the app never asks for consent
it cannot act on; the build switch sits above consent · D-169 Settings states
that nothing is collected even with no switch to offer.

## The two structural moves

**A closed type set, not `log(name, params)`.** A parameter bag is how PII
reaches an analytics service — not by decision, but because it accepts anything,
and one day somebody adds `{'service': service.name}` to debug a funnel and the
service name turns out to be `Medical assistance — Ana Dela Cruz (re-submitted)`.
Every payload field here is an enum, a bool or a bucket. A test enumerates every
signal shape and asserts each value is a declared wire constant.

**No field for the exception message.** A Dart message routinely quotes the value
that caused it — `FormatException: Invalid number: 09171234567`,
`Invalid argument(s): {given_name: Ana, family_name: Dela Cruz}`. Redaction by
pattern is a losing game because the next message has a shape nobody
anticipated, so `CrashReport` carries the error's *type* and a scrubbed stack and
has nowhere to put the text.

## The shipped state, which is also the tested state

Three conditions gate every signal: consent granted, build permits, sink
available. The shipped build has `notAsked` consent and a sink that reports
itself unavailable, so **nothing is collected** — which is the state all 1,151
tests run in, making "the app works with telemetry disabled" proven rather than
claimed.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 1151 tests (1119 → 1151) |
| `dart format` | **PASS** — clean, 0 changed |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Advertising / attribution SDKs | **PASS** — 15 named packages asserted absent |
| PII in payload definitions | **PASS** — every value a declared constant |

## Environment / production-only gaps

* **No sink implementation exists**, deliberately. The municipality has named no
  analytics service and the backend publishes no telemetry endpoint; when one
  arrives, a single class implements `TelemetrySink` and nothing else changes.
* **Most of the catalogue has no call sites yet.** Screen views and the catalogue
  load are instrumented; the funnel, span and limitation signals are defined and
  tested but not yet called. Instrumentation with nowhere to send is code that
  cannot be verified end to end, so it was defined rather than scattered.
* **No device or session identifier**, not even a random one — a stable random id
  is still a way to follow one person across sessions.
* **The consent prompt has no UI flow**, because `shouldAskForConsent` is false
  in every shipped build. The settings surface and the switch exist and are
  reachable the moment a sink does.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 28 — QA, Test Journeys, Final Servana/Taytay Polish & Release Readiness.**
Automatic advancement: AUTHORIZED.
