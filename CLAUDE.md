# Taytay Rizal LGU IDS — Resident Mobile Constitution

This file is the highest-authority document in this repository. Every change, review and
generated artifact must comply with it. Where a task instruction and this constitution
conflict, raise the conflict explicitly before writing code.

---

## Article 0 — What this repository is

This repository is the **resident-facing Flutter mobile app** for the Taytay, Rizal LGU
Identity & Services platform (LGU IDS). It is one of several independent clients of a
single backend API, and it identifies itself on the wire as the **`citizen-mobile`**
channel.

| Channel | Client | Where it lives |
| --- | --- | --- |
| `citizen-web` | Citizen web portal | separate repository |
| **`citizen-mobile`** | **This app** | **this repository** |
| `admin-console` | LGU staff/admin console | separate repository |
| `verifier-device` | QR/credential verification device or kiosk | separate repository |

**The people this app serves are residents/citizens, in exactly three states:**

| State | Meaning | Can do |
| --- | --- | --- |
| **Guest** | Nobody signed in | Browse municipal services, offices, announcements |
| **Authenticated / Unverified** | Signed in, identity not confirmed by the LGU | Manage the account, start verification |
| **Verified** | Identity confirmed by the LGU | Hold and present the digital ID, apply for services |

**No admin, staff, verifier or back-office feature is ever built here.** No staff-only
field, no approval queue, no "office" or "role" selector, no admin route prefix, no
moderation tool. If a task appears to ask for one, stop and raise it. A resident app that
grows a staff surface is how a municipal system ends up with its authorization boundary in
the wrong repository.

### Authoritative sources and their standing

| Source | Standing |
| --- | --- |
| **Taytay LGU IDS backend + its OpenAPI/API conventions** | **Authoritative.** The contract, the schema, and every authorization decision. |
| Esperanza-Mobile | Reference **only** for resident function and onboarding flow. Not a source of API shape or brand. |
| ServanaClientAPP | Reference **only** for design, motion and haptics craft. Not a source of product decisions. |
| Any other app in the workspace | Not a source. Do not copy business rules from it. |

**Taytay is the only brand in this product.** No partner, vendor or reference-app
branding, colour, logo, wordmark or copy appears anywhere in the shipped surface.

---

## Article 1 — Technology baseline

* **Flutter and Dart only.** No React Native, no web view shell, no platform-specific
  business logic. Kotlin/Swift appear only in the generated platform runners.
* **Material 3 (`useMaterial3: true`) is the accessibility foundation**, not a styling
  preference. See Article 6.
* Dart SDK `^3.12.0`; Flutter stable (developed against 3.44.0).
* Navigation: `go_router`, declaratively guarded. See Article 4.
* State: `ChangeNotifier` + `InheritedWidget` from the composition root. No service
  locator, no global singletons holding resident state.
* Tests: `flutter_test`, run with `flutter test`.
* Analysis: `flutter analyze` must be **clean**, with the strict rules in
  `analysis_options.yaml`.
* **Every new dependency needs a stated reason.** A package that touches identity,
  storage, networking or crypto needs its maintenance, permissions and data-egress
  behaviour reviewed *before* it is added. An unused dependency is unreviewed attack
  surface.

---

## Article 2 — Feature-first architecture

```
lib/
  main.dart                  # entrypoint only
  app/                       # composition root, root widget, dependency scope
  core/                      # cross-cutting seams — no feature may be named here
    api/                     # transport seam, envelope decoding, request context
    config/                  # environment + API configuration
    design/                  # design tokens + Material 3 theme
    haptics/
    motion/
    result/                  # Result<T> + AppFailure taxonomy
    router/                  # route table + guard
    session/                 # session state, controller, store, access policy
  features/<feature>/
    presentation/            # widgets, screens, view state. Flutter lives here.
    domain/                  # entities + repository *contracts*. No Flutter, no JSON.
    data/                    # repository implementations. Owns the wire format.
  shared/widgets/            # widgets used by more than one feature
```

Rules:

1. **Dependencies point inwards: `presentation → domain ← data`.** `domain` imports
   neither of the others. A `presentation` file that parses JSON, or a `domain` file that
   imports `package:flutter/material.dart`, is a defect.
2. **A feature never imports another feature's `data/` or `presentation/`.** Cross-feature
   needs go through `core/` or a published `domain` contract.
3. **`core/` never imports `features/`** — except `core/router/app_router.dart`, which
   exists precisely to bind routes to screens and is the single sanctioned exception.
4. **No `Map<String, dynamic>` above `data/`.** The wire format stops at the data layer.
5. New features follow the same shape. A feature with no `domain` is a feature whose rules
   are hiding in its widgets.

---

## Article 3 — Multi-client rules (non-negotiable)

These mirror the backend constitution (Article 3) and ADR 0002, from the client side.

1. **The server is the only authority.** Every protected operation is authorized
   server-side from the authenticated actor. This app decides what to *show*, never what
   is *allowed*.
2. **A hidden button is not access control.** `AccessLevel`, `AccessRequirement` and
   `AccessPolicy` exist for routing and explanation. If every one of them were deleted, the
   system would be less pleasant and exactly as secure.
3. **Never send an authority-shaped value.** No role, permission list, `is_admin`, tier or
   scope is ever put in a request. The server ignores such values by design; sending them
   invites a future reader to believe they matter.
4. **`X-Client-Channel: citizen-mobile` is telemetry only.** It is sent for audit and
   presentation defaults. It grants nothing.
5. **Session expiry is a server verdict.** A `401` is the single signal that ends a
   session, handled once in `ApiClient` → `SessionController`, never per call site.
6. **Verification tier comes from the server.** The app maps it with
   `AccessLevel.fromVerificationTier`, which fails closed: an unrecognised tier is
   `unverified`, never `verified`.
7. **Never fork behaviour on "this is mobile".** If the app needs something the API does
   not offer, that is a backend conversation, not a client workaround.

---

## Article 4 — Navigation

* One route table: `core/router/app_routes.dart`. **Every route declares an
  `AccessRequirement`** — there is no default, which is the client-side echo of the
  backend's deny-by-default rule.
* One guard: `resolveRedirect` in `core/router/route_guard.dart`, a pure function run on
  every navigation, including cold-start deep links and back-stack restoration.
* **Screens do not guard themselves and do not navigate to their own successor.** They
  change state; the router reacts. Two sources of navigation truth is how a protected
  screen ends up reachable by one path and not another.
* **Redirect targets are validated against the route table.** Deep links arrive from SMS,
  email and printed QR codes; an unvalidated `?from=` is an open redirect.
* While the session is restoring, protected routes **wait** — they never resolve to
  "signed out". Deciding early signs a returning resident out on every cold start.

---

## Article 5 — Security, privacy and data handling

This app holds Philippine personal data and is subject to the **Data Privacy Act of 2012
(RA 10173)**. Privacy is a default, not a feature.

1. **Data minimisation.** The session object holds an opaque account id, a greeting name
   and an access level — nothing else. Demographics, addresses, PhilSys numbers and
   household links are fetched by the screen that displays them and are never cached in
   long-lived state.
2. **Never log personal data.** No government identifiers, credential secrets, QR signing
   material, tokens, passwords or full addresses — not in `print`, not in `toString`, not
   in a crash report. `toString` on session and credential types is redacted deliberately;
   keep it that way. `avoid_print` is enforced.
3. **Credential material belongs in the platform keystore** (Android Keystore / iOS
   Keychain) and nowhere else — never `SharedPreferences`, never a plain file, never the
   app database. Until that implementation lands, `InMemorySessionStore` is the default:
   a session that dies with the process is the safe failure mode.
4. **No secrets in the binary.** `--dart-define` values ship in clear text inside the APK
   or IPA and are recoverable by anyone who downloads it. Configuration only: environment
   name, public API base URL, timeouts. Never an API key, token or signing material.
   Never read, print or commit `.env` values.
5. **The server's error `message` is operator-facing and is never rendered to a resident.**
   The app derives its own copy from the failure kind. The only server text a resident sees
   is a validation message, shown next to the field it belongs to, where it is actionable.
6. **No real citizen PII in this repository** — not in code, fixtures, tests, screenshots
   or documentation. Test data is obviously synthetic.
7. **Transport is HTTPS outside local development**, enforced by `AppConfig` at startup.
   A misconfigured build fails loudly instead of talking to the wrong environment.
8. **A credential's validity is a server-side cryptographic verdict.** This app may display
   a credential; it never decides one is genuine.

---

## Article 6 — Design, accessibility, motion and haptics

**Material 3 is the accessibility foundation.** Its colour roles carry tested contrast,
its components ship correct semantics and focus indicators, and it responds to system text
scaling and high-contrast settings without per-widget work.

* **All colour comes from `BrandColors` via the `ColorScheme`.** A widget that hard-codes a
  colour bypasses dark mode and high-contrast handling. Dark mode is an accessibility
  feature, not a preference to postpone.
* **Contrast:** body text meets WCAG 2.2 AA (4.5:1), large text and meaningful graphics
  meet 3:1. Enforced by tests over the real theme, not by eye.
* **Tap targets are at least 48×48 dp**, satisfying both Material guidance and WCAG 2.2
  target-size.
* **Text scaling is honoured, clamped, never ignored** — up to 200%. Layouts scroll rather
  than shrink text. A government service a person cannot read is a service they cannot use.
* **Motion tokens only** (`MotionTokens`), and **reduced motion is respected everywhere**
  via `Motion.reduced(context)`. Functional motion shortens; decorative motion disappears.
  Vestibular disorders are common and this app is not optional for the people who have one.
* **Haptics are never the only signal**, never fire on typing or passive scrolling, never
  repeat per retry, and never throw. They are declared by intent (`HapticIntent`), not by
  strength.
* **No runtime-downloaded fonts.** A font fetched from a third-party CDN is an avoidable
  data disclosure and renders unstyled text on the weak connections many residents have.

---

## Article 7 — Configuration and environments

* The environment is a **compile-time** constant: `--dart-define=TAYTAY_ENV=dev|staging|prod`.
  There is no in-app environment switcher — a build that can be re-pointed after shipping
  has no auditable API target, and it is how staging data reaches a public release.
* `--dart-define=TAYTAY_API_BASE_URL` overrides the base URL for local and LAN testing.
* `AppConfig` **validates and refuses**: a release build with no declared environment,
  cleartext HTTP outside dev, credentials embedded in a URL, or a query string on the base
  URL each produce a blocking startup screen instead of a silent fallback.
* Non-production builds show an environment banner, so a staging build is never mistaken
  for the real thing during LGU acceptance testing.

---

## Article 8 — Errors and results

* **Fallible work returns `Result<T>`, it does not throw.** Exceptions cross layers
  invisibly; a `Result` cannot be ignored because the value is only reachable through a
  switch the analyzer checks for exhaustiveness.
* `AppFailure` is a **closed set**. Adding a case is a deliberate act, and every `switch`
  over it is checked exhaustively (`non_exhaustive_switch_*` are errors).
* **Branch on the error `code`, never the message.** Codes are part of the API version;
  messages are not. An unrecognised code degrades to `unknown` and falls back to the HTTP
  status — a new server code must never crash a released app.
* **Unknown response fields are ignored, never rejected** (API conventions §1).
* Every failure carries the `request_id` when the server supplied one, so a resident can
  quote an opaque reference to the support desk.

---

## Article 9 — Testing and definition of done

A change is done when:

1. `flutter analyze` is **clean** — no errors, no warnings, no infos.
2. `flutter test` passes.
3. New behaviour has a test at the correct level: pure rules (guard, policy, decoding,
   config) get unit tests; anything a resident can reach gets a widget test.
4. **Access-controlled behaviour is tested from every session state** — guest, unverified,
   verified — including the denied path. A test that only covers the happy path has not
   tested access at all.
5. Privacy invariants are asserted, not assumed: no server message in resident copy, no
   token or personal data in `toString`, no authority-shaped request header.
6. The build compiles for the platforms the change affects.
7. Docs updated when a boundary, convention or decision changed.

---

## Article 10 — Operational prohibitions for agents

Never push, force-push, merge protected branches, deploy, rotate credentials, touch
production infrastructure or production data, or expose secrets. Local commits only, and
only when explicitly authorized. Preserve existing uncommitted work — inspect and
reconcile the working tree before editing; never reset, clean or revert someone else's
changes for convenience.
