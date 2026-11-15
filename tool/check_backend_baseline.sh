#!/usr/bin/env bash
#
# Is the vendored Node contract the backend's own, byte for byte?
#
# check_backend_routes.sh checks every route this app declares against
# docs/integration/taytay-node-openapi.json. That answer is worth only as much
# as the file is what the backend publishes. This script answers that, in two
# halves, from the record in lib/core/api/backend_baseline.dart (D-219):
#
#  1. The file's sha256 must equal `nodeContractSha256`. An edit to the vendored
#     copy that nobody declared — a hand fix, a merge resolution, an editor
#     re-indenting a megabyte of JSON — fails here, on every machine, with no
#     backend clone.
#  2. When the backend clone has `nodeContractCommit`, `openapi/openapi.json` at
#     that commit must be the vendored file, byte for byte. This is what makes
#     the recorded commit a fact rather than a label.
#
# Until 2026-11-15 this compared the backend's module boundary map at the PHP
# tag api-baseline-2026-08 with the table in docs/integration/backend-baseline.md.
# The backend has been Node since 2026-10-20, its Laravel tree survives only at
# the tag laravel-archive, and api-baseline-2026-08 is not in it, so the script
# could only exit 2. A guard that cannot run is worse than none: whoever reads
# certify.sh believes it checks something.
#
# No network, ever. A recorded commit may never have been pushed, and a fetch
# would make the answer depend on whatever the remote holds today.
#
# Exit codes, as certify.sh reads them:
#   0  both halves ran and agree
#   1  a half ran and disagrees
#   2  the check could not run (an unreadable record, a missing file, no sha256
#      tool, TAYTAY_BACKEND naming something that is not a checkout)
#   3  the hash agrees, but the backend half could not run (no clone, or the
#      clone lacks the commit): the copy's origin is NOT PROVEN

set -euo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONSTANTS="$REPO_ROOT/lib/core/api/backend_baseline.dart"
SPEC_REL="docs/integration/taytay-node-openapi.json"
SPEC="$REPO_ROOT/$SPEC_REL"
UPSTREAM_PATH="openapi/openapi.json"

# `dart format` wraps a long constant onto a second line, and a Windows checkout
# carries carriage returns, so both are squeezed out before matching.
dart_const() {
  tr '\r\n' '  ' < "$CONSTANTS" \
    | grep -oE "const String $1 = *'[^']*';" \
    | sed -E "s/.*'([^']*)';$/\1/" || true
}

COMMIT="$(dart_const nodeContractCommit)"
RECORDED="$(dart_const nodeContractSha256)"

if ! [[ "$COMMIT" =~ ^[0-9a-f]{7,40}$ ]] || ! [[ "$RECORDED" =~ ^[0-9a-f]{64}$ ]]; then
  echo "FAIL: could not read nodeContractCommit and nodeContractSha256 from" >&2
  echo "      lib/core/api/backend_baseline.dart (read '$COMMIT' and '$RECORDED')." >&2
  exit 2
fi

if [ ! -f "$SPEC" ]; then
  echo "FAIL: $SPEC_REL is missing." >&2
  exit 2
fi

# Read from stdin so the output is the bare hash on every platform.
if command -v sha256sum >/dev/null 2>&1; then
  sha256_of() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256_of() { shasum -a 256 | cut -d' ' -f1; }
else
  echo "FAIL: neither sha256sum nor shasum is installed, so nothing can be compared." >&2
  exit 2
fi

echo "Record: backend $COMMIT $UPSTREAM_PATH, sha256 $RECORDED"

# ── Half 1: the file is the one recorded ──────────────────────────────────────
ACTUAL="$(sha256_of < "$SPEC")"
if [ "$ACTUAL" != "$RECORDED" ]; then
  echo >&2
  echo "FAIL: $SPEC_REL has changed and the record has not." >&2
  echo "      recorded sha256  $RECORDED" >&2
  echo "      file sha256      $ACTUAL" >&2
  if [ "$(tr -d '\r' < "$SPEC" | sha256_of)" = "$RECORDED" ]; then
    echo >&2
    echo "      Only the line endings differ: a checkout converted the file to CRLF." >&2
    echo "      .gitattributes marks it -text; restore it with" >&2
    echo "      git checkout -- $SPEC_REL" >&2
  else
    echo >&2
    echo "      The vendored contract is a copy, never an edit. Re-vendor it from the" >&2
    echo "      backend's $UPSTREAM_PATH and record the commit and sha256 in" >&2
    echo "      backend_baseline.dart and docs/integration/backend-baseline.md (D-219)." >&2
  fi
  exit 1
fi

# ── Half 2: the record is the backend's ───────────────────────────────────────
#
# An explicit TAYTAY_BACKEND that is not a checkout is a misconfiguration and is
# said so; a missing conventional sibling is an honest skip.
if [ -n "${TAYTAY_BACKEND:-}" ]; then
  BACKEND="$TAYTAY_BACKEND"
  if ! git -C "$BACKEND" rev-parse --git-dir >/dev/null 2>&1; then
    echo "FAIL: TAYTAY_BACKEND=$BACKEND is not a git checkout." >&2
    echo "      Point it at a clone of taytay-backend, or unset it." >&2
    exit 2
  fi
else
  BACKEND="$(cd "$REPO_ROOT/.." && pwd)/taytay-backend"
  if ! git -C "$BACKEND" rev-parse --git-dir >/dev/null 2>&1; then
    echo "SKIP: the sha256 matches the record, but there is no backend clone at"
    echo "      $BACKEND (set TAYTAY_BACKEND), so whether the file is backend"
    echo "      $COMMIT's $UPSTREAM_PATH is NOT PROVEN."
    exit 3
  fi
fi

if ! FULL="$(git -C "$BACKEND" rev-parse --verify --quiet "$COMMIT^{commit}")"; then
  echo "SKIP: the sha256 matches the record, but $BACKEND does not have commit"
  echo "      $COMMIT, so the file's origin is NOT PROVEN. Fetch it there yourself;"
  echo "      this script never touches the network."
  exit 3
fi

if ! git -C "$BACKEND" cat-file -e "$FULL:$UPSTREAM_PATH" 2>/dev/null; then
  echo "FAIL: backend $COMMIT has no $UPSTREAM_PATH, so it cannot be where the" >&2
  echo "      vendored contract came from. The recorded commit is wrong." >&2
  exit 1
fi

UPSTREAM="$(git -C "$BACKEND" show "$FULL:$UPSTREAM_PATH" | sha256_of)"
if [ "$UPSTREAM" != "$ACTUAL" ]; then
  echo >&2
  echo "FAIL: $SPEC_REL is not backend $COMMIT's $UPSTREAM_PATH." >&2
  echo "      backend sha256   $UPSTREAM" >&2
  echo "      vendored sha256  $ACTUAL" >&2
  echo "      First differences (< backend  > vendored):" >&2
  diff <(git -C "$BACKEND" show "$FULL:$UPSTREAM_PATH") "$SPEC" | head -12 | cut -c1-160 >&2 || true
  echo >&2
  echo "      The file and its record were changed together, but not from that" >&2
  echo "      commit. Re-vendor from the commit you record, byte for byte (D-219)." >&2
  exit 1
fi

echo "OK: the vendored Node contract is backend $COMMIT's $UPSTREAM_PATH, byte for byte (sha256 ${ACTUAL:0:12}...)."
exit 0
