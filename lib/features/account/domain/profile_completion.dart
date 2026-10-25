import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';

/// How many of the resident's own `GET /me` columns are filled.
///
/// The API does not publish a figure. The ten columns a resident can fill are
/// name, birthdate, sex, mobile, email, barangay, street, the free-text
/// address, purok, and an avatar. Columns the server always sends are left out.
int profileCompletionPercent(ResidentProfileDetail detail) {
  const int slots = 10;
  final int filled = <bool>[
    detail.has(ResidentProfileField.fullName),
    detail.has(ResidentProfileField.birthDate),
    detail.has(ResidentProfileField.sex),
    detail.has(ResidentProfileField.mobileNumber),
    detail.has(ResidentProfileField.emailAddress),
    detail.has(ResidentProfileField.barangay),
    detail.hasStreetLine,
    detail.hasFreeAddress,
    detail.has(ResidentProfileField.purokOrSitio),
    detail.hasAvatar,
  ].where((bool bit) => bit).length;
  return ((filled * 100) / slots).round();
}
