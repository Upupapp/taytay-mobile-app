# Sprint sign-offs

A sprint is approved only when Paul writes the words below on its pull request.
This file records that the words were looked for. It does not invent them.

| Sprint | Status | Pull request | Commit | Approval |
| --- | --- | --- | --- | --- | --- |
| S0 Foundations | Approved by design review | https://github.com/Upupapp/taytay-mobile-app/pull/1 | bc3f75259bff5c6ed5c3ab9bf469a619c15a8d8f | Ui/Ux Taytay, 2026-10-21. Paul merges. |
| S1 Welcome | Approved by design review | https://github.com/Upupapp/taytay-mobile-app/pull/2 | 2ecacd054f7c27ff59c88f4789b7bc25d6a7221f | Ui/Ux Taytay, 2026-10-21. Paul merges. |
| S2 Sign-in | In review, not approved | https://github.com/Upupapp/taytay-mobile-app/pull/3 | 3221abdcea60e6b03fdfa14799417187fa7b1f8c | No approval words. Paul merges when he chooses. |
| S3 Verification | Approved by the owner | https://github.com/Upupapp/taytay-mobile-app/pull/5 | 29e5605fd00e75c942606b11bfc0c4a9ac769049 | The owner wrote "S3 is approved". Pull request #5 is merged. |
| S4 Shell and Home | Approved by design review | https://github.com/Upupapp/taytay-mobile-app/pull/6 | 68f5687a086ae536302ced32c88a77e751ef8502 | Ui/Ux Taytay approved S4 at tip 68f5687. Merged to main at d2636260207fb07c7cbcf2eadcfcf4529b9369ee. |
| S5 Directory | Approved by the owner | https://github.com/Upupapp/taytay-mobile-app/pull/7 | efa968afcae305ccaf832694fb692b76a799a512 | The owner approved S5 at efa968a. Merged to main at 47717668dc51c82ed8bdce8168e7efc7bed22a1f. |
| S6 Balita | In review, not approved | https://github.com/Upupapp/taytay-mobile-app/pull/8 | 5d9d4c41377749b73d301771c3f87d4dc8467c95 | No approval words. |
| S8 My Account | In review, not approved | https://github.com/Upupapp/taytay-mobile-app/pull/10 | cedf0e4f29ffa07755de3a7fe0f0f3adeb6c3ee8 | No approval words. |

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

The control stays a 44 dp circle inside a 48 dp target (`TaytayBackButton`). In-app mockups draw that circle as a 14% white disc with a white Lucide arrow-left (class `hb`). S3 verification screens `03-01` through `03-09` use that translucent disc. The screens below still use the solid white circle:

04-04 Home Hotlines, 04-08 Home Notifications, 05-02 Office-Detail, 05-03 Message-Office-Compose, 05-04 Message-Thread, 05-05 Search-Empty, 05-08 Office-MSWDO, 05-09 Office-Treasurer, 05-10 Office-Assessor, 05-11 Office-MDRRMO, 05-12 Office-PESO, 05-13 Office-PIO, 05-14 Office-Youth-Development, 05-15 Office-Health-Office, 05-16 Message-Sent, 05-17 Compose-MSWDO, 05-18 Compose-Treasury, 05-19 Compose-Assessor, 05-20 Compose-PESO, 05-21 Compose-PIO, 05-22 Compose-TYDO, 05-23 Compose-Health-Office, 06-02 Article-Detail, 06-03 Advisories-Filter, 06-04 Empty-Category, 06-06 Article-RPT-Advisory, 06-07 Article-BOSS-2026, 06-08 Article-SMILE-SAFE, 07-02 Service-Info-Page, 07-03 Social-Services-Centre, 07-04 Programme-Featured, 07-06 Service-PWD, 07-07 Service-Solo-Parent, 07-08 Service-AICS, 07-09 Service-Educational, 07-10 Service-Women-Children, 07-11 Service-PESO-Jobs, 07-12 Service-Youth, 08-02 Messages-Inbox, 08-03 Edit-Profile, 08-04 Settings-Privacy, 08-05 Photo-Credits-About, 08-06 Messages-Empty, 08-07 Thread-MSWDO, 08-08 Thread-Treasurer, 08-09 Privacy-Notice, 08-10 Photo-Credits-Office-Banners.

Welcome scenes `w2` and `w3` draw a solid circle. Onboarding is a navigation root, so the app does not put a back button on it.

### Remaining deviations

- Buttons are three variants, all weight 800. Sign-in: 16 px, pill, height 50, primary shadow `0 8px 20px` at 0.28, outline 1.6 px. Welcome: 16 px, pill, height 52, shadow `0 10px 22px` at 0.30, outline 1.6 px. In-app: 15 px, radius 12, height 48, no primary shadow, outline 1.5 px. Theme filled and outlined buttons use the in-app metrics.
- The guest link is 12/800. The shared `.link` token stays 13/800. Skip is 14/800. Sign-in eyebrow tracking is 1.5. Welcome eyebrow tracking is 1.6. `.sbtn` labels are 12/800; the hit target stays 48 dp.
- The woven header puts the official seal, unaltered, in a 46 px circle (welcome 58 px) with a 2 px white pad and a gold ring. Flutter's line box insets the wordmark, so the header opens the two lines by 4 px and paints the title 5/3 dp higher. Both corrections follow the text scaler. The seal file is not recoloured or redrawn.
- Flutter rounds a CSS line box to a whole logical pixel. On the type scale that is about 4 device pixels by the second line.
- In-app mockups that draw a bare chevron still use the solid white circle. Those screens are listed above. Onboarding is a navigation root, so it has no back button. Welcome scenes `w2` and `w3` draw a circle the app does not show there.
- Welcome and sign-in copy stays the English OTP flow. The mockup is Filipino and asks for a password. Firebase is not in this sprint.
- S4 moves the phone tab bar to Home, Directory, Balita, Tulong, and My Account. Events leaves the bar.
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

## S3 Verification

The owner approved S3 ("S3 is approved"). Pull request #5 is merged into main at `29e5605`. This section records the capture that was merged.

Status screens take the server tier through `AccessLevel.fromVerificationTier` and fail closed. Only the string `verified` is the verified face. `pending` is the pending face. `rejected` is needs-correction. Anything else, including an unknown tier, is unverified. A 409 from `POST /me/verification-requests` opens the pending-review screen. A 403 does not stamp the session verified. The wizard fetches `GET /me`, applies the server tier, and goes home only when that tier is verified. The profile wizard loads its own record and does not write it onto the session. Dates, the email, and the ID type come from `/me` and `/me/verification-requests/current`. `03-04` is the sheet for every verified-only action, including Message and Digital ID. The header is the translucent back disc, with a white Lucide arrow-left, and has no bell. The `03-01` status tile is the hourglass. The `03-05` overview name is the given name and the family name. `lib/features/verification` contains no `Transform.translate`.

The line measure is the reviewer's dark-run rule: any pixel with mean channel under 110, columns 60–1110, y above 330, minimum run 8. Max deviation is the larger of the two nearest-neighbour distances, so an extra or a missing run counts. Where the counts match, that figure is also the in-order pairing. Mismatch is CIE76 ΔE above 6 over the full 1170×2532 frame. Side-by-sides are design | render | heat in `test/goldens/compare/s3/`. On this capture every screen has the same run count as the design, and the symmetric nearest-neighbour distance is at most 2 device px.

| Screen | Lines (build / design) | Max deviation | Mismatch |
| --- | --- | --- | --- |
| 03-01 Pending | 20 / 20 | 2 | 3.19% (94537/2962440) |
| 03-02 Verified | 15 / 15 | 2 | 2.96% (87677/2962440) |
| 03-03 Needs correction | 12 / 12 | 1 | 3.68% (109132/2962440) |
| 03-04 Unverified gate | 8 / 8 | 1 | 2.12% (62850/2962440) |
| 03-05 Profile overview | 15 / 15 | 2 | 3.38% (100061/2962440) |
| 03-06 Personal info | 14 / 14 | 2 | 2.92% (86535/2962440) |
| 03-07 Household address | 16 / 16 | 2 | 3.68% (108884/2962440) |
| 03-08 Review | 15 / 15 | 1 | 2.82% (83581/2962440) |
| 03-09 Submitted | 11 / 11 | 2 | 2.19% (64996/2962440) |

`03-04`'s sheet top is the design's y = 1579. The first 300 px of that frame still mismatch at 9.14% (32090/351000): the office list under the scrim. Per-field correction notes render when the office sent them. The golden leaves that list empty, which is the design PNG. Account created, email, ID type, the office note, the review date, and the submitted stamp are parameters. `VerificationScreen` fills them from `GET /me` and the current verification request. `ProfileWizardScreen` fills the submitted stamp from `GET me/verification-requests/current`. An empty value renders as an em dash, or as a generic sentence when the office sent no note. `lib/features/verification` does not contain `juana.delacruz@example.com`, `Oct 20, 2026`, `(sample)`, or `Transform.translate`. `test/features/s3_tap_target_test.dart` asserts that, and that every `IconButton`, `FilledButton`, `OutlinedButton`, `TextButton`, `InkWell`, and `GestureDetector` is at least 48×48 dp.

Recordings were captured from this build at 1170×2532, motion on, no environment banner, each under 15MB: `test/goldens/compare/s3/recordings/s3-status.mp4` (220524 bytes), `s3-gate.mp4` (106929 bytes), `s3-wizard.mp4` (335424 bytes). `flutter analyze` was clean. `flutter test` passed 1593 tests, with 5 skipped (the recording tag). The S2 stills are byte-identical to the capture before this change, and every `02` screen stays within 2 device px.

## S4 Shell and Home

Ui/Ux Taytay approved S4 at tip `68f5687a086ae536302ced32c88a77e751ef8502`. Pull request #6 was merged into main with a merge commit, `d2636260207fb07c7cbcf2eadcfcf4529b9369ee`. This section records the capture that was approved.

The phone bar is Home, Directory, Balita, Tulong, and My Account in every session state. Balita is the raised centre disc: a 60 dp navy disc inside a 48 dp hit, lifted above the 90 dp bar. Events is a full-screen route with a back button. Programs is a root and has no back button. Hotlines and notifications stay on the Home branch, so the bar remains with Home selected. Each tab keeps its own back stack. `lib/features/shell`, `lib/features/home`, and `lib/features/notifications` contain no `Transform.translate`.

Home paints a gradient header, a bell, an avatar, a three-slide hero, quick actions, a news teaser, and a hotlines entry. Verified home has no status card. Unverified home shows the pending card. Guest home shows the guest card, a Sign in pill, and no badge. The hero auto-advances every 5 seconds and pauses when motion is reduced. Hotline numbers come from `GET /home` when the API returns them, and from the dev mock otherwise. Call uses `tel:` through `dial`. A missing dialer shows a toast. Guests who tap the bell go to sign-in. A signed-in bell opens the notification centre. Mark all read clears the unread dots. Rows follow the notification deep link.

The line measure counts every dark run from the top of the frame. A run is a row whose pixels from x 60 to 1110 average below 110, kept when the run is at least 8 rows. Nothing is dropped for being in the header. An earlier table started the count below the header, so `04-01`, `04-02`, `04-03`, `04-05`, `04-06`, and `04-07` were each reported one run short and the wordmark's 6 device px offset was invisible. Side-by-sides are design | render | heat in `test/goldens/compare/s4/`. On this capture every screen has the same run count as the design, and the in-order pairing is at most 2 device px. Mismatch is CIE76 ΔE above 6 over the full 1170×2532 frame. The hero photographs stay in the count.

| Screen | Lines (build / design) | Max deviation | Mismatch |
| --- | --- | --- | --- |
| 04-01 Home, verified | 18 / 18 | 2 | 5.62% (166607/2962440) |
| 04-02 Home, unverified | 16 / 16 | 2 | 5.92% (175238/2962440) |
| 04-03 Guest home | 14 / 14 | 2 | 5.79% (171467/2962440) |
| 04-04 Hotlines | 14 / 14 | 2 | 3.24% (95903/2962440) |
| 04-05 Pull to refresh | 11 / 11 | 2 | 3.87% (114518/2962440) |
| 04-06 Banner, Tulong | 18 / 18 | 2 | 5.47% (162052/2962440) |
| 04-07 Banner, Directory | 18 / 18 | 2 | 6.10% (180601/2962440) |
| 04-08 Notifications | 26 / 26 | 2 | 4.20% (124472/2962440) |

On guest home the wordmark reads BAYAN NG TAYTAY in full, at letter-spacing 2.2. Sign in is the label plus 16 dp of horizontal padding, 44 dp tall. Create account is the full label at 14/800 plus 14 dp of horizontal padding, also 44 dp tall, on one line. The 1.5 dp stroke is painted in front of that padding. Both keep a 48 dp hit. The guest title stays on one line. The sub-line is 12/500 with line-height 1.5 and a 2 dp gap under the title, and the tile uses the Lucide user glyph. The unverified hero sits on the design row: the spacer under the pending card is 14 dp plus two thirds of a logical pixel, which is 2 device px. S4 is approved at that tip.

The wordmark row sits 2 dp lower than the previous capture. The gap under it is 2 dp shorter, so the lines below the header stay put. Each capture frame has its own key, so `04-06` is the Tulong slide and `04-07` is the Directory slide. The hero photograph occupies the right 58% of the card. Its focus is centre 35%, 30%, and 60% on the three slides. The navy overlay and the gold arc stay. The eyebrow icons are newspaper, hand-heart, and briefcase. Directory uses Lucide building-2 and Tulong uses hand-heart, in the tab bar and on the quick tiles. The tab word is `navTulong`. The page background has the design's top-right gold radial, about 16% opacity, spreading 120% by 60% from the corner. The refresh screen does not. `04-04` and `04-08` keep their back buttons: every page has one, and the designs will be updated to match.

`test/features/s4_tap_target_test.dart` asserts a 48 dp hit on the centre disc, every tab, the bell, the avatar, the hero call to action, the four quick tiles, and every hotline call button. Hero slides are read from `assets/home/slides.json`. A live `GET /home` can replace a slide's title and route when it returns banners. The photograph stays the bundled asset. News rows and hotline numbers in a dev mock still come from `test/fixtures/mock/home_catalogue.json`.

Recordings were captured from this build at 1170×2532, motion on, no environment banner, each under 15MB: `test/goldens/compare/s4/recordings/s4-tabs.mp4` (406679 bytes, 41 frames) and `s4-carousel.mp4` (297621 bytes, 38 frames). The tab clip opens a Directory service, switches to Home, and comes back to that same service. These files are new captures. Their sizes are not the previous S4 recordings and not the S3 recordings.

## S5 Directory

S5 is not approved. This section records the capture. It does not record approval words. The draft pull request is https://github.com/Upupapp/taytay-mobile-app/pull/7. The directory commit is `cb8ae2d329333fa25c3a19860415c94cf28c6350`.

Office pages are public resident information (decision D11). They are not a staff selector, not a role, and not an office a resident signs in as. One `DirectoryCanvas` paints the list, every office, compose, the sent screen, and the thread. A dev mock reads `test/fixtures/mock/offices.json`. Every other build reads `GET /offices` and `GET /offices/{slug}`. There is no per-office widget and no office copy in Dart.

The line measure counts every dark run from the top of the frame. A run is a row whose pixels from x 60 to 1110 average below 110, kept when the run is at least 8 rows. Nothing is dropped for being in the header. Side-by-sides are design | render | heat in `test/goldens/compare/s5/`. On this capture every screen has the same run count as the design, and the in-order pairing is at most 2 device px. Mismatch is CIE76 ΔE above 6 over the full 1170×2532 frame. The office photographs stay in the count. `lib/features/directory` contains no `Transform.translate`.

| Screen | Lines (build / design) | Max deviation | Mismatch |
| --- | --- | --- | --- |
| 05-01 Office list | 24 / 24 | 0.67 | 3.45% (102181/2962440) |
| 05-02 Office detail, BPLO | 18 / 18 | 0.67 | 4.02% (119012/2962440) |
| 05-03 Compose, BPLO | 13 / 13 | 0.67 | 2.28% (67555/2962440) |
| 05-04 Message thread | 17 / 17 | 0.67 | 4.65% (137884/2962440) |
| 05-05 Search, cedula and empty | 20 / 20 | 0.67 | 2.18% (64556/2962440) |
| 05-06 Loading | 7 / 7 | 0.33 | 3.38% (100148/2962440) |
| 05-07 Offline | 13 / 13 | 0.67 | 3.03% (89781/2962440) |
| 05-08 MSWDO | 18 / 18 | 0.67 | 4.09% (121306/2962440) |
| 05-09 Treasurer | 17 / 17 | 0.67 | 3.61% (106871/2962440) |
| 05-10 Assessor | 17 / 17 | 0.67 | 3.75% (111200/2962440) |
| 05-11 MDRRMO | 16 / 16 | 0.67 | 4.17% (123561/2962440) |
| 05-12 PESO | 17 / 17 | 0.67 | 4.58% (135550/2962440) |
| 05-13 PIO | 17 / 17 | 0.67 | 3.83% (113334/2962440) |
| 05-14 Youth Development | 19 / 19 | 0.67 | 4.33% (128307/2962440) |
| 05-15 Health Office | 16 / 16 | 0.67 | 4.37% (129348/2962440) |
| 05-16 Message sent | 15 / 15 | 0.67 | 2.84% (84037/2962440) |
| 05-17 Compose, MSWDO | 15 / 15 | 0.67 | 2.47% (73028/2962440) |
| 05-18 Compose, Treasury | 13 / 13 | 0.67 | 2.05% (60729/2962440) |
| 05-19 Compose, Assessor | 12 / 12 | 0.67 | 2.05% (60598/2962440) |
| 05-20 Compose, PESO | 11 / 11 | 0.67 | 2.04% (60510/2962440) |
| 05-21 Compose, PIO | 12 / 12 | 0.67 | 2.12% (62895/2962440) |
| 05-22 Compose, TYDO | 12 / 12 | 0.67 | 2.02% (59697/2962440) |
| 05-23 Compose, Health Office | 13 / 13 | 0.67 | 2.14% (63296/2962440) |

A guest who taps Message goes to sign-in. A signed-in unverified resident gets the S3 gate sheet (`03-04`). A verified resident opens compose. The route stays verified-only, so a direct link still redirects. Search on the list and on `05-05` is a text field and filters by name and by service. Compose has a topic picker and a message field, and posts `office_id`, `subject`, and `body`. An empty message is refused. A `403` on send refetches `GET /me` and, when the tier is no longer verified, opens `03-04`. The sent screen uses the office on the route. The thread loads through `GET /threads/{id}` and `GET /threads/{id}/messages`. MDRRMO has Call 24/7, Directions, and App. It has no Message action. Dev builds (`TAYTAY_DATA=mock`) send through `MockOfficeMessagingRepository`. Any other build calls `POST /threads`. The resident never sees the server's error message.

Facts the LGU has not confirmed stay in the fixture and wear the SAMPLE tag: Assessor location, Tax Declaration copies, and property reassessment; PESO vacancies and employment counselling; PIO location and media coverage; Youth SK coordination. The thread is marked SAMPLE. No sample sentence is hardcoded in Dart.

The header seal is the municipal seal on a white pad, with no gold ring. Back buttons are a 44 dp disc inside a 48 dp hit. `test/features/s5_directory_test.dart` covers the catalogue, the 48 dp hits, the back button, and Message from guest, unverified, and verified.

The frame for `05-04` still reads the fixture's `day` field. The live thread screen formats the message time in Manila time and does not take the chip from the clock. The `05-04` comparison uses the updated design (`18_v_Fsh4K51mZwb5Dlp09br6TdDhSdqx`). The bubble layout was not changed.

The offline saved list is a fixed emergency default: MDRRMO, then MSWDO. It is not read from storage and it is not the last list the phone fetched.

Recordings were captured from this build at 1170×2532, motion on, no environment banner, 8 fps, each under 15MB: `test/goldens/compare/s5/recordings/s5-office.mp4` (956794 bytes, 29 frames), `s5-message.mp4` (1277487 bytes, 78 frames), and `s5-gate.mp4` (845421 bytes, 31 frames). The office clip opens BPLO and comes back to the list. The message clip types a search, opens BPLO, types a message, and sends. The gate clip is a guest tapping Message and reaching sign-in, with the Lucide log-in mark on the button. These sizes are not the previous captures. `flutter analyze` was clean. `flutter test` passed 1618 tests, with 9 skipped (the recording tag).

## S6 Balita

S6 is not approved. This section records the card and byline correction, the line-box correction, the round-1 capture, and the sync to backend `6f4c582` and `f32a631`. It does not record approval words. The draft pull request is https://github.com/Upupapp/taytay-mobile-app/pull/8. The card commit is `5d9d4c41377749b73d301771c3f87d4dc8467c95`. The line-box commit is `d437ddf052bdcb915958d9869c3ca4dd73843814`. The round-1 commit is `18b00183c0eedd04225067b2f5b984340edb0903`. The first Balita commit is `ad8e88e11f8696febdd8d9d80e8f974d72e18094`.

Balita is the centre tab. `/news` and `/news/:postId` stay public, so a guest, an unverified resident, and a verified resident read the same list and the same article. The article header paints one translucent back disc, 44 dp across, with a 48 dp hit. The shell tab bar stays. This app does not call `POST /news`, `PATCH /news/{id}`, or `POST`/`DELETE /news/{id}/pin`.

One `BalitaCanvas` paints the feed, a category filter, an empty category, an empty feed, the loading bones, the failed state, and the article. A dev mock reads `test/fixtures/mock/announcements.json`. Every other build reads `GET /news`, `GET /news/{id}`, and `GET /news/categories`. Lahat is client-side and sends no `category`. The other chips send the lowercase slug. The list follows `meta.pagination.next_cursor`.

The line measure for this capture is `rev5.py`: every dark run from the top of the frame. A row is dark when any pixel from x 60 to 1110 has a mean RGB below 110. A run shorter than 8 rows is dropped. Pairing is in order. Deviation is image pixels on the 1170×2532 frame. Side-by-sides are design | render | heat in `test/goldens/compare/s6/`. Mismatch is CIE76 ΔE above 6 over the full frame. The photographs stay in the count. `lib/features/news` contains no `Transform.translate`.

The shared header title is a 16 dp block and the subtitle is 11 dp text on a 16 dp line. On this capture the title ink starts at y 158 or 159 (design 157) and the subtitle ink starts at y 229 or 230 (design 229 or 230). The same header is on the directory screens. Re-rendered side-by-sides are in `test/goldens/compare/s5/`.

| Screen | Lines (build / design) | Max deviation (image px) | Mismatch |
| --- | --- | --- | --- |
| 06-01 News feed | 19 / 19 | 2 | 2.92% (86537/2962440) |
| 06-02 Article, PWD | 18 / 18 | 2 | 2.26% (66876/2962440) |
| 06-03 Advisories filter | 24 / 24 | 2 | 3.40% (100688/2962440) |
| 06-04 Empty category | 11 / 11 | 2 | 1.94% (57345/2962440) |
| 06-05 Loading | 6 / 6 | 1 | 1.03% (30557/2962440) |
| 06-06 Article, RPT | 19 / 19 | 2 | 2.03% (60099/2962440) |
| 06-07 Article, BOSS | 19 / 19 | 1 | 2.09% (61927/2962440) |
| 06-08 Article, SMILE | 18 / 18 | 2 | 2.44% (72255/2962440) |
| 05-01 Office list | 24 / 24 | 2 | 3.25% (96208/2962440) |
| 05-02 Office detail | 18 / 18 | 2 | 3.87% (114639/2962440) |
| 05-04 Message thread | 17 / 17 | 2 | 4.38% (129816/2962440) |

Every frame in the table is within 2 image px. S6 stays unapproved. The directory rows were not re-rendered. The header is unchanged, so `05-01`, `05-02`, and `05-04` stay at the numbers above.

The gap after the banner and after every card is 12 dp. Photo cards and the loading bones use 16 dp of padding on every side. The 1 dp border is painted on that box. A text card and the sample use 16 dp on the left, right, and bottom, and 15 dp on the top. A 16 dp top inset places the first line 3 px below the specimen, and that line already sits at the edge of the 2 px window. The banner uses the same 15 dp top, which is the height of the specimen banner. Photo titles sit on the CSS line advance. The summary margin is the stylesheet's 4 dp. Padding of 17 dp, the border plus 16, places the skeleton bones 12 px past the design and takes `06-01` and `06-03` past 2 px. The skeleton at 16 dp matches the design bone spans, and `06-05` mismatch is 1.03%.

The article lead is `.cs` at 14 / 500 / 1.6. The engine rounds 22.4 dp to 22, so each lead line sits on the unrounded 22.4 dp advance, with a strut at that leading (`forceStrutHeight`, even distribution). A fact value is `.lt` at 13 / 700 with no line-height, so the advance is the font's normal 1.26 (16.38 dp), placed the same way. A fact label is `.ls` at 12 / 700 on that same normal (15.12 dp); the rounded 15 dp line sits on the bottom of the 15.12 dp advance. The facts card uses the stylesheet's margin-top 12 and padding 4 × 16. The sample card uses the text-card inset and no title margin. The SAMPLE chip's text is normal 1.26, so the eyebrow line is the inline box. `05-01`, `05-02`, and `05-04` were re-rendered after that chip change and stayed at max 2.

The designed frames are specimens. `06-03` paints the pinned advisory, the RPT card, the SMILE card, and the weather sample together. A live Advisory filter is category equality and does not invent that mix. Cover assets, photo credit, a lead, fact rows, and the sample tag live on `BalitaPresentation`, and only the fixture sets them. A live article with no presentation shows the body.

Synced to backend `6f4c582`, with `short_name` from `f32a631`:

- `cover_url` is the live cover. It is null on a draft or when there is no cover. Fixture covers stay bundled assets. The −2 RGB filter is only on those fixture article photographs.
- `pinned` and `pinned_at` come from the list. The server already lists pinned items first, including under a category filter. A live pinned item shows "Pinned advisory" and the article title. The `06-03` specimen still uses the fixture's `pinned_title` and `pinned_body`. Staff pin and unpin are not called.
- `share_url` is sent with the share. An empty string is treated as no URL. This app does not compose a URL from the host and the id. A production `share_url` is https, so the client sends the value as published.
- `GET /news/categories` returns `{slug, label}`. The chips are that list, with Lahat added on the client. The dev mock returns the design set. The category query is the lowercase slug.
- Bookmarks are not on the contract. There is no save method and no save request. Save still says "Saving a story is not available yet." Leaving `/news` clears that message.
- There is no `office_name` on `NewsItem`. A live card resolves `office_slug` through `GET /offices`. The byline is `short_name` when that field is a string, then `name`, then the slug. Backend `f32a631` publishes `short_name` as a string or null on `GET /offices` and `GET /offices/{slug}`. A null short name, as on the assessor, uses the name. The byline is one line and ellipsizes. A failed offices read is not stored, so the next list asks again. A completed read is cached. The dev mock joins the same field. Seeded labels in the fixture are MSWDO, BPLO, Treasury Office, PIO, MHO, and MDRRMO. The directory catalogue still reads its own `shortName` for the S5 header, so those screens keep their labels.

Comments, reactions, and reports stay off the article page. Those calls still decline. The not-available copy is unchanged: "This announcement is not available" and "See all announcements". The bell goes to sign-in for a guest and to notifications for a signed-in resident. Icons are Lucide: the safety tile and the Command Center row use siren, the weather sample uses cloud-rain, and the empty category uses calendar-x. The BOSS "Opened" fact stays calendar.

Recordings were captured from this build at 1170×2532, motion on, no environment banner, 8 fps, each under 15MB: `test/goldens/compare/s6/recordings/s6-article.mp4` (2179907 bytes, 61 frames) and `s6-filter.mp4` (2977029 bytes, 103 frames). The article clip scrolls the feed, shows "Saving a story is not available yet.", opens the PWD story, and comes back. The filter clip scrolls, opens Events, returns through See all announcements, opens an article, and comes back. `flutter analyze` was clean (`No issues found!`). `flutter test` passed 1625 tests, with 11 skipped (the recording and live tags).

## S7 Tulong

S7 is not approved. This section records the information pages for municipal social services. It does not record approval words.

Tulong is the shell tab at `/programs`. The list and each programme page are public, so a guest, an unverified resident, and a verified resident read the same pages. The list is a shell root and has no back button. Every programme page and the social services centre use `TaytayBackButton` (44 dp disc, 48 dp hit). There is no apply control and no submit. `/services/:serviceCode` and `/apply/:serviceCode` both redirect to `/programs/:slug`. The catalogue detail screen and the assistance intake are gone.

Live reads are `GET /services` and `GET /services/{slug}`, public, with the session token attached when one exists. Office hours and the short name come from `GET /offices`. The dev mock (`TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`) reads `test/fixtures/mock/tulong_services.json`. Staging and production refuse mock mode. `GET /programs` is still absent. `ProgramApiRepository` still declines that call and Tulong does not make it.

The line measure is `rev5.py`: every dark run from the top of the 1170×2532 frame. A row is dark when any pixel from x 60 to 1110 has a mean RGB below 110. A run shorter than 8 rows is dropped. Pairing is in order. Deviation is the start row, in image pixels. Side-by-sides are design | render | heat in `test/goldens/compare/s7/`. Mismatch is CIE76 ΔE above 6 over the full frame. `lib/features/tulong` contains no `Transform.translate`.

Card edges are the 1 dp `#E7EBF3` border rows (exact RGB 231, 235, 243, more than 400 of those pixels in x 120–1050). A run of those rows is one edge. The tab-bar edge is not a content card. Deviation is the start row, render minus design.

| Screen | Lines (build / design) | Max line | Max card edge | Mismatch |
| --- | --- | --- | --- | --- |
| 07-01 Programme list | 16 / 16 | 1 | 0 | 2.14% (63297/2962440) |
| 07-02 OSCA | 19 / 19 | 2 | 1 | 3.23% (95641/2962440) |
| 07-03 Social services centre | 18 / 18 | 2 | 1 | 3.90% (115541/2962440) |
| 07-04 Featured programme | 18 / 18 | 2 | 1 | 4.62% (136763/2962440) |
| 07-05 Offline | 14 / 14 | 2 | 0 | 2.03% (60237/2962440) |
| 07-06 PWD assistance | 20 / 20 | 2 | 0 | 3.64% (107825/2962440) |
| 07-07 Solo parent | 21 / 21 | 2 | 1 | 3.47% (102838/2962440) |
| 07-08 AICS | 20 / 20 | 2 | 1 | 3.39% (100527/2962440) |
| 07-09 Educational assistance | 22 / 22 | 2 | 0 | 3.17% (94044/2962440) |
| 07-10 Women and children | 20 / 20 | 2 | 1 | 3.18% (94262/2962440) |
| 07-11 PESO jobs | 19 / 19 | 2 | 0 | 3.70% (109504/2962440) |
| 07-12 Youth | 20 / 20 | 2 | 0 | 3.50% (103818/2962440) |

Every frame is within 2 image pixels on both lines and card edges. Light mode and Plus Jakarta Sans only.

`07-03` is the existing directory office page for MSWDO, inside the Tulong shell. The office fixture was not edited.

`Service` on taytay-backend `7293051` publishes the fields Tulong paints. The live decoder reads them. A colour that is not `#RGB` or `#RRGGBB` is left unset and the tile stays the blue pair. An unknown `icon_key` is `handHeart`. `users-round` is Lucide codepoint 58478. The vendored font names that glyph `users-2`.

- `icon_key`, `tile_color`, `badge`, `legal_basis`, `claim_steps` (default `[]`), `featured_headline`, `schedule`, `hero_url`, and `hidden_from_list` are on the service. The hero chip is the badge, then the office `short_name`.
- The featured layout is used only when `featured_headline` and at least one claim step are both present. `featured: true` alone stays on the standard page.
- `GET /services` omits `hidden_from_list`. `GET /services?featured=true` returns featured services and includes ones hidden from the catalogue. A hidden service still opens by slug.
- Contacts are `{type, label|null, value}` with type `facebook`, `landline`, `hotline`, `email`, or `mobile`. An unrecognised type is still shown. A label that names the anti-trafficking line keeps the siren glyph.
- `hero_url` is stored. It is null until an image is stored. `GET /services/{slug}/hero` returns the bytes and this app does not fetch them. A null URL keeps the icon tile.
- No hours field. A contact whose label contains "hour" is shown as sent. Otherwise the hours row uses `GET /offices` when that office has an hours string.
- No SAMPLE flag. A live requirement is never marked sample. The dev fixture may still mark one.
- No saved-pages resource and no saved-at. A live failure lists services already decoded in this process, newest first, at most 20, with the summary as the second line. Nothing is written to device storage. The offline specimen dates are fixture `saved_label`.
- No apply or submit control. `/services/:serviceCode` and `/apply/:serviceCode` both redirect to `/programs/:slug`. The catalogue detail screen and the assistance intake are gone.
- Locations are `{name, address}` only.

Message follows the directory gate. A guest sees "Sign in to continue". An unverified resident sees "Verify your account to message offices". A verified resident opens the existing composer at `/offices/:officeId/message`. Share sends the title and the body and does not invent a URL. Call and directions use the published phone and address. An empty phone or address is app copy, not the server message.

The note under the list says "Information on municipal programmes. These are information pages, not applications." Its padding matches the stylesheet, 10 dp below the note. The list card is padded 3 dp on the top and the bottom, which is what puts that card's edges on the specimen. The requirements card gives 4 dp of the extra bottom padding back, and the facts card takes the same 4 image px as top padding, so the fact lines stay put while the borders move. The featured steps card and the card under it do the same. The saved-pages card is 2 dp taller at the bottom. Card content is inset 1 px on the left and the right so a 1 px border consumes width the way CSS `border-box` does. A vertical inset moves every line by 3 image pixels and is not used. The search field is drawn at 44 dp. Its hit target is 48 dp and does not move the ink. The list bell is the same: a 44 dp circle inside a 48 dp hit, so the header row stays the height of the specimen. A primary action label ellipsizes when a large text size no longer fits the button. At the specimen scale the label still sits in the centre. A requirement marked SAMPLE keeps the chip on the last text line when it fits. Women and children use Lucide heart-pulse. PESO uses briefcase-business. Youth uses `users-round` (codepoint 58478, font name `users-2`) through `TaytayIcon` on the list tile, the page tile, and the watermark. OSCA stays on the `users` glyph. Side-by-sides for `07-01` and `07-12` were repainted after that glyph change. Both stay within 2 image pixels on lines and on card edges.

Leaving `/news` still clears the Balita save message. `test/features/s6_balita_test.dart` saves a story, opens the article, and also leaves Balita for Home. The snackbar is gone in both cases.

Recordings were captured again from this build at 1170×2532, motion on, no environment banner. Every frame advances 33 ms and the file is 30 fps, so playback is real time: `test/goldens/compare/s7/recordings/s7-detail.mp4` (1425612 bytes, 210 frames, 7.0 s) and `s7-office.mp4` (2522864 bytes, 300 frames, 10.0 s). The detail clip opens PWD assistance and comes back to the list. The office clip opens PWD assistance, opens the social services centre, and comes back. Both play the route transition through. `flutter analyze` was clean (`No issues found!`). `flutter test` passed 1611 tests, with 13 skipped (the recording and live tags).

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
- Household (`03-07`). `PATCH /me` sends `street` and `purok`. The resident household calls are `GET` and `PATCH /households/current` and `POST /households`. Years at the address, residence type, and member count are not on the spec, so the live repository does not send them. The dev mock does. Barangay is an id from `GET /barangays` (`id`, `code`, `name` only — no phone).
- Assistance intake and submit. `/apply/:serviceCode` redirects to `/programs/:slug`. Requirements on an existing case stay in the app and still decline. Tulong is `GET /services` and `GET /services/{slug}`.
- Notification types beyond `verification_decided` and `message_received`. Preferences are those two rows, each with `in_app` and `push`. The screen's older categories stay in the app and are not sent as extra wire types. SMS and email are not on the preference contract.
- News comments, reactions, and reports. A resident reads `GET /news`. This app does not call `POST /news` or `PATCH /news`.
- `GET /app/config` does not carry the older bootstrap service name, API version, timezone, channel, or page size. Those stay client defaults. `feature_flags` are strings.
- Hotlines are on `GET /home` and `GET /hotlines`. The hotline screen is still the placeholder. Weather, payments, and map tiles are not published. An office may carry coordinates. The resident decoder does not surface them.
- Welcome copy, photo credits, and a bundled hall photograph. None of those are API fields.
- `UserProfile.role` and `office_id` come back and are ignored. `rejection_reason` is kept off `toString`. The needs-correction screen shows it as the office's note to the resident. `email_verified` is on the profile model. A thread's `resident_id` is the signed-in account and is not stored.
- Verification is `POST /me/verification-requests` (multipart `id_type`, `id_front`, optional `id_back`, `selfie`) and `GET /me/verification-requests/current`. It is not the old multi-step case with a documents list.

## S8 My Account

S8 is not approved. This section records the My Account screens. It does not record approval words. Round 2 removes the fitted spacing and paints the review's structure: pills, tiles, the badge-check mark, the inline Replace chip, and a profile save that does not write the legal name. Spacing is the 4-point scale (`Spacing`) and the type roles (`.lt` 14/800/1.2, `.ls` 12/500/1.2, `.sub` 13/500/1.5, `.pill` 11/800/1.2). A miss outside 2 image pixels is reported below. It is not closed with a fraction. The side-by-sides, the crops, and both clips are the round-2 commit named in the index. Pull request #10 is a draft.

My Account is the shell tab at `/profile`. A guest and an unverified resident keep the account centre: the guest copy is "You are browsing as a guest", and a guest issues no personal read. A verified resident sees the 08-01 home. The badge comes from the server tier through `AccessPolicy`. A failed profile read shows the unavailable state and does not paint the specimen. Sign out asks, then clears the session. There is no apply control and no submit.

`/profile` is a shell root and has no back button. Every other account screen uses `TaytayBackButton` (44 dp disc, 48 dp hit). The inbox stays on the My Account branch, so the tab bar remains. The thread stays on that same branch. The shell hides the bar for `/messages/`, so the thread fills the phone, and coming back does not build a second shell during the transition.

Live reads are `GET /me`, `PATCH /me` (only the changed keys among `mobile`, `email`, and `barangay_id`), `GET /threads`, `GET /me/notification-preferences`, and `GET /app/config` for the privacy notice. `ProfilePatch` has no display-name field. `name` is the legal name, so the live editor does not show Display name and never sends `name`. The specimen still paints Display name, because 08-03 does. The dev mock (`TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`) supplies the synthetic resident. Staging and production refuse mock mode. Photo credits stay on the bundled photograph manifest.

The line measure is the same dark-run method as S7: a row is dark when any pixel from x 60 to 1110 has a mean RGB below 110. A run shorter than 8 rows is dropped. Pairing is in order. Deviation is the start row, render minus design. Where the render has one extra run, the in-order maximum is left blank and the remainder is described under the table. Side-by-sides are design | render | heat at 3510×2532 in `test/goldens/compare/s8/`. Mismatch is CIE76 ΔE above 6 over the full 1170×2532 frame (2,962,440 pixels). `lib/features/account` contains no `Transform.translate`, and a credit byline is its own line.

Card edges are the 1 dp `#E7EBF3` border rows (exact RGB 231, 235, 243, more than 400 of those pixels in x 120–1050). A run of those rows is one edge. The tab-bar edge at y 2262 is the 90 dp bar. Deviation is the start row, render minus design. Edit-field borders are `#D6DCE8` on white, so they are not counted as cards.

| Screen | Lines (build / design) | Max in-order line | Max card edge | Mismatch |
| --- | --- | --- | --- | --- |
| 08-01 Account home | 14 / 14 | 43 | 53 | 9.94% (294391/2962440) |
| 08-02 Messages inbox | 10 / 9 |  | 12 | 2.98% (88152/2962440) |
| 08-03 Edit profile | 18 / 18 | 59 | 54 | 10.85% (321278/2962440) |
| 08-04 Settings and privacy | 15 / 15 | 54 | 45 | 8.37% (248081/2962440) |
| 08-05 Photo credits | 16 / 15 |  | 61 | 10.61% (314451/2962440) |
| 08-06 Messages empty | 11 / 11 | 12 | 0 | 3.34% (98887/2962440) |
| 08-07 Thread, MSWDO | 16 / 16 | 38 | 32 | 9.75% (288915/2962440) |
| 08-08 Thread, Treasurer | 16 / 16 | 35 | 31 | 7.38% (218691/2962440) |
| 08-09 Privacy notice | 22 / 22 | 47 | 45 | 8.10% (239847/2962440) |
| 08-10 Office banners | 30 / 33 |  | 1 | 10.47% (310077/2962440) |

Light mode and Plus Jakarta Sans only. 08-00 is the overview board and is not a phone screen. A blank max line means the run counts differ, so an in-order maximum would pair the wrong rows. Those screens are described under the table.

The misses are the design value against the token that replaced the fitted number. They were not pulled back onto the frame.

- List rows use a 44 dp tile and `Spacing.md` (12) vertical padding, which is `.li`. The home and settings stacks still start high: 08-01's first menu line is 563 against 570, and the sign-out card edge is 1956 against 2009 (53 px). 08-04's first row is 500 against 511, and the privacy card edge is 1719 against 1764 (45 px). Row titles are `.lt` (14/800/1.2). Settings dividers are inset by `Spacing.lg` and land on the design's x 99–1070.
- 08-02's list inset is `Spacing.xxl` (32). The All pill is y 408–515, x 48–188, against the design's y 396–503, x 48–181. The height matches (108 px). The top is 12 px low and the pill is 7 px wider. `Spacing.xl` (24) would put the same pill 12 px high. The removed 28 dp inset is not on the scale. Unread is a white pill with a `#E7EBF3` border, y 408–515, x 214–436, against y 399–499, x 209–413. The Treasurer row starts at 1041 on both images and splits into 1041–1097 and 1103–1136, because the landmark glyph still has a hole and the timestamp is not moved onto it. That is the extra run (10/9). BPLO starts at 598 against 596. MSWDO starts at 834 on both. Crops: `test/goldens/compare/s8/artifacts/08-02-landmark-time.png`, `08-02-office-time.png`, and `08-02-filters.png`.
- 08-03's field stack uses `Spacing.lg` card padding and `Spacing.md` between fields. The card edge is 1833 against 1779 (54 px). The last line is 1872 against 1818 (54 px). The specimen still shows Display name. The live screen does not.
- 08-06's gap under the empty mark is `Spacing.xxl` (32). The title run is 885 against 896 (11 px). The frame's gap is about 40 dp, which is between `Spacing.xxl` (32) and `Spacing.xxxl` (48). Card edges match.
- 08-07 and 08-08 use `.sub` line height 1.5 (13/500) and a day-pill gap of `Spacing.sm`. The bubble card edges finish 32 px and 31 px low (1446 against 1414, and 1605 against 1574). The removed line height was 56/39.
- 08-09's notice card uses `Spacing.lg` padding. Its border run is (1608, 1610) against the design's (1563, 1565), 45 px low. The SAMPLE chip stays at the end of "Your rights", after one space. The amber box is y 1467–1526, x 706–898, against y 1448–1514, x 695–887. The top is 19 px low, the left edge is 11 px to the right, and the chip is 7 px shorter (60 against 67). The width matches (193 px). Crop: `test/goldens/compare/s8/artifacts/08-09-sample.png`.
- 08-10's list card border is (576, 578) against (575, 577). That is the edge that was 593 against 596. The intro Replace chip is inside the sentence: y 361–426, x 903–1082, against y 360–427, x 909–1094. The top matches within 1 px. The chip is 2 px shorter (66 against 68) and 6 px to the left. The relief row chip is centred on the title and the byline, with no extra offset: y 723–788, x 891–1070, against y 692–750, x 885–1070. The right edge matches. The top is 31 px low. Both chips use `Spacing.sm` horizontal and `Spacing.xs` vertical padding around `.pill` (11/800/1.2), so they are 66 px tall against the row chip's 59 px (7 px) and 180 px wide against 186 px. The design's second chip, y 2049–2107, is below the rows this spacing paints, so the render has 30 runs against 33. Crops: `08-10-replace-intro.png`, `08-10-replace-relief.png`, and `08-10-replace-bfp.png`.
- 08-05 has 16 runs against 15, and its last card edge is 1980 against 2041 (61 px). The credit rows use the same 44 dp tile and `Spacing.md` padding. The version line keeps the hard break before "mockup" and uses `.ls` line height 1.2. The removed height was 59/36.
- One ratio remains, and it is not a gap: the page wash stops at 260/844, the top 260 dp of the 844 dp frame.

Round 1 structure:

- 08-01: Resident Profile is the id-card icon. Verification is a shield on a green tile. Privacy is a lock on blue. Photo credits and Messages are blue tiles. Messages carries a count badge. The bell has an unread dot. The JD initials are taytay blue at extra-bold (`.lt`). Verified uses the Lucide badge-check icon.
- 08-02: All is a blue pill. Unread is a white pill with a `#E7EBF3` border. BPLO uses the briefcase icon and carries a 1 badge. The Treasurer tile is blue.
- 08-03: an 80 dp JD avatar with a camera badge, bordered fields, and Verified chips that use badge-check. Save has no extra check. The specimen keeps Display name. The live screen does not, and Save sends only the fields that changed.
- 08-04: Balita, Office replies, and Privacy Notice are blue tiles. Emergency stays red. Change password is a blue tile with no subtitle. Section headers are bold title case (Notifications, App, Privacy). Row titles are `.lt` (14/800). Dividers are inset by `Spacing.lg`.
- 08-05: the same header. Each credit row is a 44 dp image tile, a title, a separate byline, an external-link icon, and a divider. The seal row is a blue shield. The banner row is the images icon. The design pixels for those welcome rows are the icon on a blue tile.
- 08-07 and 08-08: the day label is a small pill.
- 08-09: an amber DRAFT pill, a SAMPLE chip, a download icon, and a bold button label.
- 08-10: blue bold office labels, amber right-aligned Replace chips, and row dividers.

Data export is in the design and out of scope on the API. 08-04 draws "Request a copy" and 08-09 draws the outline button. Clarence said data export is out of scope, and there is no export route. The specimen keeps both rows so the stills match the design. Live settings and the live notice pass `showDataExport: false`, so a resident never sees the row and the app never sends an export request. This is the flag for that row.

The five people photographs are marked Replace: DSWD relief, BFP rescuers, TESDA skills training, Sangguniang Kabataan council, and Vaccination, Camarines Sur. The youth-court title is "SK basketball court". Titles, offices, and licences follow the design, including "Rescue vehicle, Bula", "Sangguniang Kabataan council", "Barangay health center, Bula", TYDO, and "Public domain (PH gov)".

The SAMPLE line on the live inbox and the live thread is painted only when `usesMockData` is on. The day chip is omitted when the live screen passes an empty day label.

Edit profile uses real text fields for mobile and email, and a barangay picker. Display name is not on the live screen: `ProfilePatch` has `name` and no display-name field, and `name` is the legal name. Save sends `PATCH /me` with only the keys that changed among `mobile`, `email`, and `barangay_id`. An unchanged form does not call the repository. A test covers each of those maps, and that `name` is absent. The specimen field stays so 08-03 still shows the design's four fields.

A failed inbox load shows "Messages did not load" and a Retry button. The empty-list copy stays for a successful empty list. A test covers the failure.

The bundled DRAFT notice is painted only outside production, and only when the published version is `placeholder`, the object is missing, the body is empty, or the load fails. Production uses `body_markdown` when that body is published, and otherwise shows the pending sentence with no DRAFT pill and no SAMPLE chip. The 08-09 still keeps the draft because the specimen default is the design.

The About version string still breaks before "mockup". That break stays for S9.

The attached `openapi_7293051.json` was not in this workspace. Account models follow the committed Node OpenAPI (`docs/integration/taytay-node-openapi.json`), including the fields from backend `3e3b110`. The specimen date on 08-01 stays fixture copy. The live home paints `verification_decided_at` as a Manila calendar date when the field is an ISO time, and leaves the subtitle "Verified" when it is null.

- Balita and emergency are preference types, each `in_app` and `push`, defaulting to on. The live settings rows write both flags. The specimen emergency row stays locked.
- `GET /app/config` publishes `privacy_notice` with `version`, `updated_at`, and `body_markdown`. A published version is rendered on the live notice in every environment. The dev mock sends `placeholder`.

Applied now:

- Profile completion is computed on the client. The API does not publish a figure. Ten resident-fillable `GET /me` columns count: name, birthdate, sex, mobile, email, barangay, street, the free-text address, purok, and an avatar. System columns are left out. The live home paints the rounded percent. The specimen "60% complete" stays fixture copy. `profileCompletionPercent` is covered at 0, 60, and 100.
- There is no phone verification. The live edit screen paints the email chip only. The specimen still paints a mobile chip.
- There is no email notification channel. Live toggle subtitles say "Push notifications". The specimen still says "Push and email".
- Change password uses the Firebase client: `reauthenticateWithCredential`, then `updatePassword`. A dev mock build and the tests use `MockAccountPasswordClient` and do not talk to Firebase. Field errors are app copy. The live change-password row has no subtitle.
- Photo credits stay on the bundled manifest. The test compares the list to the asset keys.
- A thread label joins `GET /offices` and uses `short_name` when that field is a non-empty string, then `name`. A failed offices read leaves the slug.

Also still true:

- A live thread is never marked sample. The mock may mark one, and the SAMPLE line follows `usesMockData`.
- Avatar upload exists. There is no "reviewed by the LGU" status. The edit screen shows that sentence as copy.
- A digital-ID resource exists. 08-01 does not show it, and this sprint adds no digital-ID row. The existing row stays on `/profile/record`.
- The design says "14 photos". That is the office-banner count (the hall, shared, plus 13 office-only photographs). The manifest has 16 photographs, because the three welcome photographs are credited on 08-05 and the hall is in both lists. The office-banner summary uses the office-banner length.

`ProfilePatch` from the live editor sends only changed `mobile`, `email`, and `barangay_id`. It does not send `name`, `role`, `office_id`, `verification_status`, `rejection_reason`, or `email_verified`.

Recordings were captured again from this build at 1170×2532, motion on, no environment banner. Every frame advances 33 ms and the file is 30 fps: `test/goldens/compare/s8/recordings/s8-messages.mp4` (482948 bytes, 124 frames, 4.133 s) and `s8-settings.mp4` (853277 bytes, 124 frames, 4.133 s). The messages clip opens the inbox, opens the MSWDO thread, and comes back. The settings clip opens Settings, opens the privacy notice, and comes back. Both play the route transition through. The live home paints the computed percent, the decision date, and the messages badge. The live settings write balita and emergency. The notice stays on the bundled draft because the mock version is `placeholder` and the recording environment is dev. `flutter analyze` was clean (`No issues found!`). `flutter test` passed 1645 tests, with 15 skipped (the recording and live tags).
