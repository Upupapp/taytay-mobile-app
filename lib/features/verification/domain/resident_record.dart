import 'package:flutter/foundation.dart';

import 'field_correction_note.dart';

/// The resident's own profile, held by the screen that fetched it.
///
/// This is not session state. A session keeps an account id, a greeting name
/// and an access level. Everything here — name, address, household size — is
/// loaded when the profile wizard opens and dropped when that screen goes.
@immutable
class ResidentRecord {
  const ResidentRecord({
    this.givenName = '',
    this.middleName = '',
    this.familyName = '',
    this.suffix = '',
    this.sex = '',
    this.birthdate = '',
    this.civilStatus = '',
    this.mobile = '',
    this.email = '',
    this.mobileVerified = false,
    this.barangayId = '',
    this.barangayName = '',
    this.street = '',
    this.purok = '',
    this.municipality = 'Taytay',
    this.province = 'Rizal',
    this.yearsAtAddress = '',
    this.memberCount = '',
    this.residenceType = '',
    this.verificationTier = '',
    this.rejectionReason = '',
    this.fieldNotes = const <FieldCorrectionNote>[],
    this.completeness = 0,
    this.personalComplete = false,
    this.householdStarted = false,
  });

  final String givenName;
  final String middleName;
  final String familyName;
  final String suffix;
  final String sex;
  final String birthdate;
  final String civilStatus;
  final String mobile;
  final String email;
  final bool mobileVerified;
  final String barangayId;
  final String barangayName;
  final String street;
  final String purok;
  final String municipality;
  final String province;

  /// Not on `ProfilePatch` or `HouseholdWrite`. The dev mock remembers it.
  /// A live save does not send it.
  final String yearsAtAddress;

  /// An aggregate. Never a list of names.
  final String memberCount;

  /// Not on the published write schemas. Dev mock only.
  final String residenceType;

  final String verificationTier;
  final String rejectionReason;
  final List<FieldCorrectionNote> fieldNotes;

  /// 0–100, as the overview card draws it. Computed by the repository from
  /// how many sections have something in them, not stored on the session.
  final int completeness;
  final bool personalComplete;
  final bool householdStarted;

  String get displayName {
    final parts = <String>[
      givenName,
      middleName,
      familyName,
      suffix,
    ].where((String part) => part.trim().isNotEmpty);
    return parts.join(' ');
  }

  String get addressLine {
    final streetLine = <String>[
      street,
      if (purok.isNotEmpty) 'Purok $purok',
    ].where((String part) => part.isNotEmpty).join(', ');
    final place = <String>[
      if (barangayName.isNotEmpty) 'Brgy. $barangayName',
      municipality,
      province,
    ].where((String part) => part.isNotEmpty).join(', ');
    if (streetLine.isEmpty) return place;
    if (place.isEmpty) return streetLine;
    return '$streetLine, $place';
  }

  /// Redacted. A crash report must not carry a name or an address.
  @override
  String toString() => 'ResidentRecord(completeness: $completeness)';
}

/// What the personal-info step is allowed to save.
@immutable
class PersonalDraft {
  const PersonalDraft({
    required this.givenName,
    required this.middleName,
    required this.familyName,
    required this.suffix,
    required this.sex,
    required this.birthdate,
    required this.civilStatus,
    required this.mobile,
    required this.email,
  });

  final String givenName;
  final String middleName;
  final String familyName;
  final String suffix;
  final String sex;
  final String birthdate;
  final String civilStatus;
  final String mobile;
  final String email;

  @override
  String toString() => 'PersonalDraft';
}

/// What the household step is allowed to save.
@immutable
class HouseholdDraft {
  const HouseholdDraft({
    required this.barangayId,
    required this.barangayName,
    required this.street,
    required this.purok,
    required this.yearsAtAddress,
    required this.memberCount,
    required this.residenceType,
  });

  final String barangayId;
  final String barangayName;
  final String street;
  final String purok;
  final String yearsAtAddress;
  final String memberCount;
  final String residenceType;

  @override
  String toString() => 'HouseholdDraft';
}
