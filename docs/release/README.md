# Local release builds

The short checklist (commands, keystore, Team ID, what is still pending) is
`docs/release.md`. This file keeps the icon and splash notes.

Commands for a signing machine. This repository does not build releases in
GitHub Actions, and these steps do not add or run a workflow.

`pubspec.yaml` is `version: 1.0.0+1`. That is Android `versionName` `1.0.0` and
`versionCode` `1`, and iOS `CFBundleShortVersionString` `1.0.0` and
`CFBundleVersion` `1`. Flutter passes those through; do not hard-code them in
Gradle or the Xcode project.

The app icon and the native splash are generated. Do not hand-edit the
platform copies. Change `release/assets/` or the generator blocks in
`pubspec.yaml`, then run:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_launcher_icons` writes the Android adaptive icon (including the
monochrome layer) and the opaque iOS icon. `flutter_native_splash` writes the
native splash and the Android 12 splash. It treats a splash image as a 4×
asset. The mark is 768 px, centred on the transparent 1152 px canvas, so it
is 192 dp. The Android 12 file stays 960 px (240 dp). The dashed ring and the
mark sit inside the 160 dp circle the system masks to.

`LaunchTheme` sets the status and navigation bars to `#0B3D91` with light
icons. Re-running the splash generator resets
`android:windowDrawsSystemBarBackgrounds` to `false`; set it back to `true`
on `LaunchTheme` or the bar colour does not apply. The same run resizes the
Android 12 icon without premultiplied alpha and leaves a dark fringe on the
blue disc. The disc is filled with exact `#0B3D91` after that resize; put
the fill back if you generate again. The ~0.97 inset stays, so the dashed
ring remains inside the 160 dp mask. iOS keeps the status bar visible over
the same blue. Its icon colour stays the system default: an
`UIStatusBarStyle` in `Info.plist` would still be in force after the splash.
`flutter_launcher_icons` can write `AppIcon` into
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`. That setting
stays `YES`. `ASSETCATALOG_COMPILER_APPICON_NAME` stays `AppIcon`.

## API base URL

The base URL is injected at build time. The define is `TAYTAY_API_BASE_URL`
(Article 7). There is no default staging host and no default production host.

A release build compiled without it refuses to start and names the missing
define on the blocking configuration screen. A dev debug build may omit it and
keeps using `http://10.0.2.2:3000/api/v1` (the Android emulator's route to the
host machine, where the Node API's `npm run dev` listens). `--dart-define=TAYTAY_DATA=mock` is honoured only for a dev
debug build. A release build refuses it even when `TAYTAY_ENV=dev`. Staging
and production refuse it as well.

The value is a public URL, including `/api/v1`. Outside `dev` it must be
`https`. It must not contain a user, a password, or a query string. Never put
a secret in a `--dart-define`; the value is recoverable from the binary.

Replace `https://api.example.invalid/api/v1` in the commands below with the
real public base URL. `example.invalid` is not a host this app knows.

## Identifiers

| Platform | Value | Where |
| --- | --- | --- |
| Android `applicationId` | `ph.gov.taytay.app` | `android/app/build.gradle.kts` |
| Android namespace | `ph.gov.taytay.app` | same file; `MainActivity` uses this package |
| iOS bundle id | `ph.gov.taytay.app` | Runner target in `ios/Runner.xcodeproj` |
| Display name | `Taytay` | prod `app_name`, and `CFBundleDisplayName` / `CFBundleName` |

Android flavors append `.dev` or `.staging` to the application id. The `prod`
flavor does not. Non-production labels are `Taytay (dev)` and
`Taytay (staging)` so a staging install is not mistaken for the store app.
The flavor does **not** set `TAYTAY_ENV`. Pass the matching `--dart-define`,
or the icon can say one environment while the app calls another.

## Android keystore

`android/key.properties` and the keystore are gitignored. The keystore must be
an absolute path **outside** this repository. A path inside the repo is refused.
A missing `key.properties` does not break debug builds. Release packaging fails
with `verifyReleaseSigning` instead of signing with the debug key. A half-filled
file fails configuration and names the missing keys.

1. Generate the upload keystore outside the repo. The LGU holds it. Do not
   commit it, and do not paste the passwords into a ticket.

   ```bash
   keytool -genkeypair -v \
     -keystore /absolute/path/outside/this/repo/taytay-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias taytay-upload
   ```

2. Copy the example and point it at that file.

   ```bash
   cp android/key.properties.example android/key.properties
   ```

   Set `storeFile` to the absolute path. Replace `REPLACE_ME` for
   `storePassword`, `keyAlias`, and `keyPassword`. On Windows use a drive path
   with forward slashes (`C:/Users/you/keystores/taytay-upload.jks`). `~` is not
   expanded.

3. Confirm the secrets are untracked before any commit:

   ```bash
   git check-ignore -v android/key.properties
   git status --short android/key.properties
   ```

   `git status` must not list `android/key.properties` or a `.jks` / `.keystore`
   file.

## Android App Bundle

```bash
flutter build appbundle --release \
  --flavor prod \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.json
```

The bundle is `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

## Android APK

```bash
flutter build apk --release \
  --flavor prod \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.json
```

The APK is `build/app/outputs/flutter-apk/app-prod-release.apk`.

Staging uses the same commands with `--flavor staging`,
`--dart-define=TAYTAY_ENV=staging`, that environment's own base URL and
`--dart-define-from-file=env/firebase.staging.json`. Do not point the `prod`
flavor at a staging URL or a staging Firebase file.

There is no production Firebase project yet, so `env/firebase.prod.json` does
not exist and a prod build stops on the configuration screen until it does.
The Firebase values and files are described in `docs/release.md` (Firebase).

## iOS IPA

Needs macOS and Xcode. No real team id is committed. `YOUR_APPLE_TEAM_ID` is
a placeholder.

The Runner target's **Release** configuration (optimization, dSYM, bitcode off,
assertions off, validation, automatic signing) is in
`ios/Runner.xcodeproj/project.pbxproj` and reads `ios/Flutter/Release.xcconfig`.
That file sets `DEVELOPMENT_TEAM = YOUR_APPLE_TEAM_ID`. The Apple Team ID is
pending. The gitignored signing copy overrides the placeholder when the line
there is uncommented. The short checklist is `docs/release.md`.

```bash
cp ios/Flutter/Release-Signing.xcconfig.example ios/Flutter/Release-Signing.xcconfig
cp ios/ExportOptions.plist.example ios/ExportOptions.plist
```

On the copies only: uncomment `DEVELOPMENT_TEAM` and set it, and replace
`YOUR_APPLE_TEAM_ID` in `ios/ExportOptions.plist`. Both copies are gitignored.

```bash
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist \
  --dart-define=TAYTAY_ENV=prod \
  --dart-define=TAYTAY_API_BASE_URL=https://api.example.invalid/api/v1 \
  --dart-define-from-file=env/firebase.prod.ios.json
```

The IPA is under `build/ios/ipa/`. iOS has no Android flavor dimension; the
environment comes only from `TAYTAY_ENV`.

Confirm the filled files are untracked:

```bash
git check-ignore -v ios/ExportOptions.plist ios/Flutter/Release-Signing.xcconfig
git status --short ios/ExportOptions.plist ios/Flutter/Release-Signing.xcconfig
```

## Checks

Run these before packaging, and again if the release commit changes Dart:

```bash
flutter analyze
flutter test
```

`flutter analyze` must be clean. `flutter test` must pass. Do not pass
`--dart-define=TAYTAY_DATA=mock` on a release build, or on staging or
production.
