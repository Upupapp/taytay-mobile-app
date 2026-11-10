---
description: Change a design token (colour, size, radius, type) in one place, then check contrast, the gallery and the goldens
argument-hint: <token and new value, e.g. "BrandColors.muted #4F5A73" or "Radii.card 18">
---

# Change token: $ARGUMENTS

A token is changed **where it is declared and nowhere else**. Every screen reads it by name, so
one edit restyles the app; a screen that needs a different value gets a new token, never a
literal.

## 1. Read first

1. `docs/design/DESIGN_SYSTEM.md` §1–§2 (which group the token is in) and §7–§8.
2. Where it is declared, in `lib/core/design/`:
   - colours: `design_tokens.dart` (`BrandColors`; check the alias block too — an old name may
     point at the value you are changing);
   - gradients, header shapes, glass: `brand_gradients.dart`;
   - type: `typography.dart` (`AppTypography`);
   - radii, sizes, spacing, focus ring, opacities, icon sizes, tap targets: `design_tokens.dart`
     (`Radii`, `ComponentSizes`, `Spacing`, `FocusRing`, `Opacities`, `IconSizes`, `A11y`);
   - how a Material component uses it: `app_theme.dart`, `button_styles.dart`;
   - motion: `lib/core/motion/motion_tokens.dart`.
3. Who uses it: `grep -rn "<Class>\.<token>\b" lib/` — the count, and which screens to look at.
4. The tests that pin it: `grep -rn "<token>" test/core/ test/shared/` (contrast and theme tests
   name tokens directly).

## 2. Change

1. Edit the one declaration. Keep the comment beside it true (what it is for, its contrast).
2. **Colour:** if it is painted as text or as a meaningful graphic, its contrast is tested
   (`test/core/design_test.dart`, `foundation_contrast_test.dart`, `redesign_theme_test.dart`,
   `brand_test.dart`): body text 4.5:1, large text and graphics 3:1. Never lower a threshold or
   drop a pair to make it pass; change the colour. A colour newly used as text gets a pair.
3. **Size or radius:** a tap target never drops below `A11y.minTapTarget` (48); a visible size
   may be smaller only inside a 48 dp target.
4. **New token:** add it beside its group with a comment saying what it is for, then use it.
5. **Rename or removal:** replace every use in the same commit; leave an alias only when
   something outside this repository reads the old name.
6. Never put the new value in feature code: `test/core/design_guard_test.dart` fails on colour,
   font-size, radius and shadow literals outside `lib/core/design/` and `lib/shared/widgets/`.

## 3. Check

One heavy job at a time on this PC (in the background, output to a log, read the tail).

1. `flutter analyze` — clean.
2. The token tests: `flutter test test/core/design_test.dart test/core/foundation_contrast_test.dart
   test/core/redesign_theme_test.dart test/core/brand_test.dart test/core/design_guard_test.dart
   test/shared/`.
3. The layout matrix, which a larger size or type role can break: `flutter test test/features/`
   (the `redesign_*_layout_test.dart` files cover every restyled frame).
4. **The component gallery and the goldens.** `flutter test test/goldens/` shows what moved: the
   gallery pages (`test/goldens/design_system/gallery_*.png`), one screen per pattern
   (`pattern_*.png`), the component, digital ID and welcome goldens. Every golden that moved must
   be one the token is painted on; anything else is a regression to fix. Then regenerate:
   `flutter test --update-goldens test/goldens/`, and delete any files a failing run left in
   `test/goldens/failures/`. In a dev build the live gallery is at `/dev/components`.
5. Full `flutter test` — green.

## 4. Commit

Commit locally on the current branch:

```
Design token: <Class.token> <old> -> <new>, <why in a few words>

Where it is painted (count of uses, screens looked at). Contrast: pairs tested and their new
ratios. Goldens regenerated: <list> (visual only). Tests changed: <file — why>, or none.
Gates: flutter analyze clean; flutter test <N> passed.

<the co-author trailer your session prescribes>
```

Update `docs/design/DESIGN_SYSTEM.md` §2 in the same commit. Never `git push`, `git pull` or
`git fetch` from the command line: commits stay local and the user pushes from GitHub Desktop.
