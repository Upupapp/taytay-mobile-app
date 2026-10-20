# Sprint sign-offs

A sprint is approved only when Paul writes the words below on its pull request.
This file records that the words were looked for. It does not invent them.

| Sprint | Status | Pull request | Commit | Approval |
| --- | --- | --- | --- | --- |
| S0 Foundations | In review | https://github.com/Upupapp/taytay-mobile-app/pull/1 | eb4dd2c5ead2676be13dadef8ff84147b6d90d48 | Waiting for "S0 approved" |

## S0 pixel match

S0 renders shared components and the dev gallery. It does not render the 84 resident screens (those are S1–S8). Comparison uses `tool/golden_compare`. Button crops are taken from `02-01`. The other rows are the same components painted by the gallery harness against HTML rendered from `gen*.py` / `polish.py` (Plus Jakarta Sans, 3×). The side-by-side is design | build | diff. S0 is **not** approved.

| Component | Design source | Mismatch | What the diff is |
| --- | --- | --- | --- |
| Colour and gradient tokens | 8 swatches plus `linear-gradient(135deg,#062358,#0B3D91)` | 0.00% (0/264960) | `test/goldens/compare/tokens.png` |
| Type scale | h1 28/800/−0.6/1.13, sign-in h1 24/800/−0.5/1.15, sign-in button 16/800, in-app button 15/800, body 14/500/1.55, compact 13/500/1.5, label 12/700, eyebrows 11/800 at 1.6 and 1.5 | 5.81% (46218/795600) | First line matches (y 17–99, width within 1 px). Later lines sit about 4 device pixels lower: Flutter rounds each line box to a whole logical pixel. The rest is glyph antialiasing. `test/goldens/compare/type.png` |
| Primary button, "Sign in" | `02-01` pill, 16/800, height 50, shadow `0 8px 20px rgba(11,61,145,.28)`, 964×150 | 1.15% (1667/144600) | Under 2%. Pill edge and label antialiasing. Best shift is (0, 0). `test/goldens/compare/signin_primary.png` |
| Secondary button, "Create an account" | `02-01` outline pill, 16/800, inset 1.6 px `#0B3D91`, 964×150 | 2.65% (3836/144600) | Bounds align (shift 0, 0). Glyph and border antialiasing. `test/goldens/compare/signin_secondary.png` |
| Text button, "Continue as guest" | cropped from the current `02-01` PNG, where the link is an inline 12/800 override (shared `.link` stays 13/800), 963×120 | 2.49% (2876/115560) | Ink aligned with the 12 px glyphs. The previous panel was the 13 px `.link` rule. Remainder is glyph antialiasing. `test/goldens/compare/text_button.png` |
| Text field, default, focus, error | height 44, radius 12, border 1.4, fills `#FBF8F0` / white / `#FFF7F7`, value 14/600 `#1C2540`, hint 14/500 `#6B7186`, error icon 14 | 9.81% (90450/921600) | Borders within 1–2 px. Fills match (`#FBF8F0`, `#FFF7F7`). Skia and Chrome do not put the long strings on the same stems. `test/goldens/compare/fields.png` |
| Back button | 44 px white circle, chevron 20 `#0B3D91`, inside a 48 px target | 1.08% (223/20736) | Under 2%. Chevron antialiasing. `test/goldens/compare/back.png` |
| Card, list row, chips | badges 11/800 padding 4×10, card radius 16 padding 16, icon tile 44, 12 px gap before the chevron, sample tag padding 2×7 with a 1 px dashed `#E0A400` border | 10.44% (83025/795600) | The subtitle wraps after "Floor,". The list card is 222 px tall against the design's 227. List-title ink is 8 device pixels higher. The rest is glyph and shadow edges. `test/goldens/compare/card_row_chips.png` |
| Woven header | 46 px circle, 2 px white pad, gold ring, unaltered seal, wordmark 14/800 and 11/700 `#FCD116`, sign-in page field | 4.82% (11510/238680) | Back circle, seal frame, and both wordmark lines share the design ink bounds. Left edge is `#041A44`. Remainder is seal downscale and glyph edges. `test/goldens/compare/woven.png` |
| Empty state | 72 px disc, 32 px glyph, title 16/800, message 13/500 `#55607A` | 1.15% (7475/648000) | Under 2%. Icon and title antialiasing. `test/goldens/compare/empty.png` |

Tokens, the Sign in pill, the back button, and the empty state are at or under 2%. The guest link is cropped from the current `02-01` PNG at its 12 px override. The other diffs are committed. They are glyph or seal rasterization (Skia against Chrome), not a wrong size, weight, or colour. The list-title ink is the largest placement gap, about 8 device pixels, and the list card is 5 device pixels shorter than the design.

### Back control

The control stays a 44 dp circle inside a 48 dp target (`TaytayBackButton`). In-app mockups draw that circle as a 14% white disc with a white chevron (class `hb`), which reads as a bare chevron on navy. Those screens still use the solid white circle:

03-01 Verification-Status-Pending, 03-02 Verified, 03-03 Needs-Correction, 03-04 Unverified-Gate, 03-05 Resident-Profile-Overview, 03-06 Personal-Info, 03-07 Household-Address, 03-08 Review-Submit, 03-09 Profile-Submitted, 04-04 Home Hotlines, 04-08 Home Notifications, 05-02 Office-Detail, 05-03 Message-Office-Compose, 05-04 Message-Thread, 05-05 Search-Empty, 05-08 Office-MSWDO, 05-09 Office-Treasurer, 05-10 Office-Assessor, 05-11 Office-MDRRMO, 05-12 Office-PESO, 05-13 Office-PIO, 05-14 Office-Youth-Development, 05-15 Office-Health-Office, 05-16 Message-Sent, 05-17 Compose-MSWDO, 05-18 Compose-Treasury, 05-19 Compose-Assessor, 05-20 Compose-PESO, 05-21 Compose-PIO, 05-22 Compose-TYDO, 05-23 Compose-Health-Office, 06-02 Article-Detail, 06-03 Advisories-Filter, 06-04 Empty-Category, 06-06 Article-RPT-Advisory, 06-07 Article-BOSS-2026, 06-08 Article-SMILE-SAFE, 07-02 Service-Info-Page, 07-03 Social-Services-Centre, 07-04 Programme-Featured, 07-06 Service-PWD, 07-07 Service-Solo-Parent, 07-08 Service-AICS, 07-09 Service-Educational, 07-10 Service-Women-Children, 07-11 Service-PESO-Jobs, 07-12 Service-Youth, 08-02 Messages-Inbox, 08-03 Edit-Profile, 08-04 Settings-Privacy, 08-05 Photo-Credits-About, 08-06 Messages-Empty, 08-07 Thread-MSWDO, 08-08 Thread-Treasurer, 08-09 Privacy-Notice, 08-10 Photo-Credits-Office-Banners.

Welcome scenes `w2` and `w3` draw a solid circle. Onboarding is a navigation root, so the app does not put a back button on it.

### Remaining deviations

- Buttons are three variants, all weight 800. Sign-in: 16 px, pill, height 50, primary shadow `0 8px 20px` at 0.28, outline 1.6 px. Welcome: 16 px, pill, height 52, shadow `0 10px 22px` at 0.30, outline 1.6 px. In-app: 15 px, radius 12, height 48, no primary shadow, outline 1.5 px. Theme filled and outlined buttons use the in-app metrics.
- The guest link is 12/800. The shared `.link` token stays 13/800. Skip is 14/800. Sign-in eyebrow tracking is 1.5. Welcome eyebrow tracking is 1.6. `.sbtn` labels are 12/800; the hit target stays 48 dp.
- The woven header puts the official seal, unaltered, in a 46 px circle (welcome 58 px) with a 2 px white pad and a gold ring. Flutter's line box insets the wordmark, so the header opens the two lines by 4 px and paints the title 5/3 dp higher. Both corrections follow the text scaler. The seal file is not recoloured or redrawn.
- Flutter rounds a CSS line box to a whole logical pixel. On the type scale that is about 4 device pixels by the second line.
- In-app mockups that draw a bare chevron still use the solid white circle. Those screens are listed above. Onboarding is a navigation root, so it has no back button. Welcome scenes `w2` and `w3` draw a circle the app does not show there.
- Welcome and sign-in copy stays the English OTP flow. The mockup is Filipino and asks for a password. Firebase is not in this sprint.
- The tab bar stays Home, Services, News, Events, Profile until S4.
- Full screens 01–08 are S1–S8. Skia and Chrome do not rasterize Plus Jakarta Sans, Lucide, or the downscaled seal onto the same pixels. Those diffs are the images above.

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
