# Backend integration gaps

**First audit:** 26 October 2026, app `a7c8d5f`, static, against the attached OpenAPI export named for backend `3e3b110`.
**Refresh:** 28 October 2026, mobile `main` `908896d` (`Merge pull request #19 from Upupapp/feature/digital-id-card`).
**Branch:** `docs/backend-gaps`. `origin/main` was merged in with `git merge` (fast-forward to `908896d`; no rebase, no force-push). Pull request #14, which carried the first audit, was already merged to `main` as `5f43c6b` on 26 October 2026.

A non-mock build loads `test/fixtures/mock/` only when `usesMockData` is true (`TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`). Staging and production have no baked-in API host. A release build without `--dart-define=TAYTAY_API_BASE_URL` refuses to start (`lib/core/config/app_config.dart`). Dev debug, with the define unset, still uses the Android emulator alias for the host machine.

## How this refresh was run

Static. No resident session was created and no personal data was sent.

`Upupapp/taytay-backend` is still not readable from this environment (`gh repo view` and `git ls-remote` both return repository not found) on 28 October 2026. Backend `main` could not be cloned, so a commit newer than the vendored spec cannot be confirmed.

The vendored file `docs/integration/taytay-node-openapi.json` is the `5f6fe0f` export. Mobile pull request #15 (`ab2896c`) had replaced it with the `3e3b110` export. The drift table from 26 October is closed. Items 8, 10, 15, and 17 below name the image routes this app calls on that newer file. `GET /api/v1/offices/{slug}/hero` is on `5f6fe0f` and is not called.

Every row below was scored against backend `3e3b110`, the short id of that spec. The full SHA is not in this clone. Where a route is missing, it is missing at `3e3b110`. Where a route is present, it was already present at `3e3b110` and the mobile change is named separately.

Deferred items must not be built by the backend until Paul approves them.

The 26 October probes (staging and production hostnames that are no longer compiled in, and the emulator alias) did not reach an API. They were not repeated.

## Status

| # | Gap | Status | Endpoint | Backend |
| --- | --- | --- | --- | --- |
| 1 | Sign in | Closed | Firebase SDK, then `GET /api/v1/me` | `3e3b110` (no HTTP sign-in route; bearer is a Firebase ID token) |
| 2 | Create account | Closed (re-checked 6 November 2026 against backend `6436b70`) | Firebase SDK, then `GET /api/v1/me`, then `PATCH /api/v1/me` (`name`, `mobile`, `email`, `barangay_id` from `GET /api/v1/barangays`, `street`), then `POST /api/v1/auth/email-otp/send` and `/verify`, then `POST /api/v1/me/consents`, then `POST /api/v1/me/verification-requests` | `6436b70` |
| 3 | Verification start, documents, corrections | Closed (no separate submit exists on Node) | `GET /api/v1/me/verification-requests/current`, `POST /api/v1/me/verification-requests`, `.../current/documents`, `.../current/corrections` | `6436b70` |
| 4 | Profile name split | Deferred (needs Paul's approval) | `PATCH /api/v1/me` sends one `name`. A given, middle, and family split is not on `ProfilePatch` | `3e3b110` |
| 5 | In-session password change | Closed | Firebase `updatePassword` (no HTTP route) | `3e3b110` |
| 6 | Other signed-in sessions | Deferred (needs Paul's approval) | `GET me/sessions` is not in the spec. `POST`/`DELETE /api/v1/me/devices` is a push token | `3e3b110` |
| 7 | Directory photos and service lines | Closed | `GET /api/v1/offices`, `GET /api/v1/offices/{slug}`, `GET /api/v1/offices/{slug}/hero`. `service_lines` renders. A missing hero keeps the bundled hall. | `5f6fe0f` |
| 8 | Balita cover bytes | Closed for published covers | `GET /api/v1/news/{id}/cover` when `cover_url` is set. No bearer token. A draft is not cached | `5f6fe0f` |
| 9 | Balita comments, reactions, bookmarks | Deferred (needs Paul's approval) | No citizen route under `/news` | `3e3b110` |
| 10 | Tulong hero bytes and saved list | Hero bytes closed. Saved list: Deferred (needs Paul's approval) | `GET /api/v1/services/{slug}/hero` when `hero_url` is set. No bearer token. No saved-service route | `5f6fe0f` |
| 11 | Old programmes screen | Closed | The tab and any leftover programmes entry read `GET /services` or `GET /services?office={slug}`. `GET /programs` is not called. | `5f6fe0f` |
| 12 | My Account profile, preferences, consents | Closed | `GET`/`PATCH /api/v1/me`, `GET`/`PATCH /api/v1/me/notification-preferences`, `GET`/`POST /api/v1/me/consents`, `GET /api/v1/app/config` | `3e3b110` |
| 13 | Consent withdrawal | Closed | `POST /api/v1/me/consents/withdraw` sets `withdrawn_at`. `POST /api/v1/me/consents` with that version clears it. | `5f6fe0f` |
| 14 | Inbox reply, read, close, paging, attachments | Closed | `GET`/`POST /api/v1/threads`, `GET /api/v1/threads/{id}`, `GET`/`POST /api/v1/threads/{id}/messages`, `POST /api/v1/threads/{id}/read`, `POST /api/v1/threads/{id}/close`. Cursor `limit`. `media_id` or multipart `file` | `5f6fe0f` |
| 15 | Home banner media | Closed when `image_url` is set | `GET /api/v1/home/banners/{id}/image`. No bearer token. A null URL keeps the bundled slide | `5f6fe0f` |
| 16 | Household summary | Partly closed | `GET /api/v1/households/current` is called. Correction still declines | `3e3b110` |
| 17 | Digital ID | Closed | `GET /api/v1/me/digital-id`, `GET /api/v1/me`, and authenticated `GET /api/v1/media/{id}/content` for `photo_media_id` | `5f6fe0f` |
| 18 | Notification paging and targets | Closed | `GET /api/v1/notifications` with `cursor` | `3e3b110` |
| 19 | Events | Deferred (needs Paul's approval) | No `/events` route | `3e3b110` |
| 20 | Assistance requests and uploads | Deferred (needs Paul's approval) | No citizen case or requirement route. Tulong is information only | `3e3b110` |
| 21 | Full Terms of Use text | Closed in the app (7 November 2026). The LGU's approved text is still to be published | `GET /api/v1/app/config` `terms` (`version`, `updated_at`, `body_markdown`), beside `terms_version`. "Read full Terms" shows `terms.body_markdown` once its version is not `placeholder`, as the Privacy Notice does, and otherwise says the text is not published yet | `77da0b2` |
| 22 | Document requests (issuance) | Closed (7 November 2026), with the three follow-ups wired | `GET /api/v1/issuance-types`, `GET /api/v1/issuance-types/{id}`, `GET`/`POST /api/v1/me/issuance-requests`, `GET /api/v1/me/issuance-requests/{id}`, `POST .../{id}/cancel`, `POST .../{id}/resubmit`, `GET .../{id}/attachments/{attachmentId}/content`. Body `idempotency_key` on the three sends, `403 VERIFICATION_REQUIRED`, and `accepts` on the request. Notification `issuance_request_updated` opens the request | `2fd0566`, `0d1cb14` |

Mobile commits that closed or narrowed a gap: `ab2896c` (Firebase sign-in and registration, household decode, notification cursor, contract alignment), `8843694` (verification `notes` ignored; mobile password sign-in banner), `d1252f9` and `15b8e70` (issued Digital ID card).

## Closed

### 1. Sign in

`SignInScreen` calls `AuthApiRepository.signInWithPassword` and the phone-code methods. Email and password go to `FirebaseAuth.signInWithEmailAndPassword`. A mobile number is not sent as a password; the screen asks for a phone code. Phone codes use `verifyPhoneNumber` and `signInWithCredential`. The ID token is the bearer on `GET /api/v1/me`, which creates the citizen row on the first authenticated read. There is still no `POST /auth/otp` or `POST /auth/tokens`, which matches `3e3b110`. Dev mock still uses `MockAuthRepository` and `test/fixtures/mock/resident.json` only when `usesMockData` is true.

### 2. Create account

Re-checked 6 November 2026 against backend `6436b70` (`docs/api/endpoints.md`, "Sign-up wizard", and `openapi/openapi.json`). The audit found the wizard asking for the email code before the account existed: `POST /api/v1/auth/email-otp/send` needs a signed-in registered member whose profile has an email, the Node API creates that profile empty on the first `GET /api/v1/me`, and nothing ever sent `PATCH /api/v1/me`. The refusal was swallowed and the code step opened anyway. Barangay was free text.

The wizard now runs in the server's order:

1. Personal details. The barangay is picked from `GET /api/v1/barangays` in a modal list (48 dp rows, announced as a button with its value; a failed read says so and offers Try again). There is no typed barangay.
2. The account: `createAccount` (`createUserWithEmailAndPassword`, then `GET /api/v1/me` with the ID token), and the session is opened.
3. `saveRegistrationProfile`: `PATCH /api/v1/me` with `name` (given and family joined, gap 4), `mobile`, `email`, `barangay_id` and `street`. `ProfilePatch` is strict; nothing else is sent. A field the server refuses is shown beside that field.
4. `sendEmailCode`, then `verifyEmailCode`. A send that is refused keeps the resident on the account step with a sentence saying the code was not sent; Continue asks again. A cooldown opens the hold screen. Once the account exists the email is fixed, so the code step no longer offers to change it.
5. `recordConsents` at the terms step: `GET /api/v1/app/config`, then `POST /api/v1/me/consents` for `privacy_version` and `terms_version`. A failure stays on the terms step.
6. ID front (required) and back (optional), then a selfie (required).
7. Review, then `submitProfile`: `POST /api/v1/me/verification-requests` with `id_type`, `id_front`, optional `id_back`, `selfie`. `201` is the pending state, which says staff check the request in the office's own system and the result arrives as an in-app notification.

Staging sends no real email (`EMAIL_SENDER=mock`). The send is accepted and nothing arrives; the app does not work around that. The unrouted `RegistrationScreen` still declines. It is not the register route.

### 5. In-session password change

Still Firebase `reauthenticateWithCredential` then `updatePassword`. Sign-in now creates the Firebase user those calls need. There is no HTTP password-change route. Password reset stays on `POST /api/v1/auth/password-reset/request`, `/verify`, and `/complete`.

### 12. My Account profile, preferences, consents

Unchanged and matching `3e3b110`: edit sends changed `mobile`, `email`, and `barangay_id`; preferences are `verification_decided`, `message_received`, `balita`, and `emergency`, each `in_app` and `push`; consents record `{version}`; `GET /api/v1/app/config` publishes `privacy_notice`. `editable_fields` is still absent, so local field ownership applies. `POST /api/v1/me/avatar` still uses multipart `file`. `hasAvatar` is read from `avatar_media_id` on the next `GET /me`. Completion percent stays a client derivation.

### 14. Inbox reply, read, close, paging, and attachments

Re-scored against the vendored Node export from taytay-backend pull request 2, head `5f6fe0f` (`docs/integration/taytay-node-openapi.json`). The account thread posts a reply, marks the thread read when it opens, and can close it. The thread list and the message list send `limit` and `cursor` and stop when `has_more` is false or `next_cursor` is empty. A reply attaches either `media_id` for an attachment already in the thread, or multipart field `file` for a new photo or PDF. Starting a thread sends `file` from the compose row. The repository also accepts `media_id` on start. The two are not sent together. `Message.attachments` is kept. The SAMPLE line stays on `usesMockData`. The resident does not see the server's error `message`.

### 22. Document requests (issuance)

Wired 7 November 2026 against backend `2fd0566`; the vendored Node export was refreshed from that commit. See `docs/taytay-document-requests.md`. The catalogue is read anonymously; the five `me/` routes carry the Firebase bearer. A submit is multipart (`type_id`, `purpose`, one part per requirement code, file name `<code>.<ext>`) and only a `201` counts as filed. A `403` is shown in the app's own words; only `VERIFICATION_REQUIRED` offers the way to verification. `can_cancel` and `can_resubmit` are read, never derived. `issuance_request_updated` carries the request id in `subject_id`; the decoder adds the `issuance_request` deep-link target, and tapping opens `/documents/mine/{id}`.

The three follow-ups this section asked for were served by backend `0d1cb14` and wired on 7 November 2026; the vendored Node export was refreshed from `84c7159`:

- **A retried send files once.** Submit and resubmit send `idempotency_key` as a multipart field, and cancel sends it in the JSON body: the Node API reads it there, not from a header. It is a version 4 UUID (`generateIdempotencyKey`, from the platform's secure random source), minted when the resident presses send and reused on every retry of that send, so a send whose answer was lost is answered with the request as it stands. An edit to the purpose, a file or the note is a new act with a new key. The `Idempotency-Key` header still goes too: the server ignores it, and the app's transport reads it to know an automatic retry after a dropped connection is safe. A `409` on a submit can only mean a key was reused for other content, which is a fault in this app: the resident reads a generic sentence that asks them to check My document requests, the key is dropped, and nothing about it is logged. The timeout copy now says a second try will not send twice.
- **`403 VERIFICATION_REQUIRED` is told apart from `FORBIDDEN`.** It maps to `ForbiddenFailure(requiresVerification: true)`, and only that offers "Go to verification". A plain `FORBIDDEN` (a staff account, for example) reads "Not available for this account", with no verification button. Neither shows the server's text.
- **The request carries `accepts`.** A resubmission is checked against the request's own `mime_types` and `max_bytes` (10 MB), which stay after the type is retired. The type is read only when a request comes from a server older than `0d1cb14` and has no block; the labelled 8 MB fallback is the last resort.

### 21. Full Terms of Use text

Wired 7 November 2026 against backend `77da0b2`. `GET /api/v1/app/config` publishes `terms` in the shape of `privacy_notice`; both decode to `PublishedText` (`TermsOfUse` and `PrivacyNotice` name it). The wizard's "Read full Terms" sheet shows `terms.body_markdown` once its version is not `placeholder` and the body is not empty, and otherwise says the full Terms will be available soon, as before. Consent still records `terms_version`, which publishing the Terms sets to the same version, so the version a resident accepts names the text they read. What remains is the LGU's: the approved Terms text, published by an administrator through `PATCH /api/v1/admin/app/config`. Until then staging serves the placeholder and the sheet says so.

### 18. Notification paging and targets

`listOwn` sends `cursor`. Load-more asks for another page only when `has_more` is true and `next_cursor` is a non-empty string. `message_received` is no longer relabelled to account security. `subject_type` is still not on `Notification`. When it is absent, `type` is the routing hint, with `subject_id` as the id. Mark-read routes are unchanged.

## Partly closed

### 3. Verification start, documents, and corrections

Wired against taytay-backend `5f6fe0f` (pull request 2, not merged when this was written). The vendored spec is `docs/integration/taytay-node-openapi.json`.

`GET /api/v1/me/verification-requests/current` reads the citizen fields: `message`, `submitted_at`, `can_edit`, `submitted_categories`, and `issues`. `status` stays `pending`, `approved`, or `rejected`. Staff `notes` are not copied and are not rendered. `rejection_reason` on `GET /api/v1/me` is still the reason paragraph on the needs-correction screen. The issues list is the per-field notes under it.

`POST /api/v1/me/verification-requests` starts a request (the account wizard, and Start verification once the resident has added the front of an ID and a selfie). `POST /api/v1/me/verification-requests/current/documents` replaces `id_front`, `id_back`, or `selfie`. `POST /api/v1/me/verification-requests/current/corrections` sends `{message}` and returns the request to pending. Those three no longer decline. Upload and resubmit are offered only while `can_edit` is true.

`loadDocuments` reads `GET /api/v1/me/verification-requests/current`: the identity row is attached when `id_front_media_id` is set, proof of address has no slot on the Node request and is reported as not sent, and a `404` is every row unattached rather than an error (6 November 2026, backend `6436b70`). `submitForReview` still declines, because there is nothing to call: the Node request is `pending`, which is the office's review queue, from the moment `POST /api/v1/me/verification-requests` answers `201`; replacing photos keeps that status; and a rejected request returns to pending only through the corrections route with a message. Nothing in the app calls it. A profile claim (`openCase`) is not the Node start, so it does not post. The bytes behind the media ids are not fetched. `POST /api/v1/digital-id/verify` stays on the verifier channel and is not called.

### 7. Directory photos and service lines

`GET /api/v1/offices` and `GET /api/v1/offices/{slug}` supply the text fields, including `short_name`, `service_lines` (default `[]`), and `hero_url`. The hero bytes are `GET /api/v1/offices/{slug}/hero` on the configured API host, with no bearer token. A 401 on that read does not end the session. A missing URL, an empty body, or a failed read keeps `assets/photos/municipal_hall.jpg`. Service lines render in the existing Services card. Tulong services for that office come from `GET /services?office={slug}` and are added there when the name is not already listed. A failed live list does not open `offices.json`. The dev fixture is still the only reader of `offices.json`, and only when `usesMockData` is true.

### 8. Balita cover bytes

`GET /api/v1/news`, `GET /api/v1/news/{id}`, and `GET /api/v1/news/categories` are unchanged. `GET /api/v1/news/{id}/cover` is called only when `cover_url` is set and the row has no fixture asset. The request is anonymous: no bearer token, and a 401 does not end the session. The host inside `cover_url` is not opened. A 404, including a draft, is not stored in the public cache. A failure keeps the empty cover box. Dev mocks do not call it.

### 10. Tulong hero bytes

List and detail decode the `Service` fields, including `hero_url`. The service page calls `GET /api/v1/services/{slug}/hero` when `hero_url` is set. The request is anonymous, and a 401 does not end the session. The photograph is 196 dp tall with a 20 dp radius. A null URL, a 404, or a failed read keeps the icon tile. The list does not paint it. The saved list is deferred, below. There is no citizen apply route. Dev mocks do not call the hero route.

### 15. Home banner media

`GET /api/v1/home` supplies banner title, href, sort order, active, and `image_url`. When `image_url` is set, the slide calls `GET /api/v1/home/banners/{id}/image` with no bearer token. A 401 does not end the session. Until those bytes arrive, and when they fail or `image_url` is null, the photograph stays the bundled slide. `quick_links` are decoded and unused. News titles come from `GET /api/v1/news`. Hotlines come from `GET /api/v1/home` and `GET /api/v1/hotlines`. `home_catalogue.json` is used only when `usesMockData` is true and the live lists are empty. Dev mocks do not call the image route.

### 16. Household summary

`HouseholdApiRepository.loadOwnHousehold` calls `GET /api/v1/households/current` and decodes `address`, `barangay_name`, `viewer_role`, and `members` (`name`, `relationship`, `birthdate`, `sex`, `invite_status`). The screen shows the count, address, and role. It does not list names. `toString` stays redacted. `submitCorrectionRequest` still declines. There is no category-discrepancy route. Member add, edit, remove, leave, transfer, and invitations are on the spec and have no screen.

### 17. Digital ID

`DigitalIdScreen` calls `GET /api/v1/me/digital-id` and `GET /api/v1/me` for `name`. The card covers active, suspended, revoked, expired, and not issued. Expired is this client's reading of `status=active` when `now` is after `expires_at` and `qr` is null. There is no `expired` wire value. The QR is painted from `qr.token` in memory while `qr.isLive(now)`, and a timer refreshes at `expires_at`. A 404 or a null card is not issued. `photo_media_id` is loaded with authenticated `GET /api/v1/media/{id}/content`. `GET /media/{id}` stays metadata. The portrait is decoded outside the shared image cache. A 404, a failure, or a dev mock keeps the dashed placeholder. `POST /api/v1/digital-id/verify` is not called. The SAMPLE illustration is the dev mock only.

## Open

No open gaps remain from the 11 and 13 rows. Both were closed against the vendored spec at backend `5f6fe0f`.

### 11. Old programmes screen

`/programs` is `TulongScreen` and reads `GET /services`. An office page reads `GET /services?office={slug}`. `ProgramApiRepository` reads those same service routes and does not call `GET /programs`. The old programmes widgets, if something still builds them, open the Tulong routes.

### 13. Consent withdrawal

`GET /me/consents` reads `withdrawn_at`. `POST /me/consents/withdraw` sends `{version}` and sets it. `POST /me/consents` with that version clears it. My Account settings links to the consents screen. Withdrawal asks for confirmation, keeps the row, and an error says nothing changed. The resident does not see the server's `message`. Data export still has no route and stays hidden. `POST /me/close` is still not offered.

## Deferred (needs Paul's approval)

Deferred items must not be built by the backend until Paul approves them.

### 4. Profile name split

`ProfilePatch.name` is one string. The wizard joins the parts it collected and sends that one `name` on `PATCH /api/v1/me`. Splitting the legal name into given, middle, and family on the contract is deferred. The household and digital-ID screens read the same single `name`. They do not ask for a split.

### 6. Other signed-in sessions

`SecurityScreen` still expects `GET me/sessions` and the revoke routes. Those paths are not in `3e3b110`. The repository declines. `POST`/`DELETE /api/v1/me/devices` registers a push token (`platform`, `token`) and does not list sessions.

### 9. Balita comments, reactions, and bookmarks

The article page does not offer them. The repository methods still decline. `3e3b110` has no comment, reaction, report, or bookmark path under `/news`.

### 10. Tulong saved list

Saved pages are the in-memory list for this process. There is no saved-service route. Hero bytes are the service-page read above.

### 19. Events

`EventsScreen`, event detail, and event registration are still routed and not a tab. No `/events` route exists. Every method declines.

### 20. Assistance requests and uploads

`AssistanceRequestsScreen` and the requirements screen still decline. No citizen case or requirement route exists at `3e3b110`. Tulong is information only.

## Not started

The next client work, one area at a time, is not in this commit:

1. Verification has no open half left (item 3, 6 November 2026).
