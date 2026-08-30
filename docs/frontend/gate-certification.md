# Gate certification — HEAD, verified in isolation

**Every green in this repository until now was measured in the working tree.** That is not the
same claim as "this commit passes", and the difference is the whole reason this file exists:
a dirty or merely *lived-in* tree carries generated files, resolved packages and build outputs
that HEAD does not. A gate can pass because of something that is not committed.

So the gates are run from a **detached worktree at a named SHA**, and the SHA is stamped here.
A certification without a SHA certifies nothing.

**Run `tool/certify.sh [ref]`.** The first certification below was done by hand and left as a
procedure only its author knew — which is how most of this week's findings came to exist: a rule
stated in a document and enforced by nobody. The script creates the worktree outside the repository
(a worktree *inside* it would be picked up by the very scans being certified — `Directory('lib')`
does not know it is looking at a copy of itself), resolves dependencies from the committed
`pubspec.lock`, runs every gate, prints the table below ready to paste, and removes the worktree on
any exit.

It distinguishes **four** outcomes, because collapsing them is the defect this repository kept
finding in its own gates:

| exit | meaning |
|---|---|
| 0 | certified — every gate ran and passed |
| 1 | a gate ran and **failed** |
| 2 | a gate **could not run** — nothing is claimed either way |
| 3 | certified, with gates that honestly skipped (**NOT PROVEN**) |

*Could not look* is not *looked and found nothing*, and neither is a pass. All four paths are
red-proofed: a commit with a failing test (exit 1), a ref that is not a commit (exit 2), a suite
that produces no output (exit 2, the floor), and the real run below (exit 3).

---

## `56b466b` — 2026-08-30

Produced by `tool/certify.sh`. Exit 3 — certified with gaps.

| Gate | Result |
|---|---|
| `dart format` | **clean** |
| `flutter analyze` | **clean** |
| `flutter test` | **1,511 passing** |
| `tool/check_backend_baseline.sh` | 17 modules agree at `api-baseline-2026-08` |
| `tool/check_backend_routes.sh` | 52 declared, 48 served, 4 recorded ahead (C-09) |
| `tool/check_correctable_fields.sh` | 12 correctable fields agree |
| `tool/check_fixture_drift.sh` | **SKIP (exit 3)** — `TAYTAY_STAGING` unset |
| `tool/check_release_hardening.sh` | **SKIP (exit 3)** — no artifact in a clean tree |

The formatting row is new. It was added the day after eight files that had **never** been
formatted finally were: nothing had kept the tree tidy, and the drift was not cosmetic — a blanket
`dart format` during unrelated work swept those files into two diffs they did not belong in, and a
formatter re-wrapping a constructor is the mechanism that once made the backend-route parser see
37 of 53 routes and pass. Red-proofed on a throwaway commit with one deliberately mis-spaced line:
**exit 1, NOT CERTIFIED**, naming the file.

## `8039245` — 2026-08-29

Worktree: `git worktree add --detach <path> 8039245`, clean on creation (`git status` empty),
`flutter pub get` resolved from the committed `pubspec.lock`.

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **1,510 passing, 1 skipped** |
| `tool/check_backend_baseline.sh` | OK — 17 modules agree at `api-baseline-2026-08` |
| `tool/check_backend_routes.sh` | OK — 52 declared, 48 served, 4 recorded ahead (C-09) |
| `tool/check_correctable_fields.sh` | OK — 12 fields agree |
| `tool/check_fixture_drift.sh` | **SKIP (exit 3)** — `TAYTAY_STAGING` unset. NOT PROVEN, not a pass. |
| `tool/check_release_hardening.sh` | **SKIP (exit 3)** — no artifact in a clean tree. |

### What the isolation actually established

**The release-hardening red belonged to a build product, not to this repository.** In the
working tree that gate had been red for eleven days; at HEAD, in isolation, there is no artifact
to judge and it skips. The finding was always about a 18 August APK sitting in `build/` — the
same conclusion the staleness check now reaches by itself, arrived at independently.

**The cross-repo guards need `TAYTAY_BACKEND` and say so.** Without it they fetch from
`raw.githubusercontent.com` at the pinned tag; here they were pointed at the local clone. Both
paths are legitimate, and the run above used the local one.

### What this does NOT certify

* **Nothing on a device.** No Android journey has been driven and no screen reader has run.
  See `device-matrix.md` and `accessibility-session.md`.
* **No drift against a live API.** `check_fixture_drift.sh` skipped; the contract is proven
  against a pinned tag, not against staging.
* **Not the release artifact.** No APK was built, so signing and hardening are unproven here —
  deliberately, because building one would put a build product inside a certification of HEAD.

Two of those three are marked SKIP by the gates themselves rather than being passed over
quietly, which is the property that makes this table worth reading.
