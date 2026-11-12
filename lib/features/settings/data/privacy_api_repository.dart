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
  static const String currentPath = 'me/consents/current';

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

  /// `GET me/consents/current`: the server's verdict on each text.
  ///
  /// `up_to_date` is read, never recomputed here: whether a consent stands
  /// for the version published now is the server's to say (D-208).
  @override
  Future<Result<ConsentState>> loadConsentState() async {
    final response = await _apiClient.send<ConsentState>(
      method: HttpMethod.get,
      path: currentPath,
      authenticated: true,
      decode: _decodeState,
    );
    return response.map((envelope) => envelope.data);
  }

  /// `POST me/consents/withdraw`. The body is `{version, kind}`.
  ///
  /// Withdrawing again returns the same row. An unknown version is 404.
  /// `POST me/consents` with that version again clears `withdrawn_at`. The
  /// kind is always sent: without it the server withdraws the Terms, the
  /// Privacy Notice and every older combined row of that version at once.
  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
    required ConsentKind kind,
  }) async {
    // An older combined row is history: the write body names one of the three
    // texts, and a withdrawal with no kind would take the Terms and the
    // Privacy Notice with it.
    if (kind == ConsentKind.unspecified) {
      return const Err<ConsentRecord>(
        ValidationFailure(debugMessage: 'A withdrawal names its text.'),
      );
    }
    final Result<ApiEnvelope<ConsentRecord?>> response = await _apiClient
        .send<ConsentRecord?>(
          method: HttpMethod.post,
          path: withdrawPath,
          authenticated: true,
          idempotencyKey: idempotencyKey,
          body: <String, Object?>{'version': key, 'kind': kind.wireValue},
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

  /// `POST me/consents`. Records the version of the [kind] text the resident
  /// accepted, as its own act.
  ///
  /// Accepting a version that was withdrawn clears `withdrawn_at`. The
  /// returned row is the record after that, including a null withdrawal.
  /// [ConsentKind.unspecified] is never sent: it is what an app that names no
  /// text records, and this one always names it.
  @override
  Future<Result<ConsentRecord>> acceptConsent({
    required String version,
    required ConsentKind kind,
  }) async {
    if (kind == ConsentKind.unspecified) {
      return const Err<ConsentRecord>(
        ValidationFailure(debugMessage: 'A consent names its text.'),
      );
    }
    final Result<ApiEnvelope<ConsentRecord?>> response = await _apiClient
        .send<ConsentRecord?>(
          method: HttpMethod.post,
          path: consentsPath,
          authenticated: true,
          body: <String, Object?>{'version': version, 'kind': kind.wireValue},
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
    final ConsentKind kind = ConsentKind.parse(entry['kind']);

    return ConsentRecord(
      key: version ?? '',
      kind: kind,
      label: kind.label,
      statement: kind.statement(version),
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
      // A row an older app recorded for both texts at once is kept as
      // evidence, never withdrawn or accepted again on its own (D-208).
      isWithdrawable: version != null && kind != ConsentKind.unspecified,
    );
  }

  static ConsentState _decodeState(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? older = map['unspecified'];
    return ConsentState.byKind(
      <ConsentKind, ConsentStanding>{
        for (final ConsentKind kind in ConsentKind.values)
          if (kind != ConsentKind.unspecified)
            kind: _standing(map[kind.wireValue]),
      },
      unspecified: older is List<dynamic>
          ? older
                .map(_decodeConsent)
                .whereType<ConsentRecord>()
                .toList(growable: false)
          : const <ConsentRecord>[],
    );
  }

  /// One text's standing. Anything but a real `true` is not up to date: a
  /// missing verdict asks again rather than assuming agreement.
  static ConsentStanding _standing(Object? raw) {
    if (raw is! Map<String, dynamic>) return ConsentStanding.none;
    final ConsentRecord? consent = _decodeConsent(raw['consent']);
    return ConsentStanding(
      publishedVersion: _version(raw['published_version']),
      consent: consent != null && consent.isActive ? consent : null,
      upToDate: raw['up_to_date'] == true,
    );
  }

  static String? _version(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
