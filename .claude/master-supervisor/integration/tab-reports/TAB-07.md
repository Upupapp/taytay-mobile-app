# TAB 07 — Services and programmes

**Verdict: CERTIFIED — LOCAL COMPLETION.** Commit `4c0a880`. Nothing pushed.

## Definition of done
| Item | State | Evidence |
| --- | --- | --- |
| Programmes list and detail render from live data **for guests and signed-in residents** | done | route + capability now public; widget tests both ways |
| Eligibility guidance presented as advice | done, strengthened | `conditions` are sentences; structured comparators are dropped, not modelled |
| Wiring detector shows no remaining `ServiceCatalog` stub | done | `programRepository` moved to `wired`; 13 stubs left |
| Caching directives honoured | done | unauthenticated request; cache stores only anonymous responses |
| Pagination reused; guest surface guest-visible | done | `meta.pagination`, clamped `per_page` |
| Programme linked to its intake flow | **deferred to TAB 08** | the intake repository is still stubbed; linking to a declining screen would be a dead end |

## F19 — the contract was wrong on four axes
1. **Auth** — declared bearer; the route is public. This is the one that mattered: `/programs`
   required an account, withholding published municipal information from the residents least
   likely to have one.
2. **Filter** — declared `?status=active`; no such parameter exists.
3. **Key** — addressed by `code`; the server resolves by UUID.
4. **Projection** — modelled from a matrix the server no longer follows. Would not have
   thrown; would have rendered every programme with a name and nothing else.

## Acceptances that changed, and why
* *Availability is never computed into open or closed* — existed because the app compared
  dates to a device clock. The server now answers `accepts_applications` as it replies;
  relaying it is reporting, not deciding. The entity holds no `isBefore`/`isAfter`/`DateTime.now`.
* *The maximum grant is text so no arithmetic can be done with it* — replaced by something
  stronger: no figure is published at all, so there is nowhere for one to land.

## Next
TAB 02 — Identity. Blocked from full completion by F15 and F16; the client wiring and its
contract tests are reachable and are what TAB 02 will deliver.
