# QA — what 1,346 passing tests do and do not evidence

TAB 24 consumes this. Its whole job is to refuse to launch on anything but
evidence, so it needs to know exactly what kind of evidence this suite is.

## What is proven

* **The app's own logic**, thoroughly: decoding, failure mapping, routing and
  access gating, offline policy, telemetry redaction, the error taxonomy, and the
  privacy invariants each feature declares about itself.
* **That every wired repository calls the path it claims to**, with the auth
  posture, paging and idempotency key it claims — against recorded request
  shapes.
* **That the app matches the published contract** at `api-baseline-2026-08`:
  envelope, pagination, all thirteen error codes, in both directions.
* **The seven failure paths** TAB 23 names, deliberately: expired token
  mid-journey, revoked session, network loss mid-upload, duplicate submit,
  capacity race, oversized upload *including the proxy rejection*, and OTP rate
  limiting.
* **That the guards fail.** Every check added across TABs 00–23 was proven red
  before being trusted, then restored. A conformance suite that passes because it
  asserts nothing is worse than none, because it is believed.

## What is not proven, and must not be read as proven

**CORRECTED after this document was first written.** It said no test had ever
talked to the Taytay backend, and that there was no PHP toolchain on this
machine. The first half was true at the time. **The second was taken from the
Master Command and never checked, and it is wrong**: PHP 8.4 and Composer are
installed via Herd, the backend boots against sqlite, and it serves in about six
seconds.

So the caveat is now narrower and more precise:

* **Nine endpoints have been called for real**, their responses recorded as
  golden fixtures under `test/contract/fixtures/`, and decoded through the app's
  own decoders — `app/bootstrap`, `health`, `services`, `programs`, `events`,
  `privacy/notice`, `newsfeed`, `me` (401) and a 404.
* **The fixture drift check runs and passes** rather than skipping loudly.
* **Still not exercised:** every authenticated resident journey, because no
  account can exist (F15) and no code can be dispatched (F16). That gap is the
  platform's, not the tooling's.

Calling the API found something reading it could not: **`GET newsfeed` answers
401 to a guest** on a route carrying no `auth:sanctum`, because the controller
gates anonymous readers on a feature flag that defaults off. Raised as **F30**,
and the app was wrong in a way that would have broken the feed for signed-in
residents too.

Specifically absent:

| Not done | Why | Owner |
| --- | --- | --- |
| **End-to-end resident journeys** — register → verify → ID → apply → upload → track | No staging server. Also impossible in principle today: F15 means no account can be created, F16 means no code is ever sent, F14 means KYC cannot start | backend / LGU |
| **Device matrix** — low-end Android at `minSdk`, mid-range, older and current iPhone | No physical device. Both platforms build; neither has been run | TAB 24 / LGU |
| **TalkBack and VoiceOver traversal** | Needs a device. Screen-reader behaviour is asserted structurally (labels, live regions, announcements) and has never been heard | TAB 24 / LGU |
| **Airplane-mode journeys** | The offline policy is asserted against cache behaviour, never walked with a radio off | TAB 24 / LGU |
| **Latency and jank budgets** | Targets, not measurements. A budget met only on a developer's Mac is not a budget | TAB 24 / LGU |
| **UAT with residents and MSWDO staff, in Filipino** | Comprehension failures are defects, not training gaps, and no test can find one | LGU |
| **Independent security review** | Commissioned by the LGU | LGU |
| **Fixture drift against staging** | The recorder and drift check ship unfed; CI skips them loudly rather than passing | backend |

## The number is not the evidence

1,346 tests is a fact about this repository, not about the platform. The suite
count **fell** during the wiring phase — from 1,296 to 1,276 — because each TAB
removed an "absent backend explains itself" test as it replaced the stub that
test asserted. A count going up is not progress and a count going down is not
regression; what changed is what is being asserted.

That is the specific failure this programme was created to correct. The original
build reported release readiness on 1,204 passing tests **while one was failing**,
and the app it certified could not sign a resident in, because thirteen of its
sixteen repositories declined every call and no test asserted otherwise.

**The wiring detector is the honest counter now.** It reports how many
repositories are bound to stubs — 16 at TAB 00, 1 today — and it fails when one
is quietly re-stubbed or when a TAB claims a feature is wired without moving its
entry.

## The stop condition, and it is live

TAB 23 says treat a red gate as a stop condition, because TAB 28 of the original
build reported release readiness with a failing test.

Two gates are red right now, by design, and both must stay visible:

* **`tool/check_release_hardening.sh`** fails on the debug signing key (F03) and
  goes green when the LGU holds a keystore.
* **`tool/check_fixture_drift.sh`** skips loudly with exit 3 and reports
  "NOT PROVEN" rather than passing.

Neither should be silenced to make a dashboard green. They are the two places
this programme's central failure would recur.
