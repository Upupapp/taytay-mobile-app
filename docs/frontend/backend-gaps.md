# Backend integration gaps

**First audit:** 26 October 2026, app `a7c8d5f`, static, against the attached OpenAPI export named for backend `3e3b110`.
**Refresh:** 28 October 2026, mobile `main` `908896d` (`Merge pull request #19 from Upupapp/feature/digital-id-card`).
**Branch:** `docs/backend-gaps`. `origin/main` was merged in with `git merge` (fast-forward to `908896d`; no rebase, no force-push). Pull request #14, which carried the first audit, was already merged to `main` as `5f43c6b` on 26 October 2026.

A non-mock build loads `test/fixtures/mock/` only when `usesMockData` is true (`TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`). Staging and production have no baked-in API host. A release build without `--dart-define=TAYTAY_API_BASE_URL` refuses to start (`lib/core/config/app_config.dart`). Dev debug, with the define unset, still uses the Android emulator alias for the host machine.

## How this refresh was run

Static. No resident session was created and no personal data was sent.

`Upupapp/taytay-backend` is still not readable from this environment (`gh repo view` and `git ls-remote` both return repository not found) on 28 October 2026. Backend `main` could not be cloned, so a commit newer than the vendored spec cannot be confirmed.

The latest OpenAPI this environment can read is `docs/integration/taytay-node-openapi.json` at mobile `908896d`. Mobile pull request #15 (`ab2896c`) replaced that file with the `3e3b110` export: 74 paths, the same document the first audit called newer than the old vendored copy. The drift table from 26 October is closed. `GET /api/v1/services/{slug}/hero`, the Tulong presentation fields, required `ServiceContact.type`, required `UserProfile.verification_decided_at`, and required `AppConfig.privacy_notice` are in the vendored file.

Every row below was scored against backend `3e3b110`, the short id of that spec. The full SHA is not in this clone. Where a route is missing, it is missing at `3e3b110`. Where a route is present, it was already present at `3e3b110` and the mobile change is named separately.

Deferred items must not be built by the backend until Paul approves them.

The 26 October probes (staging and production hostnames that are no longer compiled in, and the emulator alias) did not reach an API. They were not repeated.

## Status

| # | Gap | Status | Endpoint | Backend |
| --- | --- | --- | --- | --- |
| 1 | Sign in | Closed | Firebase SDK, then `GET /api/v1/me` | `3e3b110` (no HTTP sign-in route; bearer is a Firebase ID token) |
| 2 | Create account | Closed | Firebase SDK, then `GET /api/v1/me`, then `POST /api/v1/me/verification-requests` | `3e3b110` |
| 3 | Verification start, documents, corrections | Partly closed | `GET /api/v1/me/verification-requests/current`, `POST /api/v1/me/verification-requests` | `3e3b110` |
| 4 | Profile name split | Deferred (needs Paul's approval) | `PATCH /api/v1/me` sends one `name`. A given, middle, and family split is not on `ProfilePatch` | `3e3b110` |
| 5 | In-session password change | Closed | Firebase `updatePassword` (no HTTP route) | `3e3b110` |
| 6 | Other signed-in sessions | Deferred (needs Paul's approval) | `GET me/sessions` is not in the spec. `POST`/`DELETE /api/v1/me/devices` is a push token | `3e3b110` |
| 7 | Directory photos and service lines | Partly closed | `GET /api/v1/offices`, `GET /api/v1/offices/{slug}` | `3e3b110` |
| 8 | Balita cover bytes | Partly closed | `cover_url` on `GET /api/v1/news/{id}`. `GET /api/v1/news/{id}/cover` is not called | `3e3b110` |
| 9 | Balita comments, reactions, bookmarks | Deferred (needs Paul's approval) | No citizen route under `/news` | `3e3b110` |
| 10 | Tulong hero bytes and saved list | Partly closed (hero bytes). Saved list: Deferred (needs Paul's approval) | `GET /api/v1/services`, `GET /api/v1/services/{slug}`. `GET /api/v1/services/{slug}/hero` is not called. No saved-service route | `3e3b110` |
| 11 | Old programmes screen | Open | `GET /programs` is not in the spec. The tab is Tulong | `3e3b110` |
| 12 | My Account profile, preferences, consents | Closed | `GET`/`PATCH /api/v1/me`, `GET`/`PATCH /api/v1/me/notification-preferences`, `GET`/`POST /api/v1/me/consents`, `GET /api/v1/app/config` | `3e3b110` |
| 13 | Consent withdrawal | Open | No withdraw route. `PrivacyConsent` is `id`, `version`, `accepted_at`. Clarence's scope | `3e3b110` |
| 14 | Inbox reply, read, close, paging | Partly closed | `GET`/`POST /api/v1/threads` are called. `POST /api/v1/threads/{id}/messages`, `/read`, `/close` are not | `3e3b110` |
| 15 | Home banner media | Partly closed | `GET /api/v1/home`. `Banner.media_id` is not painted | `3e3b110` |
| 16 | Household summary | Partly closed | `GET /api/v1/households/current` is called. Correction still declines | `3e3b110` |
| 17 | Digital ID | Partly closed | `GET /api/v1/me/digital-id` and `GET /api/v1/me`. `photo_media_id` is not fetched | `3e3b110` |
| 18 | Notification paging and targets | Closed | `GET /api/v1/notifications` with `cursor` | `3e3b110` |
| 19 | Events | Deferred (needs Paul's approval) | No `/events` route | `3e3b110` |
| 20 | Assistance requests and uploads | Deferred (needs Paul's approval) | No citizen case or requirement route. Tulong is information only | `3e3b110` |

Mobile commits that closed or narrowed a gap: `ab2896c` (Firebase sign-in and registration, household decode, notification cursor, contract alignment), `8843694` (verification `notes` ignored; mobile password sign-in banner), `d1252f9` and `15b8e70` (issued Digital ID card).

## Closed

### 1. Sign in

`SignInScreen` calls `AuthApiRepository.signInWithPassword` and the phone-code methods. Email and password go to `FirebaseAuth.signInWithEmailAndPassword`. A mobile number is not sent as a password; the screen asks for a phone code. Phone codes use `verifyPhoneNumber` and `signInWithCredential`. The ID token is the bearer on `GET /api/v1/me`, which creates the citizen row on the first authenticated read. There is still no `POST /auth/otp` or `POST /auth/tokens`, which matches `3e3b110`. Dev mock still uses `MockAuthRepository` and `test/fixtures/mock/resident.json` only when `usesMockData` is true.

### 2. Create account

`AccountWizardScreen` calls `createAccount`, which uses `createUserWithEmailAndPassword`, then `GET /api/v1/me`, then `submitProfile` (`POST /api/v1/me/verification-requests` with `id_type`, `id_front`, optional `id_back`, `selfie`, and `POST /api/v1/me/consents`). The unrouted `RegistrationScreen` still declines. It is not the register route.

### 5. In-session password change

Still Firebase `reauthenticateWithCredential` then `updatePassword`. Sign-in now creates the Firebase user those calls need. There is no HTTP password-change route. Password reset stays on `POST /api/v1/auth/password-reset/request`, `/verify`, and `/complete`.

### 12. My Account profile, preferences, consents

Unchanged and matching `3e3b110`: edit sends changed `mobile`, `email`, and `barangay_id`; preferences are `verification_decided`, `message_received`, `balita`, and `emergency`, each `in_app` and `push`; consents record `{version}`; `GET /api/v1/app/config` publishes `privacy_notice`. `editable_fields` is still absent, so local field ownership applies. `POST /api/v1/me/avatar` still uses multipart `file`. `hasAvatar` is read from `avatar_media_id` on the next `GET /me`. Completion percent stays a client derivation.

### 18. Notification paging and targets

`listOwn` sends `cursor`. Load-more asks for another page only when `has_more` is true and `next_cursor` is a non-empty string. `message_received` is no longer relabelled to account security. `subject_type` is still not on `Notification`. When it is absent, `type` is the routing hint, with `subject_id` as the id. Mark-read routes are unchanged.

## Partly closed

### 3. Verification start, documents, and corrections

`GET /api/v1/me/verification-requests/current` is read. The decoder keeps `id`, `user_id`, `id_type`, `id_front_media_id`, `id_back_media_id`, `selfie_media_id`, `status`, `created_at`, and `reviewed_at`. `notes` is not copied and is not rendered. The status screen shows `rejection_reason` from `GET /api/v1/me`. The account wizard can `POST /api/v1/me/verification-requests`.

The remainder still declines with `BackendGap.absentOnNodeContract`: `KycClaimScreen` `openCase`, `attachDocument`, `loadDocuments`, `submitForReview`, and `submitCorrections`. `VerificationRequest` still has no `submitted_categories`, `issues`, `message`, `submitted_at`, or `can_edit`. The document bytes behind the media ids are not fetched. `POST /api/v1/digital-id/verify` stays on the verifier channel and is not called.

### 7. Directory photos and service lines

`GET /api/v1/offices` and `GET /api/v1/offices/{slug}` still supply the text fields, including `short_name`. `banner_media_id` is stored and is not a file. Every live office hero is still `assets/photos/municipal_hall.jpg`. `services` is always an empty list. `Office` has no service-line array. `GET /api/v1/services` can be filtered by `office`, and the directory does not join it. A failed live list does not open `offices.json`.

### 8. Balita cover bytes

`GET /api/v1/news`, `GET /api/v1/news/{id}`, and `GET /api/v1/news/categories` are unchanged and match, including `cover_url`. The card paints `cover_url`. `GET /api/v1/news/{id}/cover` (image bytes) is not called. A null `cover_url` leaves the card without a photograph even when the binary route would return one.

### 10. Tulong hero bytes

List and detail decode the `3e3b110` `Service` fields, including `hero_url`. `GET /api/v1/services/{slug}/hero` is not called. That byte route stays partly closed. The saved list is deferred, below. There is no citizen apply route. The screens stay information only.

### 14. Inbox reply, read, close, and paging

Called: `GET /api/v1/threads` (one page, no `limit`, no `cursor`), `GET /api/v1/threads/{id}`, `GET /api/v1/threads/{id}/messages`, and `POST /api/v1/threads` from directory compose (`office_id`, `subject`, `body`).

Not called from a screen, though the repository has the methods: `POST /api/v1/threads/{id}/messages`, `POST /api/v1/threads/{id}/read`, `POST /api/v1/threads/{id}/close`. The account thread still paints a composer that is not a text field. `Message.attachments` is still dropped. Multipart `file` on start and reply is still unused. The SAMPLE line is still limited to `usesMockData`.

### 15. Home banner media

`GET /api/v1/home` supplies banner title, href, sort order, and active. Photographs still come from `assets/home/slides.json` on every build. `Banner.media_id` is not painted. There is no public banner-bytes route. `quick_links` are decoded and unused. News titles come from `GET /api/v1/news`. Hotlines come from `GET /api/v1/home` and `GET /api/v1/hotlines`. `home_catalogue.json` is used only when `usesMockData` is true and the live lists are empty.

### 16. Household summary

`HouseholdApiRepository.loadOwnHousehold` calls `GET /api/v1/households/current` and decodes `address`, `barangay_name`, `viewer_role`, and `members` (`name`, `relationship`, `birthdate`, `sex`, `invite_status`). The screen shows the count, address, and role. It does not list names. `toString` stays redacted. `submitCorrectionRequest` still declines. There is no category-discrepancy route. Member add, edit, remove, leave, transfer, and invitations are on the spec and have no screen.

### 17. Digital ID

`DigitalIdScreen` calls `GET /api/v1/me/digital-id` and `GET /api/v1/me` for `name`. The card covers active, suspended, revoked, expired, and not issued. Expired is this client's reading of `status=active` when `now` is after `expires_at` and `qr` is null. There is no `expired` wire value. The QR is painted from `qr.token` in memory while `qr.isLive(now)`, and a timer refreshes at `expires_at`. A 404 or a null card is not issued. `photo_media_id` is not fetched, so the portrait stays the dashed placeholder. `POST /api/v1/digital-id/verify` is not called. The SAMPLE illustration is the dev mock only.

## Open

The only open gaps are 11 and 13. Both were scored against backend `3e3b110`.

### 11. Old programmes screen

`ProgramsScreen` is still unrouted and still declines `GET /programs`, which is not in the spec. The tab is `TulongScreen`.

### 13. Consent withdrawal

This is in Clarence's scope. `PrivacyControlsScreen` still offers withdraw, and `withdrawConsent` still declines. `PrivacyConsent` has no withdrawn state. Data export has no route and the live screens still hide the row. `POST /api/v1/me/close` exists, takes no body, and is still not offered.

## Deferred (needs Paul's approval)

Deferred items must not be built by the backend until Paul approves them.

### 4. Profile name split

`ProfilePatch.name` is one string. The wizard joins the parts it collected and sends that one `name` on `PATCH /api/v1/me`. Splitting the legal name into given, middle, and family on the contract is deferred. The household and digital-ID screens read the same single `name`. They do not ask for a split.

### 6. Other signed-in sessions

`SecurityScreen` still expects `GET me/sessions` and the revoke routes. Those paths are not in `3e3b110`. The repository declines. `POST`/`DELETE /api/v1/me/devices` registers a push token (`platform`, `token`) and does not list sessions.

### 9. Balita comments, reactions, and bookmarks

The article page does not offer them. The repository methods still decline. `3e3b110` has no comment, reaction, report, or bookmark path under `/news`.

### 10. Tulong saved list

Saved pages are the in-memory list for this process. There is no saved-service route. Hero bytes stay partly closed above.

### 19. Events

`EventsScreen`, event detail, and event registration are still routed and not a tab. No `/events` route exists. Every method declines.

### 20. Assistance requests and uploads

`AssistanceRequestsScreen` and the requirements screen still decline. No citizen case or requirement route exists at `3e3b110`. Tulong is information only.

## Not started

The next client work, one area at a time, is not in this commit:

1. Verification (the open half of item 3).
2. Media bytes and covers (items 8, 10, and the portrait on item 17).
3. Inbox send, read, close, and paging (item 14).
4. Consent withdrawal (item 13).
5. Directory service lines and Home banner media (items 7 and 15).
