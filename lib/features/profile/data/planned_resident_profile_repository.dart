import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/resident_profile_detail.dart';
import '../domain/resident_profile_repository.dart';

/// The [ResidentProfileRepository] this build ships with: it declines, honestly.
///
/// **`ResidentProfile` has been implemented since backend TAB 06** and serves
/// `GET me/profile`; `Identity` serves `GET me`. This file said the module was
/// planned. TAB 04 wires both.
///
/// The division of labour matters and survives the re-baseline: `GET me` is the
/// authority on who the resident is and what state they are in. Verification
/// tier decides what a resident may do, so it is read from the server and never
/// computed here — the app's Article 3 forbids inferring authority client-side,
/// and a tier cached past sign-out is a permission granted to whoever holds the
/// phone next.

class PlannedResidentProfileRepository implements ResidentProfileRepository {
  const PlannedResidentProfileRepository();

  static const UnwiredRepository _repository =
      UnwiredRepository.residentProfile;

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      unwiredRepositoryFailure<ResidentProfileSummary>(
        _repository,
        'loadOwnSummary',
      );

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async =>
      unwiredRepositoryFailure<ResidentProfileDetail>(
        _repository,
        'loadOwnDetail',
      );

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async =>
      unwiredRepositoryFailure<void>(_repository, 'updateContactDetails');

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(_repository, 'submitOwnUpdate');
}
