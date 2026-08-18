import 'package:flutter/foundation.dart';

/// One eligibility condition, **in words**.
///
/// ---
///
/// **There is no comparator, no threshold and no blocking flag here, and that is
/// the backend's decision rather than an omission.** Publishing the exact
/// numbers would turn an assistance programme into a form to be gamed, and the
/// people who would game it successfully are not the ones it exists for. The
/// server sends `conditions` as plain sentences and nothing else.
///
/// So this app cannot compute whether a resident qualifies even if somebody
/// later wanted it to — which is the point. ADR 0018 §3 is explicit that
/// eligibility guidance **advises and never decides**, and an app that rendered
/// "you qualify" would have invented an authority the platform deliberately
/// refused to create.
@immutable
class EligibilityCondition {
  const EligibilityCondition(this.explanation);

  /// The office's own words, addressed to a resident.
  final String explanation;
}

/// Whether a document is always needed, or only in some circumstances.
enum RequirementObligation {
  required('required'),
  conditional('conditional'),
  optional('optional');

  const RequirementObligation(this.wireValue);

  final String wireValue;

  /// Unrecognised obligations read as [required].
  ///
  /// Fails **towards** the resident bringing the document. Being told to bring
  /// something that turns out to be unnecessary costs a photocopy; being told it
  /// was optional and arriving without it costs the trip.
  static RequirementObligation parse(String? value) {
    for (final RequirementObligation o in RequirementObligation.values) {
      if (o.wireValue == value) return o;
    }
    return RequirementObligation.required;
  }
}

/// A document the office asks for.
@immutable
class ProgramRequirement {
  const ProgramRequirement({
    required this.code,
    required this.label,
    required this.obligation,
    this.conditionNote,
    this.instructions,
    this.acceptedDocuments = const <String>[],
  });

  final String code;
  final String label;
  final RequirementObligation obligation;

  /// When a conditional requirement applies. Meaningless without
  /// [RequirementObligation.conditional] and rendered only alongside it.
  final String? conditionNote;

  /// The office's instructions for obtaining or preparing it.
  final String? instructions;

  /// Document types the office will accept for this requirement.
  final List<String> acceptedDocuments;
}

/// A social-welfare programme as a **resident** may see it.
///
/// ---
///
/// **Re-modelled at `backend@api-baseline-2026-08` against the projection the
/// server actually sends.** The previous shape was transcribed from a
/// "visibility matrix §5" that no longer describes anything. It expected
/// `status`, `legal_basis`, `maximum_grant`, `category`, `effective_from`,
/// `effective_to`, `contact` and `application_channel`; the citizen projection
/// sends none of them, spells the office `owner_office` rather than
/// `owning_office`, and shapes a requirement as `{code, label, obligation, …}`
/// rather than `{text, optional}`.
///
/// **The failure that would have produced is the quiet kind.** Nothing throws —
/// unknown fields are ignored by design, and the old status guard let an absent
/// `status` through — so every programme would have decoded successfully with a
/// name, a code, a description, and every other field null. A screen showing
/// municipal benefits with no office, no requirements and no conditions reads as
/// a thin catalogue rather than as a broken decoder, and nothing anywhere would
/// have said which it was.
///
/// That is why TAB 07 was not the same-day win it looked like, and it is exactly
/// the class of defect the TAB 01 harness exists to surface before thirteen more
/// repositories are written on the same assumption.
///
/// **One controller, two audiences, and this is the smaller one.** The server
/// decides what a caller sees from their resolved permissions, never from which
/// URL they used. A resident's projection carries no `status`, no
/// `is_citizen_visible`, no `funding_source_label` and no guidance version — so
/// there is nowhere for any of it to land here.
@immutable
class AssistanceProgram {
  const AssistanceProgram({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.acceptsApplications,
    this.ownerOffice,
    this.targetPopulation,
    this.benefitType,
    this.applicationsCloseAt,
    this.decidedBy,
    this.turnaroundTargetDays,
    this.requirements = const <ProgramRequirement>[],
    this.conditions = const <EligibilityCondition>[],
  });

  /// Server-issued UUID. **This, not [code], addresses `programs/{program}`** —
  /// the server resolves the path segment by UUID.
  final String id;

  /// The stable human-facing code the office quotes at a counter.
  final String code;

  final String name;
  final String description;

  /// Which office owns it — where a resident actually goes.
  final String? ownerOffice;

  /// Who it is for, in the office's words.
  final String? targetPopulation;

  /// What kind of help it is. Never an amount: the server publishes no figure,
  /// because a number on a screen is a promise the caseworker has to keep.
  final String? benefitType;

  /// Whether the office is taking applications **right now**, as the server
  /// computed it at the moment it answered.
  ///
  /// Not derived from [applicationsCloseAt] here. A closing date and an open
  /// window are two facts, the server holds both, and a client that recomputed
  /// one from the other would eventually disagree with the office about whether
  /// a resident may still apply.
  final bool acceptsApplications;

  final DateTime? applicationsCloseAt;

  /// Who decides the outcome: `lgu`, or the name of the national authority.
  ///
  /// Published deliberately, and worth rendering plainly: an applicant deciding
  /// whether to travel to a municipal office deserves to know when the LGU does
  /// not control the answer.
  final String? decidedBy;

  /// The office's own target, in days. A target, never a promise.
  final int? turnaroundTargetDays;

  final List<ProgramRequirement> requirements;

  /// Conditions in words. See [EligibilityCondition] — advice, never a verdict.
  final List<EligibilityCondition> conditions;

  /// True when the LGU itself decides, rather than a national authority.
  bool get isLocallyDecided => decidedBy == 'lgu';

  bool get hasConditions => conditions.isNotEmpty;
  bool get hasRequirements => requirements.isNotEmpty;

  /// Whether a resident can still apply, and until when — as one sentence.
  ///
  /// Reads [acceptsApplications] first and only then the date, because the two
  /// can disagree: a programme can be paused with its published closing date
  /// still in the future, and the server's answer is the one that decides
  /// whether somebody should make the trip.
  String get availabilityNote {
    final DateTime? closes = applicationsCloseAt;
    if (!acceptsApplications) {
      return closes == null
          ? 'Not accepting applications right now'
          : 'Closed to new applications';
    }
    if (closes == null) return 'Accepting applications';
    return 'Accepting applications until ${_manilaDate(closes)}';
  }

  /// Manila wall time. An office's closing date is a date in Taytay, not on the
  /// device — a resident whose phone is set to another timezone must not read a
  /// deadline a day out.
  static String _manilaDate(DateTime utc) {
    final DateTime manila = utc.toUtc().add(const Duration(hours: 8));
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${manila.day} ${months[manila.month - 1]} ${manila.year}';
  }
}
