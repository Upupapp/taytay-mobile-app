# Taytay redesign — handoff pack

> **Reference only — read this first (added in this repository, redesign Phase 5).**
> The mock-ups under `mobile/screens/` are drawings with **SAMPLE data**: every name, count,
> date, message, office and photo in them is invented for the design. Never copy one into the
> app. The app reads all of it from the API; a part the API does not send is left out, not
> filled in (the fields the designs would need are listed in `DESIGN_SYSTEM.md` §9).
> How the app implements this design — tokens, shared widgets, screen patterns, rules — is in
> [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md). Where a mock-up and `CLAUDE.md` (privacy, access,
> architecture) or a test disagree, `CLAUDE.md` and the test win.
> Only the mobile half of the pack is kept here: `admin/` lives in `taytay-admin-web`. The files
> under `icons/` and `images/` are the design's copies. The app ships its own: the solid icons in
> `assets/icons/` and `assets/illustrations/` (declared in `AppAssets`), the seal in
> `assets/brand/`, the photographs in `assets/photos/` with their credits in
> `docs/frontend/PHOTO_CREDITS.md`. Nothing under `docs/` is bundled, analysed or tested.
> The original text of the pack follows.

Design reference for rebuilding the resident app (Flutter, `taytay-mobile-app`) and the
admin console (Angular, `taytay-admin-web`) in the new look. Copy this whole folder into
each repo as `design/` and point Claude in VS Code at it.

## What's inside

| Folder | Contents |
|---|---|
| `mobile/screens/` | Every resident-app screen as HTML (21 screens + bottom nav) |
| `mobile/design-system.css` | All shared styles: colours, type, radii, headers, cards, fields, tiles |
| `admin/screens/` | Admin console screens as HTML |
| `icons/` | Solid icons (SVG) and the two empty-state illustrations |
| `images/` | Seal and photos used in the designs |

**To view a screen in your browser:** the screens need a local web server (opening the file
directly won't render). In VS Code, install the **Live Server** extension, right-click
`mobile/screens/Home.dc.html` → *Open with Live Server*. Or in a terminal inside this folder:
`python -m http.server 8000`, then open `http://localhost:8000/mobile/screens/Home.dc.html`.
Set the browser to a phone size (DevTools → device toolbar → 390 × 844).

Live canvases (same designs, interactive):
- Mobile: https://claude.ai/artifact/NgRhGzxqAxW7po9Wbe4U9J
- Admin: https://claude.ai/artifact/DouUrxFGbaSBuymNVChwXK

---

## Design tokens

### Colours
| Token | Value |
|---|---|
| blue (primary) | `#0A2071` |
| navy | `#08124A` |
| gold | `#F5DA18` |
| red | `#E0090A` |
| green | `#17663A` |
| ink (headings) | `#0E1733` |
| text (body) | `#2B3550` |
| muted | `#5B6680` |
| screen background | `#F4F6FA` |
| soft fill (fields, soft cards) | `#F2F4F8` / `#F4F6FA` |
| divider | `#EEF1F6` |
| blue-50 / blue-100 (soft buttons, chips) | `#ECF1FC` / `#DCE5FA` |

### Gradients
- **Header:** 150°, `#08124A` 0% → `#0A2071` 50% → `#2D54E0` 100%. Bottom corners 28.
  Shapes: white circle 220 px at 7% opacity (top-right, offset −70/−80), gold circle 150 px
  at 16% opacity (bottom-left, offset −40/−60). No gold bottom line.
- **Wave header (registration):** same gradient + floating shapes + 3-layer wave
  (gold 85%, white 40%, white). See `.whead` in `design-system.css`.
- **Icon tiles (135°):** blue `#0A2071→#2D54E0`, green `#17663A→#2EA05A`,
  gold `#E8C500→#F5DA18` (navy icon), red `#B00708→#E0090A`, navy `#08124A→#22307E`,
  sky `#2D54E0→#5C7DF2`. White icon unless gold.

### Type (Plus Jakarta Sans)
| Role | Size / weight |
|---|---|
| Hero titles (welcome, wave header) | 20–22 / 700 |
| Header bar title | 20 / 700 (big) · 15 / 600 (with back button) |
| Page title | 18 / 700 |
| Section title | 15 / 600–700 |
| Body | 13.5 / 500, line height 1.45–1.55 |
| List title | 13.5 / 600 |
| List detail / supporting | 12.5 |
| Small / timestamps | 11–11.5 |
| Buttons | 14 / 600 |
| Field text / field label | 14 / 600 · 12.5 / 600 |
| Chips | 13.5 / 600 |
| Bottom nav labels | 11 (keep as is) |
| Category labels (ABISO · MSWDO) | 10.5 / 800, letter-spacing 0.06em, uppercase |

### Radii and sizes
Cards & lists 20–22 · buttons 16 · fields 14 · icon tiles 13–14 (sm 11, lg 17) ·
chips/pills fully round · buttons 52 high · fields 54 high · icon tiles 44 (sm 36, lg 56).

### Surfaces
- **Glass cards** (Home, ID, Balita, Account): white 74%→50% gradient, 1 px white 85% border,
  backdrop blur 18 + saturate 160%. Page background has soft colour blobs (see `.app.glass`).
- **Soft cards** (everything else): white on `#F4F6FA`, no border, radius 20.
- **Filled fields:** fill `#F2F4F8`, transparent border; focus = white fill, 1.5 px blue
  border, 3 px blue ring at 14%.
- **No shadows or glows anywhere.** Popups are centred.

---

## Screen patterns — apply to every screen in the repos

| Pattern | Designed example(s) | Mobile screens to restyle |
|---|---|---|
| Main tab (glass, blue header) | Home, Balita, Account | home, news, account_home, tulong, services, programs, events |
| List + search + filters | Directory, DirectorySearch | directory, issuance_catalogue, my_issuance_requests, assistance_requests, notification_inbox, requirements, hotlines |
| Detail page (photo + white sheet + pill actions) | Office | news_post, event_detail, program_detail, service_info, issuance_type, issuance_request_detail, assistance_case |
| Form / step flow (wave header, filled fields) | SignIn, Reg* screens | sign_in, account_wizard, registration, profile_wizard, kyc_claim, verification, issuance_request_form, event_registration, forgot_password, household_correction, contact_details |
| Settings / profile list | Account | account, profile, settings, security, privacy, privacy_controls, household |
| Success | MessageSent, RegDone | result step of every form flow |
| Notice / consent / blocked | RegTerms, DirectoryOffline | consent_update, blocking_notice, too_many_attempts, app_lock, sign_in_help |
| Card | DigitalID | digital_id |
| Splash / onboarding | Main (Welcome) | splash, onboarding |
| Messaging | NewMessage, Conversation | any message/thread screens |

Admin: restyle `shared/ui` first (page-header, data-table, empty-state, status-badge, modal,
drawer, toast, loading, connection-banner), then features. Examples: Residents = list page,
ResidentRecord = detail, AppDirectoryEdit = form, OfficeInbox/OfficeThread = messaging.

## Data rules
- Keep every repository, provider, service, route and validator. Only presentation changes.
- Nothing hard-coded: names, messages, dates, counts and photos come from the API/database.
  Remove all `SAMPLE` tags and sample text from the designs when building.
- Every data screen has four states: loading (skeleton), empty (illustrated empty state),
  error (Try again), offline (saved data + offline banner).
- Fields the designs need — add to the API if missing: office hours (structured, for the
  open/closed line), office category (icon + colour), office location line and Facebook,
  Balita `featured` flag + thumbnail, verification status + date, unread message count,
  image credits (shown on "Photo credits & about").
- Repo rules (CLAUDE.md Article 6) are overridden for this redesign: solid icons from
  `icons/`, sizes above, tile/tap sizes as designed. Update tests that enforce the old rules
  and say so in each PR.
