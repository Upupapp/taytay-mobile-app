import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_intake.dart';
import '../domain/lgu_service.dart';
import '../domain/service_request_repository.dart';

/// Service request repository for a backend module that does not exist yet.
///
/// The `ServiceDelivery` module is listed as **planned** in the committed
/// `docs/architecture/domain-boundary-map.md`, and publishes no endpoint. Rather
/// than invent one, every operation declines with a temporary failure — which
/// exercises the real error path and tells the truth. See `planned_backend.dart`
/// for why this is preferred to a mock.

class PlannedServiceRequestRepository implements ServiceRequestRepository {
  const PlannedServiceRequestRepository();

  static const PlannedModule _module = PlannedModule.serviceDelivery;

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 25,
  }) async => plannedBackendFailure<Paginated<ServiceRequest>>(
    _module,
    'listOwnRequests',
  );

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      plannedBackendFailure<ServiceRequest>(_module, 'loadOwnRequest');

  /// Declines rather than returning a question set of the app's own invention.
  ///
  /// This is the operation where mocking would have done the most damage: a
  /// fabricated intake form is the app asking a resident for personal data that
  /// no municipal office requested, under a consent statement nobody with
  /// authority wrote.
  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async =>
      plannedBackendFailure<AssistanceIntakeForm>(_module, 'loadIntakeForm');

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async => plannedBackendFailure<ServiceRequest>(_module, 'submitRequest');

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'cancelOwnRequest');
}
