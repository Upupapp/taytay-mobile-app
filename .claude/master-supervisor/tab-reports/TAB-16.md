# TAB COMPLETION REPORT

**TAB:** 16 — Requirements & Secure Document Upload
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

Requirement checklist with server-declared obligation and status; camera /
gallery / file capture behind one seam; local policy checks (size, type,
signature); preview with a decode fallback; upload with progress, cancel and
retry; idempotency-aware replay; server validation surfacing; and the
submitted-versus-verified distinction carried through model, copy and tests.

## Deliverables

* `lib/core/documents/document_capture.dart` — `CapturedDocument`,
  `DocumentCapturePolicy`, `DocumentRejection`, `DocumentPicker` +
  `UnavailableDocumentPicker`
* `lib/core/documents/platform_document_picker.dart` — `image_picker` +
  `file_selector` at the edge
* `lib/features/requirements/domain/resident_requirement.dart` — statuses,
  obligations, checklist, upload reference, cancellation, repository contract
* `lib/features/requirements/data/planned_requirement_repository.dart`
* `lib/features/requirements/presentation/requirements_controller.dart`
* `lib/features/requirements/presentation/requirements_screen.dart` + upload sheet
* `ResidentCapability.submitRequirements`; `/requests/:id/requirements` now
  renders the real screen
* `AppDependencies.requirementRepository` and `.documentPicker`
* iOS `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` and
  `NSFaceIDUsageDescription`; Android manifest rationale for the permissions
  **not** declared
* `docs/taytay-requirements-and-uploads.md`; decision log D-69 … D-77
* `test/features/requirements_test.dart` — 31 tests

## Material decisions

D-69 bytes with one lifetime, never a path · D-70 readability floor from A4 DPI,
PDFs never re-encoded · D-71 declared MIME verified against the signature ·
D-72 no Android `CAMERA`, no `READ_MEDIA_IMAGES` · D-73 submitted ≠ verified, no
completion meter · D-74 a cancelled upload never reports success · D-75
acceptance comes from an `Ok`, not from a full bar · D-76 an unrecognised status
fails closed · D-77 an undecodable preview falls back but still allows sending.

## Defect found and fixed in passing

`NSFaceIDUsageDescription` was missing although `local_auth` has shipped since
TAB 09. iOS terminates the app when that key is absent, so the first biometric
unlock on a Face ID device would have crashed the app. Added.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 771 tests (740 → 771) |
| `dart format` | **PASS** — clean |
| Access tested from every session state | **PASS** — guest, unverified, verified |
| Platform build | **NOT_RUN** — no build target requested this session |

## Environment / production-only gaps

* `ServiceDelivery` is `planned` — no requirement list and no upload endpoint, so
  the shipped repository declines and reports no progress. Non-blocking.
* The platform picker cannot be exercised in a widget test; it is thin glue and
  everything decidable without a platform channel is unit-tested.
* No Android/iOS device build was run, so the new plugins are resolved and
  configured but not yet exercised on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 17 — Assistance Status, Case Timeline & Next Steps.**
Automatic advancement: AUTHORIZED.
