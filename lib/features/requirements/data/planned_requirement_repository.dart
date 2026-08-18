import '../../../core/api/unwired_repository.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/resident_requirement.dart';

/// The [RequirementRepository] this build ships with: it declines, honestly.
///
/// **Mis-filed under the wrong module**, in the same way as the assistance
/// requests it belongs to. This file named the planned `ServiceDelivery`;
/// requirements are `Welfare` (`GET me/cases/{case}/requirements`) and the
/// documents behind them are `Files` (`documents/{handle}` and the upload and
/// single-use access routes). Both have been implemented since backend TAB 11
/// and TAB 15 respectively. TAB 10 wires them.
///
/// **Declining matters more here than anywhere else in the app.** A mocked
/// upload that reported success would tell a resident their barangay clearance
/// had reached Taytay LGU when nothing had left the phone — and they would find
/// out at the counter, having travelled there on the strength of it.
class PlannedRequirementRepository implements RequirementRepository {
  const PlannedRequirementRepository();

  static const UnwiredRepository _repository = UnwiredRepository.requirements;

  @override
  Future<Result<RequirementChecklist>> listRequirements(
    String requestId,
  ) async => unwiredRepositoryFailure<RequirementChecklist>(
    _repository,
    'listRequirements',
  );

  @override
  Future<Result<UploadedDocumentReference>> uploadRequirementDocument({
    required String requestId,
    required String requirementCode,
    required CapturedDocument document,
    required String idempotencyKey,
    void Function(double fraction)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    // Deliberately no progress callback: reporting bytes moving for an upload
    // that is not happening is the one lie this class exists to avoid.
    return unwiredRepositoryFailure<UploadedDocumentReference>(
      _repository,
      'uploadRequirementDocument',
    );
  }
}
