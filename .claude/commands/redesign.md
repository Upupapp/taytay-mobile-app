---
description: Run a whole resident-app redesign in phases — tokens, shared widgets, screens — with a PROGRESS.md and a commit per phase
argument-hint: <folder holding the new design, e.g. "design/" (README, CSS, mock-ups)>
---

# Redesign from: $ARGUMENTS

A redesign changes how the app looks, never what it does. It runs in phases, in this order, and
commits after each: the tokens first (one edit restyles everything that reads them), then the
shared widgets, then the screens feature by feature, then a sweep, then the docs and guards.

## 0. Before you start

1. `git status --short`: if there are changes you did not make, stop and report them.
2. Read `CLAUDE.md` in full. The new design overrides only the **visual** rules (Article 6 and
   `docs/design/`); architecture, access, privacy, security and testing rules still apply.
3. Read the new design: its `README.md` first (tokens, patterns, data rules), then its CSS, then
   the mock-ups — HTML with inline CSS, read with grep or offset/limit for exact values. Do not
   open screenshots unless a layout question cannot be settled from the source. The mock-ups
   carry **sample data**: never copy a name, count, date, message or photo into the app.
4. Read the current `docs/design/DESIGN_SYSTEM.md`: what exists, and the screen-and-canvas split
   the tests rely on.
5. Keep the new design folder out of git (add it to `.gitignore`); the last phase copies what stays
   into `docs/design/`.
6. Create `<design folder>/PROGRESS.md` (also ignored) with: a batch table (phase, scope, status,
   commit hash), "Next up", "API fields needed", "Tests changed", "Notes for the next agent". Keep
   it current after every step, so a fresh session can continue from it alone.

## 1. Tokens

Map every design token onto `lib/core/design/`: `BrandColors` (keep old names as aliases until
the screens move), `brand_gradients.dart`, `AppTypography`, `Radii`, `ComponentSizes`, `Spacing`,
`FocusRing`; then restyle the Material component themes in `app_theme.dart`. Show every token and
themed component in `lib/features/gallery/presentation/theme_gallery_section.dart`. Contrast
tests stay at 4.5:1 / 3:1: a design colour that fails them is adjusted and noted, never the test.
Regenerate the goldens (`flutter test --update-goldens test/goldens/`) only after the rest of the
suite passes. Commit `Redesign: Phase 1 theme`.

## 2. Shared widgets

Build or restyle each widget the design repeats in `lib/shared/widgets/` (headers, cards, tiles,
rows, chips, notes, the four data states, success, messaging pieces), keeping existing public
APIs. Each takes its data as parameters, reads tokens only and draws no shadow, has a specimen in
`shared_widgets_gallery_section.dart`, and a widget test including the layout matrix
(`test/support/layout_matrix.dart`). Commit `Redesign: Phase 2 shared widgets`.

## 3. Screens, feature by feature

Order the features in PROGRESS.md and map each to a pattern of the design (or of
DESIGN_SYSTEM.md §4). Per feature:

1. Restyle with the shared widgets — follow `/restyle-screen`. Presentation only: keep every
   controller, repository, route, guard, validator, model, key and required wording.
2. Every data screen gets loading, empty, error and offline states.
3. A design element whose data the API does not send is hidden, and the field goes under "API
   fields needed" (field, screen, what it would drive).
4. Every frame passes the layout matrix at 360 / 375 / 430 dp × 100% / 200% text.
5. A test that pins an old visual detail is updated narrowly and listed under "Tests changed"
   (file, what, why). A behaviour, access, privacy or wording test is never weakened.
6. Gate: `flutter analyze` on the changed paths and the feature's tests; then commit
   `Redesign: <feature>`. Before the commit that ends a batch, the full `flutter analyze` and
   `flutter test`.

The router imports every screen: park a half-edited feature (restore it from `HEAD` into a
scratch copy) before gating another one.

## 4. Sweep

Search for anything still on the old look and bring it in line:

```sh
grep -rnE "Color\(0x|fontSize:\s*[0-9.]|BoxShadow|(Border)?Radius\.circular\(\s*[0-9.]" lib/features lib/app
grep -rnE "AppBar\(|AppBanner\(|\bIcons\." lib/features
```

Delete widgets and tokens nothing reaches any more (check the import graph from `lib/main.dart`),
with the tests that only tested them, and list both. Commit `Redesign: Phase 4 finish`.

## 5. Docs and guards

1. Copy the design's README, mobile mock-ups, icons and images into `docs/design/` (with a note
   at the top that they are reference drawings with sample data); never the task files or
   PROGRESS.md. Check nothing (pubspec assets, analyzer, tests) picks them up.
2. Rewrite `docs/design/DESIGN_SYSTEM.md` from the code as it now is: tokens, every shared
   widget, the pattern table with skeletons, the four states, the layout matrix, the goldens,
   the rules, the known gaps.
3. Update CLAUDE.md Article 6 if a rule moved.
4. Regenerate `test/goldens/design_system/` (gallery pages and one screen per pattern) and add a
   pattern golden if the design added a pattern. Run them twice: they must pass unchanged.
5. Keep `test/core/design_guard_test.dart` green on the new tree; validate any new rule against a
   planted violation, then remove the plant.
6. Full `flutter analyze` and `flutter test`; commit
   `Redesign: design system docs, commands and guard tests`.

## Gates and commits

One heavy job at a time on this PC (`flutter analyze`, `flutter test`, `flutter build`), in the
background with output to a log; read the tail. Never commit with a failing gate. Each commit:

```
Redesign: <phase or feature>

What changed. Tests changed: <file — what — why>. Goldens regenerated: <list> (visual only).
API fields needed: <added this phase>, or none.
Gates: flutter analyze clean; flutter test <N> passed / <M> skipped.

<the co-author trailer your session prescribes>
```

Record each hash in PROGRESS.md as "committed, not pushed". Never `git push`, `git pull` or
`git fetch` from the command line, never `--no-verify`, never rewrite history: the user pushes
from GitHub Desktop.
