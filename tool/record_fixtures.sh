#!/usr/bin/env bash
#
# Records golden fixtures from a live staging API.
#
# UNFED AT TAB 01. There is no reachable staging environment for this platform
# and no PHP toolchain on the development machine, so nothing has been captured.
# This script is the mechanism, ready for the day one exists — see
# test/contract/README.md for why hand-authored fixtures were refused instead.
#
#   TAYTAY_STAGING=https://staging.example/api/v1 \
#   TAYTAY_TOKEN=<resident token> \
#   ./tool/record_fixtures.sh
#
# REDACTION HAPPENS AT CAPTURE, NEVER BEFORE COMMIT. This repository is public
# and git history is permanent: a fixture written unredacted is published even if
# the next commit removes it. So the redactor runs between the socket and the
# disk, and the script refuses to write a file that still looks like personal
# data rather than leaving that judgement to a reviewer.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_ROOT/test/contract/fixtures"
TAG="$(sed -n "s/^const String backendBaselineTag = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"

if [ -z "${TAYTAY_STAGING:-}" ]; then
  echo "SKIP: TAYTAY_STAGING is not set — no staging API to record from." >&2
  echo "      Nothing was written. This is the expected state at TAB 01." >&2
  exit 3
fi

command -v jq >/dev/null || { echo "FAIL: jq is required." >&2; exit 2; }

mkdir -p "$OUT"

# Endpoints worth a golden fixture, and the error shapes the newly wired
# repositories are most likely to get wrong. Public reads first: they can be
# captured with no token and carry no personal data by construction.
PUBLIC=(
  "app/bootstrap" "health" "services" "programs" "newsfeed" "events"
  "privacy/notice" "barangays"
)
AUTHENTICATED=(
  "me" "me/profile" "me/household" "me/kyc" "me/credential"
  "me/notifications" "me/notification-preferences" "me/cases"
  "me/assistance/drafts" "me/assistance-history" "me/referrals"
  "me/sessions" "me/devices" "me/event-registrations" "me/privacy/consents"
)

# Values that must never reach a committed file. Redaction is by KEY, not by
# pattern-matching the value: a rule that looks for things shaped like a mobile
# number misses the one written differently, and the next payload has a shape
# nobody anticipated. A key list is small, auditable and fails safe.
REDACT_KEYS='given_name,middle_name,family_name,full_name,name,display_name,
mobile_number,email,address,street,barangay_address,birth_date,date_of_birth,
philsys_number,national_id,photo_url,avatar_url,signature,qr_payload,
assigned_to,internal_note,narrative,notes,reason'

redact() {
  jq --arg keys "$(echo "$REDACT_KEYS" | tr -d '\n ')" '
    def scrub:
      ($keys | split(",")) as $k
      | walk(
          if type == "object" then
            with_entries(if (.key | IN($k[])) then .value = "[redacted]" else . end)
          else . end
        );
    scrub
  '
}

capture() {
  # $3: "public" for endpoints that carry no personal data by construction.
  #
  # Redaction is by key and deliberately blunt, which is right for a resident's
  # record and wrong for the service catalogue: `name` on a published municipal
  # service is the service's name. Redacting it produces a fixture whose decoder
  # test cannot run, so the safe default destroys the artefact it was protecting.
  #
  # Public municipal content is exempt — services, programmes, events, the
  # newsfeed, the privacy notice, health and bootstrap are the same for every
  # resident and there is nothing in them to redact.
  local path="$1" auth="$2" public="${3:-}" file
  file="$OUT/$(echo "$path" | tr '/' '_').json"

  local args=(-sS -o /tmp/fixture.body -w '%{http_code}'
              -H 'Accept: application/json'
              -H 'X-Client-Channel: citizen-mobile')
  [ "$auth" = "yes" ] && args+=(-H "Authorization: Bearer ${TAYTAY_TOKEN:-}")

  local status
  status="$(curl "${args[@]}" "$TAYTAY_STAGING/$path" || echo 000)"

  if [ "$status" = "000" ]; then
    echo "  !! $path — unreachable, not written" >&2
    return
  fi

  jq -n --arg endpoint "$path" --arg tag "$TAG" --arg captured "$(date -u +%Y-%m-%d)" \
        --argjson status "$status" --slurpfile body /tmp/fixture.body \
    '{endpoint: $endpoint, baseline_tag: $tag, captured: $captured,
      status: $status, body: $body[0]}' \
    | { if [ "$public" = "public" ]; then cat; else redact; fi; } > "$file"

  # Last line of defence. If a value that looks like a Philippine mobile number
  # or a PhilSys number survived the key list, the key list is wrong — so fail
  # loudly and delete rather than commit it and hope somebody notices.
  if grep -Eq '(\+?63|0)9[0-9]{9}|[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}' "$file"; then
    rm -f "$file"
    echo "FAIL: $path produced something shaped like a government identifier." >&2
    echo "      The file was deleted, not committed. Extend REDACT_KEYS." >&2
    exit 1
  fi

  echo "  ok $path -> $(basename "$file") ($status)"
}

echo "Recording against $TAYTAY_STAGING at $TAG"
for p in "${PUBLIC[@]}"; do capture "$p" no public; done

if [ -n "${TAYTAY_TOKEN:-}" ]; then
  for p in "${AUTHENTICATED[@]}"; do capture "$p" yes; done
else
  echo "  -- TAYTAY_TOKEN unset: authenticated fixtures skipped, loudly." >&2
fi

# The error seam. Captured deliberately, because the Master Command's trap is
# that a harness which only records the happy path is trusted and proves little.
capture "me" yes             # 401 when the token is absent or expired
capture "no-such-endpoint" no # 404
