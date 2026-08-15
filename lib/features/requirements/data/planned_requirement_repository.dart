import '../../../core/api/planned_backend.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/resident_requirement.dart';

/// Requirements for a backend module that does not exist yet.
///
/// `ServiceDelivery` owns "service applications and transactions against catalog
/// entries … their state machines and attachments" and is listed as **planned**
/// in the committed boundary map. It publishes no requirement list and no upload
/// endpoint, so both operations decline.
///
/// **Declining matters more here than anywhere else in the app.** A mocked
/// upload that reported success would tell a resident their barangay clearance
/// had reached Taytay LGU when nothing had left the phone — and they would find
/// out at the counter, having travelled there on the strength of it.
class PlannedRequirementRepository implements RequirementRepository {
  const PlannedRequirementRepository();

  static const PlannedModule _module = PlannedModule.serviceDelivery;

  @override
  Future<Result<RequirementChecklist>> listRequirements(
    String requestId,
  ) async =>
      plannedBackendFailure<RequirementChecklist>(_module, 'listRequirements');

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
    return plannedBackendFailure<UploadedDocumentReference>(
      _module,
      'uploadRequirementDocument',
    );
  }
}
