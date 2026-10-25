/// Manila civil date for `verification_decided_at`.
///
/// The wire value is an instant. The account home shows the calendar date in
/// Asia/Manila, which does not observe daylight saving. Null stays null: a
/// missing decision is not painted as a date.
String? manilaDecisionDate(DateTime? instant) {
  if (instant == null) return null;
  final DateTime manila = instant.toUtc().add(const Duration(hours: 8));
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
  return '${months[manila.month - 1]} ${manila.day}, ${manila.year}';
}
