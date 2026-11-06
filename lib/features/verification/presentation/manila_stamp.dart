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
