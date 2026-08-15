import '../domain/household_summary.dart';

/// Decodes a household payload by naming the four things a resident may see.
///
/// ---
///
/// **An allow-list, and a very short one.** The committed client-visibility
/// matrix grants a citizen `household` membership *"own household only"* while
/// naming `Household.members` among the things a citizen never receives. Those
/// two statements together define this file: the household itself, yes; the
/// people in it, no.
///
/// **[forbiddenKeys] can never arrive, and is asserted anyway.**
/// [HouseholdSummary] has no property for a member, a sector, a case, a note or
/// an audit entry, so the shape already refuses them. The set exists to state
/// plainly what must never reach a resident's screen, and to be tested against a
/// hostile payload — because the next person to add a field will read it.
abstract final class HouseholdDto {
  static const String labelKey = 'label';
  static const String barangayKey = 'barangay';
  static const String streetAddressKey = 'street_address';
  static const String memberCountKey = 'member_count';
  static const String roleKey = 'role';

  /// Everything this app reads. Anything else is ignored.
  static const Set<String> allowedKeys = <String>{
    labelKey,
    barangayKey,
    streetAddressKey,
    memberCountKey,
    roleKey,
  };

  /// What must never reach a resident's screen, in five groups.
  ///
  /// * **Other people** — `members`, `residents`, `relatives`, `dependents`,
  ///   `head_name`. The matrix names `Household.members` as cross-resident data
  ///   and calls its exposure a critical defect.
  /// * **Vulnerability signals** — `sectors`, `vulnerability_score`,
  ///   `risk_score`, `is_indigent`, `monthly_income`. `sectors` is where
  ///   `vawc-survivor` and `cicl` live; the backend omits those values
  ///   server-side rather than masking them, and a masked field that travels is
  ///   one devtools panel away from being unmasked.
  /// * **Staff and casework** — `caseworker_notes`, `assessment`,
  ///   `internal_notes`, `remarks`, `assigned_to`, `reviewed_by`. Naming the
  ///   handling social worker exposes staff to pressure and, in VAWC cases, to
  ///   danger.
  /// * **Other members' cases** — `assistance_requests`, `disbursements`,
  ///   `referrals`. A resident's own requests live on their own screen; a
  ///   relative's are not theirs to read.
  /// * **Registry and audit internals** — `household_id`, `id`,
  ///   `record_number`, `psgc_code`, `audit_trail`, `created_by`, `updated_by`,
  ///   `match_candidates`.
  static const Set<String> forbiddenKeys = <String>{
    'members',
    'residents',
    'relatives',
    'dependents',
    'head_name',
    'sectors',
    'vulnerability_score',
    'risk_score',
    'is_indigent',
    'monthly_income',
    'caseworker_notes',
    'assessment',
    'internal_notes',
    'remarks',
    'assigned_to',
    'reviewed_by',
    'assistance_requests',
    'disbursements',
    'referrals',
    'household_id',
    'id',
    'record_number',
    'psgc_code',
    'audit_trail',
    'created_by',
    'updated_by',
    'match_candidates',
  };

  /// Reads a `GET /api/v1/me/household`-shaped payload.
  ///
  /// Unknown keys are ignored rather than rejected (API conventions §1): a
  /// server that starts sending a new column must not crash a released app.
  static HouseholdSummary decode(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return const HouseholdSummary(role: HouseholdRole.member);
    }

    return HouseholdSummary(
      // Fails closed to `member`. See `HouseholdRole.fromRaw`.
      role: HouseholdRole.fromRaw(_stringOf(payload, roleKey)),
      label: _stringOf(payload, labelKey),
      barangay: _stringOf(payload, barangayKey),
      streetAddress: _stringOf(payload, streetAddressKey),
      memberCount: _positiveIntOf(payload, memberCountKey),
    );
  }

  /// Strings only, trimmed, non-empty.
  ///
  /// A nested object or a list under an allowed key is **dropped, not
  /// flattened** — that is precisely how a member list would otherwise arrive
  /// rendered as an address.
  static String? _stringOf(Map<String, dynamic> payload, String key) {
    final raw = payload[key];
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  /// A plausible household size, or nothing.
  ///
  /// Bounded on both ends. A zero or negative count is not a household, and a
  /// wildly large one is a decoding accident rather than a family — rendering
  /// either would tell a resident something false about their own record.
  static int? _positiveIntOf(Map<String, dynamic> payload, String key) {
    final raw = payload[key];
    if (raw is! int) return null;
    if (raw <= 0 || raw > 60) return null;
    return raw;
  }

  /// The body for a correction request.
  ///
  /// One field: the category. There is no branch that could add a target value,
  /// a household identifier or a person, because [HouseholdCorrectionRequest]
  /// carries none.
  static Map<String, Object?> encodeCorrection(
    HouseholdCorrectionRequest request,
  ) => <String, Object?>{'kind': request.kind.name};
}
