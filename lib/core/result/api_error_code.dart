/// The stable, machine-readable error codes published by the Taytay LGU IDS
/// backend (`docs/api/conventions.md` §4, "Canonical error codes").
///
/// The backend contract is explicit that clients branch on `code`, never on the
/// human-readable `message`. That message is operator-facing and may change
/// without notice; the code is part of the API version.
///
/// Adding a new `code` is *not* a breaking change on the server side, so an
/// unrecognised code must degrade gracefully rather than crash: it maps to
/// [ApiErrorCode.unknown].
enum ApiErrorCode {
  /// 400 — the body was not JSON.
  invalidJson('INVALID_JSON'),

  /// 400 — malformed request the schema cannot express.
  badRequest('BAD_REQUEST'),

  /// 401 — missing, invalid or expired credentials.
  unauthenticated('UNAUTHENTICATED'),

  /// 403 — authenticated but not permitted.
  forbidden('FORBIDDEN'),

  /// 403 — a resident who has not finished verifying asked for something
  /// only a verified resident may (backend `0d1cb14`, requesting a document).
  /// Kept apart from [forbidden] so the app offers the way to verification
  /// when that is the reason, and only then.
  verificationRequired('VERIFICATION_REQUIRED'),

  /// 403 — a selfie was sent without a standing consent to the biometric text
  /// published now (backend `44cae1b`). Nothing was stored. Kept apart so the
  /// app asks for the consent again rather than saying "not available".
  biometricConsentRequired('BIOMETRIC_CONSENT_REQUIRED'),

  /// 404 — the resource does not exist, **or** the actor may not know it does.
  notFound('NOT_FOUND'),

  /// 405 — wrong HTTP verb.
  methodNotAllowed('METHOD_NOT_ALLOWED'),

  /// 409 — state conflict (duplicate, concurrent update).
  conflict('CONFLICT'),

  /// 409 — lifecycle transition not permitted from the current state.
  invalidStateTransition('INVALID_STATE_TRANSITION'),

  /// 422 — input failed validation; `details` is `field -> [messages]`.
  ///
  /// This code does not carry `attempts_remaining`. Email and reset codes use
  /// [codeInvalid], [codeExpired], and [codeLocked] instead.
  validationFailed('VALIDATION_FAILED'),

  /// 422 — the 6-digit code was wrong. `details.attempts_remaining` is 4 down to 1.
  codeInvalid('code_invalid'),

  /// 422 — the 6-digit code has expired. `details.attempts_remaining` is set.
  /// The screen for it is `02-04b`.
  codeExpired('code_expired'),

  /// 422 — five wrong codes locked this one. `details.attempts_remaining` is 0
  /// and `details.retry_after` is the wait. Zero means a new code can be sent now.
  codeLocked('code_locked'),

  /// 429 — throttled. `details.retry_after` is the wait in seconds, up to 900.
  rateLimited('RATE_LIMITED'),

  /// 413 — the body exceeded the server's limit.
  ///
  /// Added when the TAB 01 conformance harness first read the published contract
  /// and found the app knew twelve codes to the backend's thirteen. Both this and
  /// [unsupportedMediaType] collapsed to [unknown], which is exactly the pair a
  /// document upload produces — so a resident who photographed an identity
  /// document at full camera resolution was told "something went wrong" instead
  /// of "that file is too large".
  ///
  /// Note that a reverse proxy can answer 413 *before* the application does, in
  /// which case the body is not this envelope at all. TAB 10 owns that path and
  /// the resident copy for both codes; decoding them is this TAB's job.
  payloadTooLarge('PAYLOAD_TOO_LARGE'),

  /// 415 — the body's content type is not accepted.
  unsupportedMediaType('UNSUPPORTED_MEDIA_TYPE'),

  /// 500 — unhandled server fault.
  serverError('SERVER_ERROR'),

  /// 500 — the Node API's name for an unhandled fault.
  internalError('INTERNAL_ERROR'),

  /// 503 — dependency down or maintenance.
  serviceUnavailable('SERVICE_UNAVAILABLE'),

  /// A code this build does not know about. Never thrown away — the raw string
  /// is preserved on the failure for logging and support.
  unknown('UNKNOWN');

  const ApiErrorCode(this.wireValue);

  /// The value as it appears in the error envelope.
  ///
  /// Most codes are `SCREAMING_SNAKE_CASE`. `code_invalid`, `code_expired`, and
  /// `code_locked` are the spelling `90aa39e` publishes for email and reset codes.
  final String wireValue;

  /// Parses a wire value, falling back to [ApiErrorCode.unknown].
  static ApiErrorCode parse(String? value) {
    if (value == null) return ApiErrorCode.unknown;
    for (final code in ApiErrorCode.values) {
      if (code.wireValue == value) return code;
    }
    return ApiErrorCode.unknown;
  }
}
