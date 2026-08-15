import '../domain/assistance_program.dart';

/// Decodes a programme by naming the fields the citizen column authorises.
///
/// ---
///
/// **The allow-list is the visibility matrix §5, transcribed.** Every key below
/// is marked ✅ for a citizen there. The two marked ⛔ — `funding_source` and
/// `audit` — are in [forbiddenKeys] and have no property to arrive in.
///
/// **`status` is read but never stored.** The citizen endpoint is
/// `?status=active`, so a programme that reaches this app is active by
/// construction. Modelling the field would invite a screen to render "status:
/// active" — noise — or worse, to branch on a value the server already filtered.
/// What the decoder does instead is **refuse anything that is not active**, so a
/// server change that widened the projection could not leak a draft programme
/// into a resident's list.
abstract final class ProgramDto {
  static const String codeKey = 'code';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String categoryKey = 'category';
  static const String statusKey = 'status';
  static const String legalBasisKey = 'legal_basis';
  static const String maximumGrantKey = 'maximum_grant';
  static const String eligibilityKey = 'eligibility';
  static const String requirementsKey = 'requirements';
  static const String effectiveFromKey = 'effective_from';
  static const String effectiveToKey = 'effective_to';
  static const String owningOfficeKey = 'owning_office';
  static const String contactKey = 'contact';
  static const String applicationChannelKey = 'application_channel';

  static const Set<String> allowedKeys = <String>{
    codeKey,
    nameKey,
    descriptionKey,
    categoryKey,
    statusKey,
    legalBasisKey,
    maximumGrantKey,
    eligibilityKey,
    requirementsKey,
    effectiveFromKey,
    effectiveToKey,
    owningOfficeKey,
    contactKey,
    applicationChannelKey,
  };

  /// The only status a citizen may be shown.
  static const String activeStatus = 'active';

  /// What must never reach a resident, in four groups.
  ///
  /// * **Marked ⛔ in the matrix** — `funding_source` (budget-line information,
  ///   *"meaningless and misleading to an applicant"*), `audit`, `created_by`,
  ///   `updated_by`.
  /// * **Operational capacity** — `slots_remaining`, `quota`, `capacity`,
  ///   `budget_remaining`, `beneficiary_count`. None of it is in the citizen
  ///   projection, and a remaining-slots figure on a municipal benefit is the
  ///   fastest way to start a queue at 4am for something that was never
  ///   first-come-first-served.
  /// * **Ranking and scoring** — `priority_score`, `ranking`, `weight`,
  ///   `eligibility_rules`. A machine-readable rule set is exactly what would
  ///   let this app compute a verdict, which acceptance 2 forbids.
  /// * **Draft and internal** — `internal_notes`, `remarks`, `draft`,
  ///   `applicants`, `beneficiaries`. Applicant lists are other residents' data.
  static const Set<String> forbiddenKeys = <String>{
    'funding_source',
    'audit',
    'created_by',
    'updated_by',
    'slots_remaining',
    'quota',
    'capacity',
    'budget_remaining',
    'beneficiary_count',
    'priority_score',
    'ranking',
    'weight',
    'eligibility_rules',
    'internal_notes',
    'remarks',
    'draft',
    'applicants',
    'beneficiaries',
  };

  /// Decodes one programme, or `null` when it is not a programme a citizen may
  /// see.
  ///
  /// Returns `null` — rather than a half-built object — when the code or name is
  /// missing, or when the status is anything other than `active`. A nameless
  /// entry in a list of public benefits is not degraded data, it is a row a
  /// resident cannot act on.
  static AssistanceProgram? decode(Object? payload) {
    if (payload is! Map<String, dynamic>) return null;

    final code = _stringOf(payload, codeKey);
    final name = _stringOf(payload, nameKey);
    if (code == null || name == null) return null;

    // Deny by default: absent status is not assumed active.
    final status = _stringOf(payload, statusKey);
    if (status != null && status.toLowerCase() != activeStatus) return null;

    return AssistanceProgram(
      code: code,
      name: name,
      description: _stringOf(payload, descriptionKey) ?? '',
      category: _stringOf(payload, categoryKey),
      legalBasis: _stringOf(payload, legalBasisKey),
      maximumGrant: _stringOf(payload, maximumGrantKey),
      eligibility: _eligibilityOf(payload),
      requirements: _requirementsOf(payload),
      effectiveFrom: _stringOf(payload, effectiveFromKey),
      effectiveTo: _stringOf(payload, effectiveToKey),
      owningOffice: _stringOf(payload, owningOfficeKey),
      contact: _stringOf(payload, contactKey),
      applicationChannel: _stringOf(payload, applicationChannelKey),
    );
  }

  /// Decodes a page, dropping entries a citizen may not see.
  ///
  /// A programme that fails [decode] is skipped rather than failing the page:
  /// one malformed or non-active row must not take the whole directory down.
  static List<AssistanceProgram> decodeAll(Object? payload) {
    if (payload is! List) return const <AssistanceProgram>[];
    return payload
        .map(decode)
        .whereType<AssistanceProgram>()
        .toList(growable: false);
  }

  static String? _stringOf(Map<String, dynamic> payload, String key) {
    final raw = payload[key];
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  /// Eligibility as **text**, never as a rule.
  ///
  /// An entry may be a plain string or an object with a `text` and an optional
  /// `category`. Anything carrying an operator, a field name or a threshold is
  /// not read — this app has no property to put it in, so a machine-readable
  /// rule set arriving here is simply ignored rather than becoming a local
  /// eligibility calculation.
  static List<EligibilityCriterion> _eligibilityOf(
    Map<String, dynamic> payload,
  ) {
    final raw = payload[eligibilityKey];
    if (raw is! List) return const <EligibilityCriterion>[];

    final criteria = <EligibilityCriterion>[];
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        criteria.add(EligibilityCriterion(text: entry.trim()));
      } else if (entry is Map<String, dynamic>) {
        final text = _stringOf(entry, 'text') ?? _stringOf(entry, 'label');
        if (text == null) continue;
        criteria.add(
          EligibilityCriterion(
            text: text,
            category: _stringOf(entry, 'category'),
          ),
        );
      }
    }
    return List<EligibilityCriterion>.unmodifiable(criteria);
  }

  static List<ProgramRequirement> _requirementsOf(
    Map<String, dynamic> payload,
  ) {
    final raw = payload[requirementsKey];
    if (raw is! List) return const <ProgramRequirement>[];

    final requirements = <ProgramRequirement>[];
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        requirements.add(ProgramRequirement(text: entry.trim()));
      } else if (entry is Map<String, dynamic>) {
        final text = _stringOf(entry, 'text') ?? _stringOf(entry, 'label');
        if (text == null) continue;
        requirements.add(
          ProgramRequirement(
            text: text,
            // Optional only when the server says so. Never inferred, because
            // telling somebody a document is optional when it is not sends them
            // home from a counter.
            isOptional: entry['optional'] == true,
          ),
        );
      }
    }
    return List<ProgramRequirement>.unmodifiable(requirements);
  }
}
