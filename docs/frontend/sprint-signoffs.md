# Sprint sign-offs

A sprint is approved only when Paul writes the words below on its pull request.
This file records that the words were looked for. It does not invent them.

| Sprint | Status | Pull request | Commit | Approval |
| --- | --- | --- | --- | --- |
| S0 Foundations | In review | https://github.com/Upupapp/taytay-mobile-app/pull/1 | 6e27dc354fb1feaf50c2f2a7e64eaccb34ecca25 | Waiting for "S0 approved" |

## S0 pixel match

S0 renders shared components and the dev gallery. It does not render the 84 resident screens (those are S1–S8). Comparison uses `tool/golden_compare` against crops of the design PNGs in `design-refs/` (gitignored). The side-by-side is design | build | diff.

| Component | Design crop | Mismatch | Layout |
| --- | --- | --- | --- |
| Primary button, label "Sign in" | `02-01` navy pill, 964×150 px | 2.91% (4214/144600) | Pill bounds identical. Glyph centroid shift 0.2 px horizontal, 0.1 px vertical. |

The button fill is `#0B3D91`. The pixels over 2% are antialiased glyph edges between the design export and Flutter's renderer. No element is more than 4 px out. Side-by-side: `test/goldens/compare/signin_primary.png`.

Exceptions, recorded rather than forced under 2%:

- Screens `01-01` through `08-10` are not built in S0. A full-frame compare against the current home would measure later sprints.
- Photographs and the OS status bar are excluded by the pixel-match method.
- The back control is a 44 dp circle inside a 48 dp target (decision D3). Some mockups draw a bare chevron. The circle is the agreed control.

## Contract gaps after the Node OpenAPI

F31 is closed. `GET/POST /threads`, messages, mark-read, and close are citizen routes and the live repository calls them.

These designs still need data the spec does not publish. The calls decline with F32, or the screen keeps static copy:

- Sign-in, sign-up, email code, forgot password (`02-01`–`02-11`). No OTP or password routes. Identity is a Firebase ID token. This app does not add the Firebase SDK. Dev sessions use `Authorization: Bearer mock:<role>:<id>` with role `registered` or `verified` only.
- Self-registration and the office contact line. No `app/bootstrap` and no `features.self_registration`. The wizard stays off the signed-out path. Creating an account is not offered from sign-in.
- Token revocation. Sign-out clears the session on the device.
- Digital ID and QR (`01-02`, account). No credential resource.
- Events catalogue and registration. No events resource.
- Household (`03-07`). Address is a string on `PATCH /me`. Barangay is an id from `GET /barangays` (`id`, `code`, `name` only — no phone).
- Assistance intake, drafts, requirements, and document checklists. Tulong is `GET /services` and `GET /services/{slug}`. There is no apply route.
- Notification preferences and device registration. Inbox types are only `verification_decided` and `message_received`. Design categories such as advisory, treasury, and BPLO are not in that enum.
- News comments, reactions, and reports. A resident reads `GET /news`. This app does not call `POST /news` or `PATCH /news`.
- Account closure.
- Hotlines as their own resource, weather, payments, and map tiles. An office may carry `phone`, `email`, `latitude`, `longitude`, and `address`. The resident decoder does not surface the coordinates. The design's location cards are an illustrative drawing.
- Welcome copy, photo credits, and a bundled hall photograph. None of those are API fields.
- A thread has no subject or preview. The start call returns the thread. The client loads messages for a preview.
- Verification is `POST /me/verification-requests` (multipart `id_type`, `id_front`, optional `id_back`, `selfie`) and `GET /me/verification-requests/current`. It is not the old multi-step case with a documents list. Staff assignment on a profile is not modeled on a resident type.
