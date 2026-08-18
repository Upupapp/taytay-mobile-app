# TAB 03 — Session, tokens and the device registry

**Verdict: CERTIFIED — LOCAL COMPLETION, WITH TWO ITEMS DEFERRED WITH REASONS.**
Commit `96e40e2`. Nothing pushed.

## Definition of done
| Item | State |
| --- | --- |
| Session survives app restart | **done** (pre-existing, re-asserted) |
| Expiry triggers exactly one recovery under concurrency | **done** — as one *sign-out*; no refresh endpoint exists (F22) |
| Remote revocation signs this device out cleanly at the next request | **done** — 401 → one invalidation → guest with a reason |
| Sign-out leaves no resident data, proven by test not inspection | **done** — store cleared, controller carries nothing |
| Session list renders and acts | **done** — list, revoke one, revoke all others |
| Device registry (`me/devices`) | **deferred to TAB 13** |
| MFA management (`me/mfa`) | **deferred — see below** |

## Deferrals, with reasons
* **`me/devices`** is push registration, not a session list. Wiring it now would create rows
  with no push token and no purpose, and put a second list in front of a resident asking
  one question. TAB 13 owns push and is where the registration means something.
* **`me/mfa`** carries no account-type filter, so a resident *could* enrol TOTP — it is
  genuinely available, unlike password sign-in (F20). It is deferred rather than dropped:
  recovery codes shown once, saveable, and never captured by a crash report is a real
  surface with its own privacy obligations, and it belongs with the account-security work
  in TAB 17 rather than bolted onto a session list. Recorded so it is a decision, not an
  omission.

## F22 — no refresh endpoint
`Identity` publishes none. The guarantee holds with an honest verb: ten concurrent `401`s
produce exactly one invalidation. `AuthCoordinator`'s refresher stays deliberately
unregistered.

## Not proven
No live server. Everything is proven against contract shapes and recorded requests.

## Next
TAB 04 — Resident profile, KYC and corrections. Unblocked; `me/profile` is already read by
sign-in for the tier (F21), and `me/kyc` is what makes the Verified state achievable.
