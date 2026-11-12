import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/features/platform/domain/consent_review.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';

/// A consent to the text its version names (`terms-…` or `privacy-…`), or
/// to [kind] when given.
ConsentRecord consent(
  String version, {
  DateTime? withdrawnAt,
  ConsentKind? kind,
}) => ConsentRecord(
  key: version,
  kind:
      kind ??
      (version.startsWith('terms') ? ConsentKind.terms : ConsentKind.privacy),
  label: 'Privacy notice',
  statement: 'Agreed under privacy notice $version',
  grantedAt: DateTime.utc(2026, 10, 1),
  withdrawnAt: withdrawnAt,
  isWithdrawable: true,
);

void main() {
  group('comparing the versions in force with what a resident accepted', () {
    test('both accepted: nothing is owed and nothing is recorded', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-2',
        privacyVersion: 'privacy-2',
        consents: <ConsentRecord>[consent('terms-2'), consent('privacy-2')],
      );
      expect(review.isSettled, isTrue);
      expect(review.missing, isEmpty);
      expect(review.versionsToRecord, isEmpty);
    });

    test('a new Terms of Use version is owed on its own', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-3',
        privacyVersion: 'privacy-2',
        consents: <ConsentRecord>[consent('terms-2'), consent('privacy-2')],
      );
      expect(review.missing, <ConsentText>{ConsentText.termsOfUse});
      expect(review.versionsToRecord, <String>['terms-3']);
    });

    test('a new Privacy Notice version is owed on its own', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-2',
        privacyVersion: 'privacy-3',
        consents: <ConsentRecord>[consent('terms-2'), consent('privacy-2')],
      );
      expect(review.missing, <ConsentText>{ConsentText.privacyNotice});
      expect(review.versionsToRecord, <String>['privacy-3']);
    });

    test('both new: both owed, the Privacy Notice recorded first', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-3',
        privacyVersion: 'privacy-3',
        consents: <ConsentRecord>[consent('terms-2'), consent('privacy-2')],
      );
      expect(review.missing, <ConsentText>{
        ConsentText.termsOfUse,
        ConsentText.privacyNotice,
      });
      expect(review.versionsToRecord, <String>['privacy-3', 'terms-3']);
    });

    test('one version for both texts is still two acts (D-208)', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: '2026-11',
        privacyVersion: '2026-11',
        consents: <ConsentRecord>[
          consent('2026-10', kind: ConsentKind.terms),
          consent('2026-10', kind: ConsentKind.privacy),
        ],
      );
      expect(review.missing, hasLength(2));
      expect(review.toRecord, <ConsentToRecord>[
        (kind: ConsentKind.privacy, version: '2026-11'),
        (kind: ConsentKind.terms, version: '2026-11'),
      ]);

      final ConsentReview accepted = ConsentReview.compare(
        termsVersion: '2026-11',
        privacyVersion: '2026-11',
        consents: <ConsentRecord>[
          consent('2026-11', kind: ConsentKind.terms),
          consent('2026-11', kind: ConsentKind.privacy),
        ],
      );
      expect(accepted.isSettled, isTrue);
    });

    test('an older combined row counts as neither text (D-208)', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: '2026-11',
        privacyVersion: '2026-11',
        consents: <ConsentRecord>[
          consent('2026-11', kind: ConsentKind.unspecified),
          consent('2026-11', kind: ConsentKind.biometric),
        ],
      );
      expect(review.missing, <ConsentText>{
        ConsentText.termsOfUse,
        ConsentText.privacyNotice,
      });
    });

    test('a consent to one text never counts for the other', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'v1',
        privacyVersion: 'v1',
        consents: <ConsentRecord>[consent('v1', kind: ConsentKind.terms)],
      );
      expect(review.missing, <ConsentText>{ConsentText.privacyNotice});
    });

    test('the newest standing consent of a kind decides, as the server', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-1',
        privacyVersion: '',
        consents: <ConsentRecord>[
          ConsentRecord(
            key: 'terms-1',
            kind: ConsentKind.terms,
            label: '',
            statement: '',
            grantedAt: DateTime.utc(2026, 9),
          ),
          ConsentRecord(
            key: 'terms-2',
            kind: ConsentKind.terms,
            label: '',
            statement: '',
            grantedAt: DateTime.utc(2026, 10),
          ),
        ],
      );
      expect(review.missing, <ConsentText>{ConsentText.termsOfUse});
    });

    test('a withdrawn consent is not an agreement in force', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-2',
        privacyVersion: 'privacy-2',
        consents: <ConsentRecord>[
          consent('terms-2'),
          consent('privacy-2', withdrawnAt: DateTime.utc(2026, 10, 9)),
        ],
      );
      expect(review.missing, <ConsentText>{ConsentText.privacyNotice});
      expect(review.versionsToRecord, <String>['privacy-2']);
    });

    test('a version the server does not name is not asked for', () {
      final ConsentReview none = ConsentReview.compare(
        termsVersion: '',
        privacyVersion: '  ',
        consents: const <ConsentRecord>[],
      );
      expect(none.namesNoVersion, isTrue);
      expect(none.isSettled, isTrue);

      final ConsentReview termsOnly = ConsentReview.compare(
        termsVersion: 'terms-2',
        privacyVersion: '',
        consents: const <ConsentRecord>[],
      );
      expect(termsOnly.missing, <ConsentText>{ConsentText.termsOfUse});
      expect(termsOnly.versionsToRecord, <String>['terms-2']);
    });

    test('versions compare trimmed and exactly, as the server keeps them', () {
      final ConsentReview review = ConsentReview.compare(
        termsVersion: ' terms-2 ',
        privacyVersion: 'Privacy-2',
        consents: <ConsentRecord>[consent('terms-2'), consent('privacy-2')],
      );
      expect(review.missing, <ConsentText>{ConsentText.privacyNotice});
      // A record with no version is not an agreement to anything.
      final ConsentReview blank = ConsentReview.compare(
        termsVersion: 'terms-2',
        privacyVersion: '',
        consents: <ConsentRecord>[consent('')],
      );
      expect(blank.missing, <ConsentText>{ConsentText.termsOfUse});
    });

    test('a date is shown only for a published text of the version asked', () {
      final DateTime published = DateTime.utc(2026, 11, 6, 2);
      final ConsentReview review = ConsentReview.compare(
        termsVersion: 'terms-3',
        privacyVersion: 'privacy-3',
        consents: const <ConsentRecord>[],
        terms: TermsOfUse(
          version: 'terms-3',
          updatedAt: published,
          bodyMarkdown: '# Terms\nSample terms.',
        ),
        // The placeholder's date is when the placeholder was written.
        privacyNotice: PrivacyNotice(
          version: PublishedText.placeholderVersion,
          updatedAt: DateTime.utc(2026),
          bodyMarkdown: 'This is a placeholder privacy notice.',
        ),
      );
      expect(review.updatedOn(ConsentText.termsOfUse), published);
      expect(review.updatedOn(ConsentText.privacyNotice), isNull);
    });
  });
}
