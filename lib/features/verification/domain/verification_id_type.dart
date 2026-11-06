/// `VerificationSubmit.id_type`, in the order the contract publishes it.
///
/// The Node API accepts exactly these on `POST /me/verification-requests`.
/// Registration and the verification screen offer the same list.
const List<String> verificationIdTypes = <String>[
  'philid',
  'drivers_license',
  'passport',
  'umid',
  'postal',
  'voters',
  'sss',
  'other',
];

/// Resident label for `VerificationRequest.id_type`.
///
/// Known wire values get the name a resident would say. An unrecognised value
/// is shown as the server sent it, so a new code is visible rather than
/// relabelled.
String idTypeLabel(String? wire) {
  final String value = wire?.trim() ?? '';
  if (value.isEmpty) return '';
  return switch (value) {
    'philid' => 'PhilSys National ID',
    'drivers_license' => "Driver's license",
    'passport' => 'Passport',
    'umid' => 'UMID',
    'postal' => 'Postal ID',
    'voters' => "Voter's ID",
    'sss' => 'SSS',
    'other' => 'Other government ID',
    _ => value,
  };
}
