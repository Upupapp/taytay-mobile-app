import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

void main() {
  group('the vocabulary is the server’s', () {
    test('wire values are unique and snake_case', () {
      final Set<String> seen = <String>{};
      for (final CorrectableField field in CorrectableField.values) {
        expect(
          seen.add(field.wireValue),
          isTrue,
          reason: '${field.wireValue} is declared twice',
        );
        expect(
          field.wireValue,
          matches(RegExp(r'^[a-z]+(_[a-z]+)*$')),
          reason: 'the server names fields in snake_case; this is the wire',
        );
      }
    });

    test('every field is offered by some category', () {
      // The quiet direction of the drift. A field the server accepts and no
      // category offers is a correction a resident cannot ask for, and nothing
      // anywhere would report it — it simply would not appear on the screen.
      final Set<CorrectableField> offered = <CorrectableField>{
        for (final VerificationItemCategory category
            in VerificationItemCategory.values)
          ...category.fields,
      };

      expect(
        CorrectableField.values.toSet().difference(offered),
        isEmpty,
        reason:
            'these fields exist on the contract and no category offers them; '
            'put each on a category, or record why it is deliberately withheld',
      );
    });

    test('no category offers a field twice, or shares one with another', () {
      // Two categories offering the same field would let a resident file two
      // corrections against it in one submission, and the map would silently
      // keep whichever was typed last.
      final List<CorrectableField> all = <CorrectableField>[
        for (final VerificationItemCategory category
            in VerificationItemCategory.values)
          ...category.fields,
      ];

      expect(all.length, all.toSet().length, reason: 'a field appears twice');
    });
  });

  group('what each category can and cannot carry', () {
    test('documents map to no field at all', () {
      // Not an oversight: `me/profile/corrections` adjudicates named profile
      // fields, and a photograph is not one. The screen must say so before the
      // input rather than refusing after the typing.
      expect(VerificationItemCategory.identityDocument.fields, isEmpty);
      expect(VerificationItemCategory.photo.fields, isEmpty);
      expect(VerificationItemCategory.identityDocument.isCorrectable, isFalse);
      expect(VerificationItemCategory.photo.isCorrectable, isFalse);
    });

    test('every correctable category spans more than one field', () {
      // True today, and the reason the model no longer has a single-field
      // shortcut: the old `field` getter made "one field" the normal case and
      // "several" the exception, when it is the other way round.
      for (final VerificationItemCategory category
          in VerificationItemCategory.values.where((c) => c.isCorrectable)) {
        expect(
          category.needsFieldChoice,
          isTrue,
          reason: '${category.name} must ask which detail',
        );
      }
    });

    test('a category never silently resolves to a field', () {
      // The defect this replaced: `address` mapped to `street_address` alone,
      // so a resident correcting their barangay filed a street correction.
      expect(
        VerificationItemCategory.address.fields,
        containsAll(<CorrectableField>[
          CorrectableField.barangayId,
          CorrectableField.streetAddress,
          CorrectableField.purokOrSitio,
        ]),
      );
    });
  });
}
