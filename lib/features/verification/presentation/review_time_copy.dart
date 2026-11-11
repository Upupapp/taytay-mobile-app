import '../../../core/l10n/app_locales.dart';
import '../../../l10n/app_localizations.dart';
import '../../platform/domain/verification_review_time.dart';

/// The one place the ID review time becomes words (D-200).
///
/// ---
///
/// The pending page and the profile wizard's submitted frame both say how long
/// a review usually takes. They read the same setting through this class, so
/// the two cannot drift apart. Each [VerificationReviewTime] reads as:
///
/// * stated: "1–3 working days", or for one number "1 working day" and
///   "5 working days";
/// * not stated: nothing at all, so the caller drops the sentence or the line;
/// * not sent: the bundled range, which is the copy this build shipped with.
///
/// The words are in the `.arb` files, in every locale the app ships, so
/// gen-l10n chooses the singular or plural and the translation tests guard the
/// Filipino. **The verification pages are literal English on every device**
/// (as D-195 left them), so they ask for [pageStrings]: a Filipino sentence in
/// the middle of an English paragraph would be worse than either language.
/// When the pages are translated, they pass `AppStrings.of(context)` instead
/// and nothing here changes.
abstract final class ReviewTimeCopy {
  /// The strings for the language the verification pages are written in.
  static AppStrings get pageStrings => lookupAppStrings(AppLocales.english);

  /// "1–3 working days", "1 working day", or `null` when the office states no
  /// review time.
  static String? duration(VerificationReviewTime time, AppStrings strings) {
    final ReviewTimeStated? range = switch (time) {
      final ReviewTimeStated stated => stated,
      ReviewTimeNotSent() => VerificationReviewTime.bundled,
      ReviewTimeNotStated() => null,
    };
    if (range == null) return null;
    return range.isSingle
        ? strings.verificationReviewDays(range.min)
        : strings.verificationReviewRange(range.min, range.max);
  }

  /// The pending page's sentence, "This usually takes 1–3 working days.", or
  /// `null` when the office states no review time.
  static String? sentence(VerificationReviewTime time, [AppStrings? strings]) {
    final AppStrings words = strings ?? pageStrings;
    final String? days = duration(time, words);
    return days == null ? null : words.verificationReviewSentence(days);
  }

  /// The line under "LGU review" on the submitted frame, "Usually 1–3 working
  /// days", or `null` when the office states no review time.
  static String? timelineDetail(
    VerificationReviewTime time, [
    AppStrings? strings,
  ]) {
    final AppStrings words = strings ?? pageStrings;
    final String? days = duration(time, words);
    return days == null ? null : words.verificationReviewTimelineDetail(days);
  }
}
