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

## D-185 — Firebase starts from four dart-defines, and Article 5.4 names them as its one exception

**Status: settled.** Category: config / privacy. Recorded 2026-11-05 on the
authority of Ella (Michaela Cailing), who directs this work and ruled that her
instructions override this repository's "Paul decides" notes for this change.
That covers this decision and the amendment to Article 5.4. It does not cover
pushing: nothing here was pushed, and D-182 / Article 10 still govern a push.

**Context.** Residents sign in through Firebase Auth (D-173), but nothing ever
called `Firebase.initializeApp`. There was no `google-services.json`, no Google
Services Gradle plugin and no committed options, so a real sign-in would have
thrown inside the SDK.

**Options**

1. The Google Services Gradle plugin with a `google-services.json` per flavor,
   and a `GoogleService-Info.plist` for iOS.
2. A FlutterFire-generated `firebase_options.dart`, committed.
3. **`Firebase.initializeApp(options: …)` from four `--dart-define` values,
   kept in gitignored files passed with `--dart-define-from-file`.**

**Chosen: 3.**

**Why.** One mechanism for every flavor, and for iOS when it has an app. Option
1 needs a file per flavor under `android/app/src/<flavor>/`, a rule for when one
is missing (Gradle fails, or somebody commits a placeholder), and a second file
format for iOS. Option 2 commits the options to a public repository that
deliberately commits none, and fixes one project per generated file.
`--dart-define` is already how this app receives its environment and API base
URL (Article 7), and `AppConfig` already turns a bad value into the blocking
configuration screen. The Firebase values now go through the same door.

No option changes what ships. The Gradle plugin writes `google-services.json`
into string resources inside the APK, the same API key included. Every
mechanism puts the key in the binary, which is why this needed a ruling on
Article 5.4 and not just a choice of file format.

**The Article 5.4 exception.** Article 5.4 said a `--dart-define` is "Never an
API key", and `test/core/release_readiness_test.dart` refused any define name
containing `KEY`. Read literally, that forbade Firebase Auth by any mechanism
and contradicted D-173. Firebase's documentation
(<https://firebase.google.com/docs/projects/api-keys>, read 2026-11-05): "Unlike
how API keys are typically used, API keys for Firebase services are not used to
control access to backend resources", and "API keys for Firebase services are
OK to include in code or checked-in config files". Article 5.4 now names
`TAYTAY_FIREBASE_API_KEY`, `TAYTAY_FIREBASE_APP_ID`,
`TAYTAY_FIREBASE_PROJECT_ID` and `TAYTAY_FIREBASE_MESSAGING_SENDER_ID` as its
single exception: allowed under those four names only, never logged, still not
committed. What protects an account is Firebase Auth's own server-side checks
and the backend's verification of the ID token on every call. The keys are
restricted in Google Cloud to the Identity Toolkit and Token Service APIs. That
was reported for the staging project's Android key on 2026-11-05; it is not
something this repository can check.

**The scan was blind.** The define-name test matched only names written inline
in `String.fromEnvironment('…')`. `AppConfig` reads every define through a
constant, so the test had never seen any of them. The only name it saw was
`TAYTAY_APP_VERSION`. It now resolves names read through constants, fails on a
read it cannot resolve, asserts that it sees the `AppConfig` names, and holds
one named exception that must also appear in `CLAUDE.md`. Proved by planting
`const String plantedDefineKey = 'TAYTAY_PLANTED_SECRET'`, read through
`String.fromEnvironment(plantedDefineKey)`. The strengthened test failed and
named it. The old pattern, run over the same tree, did not see it. The plant was
then removed.

**Behaviour.**

- Every build except a dev debug build with `TAYTAY_DATA=mock` signs in through
  Firebase and needs all four values. Without them the configuration screen
  names the missing defines, never a value. That includes a dev debug build
  against the live API, which used to start and then fail at sign-in.
- A dev mock never starts Firebase and never holds the options.
- An Android app ID on iOS is refused at startup by name.
- If `Firebase.initializeApp` throws, the build stops on the configuration
  screen. The exception is dropped, not shown: its text can quote the options.
- Firebase starts in `main()` before the first frame. It is a platform call,
  not a network request.

**Staging project, as of 2026-11-05.** `taytay-lgu-ids-staging`. Email/password
sign-in on, email enumeration protection on, TOTP off. Android apps
`ph.gov.taytay.app.dev` and `ph.gov.taytay.app.staging`, matching the `dev` and
`staging` flavor suffixes. No iOS app. Their values are in gitignored
`env/firebase.dev.json` and `env/firebase.staging.json`. Only
`env/firebase.example.json`, with empty values, is tracked.

**Open.** There is no production Firebase project, so a prod build stops until
`env/firebase.prod.json` exists. iOS cannot sign in until an iOS app is
registered. The staging API base URL is not recorded in this repository.

---

## D-186 — Google holds the app signing key; the upload key is Paul's until turnover, then the municipality's

**Status: settled.** Category: release / security. Recorded 2026-11-07 under the
owner's standing instruction to settle open design questions by best practice
(Ella, Michaela Cailing; see D-185 for the scope of her authority). It does not
cover pushing: D-182 and Article 10 still govern a push.

**Context.** Two documents disagreed. `docs/release.md` said Paul creates the
Android keystore and keeps it; `docs/integration/manual-tasks.md` ("Custody of
the release signing keys") said the municipality must generate and hold it, not
a contractor. Whoever holds it decides who can ship an update, so the
contradiction had to be settled before the key exists.

**Chosen.**

1. **Google Play App Signing holds the app signing key.** It is generated and
   kept by Google; nobody on the project, and no repository, ever has it.
2. **The upload key** (the keystore `android/key.properties` points at) is
   created by whoever sets up the Play Console listing, Paul, and kept with both
   passwords in a password vault, with a backup.
3. **At turnover it is handed to the municipality** and recorded in the turnover
   credentials register (`taytay-admin-web/docs/turnover/accounts-and-credentials-register.md`).
   Its password is never committed or sent by e-mail or chat.
4. The Apple signing identity is not changed by this decision.

**Why.** Play App Signing is how Google Play signs new apps, and it removes the
worst outcome both documents feared: with Google holding the app signing key, a
lost or leaked upload key is reset by the Play Console account owner instead of
ending the listing. That leaves the upload key as an ordinary credential with
one holder at a time. The person who builds the first release needs it, so it
starts with Paul; the municipality must own its releases after turnover, so it
ends with them, the same way every other credential is handed over.

---

## D-187 — A new Terms of Use or Privacy Notice version is asked for in the app, and a failure never locks anybody out

**Status: settled.** Category: privacy / access. Recorded 2026-11-07 under the
owner's standing instruction to settle open design questions by best practice
(Ella, Michaela Cailing; see D-185 for the scope of her authority).

**Context.** The staff console lets an administrator publish a new Terms of Use
or Privacy Notice and warns that this "makes every resident accept the text
again in the app". The API supports it (`terms_version` and `privacy_version` on
`GET /app/config`, `GET` and `POST /me/consents`), but the app recorded consent
only at registration, so the warning was untrue.

**Chosen.**

1. `ConsentGateController` asks when a session begins (a cold start that
   restores one, or a sign-in) and when the resident returns to the app, at most
   once every five minutes after a successful answer. A version is accepted when
   the resident's consents hold it, trimmed and exact, and it is not withdrawn.
   One version shared by both texts is recorded once.
2. The gate closes only on a **successful** answer from both reads that names a
   version the resident has not accepted. An empty version, a failed read or a
   timeout leaves the app open, and the next return asks again.
3. While it is closed, the guard sends a signed-in resident to
   `/consent-update?from=…` from every route except registration (its terms step
   records both texts), the update gate and the maintenance gate. A guest is
   never asked. The screen says which text changed and when, opens each text in
   the same sheet registration uses (which says "available soon" for a
   placeholder), and offers **I agree** and **Sign out**. Signing out returns to
   guest browsing.
4. **I agree** posts each missing version and reports success only when every
   answer is an accepted, unwithdrawn record of that version. A failure says it
   was not recorded, or that it could not be confirmed, never that it was. Only
   then does the screen offer **Continue for now**, which lets the resident in
   without recording anything; the next return asks again.

**Why.** A gate that a weak connection could close is one a resident cannot rely
on at a counter, where the digital ID is shown. The direction of every uncertain
case is the one `SupportedVersion` already takes: never lock anybody out on a
missing answer. The gate is presentation, not authorization (Article 3.1); the
server does not refuse requests from a resident who has not accepted.

---

## D-188 — A failed send says "nothing was sent" only when nothing left the phone

**Status: settled.** Category: errors / honesty. Recorded 2026-11-07 under the
same instruction as D-187.

**Context.** The document request form said "You are offline … Nothing was
sent." for every dropped connection, including one that dropped after the
request was written. Then the office may already hold it, and the sentence is
untrue: a resident who believes it may stop chasing a request the office has.

**Chosen.**

1. `NetworkFailure.mayHaveArrived` is set by `HttpApiTransport`, the one place
   that saw the socket. It is false only for a failure while connecting: a
   failed name lookup, `Connection failed`, a refused or unreachable destination,
   or a TLS handshake. A reset, a broken pipe or a connection closed before the
   answer is "may have arrived".
2. `AppFailure.outcomeUnknown` is true for a timeout, a network failure that may
   have arrived, an answer the app could not read, an error inside the app, and
   a `5xx` other than `503`. A refusal (`4xx`, `503`) is not unknown.
3. When the transport retries a write and a later attempt fails before sending,
   it reports the earlier attempt that may have arrived, so a retry cannot turn
   "unknown" into "not sent".
4. Where a retry is safe (an idempotency key kept between attempts, or a write
   that is idempotent by nature), an unknown outcome says so: "We could not
   confirm that your request was received. Sending the same request again is
   safe: it will not be filed twice." Document requests, consent and withdrawal,
   notification settings, contact details, the profile edit, and the
   registration wizard's profile and consent steps follow this.

**Why.** "Could not confirm" is true in every case; "nothing was sent" is true
only in some. When the app cannot tell which, it says the one that is true.

---

## D-189 — The offline banner makes no claim about what was sent

**Status: settled.** Category: errors / honesty. Recorded 2026-11-07, following
D-188.

**Context.** The offline banner said "Anything you have typed is still here, and
nothing has been sent." It appears after two failed requests in a row
(`NetworkMonitor.shouldWarn`), and those include timeouts and connections that
dropped after the request left the phone. Then the office may already hold what
was sent, and the banner's promise is untrue. It is also wider than any one
send: it stays up while the resident sends something new.

**Chosen.** The clause is dropped. The banner now says "The app cannot get
through right now. Anything you have typed is still here." In Filipino: "Hindi
makakonekta ang app ngayon. Nandiyan pa ang lahat ng na-type mo." The Filipino
was shortened, not rewritten, and still needs review by a native speaker.

**Rejected.** A banner that keeps "nothing has been sent" while every failure
in the run never left the phone, and says "something you sent may not have
arrived" otherwise. The monitor does not know which requests were writes, so
two failed reads would raise a warning about a send nobody made. A banner that
says "check before sending again" also contradicts the send screens, which say
that sending again is safe where the idempotency key makes it so (D-188).

**Why.** The banner speaks about the connection. What happened to a send is
said by the screen that made it, which knows whether it was a write and whether
a retry is safe (D-188).

---

## D-190 — A message to an office carries an idempotency key that follows its words, and a lost answer says sending again is safe

**Status: settled.** Category: errors / idempotency. Recorded 2026-11-07,
following D-188, on taytay-backend `a7a1884` (migration `0040_message_intents`).

**Context.** Starting a thread (`POST /threads`) and replying
(`POST /threads/{id}/messages`) carried no key, so a message whose answer was
lost to a timeout posted twice when the resident pressed Send again, and the
office was notified twice. The backend now accepts an optional
`idempotency_key` on both: a repeat with the same key, words and image answers
`201` or `200` with the first message and notifies nobody; the same key with
other content is `409`. The composer said "taking longer than expected" or
"offline" without saying whether the message went.

**Chosen.**

1. `send` and `reply` take a required key and put it in the body as
   `idempotency_key`, a multipart field when a file goes with it, as document
   requests do (D-188). It also goes as the `Idempotency-Key` header, which the
   server ignores and the transport reads to retry a dropped send.
2. `IssuanceSendKey` moved to `core/api/send_key.dart` as `SendKey`;
   issuance keeps the old name as an alias. The composers ask for the key with
   `takeFor(content)`, where the content is the office or thread, the subject,
   the trimmed words, the file and the media id. The same content keeps the
   key across every retry; any change mints a new one. A sent message or a
   `409` lets it go.
3. A `409` is never retried. On a first message it reads "Nothing was sent.
   Something went wrong on our side. Open Messages to check what the office has
   before trying again." On a reply it cannot be told from a closed thread by
   its code, and the screen keeps treating it as closed.
4. An unknown outcome (D-188) reads "We could not confirm that your message was
   received. Sending it again is safe: it will not be posted twice.", with "You
   can also check Messages." on a first message. Only a connection that failed
   before the request left the phone reads "Nothing was sent." before the
   offline sentence.

**Rejected.** Resetting the key from each edit path (the text field, the topic
picker, attach, clear, choosing an existing attachment), as the document
request form does. Five paths can each forget, and a forgotten one sends an old
key with new words: the `409` the backend calls a bug.

**Why.** "Sending again is safe" is true only while the retry carries the key
the first send did, and only for the same words. Binding the key to the content
makes both hold by construction. The copy is English, as the rest of the
composer is; it adds no Filipino string.

---

## D-191 — Events run on the Node API: a key in the body, an answer the app cannot read is never a blank, and a lost answer is "not confirmed"

**Status: settled.** Category: contract / errors / idempotency. Recorded
2026-11-08, on taytay-backend `580acbb` (backend DL-192), under Ella's standing
"decide best practice" instruction.

**Context.** `EventApiRepository` declined every method with
`BackendGap.absentOnNodeContract`. The backend now serves `GET /events`
(`scope` `upcoming`, `past` or `registered`, `limit` 1–50, a cursor),
`GET /events/{id}` with its `registration_form`,
`POST /events/{id}/registrations` and
`POST /events/{id}/registrations/{registration_id}/cancel`. The registration
controller minted its key with `generateRequestId()`, a `tay-…` string the API
refuses, and its failure copy said "nothing was registered" for every failure,
timeouts included. `UnsentNotice` said "Taytay LGU does not have {what} …
Nothing was filed, so sending again does not create a duplicate." That is untrue
after a send whose answer was lost, and the second clause holds only for a send
that keeps its idempotency key.

**Chosen.**

1. Every method calls its route and decodes explicitly. A success the app cannot
   read is a `ContractFailure`, never an empty list or a blank outcome: `data` of
   the wrong shape, an event with no id or title, a registration with no event
   or state, a page with no pagination block or one promising more with no
   cursor, and an outcome this build does not know (it may be a place the
   resident holds). Unknown fields are ignored.
2. No seats-left number: `capacity` is the published total and
   `EventCapacity.remaining` stays null on every path. No share link and no
   waitlist position are sent, so none is held. `category_label` is shown as
   sent; an empty description falls back to the summary; the contact is one
   line from the office's published name, office and phone; a cover is drawn
   only from an `https` link. `not_required` reads as an unknown state, so no
   register control is offered. The office's `words` are not shown: every
   sentence is this app's own, chosen by the outcome.
3. The list and the event are public reads that carry the resident's bearer
   when there is one, so each row says whether they hold a place. "My events"
   needs the account. The cursor is kept per scope, page 1 starts again, and
   nothing is asked past the last page.
4. `registered`, `waitlisted`, `full` and `closed` are outcomes, and the capacity
   race is one of them. `403 VERIFICATION_REQUIRED`, `403 FORBIDDEN`, `404`,
   `409` and `422` are `refused`, in the app's own words. A `401`, a timeout, a
   lost connection, a `5xx`, a `429` and an unreadable answer stay failures.
5. Registering and cancelling send `idempotency_key` in the body only, never as
   a header: the API's CORS policy allows four request headers. Unlike D-190,
   the transport therefore does not repeat these sends by itself; the resident
   does, with the same key. The key is a version 4 UUID from `SendKey`: the
   controller takes one per attempt and the detail screen one per place given
   up; an answer lets it go, a failure keeps it.
6. A send that may have arrived reads "We could not confirm that your
   registration was received. Trying again is safe: you will not be registered
   twice.", headed "Registration not confirmed". A later retry that fails before
   sending keeps that sentence, because the earlier send may have registered the
   resident. D-188 holds an unknown across the transport's own retries, not
   across the resident's. "Nothing was registered" is said only for a connection
   that failed before sending with no earlier doubt, and for `full` and
   `closed`, which the server answers only when the resident holds no place.
   Giving up a place that may have gone through reads "We could not confirm
   that your place was given up. Trying again is safe: it will not be done
   twice." and never "You still have your place". A `409` says the place can no
   longer be given up in the app.
7. `UnsentNotice` is headed "Not confirmed yet" and says "We could not confirm
   that Taytay LGU has {what}. Everything you typed is still on this phone." It
   adds "Sending it again is safe: it will not be filed twice." only when the
   caller passes `resendIsSafe`. In Filipino: "Hindi pa kumpirmado", "Hindi
   namin makumpirma na nasa Taytay LGU na ang {what}. Nandito pa sa telepono mo
   ang lahat ng na-type mo." and "Ligtas itong ipadala muli: hindi ito
   maisusumite nang dalawang beses." The Filipino needs review by a native
   speaker. No screen shows the notice today; event registration has its own
   outcome screen.
8. The one model addition is `LguEvent.isCalledOff`, true for status
   `cancelled`. The server keeps a called-off event in Upcoming until its date
   passes. Without it, the row would read "Registration closed" and look like
   an event still going ahead, so the row reads "Called off by Taytay LGU" and
   the page opens with a warning that says the same.
9. A resident who gave up their place may register again while registration is
   `open`. The register control checks for an active registration rather than
   any registration, because the server returns the cancelled one as
   `my_registration`.
10. Events stays routed and off the bar (D-178). `event_registration_updated`
    notifications now open the event. `browseEvents` is `available`. The four
    routes are declared in `backend_routes.dart`, and the Node export is
    re-vendored whole from `580acbb`; the staff routes under `/office/events`
    came with it and are not called.

**Rejected.** Sending the key as an `Idempotency-Key` header too, as D-190 does
for messages: the API's CORS policy allows four request headers, and the
transport's own retry is not needed for a send the resident can retry safely.
Adding a field for the office's `words`: it is a sentence the screens would
have to show beside the app's own, and Article 5.5 keeps resident copy the
app's. Adding `notRequired` to `EventRegistrationState` so a walk-in event reads
"No registration needed" instead of "Ask the office about registering": a
model change for wording, left to the owner.

**Why.** "Could not confirm" is true whenever an answer was lost, and "trying
again is safe" is true only while the retry carries the first key, which is
what `SendKey` keeps. A blank where an unreadable answer was tells a resident
there are no events, or that they have no place, and both are guesses.

---

## D-192 — Events open from a home banner, a walk-in event says so, a cover loads only from the API, and a message stays "not confirmed" after a lost answer

**Status: settled.** Category: navigation / privacy / errors. Recorded
2026-11-08, following D-191. The owner delegated all four questions with
"decide the best practice" (Ella, Michaela Cailing; see D-185 for the scope of
her authority).

**Context.** D-191 left four things open. Events is routed but not on the
approved tab bar (D-178), so a resident had no way in except a notification. A
walk-in event (`not_required`) read "Ask the office about registering", which
sends a resident to ask a question that has no answer. A cover was loaded from
whatever `https` link the office typed, so opening the list made the phone
contact a host the LGU may not run and told it the phone's address and when the
event was viewed. Balita covers never do this: they come from
`GET /news/{id}/cover`. And a message kept D-188 only for one try: after a
timeout, a retry that failed before leaving the phone said "Nothing was sent",
though the first send may have posted the message. D-191 had closed that gap
for events only.

**Chosen.**

1. **A home banner opens Events.** The tab bar stays Home, Directory, Balita,
   Tulong, My Account (D-178). `HomeCatalogue._route` maps a banner link whose
   path contains `event` to the `events` route. It is checked after `program`,
   `service`, `hotline` and `news`. The slide reads "EVENTS" above the title
   and "See events" on its button, with the calendar icon. The office sets
   banners on the staff console's home screen page, so promoting an event is
   its decision. The eyebrow and the button are literal English, as the other
   four are; Home's banner copy is not localised.
2. **A walk-in event says "No registration needed".** The one model addition
   is `EventRegistrationState.notRequired` (`not_required`). Its row and its
   page say "No registration needed". Only `open` offers the register control,
   so it offers none. A state this build does not know still reads "Ask the
   office about registering". The events screens are not localised, so the
   label is English like the other registration labels and no Filipino string
   ships. When they are localised, the proposed Filipino is "Hindi kailangang
   magparehistro", which needs review by a native speaker.
3. **A cover loads only from the API's own origin.** `EventCover` is the one
   place a cover link becomes a picture, on the list and on the page. It draws
   one only when `AppConfig.isOnApiOrigin` holds: the scheme, host and port of
   the configured API base URL, and no credentials in the link. Otherwise it
   draws nothing and takes no space. The cover was already decorative, with no
   label, and the title, date and venue carry every fact. The decoder still
   keeps only `https` links (D-191).
4. **A message stays "not confirmed" after a lost answer.** `SendKey` now holds
   `unconfirmed`: `settle` sets it for a failure whose outcome is unknown
   (D-188), and only an `Ok` clears it. Registering, giving up a place,
   starting a thread and replying all read it after settling, so the four share
   one rule instead of keeping a flag each. After a lost answer, every later
   failure in the same composer reads `MessageAct.unconfirmed`, including a
   retry that fails before sending, until a message goes through. A changed
   message gets a new key but keeps the doubt, because the earlier message may
   already be at the office. Messages send `idempotency_key` in the body; the
   `Idempotency-Key` header copy that `ApiClient` adds is ignored by the server
   and stays.

**Rejected.** Putting Events back on the tab bar: D-178 approved five tabs, and
a banner needs no change to them. Matching `event` before `news`: a Balita link
that mentions an event would open Events instead of the article. Checking the
origin in the decoder alone: a mock or a later repository could still hand
`EventCover` a link to any host, and the check at the point of loading holds
for all of them. Clearing a message's doubt on a refusal: the API answers a
repeated key before it reads the thread (`a7a1884`), but a changed message
carries another key, and the earlier one may still have posted.

**Owner question.** Should event covers be uploaded through the API, as Balita
covers are (served by `GET /news/{id}/cover`), so that an office can have them
shown? Until then a cover is shown only when its link is on the API's own host,
and a link the office typed to any other host is not shown.

**Why.** A banner is the office's own voice on Home, so it is a way into Events
that needs no new navigation. "No registration needed" is what a walk-in event
is; "ask the office" invents a question. A picture from a host the LGU does not
run tells that host who opened the event. "Could not confirm" stays true until
the server answers; "nothing was sent" was true only of the last try.

---

## D-193 — An event cover is uploaded through the API and read by the event's id, never from the address the payload gives

**Status: settled.** Category: privacy / contract. Recorded 2026-11-08,
following D-192, whose owner question it answers. The owner delegated it with
"decide the best practice" (Ella, Michaela Cailing; see D-185).

**Context.** D-192 drew a cover only from the API's own origin, so a cover
the office typed was never shown, and asked whether covers should be uploaded
through the API as Balita covers are. They now are: backend `7522174` stores
an event's cover as an uploaded image (migration `0043`), serves it from
`GET /events/{id}/cover` while the event is published or completed (404
otherwise, a cancelled event included), and sends `cover_image` as
`{ url, alt_text }`, the URL being that route, absolute, built from the
request's origin as a Balita `cover_url` is. The staff console uploads it and
requires the description before publishing (its DL-193, DL-125). Behind the
staging proxy the API writes its own origin as `http://`, because it does not
trust the proxy's forwarded scheme; `isOnApiOrigin` compares the scheme, so a
cover whose URL is used as given would never be shown there.

**Chosen.**

1. **The bytes are read by the event's id.** `MediaBytesApi.eventCover` asks
   `events/{id}/cover` on the configured base, unsigned, as `newsCover` does.
   A 404 is no picture and is not remembered, because a cancelled event's
   cover stops being served; a hit is cached like any public picture.
2. **The URL is only a sign that a cover exists.** The decoder keeps
   `cover_image.url` as sent, `http` included, and its host is never
   requested, whatever it names. The `https`-only filter of D-191 is dropped
   for it: it guarded a request that is no longer made, and on staging it would
   hide every cover.
3. **`EventCover` stays the one place a cover becomes a picture**, now through
   `MediaBytesHost`, on the list and on the page. An event with no cover draws
   nothing and takes no space; one with a cover keeps its 16:9 box, or 200 on
   the page, with the event icon until the bytes arrive, and keeps it if they
   never do, as `RemoteImage` did. A mock build asks for nothing.
4. **The office's description is read to a resident who cannot see the
   picture.** `LguEvent.coverAltText` holds `cover_image.alt_text`, and it
   becomes the picture's semantic label. D-192 left the cover unlabelled
   because the app had no words for it; the office now must write them before
   publishing. With none, the picture stays unlabelled rather than described by
   words this app made up.

`AppConfig.isOnApiOrigin` stays, with its tests, as the check any picture
loaded by its URL must pass; no screen loads one that way any more.

**Rejected.** Loading the URL as sent once it is on the API's origin: it is
not on it on staging, for a reason outside the app, and the configured base is
the only origin the app was built to trust. Rewriting the URL's scheme to the
base's: a guess about somebody else's proxy. Hiding a cover until it loads:
the list would jump as each arrives.

**Why.** A picture should come from the API the app was built for, by a path
the app composes, so no payload can point a phone at another host. The office
writes a description because the console will not publish without one, and a
a resident who cannot see the picture should hear it.

---

## D-194 — An event says who may register, an unverified resident registers where the office opened it to every account, and a corrected event's notice opens the event

**Status: settled.** Category: contract / product / privacy. Recorded 2026-11-09,
following D-193. The owner delegated the four decisions with "research best
practices and do what's best" (Ella, Michaela Cailing; see D-185); they are the
staff console's DL-195, built on backend `cf30686` (migration `0044`).

**Context.** The office asked four things of its events once they were running:
to correct a published event without losing what it said, to stop admissions at
the venue's real limit, to show staff the name a resident's ID was approved
under, and to open some events to residents who have not verified their ID. Two
of them reach this app.

**Chosen.**

1. **Who may register is the event's, and the event says it.** The backend
   sends `registration.open_to` (`verified_residents` or `app_accounts`) on every
   event, with the office's sentence, and `registration_form.allows_unverified_residents`
   is now true for an `app_accounts` event instead of always false.
   `LguEvent.openTo` holds it as a `ServerValue<EventEligibility>`, and the
   event page adds "Who can register" in this app's words: residents whose ID
   Taytay LGU has verified, or anyone signed in to the app. Nothing is shown for
   a walk-in event or for a value this build does not know. The gate itself did
   not change: `EventRegistrationController.block` already asked the form's flag
   (D-191), so an unverified resident now reaches the form where the office
   allowed it and is sent to verification where it did not. An event that gives
   out cash, goods or a benefit is always verified-only, and the server refuses
   anything else; the app never infers it from a category.
2. **A corrected event tells the resident in the inbox, and the notice opens the
   event.** A correction the office makes to when, where or who may register, or
   one that cuts the number of places, sends `event_registration_updated` to
   everybody holding a place or a waitlist place, with the old and the new date,
   time and venue and a sentence that their registration stands. The existing
   route (`_deepLinkTarget`) opens the event, which shows the new details, and
   the resident gives up their place there as before. An event notice may now
   run to 2,000 characters on the server; the inbox has never clipped a body.
3. **Literal English, as the events screens are.** The events screens carry no
   ARB keys today, so the two new sentences follow them and add no Filipino
   strings for native review.

**Not built.** Notes, or an assistance-needs checklist, on a registration. Such
needs are health information, which is sensitive personal information under
RA 10173 §3(l) and §13: holding them properly needs the resident's explicit
consent, a grant for who may read them, and deletion on a retention period the
office sets, and no retention schedule exists (the console's DL-113). An owner
question for when the schedule exists.

**Rejected.** Reading `open_to_words` as the label: a server sentence would
stay English on a translated page and could not be checked by a test. Hiding
the register button from an unverified resident on the event page: the form is
where the app learns the answer, and the server decides on submission anyway.

**Why.** A resident should know before tapping register whether they can, and a
resident whose event moved should hear it with what it moved from, in the app
they registered through.

---

## D-195 — The name on the account is checked against the ID, so a resident sets it before sending an ID and after a rejection, and not between

**Status: settled.** Category: product / contract / privacy. Recorded
2026-11-09, following D-194. The owner decided that an ID reviewer confirms the
ID shows the name the account gives (Ella, Michaela Cailing; the staff
console's DL-197, built on backend `c5e1a7d`).

**Context.** The backend now sends the reviewer the account's `name` and
`birthdate` while a request is pending, requires the confirmed name back on
approval, and refuses `PATCH /me` changing `name` or `birthdate` with `409`
while `verification_status` is `pending` or `verified`. Sending the same value
is not a change; `unverified` and `rejected` may change both. The app set the
name only in the sign-up wizard, and Edit profile offered mobile, email and
barangay. A resident whose request was rejected because their name did not
match their ID had no way to correct it.

**Chosen.**

1. **Edit profile shows the name, and it is a field only while it is open.**
   `NameLock.forTier` reads the `verification_status` that `GET /me` sent:
   `unverified` and `rejected` are open, `pending` is under review, `verified`
   (through `AccessLevel.fromVerificationTier`) is checked, and anything else,
   or a failed read, is unknown. An open name is a text field labelled "Full
   name" with the sentence "Write your name exactly as it is printed on your
   government ID. Taytay LGU checks it against your ID." Every other state draws
   the name as text with a lock and one sentence: it is being checked and
   cannot be changed while the check is pending; it was checked and cannot be
   changed here, so ask Taytay LGU; or the app could not check. A changed name
   is sent as `name` in the same `PATCH /me` as the other fields; an empty name
   or one over 120 characters is refused before sending. The birth date is not
   offered: the app has never collected it.
2. **A `409` on a name change is explained, never silent.** The code alone does
   not say it was the name, because a used email is also `409`. The screen
   reads `GET /me` again; if the name is no longer open, it locks the field,
   shows the account's name again, and says why, that nothing was saved, and
   that other changes can be saved again. Otherwise the existing "Nothing was
   changed" stands. The server's message is never shown (Article 5.5).
3. **The resident is told before sending an ID.** The start page and the
   needs-correction page carry "Your name and your ID" ahead of the photos:
   Taytay LGU will check that the ID shows the name on the account, make sure
   the two match before sending, and the name cannot be changed while the check
   is pending or after it is approved. "Check the name on your account" opens
   Edit profile, which was reachable only from a verified resident's account
   home; it is the way in for the resident this decision exists for.
4. **Literal English**, as the account and verification screens are. The
   sentences live in `NameCheckCopy` and add no Filipino strings for native
   review.

The vendored Node export was refreshed from `c5e1a7d`.

**Not built.** Editing the name from the LGU-verified list on the account
centre: its sheet still points to the municipal hall. Refreshing the session's
greeting name after a change: it updates on the next sign-in.

**Rejected.** Reading the `409` message to tell the name from the email:
branching on a message is forbidden (Article 8). Offering the name whenever the
access level is unverified: `pending` is unverified too, and the server refuses
it there. Offering it for an unknown status: a field that is refused after
typing is worse than one that says the app could not tell.

**Why.** The digital ID shows the account's name, and the office now vouches
for it. A resident must be able to correct it before that check, and after a
rejection, and must know before sending that it will be compared and then
fixed.

---

## D-196 — The Message sent page names no emergency number: it says to call an emergency hotline and opens the hotlines

**Status: settled.** Category: safety / contract / copy. Recorded 2026-11-11,
following D-195. The owner reviewed the redesign's open decisions and said "do
what's best" (Ella, Michaela Cailing; see D-185).

**Context.** The Message sent page said "For emergencies don't wait for a
reply: call the Sagip Taytay Command Center, <number>", and the number was the
*messaged office's* own phone (`office.phone`): a resident who wrote to the
business permits office was told to ring that office as the Command Center. A
resident in an emergency may call the wrong line. The emergency hotlines come
from `GET /hotlines` (then `GET /home`'s `hotlines`), which the Hotlines page
reads. A hotline carries `id`, `name`, `number`, `category` (free text, 1–40
characters, set by staff), `sort_order`, `active` and two timestamps (vendored
Node OpenAPI; backend `hotlines` table, migration `0010`). Nothing marks one
line as the Command Center or the primary emergency line.

**Chosen.**

1. **No number on the page.** The note reads "For emergencies don't wait for a
   reply: call an emergency hotline." (`MessageSentCopy.emergency`), followed by
   a button, "See emergency hotlines", that opens the Hotlines page, which has
   its own loading, empty and offline states and the `tel:` call buttons.
   `DirectoryCanvas.emergencyPhone` is removed, so no caller can put an office's
   line under that sentence again; the canvas takes `onHotlines`.
2. **No line is picked by its name or category.** A display name or a
   free-text category is staff copy, not an identifier: renaming a line would
   silently move the emergency number. A stable flag (for example a boolean
   `primary_emergency`, or a closed `kind`) is recorded as an API field needed;
   with it, the page can show that one number from the same source the Hotlines
   page reads.

**Rejected.** Matching the name "Sagip Taytay Command Center" or a category
containing "emergency"; taking the first hotline by `sort_order`; a number
bundled in the app (it would outlive a change the LGU makes); keeping the office
number under different words (an office line is not an emergency line).

**Why.** The page is read by somebody who just asked an office for help. If
their situation is an emergency, the one number it gives them must be right, and
the app cannot know which number that is.

---

## D-197 — Every gate, notice, confirmation and decision is a centred dialog; only a picker is a bottom sheet

**Status: settled.** Category: design / accessibility. Recorded 2026-11-11,
following D-196, on the owner's "do what's best" (Ella, Michaela Cailing).

**Context.** The redesign's rule is "popups are centred", while the design
system kept a restyled bottom sheet, and Phase 4 left the gates and the
confirmation as sheets as an open question. Fourteen places slid a panel up
from the bottom.

**Chosen.**

1. **A panel that explains, warns, confirms or asks for a decision is a
   centred dialog**, on the theme's dialog (centred, radius 22, flat).
   `AppDialog.show` is the panel counterpart of `AppSheet`: a heading, content
   that scrolls at 200% text, inset 20 / 24, at most 480 wide. Converted: the
   sign-in, verification and not-yet-available gates (`AccessGateSheet`;
   `UnverifiedGateSheet` lost its drag handle and top-only corners), the
   confirmation (`ConfirmSheet`), the session-ended notice
   (`SessionExpiredSheet`), the Terms and Privacy Notice text
   (`showLegalTextSheet`, now with a Close button, since a dialog has no drag
   to close), the correction notice for a checked profile field
   (`CanonicalFieldSheet`), sending a requested document (requirements), and
   the resubmit note (verification, `showResubmitMessageDialog`). The names are
   kept, so no caller changed.
2. **A picker may stay a bottom sheet**: a list of choices the resident picks
   one from. Kept: the sign-up barangay and ID type pickers, the verification
   ID type picker, the message topic picker, the issuance file source picker,
   the conversation actions menu, and the gallery's sheet specimen.
   `AppSheet` says "pickers only".
3. The rule is DESIGN_SYSTEM.md §8 rule 3 and CLAUDE.md Article 6, and
   `expectCleanDialogLayouts` (`test/support/layout_matrix.dart`) holds each
   converted dialog at 360 / 375 / 430 dp and 200% text, centred, with no
   sheet.

**Rejected.** Full-screen routes for the gates (a gate is a pause, not a
destination, and the resident returns to what they were reading); keeping the
legal text as a sheet because it is long (it is a notice, and the dialog
scrolls).

**Why.** One rule a reviewer can check by looking: a choice from a list comes
up from the bottom, everything that asks the resident to read or decide sits in
the middle.

---

## D-198 — The two screenless controllers stay, because rules they enforce are missing from the screens the app runs

**Status: settled.** Category: privacy / testing / architecture. Recorded
2026-11-11, following D-197, on the owner's "do what's best" (Ella, Michaela
Cailing). It records gaps; it does not close them.

**Context.** Phase 4 kept `ServiceDirectoryController` and
`RegistrationController` (with `RegistrationValidation`) although no route
reaches them, because their tests check non-visual rules. The question was
whether the same rules live in the code the app runs; if so, the tests could
move there and the dead code go.

**Found.**

*`ServiceDirectoryController`* (tests: `directory_test` groups "search and
filter run on the device" and "staleness is explicit"). The live catalogue
screens are the Directory (`DirectoryScreen`, `Office.matches`,
`OfficeApiRepository`) and Tulong (`TulongScreen`,
`SocialServiceApiRepository`); nothing in `lib/` reads
`ServiceCatalogRepository` apart from the wiring.

- Held live: the Directory searches on the phone and its chips are the
  categories the API returned.
- **Missing live:** Tulong sends the typed search to the server as `q` on
  `GET /services` (pinned by `s7_tulong_test`), against D-59 ("a search term is
  a disclosure"). A Tulong refresh that fails after a list was shown keeps the
  old list with no "saved" label (`_failed` is set only when nothing was
  loaded). Neither screen records the `loadCatalogue` telemetry event.

*`RegistrationController` / `RegistrationValidation`* (tests:
`registration_test`). The live sign-up is `AccountWizardScreen` on
`AuthRepository`; it uses only `Barangay` / `BarangayDirectory` from the
registration feature.

- Held live: first and last name required, a `09…` mobile number, the barangay
  required, required consents block, an invalid step does not advance, Back
  keeps what was typed, review edits go back only, a failed code request or
  check stays on its step, drafts and uploads do not print their contents.
- **Missing live:** the selfie is taken with no separate biometric consent and
  no server requirement (D-32); `POST me/verification-requests` sends no
  idempotency key, so a retried submission is not protected (D-15); Terms and
  Privacy are agreed with one tick; the street is optional; no birth date is
  collected anywhere in sign-up, so the age floor of 15 and the future-date
  check exist only in `RegistrationValidation`.
- Moot or superseded: the SMS one-time code with no length rule (the live code
  is the server's 6-digit email code), the shipped repository that declines
  everything, `createAccount` not existing (D-30, superseded by the Firebase
  sign-up), and "Nothing was submitted" on every failure (D-188).

**Chosen.** Keep both controllers and their tests unchanged, say on each
controller which rules the live screens lack, and list the gaps in
`design/PROGRESS.md` for the owner. Deleting them would delete the only tests
of those rules; moving the tests is impossible while the live code does not
enforce them.

**Not done here.** Closing any gap. Each is a product or contract change
(sending no `q`, a saved-list label on Tulong, a biometric consent step, an
idempotency key on the verification request, separate consents) and is the
owner's to schedule.

**Why.** A test that passes against code nobody runs proves nothing about the
app, but it is still the only written statement of the rule. The honest move is
to keep the statement and name where the app falls short of it.

---

## D-199 — A centred wave-header title keeps clear of the header's dot field

**Status: settled.** Category: design / accessibility. Recorded 2026-11-11,
following D-198, on the owner's "do what's best" (Ella, Michaela Cailing).

**Context.** `SuccessScreen` (and the blocking notice and app lock) centre
their title and subtitle on the wave header and ran them the full width. The
header's decorative dot field (CSS `.s4`, 46 × 30, 4 px from the right, 62 px
above the bottom) sits where the last lines of a long subtitle end, so the
text ran over the dots (seen in `pattern_success.png` in P5).

**Chosen.** A centred title block is inset by
`WaveHeaderShapes.centeredTextInset` on **both** sides: the dot field's right
offset plus its width plus a 4 px gap, less the header's side padding (34 px).
The text ends before the dots and stays centred. Start-aligned headers keep
the design's `min(300, 82%)` width, which already clears the dots. The inset is
a token computed from the dot field's own tokens, so moving the dots moves the
inset with them. `WaveHeader.dotFieldKey` marks the field for tests.

**Rejected.** Dropping or moving the dot field (the design draws it there);
raising the header's bottom padding (the dots would still sit beside a tall
subtitle at 200% text); insetting only the right side (the block would no
longer be centred).

**Why.** Text over a pattern is harder to read, most of all at the large text
sizes the app promises to honour.

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
| D-170 | The persona dataset carries no identifier at all — not even a fake one | privacy / testing | settled |
| D-171 | The session boundary is observed on the session itself, not on the three routes into it | correctness / privacy | settled |
| D-172 | Signing in is not a boundary, it is the resume; only an ending or a swap clears | correctness / product | settled |
| D-173 | Roadmap D1. The authoritative backend is Clarence Taytay's Node.js API (`Upupapp/taytay-backend`): Firebase Auth only, everything else on Linode. Until an endpoint exists, mock behind the repository interface. The PHP baseline tables stay as the historical contract this client still speaks. The Firebase SDK is not added in S0 | architecture / contract | settled |
| D-174 | Roadmap D2. Mocks run only when `TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`. Staging and production refuse to start in mock mode. Fixtures are synthetic: Juana Dela Cruz, `@example.com`, SAMPLE. No real personal data | privacy / config | settled |
| D-175 | Roadmap D3. The back control is a 44 dp circle inside a 48 dp target. Every non-root route shows it | accessibility | settled |
| D-176 | Roadmap D4. Plus Jakarta Sans is bundled (400–800, SIL OFL). No runtime download and no `google_fonts` | design / privacy | settled |
| D-177 | Roadmap D5. Lucide is a vendored font (ISC; packaging notes MIT), drawn through `TaytayIcon` with a required semantic label | design / accessibility | settled |
| D-178 | Roadmap D6. The approved tabs are Home, Directory, Balita (raised centre), Tulong, My Account. Events leaves the bar in S4. Until then the live shell stays Home, Services, News, Events, Profile | navigation | settled |
| D-179 | Roadmap D7. Office messaging is a domain contract plus a dev mock. D-184 closed F31: the live repository calls `/threads`. | contract | settled |
| D-180 | Roadmap D8. Tulong is information. New Tulong pages do not grow an apply button. Existing assistance screens stay, unlinked from those pages | product | settled |
| D-181 | Roadmap D9. The running app is light mode. Colour still comes from `ColorScheme`. Dark `ThemeData` stays for contrast tests and the later dark pass | accessibility | settled |
| D-182 | Roadmap D10. No direct push to `main` and no merge without Paul's written approval. This narrows the earlier authorisation of direct pushes. Recorded in Article 10 | process | settled |
| D-183 | Roadmap D11. A Directory office page is public resident information: contact, hours, services. It is not a staff or role selector | product / privacy | settled |
| D-184 | The Node contract is vendored at `docs/integration/taytay-node-openapi.json` (taytay-backend PR 1). Envelope `{ data, meta }` / `{ error: { code, message, details, request_id } }` matches `ApiEnvelopeDecoder`; residents do not see `message`. Role enum is `guest`, `registered`, `verified`, `staff`, `admin`. This app mints only `registered` and `verified`. `backend_routes.dart` calls the citizen surface. F31 is closed by `/threads` | contract | settled |
| D-185 | Firebase starts from four `TAYTAY_FIREBASE_*` dart-defines in gitignored `env/` files, not `google-services.json`. Article 5.4 names them as its one exception: public project identifiers, never logged, never committed. The define-name scan now sees names read through constants. Ella's authority, 2026-11-05 | config / privacy | settled |
| D-186 | Google Play App Signing holds the app signing key. The upload key is created by Paul with the Play Console listing, kept in a password vault, and handed to the municipality at turnover through the credentials register; its password is never committed. Settled under Ella's standing "decide best practice" instruction, 2026-11-07 | release / security | settled |
| D-187 | A new Terms of Use or Privacy Notice version is asked for when a session begins and on return to the app. Only a successful answer closes the gate; an empty version or a failed read leaves the app open. Registration and the update and maintenance gates are exempt, a guest is never asked, and Sign out returns to guest browsing. A failed agreement is never called recorded, and only then is Continue for now offered | privacy / access | settled |
| D-188 | "Nothing was sent" only when the connection failed before the request left the phone. The transport sets `NetworkFailure.mayHaveArrived`, `AppFailure.outcomeUnknown` names the uncertain cases, and a retried write keeps the earlier unknown. Where a retry is safe, an unknown outcome says it could not be confirmed and that sending again is safe | errors / honesty | settled |
| D-189 | The offline banner says the app cannot get through and that typed text is kept. It makes no claim about what was sent: a timeout or a connection dropped after sending may have reached the office, and each send says for itself what happened to it | errors / honesty | settled |
| D-190 | Starting a thread and replying send `idempotency_key` (backend `a7a1884`). `SendKey`, promoted from issuance, binds the key to the office or thread, subject, words and attachment: the same message keeps it across retries, a changed one gets a new one, and a `409` is never retried. An unknown outcome says sending again is safe and will not post twice | errors / idempotency | settled |
| D-191 | Events run on the Node API (backend `580acbb`). Every method decodes explicitly, and an answer the app cannot read is a `ContractFailure`, never a blank. No seats-left number. `full` and `closed` are outcomes, the four refusals are `refused`, and a lost answer is "not confirmed" with trying again safe, even after a retry that fails before sending. `idempotency_key` in the body only, a `SendKey` UUID. `UnsentNotice` says "not confirmed" and promises no duplicate only for a keyed send. One model addition, `LguEvent.isCalledOff` | contract / idempotency | settled |
| D-192 | A home banner whose link names events opens Events; the tab bar is unchanged (D-178). A walk-in event (`not_required`) reads "No registration needed" and offers no register control. `EventCover` loads a cover only from the API's own origin (`AppConfig.isOnApiOrigin`). `SendKey.unconfirmed` holds a lost answer for events and messages alike, so a message retry that fails before sending still says it could not be confirmed. Owner question: upload event covers through the API | navigation / privacy / errors | settled |
| D-193 | Event covers are uploaded through the API (backend `7522174`). `MediaBytesApi.eventCover` reads `events/{id}/cover` by the event id from the configured base; `cover_image.url` is only a sign and its host is never requested, `http` included. `EventCover` draws through `MediaBytesHost`, with the office's `alt_text` as the label (`LguEvent.coverAltText`) | privacy / contract | settled |
| D-194 | Who may register is the event's (backend `cf30686`, migration `0044`): `LguEvent.openTo` holds `registration.open_to` and the event page says "Who can register" in this app's words; the form's flag already gated, so an unverified resident reaches the form only where the office opened the event to every account. A corrected event's notice (`event_registration_updated`, with the old and the new date, time and venue) opens the event. Not built: notes or an assistance-needs checklist on a registration (health information, RA 10173 §3(l), §13; no retention schedule) | contract / product / privacy | settled |
| D-195 | The account's name is checked against the ID (console DL-197, backend `c5e1a7d`). `NameLock.forTier` on `GET /me`'s status: Edit profile offers "Full name" as a field for `unverified` and `rejected`, and as locked text with one sentence for `pending`, `verified` and an unknown status. A `409` on a name change re-reads the status and says why; the message is never shown. The start and needs-correction pages say before the photos that the ID must show the account's name and that it then cannot change, with a link to Edit profile | product / contract / privacy | settled |
| D-196 | The Message sent page names no emergency number. `GET /hotlines` has no field that marks the Command Center or the primary line (name and category are free text), and the messaged office's phone is not an emergency line. The note says to call an emergency hotline and its button opens the Hotlines page; `DirectoryCanvas.emergencyPhone` is gone. A stable flag is an API field needed | safety / contract | settled |
| D-197 | Every gate, notice, confirmation and decision is a centred dialog (`AppDialog.show`, theme dialog, scrolls at 200% text); only a picker (a list of choices) is a bottom sheet. The gates, `ConfirmSheet`, the session-ended notice, the legal text (with Close), the correction notice, sending a document and the resubmit note were converted, names kept | design / accessibility | settled |
| D-198 | `ServiceDirectoryController` and `RegistrationController` have no screen and stay, with their tests: rules they hold are missing live. Tulong sends the search as `q` (against D-59) and shows a failed refresh's old list unlabelled; the sign-up wizard takes a selfie with no biometric consent or server gate (D-32), sends no idempotency key on the verification request (D-15), ticks Terms and Privacy together, leaves the street optional and collects no birth date. Gaps recorded, not closed | privacy / testing | settled |
| D-199 | A centred wave-header title block (success screens, notices) is inset by `WaveHeaderShapes.centeredTextInset` on both sides, derived from the dot field's tokens, so a long subtitle no longer runs over the decorative dots and the block stays centred | design / accessibility | settled |

**199 decisions — 195 settled, 4 provisional.**
