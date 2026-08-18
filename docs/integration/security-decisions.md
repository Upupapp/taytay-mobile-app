# Security decisions

The deferrals TAB 17 exists to close, each decided rather than left open, and
each with the condition that would make it worth revisiting.

## Certificate pinning (F10) — **declined**

`api_transport.dart` recorded pinning as a decision deferred to the HTTP package
choice. The decision is: **do not pin**, and rely on platform TLS validation plus
the `https` enforcement `AppConfig` already applies outside dev.

**Why.** Pinning defends against a certificate authority being compromised or
coerced into issuing for `*.taytay.gov.ph`. That is a real threat and a rare one.
Against it stands a failure mode that is neither: **a pinned app whose
certificate rotates unexpectedly is a total outage that no server-side change can
reach.** Every resident is locked out until they install a new build from a store,
and the people slowest to update are the ones who most need the service. The LGU
would be trading a rare attack for a self-inflicted outage it cannot fix.

It is only worth taking that trade with a rotation runbook nobody has yet written
and a backup pin nobody has yet generated — and a pin whose rotation has never
been rehearsed is a scheduled outage with a date nobody has looked up.

**Revisit when** the platform has a named operator who owns certificate rotation
and has rehearsed it, or when the credential becomes offline-verifiable and the
QR is worth attacking a CA for.

**What is relied on instead:** platform TLS validation, `https` refused-at-startup
for staging and production, and no cleartext in the release artifact — asserted
against the artifact in `tool/check_release_hardening.sh`, not against source.

## Root and jailbreak detection — **neither detect nor block**

**Why not block.** A government identity app that refuses to run on an unusual
device excludes legitimate residents — people on inherited handsets, on
custom ROMs because the vendor stopped shipping updates, on devices a relative
set up for them. Those are disproportionately the residents a social-welfare app
exists for, and the app has nothing to protect that a rooted device could reach:
the session token is in the Keystore, the QR is short-lived and server-checked,
and there is no offline credential.

**Why not even warn.** A warning a resident cannot act on is a warning that
teaches them to dismiss warnings. "Your device may be insecure" on a phone
somebody cannot replace is noise with a frightening tone.

**Revisit when** the credential becomes offline-verifiable — at that point the
device holds something worth stealing and the calculation changes.

## Screen brightness on the ID screen — **deferred from TAB 06, still deferred**

Raising brightness while a QR is displayed needs a platform-channel dependency.
Article 1 requires a stated reason, a maintenance review and a data-egress review
per package, and the honest position is that the *benefit* is unmeasured: nobody
has yet tried to scan this app's QR under a barangay hall's lighting, because no
verifier client exists (F12).

Adding a dependency to solve a problem nobody has observed is how an app
accumulates unreviewed surface. **Revisit during TAB 23's device matrix**, where a
real scan under real lighting either demonstrates the problem or does not.

## Dependency surface

Twelve direct dependencies. Every one either ships with the Flutter SDK or is
Dart-team maintained; none is a third-party analytics, crash or messaging SDK,
which is the category that would make the municipality a data controller for
somebody else's processing.

| Package | Reason it is here | Permissions | Data egress |
| --- | --- | --- | --- |
| `flutter`, `flutter_localizations` | SDK | — | none |
| `cupertino_icons` | iOS-style glyphs | — | none |
| `intl` | plural and date machinery `gen-l10n` generates against | — | none |
| `go_router` | declarative routing with a single guard | — | none |
| `http` | transport. Minimal surface, no interceptor framework of its own — retry, auth and correlation are this app's policy in `core/api/`, where they are unit-testable | INTERNET | only to the configured API base |
| `http_parser` | media-type parsing for the one multipart request (document upload). Already present as `http`'s transitive dependency; declared so a build does not break on an unrelated upgrade | — | none |
| `local_auth` | app-lock. Biometrics gate **local access to a stored session** and are never a server-side factor | USE_BIOMETRIC, USE_FINGERPRINT | none — no biometric material leaves the device or reaches this app |
| `image_picker` | capturing a requirement document | camera / photos, at point of use | none |
| `file_selector` | choosing a PDF | — | none |
| `share_plus` | sharing a public post. **The destination is never recorded** (ADR 0029 §3) | — | none |
| `url_launcher` | opening a map or a published municipal link | — | only what the resident taps, and only `https` |

**`url_launcher` is the injection surface**, because newsfeed posts and referrals
carry server-controlled links. One call site, and it refuses anything that is not
an absolute `https` URL with a host before launching — it does not repair or
normalise, because repairing an untrusted URL is guessing at what somebody meant.
Opened externally rather than in a webview, so this app never sits between a
resident and a municipal service.

## Permissions in the artifact, not the manifest

The original build's TAB 28 audit reported "exactly two Android permissions". It
read the manifest. **The release artifact declares four** — `USE_FINGERPRINT`
merged by `local_auth` for API < 28, and a signature-level
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` that `androidx.core` grants the app to
itself. Both are accepted, and both are now recorded in
`tool/check_release_hardening.sh` so a *third* one arriving fails the build rather
than being discovered by a store reviewer.

This is the general lesson of the TAB: a build file can say one thing while the
thing it produces says another, and the audits that matter read the artifact.

## Cleartext

Impossible in release, and a debug-only network security config permits it to
`10.0.2.2` and `localhost` so the documented dev workflow works at all — Android
has blocked cleartext by default since targetSdk 28, and the README's
`http://10.0.2.2:8000` could not have connected. Scoped to two hosts rather than
permitted outright, because a blanket debug allowance is still a debug build
somebody eventually points at a staging host over http.

Verified on the artifact: the config does not appear in the release APK.

## Still open, and owned elsewhere

* **F03 — the release artifact is signed with the Android debug key.** The
  hardening check fires on it today, by design, and goes green when TAB 21
  establishes key custody. It is the single finding that makes the artifact
  unpublishable.
* **A dependency vulnerability gate** runs in CI (`flutter pub outdated` plus
  advisory review). It cannot fail a build on severity yet, because Dart has no
  first-party advisory database to gate against.
