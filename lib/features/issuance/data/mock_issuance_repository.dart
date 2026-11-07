import 'dart:typed_data';

import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/result/result.dart';
import '../domain/issuance_repository.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';
import '../domain/issuance_type.dart';
import 'issuance_codec.dart';

/// Dev-only document requests, for `TAYTAY_DATA=mock`.
///
/// The fixtures are written in the wire shape and read through
/// [IssuanceCodec], so the mock exercises the same decoder the live build
/// does. Every office, document and request here is synthetic. Staging and
/// production never construct this class.
class MockIssuanceRepository implements IssuanceRepository {
  MockIssuanceRepository(this._behavior);

  final MockBehaviorController _behavior;

  late final List<IssuanceType> _types = IssuanceCodec.typeList(_typeFixtures);
  late final List<IssuanceRequestDetail> _requests = <IssuanceRequestDetail>[
    for (final Map<String, Object?> fixture in _requestFixtures)
      if (IssuanceCodec.detail(fixture) case final IssuanceRequestDetail detail)
        detail,
  ];
  int _filed = 0;

  @override
  Future<Result<List<IssuanceType>>> listTypes() => _behavior
      .respond<List<IssuanceType>>(List<IssuanceType>.unmodifiable(_types));

  @override
  Future<Result<IssuanceType>> loadType(String typeId) async {
    for (final IssuanceType type in _types) {
      if (type.id == typeId) return _behavior.respond<IssuanceType>(type);
    }
    return const Err<IssuanceType>(
      NotFoundFailure(debugMessage: 'No fixture document type with that id.'),
    );
  }

  @override
  Future<Result<IssuanceRequestDetail>> submit({
    required String typeId,
    required String purpose,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    IssuanceType? type;
    for (final IssuanceType candidate in _types) {
      if (candidate.id == typeId) type = candidate;
    }
    if (type == null) {
      return const Err<IssuanceRequestDetail>(
        NotFoundFailure(debugMessage: 'No fixture document type with that id.'),
      );
    }
    _filed++;
    final DateTime now = DateTime.now().toUtc();
    final String id = 'dr-mock-$_filed';
    final IssuanceRequestDetail filed = IssuanceRequestDetail(
      summary: IssuanceRequestSummary(
        id: id,
        referenceNumber: 'DR-2026-${(130 + _filed).toString().padLeft(6, '0')}',
        status: IssuanceStatus.submitted,
        typeName: type.name,
        officeName: type.officeName,
        typeId: type.id,
        createdAt: now,
        updatedAt: now,
      ),
      purpose: purpose.trim(),
      requirements: type.requirements,
      attachments: _attach(files, const <IssuanceAttachment>[], now),
      history: <IssuanceHistoryEntry>[
        IssuanceHistoryEntry(
          from: null,
          to: IssuanceStatus.submitted,
          by: IssuanceActor.resident,
          at: now,
        ),
      ],
      canCancel: true,
      canResubmit: false,
      feeCentavos: type.feeCentavos,
      processingDays: type.processingDays,
      claimInstructions: type.claimInstructions,
    );
    final Result<IssuanceRequestDetail> answer = await _behavior
        .respond<IssuanceRequestDetail>(filed);
    // A dev failure files nothing, exactly as a refused live request does.
    if (answer.isOk) _requests.insert(0, filed);
    return answer;
  }

  @override
  Future<Result<Paginated<IssuanceRequestSummary>>> listOwn({String? cursor}) =>
      _behavior.respond<Paginated<IssuanceRequestSummary>>(
        Paginated<IssuanceRequestSummary>.single(<IssuanceRequestSummary>[
          for (final IssuanceRequestDetail request in _requests)
            request.summary,
        ]),
      );

  @override
  Future<Result<IssuanceRequestDetail>> loadOwn(String requestId) async {
    final IssuanceRequestDetail? found = _find(requestId);
    if (found == null) {
      return const Err<IssuanceRequestDetail>(
        NotFoundFailure(debugMessage: 'No fixture request with that id.'),
      );
    }
    return _behavior.respond<IssuanceRequestDetail>(found);
  }

  @override
  Future<Result<IssuanceRequestDetail>> cancel(
    String requestId, {
    String? reason,
    required String idempotencyKey,
  }) async {
    final IssuanceRequestDetail? found = _find(requestId);
    if (found == null || !found.canCancel) {
      return const Err<IssuanceRequestDetail>(
        ConflictFailure(
          debugMessage: 'This fixture request cannot be cancelled.',
        ),
      );
    }
    final String? said = reason?.trim();
    return _move(
      found,
      to: IssuanceStatus.cancelled,
      message: said == null || said.isEmpty ? null : said,
      files: const <String, CapturedDocument>{},
    );
  }

  @override
  Future<Result<IssuanceRequestDetail>> resubmit(
    String requestId, {
    String? note,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final IssuanceRequestDetail? found = _find(requestId);
    if (found == null || !found.canResubmit) {
      return const Err<IssuanceRequestDetail>(
        ConflictFailure(
          debugMessage: 'This fixture request takes no resubmission.',
        ),
      );
    }
    final String? said = note?.trim();
    return _move(
      found,
      to: IssuanceStatus.underReview,
      message: said == null || said.isEmpty ? null : said,
      files: files,
    );
  }

  @override
  Future<Result<Uint8List>> loadAttachmentImage(
    String requestId,
    String attachmentId,
  ) async {
    // The fixtures carry no image bytes, and inventing a picture of an ID
    // would put a fake document on screen. Said as "not found".
    return const Err<Uint8List>(
      NotFoundFailure(debugMessage: 'The dev mock holds no file contents.'),
    );
  }

  IssuanceRequestDetail? _find(String id) {
    for (final IssuanceRequestDetail request in _requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  Future<Result<IssuanceRequestDetail>> _move(
    IssuanceRequestDetail request, {
    required IssuanceStatus to,
    required String? message,
    required Map<String, CapturedDocument> files,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final IssuanceRequestSummary head = request.summary;
    final IssuanceRequestDetail moved = IssuanceRequestDetail(
      summary: IssuanceRequestSummary(
        id: head.id,
        referenceNumber: head.referenceNumber,
        status: to,
        typeName: head.typeName,
        officeName: head.officeName,
        typeId: head.typeId,
        createdAt: head.createdAt,
        updatedAt: now,
      ),
      purpose: request.purpose,
      requirements: request.requirements,
      attachments: _attach(files, request.attachments, now),
      history: <IssuanceHistoryEntry>[
        ...request.history,
        IssuanceHistoryEntry(
          from: request.status,
          to: to,
          by: IssuanceActor.resident,
          message: message,
          at: now,
        ),
      ],
      canCancel: false,
      canResubmit: false,
      feeCentavos: request.feeCentavos,
      processingDays: request.processingDays,
      claimInstructions: request.claimInstructions,
    );
    final Result<IssuanceRequestDetail> answer = await _behavior
        .respond<IssuanceRequestDetail>(moved);
    if (answer.isOk) {
      _requests[_requests.indexOf(request)] = moved;
    }
    return answer;
  }

  /// New versions beside the old ones, never in place of them.
  static List<IssuanceAttachment> _attach(
    Map<String, CapturedDocument> files,
    List<IssuanceAttachment> existing,
    DateTime now,
  ) {
    final List<IssuanceAttachment> all = <IssuanceAttachment>[
      for (final IssuanceAttachment old in existing)
        IssuanceAttachment(
          id: old.id,
          requirementCode: old.requirementCode,
          version: old.version,
          mimeType: old.mimeType,
          byteSize: old.byteSize,
          current: old.current && !files.containsKey(old.requirementCode),
          createdAt: old.createdAt,
        ),
    ];
    for (final MapEntry<String, CapturedDocument> entry in files.entries) {
      final int before = existing
          .where((IssuanceAttachment a) => a.requirementCode == entry.key)
          .fold<int>(
            0,
            (int top, IssuanceAttachment a) =>
                a.version > top ? a.version : top,
          );
      all.add(
        IssuanceAttachment(
          id: 'att-mock-${entry.key}-${before + 1}-${now.millisecondsSinceEpoch}',
          requirementCode: entry.key,
          version: before + 1,
          mimeType: entry.value.mimeType,
          byteSize: entry.value.sizeBytes,
          current: true,
          createdAt: now,
        ),
      );
    }
    return all;
  }
}

/// The `accepts` block the API publishes on every type, in its wire shape.
const Map<String, Object?> _accepts = <String, Object?>{
  'mime_types': <Object?>['application/pdf', 'image/jpeg', 'image/png'],
  'max_bytes': 10485760,
};

const Map<String, Object?> _civilRegistry = <String, Object?>{
  'id': 'office-sample-mcr',
  'slug': 'mcr',
  'name': 'Municipal Civil Registrar',
};

const Map<String, Object?> _welfare = <String, Object?>{
  'id': 'office-sample-mswdo',
  'slug': 'mswdo',
  'name': 'Municipal Social Welfare and Development Office',
};

const Map<String, Object?> _permits = <String, Object?>{
  'id': 'office-sample-bplo',
  'slug': 'bplo',
  'name': 'Business Permits and Licensing Office',
};

const Map<String, Object?> _validId = <String, Object?>{
  'code': 'valid-id',
  'label': 'Valid ID',
  'required': true,
  'hint': 'The front of any government ID with your photo.',
};

const List<Map<String, Object?>> _typeFixtures = <Map<String, Object?>>[
  <String, Object?>{
    'id': 'dt-sample-birth',
    'office': _civilRegistry,
    'name': 'Certified copy of a birth record',
    'description':
        'A certified true copy of a birth record registered in Taytay, for '
        'school, work or travel.',
    'requirements': <Object?>[
      _validId,
      <String, Object?>{
        'code': 'authorization',
        'label': 'Authorization letter',
        'required': false,
        'hint': "Only when you are asking for somebody else's record.",
      },
    ],
    'fee_centavos': 5000,
    'processing_days': 3,
    'claim_instructions':
        'Claim it at the Civil Registry window, ground floor of the Municipal '
        'Hall. Bring the ID you sent.',
    'accepts': _accepts,
  },
  <String, Object?>{
    'id': 'dt-sample-marriage',
    'office': _civilRegistry,
    'name': 'Certified copy of a marriage record',
    'description': 'A certified true copy of a marriage registered in Taytay.',
    'requirements': <Object?>[_validId],
    'fee_centavos': 5000,
    'processing_days': 3,
    'claim_instructions':
        'Claim it at the Civil Registry window, ground floor of the Municipal '
        'Hall.',
    'accepts': _accepts,
  },
  <String, Object?>{
    'id': 'dt-sample-indigency',
    'office': _welfare,
    'name': 'Certificate of indigency',
    'description':
        'Says the office has assessed your household as indigent, for '
        'hospital, school or legal aid requirements.',
    'requirements': <Object?>[
      <String, Object?>{
        'code': 'barangay-certificate',
        'label': 'Barangay certificate of indigency',
        'required': true,
        'hint': 'Issued by your barangay in the last three months.',
      },
      _validId,
    ],
    'fee_centavos': null,
    'processing_days': 1,
    'claim_instructions':
        'Claim it at the MSWDO office, second floor of the Municipal Hall.',
    'accepts': _accepts,
  },
  <String, Object?>{
    'id': 'dt-sample-permit-copy',
    'office': _permits,
    'name': 'Certified copy of a business permit',
    'description': 'A certified copy of a permit already issued to you.',
    'requirements': <Object?>[_validId],
    'fee_centavos': 10000,
    'processing_days': null,
    'claim_instructions': null,
    'accepts': _accepts,
  },
];

Map<String, Object?> _event(
  String? from,
  String to,
  String by,
  String at, {
  String? message,
  String? claimDetails,
}) => <String, Object?>{
  'from_status': from,
  'to_status': to,
  'by': by,
  'message': message,
  'claim_details': claimDetails,
  'at': at,
};

const String _claim =
    'Ready at the Civil Registry window, ground floor of the Municipal Hall, '
    'Monday to Friday, 8:00 AM to 5:00 PM. Bring your valid ID and the fee.';

const String _asked =
    'The barangay certificate you sent was issued in 2025. Please send one '
    'issued in the last three months.';

final List<Map<String, Object?>> _requestFixtures = <Map<String, Object?>>[
  <String, Object?>{
    'id': 'dr-sample-ready',
    'reference_number': 'DR-2026-000118',
    'status': 'ready-for-pickup',
    'type': <String, Object?>{
      'id': 'dt-sample-birth',
      'name': 'Certified copy of a birth record',
    },
    'office': <String, Object?>{
      'id': 'office-sample-mcr',
      'name': 'Municipal Civil Registrar',
    },
    'created_at': '2026-10-27T01:10:00Z',
    'updated_at': '2026-10-30T06:00:00Z',
    'purpose': 'For a school enrolment requirement.',
    'fee_centavos': 5000,
    'processing_days': 3,
    'claim_instructions':
        'Claim it at the Civil Registry window, ground floor of the Municipal '
        'Hall. Bring the ID you sent.',
    'requirements': <Object?>[_validId],
    'attachments': <Object?>[
      <String, Object?>{
        'id': 'att-sample-1',
        'requirement_code': 'valid-id',
        'version': 1,
        'mime_type': 'image/jpeg',
        'byte_size': 412000,
        'current': true,
        'created_at': '2026-10-27T01:10:00Z',
      },
    ],
    'claim_details': _claim,
    'needs_info_message': null,
    'history': <Object?>[
      _event(null, 'submitted', 'resident', '2026-10-27T01:10:00Z'),
      _event('submitted', 'under-review', 'office', '2026-10-28T00:30:00Z'),
      _event('under-review', 'approved', 'office', '2026-10-29T03:00:00Z'),
      _event(
        'approved',
        'ready-for-pickup',
        'office',
        '2026-10-30T06:00:00Z',
        claimDetails: _claim,
      ),
    ],
    'can_cancel': false,
    'can_resubmit': false,
  },
  <String, Object?>{
    'id': 'dr-sample-needs-info',
    'reference_number': 'DR-2026-000124',
    'status': 'needs-info',
    'type': <String, Object?>{
      'id': 'dt-sample-indigency',
      'name': 'Certificate of indigency',
    },
    'office': <String, Object?>{
      'id': 'office-sample-mswdo',
      'name': 'Municipal Social Welfare and Development Office',
    },
    'created_at': '2026-11-02T02:00:00Z',
    'updated_at': '2026-11-03T05:20:00Z',
    'purpose': 'For a hospital bill discount at the provincial hospital.',
    'fee_centavos': null,
    'processing_days': 1,
    'claim_instructions':
        'Claim it at the MSWDO office, second floor of the Municipal Hall.',
    'requirements': <Object?>[
      <String, Object?>{
        'code': 'barangay-certificate',
        'label': 'Barangay certificate of indigency',
        'required': true,
        'hint': 'Issued by your barangay in the last three months.',
      },
      _validId,
    ],
    'attachments': <Object?>[
      <String, Object?>{
        'id': 'att-sample-2',
        'requirement_code': 'barangay-certificate',
        'version': 1,
        'mime_type': 'application/pdf',
        'byte_size': 230000,
        'current': true,
        'created_at': '2026-11-02T02:00:00Z',
      },
      <String, Object?>{
        'id': 'att-sample-3',
        'requirement_code': 'valid-id',
        'version': 1,
        'mime_type': 'image/jpeg',
        'byte_size': 380000,
        'current': true,
        'created_at': '2026-11-02T02:00:00Z',
      },
    ],
    'claim_details': null,
    'needs_info_message': _asked,
    'history': <Object?>[
      _event(null, 'submitted', 'resident', '2026-11-02T02:00:00Z'),
      _event('submitted', 'under-review', 'office', '2026-11-03T01:00:00Z'),
      _event(
        'under-review',
        'needs-info',
        'office',
        '2026-11-03T05:20:00Z',
        message: _asked,
      ),
    ],
    'can_cancel': true,
    'can_resubmit': true,
  },
  <String, Object?>{
    'id': 'dr-sample-released',
    'reference_number': 'DR-2026-000097',
    'status': 'released',
    'type': <String, Object?>{
      'id': 'dt-sample-marriage',
      'name': 'Certified copy of a marriage record',
    },
    'office': <String, Object?>{
      'id': 'office-sample-mcr',
      'name': 'Municipal Civil Registrar',
    },
    'created_at': '2026-10-06T02:00:00Z',
    'updated_at': '2026-10-10T07:45:00Z',
    'purpose': 'For a passport application.',
    'fee_centavos': 5000,
    'processing_days': 3,
    'claim_instructions': null,
    'requirements': <Object?>[_validId],
    'attachments': <Object?>[],
    'claim_details': null,
    'needs_info_message': null,
    'history': <Object?>[
      _event(null, 'submitted', 'resident', '2026-10-06T02:00:00Z'),
      _event('submitted', 'under-review', 'office', '2026-10-06T05:00:00Z'),
      _event('under-review', 'approved', 'office', '2026-10-07T01:00:00Z'),
      _event('approved', 'ready-for-pickup', 'office', '2026-10-08T06:00:00Z'),
      _event('ready-for-pickup', 'released', 'office', '2026-10-10T07:45:00Z'),
    ],
    'can_cancel': false,
    'can_resubmit': false,
  },
];
