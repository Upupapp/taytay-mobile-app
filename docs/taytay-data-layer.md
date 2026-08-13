# Taytay resident mobile — data layer and backend contract foundation

The typed network and data foundation: transport, retry, auth recovery, storage,
caching, repositories and DTO mapping. Implemented in `lib/core/api/`,
`lib/core/storage/` and each feature's `domain/` + `data/`.

---

## 1. What the committed backend actually publishes

Audited against **`Taytay_Rizal_LGUIDS_Backend@7844859`**, working tree clean.
Uncommitted backend work is not treated as authoritative, and no endpoint, field
or schema is invented here.

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| `GET` | `/api/v1/health` | none | `service`, `status`, `api_version` only |
| `GET` | `/api/v1/services` | none | **Public by design** — the published catalogue |
| `GET` | `/api/v1/admin/services` | `auth:sanctum` | Same controller and query; the prefix grants nothing |

Implemented modules: `Shared`, `AccessControl`, `ServiceCatalog`. **Planned and
unpublished:** `Identity`, `ResidentProfile`, `Credential`, `Verification`,
`ServiceDelivery`, `Notification`.

### Change since TAB 02

ADR 0004 (deployment topology) and **ADR 0005 (first-party bearer tokens)** are
now committed — they were accepted-but-uncommitted at TAB 02, recorded then as
gap G-9 and decision D-17. That closes the question of *how* the app
authenticates: `Authorization: Bearer <token>` over HTTPS, no cookies, no CSRF
surface. It does **not** open the question of refresh — see §4.

---

## 2. Transport

`HttpApiTransport` over `package:http`, chosen for a small surface with no
interceptor framework of its own: retry, auth and correlation are this app's
policy, in files that can be unit-tested, rather than configuration inside a
third-party client.

Responsibilities stop at bytes: resolve the URL from `AppConfig`, send, apply
the timeout, apply the retry policy, and translate socket-level failures into the
`AppFailure` taxonomy. It never throws — every path returns an `Err`.

`SocketException`, `HandshakeException`, `TimeoutException` and
`http.ClientException` are mapped distinctly in the **debug** message while the
resident sees the same plain connectivity copy; a TLS handshake failure against a
government endpoint deserves a different investigation from a dropped
connection.

---

## 3. Retry and idempotency

### The rule

**A request is retried only when repeating it cannot create a second thing.**

- `GET` is always repeatable — the contract states `GET`/`HEAD` never mutate.
- `POST`/`PUT`/`PATCH`/`DELETE` are repeatable **only** with an
  `Idempotency-Key`, because the contract guarantees that replaying a key
  returns the original result (conventions §7).

Without the key, a retry after a dropped connection is how one resident ends up
with two document applications. A connection dropping *after* the server
committed is indistinguishable, from the client, from one dropping before — so
"it probably didn't go through" is not a judgement the app is entitled to make.

### What is retried

| Condition | Retry | Why |
| --- | --- | --- |
| Network / timeout | yes | Commonest mobile failure, usually transient |
| `429` | yes, honouring `Retry-After` | The server said when to return |
| `503` | yes | Dependency down or maintenance |
| `502` / `504` | yes | Gateway-level; the application never saw it |
| `500` | **no** | The application saw it; repeating repeats the fault |
| `401` | **no** | Handled once by the auth layer |
| other `4xx` | **no** | The request is wrong; resending does not fix it |

### Backoff

Exponential with **full jitter** — uniform in `[0, base · 2^attempt]`, capped at
8 s, 3 attempts total. Deterministic backoff synchronises every client that
failed at the same moment (a tower handover, a backend restart) into a herd that
arrives together and knocks the service over again. A server `Retry-After` always
wins, capped at 30 s so a long instruction fails the call instead of hanging it.

*Source: AWS Architecture Blog, "Exponential Backoff and Jitter" — full jitter for
this workload shape. Re-verify before changing the strategy.*

---

## 4. Auth recovery — built, and deliberately inert

`AuthCoordinator` implements **single-flight** recovery: several requests
failing with `401` at once cause **at most one** refresh, and every caller awaits
the same verdict. Without that, an expiring token produces a burst of refreshes
for one account — which a well-built server rate-limits or treats as replay, and
which on a rotating-token scheme makes the racing calls invalidate each other and
sign the resident out despite a valid session.

**No refresh call is made, because no refresh endpoint exists.** ADR 0005 names
*"short token lifetimes with refresh"* as a required mitigation, but the
committed backend publishes no `Identity` module and no refresh route. Inventing
a path and payload would create a contract the server never agreed to. So the
mechanism is real and tested, and `TokenRefresher` is left as a seam.

**Fail closed, everywhere.** Any outcome that is not a definite success — no
refresher, a `null` token, a thrown exception — invalidates the session. There is
no path where an uncertain result leaves the app believing it is authenticated.
With no refresher registered, which is today's state, a `401` ends the session
immediately.

On a successful refresh the request is replayed **exactly once**, with a **fresh
correlation id** so the replay is traceable as a distinct request. A second `401`
after refresh invalidates rather than looping.

---

## 5. Storage

### Credential material — platform keystore only

`KeystoreSecretStore` wraps `flutter_secure_storage` **11.0.0**, verified against
the installed plugin source (its Android API changed in v10/v11; the old
`encryptedSharedPreferences` flag no longer exists).

- **Android:** `AES/GCM/NoPadding` under an `RSA-OAEP`-wrapped key in the Android
  Keystore, hardware-backed where a TEE or StrongBox exists. `resetOnError: true`
  because a keystore entry can become undecryptable after an OS upgrade or
  restore, and an app that throws on every launch is worse for a resident than
  one that asks them to sign in again. `migrateWithBackup: false`.
- **iOS:** `first_unlock_this_device`. *ThisDevice* keeps a government token out
  of iCloud Keychain and encrypted backups; *AfterFirstUnlock* keeps it readable
  after a reboot, where the stricter `unlocked` would fail whenever the device is
  locked and `passcode` breaks entirely on a device without one.
- **Biometrics are not required to read the session token.** That would lock out
  residents with no enrolled biometric, and the keystore already protects it.
  Biometric gating belongs on presenting a credential.

`KeystoreSessionStore` persists exactly three fields — account id, verification
tier, greeting name — plus the token. Minimisation is enforced by the *shape* of
`ResidentSession`, not by a convention: there is nothing else to write.

Two details that matter:

- **Write order:** summary first, token last. If the process dies between writes,
  the next read finds a summary with no token, treats it as no session and
  clears. **Clear order** is the reverse, so an interrupted clear leaves a label
  that cannot authenticate rather than a token nobody will clean up.
- **The tier is stored as the server's vocabulary** (`"verified"`), never as an
  enum index, so an app update that reorders the enum cannot promote a stored
  session. Restoring an unrecognised tier fails closed to `unverified`.

### Public cache — structurally cannot hold anything personal

`PublicCache.store` takes `authenticated` as a **required** argument and refuses
to write when it is true, and only accepts allow-listed keys (`services`,
`health` — both unauthenticated on the server). A caller cannot forget to
consider it. That matters because the usual way personal data reaches a cache is
not a decision, it is a generic wrapper applied to one more endpoint.

In memory only; nothing is written to disk. Entries carry a TTL and are **evicted
on read** when stale, so a caller that receives data has no obligation to check
whether it should have. Cleared on sign-out and on session invalidation.

---

## 6. Repositories and DTO mapping

| Domain | Contract | Implementation |
| --- | --- | --- |
| ServiceCatalog | `ServiceCatalogRepository` | **Real** — `GET /api/v1/services` |
| Platform health | `PlatformRepository` | **Real** — `GET /api/v1/health` |
| Identity | `AuthRepository` | Declines — module planned |
| ResidentProfile | `ResidentProfileRepository` | Declines — module planned |
| Credential | `CredentialRepository` | Declines — module planned |
| Verification | `VerificationRepository` | Declines — module planned |
| ServiceDelivery | `ServiceRequestRepository` | Declines — module planned |
| Notification | `NotificationRepository` | Declines — module planned |

### Preserving server capabilities without duplicating server logic

`ServerValue<T>` carries **both** the raw string the server sent and the enum
case when this build recognises it. The contract is explicit that adding an enum
value is *not* breaking, so a released app will meet values it has never heard
of; it must not crash, must not silently drop them, and must not guess. Screens
branch on `known` and degrade; support quotes `raw`.

`LguService` exposes `status` and `availableChannels` as **facts the server
reported**, and two derived getters that only restate them
(`isOfferedOnMobile`, `hasUnrecognisedValues`). There is deliberately **no
`canApply`, no `isEligible`, no `requiresLevel`** — eligibility, approval and
authorisation are server decisions (ADR 0002), and a client copy would drift from
the real rule and be wrong in a build nobody can patch quickly.

Malformed rows are skipped rather than failing a page: one bad record must not
hide the whole catalogue from a resident.

### Least privilege in the contracts themselves

Every resident-scoped method is named for **own** data — `loadOwnSummary`,
`loadOwnCredential`, `listOwnRequests`. None takes another resident's identifier.
An API that cannot express "fetch someone else" cannot be misused into it.

Idempotency keys are **required parameters**, not optional ones, on every
state-changing operation a mobile client would retry.

---

## 7. Verification

`flutter analyze` clean · **280 tests pass** · debug and release APKs build.

New negative cases include: unkeyed `POST` never retried however transient the
failure; `500` never retried while `503`/`429`/`502`/`504` are; `Retry-After`
honoured and capped; full jitter bounded and actually varying; concurrent `401`s
producing exactly one refresh; a refresher returning `null` or throwing treated
as failure; a second `401` after refresh invalidating instead of looping; an
authenticated request with no token never reaching the wire; the cache refusing
authenticated responses and non-allow-listed keys; stale entries evicted on read;
partial, orphaned and corrupt keystore state reading as no session and clearing;
an unrecognised tier restoring as `unverified`; unknown categories and channels
preserved rather than dropped.

Source scans assert: no `shared_preferences` dependency or reference; the
secure-storage plugin imported in exactly one file; no hard-coded credential
literals; no `print`/`debugPrint`; session, store and request-context `toString`
never interpolating the token, account id or display name; no JSON parsing
outside `data/`; no authority-shaped header or field; `X-Client-Channel` sent
from one place; no hard-coded absolute URL outside configuration; the HTTP
package imported only by the transport.

---

## 8. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| D-1 | No refresh endpoint in the committed contract | `TokenRefresher` unimplemented; a `401` ends the session. Wire it up when `Identity` ships. |
| D-2 | Five domains have contracts but no endpoints | Their repositories decline with a temporary failure. |
| D-3 | No OpenAPI document | Contract is prose plus PHP source; no generated client, no contract tests. |
| D-4 | No certificate pinning | Relies on platform trust. Worth an explicit decision before handling credentials in production. |
| D-5 | Cache is in-memory only | The catalogue is re-fetched each launch. A disk cache was rejected as more risk than value. |
| D-6 | No offline queue for submissions | A failed submission is reported, not deferred. Belongs with the first real write endpoint. |
| D-7 | `flutter test` needs `%PROGRAMFILES(X86)%` on this host | Environmental: adding a plugin with a Windows implementation makes the tool probe the Windows toolchain. Set the variable when running tests. |
