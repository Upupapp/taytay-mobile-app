# Taytay resident mobile — brand and design system

The reference for how this app looks, moves and feels. Servana informed the
*principles* recorded in `servana-client-design-audit.md`; none of its branding,
palette, typefaces or assets appear here.

Everything below is implemented in `lib/core/design/`, `lib/core/motion/`,
`lib/core/haptics/` and `lib/shared/widgets/`, and is verified by
`test/core/brand_test.dart`, `test/core/design_test.dart` and
`test/shared/primitives_test.dart`.

---

## 1. The seal, and why this app does not show one

**The municipal seal is not in this build.** `BrandAssets.municipalSeal` is
`null`, and `BrandMark` renders a typographic wordmark instead.

The only candidate artwork in the workspace,
`Desktop/lgu_ids_taytay/assets/logos/taytay_logo.png`, was inspected byte-by-byte
and fails on four counts:

| Check | Finding |
| --- | --- |
| Container format | **JPEG** — magic bytes `FF D8 FF E0 … JFIF`, despite the `.png` extension |
| Compression | **Lossy** — the seal's fine lettering and star points carry re-encoding artifacts |
| Alpha channel | **None** — the artwork is flattened onto opaque black, so it renders as a black square on any surface |
| Provenance | An earlier prototype app, not a file issued by the LGU |

A lossily-recompressed seal flattened onto black *is an altered seal*. Two duties
apply to a government symbol and both point the same way: it must be reproduced
exactly, and it must be the real one. An approximation is worse than nothing,
because a resident cannot tell an approximation from the genuine article — the
seal is precisely the element they would use to decide whether to trust the
screen.

So the app makes no claim it cannot support. The fallback is deliberately
**not** seal-like — a rounded square with a "T" monogram, which reads as an app
icon.

### Adding the real asset

1. Obtain the seal from the Municipality of Taytay in a **lossless** form (SVG
   preferred; otherwise PNG **with alpha**), with written permission to reproduce
   it in this application.
2. Place it under `assets/brand/`, declare the directory in `pubspec.yaml`, and
   register a `BrandAsset` in `brand_assets.dart` with its SHA-256 and an
   `approvalReference` pointing at that permission.
3. Run `flutter test test/core/brand_test.dart`.

The test then enforces, mechanically:

- the file exists and its bytes hash to exactly the approved SHA-256;
- it is **not** JPEG or GIF, checked by magic bytes rather than by extension —
  the failure above is exactly what an extension check misses;
- a PNG declares an alpha-carrying colour type (IHDR byte 25 ∈ {4, 6}, or a
  palette with `tRNS`);
- an SVG really is SVG;
- every registered asset carries a licence reference and a screen-reader label.

One test asserts `hasVerifiedSeal == false`. It is meant to fail the day someone
registers a seal, so that person has to open `brand_assets.dart`, read the
policy, and delete the expectation deliberately.

### Integrity rules (`SealIntegrityRules`)

`BrandMark` enforces these by having no API that could break them: it takes a
size and nothing else — no `color`, `fit`, `shape`, `borderRadius` or `transform`.

Never recolour, tint or convert to monochrome · never stretch (`BoxFit.contain`
only) · never crop or mask to a shape · never rotate, mirror or animate · never
add a shadow, glow or border · never overlay it or use it as a background ·
never render below **32 dp** · always keep **12%** clear space · never use it as
decoration or a watermark.

---

## 2. Colour

### What these values are, and are not

They are **application interface colours**. They are not a claimed reproduction
of an official municipal colour specification. **No Pantone, CMYK or ink
reference appears anywhere in this repository**, and a test enforces that by
scanning `lib/` with comments stripped — no such specification has been supplied,
and inventing one would place a fabricated standard in a government product where
later readers would treat it as authoritative.

| Token | Value | Use |
| --- | --- | --- |
| `taytayBlue` | `#0B3D91` | Primary; the Material 3 seed |
| `taytayBlueDark` | `#062358` | Gradient anchor, dark surfaces |
| `taytayBlueLight` | `#1E5BC6` | Accent on dark |
| `sealGold` | `#FCD116` | **Accent only** — 1.6:1 on white, never text |
| `flagRed` | `#CE1126` | National/emergency context only, not a generic error colour |
| `success` `warning` `danger` `info` | see `design_tokens.dart` | Status; all carry white text at ≥ 4.5:1 |

Every screen reads semantic roles from `Theme.of(context).colorScheme`, derived
from the seed. A widget that hard-codes a value bypasses dark mode and
high-contrast.

### Gradients

A gradient has no single background colour, so contrast cannot be checked against
"the background" — text on one reaches its worst contrast at whichever stop is
nearest its own luminance, and that stop is usually not the one anyone looked at.

`BrandGradient` therefore carries the foreground it is designed for, and
`worstCaseContrastRatio()` samples **16 interpolated steps between every pair of
stops**. The test asserts ≥ 4.5:1 at the worst point for all three gradients
(`brand`, `brandDeep`, `verified`), and a deliberate trap case — black → white →
black, which passes at both endpoints and fails in the middle — proves the
sampler is doing real work.

`BrandGradientSurface` supplies the checked foreground to its subtree, so the
colour that was proved is the colour that gets used.

---

## 3. Typography

Material 3's scale, adjusted rather than replaced: every Material component reads
these roles, so a component the app has not customised still lands on the scale.

- Headlines and titles at **w700**; secondary labels at **w600**.
- Body line height raised to **1.45** — Filipino and English service copy runs
  long, and tighter leading slows reading of multi-line paragraphs.
- **11 sp** floor (`minFontSize`), matching Material's `labelSmall`.
- Platform font only. No runtime font download: that is a third-party CDN call on
  first launch and unstyled text on a weak connection.

Sizes are floors that the OS setting multiplies up from. Text is never scaled
down to fit — a layout that does not fit at 200% scrolls.

---

## 4. Spacing, radii, elevation, opacity, icons

**Spacing** — 4-point grid: `2 · 4 · 8 · 12 · 16 · 24 · 32 · 48`. Deliberately
short; a longer scale just relocates the "which gap?" judgement call.

**Radii** — `4 · 8 · 12 · 16 · 24 · pill`.

**Elevation** — levels, not shadow definitions. Material 3 expresses depth
through *surface tone*, which survives dark mode and high-contrast where a shadow
tuned on white disappears. `none · raised(1) · scrolledUnder(3) · floating(6) ·
dialog(8)`.

**Opacity** — `scrim .32 · stateLayer .12 · hairline .24 · disabled .38`. None is
used to dim live text: disabled controls are exempt from WCAG 1.4.3, but text a
resident must read is not, and dimming it is the commonest quiet contrast
failure.

**Icons** — `18 · 24 · 32 · 48 · 56`. The size is the *glyph*; the tap target is
separate and always ≥ 48 dp. Conflating them produces 24 dp buttons.

---

## 5. Motion

`MotionTokens`: `instant · micro 100 · fast 160 · standard 280 · emphasised 420 ·
celebration 650`, with `enterEase` (`easeOutCubic`), `exitEase`, `standardEase`
and `emphasisedEase`. Frequently-repeated motion is shorter than rare motion.

### Global reduction — two independent switches

```
reduced = MotionPreference.current == reduced
          ||  MediaQuery.disableAnimations
```

The OS setting is a floor that nothing can override. The in-app
`MotionPreference` can only ever *remove* motion — it exists because Android's
"Remove animations" is system-wide, and a resident may want the calmer government
app without flattening their whole phone.

- **Functional motion shortens** (`Motion.duration`) — a page transition still
  has to say where the screen came from.
- **Decorative motion disappears** (`Motion.decorative`).
- Page transitions cross-fade without travelling.
- `AppSkeleton` stops shimmering and draws a static block — a looping shimmer
  over a large area is exactly what a reduced-motion request is about.

Resolution happens per `build`, so a mid-session change takes effect immediately.

---

## 6. Haptics

Declared by **intent**, never by strength: `selection · confirm · success ·
warning · error`. The mapping to platform feedback lives in one place and can
change without touching a screen.

Rules, enforced in `AppHaptics`:

1. Never the only signal — every haptic accompanies a visible change.
2. Never on typing or passive scrolling.
3. Never repeated for the same failure.
4. **Globally suppressed when motion is reduced** (either switch) or when the
   resident turns haptics off. The accessibility settings that reduce animation
   are frequently set by people who find repeated physical feedback unpleasant
   too, so this is central rather than per call site.
5. Never throws — a device with no vibration motor must not break a flow.

---

## 7. Component primitives

| Component | Notes |
| --- | --- |
| `AppButton` | Variants `primary · secondary · text · danger`. Wraps Material's buttons, keeping their focus rings, state layers and disabled semantics. Loading state is **inert and the same size** — swapping a label for a differently-sized spinner moves the button under the resident's thumb. Fires one intent-named haptic. ≥ 48 dp in every variant. |
| `AppCard` | Tone + hairline outline, not shadow. `selected` carries a **thicker primary outline as well as** a tinted fill, so selection is not colour alone (WCAG 1.4.1). Tappable cards get ink and a focus ring from `InkWell`. |
| `AppBanner` | `info · success · warning · error`, each with a **distinct icon** — colour alone fails for roughly one man in twelve, and red-vs-amber is exactly the pair they cannot make. Live region, so it is announced when it appears. Inline rather than a snackbar for anything actionable: a snackbar disappears on a timer. |
| `AppDialog` | Built on Flutter's `AlertDialog`, deliberately — focus trapping, scrim semantics, text scaling and focus restoration come free, and a dependency added for polish can hold a store release hostage. Destructive dialogs are **not** scrim-dismissible. |
| `AppSheet` | `isScrollControlled` with a 90% height cap, safe-area and keyboard insets, drag handle, announced title. Without the cap, sheet content clips at large text scales. |
| `AppSkeleton` / `AppSpinner` / `AppLoadingView` | Skeletons for content (no reflow), spinners for actions. Spinners carry an accessible name; skeletons are excluded from semantics so a screen reader hears the state once, not a run of empty shapes. |
| `StatusView` | `empty · success · error`. Empty and error are separate kinds: "no open slots" and "we could not reach the office" need different words and different buttons, and merging them tells a resident their request failed when it did not. Empty offers no retry. Scrolls, so it survives 200% text on a short screen. |
| `FailureView` | Built on `StatusView`. Renders `residentMessage` only — never the server's operator-facing `message`. Shows the opaque `request_id` as a support reference; developer detail appears in non-production builds only. |
| `BrandMark` | See §1. |

---

## 8. Accessibility baseline

| Concern | Value | Basis |
| --- | --- | --- |
| Minimum tap target | **48 dp** | Material's guidance; also clears WCAG 2.2 SC 2.5.8 (AA, 24×24) and Apple's 44 pt. One higher number removes a per-platform judgement call. |
| Text scale | honoured to **200%**, clamped `0.85–2.0` | WCAG 1.4.4 |
| Body contrast | **4.5:1** | WCAG 1.4.3 (AA) |
| Large text / meaningful graphics | **3:1** | WCAG 1.4.3 (AA) |
| Colour never the sole signal | icons + outlines | WCAG 1.4.1 |
| Reduced motion | OS **or** in-app | WCAG 2.3.3 is AAA; exceeded deliberately — vestibular symptoms are not a AAA-priority problem for the people who have them |

WCAG and platform clause numbers are cited from established knowledge, not
verified in-session; re-check them before making an external conformance claim.

### What is verified mechanically

- Contrast of every `ColorScheme` pair in **both** themes, over the real theme.
- Worst-case gradient contrast, including interpolated midpoints.
- Brand palette pairs, including the assertion that gold *fails* as body text.
- Tap-target height for every button variant and the banner dismiss control.
- Banner icons are distinct across tones.
- Skeleton freezes under **both** reduction switches.
- Semantics: banner live region, spinner name, card label, brand-mark name.
- 200% text scale on `AppButton` and `StatusView` without exception.
- Brand-mark geometry does not grow with text scale.
- Asset format by magic bytes, alpha presence, SHA-256, licence reference.
- No Pantone/CMYK claim anywhere in `lib/`.

---

## 9. Known gaps

| # | Gap | Effect |
| --- | --- | --- |
| B-1 | No verified official seal | `BrandMark` shows a wordmark. Needs an LGU-issued lossless asset and written permission. |
| B-2 | No LGU brand manual | Colours are app choices, not claimed official values. |
| B-3 | No large-text reflow threshold | Layouts clamp at 200% but do not switch to stacked variants (Servana's `largeTextThreshold` idea, not yet adopted). |
| B-4 | `boldText` / `accessibleNavigation` unhandled | Bold-text and screen-reader-active signals are not yet consulted. |
| B-5 | Contrast is checked on tokens, not rendered pixels | A widget that hard-codes a colour would not be caught. Golden-image or pixel-sampling checks would close this. |
| B-6 | No app icon or splash artwork | Belongs to the asset pipeline (TAB 04), not started. |
