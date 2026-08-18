# TAB 00 — Re-baseline the contract premise

**Verdict: CERTIFIED — LOCAL COMPLETION.** Commit `91f8e08`. Nothing pushed.

## Baseline established
`Upupapp/taytay-backend` tagged `api-baseline-2026-08` at `eec71e6` (local annotated
tag). Chosen over the Master Command's `22cb10d`, which is an ancestor: the two
intervening commits fix the published error codes (F05) and publish the `Pagination`
schema, both consumed directly by TAB 01.

## Definition of done
| Item | Evidence |
| --- | --- |
| `docs/integration/backend-baseline.md` names tag, SHA, date, two-axis table | committed, 246 lines |
| `PlannedModule` has exactly two members | `Verification`, `ServiceDelivery`; asserted by two tests |
| Build fails loudly where the four removed members were used | 6 files, captured in the work plan |
| Failure list captured as the work plan for TABs 02–13 | baseline doc §"work plan", 14 rows |
| CI fails deliberately when the committed copy is edited to differ | proven red 5 ways, green after each |

## Beyond the stated scope
Four of fourteen stubs would have survived the specified mechanism. They carried their
falsehood as prose, not as types, so no enum change could reach them. Recorded as F17
with a per-repository table, and the offline guard now asserts that no repository claims
a planned module.

## Environmental gaps
* No PHP/Composer toolchain — the backend cannot be booted here. Every backend claim was
  made by reading source at the tag; none by exercising it. This is why TAB 01 exists.
* No staging API reachable, so no golden fixtures could be recorded.
* No physical device run, no TalkBack/VoiceOver session, no release signing.
* iOS build succeeded for the first time in this project's history — the original host
  was Windows. Simulator/device runs remain unattempted.

## Next
TAB 01 — Contract conformance harness. Its first precondition is a reachable staging API
or a CI job that can boot the backend, and neither exists on this machine. Treat that as
the first task, not an afterthought.
