import 'package:flutter/foundation.dart';

/// How many working days the app tells a resident an ID review usually takes:
/// `verification_review_working_days` on `GET /app/config` (backend `39d650b`,
/// D-200).
///
/// ---
///
/// No service standard is published for the review, so the number is the
/// office's to set from the console, and the office may also clear it. That
/// gives the app three cases, and they render differently:
///
/// * [ReviewTimeStated] — the office's range, both ends counted.
/// * [ReviewTimeNotStated] — `null` on the wire: the office states no review
///   time, so the app says none. No empty line, no dangling clause.
/// * [ReviewTimeNotSent] — the key is absent (an older server), the config has
///   not been read yet, or the value is malformed. The app keeps the copy it
///   shipped with, [bundled].
///
/// A malformed value is "not sent" rather than "not stated": a server bug must
/// not silently delete a sentence the office never cleared, and it must never
/// crash a released app (Article 8).
sealed class VerificationReviewTime {
  const VerificationReviewTime();

  /// Nothing usable arrived. See [ReviewTimeNotSent].
  static const VerificationReviewTime notSent = ReviewTimeNotSent._();

  /// The office states no review time. See [ReviewTimeNotStated].
  static const VerificationReviewTime notStated = ReviewTimeNotStated._();

  /// The range this build said before the setting existed, and what it still
  /// says when the server sends nothing. Backend migration `0046` seeds the
  /// same range, so an office that never edits the setting sees no change.
  static const ReviewTimeStated bundled = ReviewTimeStated(1, 3);

  /// The fewest working days the server accepts for either end.
  static const int fewestDays = 1;

  /// The most working days the server accepts for either end.
  static const int mostDays = 30;

  /// A range from the wire, or [notSent] when it is not one the server could
  /// have sent: either end not an integer, below [fewestDays], above
  /// [mostDays], or `min` above `max`.
  static VerificationReviewTime fromRange(Object? min, Object? max) {
    if (min is! int || max is! int) return notSent;
    if (min < fewestDays || max > mostDays || min > max) return notSent;
    return ReviewTimeStated(min, max);
  }
}

/// The server sent no usable range. The app keeps the copy it shipped with.
final class ReviewTimeNotSent extends VerificationReviewTime {
  const ReviewTimeNotSent._();

  @override
  String toString() => 'VerificationReviewTime.notSent';
}

/// The office states no review time. The app says none.
final class ReviewTimeNotStated extends VerificationReviewTime {
  const ReviewTimeNotStated._();

  @override
  String toString() => 'VerificationReviewTime.notStated';
}

/// The office's range of working days, both ends counted.
@immutable
final class ReviewTimeStated extends VerificationReviewTime {
  /// Only for a range already known to be valid. Wire values go through
  /// [VerificationReviewTime.fromRange], which never builds an invalid one.
  const ReviewTimeStated(this.min, this.max)
    : assert(min >= VerificationReviewTime.fewestDays),
      assert(max <= VerificationReviewTime.mostDays),
      assert(min <= max);

  final int min;
  final int max;

  /// One number rather than a range: "3 working days", not "3–3".
  bool get isSingle => min == max;

  @override
  bool operator ==(Object other) =>
      other is ReviewTimeStated && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'VerificationReviewTime($min–$max)';
}
