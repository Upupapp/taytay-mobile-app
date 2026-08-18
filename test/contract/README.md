# Contract harness

What is here, where it came from, and what it does and does not prove.

## The vendored contract

`openapi.json` is the backend's published contract, copied byte-for-byte from
`Upupapp/taytay-backend` at the pinned integration baseline.

| | |
| --- | --- |
| Tag | `api-baseline-2026-08` |
| Commit | `eec71e6` |
| Path in backend | `docs/api/openapi.json` |
| Captured | 18 August 2026 |
| Method | `git show api-baseline-2026-08:docs/api/openapi.json` from a local clone |
| Size | 221 paths, 56 schemas, OpenAPI 3.1.0, API `v1` |

**Refresh it only when the baseline moves**, which means re-running TAB 00 —
see `docs/integration/backend-baseline.md`. A contract updated on its own is a
baseline that moved without anybody deciding to move it.

## The F05 exception is lifted

The Master Command's TAB 01 §2 says the published error enum must **not** be used
as the source for this app's error codes, because both backend generators emitted
the PHP enum case name (`ValidationFailed`) where the wire carries the backing
value (`VALIDATION_FAILED`).

**That defect is fixed at this baseline.** `eec71e6` — "publish the contract the
API actually serves" — is the commit that fixed it, and the vendored document
here publishes all thirteen wire values correctly. So the published enum is the
authority, and `contract_conformance_test.dart` uses it as one, in both
directions: a code the backend publishes and this app does not know is a failure,
and so is a code this app knows and the backend does not publish.

The prohibition is recorded as lifted rather than silently ignored, because the
PDF still carries it and somebody will read the PDF again. `_wire values are
SCREAMING_SNAKE_CASE, not PHP case names_` in the conformance suite is the guard
that keeps the regression visible if a future generator change reintroduces it.

## Fixtures — what is missing and why

`fixtures/` is **empty of captured responses, deliberately.**

TAB 01 §4 asks for golden fixtures recorded from the live staging API, one per
endpoint, redacted at capture, with a nightly job that re-fetches and fails on
drift. None of that was possible here and pretending otherwise would be worse
than the gap:

* There is **no reachable staging API** for this platform.
* There is **no PHP or Composer toolchain on this machine**, so the backend
  cannot be booted locally to record against either.

Writing hand-authored JSON into `fixtures/` and calling it a golden fixture would
produce exactly the failure mode this whole programme exists to correct: an
artefact that looks like evidence, is trusted like evidence, and records only
what its author already believed. A fixture's entire value is that a real server
produced it.

So what is delivered instead is **the mechanism, ready and unfed**:

* `tool/record_fixtures.sh` captures and redacts against a staging base URL, and
  refuses to write anything that still looks like personal data.
* `tool/check_fixture_drift.sh` re-fetches every recorded fixture and diffs it.
* The `contract-fixtures` CI job runs the drift check nightly and is **skipped,
  loudly, when no staging URL is configured** — so a missing staging environment
  reads as "not proven" and never as "passed".

Until staging exists, the envelope and error-seam conformance in
`contract_conformance_test.dart` is what is actually proven: it asserts this
app's decoder against the *published schemas*, which is a real and useful
property, and it is not the same as proving the server sends what it publishes.
The launch dossier must say so in those words.

**When staging arrives, redact at capture, never before commit.** These are real
residents' records on a government platform and this repository is public; a
fixture committed once is published permanently.

## What each file proves

| File | Proves | Needs |
| --- | --- | --- |
| `contract_conformance_test.dart` | the app's envelope, error taxonomy and pagination match the published schemas | nothing |
| `../integration/backend_baseline_test.dart` | the enums match the committed baseline document | nothing |
| `../integration/wiring_detector_test.dart` | no repository is stubbed except with a declared, owned reason | nothing |
| `../../tool/check_backend_baseline.sh` | the committed baseline still matches the backend at its tag | the backend repo |
| `../../tool/check_fixture_drift.sh` | the server still sends what it publishes | **a staging API** |
