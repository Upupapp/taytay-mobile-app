import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../../../core/telemetry/telemetry.dart';
import '../domain/correctable_field.dart';
import '../domain/kyc_claim.dart';
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
/// **Opening an attempt used to be impossible, and now is not.** `POST me/kyc`
/// requires a barangay; until the backend published `GET barangays` the only
/// identifier it accepted was the `barangays` auto-increment primary key, which
/// no route gave out. A resident cannot supply an identifier they have no way to
/// obtain, so this class declined rather than posting a guess — and with it the
/// Verified tier, the digital ID and every service resting on them were
/// unreachable from any client. That was F14, the largest single blocker in the
/// platform.
///
/// The directory now publishes a UUID and a stable slug, `POST me/kyc` accepts
/// `barangay_code`, and [openCase] sends it. The integer primary key never
/// enters this app.
///
/// **What is still declined, and why it is not F14.** [submitForReview] posts
/// the submission, but a KYC case has nowhere to put an identity document —
/// `POST me/kyc/submit` takes no body and no route attaches a file to a case
/// (F28). A submission carrying documents therefore declines instead of quietly
/// dropping them, because a resident who has just photographed their PhilID
/// believes the office has it.
class KycApiRepository implements VerificationRepository {
  const KycApiRepository({required ApiClient apiClient, Telemetry? telemetry})
    : _apiClient = apiClient,
      _telemetry = telemetry;

  final ApiClient _apiClient;

  /// Counts and outcomes, never contents. See `Telemetry` for the three
  /// conditions that gate every signal, and `TelemetrySignal` for why the
  /// payload is a sealed set with no free-text field.
  final Telemetry? _telemetry;

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
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
  }) async {
    // A correction to a claimed detail is a correction request against the
    // record, not a second KYC submission. `POST me/profile/corrections` is
    // where the office already adjudicates them, and routing it anywhere else
    // would build the second editing path TAB 05 warns against.
    // Keyed by the field the SERVER adjudicates, decided by the resident rather
    // than by this repository (TAB 04). Nothing is inferred here any more: a
    // category that spans several fields was resolved on the screen, and one
    // that spans none never reached an input.
    final Map<String, Object?> changes = <String, Object?>{
      for (final MapEntry<CorrectableField, String> entry in corrections.entries)
        entry.key.wireValue: entry.value,
    };

    if (changes.isEmpty) {
      // The server requires `changes` to hold at least one entry, so an empty
      // map is refused here rather than sent to collect a 422 whose field names
      // a resident has never seen.
      return const Err<void>(
        ValidationFailure(
          debugMessage: 'submitCorrections called with nothing to correct.',
        ),
      );
    }

    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.verification,
          stage: TelemetryStage.advanced,
        ),
      ),
    );

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
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async {
    // Refused here rather than at the server. A 422 on this screen is a dead end
    // for a resident — the server's field errors are keyed by wire names they
    // have never seen — and this is the screen that decides whether they ever
    // become Verified.
    if (!claim.isComplete) {
      return const Err<VerificationStatus>(
        ValidationFailure(
          fieldErrors: <String, List<String>>{},
          debugMessage: 'openCase called with an incomplete claim',
        ),
      );
    }

    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.verification,
          stage: TelemetryStage.started,
        ),
      ),
    );

    final response = await _apiClient.send<VerificationStatus>(
      method: HttpMethod.post,
      path: 'me/kyc',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'first_name': claim.givenName.trim(),
        // Omitted entirely when absent rather than sent as an empty string: the
        // server's rule is `nullable`, and a blank middle name written to a
        // claimed_* column is a value a reviewer has to interpret.
        if (claim.middleName.trim().isNotEmpty)
          'middle_name': claim.middleName.trim(),
        'last_name': claim.familyName.trim(),
        if (claim.suffix.trim().isNotEmpty) 'suffix': claim.suffix.trim(),
        // Date only, in the server's own format. Sending an ISO instant would
        // put a timezone on a birthday, and a birthday that moves across
        // midnight fails a registry match.
        'birth_date': _dateOnly(claim.birthDate),
        'sex': claim.sex.wireValue,
        // The slug, never the integer. See F14 and `BarangayDirectory`.
        'barangay_code': claim.barangayCode,
        'street_address': claim.streetAddress.trim(),
      },
      decode: _decodeStatus,
    );

    return response.map(
      (ApiEnvelope<VerificationStatus> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async {
    if (documentUploadIds.isNotEmpty) {
      // Nothing attaches a file to a KYC case (F28). Submitting anyway would
      // tell a resident their identity document had reached the office when it
      // never left the device — on the one screen where being wrong about that
      // costs them the Verified state.
      return backendGapFailure<void>(
        BackendGap.kycDocumentUpload,
        'submitForReview',
      );
    }

    unawaited(
      _telemetry?.record(
        const FlowStep(
          flow: TelemetryFlow.verification,
          stage: TelemetryStage.completed,
        ),
      ),
    );

    // Takes no body: the case is resolved from the authenticated account, so
    // there is no identifier to tamper with and nothing to send. Rate limited
    // server-side, because each submission puts a case in front of a human.
    final response = await _apiClient.send<VerificationStatus>(
      method: HttpMethod.post,
      path: 'me/kyc/submit',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      decode: _decodeStatus,
    );
    return response.map((_) {});
  }

  /// `YYYY-MM-DD`, built from the local date the resident picked.
  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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
