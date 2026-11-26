import '../../../l10n/app_localizations.dart';

/// Stamps for the verification screens, in Philippine Standard Time.
///
/// The device clock is not the source. A UTC instant from `/me` or
/// `/me/verification-requests/current` is shown at UTC+8 so a capture host
/// set to UTC does not move the date.
///
/// Pass the screen's [AppStrings] and the month is named in the resident's
/// language (`verifDate`, an ICU date of the `yMMMd` shape: "Oct 22, 2026" in
/// English, "Okt 22, 2026" in Filipino). Without them the stamp is the
/// English one it always was, which tests and captures compare against.
DateTime manilaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

String formatManilaDate(DateTime instant, [AppStrings? strings]) {
  final DateTime local = manilaTime(instant);
  if (strings != null) return strings.verifDate(local);
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

String formatManilaStamp(DateTime instant, [AppStrings? strings]) {
  final DateTime local = manilaTime(instant);
  final int hour = local.hour;
  final int h = hour % 12 == 0 ? 12 : hour % 12;
  final String suffix = hour < 12 ? 'AM' : 'PM';
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${formatManilaDate(instant, strings)} · $h:$minute $suffix';
}
