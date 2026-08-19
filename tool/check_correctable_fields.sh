#!/usr/bin/env bash
#
# Does this app name the same correctable fields the server will accept?
#
# F23. `POST me/profile/corrections` validates `changes` against
# `Modules\ResidentProfile\Contracts\CorrectableField` and **refuses an unknown
# key explicitly** rather than dropping it — so a field this app invents produces
# a 422 whose message names a wire field the resident has never seen, on the
# screen that decides whether they ever become Verified.
#
# The other direction matters as much and is quieter: a field the server gains
# and this app never offers is a correction a resident simply cannot ask for,
# with nothing anywhere reporting it.
#
# The vendored contract cannot answer this — it publishes the path and no request
# schema (backend finding L-11) — so the check reads the backend at the pinned
# baseline, like `check_backend_routes.sh`, and needs the clone for the same
# reason: the tag has never been pushed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_ENUM="$REPO_ROOT/lib/features/verification/domain/correctable_field.dart"
SERVER_ENUM='modules/ResidentProfile/Contracts/CorrectableField.php'

TAG="$(sed -n "s/^const String backendBaselineTag = '\(.*\)';$/\1/p" \
  "$REPO_ROOT/lib/core/api/backend_baseline.dart")"

BACKEND="${TAYTAY_BACKEND:-$(cd "$REPO_ROOT/.." && pwd)/taytay-backend}"

if [ ! -d "$BACKEND/.git" ]; then
  echo "FAIL: no backend clone at $BACKEND. Set TAYTAY_BACKEND." >&2
  echo "      There is no network fallback: $TAG is a local tag, never pushed." >&2
  exit 2
fi

echo "Baseline: $TAG from $BACKEND"

# `case FirstName = 'first_name';` → first_name
server_fields() {
  git -C "$BACKEND" show "$TAG:$SERVER_ENUM" \
    | grep -oE "case [A-Za-z]+ = '[a-z_]+';" \
    | sed -E "s/case [A-Za-z]+ = '([a-z_]+)';/\1/" \
    | sort -u
}

# `firstName('first_name'),` → first_name
app_fields() {
  grep -oE "^  [a-zA-Z]+\('[a-z_]+'\)" "$APP_ENUM" \
    | sed -E "s/^  [a-zA-Z]+\('([a-z_]+)'\)/\1/" \
    | sort -u
}

SERVER="$(server_fields)"
APP="$(app_fields)"

if [ -z "$SERVER" ] || [ -z "$APP" ]; then
  echo "FAIL: a list parsed to nothing — server: $(printf '%s' "$SERVER" | grep -c . || true), app: $(printf '%s' "$APP" | grep -c . || true)" >&2
  echo "      A guard that parses nothing passes everything. Fix the parser." >&2
  exit 2
fi

INVENTED="$(comm -23 <(printf '%s\n' "$APP") <(printf '%s\n' "$SERVER"))"
MISSED="$(comm -13 <(printf '%s\n' "$APP") <(printf '%s\n' "$SERVER"))"

STATUS=0

if [ -n "$INVENTED" ]; then
  echo >&2
  echo "FAIL: this app names fields the server will refuse:" >&2
  printf '  %s\n' $INVENTED >&2
  echo "      The server fails the whole request on an unknown key. A resident" >&2
  echo "      meets a 422 naming a wire field they have never seen." >&2
  STATUS=1
fi

if [ -n "$MISSED" ]; then
  echo >&2
  echo "FAIL: the server accepts fields this app never offers:" >&2
  printf '  %s\n' $MISSED >&2
  echo "      A correction nobody can ask for, with nothing reporting it. Add" >&2
  echo "      the field and put it on a category, or record why it is withheld." >&2
  STATUS=1
fi

if [ "$STATUS" -eq 0 ]; then
  echo "OK: $(printf '%s\n' "$APP" | grep -c .) correctable fields agree with the server at $TAG."
fi

exit "$STATUS"
