import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/resident_profile_detail.dart';
import '../domain/resident_profile_repository.dart';

/// Resident profile repository for a backend module that does not exist yet.
///
/// The `ResidentProfile` module is listed as **planned** in the committed
/// `docs/architecture/domain-boundary-map.md`, and publishes no endpoint. Rather
/// than invent one, every operation declines with a temporary failure — which
/// exercises the real error path and tells the truth. See `planned_backend.dart`
/// for why this is preferred to a mock.

class PlannedResidentProfileRepository implements ResidentProfileRepository {
  const PlannedResidentProfileRepository();

  static const PlannedModule _module = PlannedModule.residentProfile;

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      plannedBackendFailure<ResidentProfileSummary>(_module, 'loadOwnSummary');

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async =>
      plannedBackendFailure<ResidentProfileDetail>(_module, 'loadOwnDetail');

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'updateContactDetails');

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'submitOwnUpdate');
}
