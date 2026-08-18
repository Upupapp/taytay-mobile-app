#!/usr/bin/env bash
#
# TAB 00 staleness guard, network half.
#
# Reads the backend's own domain-boundary-map.md at the pinned baseline tag,
# extracts its module status table, and compares it with the table committed in
# docs/integration/backend-baseline.md. Fails on any difference.
#
# The other half, test/integration/backend_baseline_test.dart, runs in
# `flutter test` and catches this repository drifting from its own document.
# This one catches the backend moving underneath it. When it goes red, a human
# re-runs TAB 00 — it is not a check to silence.
#
# Source of the backend copy, in order:
#   TAYTAY_BACKEND=/path/to/clone   a local clone; read with `git show <tag>:<path>`
#   otherwise                       raw.githubusercontent.com at the tag
#
# A local clone is preferred in CI: it proves the tag exists on a real object
# graph rather than trusting a URL that a moved tag would silently re-point.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE_DOC="$REPO_ROOT/docs/integration/backend-baseline.md"
MAP_PATH="docs/architecture/domain-boundary-map.md"

TAG="$(sed -n "s/^const String backendBaselineTag = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"
COMMIT="$(sed -n "s/^const String backendBaselineCommit = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"

if [ -z "$TAG" ]; then
  echo "FAIL: could not read backendBaselineTag from lib/core/api/backend_baseline.dart" >&2
  exit 2
fi

echo "Baseline: $TAG ($COMMIT)"

fetch_map() {
  if [ -n "${TAYTAY_BACKEND:-}" ]; then
    git -C "$TAYTAY_BACKEND" rev-parse "$TAG^{commit}" >/dev/null 2>&1 || {
      echo "FAIL: tag $TAG not found in $TAYTAY_BACKEND." >&2
      echo "      The baseline must be an existing annotated tag, never a branch." >&2
      exit 2
    }
    local at
    at="$(git -C "$TAYTAY_BACKEND" rev-parse --short "$TAG^{commit}")"
    if [ "$at" != "$COMMIT" ]; then
      echo "FAIL: $TAG points at $at; this repository is pinned to $COMMIT." >&2
      echo "      A moved tag is a moved baseline. Re-run TAB 00." >&2
      exit 1
    fi
    git -C "$TAYTAY_BACKEND" show "$TAG:$MAP_PATH"
  else
    curl -fsSL "https://raw.githubusercontent.com/Upupapp/taytay-backend/$TAG/$MAP_PATH" || {
      echo "FAIL: could not fetch $MAP_PATH at $TAG." >&2
      exit 2
    }
  fi
}

# Module name -> built status, from the backend's own table. Its rows look like
#   | `Identity` | owns … | does not own … | **implemented** (TAB 05) |
# so the module is the first cell and the status is the last. Parenthesised TAB
# references are dropped: which backend TAB built a module is not this app's
# business and changes without the status changing.
extract_backend() {
  awk -F'|' '
    /^\| *`[A-Za-z]+` *\|/ {
      name = $2; status = $NF == "" ? $(NF-1) : $NF
      gsub(/[` *]/, "", name)
      gsub(/\(.*\)/, "", status); gsub(/[*`]/, "", status)
      gsub(/^ +| +$/, "", status)
      # Two axes out of one cell. The backend writes the flag inline —
      # "implemented, feature-flagged off" — and a guard that compared the
      # sentence whole would go red on wording and blind on meaning. Built and
      # enabled are separate questions and TAB 06 depends on both.
      enabled = "yes"
      if (status ~ /feature-flagged off/) { enabled = "no" }
      sub(/,.*$/, "", status); gsub(/^ +| +$/, "", status)
      if (status == "planned") { enabled = "-" }
      if (name != "" && status != "") print name "=" status "/" enabled
    }
  ' | sort
}

# The same mapping out of our committed two-axis table, which is
#   | Module | Built | Enabled | Publishes api/v1 routes |
extract_committed() {
  awk -F'|' '
    /^\| *\**`[A-Za-z]+`\** *\| *\**(implemented|planned)/ {
      name = $2; status = $3; enabled = $4
      gsub(/[` *]/, "", name)
      gsub(/\(.*\)/, "", status); gsub(/[*`]/, "", status)
      gsub(/^ +| +$/, "", status)
      gsub(/[*`]/, "", enabled); gsub(/^ +| +$/, "", enabled)
      if (enabled ~ /^yes/) { enabled = "yes" }
      else if (enabled ~ /^no/) { enabled = "no" }
      else { enabled = "-" }
      if (name != "" && status != "") print name "=" status "/" enabled
    }
  ' "$BASELINE_DOC" | sort
}

BACKEND="$(fetch_map | extract_backend)"
COMMITTED="$(extract_committed)"

if [ -z "$BACKEND" ] || [ -z "$COMMITTED" ]; then
  echo "FAIL: a table parsed to nothing — backend rows: $(printf '%s' "$BACKEND" | grep -c . || true), committed rows: $(printf '%s' "$COMMITTED" | grep -c . || true)" >&2
  echo "      A guard that parses nothing passes everything. Fix the parser, do not skip the check." >&2
  exit 2
fi

if diff <(printf '%s\n' "$BACKEND") <(printf '%s\n' "$COMMITTED") >/tmp/baseline.diff 2>&1; then
  echo "OK: $(printf '%s\n' "$COMMITTED" | grep -c .) modules agree with the backend at $TAG."
  exit 0
fi

echo "FAIL: the backend's module status at $TAG differs from the committed baseline." >&2
echo "      < backend at $TAG   > docs/integration/backend-baseline.md" >&2
echo >&2
cat /tmp/baseline.diff >&2
echo >&2
echo "      This is TAB 00 asking to be re-run. Do not edit the committed table to" >&2
echo "      match without re-deriving what changed and what it unblocks." >&2
exit 1
