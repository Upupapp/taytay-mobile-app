import 'package:flutter/foundation.dart';

import '../../settings/domain/account_controls.dart';
import 'app_bootstrap.dart';
import 'privacy_notice.dart';

/// The two texts a resident accepts, each under the version `GET /app/config`
/// names for it.
enum ConsentText { termsOfUse, privacyNotice }

/// Whether a signed-in resident has accepted the versions in force now.
///
/// ---
///
/// **The comparison is the whole rule, and it is deliberately dull.** A
/// consent is a version string the server recorded (`POST /me/consents`); the
/// texts in force are `terms_version` and `privacy_version`. A version is
/// accepted when the resident's list holds it and it has not been withdrawn.
/// Nothing else counts: not an older version, not a version of the other text,
/// not something the app remembers.
///
/// **An empty version is no opinion.** A server that names no version has not
/// asked anybody to accept anything, so nothing is owed for that text. This
/// is the same direction every uncertain case takes in [SupportedVersion]: a
/// missing configuration must never lock a resident out.
///
/// **One version, one record.** The server keeps consents by version alone, so
/// when both texts share a version the resident's agreement is recorded once.
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
    final Set<String> accepted = <String>{
      for (final ConsentRecord consent in consents)
        // A withdrawn consent stays in the list as evidence. It is not an
        // agreement in force.
        if (consent.isActive && consent.key.trim().isNotEmpty)
          consent.key.trim(),
    };
    return ConsentReview._(
      termsVersion: termsWanted,
      privacyVersion: privacyWanted,
      missing: <ConsentText>{
        if (termsWanted.isNotEmpty && !accepted.contains(termsWanted))
          ConsentText.termsOfUse,
        if (privacyWanted.isNotEmpty && !accepted.contains(privacyWanted))
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

  /// The versions to record, each once: the Privacy Notice first, as
  /// registration records them.
  List<String> get versionsToRecord => <String>[
    if (missing.contains(ConsentText.privacyNotice)) privacyVersion,
    if (missing.contains(ConsentText.termsOfUse) &&
        !(missing.contains(ConsentText.privacyNotice) &&
            termsVersion == privacyVersion))
      termsVersion,
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

  @override
  String toString() =>
      'ConsentReview(missing: ${missing.map((ConsentText t) => t.name)})';
}
