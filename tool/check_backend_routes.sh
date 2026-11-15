#!/usr/bin/env bash
#
# Does every route this app calls exist in the API's published contract?
#
# A module table answers "does this module exist"; a client depends on "does
# this route exist". TAB 00 of the front-end sequence found the difference the
# expensive way: `GET barangays` and `POST newsfeed-comments/{comment}/reports`
# were being called against a baseline that had neither, and the module guard
# passed, because both routes were added inside modules already built.
#
# The declaration lives in lib/core/api/backend_routes.dart, next to the code
# that calls it. test/integration/backend_routes_test.dart keeps that declaration
# honest against the source; this script keeps it honest against the contract.
#
# ── What it reads (D-219) ─────────────────────────────────────────────────────
#
# The vendored Node OpenAPI, docs/integration/taytay-node-openapi.json: the
# backend's openapi/openapi.json, copied byte for byte at the commit recorded in
# lib/core/api/backend_baseline.dart. check_backend_baseline.sh proves the copy
# is that commit's; this script asks whether the copy publishes every declared
# route at its verb. It needs no backend clone and no network, so it runs
# wherever this repository is checked out.
#
# Until 2026-11-15 it read Routes/api_v1.php at the PHP tag api-baseline-2026-08.
# The backend has been Node since 2026-10-20 and that tag is not in it, so the
# script could only exit 2 — and a guard that cannot run is worse than none,
# because whoever reads certify.sh believes it checks something.
#
# ── The exception list is a ratchet ───────────────────────────────────────────
#
# `routesAheadOfBaseline` names the routes this app calls that the vendored
# contract does not publish yet. This script fails when a route is missing and
# unnamed — so one cannot arrive quietly — and fails equally when a named route
# turns out to be published, so the list cannot outlive the problem. A guard
# that is permanently red is a guard people learn to skip, and a permanent
# allowlist is one nobody reads again.

set -euo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/lib/core/api/backend_routes.dart"
CONSTANTS="$REPO_ROOT/lib/core/api/backend_baseline.dart"
SPEC_REL="docs/integration/taytay-node-openapi.json"
SPEC="$REPO_ROOT/$SPEC_REL"

for file in "$MANIFEST" "$SPEC"; do
  if [ ! -f "$file" ]; then
    echo "FAIL: $file is missing; there is nothing to check against." >&2
    exit 2
  fi
done

# Only for the summary line: which backend commit the answer is about. A missing
# record is check_backend_baseline.sh's failure to report, not this script's.
COMMIT="$(tr '\r\n' '  ' < "$CONSTANTS" \
  | grep -oE "const String nodeContractCommit = *'[^']*'" \
  | sed -E "s/.*'([^']*)'$/\1/" || true)"

# ── What the contract publishes ───────────────────────────────────────────────
#
# A small JSON walker rather than a pattern over lines, because the spec's
# indentation is not uniform: on the day this was written twenty operations sat
# two spaces deeper than the rest, and an indentation match saw 281 of 301 and
# reported the other twenty as missing. The walker reads strings (with their
# escapes), brackets and literals, tracks the key at each depth, and prints
# "VERB path" for every operation under the root `paths` object. Then a summary
# line the checks below hold against independent counts.
spec_operations() {
  awk '
    function fail(msg) { print "#ERROR line " NR ": " msg; failed = 1; exit }
    function onkey(d, k) {
      if (d == 1 && k == "paths") sawpaths = 1
      if (key[1] != "paths") return
      if (d == 2) items++
      if (d == 3 && k ~ /^(get|put|post|delete|options|head|patch|trace)$/) {
        ops++
        print toupper(k) " " key[2]
      }
    }
    {
      s = $0
      while (s != "") {
        if (match(s, /^[ \t\r]+/)) { s = substr(s, RLENGTH + 1); continue }
        c = substr(s, 1, 1)
        if (c == "\"") {
          if (!match(s, /^"([^"\\]|\\.)*"/)) fail("an unterminated string")
          str = substr(s, 2, RLENGTH - 2); pending = 1
          s = substr(s, RLENGTH + 1); continue
        }
        if (match(s, /^(true|false|null|-?[0-9][0-9.eE+-]*)/)) {
          pending = 0; s = substr(s, RLENGTH + 1); continue
        }
        if (c == ":") {
          if (!pending) fail("a colon with no key before it")
          key[depth] = str; onkey(depth, str)
        } else if (c == "{" || c == "[") {
          depth++; key[depth] = ""
        } else if (c == "}" || c == "]") {
          if (--depth < 0) fail("a closing bracket with nothing open")
        } else if (c != ",") {
          fail("an unexpected character")
        }
        pending = 0; s = substr(s, 2)
      }
    }
    END { if (!failed) print "#COUNTS " items + 0 " " ops + 0 " " depth + 0 " " sawpaths + 0 }
  ' "$SPEC"
}

WALK="$(spec_operations)"

if printf '%s\n' "$WALK" | grep -q '^#ERROR'; then
  echo "FAIL: $SPEC_REL could not be read as JSON:" >&2
  printf '%s\n' "$WALK" | sed -n 's/^#ERROR /      /p' >&2
  exit 2
fi

read -r ITEMS OPS DEPTH SAWPATHS <<< "$(printf '%s\n' "$WALK" | sed -n 's/^#COUNTS //p')"

# The walker is checked against two counts it did not produce. Its own output
# cannot vouch for it: a walker that loses its depth sees fewer paths, and a
# guard that misreads the contract fails for the wrong reason or, worse, passes.
TEXT_ITEMS="$(grep -oE '"/[^"]*" *: *\{' "$SPEC" | wc -l | tr -d ' ')"
TEXT_OPS="$(grep -oE '"operationId" *:' "$SPEC" | wc -l | tr -d ' ')"

if [ "${SAWPATHS:-0}" != 1 ] || [ "${DEPTH:-1}" != 0 ]; then
  echo "FAIL: $SPEC_REL has no root \`paths\` object, or its brackets do not balance." >&2
  echo "      A guard that parses nothing passes everything. Fix the parser or the file." >&2
  exit 2
fi
if [ "$ITEMS" != "$TEXT_ITEMS" ] || [ "$OPS" != "$TEXT_OPS" ]; then
  echo "FAIL: the walker saw $ITEMS paths and $OPS operations; the file has" >&2
  echo "      $TEXT_ITEMS path keys and $TEXT_OPS operationIds." >&2
  echo "      Either the walker has lost its place, or an operation was published" >&2
  echo "      without an operationId. Fix whichever it is; do not loosen this count." >&2
  exit 2
fi

# The app's base URL ends in /api/v1, so only those paths are callable, and the
# prefix goes. Parameters are flattened to `{}`: which segment is dynamic is
# contract, what the backend calls it (`{id}`, `{slug}`) is not, and matching on
# the name would go red every time somebody renamed a variable.
served_routes() {
  printf '%s\n' "$WALK" \
    | sed -nE 's#^([A-Z]+) /api/v1/#\1 #p' \
    | sed -E 's/\{[^}]*\}/{}/g' \
    | sort -u
}

# NEWLINES ARE SQUEEZED OUT FIRST, AND THAT IS NOT A TIDINESS CHOICE.
#
# `dart format` wraps a constructor whose arguments do not fit, so half the rows
# in the manifest look like
#
#     BackendRoute(
#       'POST',
#       'auth/password-reset/complete',
#       'auth_api_repository.dart',
#     ),
#
# A line-oriented match silently sees some of them and reports the rest as
# undeclared — exactly the drift this script exists to catch, produced by the
# script itself. It happened, on the first commit somebody else made after this
# guard was written. Carriage returns go too: a Windows checkout has them.
declared_routes() {
  tr '\r\n' '  ' < "$MANIFEST" \
    | grep -oE "BackendRoute\( *'[A-Z]+', *'[^']+'" \
    | sed -E "s/BackendRoute\( *'([A-Z]+)', *'([^']+)'/\1 \2/" \
    | sort -u || true
}

# A declaration this parser cannot see is a route this guard cannot check, so the
# count is asserted against the raw number of constructors. Without this the fix
# above is one reformat away from silently regressing.
assert_parser_sees_everything() {
  local declared raw
  declared="$(declared_routes | grep -c . || true)"
  raw="$(grep -c 'BackendRoute(' "$MANIFEST" || true)"
  # One extra: the constructor's own declaration in the class body.
  if [ "$declared" -lt "$((raw - 1))" ]; then
    echo "FAIL: the manifest parser sees $declared of $((raw - 1)) declared routes." >&2
    echo "      Formatting has outrun the parser again. Fix the parser; do not" >&2
    echo "      lower this expectation." >&2
    exit 2
  fi
}

assert_parser_sees_everything

# The list is found by its declaration, so a rename or a reshaping reads as
# "cannot see the list" (exit 2) rather than as an empty list that excuses nothing
# and hides nothing.
EXCEPTION_LIST="$(tr '\r\n' '  ' < "$MANIFEST" \
  | grep -oE 'const List<String> routesAheadOfBaseline = <String>\[[^]]*\]' || true)"
if [ -z "$EXCEPTION_LIST" ]; then
  echo "FAIL: could not find \`const List<String> routesAheadOfBaseline = <String>[...]\`" >&2
  echo "      in lib/core/api/backend_routes.dart. Fix the parser, not the list." >&2
  exit 2
fi

SERVED="$(served_routes)"
DECLARED="$(declared_routes)"
EXCEPTED="$(printf '%s\n' "$EXCEPTION_LIST" | grep -oE "'[A-Z]+ [^']+'" | tr -d "'" | sort -u || true)"

if [ -z "$SERVED" ] || [ -z "$DECLARED" ]; then
  echo "FAIL: a list parsed to nothing — published: $(printf '%s' "$SERVED" | grep -c . || true), declared: $(printf '%s' "$DECLARED" | grep -c . || true)" >&2
  echo "      A guard that parses nothing passes everything. Fix the parser." >&2
  exit 2
fi

MISSING="$(comm -23 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$SERVED"))"
UNEXPLAINED="$(comm -23 <(printf '%s\n' "$MISSING") <(printf '%s\n' "$EXCEPTED") | grep . || true)"
STALE="$(comm -13 <(printf '%s\n' "$MISSING") <(printf '%s\n' "$EXCEPTED") | grep . || true)"

STATUS=0

if [ -n "$UNEXPLAINED" ]; then
  echo >&2
  echo "FAIL: this app calls routes the Node contract does not publish, and does not admit it:" >&2
  printf '%s\n' "$UNEXPLAINED" | sed 's/^/  /' >&2
  echo >&2
  echo "      Either the vendored contract is stale — re-vendor it from the backend" >&2
  echo "      and record the commit and sha256 (D-219) — or the call is wrong." >&2
  echo "      Adding it to routesAheadOfBaseline is only correct when the route" >&2
  echo "      exists on the backend today and the vendored copy has not caught up." >&2
  STATUS=1
fi

if [ -n "$STALE" ]; then
  echo >&2
  echo "FAIL: routesAheadOfBaseline names routes the Node contract DOES publish" >&2
  echo "      (or that this app no longer declares):" >&2
  printf '%s\n' "$STALE" | sed 's/^/  /' >&2
  echo >&2
  echo "      The contract moved and the list did not. Remove these entries — an" >&2
  echo "      exception that outlives its reason is one nobody reads again." >&2
  STATUS=1
fi

if [ "$STATUS" -eq 0 ]; then
  TOTAL="$(printf '%s\n' "$DECLARED" | grep -c .)"
  AHEAD="$(printf '%s\n' "$EXCEPTED" | grep -c . || true)"
  echo "OK: $TOTAL declared routes; $((TOTAL - AHEAD)) published by the Node contract (backend ${COMMIT:-unrecorded}), $AHEAD recorded ahead of it."
fi

exit "$STATUS"
