---
description: Bring an existing resident screen in line with docs/design/DESIGN_SYSTEM.md without changing what it does
argument-hint: <screen file or feature, e.g. "lib/features/household/presentation/household_screen.dart">
---

# Restyle screen: $ARGUMENTS

Make the screen named above look like the rest of the app. **Presentation only**: every
controller, repository call, route, guard, validator, model, key and semantics label a test
reads stays as it is. Wording that a test or a decision requires (a warning before an action, a
privacy statement, the name check) is restyled, never dropped.

## 1. Read first

1. `CLAUDE.md` Article 5 (privacy) and Article 6 (Design).
2. `docs/design/DESIGN_SYSTEM.md` §2–§5 and §8.
3. The screen, its canvas if it has one, and every test that pumps it:
   `grep -rln "<ScreenClass>\|<CanvasClass>" test/` — note the keys, texts, semantics labels and
   sizes they assert before you move anything.
4. The pattern it belongs to (DESIGN_SYSTEM.md §4), the pattern's reference screen, and the
   mock-up's HTML (`docs/design/mobile/screens/`, read with grep or offset/limit; never copy its
   sample content).

## 2. Find what is off

Run these on the screen's files and fix each hit:

```sh
grep -nE "Color\(0x|Color\.from|fontSize:\s*[0-9.]|BoxShadow|elevation:\s*[1-9]|(Border)?Radius\.circular\(\s*[0-9.]" <files>
grep -nE "\bIcons\.|AppBar\(|AppBanner\(|showModalBottomSheet\(|showDialog\(" <files>
grep -nE "EdgeInsets\.[a-zA-Z]+\([^)]*\b[0-9]|(width|height):\s*[0-9]" <files>
```

- A literal colour, size, radius or font size becomes its token (`BrandColors`, `AppTypography`,
  `Radii`, `ComponentSizes`, `Spacing`). If no token fits and two screens need the value, add the
  token in `lib/core/design/` (see `/change-token`); a one-off mock-up offset may stay a literal
  only for spacing or a box size.
- A hand-built header, card, row, chip, note or state becomes the shared widget
  (`BlueHeader` / `WaveHeader`, `SoftCard` / `GlassCard`, `SettingsList` + `SettingsRow`,
  `SoftChoiceChip` / `HeaderChoiceChip`, `StatusPill`, `SoftNote`, `EmptyState` / `ErrorState`).
- Material `Icons.*` become `TaytayIcons` through `TaytayIcon` (with a label) or a `TaytayGlyph`
  in an `IconTile.glyph`.
- An `AppBar` becomes `BlueHeader`; an `AppBanner` becomes `SoftNote`; a raw `showDialog` becomes
  `AppDialog`.
- Shadows go. Focus rings stay.

## 3. Check the states and the layout

- The screen draws loading (`LoadingSkeleton`), empty (`EmptyState`), error (`FailureView` /
  `ErrorState`, Try again) and offline (`OfflineBanner` over saved data). Add any that is missing.
- A glass page with `GlassOverlap` inside a `ListView` passes
  `addRepaintBoundaries: false, addSemanticIndexes: false`.
- Every frame passes the layout matrix: add
  `await expectCleanLayouts(tester, () => …, scrollable: false);` for each frame to the screen's
  test (`test/support/layout_matrix.dart`).

## 4. Tests

- Run the screen's tests first. A test that pins an **old visual detail** the design replaces may
  be updated narrowly: say which assertion, what it checked and why it changed in the commit
  body. A test that checks behaviour, access, privacy or wording is never weakened; change the
  restyle instead.
- If the screen is a pattern's golden or appears in the gallery, run `flutter test
  test/goldens/`; regenerate (`--update-goldens`) only the goldens this restyle meant to move, and
  delete any files a failing run left in `test/goldens/failures/`.

## 5. Gates

One heavy job at a time on this PC (in the background, output to a log, read the tail).

1. `dart format` on the changed files only.
2. `flutter analyze` — clean.
3. `flutter test <the screen's tests> test/core/design_guard_test.dart`.
4. Full `flutter test` — green — before the commit.

## 6. Commit

Commit locally on the current branch:

```
Restyle: <screen> follows the <pattern> pattern

What changed (header, cards, rows, states, tokens), and that behaviour did not.
Tests changed: <file — assertion — why>, or none. Goldens: <moved and why>, or none.
API fields still missing: <field — what it would drive>, or none.
Gates: flutter analyze clean; flutter test <N> passed.

<the co-author trailer your session prescribes>
```

Never `git push`, `git pull` or `git fetch` from the command line, never `--no-verify`. Commits
stay local; the user pushes from GitHub Desktop.
