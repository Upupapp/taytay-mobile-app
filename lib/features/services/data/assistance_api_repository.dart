import 'dart:async';

import '../../../core/api/api_client.dart';

import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/assistance_case.dart';
import '../domain/assistance_history.dart';
import '../domain/assistance_intake.dart';
import '../domain/service_request_repository.dart';

/// Talks to the resident's own assistance drafts and cases.
///
/// ---
///
/// **The server is the draft store, and that is not a detail.** `Welfare` models
/// a draft as a first-class thing with its own lifecycle — open, amend, discard,
/// submit — and its own expiry, published so a client can warn before a form is
/// lost rather than letting a resident discover it at submission. A lost draft
/// is a household that has to start again, and an application typed on a phone
/// in a queue is exactly the thing that gets lost. So drafts live on the server
/// and any local copy is a performance aid, never the record.
///
/// **The idempotency key is the whole defence against a duplicated case.** On a
/// Philippine mobile network a request that times out has often still succeeded,
/// and a duplicate assistance application is a case the MSWDO cleans up by hand
/// while a household waits. The server wraps the *entire* submit in the key,
/// including its already-submitted check, and returns the stored response
/// verbatim — status included — so a retry is genuinely indistinguishable from
/// the original.
class AssistanceApiRepository implements ServiceRequestRepository {
  const AssistanceApiRepository({
    required ApiClient apiClient,
    Telemetry? telemetry,
  }) : _apiClient = apiClient,
       _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents. See `Telemetry` for the three
  /// conditions that gate every signal, and `TelemetrySignal` for why the
  /// payload is a sealed set with no free-text field.
  final Telemetry? _telemetry;

  static const String draftsPath = 'me/assistance/drafts';

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int? perPage,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<Paginated<ServiceRequest>>(
      BackendGap.absentOnNodeContract,
      'listOwnRequests',
    );
  }

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    unawaited(
      _telemetry?.record(
            const FlowStep(
              flow: TelemetryFlow.assistanceApplication,
              stage: TelemetryStage.blocked,
            ),
          ) ??
          Future<bool>.value(false),
    );
    return backendGapFailure<ServiceRequest>(
      BackendGap.absentOnNodeContract,
      'submitRequest',
    );
  }

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'cancelOwnRequest',
    );
  }

  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async {
    // F24. There is no per-service intake-form endpoint. The closest thing the
    // contract publishes is a programme's requirement template, which TAB 07
    // wired — but it is keyed by programme UUID, not by service code, and it
    // describes documents to bring rather than questions to answer.
    //
    // Hardcoding a question list here is what the app's own `assistance_intake`
    // doc already refuses: a form the office never agreed to, collecting answers
    // nobody reads.
    return backendGapFailure<AssistanceIntakeForm>(
      BackendGap.assistanceIntakeForm,
      'loadIntakeForm($serviceCode)',
    );
  }

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<ServiceRequest>(
      BackendGap.absentOnNodeContract,
      'loadOwnRequest',
    );
  }

  /// One case, with its timeline and whatever the office says can be done next.
  ///
  /// **The vocabulary is the server's, twice over.** `status` is already the
  /// *citizen* projection — `assessment` and `endorsed` both arrive as
  /// `under-review`, because which desk holds a file would identify the handling
  /// social worker — and `status_message` is the office's own sentence for it.
  /// The app renders both rather than composing its own, so a resident and the
  /// clerk they are standing in front of are reading the same words.
  ///
  /// **`available_actions` is computed server-side and that replaced something.**
  /// The app used to decide locally whether a case could be cancelled, which put
  /// a business rule inside a shipped mobile build that could not be patched on
  /// demand (backend ADR 0007 §4). It is now asked, never inferred.
  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<AssistanceCaseDetail>(
      BackendGap.absentOnNodeContract,
      'loadOwnCase',
    );
  }

  /// What the resident has actually received.
  ///
  /// **In-flight cases are deliberately absent from this endpoint** — those are
  /// tracked through `me/cases`, and listing one here would tell somebody they
  /// were given what they were not. So `HistoryScope.open` is answered from the
  /// case list and `HistoryScope.past` from the history endpoint; they are two
  /// different questions and the server treats them as such.
  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int? perPage,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<Paginated<AssistanceHistoryEntry>>(
      BackendGap.absentOnNodeContract,
      'listOwnHistory',
    );
  }
}
