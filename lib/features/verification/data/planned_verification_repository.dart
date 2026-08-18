import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';

/// The [VerificationRepository] this build ships with: it declines, honestly.
///
/// **The sharpest mis-attribution in the app, and it turns on one English word.**
/// This file claimed the backend's `Verification` module — which is genuinely
/// planned, and which owns "verification attempts, scan events, verifier
/// registry, offline-verification key distribution". That is a *verifier* device
/// scanning a resident's QR at a counter: the `verifier-device` channel, a staff
/// surface this app is forbidden to build.
///
/// What this repository actually does is the resident's own KYC — open an
/// attempt, submit documents, read the outcome, answer a request for more
/// information. That is `ResidentProfile`, implemented since backend TAB 06 and
/// serving `me/kyc`, `me/kyc/submit` and `me/profile/corrections` today.
///
/// Shrinking `PlannedModule` to two members left this file compiling and wrong,
/// because the name it referenced still existed. TAB 04 wires it, and TAB 04 is
/// what makes the app's third state — Verified — actually reachable.

class PlannedVerificationRepository implements VerificationRepository {
  const PlannedVerificationRepository();

  static const UnwiredRepository _repository = UnwiredRepository.residentKyc;

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      unwiredRepositoryFailure<VerificationStatus>(
        _repository,
        'loadOwnStatus',
      );

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      unwiredRepositoryFailure<VerificationStatusDetail>(
        _repository,
        'loadOwnStatusDetail',
      );

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(_repository, 'submitCorrections');

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(_repository, 'submitForReview');
}
