import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../core/time/manila_time.dart';

/// One day's opening, in Manila wall-clock minutes after midnight.
///
/// One interval a day, opening before closing: the office hours the design
/// shows ("Mon–Fri, 8:00 AM – 5:00 PM"). A lunch break or overnight hours would
/// need a second interval, which nothing asks for yet.
@immutable
class DayHours {
  const DayHours({required this.opensAt, required this.closesAt})
    : assert(opensAt >= 0 && closesAt <= 24 * 60 && opensAt < closesAt);

  /// `DayHours.of(8, 0, 17, 0)` is 8:00 AM to 5:00 PM.
  const DayHours.of(
    int openHour,
    int openMinute,
    int closeHour,
    int closeMinute,
  ) : this(
        opensAt: openHour * 60 + openMinute,
        closesAt: closeHour * 60 + closeMinute,
      );

  final int opensAt;
  final int closesAt;

  @override
  bool operator ==(Object other) =>
      other is DayHours &&
      other.opensAt == opensAt &&
      other.closesAt == closesAt;

  @override
  int get hashCode => Object.hash(opensAt, closesAt);
}

/// An office's week, keyed by [DateTime.monday] … [DateTime.sunday]. A day
/// with no entry is closed.
///
/// **Presentation-side only.** The API has no structured office hours yet
/// (design/PROGRESS.md "API fields needed"); a screen builds this from the
/// API when it does, and until then passes null to [StatusLine], which then
/// draws nothing. A screen never builds one from a free-text "Mon–Fri, 8–5"
/// or from a guess: an "Open" line that is wrong sends a resident to a locked
/// door.
@immutable
class WeeklyHours {
  const WeeklyHours(this.days);

  final Map<int, DayHours> days;

  /// Whether the office is open at [instant], and when that changes.
  /// Read on the Manila clock, whatever the phone's timezone.
  OpenStatus statusAt(DateTime instant) {
    final DateTime manila = ManilaTime.of(instant);
    final int weekday = manila.weekday;
    final int minute = manila.hour * 60 + manila.minute;
    final DayHours? today = days[weekday];
    if (today != null && minute >= today.opensAt && minute < today.closesAt) {
      return OpenNow(closesAt: today.closesAt);
    }
    if (today != null && minute < today.opensAt) {
      return ClosedNow(
        nextOpening: NextOpening(
          daysAhead: 0,
          weekday: weekday,
          opensAt: today.opensAt,
        ),
      );
    }
    for (var ahead = 1; ahead <= 7; ahead++) {
      final int day = (weekday - 1 + ahead) % 7 + 1;
      final DayHours? hours = days[day];
      if (hours != null) {
        return ClosedNow(
          nextOpening: NextOpening(
            daysAhead: ahead,
            weekday: day,
            opensAt: hours.opensAt,
          ),
        );
      }
    }
    return const ClosedNow(nextOpening: null);
  }

  @override
  bool operator ==(Object other) =>
      other is WeeklyHours && mapEquals(other.days, days);

  @override
  int get hashCode => Object.hashAllUnordered(
    days.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

/// What [WeeklyHours.statusAt] found.
sealed class OpenStatus {
  const OpenStatus();
}

final class OpenNow extends OpenStatus {
  const OpenNow({required this.closesAt});

  /// Minutes after midnight, Manila.
  final int closesAt;
}

final class ClosedNow extends OpenStatus {
  const ClosedNow({required this.nextOpening});

  /// Null when the week has no opening at all.
  final NextOpening? nextOpening;
}

@immutable
class NextOpening {
  const NextOpening({
    required this.daysAhead,
    required this.weekday,
    required this.opensAt,
  });

  /// 0 is later today, 1 tomorrow.
  final int daysAhead;
  final int weekday;
  final int opensAt;
}

/// The words [StatusLine] uses. English by default; a screen passes its
/// localised copy.
@immutable
class StatusLineLabels {
  const StatusLineLabels({
    this.open = 'Open',
    this.closed = 'Closed',
    this.closes = _closes,
    this.opensToday = _opensToday,
    this.opensTomorrow = _opensTomorrow,
    this.opensOn = _opensOn,
    this.weekdays = const <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
  });

  final String open;
  final String closed;
  final String Function(String time) closes;
  final String Function(String time) opensToday;
  final String Function(String time) opensTomorrow;
  final String Function(String time, String weekday) opensOn;

  /// Monday first, as [DateTime.monday] is 1.
  final List<String> weekdays;

  static String _closes(String time) => 'Closes $time';
  static String _opensToday(String time) => 'Opens $time today';
  static String _opensTomorrow(String time) => 'Opens $time tomorrow';
  static String _opensOn(String time, String weekday) => 'Opens $time $weekday';
}

/// "**Open** · Closes 5:00 PM" / "**Closed** · Opens 8:00 AM Monday" (CSS
/// `.meta` on Office): the state in bold green or red, then when it changes.
///
/// Renders **nothing** when [hours] is null — the API has no structured hours
/// yet, and no line is better than an invented one. The state is a word as
/// well as a colour (WCAG 1.4.1).
class StatusLine extends StatelessWidget {
  const StatusLine({
    required this.hours,
    required this.now,
    this.compact = false,
    this.labels = const StatusLineLabels(),
    super.key,
  });

  final WeeklyHours? hours;

  /// The current instant. Screens pass the clock they already use, so a test
  /// can pin it.
  final DateTime now;

  /// 12.5 px, for a list row. The default 13.5 px is the detail page's.
  final bool compact;
  final StatusLineLabels labels;

  @override
  Widget build(BuildContext context) {
    final WeeklyHours? hours = this.hours;
    if (hours == null) return const SizedBox.shrink();

    final OpenStatus status = hours.statusAt(now);
    final (String state, Color stateColor, String? detail) = switch (status) {
      OpenNow(:final closesAt) => (
        labels.open,
        BrandColors.green,
        labels.closes(formatMinutes(closesAt)),
      ),
      ClosedNow(:final nextOpening) => (
        labels.closed,
        BrandColors.redInk,
        nextOpening == null ? null : _opens(nextOpening),
      ),
    };

    final TextStyle base =
        (compact ? AppTypography.listDetail : AppTypography.bodyStyle).copyWith(
          color: BrandColors.text,
          height: 1.3,
        );
    return MergeSemantics(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: <Widget>[
          Text(
            state,
            style: base.copyWith(
              color: stateColor,
              fontWeight: AppTypography.strong,
            ),
          ),
          if (detail != null) ...<Widget>[
            const ExcludeSemantics(child: _Dot()),
            Text(detail, style: base),
          ],
        ],
      ),
    );
  }

  String _opens(NextOpening next) {
    final String time = formatMinutes(next.opensAt);
    return switch (next.daysAhead) {
      0 => labels.opensToday(time),
      1 => labels.opensTomorrow(time),
      _ => labels.opensOn(time, labels.weekdays[next.weekday - 1]),
    };
  }

  /// `5:00 PM`, the way [ManilaTime.formatTime] writes a time.
  static String formatMinutes(int minutes) {
    final int hour24 = (minutes ~/ 60) % 24;
    final int hour = switch (hour24) {
      0 => 12,
      final h when h > 12 => h - 12,
      final h => h,
    };
    final String minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute ${hour24 < 12 ? 'AM' : 'PM'}';
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.chevron,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
