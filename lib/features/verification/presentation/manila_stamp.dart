/// Stamps for the verification screens, in Philippine Standard Time.
///
/// The device clock is not the source. A UTC instant from `/me` or
/// `/me/verification-requests/current` is shown at UTC+8 so a capture host
/// set to UTC does not move the date.
DateTime manilaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

String formatManilaDate(DateTime instant) {
  final DateTime local = manilaTime(instant);
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String formatManilaStamp(DateTime instant) {
  final DateTime local = manilaTime(instant);
  final int hour = local.hour;
  final int h = hour % 12 == 0 ? 12 : hour % 12;
  final String suffix = hour < 12 ? 'AM' : 'PM';
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${formatManilaDate(instant)} · $h:$minute $suffix';
}

/// `VerificationSubmit.id_type`, in the order the contract publishes it.
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
