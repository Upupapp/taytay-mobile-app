import 'dart:math';

import 'package:flutter/foundation.dart';

/// The channel this build identifies itself as.
///
/// `docs/api/conventions.md` §2 and ADR 0002 are emphatic that
/// `X-Client-Channel` is **telemetry and presentation defaults only, never
/// authority**. The server resolves permissions from the authenticated actor; a
/// spoofed channel grants nothing. It is sent so that audit logs and support can
/// tell a mobile request from a kiosk one — nothing else.
const String kClientChannel = 'citizen-mobile';

/// Builds the per-request headers required by the Taytay API contract.
///
/// Nothing authority-shaped is ever added here. The app does not send a role, a
/// permission list, an `is_admin` flag, a verification tier, or any other claim
/// about itself: ADR 0002 §4 says such values are ignored server-side, and
/// sending them would invite a future reader to believe they matter.
@immutable
class RequestContext {
  const RequestContext({required this.requestId, this.bearerToken});

  /// Generates a fresh correlation id for one request.
  factory RequestContext.generate({String? bearerToken}) =>
      RequestContext(requestId: generateRequestId(), bearerToken: bearerToken);

  /// Client-supplied correlation id, echoed back by the server in
  /// `X-Request-Id` and inside every error body.
  final String requestId;

  /// Access token for protected routes; `null` for a guest request.
  final String? bearerToken;

  /// Header map for this request.
  ///
  /// [idempotencyKey] should be supplied for any state-changing call the app may
  /// retry (conventions §7) so a retry after a flaky mobile connection cannot
  /// create a duplicate application.
  Map<String, String> headers({
    bool hasJsonBody = false,
    String? idempotencyKey,
    String? accept,
  }) {
    return <String, String>{
      'Accept': accept ?? 'application/json',
      if (hasJsonBody) 'Content-Type': 'application/json',
      'X-Client-Channel': kClientChannel,
      'X-Request-Id': requestId,
      if (bearerToken != null && bearerToken!.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'Idempotency-Key': idempotencyKey,
    };
  }

  /// Redacted form for logs. The token must never reach a log sink, a crash
  /// report or an error message (CLAUDE.md Article 5).
  @override
  String toString() =>
      'RequestContext(requestId: $requestId, authenticated: ${bearerToken != null})';
}

const String _requestIdAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

final Random _requestIdRandom = Random();

/// Generates a correlation id inside the server's accepted shape:
/// at most 128 characters of `A-Za-z0-9._:-` (conventions §2).
///
/// A timestamp prefix makes ids sort roughly by time in a log, and the random
/// suffix keeps them unique across concurrent requests. It carries no device or
/// resident identifier — a correlation id that follows a person around is a
/// tracking identifier, not a debugging aid.
String generateRequestId() {
  final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(
    36,
  );
  final suffix = String.fromCharCodes(
    Iterable<int>.generate(
      12,
      (_) => _requestIdAlphabet.codeUnitAt(
        _requestIdRandom.nextInt(_requestIdAlphabet.length),
      ),
    ),
  );
  return 'tay-$timestamp-$suffix';
}

final Random _idempotencyRandom = Random.secure();

/// A fresh idempotency key: a random (version 4) UUID.
///
/// The Node API reads a key from the request body and accepts a UUID only
/// (backend `0d1cb14`). A caller mints one when the resident presses send and
/// holds it across every retry of that send, so a retry after a timeout is
/// answered with what the first send did instead of acting twice.
///
/// Drawn from the platform's secure source: a key another device could guess
/// is a key somebody else could replay. It names no device and no resident.
String generateIdempotencyKey() {
  final List<int> bytes = List<int>.generate(
    16,
    (_) => _idempotencyRandom.nextInt(256),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final String hex = bytes
      .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
