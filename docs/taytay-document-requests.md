# Taytay resident mobile — document requests

A verified resident asks a municipal office for a document it issues (a
certificate, a certified copy) and follows the request to the counter. Code and
wire names say **issuance**; every screen says **document request**.

Implemented in `lib/features/issuance/`, against backend `2fd0566`
(`docs/api/endpoints.md`, "Document requests (issuance)"). The Node export in
`docs/integration/taytay-node-openapi.json` was refreshed from that commit.

---

## 1. Routes and who reaches them

| Route | Screen | Requirement | Why |
| --- | --- | --- | --- |
| `/documents` | Catalogue, grouped by office; a search field from 8 types up | public | `GET issuance-types` needs no token. Reading what a document needs is not an act on a record. |
| `/documents/types/:typeId` | What it is, what it needs, fee, processing time, how to claim | public | Same. |
| `/documents/types/:typeId/request` | Purpose, files, review, send, reference number | verified | The server accepts a request from a verified resident only. |
| `/documents/mine` | My document requests (cursor pages) | authenticated | The API serves the list to any signed-in resident. |
| `/documents/mine/:requestId` | Status, timeline, the office's words, resubmit, cancel, claim details | authenticated | Same. Anybody else's request is a 404 from the server. |

**The gate explains; it does not decide.** A guest or an unverified resident
reads the catalogue and the type page with a notice above them ("Sign in to
request a document" or "Verify your account first"), and the "Request this
document" button is not offered. A typed or linked address to the form is sent
to `/verification` by the route guard. The server refuses an unverified submit
with `403` whatever the app shows, and the form then says, in this app's words,
that only verified residents can send a request and that nothing was sent.

## 2. Entry points

- The verified status page (My Account → Verification status): the "Request
  documents" line now opens the catalogue.
- The account centre (guest and unverified, and the resident record): a
  "Request documents" row opens the catalogue, with the subtitle "Sending a
  request needs a verified account" for anybody not verified.
- The catalogue links to My document requests for a signed-in resident.
- The `issuance_request_updated` notification opens the request it names.

**Not added, and why.** The verified My Account home (`08-01`) is a fixed
frame: two menu cards and a sign-out card that fills what is left. An eighth
row overflows it (the route walk in `foundation_routes_test.dart` caught 9 px
at 400×900, and a 390×844 phone has less). Home's four quick-action tiles are
the approved design too. A direct row for verified residents needs a design
decision: a scrolling account home, or a row traded for this one.

## 3. What the screens say

**Money is integer centavos.** `formatPesos` splits `fee_centavos` with `~/` and
`%`; nothing is a `double`. A stated fee reads "Fee: ₱50.00, paid at the
office". `null` reads "No fee stated" (not "free"); zero reads "No fee". There
is no online payment, and no line suggests one.

**Processing time** is the office's working days: "About 3 working days",
"Usually the same working day" for 0, and "Processing time not stated" for
`null`.

**Statuses in plain words**, defined once in `issuance_status.dart`:

| Wire | Label | Chip |
| --- | --- | --- |
| `submitted` | Sent to the office | blue |
| `under-review` | Being reviewed | blue |
| `needs-info` | Needs more from you | amber |
| `approved` | Approved, being prepared | green |
| `ready-for-pickup` | Ready to claim | gold |
| `released` | Claimed | green |
| `rejected` | Not issued | red |
| `cancelled` | Cancelled | grey |
| *unknown* | Updated | grey |

The history is drawn with the verification pages' `Timeline`, which moved to
`lib/shared/widgets/s3_surface.dart` (with `S3Card`, `IconTile` and the type
scale) so a second feature could use it without reaching into another
feature's presentation layer. Each history line is this app's own sentence;
the office's message (or the resident's own note) is shown beneath it as
written, because every reason the office writes is meant for the resident.

**Cancel and resubmit are offered only when the server says so**
(`can_cancel`, `can_resubmit`). A missing flag offers nothing.

## 4. Files

One picker per requirement, through the same `DocumentPicker` the verification
and requirements uploads use (camera, photo library, or file, whichever the
phone offers). Each file is checked on the phone against the type's own
`accepts` block (`UploadPolicy.decode`, `DocumentCapturePolicy.inspect`): size,
type, and that the bytes match the type. A refused file is dropped at once.

A part is sent under its requirement `code` with the file name
`<code>.<ext>`. The name the phone gave the file is never sent: a gallery name
routinely carries a person's name or a document number.

A resubmission takes a note, files, or both, and says that a new file is kept
beside the old one. Its upload policy is read from the type
(`GET issuance-types/{id}`); a retired type falls back to the labelled
`UploadPolicy.fallback`.

The resident may view a photo they sent (`.../attachments/{id}/content`). The
bytes live in the dialog and go when it closes. **A PDF is listed but not
opened**: the app has no PDF viewer and the binary path only reads images.

## 5. Honest states

- Loading shows skeletons; an empty list says so and offers a request.
- Offline, a load says "You are offline"; a send says "Nothing was sent. Your
  answers are still here."
- A timeout on a send does **not** say nothing was sent: it cannot know. It
  asks the resident to open My document requests before trying again.
- Every send failure is this app's own copy, chosen by the failure kind
  (`issuance_failure_copy.dart`). The server's `message` never reaches a
  screen. A `422` keyed by requirement code marks those files; it does not
  print the server's words.

## 6. Privacy

- The purpose is the resident's own words. It is shown on the review step and
  the request's own page, never on a list row, and never in `toString`.
- No new field reaches the session or the keystore. Nothing is cached.
- The notification carries the request id in `subject_id` and nothing else;
  the request is fetched under the live session after the tap.

## 7. Data

- `IssuanceRepository` (domain), `IssuanceApiRepository` (Node API),
  `MockIssuanceRepository` (dev mock, `TAYTAY_DATA=mock`). The mock's fixtures
  are written in the wire shape and read through the same `IssuanceCodec`.
- Eight routes are declared in `lib/core/api/backend_routes.dart`.

## 8. Tests

- `test/features/issuance_domain_test.dart`: labels, fee and time formatting,
  purpose and file checks, catalogue grouping and search, redaction.
- `test/features/issuance_api_repository_test.dart`: every route against a
  scripted transport, the multipart parts and file names, `201` only, `403`
  and `422`, cursor paging, missing flags, attachment bytes, and the
  notification's deep link.
- `test/features/issuance_screens_test.dart`: the gate as guest, unverified and
  verified; form validation; a refused file; send success, `403` and offline;
  the list, the needs-info timeline and resubmit, claim details, and cancel.
- `test/recording/issuance_frames_test.dart` (skipped by default) draws the
  owner's frames from sample data.
