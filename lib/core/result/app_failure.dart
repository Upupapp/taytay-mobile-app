import 'package:flutter/foundation.dart';

import 'api_error_code.dart';

/// Everything that can go wrong, as a closed set.
///
/// Two rules shape this taxonomy:
///
/// 1. **The resident never sees the server's `message`.** `docs/api/conventions.md`
///    §4 defines that field as *operator-facing*. It may name an internal state
///    or quote input, and it is not translated. The app therefore derives its own
///    [residentMessage] from the failure *kind*, and keeps the server text in
///    [debugMessage] for logs and support tooling only.
/// 2. **Every failure carries a [requestId] when the server supplied one.** The
///    backend echoes `X-Request-Id` into the error body precisely so a resident
///    can quote it to a support desk without disclosing anything personal.
@immutable
sealed class AppFailure {
  const AppFailure({this.requestId, this.debugMessage});

  /// Correlation id echoed by the backend. Safe to display — it is opaque.
  final String? requestId;

  /// Operator-facing detail. **Never render this to a resident.**
  final String? debugMessage;

  /// Short, plain-language, resident-safe explanation.
  ///
  /// English is the base locale; a localisation seam replaces this in a later
  /// TAB without changing the failure taxonomy.
  String get residentMessage;

  /// Whether retrying the same request unchanged could reasonably succeed.
  bool get isRetryable => false;

  /// Whether the app must drop to a signed-out session and ask the resident to
  /// authenticate again.
  bool get requiresReauthentication => false;

  /// A stable label for logs and analytics. Contains no personal data.
  String get kind;

  @override
  String toString() =>
      '$kind(requestId: $requestId, debugMessage: ${debugMessage ?? '-'})';
}

/// The device could not reach the API at all: no connectivity, DNS failure,
/// TLS failure or a socket error.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'network';

  @override
  String get residentMessage =>
      'You appear to be offline. Check your internet connection and try again.';

  @override
  bool get isRetryable => true;
}

/// The request was sent but no response arrived within the configured budget.
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'timeout';

  @override
  String get residentMessage =>
      'The request is taking longer than expected. Please try again.';

  @override
  bool get isRetryable => true;
}

/// Credentials are missing, invalid or expired (HTTP 401 / `UNAUTHENTICATED`).
///
/// Session expiry is *always* a server verdict. The app never decides locally
/// that a token is still good.
final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'unauthenticated';

  @override
  String get residentMessage =>
      'Your session has ended. Please sign in again to continue.';

  @override
  bool get requiresReauthentication => true;
}

/// Authenticated, but not permitted (HTTP 403 / `FORBIDDEN`).
///
/// For a resident this usually means the action needs a verified account, or it
/// belongs to someone else. The copy deliberately does not say which.
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'forbidden';

  @override
  String get residentMessage =>
      'This service is not available for your account right now.';
}

/// The resource does not exist, or the actor may not know that it does
/// (HTTP 404 / `NOT_FOUND`).
///
/// The backend deliberately returns 404 instead of 403 when the *existence* of a
/// record is itself personal data ("existence is a privilege"). The app must not
/// try to distinguish the two cases or infer anything from it.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'not_found';

  @override
  String get residentMessage => 'We could not find what you were looking for.';
}

/// Input failed server-side validation (HTTP 422 / `VALIDATION_FAILED`).
///
/// [fieldErrors] mirrors the `details` object: `field -> [messages]`. These
/// strings come from the server and are shown *next to the field* rather than as
/// the headline message, which is the one place server text is surfaced —
/// because it is the only place it is actionable.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    this.fieldErrors = const <String, List<String>>{},
    super.requestId,
    super.debugMessage,
  });

  final Map<String, List<String>> fieldErrors;

  /// The first message for [field], or `null` when that field is fine.
  String? firstErrorFor(String field) {
    final messages = fieldErrors[field];
    if (messages == null || messages.isEmpty) return null;
    return messages.first;
  }

  @override
  String get kind => 'validation';

  @override
  String get residentMessage =>
      'Please check the highlighted details and try again.';
}

/// A state conflict — duplicate submission, concurrent update, or a lifecycle
/// transition that is not legal from the current state
/// (HTTP 409 / `CONFLICT` / `INVALID_STATE_TRANSITION`).
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    this.isInvalidStateTransition = false,
    super.requestId,
    super.debugMessage,
  });

  /// True for `INVALID_STATE_TRANSITION`, false for plain `CONFLICT`.
  final bool isInvalidStateTransition;

  @override
  String get kind =>
      isInvalidStateTransition ? 'invalid_state_transition' : 'conflict';

  @override
  String get residentMessage => isInvalidStateTransition
      ? 'This request has already moved forward. Refresh to see its current status.'
      : 'This was already submitted. Refresh to see the latest status.';
}

/// The client is being throttled (HTTP 429 / `RATE_LIMITED`).
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({
    this.retryAfter,
    super.requestId,
    super.debugMessage,
  });

  /// Value of the `Retry-After` header when the server supplied one.
  final Duration? retryAfter;

  @override
  String get kind => 'rate_limited';

  @override
  bool get isRetryable => true;

  @override
  String get residentMessage {
    final seconds = retryAfter?.inSeconds;
    if (seconds == null || seconds <= 0) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Too many attempts. Please try again in $seconds seconds.';
  }
}

/// The server failed or is unavailable (HTTP 5xx / `SERVER_ERROR` /
/// `SERVICE_UNAVAILABLE`).
final class ServerFailure extends AppFailure {
  const ServerFailure({
    this.isTemporary = false,
    this.isMaintenance = false,
    super.requestId,
    super.debugMessage,
  });

  /// True for 503 / maintenance, where retrying later is the right advice.
  final bool isTemporary;

  /// The server itself answered `503 SERVICE_UNAVAILABLE`.
  ///
  /// **Narrower than [isTemporary] on purpose, and the narrowness is the point.**
  /// Every unwired repository in this app also returns a temporary
  /// [ServerFailure] — that is how they decline honestly — so a maintenance
  /// banner keyed on [isTemporary] would be showing right now, on a healthy
  /// server, for fourteen features. This flag is set only by
  /// [failureFromApiError], which means only a real response from a real server
  /// can raise it.
  ///
  /// It is how the app knows there is maintenance at all: the published
  /// `app/bootstrap` contract carries no maintenance field (F18), and inventing
  /// a cached one would claim maintenance after it ended and miss one that
  /// started. A live 503 is the server saying so, now.
  final bool isMaintenance;

  @override
  String get kind => isTemporary ? 'service_unavailable' : 'server_error';

  @override
  bool get isRetryable => true;

  @override
  String get residentMessage => isTemporary
      ? 'The service is temporarily unavailable. Please try again shortly.'
      : 'Something went wrong on our side. Please try again.';
}

/// The response did not match the API contract — unparseable body, missing
/// envelope, or a type the client cannot read.
///
/// This is a *client-visible symptom of a contract breach* and is kept distinct
/// from [ServerFailure] so it can be alerted on separately.
final class ContractFailure extends AppFailure {
  const ContractFailure({super.requestId, super.debugMessage});

  @override
  String get kind => 'contract';

  @override
  String get residentMessage =>
      'We could not read the response from the server. Please try again.';
}

/// An unhandled error inside the app itself.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    this.debugContext,
    this.error,
    this.stackTrace,
    super.requestId,
    super.debugMessage,
  });

  /// Where the guard was installed, e.g. `'ApiClient.decode'`.
  final String? debugContext;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String get kind => 'unexpected';

  @override
  String get residentMessage =>
      'Something went wrong. Please try again, or contact the LGU if it keeps happening.';
}

/// The resident sent something the server will not accept: too large, or the
/// wrong kind of file.
///
/// Its own case rather than a [ValidationFailure] because nothing here is a
/// field. A validation failure points at an input the resident can correct in
/// place; this one points at a *file*, and the remedy is to choose or retake it.
/// Folding the two together is how an upload error ends up rendered as a red
/// outline on a text box that was never the problem.
///
/// Distinct from [UnexpectedFailure] for the opposite reason: a body over the
/// limit is not a client defect the resident can do nothing about — it is the
/// single most common thing that goes wrong when somebody photographs a birth
/// certificate on a modern phone, and it is entirely actionable.
///
/// TAB 10 owns the resident-facing copy per context and the client-side
/// compression that should stop most residents ever meeting it. This type exists
/// so that path has something true to carry.
final class UnacceptableUploadFailure extends AppFailure {
  const UnacceptableUploadFailure({
    required this.isTooLarge,
    super.requestId,
    super.debugMessage,
  });

  /// True for `PAYLOAD_TOO_LARGE`, false for `UNSUPPORTED_MEDIA_TYPE`. Two
  /// different remedies — shrink it, or send a different kind of file — so the
  /// screen must be able to tell them apart.
  final bool isTooLarge;

  @override
  String get kind => 'unacceptable-upload';

  @override
  String get residentMessage => isTooLarge
      ? 'That file is too large to send. Try a smaller photo or a lower quality setting.'
      : 'That kind of file cannot be sent. Try a photo or a PDF instead.';
}

/// Maps an HTTP status and canonical error code onto the failure taxonomy.
///
/// The code wins where the two disagree, because the code is the contract; the
/// status is the fallback for responses that never reached the application layer
/// (a gateway 502, for example).
AppFailure failureFromApiError({
  required int statusCode,
  required ApiErrorCode code,
  String? message,
  String? requestId,
  Map<String, List<String>> fieldErrors = const <String, List<String>>{},
  Duration? retryAfter,
}) {
  switch (code) {
    case ApiErrorCode.unauthenticated:
      return UnauthenticatedFailure(
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.forbidden:
      return ForbiddenFailure(requestId: requestId, debugMessage: message);
    case ApiErrorCode.notFound:
      return NotFoundFailure(requestId: requestId, debugMessage: message);
    case ApiErrorCode.validationFailed:
      return ValidationFailure(
        fieldErrors: fieldErrors,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.conflict:
      return ConflictFailure(requestId: requestId, debugMessage: message);
    case ApiErrorCode.invalidStateTransition:
      return ConflictFailure(
        isInvalidStateTransition: true,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.rateLimited:
      return RateLimitedFailure(
        retryAfter: retryAfter,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.serviceUnavailable:
      return ServerFailure(
        isTemporary: true,
        isMaintenance: true,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.serverError:
      return ServerFailure(requestId: requestId, debugMessage: message);
    case ApiErrorCode.payloadTooLarge:
      return UnacceptableUploadFailure(
        isTooLarge: true,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.unsupportedMediaType:
      return UnacceptableUploadFailure(
        isTooLarge: false,
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.badRequest:
    case ApiErrorCode.methodNotAllowed:
      // A malformed request or wrong verb is a client defect the resident can do
      // nothing about; surface it as unexpected rather than blaming their input.
      return UnexpectedFailure(
        debugContext: 'api:${code.wireValue}',
        requestId: requestId,
        debugMessage: message,
      );
    case ApiErrorCode.unknown:
      return _failureFromStatus(
        statusCode: statusCode,
        message: message,
        requestId: requestId,
        retryAfter: retryAfter,
      );
  }
}

AppFailure _failureFromStatus({
  required int statusCode,
  String? message,
  String? requestId,
  Duration? retryAfter,
}) {
  if (statusCode == 401) {
    return UnauthenticatedFailure(requestId: requestId, debugMessage: message);
  }
  if (statusCode == 403) {
    return ForbiddenFailure(requestId: requestId, debugMessage: message);
  }
  if (statusCode == 404) {
    return NotFoundFailure(requestId: requestId, debugMessage: message);
  }
  if (statusCode == 409) {
    return ConflictFailure(requestId: requestId, debugMessage: message);
  }
  if (statusCode == 422) {
    return ValidationFailure(requestId: requestId, debugMessage: message);
  }
  if (statusCode == 429) {
    return RateLimitedFailure(
      retryAfter: retryAfter,
      requestId: requestId,
      debugMessage: message,
    );
  }
  if (statusCode == 503) {
    return ServerFailure(
      isTemporary: true,
      requestId: requestId,
      debugMessage: message,
    );
  }
  if (statusCode >= 500) {
    return ServerFailure(requestId: requestId, debugMessage: message);
  }
  return UnexpectedFailure(
    debugContext: 'api:http_$statusCode',
    requestId: requestId,
    debugMessage: message,
  );
}
