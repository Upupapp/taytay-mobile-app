import '../../../core/api/paginated.dart';
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
