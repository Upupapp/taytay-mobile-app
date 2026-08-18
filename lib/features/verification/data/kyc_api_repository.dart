import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';

/// Talks to `GET me/kyc`, `POST me/kyc/submit` and `POST me/profile/corrections`.
///
/// ---
///
/// **This is KYC, and the class it replaces was named after the wrong module.**
/// `PlannedVerificationRepository` claimed the backend's `Verification` — which
/// is genuinely planned, and which owns a verifier device scanning a QR at a
/// counter. What a resident does here is `ResidentProfile`'s: open an attempt,
/// read where it has got to, answer a request for more information. That has
/// been served since backend TAB 06. See F17.
///
/// **Opening an attempt is blocked, and not by wiring.** `POST me/kyc` requires
/// a `barangay_id` validated against the `barangays` table, and no route
/// publishes that list to a resident (F14). A resident cannot supply an
/// identifier they have no way to obtain, so `submitForReview` declines through
/// [BackendGap] rather than posting a guess — the alternative is a 422 the
/// resident can do nothing about, on the screen that decides whether they ever
/// become Verified.
class KycApiRepository implements VerificationRepository {
  const KycApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async {
    final response = await _apiClient.send<VerificationStatus>(
      method: HttpMethod.get,
      path: 'me/kyc',
      authenticated: true,
      decode: _decodeStatus,
    );

    // NO CASE IS NOT A FAILURE. A resident who has never started verification
    // gets a 404, and the honest answer to "where has my application got to" is
    // "you have not made one" — an ordinary state with a next step, not an
    // error banner.
    return switch (response) {
      Ok<dynamic>() => Ok<VerificationStatus>(response.valueOrNull!.data),
      Err<dynamic>(:final failure) when failure is NotFoundFailure =>
        const Ok<VerificationStatus>(
          VerificationStatus(
            state: VerificationAttemptState.notStarted,
            rawState: '',
          ),
        ),
      Err<dynamic>(:final failure) => Err<VerificationStatus>(failure),
    };
  }

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async {
    final Result<VerificationStatus> status = await loadOwnStatus();
    return status.map(
      (VerificationStatus value) => VerificationStatusDetail(
        stage: ResidentVerificationStage.fromAttemptState(value.state),
        rawState: value.rawState,
        residentGuidance: value.residentGuidance,
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async {
    // A correction to a claimed detail is a correction request against the
    // record, not a second KYC submission. `POST me/profile/corrections` is
    // where the office already adjudicates them, and routing it anywhere else
    // would build the second editing path TAB 05 warns against.
    final Map<String, Object?> changes = <String, Object?>{
      for (final MapEntry<VerificationItemCategory, String> entry
          in corrections.entries)
        if (entry.key.field != null) entry.key.field!: entry.value,
    };

    if (changes.isEmpty) {
      // Nothing here maps to a named field the office adjudicates. Declining is
      // the honest answer: a correction filed against the wrong field is worse
      // than one not filed, because the resident believes the office has been
      // told. See F23 and `VerificationItemCategory.field`.
      return backendGapFailure<void>(
        BackendGap.kycFieldCorrections,
        'submitCorrections',
      );
    }

    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/profile/corrections',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'changes': changes},
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async {
    // Blocked before it starts: opening the case needs a barangay this app
    // cannot resolve. See the class doc and F14.
    return backendGapFailure<void>(
      BackendGap.barangayDirectory,
      'submitForReview',
    );
  }

  static VerificationStatus _decodeStatus(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? raw = map['status'];
    final Object? message = map['message'];

    return VerificationStatus(
      state: VerificationAttemptState.parse(raw is String ? raw : null),
      // The server's own value, preserved whatever this build made of it, so a
      // support desk and a resident are looking at the same word.
      rawState: raw is String ? raw : '',
      // `applicant_message` is addressed to the resident by name and by design —
      // the deliberate exception to "never render the server's message", because
      // only the reviewing office knows why something was returned. The
      // reviewer's identity is not published and there is nowhere for it to land.
      residentGuidance: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
    );
  }
}
