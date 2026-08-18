import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
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
  const AssistanceApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String draftsPath = 'me/assistance/drafts';

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _apiClient.send<List<ServiceRequest>>(
      method: HttpMethod.get,
      path: draftsPath,
      authenticated: true,
      query: <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'per_page': '${perPage.clamp(1, 100)}',
      },
      decode: _decodeDrafts,
    );
    return response.map(_toPage);
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
    // TWO CALLS, AND ONLY THE SECOND CARRIES THE KEY.
    //
    // Opening a draft is `openOrResume` server-side — it is safe to repeat by
    // construction, and giving it the submit key would spend that key on the
    // wrong operation. Submitting is the irreversible one and is what the key
    // protects: it is the difference between one case and two.
    final Result<ApiEnvelope<String?>> opened = await _apiClient.send<String?>(
      method: HttpMethod.post,
      path: draftsPath,
      authenticated: true,
      body: <String, Object?>{
        'narrative': narrative,
        'requested_service_id': serviceCode,
        // `source` is deliberately not sent. The server takes provenance from
        // the channel header, never from the body: a client claiming `walk-in`
        // would be manufacturing evidence that a clerk saw the person.
        if (consentKeys.isNotEmpty) 'consent_reference': consentKeys.first,
      },
      decode: (Object? data) =>
          data is Map<String, dynamic> ? data['id'] as String? : null,
    );

    switch (opened) {
      case Err<ApiEnvelope<String?>>(:final failure):
        return Err<ServiceRequest>(failure);
      case Ok<ApiEnvelope<String?>>(:final value):
        final String? draftId = value.data;
        if (draftId == null || draftId.isEmpty) {
          return const Err<ServiceRequest>(
            ContractFailure(
              debugMessage: 'A draft was opened with no id to submit it by.',
            ),
          );
        }

        final response = await _apiClient.send<ServiceRequest>(
          method: HttpMethod.post,
          path: '$draftsPath/$draftId/submit',
          authenticated: true,
          idempotencyKey: idempotencyKey,
          decode: _decodeSubmitted,
        );
        return response.map((envelope) => envelope.data);
    }
  }

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async {
    // Discarding an unsubmitted draft. Cancelling a *submitted* case is
    // `me/cases/{case}/cancel` and belongs to TAB 09 — the two are different
    // acts with different consequences, and collapsing them would let a screen
    // withdraw a live application while calling it "discard".
    final response = await _apiClient.send<void>(
      method: HttpMethod.delete,
      path: '$draftsPath/$id',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: (_) {},
    );
    return response.map((_) {});
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
    final response = await _apiClient.send<ServiceRequest?>(
      method: HttpMethod.get,
      path: 'me/cases/$id',
      authenticated: true,
      decode: _decodeOne,
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<ServiceRequest>(
              ContractFailure(debugMessage: 'No readable request in the body.'),
            )
          : Ok<ServiceRequest>(envelope.data!),
    );
  }

  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) =>
      // TAB 09 owns the case surface. Declining here rather than half-wiring it
      // keeps the ledger honest: a repository that answers some of its contract
      // and silently fails the rest is worse than one that says which.
      Future<Result<AssistanceCaseDetail>>.value(
        backendGapFailure<AssistanceCaseDetail>(
          BackendGap.assistanceIntakeForm,
          'loadOwnCase — wired by TAB 09',
        ),
      );

  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int perPage = 25,
  }) => Future<Result<Paginated<AssistanceHistoryEntry>>>.value(
    backendGapFailure<Paginated<AssistanceHistoryEntry>>(
      BackendGap.assistanceIntakeForm,
      'listOwnHistory — wired by TAB 09',
    ),
  );

  static List<ServiceRequest> _decodeDrafts(Object? data) {
    if (data is! List<dynamic>) return const <ServiceRequest>[];
    return data
        .map(_decodeOne)
        .whereType<ServiceRequest>()
        .toList(growable: false);
  }

  static ServiceRequest? _decodeOne(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    if (id is! String || id.isEmpty) return null;

    final Object? state = entry['status'] ?? entry['state'];
    return ServiceRequest(
      id: id,
      serviceCode: entry['requested_service_id'] is String
          ? entry['requested_service_id'] as String
          : '',
      state: ServiceRequestState.fromWire(state is String ? state : null),
      rawState: state is String ? state : '',
      submittedAt: DateTime.tryParse(
        entry['submitted_at'] is String ? entry['submitted_at'] as String : '',
      )?.toUtc(),
      referenceNumber: entry['reference'] is String
          ? entry['reference'] as String
          : null,
    );
  }

  static ServiceRequest _decodeSubmitted(Object? data) {
    final decoded = _decodeOne(data);
    if (decoded != null) return decoded;
    throw const FormatException('submit answered with no readable case');
  }

  static Paginated<ServiceRequest> _toPage(
    ApiEnvelope<List<ServiceRequest>> envelope,
  ) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      // The contract says collections are always paginated; a client that
      // crashes on an omission turns it into an outage.
      return Paginated<ServiceRequest>.single(envelope.data);
    }
    return Paginated<ServiceRequest>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
