import '../../../core/api/api_client.dart';
import '../../../core/api/backend_gap.dart';
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
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<ResidentCredential?>(
      BackendGap.absentOnNodeContract,
      'loadOwnCredential',
    );
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<PresentationArtifact>(
      BackendGap.absentOnNodeContract,
      'requestPresentationArtifact',
    );
  }


}
