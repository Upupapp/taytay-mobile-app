import 'package:flutter/foundation.dart';

/// One eligibility criterion, as the LGU publishes it.
///
/// ---
///
/// **Text, never a rule the app can run.** The criterion arrives as a sentence
/// the office wrote — "60 years old and above", "household income below ₱12,000
/// a month" — and this app renders it. There is no operator, no threshold and no
/// value to compare a resident against, because the type has nowhere to put one.
///
/// That is deliberate and it is acceptance 2. An app that evaluated eligibility
/// locally would be a second rule set: it would drift from the office's the
/// moment either changed, it would be wrong in a released build nobody can patch
/// quickly, and — worst — it would tell a resident they do not qualify for a
/// benefit they are entitled to, at which point they stop asking.
///
/// The visibility matrix is explicit that publishing the criteria is the point:
/// *"Eligibility rules are deliberately public. Publishing the criteria for a
/// public benefit is good administration, and it lets a citizen self-screen
/// instead of queueing to be refused."* Self-screen — by reading, and deciding
/// for themselves.
@immutable
class EligibilityCriterion {
  const EligibilityCriterion({required this.text, this.category});

  /// The office's own words. Rendered as sent.
  final String text;

  /// An optional grouping label the server supplied, e.g. "Age" or "Residency".
  /// Presentation only.
  final String? category;

  @override
  String toString() => 'EligibilityCriterion(${category ?? 'general'})';
}

/// A document or condition an applicant is asked to bring.
@immutable
class ProgramRequirement {
  const ProgramRequirement({required this.text, this.isOptional = false});

  final String text;

  /// True only when the server said so. Never inferred.
  final bool isOptional;

  @override
  String toString() => 'ProgramRequirement(optional: $isOptional)';
}

/// A social-welfare programme, in the projection a citizen is entitled to.
///
/// ---
///
/// **Every field here appears in the committed client-visibility matrix's
/// citizen column** (§5 Program): code, name, category, description, status,
/// `legal_basis`, `maximum_grant`, eligibility, requirements, and the effective
/// dates. Two fields in that table are marked ⛔ for a citizen — `funding_source`
/// and `audit` — and this type has no property for either.
///
/// **Status is `active` only.** The citizen row in the endpoint matrix is
/// `GET /api/v1/programs?status=active` with a *"narrowed projection"*. A
/// resident is never shown a draft, a suspended or a retired programme, so this
/// app does not model those states and cannot render one.
///
/// **No capacity, no ranking, no queue position.** None of it is in the citizen
/// projection, and none of it has a field here. A remaining-slots figure on a
/// municipal benefit is the fastest way to start a queue at 4am for something
/// that was never first-come-first-served.
@immutable
class AssistanceProgram {
  const AssistanceProgram({
    required this.code,
    required this.name,
    required this.description,
    this.category,
    this.legalBasis,
    this.maximumGrant,
    this.eligibility = const <EligibilityCriterion>[],
    this.requirements = const <ProgramRequirement>[],
    this.effectiveFrom,
    this.effectiveTo,
    this.owningOffice,
    this.contact,
    this.applicationChannel,
  });

  /// Stable machine code, e.g. `AICS`. The deep-link identifier — see
  /// `ProgramDto`. Never the registry UUID.
  final String code;

  final String name;
  final String description;

  /// The server's own label. Rendered as sent; the app takes no decision from
  /// it, so an unrecognised category displays rather than disappearing.
  final String? category;

  /// The ordinance or statute the benefit rests on. *"A citizen is entitled to
  /// know the basis of a benefit."*
  final String? legalBasis;

  /// The ceiling the office publishes, as text — "up to ₱10,000".
  ///
  /// A string rather than a number, because the app must not do arithmetic with
  /// it. Rendering "you could receive ₱10,000" from a maximum is a promise, and
  /// the amount is a case-by-case decision.
  final String? maximumGrant;

  final List<EligibilityCriterion> eligibility;
  final List<ProgramRequirement> requirements;

  /// The window the office published, as text. Absent means "no window stated",
  /// which is not the same as "open" — see [availabilityNote].
  final String? effectiveFrom;
  final String? effectiveTo;

  /// The Taytay office that runs it.
  final String? owningOffice;

  /// How to reach that office. A public office contact, never a person's.
  final String? contact;

  /// How the office says to apply — "at the municipal hall", "through your
  /// barangay". Text, because the app has no submission endpoint to offer.
  final String? applicationChannel;

  bool get hasEligibility => eligibility.isNotEmpty;
  bool get hasRequirements => requirements.isNotEmpty;

  /// What to say about timing, without inventing a state.
  ///
  /// The app never computes "open" or "closed" from the dates. A window that has
  /// passed on the resident's phone clock may still be open at the counter — an
  /// office extends a deadline far more often than it publishes the extension
  /// the same afternoon — and an app that says "closed" sends somebody away from
  /// help they could still have got.
  String? get availabilityNote {
    final from = effectiveFrom;
    final to = effectiveTo;
    if (from == null && to == null) return null;
    if (from != null && to != null) {
      return 'Taytay LGU lists this for $from to $to.';
    }
    if (from != null) return 'Taytay LGU lists this from $from.';
    return 'Taytay LGU lists this until $to.';
  }

  /// Public reference data — safe to log, and useful when it is.
  @override
  String toString() => 'AssistanceProgram($code)';
}
