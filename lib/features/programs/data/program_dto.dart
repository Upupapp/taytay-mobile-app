import '../domain/assistance_program.dart';

/// Decodes a programme by naming the fields the **citizen projection** sends.
///
/// ---
///
/// **Re-derived at `backend@api-baseline-2026-08` from `ProgramController`'s own
/// `citizenProjection()` and `citizenDetail()`.** The previous allow-list was a
/// transcription of a visibility matrix the server no longer follows; see
/// [AssistanceProgram] for what that would have rendered.
///
/// **The allow-list is not the defence — the deny-list is, and it is kept.** An
/// allow-list only decides what is read; a field absent from it is ignored
/// anyway, because conventions §1 requires clients to tolerate unknown keys. The
/// deny-list exists for a different reason: it makes a server change that
/// *widened* the citizen projection fail here, loudly, instead of quietly
/// rendering budget lines or applicant names on a resident's phone. It has been
/// re-checked against the staff projection at this baseline, so every key the
/// server holds back is named.
abstract final class ProgramDto {
  static const String idKey = 'id';
  static const String codeKey = 'code';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String ownerOfficeKey = 'owner_office';
  static const String targetPopulationKey = 'target_population';
  static const String benefitTypeKey = 'benefit_type';
  static const String acceptsApplicationsKey = 'accepts_applications';
  static const String applicationsCloseAtKey = 'applications_close_at';
  static const String decidedByKey = 'decided_by';
  static const String turnaroundTargetDaysKey = 'turnaround_target_days';
  static const String requirementsKey = 'requirements';
  static const String conditionsKey = 'conditions';

  static const Set<String> allowedKeys = <String>{
    idKey,
    codeKey,
    nameKey,
    descriptionKey,
    ownerOfficeKey,
    targetPopulationKey,
    benefitTypeKey,
    acceptsApplicationsKey,
    applicationsCloseAtKey,
    decidedByKey,
    turnaroundTargetDaysKey,
    requirementsKey,
    conditionsKey,
  };

  /// What must never reach a resident, in five groups.
  ///
  /// * **Held back by the staff projection** — `status`, `is_citizen_visible`,
  ///   `authority`, `funding_source_label`, `active_from`, `active_to`,
  ///   `eligibility_guidance_version`. These are the exact keys
  ///   `staffProjection()` adds on top of the citizen one at this baseline, so
  ///   this group is a mirror of the server's own line and goes stale only when
  ///   that line moves.
  /// * **Budget and audit** — `funding_source`, `audit`, `created_by`,
  ///   `updated_by`. Budget-line information is meaningless and misleading to an
  ///   applicant.
  /// * **Operational capacity** — `slots_remaining`, `quota`, `capacity`,
  ///   `budget_remaining`, `beneficiary_count`. A remaining-slots figure on a
  ///   municipal benefit is the fastest way to start a queue at 4am for
  ///   something that was never first-come-first-served.
  /// * **Ranking and scoring** — `priority_score`, `ranking`, `weight`,
  ///   `eligibility_rules`, `vulnerability_score`. A machine-readable rule set is
  ///   precisely what would let this app compute a verdict, and ADR 0018 §3 says
  ///   the guidance advises and never decides.
  /// * **Draft and other people** — `internal_notes`, `remarks`, `draft`,
  ///   `applicants`, `beneficiaries`.
  static const Set<String> forbiddenKeys = <String>{
    'status',
    'is_citizen_visible',
    'authority',
    'funding_source_label',
    'active_from',
    'active_to',
    'eligibility_guidance_version',
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
    'vulnerability_score',
    'internal_notes',
    'remarks',
    'draft',
    'applicants',
    'beneficiaries',
  };

  /// Decodes one programme, or `null` when it is not one a resident can act on.
  ///
  /// Returns `null` rather than a half-built object when the id, code or name is
  /// missing. A nameless entry in a list of public benefits is not degraded
  /// data — it is a row a resident cannot do anything with, and showing it is
  /// worse than showing a shorter list.
  static AssistanceProgram? decode(Object? payload) {
    if (payload is! Map<String, dynamic>) return null;

    final String? id = _stringOf(payload, idKey);
    final String? code = _stringOf(payload, codeKey);
    final String? name = _stringOf(payload, nameKey);
    if (id == null || code == null || name == null) return null;

    return AssistanceProgram(
      id: id,
      code: code,
      name: name,
      description: _stringOf(payload, descriptionKey) ?? '',
      ownerOffice: _stringOf(payload, ownerOfficeKey),
      targetPopulation: _stringOf(payload, targetPopulationKey),
      benefitType: _stringOf(payload, benefitTypeKey),
      // Absent reads as CLOSED. The alternative sends somebody to a municipal
      // office for a programme that is not taking applications, and the journey
      // is the expensive half of a wrong answer here.
      acceptsApplications: payload[acceptsApplicationsKey] == true,
      applicationsCloseAt: DateTime.tryParse(
        _stringOf(payload, applicationsCloseAtKey) ?? '',
      )?.toUtc(),
      decidedBy: _stringOf(payload, decidedByKey),
      turnaroundTargetDays: _intOf(payload, turnaroundTargetDaysKey),
      requirements: _requirementsOf(payload),
      conditions: _conditionsOf(payload),
    );
  }

  /// Every programme in a page, dropping the ones that cannot be rendered.
  static List<AssistanceProgram> decodeAll(Object? payload) {
    if (payload is! List<dynamic>) return const <AssistanceProgram>[];
    return payload
        .map(ProgramDto.decode)
        .whereType<AssistanceProgram>()
        .toList(growable: false);
  }

  static List<ProgramRequirement> _requirementsOf(
    Map<String, dynamic> payload,
  ) {
    final Object? raw = payload[requirementsKey];
    if (raw is! List<dynamic>) return const <ProgramRequirement>[];

    final List<ProgramRequirement> requirements = <ProgramRequirement>[];
    for (final Object? entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final String? code = _stringOf(entry, 'code');
      final String? label = _stringOf(entry, 'label');
      // A requirement with no label cannot be brought to an office.
      if (code == null || label == null) continue;

      final Object? accepted = entry['accepted_documents'];
      requirements.add(
        ProgramRequirement(
          code: code,
          label: label,
          obligation: RequirementObligation.parse(
            _stringOf(entry, 'obligation'),
          ),
          conditionNote: _stringOf(entry, 'condition_note'),
          instructions: _stringOf(entry, 'instructions'),
          acceptedDocuments: accepted is List<dynamic>
              ? accepted.whereType<String>().toList(growable: false)
              : const <String>[],
        ),
      );
    }
    return List<ProgramRequirement>.unmodifiable(requirements);
  }

  /// `conditions` is a list of plain sentences. Anything else — an object with a
  /// comparator, a threshold, a boolean verdict — is dropped rather than
  /// modelled, because the moment this app can read a rule it can be asked to
  /// apply one.
  static List<EligibilityCondition> _conditionsOf(
    Map<String, dynamic> payload,
  ) {
    final Object? raw = payload[conditionsKey];
    if (raw is! List<dynamic>) return const <EligibilityCondition>[];
    return List<EligibilityCondition>.unmodifiable(
      raw
          .whereType<String>()
          .where((String text) => text.trim().isNotEmpty)
          .map(EligibilityCondition.new),
    );
  }

  static String? _stringOf(Map<String, dynamic> payload, String key) {
    final Object? value = payload[key];
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _intOf(Map<String, dynamic> payload, String key) {
    final Object? value = payload[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
