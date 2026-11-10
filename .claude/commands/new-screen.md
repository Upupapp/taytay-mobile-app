---
description: Build a new resident screen from a design pattern, the shared widgets and real API data
argument-hint: <feature and what the screen is for, e.g. "issuance: request history">
---

# New screen: $ARGUMENTS

Build the screen named above so that it looks and behaves like every other screen of the app,
from a pattern and the shared widgets, on data from the API. The look is the easy part: the
constitution still decides what the screen may show, who may open it and where its data comes
from.

## 1. Read first

1. `CLAUDE.md` — Article 2 (feature-first layers), 3 (the server decides), 4 (routes and the
   guard), 5 (privacy), 6 (Design), 9 (definition of done).
2. `docs/design/DESIGN_SYSTEM.md` — §2 tokens, §3 shared widgets, §4 patterns and skeletons,
   §5 the four data states, §6 the layout matrix, §8 rules.
3. The feature's own `domain/` and `data/` (the repository contract the screen will read) and any
   `docs/taytay-*.md` page for the feature. A rule there outranks any mock-up.
4. The reference screen of the pattern you pick (step 2): its screen file and its canvas.

## 2. Pick a pattern

Choose exactly one from DESIGN_SYSTEM.md §4 and say which in the commit body:

| Pattern | Mock-up (`docs/design/mobile/screens/`) | Reference (`lib/features/`) |
|---|---|---|
| Main tab | `Home`, `Balita`, `Account` | `home/presentation/home_canvas.dart` |
| List + search + filters | `Directory`, `DirectorySearch` | `directory/presentation/directory_canvas.dart` (list) |
| Detail | `Office` | `directory_canvas.dart` (detail), `events/presentation/event_detail_screen.dart` |
| Form / step flow | `SignIn`, `Reg*` | `auth/presentation/sign_in_screen.dart`, `account_wizard_screen.dart` |
| Settings / profile list | `Account` | `settings/presentation/settings_screen.dart` |
| Success | `MessageSent`, `RegDone` | `directory_canvas.dart` (sent) |
| Notice / consent / blocked | `RegTerms`, `DirectoryOffline` | `platform/presentation/blocking_notice_screen.dart` |
| Card | `DigitalID` | `credential/presentation/digital_id_canvas.dart` |
| Splash / onboarding | `Main` | `splash/presentation/splash_screen.dart` |
| Messaging | `NewMessage`, `Conversation` | `account/presentation/account_canvas.dart` (thread) |

Read the mock-up's HTML with grep or offset/limit for the classes you need (the CSS values are in
`docs/design/mobile/design-system.css`); do not open screenshots. Its names, counts, dates,
offices and photos are **sample data**: never copy them.

## 3. Build

1. **Data.** Read through the feature's repository contract from
   `AppDependencies.of(context)`; fallible work returns `Result<T>`. No JSON above `data/`, no
   mock data in a screen. If the API does not serve what the screen needs, stop and say so: the
   client mocks behind the repository interface, in a dev build only (Article 7).
2. **Route.** One entry in `core/router/app_routes.dart` with its `AccessRequirement` (there is no
   default), bound in `core/router/app_router.dart`. The screen does not guard itself and does not
   navigate to its own successor. A non-root route shows exactly one `TaytayBackButton` (the
   header draws it with `showBack: true`).
3. **Screen and canvas.** A stateful screen that owns the controller and picks a frame, and a
   stateless canvas that draws a frame from parameters (DESIGN_SYSTEM.md §4, "Screen and canvas").
   Start from the pattern's skeleton.
4. **Shared widgets only.** Headers, cards, rows, chips, pills, notes, states and buttons come
   from `lib/shared/widgets/`. Every colour is a `BrandColors` token, every type style an
   `AppTypography` role, every radius a `Radii` token, every size and gap a `ComponentSizes` /
   `Spacing` token; no shadow. Dialogs go through `AppDialog` (centred).
5. **A new shared widget** (only when two screens need the same shape): put it in
   `lib/shared/widgets/`, take its data as parameters, add a specimen to
   `lib/features/gallery/presentation/shared_widgets_gallery_section.dart`, a widget test, and its
   entry in DESIGN_SYSTEM.md §3. A new value goes in `lib/core/design/` first.
6. **Four states.** Loading (`LoadingSkeleton`), empty (`EmptyState`, empty and no-results worded
   apart), error (`FailureView` / `ErrorState` with Try again that reloads), offline (saved data
   under `OfflineBanner`; a full-screen route adds `const OfflineBanner()` or
   `SoftPage(offlineBanner: true)`).
7. **Accessibility.** A label on every icon that means something, one label per tappable card or
   row, 48 dp targets, `Motion.reduced(context)` for any animation, `AppHaptics.fire` by intent.
8. **Missing data.** A part of the mock-up the API does not send is left out, not faked. Say so in
   the commit body (field, screen, what it would drive).
9. **Copy.** Resident copy is the app's own (never the server's `message`); localised strings go
   through `AppStrings` where the feature already does.

## 4. Tests

- A widget test in `test/features/<feature>_test.dart` (or beside the feature's existing tests):
  the content frame from synthetic data, the empty, error and offline frames, and the screen from
  **every session state** it can be reached in — guest, unverified, verified — including the
  denied path (Article 9.4).
- The layout matrix for every frame:
  `await expectCleanLayouts(tester, () => MyCanvas(frame: …), scrollable: false);`
  (`test/support/layout_matrix.dart`: 360 / 375 / 430 dp × 100% / 200% text).
- A privacy assertion where the screen shows personal data or server text (Article 9.5).
- If the screen is the reference of a pattern, or a new shared widget changed the gallery, run
  the goldens (`flutter test test/goldens/`) and regenerate only what you meant to move
  (DESIGN_SYSTEM.md §7).

## 5. Gates

This PC is short of memory: run one heavy job at a time (`flutter analyze`, `flutter test`,
`flutter build`), in the background with its output in a log file, and read only the tail.

1. `dart format` on the files you changed (not on `lib/` as a whole).
2. `flutter analyze` — clean: no errors, warnings or infos.
3. `flutter test test/features/<feature>_test.dart test/core/design_guard_test.dart
   test/core/foundation_routes_test.dart test/core/navigation_test.dart`.
4. Full `flutter test` — green — before the commit.

## 6. Commit

Commit locally on the current branch:

```
<One sentence: what a resident can now do on the new screen>

Pattern: <pattern>, from <reference screen>. Route <path>, <AccessRequirement>.
Reads <repository method>; loading, empty, error and offline states.
Left out for lack of an API field: <field — screen — what it would drive>, or none.
Tests: <files>. Goldens: <moved and why>, or none.
Gates: flutter analyze clean; flutter test <N> passed.

<the co-author trailer your session prescribes>
```

Never `git push`, `git pull` or `git fetch` from the command line, never `--no-verify`, never
amend or rewrite history. Commits stay local; the user reviews and pushes from GitHub Desktop
(Article 10).
