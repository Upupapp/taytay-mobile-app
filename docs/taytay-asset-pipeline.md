# Taytay resident mobile — asset, illustration and animation pipeline

How visual assets are produced, declared, checked and replaced. Implemented in
`lib/core/assets/` and `lib/shared/illustrations/`, enforced by
`test/core/asset_manifest_test.dart` and `test/shared/illustrations_test.dart`.

Servana informed *composition technique* only — layered depth, restrained
palette, softness through stacked translucency. **No Servana asset, artwork,
palette or file is used, traced or adapted.**

---

## 1. The central choice: painted, not shipped

Every illustration, scene, state graphic, placeholder and banner motif in this
app is **drawn in Flutter with `CustomPainter`**, not shipped as an image file.

For the flat geometric artwork this app needs, that is strictly better:

| | Painted | Shipped raster |
| --- | --- | --- |
| Install bytes | **0** | 3 density variants each |
| Dark mode | Correct automatically — colours come from the live `ColorScheme` | Needs a second set of files |
| Any size / aspect | Exact | Resampled, or letterboxed |
| Licence surface | **None** | Provenance and permission per file |
| Density variants to keep in sync | None | 1x / 2x / 3x |

Residents frequently pay for install bytes by the megabyte on prepaid data. An
asset that could have been 0 KB and is instead 3 × 120 KB is not a quality
decision; it is a decision to spend someone else's money.

**When a file is still the right answer:** a photographic or hand-painted texture
that cannot be expressed as geometry. Nothing in the app currently qualifies, so
`assets/` ships empty of artwork — but the whole pipeline below is built and
tested, so the day such a file arrives it is *checked* rather than merely dropped
in.

---

## 2. Brand safety carried forward from TAB 03

The TAB 03 ruling stands and is extended: the municipal seal is absent, and
**that covers redrawing, tracing, stylising or alluding to it**. None of the
scenes contains a seal, a coat of arms, a crest, a quartered shield or an
emblematic device derived from one.

Two places this shows in the artwork:

- `_ServicesScenePainter` draws a civic pediment — a plain triangle. Its tympanum
  is **deliberately empty**, which is exactly where a crest would sit.
- `_PrivacyScenePainter` draws a plain heraldic outline as a privacy pictogram:
  no charges, no quartering, no motto, no colours from any arms.

`assets/brand/` is reserved for genuine LGU-supplied artwork and remains governed
by `lib/core/design/brand_assets.dart` and `SealIntegrityRules`.

---

## 3. Everything is an illustration, and says so

Every drawn scene is announced to a screen reader with a label beginning
`Illustration:` — enforced by an assertion in the `Illustration` widget, by the
manifest validator for file assets, and by a test that walks every scene in the
app.

A second rule forbids labels containing `photo`, `photograph`, `photography`,
`picture of`, `actual` or `real footage`. **This app ships no documentary
photography**, and describing a drawing as a photograph of a real office, event
or person is a factual claim it cannot support — made, unavoidably, to the
residents least able to check it.

Purely decorative scenery (the horizon backdrop, banner motifs) is wrapped in
`ExcludeSemantics` instead: naming it would make a screen reader read out
landscape before the content.

---

## 4. What exists

| Component | Purpose |
| --- | --- |
| `TaytayScenes.services()` | Onboarding — a municipal building and service counter |
| `TaytayScenes.digitalId()` | Onboarding — an ID card on a phone |
| `TaytayScenes.privacy()` | Onboarding — a shield over a document |
| `TaytayScenes.horizonBackdrop()` | Decorative lakeshore bands (Laguna de Bay + foothills, abstracted; no landmark) |
| `StateIllustrations.empty()` | Empty state — an empty tray |
| `StateIllustrations.error()` | Error state — a broken link |
| `StateIllustrations.success()` | Success — an animated tick (§7) |
| `ImagePlaceholders.eventPoster()` | Event notice placeholder, 3:4 portrait |
| `ImagePlaceholders.newsfeed()` | Newsfeed image placeholder, 16:9 |
| `ImagePlaceholders.square()` | Square avatar/office placeholder |
| `FeatureIcon` / `ServiceCategoryIcon` | The six backend service categories |
| `FeatureBanner` | Wide gradient strip with a painted motif (`horizon`, `arcs`, `dots`) |

**Icons are Material icons, not files.** The icon font is already bundled and
tree-shakes to the glyphs used — TAB 03's release build reduced it from 1,645,184
to 5,612 bytes. Six custom pictograms would add real weight, need density
variants and dark-mode recolouring, and would have to re-earn the optical
alignment the Material set already has.

`ServiceCategoryIcon` keys off the backend's own category values
(`dokumento`, `buwis`, `kalusugan`, `trabaho`, `ids`, `national`) and returns
`null` for an unknown code, so a category the server adds later degrades to a
neutral mark instead of crashing a released app.

---

## 5. File pipeline: manifest, budgets, densities

Any file asset must be declared as an `AssetEntry`:

```
key            snake_case identifier
path           1x path, directly under the kind's directory
kind           illustration | banner | icon | placeholder | officialArtwork
format         svg | png | webp      (JPEG and GIF are not expressible)
licence        originalWork | lguSupplied | thirdParty
provenance     where it came from and on what basis it may ship
semanticLabel  accessible name
sha256         hash of the approved bytes
maxBytes       optional override of the per-kind budget
```

### Directories and budgets (per density variant)

| Kind | Directory | Budget |
| --- | --- | --- |
| illustration | `assets/illustrations/` | 120 KB |
| banner | `assets/banners/` | 80 KB |
| icon | `assets/icons/` | 12 KB |
| placeholder | `assets/placeholders/` | 40 KB |
| officialArtwork | `assets/brand/` | 200 KB |

### 1x / 2x / 3x policy

- **SVG** needs no variants — one file, every density.
- **PNG / WebP** must ship `2.0x/` and `3.0x/` beside the declared 1x path.
  Flutter resolves them automatically; the manifest declares only the 1x path,
  and declaring a density path is itself a violation.
- **4x is not shipped.** No meaningful Android or iOS device resolves it, and it
  doubles the bytes for pixels nobody sees.

### Format rules

JPEG and GIF are absent from `AssetFormat` by construction, so adding one
requires editing the enum — a visible act in review rather than an incidental
file drop. JPEG carries no alpha and its ringing artifacts are worst exactly
where this artwork is strongest: hard edges between flat fills. PNGs must declare
an alpha-carrying colour type; a PNG without alpha renders as an opaque
rectangle, which is precisely how the rejected seal candidate behaved.

**Format is checked by magic bytes, never by extension** — the TAB 03 seal
candidate was a JPEG named `.png`, which an extension check cannot catch.

---

## 6. Loading behaviour

- **Lazy by default.** An asset loads when the widget that needs it is built.
- **Precache is opt-in, allowlisted and budgeted.** Only keys in
  `AppAssets.precacheKeys` are warmed at startup, capped at **6 assets** and
  **256 KB** total. Decoding costs CPU and memory precisely during the first
  frames, when a low-end device is already building the tree and restoring the
  session.
- The allowlist is currently **empty**: painted illustrations have nothing to
  decode.
- `AssetPrecache.warmUp` swallows failures deliberately — a missing decorative
  image must never stop the app starting. The manifest tests catch that case at
  build time, where it can be fixed.
- Placeholders **reserve their final aspect ratio**, so content does not reflow
  when a real image arrives — the layout shift that moves a resident's thumb
  mid-tap.

---

## 7. Animation policy

**One animated illustration exists in the entire app**: the success tick, which
draws itself once over 420 ms when a submission is confirmed.

It qualifies because the motion *carries meaning* — it marks the transition from
"sending" to "done" at the moment that transition happens. A decorative loop
cannot pass that test, which is why there are none.

Constraints, all tested:

- never loops, never replays on rebuild;
- under reduced motion — **either** the OS setting **or** the in-app
  `MotionPreference` — the finished tick is drawn immediately, with no travel;
- every other scene declares `willChange: false` and paints once, asserted by a
  test that walks all of them;
- every scene sits in a `RepaintBoundary`, so a neighbour repainting does not
  repaint the artwork.

Depth is built by stacking two translucent offset shapes rather than by a
`MaskFilter` blur: a real blur is expensive on the low-end hardware much of this
audience carries, and the stack reads as depth for a fraction of the cost.

---

## 8. Replacing artwork with approved official assets

The mechanism is deliberately the same one TAB 03 built for the seal, so there is
one path and one set of checks:

1. Obtain the artwork from the LGU in a **lossless** form (SVG preferred,
   otherwise PNG with alpha) with written permission.
2. Place the 1x file under the directory for its kind; add `2.0x/` and `3.0x/`
   variants for raster.
3. Register an `AssetEntry` with its `sha256`, `licence: lguSupplied`, and a
   `provenance` naming the LGU issuance or memorandum.
4. Declare the directory under `flutter: assets:` in `pubspec.yaml`.
5. Run `flutter test test/core/asset_manifest_test.dart`.

For the **seal specifically**, `brand_assets.dart` additionally applies:
`BrandMark` is the only widget permitted to render it, and
`SealIntegrityRules` forbid recolouring, cropping, masking, rotating, animating
and rendering below 32 dp.

Nothing has to be rewritten to adopt an official asset — a painted scene can be
replaced by a registered file without touching the screens that use it, because
each is exposed as a widget behind a stable name.

---

## 9. What is verified mechanically

**Manifest and file rules** (28 tests) — key uniqueness and `snake_case`; path
under the correct kind directory; density path rejected in a declaration; file
exists; SHA-256 matches the approved bytes; malformed hash rejected; within
budget; budgets ordered sensibly; JPEG rejected by magic bytes even when named
`.png`; GIF rejected; PNG without alpha rejected; 2x and 3x variants required for
raster and not for SVG; provenance required, and a real reference required for
non-original licences; accessible name required; `Illustration:` prefix required;
photographic claims rejected; precache allowlist within count and byte budgets
and every key present in the manifest; **no undeclared file may sit in an asset
directory**; every kind's directory exists.

**Illustrations** (24 tests) — every scene announced as an illustration; no
photographic claim; mislabelling and photographic claims fail loudly in debug;
decorative scenery excluded from semantics; every scene paints in light *and*
dark; scenes survive degenerate aspect ratios (400×40, 40×400, 1×1);
`RepaintBoundary` present; only the success tick animates; the tick settles and
does not loop; reduced motion via both switches skips the animation; placeholders
reserve their aspect ratio; category icons cover exactly the backend's six
categories; unknown codes degrade instead of throwing; unlabelled icons announce
nothing; banner motifs all paint and the banner is tappable.

---

## 10. Known gaps

| # | Gap | Effect |
| --- | --- | --- |
| A-1 | No verified LGU artwork of any kind | Scenes are original; the seal is still absent (TAB 03 B-1). |
| A-2 | No golden-image tests | Rendering is verified as "paints without error", not "looks correct". A visual regression would pass. |
| A-3 | `assets/` ships no files | The manifest tests are structurally sound but currently vacuous over real files; the validator negative tests carry the proof instead. |
| A-4 | No app icon or launch screen | Platform launcher assets are separate from this in-app pipeline and are not part of TAB 04's scope. |
| A-5 | No illustration localisation | Scenes carry English accessible names; Filipino labels arrive with app-wide localisation. |
