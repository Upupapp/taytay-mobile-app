# Master supervisor — recovery checkpoint

Compact state for resuming this Master Command run. **Not a transcript.**

## Master Command

`Taytay_Rizal_LGUIDS_Resident_Mobile_Flutter_Master_Command.pdf` — LGU IDS,
Municipality of Taytay, Rizal. Resident-facing **Flutter** mobile app.
**28 indexed TABs.** Reference hierarchy: Esperanza-Mobile = resident
function/onboarding only · ServanaClientAPP = design/motion/haptics only ·
Taytay = the only brand · **backend/OpenAPI = the authority** · Flutter = impl.

Repo: `C:\Users\paulg\OneDrive\Desktop\Taytay_Rizal_LGUIDS_Resident_Mobile_Flutter`
Root constitution: `CLAUDE.md` (highest authority in the repo).

## Progress

**15 of 28 TABs complete (53.6%).** TAB 01–15 certified. Next: **TAB 16 —
Requirements & Secure Document Upload**.

## Architecture (stable across TABs)

* Feature-first: `lib/features/<feature>/{presentation,domain,data}`,
  `lib/core/` for seams, `lib/shared/widgets` for cross-feature widgets.
* Dependencies point inwards: `presentation → domain ← data`. `core/` never
  imports `features/` **except** `core/router/app_router.dart`.
* State: `ChangeNotifier` + `InheritedWidget` from `AppDependencies`
  (composition root, `lib/app/app_dependencies.dart`). No service locator.
* Navigation: `go_router`; **every** route in `core/router/app_routes.dart`
  declares an `AccessRequirement`; one guard, `resolveRedirect`.
* Errors: `Result<T>` + closed `AppFailure` set. Never throw across layers.
  Branch on error **code**, never message. Server `message` is operator-facing
  and is never rendered to a resident.
* Unknown server enum values are carried as `ServerValue<T>` (raw + known), never
  dropped, never guessed.

## The rule that shapes almost every decision

Only **`Shared`, `AccessControl` and `ServiceCatalog`** are implemented on the
backend. `Identity`, `ResidentProfile`, `Credential`, `Verification`,
**`ServiceDelivery`** and `Notification` are **`planned`** — no endpoints.

Every repository for a planned module returns `plannedBackendFailure(...)`
(temporary `ServerFailure`). **Decline, never mock.** Screens render an honest
"Taytay LGU has not switched this on yet" state naming the municipal hall.
Tests inject fake repositories to exercise the real flows.

## TAB 15 (just completed) — assistance request intake

* `AssistanceIntakeForm` is **fetched from the server**, never authored in the
  client. No per-service question list exists in the app.
* Steps derived from the form; draft immutable; back never loses input.
* One idempotency key per attempt, reused on retry, retired on any server answer.
* `409` → `alreadyOpen` outcome, not an error; retry is a no-op.
* An `IntakeAnswerKind` this build cannot render **blocks submission** and names
  the question — never skipped, never guessed.
* Requirements are **listed** here; uploading is TAB 16.
* New route `/apply/:serviceCode` (verified, top-level, full-screen).
* New capability `ResidentCapability.applyForAssistance`.
* `FieldError` moved `features/registration/domain` → `core/forms/`, re-exported.

## Test / build state

`flutter analyze` — **clean** (no errors, warnings or infos).
`flutter test` — **740 passing** (712 before TAB 15, +28 new).
`dart format` — clean.
No release build attempted this session (no device/toolchain target requested).

## Environment gaps (non-blocking, carried forward)

* `ServiceDelivery` unpublished → intake/submit/track decline at runtime. This
  is the honest state, not a defect.
* No Android/iOS device build run in this session.

## Git

Branch `main`. Local commits only — **never push** (constitution Article 10).
Working tree reconciled before every edit; no pre-existing dirty work was found
at session start (tree was clean at `9fb9a57`).

## Exact next action

Begin **TAB 16 — Requirements & Secure Document Upload**: requirement checklist
with server-declared statuses, camera/gallery/file picker, preview, compression
that preserves readability, progress/cancel/retry, secure file references, and
no document contents in analytics. It owns upload for *both* a new application
(TAB 15's `attachmentIds` seam) and an existing request.
