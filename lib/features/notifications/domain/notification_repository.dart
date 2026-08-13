import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart';

/// A message the LGU sent to this resident.
@immutable
class ResidentNotification {
  const ResidentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.readAt,
  });

  final String id;

  /// Copy composed by the LGU for the resident. Rendered as sent — unlike an
  /// operator-facing error `message`, this is addressed to them.
  final String title;
  final String body;

  final DateTime? sentAt;

  /// `null` while unread.
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  /// Redacted: a notification body can name a service a resident applied for,
  /// which is personal data.
  @override
  String toString() => 'ResidentNotification($id, unread: $isUnread)';
}

/// Which channels a resident wants to be contacted on.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.push,
    required this.sms,
    required this.email,
  });

  final bool push;
  final bool sms;
  final bool email;
}

/// The resident's own notifications and channel preferences.
///
/// The `Notification` module owns "outbound notification dispatch, delivery
/// receipts, per-resident channel preferences" and explicitly does **not** own
/// "why a notification was triggered" — so this app never asks it for the reason
/// behind a message, and never infers one.
///
/// **Preferences live on the server, not on the device.** A resident who
/// silences SMS on one phone expects it silenced everywhere, and a device-local
/// preference would keep the LGU sending messages the resident asked it to stop
/// sending.
abstract interface class NotificationRepository {
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page,
    int perPage,
  });

  /// Marks one of the resident's own notifications as read.
  ///
  /// Naturally idempotent — marking a read notification read again is a no-op —
  /// so no idempotency key is required.
  Future<Result<void>> markRead(String id);

  Future<Result<NotificationPreferences>> loadPreferences();

  Future<Result<void>> updatePreferences(NotificationPreferences preferences);
}
