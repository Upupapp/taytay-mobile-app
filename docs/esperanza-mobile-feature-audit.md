# Esperanza-Mobile — resident feature audit

**Purpose.** Decide, feature by feature, what the Taytay resident app takes from the
Esperanza resident app, what it takes in altered form, and what it must not take.

**Standing of this source.** Reference **only**, for resident function and onboarding
flow (`CLAUDE.md` Article 0). Esperanza is not a source of API shape, authorization
rules, schema or brand. Where Esperanza and the Taytay backend disagree, the backend
wins without discussion.

## Evidence

| Item | Value |
| --- | --- |
| Repository | `Upupapp/Esperanza-Mobile` (public) |
| Branch | `main` |
| Commit inspected | `045cb3f` — "Update Esperanza mobile app", 2026-08-13T10:33:45Z |
| Method | Read-only GitHub Contents API. Nothing cloned into this repository; no Esperanza code is copied here. |
| Source root | `Esperanza-Mobile-App/lib/` |

A local folder `Desktop/esperanza_ids` also exists. It is **not** the audited source: it
is an older, un-versioned copy with 28 Dart files and a flat `screens/` layout, whereas
`main` has ~80 files with a models/services/widgets separation. All findings below are
from the repository above.

### Scope exclusion

Esperanza modules unrelated to the Taytay resident mandate were read only far enough to
confirm they are out of scope, and are excluded from this audit: `screens/balita/`
(municipal social feed with comments), `screens/sakuna/` + `evacuation_center_*`
(disaster-risk-reduction and evacuation centres), `screens/directory/`, and
`services/balita_service.dart`. Taytay's service catalogue (below) contains no
equivalent, and inventing one here would put a feature in the app that no LGU office has
agreed to operate.

---

## 1. Session and access model

### 1.1 Three-tier access level — **ADOPT (concept), ADAPT (derivation)**

`lib/models/access_level.dart` defines exactly the three states Taytay needs:

```dart
enum AccessLevel { guest, unverified, verified }
```

with the ordering comment that `.index` comparison gives an "at least this level" check.
`lib/services/citizen_session_service.dart` derives it in one place:

```dart
AccessLevel get accessLevel {
  final acc = _account;
  if (acc == null) return AccessLevel.guest;
  return AppStatusX.fromLabel(acc.status) == AppStatus.approved
      ? AccessLevel.verified : AccessLevel.unverified;
}
```

**Adopted:** the three states, and the rule that exactly one place decides which one is
current. Taytay already implements this as `AccessLevel` + `SessionController`
(TAB 01).

**Adapted — two changes, both required:**

1. **Ordering is explicit, not `.index`.** Taytay's `AccessLevel` carries an explicit
   `rank` and a `satisfies()` method. Relying on declaration order means a future
   contributor who inserts a case in the middle of the enum silently re-grades every
   access check in the app, with no compiler error and no failing test.
2. **The tier is the server's answer, and parsing fails closed.** Esperanza maps *any*
   non-`Approved` status to `unverified`, which is safe, but it derives the tier from a
   locally-stored account record. Taytay's `AccessLevel.fromVerificationTier` reads the
   server's tier and treats every unrecognised value as `unverified`
   (`CLAUDE.md` Article 3.6).

### 1.2 Local session persistence — **OMIT**

`CitizenSessionService` stores the whole signed-in account as JSON in
`SharedPreferences` under `esperanza_citizen_session`, and the file's own doc comment
says so: *"Frontend-only session simulation… No real backend call is made."*

**Omitted, and the omission is the point.** `SharedPreferences` is an unencrypted XML
file. On Android it is readable by anyone with ADB backup access or root, and it is
swept into cloud auto-backup by default. Storing a resident's identity record — let
alone a credential — there would breach `CLAUDE.md` Article 5.3. Taytay uses
`SessionStore` with `InMemorySessionStore` today and a platform-keystore implementation
later.

### 1.3 Guest mode with an explicit end — **ADOPT**

Esperanza models guest as a real, persisted state (`_guestKey`), not merely the absence
of an account, and provides `endGuestSession()` which
`RestrictedFeatureNotice._endGuestAndGoToRoot` calls *before* navigating to sign-in.

**Adopted, including the reason recorded in the source.** The comment in
`restricted_feature_notice.dart` documents a real bug they hit: a
`pushAndRemoveUntil(..., (route) => false)` removed the reactive auth gate from the
stack, so later `login()`/`logout()` calls had nothing left to react to. Taytay is
structurally immune — `go_router`'s `redirect` re-evaluates on every navigation and the
router listens to `SessionController` — but the underlying lesson is adopted as a rule:
**a screen never removes the thing that reacts to session changes.**

### 1.4 Startup auth gate — **ADAPT**

`main.dart`'s `_AuthGate` renders a spinner while `session.loading`, then `LoginScreen`
if neither signed in nor guest, else `RootShell`.

**Adapted.** The state machine is right — "restoring" is distinct from "signed out",
which is the distinction Taytay's `SessionRestoring` also makes. Two changes:

- **The sign-in screen is not the front door.** Esperanza shows `LoginScreen` to every
  first-time user, so the first thing a resident meets is a credential prompt. Taytay
  lands on `home` as a guest. A municipal service must be *readable* before it is
  *joinable*; requiring an account to see what the LGU offers collects personal data
  with no purpose behind it and excludes residents who cannot or will not register.
- **The gate is the router, not a widget.** Esperanza's gate is a widget that swaps its
  child, so a deep link cannot be gated at all. Taytay gates in `resolveRedirect`, which
  runs on cold-start deep links and back-stack restoration too.

---

## 2. Feature gating

### 2.1 `AccessGuard` — **ADAPT**

`lib/widgets/access_guard.dart` wraps a protected screen, compares the current level
against a required one, and substitutes an explanatory notice when it is not met.

**Adapted into the route table.** Taytay declares the requirement on the route
(`AppRoute.digitalId → AccessRequirement.verified`) rather than in a widget wrapper. The
substance is identical; the placement matters because a requirement attached to a widget
is only enforced on the paths that render that widget, while a requirement attached to a
route is enforced on every path *including* a deep link that never passes through the
shell.

### 2.2 Gating decisions per feature — **ADOPT (the reasoning)**

`root_shell.dart` records a genuinely good decision:

> Dokyu and Tulong require a Verified account… **Emergency only requires being signed in
> — withholding emergency/incident reporting behind LGU verification would be poor
> public-safety practice**, so an Unverified citizen can still use it. Home and Balita
> stay open to Guests.

**Adopted as a principle**, not as a table: *gate on the harm of getting it wrong, not on
a uniform tier*. Where an unverified resident acting is safer than an unverified resident
blocked, the feature is authenticated-only. Taytay's per-feature outcome is in
`taytay-mobile-feature-matrix.md`; this app has no emergency-reporting feature at
present, so the principle currently applies to nothing — recorded so that when one is
proposed it is not reflexively put behind verification.

### 2.3 `RestrictedFeatureNotice` — **ADOPT**

Two reasons, two different messages, two different call-to-action sets: a guest gets
"Create Account" / "Sign In"; an unverified resident gets "Continue Verification".

**Adopted.** This is the correct answer to the question a locked screen raises — *what do
I do now?* — and it is why Taytay's guard redirects an unverified resident to
`/verification` rather than to a generic error. Taytay's copy is its own; Esperanza's
wording is Esperanza's brand.

### 2.4 Hiding vs. showing locked features — **ADAPT**

Esperanza keeps Dokyu and Tulong visible in the bottom navigation for every user and
shows the notice on entry. Taytay's home screen goes further and labels the requirement
on the tile itself ("Verification required") before the resident taps.

**Rationale for the change.** Both are safe — the server authorises regardless — but
telling a resident the requirement *before* the tap saves a navigation that can only end
in refusal, and it makes the path to full access legible from the first screen.

---

## 3. Registration and verification

### 3.1 Six-step wizard — **ADOPT (shape), ADAPT (contents)**

`lib/screens/auth/register_screen.dart` restructures registration from one long form
into: **Personal Information → Terms & Conditions → Valid ID Upload → Face Verification
→ Review → Verification Status.**

**Adopted:** the staged shape, the step indicator, per-step validation
(`_validateStep`), and a final review before submission. A single long form asking for
government identity documents has a high abandonment rate and gives the resident no
sense of what they are committing to.

**Adapted:**

- **Terms and privacy consent is not a step to click past.** Under RA 10173 consent must
  be freely given, specific and informed. Taytay states, per data item, why it is
  collected — Esperanza's own verification screen already gestures at this; Taytay makes
  it the rule.
- **Face verification is a server-side decision.** Esperanza's step is explicitly
  simulated (`_faceScanCompleted` is a local bool). For Taytay, liveness/match results
  are computed and stored server-side; the app captures and uploads, and never holds a
  biometric template.

### 3.2 "Already has an account" short-circuit — **ADOPT**

> If a citizen already has an account… opening this screen jumps straight to the final
> Verification Status step showing their real status.

**Adopted.** Making an unverified resident re-enter details they have already submitted
is the single most common way this flow becomes a dead end.

### 3.3 Verification status in plain language — **ADOPT**

`widgets/verification_status_panel.dart` maps each status to an *explanation* and, where
relevant, an action ("Resubmit Information", "Continue Registration") rather than showing
a bare label.

**Adopted.** "Rejected" alone tells a resident nothing they can act on. Note the source's
own design rule, which Taytay follows: reuse the **one** status vocabulary
(`theme/app_status.dart`) rather than inventing a parallel enum for verification.

### 3.4 One shared status card — **ADOPT**

`widgets/resident_profile_status_card.dart` is used identically on Home and Profile,
reading one `ResidentProfile`, *"so the two never show conflicting numbers"*.

**Adopted** as a general rule for Taytay: a status is rendered from one source; two
screens never compute the same completeness percentage independently.

### 3.5 Demo accounts on the sign-in screen — **OMIT**

`login_screen.dart` renders `MockCatalog.demoAccounts` as tappable cards under an "or try
a demo account" divider, and matches typed emails against that list.

**Omitted without exception.** A production government client must not ship a list of
accounts that anyone can enter, and must never authenticate by comparing input against a
client-side list. Taytay's equivalent affordance is a `kDebugMode`-only session
simulator that fabricates a clearly-fake local session and grants nothing, because
authority is server-side.

### 3.6 Email + password sign-in — **OMIT**

**Omitted** in favour of one-time code on a mobile number (see
`mobile-ui-decision-log.md`, decision D-02). A resident-chosen password is the credential
most often reused across services and the one an LGU is least equipped to recover safely.

---

## 4. Resident profile

### 4.1 Sectioned profile wizard — **ADAPT**

`screens/profile/resident_profile/` splits the master record into Personal Information,
Family Information, Household Information, Review & Submit, Submission Confirmation.

**Adapted.** The sectioning matches how the Taytay backend's `ResidentProfile` module is
described in `docs/architecture/domain-boundary-map.md` (demographics, addresses,
household links), so the shape transfers. What does not transfer is *when* it is
fetched: Taytay's session holds an account id, a greeting name and an access level only,
and each section is loaded by the screen that displays it (`CLAUDE.md` Article 5.1).

### 4.2 Completeness percentage — **ADOPT (with a caveat)**

Useful for showing progress. **Caveat recorded:** the percentage must be computed from
fields the resident can actually see and edit. A completeness figure that silently counts
staff-only fields tells a resident to "complete" something they will never be shown.

---

## 5. Navigation

### 5.1 Bottom navigation with 5 destinations — **ADAPT**

Home / Dokyu / Tulong / Balita / Emergency, with Profile moved to a drawer and Alerts to
a per-tab AppBar action.

**Adapted, not adopted as-is.** Taytay's destinations follow the authoritative service
categories (`dokumento`, `buwis`, `kalusugan`, `trabaho`, `ids`, `national` — six, not
five) and cannot simply copy Esperanza's five. What is adopted is the *pattern*: a small
fixed set of top-level destinations, secondary destinations in a drawer, notifications as
a consistent AppBar action rather than a tab.

### 5.2 `IndexedStack` for tabs — **ADOPT**

Preserves each tab's scroll position and state across switches, which matters on the slow
connections many residents have: rebuilding a tab means re-fetching it.

### 5.3 Global `GlobalKey` + `RootShell.jumpTo` — **OMIT**

A static key allowing any widget to imperatively change the selected tab is a second
source of navigation truth. Taytay navigates by named route; the router is the only thing
that decides what is on screen (`CLAUDE.md` Article 4).

---

## 6. Public access

### 6.1 Reduced guest home variant — **ADOPT**

`home_screen.dart` renders `_guestContent` instead of `_signedInContent`: public
previews stay, account-specific sections (stat tiles, profile status, active requests)
disappear.

**Adopted.** Note *how* it is done: sections that would be empty are removed, not shown
empty. An empty "Active Requests" panel reads as a fault in the app.

### 6.2 Public content is genuinely public — **ADOPT**

Guests reach Home and Balita with no account. Taytay's equivalent: the published service
catalogue is public on the server (`GET /api/v1/services` is unauthenticated by design),
so the app must not require an account to browse it.

---

## 7. Summary

| # | Feature | Verdict |
| --- | --- | --- |
| 1.1 | Three-tier access level (guest/unverified/verified) | **ADOPT** concept · **ADAPT** derivation |
| 1.2 | Session persisted in `SharedPreferences` | **OMIT** |
| 1.3 | Explicit guest state with `endGuestSession()` | **ADOPT** |
| 1.4 | Startup auth gate | **ADAPT** — router-level, lands on home not sign-in |
| 2.1 | `AccessGuard` wrapper | **ADAPT** — requirement declared on the route |
| 2.2 | Gate on harm, not a uniform tier | **ADOPT** (principle) |
| 2.3 | `RestrictedFeatureNotice` with reason-specific actions | **ADOPT** |
| 2.4 | Locked features visible in navigation | **ADAPT** — label the requirement up front |
| 3.1 | Six-step registration wizard | **ADOPT** shape · **ADAPT** consent + biometrics |
| 3.2 | Existing account skips to status | **ADOPT** |
| 3.3 | Verification status explained in plain language | **ADOPT** |
| 3.4 | One shared status card across screens | **ADOPT** |
| 3.5 | Demo accounts on sign-in | **OMIT** |
| 3.6 | Email + password sign-in | **OMIT** |
| 4.1 | Sectioned resident-profile wizard | **ADAPT** — fetch per screen, never cache |
| 4.2 | Profile completeness percentage | **ADOPT** with caveat |
| 5.1 | Five-destination bottom navigation | **ADAPT** — follow Taytay's six categories |
| 5.2 | `IndexedStack` tab state preservation | **ADOPT** |
| 5.3 | Static `GlobalKey` tab jumping | **OMIT** |
| 6.1 | Reduced guest home variant | **ADOPT** |
| 6.2 | Public content reachable without an account | **ADOPT** |
| — | Balita / Sakuna / Directory modules | **OUT OF SCOPE** — excluded, no Taytay equivalent |

**Counts:** 12 ADOPT · 6 ADAPT · 4 OMIT · 1 excluded group.
