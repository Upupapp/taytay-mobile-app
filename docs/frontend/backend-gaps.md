# Backend integration gaps

**Audit date:** 26 October 2026.
**App commit:** `a7c8d5f` (`Merge hide Balita Save (#13)`), branch `docs/backend-gaps`.
**How it was run:** static. A non-mock call was attempted and did not reach an API. No resident session was created, and no personal data was sent.

This file lists every resident screen or flow that, on a non-mock build, still depends on a fixture, a bundled stand-in, or an endpoint that is missing or shaped differently from the contract. A non-mock build does **not** fall back to `test/fixtures/mock/*.json`. Those files are loaded only when `TAYTAY_ENV=dev` and `TAYTAY_DATA=mock`. The "Fixture" line on each item is that dev-mock substitute. Where a live build paints a bundled asset anyway, the item says so.

## How the audit was run

Compiled API hosts live in `lib/core/config/app_config.dart`. Staging and
production no longer have a baked-in host. A release build without
`--dart-define=TAYTAY_API_BASE_URL` refuses to start.

| Environment | Base URL |
| --- | --- |
| `dev` debug, define unset | `http://10.0.2.2:8000/api/v1` |
| `staging`, `prod`, and every release build | none — pass `--dart-define=TAYTAY_API_BASE_URL` |

Probes from this environment on 26 October 2026, against hostnames that used to
be compiled defaults and are not anymore:

| URL | Result |
| --- | --- |
| `https://staging-api.taytay.gov.ph/api/v1/health` | DNS did not resolve |
| `https://api.taytay.gov.ph/api/v1/health` | DNS did not resolve |
| `http://10.0.2.2:8000/api/v1/health` | Connection timed out (the Android emulator alias for the host machine; nothing is listening here) |

`TAYTAY_LIVE_API` is unset. `test/live/f14_live_proof_test.dart` is tagged `live` and is excluded from the ordinary suite. No live test was run.

`Upupapp/taytay-backend` is not readable from this environment (`gh` and `git ls-remote` both return "repository not found"). The newest contract on hand is the attached OpenAPI export named for backend commit `3e3b110`. The copy vendored in this repo is `docs/integration/taytay-node-openapi.json`. The historical PHP pin at `test/contract/openapi.json` (`api-baseline-2026-08`) is not the forward authority and was not used to judge these gaps.

Security on `3e3b110` is `firebaseIdToken`: Firebase is the identity provider, the API verifies the ID token, and a local mock accepts `Authorization: Bearer mock:<role>:<subjectId>`. This app mints only `registered` and `verified` in dev mocks. There is no HTTP sign-in route in the spec.

## Drift between the vendored spec and `3e3b110`

The vendored file and `3e3b110` share the same title and version (`Taytay LGU IDS API` 1.0.0). Path count: vendored 73, uploaded 74. Schema count: 116 both. Shared operations that differ: 2 of 95, and those differences are the schema refs below.

`3e3b110` is newer than the vendored file. Because the backend repository could not be read, it is possible the repository has moved on again. Nothing below claims the running server matches `3e3b110`.

| Item | Vendored `taytay-node-openapi.json` | `3e3b110` |
| --- | --- | --- |
| `GET /api/v1/services/{slug}/hero` | absent | present. Public image bytes (`image/jpeg`, `image/png`, `image/webp`). 404 when there is no image. |
| `Service` | no presentation fields | adds optional `icon_key`, `tile_color`, `badge`, `legal_basis`, `claim_steps` (string array), `featured_headline`, `schedule`, `hero_url`, `hidden_from_list` |
| `ServiceContact` | required `label` (string) and `value`. No `type`. | required `type` (`facebook`, `landline`, `hotline`, `email`, `mobile`) and `value`. `label` is optional and nullable. |
| `ServiceWrite` / `ServicePatch` | no presentation fields | same new fields as `Service`, except `hero_url` (the hero is the binary route). `ServicePatch` also gains `contacts`. Staff-only. |
| `OfficeWrite` / `OfficePatch` | no `short_name` | optional nullable `short_name`. The citizen `Office` read model already requires `short_name` in both specs. |
| `UserProfile.verification_decided_at` | property present, not required | required, nullable `date-time` |
| `AppConfig.privacy_notice` | optional, nullable | required `PrivacyNotice` (`version`, `updated_at`, `body_markdown`) |

The Tulong decoder already reads the `3e3b110` service fields. A server that still matches only the vendored file would omit `type` on contacts and the presentation fields. The app treats an unknown contact type as unknown and leaves the new strings null. It does not reject the row.

## Severity

| Level | Meaning on a non-mock build |
| --- | --- |
| **Blocker** | The resident cannot finish the flow. The call declines, or the screen never obtains a Firebase ID token. |
| **High** | The route exists and the screen ignores it, shows a stand-in, or offers a control that fails. |
| **Medium** | A field, a page, or a secondary route is wrong or unused. The rest of the flow still runs. |
| **Low** | Unrouted, or hidden on purpose because the contract has no route. |

## Auth and verification

### 1. Sign in — Blocker

- **Screen:** Sign in (`SignInScreen`, `SignInController`).
- **Dart:** `lib/features/auth/presentation/sign_in_screen.dart`, `lib/features/auth/presentation/sign_in_controller.dart`, `lib/features/auth/data/auth_api_repository.dart`.
- **What the app calls:** nothing on the wire. `requestOneTimeCode` and `verifyOneTimeCode` decline (`BackendGap.absentOnNodeContract`). `signInWithPassword` declines the same way. The controller would have put `AuthOutcome.accessToken` into `SessionController.signIn`.
- **Backend (`3e3b110`):** missing. There is no `POST /auth/otp`, `POST /auth/otp/verify`, or `POST /auth/tokens`. Protected routes expect `Authorization: Bearer` with a Firebase ID token. `lib/features/account/data/firebase_account_password_client.dart` is the only Firebase Auth call site, and it reads `FirebaseAuth.currentUser` for an in-session password change. Nothing calls `signInWithEmailAndPassword` or `createUserWithEmailAndPassword`.
- **Field detail:** a successful session in this app is an opaque bearer string plus a resident summary. The spec never returns that token from an HTTP route. Dev mocks mint `mock:<role>:<id>` inside `MockAuthRepository`.
- **Fixture:** `MockAuthRepository`, which loads `test/fixtures/mock/resident.json` through `MockResident`. Live builds do not load it. They show the repository failure.

Password reset is a separate, matching flow and is not this gap. See the aligned list.

### 2. Create account — Blocker

- **Screen:** Create account (`AccountWizardScreen` on `AppRoute.register`).
- **Dart:** `lib/features/auth/presentation/account_wizard_screen.dart`, `lib/features/auth/data/auth_api_repository.dart` (`createAccount`, `submitProfile`).
- **What the app calls:** `createAccount` declines (`BackendGap.residentSelfRegistration`) before any HTTP call. `submitProfile` would then `POST /api/v1/me/verification-requests` (multipart `id_type`, `id_front`, optional `id_back`, `selfie`) and `POST /api/v1/me/consents` with `{version}`. That second step never runs, because there is no session.
- **Backend:** no citizen account-creation route. Identity is Firebase. The verification submit route **is** present (see item 4) and expects an already authenticated caller.
- **Field detail:** `VerificationSubmit` requires `id_type` (`philid`, `drivers_license`, `passport`, `umid`, `postal`, `voters`, `sss`, `other`), `id_front`, and `selfie`. `id_back` is optional. The wizard collects a password that no Node route accepts.
- **Fixture:** `MockAuthRepository` / `resident.json` on a dev mock. The wizard's design fixture (`AccountFixture`, not `live`) skips the repository and paints the submitted step locally.

The unrouted `RegistrationScreen` (`lib/features/registration/presentation/registration_screen.dart`) still calls `PlannedRegistrationRepository`, which declines OTP and submit with `BackendGap.residentSelfRegistration`. The register route does not build that screen. `GET /api/v1/barangays` is present and is not the thing that blocks registration.

### 3. Verification start, documents, and corrections — Blocker for submit, Medium for status

- **Screens:** Verification status (`VerificationScreen`), start (`KycClaimScreen` at `/verification/start`), and the document and correction actions on `VerificationController`.
- **Dart:** `lib/features/verification/presentation/verification_screen.dart`, `lib/features/verification/presentation/verification_controller.dart`, `lib/features/verification/presentation/kyc_claim_screen.dart`, `lib/features/verification/presentation/kyc_claim_controller.dart`, `lib/features/verification/data/kyc_api_repository.dart`.
- **Status read:** `GET /api/v1/me/verification-requests/current`. Present. A 404 is treated as not started.
- **Shape of `VerificationRequest`:** required `id`, `user_id`, `id_type`, `id_front_media_id`, `selfie_media_id`, `status` (`pending`, `approved`, `rejected`), `created_at`. Optional `id_back_media_id`, `reviewer_id`, `notes`, `reviewed_at`.
- **What the decoder still looks for and does not get:** `message` (falls through to `notes`), `submitted_at` (falls through to `created_at`), `can_edit` (stays null), `submitted_categories`, and `issues`. The last two are what the status screen's "what the LGU has from you" card and the corrections list read. Both stay empty, so those sections do not render. `id_front_media_id`, `id_back_media_id`, and `selfie_media_id` are on the payload and are not copied into the detail model.
- **Status vocabulary:** `pending` maps to under review, `approved` to verified, `rejected` to unsuccessful. That matches the enum. Older names the decoder still accepts (`draft`, `needs-more-information`, `screening`, `manual-review`) are not on this schema, so a resident cannot land on "more information needed" from a value the spec publishes.
- **Submit paths that decline:** `openCase` (the start screen), `attachDocument`, `loadDocuments`, `submitForReview`, and `submitCorrections`. Each returns `BackendGap.absentOnNodeContract`. There is no `POST /me/kyc`, no `POST /me/profile/corrections`, and no document-list route.
- **Submit path that exists and is not used by these screens:** `KycApiRepository.submitVerification` posts `POST /api/v1/me/verification-requests`. No presentation file calls it. The account wizard's `submitProfile` is the only caller, and item 2 stops it.
- **Fixture:** `MockVerificationRepository` in `lib/features/mock_data/data/mock/taytay_mocks.dart`. Not a JSON file.

### 4. Resident profile wizard — Low, with one field compromise

- **Screen:** Profile wizard (`ProfileWizardScreen` under `/verification/profile`).
- **Dart:** `lib/features/verification/presentation/profile_wizard_screen.dart`, `lib/features/verification/data/resident_record_api_repository.dart`.
- **Endpoints:** `GET /api/v1/me`, `PATCH /api/v1/me`, `GET /api/v1/households/current`, `PATCH /api/v1/households/current`, and `POST /api/v1/households` when the current household is 404. All present.
- **Shape:** `ProfilePatch` is a single `name`, plus `birthdate`, `sex` (`male`, `female`, `unspecified`), `mobile`, `email`, `barangay_id`, `address`, `street`, `purok`. The wizard splits the display name into given, middle, and family on the way in and joins them back into `name` on the way out. There are no `first_name`, `middle_name`, `last_name`, or `suffix` fields on `UserProfile`. `HouseholdWrite` requires `address` and `barangay_id`.
- **Fixture:** `MockResidentRecordRepository` / `resident.json` on a dev mock. Live uses the routes above. This is not the household summary screen (item 16).

### 5. In-session password change — High

- **Screen:** Change password, from My Account settings.
- **Dart:** `lib/features/account/presentation/change_password_form.dart`, `lib/features/account/data/firebase_account_password_client.dart`.
- **Endpoint:** none. The live client calls `reauthenticateWithCredential` and `updatePassword` on `FirebaseAuth.currentUser`.
- **Backend:** password reset is HTTP (aligned list). An in-session change is Firebase. A session created only with `mock:<role>:<id>` has no Firebase user, so the call has no current user.
- **Fixture:** `MockAccountPasswordClient`.

### 6. Other signed-in sessions — High

- **Screen:** Security (`SecurityScreen`).
- **Dart:** `lib/features/account/presentation/security_screen.dart`, `lib/features/auth/data/session_api_repository.dart`.
- **What the app expects:** `GET me/sessions`, `DELETE me/sessions/{session}`, `POST me/sessions/revoke-all`. None of those paths are in `3e3b110`. The repository declines (`BackendGap.absentOnNodeContract`). The screen does not invent a device list.
- **What the spec has instead:** `POST /api/v1/me/devices` and `DELETE /api/v1/me/devices` with `{token}`, for a push token. `Device` returns `id`, `platform` (`ios`, `android`, `web`), `created_at`, `updated_at`, and does not echo the token. That is not a session list.
- **Fixture:** `MockDeviceSessionRepository`.

## Directory

### 7. Office list and office page — High for photographs, Medium for services

- **Screens:** Directory tab (`DirectoryScreen` on the services shell branch) and office detail (`OfficeDetailScreen`).
- **Dart:** `lib/features/directory/presentation/directory_screen.dart`, `lib/features/directory/data/office_catalogue.dart`, `lib/features/directory/data/office_api_repository.dart`.
- **Endpoints:** `GET /api/v1/offices` (`q`, `category`, `limit`, `cursor`) and `GET /api/v1/offices/{slug}`. Present. The client follows `meta.pagination.next_cursor` for up to five pages. A failed live list throws `OfficeDirectoryException`. It does not open the fixture.
- **`Office` fields the decoder reads:** `id`, `name`, `slug`, `short_name` (string or null; empty falls back to `name`), `description`, `head`, `hours`, `phone`, `email`, `address`, `category`. Category chips are built from those categories, with `All` added on the client.
- **Fields on `Office` that the decoder drops:** `banner_media_id`, `latitude`, `longitude`, `created_at`, `updated_at`. Every live office is given `heroAsset` and `insetAsset` of `assets/photos/municipal_hall.jpg`. `services` is always an empty list. The fixture's per-office hero, service lines, keywords, and SAMPLE tags are not on the contract.
- **There is no public banner URL.** `GET /api/v1/media/{id}` returns metadata (`id`, `content_type`, `byte_size`, `created_at`) and requires a Firebase token. It does not return image bytes. Office photos in the design therefore have no citizen URL to paint.
- **Fixture:** `test/fixtures/mock/offices.json` when `usesMockData` is true, including the sample thread under `thread`. Live directory threads do not use that sample. See item 14.

`NodeCitizenApi.listOffices` decodes a thinner `MunicipalOffice` and is not called by a screen.

## Balita

### 8. Feed, article, and categories — aligned, with two leftovers

The list, the article, and the chips are on the contract and are what the screens call.

- **Screens:** Balita tab (`NewsScreen`) and article (`NewsPostScreen`).
- **Dart:** `lib/features/news/presentation/news_screen.dart`, `lib/features/news/presentation/news_feed_controller.dart`, `lib/features/news/data/newsfeed_api_repository.dart`.
- **Endpoints:** `GET /api/v1/news` (`category`, `office`, `limit`, `cursor`), `GET /api/v1/news/{id}`, `GET /api/v1/news/categories`. Present. The feed stores `next_cursor` and sends it on the next page. `Lahat` sends no `category`. Live chips replace the design set when the category call succeeds.
- **`NewsItem` fields read:** `id`, `title`, `body`, `category`, `office_slug`, `cover_media_id`, `cover_url`, `published_at`, `pinned`, `pinned_at`, `share_url`, `status` (`draft`, `published`). Unknown `status` values are kept raw. Drafts are filtered out of the resident list.
- **Not read, and not on `NewsItem`:** a `media[]` array with `urls` and `alt_text`. The card uses `cover_url`. `GET /api/v1/news/{id}/cover` (public image bytes, 404 when there is no cover) is never called. If `cover_url` is null and the bytes exist only on that route, the card has no photograph. Severity for that case: **Medium**.
- **Office label:** the repository joins `GET /api/v1/offices` and prefers `short_name`, then `name`.

### 9. Comments, reactions, reports, and bookmarks — Low

- **Screen:** the article page does not offer them. `NewsPostScreen` says so. Save was removed from the cards. `canComment` is true only when `comments_enabled` is true, and `NewsItem` has no such field, so the comment loader does not run.
- **Dart:** the decline methods remain on `NewsfeedApiRepository` (`listComments`, `setReaction`, `clearReaction`, `addComment`, `deleteOwnComment`, `reportComment`), all `BackendGap.absentOnNodeContract`.
- **Backend:** no comment, reaction, report, or bookmark path under `/news`. Staff `POST /news`, `PATCH /news/{id}`, and pin/unpin are present and correctly not called.
- **Fixture:** `test/fixtures/mock/announcements.json` via `MockAnnouncementRepository`, dev mock only.

## Tulong

### 10. Programme list and detail — mostly present; hero bytes and saved pages are not

- **Screens:** Tulong tab (`TulongScreen` on `AppRoute.programs`) and service page (`ServiceInfoScreen`).
- **Dart:** `lib/features/tulong/presentation/tulong_screen.dart`, `lib/features/tulong/data/social_service_api_repository.dart`, `lib/features/tulong/data/social_service_codec.dart`.
- **Endpoints:** `GET /api/v1/services` (`q`, `category`, `office`, `featured`, `limit`, `cursor`) and `GET /api/v1/services/{slug}`. Present. The client sends `limit`, `cursor`, `q`, and `featured=true` when the featured filter is on. It hides rows with `hidden_from_list` on the client as well.
- **Fields read from `Service`, matching `3e3b110`:** `id`, `name`, `slug`, `summary`, `details`, `eligibility`, `requirements` (string array), `contacts` (`type`, optional `label`, `value`), `locations` (`name`, `address`), `category`, `office_id`, `office_slug`, `featured`, `icon_key`, `tile_color` (`#RGB` or `#RRGGBB`), `badge`, `legal_basis`, `claim_steps`, `featured_headline`, `schedule`, `hero_url`, `hidden_from_list`. Office name, short name, hours, and phone are joined from `GET /api/v1/offices` when `office_slug` is set. `schedule` on the service is shown on its own.
- **`GET /api/v1/services/{slug}/hero`:** present on `3e3b110`, absent from the vendored spec, and not called. `hero_url` is stored. A null URL keeps the icon tile. Severity: **Medium**.
- **Saved pages:** no saved-service route. `savedOnThisPhone` is the list already decoded in this process, capped at 20, and it dies with the process. The dev mock's saved date and SAMPLE requirement flags live under `presentation` in the fixture and are ignored on a live payload (`allowPresentation: false`). Severity: **Medium**.
- **Apply:** no citizen apply or intake route. The screens are information only. `POST /api/v1/admin/services` is staff and is not called. Severity: **Low** (the product decision, not a decoder bug).
- **Fixture:** `test/fixtures/mock/tulong_services.json`, joined to `test/fixtures/mock/offices.json`, through `MockSocialServiceRepository`. Dev mock only.

### 11. Old programmes screen — Low

- **Screen:** `ProgramsScreen` is not in the router. The tab builds `TulongScreen`.
- **Dart:** `lib/features/programs/presentation/programs_screen.dart`, `lib/features/programs/data/program_api_repository.dart`.
- **Expected:** `GET /api/v1/programs?status=active`. Absent. The repository declines (`BackendGap.absentOnNodeContract`).
- **Fixture:** `MockProgramRepository`.

The old catalogue screen (`ServicesScreen`, `ServiceCatalogApiRepository`) is also unrouted. It still `GET`s `/services` but decodes `code` (falling back to `slug`), `description` (falling back to `summary`), `status`, and `available_channels`. `Service` has no `status` and no `available_channels`, and pagination is cursor-based. The query it sends is `limit` and `category`, not `page`. Severity **Low** while it stays off the router. A deep link to `/services/:serviceCode` redirects to the Tulong page.

## My Account

### 12. Account home, edit profile, settings preferences, consents — present, with the gaps below

- **Screens:** My Account (`AccountHomeScreen`), edit profile (`EditProfileScreen`), settings (`AccountSettingsScreen`).
- **Dart:** `lib/features/account/presentation/account_home_screen.dart`, `lib/features/account/presentation/account_pages.dart`, `lib/features/profile/data/resident_profile_api_repository.dart`, `lib/features/notifications/data/notification_api_repository.dart`, `lib/features/settings/data/privacy_api_repository.dart`.
- **`GET` and `PATCH /api/v1/me`:** present. Edit profile sends only changed `mobile`, `email`, and `barangay_id`. It does not send `name`. `UserProfile` also carries `birthdate`, `sex`, `address`, `street`, `purok`, `avatar_media_id`, `email_verified`, `verification_status` (`unverified`, `pending`, `verified`, `rejected`), `verification_decided_at`, `rejection_reason`, `role`, `closed`, `closed_at`, `office_id`. The home paints `verification_decided_at` as a Manila date when it is an ISO time, and "Verified" when it is null.
- **`editable_fields` is not on `UserProfile`.** When that list is absent, `ResidentProfileDetail.ownershipOf` uses the local `FieldOwnership` on each field. The screen does not lock every field.
- **Completion percent** is computed on the client from ten `GET /me` values. The spec does not publish a percent. That is a client derivation, not a missing route.
- **`POST /api/v1/me/avatar`:** present. Multipart field name `file` matches. The response `data.avatar_media_id` is discarded (`decode` ignores the body).
- **`GET` and `PATCH /api/v1/me/notification-preferences`:** present. `NotificationPreference.type` is `verification_decided`, `message_received`, `balita`, or `emergency`, each with `in_app` and `push`. Settings writes Balita and emergency as both flags. There is no email channel. The decoder forces `sms` and `email` off.
- **`GET` and `POST /api/v1/me/consents`:** present. `PrivacyConsent` is `id`, `version`, `accepted_at`. There is no `withdrawn_at`, no `purpose`, and no withdraw route.
- **`GET /api/v1/app/config`:** present, including required `privacy_notice` on `3e3b110`. The notice screen uses `body_markdown` when the version is published. A `placeholder` version, an empty body, or a failed load keeps the bundled draft outside production.
- **Fixture:** `MockProfileRepository` and `resident.json`. Preferences and consents in the mock are in `taytay_mocks.dart`, not a separate JSON file.

### 13. Privacy actions that the contract does not serve — High for withdraw, Low for export and closure

- **Screens:** privacy controls (`PrivacyControlsScreen` at `/settings/privacy`) and the My Account notice (`showDataExport: false`).
- **Dart:** `lib/features/settings/presentation/privacy_controls_screen.dart`, `lib/features/settings/data/privacy_api_repository.dart`, `lib/features/account/presentation/account_pages.dart`.
- **Withdraw consent:** `loadControls` hardcodes `canWithdrawConsent: true`, and the screen calls `withdrawConsent`. The repository declines (`BackendGap.absentOnNodeContract`). `PrivacyConsent` has no withdrawn state. Severity: **High**.
- **Request a data correction** from this repository also declines. Profile edits go through `PATCH /me` instead. Severity: **Medium** on the privacy-controls screen.
- **Data export:** no route. The live notice and live settings pass `showDataExport: false`, so the row is not shown and no request is sent. The design canvas still has the row for specimens. Severity: **Low**.
- **Account closure:** `POST /api/v1/me/close` is present, takes no body, and returns `UserProfile`. `requestAccountClosure` calls it. `canRequestDeletion` stays false, so the resident UI does not offer it. Severity: **Low**.
- **Fixture:** `MockAccountControlsRepository`.

Photo credits (`PhotoCreditsScreen`) read the bundled asset manifest. There is no credits endpoint. Severity **Low**.

## Inbox and messages

### 14. Inbox, thread, and new message — High for reply, Medium for paging and attachments

- **Screens:** Messages inbox and thread (`MessagesInboxScreen`, `AccountThreadScreen`), directory compose (`OfficeComposeScreen`), directory thread (`OfficeThreadScreen`).
- **Dart:** `lib/features/account/presentation/account_pages.dart`, `lib/features/directory/presentation/directory_screen.dart`, `lib/features/messaging/data/office_messaging_gap_repository.dart`, `lib/features/account/presentation/account_canvas.dart`.
- **Present and called:**
  - `GET /api/v1/threads` from the inbox and the account home badge. One request, no `limit` and no `cursor`. `ThreadListEnvelope.meta.pagination` is `{has_more, next_cursor}`. Further pages are never requested. Severity: **Medium**.
  - `GET /api/v1/threads/{id}` and `GET /api/v1/threads/{id}/messages`.
  - `POST /api/v1/threads` from directory compose, JSON `{office_id, subject, body}`. The success body is `{thread, message}`. The screen does not need the row; it opens the sent state.
- **Present in the repository and not called by a screen:** `POST /api/v1/threads/{id}/messages` (`{body}`), `POST /api/v1/threads/{id}/read`, `POST /api/v1/threads/{id}/close`. The account thread paints a composer ("Write a message…", a paperclip, a send control) and does not pass `onSend`. The composer is not a text field. Attach is not a picker. A resident can start a thread from an office page and cannot reply, mark it read, or close it from the thread screen. Severity: **High**.
- **`Thread` fields read:** `id`, `office_id`, `office_slug`, `subject`, `last_message_preview`, `status` (`open`, `closed`), `unread`, `unread_count`, `last_message_at`, `created_at`, `updated_at`. Office labels come from `GET /offices`: `short_name` when it is a non-empty string, otherwise `name`. `resident_id` is not shown.
- **`Message` fields read:** `id`, `thread_id`, `sender_id`, `body`, `created_at`. `attachments` (array of objects) is dropped. The spec also publishes multipart `ThreadStartFile` and `ThreadReplyFile` with an optional `file`. The client sends JSON only. Severity: **Medium**.
- **Account thread display:** `when` is set to an empty string and `dayLabel` is empty, even though `created_at` was decoded. The directory thread formats both. Severity: **Low**.
- **SAMPLE line:** painted only when `usesMockData` is true.
- **Fixture:** `MockOfficeMessagingRepository` builds one in-memory thread (`SAMPLE inquiry`). It does not read a JSON file. `offices.json` still holds a `thread` used by `OfficeCatalogue.thread()`, which no live screen calls.

## Anything else

### 15. Home — Medium for hero photographs

- **Screen:** Home (`HomeScreen`), hotlines (`HotlinesScreen`).
- **Dart:** `lib/features/home/presentation/home_screen.dart`, `lib/features/home/presentation/hotlines_screen.dart`, `lib/features/home/data/home_catalogue.dart`, `lib/features/citizen_api/data/node_citizen_api.dart`.
- **`GET /api/v1/home`:** present. `data` is `banners`, `quick_links`, `news`, `services`, `hotlines`.
- **What the screen uses:** banner `title`, `href`, `sort_order`, and `active`, overlaid on photographs from `assets/home/slides.json`. Hotline `id`, `name`, `number`, `category` from the home payload (the hotlines screen also calls `GET /api/v1/hotlines`). News titles come from `GET /api/v1/news`, not from the home `news` array. The bell count is the unread rows in the first notifications page.
- **Dropped from `HomeFeed`:** `quick_links` (`id`, `label`, `href`, `sort_order`) and service slugs. No screen reads them. `Banner.media_id` is not painted. The code says a media id is not a file the app can paint. There is no public banner-bytes route.
- **Fixture:** `test/fixtures/mock/home_catalogue.json` supplies news and hotlines only when `usesMockData` is true and the live lists are empty. A non-mock build with an empty feed shows an empty list. Hero photographs are bundled on every build, mock or not.
- **`GET /api/v1/health` and `GET /api/v1/app/config`:** present and decoded. Health `data` is `service`, `status` (`ok`), `api_version`. Config fields match `AppConfig`, including `feature_flags` as an object. Older keys the decoder still accepts (`service`, `api_version`, `timezone`, `client.default_page_size`, `server_time`) are not on this schema, so page size stays at the client default of 25.

### 16. Household summary — High

- **Screen:** Household (`HouseholdScreen`) and the correction screen (`HouseholdCorrectionScreen`).
- **Dart:** `lib/features/household/presentation/household_screen.dart`, `lib/features/household/data/household_api_repository.dart`.
- **What the app calls:** nothing. `loadOwnHousehold` declines while naming `GET me/household`, which is not in the spec. `submitCorrectionRequest` declines (`BackendGap.kycFieldCorrections`).
- **What the spec has:** `GET /api/v1/households/current` returns `id`, `address`, `barangay_id`, `barangay_name`, `head_user_id`, `viewer_role` (`head`, `member`), `created_at`, and `members`. `HouseholdMember` is `id`, `name`, `relationship` (`head`, `spouse`, `child`, `parent`, `sibling`, `other`), `birthdate`, `sex`, `user_id`, `invite_status` (`none`, `pending`, `accepted`). Also present, and unused by any screen: `PATCH /households/current`, `DELETE /households/current`, `POST /households/current/leave`, `POST /households/current/members`, `PATCH` and `DELETE /households/current/members/{id}`, `POST /households/current/transfer`, `GET /households/invitations/current`, `POST /households/invitations/{id}/accept`, `POST /households/invitations/{id}/decline`.
- **The profile wizard already calls `GET` and `PATCH /households/current`** through `ResidentRecordApiRepository` (item 4). The household screen does not use that repository. It asks for a count and an address and then declines, so the resident sees the gap failure instead of the record.
- **Names:** the screen's own comment refuses other residents' names. Not decoding `members[].name` is consistent with that. Not calling `GET /households/current` at all drops the address and the count, which the screen does want.
- **Fixture:** `MockHouseholdRepository`, which reads `resident.json` for the barangay label and returns a synthetic summary.

### 17. Digital ID — wired, photo bytes still absent

- **Screen:** `DigitalIdScreen` at `/digital-id`, on the My Account shell branch. It paints the five card states (active, suspended, revoked, expired, not issued).
- **Dart:** `lib/features/credential/presentation/digital_id_screen.dart`, `lib/features/credential/presentation/digital_id_canvas.dart`, `lib/features/credential/data/credential_api_repository.dart`, `lib/features/credential/domain/digital_id_face.dart`.
- **What the app calls:** `GET /api/v1/me/digital-id` for the card and `qr`, and `GET /api/v1/me` for `data.name` only. The name is trimmed and is not stored on the session. A 404 or a null card is not issued. Expired is this client's reading of `status=active` when `now` is after `expires_at` and `qr` is null. There is no `expired` wire value.
- **QR:** rendered from `qr.token` in memory only while `qr.isLive(now)`. A timer is armed at `qr.expires_at` however long that is. At that instant the modules come down, the resident sees "Refreshing code…", and the card is loaded again. A refetch that is also past its expiry stays on that state and is not painted. The token is not written, logged, or put in a semantic label.
- **Left alone on purpose:** `POST /api/v1/digital-id/verify` is the verifier scan. This app does not call it. `photo_media_id` is not fetched: this client has no media-bytes route, so the portrait stays the dashed placeholder.
- **Fixture:** `MockCredentialRepository`, and only when `usesMockData` is true. The name, number, and dates are the fictional SAMPLE illustration. A non-mock build shows whatever the two GETs return.

### 18. Notifications inbox paging and targets — Medium

- **Screen:** Notifications (`NotificationInboxScreen`). The home bell uses the same repository for the first page only.
- **Dart:** `lib/features/notifications/presentation/notification_inbox_controller.dart`, `lib/features/notifications/data/notification_api_repository.dart`.
- **Endpoints:** `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/read`, `GET /api/v1/notifications/unread-count`. All present.
- **Shape:** `Notification` is `id`, `type` (`verification_decided`, `message_received`), `title`, `body`, optional `subject_id`, optional `read_at`, `created_at`. Pagination is `has_more` and `next_cursor`.
- **Mismatch:** `listOwn` sends `limit` and never `cursor`, and it ignores the `page` argument. `loadMore` therefore requests the first page again and the controller appends it. The decoder looks for `subject_type`, which is not on the schema, so the deep-link target type stays empty. `subject_id` is read. `verification_decided` is relabelled to the client category `verification_update`. `message_received` is relabelled to `account_security`.
- **Push registration** (`POST` and `DELETE /api/v1/me/devices`) matches `{platform, token}` and is separate from item 6.
- **Fixture:** `MockNotificationRepository`.

### 19. Events — Medium

- **Screens:** `EventsScreen`, `EventDetailScreen`, `EventRegistrationScreen`. Routed, not a tab.
- **Dart:** `lib/features/events/presentation/events_screen.dart`, `lib/features/events/data/event_api_repository.dart`.
- **Expected:** `GET /events` and registration routes. None exist on `3e3b110`. Every method declines (`BackendGap.absentOnNodeContract`).
- **Fixture:** `MockEventRepository`.

### 20. Assistance requests and requirement uploads — Medium

- **Screens:** `AssistanceRequestsScreen` (`/requests`) and `RequestRequirementsScreen`.
- **Dart:** `lib/features/services/data/assistance_api_repository.dart`, `lib/features/requirements/data/requirement_api_repository.dart`, `lib/features/services/presentation/assistance_requests_screen.dart`.
- **Expected:** citizen case, history, and requirement-upload routes (the historical welfare and service-delivery paths). None exist. The methods decline (`BackendGap.absentOnNodeContract`). Tulong does not submit an application (item 10).
- **Fixture:** `MockServiceRequestRepository`, `MockRequirementRepository`.

## Aligned on `3e3b110` (not gaps)

These flows call a route that exists, and the fields they send or require are on that schema. They still need a Firebase ID token before any authenticated call can succeed (item 1).

| Flow | Route | Dart |
| --- | --- | --- |
| Password reset | `POST /auth/password-reset/request` (202, `AcceptedEnvelope` with `accepted` and `retry_after`), `POST /auth/password-reset/verify` (`reset_token`, `expires_at`), `POST /auth/password-reset/complete` (`reset_token`, `new_password` → `updated`) | `auth_api_repository.dart` |
| Email code, once signed in | `POST /auth/email-otp/send` (202, same accepted envelope), `POST /auth/email-otp/verify` (`code` → `email_verified`) | `auth_api_repository.dart` |
| Barangay picker | `GET /barangays` → `id`, `code`, `name` | `barangay_api_repository.dart` |
| Startup | `GET /health`, `GET /app/config` | `platform_api_repository.dart` |
| Balita read | `GET /news`, `GET /news/{id}`, `GET /news/categories` (`slug`, `label`; slugs `abiso`, `advisory`, `negosyo`, `safety`, `events`) | `newsfeed_api_repository.dart` |
| Tulong read | `GET /services`, `GET /services/{slug}` | `social_service_codec.dart` |
| Office text | `GET /offices`, `GET /offices/{slug}` | `office_api_repository.dart` |
| Hotlines | `GET /home` and `GET /hotlines` | `node_citizen_api.dart` |
| Profile edit | `GET /me`, `PATCH /me` | `resident_profile_api_repository.dart` |
| Record a consent version | `GET /me/consents`, `POST /me/consents` `{version}` | `privacy_api_repository.dart` |
| Notification preferences and the first page of the list | `GET` and `PATCH /me/notification-preferences`, `GET /notifications`, mark-read routes | `notification_api_repository.dart` |
| Start a thread and read it | `POST /threads`, `GET /threads`, `GET /threads/{id}`, `GET /threads/{id}/messages` | `office_messaging_gap_repository.dart` |

## What this pass did not do

No screen, theme, or repository was changed. No mock was enabled. No GitHub Actions workflow was started. The backend repository was not available to diff against `3e3b110`, so a commit newer than that export would not appear here.
