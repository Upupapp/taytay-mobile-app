# Sprint sign-offs

A sprint is approved only when Paul writes the words below on its pull request.
This file records that the words were looked for. It does not invent them.

| Sprint | Status | Pull request | Commit | Approval |
| --- | --- | --- | --- | --- | --- |
| S0 Foundations | Approved by design review | https://github.com/Upupapp/taytay-mobile-app/pull/1 | bc3f75259bff5c6ed5c3ab9bf469a619c15a8d8f | Ui/Ux Taytay, 2026-10-21. Paul merges. |
| S1 Welcome | Approved by design review | https://github.com/Upupapp/taytay-mobile-app/pull/2 | 2ecacd054f7c27ff59c88f4789b7bc25d6a7221f | Ui/Ux Taytay, 2026-10-21. Paul merges. |
| S2 Sign-in | In review, not approved | https://github.com/Upupapp/taytay-mobile-app/pull/3 | 3221abdcea60e6b03fdfa14799417187fa7b1f8c | No approval words. Paul merges when he chooses. |

## S0 pixel match

S0 renders shared components and the dev gallery. It does not render the 84 resident screens (those are S1–S8). Comparison uses `tool/golden_compare`. Button crops are taken from `02-01`. The other rows are the same components painted by the gallery harness against HTML rendered from `gen*.py` / `polish.py` (Plus Jakarta Sans, 3×). The side-by-side is design | build | diff. The design reviewer Ui/Ux Taytay approved S0 on 2026-10-21 at `bc3f75259bff5c6ed5c3ab9bf469a619c15a8d8f`. The remaining diff is glyph and edge antialiasing, and layout is within 1 px. Paul merges. Pull request #1 stays a draft until that merge. This file does not record Paul as having written "S0 approved".

| Component | Design source | Mismatch | What the diff is |
| --- | --- | --- | --- |
| Colour and gradient tokens | 8 swatches plus `linear-gradient(135deg,#062358,#0B3D91)` | 0.00% (0/264960) | `test/goldens/compare/tokens.png` |
| Type scale | h1 28/800/−0.6/1.13, sign-in h1 24/800/−0.5/1.15, sign-in button 16/800, in-app button 15/800, body 14/500/1.55, compact 13/500/1.5, label 12/700, eyebrows 11/800 at 1.6 and 1.5 | 5.81% (46218/795600) | First line matches (y 17–99, width within 1 px). Later lines sit about 4 device pixels lower: Flutter rounds each line box to a whole logical pixel. The rest is glyph antialiasing. `test/goldens/compare/type.png` |
| Primary button, "Sign in" | `02-01` pill, 16/800, height 50, shadow `0 8px 20px rgba(11,61,145,.28)`, 964×150 | 1.15% (1667/144600) | Under 2%. Pill edge and label antialiasing. Best shift is (0, 0). `test/goldens/compare/signin_primary.png` |
| Secondary button, "Create an account" | `02-01` outline pill, 16/800, inset 1.6 px `#0B3D91`, 964×150 | 2.65% (3836/144600) | Bounds align (shift 0, 0). Glyph and border antialiasing. `test/goldens/compare/signin_secondary.png` |
| Text button, "Continue as guest" | cropped from the current `02-01` PNG, where the link is an inline 12/800 override (shared `.link` stays 13/800), 963×120 | 2.49% (2876/115560) | Ink aligned with the 12 px glyphs. The previous panel was the 13 px `.link` rule. Remainder is glyph antialiasing. `test/goldens/compare/text_button.png` |
| Text field, default, focus, error | height 44, radius 12, border 1.4, fills `#FBF8F0` / white / `#FFF7F7`, value 14/600 `#1C2540`, hint 14/500 `#6B7186`, error icon 14 | 9.81% (90450/921600) | Borders within 1–2 px. Fills match (`#FBF8F0`, `#FFF7F7`). Skia and Chrome do not put the long strings on the same stems. `test/goldens/compare/fields.png` |
| Back button | 44 px white circle, chevron 20 `#0B3D91`, inside a 48 px target | 1.08% (223/20736) | Under 2%. Chevron antialiasing. `test/goldens/compare/back.png` |
| Card, list row, chips | badges 11/800 padding 4×10, card radius 16 padding 16, icon tile 44, 12 px gap before the chevron, sample tag padding 2×7 with a 1 px dashed `#E0A400` border, `.lt`/`.ls` line-height 1.2 with half-leading kept on the first ascent and last descent, `.li` padding 12×0 and a 2 px title gap | 4.41% (35108/795600) | The subtitle wraps after "Floor,". The list card is 228 px tall against the design's 227. List-title ink starts at x 222, the same as the design, and at y 478 against 477. The rest is glyph and shadow edges. `test/goldens/compare/card_row_chips.png` |
| Woven header | 46 px circle, 2 px white pad, gold ring, unaltered seal, wordmark 14/800 and 11/700 `#FCD116`, sign-in page field | 4.82% (11510/238680) | Back circle, seal frame, and both wordmark lines share the design ink bounds. Left edge is `#041A44`. Remainder is seal downscale and glyph edges. `test/goldens/compare/woven.png` |
| Empty state | 72 px disc, 32 px glyph, title 16/800, message 13/500 `#55607A` | 1.15% (7475/648000) | Under 2%. Icon and title antialiasing. `test/goldens/compare/empty.png` |

Tokens, the Sign in pill, the back button, and the empty state are at or under 2%. The guest link is cropped from the current `02-01` PNG at its 12 px override. The other diffs are committed. They are glyph or seal rasterization (Skia against Chrome), not a wrong size, weight, or colour. The list card is 228 px against the design's 227, and the list-title ink is 1 device pixel lower.

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

## S1 Welcome

The design reviewer Ui/Ux Taytay approved S1 on 2026-10-21 at `2ecacd054f7c27ff59c88f4789b7bc25d6a7221f`. Paul merges. Pull request #2 stays a draft until that merge. This file does not record Paul as having written "S1 approved".

S1 renders welcome scenes `01-01`, `01-02`, and `01-03`. Comparison uses `tool/golden_compare` at 1170×2532, which is 390×844 at 3×. The side-by-side is design | build | diff. The photograph is masked to the rounded arch interior, so the white rim stays in the count. The design PNGs have no status bar, so the top of the frame stays in the count. A pixel differs when CIE76 ΔE is above 6.

| Screen | Design source | Mismatch | Layout |
| --- | --- | --- | --- |
| 01-01 Municipal services | `01-01_Welcome_Municipal-Services.png` | 3.67% (78365/2132448) | Body line tops 1889/1954/2019, +1/0/−1 against 1888/1954/2020. Copy-block origin within 1 device px. Next pill origin within 1 device px. Seal ring samples `(214, 181, 29)`. Arch rim samples `#FFFFFF`. `test/goldens/compare/welcome_01-01.png` |
| 01-02 Taytay ID | `01-02_Welcome_Taytay-ID.png` | 3.12% (66579/2132448) | Body line tops 1889/1953, +2/+1 against the design at 1887/1952. Next pill origin within 1 device px. `test/goldens/compare/welcome_01-02.png` |
| 01-03 Privacy | `01-03_Welcome_Privacy-Get-Started.png` | 4.06% (94970/2339862) | Body line tops 1685/1749/1815, +2/+1/+2 against the design at 1683/1748/1813. Knot row sits 28 px under the body. Get started pill is within 1 device px. `test/goldens/compare/welcome_01-03.png` |

On `01-01`, the gradient outside the seal and wordmark is 0.17%. The arch band outside the photograph is 1.43%. Body line tops are the first row with more than 15 pixels near `#46506A`. The design reads 1887/1952/2017, so the build is +2/+2/+2, and the pitch is 65/65 device px. `01-03`'s two gaps sum to 130 device px, the same as the design. The welcome golden host is a `Material`, so the text is not Flutter's missing-`Material` underline. S0 goldens already sat in a `Scaffold` or a transparent `Material`. The woven-header and gallery-frame goldens were regenerated because the shared seal ring now paints above its drop shadow.

Sign-in against `02-01` is 42.78% (1267297/2962440) for the full frame, in `test/goldens/compare/signin_02-01.png`. With the sheet interior masked, it is 32.08% (436190/1359504). The fade margins beside the sheet (y 960–1200, x under 36 or over 1134) are 0.00% (0/17040). The band below the sheet (y ≥ 2472) is 0.00% (0/70200). The header band y under 300 is 5.15% (18088/351000), the same seal and glyph class as the S0 woven header. At x = 12, y = 1146 (382 dp) the ground is `#F3F5FA`. The thread's gold pixels run from y = 129 to y = 753 and do not enter the sheet.

The speck runs for 7s on `cubic-bezier(.45, 0, .55, 1)`. Its position on the welcome pages is `PageController.page` along the joined stitch `Y=[200, 300, 170, 260]`, so the exit of page *n* is the entry of page *n+1*. Get started hands the live cycle to Sign-in. The thread and the 7s loop stay on the sign-in screen. Reduced motion hides the speck and keeps the thread still.

### S1 deviations

- The full-frame mismatch is above 2%. The gradient field matches. The remainder is glyph antialiasing, the downscaled seal, dashed chip edges, and button-label edges. Layout is within 2 device px.
- The body uses height 1.55 and a strut at the same leading. The engine still rounds one strut to 22 logical px, so each line is placed `14 × 1.55` apart. The line tops stay within 2 device px of 1888/1954/2020 on `01-01`, and within 2 device px of the design on `01-02` and `01-03`.
- Sign-in fades the navy field to `#F3F5FA` by y = 382 dp. The form sits on the white sheet, and the thread is painted behind that sheet. The 42.78% against `02-01` is the municipal-hall arch this OTP screen does not draw, English OTP copy against the design's Filipino email and password screen, and the debug session simulator, which is present because the capture runs with `kDebugMode`. The headline, intro, privacy line, "Trouble signing in?", and "Continue as guest" are on the white sheet and clear AA there.
- The prototype `spk` keyframes are one 7s loop positioned in percentages. These scenes follow the SVG stitch in `w1.html`, `w2.html`, and `w3.html`, on that same duration and curve, and Sign-in keeps that loop.
- Skip's painted pill is 44 dp inside a 48 dp target.
- The English locale is the design: Filipino headlines, English eyebrows and bodies, English controls. Filipino translates the English lines. The three headlines stay shared, because they are already the design's Filipino.
- Photographs are the design JPEGs, with the credits in `docs/frontend/PHOTO_CREDITS.md`. The seal is the existing asset, unaltered.
- No new package.

## S2 Sign-in

S2 is in review. It is not approved. This file does not record an approval, and it does not record Paul as having written one. S0 and S1 are on `main` at `67732d02204f271e7e547e118d7b25fdc6de9f97`.

S2 replaces the English one-time-code sign-in with `02-01` through `02-11`. Comparison uses `tool/golden_compare` at 1170×2532. A pixel differs when CIE76 ΔE is above 6. The municipal-hall interior is masked on `02-01` and `02-10`. The rim stays in the count. The design PNGs have no status bar, so the top of the frame stays in the count. The side-by-side is design | build | diff.

| Screen | Mismatch | Sheet edge |
| --- | --- | --- |
| 02-01 Sign in | 7.78% (230429/2962440) | Hall arch included. Sheet top 332. |
| 02-02 Forgot password | 6.61% (195897/2962440) | White edge y = 912, same as the design. |
| 02-03 Personal info | 10.48% (310375/2962440) | White edge y = 462, same as the design. |
| 02-04 Email code | 5.34% (158221/2962440) | Sheet top y = 901, same as the design. |
| 02-05 Terms | 10.63% (314777/2962440) | White edge y = 462, same as the design. |
| 02-06 Valid ID | 7.60% (225129/2962440) | White edge y = 462, same as the design. |
| 02-07 Selfie | 7.50% (222050/2962440) | White edge y = 462, same as the design. |
| 02-08 Review | 6.64% (196606/2962440) | White edge y = 462, same as the design. |
| 02-09 Submitted | 4.77% (141386/2962440) | Sheet top y = 1493, same as the design. |
| 02-10 Sign-in error | 8.09% (239556/2962440) | Short hall arch included. Sheet top 276. |
| 02-11 Validation | 10.48% (310548/2962440) | Street and the address line are gone. Barangay is full width. |
| 02-02b Reset code | 9.05% (267993/2962440) | White edge y = 756, same as the design. |
| 02-04b Code expired | 5.59% (165614/2962440) | White edge y = 900, same as the design. |
| 02-12 Set new password | 10.11% (299436/2962440) | White edge y = 756, same as the design. |
| 02-12b Expired reset | 11.86% (351225/2962440) | White edge y = 756, same as the design. |
| 02-13 Password updated | 3.98% (117903/2962440) | White edge y = 1500, same as the design. |

The thread and the 7s speck stay behind every `02` sheet. The curve is the SVG on that screen: sign-in `250→180`, reset `180→250`, the wizard flat at `136`, submitted `230→170`. Reduced motion hides the speck and keeps the thread. The capture runs with motion off, so the speck is not in the stills. Step dots sit on the dark header. Submitted has no dots. The debug session simulator is not on these screens.

The mismatch table above is the review capture at 1170×2532, full frame, CIE76 ΔE above 6. `02-01` and `02-10` include the hall photograph. Side-by-sides are in `test/goldens/compare/s2/`. `02-12`, `02-12b`, and `02-13` are the designed screens. `flutter analyze` on `lib` and `test` was clean. `flutter test` passed 1572 tests, with 3 skipped (the recording tag).

### S2 deviations

- The full-frame mismatch is above 2%. Sheet edges on `02-02` through `02-09` match the design PNG. The remainder is glyph antialiasing (Skia against Chrome), the downscaled seal, the dashed seam's dash phase, the hall JPEG, and the drawn ID and selfie stand-ins. Those stand-ins are not a photograph of a person.
- `02-11` no longer draws Street/Purok or the address line. Barangay is full width. Each error line is 11.5/700 `#B3261E` with a 14 px circle-alert. The sheet top was not moved.
- Text links keep a 48 dp hit target. The painted line is the design's 12 or 13 px link. The hit box extends past that line.
- The live repository declines password sign-in and registration. It does not call the staff token route. Email codes and password reset call the published routes. The dev mock returns an unverified session named Juana for password sign-in. There is no Firebase SDK.
- `02-10` shows "2 attempts left before a 15-minute pause" on the first refused password, then one fewer, then the pause. The design fixture still paints 2. The password route does not publish that count. Code attempts are a separate counter of 5.
- The help screen still explains a missing one-time code, because registration asks for an email code. Sign-in itself is email or mobile, plus a password.
- `RegistrationScreen` remains for its existing tests. `/register` paints `AccountWizardScreen`.
- `docs/taytay-login-and-session-security.md` and `docs/taytay-registration-wizard.md` still describe the earlier one-time-code flow. The contract gap is the section below.
- `AccountApplication.toString` is `AccountApplication(redacted)`. A failure on submit shows `SignInMessage` text, not the server's message.
- No new package.

## Contract gaps after the Node OpenAPI

F31 is closed. `GET/POST /threads`, messages, mark-read, and close are citizen routes and the live repository calls them.

These designs still need data the spec does not publish. The calls decline with F32, or the screen keeps static copy:

- Citizen password sign-in. There is still no citizen password route. This app does not call the staff token route. The dev mock accepts a password and returns an unverified session. Dev sessions otherwise use `Authorization: Bearer mock:<role>:<id>` with role `registered` or `verified` only.
- Self-registration. `GET /app/config` is wired, and `feature_flags` are strings. There is still no self-registration route. S2 shows Create an account and `/register` because that is the designed resident screen. The live `registerAccount` call declines. The dev mock signs the resident in as unverified and does not upload the ID or the selfie.
- Email verification during registration. `POST /auth/email-otp/send` and `verify` are published, and the app calls them. Send requires a registered session and uses the profile email, with no address in the body. `02-04` runs before an account exists, so a live send can be refused. The screen still advances. The dev mock accepts the same empty body and the same `{code}` verify.
- Code attempt counts and resend timestamps. The `202` body is `{accepted: true}` during the cooldown as well. The client starts a 10-minute code life and a 60-second resend window when that `202` arrives, and counts wrong-code `422`s down from 5. The reset token's `expires_at` is on the verify response and is 15 minutes. `02-12b` is shown when that time has passed. The designed sentence on `02-12b` still says 10 minutes.
- `02-10`'s password pause (2, then 1, then 15 minutes) is the design's notice. It is not a published field.
- Token revocation. Sign-out clears the session on the device. `POST` and `DELETE /me/devices` register a push token. They do not revoke a session.
- Digital ID and QR (`01-02`, account). No credential resource.
- Events catalogue and registration. No events resource.
- Household (`03-07`). Address is a string on `PATCH /me` (`address`). `purok_or_sitio` is not a ProfilePatch field, so it is not sent. Barangay is an id from `GET /barangays` (`id`, `code`, `name` only — no phone).
- Assistance intake, drafts, requirements, and document checklists. Tulong is `GET /services` and `GET /services/{slug}`. There is no apply route.
- Notification types beyond `verification_decided` and `message_received`. Preferences are those two rows, each with `in_app` and `push`. The screen's older categories stay in the app and are not sent as extra wire types. SMS and email are not on the preference contract.
- News comments, reactions, and reports. A resident reads `GET /news`. This app does not call `POST /news` or `PATCH /news`.
- `GET /app/config` does not carry the older bootstrap service name, API version, timezone, channel, or page size. Those stay client defaults. `feature_flags` are strings.
- Hotlines are on `GET /home` and `GET /hotlines`. The hotline screen is still the placeholder. Weather, payments, and map tiles are not published. An office may carry coordinates. The resident decoder does not surface them.
- Welcome copy, photo credits, and a bundled hall photograph. None of those are API fields.
- `UserProfile.role` and `office_id` come back and are ignored. `rejection_reason` is kept off `toString` and is not rendered. `email_verified` is on the profile model. A thread's `resident_id` is the signed-in account and is not stored.
- Verification is `POST /me/verification-requests` (multipart `id_type`, `id_front`, optional `id_back`, `selfie`) and `GET /me/verification-requests/current`. It is not the old multi-step case with a documents list.
