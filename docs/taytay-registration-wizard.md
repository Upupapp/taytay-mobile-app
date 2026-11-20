# Taytay resident mobile — sign-up and verification

How a resident goes from no account to a verified account the MSWDO can serve, on the Node API
(backend `taytay-backend`, contract pinned in `lib/core/api/backend_baseline.dart`). Rewritten
20 November 2026 (D-226). The earlier version of this file described a mobile one-time-code wizard
with a birth date against the retired PHP contract; that flow no longer exists, and git history
keeps it.

Implemented in `lib/features/auth/presentation/account_wizard_screen.dart` (the sign-up wizard),
`lib/features/verification/` (the verification status pages) and `lib/features/registration/`
(barangays and validation).

---

## 1. The sign-up wizard (`/register`)

One route, `AccountWizardScreen`, with its steps in memory (`_Step`). The order is the server's:
the Node API makes the profile row on the first `GET /me`, and `POST /auth/email-otp/send` refuses a
profile with no email, so the account exists before the code is sent.

| Step | What it asks | What it calls |
| --- | --- | --- |
| Personal details | First and last name, mobile (`09…`), barangay picked from `GET /barangays`, street or purok (optional) | Nothing yet. Once the account exists, a change here is saved with `PATCH /me` |
| Account | Email and password (8 or more characters) | Firebase `createUserWithEmailAndPassword`; `GET /me` (makes the profile row); `PATCH /me` with the name, mobile, email, barangay and street; `POST /auth/email-otp/send`. The email cannot be changed after this step |
| Email code | The 6-digit code sent to the email, with a resend countdown and a hold screen after too many tries | `POST /auth/email-otp/verify` |
| Terms and privacy | Two separate ticks, Terms of Use and the Privacy Notice | `GET /app/config` for the current versions, then `POST /me/consents` once for `privacy` and once for `terms` (D-208); the consent gate is checked again (D-187) |
| Valid ID | ID type, front photo, back photo (optional), and the name check (D-195) | Nothing yet |
| Selfie | The camera, behind the biometric consent (D-209). Declining, or no published consent text, offers verification in person and "Finish for now" (D-210) | The consent dialog records `kind: biometric` itself |
| Review | Every answer, each with an edit link that returns to review | `POST /me/verification-requests`, multipart, with an idempotency key (D-213) |
| Done | "You're all set" | Home |

The header counts these eight screens, "Step 1 of 8" to "Step 8 of 8", so every Continue moves the
counter. It used to read "Step 1 of 6" on personal details, account and email code alike, which
looked like a Continue that had done nothing. A resident whose email is already verified skips the
code screen, and the counter skips its number with it.

A resident who leaves part-way signs in later and is picked up where the server says she is:
consents by `/consent-update` (D-187), the ID and selfie from `/verification` ("Start
verification"). A submit that finds a request already waiting opens the pending page; one that
finds the account already verified reads `GET /me` again and goes home.

## 2. What is not collected, and why

- **No birth date** (D-198; D-195: the app has never collected it). The registry record the office
  holds has one; the account does not need it.
- **No sex, civil status, PhilSys number or sector** at sign-up (D-31). Sectors are applied for
  later, with proof, and decided by a person (D-215).
- **The name is one string on the account** (`PATCH /me` `name`); the wizard joins the parts it
  asks for. The office may correct a verified name against the ID it saw (console DL-198).
- **No account exists without Firebase.** The password is Firebase's; this app never sees it after
  the call that creates the account.

## 3. Verification (`/verification`)

`/verification` reads `GET /me/verification-requests/current` (a `404` is "not started") and the
tier from `GET /me`, and shows one of four pages (`verification_face.dart`):

- **Not verified**: start with the ID and the selfie (`POST /me/verification-requests`), or verify
  in person at the Municipal Hall.
- **Pending**: the review time from `GET /app/config` (D-200); what became of an erased selfie
  (D-212).
- **Needs correction**: the office's per-field notes; photos replaced with
  `POST …/current/documents`, a message with `POST …/current/corrections`. A rejected request is
  said here too: there is no separate rejected page.
- **Verified**: when and how (in the app or in person, D-210), what the resident can now do, and
  the account link below.

The pages re-read when the office acts (D-218).

## 4. After verification: the MSWDO links the account to her record

Verifying an account says who the resident is. It does not yet say **which record at the office**
is hers: the registry was kept at the counter long before the app, and a verified account starts
unconnected to it. The reviewer who verifies her, with her ID in front of them, links the account
to her registry record, makes one, or leaves it unlinked with a reason (backend ADR 0004, decision
1); a sector approval also links it (D-215).

Until it is linked, **My requests reads empty** and **Apply is refused** (the API's `409`). The
Verified page says so in plain words, and so does the Apply wizard when the send is refused: the
MSWDO links the account when it reviews the ID, or at the counter, and the resident can bring a
valid ID and ask (D-226). No read tells the app beforehand whether the account is linked; the app
does not guess.

## 5. Applying for Tulong (D-226)

A Tulong page whose `can_apply` is true offers Apply: what the programme is and who may apply, the
purpose and an optional amount, one file per document the programme asks for (required, optional
or conditional, DL-76), a review, and the send (`POST /me/assistance-applications`). The request
lands in the office's intake queue with a control number; My requests shows it as "Applied in the
app". When the office returns it, the request names the documents still missing and offers Add
documents (`POST /me/assistance-requests/{id}/documents`). See D-226 in
`docs/mobile-ui-decision-log.md`.

## 6. Rules that hold throughout

- **The server decides.** Every gate in the app explains; none protects (Article 3).
- **No server message is shown as the headline.** The app words each failure from its kind; a
  field's own validation message may appear beside that field (Article 5.5).
- **A failed send says plainly that nothing was sent**, or that it is not confirmed when the
  answer never came, and that sending again is safe (D-213, D-226).
- **Nothing personal is logged**, and wizard answers live only in memory.

## 7. Related records

- `docs/frontend/backend-gaps.md`, rows 2, 3 and 20.
- `docs/taytay-startup-and-gates.md`, the consent gate during sign-up.
- `docs/mobile-ui-decision-log.md`: D-187, D-195, D-198, D-200, D-208 to D-213, D-215, D-223, D-226.
