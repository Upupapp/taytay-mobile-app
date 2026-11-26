import '../../../core/time/manila_time.dart';
import 'credential_repository.dart';

/// What the issued card shows.
///
/// `expired` is not a server status. The wire enum is `active`, `suspended`,
/// and `revoked`. Expired is this client's reading of an active card whose
/// `expires_at` is in the past and whose `qr` is null.
enum DigitalIdFace { active, suspended, revoked, expired }

/// The face to paint, or null when there is no card to show.
///
/// A null card is not issued. An unrecognised status fails closed to the same
/// outcome: this app does not invent a working ID. Suspended and revoked win
/// over the expiry rule. Expired is `now` strictly after `expires_at` with a
/// null QR. A code the server still sent is shown, even past the card date.
DigitalIdFace? digitalIdFace(ResidentCredential? card, DateTime now) {
  if (card == null) return null;
  final CredentialLifecycleState? state = card.state;
  switch (state) {
    case CredentialLifecycleState.revoked:
      return DigitalIdFace.revoked;
    case CredentialLifecycleState.suspended:
      return DigitalIdFace.suspended;
    case CredentialLifecycleState.expired:
      return DigitalIdFace.expired;
    case CredentialLifecycleState.active:
      final DateTime? expiry = card.expiresAt;
      final bool past = expiry != null && now.toUtc().isAfter(expiry.toUtc());
      if (past && card.qr == null) return DigitalIdFace.expired;
      return DigitalIdFace.active;
    case CredentialLifecycleState.applied:
    case CredentialLifecycleState.underReview:
    case CredentialLifecycleState.approved:
    case CredentialLifecycleState.issued:
    case null:
      return null;
  }
}

/// GET /me `name`, shown as sent.
///
/// Trimmed. Not recased. Null when the field is missing or blank, which is
/// the signal to hide the NAME block.
String? publishedResidentName(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// `MMM d, yyyy` in Manila (D-107): the card's dates are the office's, and a
/// phone set to another zone once showed a card issued late in the evening
/// as issued the day before (D-236).
String formatDigitalIdDate(DateTime instant) {
  final DateTime local = ManilaTime.of(instant);
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

/// `h:mm a` in Manila, the QR line's "valid until"; the caller says PHT
/// beside it (D-107, D-236).
String formatDigitalIdClock(DateTime instant) {
  final DateTime local = ManilaTime.of(instant);
  final int hour24 = local.hour;
  final int hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final String minutes = local.minute.toString().padLeft(2, '0');
  final String period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour:$minutes $period';
}
