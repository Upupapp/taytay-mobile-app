import 'dart:async';
import 'dart:typed_data';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
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
  /// `documents` is left to `loadOwnDocuments`, which owns that list and is
  /// refreshed on its own after an upload; taking it from two places would give
  /// the screen two answers that disagree the moment one of them is stale.
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async {
    final response = await _apiClient.send<VerificationStatusDetail>(
      method: HttpMethod.get,
      path: 'me/kyc',
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
    final Object? submittedAt = map['submitted_at'];
    final Object? canEdit = map['can_edit'];

    return VerificationStatusDetail(
      stage: ResidentVerificationStage.fromAttemptState(
        VerificationAttemptState.parse(raw is String ? raw : null),
      ),
      rawState: raw is String ? raw : '',
      residentGuidance: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
      submittedAt: submittedAt is String
          ? DateTime.tryParse(submittedAt)?.toUtc()
          : null,
      // Only a real boolean counts. A missing field means "the server did not
      // say" and must stay null so the fallback applies; coercing it to false
      // would lock a resident out of a case the office considers open.
      canEdit: canEdit is bool ? canEdit : null,
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
      for (final MapEntry<CorrectableField, String> entry
          in corrections.entries)
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
    // Documents are attached before this, one request each, at
    // `POST me/kyc/documents` — see [attachDocument]. Nothing rides along here,
    // and `documentUploadIds` is kept on the contract only because the office
    // may one day reference material it holds elsewhere.
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

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.send<KycDocument>(
      method: HttpMethod.post,
      path: 'me/kyc/documents',
      authenticated: true,
      // An upload is the request most likely to be retried — long, and on the
      // worst connections. Without the key a retry is a second version in the
      // office's file.
      idempotencyKey: idempotencyKey,
      // Travels as a multipart text field beside the file. Until this call
      // nothing in the app sent one, and the transport was writing the literal
      // string `$value` for every field it was given.
      body: <String, Object?>{'type': type.wireValue},
      file: MultipartFile(
        // The field name the server validates under. Not configurable: a
        // mismatch is a 422 that reads like the resident's fault.
        field: 'file',
        filename: fileName,
        bytes: bytes,
        mimeType: mimeType,
      ),
      decode: (Object? data) => _decodeDocument(data) ?? _absent(type),
    );
    return response.map((ApiEnvelope<KycDocument> envelope) => envelope.data);
  }

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async {
    final response = await _apiClient.send<List<KycDocument>>(
      method: HttpMethod.get,
      path: 'me/kyc/documents',
      authenticated: true,
      decode: _decodeDocuments,
    );
    return response.map(
      (ApiEnvelope<List<KycDocument>> envelope) => envelope.data,
    );
  }

  static KycDocument _absent(KycDocumentType type) =>
      KycDocument(type: type, isAttached: false);

  static List<KycDocument> _decodeDocuments(Object? data) {
    final Object? rows = data is Map<String, dynamic>
        ? data['documents']
        : data;
    if (rows is! List<dynamic>) return const <KycDocument>[];

    final List<KycDocument> documents = <KycDocument>[];
    for (final Object? row in rows) {
      final KycDocument? decoded = _decodeDocument(row);
      if (decoded != null) documents.add(decoded);
    }
    return List<KycDocument>.unmodifiable(documents);
  }

  /// Returns null for a type this build has never heard of.
  ///
  /// Dropped rather than guessed. A row the app cannot name is one it cannot
  /// label either, and an unlabelled slot in a document list is something a
  /// resident taps expecting it to do something.
  static KycDocument? _decodeDocument(Object? row) {
    if (row is! Map<String, dynamic>) return null;

    final Object? wire = row['type'];
    if (wire is! String) return null;

    KycDocumentType? type;
    for (final KycDocumentType candidate in KycDocumentType.values) {
      if (candidate.wireValue == wire) type = candidate;
    }
    if (type == null) return null;

    final Object? receivedAt = row['received_at'];

    return KycDocument(
      type: type,
      isAttached: row['attached'] == true,
      receivedAt: receivedAt is String
          ? DateTime.tryParse(receivedAt)?.toUtc()
          : null,
      isAvailable: row['is_available'] == true,
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
