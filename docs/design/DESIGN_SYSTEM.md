# Resident app design system

How the Taytay resident app looks, and how to build a screen that looks the same. Written from the
code as it stood at the end of the 2026-11 redesign (Phases 1–5). Where this file and the code
disagree, the code is right and this file is out of date: fix the file.

**Sources, in order of authority.** `CLAUDE.md` wins over everything here: a privacy, access,
architecture or security rule is never traded for a look, and neither is a test that enforces one.
Then the code (`lib/core/design/`, `lib/shared/widgets/`, the component gallery). Then this file.
Then the mock-ups in [`mobile/screens/`](./mobile/screens/), which are drawings with **sample
data** ([`README.md`](./README.md) says how to open them): copy their shapes, never their content.

---

## 1. Where things live

| Path | Holds |
|---|---|
| `lib/core/design/design_tokens.dart` | `BrandColors`, `Spacing`, `Radii`, `ComponentSizes`, `FocusRing`, `Elevation` (all 0), `TaytayShadows` (all empty), `Opacities`, `IconSizes`, `A11y`, `contrastRatio()` |
| `lib/core/design/typography.dart` | `AppTypography` (the type scale), `TypeMetrics` |
| `lib/core/design/brand_gradients.dart` | `BrandGradients` (header, wave header, six tiles), `TileTone`, `HeaderShapes`, `WaveHeaderShapes` + `WavePainter`, `WelcomeShapes`, `GlassTokens` |
| `lib/core/design/app_theme.dart` | `AppTheme.light()` / `.dark()`: every themed Material component; `applyAccessibilityMediaQuery` |
| `lib/core/design/button_styles.dart` | `TaytayButtonStyles.soft() / gold() / compact()`, `TaytayButtonMetrics` (one 52 px button) |
| `lib/core/design/ringed_input_border.dart` | `RingedInputBorder`: the field border with the 3 px focus ring painted outside |
| `lib/core/design/taytay_icons.dart` | `TaytayIcons`: the vendored Lucide glyphs (87) |
| `lib/core/design/taytay_glyphs.dart` | `TaytayGlyph` (the design's 20 solid SVG icons), `TaytayIllustration` (the two empty-state drawings) |
| `lib/core/design/brand_assets.dart` | `BrandAssets.municipalSeal`, `SealIntegrityRules` |
| `lib/core/motion/motion_tokens.dart` | `MotionTokens`, `Motion.reduced(context)`, `MotionPreference` |
| `lib/core/haptics/app_haptics.dart` | `AppHaptics.fire(HapticIntent…)` |
| `lib/shared/widgets/` | Every shared widget (§3). Feature code builds screens from these |
| `lib/features/gallery/presentation/` | The component gallery: `ComponentGalleryScreen` (route `/dev/components`, dev builds only), `ThemeGallerySection` (tokens + themed components), `SharedWidgetsGallerySection` (shared widgets) |
| `assets/icons/`, `assets/illustrations/` | The solid icons and illustrations, declared in `AppAssets` (`lib/core/assets/asset_manifest.dart`) |
| `test/goldens/design_system/` | The gallery, page by page, and one screen per pattern, as goldens (§7) |
| `test/core/design_guard_test.dart` | Fails on colour, font-size, shadow and radius literals in feature code (§8) |
| `test/support/layout_matrix.dart` | `expectCleanLayouts` / `layoutHost`: the 360 / 375 / 430 × 100% / 200% check (§6) |

Only `lib/core/design/` and `lib/shared/widgets/` may hold a colour, font size, radius or shadow
value. Everything else reads tokens and builds from shared widgets.

---

## 2. Tokens

### Colours — `BrandColors`

The redesign names. New code uses these; the theme's `ColorScheme` is derived from them.

| Token | Value | Use |
|---|---|---|
| `blue` | `#0A2071` | Primary: buttons, links, selected chips, header middle stop |
| `navy` | `#08124A` | Header start, splash, gold-tile icon |
| `sky` / `skyLight` | `#2D54E0` / `#5C7DF2` | Header end; sky tile |
| `gold` | `#F5DA18` | Accent: gold button, wave layer, header circle, progress |
| `goldInk` / `gold50` | `#6B5A00` / `#FEF7CF` | Gold text on light / gold tint (warning note, draft pill) |
| `red` / `redInk` / `red50` | `#E0090A` / `#A30708` / `#FDECEC` | Error borders and badges / error text (`danger`) / error tint |
| `green` / `green50` | `#17663A` / `#E4F4EA` | Success, "Open" / success tint |
| `blue50` / `blue100` | `#ECF1FC` / `#DCE5FA` | Soft buttons, soft chips, settings icon squares |
| `ink` | `#0E1733` | Headings, titles, field values |
| `text` | `#2B3550` | Body text, field labels |
| `muted` | `#5B6680` | Supporting text, hints (`fieldHint`), timestamps |
| `background` | `#F4F6FA` | Soft page background; filled soft card |
| `glassBackground` | `#EEF2FA` | Page behind glass cards |
| `softFill` / `softFillHover` | `#F2F4F8` / `#ECEFF5` | Filled fields; their hover |
| `chipFill` | `#EEF1F7` | Unselected soft chip |
| `divider` / `line` / `line2` | `#EEF1F6` / `#ECEFF5` / `#DCE2EC` | Hairlines; upload-slot dash |
| `onHeaderMuted` / `onHeaderLede` / `onHeaderSuccess` | `#C3CDE6` / `#D5DDF2` / `#9BE3B4` | Secondary text on the blue header |
| `successBright` | `#2EA05A` | Green tile end, bright check |
| `errorFill` | `#FFF5F5` | A field in error |
| `white`, `transparent` | | |
| `chevron` | `#7D869C` | Row chevrons (3:1, a graphic) |

**Older names** (`taytayBlue`, `sealGold`, `textPrimary`, `danger`, `success`, `fieldFill`,
`chipBlueBg`…) are aliases re-pointed at the values above, so code written before the redesign
still compiles on the new palette. New code uses the names in the table. A few specialist values
stay for the screens that need them (`cardDim*` for a suspended digital ID, `qrFrame`,
`cardPendingOutline` for the ID card that is not issued yet, `sampleBorder` for `SampleTag`).

Contrast is tested, not eyeballed: `test/core/design_test.dart`, `foundation_contrast_test.dart`
and `redesign_theme_test.dart` hold body text to 4.5:1 and large text and graphics to 3:1 on the
real theme. **Light mode is what the app shows** (decision D9); `AppTheme.dark()` stays built so the
contrast tests have a dark scheme to check.

### Gradients — `BrandGradients`

| Token | Definition | Use |
|---|---|---|
| `header` | 150°, `navy` 0% → `blue` 50% → `sky` 100% | `BlueHeader`, splash, `DetailHero` scrim stops |
| `waveHeader` | 150°, same colours, `blue` at 45% | `WaveHeader` |
| `tile(TileTone)` / `tiles` | 135°: blue `#0A2071→#2D54E0`, green `#17663A→#2EA05A`, gold `#E8C500→#F5DA18`, red `#B00708→#E0090A`, navy `#08124A→#22307E`, sky `#2D54E0→#5C7DF2` | `IconTile`; `onColor` is the icon colour (navy on gold, white otherwise) |

`BrandGradient.toLinearGradient()` paints the exact CSS angle (`CssGradientAngle`).
`HeaderShapes`: white circle 220 at 7% (top-right, −70/−80), gold circle 150 at 16% (bottom-left,
−40/−60), bottom corners `Radii.header` (28), `glassOverlap` 32. `WaveHeaderShapes`: the three
wave layers (gold 85%, white 40%, white) painted 50 tall by `WavePainter`, plus the floating
shapes; `centeredTextInset` (34, derived from the dot field's tokens) keeps a centred title
clear of the dot field. `WelcomeShapes`: the onboarding photo zone, wave, Skip pill and pager. `GlassTokens`:
`fill` (white 74% → 50%), `pinnedFill` (gold tint), `border` (white 85%, 1 px), `navFill` /
`navBorder` (tab bar), `backdropFilter()` (blur 18, saturate 1.6), `pageColor`, `pageBlobs`.

*Legacy, unused outside `lib/core/design/`:* `inAppHeader` and `brand` (= `header`), `brandDeep`,
`verified`, `woven`, `WovenFieldPainter`, `WovenGoldGlow`. Contrast tests still pin them; do not
use them in new code.

### Type — `AppTypography` (Plus Jakarta Sans, bundled)

| Role | Size / weight / line height | Use |
|---|---|---|
| `hero` | 22 / 700 / 1.18, −0.33 | Welcome and wave-header titles, splash |
| `headerTitleLarge` | 20 / 700 / 1.12 | Big header-bar title (tabs) |
| `headerTitle` | 15 / 600 / 1.2 | Header title next to a back button |
| `headerSubtitle` | 11.5 / 500 | Line under a header title |
| `pageTitle` | 18 / 700 / 1.15 | Page and sheet titles |
| `storyTitle` | 16 / 700 / 1.2 | Balita story title |
| `sectionTitle` | 15 / 600 / 1.25 | Section headings |
| `bodyStyle` | 13.5 / 500 / 1.5 | Body text |
| `listTitle` / `listDetail` | 13.5 / 600 · 12.5 / 500 | Row title / row supporting line |
| `small` / `tiny` / `fieldHelp` | 11.5 · 11 · 11.5 / 500 | Timestamps, notes, help under a field |
| `chip` / `pill` | 13.5 / 600 · 11.5 / 700 | Choice chips / status pills |
| `navLabel` / `navLabelSelected` | 11 / 600 · 11 / 800 | Bottom navigation (stays 11) |
| `category` | 10.5 / 800, +0.63 (0.06em) | ABISO · MSWDO labels; the caller upper-cases the string |
| `eyebrow`, `label`, `fieldValue`, `button`, `link` | 11.5/700 · 12.5/600 · 14/600 · 14/600 · 13.5/600 | Eyebrows, field labels, field text, buttons, text links |

`AppTypography.minFontSize` is 10.5 (category only). The older roles further down the file
(`h1`, `title`, `titleCompact`, `cardTitle`, `emptyTitle`, `bodyCompact`, `listMeta`, `sbtn`…) are
re-pointed at the nearest redesign size. Colour is applied by the caller:
`AppTypography.listTitle.copyWith(color: BrandColors.ink)`. Sizes are floors that the OS text
setting multiplies up from; nothing shrinks text to fit.

### Radii — `Radii`

| Token | Value | Token | Value |
|---|---|---|---|
| `card` | 20 | `cardLarge` (glass) | 22 |
| `button` | 16 | `field` | 14 |
| `tile` / `tileSmall` / `tileLarge` | 14 / 11 / 17 | `header` (bottom corners) | 28 |
| `sheet` / `sheetLarge` | 24 / 28 | `dialog` | 22 |
| `note` | 14 | `check` (consent card) | 16 |
| `tag` | 6 | `pill` | 999 (fully round) |
| `xs` `sm` `md` `lg` `xl` | 4 / 8 / 12 / 16 / 24 | `arch` | 120 |

### Sizes — `ComponentSizes`, `IconSizes`, `A11y`

| Token | Value | Token | Value |
|---|---|---|---|
| `buttonHeight` / `buttonHeightSmall` | 52 / 44 | `fieldHeight` | 54 |
| `chipHeight` | 36 (in a 48 target) | `tile` / `tileSmall` / `tileLarge` | 44 / 36 / 56 |
| `launchTile` | 62 | `headerIconButton` | 44 (in a 48 target) |
| `avatar` / `profileAvatar` / `profileBadge` | 44 / 60 / 22 | `seal` | 38 |
| `listRow` / `listIcon` | 64 / 40 | `countBadge` | 22 |
| `stepDisc` | 26 | `progressBar` | 6 |
| `headerButton` | 50 | `bubbleWidthFactor` | 0.82 |
| `navigationBar` / `navigationIndicator` | 80 / 56 × 30 | `dialogMaxWidth` / `skeletonPhoto` | 480 / 200 |

`IconSizes`: `sm` 18, `md` 24, `lg` 32, `xl` 48, `xxl` 56 — the glyph, never the target.
`A11y`: `minTapTarget` 48, `backButtonVisual` 44, `maxSupportedTextScale` 2.0,
`minSupportedTextScale` 0.85, `minBodyContrastRatio` 4.5, `minLargeTextContrastRatio` 3.0.

### Spacing — `Spacing`

`xxs` 2 · `xs` 4 · `sm` 8 · `md` 12 · `lg` 16 (`screenGutter`) · `xl` 24 · `xxl` 32 · `xxxl` 48 ·
`formGutter` 20 (form and sheet side padding) · `formGap` 18 (between form parts) · `section` 14
(between glass cards on a tab).

### Focus, shadows, opacity

- **Focus ring:** `FocusRing.borderWidth` 1.5 (blue border), `ringWidth` 3, `ring` (blue at 14%),
  `errorRing` (red). The theme's focused field borders are `RingedInputBorder`s, so every themed
  `TextField` gets the ring; a custom field paints its own with the same values. The ring is not
  a shadow and must stay visible.
- **No shadows:** `Elevation.*` are all 0, `TaytayShadows.*` are empty lists, and every themed
  component is flat.
- **Opacities:** `scrim` 0.32, `stateLayer` 0.12, `hairline` 0.24, `disabled` 0.38 (never on text
  a resident must read).

### Motion and haptics

- `MotionTokens`: `micro` 100 ms, `fast` 160, `standard` 280, `emphasised` 420, `celebration` 650,
  `splashMinimum` 900 / `splashReduced` 300; curves `standardEase`, `enterEase`, `exitEase`,
  `emphasisedEase`.
- `Motion.reduced(context)` is true when the platform or the in-app preference asks for less
  motion. `Motion.duration(context, full)` shortens functional motion; `Motion.decorative(context,
  full)` removes decorative motion; `Motion.decorativeLoop(context)` says whether a loop may run.
  `LoadingSkeleton`'s shimmer stops under reduced motion.
- `AppHaptics.fire(HapticIntent.selection | confirm | success | warning | error, suppressed:
  Motion.reduced(context))`. Shared widgets already fire it: `PrimaryButton` and friends (confirm), `AppButton` (its
  `hapticIntent`), the back control and tappable cards and rows (selection), a destructive
  `AppDialog` (warning). Never on typing or scrolling,
  never once per retry, never the only signal; it never throws.

### Icons and images

- **Lucide** (`TaytayIcons.*`, vendored font) for interface icons, drawn through `TaytayIcon`
  (requires `semanticLabel`) or inside a shared widget (`SettingsRow(icon:)`,
  `IconTile.lucide`, `HeaderIconButton`).
- **Solid SVG glyphs** (`TaytayGlyph.*`, the design's `icons/`, in `assets/icons/`) for gradient
  tiles and the design's solid marks: `IconTile.glyph`, `GlyphIcon`, `FeedRow(placeholderGlyph:)`,
  `PillAction(glyph:)`. Name a glyph, never a path.
- **Illustrations** (`TaytayIllustration.noResults`, `.offline`): `EmptyState`, `ErrorState`,
  `IllustrationArt`.
- Feature code does not use Material `Icons.*`.
- **Photos:** bundled ones in `assets/photos/` (credited in `docs/frontend/PHOTO_CREDITS.md` and on
  "Photo credits & about"); API photos through `RemoteImage` (a URL) or `MediaBytesHost` +
  `DecodedMemoryImage` (a media id). A photo the API does not send is not drawn.

### The theme — `AppTheme.light()`

Material 3, built from the tokens: app bar (a solid blue fallback; screens use `BlueHeader`), card
(radius 20, flat), filled button (blue, 52, radius 16, 14/600), outlined and tonal buttons (soft:
blue on `blue50`, no border), text button, chips, filled input decoration (54, `softFill`, radius
14, focus ring, error fill), list tile, divider, navigation bar (80, labels 11), dialog (centred,
radius 22, flat — every gate, notice, confirmation and decision), bottom sheet (radius 28 top, drag handle,
flat — pickers only, rule 3), snack bar, popup menu, progress indicator.
`TaytayButtonStyles.soft()`, `.gold()` and `.compact()` give the same looks to a one-off
`FilledButton`. The root applies `AppTheme.applyAccessibilityMediaQuery`, which clamps the OS text
scale to 0.85–2.0.

---

## 3. Shared widgets (`lib/shared/widgets/`)

Each widget takes its data as parameters, draws no shadow, and reads tokens only. "In the gallery"
means it has a specimen in `SharedWidgetsGallerySection` or the gallery screen. Parameters marked
`*` are required.

### Headers and page frames

**`BlueHeader`** (`blue_header.dart`, in the gallery) — the blue gradient header of every in-app
screen, with the two circles and the rounded bottom. Use it for tabs (`leading: HeaderSeal()`,
20/700 title) and for pushed pages (`showBack: true`, 15/600 title). `bottom:` holds a search
field, chips or a greeting. On a glass tab pass `overlap: true` and pull the body up with
`GlassOverlap`.
Params: `title`, `subtitle`, `titleWidget`, `leading`, `showBack = false`, `onBack`,
`backEnabled = true`, `actions = []`, `bottom`, `overlap = false`, `includeSafeArea = true`.

```dart
BlueHeader(
  title: 'Directory',
  subtitle: 'Bayan ng Taytay · Rizal',
  leading: const HeaderSeal(),
  actions: <Widget>[
    HeaderIconButton(
      icon: TaytayIcons.bell,
      semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      badgeCount: unread, // from the API only
      onPressed: onBell,
    ),
  ],
  bottom: HeaderSearchField(hint: 'Search offices', onChanged: onSearch),
)
```

**`HeaderSeal`** — the official seal in its white circle. `HeaderSeal({diameter = 38})`.
`const HeaderSeal()`.

**`HeaderIconButton`** — a 44 px translucent disc in a 48 dp target on the header, with an
optional red count. Params: `icon*`, `semanticLabel*`, `onPressed*`, `badgeCount`, `visualKey`.
Put the count in `semanticLabel` too; a count comes from the API, never a constant.

**`HeaderSearchField`** (`header_search_field.dart`, in the gallery) — the white 54 px search field
on the blue header, with a gold focus ring. Params: `hint*`, `controller`, `onChanged`,
`fieldKey`. Goes in `BlueHeader(bottom:)`.
`HeaderSearchField(hint: 'Search services', controller: _query, onChanged: _filter)`

**`HeaderChoiceChip`** (`pills.dart`, in the gallery) — a filter chip on the blue header (white
when selected, white outline otherwise), 36 tall in a 48 target, announced as a selected button.
Params: `label*`, `selected*`, `onTap`.
`HeaderChoiceChip(label: chip.label, selected: chip == _chip, onTap: () => _select(chip))`

**`WaveHeader`** (`wave_header.dart`, in the gallery) — the playful header of sign-in,
registration and every form flow: gradient, floating shapes, three-layer wave, white page below.
Params: `title`, `subtitle`, `showBack = false`, `onBack`, `backEnabled = true`, `stepLabel`,
`progress` (0–1), `progressSemanticLabel`, `trailing`, `badge`, `eyebrow`, `centered = false`,
`includeSafeArea = true`. Usually reached through `AuthFormPage`; a notice uses
`WaveHeader(centered: true, badge: IconTile.lucide(…, tileSize: IconTileSize.large))`. A centred
title block is inset `WaveHeaderShapes.centeredTextInset` on both sides, so a long subtitle never
runs over the decorative dot field (`WaveHeader.dotFieldKey`) and stays centred (D-199).

**`AuthFormPage`** (`form_page.dart`) — the form / step page: `WaveHeader` over a white page, the
form scrolling under it (the header scrolls too, so 200% text never squeezes the fields), the
actions in a pinned footer. Params: `child*`, `title`, `subtitle`, `eyebrow`, `showBack = true`,
`onBack`, `backEnabled = true`, `stepLabel`, `progress`, `progressSemanticLabel`, `footer`,
`pageKey`.

```dart
AuthFormPage(
  title: 'Your details',
  subtitle: 'As printed on your ID',
  stepLabel: 'Step 1 of 6',
  progress: 1 / 6,
  progressSemanticLabel: 'Step 1 of 6',
  footer: PrimaryButton(label: 'Continue', onPressed: _valid ? _next : null),
  child: Column(children: <Widget>[
    AuthField(label: 'First name', controller: _first, requiredField: true, error: _firstError),
    const SizedBox(height: Spacing.formGap),
    AuthField(label: 'Mobile number', controller: _mobile, keyboardType: TextInputType.phone),
  ]),
)
```

**`AuthField`** — a labelled filled field (label above, 54 px filled field, optional leading
icon and trailing control, error or hint below). Params: `label*`, `controller*`,
`requiredField = false`, `icon`, `error`, `hint`, `placeholder`, `obscure = false`,
`readOnly = false`, `enabled = true`, `trailing`, `onTap`, `onChanged`, `keyboardType`,
`textInputAction`, `autofillHints`, `inputFormatters`, `fieldKey`. In the gallery. A server
validation message may be shown as `error` (Article 5.5); nothing else from the server is.

**`AuthFieldLabel`** — `AuthFieldLabel('Barangay', requiredField: true)`: 12.5/600 with a red
asterisk. **`AuthLink`** — `AuthLink('Forgot password?', onPressed: _forgot, muted: false,
alignment: Alignment.center)`: an underlined 13.5/600 text action in a 48 dp target.
**`AuthBrandRow`** — `const AuthBrandRow()`: sign-in's seal and brand line, for
`AuthFormPage(eyebrow:)`.

**`SoftPage`** (`soft_page.dart`) — a page reached from a list (settings, security, privacy):
`BlueHeader` with back over the `#F4F6FA` page, children in a scrolling column with the 16 px
gutter. Params: `title*`, `children*`, `subtitle`, `onBack`, `actions = []`,
`offlineBanner = false` (pass `true` outside the tab shell), `scrollKey`, `footer`.
`SoftPage(title: 'Settings', offlineBanner: true, children: <Widget>[...])`

**`DetailHero`, `DetailSheet`, `DetailFactRow`** (`detail_page.dart`, in the gallery) — the
Office detail page. `DetailHero({photo*, onBack, credit})`: the 250 px photo
(`DetailHero.photoHeight`) with a navy scrim, translucent back, seal and an optional credit pill.
`DetailSheet({children*})`: the white sheet with 28 px top corners and 22/20 padding.
`DetailFactRow({icon*, label*, value*, trailing, onTap, tapKey, divider = true})`: a 36 px soft
square, the label over the value, a hairline; with `onTap` it is one button reading "label,
value".

```dart
ListView(
  addRepaintBoundaries: false, // GlassOverlap's raised part must take taps
  addSemanticIndexes: false,
  children: <Widget>[
    DetailHero(photo: RemoteImage(url: office.heroUrl), credit: credit),
    GlassOverlap(
      amount: Radii.sheetLarge,
      child: DetailSheet(children: <Widget>[
        Text(office.name, style: AppTypography.pageTitle.copyWith(color: BrandColors.ink)),
        const SizedBox(height: Spacing.formGap),
        PillButtonRow(actions: actions),
        for (final fact in office.facts)
          DetailFactRow(icon: _icon(fact), label: fact.label, value: fact.value),
      ]),
    ),
  ],
)
```

With no photo, use `BlueHeader(showBack: true)` and the `DetailSheet` on white.

**`GlassBackground`, `GlassOverlap`** (`surface_cards.dart`) — `GlassBackground({child*})` paints
`#EEF2FA` with the three soft blobs behind a main tab. `GlassOverlap({child*, amount = 32})`
paints its child `amount` higher (the CSS `margin-top: -32px`) and still hit-tests the raised
part — inside a `ListView` pass `addRepaintBoundaries: false, addSemanticIndexes: false`, or the
raised strip takes no taps.

**`TaytayBackButton`** (`taytay_back_button.dart`) — the back control of every non-root route: a
44 dp circle in a 48 dp target; by default it pops, or goes home when it cannot. Params:
`onPressed`, `light = false`, `translucent = false` (the 14% white disc on a blue header),
`enabled = true`. Headers draw it for you (`showBack: true`).

### Surfaces and cards

**`SoftCard`** (`surface_cards.dart`, in the gallery) — the everyday card: white, no border,
radius 20. On a white page pass `filled: true` for the `#F4F6FA` fill. Params: `child*`,
`padding = 16`, `filled = false`, `radius = Radii.card`, `onTap`, `semanticLabel`.
`SoftCard(onTap: open, semanticLabel: '${item.title}, ${item.status}', child: ...)`

**`GlassCard`** (`surface_cards.dart`, in the gallery) — the frosted card of the main tabs only
(Home, Balita, Account, ID), on a `GlassBackground`. Params: `child*`, `padding = 16`,
`pinned = false` (gold tint), `radius = Radii.cardLarge`, `onTap`, `semanticLabel`.
`GlassCard(child: Column(children: rows))`

**`SettingsList`** and its rows (`settings_list.dart`, in the gallery) — the Account list: one
card of rows with a hairline that starts after the icon.
- `SettingsList({children*, glass = false})` — soft card, or glass on a main tab.
- `SettingsRow({title*, detail, icon, tone = SettingsTone.blue, iconFill, iconInk, leading,
  trailing, showChevron = true, badgeCount, progress, destructive = false, onTap, semanticLabel,
  titleMaxLines, detailMaxLines, detailStyle})` — at least 64 tall, a 40 px icon square, chevron
  when tappable, `badgeCount` as a red count, `progress` as a bar, `destructive` in red. A
  tappable row reads "title, detail[, N new]" as one label.
- `SettingsSwitchRow({title*, value*, onChanged*, detail, icon, tone, iconFill, iconInk})` — a
  styled `SwitchListTile`.
- `SettingsSectionTitle(title, {onHeader = false})` — the 15/600 heading above a list, announced
  as a heading. `SettingsIcon({icon*, tone, fill, ink})`, `SettingsDivider()`,
  `CountBadge({count*})` (decorative; the row says the count), `SettingsTone { blue, green, gold,
  red }`.

```dart
const SettingsSectionTitle('Privacy'),
SettingsList(children: <Widget>[
  SettingsRow(icon: TaytayIcons.fileText, title: 'Privacy notice',
      detail: 'What Taytay LGU holds, and your rights', onTap: openNotice),
  SettingsSwitchRow(icon: TaytayIcons.bell, title: 'Balita & advisories',
      value: on, onChanged: setOn),
  SettingsRow(icon: TaytayIcons.logOut, title: 'Sign out', destructive: true,
      showChevron: false, onTap: signOut),
]),
```

**`SoftNote`** (`soft_note.dart`, in the gallery) — every inline notice inside a page: a tinted
rounded box with a per-tone icon (colour is never the only signal), a live region by default.
Params: `message*`, `title` (runs into the message — end it with ". "), `heading` (a bold line of
its own above the message — a note whose title is a statement, or when a test or rule needs title
and message as separate texts), `tone = NoteTone.info` (`info`, `warning`, `error`, `success`,
`emergency` — red with a siren, read as "Emergency": call a hotline, do not wait), `action` (one
control under the message, inside the note, keeping its own semantics — a `PillButtonRow`, a
button), `live = true` (pass false for a note that is part of the page rather than news),
`focusNode` (an error summary). The gallery shows a heading with an action (D-203).
`SoftNote(tone: NoteTone.warning, heading: 'Check your name', message: NameCheckCopy.asPrinted)`

```dart
SoftNote(
  tone: NoteTone.emergency,
  heading: MessageSentCopy.emergencyHeading,
  message: MessageSentCopy.emergency,
  live: false,
  action: PillButtonRow(wrap: true, padding: EdgeInsets.zero, actions: <PillAction>[
    PillAction(label: 'See emergency hotlines', glyph: TaytayGlyph.phone, danger: true, onPressed: openHotlines),
  ]),
)
```

**`NoticePanel`, `NoticePoint`, `DraftPill`** (`notice_panel.dart`, in the gallery) — the RegTerms
summary: a gradient icon, title, source line, optional badge, intro and titled points.
`NoticePanel({title*, icon*, subtitle, badge, intro, points = [], footer, onWhite = true})`;
`NoticePoint({title*, body*, trailing, suffix = ''})`; `DraftPill(label)` marks text the LGU has
not approved.

```dart
NoticePanel(
  icon: TaytayIcons.shieldCheck,
  title: 'Privacy Notice',
  subtitle: 'Taytay LGU',
  badge: published ? null : const DraftPill('Draft'),
  points: <NoticePoint>[for (final p in points) NoticePoint(title: p.title, body: p.body)],
)
```

**`ConsentCheckCard`** (`consent_check_card.dart`, in the gallery) — a consent tick on a card;
ticked, it turns soft blue. Params: `value*`, `onChanged*`, `label*`, `description`. The screen
keeps Continue disabled until it is ticked.
`ConsentCheckCard(value: _agreed, onChanged: (v) => setState(() => _agreed = v), label: terms.label)`

**`UploadSlot`, `AttachedFileCard`** (`upload_slot.dart`, in the gallery) — RegID's file slots.
`UploadSlot({label*, onPressed*, error = false})`: a dashed empty slot, one button.
`AttachedFileCard({title*, status*, icon = TaytayIcons.fileText, actionLabel, onAction,
actionKey})`: a chosen file with a green check and one text action. Neither draws the file
itself (a privacy choice).

**`DashedOutline`** (`dashed_outline.dart`) — the 2 px dashed rounded outline Flutter's `Border`
cannot draw, as a `CustomPainter`: `UploadSlot`'s outline and the ID tab's card that is not
issued yet (D-207). `DashedOutline({colour*, radius = Radii.lg})`, passed as
`CustomPaint(painter: …)` behind the content. Seen in the gallery through `UploadSlot`.

### Rows, lists and timelines

**`FeedRow`** (`feed_row.dart`, in the gallery) — one story in a list: category line, bold title,
date, a 76 px thumbnail on the right. Params: `title*`, `category` (upper-cased by the caller),
`categoryTone = CategoryTone.blue` (`blue`, `green`, `gold`, `red`, `neutral`), `dateLabel`
(pre-formatted, `ManilaTime.formatDate`), `thumbnail` (the caller's `RemoteImage`),
`placeholderGlyph`, `onTap`, `divider = false`, `titleMaxLines`. Rows sit in a card with
horizontal padding 16 and `divider: index > 0`.
`FeedRow(title: a.title, category: a.category.toUpperCase(), dateLabel: date, divider: i > 0, onTap: () => open(a))`

**`Timeline`, `TimelineStep`** (`s3_surface.dart`) — numbered step discs (green done, blue current,
gold in hand, hollow upcoming) with the step in words. `Timeline({steps*})`,
`TimelineStep({icon*, title*, tone*, detail = '', onTap})`, `TimelineTone { done, current,
upcoming, navy }`.

### Actions

**`PrimaryButton`, `SecondaryButton`, `GoldButton`** (`taytay_buttons.dart`, in the gallery) — the
52 px buttons: filled blue, soft (blue on `blue50`, no border), gold with a navy label. Params:
`label*`, `onPressed*` (null disables), `kind`, `icon`, `expand = true`.
`PrimaryButton(label: 'Send request', onPressed: _canSend ? _send : null)`

**`AppButton`** (`app_button.dart`) — the same buttons with role variants, a loading state and a
declared haptic. Params: `label*`, `onPressed*`, `variant = AppButtonVariant.primary`
(`primary`, `secondary`, `text`, `danger`), `kind`, `icon`, `iconTrailing = false`,
`loading = false`, `fullWidth = true`, `hapticIntent = HapticIntent.selection`, `semanticLabel`.
`AppButton(label: 'Give up my place', variant: AppButtonVariant.danger, hapticIntent: HapticIntent.warning, onPressed: cancel)`

**`PillButtonRow`, `PillAction`** (`pill_button_row.dart`, in the gallery) — the detail page's 40
px pills in 48 px targets, soft blue, the first usually solid. Scrolls sideways, or wraps with
`wrap: true`. `PillButtonRow({actions*, padding = h20, wrap = false})`;
`PillAction({label*, onPressed*, glyph, primary = false, danger = false, semanticLabel,
buttonKey})`.
`PillButtonRow(wrap: true, actions: <PillAction>[PillAction(label: 'Call', glyph: TaytayGlyph.phone, primary: true, onPressed: call)])`

**`SoftChoiceChip`** (`pills.dart`, in the gallery) — a filter chip on a soft page: solid blue
when in force, grey otherwise, 36 in a 48 target. Params: `label*`, `selected*`, `onTap`.
**`StatusPill`** — a status in words on a pill; colour only repeats it. `StatusPill({label*,
tone = PillTone.blue})`, `PillTone { blue, green, gold, red, neutral }`.
`StatusPill(label: request.statusLabel, tone: _toneOf(request.status))`

**`StateActionButton`** (`error_state.dart`) — the round 46 px button of an illustrated state.
`StateActionButton({label*, onPressed*, primary = false, icon})`. `EmptyState` / `ErrorState`
draw it for you.

### Icons, tiles and images

**`IconTile`** (`icon_tile.dart`, in the gallery) — the gradient tile behind an icon.
`IconTile.glyph({glyph*, tone = TileTone.blue, tileSize = IconTileSize.medium, semanticLabel})`
for the solid SVGs; `IconTile.lucide({icon*, tone, tileSize, semanticLabel})` for a Lucide icon.
`IconTileSize { small (36), medium (44), large (56) }`. The plain `IconTile({icon*, fill*,
ink*, size = 40, iconSize, radius})` is the pre-redesign disc, kept for compatibility; new code
uses the named constructors.
`IconTile.glyph(glyph: TaytayGlyph.siren, tone: TileTone.red)`

**`GlyphIcon`** (`taytay_glyph.dart`) — one solid glyph in one colour, decorative by default.
`GlyphIcon(glyph, {size = 22, color, semanticLabel})`. **`IllustrationArt`** —
`IllustrationArt(TaytayIllustration.noResults, {width})`, always decorative.

**`TaytayIcon`** (`taytay_icon.dart`) — a Lucide glyph with a **required** label.
`TaytayIcon({icon*, semanticLabel*, size = 24, color, excludeSemantics = false})`.
`TaytayIcon(icon: TaytayIcons.mapPin, semanticLabel: 'Location', color: BrandColors.blue)`

**`RemoteImage`** (`remote_image.dart`) — a picture the LGU published, decoded at its drawn size,
with a placeholder and an error mark. `RemoteImage({url*, fit = BoxFit.cover, semanticLabel,
maxDecodeWidth, placeholderIcon, errorIcon, showProgress = false})`.
**`MediaBytesHost`, `DecodedMemoryImage`** (`media_bytes_image.dart`) — `GET /…/{id}` bytes
behind the bearer: `MediaBytesHost({id*, builder*, load, enabled = true})` asks once and hands the
bytes (or null) to `builder`; `DecodedMemoryImage({bytes*, placeholder*, fit, alignment,
semanticLabel, height, maxDecodeWidth, keepInImageCache})` draws them.

**`PhotoCarousel`, `CarouselPhoto`** (`photo_carousel.dart`, in the gallery) — swipeable photos
with dots. `PhotoCarousel({photos*, height = 250, viewportFraction = 1, radius = 24, onTap,
onPageChanged, overlayBuilder})`; `CarouselPhoto.url(url, {semanticLabel})`,
`CarouselPhoto.provider(provider, {semanticLabel})`.

**`StatusLine`** (`status_line.dart`, in the gallery) — "**Open** · Closes 5:00 PM" from
structured hours on the Manila clock. `StatusLine({hours*, now*, compact = false, labels})`,
`WeeklyHours(Map<int, DayHours>)`, `DayHours.of(8, 0, 17, 0)`. **The API sends no structured
hours yet: pass `hours: null` and it draws nothing.** Never parse free-text hours.

### Data states

**`LoadingSkeleton`** (`loading_skeleton.dart`, in the gallery) — grey blocks shaped like what is
coming; the shimmer stops under reduced motion. `LoadingSkeleton({layout = SkeletonLayout.list,
count = 3, semanticLabel = 'Loading'})`, `SkeletonLayout { list, feed, cards, detail, text, photo }`
(`text`: `count` lines of a paragraph — a notice or a short list loading in a dialog or a picker;
`photo`: one `ComponentSizes.skeletonPhoto` block — a photo opening in a dialog). A dialog or a
sheet that loads shows a skeleton too, never a lone spinner.
`SkeletonBlock({width, height = 16, radius = Radii.md})` (`taytay_states.dart`) is one block.

**`EmptyState`** (`taytay_states.dart`, in the gallery) — nothing to show, with the illustration.
`EmptyState({title*, message*, actionLabel, onAction, illustration =
TaytayIllustration.noResults, boxed = false, primaryAction = false, actionIcon, actionKey})`.
`EmptyState(title: 'No offices found', message: 'Try another word, or browse by category.', actionLabel: 'Browse all offices', onAction: clear)`

**`ErrorState`** (`error_state.dart`, in the gallery) — a load failed: what failed, what to do,
and **Try again** when trying again could work. `ErrorState({title*, message, onRetry,
retryLabel = 'Try again', offline = false, icon, boxed = false, details = []})`.
`StatePanel({art*, title*, message, action, details = [], boxed = false})` is the shared layout.

**`FailureView`** (`failure_view.dart`) — the one way an `AppFailure` is shown: the app's own copy
for the failure kind, never the server's `message`, and the request id when there is one. Draws
`ErrorState` (offline for network and timeout failures).
`FailureView(failure: failure, environment: config.environment, onRetry: _load)`

**`OfflineError`** — `OfflineError(onRetry: _load)`: `ErrorState` with the offline illustration.

**`OfflineBanner`, `OfflineNotice`** (`network_status_views.dart`; `OfflineNotice` is in the
gallery) —
`OfflineBanner({onRetry})` shows itself from the network monitor when requests are not arriving
(never over a server refusal), and draws nothing without an `AppDependenciesScope` above it.
The tab shell already draws one; a full-screen route puts `const OfflineBanner()` under its
header (or `SoftPage(offlineBanner: true)`). `OfflineNotice({title*, message, onRetry,
retryLabel})` is the gold strip itself.

**`StaleContentNotice`, `UnsentNotice`** — `StaleContentNotice({storedAt*, isFresh = false,
onRefresh})` says how old cached content is; `UnsentNotice({what*, resendIsSafe = false,
onRetry, retryLabel})` marks work the office has not received.

**`StatusView`** (`status_view.dart`) and **`CapabilityGate`** (`capability_gate.dart`) —
`CapabilityGate({capability*, child*, intent, targetId})` shows `child` when the resident's
session may use `capability` and a `CapabilityLockedView` (drawn with `StatusView`: large
gradient tile, title, body) with the way forward when not. It decides what to *show*; the server
decides what is allowed.
`CapabilityGate(capability: ResidentCapability.viewHouseholdSummary, child: body)`

### Messaging

**`ConversationBubble`, `ConversationDayChip`, `ConversationComposer`,
`ConversationRoundButton`** (`conversation.dart`) — the Conversation screen.
`ConversationBubble({body*, meta*, mine*, attachments = []})`: blue on the right for the
resident, white on the left for the office, at most 82% wide. `ConversationDayChip(label)`.
`ConversationComposer({controller, onAttach, onSend, sendEnabled = true, attachmentLabel,
onClearAttachment, hint = 'Write a message…', attachKey, sendKey, fieldKey, clearKey})`.
`ConversationRoundButton({icon*, semanticLabel*, onPressed*, solid = false, gestureKey})`.
**`MessageField`** (`message_field.dart`) — the compose page's labelled message box:
`MessageField({controller, preview = '', fieldKey})`. Not in the gallery; see the Conversation
frames in `account_canvas.dart` and `directory_canvas.dart`.

### Results

**`SuccessScreen`, `SuccessMark`, `SuccessDetail`** (`success_screen.dart`, in the gallery) — the
result step of a form flow: a centred wave header with the mark, the title and message, a receipt
of details, the next actions. `SuccessScreen({title*, primaryLabel*, onPrimary*, message,
details = [], note, body, secondaryLabel, onSecondary, mark = SuccessMarkStyle.badge (`badge` =
MessageSent, `medal` = RegDone), stepLabel, progress, progressSemanticLabel, showBack = false,
onBack})`; `SuccessDetail({label*, value*})`. It fills its parent; as its own route wrap it in a
`Scaffold` and pass `showBack: true`.

```dart
Scaffold(
  body: SuccessScreen(
    mark: SuccessMarkStyle.medal,
    title: 'Request sent',
    message: 'You will get a notification in this app when the office replies.',
    details: <SuccessDetail>[SuccessDetail(label: 'Reference', value: request.reference)],
    primaryLabel: 'View my requests',
    onPrimary: openRequests,
    showBack: true,
  ),
)
```

### Dialogs, sheets and feedback

Every gate, notice, confirmation and decision is a centred dialog opened through **`AppDialog`**;
only a picker is a bottom sheet, through **`AppSheet`** (rule 3, D-197, D-202). Nothing else in
`lib/` calls `showDialog`, `showModalBottomSheet` or `showGeneralDialog`: the design guard fails
the build on it.

- **`AppDialog.show<T>({context*, title*, builder*, actions, icon, scrollable = true, dismissible
  = true, useRootNavigator = true})`** → `Future<T?>` — the theme's dialog (centred, radius 22,
  flat), inset `AppDialog.panelInset` (20 / 24), at most `ComponentSizes.dialogMaxWidth` (480)
  wide. It draws, top to bottom: the hero `icon` if given (the title then centres), the **title —
  a heading that names the route**, so a screen reader says what opened — the content, then the
  actions. `actions: (dialogContext) => AppDialogActions(…)` builds the buttons from the dialog's
  own context, so a button can pop it. **`scrollable`** (the default) puts title, content and
  actions in one scroll view, so 200% text on a 360 dp phone scrolls and never clips;
  `scrollable: false` is for content that scrolls itself (the legal text's list): the content
  takes the height between the title and the actions, which stay in view. A field inside rises
  above the keyboard. Focus moves into the dialog, Tab stays inside it, and focus returns to the
  opener when it closes.
- **`AppDialogActions({primary, secondary, text})`**, with **`DialogButton({label*, onPressed*,
  destructive = false, icon, loading = false, hapticIntent = HapticIntent.selection, key})`** —
  the one way a dialog's buttons are drawn: the primary button (danger when `destructive`), an
  optional soft secondary for a second way forward (the sign-in gate's "Create account"), then the
  text button — Cancel, Close, Not now, Keep browsing — stacked, full width, each at least 48 dp.
  **`AppDialogActions.close(dialogContext, {label = 'Close', closeKey})`** is a notice's only way
  out. Content whose buttons follow its own state (a form, a step that changes) draws
  `AppDialogActions` as its last child instead of using the slot; it looks the same. Every dialog
  that asks for something has a Cancel.
- **`AppDialog.confirm({context*, title*, message*, confirmLabel = 'Confirm', cancelLabel =
  'Cancel', destructive = false})`** → `Future<bool?>` and **`AppDialog.acknowledge({context*,
  title*, message*, actionLabel = 'OK'})`** — `show` with the message (`AppDialogMessage`) and the
  actions filled in: confirm over Cancel, or the one text action. A destructive confirmation is
  not dismissed by a scrim tap and fires a warning haptic.
- **`AppDialogPanel({title*, child*, actions, icon, scrollable = true})`** — the inside of a
  dialog, for a specimen (gallery, recording frame) that draws one inside a `Dialog` without
  opening a route.

```dart
final bool? confirmed = await AppDialog.confirm(
  context: context,
  title: 'Sign out of this device?',
  message: 'You will need a new one-time code to sign in again.',
  confirmLabel: 'Sign out',
);

await AppDialog.show<void>(
  context: context,
  title: label,
  builder: (dialog) => _AttachmentPhoto(load: load, label: label),
  actions: (dialog) => AppDialogActions.close(dialog),
);
```

- Wrappers that open an `AppDialog`, names kept for their callers: **`ConfirmSheet.show({context*,
  title*, consequence*, confirmLabel*, detail, isDestructive = true, cancelLabel = 'Keep it as it
  is'})`** → `Future<bool>`; **`AccessGateSheet.show(...)` / `.showForCapability(...)`** explains
  why an action needs an account or verification (the verification gate is `UnverifiedGateSheet`
  as the content, its lock tile as the hero icon, and says only that the account is not verified
  yet, D-201); **`SessionExpiredSheet.show(context)`**; **`showLegalTextSheet({title*, markdown*,
  pending*})`** opens the Terms or Privacy Notice, not scrolling as a frame, with Close
  (`legalTextCloseKey`) always in view.
- **`AppSheet.show<T>({context*, title*, builder*, dismissible = true})`** — the modal bottom
  sheet (radius 24 top, at most 90% high, a title, the content scrolling), **for pickers only**: a
  list of choices the resident picks one from. Each choice is a **`PickerChoiceRow({rowKey*,
  label*, selected*, onTap*})`** (`app_sheet.dart`): at least 48 dp, a button in a group where one
  is selected, a tick on the chosen one.
- **`showBarangayPicker(context, {load*, selectedId})`** → `Future<Barangay?>`
  (`barangay_picker.dart`) — the one barangay picker, for sign-up and Edit profile:
  `BarangayPicker` in an `AppSheet`, a text skeleton while it loads, the failure in words with Try
  again, one `PickerChoiceRow` per barangay.
- **`Outcome.succeeded(context, message)` / `Outcome.problem(context, message)`** — says how
  something turned out on screen and to a screen reader. **`showTaytayToast(context, message)`**
  / `TaytayToast({message*})` — a short confirmation snack bar.
- App plumbing, not for screens: `SessionExpiryWatcher`, `IntentResumer`.

### Forms support (`form_support.dart`)

`FormErrorSummary({errors*, focusNode})` lists what is wrong on the step, above the fields.
`FieldLabel({label*, required = true, hint})` says required **or** optional. `WhyWeAsk({purpose*,
whoSeesIt*, ifYouDecline, title = 'Why we ask for this'})` explains a sensitive field.
`UploadGuidance({points*})` says what a good photo looks like before the picker opens.

### Kept for compatibility

`AppBanner` (restyled as a soft note; no feature uses it — use `SoftNote`), the plain `IconTile`,
`SampleTag` (marks a specimen in the gallery or a fact the LGU has not confirmed; never on real
data), and the `s3_surface.dart` re-exports used by the verification chrome.

---

## 4. Screen patterns

Every screen is one of these. The mock-ups are in `docs/design/mobile/screens/`; the golden is in
`test/goldens/design_system/`.

| Pattern | Mock-up(s) | Implemented by | Golden |
|---|---|---|---|
| Main tab (glass, blue header) | `Home`, `Balita`, `Account` | `home/presentation/home_canvas.dart`; `news/presentation/balita_canvas.dart` | `pattern_main_tab.png` |
| List + search + filters | `Directory`, `DirectorySearch` | `directory/presentation/directory_canvas.dart` (`DirectoryFrame.list`); `tulong/presentation/tulong_canvas.dart` | `pattern_list_search.png` |
| Detail (photo + white sheet + pills) | `Office` | `directory_canvas.dart` (`DirectoryFrame.detail`); `events/presentation/event_detail_screen.dart` | `pattern_detail.png` |
| Form / step flow (wave header, filled fields) | `SignIn`, `RegDetails`, `RegEmail`, `RegTerms`, `RegID`, `RegSelfie`, `RegReview` | `auth/presentation/sign_in_screen.dart`, `account_wizard_screen.dart`; `issuance/presentation/issuance_request_form_screen.dart` | `pattern_form.png` |
| Settings / profile list | `Account` | `settings/presentation/settings_screen.dart` (`SoftPage` + `SettingsList`); `account/presentation/account_canvas.dart` (`AccountFrame.settings`) | `pattern_settings_list.png` |
| Success | `MessageSent`, `RegDone` | `directory_canvas.dart` (`DirectoryFrame.sent`); the issuance and event results | `pattern_success.png` |
| Notice / consent / blocked | `RegTerms`, `DirectoryOffline` | `platform/presentation/blocking_notice_screen.dart`, `consent_update_screen.dart`; `auth/presentation/app_lock_screen.dart`, `too_many_attempts_screen.dart` | `pattern_notice.png` |
| Card | `DigitalID` | `credential/presentation/digital_id_canvas.dart` (`DigitalIdView`) | `pattern_card.png` (+ `test/goldens/digital_id/`) |
| Splash / onboarding | `Main` | `splash/presentation/splash_screen.dart`; `onboarding/presentation/welcome_scene.dart` | `pattern_splash.png` (+ `test/goldens/welcome/`) |
| Messaging | `NewMessage`, `Conversation` | `account/presentation/account_canvas.dart` (`AccountFrame.thread`, routed by `AccountThreadScreen`); `directory_canvas.dart` (`DirectoryFrame.compose`) | `pattern_messaging.png` |

Paths are under `lib/features/`. The bottom navigation is `BottomNav.dc.html`, built as
`shell/presentation/shell_tab_bar.dart`.

**Screen and canvas.** Most screens are split in two: a stateful *screen* that reads
`AppDependencies.of(context)`, owns the controller and picks a frame (`BalitaFrame.loading`,
`.failed`, `.emptyFeed`, `.feed`…), and a stateless *canvas* that draws a frame from parameters
(`BalitaCanvas`, `DirectoryCanvas`, `AccountCanvas`, `HomeCanvas`, `DigitalIdView`). The canvas is
what the layout tests and goldens pump with synthetic data; keep that split in a new screen.

### Skeletons

Each skeleton is the shape, not a complete screen: data, controllers and routes are the
feature's own.

**Main tab** — glass page, overlapping header, glass cards 14 apart.

```dart
GlassBackground(
  child: ListView(
    addRepaintBoundaries: false,
    addSemanticIndexes: false,
    padding: const EdgeInsets.only(bottom: Spacing.xl),
    children: <Widget>[
      BlueHeader(overlap: true, leading: const HeaderSeal(), title: greeting, actions: bell),
      GlassOverlap(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(children: <Widget>[
            GlassCard(child: first),
            const SizedBox(height: Spacing.section),
            GlassCard(child: second),
          ]),
        ),
      ),
    ],
  ),
)
```

**List + search + filters** — header with search and chips, rows in one card, the four states.

```dart
Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
  BlueHeader(
    title: 'Services',
    showBack: true,
    bottom: Column(children: <Widget>[
      HeaderSearchField(hint: 'Search services', onChanged: onSearch),
      const SizedBox(height: Spacing.md),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: chips)),
    ]),
  ),
  Expanded(
    child: switch (frame) {
      Frame.loading => const LoadingSkeleton(),
      Frame.failed => FailureView(failure: failure, environment: env, onRetry: reload),
      Frame.empty => EmptyState(title: 'No services found', message: tryAnother),
      Frame.list => ListView(padding: const EdgeInsets.all(Spacing.lg), children: <Widget>[
          SettingsList(children: <Widget>[for (final s in items) SettingsRow(...)]),
        ]),
    },
  ),
])
```

**Detail** — see `DetailHero` / `DetailSheet` above: photo, sheet over it, title, `StatusLine`
(only with structured hours), `PillButtonRow`, `DetailFactRow`s. No photo: `BlueHeader(showBack:
true)` + `DetailSheet` on white.

**Form / step flow** — `AuthFormPage` with `AuthField`s 18 apart, `SoftNote` for anything the
resident must know before acting, one primary action in the footer (disabled until valid), and
`SoftCard(filled: true)` for grouped content on the white page.

**Settings / profile list** — `SoftPage(title:, offlineBanner: true, children: [SettingsSectionTitle,
SettingsList([SettingsRow…]), SizedBox(height: Spacing.xl), …])`; on the glass My Account tab use
`SettingsList(glass: true)`.

**Success** — `Scaffold(body: SuccessScreen(...))`, the result step of the flow; it says what the
app will do next, never a promise the API does not make.

**Notice / consent / blocked** — no back control when the resident cannot go anywhere else
(`blocking_notice_screen.dart`):

```dart
Scaffold(
  backgroundColor: BrandColors.white,
  body: SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
      WaveHeader(
        centered: true,
        title: title,
        badge: const IconTile.lucide(
          icon: TaytayIcons.settings,
          tone: TileTone.gold,
          tileSize: IconTileSize.large,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.formGutter, Spacing.sm, Spacing.formGutter, Spacing.xl,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text(body, style: AppTypography.bodyStyle.copyWith(color: BrandColors.text)),
          const SizedBox(height: Spacing.formGap),
          SoftCard(filled: true, child: supportLines), // only when the LGU lists support
        ]),
      ),
    ]),
  ),
)
```

A consent update is `AuthFormPage(showBack: false)` with `NoticePanel` and `ConsentCheckCard`,
and the ways on in the footer.

**Card** — `DigitalIdView(now:, card:, name:, loading:, failure:, onRetry:)` on the glass tab.
The card is capped at 420 wide and grows with its text; it draws "Not yet issued" only after the
read has answered.

**Splash / onboarding** — the header gradient full screen, the seal (`HeaderSeal(diameter: 96)`),
the product name in `hero`, a gold progress line. Onboarding is `welcome_scene.dart`
(`WelcomeShapes`).

**Messaging** — `BlueHeader(showBack: true)`, `ConversationDayChip` and `ConversationBubble`s in a
scrolling list, `ConversationComposer` pinned under it; the compose page is a `MessageField` with
a topic and an attachment slot, then `SuccessScreen` (MessageSent).

---

## 5. The four data states

Every screen that reads data draws all four. A loading screen never says "nothing here".

| State | When | Widgets |
|---|---|---|
| Loading | The first read has not answered | `LoadingSkeleton(layout: …)` shaped like the content (never a lone spinner); a canvas usually takes `loading: true` |
| Empty | The read answered with nothing | `EmptyState` (`noResults` illustration): the title says what is empty, the sentence what to do. A search with no match and a list that is empty are worded apart |
| Error | The read failed | `FailureView(failure:, environment:, onRetry:)` for an `AppFailure`, or `ErrorState(onRetry:)`; **Try again** reloads. Never the server's message |
| Offline | Requests are not arriving | Saved data stays on screen with `OfflineBanner` above it (the tab shell draws it; full-screen routes add `const OfflineBanner()` or `SoftPage(offlineBanner: true)`); with no saved data, `FailureView` draws the offline `ErrorState`. `StaleContentNotice` says how old saved data is. Nothing is queued or promised |

---

## 6. The layout matrix

`test/support/layout_matrix.dart` holds every screen to the phones residents use:

```dart
testWidgets('the services list fits every phone', (tester) async {
  await expectCleanLayouts(
    tester,
    () => const ServicesCanvas(frame: ServicesFrame.list, items: _synthetic),
    scrollable: false, // the canvas fills the page and scrolls itself
    height: 1200,
  );
});
```

`expectCleanLayouts(tester, build, {height = 800, scrollable = true, widths = [360, 375, 430],
textScales = [1, 2], frames = 3})` pumps every width × text scale on the light theme and fails on
any `FlutterError` — a `RenderFlex` overflow included — naming the width and scale.
`layoutHost(child, {textScale = 1, scrollable = true})` is the host on its own. Run it for every
frame of a new or restyled screen (loading, empty, error, content).

A dialog is checked the same way once it is open: `expectCleanDialogLayouts(tester, build,
{trigger, host, height = 800, widths, textScales})` pumps `build()` (`dialogOpener((context) =>
…)` draws a page with one button that opens it; or pass a real screen and the `trigger` to tap),
opens the dialog at every width × scale, and fails on any `FlutterError`, on a bottom sheet, and
on a dialog surface that is not centred. `host` adds dependencies and a router where the dialog
needs them (`test/shared/centred_dialogs_test.dart` has one). Every caller of `AppDialog.confirm`
and `.acknowledge` is opened with its own words in `test/shared/dialog_callers_test.dart`; a new
caller adds its row there.

---

## 7. Goldens

`test/goldens/design_system_golden_test.dart` pins the gallery (`gallery_NN.png`, one per 844 px
page) and one screen per pattern (`pattern_*.png`), 390 × 844 at 3× with the bundled fonts,
synthetic data, no text scaling and animations off. The older goldens stay: components
(`component_golden_test.dart`), digital ID faces, welcome pages, the misconfigured-app screen.

A deliberate visual change regenerates them, after the rest of the suite passes:

```sh
flutter test --update-goldens test/goldens/
```

Then delete anything a failing run left in `test/goldens/failures/` (untracked) and say in the
commit body which goldens moved and why. A golden that moves when you did not mean to change
anything is a regression: fix the code, not the golden.

---

## 8. Rules

1. **Tokens and shared widgets only.** Feature code never hard-codes a colour (`Color(0x…)`,
   `Color.fromARGB`), a font size (`fontSize: 13`), a radius (`BorderRadius.circular(12)`,
   `Radius.circular(8)`) or a shadow (`BoxShadow`, `elevation:` above 0).
   `test/core/design_guard_test.dart` fails the build on each, naming the file and line; its
   allow-list is empty, and any entry needs a written reason. A value two screens need becomes a
   token in `lib/core/design/` or a shared widget in `lib/shared/widgets/` (with a gallery entry),
   never a second literal.
2. **No shadows or glows.** Flat surfaces, separated by fill and spacing. Focus rings are not
   shadows and stay visible.
3. **Popups are centred.** Every gate panel, notice, confirmation or decision is a centred
   dialog: `AppDialog.show`, `AppDialog.confirm` or `AppDialog.acknowledge` (or a wrapper above
   that opens one), with its buttons in `AppDialogActions`. **Only a picker — a list of choices the
   resident picks one from (a barangay, an ID type, a topic, where a file comes from, a date) — may
   be a bottom sheet**, through `AppSheet.show` with `PickerChoiceRow`s. A sheet that explains,
   warns, asks to confirm, or collects a decision is a dialog, whatever it holds. Today's sheets:
   the barangay picker (sign-up and Edit profile, `showBarangayPicker`), the sign-up and
   verification ID type pickers, the message topic picker, the file source picker (issuance), the
   conversation actions menu (Messages), and the gallery's specimen. Only `app_dialog.dart` and
   `app_sheet.dart` call `showDialog`, `showModalBottomSheet`, `showGeneralDialog`,
   `showCupertinoDialog` or `showCupertinoModalPopup`; `test/core/design_guard_test.dart` fails on
   any other call, naming the file and line (a date picker is a picker the theme centres, and is
   allowed). Test a new dialog with `expectCleanDialogLayouts` (§6).
4. **Real data only.** Names, messages, dates, counts and photos come from the API. Nothing from a
   mock-up's sample data reaches the app; no `SAMPLE` tag on real data. A design element whose
   field the API does not send is hidden, not faked, and the field is recorded as needed.
5. **The four data states** (§5) on every data screen.
6. **360 / 375 / 430 dp wide and 200% text** without clipping (§6). Layouts scroll; text never
   shrinks to fit. Tap targets stay at least 48 × 48 dp whatever the visible size.
7. **Privacy wins over a mock-up.** CLAUDE.md Article 5 decides what a screen may show: no server
   message, no cached personal data, no captured ID drawn back, the name check worded as the
   decision log says. Wording a test or a decision requires (warnings before an action, privacy
   statements) is restyled, never dropped.
8. **Accessibility is part of the look.** Every icon that means something has a label
   (`TaytayIcon` requires one); a tappable card or row reads as one sentence; colour is never the
   only signal (notes, pills and chips carry words or icons); motion uses `MotionTokens` and
   respects `Motion.reduced(context)`; haptics go through `AppHaptics` by intent.
9. **New screens pick a pattern** from §4 and start from its skeleton and its reference screen.

---

## 9. Known gaps

- **Spacing and box sizes are not guarded.** About 17 `EdgeInsets` and 88 `width:` / `height:`
  literals remain in feature code (mock-up offsets and one-off boxes). Use `Spacing` and
  `ComponentSizes` in new code; the guard reads colours, font sizes, shadows and radii only.
- **Legacy names.** The old `BrandColors` aliases, the old type roles and the woven / deep / verified
  gradients are still in `lib/core/design/`, pinned by contrast tests. New code does not use them.
- **API fields the design would need** (structured office hours, office category icon, Balita
  `featured` and Home thumbnails, unread counts on every bell, image credits, reply-time
  standard): the elements are hidden until the API sends them.
- **The gallery does not show** `SoftPage`, `AuthFormPage` or the conversation widgets; the
  Settings, Account and Directory screens (and their goldens) do. The theme section opens the
  panel dialog (`AppDialog.show`) and the picker sheet.
