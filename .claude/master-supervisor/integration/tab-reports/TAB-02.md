# TAB 02 — Identity: sign-in, OTP and MFA

**Verdict: CERTIFIED — LOCAL COMPLETION, WITH THE END-TO-END CRITERION UNREACHABLE.**
Commit `bb5e9cb`. Nothing pushed.

## Definition of done
| Item | State |
| --- | --- |
| `AuthRepository` bound to a real implementation (detector) | **done** |
| Guest / Authenticated-Unverified / Verified reachable, driven by the server | **done** — via `GET me` + `GET me/profile`, never client inference |
| Contract tests cover each auth endpoint incl. 401/422/429 | **done** — 17 tests |
| Sign-out succeeds with the network disabled | **done** |
| A resident signs in on a physical device against staging, by OTP | **UNREACHABLE — F16** |
| …by password, and with MFA enabled and disabled | **NOT APPLICABLE — F20** |

## F20 — three of six endpoints are staff surfaces
`auth/tokens`, `auth/tokens/mfa`, `auth/password/forgot` filter `account_type = Staff`.
Not wired, deliberately; Article 0 forbids staff surfaces here and the code could never
succeed for a resident. A test asserts they stay absent.

## F21 — the tier is not on `GET me`
It is on `GET me/profile`. Sign-in reads both. Every uncertain path lands on **unverified**;
a failed `GET me` refuses the session outright.

## Not proven
Nothing here was exercised against a running server. F16 (codes issued, never dispatched)
means the flow cannot complete end-to-end regardless of client correctness — a backend
change with a named owner, not wiring.

## Next
TAB 03 — Session, tokens and the device registry. Unblocked: `me/sessions` and `me/devices`
are implemented and citizen-reachable, and `me/mfa` carries no account-type filter.
