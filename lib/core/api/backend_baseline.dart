/// The backend contract this app is built against.
///
/// A pinned tag rather than a branch, and a constant rather than a comment, so
/// that the document describing the baseline and the code obeying it cannot
/// drift apart silently — which is the exact failure this repository spent
/// forty-five backend commits inside. `docs/integration/backend-baseline.md`
/// carries the reasoning, the two-axis module table and the gaps;
/// `test/integration/backend_baseline_test.dart` asserts the two agree.
///
/// Two pins live here. The first three constants are the historical PHP
/// baseline: the fixtures and the module table still cite them, and no guard
/// reads that tag any more, because the backend has been Node since 2026-10-20
/// and the tag is not in it. The last two pin the contract this app actually
/// speaks, the vendored Node OpenAPI (D-219).
///
/// Moving the PHP values is re-running TAB 00, not editing a constant; moving
/// the Node values is re-vendoring the spec, never editing them alone.
library;

/// The annotated tag on `Upupapp/taytay-backend` this app is baselined against.
const String backendBaselineTag = 'api-baseline-2026-08';

/// The commit that tag names.
const String backendBaselineCommit = 'eec71e6';

/// When the baseline was taken, ISO-8601 date.
const String backendBaselineDate = '2026-08-18';

/// The backend commit whose `openapi/openapi.json` was copied, byte for byte,
/// to `docs/integration/taytay-node-openapi.json`.
///
/// `tool/check_backend_baseline.sh` compares the two when the backend clone has
/// this commit. Re-vendoring the spec means changing this, [nodeContractSha256]
/// and the record in `docs/integration/backend-baseline.md` in the same commit.
const String nodeContractCommit = '769deea';

/// The sha256 of `docs/integration/taytay-node-openapi.json`, so that an edit
/// to the vendored file that nobody declared fails on every machine, with no
/// backend clone. `tool/check_backend_baseline.sh` checks it.
const String nodeContractSha256 =
    'd848895ea888018b8452434b46f106252e098414e3534338d067998f35635875';
