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
| **Oldest supported Android — `minSdk = 24`** | The 5-inch Android phone still in service in Taytay. It is the device the app is most likely to be *used* on and the one that clips first. | **PARTIAL** — builds, installs, launches and renders at Android 7.0 / API 24 / arm64-v8a, 1080×1920 @ 420dpi (411×731 dp). **Driven journeys did not complete** — see below |
| **Current mid-range Android** | What a resident buying a phone this year holds. | **NOT RUN** — one image was installed and it was deliberately the oldest, because that is the entry that fails first |
| **Smallest supported iPhone** | The narrowest iOS layout. | **NOT RUN as hardware.** 320×568 and 390×844 are exercised in `device_adaptation_test.dart` |
| **Current iPhone** | The widest. | **iPhone 17 simulator — launched, rendered, journeys driven** |

### Correction — "neither could be run" was wrong, and it was wrong in the direction that flatters

This document first recorded both Android entries as unrunnable because `flutter emulators` reports
no AVD sources. That is what the tool says and it is not what it means. Android Studio is installed
on this machine, `sdkmanager` and `avdmanager` are on disk, and
**`system-images;android-24;default;arm64-v8a` is available to download** — exactly `minSdk = 24`,
and arm64, so it runs natively on Apple silicon rather than under emulation.

What was true was that no image was *installed*. What was written was that Android could not be
run. Those are different statements, and the second one turned a task into an impossibility on the
strength of one command's output — which is the same mistake this sequence has now made three other
times and recorded each time.

The image was installed and the run attempted. What follows is what actually happened.

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

---

## What the first Android run actually showed

Nothing in fifty-three TABs of widget tests had ever put this app in front of Android's own chrome.
One thing came out of it immediately, and it is exactly the class of observation a device run
exists to produce:

**The `DEV` ribbon overlaps the status-bar clock on Android, and does not on iOS.** The ribbon is
drawn into the top-right corner. iOS puts its clock top-*left*, so they never meet; Android puts
its clock top-*right*, so the ribbon sits over it. Neither a widget test nor an iOS run could have
found this, because both were looking at the wrong corner.

**It is not a release defect.** Article 7 shows the environment banner on non-production builds
only, so no resident ever sees it — it is an LGU acceptance-testing surface, and the cost is that a
tester reads the clock through a brown diagonal. Recorded rather than fixed: changing it would be
scope this TAB does not own, and a finding logged is worth more than a change nobody asked for.

---

## The Android journeys did not run, and the harness is why

The driven walk was started against the emulator and killed after **74 minutes with no output**.
The proof it had not progressed is exact: the screen at 11:18 was the onboarding screen from
10:05, pixel-identical but for the clock.

Rather than guess whether that was the app or the tooling, a bounded probe was run — an
`integration_test` containing nothing but a `Text` widget pumped once and matched. **It hung too**,
for over twelve hours, on a test that cannot fail.

So the finding is about the tooling, not the app: **`integration_test` does not complete against an
emulated arm64 API 24 image on this machine.** The same harness, the same test file and the same
app pass on the iOS Simulator in about ninety seconds.

**What that does and does not license:**

* It does **not** say the app is fine on Android. Nothing has driven it there.
* It does **not** say the app is broken on Android. The probe rules the app out of the diagnosis
  entirely — whatever is wrong is upstream of any code in this repository.
* It **does** mean this machine cannot answer the question, and a real handset would settle it in
  minutes. `adb` over USB to a physical phone bypasses the emulator entirely.

## What the Android leg actually bought

Two things, and they are worth stating plainly against the cost — 4.2 GB of SDK downloaded and
roughly fourteen hours of wall-clock spent, most of it on a hang that should have been called at
twenty minutes.

1. **The app builds, installs, launches and renders correctly at `minSdk = 24`.** Nothing in
   twenty-eight build TABs, twenty-five integration TABs or eight TABs of this sequence had
   established that. It is now established.
2. **One defect, from the launch rather than the walk** — the `DEV` ribbon over the status-bar
   clock, which only an Android render could have shown.

The cheapest part of the exercise found everything the exercise found.
