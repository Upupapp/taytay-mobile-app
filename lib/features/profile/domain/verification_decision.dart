import '../../../core/time/manila_time.dart';

/// Manila civil date for `verification_decided_at`.
///
/// The wire value is an instant. The account home shows the calendar date in
/// Asia/Manila, which does not observe daylight saving. Null stays null: a
/// missing decision is not painted as a date.
///
/// [languageCode] chooses only the month's **name** (`fil` gives `Ago 5,
/// 2026`), never the order, as `ManilaTime` does (D-237). A screen passes the
/// reader's language through `verificationDecisionDate` in
/// `core/l10n/profile_copy.dart`.
String? manilaDecisionDate(DateTime? instant, {String languageCode = 'en'}) {
  if (instant == null) return null;
  final DateTime manila = instant.toUtc().add(const Duration(hours: 8));
  return '${monthAbbreviation(manila.month, languageCode: languageCode)} '
      '${manila.day}, ${manila.year}';
}

/// A month's short name, `1` to `12`, in English or Filipino.
///
/// The Filipino names are CLDR's `fil` abbreviations, the same ones
/// `ManilaTime` prints, so a date reads alike on every screen.
String monthAbbreviation(int month, {String languageCode = 'en'}) =>
    (languageCode == ManilaTime.filipinoLanguageCode
    ? _monthsFil
    : _months)[month - 1];

const List<String> _months = <String>[
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

const List<String> _monthsFil = <String>[
  'Ene',
  'Peb',
  'Mar',
  'Abr',
  'May',
  'Hun',
  'Hul',
  'Ago',
  'Set',
  'Okt',
  'Nob',
  'Dis',
];
