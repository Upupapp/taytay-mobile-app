# Taytay resident mobile — requirements and document upload

The documents an office is waiting for, and how a resident sends one from a
phone without being told something the app has no standing to say.

Implemented in `lib/core/documents/` and `lib/features/requirements/`.

---

## 1. Submitted is not verified

This is the sentence the whole TAB is built around, and acceptance 3 is exactly
it: a resident must be able to tell the difference between a document the LGU
*has* and a document the LGU has *accepted*.

| Status | What the screen says | Can they replace it? |
| --- | --- | --- |
| `missing` | Not sent yet | yes |
| `submitted` | **Sent — not checked yet** | no |
| `under_verification` | Being checked by the office | no |
| `needs_replacement` | Needs to be sent again | yes |
| `verified` | **Checked and accepted** | no |
| `expired` | Out of date — send a current one | yes |
| *unrecognised* | Being processed | **no** |

The confirmation sheet says it again, in the moment it matters most: *"Taytay
LGU has your document. It has not been checked yet."* A resident who reads
"Done" after uploading, travels to the counter, and finds nobody had looked at
it has been misled by this app.

`submitted` is also what the checklist falls back to when the server's response
carries no status. **Never `verified`** — the app has no standing to decide a
person read something.

### Why `under_verification` cannot be replaced

Replacing a document mid-review sends a caseworker back to the start, and the
resident cannot see that happening. An unrecognised status is refused for the
same reason, failing closed: the cost is a trip to the counter, where failing
open would replace a document in a state this build knows nothing about.

---

## 2. There is no completion meter, and there must not be

TAB 16 says a local 100% requirements meter must not imply approval, and the
reasoning generalises: approval is a decision Taytay LGU staff make after
reading documents, so any progress bar the app draws over that decision is the
app speaking with authority it does not have.

`RequirementChecklist` therefore exposes `outstandingCount` and **no
percentage**. A count of what is left is a statement about the resident's own
to-do list; a percentage complete is a statement about the outcome. A test
asserts neither `%` nor "complete" appears on the rendered checklist.

---

## 3. Bytes, never a path

`CapturedDocument` holds the file's bytes. Two reasons, both Article 5
obligations:

1. **A path points at a file this app does not own and cannot promise to
   delete.** An Android gallery pick may hand back a URI backed by a cache copy
   that outlives the flow; an iOS camera capture may write to the temporary
   directory. Holding bytes gives the sensitive material exactly one lifetime —
   the object's — and the controller releases it on success, on cancellation and
   on dispose.
2. **A path is not a document.** Sending one transmits a reference that means
   nothing off this device.

The server's receipt is an `UploadedDocumentReference`, so a document is
uploaded once and referred to by id afterwards. A retry elsewhere in the app
never re-sends an identity document over a resident's mobile data.

---

## 4. Compression, and the readability floor

The acceptance criterion is that documents stay readable after optimisation,
and that is a resolution question with a real answer. OCR and human reading of
small print on an A4 form both want roughly 150–200 DPI. A4's long edge is 8.27
inches:

* 150 DPI → ~1240 px
* 200 DPI → ~1654 px

So `minLongEdge` is **1600 px** — near the top of that band — and `imageQuality`
is **88**, high enough that JPEG ringing does not close up the counters of small
type. A test asserts the floor stays inside the band, so a later "optimisation"
cannot quietly drop it.

Re-encoding happens **natively**, in the platform picker, which is what makes it
affordable on the mid-range phones most residents carry. **A PDF is never
re-encoded at all**: that is not compression, it is rasterising a document that
may already be a signed original.

---

## 5. The declared type is not trusted

A file's MIME type comes from an extension or from the OS, and both are
attacker-influenced on a shared device. `DocumentCapturePolicy.inspect` matches
the leading bytes against the format's own signature — `FF D8 FF`, `89 50 4E
47`, `%PDF` — and rejects a mismatch.

This is **not** a security boundary; the server validates the upload and its
answer is the one that counts. It is here because catching it on the device
tells the resident something actionable now, instead of after a round trip that
ends in a message written for an operator.

A signature check cannot see a *truncated* file, so the preview also carries an
`errorBuilder`: a decode failure renders a fallback rather than taking down the
sheet the resident is standing in, and sending stays available, because a
preview this device could not render is not proof the office cannot read it.

---

## 6. Two permissions deliberately not requested

| | Declared? | Why |
| --- | --- | --- |
| Android `CAMERA` | **no** | `image_picker` uses `ACTION_IMAGE_CAPTURE`, handled by the system camera app. Declaring `CAMERA` would *add* a runtime grant: once it is in the manifest, Android requires it before that intent returns a photo. Omitting it means one fewer prompt and one fewer capability in the APK. |
| Android `READ_MEDIA_IMAGES` | **no** | Gallery selection goes through the Android photo picker, which returns the single chosen item. The broad permission would grant this app the entire photo library to read one document. |
| iOS `NSCameraUsageDescription` | yes | iOS **terminates** the app when it is missing, so its absence is a crash on the first document, not a degraded feature. |
| iOS `NSPhotoLibraryUsageDescription` | yes | Same. |
| iOS `NSFaceIDUsageDescription` | yes | Added here: `local_auth` has shipped since TAB 09 without it, which would have terminated the app on the first biometric unlock. |

---

## 7. Cancel, progress, retry

* **A cancelled upload never reports success.** The controller checks the
  cancellation *after* the repository resolves, and reports `stopped` regardless
  of what came back. Reporting success for something a resident stopped is the
  worst possible outcome of a cancel button.
* **A full progress bar is not an accepted document.** `UploadStage.accepted` is
  set from an `Ok` and from nowhere else; progress reaching 1.0 means bytes left
  the phone, which is not the same as the LGU having stored them. The uploading
  screen says so: *"Keep this open until Taytay LGU confirms it has the
  document."*
* **A retry replays one attempt.** The idempotency key is minted per document
  and reused until the server answers, so a dropped connection does not leave
  two copies of an ID card in an office queue. A *different* document is a new
  attempt and gets a new key.
* **A failure keeps the document**, so the resident does not re-photograph it.
* **One upload at a time.** Parallel uploads on a weak connection make each one
  slower, make progress unreadable, and leave the resident unable to tell which
  one failed.

Server validation messages are surfaced — the one place server text is shown,
because it is the only place it is actionable. The operator-facing `message`
stays out of it.

---

## 8. Access

`/requests/:requestId/requirements` is verified-only, and the screen carries a
`CapabilityGate` on `ResidentCapability.submitRequirements` as well.

That capability is separate from `applyForAssistance` because the two switch on
at different times: an LGU that has enabled applications still has to enable
attachment storage, and a resident who can apply but cannot yet upload should be
told exactly that rather than meeting a generic refusal.

The request id is re-validated with `DeepLink.isValidIdentifier` at the point of
use — this is the most sensitive deep-link target in the app and it is reached
from a push notification.

---

## 9. What is not built, and why

`ServiceDelivery` remains `planned`, so `PlannedRequirementRepository` declines
both operations. **Declining matters more here than anywhere else in the app:** a
mocked upload reporting success would tell a resident their barangay clearance
had reached Taytay LGU when nothing had left the phone — and they would find out
at the counter, having travelled there on the strength of it. The planned
implementation deliberately reports **no progress** either, because bytes moving
is the one thing a decline must not simulate.

The intake flow's `attachmentIds` seam (TAB 15, D-65) is filled by this flow once
a request exists; at intake time there is no request id to attach to.

---

## 10. Tests

`test/features/requirements_test.dart` — 31 tests.

* policy: empty, oversized, wrong type, spoofed signature, accepted types, PDFs
  never re-encoded, readability floor inside the 150–200 DPI band
* the planned repository declines and reports no progress
* a refused file is dropped rather than previewed; a cancelled picker is not an
  error
* a full progress bar is not acceptance; a cancelled upload never reports success
* a retry replays the same key and keeps the document; a new document gets a new
  key
* a success moves the row to `submitted`, never `verified`, and releases the bytes
* server field messages surface; the operator-facing message does not
* which statuses accept an upload; an unrecognised one fails closed
* guest → sign-in, unverified → verification; capability and route agree
* submitted and verified read differently; an outstanding count with no
  percentage; a document under review cannot be replaced; a reviewer message is
  shown; an absent backend offers no upload; a device with no picker says so
* end-to-end choose → preview → send → confirmation
* no staff vocabulary; 200% text scale
