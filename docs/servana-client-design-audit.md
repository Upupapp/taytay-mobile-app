# ServanaClientAPP — design, motion and haptics audit

**Purpose.** Decide which craft techniques from the Servana client app the Taytay
resident app takes, in what form, and which it must not take.

**Standing of this source.** Reference **only**, for design, motion and haptics craft
(`CLAUDE.md` Article 0). Servana is a commercial consumer marketplace; Taytay is a
municipal government service. **No Servana brand asset, colour, wordmark, photograph,
typeface choice or copy appears in Taytay.** What transfers is *technique* — how a thing
is built and why — never the thing itself.

## Evidence

| Item | Value |
| --- | --- |
| Repository | `Upupapp/ServanaClientAPP` |
| Branch | `main` |
| Commit inspected | `ce02830` — "docs(catalog-v2): final report", 2026-08-11T23:28:07+08:00 |
| Local path | `Desktop/servana_client-main` (working tree carries one unrelated uncommitted edit to `lib/common/config/app_theme.dart`, left untouched) |
| Method | Read-only inspection. No Servana code copied into this repository. |

---

## 1. Welcome composition and hero scenes

### 1.1 Typed scene specification — **ADOPT**

`lib/modules/landing/domain/welcome_scene_spec.dart` holds each onboarding scene as an
immutable value: id, headline, subtext, background asset, **semantic description**,
gradient stops, per-breakpoint focal points, analytics id. The file states the reason:

> Content is stored here so copy, assets, and analytics IDs are never scattered inside
> animation widgets.

**Adopted.** Two consequences matter for Taytay. Copy that lives in a data class can be
reviewed by the LGU and later localised (Filipino/English) without touching animation
code. And `semanticDescription` being a *required* field means a screen-reader
description cannot be forgotten — the accessibility equivalent of a compile error.

Taytay's onboarding is three plain pages today; this structure is the target when it
gains imagery.

### 1.2 Layered parallax hero — **ADAPT, heavily reduced**

`welcome_parallax_layer.dart` documents a five-depth system, each layer translating by a
factor of page width:

```
0.05  atmospheric / deepest background   0.35  mid-ground content
0.15  environment / photo layer          0.55  cards and interface
                                         0.80  foreground particles / ribbon
```

Each layer is wrapped in a `RepaintBoundary` so parallax does not repaint static
siblings.

**Adapted.** The `RepaintBoundary` discipline and the idea of a *small, named* depth
scale are adopted. The five-layer cinematic treatment is not: it needs multiple
full-bleed photographs per scene, which is bundle weight residents pay for on metered
connections, and it is exactly the kind of large-field movement that provokes vestibular
symptoms. If Taytay's welcome ever gains depth it will use at most two layers with
factors in the 0.05–0.20 range.

### 1.3 Continuous gradient interpolation — **ADOPT (technique)**

`gradientStops` are interpolated continuously during the swipe rather than snapped at
`onPageChanged`. Snapping produces a visible jump halfway through a drag that reads as a
frame drop.

### 1.4 `WelcomeMotionMode` — **ADOPT (the ladder), ADAPT (the resolution)**

```dart
enum WelcomeMotionMode { full, standard, reduced, staticMode }
```

with capability getters (`hasParallax`, `hasTravelingElements`, `hasLogoFragments`,
`hasPortalTransition`, `hasAmbientLoops`) and a resolver that returns `staticMode` when
`MediaQuery.disableAnimations` is true. Resolved once at cold start and held for the
session.

**Adopted:** naming motion *richness* as a first-class value that widgets query, instead
of scattering `if (reducedMotion)` through the tree; and the four-rung ladder, which
allows a middle setting for weaker hardware — relevant for Taytay, where a large share of
residents are on entry-level Android devices.

**Adapted:** `WelcomeMotionMode.resolve` currently returns `full` for everything that is
not `staticMode` — `standard` and `reduced` exist but nothing selects them, so the
device-capability ladder is aspirational. Taytay will not add rungs it does not select.
Taytay's `Motion` helper resolves per build (so a mid-session accessibility change takes
effect) rather than latching once at cold start.

---

## 2. Design tokens

### 2.1 Deliberately short spacing scale — **ADOPT, already implemented**

`lib/common/constants/app_spacing.dart` is worth quoting because the reasoning is the
valuable part:

> Home mixed 8, 10, 14, 16, 20 and 28pt gutters with no rule for choosing between them…
> The scale is deliberately short. A longer one just relocates the original problem —
> with ten options, picking is still a judgement call every time.

Servana: `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 20 · section 24 · sectionLarge 32`.
Taytay's `Spacing` (TAB 01) is the same idea on a strict 4-point grid.

**One difference, deliberate:** Servana's `xl` is 20; Taytay's is 24. Twenty is not on a
4-point grid's natural rhythm with 16 and 24 both present, and mixing 20 and 24 in one
layout is precisely the ambiguity the scale exists to remove.

### 2.2 A single responsive gutter function — **ADOPT**

Servana exposes one `horizontalPadding(context)` so *"every section lands on the same
guide by construction"*. Taytay has `Spacing.screenGutter` as a constant; the function
form is the target once tablet layouts exist.

### 2.3 Breakpoints by capability, never device — **ADOPT**

`ServanaBreakpoints`: compact 360 · standard 420 · largePhone 600 · tablet 840, with the
rule *"use capability- and size-based logic only — never check a device model name."*
Adopted verbatim as a rule.

### 2.4 Colour palette — **OMIT**

Servana's palette (`#F89040` orange accent, `#3058C8` blue, `#EF4444` danger) is Servana
brand. Taytay uses `BrandColors` seeded from the official municipal blue.

**One structural criticism, recorded so Taytay does not repeat it:** Servana's
`ColorPalette` is a set of `static Color` fields — mutable statics, not `const`, and not
derived from a `ColorScheme`. That is why the app has a separate `navActive` /
`navInactive` / `navBorder` group: values that a Material 3 `ColorScheme` supplies for
free (`primary`, `onSurfaceVariant`, `outlineVariant`) had to be hand-defined, and each
one is a place dark mode and high-contrast can be missed. Taytay reads every colour from
`Theme.of(context).colorScheme`.

### 2.5 Typography — **OMIT the choice, ADOPT the discipline**

Servana uses `Poppins` for body and `Plus Jakarta Sans` for button text, declared once in
`FontPalette`. Naming fonts in one place is right. Taytay uses the platform font
(`CLAUDE.md` Article 6) — a downloadable font package means a third-party CDN call on
first launch and unstyled text on weak connections. Two font families for one app is also
more than a government service needs.

### 2.6 Radii and shadows — **NOT ADOPTABLE (no source token set)**

`constants/boxes.dart` turned out to be an unrelated storage-key holder, not box
decoration tokens. Radii are inlined per widget, with `BorderRadius.circular(16)` shared
in the theme. There is no elevation/shadow scale to audit. Taytay's `Radii` scale
(4/8/12/16/24/pill) stands on its own, and elevation comes from Material 3 surface tones
rather than hand-rolled shadows.

---

## 3. Motion and easing

### 3.1 Durations justified against a real alternative — **ADOPT**

`servana_nav_motion.dart` on the 320 ms navigation transition:

> MoveUp's own transition is a full second; that reads as deliberate on a screen you
> visit occasionally and as lag on primary navigation you touch dozens of times a
> session, so the character is kept and the duration is not.

**Adopted as a rule:** a duration token records what it is *for*, and frequently-repeated
motion is shorter than rare motion. Taytay's `MotionTokens` follows this
(micro 100 · fast 160 · standard 280 · emphasised 420 · celebration 650).

### 3.2 Ease-out dominant for entry — **ADOPT, already implemented**

> Ease-out dominant: the bubble leaves immediately and settles gently, which reads as
> responsive. A symmetric curve feels like it hesitates.

Taytay: `MotionTokens.enterEase = Curves.easeOutCubic`.

### 3.3 Small rise on page entry — **ADOPT**

`pageRiseOffset = 8` logical pixels, *"small on purpose — the intent is a sense of
arrival, not a slide."* Taytay's page transition uses a 4% horizontal offset for the same
reason, and drops the travel entirely under reduced motion.

### 3.4 Splash portal transition — **OMIT**

A `ClipOval` expansion from the logo centre (`splashPortal`, 600 ms). Distinctive, and
appropriate for a consumer brand. A municipal ID app's splash should be brief and get out
of the way; 600 ms of decorative expansion after a cold start is time a resident on a
slow device is already spending.

---

## 4. Haptics

### 4.1 Central haptics with explicit rules — **ADOPT, already implemented**

Servana's `AppHaptics` states four rules in its doc comment: never on keystrokes or
passive scrolling; never repeatedly when an API fails; never as the only signal of a
result; fire-and-forget, swallowing errors so a device with no vibration motor cannot
crash the app. All four are in Taytay's `CLAUDE.md` Article 6 and enforced in
`AppHaptics`.

### 4.2 Naming by strength vs. by intent — **ADAPT (improvement)**

Servana's methods are a mix of strength (`light`, `medium`), outcome (`success`,
`warning`, `selection`) and context (`categoryEntry`, `categoryRevealSettled`). Two
problems: `categoryEntry` and `selection` are the same call, so the API has drifted from
one concept into three names; and a strength-named method invites a call site to pick a
buzz by feel.

**Taytay adapts to intent-only** — `HapticIntent { selection, confirm, success, warning,
error }` — so the strength mapping can change in one place. Servana's `setEnabled`
preference is adopted as-is.

### 4.3 Suppression under reduced motion — **ADAPT (extension)**

Servana gates haptics on its own preference only. Taytay also suppresses non-essential
haptics when the platform requests reduced motion: the accessibility settings that reduce
animation are frequently set by people who find repeated physical feedback unpleasant
too. Servana's `categoryRevealSettled` comment shows awareness of this ("never during…
reduced-motion sessions") but it is enforced at the call site, not centrally.

---

## 5. States: loading, empty, error, success

### 5.1 Three distinct state widgets per surface — **ADOPT**

`category_skeleton.dart`, `category_empty_state.dart`, `category_error_state.dart` are
separate components. Empty and error are genuinely different situations: "there is
nothing here" needs no retry button, "we could not load this" needs one, and collapsing
them tells a resident their request failed when in fact the office has no open slots.
Taytay's `FailureView` is the error half; empty and skeleton states are still to come.

### 5.2 Skeletons over spinners for content — **ADOPT (with limits)**

Skeleton placeholders preserve layout and avoid the reflow that a spinner-then-content
swap causes. **Limit recorded:** a shimmering skeleton is animated decoration and must
stop moving under reduced motion — a static grey block is the correct fallback.

### 5.3 Dialog built on Flutter's own `AlertDialog` — **ADOPT, including the reasoning**

`servana_alert_dialog.dart` replaced the `awesome_dialog` package, and the comment
records both reasons: the package dragged in the whole Rive runtime, whose
`librive_text.so` is not 4 KB page-aligned and **blocked the Play Store upload for API
35+**; and Flutter's own `AlertDialog` gives *"correct focus trapping, scrim semantics and
text scaling for free."*

**Adopted as a rule for Taytay:** prefer the framework's component. A dependency added
for visual polish can hold a government release hostage at submission time, and
hand-rolled dialogs routinely lose focus trapping — which is the difference between usable
and unusable for a screen-reader user.

Also adopted: the note that callers navigating afterwards must `await` the dialog, since
dismissing a route while its dialog is still on top orphans the dialog over the new
screen.

---

## 6. Images and assets

### 6.1 Central `AppImage` with asset fallback — **ADOPT**

`appImageProvider` / `AppImage` validate the URL scheme, allow only `http`/`https`, and
fall back to a bundled asset via `errorBuilder`. A broken remote image degrades to a
placeholder rather than a Flutter error box.

**Adopted, with one tightening:** Taytay allows `https` only outside local development,
matching `AppConfig`'s transport rule. Servana permits plain `http`.

### 6.2 A build-level switch that forbids network images — **ADOPT (strongly)**

`_allowNetworkImages()` returns false in mock/white-label builds so those builds make
*zero* external calls, and the `try/catch` around the locator means an unconfigured build
fails closed to "no network images".

**Adopted as a privacy control.** For Taytay the relevant case is any build not pointed at
a real environment: an image request leaks the device IP and a referring identifier to
whoever hosts it. Failing closed is right.

### 6.3 WebP assets — **ADOPT**

Servana's backgrounds are `.webp`. Materially smaller than PNG at the same quality, and
bundle size is data a resident pays for on first install.

---

## 7. Accessibility

`AccessibilityTokens` is the closest analogue to Taytay's `A11y`, and the comparison is
worth recording:

| Concern | Servana | Taytay | Note |
| --- | --- | --- | --- |
| Minimum touch target | **44 dp** | **48 dp** | Servana's own comment says "WCAG 2.2 AA minimum: 24×24 CSS px / 44×44 dp… the comfortable iOS/Android minimum". 44 is Apple's HIG figure; Material's is 48. Taytay takes 48 — the stricter of the two, and it satisfies both. |
| Large-text threshold | 1.3 → reflow to stacked layouts | — | **ADOPT.** A named threshold at which layouts switch to vertical is more useful than clamping alone. Taytay clamps at 2.0 but has no reflow threshold yet. |
| Max required scale | 2.0 (WCAG 1.4.4) | 2.0 | Agreed. |
| Reduced motion | `MediaQuery.disableAnimations` | same | Agreed. |
| Bold text | `MediaQuery.boldText` | — | **ADOPT later.** Not yet handled in Taytay. |
| Screen reader active | `MediaQuery.accessibleNavigation` | — | **ADOPT later.** Useful for suppressing decorative motion and auto-advancing carousels. |

---

## 8. Summary

| # | Technique | Verdict |
| --- | --- | --- |
| 1.1 | Typed scene spec with required semantic description | **ADOPT** |
| 1.2 | Five-layer parallax hero | **ADAPT** — at most two shallow layers |
| 1.3 | Continuous gradient interpolation on swipe | **ADOPT** |
| 1.4 | `WelcomeMotionMode` richness ladder | **ADOPT** ladder · **ADAPT** per-build resolution |
| 2.1 | Deliberately short spacing scale | **ADOPT** (implemented; `xl` 24 not 20) |
| 2.2 | One responsive gutter function | **ADOPT** (target) |
| 2.3 | Capability-based breakpoints, never device names | **ADOPT** |
| 2.4 | Colour palette | **OMIT** — brand; and prefer `ColorScheme` roles to static fields |
| 2.5 | Two custom font families | **OMIT** choice · **ADOPT** single-source discipline |
| 2.6 | Radii / shadow tokens | **N/A** — no token set exists in the source |
| 3.1 | Durations justified against alternatives | **ADOPT** |
| 3.2 | Ease-out dominant entry curve | **ADOPT** (implemented) |
| 3.3 | Small rise/travel on entry | **ADOPT** (implemented) |
| 3.4 | Splash portal (ClipOval) transition | **OMIT** |
| 4.1 | Central haptics with explicit rules | **ADOPT** (implemented) |
| 4.2 | Haptic naming | **ADAPT** — intent-only, not strength |
| 4.3 | Haptic suppression under reduced motion | **ADAPT** — centrally, not per call site |
| 5.1 | Separate skeleton / empty / error states | **ADOPT** |
| 5.2 | Skeletons over spinners | **ADOPT** — static under reduced motion |
| 5.3 | Dialogs on Flutter's `AlertDialog` | **ADOPT** including the dependency lesson |
| 6.1 | `AppImage` with asset fallback | **ADOPT** — https-only |
| 6.2 | Build-level "no network images", failing closed | **ADOPT** |
| 6.3 | WebP assets | **ADOPT** |
| 7 | Large-text reflow threshold, bold-text, screen-reader signals | **ADOPT later** |
| 7 | 44 dp touch target | **ADAPT** — Taytay uses 48 dp |

**Counts:** 14 ADOPT · 7 ADAPT · 3 OMIT · 1 not applicable.
