import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';

/// Credential repository for a backend module that does not exist yet.
///
/// The `Credential` module is listed as **planned** in the committed
/// `docs/architecture/domain-boundary-map.md`, and publishes no endpoint. Rather
/// than invent one, every operation declines with a temporary failure — which
/// exercises the real error path and tells the truth. See `planned_backend.dart`
/// for why this is preferred to a mock.

class PlannedCredentialRepository implements CredentialRepository {
  const PlannedCredentialRepository();

  static const PlannedModule _module = PlannedModule.credential;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async =>
      plannedBackendFailure<ResidentCredential?>(_module, 'loadOwnCredential');

  @override
  Future<Result<String>> requestPresentationArtifact() async =>
      plannedBackendFailure<String>(_module, 'requestPresentationArtifact');
}
