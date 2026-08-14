# Taytay resident mobile — citizen registration wizard

The guided, multi-step registration flow: what it collects, why each field is
there, which steps are server-gated, and what is deliberately not built.

Implemented in `lib/features/registration/` and
`lib/shared/widgets/form_support.dart`.

---

## 1. What the committed backend actually supports

Audited against **`Taytay_Rizal_LGUIDS_Backend@896cec9`**
(`docs/contracts/frontend-endpoint-matrix.md`, `frontend-backend-gap-list.md`),
working tree clean. `modules/` still holds only `Shared`, `AccessControl` and
`ServiceCatalog`.

**The single most important finding: there is no account-creation endpoint.**

The citizen contract is:

| Row | Endpoint | Status |
| --- | --- | --- |
| Request code | `POST /api/v1/auth/otp` `{mobile_number}` → `202` | `planned` |
| Verify code | `POST /api/v1/auth/otp/verify` `{mobile_number,code}` → `{token,…}` | `planned` |
| Session bootstrap | `GET /api/v1/me` → actor + `verification_tier` | `planned` |
| Profile update | `PATCH /api/v1/me/profile` — **contact fields only** | `planned` |
| Verification status | `GET /api/v1/me/verification` → tier + outstanding steps | `planned` |
| Submit verification | `POST /api/v1/me/verification/submissions` → `202` | `planned` |
| Barangay reference | `GET /api/v1/barangays` | `planned` |

So a citizen account **comes into existence through the one-time-code
exchange**, and identity details travel as a *verification submission*, not as
an account payload. The matrix is also explicit that a citizen *may not edit
their own eligibility-bearing fields*.

This shaped the whole feature. A `POST /api/v1/register` carrying demographics
would have been an invented endpoint, and `RegistrationRepository` therefore has
**no `createAccount` method** — a test asserts the contract surface is
OTP + capabilities + barangays + submit.

**OTP is in the flow because the contract puts it there**, not because the app
wanted a code screen (Master Command item 2: "OTP only if contract
supports/requires it").

---

## 2. The steps

| # | Step | Present when |
| --- | --- | --- |
| 1 | Contact — mobile number | always |
| 2 | Confirm code | always (contract authenticates this way) |
| 3 | Your details — name, birth date | always |
| 4 | Your address — barangay, street | always |
| 5 | Terms and privacy | always |
| 6 | Proof of identity | **only when the server requires it** |
| 7 | Photo of you | **only when the server requires it AND biometric consent is given** |
| 8 | Review | always |
| 9 | Submitting | outcome |
| 10 | Status and next step | outcome |

Six input steps in the current build; steps 9 and 10 are outcomes and are
excluded from "Step 3 of 6", because counting them would tell a resident there
is more to do than there is.

### Why a wizard rather than one form

A single screen carrying name, birth date, address, consent checkboxes and two
file pickers is abandoned far more often, and — more importantly — it presents
consent as one more checkbox in a wall of inputs. Under RA 10173 consent must be
*informed*; it cannot be informed if the explanation sits as fine print beside
twelve other controls.

---

## 3. Data minimisation

`RegistrationDraft` holds only what lets the LGU match an existing resident
record:

- given / middle / family name and suffix,
- date of birth,
- barangay and street address,
- the mobile number the account authenticates on.

**Deliberately absent**, though the staff console's own `Resident` model carries
them: `sex`, `civilStatus`, `sectors`, `monthlyIncome`, `philsysLastFour`,
`householdId`. None narrows a name-and-birth-date match; several are sensitive
personal information under RA 10173 §13; and the committed contract gives this
client no endpoint that would accept them. A test asserts they are not there.

`RegistrationDraft.toString()` renders nothing — it is exactly the kind of
object that reaches a crash report. `SelectedUpload.toString()` reports a MIME
type and a size, never the file reference.

---

## 4. Consent

Four separate consents, each recorded individually:

| Consent | Required |
| --- | --- |
| Terms of Use | yes |
| Privacy Notice | yes |
| Processing of identity information | yes |
| Processing of photo for identity checking | **no** |

Bundling them into one "I agree" is what makes consent unfree: a resident who
wants a municipal service but not biometric processing would have no way to say
so, and the LGU could not show which processing was agreed to. RA 10173 requires
consent to be freely given, specific and informed.

The biometric consent is **optional and only shown when the server actually
requires a face capture** — asking for it otherwise would collect a consent for
processing that will not happen. Consent that cannot be refused is not consent.

---

## 5. Feature gating — deny by default

`RegistrationCapabilities` starts with every flag `false` and **only a server
response may widen it**. The authoritative source is
`GET /api/v1/me/verification` ("tier + outstanding steps"), which is `planned`.

So in this build:

- `requiresIdentityDocument` = false → step 6 is absent,
- `requiresFaceCapture` = false → step 7 is absent,
- `acceptsSubmissions` = false.

**No camera or file picker is opened anywhere**, and a test asserts the steps do
not appear. Two reasons this is the right default rather than a placeholder: a
client that decides on its own to collect a face photo is collecting the most
sensitive artifact in the system (backend gap **G-18**, which leaves the upload
contract unspecified) without the LGU asking; and whether a given resident needs
a document at all is a matching decision only the server can make.

The selfie step needs **both** the server requirement **and** explicit consent.
Either alone is insufficient, and withdrawing consent removes the step again —
all three cases are tested.

---

## 6. Non-enumerating errors

On the contact and code steps, the answer must be identical whether or not the
number belongs to an existing account. "This number is already registered" would
turn registration into an oracle for testing who is a Taytay resident. The
committed matrix states this on the `POST /api/v1/auth/otp` row — *"must not
reveal whether the number is registered"* — and the client must not undo it.

`_residentSafeMessage` therefore renders a `409 CONFLICT` as:

- contact / code steps → *"If this mobile number can be used, we have sent a
  code to it."*
- later steps → *"We could not complete this automatically. Please visit the
  Taytay municipal hall with a valid ID."*

A `422` shows a generic banner; field-level server messages appear against their
fields, which is the one place server text is actionable. **No server message is
ever rendered as the headline**, and no message describes another record.

---

## 7. Form quality

- **Error summary** at the top, a live region, focused when submission fails —
  an inline message beside a field below the fold is invisible to a sighted
  resident and silent to a screen-reader user. This is the GOV.UK Design System
  pattern and the reasoning carries: a government form is used once, under time
  pressure.
- **Inline errors** as well, against each field.
- **Required *and* optional are labelled in words.** Marking only required
  fields leaves the rest to inference, and an asterisk means nothing to a screen
  reader.
- **"Why we ask for this"** — an expandable panel on every sensitive field
  giving purpose, who sees it, and what happens if the resident declines.
  Collapsed by default; expanding never costs progress. RA 10173 requires the
  purpose to be available *at the moment of collection*.
- **Upload guidance** states what a good photo looks like *before* the picker
  opens, rather than after a review queue rejects it days later.
- **Safe back navigation**: back never validates, always retains the draft, and
  the system back gesture steps backwards rather than discarding everything.
- **Review with per-row "Change"**, which jumps backwards only — never forward
  into a step that was not completed.

---

## 8. Submission

`submitRegistration` requires an `Idempotency-Key`, and the controller mints one
per attempt and **reuses it across retries**. A registration submitted twice is a
duplicate identity review in a municipal queue, and the resident cannot tell
whether the first arrived.

A failed submission says plainly that **nothing was submitted**, so retrying is
safe, and offers the municipal hall as the alternative.

The shipped `PlannedRegistrationRepository` declines every call with a temporary
`ServerFailure`. A mock that succeeded would be the most dangerous placeholder in
this app: it would tell a resident their identity documents had reached the LGU
when nothing left the device, and it is exactly the screen that gets demonstrated
to a municipal officer as proof the system works.

---

## 9. Barangays

Five, names only, no PSGC codes: Dolores, Muzon, San Isidro, San Juan,
Santa Ana. Source: `Taytay_Rizal_Social_Welfare_Angular@c470960`,
`src/app/domain/geography/barangay.ts`.

PSGC codes are deliberately absent. The staff console leaves them `null` with a
comment that a wrong code is worse than an absent one because DSWD reporting
keys off it; the backend repeats this as gap **G-11** and resolves it by loading
the authoritative PSA dataset server-side. This client is in no position to
improve on that. The local `id` values are selection keys, not municipal
identifiers, and the server's list replaces this one wholesale when
`GET /api/v1/barangays` lands.

---

## 10. Verification

`dart format` clean · `flutter analyze` clean · **382 tests pass** · debug and
release APKs build.

Registration-specific coverage (47 tests): draft minimisation and redaction;
upload descriptor redaction; mobile-number, name, birth-date and address
validation; acceptance of single-word, accented, hyphenated and apostrophe names;
the 15-year age floor; no invented code-length rule; required-versus-optional
consent gating; capabilities defaulting to denied; document and selfie steps
absent, present only on server requirement, and the selfie needing consent as
well; consent alone never enabling it; invalid steps not advancing; back
retaining every field; back clearing errors; progress counting input steps only;
review "Change" refusing forward jumps and steps outside the flow; failed
code-request and code-verify keeping the resident in place; capabilities re-read
after verification; idempotency key present and reused across retries; failed
submission stating nothing was submitted; the shipped repository declining; the
barangay list carrying no PSGC codes; reaching the wizard from sign-in and from
the gate sheet; progress announced as text; one step per screen; error summary;
expandable explanations; no picker opened; 200% text scale; and the progress bar
hidden from assistive technology.

Source scans additionally assert that registration types never interpolate
personal fields into `toString`, and that no file under `lib/features/registration/`
references `Uint8List`, `dart:io` or `File(` — this build holds no identity image
bytes it cannot send.

---

## 11. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| R-1 | No `Identity` module or OTP endpoints | Requesting and verifying a code decline; registration cannot complete end to end. |
| R-2 | No verification-submission endpoint | Submission declines; the status step reports that nothing was sent. |
| R-3 | No upload contract (backend **G-18**) | Document and selfie steps carry guidance and consent but capture nothing. |
| R-4 | No `GET /api/v1/me/verification` | Capabilities stay denied, so optional steps never appear. |
| R-5 | No `GET /api/v1/barangays` | A five-item local list is used, names only. |
| R-6 | No resident-matching contract | Duplicate/match handling is copy-only; the actual match happens server-side. |
| R-7 | Draft is not persisted | Closing the app mid-registration loses progress. Deliberate: a partly-filled identity form is personal data, and persisting it needs the keystore and a retention rule. |
| R-8 | English only | Filipino copy arrives with app-wide localisation. |
