/// Dates and times in the only timezone this app has to be right about.
///
/// ---
///
/// ## Why a fixed offset and not a timezone database
///
/// The Philippines observes **UTC+08:00 all year**. It has had no daylight
/// saving since 1978, and the offset has not changed since. So Manila wall time
/// is UTC plus eight hours, always — a rule that fits in one constant and cannot
/// drift, where a tz database is 400KB of install size, a dependency to keep
/// current, and a source of bugs when it is not.
///
/// If the Philippines ever reintroduces DST, [offset] is the single line that
/// changes, and every date in the app moves with it.
///
/// ## Why not just use the device clock
///
/// Because a phone can be set to any timezone, and often is: a resident on a
/// handset bought abroad, one whose automatic timezone is off, or an OFW reading
/// a Taytay event schedule from Dubai. Rendering "7:00 PM" in their local time
/// for an event happening in Taytay is worse than useless — they will arrive on
/// the wrong day.
///
/// So every LGU date and time is rendered in **Manila** time and **says so**.
/// The label is not decoration; it is what makes the number unambiguous.
abstract final class ManilaTime {
  /// Philippine Standard Time. Fixed, no DST.
  static const Duration offset = Duration(hours: 8);

  /// Short label shown beside a time so the reader knows which clock it is.
  static const String label = 'PHT';

  /// Converts an instant to Manila wall time.
  ///
  /// Takes any [DateTime] — the server sends UTC, but a local one converts
  /// correctly too, because [DateTime.toUtc] normalises first.
  static DateTime of(DateTime instant) => instant.toUtc().add(offset);

  static const List<String> _months = <String>[
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

  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Filipino month abbreviations, as CLDR's `fil` locale writes them
  /// (abbreviated, format context) — the same names Android and iOS print in
  /// their own date pickers on a phone set to Filipino.
  ///
  /// The **order** of day, month and year does not change with the language:
  /// only the words do. `05 Ago 2026` and `05 Aug 2026` are the same day, which
  /// is the property this class exists to keep (see [formatDate]).
  static const List<String> _monthsFil = <String>[
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

  /// Filipino weekday abbreviations, Monday first, as CLDR's `fil` locale
  /// writes them.
  static const List<String> _weekdaysFil = <String>[
    'Lun',
    'Mar',
    'Miy',
    'Huw',
    'Biy',
    'Sab',
    'Lin',
  ];

  /// Language code for which the month and weekday names are Filipino.
  /// Anything else reads English, the app's fallback (`AppLocales`).
  static const String filipinoLanguageCode = 'fil';

  static List<String> _monthsFor(String languageCode) =>
      languageCode == filipinoLanguageCode ? _monthsFil : _months;

  static List<String> _weekdaysFor(String languageCode) =>
      languageCode == filipinoLanguageCode ? _weekdaysFil : _weekdays;

  /// `05 Aug 2026`.
  ///
  /// Written out rather than numeric: `05/08/2026` is the fifth of August to a
  /// Filipino reader and the eighth of May to an American one, and a municipal
  /// schedule cannot afford that ambiguity.
  ///
  /// [languageCode] chooses only the month's **name** (`fil` gives `05 Ago
  /// 2026`); it defaults to English for callers with no `BuildContext`. A
  /// screen passes the reader's language through `manilaDate` in
  /// `core/l10n/core_copy.dart` rather than reading the device locale here.
  static String formatDate(DateTime instant, {String languageCode = 'en'}) {
    final manila = of(instant);
    final day = manila.day.toString().padLeft(2, '0');
    return '$day ${_monthsFor(languageCode)[manila.month - 1]} ${manila.year}';
  }

  /// `Wed 05 Aug 2026`.
  static String formatDateWithWeekday(
    DateTime instant, {
    String languageCode = 'en',
  }) {
    final manila = of(instant);
    return '${_weekdaysFor(languageCode)[manila.weekday - 1]} '
        '${formatDate(instant, languageCode: languageCode)}';
  }

  /// `7:00 PM`.
  ///
  /// 12-hour with AM/PM, which is how time is spoken and written in the
  /// Philippines. It takes no language: CLDR's `fil` writes `AM` and `PM` too,
  /// so a Filipino reader sees the same characters an English one does.
  static String formatTime(DateTime instant) {
    final manila = of(instant);
    final hour24 = manila.hour;
    final hour = switch (hour24) {
      0 => 12,
      final h when h > 12 => h - 12,
      final h => h,
    };
    final minute = manila.minute.toString().padLeft(2, '0');
    final meridiem = hour24 < 12 ? 'AM' : 'PM';
    return '$hour:$minute $meridiem';
  }

  /// `Wed 05 Aug 2026, 7:00 PM PHT`.
  static String formatDateTime(
    DateTime instant, {
    String languageCode = 'en',
  }) =>
      '${formatDateWithWeekday(instant, languageCode: languageCode)}, '
      '${formatTime(instant)} $label';

  /// A start and an end, collapsed when they fall on the same Manila day.
  ///
  /// `Wed 05 Aug 2026, 7:00 PM – 9:00 PM PHT` for one day;
  /// `Wed 05 Aug 2026, 7:00 PM – Thu 06 Aug 2026, 1:00 AM PHT` across midnight.
  /// An event that runs past midnight is exactly the case a collapsed range
  /// would misreport, so the day is repeated when it changes.
  static String formatRange(
    DateTime start,
    DateTime? end, {
    String languageCode = 'en',
  }) {
    if (end == null) return formatDateTime(start, languageCode: languageCode);

    final startManila = of(start);
    final endManila = of(end);
    final sameDay =
        startManila.year == endManila.year &&
        startManila.month == endManila.month &&
        startManila.day == endManila.day;

    final String startDay = formatDateWithWeekday(
      start,
      languageCode: languageCode,
    );
    if (sameDay) {
      return '$startDay, ${formatTime(start)} – ${formatTime(end)} $label';
    }
    return '$startDay, ${formatTime(start)} – '
        '${formatDateWithWeekday(end, languageCode: languageCode)}, '
        '${formatTime(end)} $label';
  }

  /// Whether [instant] is in the past relative to [now].
  ///
  /// Both are compared as instants, so the caller does not have to think about
  /// which clock either one is in.
  static bool isPast(DateTime instant, {DateTime? now}) =>
      instant.toUtc().isBefore((now ?? DateTime.now()).toUtc());
}
