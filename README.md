# Taytay LGU IDS — Resident Mobile App

The resident-facing Flutter app for the Municipality of Taytay, Rizal Identity & Services
platform. It is the `citizen-mobile` client of the Taytay LGU IDS backend API.

> **Read [`CLAUDE.md`](CLAUDE.md) first.** It is the constitution for this repository and
> outranks any other instruction here.

## Who this app is for

Residents of Taytay, in three states:

| State | What they can do |
| --- | --- |
| **Guest** | Browse municipal services and information |
| **Authenticated / Unverified** | Manage the account, start identity verification |
| **Verified** | Hold and present the digital ID, apply for services |

There are **no admin or staff features** in this app, by design.

## Requirements

* Flutter stable (developed against **3.44.0**, Dart **3.12.0**)
* Android SDK for Android builds; Xcode on macOS for iOS builds

## Running

The environment is a compile-time constant. There is no in-app switcher.

```bash
flutter pub get

# Local development (defaults to the Android emulator's host route)
flutter run --dart-define=TAYTAY_ENV=dev

# Against a backend on your LAN or a local Laravel server
flutter run --dart-define=TAYTAY_ENV=dev \
            --dart-define=TAYTAY_API_BASE_URL=http://192.168.1.10:8000/api/v1

# Staging / production builds must declare their environment explicitly —
# a release build without TAYTAY_ENV refuses to start.
flutter build apk --release --dart-define=TAYTAY_ENV=prod
```

| `--dart-define` | Values | Notes |
| --- | --- | --- |
| `TAYTAY_ENV` | `dev`, `staging`, `prod` | Required for release builds |
| `TAYTAY_API_BASE_URL` | absolute URL incl. `/api/v1` | Optional override; https required outside `dev` |

**Never put a secret in a `--dart-define`.** Those values ship in clear text inside the
APK/IPA. See `CLAUDE.md` Article 5.

## Checks

```bash
flutter analyze   # must be clean — no errors, warnings or infos
flutter test
```

## Layout

```
lib/
  main.dart                  entrypoint
  app/                       composition root, root widget, dependency scope
  core/
    api/                     transport seam, envelope decoding, request context
    config/                  environment + API configuration
    design/                  design tokens + Material 3 theme
    haptics/  motion/        haptic and motion tokens (reduced-motion aware)
    result/                  Result<T> and the AppFailure taxonomy
    router/                  route table + access guard
    session/                 session state, controller, store, access policy
  features/<feature>/
    presentation/ domain/ data/
  shared/widgets/
```

Dependencies point inwards: `presentation → domain ← data`. See `CLAUDE.md` Article 2.

## Backend contract

The Taytay LGU IDS backend is authoritative for schema, lifecycle and every authorization
decision. This app:

* sends `X-Client-Channel: citizen-mobile` and a correlation `X-Request-Id`;
* reads the `{ data, meta }` / `{ error: { code, message, details, request_id } }`
  envelopes;
* branches on the error `code`, never the message, and ignores unknown fields;
* treats a `401` as the single signal that ends a session.

Authentication endpoints do not exist yet — the backend's `Identity` module is planned —
so `PendingBackendAuthRepository` declines sign-in honestly rather than mocking a session.
`GET /api/v1/health` is wired end to end and is the reference implementation for future
repositories.
