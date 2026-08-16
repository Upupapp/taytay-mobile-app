# Telemetry, crash safety and privacy guardrails

TAB 27. What the app may learn about how it is used, and the structural reasons
it cannot learn anything about who is using it.

---

## The state this app actually ships in

**Nothing is collected.** Three conditions must all hold before a single signal
leaves the device:

| Condition | Shipped value |
| --- | --- |
| The resident granted consent | `notAsked` — nobody has been asked |
| The build permits telemetry | `true` |
| A sink is available | **`false`** — `DisabledTelemetrySink` |

So the seam is complete, the catalogue is defined, the redaction rules are
written and tested, and the app sends nothing. That is the state every one of
the 1,151 tests in this repository runs in, which makes "the app works with
telemetry disabled" a proven property rather than a claim.

---

## No analytics SDK is wired, and that is the decision

Three reasons, in order of weight (D-161):

1. **There is nowhere to send.** The backend publishes no telemetry endpoint and
   the municipality has commissioned no analytics service. Adding one would be
   this client choosing where Taytay residents' usage data lives.
2. **A third-party analytics SDK is a data-processor decision.** Under RA 10173
   the LGU is the personal information controller. Sending resident usage to
   Google, Amplitude or anyone else needs a data-sharing agreement the
   municipality signs — not a line in `pubspec.yaml`.
3. **Every mainstream mobile analytics SDK collects a device identifier by
   default** — an advertising id, an install id, a resettable device id. That is
   precisely what the Master Command's "never log IDs" rule exists to prevent,
   and it is on by default in most of them.

Same shape as the push decision from TAB 23 (D-123): the seam lands now, the
vendor lands when the office names one, and nothing else in the app changes.

A test asserts fifteen named packages are absent from `pubspec.yaml`, including
every advertising and attribution SDK a developer would reach for, plus
`firebase_crashlytics`, `sentry_flutter` and `device_info_plus`.

---

## The event catalogue

`lib/core/telemetry/telemetry_events.dart`

### Why it is a closed type set and not `log(name, params)`

The acceptance criterion is that **no citizen PII appears in analytics payload
definitions**, and the only way to hold that over a year of maintenance is to
make it structurally impossible rather than a rule people remember (D-162).

A `Map<String, Object?>` parameter bag is precisely how PII reaches an analytics
service. Not by decision — nobody sets out to log a name — but because the bag
accepts anything, and one day somebody adds `{'service': service.name}` to debug
a funnel and the service name turns out to be
`Medical assistance — Ana Dela Cruz (re-submitted)`.

So `TelemetrySignal` is a **sealed** class and every payload field on every
subclass is an enum, a bool, or a bucket. There is no constructor anywhere in the
file that accepts free text.

| Signal | Carries |
| --- | --- |
| `ScreenViewed` | an `AppRoute` **enum value** |
| `FlowStep` | `TelemetryFlow` + `TelemetryStage` |
| `OperationFinished` | `TelemetryOperation` + `TelemetryResult` + a bool |
| `SpanMeasured` | `TelemetrySpan` + a duration **bucket** |
| `ReachabilityChanged` | a bool |
| `AccessGateShown` | an `AppRoute` + the route's requirement enum name |
| `ClientLimitationHit` | `TelemetryLimitation` |

A test enumerates every signal shape and asserts each parameter value is drawn
from the union of every declared wire constant. Anything else is free text that
reached a payload.

### A screen is a route, never a path

The obvious implementation sends `route.settings.name`, which in this app is
`/events/e-1` or `/requests/req-8823`. **That is an identifier** — it names a
specific event, a specific application, and joined to a handful of siblings it
describes one resident's week at the municipal hall.

`TelemetryRouteObserver` resolves the path to an `AppRoute` and sends the enum's
name (D-163). `AppRoute.eventDetail` says a resident opened an event, which is
the operational fact anyone wanted, and says nothing about which.

**A path that resolves to no known route sends nothing at all**, rather than
falling back to the raw string. An unresolvable path is exactly the case where
the raw string is most likely to be something unexpected.

### Durations and counts are buckets

A precise millisecond count is a weak identifier: enough of them, joined to a
timestamp, distinguish one device from another and one session from the next
(D-164). Buckets answer the question anyone actually asks of a timing — is this
fast, slow, or unusable — and carry nothing else. Same for counts: "this resident
has 47 notifications" is closer to identifying than "this resident has some".

### An outcome is a category, from the failure's kind

`CrashRedaction.resultOf` maps the closed `AppFailure` set to a
`TelemetryResult`. Never from the message: a server message is written for an
operator and routinely quotes the value that caused the problem —
`Invalid number: 09171234567` names a resident's mobile number, and a constraint
violation names the row.

### What is deliberately absent from every payload

No user id, no account id, no device id, no session id, no advertising id, no IP,
no free text, no timestamp of the resident's own choosing. Correlation is
something a sink may add for its own session if the LGU ever configures one; it
is not a property of a signal.

---

## Crash safety

### Three doors, one redactor

`main` wires all three inside a `runZonedGuarded`:

| Door | Catches |
| --- | --- |
| `FlutterError.onError` | framework and widget errors |
| `PlatformDispatcher.instance.onError` | platform-side errors that bypass Flutter |
| the zone handler | asynchronous errors nothing else caught |

Each **keeps Flutter's own behaviour** — the red screen in debug, the console
dump — and adds a redacted report on top. Nothing a developer used to see stops
being visible. The zone handler goes through `FlutterError.presentError` rather
than `debugPrint`, because the device log is readable by app-adjacent tooling and
`avoid_print`/the repository's own scan forbid it.

### Why the exception message is thrown away

A Dart exception message routinely **quotes the value that caused it**:

* `FormatException: Invalid number (at character 1): 09171234567`
* `Invalid argument(s): {given_name: Ana, family_name: Dela Cruz}`
* `RangeError: Value not in range: household_members[3]`
* a `TypeError` from a decoder, carrying the decoded map

Every one of those is a crash report containing a resident's data, and nobody
wrote a line of code to put it there. Redaction by pattern — strip things that
look like phone numbers, strip things that look like names — is a losing game,
because the next message has a shape nobody anticipated.

So **`CrashReport` has no field for the message** (D-165). It carries:

* `errorType` — `error.runtimeType`, never `error.toString()`. The first is a
  class name written by a programmer; the second is the class name *and* the
  offending value.
* `frames` — the stack, scrubbed and bounded.
* `library` — Flutter's own label, "widgets library".
* `fatal`.

That is what a fix is actually made from. The message almost never is.

### Stack scrubbing

Two things go (D-166):

* **Absolute filesystem paths.** A stack from a build machine carries its home
  directory, which names a person: `file:///C:/Users/ana/projects/...` becomes
  `.../lib/...`.
* **Anything past 24 frames.** Deep frames are framework internals that say
  nothing about the defect, and a shorter report is a smaller surface.

What survives is `package:` and `dart:` frames naming functions and source files.

### Consent applies to crashes too

A crash report is still data about a resident's device and session. A government
app that collected it from somebody who declined analytics would be treating
"analytics" and "diagnostics" as different words for the same promise (D-167).

---

## Consent

`TelemetryConsent` has **three** states, not a boolean: not having answered is
not the same as saying no, and the app needs to tell them apart to know whether
it may ask.

* Default `notAsked`, which collects nothing.
* An unreadable or absent stored value parses to `notAsked` — the state that
  collects nothing — rather than to anything permissive.
* `shouldAskForConsent` is false when there is nowhere to send. Asking permission
  to do something the app cannot do is a dialog that costs trust and buys
  nothing (D-168).
* Declining is durable and is never re-asked.
* The build switch sits **above** consent: a build the municipality has not
  cleared collects nothing even from a resident who agreed.
* Consent is checked **first** in `isCollecting`, so a resident who declined is
  never even the subject of a question about what the build allows.

### The settings surface

Settings → Privacy states plainly:

> This app sends no information about how you use it to anyone. It contacts
> Taytay LGU only to show you what you asked for.

**Shown even though there is nothing to switch** (D-169). A government app that
collects no usage data should say so on the screen where a resident goes looking;
silence reads as "they are not telling me", which is the wrong impression to
leave on a municipal ID app.

The switch replaces it only when telemetry could actually run, and its subtitle
names what is excluded: never your name, your documents, what you applied for, or
anything you typed.

---

## Instrumentation never breaks anything

* `Telemetry.record` and `recordCrash` **cannot throw**. Both swallow.
* A sink that throws is **disabled for the rest of the process** rather than
  given another chance to take a screen down.
* Call sites use `unawaited`: instrumentation never delays what a resident is
  waiting for.

Instrumented so far: screen views (via the navigator observer) and the catalogue
load outcome (`ServiceDirectoryController`, demonstrating the failure→category
mapping at a real call site). The rest of the catalogue is defined and tested but
not yet called from — deliberately, because instrumentation with nowhere to send
is code that cannot be verified end to end.

---

## Tests

`test/core/telemetry_test.dart` — 32 tests.

* **Off by default:** the shipped sink is unavailable; a fresh `Telemetry`
  collects nothing; consent alone is not enough; a sink alone is not enough; the
  build switch overrides consent; declining is durable and never re-asked; an
  unreadable stored answer is unanswered.
* **With consent and a sink:** signals send; withdrawal stops them immediately; a
  throwing sink is disabled rather than retried.
* **No PII:** every parameter value is a declared constant; event names describe
  actions; a screen is a route with no `/` or `:`; durations are buckets; no
  server message survives the failure mapping.
* **Crash redaction:** a `FormatException` quoting a mobile number, an
  `ArgumentError` carrying a decoded profile map, absolute paths naming a user,
  a 200-frame stack, a missing stack; consent gating both ways.
* **Route observer:** identifiers resolve away, unresolvable paths send nothing,
  query strings never reach a payload.
* **Guardrails on the repository:** fifteen named advertising/analytics packages
  absent from `pubspec.yaml`; the catalogue declares no free-text payload field;
  nothing outside `core/telemetry` constructs a `CrashReport`.

---

## What this TAB deliberately does not do

* **No analytics or crash SDK**, for the reasons above.
* **No device or session identifier**, not even a random one. A stable random id
  is still a way to follow one person across sessions, and this app has no
  question that needs it answered.
* **No breadcrumbs.** A breadcrumb trail is a free-text log by another name, and
  the whole point of the closed catalogue is that there is no free-text door.
* **No performance tracing on a real device.** `SpanMeasured` exists and is
  tested; nothing calls it yet, because a timing with nowhere to go is a timing
  nobody can verify.
