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

failed=0
for f in "${FIXTURES[@]}"; do
  endpoint="$(jq -r '.endpoint' "$f")"
  recorded="$(jq -S '.body | walk(if type == "object" then with_entries(.value = (.value | type)) else . end)' "$f" 2>/dev/null || echo '{}')"

  live_raw="$(curl -sS -H 'Accept: application/json' \
                   -H 'X-Client-Channel: citizen-mobile' \
                   "$TAYTAY_STAGING/$endpoint" || echo '{}')"
  live="$(echo "$live_raw" | jq -S 'walk(if type == "object" then with_entries(.value = (.value | type)) else . end)' 2>/dev/null || echo '{}')"

  # Compares SHAPE, not values. A fixture that failed on a changed name or a new
  # row would go red every day and be switched off within a week; a fixture that
  # goes red when a field changes type or disappears is one people believe.
  if [ "$recorded" != "$live" ]; then
    echo "DRIFT: $endpoint" >&2
    diff <(echo "$recorded") <(echo "$live") >&2 || true
    failed=1
  fi
done

[ $failed -eq 0 ] && echo "OK: ${#FIXTURES[@]} fixtures still match staging." || exit 1
