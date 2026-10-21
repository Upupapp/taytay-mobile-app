import 'package:flutter/foundation.dart';

/// How long a presented QR stays scannable.
///
/// `GET /api/v1/me/digital-id` returns the card and a QR. The QR's own
/// `expires_at` is two minutes after it is minted.
const Duration digitalIdQrLifetime = Duration(minutes: 2);

/// Fetch a replacement this long before [DigitalIdQr.expiresAt].
///
/// A code that dies while a clerk is raising the scanner is the failure the
/// expiry exists to avoid. Refreshing slightly early costs one extra read.
const Duration digitalIdQrRefreshLead = Duration(seconds: 15);

/// Card status from `DigitalIdCard.status`.
///
/// An unrecognised value stays null. This app may show a card; it does not
/// decide that an unknown status is a working ID.
enum DigitalIdStatus {
  active,
  suspended,
  revoked;

  static DigitalIdStatus? fromWire(String? raw) => switch (raw) {
    'active' => active,
    'suspended' => suspended,
    'revoked' => revoked,
    _ => null,
  };

  bool get isPresentable => this == DigitalIdStatus.active;
}

/// The short-lived QR on a digital ID.
///
/// The token is signed material. [toString] does not include it.
@immutable
class DigitalIdQr {
  const DigitalIdQr({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  /// Whether [now] is inside the refresh window, or past the expiry.
  bool refreshDue(DateTime now) =>
      !expiresAt.toUtc().isAfter(now.toUtc().add(digitalIdQrRefreshLead));

  @override
  String toString() => 'DigitalIdQr(expiresAt: $expiresAt)';
}

/// The signed-in resident's municipal card, plus its current QR.
///
/// `id_number` is the municipal card number. It is not a national identifier,
/// and it is still personal data, so [toString] keeps only the status.
@immutable
class DigitalIdCard {
  const DigitalIdCard({
    required this.id,
    required this.idNumber,
    required this.photoMediaId,
    required this.status,
    required this.rawStatus,
    required this.issuedAt,
    required this.expiresAt,
    this.qr,
  });

  final String id;
  final String idNumber;
  final String photoMediaId;
  final DigitalIdStatus? status;
  final String rawStatus;
  final DateTime issuedAt;

  /// When the card itself stops being current. Not the QR lifetime.
  final DateTime expiresAt;

  /// Null when the server sent no scannable payload.
  final DigitalIdQr? qr;

  /// A missing QR is due for a fetch. A live one is due inside the lead.
  bool qrRefreshDue(DateTime now) {
    final DigitalIdQr? code = qr;
    if (code == null) return true;
    return code.refreshDue(now);
  }

  @override
  String toString() => 'DigitalIdCard(status: $rawStatus)';
}

/// What a staff scanner is told by `POST /api/v1/digital-id/verify`.
///
/// The resident app names this response and does not request it.
@immutable
class DigitalIdHolder {
  const DigitalIdHolder({
    required this.name,
    required this.photoMediaId,
    required this.status,
    required this.rawStatus,
    required this.expired,
    required this.barangayId,
    required this.barangayName,
  });

  final String? name;
  final String photoMediaId;
  final DigitalIdStatus? status;
  final String rawStatus;
  final bool expired;
  final String? barangayId;
  final String? barangayName;

  @override
  String toString() => 'DigitalIdHolder(status: $rawStatus, expired: $expired)';
}
