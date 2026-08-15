import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import 'assistance_intake.dart';
import 'lgu_service.dart';

/// Lifecycle of an application a resident submits against a catalogue entry.
///
/// The `ServiceDelivery` module owns "service applications/transactions against
/// catalog entries … their state machines and attachments" per the committed
/// boundary map. The states below are the shape that map describes; wire values
/// are not published and none are assigned.
enum ServiceRequestState {
  draft,
  submitted,
  underReview,
  needsMoreInformation,
  approved,
  readyForRelease,
  completed,
  rejected,
  cancelled;

  bool get isTerminal =>
      this == ServiceRequestState.completed ||
      this == ServiceRequestState.rejected ||
      this == ServiceRequestState.cancelled;
}

/// One application the resident has made.
@immutable
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.serviceCode,
    required this.state,
    required this.rawState,
    required this.submittedAt,
    this.referenceNumber,
  });

  final String id;

  /// The catalogue entry this was filed against, by its stable `code`.
  final String serviceCode;

  final ServiceRequestState? state;

  /// The server's own value, preserved.
  final String rawState;

  final DateTime? submittedAt;

  /// The number a resident quotes at the municipal hall.
  final String? referenceNumber;

  @override
  String toString() => 'ServiceRequest($serviceCode, $rawState)';
}

/// Applications the signed-in resident has filed.
///
/// **No eligibility logic lives here or above.** Whether a resident may apply
/// for a service is decided by the server on submission. The app does not
/// pre-judge it: a client-side eligibility rule is a second rule set that drifts
/// from the real one, and it would tell a resident they cannot apply when the
/// office would have accepted them.
abstract interface class ServiceRequestRepository {
  /// The resident's own applications. Never another person's.
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page,
    int perPage,
  });

  Future<Result<ServiceRequest>> loadOwnRequest(String id);

  /// What this service's application asks for, as the server describes it.
  ///
  /// The app holds no per-service question list of its own — see
  /// `assistance_intake.dart` for why. The response also carries the server's
  /// statement about an application already in progress
  /// ([AssistanceIntakeForm.activeRequest]), which is the only source for the
  /// duplicate warning: the client never infers one.
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(String serviceCode);

  /// Files an application against a catalogue entry.
  ///
  /// [idempotencyKey] is required. This is the operation the idempotency rule
  /// exists for: a duplicate document application is a real cost to the resident
  /// and to the office that processes it, and a dropped connection after the
  /// server committed is indistinguishable from one before.
  ///
  /// [consentKeys] are the acknowledgements the resident gave, by the key the
  /// server declared them under. They travel as their own argument rather than
  /// inside [answers] because a consent is a legal record of what a person
  /// agreed to under RA 10173, not an answer to a question, and it must be
  /// impossible to lose it in a map merge.
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  });

  /// Withdraws an application the resident filed.
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  });
}
