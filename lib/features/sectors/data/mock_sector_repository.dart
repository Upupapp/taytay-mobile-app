import '../../../core/documents/document_capture.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/result/result.dart';
import '../domain/resident_sector.dart';
import '../domain/sector_repository.dart';
import 'sector_codec.dart';

/// Dev-only sectors, for `TAYTAY_DATA=mock`.
///
/// The fixtures are written in the wire shape and read through
/// [SectorCodec], so the mock exercises the decoder the live build uses.
/// Everything here is synthetic. Staging and production never construct this
/// class.
class MockSectorRepository implements SectorRepository {
  MockSectorRepository(this._behavior);

  final MockBehaviorController _behavior;

  late final List<OwnSector> _own = SectorCodec.ownList(<Object?>[
    <String, Object?>{
      'sector': 'pwd',
      'since': '2026-01-15',
      'id_number': '••••0000',
      'valid_until': '2029-01-15',
    },
  ]);

  late final List<SectorApplication> _applications =
      SectorCodec.applicationList(<Object?>[
        <String, Object?>{
          'id': 'sa-sample-1',
          'sector': 'solo-parent',
          'status': 'pending',
          'reason': null,
          'submitted_at': '2026-11-02T06:41:00Z',
          'decided_at': null,
        },
      ]);

  int _uploaded = 0;
  int _filed = 0;

  @override
  Future<Result<List<OwnSector>>> listOwn() =>
      _behavior.respond<List<OwnSector>>(List<OwnSector>.unmodifiable(_own));

  @override
  Future<Result<List<SectorApplication>>> listApplications() =>
      _behavior.respond<List<SectorApplication>>(
        List<SectorApplication>.unmodifiable(_applications),
      );

  @override
  Future<Result<String>> uploadProof(CapturedDocument proof) {
    _uploaded++;
    return _behavior.respond<String>('media-sample-$_uploaded');
  }

  @override
  Future<Result<SectorApplication>> apply({
    required ResidentSector sector,
    required List<String> proofMediaIds,
  }) {
    // The two refusals the server answers with a conflict.
    final bool held = _own.any((OwnSector own) => own.sector == sector);
    final bool waiting = _applications.any(
      (SectorApplication a) =>
          a.sector == sector && a.status == SectorApplicationStatus.pending,
    );
    if (held || waiting) {
      return Future<Result<SectorApplication>>.value(
        const Err<SectorApplication>(
          ConflictFailure(debugMessage: 'Mock: held or already waiting.'),
        ),
      );
    }
    _filed++;
    final SectorApplication? filed = SectorCodec.application(<String, Object?>{
      'id': 'sa-sample-new-$_filed',
      'sector': SectorCodec.wireSector(sector),
      'status': 'pending',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    });
    if (filed == null) {
      return Future<Result<SectorApplication>>.value(
        const Err<SectorApplication>(
          ContractFailure(debugMessage: 'Mock application did not decode.'),
        ),
      );
    }
    _applications.insert(0, filed);
    return _behavior.respond<SectorApplication>(filed);
  }
}
