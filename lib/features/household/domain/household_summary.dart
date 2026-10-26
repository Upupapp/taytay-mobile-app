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

/// How one person is recorded in the household.
///
/// An unrecognised value is [other]. It is never promoted to [head].
enum HouseholdRelationship {
  head,
  spouse,
  child,
  parent,
  sibling,
  other;

  static HouseholdRelationship fromRaw(String? raw) => switch (raw?.trim()) {
    'head' => head,
    'spouse' => spouse,
    'child' => child,
    'parent' => parent,
    'sibling' => sibling,
    _ => other,
  };
}

/// Sex as the household record publishes it. Null when the server omitted it.
enum HouseholdSex {
  male,
  female,
  unspecified;

  static HouseholdSex? fromRaw(String? raw) => switch (raw?.trim()) {
    'male' => male,
    'female' => female,
    'unspecified' => unspecified,
    _ => null,
  };
}

/// Whether a member has been invited to an account.
enum HouseholdInviteStatus {
  none,
  pending,
  accepted;

  static HouseholdInviteStatus fromRaw(String? raw) => switch (raw?.trim()) {
    'pending' => pending,
    'accepted' => accepted,
    _ => none,
  };
}

/// One person on `GET /households/current`.
///
/// The screen shows the count, not this list. [toString] is redacted.
@immutable
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.inviteStatus,
    this.birthdate,
    this.sex,
    this.userId,
  });

  final String id;
  final String name;
  final HouseholdRelationship relationship;
  final DateTime? birthdate;
  final HouseholdSex? sex;
  final String? userId;
  final HouseholdInviteStatus inviteStatus;

  @override
  String toString() => 'HouseholdMember(${relationship.name})';
}

/// What a resident may be shown about their own household.
///
/// ---
///
/// ## What is deliberately absent, and why
///
/// **Names are decoded and not shown.** `GET /households/current` publishes
/// the members of the signed-in resident's own household. This type holds
/// them so the count matches the record. The screen shows [memberCount] and
/// never a [HouseholdMember.name]. [toString] on this type and on
/// [HouseholdMember] is redacted.
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
    this.members = const <HouseholdMember>[],
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

  /// How many people the decoded member list contains.
  ///
  /// The screen shows this count and not the names.
  final int? memberCount;

  /// People on the household record. The screen does not list [HouseholdMember.name].
  final List<HouseholdMember> members;

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
