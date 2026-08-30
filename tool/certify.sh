#!/usr/bin/env bash
#
# Gate a COMMIT, not a working tree — and stamp the SHA.
#
# ## Why this exists
#
# Every green in this repository was measured in the working tree until
# 2026-08-29, when the gates were first run from a detached worktree. A
# lived-in tree carries resolved packages, generated files and build outputs
# that HEAD does not, so a gate can pass because of something nobody committed.
# The clearest case: `check_release_hardening.sh` had been red for eleven days
# over an APK in `build/` that HEAD has never contained.
#
# That run was done by hand and left as a procedure only its author knew, which
# is exactly how the rest of that week's findings came to exist — a rule stated
# in a document and enforced by nobody. So it is a script.
#
# ## What this script refuses to do
#
# It does not swallow a tool's error and report it as a finding. Every failure
# below distinguishes THREE outcomes, because collapsing them is the defect
# this repository kept finding in its own gates:
#
#   exit 0   certified — every gate ran and passed
#   exit 1   a gate ran and FAILED
#   exit 2   a gate COULD NOT RUN — nothing is claimed either way
#   exit 3   certified, with gates that honestly skipped (NOT PROVEN)
#
# "Could not look" is not "looked and found nothing", and neither is a pass.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="${1:-HEAD}"

cd "$REPO_ROOT"

if ! SHA="$(git rev-parse --verify "$REF^{commit}" 2>&1)"; then
  echo "FAIL: '$REF' is not a commit in this repository." >&2
  echo "      git said: $SHA" >&2
  exit 2
fi
SHORT="$(git rev-parse --short "$SHA")"

# A worktree inside the repo would be picked up by the very scans being
# certified — `Directory('lib').listSync(recursive: true)` does not know it is
# looking at a copy of itself.
WT="${TMPDIR:-/tmp}/taytay-certify-$SHORT.$$"
cleanup() {
  git worktree remove --force "$WT" >/dev/null 2>&1 || true
  git worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Certifying $SHORT ($(git log -1 --format=%s "$SHA" | cut -c1-64))"
echo

if ! out="$(git worktree add --detach "$WT" "$SHA" 2>&1)"; then
  echo "FAIL: could not create a worktree." >&2
  echo "      git said: $out" >&2
  exit 2
fi

# The worktree must be clean by construction. If it is not, something is
# generating files during checkout and the certification is already meaningless.
if [ -n "$(git -C "$WT" status --porcelain)" ]; then
  echo "FAIL: the fresh worktree is not clean." >&2
  git -C "$WT" status --porcelain >&2
  exit 2
fi

cd "$WT"

if ! out="$(flutter pub get 2>&1)"; then
  echo "FAIL: dependencies would not resolve at $SHORT." >&2
  echo "$out" | sed 's/^/        /' >&2
  exit 2
fi

fail=0
unproven=0
declare -a ROWS=()

# A row with an empty result is not a row. It renders as a blank table cell,
# which reads as "did not run" — the one thing this script exists to
# distinguish from "ran and passed". The typed-render gate produced exactly that
# on its first certification: it passed, exited 0, and reported nothing, because
# its output was scraped with an anchored pattern that `dart run`'s
# "Running build hooks..." prefix defeated.
#
# So an empty result is a fault in this script, and it says so loudly rather
# than printing a blank and letting the reader supply the meaning.
row() {
  if [ -z "$2" ]; then
    ROWS+=("$1|**REPORTED NOTHING** — certify.sh could not read this gate's result")
    fail=1
  else
    ROWS+=("$1|$2")
  fi
}

# --- formatting -----------------------------------------------------------
# Added 2026-08-30, straight after eight files that had NEVER been formatted
# were finally formatted. Nothing had kept the tree tidy, and the drift was not
# harmless: a blanket `dart format` during unrelated work swept those files into
# two diffs they did not belong in and had to be reverted both times, and the
# formatter re-wrapping a constructor is the same mechanism that once made the
# backend-route parser see 37 of 53 routes and pass.
#
# `--output=none` so this never edits the worktree it is certifying.
set +e
fmt="$(dart format --output=none --set-exit-if-changed lib test 2>&1)"; fmt_code=$?
set -e
case $fmt_code in
  0) row "\`dart format\`" "**clean**" ;;
  1)
    row "\`dart format\`" "**FAILED** — $(printf '%s' "$fmt" | grep -c '^Changed') file(s) unformatted"
    printf '%s\n' "$fmt" | grep '^Changed' >&2
    fail=1
    ;;
  *)
    # Distinguish "the formatter says no" from "the formatter did not run".
    echo "FAIL: dart format could not run." >&2
    printf '%s\n' "$fmt" | tail -10 >&2
    exit 2
    ;;
esac

# --- analyzer -------------------------------------------------------------
if analyze="$(flutter analyze 2>&1)"; then
  row "flutter analyze" "**clean**"
else
  row "flutter analyze" "**FAILED**"
  echo "$analyze" | tail -20 >&2
  fail=1
fi

# --- suite ----------------------------------------------------------------
suite="$(flutter test 2>&1 || true)"
# FLOOR. `flutter test` printing nothing useful must not read as success — a
# suite that ran no tests is the shell equivalent of a parser that matched
# nothing, and this repository has been bitten by that shape four times.
counts="$(printf '%s\n' "$suite" | grep -oE '\+[0-9]+' | tail -1 || true)"
passed="${counts#+}"
if [ -z "${passed:-}" ] || [ "$passed" -lt 1 ]; then
  echo "FAIL: the suite reported no passing tests — it did not run." >&2
  printf '%s\n' "$suite" | tail -20 >&2
  exit 2
fi
if printf '%s\n' "$suite" | grep -q 'All tests passed!'; then
  row "flutter test" "**$passed passing**"
else
  row "flutter test" "**FAILED** ($passed passing)"
  printf '%s\n' "$suite" | grep -A3 'Failing tests' >&2 || true
  fail=1
fi

# --- cross-repo guards ----------------------------------------------------
# These read the backend at the pinned tag. Without TAYTAY_BACKEND they fetch
# from raw.githubusercontent, which is legitimate and slower; either way the
# script says which one happened rather than leaving it to be guessed.
if [ -n "${TAYTAY_BACKEND:-}" ]; then
  echo "  backend source: local clone at $TAYTAY_BACKEND"
else
  echo "  backend source: raw.githubusercontent at the pinned tag"
fi

# The type-aware render guard. A `dart run` rather than a shell script: inside
# `flutter test` the analyzer cannot find the Dart SDK, so this is the only
# place it runs. It resolves the whole of lib/ and costs about eight seconds.
set +e
typed="$(dart run tool/check_typed_renders.dart 2>&1)"; typed_code=$?
set -e
case $typed_code in
  # `grep -o 'OK:.*'`, not `grep '^OK:'`. `dart run` prints "Running build
  # hooks..." with NO trailing newline, so the tool's own first line is not at
  # the start of a line and an anchored match finds nothing. The first version
  # of this row was therefore EMPTY on a passing run — the gate worked, the
  # exit code was right, and the table said nothing where a reader looks for a
  # result. A blank cell reads as "did not run", which is the one thing this
  # script exists to distinguish from "ran and passed".
  0) row "\`check_typed_renders.dart\`" "$(printf '%s' "$typed" | grep -o 'OK:.*' | head -1 | sed 's/^OK: //')" ;;
  1) row "\`check_typed_renders.dart\`" "**FAILED**" ; printf '%s\n' "$typed" | tail -8 >&2 ; fail=1 ;;
  *) row "\`check_typed_renders.dart\`" "**could not run**" ; printf '%s\n' "$typed" | tail -8 >&2 ; exit 2 ;;
esac

for guard in check_backend_baseline check_backend_routes check_correctable_fields; do
  set +e
  out="$(bash "tool/$guard.sh" 2>&1)"; code=$?
  set -e
  case $code in
    0) row "\`$guard.sh\`" "$(printf '%s' "$out" | grep -o 'OK:.*' | head -1 | sed 's/^OK: //')" ;;
    3) row "\`$guard.sh\`" "**SKIP** — not proven" ; unproven=1 ;;
    *) row "\`$guard.sh\`" "**FAILED**" ; echo "$out" | tail -10 >&2 ; fail=1 ;;
  esac
done

# --- gates that legitimately cannot run here -------------------------------
for guard in check_fixture_drift check_release_hardening; do
  set +e
  out="$(bash "tool/$guard.sh" 2>&1)"; code=$?
  set -e
  case $code in
    0) row "\`$guard.sh\`" "OK" ;;
    3) row "\`$guard.sh\`" "**SKIP (exit 3)** — $(printf '%s' "$out" | head -1 | sed 's/^[A-Z ]*: //')" ; unproven=1 ;;
    *) row "\`$guard.sh\`" "**FAILED**" ; echo "$out" | tail -10 >&2 ; fail=1 ;;
  esac
done

# --- the stamped report ----------------------------------------------------
echo
echo "## \`$SHORT\` — $(date -u +%Y-%m-%d)"
echo
echo "Worktree: \`git worktree add --detach <path> $SHORT\`, clean on creation,"
echo "\`flutter pub get\` resolved from the committed \`pubspec.lock\`."
echo
echo "| Gate | Result |"
echo "|---|---|"
for r in "${ROWS[@]}"; do echo "| ${r%%|*} | ${r#*|} |"; done
echo

if [ $fail -ne 0 ]; then
  echo "NOT CERTIFIED: a gate failed at $SHORT." >&2
  exit 1
elif [ $unproven -ne 0 ]; then
  echo "CERTIFIED WITH GAPS at $SHORT: every gate that could run passed, and"
  echo "some could not run. The SKIP rows are NOT PROVEN, not passes."
  exit 3
else
  echo "CERTIFIED at $SHORT: every gate ran and passed."
  exit 0
fi
