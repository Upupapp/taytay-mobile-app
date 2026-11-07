import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/features/issuance/data/issuance_codec.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_form.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_request.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_status.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_terms.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';

/// The served policy for document requests: PDF, JPEG or PNG, 10 MB.
final UploadPolicy _served = UploadPolicy.decode(<String, dynamic>{
  'mime_types': <dynamic>['application/pdf', 'image/jpeg', 'image/png'],
  'max_bytes': 10485760,
});

IssuanceType _type({List<IssuanceRequirement>? requirements}) => IssuanceType(
  id: 'dt-1',
  name: 'Certified copy of a birth record',
  officeId: 'office-1',
  officeName: 'Municipal Civil Registrar',
  requirements:
      requirements ??
      const <IssuanceRequirement>[
        IssuanceRequirement(
          code: 'valid-id',
          label: 'Valid ID',
          required: true,
        ),
        IssuanceRequirement(
          code: 'authorization',
          label: 'Authorization letter',
          required: false,
        ),
      ],
  uploadPolicy: _served,
);

CapturedDocument _file(List<int> head, {int size = 2048, String? type}) {
  final Uint8List bytes = Uint8List(size)..setRange(0, head.length, head);
  return CapturedDocument(
    bytes: bytes,
    fileName: 'scan',
    mimeType: type ?? 'application/pdf',
    source: DocumentSource.file,
  );
}

const List<int> _pdf = <int>[0x25, 0x50, 0x44, 0x46];
const List<int> _jpeg = <int>[0xFF, 0xD8, 0xFF];

void main() {
  group('status in plain words', () {
    test('every status has its own label and explanation', () {
      final Set<String> labels = <String>{
        for (final IssuanceStatus s in IssuanceStatus.values)
          issuanceStatusLabel(s),
      };
      expect(labels, hasLength(IssuanceStatus.values.length));
      for (final IssuanceStatus s in IssuanceStatus.values) {
        expect(issuanceStatusExplanation(s), isNotEmpty, reason: s.name);
      }
    });

    test('the labels a resident reads', () {
      expect(
        issuanceStatusLabel(IssuanceStatus.needsInfo),
        'Needs more from you',
      );
      expect(
        issuanceStatusLabel(IssuanceStatus.readyForPickup),
        'Ready to claim',
      );
      expect(issuanceStatusLabel(IssuanceStatus.rejected), 'Not issued');
    });

    test(
      'an unknown status degrades to a neutral word, never a wire value',
      () {
        expect(IssuanceCodec.status('on-hold'), isNull);
        expect(issuanceStatusLabel(null), 'Updated');
        expect(issuanceStatusLabel(null), isNot(contains('-')));
      },
    );

    test('every wire status decodes, and round-trips', () {
      for (final String wire in <String>[
        'submitted',
        'under-review',
        'needs-info',
        'approved',
        'ready-for-pickup',
        'released',
        'rejected',
        'cancelled',
      ]) {
        final IssuanceStatus? decoded = IssuanceCodec.status(wire);
        expect(decoded, isNotNull, reason: wire);
        expect(IssuanceCodec.wireStatus(decoded!), wire);
      }
    });

    test('released, rejected and cancelled are finished; the rest are not', () {
      expect(
        IssuanceStatus.values.where((IssuanceStatus s) => s.isFinished),
        unorderedEquals(<IssuanceStatus>[
          IssuanceStatus.released,
          IssuanceStatus.rejected,
          IssuanceStatus.cancelled,
        ]),
      );
    });

    test('a history line is written in the resident\'s words', () {
      expect(
        issuanceHistoryLine(from: null, to: IssuanceStatus.submitted),
        'You sent the request',
      );
      expect(
        issuanceHistoryLine(
          from: IssuanceStatus.needsInfo,
          to: IssuanceStatus.underReview,
        ),
        'You sent what the office asked for',
      );
      expect(
        issuanceHistoryLine(
          from: IssuanceStatus.submitted,
          to: IssuanceStatus.underReview,
        ),
        'The office started reviewing it',
      );
    });
  });

  group('fees are integer centavos, formatted without floating point', () {
    test('pesos and centavos', () {
      expect(formatPesos(5000), '₱50.00');
      expect(formatPesos(5010), '₱50.10');
      expect(formatPesos(5), '₱0.05');
      expect(formatPesos(0), '₱0.00');
      expect(formatPesos(125000), '₱1,250.00');
      expect(formatPesos(100000000), '₱1,000,000.00');
      expect(formatPesos(99999999999), '₱999,999,999.99');
    });

    test(
      'the fee line says it is paid at the office, or that none was stated',
      () {
        expect(issuanceFeeLine(5000), 'Fee: ₱50.00, paid at the office');
        expect(issuanceFeeLine(null), 'No fee stated');
        expect(issuanceFeeLine(0), 'No fee');
      },
    );

    test('processing time is stated or said to be unstated', () {
      expect(issuanceProcessingLine(null), 'Processing time not stated');
      expect(issuanceProcessingLine(0), 'Usually the same working day');
      expect(issuanceProcessingLine(1), 'About 1 working day');
      expect(issuanceProcessingLine(5), 'About 5 working days');
    });

    test('the accepted files are read from the server policy', () {
      expect(acceptedFilesLine(_served), 'JPEG, PDF or PNG, up to 10 MB each');
      final UploadPolicy photosOnly = UploadPolicy.decode(<String, dynamic>{
        'mime_types': <dynamic>['image/jpeg'],
        'max_bytes': 5242880,
      });
      expect(acceptedFilesLine(photosOnly), 'JPEG, up to 5 MB each');
    });
  });

  group('the form is checked before anything is sent', () {
    test('the purpose is trimmed and must be 10 to 300 characters', () {
      expect(checkPurpose(''), PurposeProblem.empty);
      expect(checkPurpose('          '), PurposeProblem.empty);
      expect(checkPurpose('For work'), PurposeProblem.tooShort);
      expect(checkPurpose('   For work   '), PurposeProblem.tooShort);
      expect(checkPurpose('For school'), isNull);
      expect(checkPurpose('a' * 300), isNull);
      expect(checkPurpose('a' * 301), PurposeProblem.tooLong);
      for (final PurposeProblem p in PurposeProblem.values) {
        expect(purposeProblemText(p), isNotEmpty);
      }
    });

    test('only required files are missing; optional ones may stay empty', () {
      final IssuanceType type = _type();
      expect(
        missingRequiredFiles(
          type,
          const <String, CapturedDocument>{},
        ).map((IssuanceRequirement r) => r.code),
        <String>['valid-id'],
      );
      expect(
        missingRequiredFiles(type, <String, CapturedDocument>{
          'valid-id': _file(_pdf),
        }),
        isEmpty,
      );
      final ({PurposeProblem? purpose, List<IssuanceRequirement> missing})
      checked = checkRequest(
        type,
        purpose: 'For school',
        files: const <String, CapturedDocument>{},
      );
      expect(checked.purpose, isNull);
      expect(checked.missing, hasLength(1));
    });

    test('a file is refused on the phone by the type\'s own policy', () {
      expect(DocumentCapturePolicy.inspect(_file(_pdf), _served), isNull);
      expect(
        DocumentCapturePolicy.inspect(
          _file(_jpeg, type: 'image/jpeg'),
          _served,
        ),
        isNull,
      );
      expect(
        DocumentCapturePolicy.inspect(_file(_pdf, size: 10485761), _served),
        DocumentRejection.tooLarge,
      );
      expect(
        DocumentCapturePolicy.inspect(_file(_pdf, size: 10485760), _served),
        isNull,
      );
      expect(
        DocumentCapturePolicy.inspect(_file(_jpeg), _served),
        DocumentRejection.contentsDoNotMatchType,
      );
      expect(
        DocumentCapturePolicy.inspect(_file(_pdf, type: 'image/heic'), _served),
        DocumentRejection.unsupportedType,
      );
    });

    test('a resubmission needs a note or a file', () {
      expect(
        resubmissionHasContent(
          note: '  ',
          files: const <String, CapturedDocument>{},
        ),
        isFalse,
      );
      expect(
        resubmissionHasContent(
          note: 'Here it is',
          files: const <String, CapturedDocument>{},
        ),
        isTrue,
      );
      expect(
        resubmissionHasContent(
          note: '',
          files: <String, CapturedDocument>{'valid-id': _file(_pdf)},
        ),
        isTrue,
      );
    });
  });

  group('the catalogue', () {
    IssuanceType typed(String id, String office, String name) => IssuanceType(
      id: id,
      name: name,
      officeId: office,
      officeName: 'Office $office',
      requirements: const <IssuanceRequirement>[],
      uploadPolicy: _served,
    );

    test('is grouped by office in the order the server listed them', () {
      final List<(String, List<IssuanceType>)> groups =
          groupByOffice(<IssuanceType>[
            typed('1', 'b', 'Birth record'),
            typed('2', 'a', 'Indigency'),
            typed('3', 'b', 'Marriage record'),
          ]);
      expect(groups.map(((String, List<IssuanceType>) g) => g.$1), <String>[
        'Office b',
        'Office a',
      ]);
      expect(groups.first.$2.map((IssuanceType t) => t.id), <String>['1', '3']);
    });

    test('search matches every word, in any field, ignoring case', () {
      final List<IssuanceType> all = <IssuanceType>[
        typed('1', 'b', 'Birth record'),
        typed('2', 'a', 'Certificate of indigency'),
      ];
      expect(searchTypes(all, '').length, 2);
      expect(searchTypes(all, 'BIRTH').single.id, '1');
      expect(searchTypes(all, 'office a indigency').single.id, '2');
      expect(searchTypes(all, 'birth indigency'), isEmpty);
    });
  });

  group('a request', () {
    test('never prints the purpose', () {
      final IssuanceRequestDetail? detail = IssuanceCodec.detail(
        <String, dynamic>{
          'id': 'r-1',
          'reference_number': 'DR-2026-000001',
          'status': 'rejected',
          'purpose': 'For a hospital bill of my son',
          'history': <dynamic>[
            <String, dynamic>{
              'from_status': 'under-review',
              'to_status': 'rejected',
              'by': 'office',
              'message': 'The record is not registered in Taytay.',
            },
          ],
        },
      );
      expect(detail, isNotNull);
      expect(detail.toString(), isNot(contains('hospital')));
      expect(detail!.refusalReason, 'The record is not registered in Taytay.');
    });
  });
}
