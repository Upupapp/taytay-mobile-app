import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import 'resident_sector.dart';

/// The signed-in resident's own sectors and sector applications (D-215).
///
/// Every route is `/me`-scoped: there is no resident id to pass, so there is
/// nothing to put in a path. The server sends only the resident's own,
/// non-sensitive sectors.
abstract interface class SectorRepository {
  /// `GET /me/sectors`.
  Future<Result<List<OwnSector>>> listOwn();

  /// `GET /me/sector-applications`.
  Future<Result<List<SectorApplication>>> listApplications();

  /// `POST /media`: the photo of the sector ID. Answers the opaque id the
  /// application names.
  Future<Result<String>> uploadProof(CapturedDocument proof);

  /// `POST /me/sector-applications`: the sector and one to four proof ids.
  Future<Result<SectorApplication>> apply({
    required ResidentSector sector,
    required List<String> proofMediaIds,
  });
}
