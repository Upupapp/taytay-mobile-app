# TAB 01 — Contract conformance harness

**Verdict: CERTIFIED — LOCAL COMPLETION, WITH ONE ITEM UNPROVEN BY DESIGN.**
Commit `4971edd`. Nothing pushed.

## Definition of done
| Item | State | Evidence |
| --- | --- | --- |
| Contract vendored at the pinned tag | done | `test/contract/openapi.json`, 221 paths / 56 schemas |
| F05 resolved before use | **closed upstream**, exception lifted and documented | `test/contract/README.md` |
| Envelope conformance tests | done | 30 tests, contract-derived |
| Error seam beyond the happy path | done | 401/403/404/409/413/415/422/429/503 + Retry-After |
| Wiring detector | done, proven red twice | `test/integration/wiring_detector_test.dart` |
| `app/bootstrap` consumed; force-upgrade and maintenance render | done | 21 tests incl. Filipino at 200% |
| Harness wired into CI | done | 4 jobs in `contract-baseline.yml` |
| **Golden fixtures from staging** | **NOT DONE — no staging exists** | mechanism shipped unfed; CI skips loudly |

## Findings
* **F04 closed.** `PAYLOAD_TOO_LARGE` and `UNSUPPORTED_MEDIA_TYPE` decode to their own
  failure with copy in both languages. Per-context wording remains TAB 10/14.
* **F05 closed upstream.** Lifted with the commit that lifted it.
* **F06 closed.** Bootstrap consumed; flags, minimum version and support contact all reach
  the app.
* **F18 raised and decided.** `app/bootstrap` publishes no maintenance state. Decision:
  infer from a live `503`, not from bootstrap. Rationale recorded so nobody adds the field.

## What is proven, and what is not
Proven: this app's decoder matches the **published schemas**. That is a real property.

Not proven: that the server **sends what it publishes**. That needs a reachable staging API
and there is none. The launch dossier (TAB 24) must state this in those words rather than
counting the conformance suite as end-to-end evidence.

## Environmental gaps
Unchanged from TAB 00: no PHP/Composer toolchain, no staging API, no device run, no
TalkBack/VoiceOver, no release signing. Both platforms build.

## Next
TAB 02 — Identity: sign-in, OTP and MFA. **Its definition of done is not reachable at this
baseline.** F16 (issued codes are never dispatched) blocks OTP sign-in end-to-end regardless
of client correctness, and F15 (no self-registration) means there is no way to create the
account that would receive one. Both need a person, not code.
