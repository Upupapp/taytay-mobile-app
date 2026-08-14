import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';

/// Wire → domain mapping for the resident's verification status.
///
/// ---
///
/// ## An allow-list decoder, and why that shape matters here
///
/// This decoder reads **only** the keys named below and walks past everything
/// else. That is the normal rule for this app (conventions section 1 — clients
/// ignore unknown fields), but here it is also the privacy control.
///
/// The committed client-visibility matrix names fields that "never appear in any
/// citizen or verifier response, in any endpoint, ever" — reviewer identity,
/// internal review notes, staff identities — and states that a citizen
/// projection is built "by naming the fields to include, never by taking the
/// staff projection and removing some".
///
/// A deny-list decoder would be one forgotten key away from rendering a
/// caseworker's note. An allow-list decoder cannot leak a field nobody added a
/// line for, and `verification_test.dart` proves it by feeding in a payload
/// stuffed with `reviewed_by`, `risk_score`, `internal_notes`, `audit_trail`,
/// `match_candidates` and another resident's record, then asserting none of it
/// survives.
///
/// **No endpoint is invented.** The shape below follows the committed matrix row
/// `GET /api/v1/me/verification` → "tier + outstanding steps"; the field names
/// are the app's reading of that description and are re-checked when the
/// `Verification` module ships.
abstract final class VerificationStatusDto {
  /// Keys this decoder will read. Anything else in the payload is ignored.
  static const Set<String> allowedKeys = <String>{
    'state',
    'verification_tier',
    'submitted_categories',
    'issues',
    'resident_guidance',
    'manual_review_available',
    'submitted_at',
  };

  /// Keys that must never be read even if a server sends them.
  ///
  /// Listed for the test and for the reader, not consulted at runtime — the
  /// allow-list above already excludes them. Naming them makes the intent
  /// checkable rather than implied.
  static const Set<String> forbiddenKeys = <String>{
    'reviewed_by',
    'reviewer_name',
    'reviewer_id',
    'risk_score',
    'fraud_score',
    'confidence',
    'internal_notes',
    'remarks',
    'caseworker_notes',
    'audit_trail',
    'status_changes',
    'match_candidates',
    'matched_resident',
    'rejection_code',
    'rejection_heuristic',
    'actor_id',
    'actor_name',
  };

  static VerificationStatusDetail fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return VerificationStatusDetail.unknown;

    final rawState = _string(raw['state']) ?? _string(raw['verification_tier']);
    final attemptState = _attemptState(rawState);

    return VerificationStatusDetail(
      // Unknown server states land on `manualReview`, which always has a safe
      // next step. Never on `verified`.
      stage: ResidentVerificationStage.fromAttemptState(attemptState),
      rawState: rawState ?? '',
      submittedCategories: _categories(raw['submitted_categories']),
      issues: _issues(raw['issues']),
      residentGuidance: _string(raw['resident_guidance']),
      manualReviewAvailable: raw['manual_review_available'] == true,
      submittedAt: _dateTime(raw['submitted_at']),
    );
  }

  /// Maps the server's state string.
  ///
  /// The `Verification` module publishes no wire values yet (backend gap
  /// **G-08** says the enumeration is owned server-side and built in a later
  /// TAB), so this recognises the spellings the boundary map's own lifecycle
  /// description implies and returns `null` for everything else. `null` is not a
  /// failure: it routes to the manual-review stage, which is safe.
  static VerificationAttemptState? _attemptState(String? raw) => switch (raw) {
    'not_started' => VerificationAttemptState.notStarted,
    'draft' || 'in_progress' => VerificationAttemptState.draft,
    'submitted' => VerificationAttemptState.submitted,
    'under_review' => VerificationAttemptState.underReview,
    'approved' || 'verified' => VerificationAttemptState.approved,
    'rejected' => VerificationAttemptState.rejected,
    _ => null,
  };

  static List<VerificationItemCategory> _categories(Object? raw) {
    if (raw is! List) return const <VerificationItemCategory>[];
    return raw
        .whereType<String>()
        .map(VerificationItemCategory.fromCode)
        .whereType<VerificationItemCategory>()
        .toList(growable: false);
  }

  /// Decodes outstanding items.
  ///
  /// An issue whose category this build does not recognise is **dropped**: a
  /// resident cannot act on a raw code, and showing one invites them to guess.
  /// An issue with no instruction is dropped for the same reason — "something is
  /// wrong with your address" with no further detail is worse than the office
  /// simply not having flagged it.
  static List<VerificationItemIssue> _issues(Object? raw) {
    if (raw is! List) return const <VerificationItemIssue>[];

    final issues = <VerificationItemIssue>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final category = VerificationItemCategory.fromCode(
        _string(entry['category']),
      );
      final instruction = _string(entry['instruction']);
      if (category == null || instruction == null) continue;
      issues.add(
        VerificationItemIssue(category: category, instruction: instruction),
      );
    }
    return List<VerificationItemIssue>.unmodifiable(issues);
  }

  static DateTime? _dateTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
