# Sprint sign-offs

A sprint is approved only when Paul writes the words below on its pull request.
This file records that the words were looked for. It does not invent them.

| Sprint | Status | Pull request | Commit | Approval |
| --- | --- | --- | --- | --- |
| S0 Foundations | In review | https://github.com/Upupapp/taytay-mobile-app/pull/1 | 6e27dc354fb1feaf50c2f2a7e64eaccb34ecca25 | Waiting for "S0 approved" |

## S0 pixel match

S0 renders shared components and the dev gallery. It does not render the 84 resident screens (those are S1–S8). Comparison uses `tool/golden_compare`. Button crops are taken from `02-01`. The other rows are the same components painted by the gallery harness against HTML rendered from `gen*.py` / `polish.py` (Plus Jakarta Sans, 3×). The side-by-side is design | build | diff. S0 is **not** approved.

| Component | Design source | Mismatch | What the diff is |
| --- | --- | --- | --- |
| Colour and gradient tokens | 8 swatches plus `linear-gradient(135deg,#062358,#0B3D91)` | 0.00% (0/264960) | `test/goldens/compare/tokens.png` |
| Type scale | h1 28/800, sign-in h1 24/800, button 16/700, body 14/500, compact 13/500, label 12/700, eyebrow 11/800 | 6.15% (48896/795600) | Line boxes drift after the first line. Skia and Chrome do not share a leading. Sizes, weights and tracking match the polished CSS. `test/goldens/compare/type.png` |
| Primary button, "Sign in" | `02-01` navy pill, 964×150 | 3.01% (4350/144600) | Pill bounds identical. Label ink sits in the same 59–105 px band (1 px). The design export is weight 800; the reviewer required 700. The rest is pill-edge antialiasing. Diff: `test/goldens/compare/signin_primary.png` |
| Secondary button, "Create an account" | `02-01` outline pill, 964×150 | 4.27% (6173/144600) | Same weight gap (CSS 800, app 700) plus the 1.6 px inset border. Fill is white, label and border are `#0B3D91`. `test/goldens/compare/signin_secondary.png` |
| Text button, "Continue as guest" | `.link` 13/800 `#0B3D91`, 963×120 | 4.49% (5189/115560) | Glyph rasterization. The sign-in screen itself uses 12 px, which is the inline override on that one link. `test/goldens/compare/text_button.png` |
| Text field, default, focus, error | height 44, radius 12, border 1.4, fills `#FBF8F0` / white / `#FFF7F7` | 16.28% (150078/921600) | Fill samples match (`#FBF8F0`, `#FFF7F7`). Labels start 1 px apart. Later fields sit about 2 px higher. The rest is hint and label rasterization. `test/goldens/compare/fields.png` |
| Back button | 44 px white circle on `#062358`, inside a 48 px target | 0.50% (103/20736) | Chevron antialiasing. `test/goldens/compare/back.png` |
| Card, list row, chips | badges 11/800, card radius 16, list icon 44 | 14.42% (114749/795600) | Chip colours match. The row draws a trailing chevron and the card draws the two CSS shadows; those edges do not sit on the same pixels as the HTML strip. `test/goldens/compare/card_row_chips.png` |
| Woven header | seal PNG, wordmark 14/800, subtitle 11/700 `#FCD116`, gradient mid-stop at 55% | 67.14% (377059/561600) | Left-edge navy matches `#031433`. The seal is the official PNG, unmasked. The mockup draws it inside a 46 px circle with a 2 px white pad and a gold ring. The mark also keeps its clear space. `test/goldens/compare/woven.png` |
| Empty state | 72 px disc, 32 px glyph, title 16/800, message 13/500 `#55607A` | 2.78% (17983/648000) | Icon and title rasterization. `test/goldens/compare/empty.png` |

The sign-in primary crop is over 2%. The pill is not shifted. The diff image is the record of the remaining antialiasing and the 800-versus-700 stroke.

### Back control

The control stays a 44 dp circle inside a 48 dp target (`TaytayBackButton`). In-app mockups draw that circle as a 14% white disc with a white chevron (class `hb`), which reads as a bare chevron on navy. Those screens still use the solid white circle:

03-01 Verification-Status-Pending, 03-02 Verified, 03-03 Needs-Correction, 03-04 Unverified-Gate, 03-05 Resident-Profile-Overview, 03-06 Personal-Info, 03-07 Household-Address, 03-08 Review-Submit, 03-09 Profile-Submitted, 04-04 Home Hotlines, 04-08 Home Notifications, 05-02 Office-Detail, 05-03 Message-Office-Compose, 05-04 Message-Thread, 05-05 Search-Empty, 05-08 Office-MSWDO, 05-09 Office-Treasurer, 05-10 Office-Assessor, 05-11 Office-MDRRMO, 05-12 Office-PESO, 05-13 Office-PIO, 05-14 Office-Youth-Development, 05-15 Office-Health-Office, 05-16 Message-Sent, 05-17 Compose-MSWDO, 05-18 Compose-Treasury, 05-19 Compose-Assessor, 05-20 Compose-PESO, 05-21 Compose-PIO, 05-22 Compose-TYDO, 05-23 Compose-Health-Office, 06-02 Article-Detail, 06-03 Advisories-Filter, 06-04 Empty-Category, 06-06 Article-RPT-Advisory, 06-07 Article-BOSS-2026, 06-08 Article-SMILE-SAFE, 07-02 Service-Info-Page, 07-03 Social-Services-Centre, 07-04 Programme-Featured, 07-06 Service-PWD, 07-07 Service-Solo-Parent, 07-08 Service-AICS, 07-09 Service-Educational, 07-10 Service-Women-Children, 07-11 Service-PESO-Jobs, 07-12 Service-Youth, 08-02 Messages-Inbox, 08-03 Edit-Profile, 08-04 Settings-Privacy, 08-05 Photo-Credits-About, 08-06 Messages-Empty, 08-07 Thread-MSWDO, 08-08 Thread-Treasurer, 08-09 Privacy-Notice, 08-10 Photo-Credits-Office-Banners.

Welcome scenes `w2` and `w3` draw a solid circle. Onboarding is a navigation root, so the app does not put a back button on it.

### Remaining deviations

- Button labels are weight 700, as reviewed. `gen.py` `.btn` is weight 800. Sign-in size is 16 (15.5 polished). In-app `.btn` is 15 px and radius 12; the shared pill stays 16 / radius 999 for the sign-in crop. Theme `FilledButton` / `OutlinedButton` stay radius 12 with the 16/700 label.
- Sign-in eyebrow tracking is 1.6. Sign-in CSS `.en` is 1.5. Welcome `.en` is 1.6.
- The seal is never circle-masked, recoloured, or replaced by the wordmark. Clear space is 0.12× the mark.
- Welcome and sign-in copy stays the English OTP flow. The mockup is Filipino and asks for a password. Firebase is not in this sprint.
- The tab bar stays Home, Services, News, Events, Profile until S4.
- Small action labels (`.sbtn`) are 12/700. CSS is 12/800.
- Welcome primary shadow is `0 10px 22px` at 0.30 alpha. The shared primary uses the sign-in shadow `0 8px 20px` at 0.28 alpha.
- Full screens 01–08 are S1–S8.

Exceptions, recorded rather than forced under 2%:

- Screens `01-01` through `08-10` are not built in S0.
- Photographs and the OS status bar are excluded by the pixel-match method.

## Contract gaps after the Node OpenAPI

F31 is closed. `GET/POST /threads`, messages, mark-read, and close are citizen routes and the live repository calls them.

These designs still need data the spec does not publish. The calls decline with F32, or the screen keeps static copy:

- Sign-in, sign-up, email code, forgot password (`02-01`–`02-11`). No OTP or password routes. Identity is a Firebase ID token. This app does not add the Firebase SDK. Dev sessions use `Authorization: Bearer mock:<role>:<id>` with role `registered` or `verified` only.
- Self-registration and the office contact line. No `app/bootstrap` and no `features.self_registration`. The wizard stays off the signed-out path. Creating an account is not offered from sign-in.
- Token revocation. Sign-out clears the session on the device.
- Digital ID and QR (`01-02`, account). No credential resource.
- Events catalogue and registration. No events resource.
- Household (`03-07`). Address is a string on `PATCH /me`. Barangay is an id from `GET /barangays` (`id`, `code`, `name` only — no phone).
- Assistance intake, drafts, requirements, and document checklists. Tulong is `GET /services` and `GET /services/{slug}`. There is no apply route.
- Notification preferences and device registration. Inbox types are only `verification_decided` and `message_received`. Design categories such as advisory, treasury, and BPLO are not in that enum.
- News comments, reactions, and reports. A resident reads `GET /news`. This app does not call `POST /news` or `PATCH /news`.
- Account closure.
- Hotlines as their own resource, weather, payments, and map tiles. An office may carry `phone`, `email`, `latitude`, `longitude`, and `address`. The resident decoder does not surface the coordinates. The design's location cards are an illustrative drawing.
- Welcome copy, photo credits, and a bundled hall photograph. None of those are API fields.
- A thread has no subject or preview. The start call returns the thread. The client loads messages for a preview.
- Verification is `POST /me/verification-requests` (multipart `id_type`, `id_front`, optional `id_back`, `selfie`) and `GET /me/verification-requests/current`. It is not the old multi-step case with a documents list. Staff assignment on a profile is not modeled on a resident type.
