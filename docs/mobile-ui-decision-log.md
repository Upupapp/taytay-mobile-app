# Mobile UI decision log

Material product, privacy, authorization, schema and lifecycle decisions for the Taytay
resident app. One entry per decision: the options considered, what was chosen, why, and
what evidence it rests on.

**How to read a decision.** "Status: **settled**" means the evidence supports it now and
changing it needs a new entry. "Status: **provisional**" means it rests on an assumption
recorded in the entry, and must be re-checked when the named gap closes.

**Source classes used below**

- **REPO** — read directly from a repository in this workspace, with commit cited.
- **STD** — a published standard or platform guideline, cited by name and clause. These
  are cited from established knowledge; the clause numbers should be re-verified against
  the current published text before any accessibility conformance claim is made
  externally.
- **LAW** — Philippine statute, cited by number.

Repository evidence used throughout:
`Taytay_Rizal_LGUIDS_Backend@fa77cef` · `Taytay_Rizal_Social_Welfare_Angular@c470960` ·
`Upupapp/Esperanza-Mobile@045cb3f` · `Upupapp/ServanaClientAPP@ce02830`.

---

## D-01 — A guest lands on Home, not on sign-in

**Status: settled.** Category: product / privacy.

**Options**

1. Sign-in first, as Esperanza does (`main.dart` `_AuthGate` → `LoginScreen`).
2. Onboarding first, then sign-in.
3. **Home first as a guest; sign-in only when a feature needs it.**

**Chosen: 3.**

**Why.** The backend already decided this. `GET /api/v1/services` is unauthenticated with
the reason written into the route file: *"citizens must be able to browse it before
registering."* A client that puts a credential prompt in front of public information
contradicts its own server. It also collects personal data with no purpose behind it,
which is a data-minimisation failure before a single field is submitted, and it excludes
residents who cannot or will not register from information the LGU publishes for
everyone.

**Sources.** REPO `modules/ServiceCatalog/Routes/api_v1.php`; LAW RA 10173 (proportionality
and legitimate purpose); REPO Esperanza `main.dart` (the rejected option).

---

## D-02 — One-time code on a mobile number, not email and password

**Status: provisional** — blocked on gap G-2 (`Identity` module not built). The domain
contract is written; the wire format is not.

**Options**

1. Email + password, as Esperanza does.
2. **One-time code sent to a mobile number.**
3. National ID (PhilSys) federated sign-in.

**Chosen: 2**, with 3 recorded as the likely long-term direction once PhilSys assisted
access exists (`NATIONAL_ID_ASSISTANCE`, currently draft).

**Why.** A resident-chosen password is the credential most often reused across services,
and an LGU is poorly placed to run a safe recovery process for one — password reset by
walk-in at a municipal hall is both a queue and a social-engineering surface. A mobile
number is the contact channel the LGU already needs for service notifications, so it
introduces no additional data. Esperanza's own registration collects a mobile number
anyway.

**Constraint carried into implementation.** The response to "send me a code" must not
reveal whether the number is registered. That answer would let anyone test whether a
given person is a Taytay resident. Registration and sign-in must be indistinguishable
from outside — recorded in `AuthRepository`'s contract.

**Sources.** REPO Esperanza `screens/auth/register_screen.dart` (mobile collected);
REPO backend `docs/architecture/domain-boundary-map.md` (`Identity` planned).

---

## D-03 — Credentials in the platform keystore; in-memory until then

**Status: settled.** Category: privacy / authorization.

**Options**

1. `SharedPreferences`, as Esperanza does (`esperanza_citizen_session`).
2. Encrypted file in app storage.
3. **Android Keystore / iOS Keychain, with an in-memory store until that lands.**

**Chosen: 3.**

**Why.** `SharedPreferences` is unencrypted XML. It is readable via ADB backup or on a
rooted device, and is swept into cloud auto-backup by default — an access token for a
government identity service would leave the device without the resident doing anything.
Option 2 needs a key, and the only safe place for that key is the keystore, so it
collapses into option 3 with extra moving parts.

Shipping `InMemorySessionStore` first is a deliberate choice, not an omission: a session
that dies with the process is the safe failure mode. The worst outcome is that a resident
signs in again; the alternative is a credential surviving on a shared device.

**Sources.** REPO Esperanza `services/citizen_session_service.dart`; `CLAUDE.md`
Article 5.3.

---

## D-04 — Access requirements live on the route, not in a widget

**Status: settled.** Category: authorization.

**Options**

1. `AccessGuard` widget wrapping each protected screen (Esperanza).
2. Each screen checks the session in `build`.
3. **Every route declares an `AccessRequirement`; one pure guard runs on every
   navigation.**

**Chosen: 3.**

**Why.** A requirement attached to a widget is only enforced on paths that render that
widget. Deep links arrive from SMS, email and printed QR codes and can target a protected
route directly at cold start, when no shell has been built. Option 2 is worse again: it
distributes the rule to every screen, and the screen that forgets is invisible until
someone finds it.

**What this is not.** It is not access control. The server authorises every protected
operation from the authenticated actor; if this guard were deleted the app would be less
pleasant and exactly as secure. It exists so a resident lands somewhere useful instead of
on a screen that will fail its first request.

**Sources.** REPO Esperanza `widgets/access_guard.dart`; REPO backend ADR 0002
§4–§6; `CLAUDE.md` Article 4.

---

## D-05 — Locked features are shown with their requirement, not hidden

**Status: settled.** Category: product.

**Options**

1. Hide anything the current level cannot use.
2. Show it, explain on tap (Esperanza).
3. **Show it, label the requirement before the tap, explain on tap.**

**Chosen: 3.**

**Why.** Hiding tells a resident nothing and makes the path to full access invisible —
they cannot want what they cannot see. It also discloses nothing to hide it, since the
catalogue is public and the server authorises regardless. Labelling before the tap saves
a navigation that could only end in refusal.

**Boundary.** This applies to *service availability*, which is public. It does not extend
to anything whose existence is itself personal data; there the backend returns `404`
rather than `403` ("existence is a privilege") and the app must not try to distinguish
the two.

**Sources.** REPO Esperanza `widgets/restricted_feature_notice.dart`; REPO backend
`docs/api/conventions.md` §4.

---

## D-06 — Verification tier is read from the server and fails closed

**Status: provisional** — blocked on gap G-6 (no `verification_tier` field observed in any
response yet; the field name must be confirmed).

**Options**

1. Derive from a locally-stored account status, as Esperanza does
   (`AppStatusX.fromLabel(acc.status) == approved`).
2. Compare against a list of known-verified tiers, defaulting unknown to verified.
3. **Read the server's tier; treat every unrecognised value as `unverified`.**

**Chosen: 3.**

**Why.** Option 2 fails open: a server that adds a tier — or a typo in a response — would
promote residents. Option 1 is safe in Esperanza only because the status string is also
local; once the tier arrives over the wire, the parse is a trust boundary. Failing closed
costs a verified resident one screen of friction; failing open hands out a credential
surface.

**Sources.** REPO Esperanza `models/access_level.dart`; `CLAUDE.md` Article 3.6.

---

## D-07 — The service catalogue is fetched, filtered by channel, never hard-coded

**Status: settled.** Category: lifecycle / schema.

**Options**

1. Hard-code the six categories and their services in the app.
2. Fetch the catalogue but show everything returned.
3. **Fetch with `?channel=citizen-mobile` and render only what returns.**

**Chosen: 3.**

**Why.** Publication is an LGU decision made in the staff console and modelled as an
explicit lifecycle (`draft` → `published` → `retired`). A hard-coded list means a service
the LGU retired stays on residents' phones until the next app release, and a service it
published is invisible until then — the app becomes the slowest part of a municipal
process. `available_channels` is part of the resource precisely because a published
service need not be offered on every channel: `BUSINESS_PERMIT` is web and admin only,
and `NATIONAL_ID_ASSISTANCE` is draft and admin only.

**Consequence accepted.** The `national` category has no resident-visible entry today, so
a `national` destination would be empty. It is designed for, not shipped.

**A distinction the implementation must keep.** `?channel=citizen-mobile` (a query filter
the caller chooses) and `X-Client-Channel: citizen-mobile` (a telemetry header) are
different things that happen to share a value. The backend says so explicitly:
*"An explicit `?channel=` filter is a presentation filter chosen by the caller. It is
unrelated to the `X-Client-Channel` header and confers no authority."* Sending the header
does not filter the catalogue; sending the filter does not widen access. Conflating them
would produce an app that appears to work while relying on a header for filtering the
server never applies.

**Sources.** REPO `modules/ServiceCatalog/Domain/PublicationStatus.php`,
`config/service_catalog.php`, `Http/Resources/LguServiceResource.php`,
`Application/ListServicesCriteria.php`.

---

## D-08 — Gate on the harm of getting it wrong, not on a uniform tier

**Status: settled** as a principle; individual rows in the matrix may change.

**Options**

1. Everything beyond browsing requires verification.
2. Everything beyond browsing requires only an account.
3. **Per-feature, decided by which error is worse: a wrongly-allowed action or a
   wrongly-blocked resident.**

**Chosen: 3.**

**Why.** Esperanza reached this independently and recorded it: emergency reporting is
available to unverified citizens because *"withholding emergency/incident reporting
behind LGU verification would be poor public-safety practice."* The same reasoning gives
Taytay two rows: PESO employment services are authenticated-only, because an unemployed
resident stuck in a verification queue may miss a referral entirely; and the resident ID
application is authenticated-only, because requiring verification to apply for the
credential that confers verification is a closed loop.

**Constraint.** This is a presentation decision. The server's authorisation is the real
answer, and where it is stricter, it wins.

**Sources.** REPO Esperanza `screens/home/root_shell.dart`; REPO backend ADR 0002 §1.

---

## D-09 — The server's error `message` is never shown to a resident

**Status: settled.** Category: privacy.

**Options**

1. Render `error.message` — it is short and already written.
2. Render it only in non-production builds.
3. **Derive resident copy from the failure kind; keep the server text for logs and
   support only.**

**Chosen: 3**, with 2 as the non-production presentation of the *debug* string
specifically.

**Why.** The backend's own convention defines `message` as *operator-facing*. It is not
translated, it may name an internal state, and it is explicitly allowed to change without
a version bump — so a client that renders it has an untranslated, unversioned string in
front of residents. The one exception is validation `details`, shown next to the field it
belongs to, because there it is actionable.

Every failure also carries `request_id`, which is opaque and safe to display, so a
resident can quote a reference to the support desk without disclosing anything personal.

**Sources.** REPO backend `docs/api/conventions.md` §4; `CLAUDE.md` Article 5.5.

---

## D-10 — No runtime-downloaded fonts

**Status: settled.** Category: privacy / performance.

**Options**

1. `google_fonts` fetching at runtime, as the earlier `lgu_ids_taytay` app does.
2. Bundle a licensed font file.
3. **Use the platform font.**

**Chosen: 3**, with 2 available later as a deliberate, licensed choice.

**Why.** A runtime fetch is a third-party CDN call on first launch — an avoidable
disclosure of a resident's IP and app usage to a party the LGU has no agreement with —
and it renders unstyled text on exactly the weak connections many residents have.
Servana bundles two families (`Poppins`, `Plus Jakarta Sans`); one government app does
not need two.

**Sources.** REPO `lgu_ids_taytay/lib/core/theme/app_theme.dart` (the rejected option);
REPO Servana `lib/common/constants/font_palette.dart`; `CLAUDE.md` Article 6.

---

## D-11 — Reduced motion is resolved per build, and functional motion shortens rather than stops

**Status: settled.** Category: accessibility.

**Options**

1. Ignore the platform signal.
2. Latch a motion mode once at cold start, as Servana's `WelcomeMotionMode.resolve` does.
3. **Resolve per build from `MediaQuery`; functional motion shortens, decorative motion
   disappears.**

**Chosen: 3**, adopting Servana's idea of a named richness ladder but not its latching.

**Why.** Latching at cold start means a resident who turns on "Remove animations" mid-session
keeps the full treatment until they restart the app. Distinguishing functional from
decorative matters too: a page transition still has to say where the new screen came
from, so it shortens; a parallax hero communicates nothing and is removed.

Servana's ladder has four rungs but its resolver only ever returns `full` or `staticMode`
— the middle rungs are aspirational. Taytay will not add rungs nothing selects.

**Sources.** STD WCAG 2.2 SC 2.3.3 *Animation from Interactions* (AAA — exceeded
deliberately: vestibular symptoms are not a AAA-priority problem for the people who have
them); REPO Servana `modules/landing/domain/welcome_motion_mode.dart`.

---

## D-12 — 48 dp minimum touch target, not 44

**Status: settled.** Category: accessibility.

**Options**

1. 24×24, the WCAG 2.2 AA floor.
2. 44 dp, as Servana uses, citing Apple's guidance.
3. **48 dp.**

**Chosen: 3.**

**Why.** 48 satisfies Material's guidance and Apple's 44 pt simultaneously, and clears
the WCAG floor with margin. A single higher number removes a per-platform judgement call.
The cost is denser lists needing more vertical space, which is the right trade for an app
used by elderly residents and by people filling forms one-handed in a queue.

**Sources.** STD WCAG 2.2 SC 2.5.8 *Target Size (Minimum)*, AA, 24×24 CSS px; STD
Material 3 accessibility guidance (48×48 dp); STD Apple HIG (44×44 pt); REPO Servana
`lib/core/accessibility/accessibility_tokens.dart`.

---

## D-13 — Sensitive sector and means-test data never reach this app

**Status: settled.** Category: privacy / authorization.

**Options**

1. Fetch the full resident record and render a resident-safe subset.
2. Fetch the full record, render a subset, and rely on the UI not to show the rest.
3. **The server does not send it. The app has no field for it.**

**Chosen: 3.**

**Why.** Options 1 and 2 put sensitive data on the device, where it reaches crash reports,
logs, screenshots and backups regardless of what is rendered. The staff console's
`domain/residents/resident.ts` names the specific fields: `SENSITIVE_SECTORS =
['vawc-survivor', 'cicl']`, `monthlyIncome`, `Household.isIndigent`, `philsysLastFour`,
`audit`, `householdId`/`members`.

VAWC-survivor and child-in-conflict-with-the-law status carry statutory confidentiality
beyond the general data-privacy duty. Household links are other people's data appearing
in one resident's app. An indigency classification is a casework conversation, not a
field.

**Sources.** REPO `Taytay_Rizal_Social_Welfare_Angular/src/app/domain/residents/resident.ts`;
LAW RA 10173 §3(l) (definition of sensitive personal information) and §13 (restrictions on
processing it); LAW RA 9262 (VAWC — confidentiality of victim identity); LAW RA 9344
(juvenile justice — confidentiality of records of children in conflict with the law).

---

## D-14 — Identity verification is decided server-side; the app captures only

**Status: provisional** — blocked on gap G-3 (`ResidentProfile` not built).

**Options**

1. On-device liveness/match, sending a pass/fail, as Esperanza simulates with a local
   `_faceScanCompleted` boolean.
2. On-device template extraction, sending the template.
3. **Capture and upload; the server decides and stores the verdict.**

**Chosen: 3.**

**Why.** Option 1 lets a modified client assert its own verification — the client is
installed on a device the LGU does not control, can be decompiled and proxied, and a
released build cannot be patched quickly. Option 2 puts a biometric template on the
device and on the wire, and a template is not revocable the way a password is. Biometric
data is sensitive personal information under RA 10173.

**Sources.** REPO Esperanza `screens/auth/register_screen.dart` (`_faceScanStep`, the
rejected option); REPO backend ADR 0002 (context: a released mobile build cannot be
trusted); LAW RA 10173 §3(l); `CLAUDE.md` Article 5.8.

---

## D-17 — Bearer tokens, server-side revocation, and refresh (upstream watch item)

**Status: provisional** — depends on backend work that is **accepted but not yet
committed**. Re-check before implementing.

The backend working tree carries an uncommitted, `Status: Accepted` ADR dated
2026-08-14: **ADR 0005 — First-party bearer tokens, not Sanctum cookie SPA auth.** It is
not in commit `fa77cef`, so it is not yet contract; it is recorded here because it lands
squarely on this app's authentication seam and would otherwise be discovered late.

**What it says that affects this app**

- All four clients — including `citizen-mobile` — authenticate with **first-party Sanctum
  bearer tokens over HTTPS**; cookie/SPA mode is not enabled. This confirms the
  `Authorization: Bearer <token>` design already implemented in TAB 01, and confirms that
  no cookie or CSRF handling belongs in this client.
- **Short token lifetimes with refresh.** The app has no refresh path today. `ApiClient`
  currently treats every `401` as session-ended; with refresh, a `401` must first attempt
  exactly one refresh and only then end the session — and concurrent requests must not
  each trigger their own refresh.
- **"Logout must revoke server-side. Discarding a token client-side is not revocation."**
  This validates the existing `AuthRepository.signOut()` contract, which calls the server
  before clearing locally. It also sharpens the rule: local sign-out must still succeed
  when the network call fails (a resident on a borrowed phone must always be able to sign
  out), but that case leaves a live token on the server and must be treated as an
  incomplete sign-out, not a clean one.
- The ADR notes XSS as the primary token-theft risk **for browser clients**. That
  particular risk does not transfer to this app, which has no injected-script surface;
  the mobile equivalent is device compromise and backup extraction, which is what D-03
  addresses.

**Action.** No implementation now. When the ADR is committed, revisit D-02 and D-03 and
add refresh handling to `ApiClient` as a single-flight operation.

**Sources.** REPO (uncommitted working tree)
`Taytay_Rizal_LGUIDS_Backend/docs/adr/0005-cross-origin-authentication.md`.

---

## D-15 — Idempotency keys on every retryable state change

**Status: settled** as a rule; nothing implements it yet.

**Why.** The backend accepts `Idempotency-Key` on state-changing endpoints a mobile client
may retry, and replaying a key returns the original result. Mobile connections drop
mid-request routinely; without a key, a resident who retries a document application
submits it twice, and a duplicate application is a real cost to both the resident and the
office that processes it.

**Sources.** REPO `docs/api/conventions.md` §7.

---

## D-16 — No client-side schema is invented ahead of the backend

**Status: settled.** Category: schema.

**Options**

1. Write the request/response models the app expects and let the backend match them.
2. Generate from an OpenAPI document.
3. **Express the app's needs as a Flutter-free domain contract; map to the wire only when
   the endpoint exists.**

**Chosen: 3.** Option 2 is unavailable — gap G-1, there is no OpenAPI document in the
backend repository; the contract is prose in `docs/api/conventions.md` plus the route
files, resources and domain enums.

**Why.** Option 1 creates a contract the server never agreed to, and it is discovered
wrong only after both sides are written. `AuthRepository` therefore states what the app
needs in domain terms and `PendingBackendAuthRepository` declines with a temporary
failure, which is the truth: the service does not exist yet. A mock that handed out a
session would become the thing people demo.

**Recorded as a request to the backend:** publish an OpenAPI document, or accept that
clients are hand-written against prose. This is a backend conversation, not a client
workaround.

**Sources.** REPO backend `docs/api/conventions.md`; `CLAUDE.md` Articles 1 and 3.7.

---

## Index

| ID | Decision | Category | Status |
| --- | --- | --- | --- |
| D-01 | Guest lands on Home, not sign-in | product / privacy | settled |
| D-02 | One-time code on mobile number | product / authorization | provisional (G-2) |
| D-03 | Keystore credentials; in-memory until then | privacy | settled |
| D-04 | Access requirements on routes, one guard | authorization | settled |
| D-05 | Locked features shown with their requirement | product | settled |
| D-06 | Server-supplied verification tier, failing closed | authorization | provisional (G-6) |
| D-07 | Catalogue fetched and channel-filtered | lifecycle / schema | settled |
| D-08 | Gate on harm, not a uniform tier | product / authorization | settled |
| D-09 | Server `message` never shown to residents | privacy | settled |
| D-10 | No runtime-downloaded fonts | privacy / performance | settled |
| D-11 | Reduced motion resolved per build | accessibility | settled |
| D-12 | 48 dp minimum touch target | accessibility | settled |
| D-13 | Sensitive and means-test data never reach the app | privacy | settled |
| D-14 | Verification decided server-side | privacy / authorization | provisional (G-3) |
| D-15 | Idempotency keys on retryable writes | lifecycle | settled (unimplemented) |
| D-16 | No invented client-side schema | schema | settled |
| D-17 | Bearer tokens, server-side revocation, refresh | authorization | provisional (upstream ADR 0005 uncommitted) |

**17 decisions — 13 settled, 4 provisional pending named backend gaps.**
