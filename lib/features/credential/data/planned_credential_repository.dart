import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';

/// The [CredentialRepository] this build ships with: it declines, honestly.
///
/// **`Credential` is not planned — it is built and switched off.** It has been
/// implemented since backend TAB 06 and serves `GET me/credential` and
/// `POST me/credential/qr`; what it also carries is a second axis this file had
/// no way to express, `credential.enabled`, currently false. Status on this
/// platform is two questions — built, and enabled — and collapsing them is how
/// TAB 06 would have been planned against a false premise the same way this file
/// was.
///
/// So the digital ID needs both halves: TAB 06 wires the repository, and the LGU
/// lifts the flag deliberately and in coordination. Both states must ship in one
/// build, driven by `digital_id` on `GET app/bootstrap` — never hardcoded — so
/// the ID can be switched on for real residents without a new app version.

class PlannedCredentialRepository implements CredentialRepository {
  const PlannedCredentialRepository();

  static const UnwiredRepository _repository = UnwiredRepository.credential;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async =>
      unwiredRepositoryFailure<ResidentCredential?>(
        _repository,
        'loadOwnCredential',
      );

  @override
  Future<Result<String>> requestPresentationArtifact() async =>
      unwiredRepositoryFailure<String>(
        _repository,
        'requestPresentationArtifact',
      );
}
