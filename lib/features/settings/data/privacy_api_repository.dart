import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
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
  static const String withdrawPath = 'me/consents/withdraw';

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

  /// `POST me/consents/withdraw`. The body is `{version}`.
  ///
  /// Withdrawing again returns the same row. An unknown version is 404.
  /// `POST me/consents` with that version again clears `withdrawn_at`.
  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async {
    final Result<ApiEnvelope<ConsentRecord?>> response = await _apiClient
        .send<ConsentRecord?>(
          method: HttpMethod.post,
          path: withdrawPath,
          authenticated: true,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{'version': key},
          decode: _decodeConsent,
        );
    return switch (response) {
      Err<ApiEnvelope<ConsentRecord?>>(:final failure) => Err<ConsentRecord>(
        failure,
      ),
      Ok<ApiEnvelope<ConsentRecord?>>(:final value) =>
        value.data == null
            ? const Err<ConsentRecord>(
                ContractFailure(
                  debugMessage: 'Withdraw returned no consent record.',
                ),
              )
            : Ok<ConsentRecord>(value.data!),
    };
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
  ///
  /// Accepting a version that was withdrawn clears `withdrawn_at`. The
  /// returned row is the record after that, including a null withdrawal.
  @override
  Future<Result<ConsentRecord>> acceptConsent({required String version}) async {
    final Result<ApiEnvelope<ConsentRecord?>> response = await _apiClient
        .send<ConsentRecord?>(
          method: HttpMethod.post,
          path: consentsPath,
          authenticated: true,
          body: <String, Object?>{'version': version},
          decode: _decodeConsent,
        );
    return switch (response) {
      Err<ApiEnvelope<ConsentRecord?>>(:final failure) => Err<ConsentRecord>(
        failure,
      ),
      Ok<ApiEnvelope<ConsentRecord?>>(:final value) =>
        value.data == null
            ? const Err<ConsentRecord>(
                ContractFailure(
                  debugMessage: 'Accept returned no consent record.',
                ),
              )
            : Ok<ConsentRecord>(value.data!),
    };
  }

  static ConsentRecord? _decodeConsent(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    // The withdraw body is the notice version. An id is not a version, and
    // sending it would record a withdrawal the office cannot match.
    final String? version = _version(
      entry['version'] ?? entry['notice_version'],
    );
    final Object? id = entry['id'];
    if (version == null && id is! String) return null;

    return ConsentRecord(
      key: version ?? '',
      label: 'Privacy notice',
      statement: version == null
          ? 'Agreed under the privacy notice in force at the time'
          : 'Agreed under privacy notice $version',
      grantedAt: DateTime.tryParse(
        (entry['granted_at'] ?? entry['accepted_at']) is String
            ? (entry['granted_at'] ?? entry['accepted_at']) as String
            : '',
      )?.toUtc(),
      // Kept, not dropped. A withdrawn consent stays in the list because the
      // record is the point. Null means this version is in force again.
      withdrawnAt: DateTime.tryParse(
        entry['withdrawn_at'] is String ? entry['withdrawn_at'] as String : '',
      )?.toUtc(),
      isWithdrawable: version != null,
    );
  }

  static String? _version(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
