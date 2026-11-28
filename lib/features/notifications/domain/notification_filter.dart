import 'package:flutter/foundation.dart';

import '../../../core/time/manila_time.dart';
import 'notification_repository.dart';

/// How far back the inbox's When filter reaches (D-238).
///
/// ---
///
/// **Days are Manila's** (D-107). "Today" and "On a date" are the Manila
/// calendar day, as the inbox's own Today heading is, so a phone set to
/// another zone never files a notice the office sent this morning under
/// yesterday. "Last 7 days" and "Last 30 days" are that many days back from
/// now, as the console's are (DL-291).
///
/// It has no English label of its own: the screen names each period from the
/// resident's language, so there is no constant a screen could render raw.
enum NotificationPeriod {
  anyTime,
  today,
  lastWeek,
  lastMonth,

  /// One Manila calendar day the resident picks, [NotificationFilter.day].
  onDay,
}

/// What a notice is about, as the Category filter offers it: one of the
/// categories this build knows, or [NoticeKind.other] for a notice whose type
/// it does not, which the inbox draws as "Update".
@immutable
final class NoticeKind {
  const NoticeKind(NotificationCategory this.category);

  /// A notice whose category this build does not know.
  const NoticeKind.other() : category = null;

  /// The kind of [notice].
  factory NoticeKind.of(ResidentNotification notice) {
    final NotificationCategory? category = notice.category?.known;
    return category == null ? const NoticeKind.other() : NoticeKind(category);
  }

  /// Null for [NoticeKind.other].
  final NotificationCategory? category;

  bool get isOther => category == null;

  @override
  bool operator ==(Object other) =>
      other is NoticeKind && other.category == category;

  @override
  int get hashCode => category.hashCode;

  @override
  String toString() => 'NoticeKind(${category?.name ?? 'other'})';
}

/// A kind the inbox holds, and how many of its notices it holds.
@immutable
final class NoticeKindCount {
  const NoticeKindCount({required this.kind, required this.count});

  final NoticeKind kind;
  final int count;

  @override
  String toString() => 'NoticeKindCount($kind, $count)';
}

/// What the resident has narrowed her inbox to (D-238).
///
/// ---
///
/// **A view over what is loaded, and nothing is sent.** `GET notifications`
/// takes a page size and a cursor and nothing else, so every filter here reads
/// only notices already in the app. It decides what is *shown*, never what she
/// may read.
///
/// **All / Unread is its own control.** [isNarrowed] and [cleared] cover the
/// Category, When and search filters only, as the console's Clear filters does
/// (DL-292): the All / Unread chips sit above them and say their own state.
@immutable
final class NotificationFilter {
  const NotificationFilter({
    this.unreadOnly = false,
    this.kind,
    this.period = NotificationPeriod.anyTime,
    this.day,
    this.words = '',
  });

  /// Everything, read or not.
  static const NotificationFilter none = NotificationFilter();

  final bool unreadOnly;

  /// The chosen kind; null is every kind.
  final NoticeKind? kind;

  final NotificationPeriod period;

  /// The Manila calendar day [NotificationPeriod.onDay] means, as
  /// `DateTime.utc(year, month, day)`. Read only for that period.
  final DateTime? day;

  /// Words to find in a notice's title or body, in any case. Blank finds
  /// everything.
  final String words;

  /// Whether Category, When or a search narrows the list.
  bool get isNarrowed =>
      kind != null ||
      period != NotificationPeriod.anyTime ||
      words.trim().isNotEmpty;

  NotificationFilter withUnreadOnly(bool unreadOnly) => NotificationFilter(
    unreadOnly: unreadOnly,
    kind: kind,
    period: period,
    day: day,
    words: words,
  );

  /// [kind] null shows every kind.
  NotificationFilter withKind(NoticeKind? kind) => NotificationFilter(
    unreadOnly: unreadOnly,
    kind: kind,
    period: period,
    day: day,
    words: words,
  );

  /// [day] is kept only for [NotificationPeriod.onDay]; any other period lets
  /// a picked day go.
  NotificationFilter withPeriod(NotificationPeriod period, {DateTime? day}) =>
      NotificationFilter(
        unreadOnly: unreadOnly,
        kind: kind,
        period: period,
        day: period == NotificationPeriod.onDay && day != null
            ? manilaDayOf(day)
            : null,
        words: words,
      );

  NotificationFilter withWords(String words) => NotificationFilter(
    unreadOnly: unreadOnly,
    kind: kind,
    period: period,
    day: day,
    words: words,
  );

  /// Category, When and search cleared; All / Unread kept.
  NotificationFilter cleared() => NotificationFilter(unreadOnly: unreadOnly);

  /// Whether [notice] is shown under this filter, at [now].
  ///
  /// A notice with no date is shown only for any time: no day can be said to
  /// hold it.
  bool admits(ResidentNotification notice, {required DateTime now}) {
    if (unreadOnly && !notice.isUnread) return false;
    if (kind case final NoticeKind chosen
        when NoticeKind.of(notice) != chosen) {
      return false;
    }
    if (!_inPeriod(notice.sentAt, now)) return false;
    return _mentions(notice);
  }

  bool _inPeriod(DateTime? sentAt, DateTime now) {
    if (period == NotificationPeriod.anyTime) return true;
    if (sentAt == null) return false;
    return switch (period) {
      NotificationPeriod.anyTime => true,
      NotificationPeriod.today => manilaDayOf(sentAt) == manilaDayOf(now),
      NotificationPeriod.lastWeek => !sentAt.isBefore(
        now.subtract(const Duration(days: 7)),
      ),
      NotificationPeriod.lastMonth => !sentAt.isBefore(
        now.subtract(const Duration(days: 30)),
      ),
      // "On a date" with no date picked yet admits everything, rather than
      // emptying the list while the calendar is still open.
      NotificationPeriod.onDay => switch (day) {
        final DateTime chosen => manilaDayOf(sentAt) == chosen,
        null => true,
      },
    };
  }

  bool _mentions(ResidentNotification notice) {
    final String term = words.trim().toLowerCase();
    if (term.isEmpty) return true;
    return '${notice.title}\n${notice.body}'.toLowerCase().contains(term);
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationFilter &&
      other.unreadOnly == unreadOnly &&
      other.kind == kind &&
      other.period == period &&
      other.day == day &&
      other.words == words;

  @override
  int get hashCode => Object.hash(unreadOnly, kind, period, day, words);

  /// Redacted: the words she searched for can name a service or a person.
  @override
  String toString() =>
      'NotificationFilter(unreadOnly: $unreadOnly, kind: $kind, '
      'period: ${period.name}, searching: ${words.trim().isNotEmpty})';
}

/// The Manila calendar day [instant] falls on, as `DateTime.utc(y, m, d)`.
DateTime manilaDayOf(DateTime instant) {
  final DateTime manila = ManilaTime.of(instant);
  return DateTime.utc(manila.year, manila.month, manila.day);
}

/// [notices] that [filter] shows at [now], in the order given.
List<ResidentNotification> filterNotifications(
  Iterable<ResidentNotification> notices,
  NotificationFilter filter, {
  required DateTime now,
}) => <ResidentNotification>[
  for (final ResidentNotification notice in notices)
    if (filter.admits(notice, now: now)) notice,
];

/// The kinds [notices] hold, each with its count: the categories in
/// [NotificationCategory] order, then [NoticeKind.other].
///
/// **A kind with nothing in it is not offered** (DL-291): choosing it could
/// only ever show an empty list. The counts are over every notice given,
/// whatever else is filtered, so a choice never reads as fewer than it holds.
List<NoticeKindCount> kindsPresent(Iterable<ResidentNotification> notices) {
  final Map<NoticeKind, int> counts = <NoticeKind, int>{};
  for (final ResidentNotification notice in notices) {
    final NoticeKind kind = NoticeKind.of(notice);
    counts[kind] = (counts[kind] ?? 0) + 1;
  }
  return <NoticeKindCount>[
    for (final NotificationCategory category in NotificationCategory.values)
      if (counts[NoticeKind(category)] case final int count)
        NoticeKindCount(kind: NoticeKind(category), count: count),
    if (counts[const NoticeKind.other()] case final int count)
      NoticeKindCount(kind: const NoticeKind.other(), count: count),
  ];
}
