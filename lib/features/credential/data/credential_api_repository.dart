import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';

/// Talks to `GET me/credential` and `POST me/credential/qr`.
///
/// ---
///
/// **Built, and switched off.** `Credential` is implemented at the baseline and
/// `credential.enabled` is false, so the whole surface answers `404` — a feature
/// that is not live should look absent rather than forbidden (backend ADR 0011).
/// That makes a plain `NotFoundFailure` ambiguous here: it means either "the LGU
/// has not switched the digital ID on" or "you do not have one yet", and those
/// are different sentences to a resident. Neither is an error.
///
/// So both resolve to `null` — no credential to show — and the screen decides
/// what to say from the `digital_id` flag on `GET app/bootstrap`, which is the
/// only thing that can tell the two apart. Both states ship in one build, which
/// is what lets the municipality enable the ID for real residents without a new
/// app release.
///
/// **The verifier side is not here and must never be.** `POST
/// credential-verifications` exists and belongs to the `verifier-device`
/// channel; building it would put a staff surface in the resident repository,
/// which Article 0 forbids outright.
class CredentialApiRepository implements CredentialRepository {
  const CredentialApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    final response = await _apiClient.send<ResidentCredential?>(
      method: HttpMethod.get,
      path: 'me/credential',
      authenticated: true,
      decode: _decode,
    );

    return switch (response) {
      Ok<dynamic>() => Ok<ResidentCredential?>(response.valueOrNull!.data),
      // See the class doc: absent is not an error on this path.
      Err<dynamic>(:final failure) when failure is NotFoundFailure =>
        const Ok<ResidentCredential?>(null),
      Err<dynamic>(:final failure) => Err<ResidentCredential?>(failure),
    };
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    // Minted on demand, when the resident opens their ID to present it. Never
    // pre-fetched and never kept: a code held in advance is a code that has
    // expired by the time it is needed, and one written down is one that can be
    // taken out of a backup.
    final response = await _apiClient.send<PresentationArtifact>(
      method: HttpMethod.post,
      path: 'me/credential/qr',
      authenticated: true,
      decode: _decodeArtifact,
    );
    return response.map((envelope) => envelope.data);
  }

  static ResidentCredential? _decode(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? id = map['id'];
    if (id is! String || id.isEmpty) return null;

    final Object? status = map['status'];
    return ResidentCredential(
      id: id,
      state: CredentialLifecycleState.fromWire(
        status is String ? status : null,
      ),
      rawState: status is String ? status : '',
      issuedAt: DateTime.tryParse(
        map['issued_at'] is String ? map['issued_at'] as String : '',
      )?.toUtc(),
      expiresAt: DateTime.tryParse(
        map['expires_at'] is String ? map['expires_at'] as String : '',
      )?.toUtc(),
    );
  }

  static PresentationArtifact _decodeArtifact(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? payload = map['payload'];
    return PresentationArtifact(
      payload: payload is String ? payload : '',
      expiresAt: DateTime.tryParse(
        map['expires_at'] is String ? map['expires_at'] as String : '',
      )?.toUtc(),
    );
  }
}
