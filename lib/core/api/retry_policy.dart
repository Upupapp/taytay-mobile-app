import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../result/result.dart';
import 'api_transport.dart';

/// Decides whether a failed request may be sent again, and when.
///
/// ---
///
/// ## The rule that matters
///
/// **A request is retried only when repeating it cannot create a second thing.**
/// In practice that means:
///
/// * `GET` is always safe — the contract states `GET`/`HEAD` never mutate
///   (`docs/api/conventions.md` §7).
/// * `POST`/`PUT`/`PATCH`/`DELETE` are retried **only** when the caller supplied
///   an `Idempotency-Key`, because the contract states that replaying a key
///   returns the original result rather than acting twice.
///
/// Without that key, a retry after a dropped connection is how one resident ends
/// up with two document applications, or two payments. The connection dropping
/// *after* the server committed is indistinguishable, from the client, from it
/// dropping before — so "it probably didn't go through" is not a judgement the
/// app is entitled to make.
///
/// ## What is retried
///
/// | Condition | Retry | Why |
/// | --- | --- | --- |
/// | Network / timeout | yes | The commonest failure on a mobile connection, and usually transient. |
/// | `429 RATE_LIMITED` | yes, honouring `Retry-After` | The server has said when to come back. |
/// | `503 SERVICE_UNAVAILABLE` | yes | Dependency down or maintenance. |
/// | `502` / `504` | yes | Gateway-level, the application never saw the request. |
/// | `500 SERVER_ERROR` | **no** | The request reached the application and something went wrong inside it. Repeating it repeats the fault, and may repeat a partial effect. |
/// | `401` | **no** | Handled once by the auth layer, never by retrying. |
/// | Any other `4xx` | **no** | The request is wrong; sending it again does not make it right. |
///
/// ## Backoff
///
/// Exponential with **full jitter** — the delay is a uniform random value in
/// `[0, base * 2^attempt]`, capped. Deterministic backoff synchronises every
/// client that failed at the same moment (a tower handover, a backend restart)
/// into a thundering herd that arrives together and knocks the service over
/// again. Full jitter is the standard mitigation, and it is what AWS's
/// "Exponential Backoff and Jitter" guidance recommends over equal or decorrelated
/// jitter for this shape of workload.
///
/// A server-supplied `Retry-After` always wins over the computed delay: the
/// server knows something the client does not.
@immutable
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 8),
    this.maxRetryAfter = const Duration(seconds: 30),
  }) : assert(maxAttempts >= 1, 'At least one attempt must be made.');

  /// Total attempts including the first. 3 means one try and two retries.
  ///
  /// Small on purpose: a resident staring at a spinner would rather be told the
  /// service is unavailable than wait through five silent attempts.
  final int maxAttempts;

  final Duration baseDelay;

  /// Ceiling for the computed backoff.
  final Duration maxDelay;

  /// Ceiling for honouring a server `Retry-After`.
  ///
  /// A server asking the app to wait ten minutes is not something to obey
  /// inside a request: the call fails, and the resident is told, rather than the
  /// app hanging with no explanation.
  final Duration maxRetryAfter;

  /// Never retried, whatever else is true.
  static const Set<int> nonRetryableStatuses = <int>{
    400, 401, 403, 404, 405, 409, 422,
    // 500 is deliberately here: the application saw the request.
    500,
  };

  static const Set<int> retryableStatuses = <int>{408, 429, 502, 503, 504};

  /// Whether [failure] on [request] may be retried at all.
  bool isRetryable({
    required ApiRequest request,
    required AppFailure failure,
    int? statusCode,
  }) {
    if (!_isRepeatable(request)) return false;

    if (statusCode != null) {
      if (nonRetryableStatuses.contains(statusCode)) return false;
      return retryableStatuses.contains(statusCode);
    }

    // No status: the response never arrived.
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => true,
      RateLimitedFailure() => true,
      ServerFailure(isTemporary: final temporary) => temporary,
      _ => false,
    };
  }

  /// Whether sending [request] again can create a second thing.
  ///
  /// Exposed for testing and for call sites that want to explain to a resident
  /// why an action was not retried automatically.
  bool _isRepeatable(ApiRequest request) {
    if (request.method.isSafe) return true;
    final key = request.headers['Idempotency-Key'];
    return key != null && key.isNotEmpty;
  }

  /// Delay before attempt number [attempt] (1-based: the first *retry* is 1).
  ///
  /// [retryAfter] is the server's instruction, when it supplied one.
  Duration delayFor(int attempt, {Duration? retryAfter, math.Random? random}) {
    if (retryAfter != null && retryAfter > Duration.zero) {
      return retryAfter > maxRetryAfter ? maxRetryAfter : retryAfter;
    }

    final exponential = baseDelay * math.pow(2, attempt - 1).toDouble();
    final ceiling = exponential > maxDelay ? maxDelay : exponential;
    // Full jitter: uniform in [0, ceiling].
    final jittered = (random ?? _random).nextDouble() * ceiling.inMicroseconds;
    return Duration(microseconds: jittered.round());
  }

  static final math.Random _random = math.Random();
}

/// Extension point so a caller can explain non-retryability.
extension RetryPolicyExplanation on RetryPolicy {
  /// Whether a repeat of [request] is permitted by the idempotency rule.
  bool mayRepeat(ApiRequest request) => _isRepeatable(request);
}
