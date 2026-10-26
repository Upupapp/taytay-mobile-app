import 'dart:async';
import 'dart:typed_data';

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
      path: 'me/verification-requests/current',
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
  /// The applicant's own view of their case, decoded from what the server
  /// actually sends.
  ///
  /// ## Why this no longer goes through [loadOwnStatus] (C-11)
  ///
  /// It used to: it called that method, took the three fields the narrow
  /// `VerificationStatus` carries, and built a detail from them. The projection
  /// on the wire has eight — `id`, `status`, `can_edit`, `submitted_at`,
  /// `message`, `claimed`, `resident_id`, `documents` — so **five were being
  /// read off the socket and dropped**, including two the screen already knows
  /// how to render.
  ///
  /// `submitted_at` is why "Sent on …" never appeared for anybody. `can_edit`
  /// is the more consequential one: the office computes it from the case status
  /// and this app inferred the same thing from its own reading of the stage
  /// instead. Same class of defect as the upload ceiling and the page size —
  /// a value the server publishes, derived locally rather than read.
  ///
  /// `id`, `resident_id` and `claimed` are read and deliberately not carried:
  /// `claimed` is the resident's own submitted details, which this screen does
  /// not re-display, and the two identifiers have nowhere to go. Naming them
  /// here is the record that they were considered rather than missed.
  ///
  /// **That decision was re-examined on 2026-08-29 and stands, for a reason
  /// worth writing down.** The screen *does* have a card titled "What Taytay
  /// LGU has from you", which looks like exactly the thing `claimed` could
  /// fill — so the note above reads as a contradiction. It is not. That card
  /// draws `submittedCategories`, a privacy-safe summary of the *kinds* of
  /// information held; `claimed` carries the actual *values*. Filling the card
  /// from `claimed` would quietly convert a category summary into a
  /// re-display of the resident's name and birth date — a more exposing
  /// feature wearing the same heading.
  ///
  /// The categories cannot be derived from anything on the wire, so the card
  /// stays dark until the server publishes them. See
  /// `test/features/verification_dead_sections_test.dart`, which holds that
  /// gap open rather than letting a passing widget test imply the section
  /// renders.
  ///
  /// `documents` is left to `loadOwnDocuments`, which owns that list and is
  /// refreshed on its own after an upload; taking it from two places would give
  /// the screen two answers that disagree the moment one of them is stale.
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async {
    final response = await _apiClient.send<VerificationStatusDetail>(
      method: HttpMethod.get,
      path: 'me/verification-requests/current',
      authenticated: true,
      decode: _decodeDetail,
    );

    // The same 404-is-not-a-failure rule `loadOwnStatus` carries: a resident who
    // has never started verification has not failed at anything.
    return switch (response) {
      Ok<dynamic>() => Ok<VerificationStatusDetail>(response.valueOrNull!.data),
      Err<dynamic>(:final failure) when failure is NotFoundFailure =>
        const Ok<VerificationStatusDetail>(VerificationStatusDetail.unknown),
      Err<dynamic>(:final failure) => Err<VerificationStatusDetail>(failure),
    };
  }

  /// Allow-list decoder for the applicant projection.
  ///
  /// Names every key it reads and walks past everything else, which is both the
  /// house convention (unknown fields are ignored, never rejected) and the
  /// privacy control: a reviewer's identity or an internal note cannot land in
  /// a field nobody added a line for.
  static VerificationStatusDetail _decodeDetail(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    final Object? raw = map['status'];
    final Object? message = map['message'];
    final Object? notes = map['notes'];
    final Object? submittedAt = map['submitted_at'] ?? map['created_at'];
    final Object? canEdit = map['can_edit'];
    final Object? idType = map['id_type'];
    final Object? reviewedAt = map['reviewed_at'];
    final String? guidance = message is String && message.trim().isNotEmpty
        ? message.trim()
        : (notes is String && notes.trim().isNotEmpty ? notes.trim() : null);

    return VerificationStatusDetail(
      stage: ResidentVerificationStage.fromAttemptState(
        VerificationAttemptState.parse(raw is String ? raw : null),
      ),
      rawState: raw is String ? raw : '',
      residentGuidance: guidance,
      submittedAt: submittedAt is String
          ? DateTime.tryParse(submittedAt)?.toUtc()
          : null,
      idType: idType is String && idType.trim().isNotEmpty
          ? idType.trim()
          : null,
      reviewedAt: reviewedAt is String
          ? DateTime.tryParse(reviewedAt)?.toUtc()
          : null,
      // Only a real boolean counts. A missing field means "the server did not
      // say" and must stay null so the fallback applies; coercing it to false
      // would lock a resident out of a case the office considers open.
      canEdit: canEdit is bool ? canEdit : null,
      id: _text(map['id']),
      userId: _text(map['user_id']),
      idFrontMediaId: _text(map['id_front_media_id']),
      idBackMediaId: _text(map['id_back_media_id']),
      selfieMediaId: _text(map['selfie_media_id']),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'submitCorrections',
    );
  }

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    unawaited(
      _telemetry?.record(
            const FlowStep(
              flow: TelemetryFlow.verification,
              stage: TelemetryStage.blocked,
            ),
          ) ??
          Future<bool>.value(false),
    );
    return backendGapFailure<VerificationStatus>(
      BackendGap.absentOnNodeContract,
      'openCase',
    );
  }

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'submitForReview',
    );
  }

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<KycDocument>(
      BackendGap.absentOnNodeContract,
      'attachDocument',
    );
  }

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async {
    final Object _ = _apiClient.runtimeType;
    final Object? _ = _telemetry;
    return backendGapFailure<List<KycDocument>>(
      BackendGap.absentOnNodeContract,
      'loadDocuments',
    );
  }

  /// `POST me/verification-requests`.
  ///
  /// One multipart body: id type, front, optional back, and a selfie.
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required Uint8List frontBytes,
    required String frontName,
    required String frontMime,
    Uint8List? backBytes,
    String? backName,
    String? backMime,
    required Uint8List selfieBytes,
    required String selfieName,
    required String selfieMime,
  }) async {
    final response = await _apiClient.send<VerificationStatus>(
      method: HttpMethod.post,
      path: 'me/verification-requests',
      authenticated: true,
      body: <String, Object?>{'id_type': idType},
      files: <MultipartFile>[
        MultipartFile(
          field: 'id_front',
          filename: frontName,
          bytes: frontBytes,
          mimeType: frontMime,
        ),
        if (backBytes != null && backName != null && backMime != null)
          MultipartFile(
            field: 'id_back',
            filename: backName,
            bytes: backBytes,
            mimeType: backMime,
          ),
        MultipartFile(
          field: 'selfie',
          filename: selfieName,
          bytes: selfieBytes,
          mimeType: selfieMime,
        ),
      ],
      decode: _decodeStatus,
    );
    return response.map(
      (ApiEnvelope<VerificationStatus> envelope) => envelope.data,
    );
  }

  static VerificationStatus _decodeStatus(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? raw = map['status'];
    final Object? message = map['message'];
    final Object? notes = map['notes'];
    final String? guidance = message is String && message.trim().isNotEmpty
        ? message.trim()
        : (notes is String && notes.trim().isNotEmpty ? notes.trim() : null);

    return VerificationStatus(
      state: VerificationAttemptState.parse(raw is String ? raw : null),
      // The server's own value, preserved whatever this build made of it, so a
      // support desk and a resident are looking at the same word.
      rawState: raw is String ? raw : '',
      // `notes` is the office text on VerificationRequest. The reviewer's
      // identity is not copied.
      residentGuidance: guidance,
    );
  }
}
