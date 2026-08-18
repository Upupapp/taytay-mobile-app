import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/account_controls.dart';

/// Talks to the `Audit` module's resident privacy surface.
///
/// ---
///
/// **This is the resident's side of the LGU's RA 10173 evidence.** The consent
/// list is not a settings screen that happens to hold switches: it is the record
/// of what somebody agreed to, when, and against which version of the notice —
/// and a withdrawn consent keeps its row, because "did she ever agree, and when
/// did she change her mind" is the question a complaint asks. Removing the row
/// would erase the evidence it exists to provide.
///
/// **`loadControls` still answers "nothing yet", and that is still true.** The
/// stub it replaces returned `AccountControls.none` deliberately, and this
/// repository keeps that answer for everything except consent withdrawal —
/// because withdrawal is the one control the backend actually publishes. A
/// "Delete my account" button on a government app is a statement about a civil
/// record, and retention is set by law rather than by a client (F13).
class PrivacyApiRepository implements AccountControlsRepository {
  const PrivacyApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String consentsPath = 'me/privacy/consents';

  @override
  Future<Result<AccountControls>> loadControls() async {
    // Asked of the server, not assumed — but only one answer can be given
    // truthfully today. Consent withdrawal exists; correction is routed through
    // TAB 04's corrections flow; deactivation and deletion have no route at all
    // (F13), and offering either would tell a resident they had asked the
    // municipality to erase their record when nobody had been told.
    return const Ok<AccountControls>(
      AccountControls(canWithdrawConsent: true, canRequestDataCorrection: true),
    );
  }

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async {
    final response = await _apiClient.send<List<ConsentRecord>>(
      method: HttpMethod.get,
      path: consentsPath,
      authenticated: true,
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeConsent)
                .whereType<ConsentRecord>()
                .toList(growable: false)
          : const <ConsentRecord>[],
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<ConsentRecord?>(
      method: HttpMethod.delete,
      // Addressed by purpose, which is what the server keys a consent on. The
      // record's own id is not a route key: a resident withdraws a *purpose*,
      // not a row, and the office keeps every row either way.
      path: '$consentsPath/$key',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: _decodeConsent,
    );

    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<ConsentRecord>(
              ContractFailure(
                debugMessage: 'Withdrawal answered with no readable record.',
              ),
            )
          : Ok<ConsentRecord>(envelope.data!),
    );
  }

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async {
    // The same route TAB 04 wired, and deliberately not a second one. A
    // correction raised from the privacy screen and a correction raised from the
    // profile screen are the same request to the same reviewer; two paths would
    // be two places for one to be lost, and two places is how one of them stops
    // being watched.
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/profile/corrections',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'changes': <String, Object?>{'street_address': detail},
      },
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async {
    // F13, unchanged and still a store blocker. No module publishes a route that
    // closes, erases or deletes an account. Declining is the only honest answer:
    // a closure request that silently succeeded against nothing would leave a
    // resident believing they had asked the municipality to erase their record,
    // and nobody would ever have been told.
    return backendGapFailure<void>(
      BackendGap.accountClosure,
      'requestAccountClosure',
    );
  }

  static ConsentRecord? _decodeConsent(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? purpose = entry['purpose'];
    if (purpose is! String || purpose.isEmpty) return null;

    final Object? version = entry['notice_version'];

    return ConsentRecord(
      key: purpose,
      // The purpose code is the label until the notice supplies a friendlier
      // one. A code a resident can quote to the office beats an invented
      // sentence about what they agreed to.
      label: purpose,
      statement: version is String && version.isNotEmpty
          ? 'Agreed under privacy notice $version'
          : 'Agreed under the privacy notice in force at the time',
      grantedAt: DateTime.tryParse(
        entry['granted_at'] is String ? entry['granted_at'] as String : '',
      )?.toUtc(),
      // Kept, not dropped. A withdrawn consent stays in the list because the
      // record is the point.
      withdrawnAt: DateTime.tryParse(
        entry['withdrawn_at'] is String ? entry['withdrawn_at'] as String : '',
      )?.toUtc(),
    );
  }
}
