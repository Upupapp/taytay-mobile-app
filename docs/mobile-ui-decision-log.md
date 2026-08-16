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

## D-18 — The municipal seal is not shipped until a verified asset exists

**Status: settled.** Category: brand / licensing / privacy-of-trust.

**Options**

1. Use `lgu_ids_taytay/assets/logos/taytay_logo.png`, the seal already present in
   the workspace.
2. Recreate the seal as vector artwork from that raster.
3. **Ship no seal. Render a plainly non-official wordmark, and gate the real asset
   behind a checksum-verified registry.**

**Chosen: 3.**

**Why.** Option 1 was inspected byte-by-byte and fails: the file is **JPEG**
(`FF D8 FF E0 … JFIF`) despite its `.png` extension, so it is lossily
re-encoded; it has **no alpha channel** and is flattened onto opaque black, so it
renders as a black square on any surface; and its provenance is a prototype app,
not the LGU. A lossily-recompressed seal on a black box is an altered seal.

Option 2 is worse. Redrawing a government symbol produces something that looks
official and is not, and the resident looking at it has no way to tell — the seal
is exactly the element they would use to decide whether to trust the screen.

Shipping nothing costs a little polish. Shipping a degraded or invented seal
costs the ability to ever answer "is this the official mark?".

**What enforces it.** `BrandAssets` is empty; `BrandMark` has no `color`, `fit`,
`shape` or `transform` parameter, so it cannot express a violation of
`SealIntegrityRules`; and `brand_test.dart` checks format by magic bytes (not
extension), alpha presence, SHA-256 against the approved bytes, and the presence
of a licence reference. One test asserts no seal is registered, so adding one
forces a deliberate edit.

**Sources.** Byte inspection of
`Desktop/lgu_ids_taytay/assets/logos/taytay_logo.png` (sha256
`a1c116dd…e614`, 322,361 bytes, JFIF header).

---

## D-19 — No Pantone, CMYK or ink specification is asserted

**Status: settled.** Category: brand.

**Options**

1. Publish Pantone/CMYK values alongside the hex tokens, as brand docs usually do.
2. Sample values from the seal artwork and present them as the official palette.
3. **State hex tokens as application interface colours, and assert no official
   specification.**

**Chosen: 3.**

**Why.** No LGU brand manual has been supplied. Option 1 would invent a standard;
option 2 would derive one from a JPEG that is already colour-shifted by lossy
compression, then present the artifact as authoritative. Either way a later reader
finds numbers in a government repository and reasonably treats them as official.

The earlier wording "Official deep blue" in `design_tokens.dart` was corrected as
part of this decision — it made exactly the claim this entry forbids.

**Enforced by** a test that scans `lib/` for `pantone`, `pms <digits>` and `cmyk`
with comments stripped, so the disclaimer explaining the rule does not trip it.

---

## D-20 — Reduced motion has two independent switches, OR-ed

**Status: settled.** Category: accessibility.

**Options**

1. Follow the OS setting only.
2. Offer an in-app setting that can also *enable* motion the OS suppressed.
3. **OS setting as a floor, plus an in-app preference that can only reduce.**

**Chosen: 3.**

**Why.** Option 1 forces an all-or-nothing choice on the resident: Android's
"Remove animations" is system-wide, and someone who wants the calmer government
app should not have to flatten every other app to get it. Option 2 is unsafe — it
would let an in-app default override an accessibility setting the person
deliberately turned on, which is the one direction that must never be possible.

`Motion.reduced` is therefore an OR, and `MotionPreference` has no value meaning
"more motion than the system asked for".

**Scope.** The same switch suppresses haptics, centrally rather than per call
site.

---

## D-21 — Gradients declare their foreground and are proved across the ramp

**Status: settled.** Category: accessibility.

**Options**

1. Check contrast against the gradient's darkest stop.
2. Check both endpoints.
3. **Bind the foreground to the gradient and sample interpolated midpoints.**

**Chosen: 3.**

**Why.** Text on a gradient reaches worst contrast wherever the background is
closest in luminance to the text, and on a multi-stop ramp that point can lie
between two stops that both pass. A black → white → black gradient passes at both
endpoints and fails badly in the middle; `brand_test.dart` includes exactly that
case to prove the sampler is not decorative.

Binding `onColor` to the gradient means the colour that was proved is the colour
`BrandGradientSurface` actually supplies to its subtree.

---

## D-22 — Illustrations are painted in Flutter, not shipped as image files

**Status: settled.** Category: product / performance / licensing.

**Options**

1. Commission or generate raster illustrations and ship them with 1x/2x/3x
   variants.
2. Ship SVG files and add `flutter_svg`.
3. **Paint them with `CustomPainter`.**

**Chosen: 3**, with the file pipeline built and tested for the day a file is
genuinely warranted.

**Why.** For flat geometric artwork, painting wins on every axis that matters
here: zero install bytes, no density variants to keep in sync, colours taken from
the live `ColorScheme` so dark mode is correct without a second set of artwork,
any size and aspect ratio without resampling, and no licence surface at all.
Option 2 also adds a dependency and still needs one file per scene.

Install bytes are paid for by residents, frequently on prepaid data metered by
the megabyte. An asset that could have been 0 KB and is instead 3 × 120 KB is not
a quality decision; it is a decision to spend somebody else's money.

**Where a file still wins:** a photographic or hand-painted texture that cannot
be expressed as geometry. Nothing in the app qualifies today, which is why
`assets/` ships no artwork — but the manifest, budgets, density rules and
validators exist so that such a file is checked rather than merely dropped in.

---

## D-23 — Every drawn scene is announced as an illustration

**Status: settled.** Category: accessibility / honesty.

**Options**

1. Describe the scene's content plainly ("a municipal building").
2. Leave illustrations unlabelled.
3. **Prefix every accessible name with `Illustration:`, and forbid photographic
   claims.**

**Chosen: 3.**

**Why.** A sighted resident can see instantly that a scene is drawn. A resident
using a screen reader cannot, and option 1 leaves them to infer that "a municipal
building" is a photograph of the actual Taytay municipal hall. That is a factual
claim the app cannot support, made to precisely the people least able to check
it. Option 2 is worse: it removes the content entirely for those users.

Purely decorative scenery is the exception and is wrapped in `ExcludeSemantics` —
naming a backdrop makes a screen reader read out landscape before the content.

**Enforced by** an assertion inside `Illustration`, the manifest validator for
file assets, and a test that walks every scene in the app checking both the prefix
and a forbidden-claims list (`photo`, `photograph`, `picture of`, `actual`, `real
footage`).

---

## D-24 — Exactly one animated illustration, and it must carry meaning

**Status: settled.** Category: accessibility / performance.

**Options**

1. Animate onboarding scenes and empty states for liveliness.
2. Ship a Lottie/Rive runtime for richer motion.
3. **Animate only where the motion itself carries information.**

**Chosen: 3.** The sole animation is the success tick, drawn once over 420 ms at
the moment a submission is confirmed.

**Why.** Motion that marks a state transition tells a resident something; a
looping decorative animation tells them nothing and costs battery, CPU and — for
residents with vestibular conditions — comfort. Option 2 adds a runtime whose
native libraries have previously blocked store uploads (recorded in the TAB 02
Servana audit), for artwork this app does not need.

**Constraints, all tested:** never loops; never replays on rebuild; draws
instantly with no travel under reduced motion via *either* switch; every other
scene declares `willChange: false`; every scene sits in a `RepaintBoundary`.

Depth uses two stacked translucent shapes rather than a `MaskFilter` blur, which
is expensive on the low-end hardware much of this audience carries.

---

## D-25 — An undeclared file in `assets/` fails the build

**Status: settled.** Category: licensing / supply chain.

**Options**

1. Declare assets in `pubspec.yaml` only, as Flutter requires.
2. Keep a manifest, but let undeclared files pass.
3. **Keep a manifest and fail when a file exists that is not declared in it.**

**Chosen: 3.**

**Why.** `pubspec.yaml` records only that a directory ships. It cannot record
where a file came from, whether the project may use it, what it may weigh, or
whether its bytes are still the bytes someone approved. An undeclared file in a
government repository is artwork with no licence basis and no review trail, and
the usual way one appears is that somebody dropped it in to try something and it
was never removed.

Making the manifest authoritative — hash, licence, provenance, budget, accessible
name — turns "where did this come from?" from an unanswerable question into a
failing test.

---

## D-26 — Preserved intents are a closed enum holding no personal data

**Status: settled.** Category: privacy / authorization.

**Options**

1. Store a callback or a closure to re-run after the gate.
2. Store the action plus its payload — the draft comment, the form contents.
3. **Store a closed-set enum plus at most one validated opaque identifier.**

**Chosen: 3.**

**Why.** An intent outlives the screen that created it and can be created by a
guest, so anything held may outlive the account it belonged to. Option 1 stores
arbitrary behaviour and replays it later against whatever session exists at that
moment — the worst version of this is a closure that captures a repository and
fires after a *different* resident signs in. Option 2 puts the resident's own
words into a global holding area keyed to nobody.

The trade accepted: a half-typed comment is lost when a gate interrupts it. That
is a small cost, and losing it is much better than leaking it.

`targetId` is validated against `^[A-Za-z0-9_-]{1,64}$`, so a sentence, a URL or
a phone number fails an assertion rather than being stored.

**Bounds:** one intent at a time, 10-minute TTL, in memory only, cleared on any
session change.

---

## D-27 — Resuming an intent is a navigation, never an action

**Status: settled.** Category: product / authorization.

**Options**

1. Perform the action automatically once the gate is passed.
2. **Navigate to the screen where the resident can do it.**

**Chosen: 2.**

**Why.** Option 1 means an app completing something on a resident's behalf
minutes later, on the far side of a sign-in flow they may have entered for a
different reason. If it were a service application, it would file a request
against their civil record without a fresh confirmation.

`takeIfSatisfied` also asks `AccessPolicy` — the same evaluation the router uses
— so an intent cannot resume early. Passing a gate does not authorise the
action: the server decides on the request that follows (ADR 0002).

---

## D-28 — First-launch state lives in the keystore, not in plain preferences

**Status: settled.** Category: architecture / privacy.

**Options**

1. Add `shared_preferences` for the "welcome seen" boolean.
2. Write a small unencrypted file.
3. **Store it through the existing `SecretStore`, under its own key namespace.**

**Chosen: 3.**

**Why.** The flag is not sensitive, but options 1 and 2 each add a *second*
persistence mechanism to hold one boolean. That means a new dependency —
`shared_preferences` is banned by CLAUDE.md Article 5.3 and by a test — a second
thing to clear correctly, and a second place a future contributor might put
something that *is* sensitive, next to a precedent saying this store is for
unimportant things. Encrypting a boolean costs nothing measurable.

It is deliberately **not** cleared on sign-out: the flag belongs to the install,
not the account. A read failure degrades to "show the welcome", because showing
it twice is an annoyance while skipping it for a real first-time resident means
they never learn what the app will ask for.

---

## D-29 — Skipping the welcome counts as completing it

**Status: settled.** Category: product.

**Options**

1. Only a full read-through sets the flag; a skip shows the scenes again.
2. **Skip and finish both set the flag.**

**Chosen: 2.**

**Why.** Re-asking overrides a decision the resident already made, and doing it
every launch is precisely what makes onboarding feel like a trap. A resident who
skipped has told the app something; ignoring it to raise the completion rate is
optimising the metric against the person.

Together with a skip control on every scene, an equal-weight "Continue as guest"
action, and a public, escapable route, this is what keeps the welcome a starting
point rather than a funnel.

---

## D-30 — Registration is verification, not account creation

**Status: settled.** Category: schema / product.

**Options**

1. `POST /api/v1/register` carrying name, birth date and address.
2. Create the account with `PATCH /me/profile` after signing in.
3. **OTP creates the account; identity details travel as a verification
   submission.**

**Chosen: 3**, because the committed contract leaves no alternative.

**Why.** `Taytay_Rizal_LGUIDS_Backend@896cec9` publishes a full citizen endpoint
matrix and it contains **no account-creation row**. It also states that
`PATCH /api/v1/me/profile` is *contact fields only* and that a citizen *may not
edit their own eligibility-bearing fields*. Option 1 would be an invented
endpoint; option 2 would push demographics through a route the contract
explicitly narrows.

So `RegistrationRepository` has no `createAccount`, and the wizard's shape —
contact, code, details, address, consent, review, submit — follows the contract
rather than a form design.

**Sources.** REPO backend `docs/contracts/frontend-endpoint-matrix.md` §2 and §12.

---

## D-31 — The wizard collects less than the staff console holds

**Status: settled.** Category: privacy.

**Options**

1. Mirror the staff `Resident` model so the record is complete on arrival.
2. Collect the common subset a clerk usually needs.
3. **Collect only what matches a person to an existing resident record.**

**Chosen: 3** — name, birth date, barangay, street, mobile number.

**Why.** `sex`, `civilStatus`, `sectors`, `monthlyIncome`, `philsysLastFour` and
`householdId` do not narrow a name-and-birth-date match. Several are sensitive
personal information under RA 10173 §13 — `sectors` includes VAWC-survivor and
child-in-conflict-with-the-law status — and this client has no endpoint that
accepts any of them. Collecting data with no purpose and no destination is the
clearest possible failure of minimisation.

A test asserts the absent fields stay absent.

---

## D-32 — Optional identity steps are server-gated and deny by default

**Status: settled.** Category: privacy / authorization.

**Options**

1. Always collect an ID and a selfie — the LGU will want them.
2. A build-time flag.
3. **A server capability, defaulting to denied, plus explicit consent for
   biometrics.**

**Chosen: 3.**

**Why.** Whether a resident needs a document is a *matching* decision only the
server can make — someone already in the register may need nothing. And a client
that decides on its own to capture a face photo is collecting the most sensitive
artifact in the system without the LGU asking; backend gap **G-18** records that
there is not even an agreed upload mechanism yet.

`RegistrationCapabilities` therefore starts all-false and only
`GET /api/v1/me/verification` may widen it. Since that row is `planned`, this
build shows neither step and opens no picker — the fail-closed outcome, and a
tested one.

The selfie step additionally requires biometric consent, which is the one
**optional** consent: consent that cannot be refused is not consent.

---

## D-33 — Duplicate and match errors never enumerate

**Status: settled.** Category: privacy / security.

**Options**

1. "This mobile number is already registered — sign in instead."
2. "A resident with this name and birth date already exists."
3. **The same answer whether or not a record exists.**

**Chosen: 3.**

**Why.** Options 1 and 2 turn a public registration form into an oracle: anyone
could test numbers, or names and birth dates, and learn who is a Taytay resident.
That is a disclosure about a third party made to a stranger, and it is exactly
what the committed contract forbids on the OTP row — *"must not reveal whether
the number is registered"*. A client that renders a `409` distinguishably undoes
a server-side protection.

A conflict on the contact step therefore reads "If this mobile number can be
used, we have sent a code to it", and a conflict later reads "please visit the
municipal hall" — helpful, and silent about what exists.

**Cost accepted:** a resident who genuinely already has an account gets a
slightly vaguer message. Being sent to the code screen still works for them.

---

## D-34 — Two verification vocabularies, mapped one way, degrading downward

**Status: settled.** Category: schema / authorization.

**Options**

1. Render the server's state string directly.
2. Map server states to resident copy, treating anything unknown as a failure.
3. **Map server states to a resident stage, degrading anything unknown to the
   stage that always has a safe next step.**

**Chosen: 3.**

**Why.** The backend "owns a canonical `VerificationState` enumeration"
exposed as `verification_tier` (gap **G-08**) and does not publish its values,
so a released app *will* meet states it has never seen. Option 1 shows a
resident `awaiting_barangay_endorsement` and leaves them to guess. Option 2
tells someone they failed when nobody said so.

Unknown therefore maps to `manualReview` — "needs a person to check", with the
municipal hall as the route. Never to `verified`, which would grant capabilities
the server never granted; never to `unsuccessful`, which would be a false
statement about a real person's application.

**Sources.** REPO backend `docs/contracts/frontend-backend-gap-list.md` G-08;
`docs/contracts/frontend-endpoint-matrix.md` §12.

---

## D-35 — The status decoder is an allow-list, not a deny-list

**Status: settled.** Category: privacy.

**Options**

1. Decode the whole payload and choose what to render.
2. Decode everything, then strip known-sensitive fields.
3. **Read only an enumerated set of keys; ignore everything else.**

**Chosen: 3.**

**Why.** The fields at stake are reviewer identity, risk and fraud scores,
caseworker notes, audit trails, matching candidates and rejection heuristics.
The committed client-visibility matrix says such fields "never appear in any
citizen or verifier response, in any endpoint, ever", and that a citizen
projection is built "by naming the fields to include, never by taking the staff
projection and removing some".

Option 2 is one forgotten key away from rendering a caseworker's note — and the
key that gets forgotten is the one added after the code review. An allow-list
cannot leak a field nobody wrote a line for.

`VerificationStatusDetail` additionally has no field any of it could occupy, so
the shape is the first control and the decoder is the second. A test decodes a
payload carrying all of the above, plus another resident's name, and asserts
none of it survives.

---

## D-36 — Verified unlocks through the session controller, not the screen

**Status: settled.** Category: authorization / product.

**Options**

1. The verification screen navigates to the credential on success.
2. The screen sets a local "verified" flag and shows the ID.
3. **Push the server's tier into `SessionController`, and let the router react.**

**Chosen: 3.**

**Why.** Options 1 and 2 create a second source of truth about what a resident
may do — exactly what `AccessPolicy` and the route guard exist to prevent — and
option 2 lets a screen grant itself access.

Routing the answer through `applyVerificationTier` means one place changes access
level, the router re-evaluates every gated route in the same frame, and the
guarantee holds for screens nobody has written yet. It also makes the reverse
work for free: a status that stops saying verified lowers the level again, so a
revoked verification takes the capability with it.

The app decides nothing — the tier is the server's, and
`AccessLevel.fromVerificationTier` fails closed on anything that is not exactly
`verified`.

---

## D-37 — No turnaround promises anywhere in verification copy

**Status: settled.** Category: copy / trust.

**Options**

1. "Usually reviewed within three working days."
2. Show an estimate supplied by the server.
3. **State what is happening and what the resident can do. No duration.**

**Chosen: 3**, with 2 available later if the LGU publishes a figure it stands
behind.

**Why.** The app has no basis for a number, a municipal review queue does not
honour one, and a missed promise from a government service costs more trust than
never having made it. The resident's real question — "is there anything I need to
do?" — is answered directly on every stage instead.

Enforced by a test that scans both the stage copy and the rendered screen for
`N days/weeks`, "within" and "guarantee".

---

## D-38 — No refresh, because the contract publishes none

**Status: settled.** Category: schema / lifecycle.

**Options**

1. Implement a refresh endpoint the app expects the server to provide.
2. Keep a long-lived token so a session rarely ends.
3. **No refresh. Use the `expires_at` the contract already returns, and let a
   session end.**

**Chosen: 3.**

**Why.** ADR 0005 names *"short token lifetimes with refresh"* as a required
mitigation, but the endpoint matrix publishes no refresh route — the citizen
rows are `POST /auth/otp`, `POST /auth/otp/verify`, `GET /me` and
`DELETE /auth/tokens/current`, and nothing else. Option 1 would invent a path,
request shape and response shape the server has never agreed to, and it would be
discovered wrong only once both sides were written. Option 2 trades the
resident's exposure for their convenience, in an app that holds a government
credential.

`AuthCoordinator` was built in TAB 05 with the mechanism present and the
refresher deliberately unregistered, so a `401` fails closed. TAB 09 left it that
way and added a source scan that fails the build if anyone writes an
`auth/refresh` path or a `refresh_token` field.

What the contract *does* return is `expires_at`, and using it is always safe in
one direction: the app can stop presenting a token it can already see is dead. It
can never extend a session or raise a level, and an unreadable timestamp reads as
"unknown", never as "expired".

**Sources.** REPO backend `docs/contracts/frontend-endpoint-matrix.md` §2;
ADR 0005.

---

## D-39 — Recovery is the LGU counter, not a form

**Status: settled.** Category: product / privacy.

**Options**

1. A "forgot password" flow.
2. An in-app account-recovery form — security questions, alternate email, a
   support ticket.
3. **Explain that there is no password, and route a lost number to the municipal
   hall.**

**Chosen: 3.**

**Why.** Option 1 cannot exist: the citizen contract has no password. Option 2 is
worse than nothing on two counts. Changing the mobile number on an account is an
identity decision, and an app cannot make it — so the form would end in a queue
nobody has staffed, having first collected personal data for a purpose it cannot
fulfil. And a recovery form is the softest place in a product to leak an account
oracle: the copy is helpful, the flow feels low-stakes, and "we couldn't find
that number" reads like kindness.

So the help screen has **no input field at all**. It cannot be used to test
whether a number belongs to a Taytay resident, because it collects nothing and
looks nothing up. Every answer on it is true regardless of who is reading it.

It also carries the one warning that prevents the most common real-world attack
on a code-based sign-in: Taytay LGU will never ask for your one-time code.

---

## D-40 — Biometrics unlock the app, never the account

**Status: settled.** Category: biometric / authorization.

**Options**

1. No biometrics at all.
2. Biometric unlock treated as re-authentication, extending or restoring a
   session.
3. **A local lock over an already-signed-in app, which grants nothing.**

**Chosen: 3.**

**Why.** Option 2 is the mistake worth naming. A local unlock proves possession
of a device, unlocked by whoever the device trusts. It is not a statement about
who a person is, and the server has neither seen it nor agreed to it. Treating it
as authentication would put an authority decision on the client — the exact
inversion ADR 0002 and Article 3 exist to prevent — and would let a phone's
owner's fingerprint stand in for a resident's identity.

So the lock hides pixels. The session behind it is exactly as authorised while
locked as while unlocked; the same token would be accepted either way.

Option 1 was rejected because the threat it addresses is ordinary and physical:
phones are shared, borrowed and left on counters, and a digital ID is exactly
what an onlooker would open.

The three rules that make it shippable are in the controller's own doc: it never
blocks a guest, there is always a way out that does not need the sensor, and it
cannot be switched on without being passed once. The way out is the important
one — a lock a resident cannot pass and cannot leave is a bricked government
service.

**Dependency.** `local_auth`, reviewed before adding: Flutter-team maintained,
`USE_BIOMETRIC` only, and no data egress — the platform returns a boolean and no
template ever reaches this app.

---

## D-41 — One message for every refusal that could identify an account

**Status: settled.** Category: privacy / security.

**Options**

1. Specific errors: "no account with that number", "incorrect code",
   "account locked".
2. Specific errors for some, generic for the sensitive ones.
3. **One message for every refusal that could distinguish a known number from an
   unknown one.**

**Chosen: 3.**

**Why.** Option 2 is the trap: the moment one refusal is distinguishable, the
*absence* of it is informative, and the oracle is rebuilt from the difference.

`SignInMessage` therefore has no value that names an account state. The mapping
collapses `NOT_FOUND`, `FORBIDDEN`, `VALIDATION_FAILED`, `CONFLICT` and
`UNAUTHENTICATED` into one — precisely the codes a server might use to tell those
cases apart. Rate limiting is the single exception, and it is safe because it says
"not now" regardless of whether the number exists.

The success message is conditional for the same reason: "we sent you a code"
confirms registration; "if that number is registered" does not.

The backend already requires this of itself. The client keeps the same promise so
that a future server change cannot leak through a client that had been assuming
otherwise.

**Sources.** REPO backend `docs/contracts/frontend-endpoint-matrix.md` §2
("must not reveal whether the number is registered").

---

## D-42 — Five destinations, identical at every access level

**Status: settled.** Category: navigation / product.

**Options**

1. Show only what the current level can use — four tabs for a guest, six for a
   verified resident.
2. Five fixed tabs, with locked ones visibly disabled.
3. **Five fixed tabs, all public, with gating inside the content.**

**Chosen: 3.**

**Why.** Option 1 makes the app unlearnable. Municipal software is used rarely
and under pressure, and navigation that rearranges itself between visits has to
be relearned every visit — by exactly the people with the least practice. It also
changes shape at the moment a person's status changes, which is a status
disclosure visible to anyone glancing at their phone.

Option 2 keeps the shape but adds a control that cannot be pressed, which reads
as a fault rather than as a step.

Under option 3 every destination route is `public`, so no tab can bounce, and the
gate lives on the content — which is where the explanation belongs anyway. Profile
is public for the same reason: it must open for a guest, and for them it is the
explanation of what an account is for.

The property is testable once and holds forever: five, in this order, at every
level. "The right subset for each of three states" is nine assertions that drift.

---

## D-43 — Access and availability are separate questions

**Status: settled.** Category: authorization / product.

**Options**

1. One verdict: usable or not.
2. **Two axes — may this resident see it, and has the LGU switched it on —
   evaluated in that order, with navigation decided by access alone.**

**Chosen: 2**, and the ordering and the split were both bugs first.

**Why the order.** Availability first would answer "not available yet" to a guest
asking for a verified-only feature. That is a different answer than a verified
resident gets, which leaks that the feature exists and is gated; and it sends
away someone who should have been sent to sign in.

**Why navigation ignores availability.** Every screen in this app already handles
an absent backend by rendering an honest state that names what the LGU *does*
offer. Treating "planned" as a reason to refuse navigation replaced each screen's
specific explanation with a generic one, and hid working screens — the digital
ID, verification, the account — behind a flag describing something the resident
cannot see and did not cause. So availability decides what a screen *says*;
access decides whether it *opens*. The tile still reads "Not available yet", so
nobody taps in expecting data that is not there.

---

## D-44 — The household summary is withheld, not built

**Status: settled.** Category: privacy / schema.

**Options**

1. Build it against `GET /api/v1/households/{household_id}`.
2. Assume a `/me/household` route and build against that.
3. **Declare the capability, report it unavailable, ship no screen.**

**Chosen: 3.**

**Why.** The committed contract has exactly one household row, and it is a
**staff** route requiring `resident.view` under a role scope, with the
sensitivity note *"member list is other people's data — audited read"*. There is
no citizen equivalent.

Option 1 would mean this resident app asking for a permission it must never hold
— the precise boundary CLAUDE.md Article 0 exists to defend. Option 2 would mean
shipping a screen whose contract nobody has agreed, for the most sensitive
collection in the system, and a household member list is other people's personal
data before it is this resident's convenience.

Declaring the capability and reporting it unavailable is the honest state, keeps
the Master Command's requirement visible rather than silently dropped, and is one
line to flip when the backend publishes a citizen route.

**Sources.** REPO backend `docs/contracts/frontend-endpoint-matrix.md` §4 and §12.

---

## D-45 — A notification names a target, never a path, and never an action

**Status: settled.** Category: deep-link / security.

**Options**

1. The payload carries a path; the app opens it.
2. The payload carries a path, validated against the route table.
3. **The payload names a target from an allow-list, plus at most one bounded
   opaque identifier. Actions are refused by name.**

**Chosen: 3.**

**Why not a path.** A push payload is attacker-writable: anyone who can message a
resident can put a string in front of the resolver. Option 1 lets the sender
choose any screen, including ones added in later versions that were never meant
to be linkable. Option 2 is better but still couples the link format to the route
table, so adding a route silently adds a link target.

**Why the identifier is bounded to `[A-Za-z0-9_-]{1,64}`.** That excludes `/`,
`.`, `%`, `?` and `#`, so an id cannot carry a path segment, traverse upward,
smuggle a query string, or resolve to a route other than the one whose access the
guard evaluated.

**Why PII keys are rejected rather than stripped.** A notification is stored by
the OS, shown on a lock screen and often mirrored to a watch — anything readable
there has been disclosed to whoever is nearby. A payload carrying a resident's
name has already been mishandled server-side, and quietly dropping the field
would hide a contract breach that needs fixing at the source.

**Why actions are named and refused.** A link that can act can be forged into
acting, and the resident would never see the request made in their name. Listing
the seven action targets makes the refusal explicit and testable rather than
incidental.

The resolver decides *where*, never *whether*: `resolveRedirect` re-runs
authorization on the resolved route against the live session, including on a cold
start. Unknown target, bad identifier and wrong arity share one message, because
distinguishing them would tell the sender whether their guess landed.

---

## D-46 — Home describes states and steps, never counts

**Status: settled.** Category: product / copy.

**Options**

1. A dashboard: pending requests, unread notifications, verification progress.
2. Counts where a total is available, prose elsewhere.
3. **No counts, percentages or progress anywhere. Every card is a state and a
   step.**

**Chosen: 3.**

**Why.** There is no authoritative source for any of the numbers option 1 wants.
A "pending" count would have to be derived from a page of results, which is a
page and not a total; a completion percentage would have to be derived from a
draft the app deliberately does not persist. Option 2 is worse than either
extreme, because a resident cannot tell which figures are real.

A fabricated figure on a government service is not a cosmetic problem: a resident
who reads "2 pending" plans around two. And a KPI dashboard answers a question
nobody standing in a municipal queue is asking. "What can I do now?" is answered
by a sentence and a button, not by a tile of digits.

Enforced by tests scanning Home's rendered text for `N pending/new/unread`, `%`
and turnaround phrasing, plus a source scan asserting no Home file constructs an
`Announcement`, an `LguEvent` or a `ServiceRequest` — sample content on a
municipal app is a fabricated statement by a local government.

---

## D-47 — On Home an unavailable section disappears; on a destination it explains

**Status: settled.** Category: product / lifecycle.

**Options**

1. One rule everywhere: always explain why a section is empty.
2. One rule everywhere: always hide what cannot load.
3. **Explain on a destination screen, hide on Home.**

**Chosen: 3.**

**Why.** The two situations differ in what the resident asked for. Someone who
opens the News tab chose News, and an empty screen with no explanation reads as a
broken app; they get the honest "not published yet" state, naming what the LGU
does offer instead.

Someone opening Home asked "what can I do now?". With five planned modules, rule
1 answers that with a column of apologies — technically honest, practically a
shrug, and it buries the two things that *do* work. Rule 2 applied everywhere
would leave the News tab silently blank.

The safety property that makes hiding acceptable on Home is that three sections
**never** hide: the hero, the service catalogue and the municipal hall. Home is
therefore always worth opening, even with every planned module absent — which is
exactly today's build. The catalogue keeps a card pointing at Services even when
its list is empty, for the same reason.

---

## D-48 — Nothing personal is fetched for a guest, not merely nothing shown

**Status: settled.** Category: privacy.

**Options**

1. Fetch what Home might need and render only what the level permits.
2. Guard each personal widget so it does not render for a guest.
3. **Choose the sections from access level, and gate every `/me/` read on
   `CapabilityService` as well.**

**Chosen: 3.**

**Why.** Option 1 is the common shape and the wrong one: the data arrives, sits
in memory, and reaches a crash report, a cache and the OS task-switcher snapshot
regardless of whether a widget drew it. "It was not displayed" is not a privacy
guarantee.

Option 2 depends on every future widget remembering. The read is the disclosure,
so the read is what must be gated — and gated by the same service the router
uses, so a section cannot be more permissive than the route it sits on.

The tests assert the strong form: counting repositories, `listCalls == 0` and
`statusCalls == 0` for a guest. Not "nothing was shown" but "nothing was ever
fetched".

---

## D-49 — No progress card, because the draft is deliberately unpersisted

**Status: settled.** Category: privacy / schema.

**Options**

1. Persist the registration draft and show "continue where you left off".
2. Summarise whatever draft happens to be in memory.
3. **No progress card at all.**

**Chosen: 3.**

**Why.** TAB 07 decided the registration draft is held in memory only and dies
with the process, because a draft is the most sensitive object this app ever
holds — names, birth dates, addresses, identity images — and a persisted one
outlives the moment on a device that may be shared. Option 1 reverses a privacy
decision to gain a convenience.

Option 2 produces a card that appears and vanishes depending on whether the app
was killed, which is worse than no card: a resident who saw "continue your
application" yesterday and does not see it today reasonably concludes their
application was lost.

The Master Command asked for this "only if an authoritative, privacy-safe source
actually exists". It does not, so the card does not.

---

## D-50 — Field ownership is declared, and the UI shows it before the refusal

**Status: settled.** Category: schema / product.

**Options**

1. One flat list of fields; the server rejects what a resident may not change.
2. Grey out the canonical fields.
3. **Two labelled sections with different affordances, driven by a declared
   ownership on every field.**

**Chosen: 3.**

**Why.** Option 1 is the common shape and the cruel one: a resident edits their
birth date, submits, and is refused — having been given no way to know in advance
that the field was not theirs. Option 2 shows the difference but not the reason,
and a greyed row reads as "broken" rather than "belongs to the LGU".

The split is not this app's invention. The committed matrix gives
`PATCH /api/v1/me/profile` the request column *"contact fields only"* and the
note *"a citizen may not edit their own eligibility-bearing fields"*. Making it
visible is the client's job.

`FieldOwnership.isEditableInApp` is the single gate — no screen decides for
itself — and a test asserts every eligibility-bearing field answers false. That
matters concretely: a resident who could edit their own date of birth could grant
themselves a senior citizen benefit, and one who could edit their own barangay
could move into a different office's caseload.

**Sources.** REPO backend `docs/contracts/frontend-endpoint-matrix.md` §12.

---

## D-51 — The correction path is a sentence, because no correction endpoint exists

**Status: settled.** Category: correction / product.

**Options**

1. A correction-request form that uploads evidence.
2. Reuse the verification correction flow (TAB 08) for profile fields.
3. **Explain, and name the municipal hall.**

**Chosen: 3.**

**Why.** Option 1 has nowhere to send anything: the contract has no
resident-initiated correction route, and the staff route that could change a
canonical field needs a permission this app must never hold. A form whose
submission silently goes nowhere is worse than an instruction, because the
resident who followed the instruction gets their record fixed and the one who
filled in the form waits.

Option 2 misreads what TAB 08 built. That flow answers a correction *the LGU
asked for* on a specific verification attempt; it is not a general channel for a
resident to dispute their record, and using it as one would put unrelated claims
into a review queue that has no state for them.

What is offered instead: the counter, what to bring, and the note that the app
and the phone are not needed to use it. Residents mid-verification get the one
real shortcut — answering what the LGU already asked.

---

## D-52 — Profile completeness is removed, not hidden

**Status: settled.** Category: schema / privacy.

**Options**

1. Compute a percentage from the fields this build knows.
2. Keep the field and render it when the server sends one.
3. **Remove it from the domain type entirely.**

**Chosen: 3.**

**Why.** Option 1 counts the wrong denominator: the fields *this build* knows,
which drifts from what the LGU requires the moment either changes, and which
would include staff-only fields a resident will never be shown.

Option 2 sounds safer but leaves a loaded gun on the table — a nullable
`completionPercent` on a widely-used type is an invitation for the next screen to
render it, and the module that would populate it does not exist.

There is a product reason as well as a schema one. "Your profile is 60%
complete" reads as an instruction on a government service, and a resident who
chases it to 100% may hand over data the LGU never asked them for — the opposite
of minimisation. What the screen shows instead is which details are on file and
which are not, which is the same information without the false precision.

---

## D-53 — Privacy is explained, not toggled

**Status: settled.** Category: consent / privacy.

**Options**

1. Consent switches that persist locally.
2. Consent switches that call an endpoint.
3. **Fixed informational copy, naming where consent actually lives.**

**Chosen: 3.**

**Why.** Option 2 has no endpoint to call. Option 1 is actively harmful: under
the Data Privacy Act a consent record must be **demonstrable by the controller**,
and a toggle whose state lives on one phone proves nothing to the LGU while
telling the resident they have withdrawn something. The gap between what the
resident believes and what the LGU holds is the whole harm.

The consents the LGU does hold were given during registration (TAB 07) —
explicit, itemised and recorded with the submission. This screen says where they
live and how to change them rather than presenting a second, unrecorded copy.

Retention is stated in the same spirit: the matrix marks deactivation "never a
hard delete — retention is statutory", so the screen says a municipal record is
kept as long as the law requires instead of offering a delete button that would
be refused.

The screen reaches for no dependency at all — asserted by a source test — so it
renders identically for everyone and discloses nothing by being opened.

---

## D-54 — A resident sees their household, never its members

**Status: settled.** Category: privacy / household membership.

**Options**

1. Show the member list — names and relationships — as the Master Command's
   wording allows "when authorized".
2. Show names but hide anything sensitive about each person.
3. **Show the household and an aggregate count. No names, and no type that
   could hold one.**

**Chosen: 3.**

**Why.** The committed client-visibility matrix settles it in two lines. A
citizen gets `household` membership *"own household only"*; and
`Household.members` is listed among the things a citizen never receives, with
cross-resident access called *"a critical defect"*. So names are not authorized,
and the Master Command's condition is simply not met.

Option 2 is the tempting middle and the wrong one. The people in a household are
separate data subjects: their names are their data regardless of what is shown
alongside, and one household member is not the others' data controller. In
practice this matters most in exactly the households the LGU most needs to
protect — a VAWC survivor who has moved, an adult child estranged from a parent
who still holds the phone.

What replaces it is a **count**. It is an aggregate, it names nobody, and it does
the one job a resident needs from this screen: noticing that the office believes
it is serving four people when it is serving six.

The guarantee is structural rather than editorial. There is no `HouseholdMember`
class in this app, so no screen can render one; a source scan asserts it stays
that way.

**Sources.** REPO backend `docs/contracts/client-visibility-matrix.md` §1 and §2.

---

## D-55 — Head of household fails closed

**Status: settled.** Category: authorization / lifecycle.

**Options**

1. Render the server's role string as sent.
2. Map known roles, and show an unrecognised one verbatim.
3. **Map `head` and `household_head`; everything else reads as member.**

**Chosen: 3.**

**Why.** "Head of household" is not a label, it is a standing. It is who the
municipal office speaks to, and in some programmes who receives on behalf of
everyone in the home. A resident shown that title reasonably acts on it — at a
counter, in front of family.

Options 1 and 2 both let an unreviewed or unrecognised string confer it. The
failure is asymmetric: mistakenly showing "member" to a head costs one confused
conversation, and mistakenly showing "head" to a member can cost a household its
claim while somebody is turned away.

The same reasoning as `AccessLevel.fromVerificationTier`, applied to a different
kind of standing, and for the same reason: an unrecognised value must degrade to
the least authority, never toward it.

---

## D-56 — A household correction is a category, not a form

**Status: settled.** Category: correction / privacy.

**Options**

1. A free-text description with optional document upload.
2. A structured form naming the field and its correct value.
3. **A single choice from five categories, and nothing else.**

**Chosen: 3.**

**Why not free text.** A box on a household screen invites a resident to type
the things this app must never hold: a relative's medical condition, why somebody
left, an allegation about another household. That text would then sit in memory,
in a crash report and in the OS task-switcher snapshot — for a submission that
today has nowhere to go at all. The Master Command's instruction not to accept
evidence the app cannot send points the same way.

**Why not a structured value.** Option 2 is a rewrite wearing a request's
clothes: "set barangay to X" is one server change away from being applied, and
acceptance 3 requires that a correction never rewrite canonical relationships.
`HouseholdCorrectionRequest` therefore has one field — the category — so it is
*structurally* incapable of expressing a target value.

**And no category can move a person between households.** Household composition
is a registry decision with eligibility consequences for two households at once,
and it is not something one member of one of them should start from a phone. No
value can express it; a test scans every label for "move", "transfer",
"reassign", "merge" and "split".

A category is enough to route the resident to the right counter, which is what a
correction actually needs. The detail belongs to the conversation with the person
who can act on it — and the screen says so, and gives them no way to type it.

---

## D-57 — Eligibility is text the app renders, never a rule it runs

**Status: settled.** Category: eligibility / product.

**Options**

1. Take the machine-readable rule set and evaluate it against the resident's
   profile — "You look eligible for this."
2. Evaluate only the cheap criteria (age, barangay) and stay quiet on the rest.
3. **Render the office's own sentences. Compute nothing.**

**Chosen: 3.**

**Why.** Option 1 creates a second rule set. It drifts from the office's the
moment either changes, it is wrong in a released build nobody can patch quickly,
and it is wrong in the direction that matters: a resident told they do not
qualify stops asking, and never finds out that the counter would have said yes.
An LGU can correct a clerk in an afternoon; it cannot correct an app store.

Option 2 is worse than either extreme, because a partial verdict reads as a
whole one. "You meet the age requirement" is heard as "you will get it".

The backend's own position is the same and is written down: *"Eligibility rules
are deliberately public… it lets a citizen self-screen instead of queueing to be
refused."* **Self-screen — by reading.**

The guarantee is structural. `EligibilityCriterion` holds text and an optional
label; there is no operator, no threshold and no field name, so there is nowhere
to put a rule. `eligibility_rules` is in the forbidden key list precisely because
it is the one payload that would make local evaluation possible. Two app-wide
scans fail the build on `isEligible`, `canApply`, `qualifies`,
`computeEligibility`, `approvalChance` and `incomeCeiling`.

**Sources.** REPO backend `docs/contracts/client-visibility-matrix.md` §5.

---

## D-58 — Dates are quoted, never turned into "open" or "closed"

**Status: settled.** Category: lifecycle / copy.

**Options**

1. Compare `effective_to` against the device clock and label the programme
   open or closed.
2. Grey out and disable programmes whose window has passed.
3. **Quote the window the office published, and let the resident judge.**

**Chosen: 3.**

**Why.** A municipal window is not a hard boundary. Offices extend deadlines,
reopen for a batch, and accept late applications with a reason — and they do all
three far more often than they publish the change the same afternoon. An app
that computed "closed" would be confidently wrong on exactly the days it matters
most, and it would send somebody away from help they could still have received.

There is also a clock problem: the comparison runs on a phone whose date can be
wrong, in a timezone the server never stated.

Option 2 compounds it by removing the contact details along with the CTA — the
resident cannot even ring the office to ask.

So availability is backend-driven (acceptance 3): the server publishes dates, the
app renders them, and if the LGU wants a programme to stop appearing it stops
returning it. The decoder additionally **refuses any status that is not
`active`**, so a widened projection could not leak a draft programme into a
resident's list.

---

## D-59 — Search runs on the device, because a search term is a disclosure

**Status: settled.** Category: privacy / schema.

**Options**

1. Add a `?search=` parameter to the request.
2. Send the query to the server as a filter, as the web portal would.
3. **Filter locally, over data the server already returned.**

**Chosen: 3.**

**Why.** The endpoint accepts `?category=` and `?channel=` and no search
parameter, so options 1 and 2 would mean inventing one. But the local choice is
also the better one on its own merits.

"burial assistance", "solo parent", "medical", "cash aid" — typed into a
municipal app by a signed-in account — is a sentence about somebody's
circumstances, and it would be logged by every layer between the phone and the
database. The catalogue is small enough to filter on the device, so the
disclosure buys nothing at all.

The limit is honest and recorded as gap S-5: a catalogue large enough to need
server-side paging would need server-side search, and at that point the term
leaves the device. That is a decision to take again with the LGU when it arises,
not a default to drift into.

Search matches name, description and the category label, and deliberately not the
code: `JOBFAIR` is not a word a resident searches for, and matching it produces a
result they cannot explain.

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
| D-18 | No municipal seal until a verified asset exists | brand / licensing | settled |
| D-19 | No Pantone/CMYK specification asserted | brand | settled |
| D-20 | Reduced motion: OS floor OR in-app preference | accessibility | settled |
| D-21 | Gradients declare their foreground, proved across the ramp | accessibility | settled |
| D-22 | Illustrations painted in Flutter, not shipped as files | product / performance | settled |
| D-23 | Every drawn scene announced as an illustration | accessibility | settled |
| D-24 | One animated illustration, and only where motion means something | accessibility | settled |
| D-25 | An undeclared file in `assets/` fails the build | licensing | settled |
| D-26 | Preserved intents are a closed enum with no personal data | privacy / authorization | settled |
| D-27 | Resuming an intent navigates, never acts | product / authorization | settled |
| D-28 | First-launch state lives in the keystore | architecture / privacy | settled |
| D-29 | Skipping the welcome counts as completing it | product | settled |
| D-30 | Registration is verification, not account creation | schema / product | settled |
| D-31 | Collect less than the staff console holds | privacy | settled |
| D-32 | Optional identity steps are server-gated, deny by default | privacy / authorization | settled |
| D-33 | Duplicate and match errors never enumerate | privacy / security | settled |
| D-34 | Verification states mapped one way, degrading downward | schema / authorization | settled |
| D-35 | The status decoder is an allow-list | privacy | settled |
| D-36 | Verified unlocks through the session controller | authorization / product | settled |
| D-37 | No turnaround promises in verification copy | copy / trust | settled |
| D-38 | No token refresh, because none is published | schema / lifecycle | settled |
| D-39 | Recovery is the LGU counter, not a form | product / privacy | settled |
| D-40 | Biometrics unlock the app, never the account | biometric / authorization | settled |
| D-41 | One message for every account-identifying refusal | privacy / security | settled |
| D-42 | Five destinations, identical at every access level | navigation / product | settled |
| D-43 | Access and availability are separate questions | authorization / product | settled |
| D-44 | The household summary is withheld, not built | privacy / schema | settled |
| D-45 | A notification names a target, never a path or an action | deep-link / security | settled |
| D-46 | Home describes states and steps, never counts | product / copy | settled |
| D-47 | Hide on Home, explain on a destination | product / lifecycle | settled |
| D-48 | Nothing personal is fetched for a guest | privacy | settled |
| D-49 | No progress card, because the draft is unpersisted | privacy / schema | settled |
| D-50 | Field ownership is declared and shown before the refusal | schema / product | settled |
| D-51 | The correction path is a sentence, not a form | correction / product | settled |
| D-52 | Profile completeness is removed, not hidden | schema / privacy | settled |
| D-53 | Privacy is explained, not toggled | consent / privacy | settled |
| D-54 | A resident sees their household, never its members | privacy / household | settled |
| D-55 | Head of household fails closed | authorization / lifecycle | settled |
| D-56 | A household correction is a category, not a form | correction / privacy | settled |
| D-57 | Eligibility is text the app renders, never a rule it runs | eligibility / product | settled |
| D-58 | Dates are quoted, never turned into open or closed | lifecycle / copy | settled |
| D-59 | Search runs on the device | privacy / schema | settled |
| D-60 | The intake form is fetched, never authored in the client | schema / product | settled |
| D-61 | An unrenderable question blocks the application, never skipped | schema / trust | settled |
| D-62 | Consent keys travel as their own field, not inside answers | consent / privacy | settled |
| D-63 | The duplicate warning is the server's statement, never inferred | privacy / product | settled |
| D-64 | One idempotency key per attempt, retired on any server answer | lifecycle / idempotency | settled |
| D-65 | Requirements are listed at intake; uploading belongs to TAB 16 | product / scope | settled |
| D-66 | `/apply/:serviceCode` is top-level, not nested under the public catalogue | navigation / authorization | settled |
| D-67 | `FieldError` moved to `core/forms/`, re-exported | architecture | settled |
| D-68 | Autosave is off unless the server declares draft support | privacy / storage | settled |
| D-69 | A captured document is bytes with one lifetime, never a path | privacy / storage | settled |
| D-70 | The readability floor is derived from A4 DPI; PDFs are never re-encoded | accessibility / product | settled |
| D-71 | The declared MIME type is verified against the file's own signature | security / product | settled |
| D-72 | No Android `CAMERA` and no `READ_MEDIA_IMAGES` are declared | privacy / permissions | settled |
| D-73 | Submitted and verified are never collapsed, and there is no completion meter | copy / trust | settled |
| D-74 | A cancelled upload never reports success | lifecycle / trust | settled |
| D-75 | Acceptance comes from an `Ok`; a full progress bar is not acceptance | lifecycle / trust | settled |
| D-76 | An unrecognised requirement status offers no upload — fails closed | schema / lifecycle | settled |
| D-77 | An undecodable preview falls back but still allows sending | product / resilience | settled |
| D-78 | The canonical status is shown alongside the friendly copy, labelled | schema / support | settled |
| D-79 | One status-copy switch, in `domain/`, for every screen | architecture / copy | settled |
| D-80 | Next steps appear only when the backend offers them; unknown kinds are described, not linked | product / trust | settled |
| D-81 | A rejection reason appears only when the office published one | privacy / copy | settled |
| D-82 | The case model has no field for staff data — structural, not filtered | privacy / schema | settled |
| D-83 | `assigned` never names a staff member | privacy / product | settled |
| D-84 | The superseded single-request screen is deleted, not left behind | architecture | settled |
| D-85 | One request list with Open/Past scopes, not two screens | product / navigation | settled |
| D-86 | An approved amount is a server-authored string, never parsed or reformatted | schema / trust | settled |
| D-87 | A receipt is a reference, not a download, until a document endpoint exists | product / schema | settled |
| D-88 | Release acknowledgement is stated, never offered as a tap | consent / trust | settled |
| D-89 | "No record" and "could not load" are separate branches and separate sentences | copy / trust | settled |
| D-90 | A referral contact appears only when published; `declined` always points somewhere | privacy / copy | settled |
| D-91 | Release and referral are structured once and shared by case and history | architecture | settled |
| D-92 | Publication state fails open on unknown, closed on known non-public | schema / trust | settled |
| D-93 | An absent engagement count renders as nothing, never zero | copy / trust | settled |
| D-94 | The end of the feed is the server's `hasMore`, never a short page | schema / pagination | settled |
| D-95 | A page failure keeps the pages already read | product / resilience | settled |
| D-96 | The preview is the office's summary or the full body, never machine-truncated | copy / safety | settled |
| D-97 | Remote media reserves its space; a broken image never takes the post down | performance / resilience | settled |
| D-98 | No interaction control until TAB 20 — a disabled one advertises a missing feature | product | settled |
| D-99 | Every post capability defaults to false, and is guarded in screen *and* controller | authorization / product | settled |
| D-100 | An optimistic reaction adopts the server's count; a failure restores the prior state exactly | lifecycle / trust | settled |
| D-101 | A failed comment keeps its text and replays one idempotency key | lifecycle / product | settled |
| D-102 | A hidden comment is rendered as withheld, never dropped | moderation / trust | settled |
| D-103 | Official replies come from the server's `authorKind`, never inferred from a name | privacy / trust | settled |
| D-104 | The share link is the server's or absent — never composed by the app | trust / safety | settled |
| D-105 | Sharing degrades to the clipboard rather than throwing | resilience | settled |
| D-106 | An unrecognised reaction is shown by its raw label and is not pressable | schema / trust | settled |
| D-107 | LGU times render in Manila time and say so — never the device's clock | copy / safety | settled |
| D-108 | A fixed +08:00 offset, not a timezone database | architecture / performance | settled |
| D-109 | External links are `https`-only and refused rather than repaired | security | settled |
| D-110 | A directions link is the server's or absent — never composed | trust / safety | settled |
| D-111 | Remaining places are stated by the server, never computed by the app | trust / schema | settled |
| D-112 | Publication state is enforced at the list **and** the detail | authorization / trust | settled |
| D-113 | "Registered" is hidden from a guest, decided via `AccessPolicy` | authorization / product | settled |
| D-114 | Full and closed are outcomes to read, not errors to report | copy / trust | settled |
| D-115 | The register control appears only on the server's own `open` state | product / trust | settled |
| D-116 | Whether an unverified resident may register is a per-event server answer | authorization / schema | settled |
| D-117 | The registration route is `authenticated`, with the form gating verification | authorization | settled |
| D-118 | Server-defined form shapes promoted to `core/forms/`, aliased in intake | architecture | settled |
| D-119 | `ServerValue` promoted to `core/api/`, re-exported | architecture | settled |
| D-120 | A waitlist position and an attendance result appear only when published | privacy / trust | settled |
| D-121 | `block` yields to an outcome once an attempt has answered | product / correctness | settled |
| D-122 | The push prompt waits for a meaningful moment, and is never re-asked | product / trust | settled |
| D-123 | No push SDK until an endpoint exists to register a token with | privacy / dependencies | settled |
| D-124 | A push payload redacts itself entirely, including its keys | privacy | settled |
| D-125 | Public advisories and security notices have no off switch | product / safety | settled |
| D-126 | A category the backend has not set defaults to on | schema / safety | settled |
| D-127 | The inbox groups by Manila recency, not by date headings | copy / product | settled |
| D-128 | Reading is optimistic and restores the unread mark on refusal | lifecycle / trust | settled |
| D-129 | A notification is a pointer; detail is fetched under the live session | privacy / authorization | settled |
| D-130 | Settings, help, privacy and accessibility are public — a guest reads them before handing over a number | product / privacy | settled |
| D-131 | Account sections are absent for a guest, not present and disabled | product / copy | settled |
| D-132 | `AccountControls` defaults to allowing nothing; no legal path appears the backend did not offer | authorization / privacy | settled |
| D-133 | `loadControls` succeeds with `none` where every other planned repository declines — "nothing yet" is a true answer | architecture / trust | settled |
| D-134 | Deactivation and erasure are separate requests, never conflated | privacy / copy | settled |
| D-135 | A retention period is the office's sentence or nothing — never one this app guessed | privacy / copy | settled |
| D-136 | A withdrawn consent keeps its row: the record is the evidence | privacy / trust | settled |
| D-137 | A consent the LGU cannot operate without shows its reason, not a switch that would fail | copy / trust | settled |
| D-138 | No invented phone number, address or opening hours anywhere in Help | trust / safety | settled |
| D-139 | Reduce motion is a device preference, never sent to a server | privacy / accessibility | settled |
| D-140 | The OS reduce-motion setting is the floor and cannot be overridden downward in-app | accessibility | settled |
| D-141 | The version row is omitted when the pipeline supplied no version | trust / copy | settled |
| D-142 | Every irreversible act goes through one `ConfirmSheet` whose `consequence` is required | product / safety | settled |
| D-143 | A registration's cancellability is the server's answer about **that place**, not the form's promise | authorization / schema | settled |
| D-144 | A cancellation adopts the server's registration; a failure changes nothing on screen | lifecycle / trust | settled |
| D-145 | Reachability is inferred from real request outcomes, never from a radio flag | architecture / trust | settled |
| D-146 | No connectivity plugin: a dependency reviewed under Article 1 to learn something less accurately | dependencies | settled |
| D-147 | Two consecutive failures before the app says anything | product / trust | settled |
| D-148 | One offline banner, in the shell — reachability is one app-wide fact | architecture | settled |
| D-149 | The cache key is the path **and** its sorted query; the allow-list is checked on the path | correctness / privacy | settled |
| D-150 | `read` evicts stale; `readAllowingStale` returns it with its age attached | architecture / trust | settled |
| D-151 | The public cache stays in memory, and the cost of that is stated | privacy / architecture | settled |
| D-152 | Unsent work says "not sent", never "saved" | copy / safety | settled |
| D-153 | Remote images decode to the size of the box, capped, with a feed and a full-size ceiling | performance | settled |
| D-154 | Filipino is a first-class locale, complete and guarded by a test — English is the template, not the priority | product / accessibility | settled |
| D-155 | No in-app language switcher: the device's preference decides, matched on the language subtag | product / trust | settled |
| D-156 | Failure copy is translated by kind; `residentMessage` stays the English default for context-free callers | architecture / privacy | settled |
| D-157 | Dates never follow the device locale — a reordered date is a different day | correctness / safety | settled |
| D-158 | Every snackbar is announced as well as shown, with tone as a parameter rather than a guess | accessibility | settled |
| D-159 | The form error summary is a live region carrying every message as one sentence | accessibility | settled |
| D-160 | Keyboard action follows field shape: `next`, `done`, or `newline` where the office asked for a paragraph | accessibility / product | settled |
| D-161 | No analytics or crash SDK: a third-party processor is a decision the municipality signs, not a pubspec line | privacy / dependencies | settled |
| D-162 | The event catalogue is a sealed type set with no free-text field — structural, not a convention | privacy / architecture | settled |
| D-163 | A screen view carries an `AppRoute` enum value; an unresolvable path sends nothing | privacy | settled |
| D-164 | Durations and counts travel as buckets — a precise timing is a weak identifier | privacy | settled |
| D-165 | `CrashReport` has no field for the message: a Dart exception quotes the value that broke it | privacy / architecture | settled |
| D-166 | Stack frames are scrubbed of absolute paths and bounded to 24 | privacy | settled |
| D-167 | Consent gates crash reports too — "diagnostics" is not a different promise from "analytics" | privacy / trust | settled |
| D-168 | The app never asks for consent it cannot act on; the build switch sits above consent | product / trust | settled |
| D-169 | Settings states that nothing is collected, even with no switch to offer | copy / trust | settled |

**169 decisions — 165 settled, 4 provisional pending named backend gaps.**
