import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';
import '../domain/digital_id_face.dart';

/// Talks to `GET /me/digital-id`.
///
/// A 404 and a null body are both "not issued". The verifier scan
/// (`POST /digital-id/verify`) is another channel and is not called here.
class CredentialApiRepository implements CredentialRepository {
  const CredentialApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/digital-id';
  static const String profilePath = 'me';

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    final response = await _apiClient.send<ResidentCredential?>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: decodeDigitalId,
    );
    return switch (response) {
      Ok(:final value) => Ok<ResidentCredential?>(value.data),
      Err(:final failure) when failure is NotFoundFailure =>
        const Ok<ResidentCredential?>(null),
      Err(:final failure) => Err<ResidentCredential?>(failure),
    };
  }

  @override
  Future<Result<String?>> loadResidentName() async {
    final response = await _apiClient.send<String?>(
      method: HttpMethod.get,
      path: profilePath,
      authenticated: true,
      decode: decodeResidentName,
    );
    return switch (response) {
      Ok(:final value) => Ok<String?>(value.data),
      Err(:final failure) => Err<String?>(failure),
    };
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    final Result<ResidentCredential?> loaded = await loadOwnCredential();
    if (loaded case Err(:final failure)) {
      return Err<PresentationArtifact>(failure);
    }
    final PresentationArtifact? qr = loaded.valueOrNull?.qr;
    if (qr == null) {
      return const Err<PresentationArtifact>(
        NotFoundFailure(debugMessage: 'No digital ID QR is current.'),
      );
    }
    return Ok<PresentationArtifact>(qr);
  }

  /// GET /me `data.name`. Trimmed. Null when missing or blank.
  static String? decodeResidentName(Object? data) {
    if (data is! Map) return null;
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final Object? name = map['name'];
    if (name is! String) return null;
    return publishedResidentName(name);
  }

  /// `DigitalIdCard` plus `qr`, which is an object or null.
  static ResidentCredential? decodeDigitalId(Object? data) {
    if (data == null) return null;
    if (data is! Map) return null;
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final Object? id = map['id'];
    final Object? idNumber = map['id_number'];
    final Object? status = map['status'];
    if (id is! String || id.isEmpty) return null;
    final String rawState = status is String ? status : '';
    final Object? photo = map['photo_media_id'];
    return ResidentCredential(
      id: id,
      idNumber: idNumber is String && idNumber.isNotEmpty ? idNumber : null,
      photoMediaId: photo is String && photo.isNotEmpty ? photo : null,
      state: CredentialLifecycleState.fromWire(
        rawState.isEmpty ? null : rawState,
      ),
      rawState: rawState,
      issuedAt: _time(map['issued_at']),
      expiresAt: _time(map['expires_at']),
      qr: _qr(map['qr']),
    );
  }

  static PresentationArtifact? _qr(Object? raw) {
    if (raw == null || raw is! Map) return null;
    final Map<String, dynamic> map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final Object? token = map['token'];
    if (token is! String || token.isEmpty) return null;
    return PresentationArtifact(
      payload: token,
      expiresAt: _time(map['expires_at']),
    );
  }

  static DateTime? _time(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}
