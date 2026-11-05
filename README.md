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

# Synthetic data and a mock identity. Firebase is never started.
flutter run --flavor dev --dart-define=TAYTAY_ENV=dev --dart-define=TAYTAY_DATA=mock

# The live API on the emulator's host route, signing in to Firebase
flutter run --flavor dev --dart-define=TAYTAY_ENV=dev \
            --dart-define-from-file=env/firebase.dev.json

# Against a backend on your LAN or a local server
flutter run --flavor dev --dart-define=TAYTAY_ENV=dev \
            --dart-define=TAYTAY_API_BASE_URL=http://192.168.1.10:8000/api/v1 \
            --dart-define-from-file=env/firebase.dev.json

# Staging
flutter run --flavor staging --dart-define=TAYTAY_ENV=staging \
            --dart-define=TAYTAY_API_BASE_URL=https://staging-api.example.invalid/api/v1 \
            --dart-define-from-file=env/firebase.staging.json
```

Every build except the mock one signs residents in through Firebase and needs the
four `TAYTAY_FIREBASE_*` values. They live in gitignored `env/firebase.<env>.json`
files; copy `env/firebase.example.json` and fill it. A build without them stops on
the configuration screen. The staging Firebase project is `taytay-lgu-ids-staging`.
There is **no production project yet**, and **iOS cannot sign in** until an iOS app is
registered in Firebase. Replace the staging URL above with the staging API's public
`https` base URL. See [`docs/release.md`](docs/release.md#firebase).

Release builds have no default staging or production host. The exact
`appbundle`, `apk`, and `ipa` commands, including the keystore and the iOS
export options, are in [`docs/release/README.md`](docs/release/README.md).

| `--dart-define` | Values | Notes |
| --- | --- | --- |
| `TAYTAY_ENV` | `dev`, `staging`, `prod` | Required for release builds |
| `TAYTAY_API_BASE_URL` | absolute URL incl. `/api/v1` | Required for release, staging, and production. Dev debug may omit it. https required outside `dev` |
| `TAYTAY_DATA` | `live` (default), `mock` | `mock` only in a dev debug build |
| `TAYTAY_FIREBASE_API_KEY`, `TAYTAY_FIREBASE_APP_ID`, `TAYTAY_FIREBASE_PROJECT_ID`, `TAYTAY_FIREBASE_MESSAGING_SENDER_ID` | from `env/firebase.<env>.json` | Required by every build except a dev mock |

**Never put a secret in a `--dart-define`.** Those values ship in clear text inside the
APK/IPA. See `CLAUDE.md` Article 5. The four `TAYTAY_FIREBASE_*` values are its one
named exception: public Firebase project identifiers, never logged and still not
committed (Article 5.4, decision D-185).

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

Residents sign in with Firebase Auth (email and password). The API only ever sees the
Firebase ID token, and the first authenticated `GET /me` creates the citizen record.
Firebase is started at launch from the `TAYTAY_FIREBASE_*` defines; a dev mock build
uses a mock identity instead and never starts it.
