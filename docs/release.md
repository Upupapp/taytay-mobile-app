# Release builds

Local commands for a signing machine. This repository does not build releases
in GitHub Actions. Icon and splash generation stay in
`docs/release/README.md`. `pubspec.yaml` is `version: 1.0.0+1`.

## Identifiers

| | Value |
| --- | --- |
| Android `applicationId` and namespace | `ph.gov.taytay.app` |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `ph.gov.taytay.app` |
| Store / home-screen name | `Taytay` |

The Android label is the prod flavor's `app_name` (`Taytay`). iOS reads
`CFBundleDisplayName` and `CFBundleName`, both `Taytay`. Dev and staging
installs are `Taytay (dev)` and `Taytay (staging)`, with application-id
suffixes `.dev` and `.staging`, so they can sit beside the store app. The
flavor does not set `TAYTAY_ENV`. Pass the matching `--dart-define`.

## API base URL

The base URL comes only from `--dart-define=TAYTAY_API_BASE_URL` (Article 7).
There is no second define name. A release build with the value missing, not
an absolute URL, cleartext outside dev, carrying credentials, or carrying a
query string stops on the configuration screen. It does not fall back to a
host.

The only baked-in host is `http://10.0.2.2:3000/api/v1` (the Node API's
`npm run dev` port, through the Android emulator's route to the host), and only a dev debug
build that omits the define may use it. `https://unconfigured.invalid` is the
placeholder the startup screen refuses before anything connects.

`--dart-define=TAYTAY_DATA=mock` is impossible in a release build.
`usesMockData` is false when `kReleaseMode` is true, and `MockFixtures` will
not read `test/fixtures/mock/`. A release build also refuses to start if the
flag is set, including when `TAYTAY_ENV=dev`.

The value is a public URL, including `/api/v1`, and `https` outside dev. A
`--dart-define` is recoverable from the binary. Do not put a secret in one.

## Firebase

Residents sign in through Firebase Auth. `main()` starts Firebase from four
`--dart-define` values and from nothing else: there is no Google Services
Gradle plugin, no `google-services.json` and no `GoogleService-Info.plist`
(decision D-185).

| `--dart-define` | Firebase console name |
| --- | --- |
| `TAYTAY_FIREBASE_API_KEY` | Web API key |
| `TAYTAY_FIREBASE_APP_ID` | App ID of the app registered for this platform |
| `TAYTAY_FIREBASE_PROJECT_ID` | Project ID |
| `TAYTAY_FIREBASE_MESSAGING_SENDER_ID` | Project number |

They are public project identifiers, the one exception Article 5.4 names. They
are never logged, and they are still not committed.

Every build needs all four except a dev debug build with
`TAYTAY_DATA=mock`, which uses the mock identity and never starts Firebase.
Any other build without them stops on the configuration screen and names the
missing defines. That includes staging, prod, every release build and a dev
debug build against the live API. An app ID registered for Android stops an
iOS build the same way. If Firebase will not start with the values given, the
build stops there too. It does not start and then fail at sign-in.

### Value files

The values live in gitignored files under `env/`, passed with
`--dart-define-from-file`. Only `env/firebase.example.json` (four empty values)
is tracked.

| File | Firebase app | Flavor |
| --- | --- | --- |
| `env/firebase.dev.json` | Android `ph.gov.taytay.app.dev` in `taytay-lgu-ids-staging` | `dev` |
| `env/firebase.staging.json` | Android `ph.gov.taytay.app.staging` in `taytay-lgu-ids-staging` | `staging` |
| `env/firebase.prod.json` | none: there is no production project yet | `prod` |

To make one, copy the example and fill it from the Firebase console
(Project settings, Your apps, the app for that flavor):

```bash
cp env/firebase.example.json env/firebase.staging.json
git check-ignore -v env/firebase.staging.json
git status --short env/
```

`git status` must not list `env/firebase.dev.json`, `env/firebase.staging.json`
or `env/firebase.prod.json`.

### Run and build

Dev, mock data, no Firebase:

```bash
flutter run --flavor dev \
  --dart-define=TAYTAY_ENV=dev \
  --dart-define=TAYTAY_DATA=mock
```

Dev against a local API, signing in to the staging Firebase project:

```bash
flutter run --flavor dev \
  --dart-define=TAYTAY_ENV=dev \
  --dart-define=TAYTAY_API_BASE_URL=http://10.0.2.2:3000/api/v1 \
  --dart-define-from-file=env/firebase.dev.json
```

Staging:

```bash
flutter run --flavor staging \
  --dart-define=TAYTAY_ENV=staging \
  --dart-define=TAYTAY_API_BASE_URL=https://taytay-api.139-162-51-165.sslip.io/api/v1 \
  --dart-define-from-file=env/firebase.staging.json
```

```bash
flutter build apk --release --flavor staging \
  --dart-define=TAYTAY_ENV=staging \
  --dart-define=TAYTAY_API_BASE_URL=https://taytay-api.139-162-51-165.sslip.io/api/v1 \
  --dart-define-from-file=env/firebase.staging.json
```

`https://taytay-api.139-162-51-165.sslip.io/api/v1` is the staging Node API (the shared Linode).
`env/firebase.staging.json` is gitignored and holds the four Firebase client
values for the staging project; it is never printed or committed. Staging sends
no real email (`EMAIL_SENDER=mock`): the registration wizard says a code was
sent when the API accepts the send, but nothing arrives. A staging build refuses
`http`. The release APK also needs `android/key.properties` (below).

### Staging project

`taytay-lgu-ids-staging` has email/password sign-in on, email enumeration
protection on, and TOTP off. Its Android API key is restricted in Google Cloud
to the Identity Toolkit and Token Service APIs. It has Android apps for
`ph.gov.taytay.app.dev` and `ph.gov.taytay.app.staging` and **no iOS app**.

### Production and iOS

There is no production Firebase project. A prod build has no
`env/firebase.prod.json` to pass, so it stops on the configuration screen.
That is intended. The prod commands below already pass the file.

iOS cannot sign in until an iOS app is registered in the Firebase project.
iOS has no flavor, so its bundle ID is `ph.gov.taytay.app`. The Android app IDs
in `env/` are refused on an iPhone. Register the iOS app, then put its own app
ID, and the API key Firebase lists for it, in a separate gitignored file such
as `env/firebase.staging.ios.json`.

## Android keystore

`android/app/build.gradle.kts` reads `android/key.properties`
(`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). The file, `*.jks`,
and `*.keystore` are gitignored. Commit only `android/key.properties.example`.

`storeFile` must be an absolute path **outside** this repository. Paul creates
the keystore and keeps it. Do not generate one in this tree and do not commit
passwords.

A missing `key.properties` does not break debug builds. **Release packaging
fails** in `verifyReleaseSigning` with a message that names the example file.
It does not sign with the debug key. A half-filled file fails configuration
and names the missing keys.

```bash
cp android/key.properties.example android/key.properties
```

Set `storeFile`, and replace each `REPLACE_ME`. Then:

```bash
git check-ignore -v android/key.properties
git status --short android/key.properties
```

`git status` must not list `android/key.properties` or a `.jks` / `.keystore`.

## Android App Bundle and APK

`--flavor prod` is required. There is no default flavor.

```bash
flutter build appbundle --release \
  --flavor prod \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.json
```

The bundle is `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

```bash
flutter build apk --release \
  --flavor prod \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.json
```

The APK is `build/app/outputs/flutter-apk/app-prod-release.apk`.

Replace `https://api.example.invalid/api/v1` with the public Linode base URL.
`example.invalid` does not resolve.

## iOS IPA

Needs macOS and Xcode. `ios/Flutter/Release.xcconfig` sets:

```
DEVELOPMENT_TEAM = YOUR_APPLE_TEAM_ID
```

That is a placeholder. The Apple Team ID is pending from Paul. No real team
id is in the project. On the signing machine, copy the example and uncomment
`DEVELOPMENT_TEAM` there. The copy is included after the placeholder, so it
replaces `YOUR_APPLE_TEAM_ID`. Do not commit the copy.

```bash
cp ios/Flutter/Release-Signing.xcconfig.example ios/Flutter/Release-Signing.xcconfig
cp ios/ExportOptions.plist.example ios/ExportOptions.plist
```

Replace `YOUR_APPLE_TEAM_ID` in the gitignored `ios/ExportOptions.plist` as
well.

```bash
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.ios.json
```

The IPA is under `build/ios/ipa/`. iOS has no flavor dimension. The
environment comes only from `TAYTAY_ENV`.
`env/firebase.prod.ios.json` cannot exist until a production project with
an iOS app does (see Firebase above).

## Still pending from Paul

* **Linode production API.** The public base URL for
  `--dart-define=TAYTAY_API_BASE_URL`. Nothing in the repo is that host.
* **Firebase production project.** None exists. `taytay-lgu-ids-staging` is
  the only project. A prod build stops until `env/firebase.prod.json` holds the
  production Android app's values. No Firebase options are committed, and
  `google-services.json` / `GoogleService-Info.plist` are not used (D-185).
  Both stay gitignored so one cannot be committed by accident.
* **iOS Firebase app.** No iOS app is registered in any project, so iOS cannot
  sign in yet.
* **Apple Team ID.** Replace `YOUR_APPLE_TEAM_ID` on the signing machine.
* **Android upload keystore.** Create it outside the repo, point
  `android/key.properties` at it, and keep the file and the passwords. Losing
  the keystore means the Play listing cannot be updated.
