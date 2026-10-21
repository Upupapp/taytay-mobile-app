import 'package:flutter/foundation.dart';

import 'household_summary.dart';

/// The caller's place in their household. `viewer_role` on `Household`.
///
/// An unrecognised value is [member]. Headship is a standing the LGU records,
/// and an unknown string does not grant it.
enum HouseholdViewerRole {
  head,
  member;

  static HouseholdViewerRole fromWire(String? raw) => switch (raw) {
    'head' => head,
    _ => member,
  };
}

/// `HouseholdMember.relationship`.
///
/// An unrecognised value is [other], never [head].
enum HouseholdRelationship {
  head,
  spouse,
  child,
  parent,
  sibling,
  other;

  static HouseholdRelationship fromWire(String? raw) => switch (raw) {
    'head' => head,
    'spouse' => spouse,
    'child' => child,
    'parent' => parent,
    'sibling' => sibling,
    _ => other,
  };
}

/// Relationship a resident may assign when adding or editing a member.
///
/// Headship moves through transfer, not through this list.
enum HouseholdMemberRelationship {
  spouse,
  child,
  parent,
  sibling,
  other;

  String get wireValue => name;
}

/// `HouseholdMember.sex`. Null when the server omits it or sends an unknown.
enum HouseholdSex {
  male,
  female,
  unspecified;

  static HouseholdSex? fromWire(String? raw) => switch (raw) {
    'male' => male,
    'female' => female,
    'unspecified' => unspecified,
    _ => null,
  };

  String get wireValue => name;
}

/// `HouseholdMember.invite_status`. Unknown degrades to [none].
enum HouseholdInviteStatus {
  none,
  pending,
  accepted;

  static HouseholdInviteStatus fromWire(String? raw) => switch (raw) {
    'pending' => pending,
    'accepted' => accepted,
    _ => none,
  };
}

/// One person on the caller's own household.
///
/// The contract returns this list on `GET /households/current`. Names and
/// birth dates stay off [toString].
@immutable
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.birthdate,
    required this.sex,
    required this.userId,
    required this.inviteStatus,
  });

  final String id;
  final String name;
  final HouseholdRelationship relationship;

  /// Server date `YYYY-MM-DD`, or null. Not parsed into a local calendar.
  final String? birthdate;
  final HouseholdSex? sex;
  final String? userId;
  final HouseholdInviteStatus inviteStatus;

  @override
  String toString() => 'HouseholdMember(${relationship.name})';
}

/// The caller's household, as `Household` publishes it.
@immutable
class HouseholdRecord {
  const HouseholdRecord({
    required this.id,
    required this.address,
    required this.barangayId,
    required this.barangayName,
    required this.headUserId,
    required this.viewerRole,
    required this.createdAt,
    required this.members,
  });

  final String id;
  final String address;
  final String barangayId;
  final String barangayName;
  final String headUserId;
  final HouseholdViewerRole viewerRole;
  final DateTime createdAt;
  final List<HouseholdMember> members;

  /// The existing screen's shape: role, address, and a count. No names.
  HouseholdSummary toSummary() => HouseholdSummary(
    role: viewerRole == HouseholdViewerRole.head
        ? HouseholdRole.head
        : HouseholdRole.member,
    barangay: barangayName.trim().isEmpty ? null : barangayName.trim(),
    streetAddress: address.trim().isEmpty ? null : address.trim(),
    memberCount: members.length,
  );

  @override
  String toString() => 'HouseholdRecord(${viewerRole.name})';
}

/// A person to add with `POST /households/current/members`.
@immutable
class HouseholdMemberDraft {
  const HouseholdMemberDraft({
    required this.name,
    required this.relationship,
    this.birthdate,
    this.sex,
    this.userId,
  });

  final String name;
  final HouseholdMemberRelationship relationship;
  final String? birthdate;
  final HouseholdSex? sex;
  final String? userId;

  @override
  String toString() => 'HouseholdMemberDraft(${relationship.name})';
}

/// A partial edit. Null fields are left as they are and are not sent.
@immutable
class HouseholdMemberChange {
  const HouseholdMemberChange({
    this.name,
    this.relationship,
    this.birthdate,
    this.sex,
  });

  final String? name;
  final HouseholdMemberRelationship? relationship;
  final String? birthdate;
  final HouseholdSex? sex;

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      relationship == null &&
      (birthdate == null || birthdate!.trim().isEmpty) &&
      sex == null;

  @override
  String toString() => 'HouseholdMemberChange()';
}

/// `GET /households/invitations/current`.
@immutable
class HouseholdInvitation {
  const HouseholdInvitation({
    required this.id,
    required this.householdId,
    required this.address,
    required this.barangayId,
    required this.barangayName,
  });

  final String id;
  final String householdId;
  final String address;
  final String barangayId;
  final String barangayName;

  @override
  String toString() => 'HouseholdInvitation()';
}
