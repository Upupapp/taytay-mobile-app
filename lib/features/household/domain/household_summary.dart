import 'package:flutter/foundation.dart';

/// The signed-in resident's own place in their household.
///
/// A closed set. The label a resident sees is fixed copy chosen by this enum,
/// never a server string rendered as-is, so a role nobody has reviewed cannot
/// appear on screen — and an unrecognised value degrades to [member] rather
/// than to something that sounds like authority.
enum HouseholdRole {
  /// The person the LGU records as answering for the household.
  head('Household head'),

  /// Anyone else recorded in it.
  member('Household member');

  const HouseholdRole(this.label);

  final String label;

  /// Fails closed: an unrecognised or absent role reads as [member].
  ///
  /// "Head of household" carries weight at a municipal counter — it is who the
  /// office speaks to and, in some programmes, who receives on behalf of
  /// everyone. Guessing it upward from an unknown string would tell a resident
  /// they hold a standing the LGU never gave them.
  static HouseholdRole fromRaw(String? raw) => switch (raw?.trim()) {
    'head' || 'household_head' => head,
    _ => member,
  };
}

/// What a resident may be shown about their own household.
///
/// ---
///
/// ## What is deliberately absent, and why
///
/// **There is no member list, and no type for one.** The committed
/// client-visibility matrix names `Household.members` explicitly among the
/// things a citizen never receives — *"Any other resident's data —
/// `Household.members`, another resident's `monthly_income` … Cross-resident
/// access is a critical defect"*. The same document grants a citizen
/// `household` membership *"own household only"*: they may know **that** they
/// belong to a household and see its address, not **who else** is in it.
///
/// So this type has no `List<HouseholdMember>` and there is no
/// `HouseholdMember` class in this app. The shape is the control: a member's
/// name cannot be rendered by a screen that has nowhere to read one from, and
/// adding that type later would have to be a deliberate act against a contract
/// change rather than an afternoon's feature work.
///
/// **There is no household identifier here either.** A registry id is not
/// useful to a resident, is never quoted at a counter, and its only effect on
/// screen is to invite someone to pass it around. Nothing in the app needs one,
/// because every read is `/me`-scoped and takes no argument.
///
/// **No vulnerability signals, in any form.** `sectors` — which is where
/// `vawc-survivor` and `cicl` live — is another resident's data for anybody but
/// the resident themselves, and the backend omits sensitive values server-side
/// rather than masking them. This type has no field for a sector, a score, a
/// flag or a case, so there is nothing here to suppress.
@immutable
class HouseholdSummary {
  const HouseholdSummary({
    required this.role,
    this.label,
    this.barangay,
    this.streetAddress,
    this.memberCount,
  });

  /// The signed-in resident's own role. Always known — it fails closed.
  final HouseholdRole role;

  /// A resident-facing name for the household, when the LGU publishes one.
  ///
  /// Not an identifier. If the server ever sends a registry number here it is
  /// dropped at the decoder, which reads only a human label.
  final String? label;

  /// The household's barangay — which is also the resident's own.
  final String? barangay;

  /// The household's street address, likewise the resident's own.
  final String? streetAddress;

  /// How many people the LGU records in the household.
  ///
  /// An aggregate, and the only thing this app will show *about* the others.
  /// A count says how large a household the office believes it is serving —
  /// which is exactly what a resident needs in order to notice that it is
  /// wrong — while naming nobody. It is shown only when the server supplies it;
  /// the app never derives it, because there is no list to derive it from.
  final int? memberCount;

  bool get hasAddress =>
      (barangay != null && barangay!.isNotEmpty) ||
      (streetAddress != null && streetAddress!.isNotEmpty);

  /// Redacted: an address and a household size are personal data about a
  /// specific family, and this is the object that reaches a crash report.
  @override
  String toString() => 'HouseholdSummary(role: ${role.name})';
}

/// What a resident can say is wrong with their household record.
///
/// ---
///
/// **A closed list, with no free-text field anywhere** (acceptance 3, and the
/// Master Command's instruction not to accept evidence the app cannot send).
///
/// A text box on a household screen invites a resident to type the very things
/// this app must never hold: a relative's medical condition, a reason someone
/// left, an allegation about another household. That text would then sit in
/// memory, in a crash report and in the OS task-switcher snapshot — for a
/// submission that, today, has nowhere to go at all.
///
/// A category is enough to route the resident to the right counter, which is
/// what the correction actually needs. The detail belongs to the conversation
/// with the person who can act on it.
///
/// **There is no category for moving a person between households.** Household
/// composition is a registry decision with eligibility consequences for two
/// households at once, and it is not something an app should let one member of
/// one of them initiate. No value here can express it, so no request can carry
/// it.
enum HouseholdCorrectionKind {
  addressWrong(
    'The address is wrong',
    'The street address or barangay Taytay LGU has for this household is not '
        'correct.',
  ),
  roleWrong(
    'My role in the household is wrong',
    'Taytay LGU records you differently from how the household actually works.',
  ),
  sizeWrong(
    'The number of people is wrong',
    'Someone is missing from the household record, or someone is listed who no '
        'longer lives here.',
  ),
  notMyHousehold(
    'This is not my household',
    'You have been recorded in a household you do not belong to.',
  ),
  somethingElse(
    'Something else is wrong',
    'You will be asked about it at the municipal hall.',
  );

  const HouseholdCorrectionKind(this.label, this.description);

  /// Resident-facing name. Fixed copy.
  final String label;

  /// One sentence saying what this covers, so a resident picks the right one
  /// without having to describe anything.
  final String description;
}

/// A correction a resident wants to raise about their own household.
///
/// ---
///
/// **This is a request to be looked at, never an edit.** It carries a category
/// and nothing else: no target value, no replacement address, no person, no
/// household identifier. It is structurally incapable of expressing "change X
/// to Y", so no server that receives it — today or later — could interpret it as
/// an instruction to rewrite canonical membership (acceptance 3).
@immutable
class HouseholdCorrectionRequest {
  const HouseholdCorrectionRequest({required this.kind});

  final HouseholdCorrectionKind kind;

  /// Safe to log: a category is not personal data, and knowing which kind of
  /// correction was raised is exactly what support would need.
  @override
  String toString() => 'HouseholdCorrectionRequest(${kind.name})';
}
