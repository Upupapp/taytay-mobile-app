# Release engineering and signing

Closes **F03** (release builds signed with the debug key) and **F11** (`minSdk`
and `targetSdk` inherited from Flutter). What it deliberately does **not** do is
create a production key — that is the LGU's to hold, and a keystore generated
here would be a credential in the wrong hands from the moment it existed.

## F03 — the debug key, and why it survived twenty-eight TABs

The Flutter template signs release builds with the debug key *"so
`flutter run --release` works"*. It does work — **that is the problem.** The build
succeeds, the artifact looks finished, and it is unpublishable in a way nothing
announces. It passed a release-readiness audit in that state.

Release builds now read `android/key.properties`, and **there is no fallback**.
With no credentials the build fails at signing rather than producing something
that cannot be shipped:

```
> SigningConfig "release" is missing required property "storeFile".
```

A failure a developer meets in a minute is cheaper than a store rejection three
weeks later. A half-filled `key.properties` fails earlier still, naming the
missing keys rather than failing deep inside the packaging task.

**The whole path was verified end to end** with a throwaway key generated,
used once, and deleted in the same step: the build signed, `apksigner` reported
`CN=THROWAWAY DO NOT USE`, and `tool/check_release_hardening.sh` went from
FAIL-on-debug-key to OK. Then the key was removed and the build returned to
failing. Nothing credential-shaped is tracked, and a test asserts that.

## What the LGU must do, and what it costs to get wrong

1. **Generate the production keystore** and hold it. Not in this repository, not
   in a chat, not in a ticket.
2. **Back it up, in two places, with the passwords stored separately.** Losing it
   means **never being able to update this app under the same Play listing
   again** — residents would have to uninstall and reinstall a different listing,
   which on a government identity app means re-establishing trust with everybody.
   Treat loss as an incident with a named owner.
3. **Decide Play App Signing before the first upload.** It changes what the
   upload key is and what happens if it is lost, and a re-signing change later
   requires both the old and the new certificate. Cheaper to decide once than to
   revisit. *Recommended: adopt it* — Google holds the signing key, and the
   failure mode it removes (a lost key ending the listing) is exactly the one
   this LGU is least equipped to survive.
4. **Configure iOS signing and provisioning** for distribution. Not done here: it
   needs an Apple Developer account owned by the LGU, which does not yet exist.

## F11 — the SDK floor

| | Value | Why |
| --- | --- | --- |
| `minSdk` | **24** (Android 7.0) | Chosen from who is *excluded* rather than from what is convenient. Each step up excludes exactly the residents a social-welfare app exists for — people on inherited handsets that no longer receive vendor updates. Raising it needs a reason about devices, not about libraries. |
| `targetSdk` | **36** | Play enforces a target-API floor that moves annually and is checked **at submission**, not at build. Re-read it against the current floor before each submission rather than letting a rejection explain it. |
| `compileSdk` | 37 (+ `compileSdkMinor = 0`) | Required by `flutter_secure_storage` 11. |

Both were inherited before, which meant the device base this app supports could
change because somebody upgraded a toolchain — not a decision anybody would have
made deliberately.

## Flavours

`dev`, `staging`, `prod`, each with its own application id and label, so a
staging build can never be mistaken for production **and both can be installed
side by side**. A single application id means acceptance testing against staging
requires uninstalling the real app, which is exactly when somebody tests the
wrong one and files a bug against the wrong environment.

The suffix is on the application id rather than only on the label, because a
label is what somebody reads and an id is what the OS enforces.

**The flavours do not set `TAYTAY_ENV`.** It stays a `--dart-define`, because a
flavour whose Gradle config disagreed with the dart-define would be a build that
says "staging" on the icon and talks to production — worse than having no
flavours at all. Asserted by test.

## Still not done

* **No CI-produced artifact from a clean clone, and no published checksums.** CI
  builds a release APK for the hardening check but does not publish one, because
  there is nothing to sign it with.
* **No `versionCode` automation.** It needs a CI build number source, which
  arrives with the release pipeline.
* **Minification and resource shrinking are off**, deliberately. Shrinking changes
  what ships and this app has no measured size problem to solve with it — 19.5 MB
  of a 20.9 MB artifact is the Flutter engine (TAB 20). Turning it on before
  there is a reason risks a reflection-related crash that appears only in release.
