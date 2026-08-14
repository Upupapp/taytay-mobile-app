# Taytay resident mobile — login, recovery, session and device security

How a resident signs in, what happens when a session ends, what they can control
on their own device, and which of those things the backend does not yet support.

Implemented in `lib/features/auth/`, `lib/core/session/` and
`lib/shared/widgets/session_expired_sheet.dart`.

---

## 1. What the committed backend supports

Audited against **`Taytay_Rizal_LGUIDS_Backend@75b251d`**, working tree clean,
`docs/contracts/frontend-endpoint-matrix.md` §2.

| Capability | Endpoint | Status | Built here |
| --- | --- | --- | --- |
| Request a code | `POST /api/v1/auth/otp` `{mobile_number}` → `202` | `planned` | ✅ step 1 |
| Verify a code | `POST /api/v1/auth/otp/verify` → `{token, expires_at, actor}` | `planned` | ✅ step 2 |
| Session bootstrap | `GET /api/v1/me` → `verification_tier` | `planned` | ✅ (TAB 05) |
| Sign out | `DELETE /api/v1/auth/tokens/current` → `204` | `planned` | ✅ |
| Admin sign-in | `POST /api/v1/auth/tokens` `{email,password,device_name}` | `planned` | ❌ **never** |

**What is absent from the contract, and therefore absent here:**

| Not built | Why |
| --- | --- |
| Password sign-in | The email/password route is marked **Admin sign-in**. A citizen app that accepts staff credentials is a staff surface in a resident repository (CLAUDE.md Article 0). |
| Forgot password / reset | There is no citizen password to forget. |
| Automatic token refresh | No refresh endpoint exists. ADR 0005 names *"short token lifetimes with refresh"* as a mitigation the browser clients must handle, but publishes no route. |
| Device-session list / revoke | Only `DELETE /auth/tokens/current` exists — this token. `POST /me/devices` is push-notification registration (§13), not a session list. |

The Master Command asked for each of these **"only if actually supported by the
committed contract"**. Each is a typed seam that declines, not a mock.

---

## 2. One identifier, no password

Sign-in is two steps because the contract is two calls. `SignInIdentifier`
accepts an 11-digit Philippine mobile number and nothing else; there is no field
for anything a staff member would type.

That is worth stating as a benefit rather than a limitation. A resident-chosen
password is the credential most often reused across services, and an LGU is
poorly placed to run a safe recovery for one — password reset by walk-in at a
municipal hall is both a queue and a social-engineering surface. Nothing is
memorised, so nothing can be phished with a "reset your password" link.

---

## 3. Nothing reveals whether an account exists — acceptance 3

`SignInMessage` is a closed set of seven messages. **None of them distinguishes
an unknown number from a wrong code from a refused account.** There is no such
value to select, so no screen can render one and no future edit can add one by
accident.

`SignInFeedback.forFailure` collapses `NOT_FOUND`, `FORBIDDEN`,
`VALIDATION_FAILED`, `CONFLICT` and `UNAUTHENTICATED` into a single
`codeNotAccepted`. Those are precisely the codes a server might use to
distinguish "no such number" from "wrong code"; keeping them apart in the client
would rebuild the enumeration oracle the backend refuses to be ("must not reveal
whether the number is registered", endpoint matrix §2).

Rate limiting is the one refusal kept separate, because it discloses nothing: it
says "not now" regardless of whether the number exists.

The success message is conditional — *"If that number is registered with Taytay
LGU, a code is on its way"* — because "we sent you a code" is itself a
confirmation that the number is registered.

**Why this matters more for an LGU than for a consumer app.** A sign-in screen
that answers "no account with that number" is a free lookup for whether a given
person is a registered Taytay resident, usable by a debt collector, an abusive
ex-partner, or anyone working through a list of numbers.

The help screen keeps the same promise: it has **no input field at all**, so it
cannot be used to test a number. Tests assert both the enum copy and the
rendered screen.

---

## 4. States a resident actually meets

| State | What they see |
| --- | --- |
| Loading | The action button shows a spinner at its own size and is disabled, so a second tap cannot spend a second attempt. |
| Code not accepted | One message, no detail. Ask for a new code. |
| Rate-limited / locked | "Too many attempts… please wait", with no reason given. |
| Offline | "You appear to be offline." |
| Timed out | "That took too long." |
| Service unavailable | "Signing in is temporarily unavailable." |

The server's `message` field is **never rendered** — `docs/api/conventions.md`
§4 defines it as operator-facing. On this screen even the dev-build debug detail
was removed: it would name the endpoint that refused, which is one step from
naming *why*.

---

## 5. Token storage and lifetime — acceptance 1

The token lives in the platform keystore (`KeystoreSessionStore` over
`flutter_secure_storage`, AES-GCM under an Android Keystore RSA-OAEP key;
`first_unlock_this_device` on iOS). That was TAB 05's work and is unchanged.

TAB 09 adds the server's own **`expires_at`** to what is persisted — additively,
so a session written by an older build reads back as "lifetime unknown" and is
resumed, never as "expired". Three behaviours follow:

* `restore()` does not resume a session whose deadline has passed. It clears it
  and reports `SessionEndedReason.expired`.
* `currentAccessToken()` withholds an expired token rather than putting a dead
  bearer credential on the wire.
* `endSessionIfTokenExpired()` runs on app resume.

**This is not an authorization decision.** A token is valid because the server
accepts it, and the server may revoke it at any moment before that timestamp — a
`401` is still the only verdict that ends a session for certain. What the
timestamp buys is the safe direction only: the app can stop presenting a token it
can already see is dead. Nothing in this path can extend a session or raise a
level, and a decode failure reads as "unknown", never as "expired", so a storage
bug cannot sign a resident out.

**No refresh was added.** `AuthCoordinator` still has no `TokenRefresher`
registered, so a `401` fails closed and ends the session. A source scan now
fails the build if anyone writes an `auth/refresh` path or a `refresh_token`
field.

---

## 6. Session expiry, explained

The router already moves a resident off a protected screen when the session ends.
Correct, but silent — and the reason matters, because it is the difference
between "the app is broken" and "this is how it protects me".

`SessionExpiryWatcher` sits above the router's output, reacts to the *transition*
into `GuestSession(expired)` rather than to the state, and shows one sheet with
two real exits: **Sign in again** and **Continue as guest**. A deliberate
sign-out is excluded — the resident asked for that.

Two implementation notes that were bugs first:

* `_wasAuthenticated` is assigned in `initState`, not as a `late` initialiser. A
  `late` field is not evaluated until first read, which would have been *inside*
  the listener, after the session had already become a guest — so the transition
  would never have been detected and the sheet would never have appeared.
* The haptic is fired unawaited. Awaiting a platform round trip before showing
  the words is the wrong order, and on a device that answers late it delays the
  explanation indefinitely.

---

## 7. Signing out, and what survives it — acceptance 2

Sign-out is confirmed, because it cannot be undone without a new one-time code —
and the confirmation is where the resident is told what they keep: *"You can
still browse Taytay services, offices and announcements as a guest."*

The order is deliberate: revoke server-side first, then clear locally
**regardless of the outcome**. A resident on a borrowed phone must always be able
to sign out, and a failed network call must never be the reason a token stays on
a device.

The result is a `GuestSession`, not "no session", so every public route stays
open. Tested end to end: sign out from the security screen, then reach the home
screen and browse.

---

## 8. The app lock — a local convenience, and nothing more

Optional. Off by default. It asks for a fingerprint, face or the device
PIN/pattern before re-showing an app that is **already signed in**, after it has
been backgrounded.

**What it is not.** It is not authentication. It proves nothing to Taytay LGU,
sends nothing to the server, and cannot change an access level. The session
behind it is exactly as authorised while locked as while unlocked. A local unlock
is a statement about a *device*, made by the device, to itself — and treating it
as identity proof would be the serious mistake here.

Four rules make it safe to ship:

1. **It never blocks a guest.** There is no resident data to protect when nobody
   is signed in, and hiding public services behind a prompt helps no one.
2. **There is always a way out.** The lock screen offers sign-out
   unconditionally. A resident whose sensor has failed, whose enrolled finger is
   bandaged, or who cannot pass the prompt must never be trapped. Turning the
   lock *off* also requires no unlock, for the same reason.
3. **Turning it on requires passing it once**, so nobody can enable a lock their
   device turns out not to satisfy.
4. **A device that can no longer satisfy it reads as off**, not as permanently
   locked. The alternative bricks the app for someone who changed a system
   setting.

The gate *replaces* the app's content rather than overlaying it, so the content
is not built and cannot appear in the OS task-switcher screenshot — which is
where a locked app most often leaks what it was showing.

`biometricOnly: false`: the device PIN or pattern is an acceptable fallback.
Requiring biometrics would strand a resident whose fingerprint stops being read
and would withhold the feature entirely from a handset with no reader — exactly
the cheaper phones this app must serve.

### The dependency

`local_auth ^3.0.2`, reviewed against Article 1 before adding: maintained by the
Flutter team in `flutter/packages`; Android `USE_BIOMETRIC` permission only; and
**no data egress** — the platform runs its own prompt against templates held in
the Secure Enclave or TEE and returns a boolean. No biometric template ever
reaches Dart, this app, or the network.

Platform changes: `MainActivity` extends `FlutterFragmentActivity`, because
`androidx.biometric.BiometricPrompt` is a fragment and needs a `FragmentActivity`
host. A source scan keeps the plugin import to one file and asserts no unlock
result reaches the data or transport layers.

The merged release manifest was checked rather than assumed. It carries exactly
three permissions:

| Permission | Declared by | Note |
| --- | --- | --- |
| `INTERNET` | this app | See §9. |
| `USE_BIOMETRIC` | this app and the plugin | API 28+. |
| `USE_FINGERPRINT` | the plugin | Legacy, for the deprecated `FingerprintManager` on API 23–27. Merged in automatically; normal protection level, no runtime prompt. Expect it in a store listing. |

No camera, storage, contacts or location permission enters the build.

---

## 9. A defect fixed on the way

`AndroidManifest.xml` declared **no `INTERNET` permission**. Flutter injects it
into debug and profile builds automatically but not into release, so a release
APK could not have reached the backend at all. Added, since a sign-in that cannot
reach the network in a release build is not a sign-in.

---

## 10. Verification

`dart format` clean · `flutter analyze` clean · **483 tests pass** · debug and
release APKs build.

TAB 09 coverage (60 tests): identifier and code validation; validation copy that
never mentions an account; number masking; the five failure kinds that collapse
to one message; every message scanned for enumerating phrases; the conditional
code-sent wording; rate limiting kept separate; no server debug text in resident
copy; step advancement and refusal; the session established only through
`SessionController`; the server's `expires_at` reaching storage; nothing about a
finished attempt retained; the resend cooldown and its clock; redacted
`toString` on the controller and the auth outcome; expired sessions not resumed
and cleared; unknown lifetime resumed; expired tokens withheld; resume-time
expiry that can only remove access; guest access surviving sign-out; the app lock
across nine behaviours including the guest case, the escape hatch and the
unchanged access level; the declining device-session seam; and screen-level tests
for both sign-in steps, the refusal, the resend, the help screen, sign-out with
and without confirmation, the expiry sheet and both its exits, the app lock
overlay, the security screen, and sign-in at 200% text scale.

Three pre-existing tests asserted behaviour TAB 09 deliberately changed — the
persisted-field set, unconfirmed sign-out, and the dev-build failure detail on
sign-in. They were **updated, not deleted**.

---

## 11. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| S-1 | No `POST /auth/otp` or `/auth/otp/verify` | Sign-in is complete and inert; `PendingBackendAuthRepository` declines. Nothing is simulated. |
| S-2 | No refresh endpoint | A session ends when the token expires or a `401` arrives. The resident signs in again. Re-open when Identity ships one. |
| S-3 | No device-session list or revoke | The security screen shows an honest "not available yet"; no fabricated list. |
| S-4 | Code length is assumed to be 6 | Implied, not published. Confirm against the Identity module. |
| S-5 | Resend cooldown is client-side only | A courtesy. The server is attempt-limited and its answer is the one that counts. |
| S-6 | No "sign out everywhere" | Needs S-3. A resident who suspects compromise is directed to the municipal hall. |
| S-7 | iOS `NSFaceIDUsageDescription` not added | Cannot be verified on this Windows host; required before an iOS build. |
| S-8 | English only | Filipino copy arrives with app-wide localisation. |
