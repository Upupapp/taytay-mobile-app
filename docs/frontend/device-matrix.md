# Device matrix and the first run on an Apple runtime — TAB 08

**19 August 2026.** What was run, on what, and — the half that decides how this reads —
**what a simulator is not**.

---

## The headline

**This app had never run on an Apple runtime.** It was built on a Windows host through
twenty-eight build TABs; the twenty-five-TAB integration sequence established that it *compiles*
for iOS on this Mac, which moved `IPHONEOS_DEPLOYMENT_TARGET` to 15.0. Compiling is not running.

On 19 August 2026 it was installed and launched on an iPhone 17 simulator and rendered its first
screen correctly: brand blue, the notch cleared, the `DEV` environment banner present as Article 7
requires, and white text on the brand-blue button.

That last detail also settles TAB 07's contrast finding by eye: the button really is white on blue,
and `textContrastGuideline`'s claim of 1.06:1 really was the sampler weighing fill against fill.

---

## The matrix, chosen from the audience rather than from convenience

| Entry | Why this one | Status |
| --- | --- | --- |
| **Oldest supported Android — `minSdk = 24`** | The 5-inch Android phone still in service in Taytay. It is the device the app is most likely to be *used* on and the one that clips first. | **NOT RUN — no Android emulator image installed, no device attached** |
| **Current mid-range Android** | What a resident buying a phone this year holds. | **NOT RUN — same** |
| **Smallest supported iPhone** | The narrowest iOS layout. | **NOT RUN as hardware.** 320×568 and 390×844 are exercised in `device_adaptation_test.dart` |
| **Current iPhone** | The widest. | **iPhone 17 simulator — launched, rendered, journeys driven** |

**Two of the four entries are Android, and neither could be run.** `flutter emulators` reports no
AVD sources on this machine. That is not a small gap: Android is the majority platform for this
audience, `minSdk = 24` is the entry this app most needs to prove, and it remains entirely
unproven on anything but a widget test.

---

## What was actually run

`integration_test/device_journey_test.dart`, the first thing in this programme to drive the app on
a real engine rather than a fake window.

| Journey | Result |
| --- | --- |
| Past the welcome scenes via **Skip** | **pass** — the escape a returning resident takes, and the one nobody exercises by hand |
| Every shell destination, in turn | **pass** — each rendered without throwing, against an unreachable API |
| Cold start → first meaningful frame | **not measured — see below. Two attempts discarded** |

The API base URL is deliberately `https://example.invalid` — so what is exercised is every screen's
own empty and error state. Given F15 and F16, **that is every journey a resident can complete
today**: no account can be created and no sign-in code is dispatched, so there is no authenticated
journey to walk.

---

## The performance budgets, and why no number here is a pass

`docs/integration/performance-budgets.md` sets cold start `< 2.5 s`, time-to-interactive
`< 3.5 s`, p95 transition `< 400 ms`, and no frame over 32 ms — and it says of each that the target
**needs a low-end device**.

An iPhone 17 simulator on an Apple-silicon Mac is the opposite of a low-end device. It shares the
host's CPU and memory and has no thermal envelope: **it would pass a 2.5 s budget whatever the app
did**, which makes a figure taken here evidence of nothing.

**Two attempts were made and both were discarded**, and how they failed is worth more than the
numbers would have been:

1. `pumpAndSettle` reported **over ten seconds**. That was the instrument, not the app — it waits
   for every animation to stop, and the welcome screen animates. It measures "when the app finished
   moving", which is not what the budget names.
2. Pumping frame by frame until readable content appears measures the **splash hold**.
   `_SplashScreenState._restore` deliberately waits `MotionTokens.splashMinimum` — **900 ms**, or
   300 ms under reduced motion — before publishing, because a splash that flashes is worse than one
   that holds. Any honest "first meaningful frame" for this app therefore has a 900 ms floor *by
   design*, and a number that is mostly a constant is not a measurement.

So cold start is recorded as **unmeasured**. Manufacturing a figure that could not have failed
would have been worse than the gap it concealed.

The budgets stay unmet, and they stay unmet in the honest sense: nothing has yet been measured on a
device that could fail them.

---

## The signing guardrail, re-verified

`android/key.properties` is absent, as it must be — the keystore is the LGU's to generate and hold
(F03), and an agent must never generate, hold or rotate it. `android/app/build.gradle.kts` reads
the release signing config from that file and **fails the build** when it is missing, rather than
falling back to the debug key.

Re-verified in this TAB by running `flutter build apk --release` and confirming it refuses. A
half-filled `key.properties` is refused too, by name, which is the more useful failure.

---

## Simulator versus device, per criterion

Nothing in the right-hand column is claimed anywhere in this repository.

| Criterion | Simulator answers it | Needs hardware |
| --- | --- | --- |
| Layout at a given size | ✅ | |
| Widget tree renders without throwing | ✅ | |
| Touch dispatch and navigation | ✅ | |
| Locale resolution and text scaling | ✅ | |
| Cold start, structurally | ✅ (as a floor, not a figure) | |
| **Cold start against the budget** | | ✅ low-end device |
| **Frame timing under scroll** | | ✅ real GPU and panel |
| **Thermal behaviour** | | ✅ |
| **Real camera capture** | | ✅ — the upload path's first step |
| **Real network transitions** (wifi → cellular → none) | | ✅ |
| **Memory pressure and background eviction** | | ✅ |
| **Screen readers** | | ✅ — see `accessibility-session.md` |
| **Android, at any version** | | ✅ **nothing has ever run** |

---

## What would change this

One Android phone at `minSdk = 24` and one hour. It would answer the whole Android column, the
frame-timing budget, and — with a photograph taken rather than a fixture loaded — the first real
exercise of the upload path this sequence spent TAB 01 fixing.
