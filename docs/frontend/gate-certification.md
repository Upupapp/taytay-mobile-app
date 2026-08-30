# Gate certification — HEAD, verified in isolation

**Every green in this repository until now was measured in the working tree.** That is not the
same claim as "this commit passes", and the difference is the whole reason this file exists:
a dirty or merely *lived-in* tree carries generated files, resolved packages and build outputs
that HEAD does not. A gate can pass because of something that is not committed.

So the gates are run from a **detached worktree at a named SHA**, and the SHA is stamped here.
A certification without a SHA certifies nothing.

---

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
