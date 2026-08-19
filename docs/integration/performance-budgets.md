# Performance and startup budgets

Numbers that were **measured** are marked as such. Numbers that need a device are
marked as targets, because a budget nobody has measured is a wish, and a budget
measured only on the developer's machine is worse — it is a wish with a number
attached.

## Install size — measured

Built from this repository at TAB 20, release mode, `TAYTAY_ENV=prod`:

| Artifact | Size |
| --- | --- |
| Universal APK (all ABIs) | **57 MB** |
| `armeabi-v7a` split | **18.5 MB** |
| `arm64-v8a` split | **20.9 MB** |
| `x86_64` split | 22.4 MB |
| App Bundle (`.aab`) | 57.6 MB uploaded; Play delivers ~19–21 MB per device |

**Ship the App Bundle.** That is the whole of the install-size work, and it is
worth stating plainly because the universal APK is what `flutter build apk`
produces by default and what somebody would otherwise sideload to a tester: a
resident on a prepaid connection would download 57 MB instead of 20 MB for the
same app, and on the device base this LGU is serving that is the difference
between installing it and giving up.

**There is nothing else to trim.** Inside the arm64 APK, `libflutter.so`
(11.7 MB) and `libapp.so` (7.8 MB) are 19.5 MB of the 21.6 MB total. All Flutter
assets together are **155 KB**, of which 102 KB is the licence NOTICES file that
must ship. Icon tree-shaking already removes 99% of the Material font. Asset
optimisation would be optimising a rounding error, and any real reduction would
have to come from the engine.

## Data usage — the budget that matters most here

Many residents are on prepaid data, and an app expensive to use is uninstalled
regardless of how well it works.

| Decision | Effect |
| --- | --- |
| Public reads sent **anonymously** | Keeps the response publicly cacheable; a signed-in resident gains nothing by identifying themselves on a catalogue |
| Every list request **paged and clamped** | A page is whatever the server publishes for `citizen-mobile` — 15 at the pinned baseline — never the whole table. Was 25 here, and 20 on three surfaces, until TAB 05 made the client read `client.default_page_size` instead of copying it |
| Images decoded to the **displayed** size | A 4000×3000 cover in a 360dp card is ~48 MB of ARGB; right-sized it is ~2.6 MB and visually identical |
| Uploads **downscaled before sending** | A phone photo goes from megabytes to hundreds of kilobytes, and the resident never pays to upload bytes a reviewer cannot use |
| **No offline write queue** | Nothing is silently replayed on a metered connection later |

Asserted structurally in `test/core/startup_performance_test.dart`. **Per-session
data usage has not been measured** — it needs a real session against a real
server, which does not exist yet.

## Startup — structurally correct, not yet timed

`GET app/bootstrap` is fired and **not awaited by anything that draws**, asserted
by test rather than by inspection. If it ever becomes `await`, a server that never
answers becomes an app that never starts, and that happens first to the residents
on the worst connections.

Until it answers, defaults are **permissive about versions and closed about
features**: a bootstrap that could not be fetched must never lock somebody out of
a working app, and must never draw a door the server would refuse to open.

## Targets that need a low-end device

Not measured. A budget met only on this Mac is not a budget, and none of these
should be treated as passing until run on a device at the chosen `minSdk`.

| Budget | Target | Why this number |
| --- | --- | --- |
| Cold start → first meaningful frame | **< 2.5 s** | Beyond about three seconds a resident on a queue-side phone assumes it has hung |
| Time to interactive, home | **< 3.5 s** | Home is the first authenticated screen and the one opened most |
| p95 screen transition | **< 400 ms** | Below the point a transition reads as lag rather than as motion |
| Frame budget, list scroll | **no frame > 32 ms** | Two dropped frames is visible jank on the panel types in this device base |

**Profile builds, never debug.** Debug-mode Flutter performance says nothing
about shipped behaviour — the debug APK measured here is 181 MB against a release
arm64 of 20.9 MB, which is the size of the gap in every other dimension too.

## What is not done

* No measurement on a low-end reference device, so no CI enforcement of the
  latency budgets — enforcing an unmeasured number would fail the first honest
  run and be disabled.
* No battery measurement under background work. There is no background work yet:
  no push SDK (TAB 18), no polling, no scheduled sync.
* No jank profile of the list surfaces. They page and clamp, which is the
  precondition; whether they drop frames needs a device and real data.
