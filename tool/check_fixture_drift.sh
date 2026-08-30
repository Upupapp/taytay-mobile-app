#!/usr/bin/env bash
#
# Re-fetches every recorded fixture and fails on drift.
#
# This is what turns "we match the contract" from an assertion into a monitored
# fact. It needs a staging API; without one it SKIPS LOUDLY, because a check that
# passes when it cannot run is worse than no check — it reports proof it does not
# have.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/test/contract/fixtures"

if [ -z "${TAYTAY_STAGING:-}" ]; then
  echo "SKIP: TAYTAY_STAGING is not set." >&2
  echo "      Fixture drift is NOT PROVEN. Do not read this as a pass." >&2
  exit 3
fi

shopt -s nullglob
FIXTURES=("$OUT"/*.json)
if [ ${#FIXTURES[@]} -eq 0 ]; then
  echo "SKIP: no fixtures recorded yet — run tool/record_fixtures.sh." >&2
  echo "      Fixture drift is NOT PROVEN." >&2
  exit 3
fi

command -v jq >/dev/null || { echo "FAIL: jq is required." >&2; exit 2; }

# BOTH SIDES USED TO DEGRADE TO THE SAME SENTINEL.
#
# `recorded` and `live` were each computed as `jq ... || echo '{}'`. A fixture
# jq could not parse gave `{}`; a staging reply jq could not parse gave `{}`;
# and `{}` equals `{}`, so the loop found no drift and the script printed
# "OK: N fixtures still match staging" having compared nothing to nothing.
#
# That is the same fault as the signature check next door, pointed the other
# way — and this direction is worse, because a false FAIL gets investigated and
# a false OK gets believed. There is no sentinel any more: a side that cannot be
# read is an error, not an empty object.
#
# `curl -sS` also does not fail on HTTP errors. Without `-f` a 401 or a 500 is
# "success" with an error page as the body, so an unauthenticated staging host
# would have been compared against as though it were the API.
failed=0
compared=0
for f in "${FIXTURES[@]}"; do
  # Guarded like everything else below it. Unguarded, `set -e` aborted here
  # with exit 1 — which in this script means DRIFT FOUND — and printed only
  # jq's parse error. A malformed fixture reported itself as a contract change.
  # Found by red-proofing the check two lines down, which is the argument for
  # red-proofing: the fault was in the line nobody was testing.
  if ! endpoint="$(jq -re '.endpoint' "$f" 2>&1)"; then
    echo "FAIL: could not read .endpoint from $f" >&2
    echo "      jq said: $endpoint" >&2
    echo "      This says nothing about staging — nothing was compared." >&2
    exit 2
  fi

  if ! recorded="$(jq -S '.body | walk(if type == "object" then with_entries(.value = (.value | type)) else . end)' "$f" 2>&1)"; then
    echo "FAIL: could not read the recorded fixture $f" >&2
    echo "      jq said: $recorded" >&2
    echo "      This says nothing about staging — nothing was compared." >&2
    exit 2
  fi

  # NOT `curl -f`. Three of the recorded fixtures are deliberate ERROR
  # envelopes — `me` and `newsfeed` at 401, `no-such-endpoint` at 404 — because
  # the shape of `error.code` / `request_id` is part of the contract this app
  # decodes. `-f` makes curl fail on those, so hardening this script with it
  # would have broken drift-checking for three fixtures while looking stricter.
  #
  # What matters is the difference between "the host did not answer" (no
  # evidence) and "the host answered with an HTTP error" (evidence, and
  # possibly the expected one). So: transport failure is fatal, and the status
  # code is compared against the fixture rather than assumed.
  http=0
  body_file="$(mktemp)"
  http="$(curl -sS -o "$body_file" -w '%{http_code}' \
               -H 'Accept: application/json' \
               -H 'X-Client-Channel: citizen-mobile' \
               "$TAYTAY_STAGING/$endpoint")" || {
    echo "FAIL: could not reach staging for $endpoint." >&2
    echo "      Not proven is not the same as no drift." >&2
    rm -f "$body_file"
    exit 2
  }
  live_raw="$(cat "$body_file")"
  rm -f "$body_file"

  # A status change is drift. `me` answering 200 where the fixture recorded 401
  # is a contract change, and comparing only the body shape would miss it.
  recorded_status="$(jq -r '.status' "$f")"
  if [ "$http" != "$recorded_status" ]; then
    echo "DRIFT: $endpoint — HTTP $recorded_status recorded, $http now." >&2
    failed=1
  fi

  if ! live="$(echo "$live_raw" | jq -S 'walk(if type == "object" then with_entries(.value = (.value | type)) else . end)' 2>&1)"; then
    echo "FAIL: staging returned something that is not JSON for $endpoint" >&2
    echo "      jq said: $live" >&2
    exit 2
  fi

  # Compares SHAPE, not values. A fixture that failed on a changed name or a new
  # row would go red every day and be switched off within a week; a fixture that
  # goes red when a field changes type or disappears is one people believe.
  if [ "$recorded" != "$live" ]; then
    echo "DRIFT: $endpoint" >&2
    diff <(echo "$recorded") <(echo "$live") >&2 || true
    failed=1
  fi
  compared=$((compared + 1))
done

# Floor: a run that compared nothing must not report that nothing drifted.
if [ "$compared" -ne "${#FIXTURES[@]}" ]; then
  echo "FAIL: $compared of ${#FIXTURES[@]} fixtures were actually compared." >&2
  exit 2
fi
[ $failed -eq 0 ] && echo "OK: $compared fixtures still match staging." || exit 1
