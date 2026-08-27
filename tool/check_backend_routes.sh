#!/usr/bin/env bash
#
# Does every route this app calls exist in the backend at the pinned baseline?
#
# The module guard (check_backend_baseline.sh) answers "does this module exist".
# This one answers the question a client actually depends on. TAB 00 of the
# front-end sequence found the difference the expensive way: `GET barangays` and
# `POST newsfeed-comments/{comment}/reports` were being called against a baseline
# that has neither, and the module guard passed — both routes were added inside
# modules already `implemented` at the tag, so no module's status changed.
#
# The declaration lives in lib/core/api/backend_routes.dart, next to the code
# that calls it. test/integration/backend_routes_test.dart keeps that declaration
# honest against the source; this script keeps it honest against the contract.
#
# ── The exception list is a ratchet ───────────────────────────────────────────
#
# `routesAheadOfBaseline` names the routes known to be missing at the baseline.
# This script fails when a route is missing and unnamed — so a third cannot
# arrive quietly — and fails equally when a named route turns out to exist, so
# the list cannot outlive the problem. A guard that is permanently red is a guard
# people learn to skip, and a permanent allowlist is one nobody reads again.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/lib/core/api/backend_routes.dart"

TAG="$(sed -n "s/^const String backendBaselineTag = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"
COMMIT="$(sed -n "s/^const String backendBaselineCommit = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"

# ── Finding the backend ───────────────────────────────────────────────────────
#
# A local clone, always. There is deliberately no network fallback here: the
# baseline is a LOCAL annotated tag and this programme's boundary forbids
# pushing, so raw.githubusercontent.com has never heard of it and never will.
# The sibling guard learned that by 404-ing (finding C-10).
BACKEND="${TAYTAY_BACKEND:-$(cd "$REPO_ROOT/.." && pwd)/taytay-backend}"

if [ ! -d "$BACKEND/.git" ]; then
  echo "FAIL: no backend clone at $BACKEND" >&2
  echo "      Set TAYTAY_BACKEND=/path/to/taytay-backend." >&2
  echo "      There is no network fallback: $TAG is a local tag that has never" >&2
  echo "      been pushed, so no host can serve it." >&2
  exit 2
fi

if ! git -C "$BACKEND" rev-parse "$TAG^{commit}" >/dev/null 2>&1; then
  echo "FAIL: tag $TAG does not exist in $BACKEND." >&2
  exit 2
fi

AT="$(git -C "$BACKEND" rev-parse --short "$TAG^{commit}")"
if [ "$AT" != "$COMMIT" ]; then
  echo "FAIL: $TAG points at $AT; this app is pinned to $COMMIT." >&2
  echo "      A moved tag is a moved baseline. Re-run TAB 00." >&2
  exit 1
fi

echo "Baseline: $TAG ($COMMIT) from $BACKEND"

# ── What the backend serves at the baseline ───────────────────────────────────
#
# Named parameters are flattened to `{}`. Which segment is dynamic is contract;
# what the backend calls it is not, and matching on the name would go red every
# time somebody renamed a variable.
backend_routes() {
  local file
  for file in $(git -C "$BACKEND" ls-tree -r --name-only "$TAG" | grep 'Routes/api_v1\.php$'); do
    git -C "$BACKEND" show "$TAG:$file"
  done | grep -oE "Route::(get|post|put|patch|delete)\( *'[^']+'" \
       | sed -E "s/Route::([a-z]+)\( *'([^']+)'/\1 \2/" \
       | sed -E 's/\{[^}]*\}/{}/g' \
       | awk '{ print toupper($1), $2 }' \
       | sort -u
}

# NEWLINES ARE SQUEEZED OUT FIRST, AND THAT IS NOT A TIDINESS CHOICE.
#
# `dart format` wraps a constructor whose arguments do not fit, so half the rows
# in the manifest look like
#
#     BackendRoute(
#       'POST',
#       'newsfeed-comments/{}/reports',
#       'newsfeed_api_repository.dart',
#     ),
#
# A line-oriented match silently sees 37 of 53 and reports the missing sixteen as
# undeclared — which is exactly the drift this script exists to catch, produced
# by the script itself. It happened, on the first commit somebody else made after
# this guard was written.
declared_routes() {
  tr '\n' ' ' < "$MANIFEST" \
    | grep -oE "BackendRoute\( *'[A-Z]+', *'[^']+'" \
    | sed -E "s/BackendRoute\( *'([A-Z]+)', *'([^']+)'/\1 \2/" \
    | sort -u
}

exceptions() {
  awk '/^const List<String> routesAheadOfBaseline/,/^\];/' "$MANIFEST" \
    | grep -oE "'[A-Z]+ [^']+'" | tr -d "'" | sort -u
}

# A declaration this parser cannot see is a route this guard cannot check, so the
# count is asserted against the raw number of constructors. Without this the fix
# above is one reformat away from silently regressing.
assert_parser_sees_everything() {
  local declared raw
  declared="$(declared_routes | grep -c .)"
  raw="$(grep -c 'BackendRoute(' "$MANIFEST")"
  # One extra: the constructor's own declaration in the class body.
  if [ "$declared" -lt "$((raw - 1))" ]; then
    echo "FAIL: the manifest parser sees $declared of $((raw - 1)) declared routes." >&2
    echo "      Formatting has outrun the parser again. Fix the parser; do not" >&2
    echo "      lower this expectation." >&2
    exit 2
  fi
}

assert_parser_sees_everything

SERVED="$(backend_routes)"
DECLARED="$(declared_routes)"
EXCEPTED="$(exceptions)"

if [ -z "$SERVED" ] || [ -z "$DECLARED" ]; then
  echo "FAIL: a list parsed to nothing — served: $(printf '%s' "$SERVED" | grep -c . || true), declared: $(printf '%s' "$DECLARED" | grep -c . || true)" >&2
  echo "      A guard that parses nothing passes everything. Fix the parser." >&2
  exit 2
fi

MISSING="$(comm -23 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$SERVED"))"
UNEXPLAINED="$(comm -23 <(printf '%s\n' "$MISSING") <(printf '%s\n' "$EXCEPTED"))"
STALE="$(comm -13 <(printf '%s\n' "$MISSING") <(printf '%s\n' "$EXCEPTED"))"

STATUS=0

if [ -n "$UNEXPLAINED" ]; then
  echo >&2
  echo "FAIL: this app calls routes the baseline does not serve, and does not admit it:" >&2
  printf '  %s\n' $(printf '%s\n' "$UNEXPLAINED" | tr ' ' '~') | tr '~' ' ' >&2
  echo >&2
  echo "      Either the baseline is stale — re-run TAB 00 and move it — or the call" >&2
  echo "      is wrong. Adding it to routesAheadOfBaseline is only correct when the" >&2
  echo "      route genuinely exists on the backend today and the pin has not caught" >&2
  echo "      up; see C-09 in docs/frontend/open-work.md." >&2
  STATUS=1
fi

if [ -n "$STALE" ]; then
  echo >&2
  echo "FAIL: routesAheadOfBaseline names routes the baseline DOES serve:" >&2
  printf '  %s\n' $(printf '%s\n' "$STALE" | tr ' ' '~') | tr '~' ' ' >&2
  echo >&2
  echo "      The baseline moved and the list did not. Remove these entries — an" >&2
  echo "      exception that outlives its reason is one nobody reads again." >&2
  STATUS=1
fi

if [ "$STATUS" -eq 0 ]; then
  TOTAL="$(printf '%s\n' "$DECLARED" | grep -c .)"
  AHEAD="$(printf '%s\n' "$EXCEPTED" | grep -c . || true)"
  echo "OK: $TOTAL declared routes; $((TOTAL - AHEAD)) served at $TAG, $AHEAD recorded ahead of it (C-09)."
fi

exit "$STATUS"
