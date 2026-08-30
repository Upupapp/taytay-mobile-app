#!/usr/bin/env bash
#
# Verifies the ARTIFACT, not the source.
#
# TAB 17's trap, and it is a real one: a build file can say one thing while the
# thing it produces says another. A debug-only manifest that was accidentally
# placed in `src/main`, a plugin that merges a permission nobody declared, a
# network-security config that survived into release — none of those are visible
# in the source you would think to read.
#
#   ./tool/check_release_hardening.sh [path/to/app.apk]
#
# Defaults to the release APK. Requires the Android SDK's aapt2 or apkanalyzer.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="${1:-$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk}"

if [ ! -f "$APK" ]; then
  echo "SKIP: no artifact at $APK." >&2
  echo "      Release hardening is NOT PROVEN. Build one first:" >&2
  echo "      flutter build apk --release --dart-define=TAYTAY_ENV=prod" >&2
  exit 3
fi

AAPT="$(find "${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools" \
  -name aapt2 -type f 2>/dev/null | sort -V | tail -1)"
if [ -z "$AAPT" ]; then
  echo "FAIL: aapt2 not found; cannot read the artifact." >&2
  exit 2
fi

echo "Reading $(basename "$APK")"

# IS THIS ARTIFACT EVEN CURRENT?
#
# The reason this gate went ignored for eleven days is not only that it was
# wrong — it is that it was reporting on a build output from 18 August as
# though it described the code. Three of the release APKs sitting in this tree
# are signed with the debug key, which reads as F03 unfixed; they were built at
# 15:47 and the fix landed at 16:12 the same day. They are stale, not evidence.
#
# A gate that reads a stale artifact and says nothing about its age invites
# exactly that misreading, so it says something now.
CONFIG="$REPO_ROOT/android/app/build.gradle.kts"
if [ -f "$CONFIG" ] && [ "$CONFIG" -nt "$APK" ]; then
  echo "STALE: this artifact is older than android/app/build.gradle.kts." >&2
  echo "       It was built before the current signing configuration existed," >&2
  echo "       so anything below describes an old build, not this code." >&2
  echo "       Rebuild before believing the result:" >&2
  echo "         flutter build apk --release --dart-define=TAYTAY_ENV=prod" >&2
  stale=1
fi
DUMP="$("$AAPT" dump badging "$APK" 2>/dev/null || true)"
MANIFEST="$("$AAPT" dump xmltree --file AndroidManifest.xml "$APK" 2>/dev/null || true)"

fail=0

# 1. Cleartext must be impossible.
if echo "$MANIFEST" | grep -q 'usesCleartextTraffic.*0xffffffff'; then
  echo "FAIL: the release artifact permits cleartext traffic." >&2
  fail=1
fi
if echo "$MANIFEST" | grep -q 'networkSecurityConfig'; then
  echo "FAIL: a network security config survived into the release artifact." >&2
  echo "      The debug-only cleartext allowance must not ship." >&2
  fail=1
fi

# 2. Exactly the permissions this app declares, and no plugin's extras.
# Declared by this app, plus the ones a dependency merges in. A merged permission
# is not automatically acceptable — it is a decision, and this list is where the
# decision is recorded rather than discovered by a store reviewer.
#
#   USE_FINGERPRINT   local_auth, for API < 28 where USE_BIOMETRIC does not
#                     exist. Same capability, older name; nothing extra is
#                     reachable. Accepted.
#   DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
#                     androidx.core, a signature-level permission the app grants
#                     only to itself so its own runtime receivers are not
#                     exported. Grants nothing to anybody else. Accepted.
EXPECTED="android.permission.INTERNET android.permission.USE_BIOMETRIC \
android.permission.USE_FINGERPRINT \
ph.gov.taytay.lguids.taytay_resident.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
ACTUAL="$(echo "$DUMP" | sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" | sort | tr '\n' ' ')"
for p in $ACTUAL; do
  case " $EXPECTED " in
    *" $p "*) ;;
    *)
      echo "FAIL: the artifact declares an undeclared permission: $p" >&2
      echo "      A plugin merged it in. Decide whether it belongs before shipping." >&2
      fail=1
      ;;
  esac
done

# 3. Not signed with the debug key (F03). The launch blocker.
#
# Read with apksigner, not by unzipping META-INF. A v2/v3-signed APK carries its
# signature in a block after the central directory and leaves NOTHING in
# META-INF — so the obvious check finds no certificate, reports nothing, and
# passes. That is worse than not checking: it is a green tick on the single
# finding that makes the artifact unpublishable.
APKSIGNER="$(find "${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools" \
  -name apksigner -type f 2>/dev/null | sort -V | tail -1)"
if [ -z "$APKSIGNER" ]; then
  echo "FAIL: apksigner not found; the signing certificate cannot be read." >&2
  echo "      Not proven is not the same as fine — this gate must not be skipped." >&2
  exit 2
fi

# apksigner is a shell wrapper around a JAR and needs a JRE. This Mac has no
# Java on PATH and no /Library/Java, so `apksigner` printed "Unable to locate a
# Java Runtime", the `2>/dev/null` below swallowed it, CERT came back empty, and
# this gate reported "the artifact has no readable signature" for eleven days.
#
# THAT IS THE BUG THIS BLOCK FIXES, and it is the same bug the file warns about
# thirty lines up: cannot-read was being reported as a finding about the
# artifact. Android Studio ships a JBR, so there is a runtime here; it just is
# not on PATH.
#
# `command -v java` is NOT the test. macOS ships a /usr/bin/java STUB that
# exists, is executable, and does nothing but print "Unable to locate a Java
# Runtime" — so the obvious existence check passes on a machine with no Java,
# which is how the first version of this fix failed to fix anything. Run it.
java_works() { java -version >/dev/null 2>&1; }

if ! java_works; then
  JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  if [ -x "$JBR/bin/java" ]; then
    export JAVA_HOME="$JBR"
    PATH="$JBR/bin:$PATH"
    export PATH
  fi
fi
# NOT RED-PROVEN on this machine: Android Studio is installed, so the fallback
# above always succeeds and this branch cannot be reached here. It is reasoned,
# not demonstrated, and that distinction is worth the two lines it costs.
if ! java_works; then
  echo "FAIL: no working Java runtime; apksigner cannot read the certificate." >&2
  echo "      This is NOT a statement about the artifact. Install a JDK or set" >&2
  echo "      JAVA_HOME, then run this again before believing anything." >&2
  exit 2
fi

CERT_ERR="$(mktemp)"
CERT="$("$APKSIGNER" verify --print-certs "$APK" 2>"$CERT_ERR" || true)"
CERT="$(echo "$CERT" | grep -v '^WARNING:' || true)"
if [ -z "$CERT" ]; then
  # Distinguish "unsigned" from "could not look". Conflating them is what put
  # this gate in the ignored pile.
  echo "FAIL: could not read a certificate from the artifact." >&2
  echo "      apksigner said:" >&2
  sed 's/^/        /' "$CERT_ERR" >&2
  rm -f "$CERT_ERR"
  fail=1
else
  rm -f "$CERT_ERR"
  DN="$(echo "$CERT" | grep -i 'certificate DN' | head -1)"

  # A debug key is not the only unpublishable signer, and the artifact on this
  # machine proves it: it is signed `CN=THROWAWAY DO NOT USE, O=Verification
  # Only, C=PH`, which sails past a check that only looks for Android Debug.
  # Fixing the Java fault alone would therefore have turned this gate GREEN on
  # an artifact that says, in its own certificate, that it must not be used.
  if echo "$CERT" | grep -qi 'CN=Android Debug'; then
    echo "FAIL: signed with the ANDROID DEBUG KEY. This can never be published (F03)." >&2
    echo "      $DN" >&2
    fail=1
  elif echo "$CERT" | grep -qiE 'do not use|throwaway|verification only|test *key'; then
    echo "FAIL: signed with a self-declared non-production certificate." >&2
    echo "      $DN" >&2
    echo "      The certificate says what it is. Publishing it is F03 in a" >&2
    echo "      different hat." >&2
    fail=1
  fi

  # Identity, not just "not obviously bad". Without a recorded fingerprint this
  # gate can only reject the signers it has heard of, which is a much weaker
  # claim than the OK line implies.
  ACTUAL_SHA="$(echo "$CERT" | sed -n 's/.*certificate SHA-256 digest: *//p' | head -1)"
  if [ -n "${TAYTAY_RELEASE_CERT_SHA256:-}" ]; then
    if [ "$ACTUAL_SHA" != "$TAYTAY_RELEASE_CERT_SHA256" ]; then
      echo "FAIL: signed by an unexpected certificate." >&2
      echo "      expected $TAYTAY_RELEASE_CERT_SHA256" >&2
      echo "      actual   $ACTUAL_SHA" >&2
      fail=1
    fi
  else
    # CORRECTED within the hour it was written. The first version of this
    # message printed the observed fingerprint and said "set it to this once
    # that is known to be the real release certificate" — which, on the only
    # artifact anybody has here, invites pinning
    # `CN=THROWAWAY DO NOT USE` as the production key. A gate that hands you
    # the wrong value to copy is worse than one that stays quiet.
    #
    # docs/integration/release-engineering.md is explicit: the production key
    # is the LGU's to hold, and "a keystore generated here would be a
    # credential in the wrong hands from the moment it existed". So the
    # fingerprint cannot come from this machine at all, and the message says
    # that instead of offering one.
    unproven=1
    echo "NOT PROVEN: signer identity is unchecked." >&2
    echo "            TAYTAY_RELEASE_CERT_SHA256 is unset, so this run can only" >&2
    echo "            reject signers it recognises as bad. It cannot confirm the" >&2
    echo "            artifact carries the RIGHT key." >&2
    echo "            The value must come from the LGU's production keystore," >&2
    echo "            which is not on this machine and must not be generated" >&2
    echo "            here — see docs/integration/release-engineering.md." >&2
    echo "            Observed on this artifact (NOT a value to pin): $ACTUAL_SHA" >&2
  fi
fi

# 4. No secret-shaped dart-define baked in. They ship in clear text.
if unzip -p "$APK" 'assets/flutter_assets/*' 2>/dev/null | \
   grep -Eaq '(api[_-]?key|secret|private[_-]?key)["'"'"']?\s*[:=]'; then
  echo "FAIL: something secret-shaped is in the bundle. --dart-define values are" >&2
  echo "      recoverable from any downloaded APK." >&2
  fail=1
fi

if [ "${stale:-0}" -ne 0 ]; then
  # A finding about a stale artifact is not a finding about this repository.
  # Reporting it as pass or fail would be a claim the evidence cannot support.
  echo "NOT PROVEN: the artifact is stale — see the STALE note above." >&2
  exit 3
elif [ $fail -ne 0 ]; then
  exit 1
elif [ "${unproven:-0}" -ne 0 ]; then
  # Not a bare OK. Everything checked passed, and one thing was not checked;
  # saying only the first half is how a gate comes to mean less than its reader
  # thinks it does.
  echo "OK (PARTIAL): every check that could run passed, but signer identity"
  echo "              was not verified. See the NOT PROVEN note above."
else
  echo "OK: release hardening holds on the artifact."
fi
