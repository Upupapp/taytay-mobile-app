/// The backend contract this app is built against.
///
/// A pinned tag rather than a branch, and a constant rather than a comment, so
/// that the document describing the baseline and the code obeying it cannot
/// drift apart silently — which is the exact failure this repository spent
/// forty-five backend commits inside. `docs/integration/backend-baseline.md`
/// carries the reasoning, the two-axis module table and the gaps;
/// `test/integration/backend_baseline_test.dart` asserts the two agree.
///
/// Moving these values is re-running TAB 00, not editing a constant.
library;

/// The annotated tag on `Upupapp/taytay-backend` this app is baselined against.
const String backendBaselineTag = 'api-baseline-2026-08';

/// The commit that tag names.
const String backendBaselineCommit = 'eec71e6';

/// When the baseline was taken, ISO-8601 date.
const String backendBaselineDate = '2026-08-18';
