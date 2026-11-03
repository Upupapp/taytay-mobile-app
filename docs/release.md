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

The only baked-in host is `http://10.0.2.2:8000/api/v1`, and only a dev debug
build that omits the define may use it. `https://unconfigured.invalid` is the
placeholder the startup screen refuses before anything connects.

`--dart-define=TAYTAY_DATA=mock` is impossible in a release build.
`usesMockData` is false when `kReleaseMode` is true, and `MockFixtures` will
not read `test/fixtures/mock/`. A release build also refuses to start if the
flag is set, including when `TAYTAY_ENV=dev`.

The value is a public URL, including `/api/v1`, and `https` outside dev. A
`--dart-define` is recoverable from the binary. Do not put a secret in one.

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
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1
```

The bundle is `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

```bash
flutter build apk --release \
  --flavor prod \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1
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
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1
```

The IPA is under `build/ios/ipa/`. iOS has no flavor dimension. The
environment comes only from `TAYTAY_ENV`.

## Still pending from Paul

* **Linode production API.** The public base URL for
  `--dart-define=TAYTAY_API_BASE_URL`. Nothing in the repo is that host.
* **Firebase production config.** `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist` are gitignored and are not in this
  repository. No Firebase project options are committed.
* **Apple Team ID.** Replace `YOUR_APPLE_TEAM_ID` on the signing machine.
* **Android upload keystore.** Create it outside the repo, point
  `android/key.properties` at it, and keep the file and the passwords. Losing
  the keystore means the Play listing cannot be updated.
