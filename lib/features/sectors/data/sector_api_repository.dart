import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/resident_sector.dart';
import '../domain/sector_repository.dart';
import 'sector_codec.dart';

/// The Node API's sector routes for the signed-in resident (citizen pack B4,
/// D-215). Verified residents only; the server decides that, not this class.
class SectorApiRepository implements SectorRepository {
  const SectorApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<OwnSector>>> listOwn() async {
    final Result<ApiEnvelope<List<OwnSector>>> response = await _apiClient
        .send<List<OwnSector>>(
          method: HttpMethod.get,
          path: 'me/sectors',
          authenticated: true,
          decode: SectorCodec.ownList,
        );
    return response.map((ApiEnvelope<List<OwnSector>> e) => e.data);
  }

  @override
  Future<Result<List<SectorApplication>>> listApplications() async {
    final Result<ApiEnvelope<List<SectorApplication>>> response =
        await _apiClient.send<List<SectorApplication>>(
          method: HttpMethod.get,
          path: 'me/sector-applications',
          authenticated: true,
          decode: SectorCodec.applicationList,
        );
    return response.map((ApiEnvelope<List<SectorApplication>> e) => e.data);
  }

  @override
  Future<Result<String>> uploadProof(CapturedDocument proof) async {
    final Result<ApiEnvelope<String?>> response = await _apiClient
        .send<String?>(
          method: HttpMethod.post,
          path: 'media',
          authenticated: true,
          // The name the phone gave the file often carries a person's name or
          // a document number; the server keeps its own name anyway.
          file: MultipartFile(
            field: 'file',
            filename: proof.mimeType == 'image/png'
                ? 'sector-proof.png'
                : 'sector-proof.jpg',
            bytes: proof.bytes,
            mimeType: proof.mimeType,
          ),
          decode: SectorCodec.mediaId,
        );
    return response.flatMap(
      (ApiEnvelope<String?> envelope) => _present<String>(envelope, 'media'),
    );
  }

  @override
  Future<Result<SectorApplication>> apply({
    required ResidentSector sector,
    required List<String> proofMediaIds,
  }) async {
    final Result<ApiEnvelope<SectorApplication?>> response = await _apiClient
        .send<SectorApplication?>(
          method: HttpMethod.post,
          path: 'me/sector-applications',
          authenticated: true,
          body: SectorCodec.applicationBody(
            sector: sector,
            proofMediaIds: proofMediaIds,
          ),
          decode: SectorCodec.application,
        );
    return response.flatMap(
      (ApiEnvelope<SectorApplication?> envelope) =>
          _present<SectorApplication>(envelope, 'sector application'),
    );
  }

  /// A success with nothing readable in it is a contract failure, not a
  /// blank page.
  static Result<T> _present<T>(ApiEnvelope<T?> envelope, String what) {
    final T? value = envelope.data;
    if (value == null) {
      return Err<T>(
        ContractFailure(
          requestId: envelope.requestId,
          debugMessage: 'The $what response had no readable data.',
        ),
      );
    }
    return Ok<T>(value);
  }
}
