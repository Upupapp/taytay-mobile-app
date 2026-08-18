# TAB 04 — Resident profile, KYC and corrections

**Verdict: CERTIFIED — LOCAL COMPLETION; THE VERIFIED PATH IS BLOCKED BY A BACKEND GAP.**
Commit `58577ce`. Nothing pushed.

## Definition of done
| Item | State |
| --- | --- |
| `PlannedResidentProfileRepository` replaced against `GET me/profile` / `GET me` | **done** |
| KYC lifecycle read and submit | **read done**; **open blocked — F14** |
| Corrections raised, listed, withdrawn | **partial — F23** |
| Verification status rendered honestly | **done** — nine server states mapped |
| Tier never computed locally, never cached past sign-out | **done** |
| A staging resident completes Unverified → submitted → Verified | **UNREACHABLE — F14** |

## F14 raised from P2 to P1 — it is the critical path
`POST me/kyc` requires a `barangay_id` validated against the `barangays` table. No route
publishes that list to a resident. Opening a KYC case is therefore impossible from this
app, which makes **the Verified state, the digital ID and every service resting on it
unreachable**. It was filed as a registration-form inconvenience; it is not.

## F23 — corrections are keyed differently on the two sides
Categories mapping to exactly one field are sent; the rest decline. A correction filed
against the wrong field is worse than one not filed.

## The state model was wrong, not merely thin
Six app states against nine server states, and the missing one — `needs-more-information` —
is the only non-terminal state with a resident action in it. `withdrawn` and `expired` are
kept apart from `rejected` deliberately.

## Next
TAB 05 — Household. Small and unblocked: one endpoint, `GET me/household`, and the
corrections path it routes to is now wired.
