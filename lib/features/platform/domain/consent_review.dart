import 'package:flutter/foundation.dart';

import '../../settings/domain/account_controls.dart';
import 'app_bootstrap.dart';
import 'privacy_notice.dart';

/// The two texts a resident accepts, each under the version `GET /app/config`
/// names for it.
enum ConsentText { termsOfUse, privacyNotice }

/// One act the resident owes: the version of one text, recorded with its kind.
typedef ConsentToRecord = ({ConsentKind kind, String version});

/// Whether a signed-in resident has accepted the versions in force now.
///
/// ---
///
/// **The comparison is the whole rule, and it is deliberately dull.** A
/// consent is a version string the server recorded (`POST /me/consents`)
/// under the text it names (`kind`, backend `6c82f32`); the texts in force are
/// `terms_version` and `privacy_version`. A text is accepted when the newest
/// standing consent *of that kind* names its version, which is the server's
/// own `up_to_date` rule (`GET /me/consents/current`). Nothing else counts:
/// not an older version, not a consent to the other text, not a row an older
/// app recorded under one tick for both (`unspecified`, D-208), not something
/// the app remembers.
///
/// **An empty version is no opinion.** A server that names no version has not
/// asked anybody to accept anything, so nothing is owed for that text. This
/// is the same direction every uncertain case takes in [SupportedVersion]: a
/// missing configuration must never lock a resident out.
///
/// **One text, one act.** Each owed text is recorded on its own with its kind,
/// even when both texts share a version string: they are two agreements, and
/// the server keeps two rows (D-208).
@immutable
class ConsentReview {
  const ConsentReview._({
    required this.termsVersion,
    required this.privacyVersion,
    required this.missing,
    required this.terms,
    required this.privacyNotice,
  });

  /// Compares the versions in force with the resident's consents.
  ///
  /// [termsVersion] and [privacyVersion] are compared trimmed and exactly, as
  /// the server stores them. [terms] and [privacyNotice] are the texts to show;
  /// they decide nothing.
  factory ConsentReview.compare({
    required String termsVersion,
    required String privacyVersion,
    required Iterable<ConsentRecord> consents,
    TermsOfUse terms = TermsOfUse.missing,
    PrivacyNotice privacyNotice = PrivacyNotice.missing,
  }) {
    final String termsWanted = termsVersion.trim();
    final String privacyWanted = privacyVersion.trim();
    final List<ConsentRecord> held = consents.toList(growable: false);
    return ConsentReview._(
      termsVersion: termsWanted,
      privacyVersion: privacyWanted,
      missing: <ConsentText>{
        if (termsWanted.isNotEmpty &&
            _standingVersion(held, ConsentKind.terms) != termsWanted)
          ConsentText.termsOfUse,
        if (privacyWanted.isNotEmpty &&
            _standingVersion(held, ConsentKind.privacy) != privacyWanted)
          ConsentText.privacyNotice,
      },
      terms: terms,
      privacyNotice: privacyNotice,
    );
  }

  /// [ConsentReview.compare] against what `GET /app/config` answered.
  factory ConsentReview.of(
    AppBootstrap current,
    Iterable<ConsentRecord> consents,
  ) => ConsentReview.compare(
    termsVersion: current.termsVersion,
    privacyVersion: current.privacyVersion,
    consents: consents,
    terms: current.terms,
    privacyNotice: current.privacyNotice,
  );

  /// `terms_version`, trimmed. Empty when the server named none.
  final String termsVersion;

  /// `privacy_version`, trimmed. Empty when the server named none.
  final String privacyVersion;

  /// The texts whose version in force the resident has not accepted.
  final Set<ConsentText> missing;

  /// The Terms of Use text, for reading. Decides nothing.
  final TermsOfUse terms;

  /// The Privacy Notice text, for reading. Decides nothing.
  final PrivacyNotice privacyNotice;

  /// Whether nothing is owed.
  bool get isSettled => missing.isEmpty;

  /// Whether the server names no version at all, so there is nothing to ask.
  bool get namesNoVersion => termsVersion.isEmpty && privacyVersion.isEmpty;

  /// The acts to record, one per owed text, each with its kind: the Privacy
  /// Notice first, as registration records them. Two texts that share a
  /// version string are still two acts.
  List<ConsentToRecord> get toRecord => <ConsentToRecord>[
    if (missing.contains(ConsentText.privacyNotice))
      (kind: ConsentKind.privacy, version: privacyVersion),
    if (missing.contains(ConsentText.termsOfUse))
      (kind: ConsentKind.terms, version: termsVersion),
  ];

  /// The versions of [toRecord], in order.
  List<String> get versionsToRecord => <String>[
    for (final ConsentToRecord act in toRecord) act.version,
  ];

  /// When [text] was published, if the server said so for this version.
  ///
  /// Only a published text whose own version is the one being asked for
  /// carries a date: the placeholder's date is when the placeholder was
  /// written, which is not news to anybody.
  DateTime? updatedOn(ConsentText text) {
    final (PublishedText published, String version) = switch (text) {
      ConsentText.termsOfUse => (terms, termsVersion),
      ConsentText.privacyNotice => (privacyNotice, privacyVersion),
    };
    if (!published.isPublished) return null;
    if (published.version.trim() != version) return null;
    return published.updatedAt;
  }

  /// The version of the newest standing consent of [kind], or null.
  ///
  /// A withdrawn consent stays in the list as evidence. It is not an
  /// agreement in force. Rows of another kind, `unspecified` ones included,
  /// are not read at all.
  static String? _standingVersion(List<ConsentRecord> held, ConsentKind kind) {
    ConsentRecord? newest;
    for (final ConsentRecord consent in held) {
      if (consent.kind != kind || !consent.isActive) continue;
      if (consent.key.trim().isEmpty) continue;
      final DateTime? at = consent.grantedAt;
      final DateTime? best = newest?.grantedAt;
      if (newest == null ||
          (at != null && (best == null || at.isAfter(best)))) {
        newest = consent;
      }
    }
    return newest?.key.trim();
  }

  @override
  String toString() =>
      'ConsentReview(missing: ${missing.map((ConsentText t) => t.name)})';
}
