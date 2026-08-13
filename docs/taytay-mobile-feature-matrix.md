# Taytay resident mobile — feature matrix

**Purpose.** Map every planned resident feature to the LGU capability that administers
it, the backend resource behind it, the access level required, the fields a resident may
see, and the fields that must never reach this app.

**Authority.** The Taytay LGU IDS backend is the only authority
(`CLAUDE.md` Article 0). Everything below is traced to source in that repository or to
the staff console that administers it. Where a row has no backend resource, it is marked
**NOT YET SPECIFIED** and must not be built.

## Evidence

| Source | Identity | Commit |
| --- | --- | --- |
| Backend (authoritative) | `Desktop/Taytay_Rizal_LGUIDS_Backend`, `main` | `fa77cef` — 2026-08-14T01:11:43+08:00 |
| MSWDO staff console | `Desktop/Taytay_Rizal_Social_Welfare_Angular`, `main` | `c470960` — 2026-08-14T00:59:38+08:00 |

**There is no OpenAPI document in the backend repository.** The contract is specified in
prose in `docs/api/conventions.md` plus the route files, resources and domain enums. That
is a gap, recorded in §6; until it closes, the PHP source is the contract.

---

## 1. What the backend actually publishes today

`modules/Shared/Routes/api_v1.php` and `modules/ServiceCatalog/Routes/api_v1.php` are the
complete public surface:

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| `GET` | `/api/v1/health` | none | Liveness only: service, status, api_version. |
| `GET` | `/api/v1/services` | none | **Public by design** — published catalogue. |
| `GET` | `/api/v1/admin/services` | `auth:sanctum` | Same controller, same query. The prefix grants nothing. |

Both `services` routes call one `ListServicesQuery`. The only thing that widens the
result is the server-resolved permission `services.view_unpublished`:

```php
$maySeeUnpublished = $this->authorization->allows($actor, Permission::ServicesViewUnpublished);
if (! $maySeeUnpublished && ! $service->isVisibleToPublic()) { return false; }
```

`Role::permissions()` grants that permission to `lgu_staff` and `lgu_admin` only.
**`Role::Resident` and `Role::Verifier` hold no permissions at all.** A resident calling
the `/admin` URL receives exactly the published catalogue.

### 1.1 The catalogue, and what the mobile channel may show

From `config/service_catalog.php`. `available_channels` is part of the resource, so a
service can be published yet unavailable on this channel:

| Code | Name | Category | Status | `citizen-mobile`? |
| --- | --- | --- | --- | --- |
| `CEDULA` | Community Tax Certificate (Cedula) | `dokumento` | published | **yes** |
| `BUSINESS_PERMIT` | Business Permit Application | `dokumento` | published | **no** — web + admin only |
| `REAL_PROPERTY_TAX` | Real Property Tax Assessment and Payment | `buwis` | published | **yes** |
| `HEALTH_CERTIFICATE` | Health Certificate | `kalusugan` | published | **yes** |
| `PESO_JOB_MATCHING` | PESO Job Matching | `trabaho` | published | **yes** |
| `LGU_RESIDENT_ID` | Taytay Resident ID Application | `ids` | published | **yes** |
| `NATIONAL_ID_ASSISTANCE` | National ID (PhilSys) Assistance | `national` | **draft** | **no** — admin only |

Two consequences the app must respect:

- **The app never hard-codes this list.** It requests
  `GET /api/v1/services?channel=citizen-mobile` and renders what comes back. Publication
  state is an LGU decision made in the staff console; a hard-coded list means a service
  the LGU retired stays on residents' phones until the next app release.

  `ListServicesCriteria::fromRequest` confirms `?category=` and `?channel=` are the two
  supported filters, both an enumerated allow-list where an unrecognised value is
  *dropped rather than applied*, so a client cannot widen or reshape the query. Its
  comment also draws a distinction the app must preserve: **the `?channel=` query
  parameter is a presentation filter chosen by the caller and is unrelated to the
  `X-Client-Channel` header** — neither confers authority. Sending the header does not
  filter the catalogue, and sending the filter does not change what the caller is allowed
  to see.

  Accepted wire values (`Modules\Shared\Application\ClientChannel`): `citizen-web`,
  `citizen-mobile`, `admin-console`, `verifier-device`, `unknown`.
- **The `national` category currently has no resident-visible entry.** A `national`
  destination in the app today would be an empty screen. It is designed for, not shipped.

### 1.2 Category vocabulary (authoritative)

`Domain/ServiceCategory.php` — stable strings, safe to key translations off:
`dokumento` · `buwis` · `kalusugan` · `trabaho` · `ids` · `national`.

### 1.3 Publication lifecycle (authoritative)

`Domain/PublicationStatus.php`: `draft` → not visible to citizens · `published` → offered
· `retired` → not visible, retained for historical transactions. A single enumerated
state, explicitly not a pair of booleans.

**Client rule:** the app treats *anything it did not receive* as not offered. It must
never infer availability from a cached list, and must never render a "retired" service
because it saw it yesterday.

---

## 2. Feature matrix

Access column: **G** = guest · **A** = authenticated (verified or not) · **V** = verified.
"Administering capability" is the LGU function that operates the feature — the thing the
staff console exists to do.

### 2.1 Built in TAB 01

| Feature | Administering capability | Backend resource | Access | Resident-visible fields | Staff-only — must not reach this app |
| --- | --- | --- | --- | --- | --- |
| Splash / session restore | — (client) | none | G | none | none |
| Onboarding | LGU communications | none (static copy) | G | none | none |
| Sign-in | `Identity` (**planned**) | **NOT YET SPECIFIED** | G | own mobile number | password hashes, tokens of other accounts, login audit trail |
| Home / service browse | `ServiceCatalog` | `GET /api/v1/services` | G | `id`, `code`, `name`, `description`, `category`, `available_channels` | unpublished entries (`draft`/`retired`); `status` is present in the resource but is not resident copy — see §3.1 |
| Account & preferences | `Identity` (**planned**) | **NOT YET SPECIFIED** | A | display name, contact details, notification/haptic preferences | role and permission assignments, internal account flags, staff notes |
| Verification | `ResidentProfile` (**planned**) | **NOT YET SPECIFIED** | A | own submission status + next action | reviewer identity, internal review notes, rejection reason codes, risk scores |
| Digital ID | `Credential` (**planned**) | **NOT YET SPECIFIED** | V | own credential as issued by the LGU | QR signing keys, revocation lists, other residents' credentials |
| Service status check | `Shared` | `GET /api/v1/health` | G | `service`, `status`, `api_version` | dependency versions, environment names, configuration (server already forbids these — conventions §8) |

### 2.2 Planned, backend not yet built — **do not implement**

| Feature | Administering capability | Backend module | Access | Notes |
| --- | --- | --- | --- | --- |
| Document requests (`dokumento`) | Municipal Civil Registrar / Treasurer | `ServiceDelivery` (planned) | V | Applying against a service is a transaction on the resident's civil record. |
| Real property tax (`buwis`) | Municipal Assessor / Treasurer | `ServiceDelivery` (planned) | V | Assessment enquiry reveals property ownership — verified only. |
| Health services (`kalusugan`) | Municipal Health Office | `ServiceDelivery` (planned) | V | Health data is sensitive personal information under RA 10173 §13. |
| Employment (`trabaho`) | PESO | `ServiceDelivery` (planned) | **A** | See §3.3 — deliberately not `V`. |
| Resident ID application (`ids`) | Civil Registrar / ID office | `Credential` (planned) | A | Must be reachable while unverified: this is how a resident *becomes* verified. |
| National referrals (`national`) | Assisted-access desk | `ServiceDelivery` (planned) | V | No resident-visible entry exists yet (§1.1). |
| Notifications | `Notification` (planned) | planned | A | Per-resident channel preferences. |
| Assistance / social welfare | **MSWDO staff console** | not in LGU IDS backend | — | See §4. Out of scope for this app until a backend module owns it. |

---

## 3. Access-level decisions and their reasoning

### 3.1 Service catalogue is public — **G**

The backend route is unauthenticated *by explicit design*, with the reason in the route
file: *"citizens must be able to browse it before registering."* The app must not add an
account requirement the server does not have. Requiring registration to read public
service information collects personal data with no purpose behind it.

**Field note.** `LguServiceResource` includes `status`. Since a resident only ever
receives `published` entries, the field is constant from their point of view and is not
rendered. Rendering it would invite a future contributor to branch resident UI on a
lifecycle value that the server has already filtered.

### 3.2 Credential display requires verification — **V**

A credential is a statement by the LGU about a person whose identity it has confirmed.
Enforced server-side; the app's route requirement only avoids a screen that would fail.

### 3.3 Employment services are authenticated, not verified — **A**

Applying the Esperanza principle (feature audit §2.2: *gate on the harm of getting it
wrong*). PESO job matching is a referral service; an unverified resident who reaches a
job listing suffers no harm, whereas an unemployed resident blocked behind a verification
queue may miss the referral entirely. Employment is also a livelihood service, where the
cost of over-restriction falls hardest on the people the service exists for.

**Constraint:** this is a *presentation* decision. If the backend later authorises
`ServiceDelivery` for verified residents only, the server's answer wins and this row
changes — not the other way round.

### 3.4 Resident ID application is authenticated — **A**

Necessarily. Requiring verification to apply for the credential that confers verification
is a closed loop, and it is the most common way an ID flow becomes unreachable.

---

## 4. Staff capabilities that must never appear in this app

The MSWDO staff console (`Taytay_Rizal_Social_Welfare_Angular`) is the reference for what
"staff-only" means concretely. Its domain covers `assistance`, `disbursements`,
`programs`, `referrals`, `residents`, `geography`, `access`, `notifications`.

**None of it is built here** (`CLAUDE.md` Article 0). Recorded so the boundary is
checkable rather than assumed:

| Staff capability | Why it never appears in the resident app |
| --- | --- |
| Assistance casework — intake, eligibility, approval | Decisions *about* a resident, made by staff. A resident may see their own outcome; never the queue, never another person's case. |
| Disbursements / payouts | Money movement, authorised by role and office. |
| Programs & eligibility rules | Publishing an eligibility rule to a client invites a client to evaluate it. |
| Referrals between offices | Inter-office routing with staff attribution. |
| Resident master record editing | Staff edit the master record; a resident submits changes for review. Different operations. |
| Access control — roles, permissions, scope | `Role::Resident` holds no permissions. There is nothing to render. |
| Geography administration | Barangay reference data may be *read*; administering it is staff-only. |
| Audit trail | Append-only staff record. |

### 4.1 Specific fields that must not reach this app

From the staff console's `domain/residents/resident.ts` — a concrete list, not a category:

| Field | Reason |
| --- | --- |
| `sectors` including `SENSITIVE_SECTORS = ['vawc-survivor', 'cicl']` | VAWC-survivor and children-in-conflict-with-the-law status is sensitive personal information under RA 10173 §13 and is protected by RA 9262 and RA 9344 confidentiality rules. It must not be cached on a device, and must not be rendered in a context another person could see over a resident's shoulder. |
| `monthlyIncome`, `Household.isIndigent` | Means-test outcomes. Disclosing an indigency classification to the household is a casework conversation, not an app field. |
| `philsysLastFour` | A PhilSys fragment. `CLAUDE.md` Article 5.2 forbids government identifiers in logs; storing even a fragment client-side is unnecessary. |
| `audit: AuditStamp` | Who touched the record and when — staff attribution. |
| `isActive` | An administrative flag whose meaning is internal. |
| `householdId`, `Household.members` | Household composition links one resident's record to others'. Displaying it in one resident's app discloses other people's association. |

**Rule.** These are excluded by *the server not sending them*, which is where exclusion
belongs. This list exists so that if one ever appears in a response, it is recognised as
a defect on both sides rather than rendered because it arrived.

---

## 5. Cross-cutting client rules

1. **Never send an authority-shaped value.** No role, permission, tier or `is_admin` in a
   request (`X-Client-Channel: citizen-mobile` is telemetry only — ADR 0002 §3).
2. **Branch on error `code`, never `message`.** Codes are versioned; messages are not.
3. **Ignore unknown response fields** (conventions §1). A new server field must never
   crash a released app.
4. **Every collection is paginated** — `per_page` default 25, max 100. No unbounded list.
5. **Timestamps are ISO-8601 UTC**; identifiers are UUIDs; money is integer centavos.
6. **`Idempotency-Key` on any state-changing call the app may retry** (conventions §7).
   A resident on a flaky connection must not create duplicate applications.
7. **404 may mean "not permitted to know it exists"** — the app must not infer existence
   from a 404 or distinguish it from a genuine absence.

---

## 6. Gaps and what they block

| # | Gap | Blocks | Disposition |
| --- | --- | --- | --- |
| G-1 | No OpenAPI/JSON-Schema document in the backend | Generated clients; contract tests | Prose + source is the contract for now. Raise with backend; do not invent a spec here. |
| G-2 | `Identity` module not built | Sign-in, account, tokens | `PendingBackendAuthRepository` declines honestly. No schema invented. |
| G-3 | `ResidentProfile` module not built | Verification submission, profile | Verification screen explains, submits nothing. |
| G-4 | `Credential` module not built | Digital ID, QR presentation | Placeholder only. |
| G-5 | `ServiceDelivery` module not built | Every application flow | Catalogue is browse-only. |
| G-6 | No `verification_tier` field observed in any response | `AccessLevel.fromVerificationTier` input | Mapper already fails closed to `unverified`. Confirm the field name with backend before TAB 03. |
| G-7 | `BUSINESS_PERMIT` excluded from `citizen-mobile` | Residents may expect it | Product question for the LGU, not a client workaround (`CLAUDE.md` Article 3.7). |
| G-8 | Catalogue is config-backed, in-memory paginated | Nothing today | Backend's own comment notes a DB repository must paginate in SQL. |
| G-9 | Backend working tree holds accepted-but-uncommitted infrastructure work (ADR 0004 deployment topology, ADR 0005 bearer-token authentication, trusted-proxy tests) | Token refresh and revocation design | Audited against committed `fa77cef` only. Tracked as decision D-17; re-check when committed. |

---

## 7. Summary

- **2** resident-reachable endpoints exist today; both are unauthenticated by design.
- **6** service categories and **7** catalogue entries are authoritative; **5** are
  available on `citizen-mobile`.
- **8** features are built or scaffolded; **8** more are designed but blocked on backend
  modules that do not exist.
- **8** staff capability areas and **6** specific field groups are named as permanently
  out of bounds.
- **9** gaps recorded; none is worked around client-side.
