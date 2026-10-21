import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';
import '../domain/digital_id.dart';

/// `GET /api/v1/me/digital-id` for a verified resident.
///
/// The response is the card plus a QR. The QR carries its own `expires_at`.
/// This repository keeps the last card in memory and fetches again when that
/// QR is inside [digitalIdQrRefreshLead] of expiry. Nothing is written to
/// disk.
///
/// `POST /api/v1/digital-id/verify` is the staff scan. [verifyScannedToken]
/// names it and does not send it.
class CredentialApiRepository implements CredentialRepository {
  CredentialApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/digital-id';

  DigitalIdCard? _held;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    final Result<DigitalIdCard> card = await loadDigitalId();
    return switch (card) {
      Ok(:final value) => Ok<ResidentCredential?>(
        credentialFromDigitalId(value),
      ),
      Err(:final failure) when failure is NotFoundFailure =>
        const Ok<ResidentCredential?>(null),
      Err(:final failure) => Err<ResidentCredential?>(failure),
    };
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    final Result<DigitalIdCard> card = await loadDigitalId();
    return switch (card) {
      Ok(:final value) => _artifact(value),
      Err(:final failure) => Err<PresentationArtifact>(failure),
    };
  }

  @override
  Future<Result<DigitalIdCard>> loadDigitalId({DateTime? now}) async {
    final DateTime clock = (now ?? DateTime.now()).toUtc();
    final DigitalIdCard? held = _held;
    if (held != null && !held.qrRefreshDue(clock)) {
      return Ok<DigitalIdCard>(held);
    }
    return _fetch();
  }

  @override
  Future<Result<DigitalIdHolder>> verifyScannedToken({
    required String token,
  }) async {
    final Object _ = _apiClient.runtimeType;
    if (token.trim().isEmpty) {
      return const Err<DigitalIdHolder>(
        ValidationFailure(debugMessage: 'A token is required.'),
      );
    }
    // Staff scan. The resident channel does not send this request.
    return const Err<DigitalIdHolder>(
      ForbiddenFailure(debugMessage: 'Staff scan is not a resident action.'),
    );
  }

  Future<Result<DigitalIdCard>> _fetch() async {
    final Result<ApiEnvelope<DigitalIdCard>> response = await _apiClient
        .send<DigitalIdCard>(
          method: HttpMethod.get,
          path: path,
          authenticated: true,
          decode: _decodeCard,
        );
    if (response case Ok(:final value)) {
      _held = value.data;
    }
    return response.map((ApiEnvelope<DigitalIdCard> envelope) => envelope.data);
  }

  static Result<PresentationArtifact> _artifact(DigitalIdCard card) {
    final PresentationArtifact? artifact = presentationFromDigitalId(card);
    if (artifact == null) {
      return const Err<PresentationArtifact>(
        NotFoundFailure(debugMessage: 'The card has no QR payload.'),
      );
    }
    return Ok<PresentationArtifact>(artifact);
  }

  static DigitalIdCard _decodeCard(Object? data) {
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final String? id = _text(map['id']);
    final String? idNumber = _text(map['id_number']);
    final String? photo = _text(map['photo_media_id']);
    final String? rawStatus = _text(map['status']);
    final DateTime? issued = _instant(map['issued_at']);
    final DateTime? expires = _instant(map['expires_at']);
    if (id == null ||
        idNumber == null ||
        photo == null ||
        rawStatus == null ||
        issued == null ||
        expires == null) {
      throw const FormatException('Digital ID card.');
    }
    return DigitalIdCard(
      id: id,
      idNumber: idNumber,
      photoMediaId: photo,
      status: DigitalIdStatus.fromWire(rawStatus),
      rawStatus: rawStatus,
      issuedAt: issued,
      expiresAt: expires,
      qr: _decodeQr(map['qr']),
    );
  }

  static DigitalIdQr? _decodeQr(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final String? token = _text(raw['token']);
    final DateTime? expires = _instant(raw['expires_at']);
    if (token == null || expires == null) {
      throw const FormatException('Digital ID QR.');
    }
    return DigitalIdQr(token: token, expiresAt: expires);
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _instant(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim())?.toUtc();
  }
}
