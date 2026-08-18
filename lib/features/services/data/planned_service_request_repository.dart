import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_case.dart';
import '../domain/assistance_history.dart';
import '../domain/assistance_intake.dart';
import '../domain/lgu_service.dart';
import '../domain/service_request_repository.dart';

/// The [ServiceRequestRepository] this build ships with: it declines, honestly.
///
/// **Mis-filed under the wrong module.** This file named `ServiceDelivery`,
/// which is genuinely planned — and which owns national service transactions
/// (dokumento, buwis, kalusugan, trabaho), not this. What a resident does here —
/// open an assistance draft, submit it, follow the case, read their history —
/// is `Welfare`, implemented since backend TAB 11 and serving
/// `me/assistance/drafts`, `me/cases`, `me/assistance-history` and `me/referrals`
/// today.
///
/// Shrinking `PlannedModule` to the truth did not catch this: `serviceDelivery`
/// still exists and still means something real, just not this. Only reading the
/// two contracts side by side did. TAB 08 wires the drafts; TAB 09 the cases.

class PlannedServiceRequestRepository implements ServiceRequestRepository {
  const PlannedServiceRequestRepository();

  static const UnwiredRepository _repository =
      UnwiredRepository.serviceRequests;

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 25,
  }) async => unwiredRepositoryFailure<Paginated<ServiceRequest>>(
    _repository,
    'listOwnRequests',
  );

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      unwiredRepositoryFailure<ServiceRequest>(_repository, 'loadOwnRequest');

  /// Declines rather than composing a plausible history.
  ///
  /// A fabricated timeline is the most convincing lie this app could tell: it
  /// looks exactly like progress, and a resident reading "Under verification —
  /// 12 August" would stop chasing an application that does not exist.
  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) async =>
      unwiredRepositoryFailure<AssistanceCaseDetail>(
        _repository,
        'loadOwnCase',
      );

  /// Declines rather than showing an empty history.
  ///
  /// The distinction matters more here than it looks. "You have never received
  /// assistance from Taytay LGU" and "we cannot reach Taytay LGU" are different
  /// statements, and the first one — shown wrongly — is the app telling a
  /// resident their record does not exist.
  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int perPage = 25,
  }) async => unwiredRepositoryFailure<Paginated<AssistanceHistoryEntry>>(
    _repository,
    'listOwnHistory',
  );

  /// Declines rather than returning a question set of the app's own invention.
  ///
  /// This is the operation where mocking would have done the most damage: a
  /// fabricated intake form is the app asking a resident for personal data that
  /// no municipal office requested, under a consent statement nobody with
  /// authority wrote.
  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async => unwiredRepositoryFailure<AssistanceIntakeForm>(
    _repository,
    'loadIntakeForm',
  );

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async =>
      unwiredRepositoryFailure<ServiceRequest>(_repository, 'submitRequest');

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(_repository, 'cancelOwnRequest');
}
