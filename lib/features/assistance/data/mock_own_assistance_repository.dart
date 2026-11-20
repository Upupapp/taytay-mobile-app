import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/result/result.dart';
import '../domain/own_assistance_repository.dart';
import '../domain/own_assistance_request.dart';
import 'own_assistance_codec.dart';

/// Dev-only assistance requests, for `TAYTAY_DATA=mock`.
///
/// Written in the wire shape and read through [OwnAssistanceCodec], so the
/// mock exercises the decoder the live build uses. Everything here is
/// synthetic, and nobody in it is a real resident. Staging and production
/// never construct this class.
class MockOwnAssistanceRepository implements OwnAssistanceRepository {
  MockOwnAssistanceRepository(this._behavior);

  final MockBehaviorController _behavior;

  late final List<OwnAssistanceRequest> _rows = OwnAssistanceCodec.list(
    <Object?>[
      <String, Object?>{
        'id': 'ar-sample-returned',
        'reference_number': 'TAY-SAMPLE-0004',
        'program_name': 'Sample medical assistance',
        'filed_at': '2026-11-14T01:15:00Z',
        'status': 'returned',
        'status_changed_at': '2026-11-17T02:00:00Z',
        'approved_amount_centavos': null,
        'payout_scheduled_for': null,
        'payout_venue': null,
        'released_at': null,
        'channel': 'online',
        'missing_documents': <Object?>[
          <String, Object?>{
            'code': 'sample-medical-certificate',
            'name': 'Sample medical certificate',
            'state': 'send-again',
            'instruction': 'Sample: a clear photo of the whole page.',
          },
        ],
      },
      <String, Object?>{
        'id': 'ar-sample-scheduled',
        'reference_number': 'AR-SAMPLE-0003',
        'program_name': 'Sample burial assistance',
        'filed_at': '2026-11-03T01:15:00Z',
        'status': 'scheduled',
        'status_changed_at': '2026-11-12T02:00:00Z',
        'approved_amount_centavos': 500000,
        'payout_scheduled_for': '2026-11-20',
        'payout_venue': 'Sample venue, Taytay',
        'released_at': null,
      },
      <String, Object?>{
        'id': 'ar-sample-assessment',
        'reference_number': 'AR-SAMPLE-0002',
        'program_name': 'Sample medical assistance',
        'filed_at': '2026-10-21T03:40:00Z',
        'status': 'assessment',
        'status_changed_at': '2026-10-24T05:00:00Z',
        'approved_amount_centavos': null,
        'payout_scheduled_for': null,
        'payout_venue': null,
        'released_at': null,
      },
      <String, Object?>{
        'id': 'ar-sample-released',
        'reference_number': 'AR-SAMPLE-0001',
        'program_name': 'Sample educational assistance',
        'filed_at': '2026-08-05T00:30:00Z',
        'status': 'completed',
        'status_changed_at': '2026-08-28T06:10:00Z',
        'approved_amount_centavos': 300000,
        'payout_scheduled_for': null,
        'payout_venue': null,
        'released_at': '2026-08-28T06:10:00Z',
      },
    ],
  );

  @override
  Future<Result<Paginated<OwnAssistanceRequest>>> listOwn({String? cursor}) =>
      _behavior.respond<Paginated<OwnAssistanceRequest>>(
        Paginated<OwnAssistanceRequest>.single(
          cursor == null
              ? List<OwnAssistanceRequest>.unmodifiable(_rows)
              : const <OwnAssistanceRequest>[],
        ),
      );

  int _filed = 0;

  /// Files a synthetic request at the top of the list, as `submitted` with a
  /// sample control number. Nothing leaves the phone.
  @override
  Future<Result<OwnAssistanceRequest>> apply({
    required String serviceSlug,
    required String purpose,
    int? requestedAmountCentavos,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final Result<void> gate = await _behavior.respond<void>(null);
    if (gate case Err(:final failure)) {
      return Err<OwnAssistanceRequest>(failure);
    }
    _filed++;
    final String now = DateTime.now().toUtc().toIso8601String();
    final OwnAssistanceRequest? row = OwnAssistanceCodec.row(<String, dynamic>{
      'id': 'ar-sample-applied-$_filed',
      'reference_number': 'TAY-SAMPLE-1${_filed.toString().padLeft(3, '0')}',
      'program_name': 'Sample assistance applied for in the app',
      'filed_at': now,
      'status': 'submitted',
      'status_changed_at': now,
      'channel': 'online',
      'missing_documents': <Object?>[],
    });
    if (row == null) {
      return const Err<OwnAssistanceRequest>(
        UnexpectedFailure(debugMessage: 'Mock: the sample row did not decode.'),
      );
    }
    _rows.insert(0, row);
    return Ok<OwnAssistanceRequest>(row);
  }

  /// Marks a returned sample request's documents as sent: the list stops
  /// naming them, and the status stays returned, as the office moves it.
  @override
  Future<Result<OwnAssistanceRequest>> addDocuments(
    String requestId, {
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    final Result<void> gate = await _behavior.respond<void>(null);
    if (gate case Err(:final failure)) {
      return Err<OwnAssistanceRequest>(failure);
    }
    final int index = _rows.indexWhere(
      (OwnAssistanceRequest row) => row.id == requestId,
    );
    if (index < 0) {
      return const Err<OwnAssistanceRequest>(
        NotFoundFailure(debugMessage: 'Mock: not in the list.'),
      );
    }
    final OwnAssistanceRequest before = _rows[index];
    if (!before.takesDocuments) {
      return const Err<OwnAssistanceRequest>(
        ConflictFailure(debugMessage: 'Mock: not returned.'),
      );
    }
    final OwnAssistanceRequest after = OwnAssistanceRequest(
      id: before.id,
      referenceNumber: before.referenceNumber,
      programName: before.programName,
      filedAt: before.filedAt,
      status: before.status,
      statusChangedAt: before.statusChangedAt,
      channel: before.channel,
      missingDocuments: <MissingDocument>[
        for (final MissingDocument document in before.missingDocuments)
          if (!files.containsKey(document.code)) document,
      ],
    );
    _rows[index] = after;
    return Ok<OwnAssistanceRequest>(after);
  }

  @override
  Future<Result<OwnAssistanceRequest>> findOwn(String id) async {
    final Result<Paginated<OwnAssistanceRequest>> page = await listOwn();
    return switch (page) {
      Err(:final failure) => Err<OwnAssistanceRequest>(failure),
      Ok(:final value) => _find(value.items, id),
    };
  }

  static Result<OwnAssistanceRequest> _find(
    List<OwnAssistanceRequest> items,
    String id,
  ) {
    for (final OwnAssistanceRequest item in items) {
      if (item.id == id) return Ok<OwnAssistanceRequest>(item);
    }
    return const Err<OwnAssistanceRequest>(
      NotFoundFailure(debugMessage: 'Mock: not in the list.'),
    );
  }
}
