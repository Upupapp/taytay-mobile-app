import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';

/// Verification repository for a backend module that does not exist yet.
///
/// The `Verification` module is listed as **planned** in the committed
/// `docs/architecture/domain-boundary-map.md`, and publishes no endpoint. Rather
/// than invent one, every operation declines with a temporary failure — which
/// exercises the real error path and tells the truth. See `planned_backend.dart`
/// for why this is preferred to a mock.

class PlannedVerificationRepository implements VerificationRepository {
  const PlannedVerificationRepository();

  static const PlannedModule _module = PlannedModule.verification;

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      plannedBackendFailure<VerificationStatus>(_module, 'loadOwnStatus');

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      plannedBackendFailure<VerificationStatusDetail>(
        _module,
        'loadOwnStatusDetail',
      );

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'submitCorrections');

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'submitForReview');
}
