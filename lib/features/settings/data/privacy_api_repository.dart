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
/// **`loadControls` still does not offer deletion.** Consent withdrawal is the
/// flag it sets. `POST /me/close` exists and `requestAccountClosure` calls it,
/// but a deletion button stays off until the LGU retention schedule says what
/// a municipal record keeps.
class PrivacyApiRepository implements AccountControlsRepository {
  const PrivacyApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String consentsPath = 'me/consents';

  @override
  Future<Result<AccountControls>> loadControls() async {
    // Consent withdrawal is the flag the screen can honour today. Correction
    // is a separate flow. `POST /me/close` exists, and the deletion flag stays
    // false until the LGU says what a municipal record keeps.
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
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<ConsentRecord>(
      BackendGap.absentOnNodeContract,
      'withdrawConsent',
    );
  }

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'requestDataCorrection',
    );
  }

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async {
    // `POST /me/close` has no body. [permanent], [reason] and
    // [idempotencyKey] stay off the wire: Profile close accepts none of them.
    // A 409 means the account is already closed.
    final Object _ = (permanent, reason, idempotencyKey);
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/close',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  /// `POST me/consents`. Records the notice version the resident accepted.
  Future<Result<ConsentRecord?>> recordConsent({
    required String version,
  }) async {
    final response = await _apiClient.send<ConsentRecord?>(
      method: HttpMethod.post,
      path: consentsPath,
      authenticated: true,
      body: <String, Object?>{'version': version},
      decode: _decodeConsent,
    );
    return response.map((envelope) => envelope.data);
  }

  static ConsentRecord? _decodeConsent(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? purpose = entry['purpose'] ?? entry['version'] ?? entry['id'];
    if (purpose is! String || purpose.isEmpty) return null;

    final Object? version = entry['notice_version'] ?? entry['version'];

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
        (entry['granted_at'] ?? entry['accepted_at']) is String
            ? (entry['granted_at'] ?? entry['accepted_at']) as String
            : '',
      )?.toUtc(),
      // Kept, not dropped. A withdrawn consent stays in the list because the
      // record is the point.
      withdrawnAt: DateTime.tryParse(
        entry['withdrawn_at'] is String ? entry['withdrawn_at'] as String : '',
      )?.toUtc(),
    );
  }
}
