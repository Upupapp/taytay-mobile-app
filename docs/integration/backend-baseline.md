# Backend integration baseline

**Status:** authoritative for this repository. Every statement here was produced by reading
or running the two repositories on the date below. Nothing is taken from a status document,
because on this platform the status documents have already been shown to drift from the
code — that is the whole reason this file exists.

| | |
| --- | --- |
| **Backend repository** | `Upupapp/taytay-backend` |
| **Baseline tag** | `api-baseline-2026-08` |
| **Commit** | `eec71e671378b7a2cd933bf37f8b519e7e82e361` (`eec71e6`) |
| **Commit subject** | TAB 01 — publish the contract the API actually serves |
| **Baselined on** | 18 August 2026 (`2026-08-18`) |
| **Derived from** | `docs/architecture/domain-boundary-map.md` at that tag |
| **App commit at baseline** | `86e92b3` (TAB 28) |

## Why `eec71e6` and not `22cb10d`

The Master Command names `22cb10d` as the backend baseline. This baseline is two commits
later, and deliberately so. `22cb10d` is an ancestor of `eec71e6`, so nothing is lost, and
both intervening commits are contract-publication work that this integration consumes
directly:

* **`eec71e6` fixes the published error codes** — the defect the Master Command raises as
  F05. Both generators emitted the PHP enum *case name* (`ValidationFailed`) where the wire
  carries the backing value (`VALIDATION_FAILED`). Baselining at `22cb10d` would vendor a
  contract known to be wrong on the one field clients are told to branch on, and would put
  TAB 01 to work routing around a defect that is already closed upstream.
* **`eec71e6` publishes the `Pagination` schema.** Before it, `meta` was a bare
  `{"type":"object"}` on every response — so the envelope conformance tests TAB 01 asks for
  would have had nothing to assert against, on a contract this app already implements
  correctly.

Verified at the tag: the published error enum carries all thirteen wire values, and
`Pagination` requires `page`, `per_page`, `total`, `total_pages` and `has_more`.

**F05 is therefore closed at the source, not routed around.** The instruction in the Master
Command's TAB 01 §2 — "do not generate the app's error enum from `openapi.json` while F05
stands" — no longer binds. It is safe to generate from the contract at this tag onward. The
exception it asked to be recorded is recorded here as *lifted*, with the commit that lifted
it, and `test/contract/contract_conformance_test.dart` now uses the published enum as the
authority in both directions. A guard named `_wire values are SCREAMING_SNAKE_CASE, not PHP
case names_` keeps the regression visible if a future generator change reintroduces it.

The tag is a local annotated tag. It has not been pushed; pushing is outside the boundary
this programme runs under.

## Module status — the two axes

A module has **two** statuses and reading only the first is how TAB 06 would have been
planned against a false premise in exactly the way this app was. `Credential` is built and
switched off; "implemented" alone does not tell you a resident can use it.

| Module | Built | Enabled | Publishes `api/v1` routes |
| --- | --- | --- | --- |
| `Shared` | implemented | yes | yes |
| `AccessControl` | implemented (TAB 07) | yes | yes |
| `ServiceCatalog` | implemented | yes | yes |
| `Identity` | implemented (TAB 05) | yes | yes |
| `ResidentProfile` | implemented (TAB 06, 08, 09, 10) | yes | yes |
| `Credential` | implemented (TAB 06) | **no — `credential.enabled` is false** | yes |
| `Welfare` | implemented (TAB 11, 14, 16) | yes | yes |
| `Files` | implemented (TAB 15, 28) | yes | no (served through owning modules) |
| `Tasks` | implemented (TAB 19) | yes | yes |
| `Notification` | implemented (TAB 20) | yes | yes |
| `Reporting` | implemented (TAB 21) | yes | yes |
| `Search` | implemented (TAB 22) | yes | yes |
| `Content` | implemented (TAB 23, 24) | yes | yes |
| `Events` | implemented (TAB 25, 26) | yes | yes |
| `Audit` | implemented (TAB 29, 32) | yes | yes |
| **`Verification`** | **planned** | — | no |
| **`ServiceDelivery`** | **planned** | — | no |

Measured at the tag: **15 module directories**, 14 of which publish `Routes/api_v1.php`;
`Files` has no HTTP surface of its own by design (ADR 0020 §1). `Verification` and
`ServiceDelivery` have no directory at all. **262 `api/v1` routes** in total, of which
**33** are outside the `admin/`, `staff/` and `me/` prefixes.

The enabled column is not derived from the boundary map, which does not carry it. It is
read from `config/client.php`, which is also the source `GET app/bootstrap` publishes to
clients — one source per flag, so the endpoint cannot claim a feature is on while the module
refuses it.

## The two genuine gaps

`PlannedModule` in `lib/core/api/planned_backend.dart` has exactly these two members and no
others. Neither has a repository in this app.

### `Verification`

Owns verification attempts, scan events, the verifier registry and offline-verification key
distribution. This is the **verifier** side: a device or kiosk scanning a resident's QR at a
counter, on the `verifier-device` channel.

* **What this app does instead:** nothing, and correctly. Building it here would put a staff
  surface in the resident repository, which Article 0 of this repository's constitution
  forbids outright.
* **What the resident sees:** no change. Nothing in the resident app depends on it.
* **Launch decision:** a credential QR can be *produced* at launch and cannot be *proven*
  end-to-end until the verifier client exists. The launch scope must say so. "The digital ID
  works" must not be reported when only half the loop is testable.
* **Note:** the app's `PlannedVerificationRepository` was named after this module and is not
  about it. See F17.

### `ServiceDelivery`

Owns service applications and transactions against catalogue entries — dokumento, buwis,
kalusugan, trabaho, national referrals — their state machines and attachments.

* **What this app does instead:** nothing. No screen offers a national service transaction.
* **What the resident sees:** the services directory lists what the LGU offers; it does not
  offer to transact.
* **Launch decision:** out of scope, stated rather than discovered. Residents and frontline
  staff must be told before launch that the app does not yet submit national service
  transactions.
* **Note:** three of this app's repositories were filed under this module and none of them
  belongs to it. See F17.

## Findings raised by this re-baseline

The Master Command carries F01–F12. These are additional, found while re-deriving. F13–F16
are **backend gaps**: the module is built and the route is absent. They are neither planned
work nor wiring work, which is why they had no name before and why they are the ones most
likely to be planned around by both sides and closed by neither.

| ID | Sev | Finding | Owner |
| --- | --- | --- | --- |
| **F13** | P1 | **No route closes, erases or deletes an account.** `Audit` serves consents and acknowledgements; nothing serves closure. Both app stores require an in-app account deletion path, so this blocks store submission. Needs TAB 18's retention schedule before it can even be specified — a municipal record cannot always simply be erased. | backend · TAB 22 |
| **F14** | P2 | **No resident-facing barangay directory.** The registration and address flows need Taytay's barangays. The only barangay routes are `POST staff/{staff}/barangays` and its delete — `AccessControl` staff scoping. Hardcoding the list in the client was considered and rejected: barangay names and boundaries are municipal records, and a client copy is a second source of truth that goes wrong quietly. | backend · TAB 04 |
| **F15** | **P0** | **No resident can create their own account.** The entire public `Identity` surface is sign-in. `auth/otp` answers "if that number is registered, a code has been sent to it" and returns null for a number it does not hold. Citizen accounts are created by staff at `POST admin/residents` and bound to a login at `POST admin/residents/{resident}/account-links` — admin-console surfaces this app may not call. **Onboarding on this platform is staff-mediated by construction, and this app ships a seven-field self-registration wizard with no server counterpart.** | product · LGU |
| **F16** | **P0** | **A sign-in code is issued, recorded, and never sent.** `AuthenticationController::requestCode` calls `requestSignInCode` and then `unset($code)` — deliberately, so it is neither returned nor logged, which is right. Nothing dispatches it. The comment there still says delivery waits on the `Notification` module; `Notification` has been implemented since backend TAB 20 and has no awareness of sign-in codes at all. **TAB 02's definition of done — a resident signing in by OTP on a physical device — is unreachable by any amount of correct client wiring while this stands.** | backend · TAB 02 |
| **F25** | P1 | **The proxy body limit is unknown and is currently a guess.** A body over nginx's `client_max_body_size` is refused *by nginx*, before the application — so the answer is not the JSON envelope, carries no error code, and on some stacks arrives looking like a dropped connection. The app therefore refuses oversized uploads client-side first, at 8 MB, which is a number nobody has confirmed. **It must be reconciled with the deployed proxy before launch**: too high and residents still meet an unreadable failure after paying to upload; too low and the app refuses documents the office would have accepted. | backend · TAB 10 |
| **F24** | P1 | **There is no per-service intake form.** The app asks the server what to put on an application form, so a change to a programme does not need an app release. Nothing publishes that. The closest thing is a programme's requirement template (wired at TAB 07), but it is keyed by programme UUID rather than service code and lists documents to bring rather than questions to answer. Hardcoding a question list is a form the office never agreed to, collecting answers nobody reads — discovered wrong once a caseworker opens the first application. | backend · TAB 08 |
| **F23** | P1 | **A KYC correction cannot be filed the way the office asks for it.** `POST me/profile/corrections` takes named fields; this app groups what a resident recognises — "your details", "proof of identity" — because those are the categories a reviewer flags. "Your details" is three fields and a document is none of them. Categories that map to exactly one field are sent; the rest decline, because a correction filed against the wrong field is worse than one not filed — the resident believes the office has been told. Closing it needs per-field corrections in the app or a KYC-shaped route on the server. | decided · TAB 04 |
| **F14** | **raised to P1 at TAB 04** | **No barangay directory now blocks the Verified state outright.** `POST me/kyc` requires a `barangay_id` validated against the `barangays` table, and no route publishes that list to a resident. A resident cannot supply an identifier they have no way to obtain, so opening a KYC case is impossible from this app — which means the Verified state, the digital ID and every service that rests on it are unreachable. Filed at P2 as a registration-form inconvenience; it is the critical path. | backend · TAB 04 |
| **F22** | P1 | **There is no token-refresh endpoint, so "one refresh under concurrency" is "one sign-out under concurrency".** TAB 03 asks that an expired token trigger exactly one refresh with concurrent requests queued behind it. `Identity` publishes no refresh route at this baseline and inventing one would be a path the server never agreed to. `AuthCoordinator` already serialises recovery and its refresher is deliberately unregistered, so the guarantee holds with the honest verb: ten concurrent `401`s produce exactly one invalidation, asserted by test. | decided · TAB 03 (closed) |
| **F20** | **P0** | **Three of the six endpoints TAB 02 names are staff surfaces.** `POST auth/tokens`, `POST auth/tokens/mfa` and `POST auth/password/forgot` all filter `account_type = Staff` server-side and take an email and a password; a citizen account is excluded before the password is even checked. Wiring them would put admin-console surfaces in the resident repository, which Article 0 forbids outright, and the code could never do anything but fail. **Not wired, deliberately.** The consequence for TAB 02's definition of done: "signs in by password" and "with MFA enabled and disabled" are not applicable to this app — citizen sign-in is OTP only and `verifySignInCode` has no MFA branch. | decided · TAB 02 (closed) |
| **F21** | P1 | **The verification tier is not on `GET me`.** TAB 02 and TAB 04 both say the tier comes from `GET me`; that endpoint returns account fields — id, status, display name, `mobile_verified`, `mfa_enabled`, permissions, roles, `resident_id` — and no tier. It is `ResidentProfile`'s, on `GET me/profile`. Sign-in therefore reads both, and an account with no resident link or a failed profile read stays **unverified**. Without this, no resident could reach the Verified state at all. | this repo · TAB 02 (closed) |
| **F19** | P1 | **The programme contract was wrong on three axes, and one of them locked a door.** `ProgramRepository` declared programmes bearer-authenticated at `GET programs?status=active`; the route carries no `auth:sanctum`, there is no `status` parameter anywhere in the contract, and `programs/{program}` resolves by **UUID** rather than by the code the app was sending. The auth error was the expensive one: `/programs` required an account, so a guest could not read what the municipality had deliberately published for everyone — withheld from exactly the residents least likely to already have an account. The projection was also modelled from a "visibility matrix §5" the server no longer follows, which would have rendered every programme with a name and nothing else. | this repo · TAB 07 (closed) |
| **F18** | P2 | **`app/bootstrap` publishes no maintenance state.** The payload carries `service`, `api_version`, `server_time`, `timezone`, `client`, `features`, `support` and `conventions` — TAB 01 asks for a maintenance screen driven by it and there is no field. **Recorded with a decision rather than a request: the app infers maintenance from a live `503 SERVICE_UNAVAILABLE` instead.** Maintenance changes minute to minute; a flag read once at startup would announce it after it ended and miss one that began, and a client caching it to survive a cold start caches the most perishable fact the server has. A 503 is the server saying so, at the moment it is true. Do not "fix" this by adding the field. | decided · TAB 01 (closed) |
| **F17** | P1 | **Four repositories name the wrong module, and shrinking `PlannedModule` cannot catch them.** Removing the four shipped members made the compiler point at six files. It could not point at these, because the names they reference still exist and still mean something real — just not this. See the table below. | this repo · TAB 00 (closed) |

### F17 in detail — the mis-attributions

| Repository | Claimed | Actually served by | Status |
| --- | --- | --- | --- |
| `PlannedVerificationRepository` | `Verification` (planned) | `ResidentProfile` — `me/kyc`, `me/kyc/submit`, `me/profile/corrections` | implemented |
| `PlannedProgramRepository` | `ServiceDelivery` (planned) | `ServiceCatalog` — `programs`, `programs/{program}` | implemented |
| `PlannedServiceRequestRepository` | `ServiceDelivery` (planned) | `Welfare` — `me/assistance/drafts`, `me/cases`, `me/assistance-history` | implemented |
| `PlannedRequirementRepository` | `ServiceDelivery` (planned) | `Welfare` + `Files` — `me/cases/{case}/requirements`, `documents/{handle}` | implemented |

`PlannedVerificationRepository` is the sharpest of these and turns on a single English word.
The backend's `Verification` is a verifier scanning a QR. What the repository actually does —
open an attempt, submit documents, read the outcome, answer a request for more information —
is KYC, which `ResidentProfile` has served since backend TAB 06. Its own domain file still
says "wire values are not published, so none are assigned here"; `me/kyc` publishes them.

### Additional staleness sources found

The app's beliefs were pinned to **three different backend commits**, not one:

* `lib/core/api/planned_backend.dart` — `7844859`
* `lib/features/registration/data/planned_registration_repository.dart` — `896cec9`, and it
  asserted `Identity` was "absent from `modules/`"
* `PlannedAnnouncementRepository`, `PlannedEventRepository`,
  `PlannedDeviceSessionRepository` — an unnamed "committed endpoint matrix", with no commit
  at all, and hardcoded reason strings that no enum change could ever invalidate

`PlannedAnnouncementRepository` also asked for a path that has **never existed** on this
backend: `GET announcements` is served by no module at any commit, while `Content` has served
`GET newsfeed` since backend TAB 23. A wrong path and a wrong module status are separate
errors and that file carried both.

## Corrections to the Master Command's measured figures

Stated in the spirit of the document itself, which says to re-measure rather than trust.

| Master Command | Measured at this baseline |
| --- | --- |
| "16 of its 18 repositories are bound to stubs" | **14 of 16.** The composition root binds 16 repositories; 14 were stubs, 2 were real (`PlannedRepository` count verified against `app_dependencies.dart`). |
| "four of six planned modules have since shipped" | Correct — but understated. **Zero of the 14 stubbed repositories are blocked on a genuinely planned module.** Every one has endpoints serving today, or a backend gap (F13–F16) that is not a planned module either. |
| "~70 resident endpoints" | Broadly right and incomplete: the inventory omits `Audit`'s resident privacy surface (`GET/POST me/privacy/consents`, `DELETE me/privacy/consents/{purpose}`, `POST me/privacy/acknowledgement`) and the public `GET privacy/notice`. |
| "Flutter 3.44.0 stable — present and working on this machine" | This machine runs **Flutter 3.47.0 / Dart 3.13.0**, inside the `^3.12.0` constraint. Suite and analyzer both clean on it. |
| F05 "the backend publishes the wrong error codes" | **Closed upstream** at this baseline. |

## The work plan for TABs 02–13

This is the failure list the re-baseline produced, captured as required by TAB 00's
definition of done. Six files came from the compiler; four more came from reading the two
contracts side by side, and would have shipped silently otherwise.

| Repository | Module | Endpoints | Wired by | Caught by |
| --- | --- | --- | --- | --- |
| `PendingBackendAuthRepository` | `Identity` | `auth/otp`, `auth/otp/verify`, `auth/tokens`, `auth/tokens/mfa`, `auth/password/forgot`, `DELETE auth/tokens/current` | TAB 02 | reading (no enum reference) |
| `PlannedDeviceSessionRepository` | `Identity` | `me/sessions` ×3, `me/devices` ×3 | TAB 03 | reading (no enum reference) |
| `PlannedRegistrationRepository` | — | **blocked, F15 + F14** | product decision | compiler |
| `PlannedResidentProfileRepository` | `ResidentProfile` | `me`, `me/profile` | TAB 04 | compiler |
| `PlannedVerificationRepository` | `ResidentProfile` | `me/kyc` ×3, `me/profile/corrections` ×3 | TAB 04 | reading (F17) |
| `PlannedHouseholdRepository` | `ResidentProfile` | `me/household` | TAB 05 | compiler |
| `PlannedCredentialRepository` | `Credential` (flagged off) | `me/credential`, `me/credential/qr` | TAB 06 | compiler |
| ~~`PlannedProgramRepository`~~ → `ProgramApiRepository` | `ServiceCatalog` | `programs`, `programs/{program}` | **TAB 07 — wired** | reading (F17) |
| `PlannedServiceRequestRepository` | `Welfare` | `me/assistance/drafts` ×5, `me/cases` ×3, `me/assistance-history`, `me/referrals` | TAB 08, TAB 09 | reading (F17) |
| `PlannedRequirementRepository` | `Welfare` + `Files` | `me/cases/{case}/requirements`, document upload and access, `documents/{handle}` | TAB 10 | reading (F17) |
| `PlannedAnnouncementRepository` | `Content` | `newsfeed` ×9 | TAB 11 | reading (no enum reference) |
| `PlannedEventRepository` | `Events` | `events` ×4, `me/event-registrations` ×2 | TAB 12 | reading (no enum reference) |
| `PlannedNotificationRepository` | `Notification` | `me/notifications` ×3, `me/notification-preferences` ×2 | TAB 13 | compiler |
| `PlannedAccountControlsRepository` | `Audit` (consents) | `me/privacy/consents` ×3, `me/privacy/acknowledgement`; **closure blocked, F13** | TAB 18, TAB 22 | compiler |

**Four of fourteen would have survived the mechanism TAB 00 specifies.** That is recorded
here rather than smoothed over, because it is the argument for the guard below: a compiler
check catches only the beliefs expressed as types, and the most confident wrong statements
in this app were expressed as prose.

## The three honest statements

The single sentence "the module is planned" was flattening three different situations with
three different owners. They are now three types, and telling them apart is the mechanism
this TAB delivers.

| Type | Means | Remedy | Members |
| --- | --- | --- | --- |
| `PlannedModule` | the backend has not built the module | backend roadmap | 2, no repositories |
| `BackendGap` | the module is built; **this route is not** | a named backend change | 4 (F13–F16) |
| `UnwiredRepository` | the route serves; we have not called it | an indexed TAB here | 14 |

Resident-visible behaviour is identical across all three — a temporary `ServerFailure`,
because "not built", "not routed" and "not connected" are the same afternoon to somebody
standing in a barangay hall. Only `AppFailure.debugMessage` differs, and that is for logs
and support tooling, never for a screen.

`UnwiredRepository.wiredBy` carries the TAB. The backlog is readable out of the source
rather than out of a document, because a document is what went stale.

## The guard

Two halves, because one of them needs a network and one of them must run everywhere.

1. **`test/integration/backend_baseline_test.dart`** — runs in `flutter test`, no network.
   Asserts that `PlannedModule`, `BackendGap` and `UnwiredRepository` agree with the tables
   in *this file*. Editing one without the other goes red.
2. **`tool/check_backend_baseline.sh`** — runs in CI and nightly. Reads the backend's
   `docs/architecture/domain-boundary-map.md` at the pinned tag, extracts the module status
   table, and fails if it differs from the table committed here. When the backend advances
   the baseline tag, this goes red and a human re-runs TAB 00.

Both have been proven to fail before being trusted; see the TAB 00 completion report.

**Do not re-derive module status by grepping route files.** Routes tell you what is exposed,
not what is supported; a module can publish a route it considers internal. The committed
boundary map is the backend's own declaration and is the authority. Route evidence in this
document is used only to confirm that a specific endpoint exists, which is a different
question.

**Do not baseline against `main`.** A moving baseline makes the guard oscillate, and a guard
that cries wolf gets disabled, which returns this repository to the condition this document
exists to end.
